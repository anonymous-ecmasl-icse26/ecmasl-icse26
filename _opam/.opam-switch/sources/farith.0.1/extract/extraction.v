From Flocq Require Import Core.Zaux IEEE754.BinarySingleNaN IEEE754.Bits Version.
From Farith Require Import Qextended GenericFloat.
From Coq Require Import Extraction Lia Arith.Wf_nat ZArith.

(* Goal (Beqb (B32.add mode_NE (B32.of_q mode_NE Qx_half) (B32.of_q mode_NE Qx_half)) (B32.of_q mode_NE Qx_one) = true). *)
(* Proof. *)
(*   cbn. *)
(*   reflexivity. *)
(* Qed. *)

(* Goal (Beqb (B32.div mode_NE (B32.of_q mode_NE Qx_one) (B32.of_q mode_NE Qx_two)) (B32.of_q mode_NE Qx_half) = true). *)
(* Proof. *)
(*   cbn. *)
(*   reflexivity. *)
(* Qed. *)

Require Import Sumbool.

Extract Inlined Constant bool_of_sumbool => "Farith_Big.identity".
Extract Inlined Constant sumbool_of_bool => "Farith_Big.identity".


(** From ExtrOcamlNatBigInt of coq archive *)

Require Import Arith Even Div2 EqNat Euclid.
Require Import ExtrOcamlBasic.

Extract Inlined Constant Datatypes.negb => "Stdlib.not".
Extract Inlined Constant Datatypes.fst => "Stdlib.fst".
Extract Inlined Constant Datatypes.snd => "Stdlib.snd".


(** NB: The extracted code should be linked with [nums.cm(x)a]
    from ocaml's stdlib and with the wrapper [big.ml] that
    simplifies the use of [Big_int] (it can be found in the sources
    of Coq). *)

(** Disclaimer: trying to obtain efficient certified programs
    by extracting [nat] into [big_int] isn't necessarily a good idea.
    See comments in [ExtrOcamlNatInt.v].
*)


(** Mapping of [nat] into [big_int]. The last string corresponds to
    a [nat_case], see documentation of [Extract Inductive]. *)

Extract Inductive nat => "Farith_Big.big_int" [ "Farith_Big.zero" "Farith_Big.succ" ]
 "Farith_Big.nat_case".

(** Efficient (but uncertified) versions for usual [nat] functions *)

Extract Inlined Constant plus => "Farith_Big.add".
Extract Inlined Constant mult => "Farith_Big.mult".
Extract Constant pred => "fun n -> Farith_Big.max Farith_Big.zero (Farith_Big.pred n)".
Extract Constant minus => "fun n m -> Farith_Big.max Farith_Big.zero (Farith_Big.sub n m)".
Extract Inlined Constant max => "Farith_Big.max".
Extract Inlined Constant min => "Farith_Big.min".
(*Extract Constant nat_beq => "Farith_Big.eq".*)
Extract Constant EqNat.beq_nat => "Farith_Big.eq".
Extract Constant EqNat.eq_nat_decide => "Farith_Big.eq".

Extract Constant Peano_dec.eq_nat_dec => "Farith_Big.eq".

(* Extract Constant Compare_dec.nat_compare =>
 "Farith_Big.compare_case Eq Lt Gt".

Extract Constant Compare_dec.leb => "Farith_Big.le".
Extract Constant Compare_dec.le_lt_dec => "Farith_Big.le".
Extract Constant Compare_dec.lt_eq_lt_dec =>
 "Farith_Big.compare_case (Some false) (Some true) None". *)

Extract Constant Even.even_odd_dec =>
 "fun n -> Farith_Big.sign (Farith_Big.mod n Farith_Big.two) = 0".
Extract Constant Div2.div2 => "fun n -> Farith_Big.div n Farith_Big.two".

Extract Inductive Euclid.diveucl => "(Farith_Big.big_int * Farith_Big.big_int)" [""].
Extract Constant Euclid.eucl_dev => "fun n m -> Farith_Big.quomod m n".
Extract Constant Euclid.quotient => "fun n m -> Farith_Big.div m n".
Extract Constant Euclid.modulo => "fun n m -> Farith_Big.modulo m n".


