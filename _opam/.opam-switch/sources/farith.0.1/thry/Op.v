From Flocq Require Import Core.Core IEEE754.BinarySingleNaN IEEE754.Bits.
From Coq Require Import Program ZArith Bool Lia Reals Qreals ZBits SpecFloat.
Require Import Assert  Utils Interval Qextended Rextended.


Section Op.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float := binary_float prec emax.

Lemma split_bounded_emin:
  forall m e, bounded prec emax m e = true <->
                ( e = emin prec emax /\ (Z.pos (digits2_pos m) <= prec)%Z )
                \/ ( (emin prec emax < e)%Z /\ (e <= emax-prec)%Z /\ (Z.pos (digits2_pos m) = prec)%Z ).
Proof.
  intros m e; split.
  - intros H.
    unfold bounded in H.
    unfold canonical_mantissa in H.
    unfold SpecFloat.fexp in H.
    destruct (Z_ge_lt_dec (emin prec emax) (Z.pos (digits2_pos m) + e - prec)).
    * left.
      rewrite Z.max_r in H.
      apply andb_prop in H.
      rewrite <- Zeq_is_eq_bool in H.
      rewrite <- Zle_is_le_bool in H.
      split; lia.
      lia.
    * right.
      rewrite Z.max_l in H.
      apply andb_prop in H.
      rewrite <- Zeq_is_eq_bool in H.
      rewrite <- Zle_is_le_bool in H.
      split; [lia | split ; lia ].
      lia.
  - intro H.
    destruct H as [[H1 H2]|[H1 [H2 H3]]]; unfold bounded; unfold canonical_mantissa; unfold SpecFloat.fexp; apply andb_true_intro.
    + split.
      * rewrite Z.max_r.
        rewrite <- Zeq_is_eq_bool.
        lia.
        lia.
      * rewrite <- Zle_is_le_bool.
        unfold emin in H1.
        unfold Prec_gt_0 in Hprec.
        unfold Prec_lt_emax in Hemax.
        lia.
    + split.
      * rewrite Z.max_l.
        rewrite <- Zeq_is_eq_bool.
        lia.
        lia.
      * rewrite <- Zle_is_le_bool.
        unfold emin in H1.
        unfold Prec_gt_0 in Hprec.
        unfold Prec_lt_emax in Hemax.
        lia.
Qed.

Lemma max_mantissa_has_length_prec:
  Z.pos (digits2_pos (shift_pos (Z.to_pos prec) 1 - 1)) = prec.
Proof.
  rewrite Zpos_digits2_pos, Pos2Z.inj_sub.
    - rewrite shift_pos_correct, Z.mul_1_r.
      assert (P2pm1 : (0 <= 2 ^ prec - 1)%Z).
      { apply (Zplus_le_reg_r _ _ 1); ring_simplify.
        change 1%Z with (2 ^ 0)%Z; change 2%Z with (radix2 : Z).
        apply Zpower_le; unfold Prec_gt_0 in Hprec; lia. }
      apply Zdigits_unique;
        rewrite Z.pow_pos_fold, Z2Pos.id; [|exact Hprec]; simpl; split.
      + rewrite (Z.abs_eq _ P2pm1).
        replace prec with (prec - 1 + 1)%Z at 2 by ring.
        rewrite Zpower_plus; [| unfold Prec_gt_0 in Hprec; lia|lia].
        simpl; unfold Z.pow_pos; simpl.
        assert (1 <= 2 ^ (prec - 1))%Z; [|lia].
        change 1%Z with (2 ^ 0)%Z; change 2%Z with (radix2 : Z).
        apply Zpower_le; simpl; unfold Prec_gt_0 in Hprec; lia.
      + now rewrite Z.abs_eq; [lia|].
    - change (_ < _)%positive
        with (Z.pos 1 < Z.pos (shift_pos (Z.to_pos prec) 1))%Z.
      rewrite shift_pos_correct, Z.mul_1_r, Z.pow_pos_fold.
      rewrite Z2Pos.id; [|exact Hprec].
      change 1%Z with (2 ^ 0)%Z; change 2%Z with (radix2 : Z).
      apply Zpower_lt; unfold Prec_gt_0 in Hprec; lia.
