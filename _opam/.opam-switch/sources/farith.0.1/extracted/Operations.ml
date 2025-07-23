open BinInt
open Defs
open Zaux

(** val coq_Falign :
    radix -> float -> float ->
    (Farith_Big.big_int * Farith_Big.big_int) * Farith_Big.big_int **)

let coq_Falign beta f1 f2 =
  let { coq_Fnum = m1; coq_Fexp = e1 } = f1 in
  let { coq_Fnum = m2; coq_Fexp = e2 } = f2 in
  if Farith_Big.le e1 e2
  then ((m1,
         (Farith_Big.mult m2 (Z.pow (radix_val beta) (Farith_Big.sub e2 e1)))),
         e1)
  else (((Farith_Big.mult m1 (Z.pow (radix_val beta) (Farith_Big.sub e1 e2))),
         m2), e2)

(** val coq_Fplus : radix -> float -> float -> float **)

let coq_Fplus beta f1 f2 =
  let (p, e) = coq_Falign beta f1 f2 in
  let (m1, m2) = p in { coq_Fnum = (Farith_Big.add m1 m2); coq_Fexp = e }

(** val coq_Fmult : radix -> float -> float -> float **)

let coq_Fmult _ f1 f2 =
  let { coq_Fnum = m1; coq_Fexp = e1 } = f1 in
  let { coq_Fnum = m2; coq_Fexp = e2 } = f2 in
  { coq_Fnum = (Farith_Big.mult m1 m2); coq_Fexp = (Farith_Big.add e1 e2) }
