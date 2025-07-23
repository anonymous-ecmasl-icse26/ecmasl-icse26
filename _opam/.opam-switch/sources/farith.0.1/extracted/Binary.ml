
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

(** val coq_FF2B :
    Farith_Big.big_int -> Farith_Big.big_int -> full_float -> binary_float **)

let coq_FF2B _ _ = function
| F754_zero s -> B754_zero s
| F754_infinity s -> B754_infinity s
| F754_nan (b, pl) -> B754_nan (b, pl)
| F754_finite (s, m, e) -> B754_finite (s, m, e)