Qed.

Lemma min_normal_mantissa_has_length_prec:
  Z.pos (digits2_pos (Z.to_pos (Z.shiftl 1 (prec - 1)%Z)))%positive = prec.
Proof.
  unfold Prec_gt_0 in Hprec.
  rewrite Zpos_digits2_pos.
  rewrite Z.shiftl_mul_pow2.
  rewrite Z2Pos.id.
  rewrite Z.mul_1_l.
  rewrite Zdigits_Zpower.
  - lia.
  - lia.
  - assert (H2 : (0 < 2)%Z) by lia.
    assert (H3 : (0 <= (prec - 1))%Z) by lia.
    assert (H := (Z.pow_pos_nonneg 2 (prec - 1) H2 H3)%Z).
    lia.
  - lia.
Qed.

Lemma max_prec_is_canonical:
  forall e, ((SpecFloat.emin prec emax) <= e)%Z -> (e <= emax - prec)%Z ->
            canonical_mantissa prec emax (shift_pos (Z.to_pos prec) 1 - 1) e = true.
Proof.
 intros e Hege Hele.
 unfold canonical_mantissa; apply Zeq_bool_true.
 assert (H := max_mantissa_has_length_prec).
 set (p := Z.pos (digits2_pos _)) in *.
 unfold SpecFloat.fexp, FLT_exp; rewrite H, Z.max_l; [ring|].
 unfold emin in *.
 (* generalize (prec_gt_0 prec) (prec_lt_emax prec emax). *)
 lia.
Qed.

Lemma min_normal_prec_is_canonical:
  forall e, ((SpecFloat.emin prec emax) <= e)%Z -> (e <= emax - prec)%Z ->
            canonical_mantissa prec emax (Z.to_pos (Z.shiftl 1 (prec - 1)%Z))%positive e = true.
Proof.
 intros e Hege Hele.
 unfold canonical_mantissa; apply Zeq_bool_true.
 assert (H := min_normal_mantissa_has_length_prec).
 set (p := Z.pos (digits2_pos _)) in *.
 unfold SpecFloat.fexp, FLT_exp; rewrite H, Z.max_l; [ring|].
 unfold emin in *.
 (* generalize (prec_gt_0 prec) (prec_lt_emax prec emax). *)
 lia.
Qed.

Lemma Bmax_float_proof :
  valid_binary prec emax
    (S754_finite false (shift_pos (Z.to_pos prec) 1 - 1) (emax - prec))
  = true.
Proof.
unfold valid_binary, bounded; apply andb_true_intro; split.
- apply max_prec_is_canonical.
  + unfold emin.
    unfold Prec_gt_0 in Hprec.
    unfold Prec_lt_emax in Hemax.
    lia.
  + lia.
- apply Zle_bool_true; unfold emin; unfold Prec_gt_0 in Hprec; lia.
Qed.


Lemma bounded_is_bigger_than_emin:
  forall m0 e, bounded prec emax m0 e = true -> (emin prec emax <= e)%Z.
Proof.
  intros m0 e H.
  apply andb_prop in H.
  unfold canonical_mantissa in H.
  unfold SpecFloat.fexp in H.
  assert (Hmax := Z.le_max_r (Z.pos (digits2_pos m0) + e - prec) (emin prec emax)).
  rewrite <- Zeq_is_eq_bool in H.
  lia.
Qed. 

