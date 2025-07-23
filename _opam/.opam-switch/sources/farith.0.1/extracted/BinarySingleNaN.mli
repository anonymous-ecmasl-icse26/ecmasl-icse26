open BinInt
open BinPos
open Bool
open Datatypes
open Defs
open Operations
open Round
open SpecFloat
open Zaux
open Zpower

type binary_float =
| B754_zero of bool
| B754_infinity of bool
| B754_nan
| B754_finite of bool * Farith_Big.big_int * Farith_Big.big_int

val coq_SF2B :
  Farith_Big.big_int -> Farith_Big.big_int -> spec_float -> binary_float

val coq_B2SF :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> spec_float

val coq_Bsign :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> bool

val is_nan : Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> bool

val coq_Bopp :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float

val coq_Babs :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float

val coq_Beqb :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float ->
  bool

val coq_Bltb :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float ->
  bool

val coq_Bleb :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float ->
  bool

val choice_mode :
  Farith_Big.mode -> bool -> Farith_Big.big_int -> location ->
  Farith_Big.big_int

val overflow_to_inf : Farith_Big.mode -> bool -> bool

val binary_overflow :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
  spec_float

val binary_fit_aux :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
  Farith_Big.big_int -> Farith_Big.big_int -> spec_float

val binary_round_aux :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
  Farith_Big.big_int -> Farith_Big.big_int -> location -> spec_float

val coq_Bmult :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float

val shl_align_fexp :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int -> Farith_Big.big_int * Farith_Big.big_int

val binary_round :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
  Farith_Big.big_int -> Farith_Big.big_int -> spec_float

val binary_normalize :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
  Farith_Big.big_int -> Farith_Big.big_int -> bool -> binary_float

val coq_Fplus_naive :
  bool -> Farith_Big.big_int -> Farith_Big.big_int -> bool ->
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int

val coq_Bplus :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float

val coq_Bminus :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float

val coq_Bfma_szero :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float -> bool

val coq_Bfma :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float -> binary_float

val coq_Bdiv :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float -> binary_float

val coq_Bsqrt :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> binary_float
  -> binary_float

val coq_Bmax_float : Farith_Big.big_int -> Farith_Big.big_int -> binary_float
