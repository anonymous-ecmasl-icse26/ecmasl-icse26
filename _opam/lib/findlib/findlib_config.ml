(* $Id$
 * ----------------------------------------------------------------------
 *
 *)
open Fl_compat

let ( / ) = Filename.concat

let exists path =
  match Sys.file_exists path with
  | true -> Some path
  | false -> None

let findlib_conf_of_path path =
  match exists (path / "etc" / "findlib.conf") with
  | Some etc_path -> etc_path
  | None -> path / "lib" / "findlib.conf"

let install_dir_from_binary path =
  let exe_dir = Filename.dirname path in
  let install_dir = Filename.dirname exe_dir in
  let config_path = findlib_conf_of_path install_dir in
  match Sys.file_exists config_path with
  | true -> Some install_dir
  | false -> None
;;

let find_in_path name =
  match Sys.getenv_opt "PATH" with
  | None -> None
  | Some search_in -> (
    let paths = String.split_on_char Fl_split.path_separator search_in in
    match List.find_map (fun path -> path / name |> exists) paths with
    | None -> None
    | Some location -> install_dir_from_binary location)
;;

let install_dir_from_ld_library_path paths =
  String.split_on_char Fl_split.path_separator paths
  |> List.find_map (fun path ->
    let parent = Filename.dirname path in
    let parent' = Filename.dirname parent in
    match Sys.file_exists (findlib_conf_of_path parent') with
    | true -> Some parent'
    | false -> None)
;;

let install_dir_from_ocaml_toplevel_path = install_dir_from_binary

let install_dir_from_opam_switch_prefix path =
  match Sys.file_exists (findlib_conf_of_path path) with
  | false -> None
  | true -> Some path

let default = "/home/arckenimuz/dev/ECMA-SL/_opam/lib/findlib.conf"
let fallback = Option.value ~default

let rec try_vars = function
  | [] -> None
  | (var, mapper)::xs -> (
    match Sys.getenv_opt var with
    | None -> try_vars xs
    | Some content -> (
      match mapper content with
      | None -> try_vars xs
      | Some _ as found -> found))

(* exposed condfigure-time setting *)
let uses_relative_paths = false

(* the location where we assume to be installed in *)
let location = lazy (
  try_vars [
    ("OPAM_SWITCH_PREFIX", install_dir_from_opam_switch_prefix);
    ("CAML_LD_LIBRARY_PATH", install_dir_from_ld_library_path);
    ("OCAML_TOPLEVEL_PATH", install_dir_from_ocaml_toplevel_path);
  ])

let findlib_conf = lazy (
  match Lazy.force location with
  | None -> default
  | Some location -> location
    |> findlib_conf_of_path
    |> exists
    |> fallback)

let config_file = lazy (
  match uses_relative_paths with
  | false -> default
  | true -> Lazy.force findlib_conf)

let ocaml_has_meta_files =
  let ocaml_major =
    String.sub Sys.ocaml_version 0 (String.index Sys.ocaml_version '.') in
  int_of_string ocaml_major >= 5;;

let ocaml_stdlib = "/home/arckenimuz/dev/ECMA-SL/_opam/lib/ocaml";;

let ocaml_ldconf = ocaml_stdlib / "ld.conf";;

let ocaml_has_autolinking = true;;

let libexec_name = "stublibs";;

let system = "linux";;
(* - "mingw", "mingw64", "win32", "cygwin", "linux_elf", ... *)

let dll_suffix =
  match Sys.os_type with
    | "Unix"  | "BeOS"   -> ".so"
    | "Win32" | "Cygwin" -> ".dll"
    | "MacOS"            -> ""        (* don't know *)
    | _ -> failwith "Unknown Sys.os_type"
;;
