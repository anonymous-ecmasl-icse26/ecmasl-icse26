open Cmdliner

(* Helpers *)
let existing_file_conv = Arg.conv (Fpath.of_string, Fpath.pp)

(* Terms *)
let config =
  let doc = "Input file" in
  Arg.(required & pos 0 (some existing_file_conv) None (info [] ~doc))

(* Command *)
let pp_cmd =
  let open Term.Syntax in
  let+ config in
  match Scfg.Parse.from_file config with
  | Error (`Msg e) ->
    Fmt.epr "%s" e;
    exit 1
  | Ok config -> Fmt.pr "%a@." Scfg.Pp.config config

let pp_info =
  let doc = "Format scfg files." in
  let man = [ `S Manpage.s_bugs; `P "Léo Andrès <contact@ndrs.fr>" ] in
  Cmd.info "scfg" ~version:"%%VERSION%%" ~doc ~man

let cli = Cmd.v pp_info pp_cmd

let () = exit @@ Cmdliner.Cmd.eval cli
