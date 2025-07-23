(** Module providing functions to pretty print a config or parts of a config. *)

open Types

(** Print a name or a parameter on a given formatter. The function will try to
    print with as low quoting as possible. *)
let param =
  let chars_to_quote = Hashtbl.create 512 in
  Array.iter
    (fun c -> Hashtbl.replace chars_to_quote c ())
    [| ' '; '{'; '}'; '"'; '\\'; '\''; '\n'; '\r'; '\t' |];
  fun fmt param ->
    if String.length param = 0 then Fmt.string fmt {|""|}
    else if String.exists (Hashtbl.mem chars_to_quote) param then begin
      if String.contains param '"' && not (String.contains param '\'') then
        Fmt.pf fmt {|'%s'|} param
      else
        let buf = Buffer.create (String.length param) in
        String.iter
          (function
            | '\n' -> Buffer.add_string buf "\\n"
            | '\r' -> Buffer.add_string buf "\\r"
            | '\t' -> Buffer.add_string buf "\\t"
            | '"' -> Buffer.add_string buf "\\\""
            | '\\' -> Buffer.add_string buf "\\\\"
            | c -> Buffer.add_char buf c )
          param;
        let param = Buffer.contents buf in
        Fmt.pf fmt {|"%s"|} param
    end
    else Fmt.string fmt param

(** Print a list of parameters on a given formatter. *)
let params fmt = function
  | [] -> ()
  | params ->
    Fmt.pf fmt " %a"
      (Fmt.list ~sep:(fun fmt () -> Fmt.string fmt " ") param)
      params

(** Print children of a directive on a given formatter. *)
let rec children fmt = function
  | [] -> ()
  | children -> Fmt.pf fmt " {@\n  @[<v>%a@]@\n}" config children

(** Print a directive on a given formatter. *)
and directive fmt d =
  Fmt.pf fmt {|%a%a%a|} param d.name params d.params children d.children

(** Print a config on a given formatter. *)
and config fmt (config : Types.config) =
  Fmt.list ~sep:(fun fmt () -> Fmt.pf fmt "@\n") directive fmt config
