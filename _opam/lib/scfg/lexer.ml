open Sedlexing
open Menhir_parser

let ctl = [%sedlex.regexp? '\x00' .. '\x1f' | '\x7F']

let wsp = [%sedlex.regexp? ' ' | '\t']

let vchar = [%sedlex.regexp? Sub (any, ctl)]

let sqchar = [%sedlex.regexp? Sub (any, (ctl | '\''))]

let dqchar = [%sedlex.regexp? Sub (any, (ctl | '"' | '\\'))]

let achar =
  [%sedlex.regexp? Sub (any, (ctl | '"' | '\\' | '\'' | '{' | '}' | wsp))]

let newline =
  [%sedlex.regexp?
    Plus (Star wsp, '\n', Star wsp, Opt ('#', Star (Sub (any, '\n'))))]

let esc_pair = [%sedlex.regexp? '\\', vchar]

let squote_word = [%sedlex.regexp? '\'', Star sqchar, '\'']

let dquote_word = [%sedlex.regexp? '"', Star (dqchar | esc_pair), '"']

let atom = [%sedlex.regexp? Plus (achar | esc_pair)]

let string_of_atom s =
  let b = Buffer.create (String.length s) in
  let i = ref 0 in
  while !i < String.length s do
    let c =
      if not @@ Char.equal '\\' s.[!i] then s.[!i]
      else
        match
          incr i;
          s.[!i]
        with
        | 'n' -> '\n'
        | 'r' -> '\r'
        | 't' -> '\t'
        | '\\' -> '\\'
        | '\'' -> '\''
        | '"' -> '"'
        | '{' -> '{'
        | '}' -> '}'
        | _c -> assert false
    in
    Buffer.add_char b c;
    incr i
  done;
  Buffer.contents b

let string_of_dqword s =
  let b = Buffer.create (String.length s) in
  let i = ref 0 in
  while !i < String.length s do
    let c =
      if not @@ Char.equal '\\' s.[!i] then s.[!i]
      else
        match
          incr i;
          s.[!i]
        with
        | 'n' -> '\n'
        | 'r' -> '\r'
        | 't' -> '\t'
        | '\\' -> '\\'
        | '"' -> '"'
        | _c -> assert false
    in
    Buffer.add_char b c;
    incr i
  done;
  Buffer.contents b

exception Error of string

let error msg = raise @@ Error msg

let rec token buf =
  match%sedlex buf with
  (* 1 *)
  | "{", newline -> LBRACE
  | newline, "}" -> RBRACE
  (* other *)
  | wsp -> token buf
  | Opt newline, eof -> EOF
  | newline -> NEWLINE
  | atom ->
    let word = Utf8.lexeme buf in
    let word = string_of_atom word in
    WORD word
  | dquote_word ->
    let word = Utf8.lexeme buf in
    let word = String.sub word 1 (String.length word - 2) in
    let word = string_of_dqword word in
    WORD word
  | squote_word ->
    let word = Utf8.lexeme buf in
    let word = String.sub word 1 (String.length word - 2) in
    WORD word
  | any ->
    let invalid = Utf8.lexeme buf in
    let start, _stop = Sedlexing.lexing_positions buf in
    Fmt.kstr error "File %s, line %i, character %i: unexpected lexeme `%s`"
      start.pos_fname start.pos_lnum
      (start.pos_cnum - start.pos_bol)
      invalid
  | _ -> assert false