(** From ExtrOcamlZBigInt of coq archive *)

Require Import ZArith NArith.
Require Import ExtrOcamlBasic.

(** NB: The extracted code should be linked with [nums.cm(x)a]
    from ocaml's stdlib and with the wrapper [big.ml] that
    simplifies the use of [Big_int] (it can be found in the sources
    of Coq). *)

(** Disclaimer: trying to obtain efficient certified programs
    by extracting [Z] into [big_int] isn't necessarily a good idea.
    See the Disclaimer in [ExtrOcamlNatInt]. *)

(** Mapping of [positive], [Z], [N] into [big_int]. The last strings
    emulate the matching, see documentation of [Extract Inductive]. *)

Extract Inductive positive => "Farith_Big.big_int"
 [ "Farith_Big.succ_double" "Farith_Big.double" "Farith_Big.one" ] "Farith_Big.positive_case".

Extract Inductive Z => "Farith_Big.big_int"
 [ "Farith_Big.zero" "" "Farith_Big.opp" ] "Farith_Big.z_case".

Extract Inductive N => "Farith_Big.big_int"
 [ "Farith_Big.zero" "" ] "Farith_Big.n_case".

(** Nota: the "" above is used as an identity function "(fun p->p)" *)

(** Efficient (but uncertified) versions for usual functions *)

Extract Inlined Constant Pos.add => "Farith_Big.add".
Extract Inlined Constant Pos.succ => "Farith_Big.succ".
Extract Constant Pos.pred => "fun n -> Farith_Big.max Farith_Big.one (Farith_Big.pred n)".
Extract Constant Pos.sub => "fun n m -> Farith_Big.max Farith_Big.one (Farith_Big.sub n m)".
Extract Inlined Constant Pos.pred_double => "Farith_Big.pred_double".
Extract Inlined Constant Pos.mul => "Farith_Big.mult".
Extract Inlined Constant Pos.min => "Farith_Big.min".
Extract Inlined Constant Pos.max => "Farith_Big.max".
Extract Inlined Constant Pos.compare => "(Farith_Big.compare_case Eq Lt Gt)".
Extract Constant Pos.compare_cont =>
 "fun c x y -> Farith_Big.compare_case c Lt Gt x y".
Extract Inlined Constant Pos.eqb => "Farith_Big.eq".
Extract Inlined Constant Pos.leb => "Farith_Big.le".
Extract Inlined Constant Pos.ltb => "Farith_Big.lt".
Extract Inlined Constant Pos.to_nat => "Farith_Big.identity".
Extract Inlined Constant Pos.of_nat => "Farith_Big.identity".
Extract Inlined Constant Pos.of_succ_nat => "Farith_Big.succ".
Extract Constant Pos.add_carry => "fun p q -> Farith_Big.succ (Farith_Big.add p q)".
Extract Inlined Constant Pos.sqrt => "Farith_Big.Z.sqrt".
Extract Inlined Constant Pos.square => "Farith_Big.square".
Extract Inlined Constant Pos.eq_dec => "Farith_Big.Z.equal".
Extract Inlined Constant Pos.pow => "Farith_Big.pow_pos".
Extract Inlined Constant Pos.gcd => "Farith_Big.Z.gcd".
Extract Inlined Constant Pos.lor => "Farith_Big.Z.logor".
Extract Inlined Constant Pos.land => "Farith_Big.Z.logand".
Extract Inlined Constant Pos.lxor => "Farith_Big.Z.logxor".
Extract Inlined Constant Pos.ldiff => "Farith_Big.ldiff".
Extract Inlined Constant Pos.shiftl_nat => "Farith_Big.shiftl".
Extract Inlined Constant Pos.shiftr_nat => "Farith_Big.shiftr".
Extract Inlined Constant Pos.shiftl => "Farith_Big.shiftl".
Extract Inlined Constant Pos.shiftr => "Farith_Big.shiftr".

