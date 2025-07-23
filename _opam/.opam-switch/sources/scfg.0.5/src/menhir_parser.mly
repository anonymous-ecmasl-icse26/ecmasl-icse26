%token<String.t> WORD
%token LBRACE
%token RBRACE
%token NEWLINE
%token EOF

%{ open Types %}

%start <Types.config> config

%%

let params ==
| ~ = list(WORD); <>

let children :=
| LBRACE; ~ = separated_list(NEWLINE, directive); RBRACE; <>
| { [] }

let directive :=
| name = WORD; ~ = params; ~ = children; {
  { name; params; children }
}

let config :=
| option(NEWLINE); ~ = separated_list(NEWLINE, directive); EOF; <>