Program Definition Fsucc x :=
  match x with
  | B754_zero _ => B754_finite false 1%positive (SpecFloat.emin prec emax) (Bulp_correct_aux _ _ Hprec Hemax)
  | B754_infinity false => x
  | B754_infinity true => Bopp Bmax_float
  | B754_nan => x
  | B754_finite false m e H =>
      let m := (Pos.succ m) in
      if dec (Z.ltb prec (Z.pos(SpecFloat.digits2_pos m)))%Z then
        if dec (Z.eqb e (emax - prec))%Z then
          B754_infinity false
        else B754_finite false (Z.to_pos (Z.shiftl 1 (prec - 1)%Z)) (e+1)%Z _
      else B754_finite false m e _
  | B754_finite true m e H =>
      if dec (e =? (SpecFloat.emin prec emax))%Z then
        if dec (1 <? Z.pos m)%Z then
          B754_finite true (Pos.pred m) e _
        else
          B754_zero true
      else
         let m0 := (Z.pred (Z.pos m))%Z in
         if dec ((Zdigits2 m0) <? prec)%Z then
           B754_finite true (shift_pos (Z.to_pos prec) 1 - 1) (e-1)%Z _
         else
           B754_finite true (Z.to_pos m0) e _
  end.

Next Obligation.
  apply andb_true_intro.
  split.
  - apply min_normal_prec_is_canonical.
    + apply bounded_is_bigger_than_emin  in H.
      lia.
    + apply andb_prop in H.
      rewrite Z.leb_le in H.
      lia.
  - rewrite Z.leb_le in *.
    rewrite Z.eqb_neq in H1.
    apply andb_prop in H.
    rewrite Z.leb_le in H.
    lia.
Qed.

Next Obligation.
  rewrite split_bounded_emin in *.
  destruct H.
  * left.
    apply Z.ltb_nlt in H0.
    split; lia.
  * right.
    apply Z.ltb_nlt in H0.
    split. easy.
    split. easy.
    rewrite Zpos_digits2_pos in *.
    assert (H1:= Zdigits_le radix2 (Z.pos m0) (Z.pos (Pos.succ m0))).
    lia.
Qed.

Next Obligation.
  rewrite split_bounded_emin.
  left.
  rewrite Z.ltb_lt in *.
  rewrite Z.eqb_eq in *.
  rewrite split_bounded_emin in H.
  destruct H.
  split. lia.
  assert (Zdigits radix2 (Z.pred (Z.pos m)) <= Zdigits radix2 (Z.pos m))%Z.
  apply Zdigits_le; lia.
  rewrite Zpos_digits2_pos in *.
  rewrite Pos2Z.inj_pred in *.
  lia.
  lia.
  lia.
Qed.

Next Obligation.
  rewrite split_bounded_emin in H.
  destruct H.
  * lia.
  * apply andb_true_intro.
    split.
    - apply max_prec_is_canonical; lia.
    - lia.
Qed.

Next Obligation.
  replace (match m with | (p~1)%positive => Z.pos p~0  | (p~0)%positive => Z.pos (Pos.pred_double p)
          | 1%positive => 0  end)%Z with (Z.pred (Z.pos m)) in *.
  rewrite split_bounded_emin in H.
  destruct H.
  * lia.
  * rewrite split_bounded_emin.
    right.
    rewrite Z.ltb_ge in *.
    rewrite Z.eqb_neq in *.
    rewrite Zpos_digits2_pos in *.
    destruct (Pos.eq_dec 1 m)%Z.
    + rewrite <- e0 in *.
      unfold Prec_gt_0 in Hprec.
      simpl in H1.
      lia. (* absurd *)
    + rewrite Zdigits2_Zdigits in *.
      assert (Zdigits radix2 (Z.pred (Z.pos m)) <= Zdigits radix2 (Z.pos m))%Z.
      apply Zdigits_le; lia.
      split. lia.
      split. lia.
      rewrite Z2Pos.id.
      lia.
      lia.
  * reflexivity.
Qed.

Definition Fneg (x:float) : float :=
    match x with
     | B754_nan => B754_nan
     | B754_zero s => B754_zero (negb s)
     | B754_infinity s => B754_infinity (negb s)
     | B754_finite s m e H => B754_finite (negb s) m e H
     end.


Definition Fpred x := Fneg (Fsucc (Fneg x)).


End Op.
