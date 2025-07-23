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

(** val coq_SF2B :
    Farith_Big.big_int -> Farith_Big.big_int -> spec_float -> binary_float **)

let coq_SF2B _ _ = function
| S754_zero s -> B754_zero s
| S754_infinity s -> B754_infinity s
| S754_nan -> B754_nan
| S754_finite (s, m, e) -> B754_finite (s, m, e)

(** val coq_B2SF :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> spec_float **)

let coq_B2SF _ _ = function
| B754_zero s -> S754_zero s
| B754_infinity s -> S754_infinity s
| B754_nan -> S754_nan
| B754_finite (s, m, e) -> S754_finite (s, m, e)

(** val coq_Bsign :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> bool **)

let coq_Bsign _ _ = function
| B754_zero s -> s
| B754_infinity s -> s
| B754_nan -> false
| B754_finite (s, _, _) -> s

(** val is_nan :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> bool **)

let is_nan _ _ = function
| B754_nan -> true
| _ -> false

(** val coq_Bopp :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float **)

let coq_Bopp _ _ x = match x with
| B754_zero sx -> B754_zero (Stdlib.not sx)
| B754_infinity sx -> B754_infinity (Stdlib.not sx)
| B754_nan -> x
| B754_finite (sx, mx, ex) -> B754_finite ((Stdlib.not sx), mx, ex)

(** val coq_Babs :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float **)

let coq_Babs _ _ x = match x with
| B754_zero _ -> B754_zero false
| B754_infinity _ -> B754_infinity false
| B754_nan -> x
| B754_finite (_, mx, ex) -> B754_finite (false, mx, ex)

(** val coq_Beqb :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float
    -> bool **)

let coq_Beqb prec emax f1 f2 =
  coq_SFeqb (coq_B2SF prec emax f1) (coq_B2SF prec emax f2)

(** val coq_Bltb :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float
    -> bool **)

let coq_Bltb prec emax f1 f2 =
  coq_SFltb (coq_B2SF prec emax f1) (coq_B2SF prec emax f2)

(** val coq_Bleb :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float -> binary_float
    -> bool **)

let coq_Bleb prec emax f1 f2 =
  coq_SFleb (coq_B2SF prec emax f1) (coq_B2SF prec emax f2)

(** val choice_mode :
    Farith_Big.mode -> bool -> Farith_Big.big_int -> location ->
    Farith_Big.big_int **)

let choice_mode m sx mx lx =
  match m with
  | Farith_Big.NE -> cond_incr (round_N (Stdlib.not (Z.even mx)) lx) mx
  | Farith_Big.ZR -> mx
  | Farith_Big.DN -> cond_incr (round_sign_DN sx lx) mx
  | Farith_Big.UP -> cond_incr (round_sign_UP sx lx) mx
  | Farith_Big.NA -> cond_incr (round_N true lx) mx

(** val overflow_to_inf : Farith_Big.mode -> bool -> bool **)

let overflow_to_inf m s =
  match m with
  | Farith_Big.ZR -> false
  | Farith_Big.DN -> s
  | Farith_Big.UP -> Stdlib.not s
  | _ -> true

(** val binary_overflow :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
    spec_float **)

let binary_overflow prec emax m s =
  if overflow_to_inf m s
  then S754_infinity s
  else S754_finite (s,
         (Z.to_pos
           (Farith_Big.sub (Z.pow (Farith_Big.double Farith_Big.one) prec)
             Farith_Big.one)), (Farith_Big.sub emax prec))

(** val binary_fit_aux :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
    Farith_Big.big_int -> Farith_Big.big_int -> spec_float **)

let binary_fit_aux prec emax mode0 sx mx ex =
  if Farith_Big.le ex (Farith_Big.sub emax prec)
  then S754_finite (sx, mx, ex)
  else binary_overflow prec emax mode0 sx

(** val binary_round_aux :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
    Farith_Big.big_int -> Farith_Big.big_int -> location -> spec_float **)

let binary_round_aux prec emax mode0 sx mx ex lx =
  let (mrs', e') = shr_fexp prec emax mx ex lx in
  let (mrs'', e'') =
    shr_fexp prec emax
      (choice_mode mode0 sx mrs'.shr_m (loc_of_shr_record mrs')) e'
      Coq_loc_Exact
  in
  (Farith_Big.z_case
     (fun _ -> S754_zero sx)
     (fun m -> binary_fit_aux prec emax mode0 sx m e'')
     (fun _ -> S754_nan)
     mrs''.shr_m)

(** val coq_Bmult :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float **)

