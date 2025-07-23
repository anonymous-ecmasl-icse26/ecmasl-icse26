# 1 "extracted/Bits.ml"
open BinInt
open Binary
open SpecFloat

(** val join_bits :
    Farith_Big.big_int -> Farith_Big.big_int -> bool -> Farith_Big.big_int ->
    Farith_Big.big_int -> Farith_Big.big_int **)

let join_bits mw ew s m e =
  Farith_Big.add
    (Farith_Big.shiftl
      (Farith_Big.add
        (if s
         then Z.pow (Farith_Big.double Farith_Big.one) ew
         else Farith_Big.zero) e) mw) m

(** val split_bits :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    (bool * Farith_Big.big_int) * Farith_Big.big_int **)

let split_bits mw ew x =
  let mm = Z.pow (Farith_Big.double Farith_Big.one) mw in
  let em = Z.pow (Farith_Big.double Farith_Big.one) ew in
  (((Farith_Big.le (Farith_Big.mult mm em) x), (Farith_Big.mod_floor x mm)),
  (Farith_Big.mod_floor (Farith_Big.div_floor x mm) em))

(** val bits_of_binary_float :
    Farith_Big.big_int -> Farith_Big.big_int -> binary_float ->
    Farith_Big.big_int **)

let bits_of_binary_float mw ew =
  let prec = Farith_Big.add mw Farith_Big.one in
  let emax =
    Z.pow (Farith_Big.double Farith_Big.one)
      (Farith_Big.sub ew Farith_Big.one)
  in
  (fun x ->
  match x with
  | B754_zero sx -> join_bits mw ew sx Farith_Big.zero Farith_Big.zero
  | B754_infinity sx ->
    join_bits mw ew sx Farith_Big.zero
      (Farith_Big.sub (Z.pow (Farith_Big.double Farith_Big.one) ew)
        Farith_Big.one)
  | B754_nan (sx, plx) ->
    join_bits mw ew sx plx
      (Farith_Big.sub (Z.pow (Farith_Big.double Farith_Big.one) ew)
        Farith_Big.one)
  | B754_finite (sx, mx, ex) ->
    let m = Farith_Big.sub mx (Z.pow (Farith_Big.double Farith_Big.one) mw) in
    if Farith_Big.le Farith_Big.zero m
    then join_bits mw ew sx m
           (Farith_Big.add (Farith_Big.sub ex (emin prec emax))
             Farith_Big.one)
    else join_bits mw ew sx mx Farith_Big.zero)

(** val binary_float_of_bits_aux :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    full_float **)

let binary_float_of_bits_aux mw ew =
  let prec = Farith_Big.add mw Farith_Big.one in
  let emax =
    Z.pow (Farith_Big.double Farith_Big.one)
      (Farith_Big.sub ew Farith_Big.one)
  in
  (fun x ->
  let (p, ex) = split_bits mw ew x in
  let (sx, mx) = p in
  if Farith_Big.eq ex Farith_Big.zero
  then (Farith_Big.z_case
          (fun _ -> F754_zero sx)
          (fun px -> F754_finite (sx, px, (emin prec emax)))
          (fun _ -> F754_nan (false, Farith_Big.one))
          mx)
  else if Farith_Big.eq ex
            (Farith_Big.sub (Z.pow (Farith_Big.double Farith_Big.one) ew)
              Farith_Big.one)
       then (Farith_Big.z_case
               (fun _ -> F754_infinity sx)
               (fun plx -> F754_nan (sx, plx))
               (fun _ -> F754_nan (false, Farith_Big.one))
               mx)
       else (Farith_Big.z_case
               (fun _ -> F754_nan (false, Farith_Big.one))
               (fun px -> F754_finite (sx, px,
               (Farith_Big.sub (Farith_Big.add ex (emin prec emax))
                 Farith_Big.one)))
               (fun _ -> F754_nan (false,
               Farith_Big.one))
               (Farith_Big.add mx
                 (Z.pow (Farith_Big.double Farith_Big.one) mw))))

(** val binary_float_of_bits :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    binary_float **)

let binary_float_of_bits mw ew x =
  let prec = Farith_Big.add mw Farith_Big.one in
  let emax =
    Z.pow (Farith_Big.double Farith_Big.one)
      (Farith_Big.sub ew Farith_Big.one)
  in
  coq_FF2B prec emax (binary_float_of_bits_aux mw ew x)
