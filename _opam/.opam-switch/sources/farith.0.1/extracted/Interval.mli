open BinarySingleNaN
open Utils

type float = binary_float

type coq_Interval' =
| Inan
| Intv of float * float * bool

type coq_Interval = coq_Interval'

type coq_Interval_opt = coq_Interval option

val to_Interval_opt :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval' option ->
  coq_Interval_opt

val top : Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval

val is_singleton :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> float option

val singleton :
  Farith_Big.big_int -> Farith_Big.big_int -> float -> coq_Interval

val inter' :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval' -> coq_Interval'
  -> coq_Interval' option

val inter :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval ->
  coq_Interval_opt

val coq_Iadd' :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
  coq_Interval' -> coq_Interval' -> coq_Interval'

val coq_Iadd :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> coq_Interval
  -> coq_Interval -> coq_Interval

val coq_Ile :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval_opt

val coq_Ilt :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval_opt

val coq_Ige :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval_opt

val coq_Igt :
  Farith_Big.big_int -> Farith_Big.big_int -> coq_Interval -> coq_Interval_opt
