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

(** Float Arithmetics (based on [Flocq] extraction) *)

module Mode : sig
  (** Supported rounding modes *)

  type t =
    | NE  (** Nearest to even *)
    | ZR  (** Toward zero *)
    | DN  (** Toward minus infinity *)
    | UP  (** Toward plus infinity *)
    | NA  (** Nearest away from zero *)
  [@@deriving eq, ord, hash, show]
end

module Classify : sig
  (** Type used for classifying floating points *)

  type t =
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

module F : sig
  type t [@@deriving eq, ord, hash, show]

  val ew : t -> int
  val mw : t -> int
  val pp : Format.formatter -> t -> unit
  val of_q : mw:int -> ew:int -> Mode.t -> Q.t -> t
  val to_q : t -> Q.t
  val add : Mode.t -> t -> t -> t
  val sub : Mode.t -> t -> t -> t
  val mul : Mode.t -> t -> t -> t
  val div : Mode.t -> t -> t -> t
  val fma : Mode.t -> t -> t -> t -> t
  val sqrt : Mode.t -> t -> t
  val abs : t -> t
  val neg : t -> t
  val pred : t -> t
  val succ : t -> t
  val of_bits : mw:int -> ew:int -> Z.t -> t
  val to_bits : t -> Z.t
  val of_float : float -> t
  val to_float : Mode.t -> t -> float
  val round : mw:int -> ew:int -> Mode.t -> t -> t
  val ge : t -> t -> bool
  val gt : t -> t -> bool
  val le : t -> t -> bool
  val lt : t -> t -> bool
  val eq : t -> t -> bool
  val nan : mw:int -> ew:int -> t

  val zero : mw:int -> ew:int -> bool -> t
  (** [zero false] is positive zero and [zero true] is negative zero *)

  val inf : mw:int -> ew:int -> bool -> t
  val is_zero : t -> bool
  val is_infinite : t -> bool
  val is_nan : t -> bool
  val is_negative : t -> bool
  val is_positive : t -> bool
  val is_normal : t -> bool
  val is_subnormal : t -> bool
  val classify : t -> Classify.t
end

module I : sig
  type t [@@deriving eq, ord, hash]

  val ew : t -> int
  val mw : t -> int
  val pp : Format.formatter -> t -> unit
  val top : mw:int -> ew:int -> t
  val inter : t -> t -> t option
  val add : Mode.t -> t -> t -> t
  val ge : t -> t option
  val gt : t -> t option
  val le : t -> t option
  val lt : t -> t option
  val singleton : F.t -> t
  val is_singleton : t -> F.t option
end

val flocq_version : Z.t

