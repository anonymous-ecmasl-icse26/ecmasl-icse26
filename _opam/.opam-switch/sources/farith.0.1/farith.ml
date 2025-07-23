(**************************************************************************)
(*  This file is part of FArith.                                          *)
(*                                                                        *)
(*  Copyright (C) 2015-2015                                               *)
(*    CEA (Commissariat a l'energie atomique et aux energies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  (enclosed file LGPLv2.1).                                             *)
(*                                                                        *)
(**************************************************************************)
open Base
module Format = Stdlib.Format

module Z = struct
  include Z

  let hash_fold_t s t = Base.Hash.fold_int s (hash t)
end

module Mode = struct
  type t = Farith_Big.mode = NE | ZR | DN | UP | NA
  [@@deriving eq, ord, hash, show]
end

module Classify = struct
  type t = FloatClass.float_class =
    | PNormal
    | NNormal
    | PSubn
    | NSubn
    | PZero
    | NZero
    | PInf
    | NInf
    | NaN
  [@@deriving eq, ord, hash, show]
end

type 'v generic = 'v GenericFloat.coq_Generic = {
  mw : Z.t;
  ew : Z.t;
  value : 'v;
}
[@@deriving eq, ord, hash]

module F = struct
  open GenericFloat
  include GenericFloat

  let mw t = Z.to_int t.mw
  let ew t = Z.to_int t.ew
  let pp_sign fmt b = Format.pp_print_string fmt (if b then "-" else "+")

  type binary_float = BinarySingleNaN.binary_float =
    | B754_zero of bool
    | B754_infinity of bool
    | B754_nan
    | B754_finite of bool * Z.t * Z.t
  [@@deriving eq, ord, hash]

  type t = binary_float generic [@@deriving eq, ord, hash]

  let pp_binary_float fmt (t : binary_float) =
    match t with
    | B754_zero b -> Format.fprintf fmt "%a0" pp_sign b
    | B754_infinity b -> Format.fprintf fmt "%a∞" pp_sign b
    | B754_nan -> Format.fprintf fmt "NaN"
    | B754_finite (b, m, e) ->
        let rec oddify a p =
          if Z.equal (Z.logand a Z.one) Z.zero then
            oddify (Z.shift_right_trunc a 1) (Z.succ p)
          else if Z.equal a Z.zero then (Z.zero, Z.zero)
          else (a, p)
        in
        let m, e = oddify m e in
        Format.fprintf fmt "%a%ap%a" pp_sign b Z.pp_print m Z.pp_print e

  let pp fmt t = pp_binary_float fmt t.value
  let show = Format.asprintf "%a" pp

  (** lexer for finite float *)
  let lex_float s =
    match String.index s 'p' with
    | Some k ->
        let m = String.sub s ~pos:0 ~len:k in
        let e = String.sub s ~pos:(Int.succ k) ~len:(String.length s - k - 1) in
        (Z.of_string m, Z.of_string e)
    | None -> (Z.of_string s, Z.zero)

  let of_q ~mw ~ew mode q = of_q (Z.of_int mw) (Z.of_int ew) mode q
  let of_bits ~mw ~ew z = of_bits (Z.of_int mw) (Z.of_int ew) z
  let to_bits t = to_bits t
  let nan ~mw ~ew = nan (Z.of_int mw) (Z.of_int ew)
  let zero ~mw ~ew b = zero (Z.of_int mw) (Z.of_int ew) b
  let inf ~mw ~ew b = inf (Z.of_int mw) (Z.of_int ew) b

  let round ~mw ~ew mode (f : t) : t =
    match f.value with
    | B754_zero _ | B754_infinity _ | B754_nan ->
        { mw = Z.of_int mw; ew = Z.of_int ew; value = f.value }
    | B754_finite (_, _, _) -> of_q ~mw ~ew mode (to_q f)

  let of_float f =
    of_bits ~mw:52 ~ew:11 @@ Z.extract (Z.of_int64 (Int64.bits_of_float f)) 0 64

  let to_float mode f =
    round ~mw:52 ~ew:11 mode f |> to_bits |> fun z ->
    Z.signed_extract z 0 64 |> Z.to_int64 |> Int64.float_of_bits

  let is_zero t = match t.value with B754_zero _ -> true | _ -> false
  let is_infinite t = match t.value with B754_infinity _ -> true | _ -> false
  let is_nan t = match t.value with B754_nan -> true | _ -> false

  let is_negative t =
    match t.value with
    | B754_infinity b | B754_zero b | B754_finite (b, _, _) -> b
    | B754_nan -> false

  let is_positive t =
    match t.value with
    | B754_infinity b | B754_zero b | B754_finite (b, _, _) -> not b
    | B754_nan -> false

  let is_normal t =
    match classify t with
    | FloatClass.PNormal | FloatClass.NNormal -> true
    | _ -> false

  let is_subnormal t =
    match classify t with
    | FloatClass.PSubn | FloatClass.NSubn -> true
    | _ -> false
end

module I = struct
  open GenericFloat
  include GenericInterval

  type interval = Interval.coq_Interval' =
    | Inan
    | Intv of F.binary_float * F.binary_float * bool
  [@@deriving eq, ord, hash]

  type t = interval generic [@@deriving eq, ord, hash]

  let mw t = Z.to_int t.mw
  let ew t = Z.to_int t.ew

  let pp fmt (t : t) =
    match t.value with
    | Inan -> Format.fprintf fmt "{ NaN }"
    | Intv (a, b, nan) ->
        if nan then
          Format.fprintf fmt "[%a, %a] + NaN" F.pp_binary_float a
            F.pp_binary_float b
        else
          Format.fprintf fmt "[%a, %a]" F.pp_binary_float a F.pp_binary_float b

  let top ~mw ~ew = top (Z.of_int mw) (Z.of_int ew)
end

(*
module D = struct
  type 't conf = 't Farith_F_aux.fconf
  include Farith_F_aux.D
  include Common

  let mw conf = Z.to_int (Farith_F_aux.mw conf)
  let ew conf = Z.to_int (Farith_F_aux.ew conf)

  let roundq ~mw ~ew mode q = roundq (Z.of_int mw) (Z.of_int ew) mode q

  let pp conf fmt x = pp fmt (cast_to_t conf x)

  (* let of_string conf mode s =
   *   let m,e = lex_float s in
   *   finite conf mode m e *)
end

module type S = sig

  type t
  val conf : t D.conf

  val compare: t -> t -> int
  val equal: t -> t -> bool
  val hash : t -> int

  val opp : t -> t
  val add : mode -> t -> t -> t
  val sub : mode -> t -> t -> t
  val mul : mode -> t -> t -> t
  val div : mode -> t -> t -> t
  val sqrt : mode -> t -> t
  val abs : t -> t

  val of_bits : Z.t -> t
  val to_bits : t -> Z.t

  val of_z : mode -> Z.t -> t (** Round. *)

  val of_q : mode -> Q.t -> t (** Round. *)

  val to_q : t -> Q.t (** Exact. *)

  val conv : 't D.conf -> mode -> t -> 't

  val infinity: bool -> t
  val infp : t
  val infm : t
  val zero : bool -> t
  val zerop: t
  val nan: bool -> Z.t -> t
  val default_nan: t
  val finite: mode -> Z.t -> Z.t -> t
  val classify: t -> classify

  val le  : t -> t -> bool
  val lt  : t -> t -> bool
  val ge  : t -> t -> bool
  val gt  : t -> t -> bool
  val eq  : t -> t -> bool
  val neq : t -> t -> bool

  val fcompare : t -> t -> int option

  val pp : Format.formatter -> t -> unit
  val of_string: mode -> string -> t

end

module B32 = struct include Farith_F_aux.B32 include Common

  let of_string mode s =
    let m,e = lex_float s in
    finite mode m e
end

module B64 = struct include Farith_F_aux.B64 include Common

  (** unfortunately of_bits and to_bits wants positive argument (unsigned int64)
      and Z.of_int64/Z.to_int64 wants signed argument (signed int64)
  *)
  let mask_one = Z.pred (Z.shift_left Z.one 64)
  let of_float f =
    let fb = (Big_int_Z.big_int_of_int64 (Int64.bits_of_float f)) in
    let fb = Z.logand mask_one fb in
    of_bits fb

  let mask_63 = Z.shift_left Z.one 63
  let intmask_63 = Int64.shift_left Int64.one 63
  let to_float f =
    let fb = to_bits f in
    let i = if Z.logand mask_63 fb = Z.zero then Z.to_int64 fb
      else Int64.logor intmask_63 (Z.to_int64 (Z.logxor mask_63 fb)) in
    Int64.float_of_bits i

  let of_string mode s =
    let m,e = lex_float s in
    finite mode m e

end

module type Size =
sig
  val mw : int (** mantissa size (in bits) *)

  val ew : int (** exponent size (in bits) *)
end

module Make(Size : Size) =
struct

  include Farith_F_aux.Make
      (struct
        let mw = Z.of_int Size.mw
        let ew = Z.of_int Size.ew
      end)

  include Common

  let of_string mode s =
    let m,e = lex_float s in
    finite mode m e

end
*)
let flocq_version = Version.coq_Flocq_version