Extract Inlined Constant BinPos.Pos.compare_cont => "(fun c x y -> Farith_Big.compare_case c Lt Gt x y)".


Extract Inlined Constant N.add => "Farith_Big.add".
Extract Inlined Constant N.succ => "Farith_Big.succ".
Extract Constant N.pred => "fun n -> Farith_Big.max Farith_Big.zero (Farith_Big.pred n)".
Extract Constant N.sub => "fun n m -> Farith_Big.max Farith_Big.zero (Farith_Big.sub n m)".
Extract Inlined Constant N.mul => "Farith_Big.mult".
Extract Inlined Constant N.min => "Farith_Big.min".
Extract Inlined Constant N.max => "Farith_Big.max".
Extract Constant N.div =>
 "fun a b -> if Farith_Big.eq b Farith_Big.zero then Farith_Big.zero else Farith_Big.div a b".
Extract Constant N.modulo =>
 "fun a b -> if Farith_Big.eq b Farith_Big.zero then Farith_Big.zero else Farith_Big.modulo a b".
Extract Constant N.compare => "Farith_Big.compare_case Eq Lt Gt".
Extract Inlined Constant N.succ_double => "Farith_Big.succ_double".
Extract Inlined Constant N.double => "Farith_Big.double".
Extract Inlined Constant Pos.Nsucc_double => "Farith_Big.succ_double".
Extract Inlined Constant Pos.Ndouble => "Farith_Big.double".

Extract Inlined Constant Z.add => "Farith_Big.add".
Extract Inlined Constant Z.succ => "Farith_Big.succ".
Extract Inlined Constant Z.pred => "Farith_Big.pred".
Extract Inlined Constant Z.sub => "Farith_Big.sub".
Extract Inlined Constant Z.mul => "Farith_Big.mult".
Extract Inlined Constant Z.opp => "Farith_Big.opp".
Extract Inlined Constant Z.abs => "Farith_Big.abs".
Extract Inlined Constant Z.min => "Farith_Big.min".
Extract Inlined Constant Z.max => "Farith_Big.max".
Extract Inlined Constant Z.eqb => "Farith_Big.eq".
Extract Inlined Constant Z.leb => "Farith_Big.le".
Extract Inlined Constant Z.ltb => "Farith_Big.lt".
Extract Inlined Constant Z.geb => "Farith_Big.ge".
Extract Inlined Constant Z.gtb => "Farith_Big.gt".
Extract Inlined Constant Z.compare => "(Farith_Big.compare_case Eq Lt Gt)".
Extract Inlined Constant Z.double => "Farith_Big.double".
Extract Inlined Constant Z.succ_double => "Farith_Big.succ_double".
Extract Inlined Constant Z.pred_double => "Farith_Big.pred_double".
Extract Inlined Constant Z.pos_sub => "Farith_Big.sub".
Extract Inlined Constant Z.gcd => "Farith_Big.Z.gcd".
Extract Inlined Constant Z.sqrt => "Farith_Big.Z.sqrt".
Extract Inlined Constant Z.sqrtrem => "Farith_Big.Z.sqrt_rem".
Extract Inlined Constant Z.square => "Farith_Big.square".
Extract Inlined Constant Z.lnot => "Farith_Big.Z.lognot".
Extract Inlined Constant Z.lor => "Farith_Big.Z.logor".
Extract Inlined Constant Z.land => "Farith_Big.Z.logand".
Extract Inlined Constant Z.lxor => "Farith_Big.Z.logxor".
Extract Inlined Constant Z.ldiff => "Farith_Big.ldiff".
Extract Inlined Constant Z.eq_dec => "Farith_Big.Z.equal".
Extract Inlined Constant Z.shiftr => "Farith_Big.shiftr".
Extract Inlined Constant Z.shiftl => "Farith_Big.shiftl".
Extract Inlined Constant Z.sgn => "Farith_Big.sgn".

Extract Inlined Constant Z.of_N => "Farith_Big.identity".
Extract Inlined Constant Z.of_nat => "Farith_Big.identity".

