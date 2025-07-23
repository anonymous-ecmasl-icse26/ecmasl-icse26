# 1 "extracted/GenericFloat.ml"
open BinInt
open Binary
open BinarySingleNaN
open Bits
open Datatypes
open FloatClass
open Interval
open Op
open Qextended
open SpecFloat

type __ = Obj.t
let __ = let rec f _ = Obj.repr f in Obj.repr f

(** val cprec : Farith_Big.big_int -> Farith_Big.big_int **)

let cprec =
  Farith_Big.succ

(** val cemax : Farith_Big.big_int -> Farith_Big.big_int **)

let cemax ew0 =
  Z.pow (Farith_Big.double Farith_Big.one) (Farith_Big.sub ew0 Farith_Big.one)

(** val check_param : Farith_Big.big_int -> Farith_Big.big_int -> bool **)

let check_param mw0 ew0 =
  (&&)
    ((&&) (Farith_Big.lt Farith_Big.zero mw0)
      (Farith_Big.lt Farith_Big.zero ew0))
    (Farith_Big.lt (cprec mw0) (cemax ew0))

type 'v coq_Generic = { mw : Farith_Big.big_int; ew : Farith_Big.big_int;
                        value : 'v }

(** val prec : 'a1 coq_Generic -> Farith_Big.big_int **)

let prec f =
  cprec f.mw

(** val emax : 'a1 coq_Generic -> Farith_Big.big_int **)

let emax f =
  cemax f.ew

(** val mk_generic :
    Farith_Big.big_int -> Farith_Big.big_int -> (Farith_Big.big_int ->
    Farith_Big.big_int -> __ -> __ -> 'a1) -> 'a1 coq_Generic **)

let mk_generic mw0 ew0 x =
  let prec0 = cprec mw0 in
  let emax0 = cemax ew0 in
  { mw = mw0; ew = ew0; value = (x prec0 emax0 __ __) }

(** val same_format_cast :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int -> 'a1 -> 'a1 **)

let same_format_cast _ _ _ _ f =
  f

(** val same_format : 'a1 coq_Generic -> 'a2 coq_Generic -> bool **)

let same_format x y =
  (&&) (Farith_Big.eq (prec x) (prec y)) (Farith_Big.eq (emax x) (emax y))

(** val mk_with : 'a1 coq_Generic -> 'a2 -> 'a2 coq_Generic **)

let mk_with x y =
  { mw = x.mw; ew = x.ew; value = y }

(** val mk_witho : 'a1 coq_Generic -> 'a2 option -> 'a2 coq_Generic option **)

let mk_witho x = function
| Some r -> Some (mk_with x r)
| None -> None

module GenericFloat =
 struct
  module Coq__1 = struct
   type t = binary_float coq_Generic
  end
  include Coq__1

  module F_inhab =
   struct
    type t = Coq__1.t

    (** val dummy : binary_float coq_Generic **)

    let dummy =
      { mw = (Farith_Big.double (Farith_Big.double (Farith_Big.double
        (Farith_Big.succ_double Farith_Big.one)))); ew = (Farith_Big.double
        (Farith_Big.double (Farith_Big.double (Farith_Big.double
        (Farith_Big.double (Farith_Big.double (Farith_Big.double
        Farith_Big.one))))))); value = B754_nan }
   end

  module AssertF = Assert.Assert(F_inhab)

  module B_inhab =
   struct
    type t = bool

    (** val dummy : bool **)

    let dummy =
      true
   end

  module AssertB = Assert.Assert(B_inhab)

  (** val of_q' :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> Q.t ->
      binary_float **)

  let of_q' prec0 emax0 m q =
    match Q.classify q with
    | Q.INF -> B754_infinity false
    | Q.MINF -> B754_infinity true
    | Q.UNDEF -> B754_nan
    | Q.ZERO -> B754_zero false
    | Q.NZERO ->
      (Farith_Big.z_case
         (fun _ -> B754_nan)
         (fun pn ->
         coq_SF2B prec0 emax0
           (let (p, lz) =
              coq_SFdiv_core_binary prec0 emax0 pn Farith_Big.zero
                (Z.to_pos (Farith_Big.q_den q)) Farith_Big.zero
            in
            let (mz, ez) = p in
            binary_round_aux prec0 emax0 m (xorb false false) mz ez lz))
         (fun nn ->
         coq_SF2B prec0 emax0
           (let (p, lz) =
              coq_SFdiv_core_binary prec0 emax0 nn Farith_Big.zero
                (Z.to_pos (Farith_Big.q_den q)) Farith_Big.zero
            in
            let (mz, ez) = p in
            binary_round_aux prec0 emax0 m (xorb true false) mz ez lz))
         (Farith_Big.q_num q))

  (** val of_q :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> Q.t -> t **)

  let of_q mw0 ew0 m q =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ ->
      mk_generic mw0 ew0 (fun prec0 emax0 _ _ -> of_q' prec0 emax0 m q))

  (** val add : Farith_Big.mode -> t -> t -> t **)

  let add m x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      mk_with x
        (coq_Bplus (cprec x.mw) (cemax x.ew) m x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)))

  (** val sub : Farith_Big.mode -> t -> t -> t **)

  let sub m x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      mk_with x
        (coq_Bminus (cprec x.mw) (cemax x.ew) m x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)))

  (** val mul : Farith_Big.mode -> t -> t -> t **)

  let mul m x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      mk_with x
        (coq_Bmult (cprec x.mw) (cemax x.ew) m x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)))

  (** val div : Farith_Big.mode -> t -> t -> t **)

  let div m x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      mk_with x
        (coq_Bdiv (cprec x.mw) (cemax x.ew) m x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)))

  (** val fma : Farith_Big.mode -> t -> t -> t -> t **)

  let fma m x y z =
    (fun x f -> assert x; f ()) ((&&) (same_format x y) (same_format x z))
      (fun _ ->
      mk_with x
        (coq_Bfma (cprec x.mw) (cemax x.ew) m x.value
          (same_format_cast (cprec x.mw) (cemax x.ew) (cprec y.mw)
            (cemax y.ew) y.value)
          (same_format_cast (cprec x.mw) (cemax x.ew) (cprec z.mw)
            (cemax z.ew) z.value)))

  (** val sqrt : Farith_Big.mode -> t -> t **)

  let sqrt m x =
    mk_with x (coq_Bsqrt (cprec x.mw) (cemax x.ew) m x.value)

  (** val abs : t -> t **)

  let abs x =
    mk_with x (coq_Babs (cprec x.mw) (cemax x.ew) x.value)

  (** val succ : t -> t **)

  let succ x =
    mk_with x (coq_Fsucc (cprec x.mw) (cemax x.ew) x.value)

  (** val pred : t -> t **)

  let pred x =
    mk_with x (coq_Fpred (cprec x.mw) (cemax x.ew) x.value)

  (** val neg : t -> t **)

  let neg x =
    mk_with x (coq_Fneg (cprec x.mw) (cemax x.ew) x.value)

  (** val least_bit_Pnat : Farith_Big.big_int -> Farith_Big.big_int **)

  let rec least_bit_Pnat n =
    Farith_Big.positive_case
      (fun _ -> Farith_Big.zero)
      (fun p -> Farith_Big.succ (least_bit_Pnat p))
      (fun _ -> Farith_Big.zero)
      n

  (** val shiftr_pos :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

  let shiftr_pos a p =
    Farith_Big.nat_rect a (fun _ -> Farith_Big.div2_floor) p

  (** val to_q : t -> Q.t **)

  let to_q f =
    match f.value with
    | B754_zero _ -> coq_Qx_zero
    | B754_infinity b -> if b then coq_Qx_minus_inf else coq_Qx_inf
    | B754_nan -> coq_Qx_undef
    | B754_finite (b, m, e) ->
      let e' = least_bit_Pnat m in
      let m' = if b then Farith_Big.opp m else m in
      let e'' = Farith_Big.add e (Farith_Big.identity e') in
      (Farith_Big.z_case
         (fun _ -> Farith_Big.q_mk ((shiftr_pos m' e'),
         Farith_Big.one))
         (fun _ -> Farith_Big.q_mk ((Farith_Big.shiftl m' e),
         Farith_Big.one))
         (fun p -> Farith_Big.q_mk ((shiftr_pos m' e'),
         (Farith_Big.shiftl Farith_Big.one p)))
         e'')

  (** val le : t -> t -> bool **)

  let le x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      coq_Bleb (cprec x.mw) (cemax x.ew) x.value
        (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value))

  (** val lt : t -> t -> bool **)

  let lt x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      coq_Bltb (cprec x.mw) (cemax x.ew) x.value
        (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value))

  (** val eq : t -> t -> bool **)

  let eq x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      coq_Beqb (cprec x.mw) (cemax x.ew) x.value
        (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value))

  (** val ge : t -> t -> bool **)

  let ge x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      coq_Bleb (cprec x.mw) (cemax x.ew)
        (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value) x.value)

  (** val gt : t -> t -> bool **)

  let gt x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      coq_Bltb (cprec x.mw) (cemax x.ew)
        (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value) x.value)

  (** val of_bits' :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
      binary_float **)

  let of_bits' mw0 ew0 b =
    let filtered_var = binary_float_of_bits mw0 ew0 b in
    (match filtered_var with
     | Binary.B754_zero s -> B754_zero s
     | Binary.B754_infinity s -> B754_infinity s
     | Binary.B754_nan (_, _) -> B754_nan
     | Binary.B754_finite (s, m, e) -> B754_finite (s, m, e))

  (** val of_bits : Farith_Big.big_int -> Farith_Big.big_int -> Z.t -> t **)

  let of_bits mw0 ew0 z =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ -> { mw = mw0;
      ew = ew0; value = (of_bits' mw0 ew0 z) })

  (** val pl_cst : Farith_Big.big_int -> Farith_Big.big_int **)

  let pl_cst mw0 =
    Farith_Big.iter_nat (fun x -> Farith_Big.double x)
      (Z.to_nat (Farith_Big.pred mw0)) Farith_Big.one

  (** val to_bits : t -> Farith_Big.big_int **)

  let to_bits f =
    match f.value with
    | B754_zero s -> bits_of_binary_float f.mw f.ew (Binary.B754_zero s)
    | B754_infinity s ->
      bits_of_binary_float f.mw f.ew (Binary.B754_infinity s)
    | B754_nan ->
      bits_of_binary_float f.mw f.ew (Binary.B754_nan (true, (pl_cst f.mw)))
    | B754_finite (s, m, e) ->
      bits_of_binary_float f.mw f.ew (Binary.B754_finite (s, m, e))

  (** val nan : Farith_Big.big_int -> Farith_Big.big_int -> t **)

  let nan mw0 ew0 =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ ->
      mk_generic mw0 ew0 (fun _ _ _ _ -> B754_nan))

  (** val zero : Farith_Big.big_int -> Farith_Big.big_int -> bool -> t **)

  let zero mw0 ew0 b =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ ->
      mk_generic mw0 ew0 (fun _ _ _ _ -> B754_zero b))

  (** val inf : Farith_Big.big_int -> Farith_Big.big_int -> bool -> t **)

  let inf mw0 ew0 b =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ ->
      mk_generic mw0 ew0 (fun _ _ _ _ -> B754_infinity b))

  (** val classify : binary_float coq_Generic -> float_class **)

  let classify f =
    match f.value with
    | B754_zero s -> if s then NZero else PZero
    | B754_infinity s -> if s then NInf else PInf
    | B754_nan -> NaN
    | B754_finite (s, m, _) ->
      if s
      then if Farith_Big.eq (digits2_pos m) (Z.to_pos (prec f))
           then NNormal
           else NSubn
      else if Farith_Big.eq (digits2_pos m) (Z.to_pos (prec f))
           then PNormal
           else PSubn
 end

