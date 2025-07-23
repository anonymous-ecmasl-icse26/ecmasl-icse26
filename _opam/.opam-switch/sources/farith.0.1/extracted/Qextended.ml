
(** val coq_Qx_zero : Q.t **)

let coq_Qx_zero =
  Farith_Big.q_mk (Farith_Big.zero, Farith_Big.one)

(** val coq_Qx_undef : Q.t **)

let coq_Qx_undef =
  Farith_Big.q_mk (Farith_Big.zero, Farith_Big.zero)

(** val coq_Qx_inf : Q.t **)

let coq_Qx_inf =
  Farith_Big.q_mk (Farith_Big.one, Farith_Big.zero)

(** val coq_Qx_minus_inf : Q.t **)

let coq_Qx_minus_inf =
  Farith_Big.q_mk ((Farith_Big.opp Farith_Big.one), Farith_Big.zero)


