From Flocq Require Import Core.Core IEEE754.BinarySingleNaN IEEE754.Bits.
Require Import QArith.
Require Import Qreals.
Require Import Reals.
Require Import ZBits.
Require Import Lia Lra.
Require Coq.Arith.Wf_nat.
Require Import Extraction.
Require Import Qextended Rextended.

(** * An instanciation of Flocq's BinarySingleNan for 32 bits IEEE-754 floating points *)

Module B32.

(** ** 1. Precision, maximal exponent & their properties *)

Definition prec : Z := 24.
Definition emax : Z := 128.
Definition mw : Z := 23.
Definition ew : Z := 8.
Definition t : Type := binary_float prec emax.

Lemma Hprec : Prec_gt_0 prec.
Proof.
  unfold Prec_gt_0, prec; lia.
Qed.

Lemma Hemax : Prec_lt_emax prec emax.
Proof.
  unfold Prec_lt_emax, prec, emax; lia.
Qed.

Lemma Hmw : (0 < mw)%Z.
Proof.
  unfold mw; lia.
Qed.

Lemma Hew : (0 < ew)%Z.
Proof.
  unfold ew; lia.
Qed.

(** ** 2. Floating-points operators *)

Definition add : mode -> t -> t -> t := @Bplus _ _ Hprec Hemax.
Definition sub : mode -> t -> t -> t := @Bminus _ _ Hprec Hemax.
Definition mult : mode -> t -> t -> t := @Bmult _ _ Hprec Hemax.
Definition div : mode -> t -> t -> t := @Bdiv _ _ Hprec Hemax.
Definition sqrt : mode -> t -> t := @Bsqrt _ _ Hprec Hemax.
Definition abs : t -> t := Babs.

(** ** 3. Floating-points relations *)

Definition le : t -> t -> bool := Bleb.
Definition lt : t -> t -> bool := Bltb.
Definition eq : t -> t -> bool := Beqb.
Definition ge : t -> t -> bool := fun x y => Bleb y x.
Definition gt : t -> t -> bool := fun x y => Bltb y x.

(** ** 4. convertions to and from [Z] and [Q]*)

Definition of_bits (b : Z) : t :=
  match Bits.binary_float_of_bits mw ew Hmw Hew Hemax b with
  | Binary.B754_nan _ _ _ _ _ => B754_nan
  | Binary.B754_zero _ _ s => B754_zero s
  | Binary.B754_infinity _ _ s => B754_infinity s
  | Binary.B754_finite _ _ s m e H => B754_finite s m e H
  end.

Definition pl_cst := (Zaux.iter_nat xO (Z.to_nat (Z.pred mw)) xH)%Z.

Lemma pl_valid : (Z.pos (Digits.digits2_pos pl_cst) <? prec)%Z = true.
Proof.
  assert (G:forall n, Digits.digits2_Pnat (Zaux.iter_nat xO n xH)%Z = n).
  - induction n.
    * reflexivity.
    * rewrite iter_nat_S; simpl.
      rewrite IHn; reflexivity.
  - rewrite Digits.Zpos_digits2_pos.
    rewrite <- Digits.Z_of_nat_S_digits2_Pnat.
    unfold pl_cst, prec, mw.
    rewrite G;clear G.
    rewrite Nat2Z.inj_succ.
    rewrite Z2Nat.id; [rewrite Z.ltb_lt | ]; lia.
Qed.

Definition to_bits (f : t) : Z :=
  match f with
  | B754_nan =>
    Bits.bits_of_binary_float mw ew (Binary.B754_nan prec emax true pl_cst pl_valid) 
  | B754_zero s => Bits.bits_of_binary_float mw ew (Binary.B754_zero prec emax s)
  | B754_infinity s => Bits.bits_of_binary_float mw ew (Binary.B754_infinity prec emax s)
  | B754_finite s m e H => Bits.bits_of_binary_float mw ew (Binary.B754_finite prec emax s m e H)
  end.

Definition of_q (m : mode) (q : Qx) : t :=
  match Qx_classify q with
  | Qx_ZERO _ _ _ _ => B754_zero false
  | Qx_INF _ _ _ => B754_infinity false
  | Qx_MINF _ _ _ => B754_infinity true
  | Qx_UNDEF _ _ _ => B754_nan
  | Qx_NZERO _ _ _ _ _ =>
    match num q with
    | Z0 => B754_nan (** absurd *)
    | Z.pos pn =>
      SF2B _ (proj1 (Bdiv_correct_aux _ _ Hprec Hemax m false pn 0%Z false (Z.to_pos (den q)) 0%Z))
    | Z.neg nn =>
      SF2B _ (proj1 (Bdiv_correct_aux _ _ Hprec Hemax m true nn 0%Z false (Z.to_pos (den q)) 0%Z))
    end
  end.

Lemma of_q_correct : forall m q, Q2Rx q = B2Rx (of_q m q).
Proof.
  intros m q.
  unfold of_q, Q2Rx; destruct (Qx_classify q).
  - rewrite e, e0. reflexivity.
  - rewrite e, e0. reflexivity.
  - rewrite e, e0. reflexivity.
  - rewrite e, e0.
    destruct (Z.pos pq =? 0)%Z; try reflexivity.
    unfold Q2R; simpl.
    now rewrite Rmult_0_l.
  - rewrite e.
    destruct (Z.pos pq =? 0)%Z eqn:E1, (num q =? 0)%Z eqn:E2.
    + rewrite Z.eqb_eq in E1; rewrite E1;
      rewrite Z.eqb_eq in E2; rewrite E2.
      reflexivity.
    + admit.
    + admit.
    + admit.
Admitted.

End B32.
