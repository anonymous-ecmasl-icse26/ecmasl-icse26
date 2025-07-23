# 1 "extracted/Zaux.ml"

type radix =
  Farith_Big.big_int
  (* singleton inductive, whose constructor was Build_radix *)

(** val radix_val : radix -> Farith_Big.big_int **)

let radix_val r =
  r

(** val radix2 : radix **)

let radix2 =
  (Farith_Big.double Farith_Big.one)


