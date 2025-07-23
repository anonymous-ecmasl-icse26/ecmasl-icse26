(* run on the `main.scfg` file in this directory *)
let () =
  if Array.length Sys.argv <> 2 then begin
    Format.eprintf "usage: %s <scfg file>@\n" Sys.argv.(0);
    exit 1
  end

(* parsing file path *)
let filepath =
  match Fpath.of_string Sys.argv.(1) with
  | Error (`Msg e) ->
    Format.eprintf "error: %s@\n" e;
    exit 1
  | Ok path -> path

(* parsing the file *)
let config =
  match Scfg.Parse.from_file filepath with
  | Error (`Msg e) ->
    Format.eprintf "error: %s@\n" e;
    exit 1
  | Ok config -> config

(* printing the file *)
let () = Format.printf "```scfg@\n%a@\n```@\n" Scfg.Pp.config config

(* querying the file *)
let () =
  match Scfg.Query.get_dir "train" config with
  | None -> Format.printf "No train found.@\n"
  | Some train -> (
    match Scfg.Query.get_param 0 train with
    | Error _e -> Format.printf "Train has no name.@\n"
    | Ok name -> Format.printf "The first train is `%s`.@\n" name )
