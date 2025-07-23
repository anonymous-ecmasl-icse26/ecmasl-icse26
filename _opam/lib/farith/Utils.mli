# 1 "extracted/Utils.mli"
open BinarySingleNaN

type float = binary_float

val coq_Bmax :
  Farith_Big.big_int -> Farith_Big.big_int -> float -> float -> float

val coq_Bmin :
  Farith_Big.big_int -> Farith_Big.big_int -> float -> float -> float