let coq_Bmult prec emax m x y =
  match x with
  | B754_zero sx ->
    (match y with
     | B754_zero sy -> B754_zero (xorb sx sy)
     | B754_finite (sy, _, _) -> B754_zero (xorb sx sy)
     | _ -> B754_nan)
  | B754_infinity sx ->
    (match y with
     | B754_infinity sy -> B754_infinity (xorb sx sy)
     | B754_finite (sy, _, _) -> B754_infinity (xorb sx sy)
     | _ -> B754_nan)
  | B754_nan -> B754_nan
  | B754_finite (sx, mx, ex) ->
    (match y with
     | B754_zero sy -> B754_zero (xorb sx sy)
     | B754_infinity sy -> B754_infinity (xorb sx sy)
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) ->
       coq_SF2B prec emax
         (binary_round_aux prec emax m (xorb sx sy) (Farith_Big.mult mx my)
           (Farith_Big.add ex ey) Coq_loc_Exact))

(** val shl_align_fexp :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int -> Farith_Big.big_int * Farith_Big.big_int **)

let shl_align_fexp prec emax mx ex =
  shl_align mx ex (fexp prec emax (Farith_Big.add (digits2_pos mx) ex))

(** val binary_round :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> bool ->
    Farith_Big.big_int -> Farith_Big.big_int -> spec_float **)

let binary_round prec emax m sx mx ex =
  let (mz, ez) = shl_align_fexp prec emax mx ex in
  binary_round_aux prec emax m sx mz ez Coq_loc_Exact

(** val binary_normalize :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    Farith_Big.big_int -> Farith_Big.big_int -> bool -> binary_float **)

let binary_normalize prec emax mode0 m e szero =
  Farith_Big.z_case
    (fun _ -> B754_zero szero)
    (fun m0 ->
    coq_SF2B prec emax (binary_round prec emax mode0 false m0 e))
    (fun m0 -> coq_SF2B prec emax (binary_round prec emax mode0 true m0 e))
    m

(** val coq_Fplus_naive :
    bool -> Farith_Big.big_int -> Farith_Big.big_int -> bool ->
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int **)

let coq_Fplus_naive sx mx ex sy my ey ez =
  Farith_Big.add (cond_Zopp sx (Stdlib.fst (shl_align mx ex ez)))
    (cond_Zopp sy (Stdlib.fst (shl_align my ey ez)))

(** val coq_Bplus :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float **)

let coq_Bplus prec emax m x y =
  match x with
  | B754_zero sx ->
    (match y with
     | B754_zero sy ->
       if eqb sx sy
       then x
       else (match m with
             | Farith_Big.DN -> B754_zero true
             | _ -> B754_zero false)
     | B754_nan -> B754_nan
     | _ -> y)
  | B754_infinity sx ->
    (match y with
     | B754_infinity sy -> if eqb sx sy then x else B754_nan
     | B754_nan -> B754_nan
     | _ -> x)
  | B754_nan -> B754_nan
  | B754_finite (sx, mx, ex) ->
    (match y with
     | B754_zero _ -> x
     | B754_infinity _ -> y
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) ->
       let ez = Farith_Big.min ex ey in
       binary_normalize prec emax m (coq_Fplus_naive sx mx ex sy my ey ez) ez
         (match m with
          | Farith_Big.DN -> true
          | _ -> false))

(** val coq_Bminus :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float **)

let coq_Bminus prec emax m x y =
  match x with
  | B754_zero sx ->
    (match y with
     | B754_zero sy ->
       if eqb sx (Stdlib.not sy)
       then x
       else (match m with
             | Farith_Big.DN -> B754_zero true
             | _ -> B754_zero false)
     | B754_infinity sy -> B754_infinity (Stdlib.not sy)
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) -> B754_finite ((Stdlib.not sy), my, ey))
  | B754_infinity sx ->
    (match y with
     | B754_infinity sy -> if eqb sx (Stdlib.not sy) then x else B754_nan
     | B754_nan -> B754_nan
     | _ -> x)
  | B754_nan -> B754_nan
  | B754_finite (sx, mx, ex) ->
    (match y with
     | B754_zero _ -> x
     | B754_infinity sy -> B754_infinity (Stdlib.not sy)
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) ->
       let ez = Farith_Big.min ex ey in
       binary_normalize prec emax m
         (coq_Fplus_naive sx mx ex (Stdlib.not sy) my ey ez) ez
         (match m with
          | Farith_Big.DN -> true
          | _ -> false))

(** val coq_Bfma_szero :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float -> bool **)

let coq_Bfma_szero prec emax m x y z =
  let s_xy = xorb (coq_Bsign prec emax x) (coq_Bsign prec emax y) in
  if eqb s_xy (coq_Bsign prec emax z)
  then s_xy
  else (match m with
        | Farith_Big.DN -> true
        | _ -> false)

(** val coq_Bfma :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float -> binary_float **)

