test 1:
  $ dune exec -- scfg test1.scfg
  train Shinkansen {
    model E5 {
      max-speed 320km/h
      weight 453.5t
      lines-served Tōhoku Hokkaido
    }
    model E7 {
      max-speed 275km/h
      weight 540t
      lines-served Hokuriku Jōetsu
    }
    escapetests "A random line" "abracket{line" "anotherbracket}line" 'aquote"line' "anesc\\line" "asq'line" 'adq"line' 'asinglequote"{} \line' 'asinglequote"justewithadq' "dq\"and'sq"
    emptytests "" ""
    "an escaped name" a b c
    namewithoutparam
    p "unesc\nnewline" "unesc\rcr" "unesc\ttab"
    q "new line \n" "cr \r" "tab \t"
  }
test 2:
  $ dune exec -- scfg parse_start_with_newline.scfg
  wo lo lo {
    a b c
  }
lex error 1:
  $ dune exec -- scfg lex_error.scfg
  File lex_error.scfg, line 1, character 2: unexpected lexeme `"`
  [1]
parse error 1:
  $ dune exec -- scfg parse_error1.scfg
  File parse_error1.scfg, line 1, character 2: unexpected lexeme `{`
  [1]
parse error 2:
  $ dune exec -- scfg parse_error2.scfg
  File parse_error2.scfg, line 2, character 0: unexpected token EOF
  [1]
parse error 3:
  $ dune exec -- scfg parse_error3.scfg
  File parse_error3.scfg, line 1, character 2: unexpected lexeme `}`
  [1]
parse error 4:
  $ dune exec -- scfg parse_error4.scfg
  File parse_error4.scfg, line 1, character 2: unexpected lexeme `{`
  [1]
bug 1:
  $ dune exec -- scfg bug1.scfg
  "" {
    "" {
      ""
    }
    "" {
      ""
    }
    "" ""
    ""
  }
bug 2:
  $ dune exec -- scfg bug2.scfg
  


bug 3:
  $ dune exec -- scfg bug3.scfg
  edff
