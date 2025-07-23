
(* The type of tokens. *)

type token = 
  | WHILE
  | TYPEOF
  | TIMES
  | TILDE
  | SYMBOL of (string)
  | SWITCH
  | STRING_TO_INT
  | STRING_TO_FLOAT
  | STRING of (string)
  | SHIFT_RIGHT_LOGICAL
  | SHIFT_RIGHT
  | SHIFT_LEFT
  | SEMICOLON
  | RPAREN
  | RETURN
  | RBRACK
  | RBRACE
  | QUESTION
  | PRINT
  | POW
  | PLUS
  | PIPE
  | OBJECT_TO_LIST
  | OBJECT_MEM
  | OBJECT_FIELDS
  | NULL
  | NE
  | MODULO
  | MINUS
  | LT
  | LPAREN
  | LOR
  | LIST_TAIL
  | LIST_HEAD
  | LE
  | LBRACK
  | LBRACE
  | LAND
  | INT_TO_STRING
  | INT_TO_FLOAT
  | INT of (int)
  | IF
  | ID of (string)
  | HASH
  | GT
  | GE
  | FUNCTION
  | FLOAT_TO_STRING
  | FLOAT_TO_INT
  | FLOAT of (float)
  | FAIL
  | EXTERN
  | EXCLAMATION
  | EQ
  | EOF
  | ELSE
  | DIVIDE
  | DELETE
  | DEFEQ
  | DEFAULT
  | COMMA
  | COLON
  | CASE
  | CARET
  | BOOLEAN of (bool)
  | ATSIGN
  | ASSERT
  | AMPERSAND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val entry_stmt_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.Stmt.t)

val entry_prog_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.Prog.t)

val entry_func_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.Func.t)

val entry_expr_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.Expr.t)

module MenhirInterpreter : sig
  
  (* The incremental API. *)
  
  include MenhirLib.IncrementalEngine.INCREMENTAL_ENGINE
    with type token = token
  
end

(* The entry point(s) to the incremental API. *)

module Incremental : sig
  
  val entry_stmt_target: Lexing.position -> (EslSyntax.Stmt.t) MenhirInterpreter.checkpoint
  
  val entry_prog_target: Lexing.position -> (EslSyntax.Prog.t) MenhirInterpreter.checkpoint
  
  val entry_func_target: Lexing.position -> (EslSyntax.Func.t) MenhirInterpreter.checkpoint
  
  val entry_expr_target: Lexing.position -> (EslSyntax.Expr.t) MenhirInterpreter.checkpoint
  
end
