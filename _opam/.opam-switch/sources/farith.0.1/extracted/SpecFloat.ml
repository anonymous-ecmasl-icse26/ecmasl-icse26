open BinInt
open Datatypes
open Zpower

type spec_float =
| S754_zero of bool
| S754_infinity of bool
| S754_nan
| S754_finite of bool * Farith_Big.big_int * Farith_Big.big_int

(** val emin :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

let emin prec emax =
  Farith_Big.sub
    (Farith_Big.sub (Farith_Big.succ_double Farith_Big.one) emax) prec

(** val fexp :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int **)

let fexp prec emax e =
  Farith_Big.max (Farith_Big.sub e prec) (emin prec emax)

(** val digits2_pos : Farith_Big.big_int -> Farith_Big.big_int **)

let rec digits2_pos n =
  Farith_Big.positive_case
    (fun p -> Farith_Big.succ (digits2_pos p))
    (fun p -> Farith_Big.succ (digits2_pos p))
    (fun _ -> Farith_Big.one)
    n

(** val coq_Zdigits2 : Farith_Big.big_int -> Farith_Big.big_int **)

let coq_Zdigits2 n =
  Farith_Big.z_case
    (fun _ -> n)
    (fun p -> (digits2_pos p))
    (fun p -> (digits2_pos p))
    n

(** val iter_pos : ('a1 -> 'a1) -> Farith_Big.big_int -> 'a1 -> 'a1 **)

let rec iter_pos f n x =
  Farith_Big.positive_case
    (fun n' -> iter_pos f n' (iter_pos f n' (f x)))
    (fun n' -> iter_pos f n' (iter_pos f n' x))
    (fun _ -> f x)
    n

type location =
| Coq_loc_Exact
| Coq_loc_Inexact of comparison

type shr_record = { shr_m : Farith_Big.big_int; shr_r : bool; shr_s : bool }

(** val shr_1 : shr_record -> shr_record **)

let shr_1 mrs =
  let { shr_m = m; shr_r = r; shr_s = s } = mrs in
  let s0 = (||) r s in
  (Farith_Big.z_case
     (fun _ -> { shr_m = Farith_Big.zero; shr_r = false; shr_s =
     s0 })
     (fun p0 ->
     Farith_Big.positive_case
       (fun p -> { shr_m = p; shr_r = true; shr_s = s0 })
       (fun p -> { shr_m = p; shr_r = false; shr_s = s0 })
       (fun _ -> { shr_m = Farith_Big.zero; shr_r = true; shr_s = s0 })
       p0)
     (fun p0 ->
     Farith_Big.positive_case
       (fun p -> { shr_m = (Farith_Big.opp p); shr_r = true; shr_s =
       s0 })
       (fun p -> { shr_m = (Farith_Big.opp p); shr_r = false; shr_s =
       s0 })
       (fun _ -> { shr_m = Farith_Big.zero; shr_r = true; shr_s = s0 })
       p0)
     m)

(** val loc_of_shr_record : shr_record -> location **)

let loc_of_shr_record mrs =
  let { shr_m = _; shr_r = shr_r0; shr_s = shr_s0 } = mrs in
  if shr_r0
  then if shr_s0 then Coq_loc_Inexact Gt else Coq_loc_Inexact Eq
  else if shr_s0 then Coq_loc_Inexact Lt else Coq_loc_Exact

(** val shr_record_of_loc : Farith_Big.big_int -> location -> shr_record **)

let shr_record_of_loc m = function
| Coq_loc_Exact -> { shr_m = m; shr_r = false; shr_s = false }
| Coq_loc_Inexact c ->
  (match c with
   | Eq -> { shr_m = m; shr_r = true; shr_s = false }
   | Lt -> { shr_m = m; shr_r = false; shr_s = true }
   | Gt -> { shr_m = m; shr_r = true; shr_s = true })

(** val shr :
    shr_record -> Farith_Big.big_int -> Farith_Big.big_int ->
    shr_record * Farith_Big.big_int **)

let shr mrs e n =
  Farith_Big.z_case
    (fun _ -> (mrs, e))
    (fun p -> ((iter_pos shr_1 p mrs), (Farith_Big.add e n)))
    (fun _ -> (mrs, e))
    n

(** val shr_fexp :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int -> location -> shr_record * Farith_Big.big_int **)

let shr_fexp prec emax m e l =
  shr (shr_record_of_loc m l) e
    (Farith_Big.sub (fexp prec emax (Farith_Big.add (coq_Zdigits2 m) e)) e)

(** val shl_align :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int * Farith_Big.big_int **)

let shl_align mx ex ex' =
  Farith_Big.z_case
    (fun _ -> (mx, ex))
    (fun _ -> (mx, ex))
    (fun d -> ((shift_pos d mx), ex'))
    (Farith_Big.sub ex' ex)

(** val coq_SFcompare : spec_float -> spec_float -> comparison option **)

let coq_SFcompare f1 f2 =
  match f1 with
  | S754_zero _ ->
    (match f2 with
     | S754_zero _ -> Some Eq
     | S754_infinity s -> Some (if s then Gt else Lt)
     | S754_nan -> None
     | S754_finite (s, _, _) -> Some (if s then Gt else Lt))
  | S754_infinity s ->
    (match f2 with
     | S754_infinity s0 ->
       Some (if s then if s0 then Eq else Lt else if s0 then Gt else Eq)
     | S754_nan -> None
     | _ -> Some (if s then Lt else Gt))
  | S754_nan -> None
  | S754_finite (s1, m1, e1) ->
    (match f2 with
     | S754_zero _ -> Some (if s1 then Lt else Gt)
     | S754_infinity s -> Some (if s then Gt else Lt)
     | S754_nan -> None
     | S754_finite (s2, m2, e2) ->
       Some
         (if s1
          then if s2
               then (match (Farith_Big.compare_case Eq Lt Gt) e1 e2 with
                     | Eq ->
                       coq_CompOpp
                         ((fun c x y -> Farith_Big.compare_case c Lt Gt x y)
                           Eq m1 m2)
                     | Lt -> Gt
                     | Gt -> Lt)
               else Lt
          else if s2
               then Gt
               else (match (Farith_Big.compare_case Eq Lt Gt) e1 e2 with
                     | Eq ->
                       (fun c x y -> Farith_Big.compare_case c Lt Gt x y) Eq
                         m1 m2
                     | x -> x)))

(** val coq_SFeqb : spec_float -> spec_float -> bool **)

let coq_SFeqb f1 f2 =
  match coq_SFcompare f1 f2 with
  | Some c -> (match c with
               | Eq -> true
               | _ -> false)
  | None -> false

(** val coq_SFltb : spec_float -> spec_float -> bool **)

let coq_SFltb f1 f2 =
  match coq_SFcompare f1 f2 with
  | Some c -> (match c with
               | Lt -> true
               | _ -> false)
  | None -> false

(** val coq_SFleb : spec_float -> spec_float -> bool **)

let coq_SFleb f1 f2 =
  match coq_SFcompare f1 f2 with
  | Some c -> (match c with
               | Gt -> false
               | _ -> true)
  | None -> false

(** val cond_Zopp : bool -> Farith_Big.big_int -> Farith_Big.big_int **)

let cond_Zopp b m =
  if b then Farith_Big.opp m else m

(** val new_location_even :
    Farith_Big.big_int -> Farith_Big.big_int -> location **)

let new_location_even nb_steps k =
  if Farith_Big.eq k Farith_Big.zero
  then Coq_loc_Exact
  else Coq_loc_Inexact
         ((Farith_Big.compare_case Eq Lt Gt)
           (Farith_Big.mult (Farith_Big.double Farith_Big.one) k) nb_steps)

(** val new_location_odd :
    Farith_Big.big_int -> Farith_Big.big_int -> location **)

let new_location_odd nb_steps k =
  if Farith_Big.eq k Farith_Big.zero
  then Coq_loc_Exact
  else Coq_loc_Inexact
         (match (Farith_Big.compare_case Eq Lt Gt)
                  (Farith_Big.add
                    (Farith_Big.mult (Farith_Big.double Farith_Big.one) k)
                    Farith_Big.one) nb_steps with
          | Eq -> Lt
          | x -> x)

(** val new_location :
    Farith_Big.big_int -> Farith_Big.big_int -> location **)

let new_location nb_steps =
  if Z.even nb_steps
  then new_location_even nb_steps
  else new_location_odd nb_steps

(** val coq_SFdiv_core_binary :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    (Farith_Big.big_int * Farith_Big.big_int) * location **)

let coq_SFdiv_core_binary prec emax m1 e1 m2 e2 =
  let d1 = coq_Zdigits2 m1 in
  let d2 = coq_Zdigits2 m2 in
  let e' =
    Farith_Big.min
      (fexp prec emax
        (Farith_Big.sub (Farith_Big.add d1 e1) (Farith_Big.add d2 e2)))
      (Farith_Big.sub e1 e2)
  in
  let s = Farith_Big.sub (Farith_Big.sub e1 e2) e' in
  let m' =
    Farith_Big.z_case
      (fun _ -> m1)
      (fun _ -> Farith_Big.shiftl m1 s)
      (fun _ -> Farith_Big.zero)
      s
  in
  let (q, r) = Farith_Big.div_mod_floor m' m2 in
  ((q, e'), (new_location m2 r))

(** val coq_SFsqrt_core_binary :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int -> (Farith_Big.big_int * Farith_Big.big_int) * location **)

let coq_SFsqrt_core_binary prec emax m e =
  let d = coq_Zdigits2 m in
  let e' =
    Farith_Big.min
      (fexp prec emax
        (Farith_Big.div2_floor
          (Farith_Big.add (Farith_Big.add d e) Farith_Big.one)))
      (Farith_Big.div2_floor e)
  in
  let s =
    Farith_Big.sub e (Farith_Big.mult (Farith_Big.double Farith_Big.one) e')
  in
  let m' =
    Farith_Big.z_case
      (fun _ -> m)
      (fun _ -> Farith_Big.shiftl m s)
      (fun _ -> Farith_Big.zero)
      s
  in
  let (q, r) = Farith_Big.Z.sqrt_rem m' in
  let l =
    if Farith_Big.eq r Farith_Big.zero
    then Coq_loc_Exact
    else Coq_loc_Inexact (if Farith_Big.le r q then Lt else Gt)
  in
  ((q, e'), l)
