open Bos
open Result
open Cmdliner

(* let ( let* ) v f = Result.bind v f

let ( let+ ) v f = Result.map f v *)

let list_map f v =
  let rec list_map_cps f v k =
    match v with
    | [] -> k (Ok [])
    | hd :: tl ->
      list_map_cps f tl (fun rest ->
        let* rest in
        let* hd' = f hd in
        k (Ok (hd' :: rest)) )
  in
  list_map_cps f v Fun.id

let find_files_ext dir ext =
  let files =
    OS.Dir.fold_contents
      (fun path acc -> if Fpath.has_ext ext path then path :: acc else acc)
      [] dir
  in
  value files ~default:[]

let get_dataset dir filter =
  let dataset = find_files_ext dir ".js" in
  let contains s regex =
    try
      let _ = Pcre.exec ~pat:regex s in
      true
    with Not_found -> false
  in

  let dataset' =
    match filter with
    | None -> dataset
    | Some pattern ->
      List.filter (fun path -> contains (Fpath.to_string path) pattern) dataset
  in

  (* Ensure deterministic execution order *)
  List.rev @@ List.sort Fpath.compare dataset'

let dup2 src dst =
  let src = Unix.openfile (Fpath.to_string src) [ O_CREAT; O_WRONLY ] 0o644 in
  Fun.protect ~finally:(fun () -> Unix.close src) (fun () -> Unix.dup2 src dst)

let results_dir_name objmodel output =
  match output with
  | None ->
    let tm = Unix.localtime @@ Unix.gettimeofday () in
    Fmt.kstr Fpath.v "./results-%04d-%02d-%02d_%02dh%02dm%02ds-%s"
      (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday tm.tm_hour tm.tm_min
      tm.tm_sec objmodel
  | Some name -> Fpath.v name

let create_results_dir objmodel output =
  let folder = results_dir_name objmodel output in
  let _ = OS.Dir.create folder in
  folder

let oc folder filename_ =
  let results = Fpath.(folder / filename_) in
  Out_channel.open_text @@ Fpath.to_string results

let pp oc fmt =
  Fun.protect ~finally:Out_channel.flush_all (fun () ->
    Fmt.kstr (Out_channel.output_string oc) fmt )

let ok_or_failwith = function
  | Ok v -> v
  | Error (`Msg err) -> Fmt.failwith "%s@." err

type summary =
  { total_tests : int
  ; failed_tests : int
  ; elapsed_time : float
  ; n_paths : int
  }

let summarize_results results : summary =
  let (failed_tests, elapsed_time, n_paths) =
    List.fold_left
      (fun (fail_acc, time_acc, paths_acc)
           Exec_result.{ clock; status; paths; _ } ->
        let fail_acc =
          match status with Unix.WEXITED 0 -> fail_acc | _ -> succ fail_acc
        in
        (fail_acc, time_acc +. clock, paths_acc + paths) )
      (0, 0.0, 0) results
  in
  let total_tests = List.length results in
  { total_tests; failed_tests; elapsed_time; n_paths }

let pp_summary_text fmt (s : summary) =
  if s.failed_tests = 0 then Fmt.pr "All OK@\n"
  else Fmt.pf fmt "Tests %d/%d failed!@\n" s.failed_tests s.total_tests;
  Fmt.pf fmt "Elapsed time %as" Fmt.float s.elapsed_time

let pp_summary_json oc (s : summary) =
  let json =
    `Assoc
      [ ("total_tests", `Int s.total_tests)
      ; ("failed_tests", `Int s.failed_tests)
      ; ("time", `Float s.elapsed_time)
      ; ("paths", `Int s.n_paths)
      ]
  in
  Yojson.Basic.pretty_to_channel oc json

let run_single workspace file objmodel timeout =
  Fmt.pr "Running test: %a@." Fpath.pp file;
  let start_time = Unix.gettimeofday () in
  let start_rusage = Ruse.get Children in
  let pid = Unix.fork () in
  if pid = 0 then (
    dup2 Fpath.(workspace / "stderr") Unix.stderr;
    dup2 Fpath.(workspace / "stdout") Unix.stdout;
    let (prog, args) = Tool.cmd Tool.Symbolic ~workspace ~file ~objmodel in
    Unix.execvp prog args )
  else
    let _ = Unix.alarm timeout in
    Sys.set_signal Sys.sigalrm (Signal_handle (fun (_ : int) -> Unix.kill pid 9));
    Fun.protect
      ~finally:(fun () -> Sys.set_signal Sys.sigalrm Signal_default)
      (fun () ->
        let (waited_pid, status) =
          try Unix.waitpid [] pid
          with Unix.Unix_error (Unix.EINTR, _, _) -> Unix.waitpid [] pid
        in
        let models = Fpath.(workspace / "test-suite") in
        let paths = find_files_ext models ".sexp" in
        let clock = Unix.gettimeofday () -. start_time in
        let rusage = Ruse.sub (Ruse.get Children) start_rusage in
        assert (waited_pid = pid);
        Exec_result.{ clock; file; rusage; status; paths = List.length paths } )

let run datasets results_dir oc objmodel timeout filter =
  let dataset = get_dataset datasets filter in
  let i = ref 0 in
  let n = List.length dataset in
  list_map
    (fun file ->
      incr i;
      let workspace = Fpath.(results_dir // base file) in
      let+ _ = OS.Dir.create ~path:true workspace in
      let exec_result = run_single workspace file objmodel timeout in
      pp oc "Run %d/%d %a@." !i n Exec_result.pp exec_result;
      exec_result )
    dataset

let main (dataset_dir : string) (objmodel : string) (timeout : int)
  (filter : string option) (output : string option) :
  (unit, [ `Msg of string ]) result =
  let dataset_dir = Fpath.v dataset_dir in
  let results_dir = create_results_dir objmodel output in
  let oc_text = oc results_dir "results.txt" in
  let oc_json = oc results_dir "results.json" in
  Fmt.pr "Using dataset dir: %a@." Fpath.pp dataset_dir;
  Fun.protect
    ~finally:(fun () ->
      Out_channel.close oc_text;
      Out_channel.close oc_json )
    (fun () ->
      let results =
        run dataset_dir results_dir oc_text objmodel timeout filter
      in
      let results' = ok_or_failwith results in
      let summary = summarize_results results' in
      pp oc_text "%a@." pp_summary_text summary;
      pp_summary_json oc_json summary;
      Ok () )

let info =
  let doc = "Run symbolic analysis on JavaScript files" in
  Cmd.info "ecma-sl runner" ~version:"0.1" ~doc

let output_arg =
  let doc = "Specify the output directory name." in
  Cmdliner.Arg.(
    value & opt (some string) None & info [ "out"; "output" ] ~docv:"DIR" ~doc )

let filter_arg =
  let doc =
    "Only run tests whose filenames contain this string (case-sensitive)"
  in
  Cmdliner.Arg.(
    value & opt (some string) None & info [ "f"; "filter" ] ~docv:"PATTERN" ~doc )

let objmodel_arg =
  let docv = "MODEL" in
  let doc =
    "The chosen symbolic object model. \n\
    \ Options: (default); (logging); (lifting); and (loglifting)"
  in
  let models = Arg.enum Tool.ObjModels.opts in
  Arg.(
    value
    & opt models (Tool.ObjModels.to_string Tool.ObjModels.Default)
    & info [ "objmodel"; "o" ] ~docv ~doc )

let timeout_arg =
  let doc = "Timeout in seconds (default: 300)" in
  Arg.(value & opt int 300 & info [ "t"; "timeout" ] ~docv:"SECONDS" ~doc)

let dataset_dir_arg =
  let doc = "Path to the dataset directory (default: ../buckets-js/test)" in
  Arg.(
    value
    & opt string "../buckets-js/test"
    & info [ "d"; "dataset-dir" ] ~docv:"DIR" ~doc )

let cmd_main =
  Term.(
    term_result
      ( const main
      $ dataset_dir_arg
      $ objmodel_arg
      $ timeout_arg
      $ filter_arg
      $ output_arg ) )

let () = exit (Cmd.eval (Cmd.v info cmd_main))
