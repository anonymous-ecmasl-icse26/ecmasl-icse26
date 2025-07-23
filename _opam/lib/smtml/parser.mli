
(* The type of tokens. *)

type token = 
  | UNARY of (Ty.t * Ty.Unop.t)
  | TYPE of (Ty.t)
  | TERNARY of (Ty.t * Ty.Triop.t)
  | SYMBOL of (string)
  | STR of (string)
  | SET_LOGIC
  | RPAREN
  | RELOP of (Ty.t * Ty.Relop.t)
  | PUSH
  | PTR
  | POP
  | NUM of (int)
  | NARY of (Ty.t * Ty.Naryop.t)
  | LPAREN
  | LOGIC of (Logic.t)
  | LET_CONST
  | GET_MODEL
  | EXTRACT
  | EOF
  | DEC of (float)
  | CVTOP of (Ty.t * Ty.Cvtop.t)
  | CONCAT
  | CHECK_SAT
  | BOOL of (bool)
  | BINARY of (Ty.t * Ty.Binop.t)
  | ASSERT

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val script: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.t list)

module MenhirInterpreter : sig
  
  (* The incremental API. *)
  
  include MenhirLib.IncrementalEngine.INCREMENTAL_ENGINE
    with type token = token
  
end

(* The entry point(s) to the incremental API. *)

module Incremental : sig
  
  val script: Lexing.position -> (Ast.t list) MenhirInterpreter.checkpoint
  
end
