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

val cprec : Farith_Big.big_int -> Farith_Big.big_int

val cemax : Farith_Big.big_int -> Farith_Big.big_int

val check_param : Farith_Big.big_int -> Farith_Big.big_int -> bool

type 'v coq_Generic = { mw : Farith_Big.big_int; ew : Farith_Big.big_int;
                        value : 'v }

val prec : 'a1 coq_Generic -> Farith_Big.big_int

val emax : 'a1 coq_Generic -> Farith_Big.big_int

val mk_generic :
  Farith_Big.big_int -> Farith_Big.big_int -> (Farith_Big.big_int ->
  Farith_Big.big_int -> __ -> __ -> 'a1) -> 'a1 coq_Generic

val same_format_cast :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int -> 'a1 -> 'a1

val same_format : 'a1 coq_Generic -> 'a2 coq_Generic -> bool

val mk_with : 'a1 coq_Generic -> 'a2 -> 'a2 coq_Generic

val mk_witho : 'a1 coq_Generic -> 'a2 option -> 'a2 coq_Generic option

module GenericFloat :
 sig
  module Coq__1 : sig
   type t = binary_float coq_Generic
  end
  include module type of struct include Coq__1 end

  module F_inhab :
   sig
    type t = Coq__1.t

    val dummy : binary_float coq_Generic
   end

  module AssertF :
   sig
   end

  module B_inhab :
   sig
    type t = bool

    val dummy : bool
   end

  module AssertB :
   sig
   end

  val of_q' :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> Q.t ->
    binary_float

  val of_q :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.mode -> Q.t -> t

  val add : Farith_Big.mode -> t -> t -> t

  val sub : Farith_Big.mode -> t -> t -> t

  val mul : Farith_Big.mode -> t -> t -> t

  val div : Farith_Big.mode -> t -> t -> t

  val fma : Farith_Big.mode -> t -> t -> t -> t

  val sqrt : Farith_Big.mode -> t -> t

  val abs : t -> t

  val succ : t -> t

  val pred : t -> t

  val neg : t -> t

  val least_bit_Pnat : Farith_Big.big_int -> Farith_Big.big_int

  val shiftr_pos :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int

  val to_q : t -> Q.t

  val le : t -> t -> bool

  val lt : t -> t -> bool

  val eq : t -> t -> bool

  val ge : t -> t -> bool

  val gt : t -> t -> bool

  val of_bits' :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
    binary_float

  val of_bits : Farith_Big.big_int -> Farith_Big.big_int -> Z.t -> t

  val pl_cst : Farith_Big.big_int -> Farith_Big.big_int

  val to_bits : t -> Farith_Big.big_int

  val nan : Farith_Big.big_int -> Farith_Big.big_int -> t

  val zero : Farith_Big.big_int -> Farith_Big.big_int -> bool -> t

  val inf : Farith_Big.big_int -> Farith_Big.big_int -> bool -> t

  val classify : binary_float coq_Generic -> float_class
 end

module GenericInterval :
 sig
  module Coq__2 : sig
   type t = coq_Interval coq_Generic
  end
  include module type of struct include Coq__2 end

  module I_inhab :
   sig
    type t = Coq__2.t

    val dummy : t
   end

  module AssertI :
   sig
   end

  module O_inhab :
   sig
    type t = Coq__2.t option

    val dummy : t
   end

  module AssertO :
   sig
   end

  val inter : t -> t -> t option

  val add : Farith_Big.mode -> t -> t -> t

  val ge : t -> t option

  val gt : t -> t option

  val le : t -> t option

  val lt : t -> t option

  val singleton : GenericFloat.t -> t

  val is_singleton : t -> GenericFloat.t option

  val top : Farith_Big.big_int -> Farith_Big.big_int -> t
 end
