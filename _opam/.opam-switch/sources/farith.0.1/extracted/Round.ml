open Datatypes
open SpecFloat

(** val cond_incr : bool -> Farith_Big.big_int -> Farith_Big.big_int **)

let cond_incr b m =
  if b then Farith_Big.add m Farith_Big.one else m

(** val round_sign_DN : bool -> location -> bool **)

let round_sign_DN s = function
| Coq_loc_Exact -> false
| Coq_loc_Inexact _ -> s

(** val round_sign_UP : bool -> location -> bool **)

let round_sign_UP s = function
| Coq_loc_Exact -> false
| Coq_loc_Inexact _ -> Stdlib.not s

(** val round_N : bool -> location -> bool **)

let round_N p = function
| Coq_loc_Exact -> false
| Coq_loc_Inexact c -> (match c with
                        | Eq -> p
                        | Lt -> false
                        | Gt -> true)