let coq_Bfma prec emax m x y z =
  match x with
  | B754_zero _ ->
    (match y with
     | B754_zero _ ->
       (match z with
        | B754_zero _ -> B754_zero (coq_Bfma_szero prec emax m x y z)
        | B754_nan -> B754_nan
        | _ -> z)
     | B754_finite (_, _, _) ->
       (match z with
        | B754_zero _ -> B754_zero (coq_Bfma_szero prec emax m x y z)
        | B754_nan -> B754_nan
        | _ -> z)
     | _ -> B754_nan)
  | B754_infinity sx ->
    (match y with
     | B754_infinity sy ->
       let s = xorb sx sy in
       (match z with
        | B754_infinity sz -> if eqb s sz then z else B754_nan
        | B754_nan -> B754_nan
        | _ -> B754_infinity s)
     | B754_finite (sy, _, _) ->
       let s = xorb sx sy in
       (match z with
        | B754_infinity sz -> if eqb s sz then z else B754_nan
        | B754_nan -> B754_nan
        | _ -> B754_infinity s)
     | _ -> B754_nan)
  | B754_nan -> B754_nan
  | B754_finite (sx, mx, ex) ->
    (match y with
     | B754_zero _ ->
       (match z with
        | B754_zero _ -> B754_zero (coq_Bfma_szero prec emax m x y z)
        | B754_nan -> B754_nan
        | _ -> z)
     | B754_infinity sy ->
       let s = xorb sx sy in
       (match z with
        | B754_infinity sz -> if eqb s sz then z else B754_nan
        | B754_nan -> B754_nan
        | _ -> B754_infinity s)
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) ->
       (match z with
        | B754_zero _ ->
          let x0 = { coq_Fnum = (cond_Zopp sx mx); coq_Fexp = ex } in
          let y0 = { coq_Fnum = (cond_Zopp sy my); coq_Fexp = ey } in
          let { coq_Fnum = mr; coq_Fexp = er } = coq_Fmult radix2 x0 y0 in
          binary_normalize prec emax m mr er
            (coq_Bfma_szero prec emax m x y z)
        | B754_infinity _ -> z
        | B754_nan -> B754_nan
        | B754_finite (sz, mz, ez) ->
          let x0 = { coq_Fnum = (cond_Zopp sx mx); coq_Fexp = ex } in
          let y0 = { coq_Fnum = (cond_Zopp sy my); coq_Fexp = ey } in
          let z0 = { coq_Fnum = (cond_Zopp sz mz); coq_Fexp = ez } in
          let { coq_Fnum = mr; coq_Fexp = er } =
            coq_Fplus radix2 (coq_Fmult radix2 x0 y0) z0
          in
          binary_normalize prec emax m mr er
            (coq_Bfma_szero prec emax m x y z)))

(** val coq_Bdiv :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float -> binary_float **)

let coq_Bdiv prec emax m x y =
  match x with
  | B754_zero sx ->
    (match y with
     | B754_infinity sy -> B754_zero (xorb sx sy)
     | B754_finite (sy, _, _) -> B754_zero (xorb sx sy)
     | _ -> B754_nan)
  | B754_infinity sx ->
    (match y with
     | B754_zero sy -> B754_infinity (xorb sx sy)
     | B754_finite (sy, _, _) -> B754_infinity (xorb sx sy)
     | _ -> B754_nan)
  | B754_nan -> B754_nan
  | B754_finite (sx, mx, ex) ->
    (match y with
     | B754_zero sy -> B754_infinity (xorb sx sy)
     | B754_infinity sy -> B754_zero (xorb sx sy)
     | B754_nan -> B754_nan
     | B754_finite (sy, my, ey) ->
       coq_SF2B prec emax
         (let (p, lz) = coq_SFdiv_core_binary prec emax mx ex my ey in
          let (mz, ez) = p in
          binary_round_aux prec emax m (xorb sx sy) mz ez lz))

(** val coq_Bsqrt :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode ->
    binary_float -> binary_float **)

let coq_Bsqrt prec emax m x = match x with
| B754_zero _ -> x
| B754_infinity s -> if s then B754_nan else x
| B754_nan -> B754_nan
| B754_finite (sx, mx, ex) ->
  if sx
  then B754_nan
  else coq_SF2B prec emax
         (let (p, lz) = coq_SFsqrt_core_binary prec emax mx ex in
          let (mz, ez) = p in binary_round_aux prec emax m false mz ez lz)

(** val coq_Bmax_float :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float **)

let coq_Bmax_float prec emax =
  coq_SF2B prec emax (S754_finite (false,
    (Pos.sub (shift_pos (Z.to_pos prec) Farith_Big.one) Farith_Big.one),
    (Farith_Big.sub emax prec)))
