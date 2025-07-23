# 1 "extracted/SpecFloat.mli"
open BinInt
open Datatypes
open Zpower

type spec_float =
| S754_zero of bool
| S754_infinity of bool
| S754_nan
| S754_finite of bool * Farith_Big.big_int * Farith_Big.big_int

val emin : Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int

val fexp :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int

val digits2_pos : Farith_Big.big_int -> Farith_Big.big_int

val coq_Zdigits2 : Farith_Big.big_int -> Farith_Big.big_int

val iter_pos : ('a1 -> 'a1) -> Farith_Big.big_int -> 'a1 -> 'a1

type location =
| Coq_loc_Exact
| Coq_loc_Inexact of comparison

type shr_record = { shr_m : Farith_Big.big_int; shr_r : bool; shr_s : bool }

val shr_1 : shr_record -> shr_record

val loc_of_shr_record : shr_record -> location

val shr_record_of_loc : Farith_Big.big_int -> location -> shr_record

val shr :
  shr_record -> Farith_Big.big_int -> Farith_Big.big_int ->
  shr_record * Farith_Big.big_int

val shr_fexp :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int -> location -> shr_record * Farith_Big.big_int

val shl_align :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int * Farith_Big.big_int

val coq_SFcompare : spec_float -> spec_float -> comparison option

val coq_SFeqb : spec_float -> spec_float -> bool

val coq_SFltb : spec_float -> spec_float -> bool

val coq_SFleb : spec_float -> spec_float -> bool

val cond_Zopp : bool -> Farith_Big.big_int -> Farith_Big.big_int

val new_location_even : Farith_Big.big_int -> Farith_Big.big_int -> location

val new_location_odd : Farith_Big.big_int -> Farith_Big.big_int -> location

val new_location : Farith_Big.big_int -> Farith_Big.big_int -> location

val coq_SFdiv_core_binary :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  (Farith_Big.big_int * Farith_Big.big_int) * location

val coq_SFsqrt_core_binary :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  Farith_Big.big_int -> (Farith_Big.big_int * Farith_Big.big_int) * location
