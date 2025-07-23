# 1 "extracted/Utils.ml"
open BinarySingleNaN

type float = binary_float

(** val coq_Bmax :
    Farith_Big.big_int -> Farith_Big.big_int -> float -> float -> float **)

let coq_Bmax prec emax f1 f2 =
  if (||) (is_nan prec emax f1) (is_nan prec emax f2)
  then B754_nan
  else if coq_Bleb prec emax f1 f2 then f2 else f1

(** val coq_Bmin :
    Farith_Big.big_int -> Farith_Big.big_int -> float -> float -> float **)

let coq_Bmin prec emax f1 f2 =
  if (||) (is_nan prec emax f1) (is_nan prec emax f2)
  then B754_nan
  else if coq_Bleb prec emax f1 f2 then f1 else f2
