# 1 "extracted/Op.mli"
open BinInt
open BinPos
open BinarySingleNaN
open SpecFloat
open Zpower

type float = binary_float

val coq_Fsucc :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float

val coq_Fneg : Farith_Big.big_int -> Farith_Big.big_int -> float -> float

val coq_Fpred : Farith_Big.big_int -> Farith_Big.big_int -> float -> float
