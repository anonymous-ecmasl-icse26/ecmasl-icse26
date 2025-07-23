From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import ZArith Lia Reals Psatz.
Require Import Utils Rextended.

Section Correction.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float : Type := binary_float prec emax.


Lemma B2SF_eq :
  forall (x : float) y H, B2SF x = y -> x = SF2B y H.
Proof.
  intros.
  apply B2SF_inj.
  rewrite H0.
  symmetry.
  apply B2SF_SF2B.
Qed.

Lemma Bplus_correct :
  forall (m : mode) (x y : float),
  is_nan (Bplus m x y) = false ->
  B2Rx (Bplus m x y) = round m (add (B2Rx x) (B2Rx y)).
Proof.
  Ltac compute0 :=
    match goal with
    | [ m : mode |- _ ] =>
      destruct m; simpl (B2Rx (B754_zero _)); (rewrite add_0_l || rewrite add_0_r); try apply round_id; apply round_0
  end.
  intros m x y HnanS.
  destruct (Bplus_not_nan_inv _ _ _ HnanS) as [HnanX HnanY].
  induction x as [ [ ] | [ ] | | ] eqn:Ex, y as [ [ ] | [ ] | | ] eqn:Ey; try easy; try compute0.
  unfold add.
  repeat rewrite (B2Rx_finite (B754_finite _ _ _ _)); auto.
  unfold round.
  assert (Fx : is_finite x = true) by (rewrite Ex; auto).
  assert (Fy : is_finite y = true) by (rewrite Ey; auto).
  pose proof (Bplus_correct _ _ _ _ m x y Fx Fy).
  destruct (do_overflow _ _ _ _) eqn:Ho1.
  - apply do_overflow_true in Ho1.
    unfold dont_overflow in Ho1.
    rewrite <- Ex, <- Ey in *.
    unfold R_imax in Ho1.
    rewrite Ho1 in H.
    destruct H as [H1 H2].
    apply (B2SF_eq _ _ (binary_overflow_correct _ _ _ _ _ _)) in H1.
    destruct m eqn:Em, (sign (B2R x + B2R y)) eqn:Hs.
    + simpl in *. rewrite H1; simpl. 
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_neg_inv in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_pos_inv in Hs.
      pose proof (IZR_neg m2); pose proof (IZR_neg m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_neg_inv in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_pos_inv in Hs.
      change (Z.neg m2) with (- Z.pos m2)%Z in Hs.
      change (Z.neg m3) with (- Z.pos m3)%Z in Hs.
      repeat rewrite opp_IZR in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_neg_inv in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_pos_inv in Hs.
      pose proof (IZR_neg m2); pose proof (IZR_neg m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_neg_inv in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_pos_inv in Hs.
      pose proof (IZR_neg m2); pose proof (IZR_neg m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_neg_inv in Hs.
      pose proof (IZR_pos m2); pose proof (IZR_pos m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
    + simpl in *. rewrite H1; simpl.
      fdestruct x; fdestruct y.
      destruct s1, s2; simpl in *; try easy.
      unfold Defs.F2R in Hs; simpl in Hs.
      apply sign_pos_inv in Hs.
      pose proof (IZR_neg m2); pose proof (IZR_neg m3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e3);
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e5); nra.
  - apply do_overflow_false in Ho1.
    unfold dont_overflow in Ho1.
    rewrite <- Ex, <- Ey in *.
    unfold R_imax in Ho1.
    rewrite Ho1 in H.
    now destruct H as [<- [Hf _]], (Bplus _ _ _).
Qed.

Lemma Bmult_correct :
  forall (m : mode) (x y : float),
  is_nan (Bmult m x y) = false ->
  B2Rx (Bmult m x y) = round m (mult (B2Rx x) (B2Rx y)).
Admitted.

Theorem Bplus_le_mono_l:
  forall m (a b c : float),
    is_nan (Bplus m a c) = false ->
    is_nan (Bplus m b c) = false ->
    a <= b ->
    Bplus m a c <= Bplus m b c.
Proof.
  intros m a b c Hnan1 Hnan2 Hab.
  apply B2Rx_le; auto.
  repeat (rewrite Bplus_correct; auto).
  apply round_le.
  apply (add_leb_mono_l _ _ _ (le_B2Rx _ _ Hab)).
Qed.

Theorem Bplus_le_mono_r:
  forall m (a b c : float),
    is_nan (Bplus m c a) = false ->
    is_nan (Bplus m c b) = false ->
    a <= b ->
    Bplus m c a <= Bplus m c b.
Proof.
  intros m a b c Hnan1 Hnan2 Hab.
  apply B2Rx_le; auto.
  repeat (rewrite Bplus_correct; auto).
  apply round_le.
  apply (add_leb_mono_r _ _ _ (le_B2Rx _ _ Hab)).
Qed.

Theorem Bplus_le_compat:
  forall m (a b c d : float),
    is_nan (Bplus m a b) = false ->
    is_nan (Bplus m c d) = false ->
    a <= c ->
    b <= d ->
    Bplus m a b <= Bplus m c d.
Proof.
  intros.
  apply B2Rx_le; auto.
  repeat (rewrite Bplus_correct); auto.
  eapply leb_trans; apply round_le.
  - apply (add_leb_mono_l _ _ _ (le_B2Rx _ _ H1)).
  - apply (add_leb_mono_r _ _ _ (le_B2Rx _ _ H2)).
Qed.

End Correction.
