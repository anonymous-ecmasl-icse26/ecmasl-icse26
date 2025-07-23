
(* The type of tokens. *)

type token = 
  | WORD of (String.t)
  | RBRACE
  | NEWLINE
  | LBRACE
  | EOF

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val config: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Types.config)

module MenhirInterpreter : sig
  
  (* The incremental API. *)
  
  include MenhirLib.IncrementalEngine.INCREMENTAL_ENGINE
    with type token = token
  
end

(* The entry point(s) to the incremental API. *)

module Incremental : sig
  
  val config: Lexing.position -> (Types.config) MenhirInterpreter.checkpoint
  
end
