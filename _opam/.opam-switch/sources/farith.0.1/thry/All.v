(** * A list of all submodules of Farith2 *)

(** Usefull facts about floating points *)
From F Require Import Utils.

(** An extension of [R] including infinite values
  together with a new semantic for floating points
*)
From F Require Import Rextended.

(** An extension of [Q] including infinite values
  used to write the specifications of conversions from [Q] to [float]
  and from [float] to [Q]
*)
From F Require Import Qextended.

(** Correction lemmas associated to floating point binary operators *)
From F Require Import Utils.

(** A 32 bits instanciation of Flocq's [BinarySingleNaN] *)
From F Require Import B32.

(** Generic float intervals with verified propagators *)
From F Require Import Interval.

(** A 32 bits instanciation of [Interval] *)
From F Require Import Intv32.