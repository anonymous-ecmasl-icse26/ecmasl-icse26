
(* The type of tokens. *)

type token = 
  | WITH
  | WHILE
  | UNTIL
  | TYPE_VOID
  | TYPE_UNKNOWN
  | TYPE_UNDEFINED
  | TYPE_SYMBOL
  | TYPE_STRING
  | TYPE_SIGMA
  | TYPE_NEVER
  | TYPE_INT
  | TYPE_FLOAT
  | TYPE_BOOLEAN
  | TYPE_ANY
  | TYPEOF
  | TYPEDEF
  | TIMES
  | TILDE
  | THROW
  | SYMBOL of (string)
  | SWITCH
  | STRING_TO_INT
  | STRING_TO_FLOAT
  | STRING of (string)
  | SHIFT_RIGHT_LOGICAL
  | SHIFT_RIGHT
  | SHIFT_LEFT
  | SEMICOLON
  | SCLOR
  | SCLAND
  | RPAREN
  | RETURN
  | REPEAT
  | RBRACK
  | RBRACE
  | QUESTION
  | PRINT
  | POW
  | PLUS
  | PIPE
  | PERIOD
  | OBJECT_TO_LIST
  | OBJECT_MEM
  | OBJECT_FIELDS
  | NULL
  | NONE
  | NE
  | MODULO
  | MINUS
  | MATCH
  | MACRO
  | LT
  | LPAREN
  | LOR
  | LIST_TAIL
  | LIST_HEAD
  | LET
  | LE
  | LBRACK
  | LBRACE
  | LAND
  | LAMBDA
  | INT_TO_STRING
  | INT_TO_FLOAT
  | INT of (int)
  | IMPORT
  | IF
  | ID of (string)
  | HASH
  | GT
  | GID of (string)
  | GE
  | FUNCTION
  | FOREACH
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
  | DEFEQ0
  | DEFEQ
  | DEFAULT
  | COMMA
  | COLON
  | CATCH
  | CASE
  | CARET
  | BOOLEAN of (bool)
  | BEFORE
  | ATSIGN
  | ASSERT
  | ARROW
  | AMPERSAND
  | AFTER
  | ADVICE

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val entry_type_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.EType.t)

val entry_stmt_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.EStmt.t)

val entry_prog_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.EProg.t)

val entry_func_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.EFunc.t)

val entry_expr_target: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (EslSyntax.EExpr.t)

module MenhirInterpreter : sig
  
  (* The incremental API. *)
  
  include MenhirLib.IncrementalEngine.INCREMENTAL_ENGINE
    with type token = token
  
end

(* The entry point(s) to the incremental API. *)

module Incremental : sig
  
  val entry_type_target: Lexing.position -> (EslSyntax.EType.t) MenhirInterpreter.checkpoint
  
  val entry_stmt_target: Lexing.position -> (EslSyntax.EStmt.t) MenhirInterpreter.checkpoint
  
  val entry_prog_target: Lexing.position -> (EslSyntax.EProg.t) MenhirInterpreter.checkpoint
  
  val entry_func_target: Lexing.position -> (EslSyntax.EFunc.t) MenhirInterpreter.checkpoint
  
  val entry_expr_target: Lexing.position -> (EslSyntax.EExpr.t) MenhirInterpreter.checkpoint
  
end
