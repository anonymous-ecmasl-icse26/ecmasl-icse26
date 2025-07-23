# 1 "extracted/Binary.mli"

type full_float =
| F754_zero of bool
| F754_infinity of bool
| F754_nan of bool * Farith_Big.big_int
| F754_finite of bool * Farith_Big.big_int * Farith_Big.big_int

type binary_float =
| B754_zero of bool
| B754_infinity of bool
| B754_nan of bool * Farith_Big.big_int
| B754_finite of bool * Farith_Big.big_int * Farith_Big.big_int

val coq_FF2B :
  Farith_Big.big_int -> Farith_Big.big_int -> full_float -> binary_float