Extract Inlined Constant Z.abs_N => "Farith_Big.abs".
Extract Inlined Constant Z.abs_nat => "Farith_Big.abs".

Extract Inlined Constant Zeq_bool => "Farith_Big.eq".

(** trunc convention *)
Extract Inlined Constant Z.rem => "Farith_Big.Z.rem".
Extract Inlined Constant Z.quot => "Farith_Big.Z.div".
Extract Inlined Constant Z.quot2 => "Farith_Big.div2_trunc".
Extract Inlined Constant Z.quotrem => "Farith_Big.Z.div_rem".

(** floor convention *)
Extract Inlined Constant Z.modulo => "Farith_Big.mod_floor".
Extract Inlined Constant Z.div => "Farith_Big.div_floor".
Extract Inlined Constant Z.div_eucl => "Farith_Big.div_mod_floor".
Extract Inlined Constant Z.div2 => "Farith_Big.div2_floor".

(** euclid convention *)
Require Import Zeuclid.
Extract Inlined Constant ZEuclid.modulo => "Farith_Big.Z.erem".
Extract Inlined Constant ZEuclid.div => "Farith_Big.Z.ediv".

Extract Inlined Constant Z.pow_pos => "Farith_Big.pow_pos".



Require Import Flocq.Core.Zaux.
Require Coq.Arith.Wf_nat.
(* Extract Inlined Constant shiftl_pos => "Farith_Big.shiftl_pos". *)
Extract Inlined Constant Core.Zaux.iter_nat => "Farith_Big.iter_nat".
Extract Inlined Constant nat_rect => "Farith_Big.nat_rect".


(** Some proofs used in function realization *)

Definition div_mod_floor a b :=
    let (q,r) := Z.quotrem a b in
    if orb (Z.lxor (Z.sgn a) (Z.sgn b) >=? 0)%Z (r =? 0)%Z
    then (q,r)
    else (Z.pred q,b+r)%Z.

Lemma Floor_of_Trunc:
  forall a b, (b <> 0)%Z -> Z.div_eucl a b = div_mod_floor a b.
Proof.
  intros a' b' Hb.
  unfold div_mod_floor.
  assert (Lmod := Z.rem_mod a' b' Hb).
  assert (Ldiv := Z.quot_div a' b' Hb).
  replace (Z.quotrem a' b') with ((Z.quot a' b',Z.rem a' b')) by
      (compute [Z.quot Z.rem]; destruct (Z.quotrem a' b'); trivial).
  replace (Z.pred (Z.quot a' b'))%Z with (-(Z.opp (Z.quot a' b')+1))%Z by lia.
  rewrite Lmod. rewrite Ldiv.
  pose (a := a'). pose (b := b').
  destruct a'; destruct b'; unfold Z.modulo, Z.div; simpl; trivial; try destruct (Hb (refl_equal 0%Z));
  destruct (Z.pos_div_eucl p (Z.pos p0)) as [[|pq|nq] [|pr|nr]]; trivial.
Qed.

(* Avoid name clashes *)
Extraction Blacklist Big List String Int Z Q.

Extract Inductive Qextended.Qx => "Q.t" [ "Farith_Big.q_mk" ] "Farith_Big.q_case".
Extract Inlined Constant Qextended.den => "Farith_Big.q_den".
Extract Inlined Constant Qextended.num => "Farith_Big.q_num".
Extract Inlined Constant Qextended.Qx_classify => "Q.classify".

Extract Inductive Qx_kind => "Q.kind" [ "Q.INF" "Q.MINF" "Q.UNDEF" "Q.ZERO" "Q.NZERO" ].
Extract Inlined Constant Qx_classify => "Q.classify".

Extract Inductive mode => "Farith_Big.mode" [
  "Farith_Big.NE" "Farith_Big.ZR" "Farith_Big.DN" "Farith_Big.UP" "Farith_Big.NA"
].

Separate Extraction GenericFloat GenericInterval Flocq.Version.
