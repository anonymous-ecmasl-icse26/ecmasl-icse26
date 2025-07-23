open BinInt
open Defs
open Zaux

val coq_Falign :
  radix -> float -> float ->
  (Farith_Big.big_int * Farith_Big.big_int) * Farith_Big.big_int

val coq_Fplus : radix -> float -> float -> float

val coq_Fmult : radix -> float -> float -> float
