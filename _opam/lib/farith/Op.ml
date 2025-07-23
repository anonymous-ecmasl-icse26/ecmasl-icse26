# 1 "extracted/Op.ml"
open BinInt
open BinPos
open BinarySingleNaN
open SpecFloat
open Zpower

type float = binary_float

(** val coq_Fsucc :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float **)

let coq_Fsucc prec emax x = match x with
| B754_zero _ -> B754_finite (false, Farith_Big.one, (emin prec emax))
| B754_infinity s ->
  if s then coq_Bopp prec emax (coq_Bmax_float prec emax) else x
| B754_nan -> x
| B754_finite (s, m, e) ->
  if s
  then if Farith_Big.identity (Farith_Big.eq e (emin prec emax))
       then if Farith_Big.identity (Farith_Big.lt Farith_Big.one m)
            then B754_finite (true, (Pos.pred m), e)
            else B754_zero true
       else let m0 = Farith_Big.pred m in
            if Farith_Big.identity (Farith_Big.lt (coq_Zdigits2 m0) prec)
            then B754_finite (true,
                   (Pos.sub (shift_pos (Z.to_pos prec) Farith_Big.one)
                     Farith_Big.one), (Farith_Big.sub e Farith_Big.one))
            else B754_finite (true, (Z.to_pos m0), e)
  else let m0 = Farith_Big.succ m in
       if Farith_Big.identity (Farith_Big.lt prec (digits2_pos m0))
       then if Farith_Big.identity
                 (Farith_Big.eq e (Farith_Big.sub emax prec))
            then B754_infinity false
            else B754_finite (false,
                   (Z.to_pos
                     (Farith_Big.shiftl Farith_Big.one
                       (Farith_Big.sub prec Farith_Big.one))),
                   (Farith_Big.add e Farith_Big.one))
       else B754_finite (false, m0, e)

(** val coq_Fneg :
    Farith_Big.big_int -> Farith_Big.big_int -> float -> float **)

let coq_Fneg _ _ = function
| B754_zero s -> B754_zero (Stdlib.not s)
| B754_infinity s -> B754_infinity (Stdlib.not s)
| B754_nan -> B754_nan
| B754_finite (s, m, e) -> B754_finite ((Stdlib.not s), m, e)

(** val coq_Fpred :
    Farith_Big.big_int -> Farith_Big.big_int -> float -> float **)

let coq_Fpred prec emax x =
  coq_Fneg prec emax (coq_Fsucc prec emax (coq_Fneg prec emax x))