(* (\** {2 Generic Version } *\)
 * 
 * 
 * module D : sig
 * 
 *   type 't conf
 *   (\** A configuration links a mantissa and exponent size to a
 *       type which is the set of representable floating point with these sizes.
 *       A value of this type is obtained by application of {!Farith.Make}
 *   *\)
 * 
 *   val mw : 't conf -> int
 *   (\** mantissa size *\)
 * 
 *   val ew : 't conf -> int
 *   (\** exponent size *\)
 * 
 *   (\** {2 Total operators} *\)
 * 
 *   val compare: 't conf -> 't -> 't -> int
 *   val equal: 't conf -> 't -> 't -> bool
 *   val hash : 't conf -> 't -> int
 * 
 *   (\** {2 Floating point operations} *\)
 * 
 *   val opp : 't conf -> 't -> 't
 *   val add : 't conf -> Mode.t -> 't -> 't -> 't
 *   val sub : 't conf -> Mode.t -> 't -> 't -> 't
 *   val mul : 't conf -> Mode.t -> 't -> 't -> 't
 *   val div : 't conf -> Mode.t -> 't -> 't -> 't
 *   val sqrt : 't conf -> Mode.t -> 't -> 't
 *   val abs : 't conf -> 't -> 't
 * 
 *   (\** {2 Conversions} *\)
 * 
 *   val of_bits : 't conf -> Z.t -> 't
 *   (\** Conversions from bitvector representation.
 *       The given bitvector must be positive.
 *   *\)
 * 
 *   val to_bits : 't conf -> 't -> Z.t
 *   (\** Convert the floating point to its bitvector representation *\)
 * 
 *   val of_z : 't conf -> Mode.t -> Z.t -> 't
 *   (\** Convert the integer to the nearest representable integer *\)
 * 
 *   val of_q : 't conf -> Mode.t -> Q.t -> 't
 *   (\** Convert the rational to the nearest representable integer. *\)
 * 
 *   val to_q : 't conf -> 't -> Q.t
 *   (\** Convert the floating-point to its rational representation. *\)
 * 
 *   val conv : 't1 conf -> 't2 conf -> Mode.t -> 't1 -> 't2
 *   (\** Convert the floating point to the nearest representable floating point
 *       having another mantissa and exponent size. *\)
 * 
 *   val roundq : mw:int -> ew:int -> Mode.t -> Q.t -> Q.t
 *   (\** Round the given rational to the nearest representable floating
 *       point with the mantissa width [mw] and exponent width [ew] using
 *       the rounding Mode.t [Mode.t].
 *   *\)
 * 
 *   (\** {2 Floating point constants} *\)
 *   val infinity: 't conf -> bool -> 't
 *   (\** create infinity floating point (true negative, false positive) *\)
 * 
 *   val infp : 't conf -> 't
 *   (\** positive infinity *\)
 * 
 *   val infm : 't conf -> 't
 *   (\** minus infinity *\)
 * 
 *   val zero : 't conf -> bool -> 't
 *   (\** create zero floating point (true negative, false positive) *\)
 * 
 *   val zerop: 't conf -> 't
 *   (\** positive zero *\)
 * 
 *   val nan: 't conf -> bool -> Z.t -> 't
 *   (\** create a nan with the given payload. The payload must fit in the
 *       mantissa *\)
 * 
 *   val default_nan: 't conf -> 't
 * 
 *   val finite: 't conf -> Mode.t -> Z.t -> Z.t -> 't
 *   (\** [finite conf Mode.t m e] return the rounded floating point
 *       corresponding to m*2^e. Beware of the result can be classified
 *       not only as finite but also as infinite or zero because of the
 *       rounding.
 *   *\)
 * 
 *   val classify: 't conf -> 't -> classify
 *   (\** Classify the floating point according to its kind *\)
 * 
 *   (\** {3 IEEE Comparison}
 * 
 *       Respect IEEE behavior for NaN
 *   *\)
 * 
 *   val le  : 't conf -> 't -> 't -> bool
 *   val lt  : 't conf -> 't -> 't -> bool
 *   val ge  : 't conf -> 't -> 't -> bool
 *   val gt  : 't conf -> 't -> 't -> bool
 *   val eq  : 't conf -> 't -> 't -> bool
 *   val neq : 't conf -> 't -> 't -> bool
 * 
 *   val fcompare : 't conf -> 't -> 't -> int option
 *   (\** return None in the undefined cases (one of the argument is NaN) *\)
 * 
 *   (\** {3 Formatting}
 * 
 *       Format is [<m>[p<e>]] where [<m>] is a signed decimal integer
 *       and [p<e>] an optional exponent in power of 2.
 *       For instance [to_string (of_string "24p-1")] is ["3p2"].
 *   *\)
 * 
 *   val pp : 't conf -> Format.formatter -> 't -> unit
 * end
 * 
 * (\** {2 Functorized Version} *\)
 * 
 * 
 * module type S = sig
 *   type t
 * 
 *   val conf : t D.conf
 *   (\** The configuration for this type of floating-point *\)
 * 
 *   (\** {2 Total operators} *\)
 * 
 *   val compare: t -> t -> int
 *   val equal: t -> t -> bool
 *   val hash : t -> int
 * 
 *   (\** {2 Floating point operations} *\)
 * 
 *   val opp : t -> t
 *   val add : Mode.t -> t -> t -> t
 *   val sub : Mode.t -> t -> t -> t
 *   val mul : Mode.t -> t -> t -> t
 *   val div : Mode.t -> t -> t -> t
 *   val sqrt : Mode.t -> t -> t
 *   val abs : t -> t
 * 
 *   (\** {2 conversions} *\)
 * 
 *   val of_bits : Z.t -> t
 *   (\** Conversions from bitvector representation.
 *       The given bitvector must be positive.
 *   *\)
 * 
 *   val to_bits : t -> Z.t
 *   (\** Convert the floating point to its bitvector representation *\)
 * 
 *   val of_z : Mode.t -> Z.t -> t
 *   (\** Convert the integer to the nearest representable integer *\)
 * 
 *   val of_q : Mode.t -> Q.t -> t
 *   (\** Convert the rational to the nearest representable integer. *\)
 * 
 *   val to_q : t -> Q.t
 *   (\** Convert the floating-point to its rational representation. *\)
 * 
 *   val conv : 't D.conf -> Mode.t -> t -> 't
 *   (\** Convert the floating point to the nearest representable floating point
 *       having another mantissa and exponent size. *\)
 * 
 *   (\** {2 Floating point constants} *\)
 *   val infinity: bool -> t
 *   (\** create infinity floating point (true negative, false positive) *\)
 * 
 *   val infp : t
 *   (\** positive infinity *\)
 * 
 *   val infm : t
 *   (\** minus infinity *\)
 * 
 *   val zero : bool -> t
 *   (\** create zero floating point (true negative, false positive) *\)
 * 
 *   val zerop: t
 *   (\** positive zero *\)
 * 
 *   val nan: bool -> Z.t -> t
 *   (\** create a nan with the given payload. The payload must fit in the
 *       mantissa *\)
 * 
 *   val default_nan: t
 * 
 *   val finite: Mode.t -> Z.t -> Z.t -> t
 *   (\** [finite conf Mode.t m e] return the rounded floating point
 *       corresponding to m*2^e. Beware of the result can be classified
 *       not only as finite but also as infinite or zero because of the
 *       rounding. *\)
 * 
 *   val classify: t -> classify
 *   (\** Classify the floating point according to its kind *\)
 * 
 *   (\** {3 IEEE Comparison}
 * 
 *       Respect IEEE behavior for NaN
 *   *\)
 * 
 *   val le  : t -> t -> bool
 *   val lt  : t -> t -> bool
 *   val ge  : t -> t -> bool
 *   val gt  : t -> t -> bool
 *   val eq  : t -> t -> bool
 *   val neq : t -> t -> bool
 * 
 *   val fcompare : t -> t -> int option
 *   (\** return None in the undefined cases (one of the argument is NaN) *\)
 * 
 * 
 *   (\** {3 Formatting}
 * 
 *       Format is [<m>[p<e>]] where [<m>] is a signed decimal integer
 *       and [p<e>] an optional exponent in power of 2.
 *       For instance [to_string (of_string "24p-1")] is ["3p2"].
 *   *\)
 * 
 *   val pp : Format.formatter -> t -> unit
 * 
 * 
 *   val of_string: Mode.t -> string -> t
 *   (\** convert string of the shape "[-+][0-9]+p[-+][0-9]+" or "[-+][0-9]+"
 *       to a floating point using the given rounding *\)
 * end
 * 
 * module type Size =
 * sig
 *   val mw : int
 *   (\** mantissa size (in bits) *\)
 * 
 *   val ew : int
 *   (\** exponent size (in bits) *\)
 * end
 * 
 * module Make (Size : Size) : S
 * 
 * (\** {2 Already Applied Versions } *\)
 * 
 * (\** Simple  (mw = 23 ew = 8) *\)
 * module B32 : S
 * 
 * (\** Double (mw = 52 ew = 11) *\)
 * module B64 : sig
 *   include S
 * 
 *   (\** {3 Exact conversion from/to OCaml floats} *\)
 *   val of_float : float -> t
 *   val to_float : t -> float
 * 
 * end
 * 
 * val flocq_version: Z.t *)
