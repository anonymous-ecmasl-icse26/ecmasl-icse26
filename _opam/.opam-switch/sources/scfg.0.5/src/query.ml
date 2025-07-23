(** Module providing functions to search inside a config. *)

open Types

(** Returns a list of directives with the provided name from a list of
    directives. *)
let get_dirs name directives =
  List.filter (fun directive -> String.equal directive.name name) directives

(** Returns the first directive with the provided name from a list of directive.
*)
let get_dir name directives =
  List.find_opt (fun directive -> String.equal directive.name name) directives

(** Same as [get_dir] but raises if no directive is found. *)
let get_dir_exn name directives =
  match get_dir name directives with
  | None -> Fmt.failwith "missing directive %a" Pp.param name
  | Some dir -> dir

(** Extract a given number of parameters from a directive. *)
let get_params n directive =
  let len = List.length directive.params in
  if len < n then
    Fmt.error_msg "directive %a: want %d params, got only %d" Pp.param
      directive.name n len
  else Ok (List.filteri (fun i _param -> i < n) directive.params)

(** Extract a parameter at a given index from a directive. *)
let get_param n directive =
  let params = directive.params in
  match List.nth_opt params n with
  | None ->
    Fmt.error_msg "directive %a: want param at index %d, got only %d" Pp.param
      directive.name n (List.length params)
  | Some param -> Ok param

(** Same as [get_param] but raises if an error occurs. *)
let get_param_exn n directive =
  match get_param n directive with
  | Ok v -> v
  | Error (`Msg msg) -> Fmt.failwith "%s" msg

(** Extract a bool parameter at a given index from a directive. *)
let get_param_bool n directive =
  let params = directive.params in
  match List.nth_opt params n with
  | None ->
    Fmt.error_msg "directive %a: want param at index %d, got only %d" Pp.param
      directive.name n (List.length params)
  | Some param -> (
    match bool_of_string_opt param with
    | None ->
      Fmt.error_msg "directive %a: want bool param at index %d, but got `%s`"
        Pp.param directive.name n param
    | Some b -> Ok b )

(** Same as [get_param_bool] but raises if an error occurs. *)
let get_param_bool_exn n directive =
  match get_param_bool n directive with
  | Ok v -> v
  | Error (`Msg msg) -> Fmt.failwith "%s" msg

(** Extract an int parameter at a given index from a directive. *)
let get_param_int n directive =
  let params = directive.params in
  match List.nth_opt params n with
  | None ->
    Fmt.error_msg "directive %a: want param at index %d, got only %d" Pp.param
      directive.name n (List.length params)
  | Some param -> (
    match int_of_string_opt param with
    | None ->
      Fmt.error_msg "directive %a: want int param at index %d, but got %s"
        Pp.param directive.name n param
    | Some v -> Ok v )

(** Same as [get_param_int] but raises if an error occurs. *)
let get_param_int_exn n directive =
  match get_param_int n directive with
  | Ok v -> v
  | Error (`Msg msg) -> Fmt.failwith "%s" msg

(** Extract a positive int parameter at a given index from a directive. *)
let get_param_pos_int n directive =
  let params = directive.params in
  match List.nth_opt params n with
  | None ->
    Fmt.error_msg "directive %a: want param at index %d, got only %d" Pp.param
      directive.name n (List.length params)
  | Some param -> (
    match int_of_string_opt param with
    | None ->
      Fmt.error_msg "directive %a: want int param at index %d, but got %s"
        Pp.param directive.name n param
    | Some n ->
      if n < 0 then
        Fmt.error_msg
          "directive %a: want positive int param at index %d, but got %d"
          Pp.param directive.name n n
      else Ok n )

(** Same as [get_param_pos_int] but raises if an error occurs. *)
let get_param_pos_int_exn n directive =
  match get_param_pos_int n directive with
  | Ok v -> v
  | Error (`Msg msg) -> Fmt.failwith "%s" msg

(** Extract a float parameter at a given index from a directive. *)
let get_param_float n directive =
  let params = directive.params in
  match List.nth_opt params n with
  | None ->
    Fmt.error_msg "directive %a: want param at index %d, got only %d" Pp.param
      directive.name n (List.length params)
  | Some param -> (
    match float_of_string_opt param with
    | None ->
      Fmt.error_msg "directive %a: want float param at index %d, but got %s"
        Pp.param directive.name n param
    | Some f -> Ok f )

(** Same as [get_param_float] but raises if an error occurs. *)
let get_param_float_exn n directive =
  match get_param_float n directive with
  | Ok v -> v
  | Error (`Msg msg) -> Fmt.failwith "%s" msg