module GenericInterval =
 struct
  module Coq__2 = struct
   type t = coq_Interval coq_Generic
  end
  include Coq__2

  module I_inhab =
   struct
    type t = Coq__2.t

    (** val dummy : t **)

    let dummy =
      { mw = (Farith_Big.succ_double (Farith_Big.succ_double
        (Farith_Big.succ_double (Farith_Big.double Farith_Big.one)))); ew =
        (Farith_Big.double (Farith_Big.double (Farith_Big.double
        Farith_Big.one))); value = (Intv ((B754_infinity true),
        (B754_infinity false), true)) }
   end

  module AssertI = Assert.Assert(I_inhab)

  module O_inhab =
   struct
    type t = Coq__2.t option

    (** val dummy : t **)

    let dummy =
      None
   end

  module AssertO = Assert.Assert(O_inhab)

  (** val inter : t -> t -> t option **)

  let inter x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      let r =
        inter (prec x) (emax x) x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)
      in
      (match r with
       | Some r0 -> Some (mk_with x r0)
       | None -> None))

  (** val add : Farith_Big.mode -> t -> t -> t **)

  let add m x y =
    (fun x f -> assert x; f ()) (same_format x y) (fun _ ->
      mk_with x
        (coq_Iadd (prec x) (emax x) m x.value
          (same_format_cast (prec x) (emax x) (prec y) (emax y) y.value)))

  (** val ge : t -> t option **)

  let ge x =
    mk_witho x (coq_Ige (prec x) (emax x) x.value)

  (** val gt : t -> t option **)

  let gt x =
    mk_witho x (coq_Igt (prec x) (emax x) x.value)

  (** val le : t -> t option **)

  let le x =
    mk_witho x (coq_Ile (prec x) (emax x) x.value)

  (** val lt : t -> t option **)

  let lt x =
    mk_witho x (coq_Ilt (prec x) (emax x) x.value)

  (** val singleton : GenericFloat.t -> t **)

  let singleton x =
    mk_with x (singleton (cprec x.mw) (cemax x.ew) x.value)

  (** val is_singleton : t -> GenericFloat.t option **)

  let is_singleton x =
    mk_witho x (is_singleton (cprec x.mw) (cemax x.ew) x.value)

  (** val top : Farith_Big.big_int -> Farith_Big.big_int -> t **)

  let top mw0 ew0 =
    (fun x f -> assert x; f ()) (check_param mw0 ew0) (fun _ ->
      mk_generic mw0 ew0 (fun prec0 emax0 _ _ -> top prec0 emax0))
 end
