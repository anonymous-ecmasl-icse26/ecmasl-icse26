open BinarySingleNaN
open Utils

type float = binary_float

type coq_Interval' =
| Inan
| Intv of float * float * bool

type coq_Interval = coq_Interval'

type coq_Interval_opt = coq_Interval option

(** val to_Interval_opt :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval' option ->
    coq_Interval_opt **)

let to_Interval_opt _ _ = function
| Some j -> Some j
| None -> None

(** val top : Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval **)

let top _ _ =
  Intv ((B754_infinity true), (B754_infinity false), true)

(** val is_singleton :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> float option **)

let is_singleton prec emax = function
| Inan -> Some B754_nan
| Intv (a, b, n) ->
  if (&&)
       ((&&) (coq_Beqb prec emax a b)
         (Stdlib.not (coq_Beqb prec emax a (B754_zero false)))) (Stdlib.not n)
  then Some a
  else None

(** val singleton :
    Farith_Big.big_int -> Farith_Big.big_int -> float -> coq_Interval **)

let singleton _ _ x = match x with
| B754_nan -> Inan
| _ -> Intv (x, x, false)

(** val inter' :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval' ->
    coq_Interval' -> coq_Interval' option **)

let inter' prec emax i1 i2 =
  match i1 with
  | Inan ->
    (match i2 with
     | Inan -> Some Inan
     | Intv (_, _, nan) -> if nan then Some Inan else None)
  | Intv (lo1, hi1, nan1) ->
    (match i2 with
     | Inan -> if nan1 then Some Inan else None
     | Intv (lo2, hi2, nan2) ->
       if (||) (coq_Bltb prec emax hi1 lo2) (coq_Bltb prec emax hi2 lo1)
       then if (&&) nan1 nan2 then Some Inan else None
       else Some (Intv ((coq_Bmax prec emax lo1 lo2),
              (coq_Bmin prec emax hi1 hi2), ((&&) nan1 nan2))))

(** val inter :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval
    -> coq_Interval_opt **)

let inter prec emax i1 i2 =
  to_Interval_opt prec emax (inter' prec emax i1 i2)

(** val coq_Iadd' :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    coq_Interval' -> coq_Interval' -> coq_Interval' **)

let coq_Iadd' prec emax m i1 i2 =
  match i1 with
  | Inan -> Inan
  | Intv (l, h, n) ->
    (match i2 with
     | Inan -> Inan
     | Intv (l', h', n') ->
       let sum1 = coq_Bplus prec emax m l l' in
       let sum2 = coq_Bplus prec emax m h h' in
       if is_nan prec emax sum1
       then if is_nan prec emax sum2
            then Inan
            else Intv ((B754_infinity false), (B754_infinity false), true)
       else if is_nan prec emax sum2
            then Intv ((B754_infinity true), (B754_infinity true), true)
            else Intv (sum1, sum2,
                   ((||)
                     ((||) ((||) n n')
                       ((&&) (coq_Beqb prec emax h (B754_infinity false))
                         (coq_Beqb prec emax l' (B754_infinity true))))
                     ((&&) (coq_Beqb prec emax h' (B754_infinity false))
                       (coq_Beqb prec emax l (B754_infinity true))))))

(** val coq_Iadd :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    coq_Interval -> coq_Interval -> coq_Interval **)

let coq_Iadd =
  coq_Iadd'

(** val coq_Ile :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval ->
    coq_Interval_opt **)

let coq_Ile _ _ = function
| Inan -> None
| Intv (_, b, n) -> Some (Intv ((B754_infinity true), b, n))

(** val coq_Ilt :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval ->
    coq_Interval_opt **)

let coq_Ilt _ _ = function
| Inan -> None
| Intv (_, b, n) -> Some (Intv ((B754_infinity true), b, n))

(** val coq_Ige :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval ->
    coq_Interval_opt **)

let coq_Ige _ _ = function
| Inan -> None
| Intv (a, _, n) -> Some (Intv (a, (B754_infinity false), n))

(** val coq_Igt :
    Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval ->
    coq_Interval_opt **)

let coq_Igt _ _ = function
| Inan -> None
| Intv (a, _, n) -> Some (Intv (a, (B754_infinity false), n))
