# 1 "extracted/Datatypes.mli"

val xorb : bool -> bool -> bool

type comparison =
| Eq
| Lt
| Gt

val coq_CompOpp : comparison -> comparison
