(** Module providing functions to parse a config from various kind of inputs. *)

(** Pretty print a token *)
let pp_token fmt = function
  | Menhir_parser.WORD s -> Fmt.pf fmt "WORD %s" s
  | LBRACE -> Fmt.string fmt "LBRACE"
  | RBRACE -> Fmt.string fmt "RBRACE"
  | NEWLINE -> Fmt.string fmt "NEWLINE"
  | EOF -> Fmt.string fmt "EOF"

(** Parse a config from a lexing buffer. *)
let from_lexbuf =
  let parser =
    MenhirLib.Convert.Simplified.traditional2revised Menhir_parser.config
  in
  fun buf ->
    let last_token = ref None in
    let provider () =
      let tok = Lexer.token buf in
      let start, stop = Sedlexing.lexing_positions buf in
      last_token := Some tok;
      (tok, start, stop)
    in
    try Ok (parser provider) with
    | Menhir_parser.Error ->
      let start, _stop = Sedlexing.lexing_positions buf in
      Fmt.error_msg "File %s, line %i, character %i: unexpected token %a"
        start.pos_fname start.pos_lnum
        (start.pos_cnum - start.pos_bol)
        (Fmt.option pp_token) !last_token
    | Lexer.Error msg -> Error (`Msg msg)

(** Parse a config from a string. *)
let from_string s = from_lexbuf (Sedlexing.Utf8.from_string s)
(*
  let filename = Filename.temp_file "scfg" "scfg" in
  let chan = open_out_bin filename in
  output_string chan s;
  close_out_noerr chan;
  let chan = open_in_bin filename in
  from_lexbuf (Sedlexing.Utf8.from_channel chan)
  *)

(** Parse a config from a channel. *)
let from_channel c = from_lexbuf (Sedlexing.Utf8.from_channel c)

(** Parse a config from a file. *)
let from_file f =
  match
    Bos.OS.File.with_ic f
      (fun chan () ->
        let lexbuf = Sedlexing.Utf8.from_channel chan in
        Sedlexing.set_filename lexbuf (Fpath.to_string f);
        from_lexbuf lexbuf )
      ()
  with
  | Error _ as e -> e
  | Ok (Error _ as e) -> e
  | Ok (Ok _ as ok) -> ok
