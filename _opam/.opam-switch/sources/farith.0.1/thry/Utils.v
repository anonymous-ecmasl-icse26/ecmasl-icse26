From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import ZArith Lia Reals Psatz Bool.
(* From F Require Import Rextended. *)

(**
  Usefull facts & definitions about R
*)
Section Rutils.

Definition sign (r : R) :=
  Raux.Rlt_bool r 0.

Lemma sign_pos_inv :
  forall r, sign r = false -> (0 <= r)%R.
Proof.
  intros.
  unfold sign in H.
  now destruct (Raux.Rlt_bool_spec r 0).
Qed.

Lemma sign_neg_inv :
  forall r, sign r = true -> (r <= 0)%R.
Proof.
  intros.
  unfold sign in H. left.
  now destruct (Raux.Rlt_bool_spec r 0).
Qed.

Lemma sign_neg_inv_strict:
  forall r, sign r = true -> (r < 0)%R.
Proof.
  intros.
  unfold sign in H.
  now destruct (Raux.Rlt_bool_spec r 0).
Qed.

Lemma minus_pos_lt :
  forall r1 r2, (0 < r2)%R -> (r1 - r2 < r1)%R.
Proof.
  intros; lra.
Qed.

Lemma IZR_neg :
  (forall x, IZR (Z.neg x) < 0)%R.
Proof.
  induction x; try lra;
  apply (Rgt_trans _ (IZR (Z.neg x))); auto;
  apply IZR_lt; lia.
Qed.

Lemma IZR_pos :
  (forall x, IZR (Z.pos x) > 0)%R.
Proof.
  induction x; try lra;
  apply (Rgt_trans _ (IZR (Z.pos x))); auto;
  apply IZR_lt; lia.
Qed.

Lemma pos_Rleb_neg :
  forall r1 r2, 
    sign r1 = false ->
    sign r2 = true ->
    Raux.Rle_bool r1 r2 = false.
Proof.
  intros. unfold sign in *.
  destruct (Raux.Rlt_bool_spec r1 0); try easy.
  destruct (Raux.Rlt_bool_spec r2 0); try easy.
  apply Raux.Rle_bool_false; lra.
Qed.

Lemma Rleb_Rle :
  forall r1 r2, Raux.Rle_bool r1 r2 = true -> (r1 <= r2)%R.
Proof.
  intros.
  now destruct (Raux.Rle_bool_spec r1 r2).
Qed.

Lemma Reqb_Req :
  forall r1 r2, Raux.Req_bool r1 r2 = true -> (r1 = r2)%R.
Proof.
  intros.
  now destruct (Raux.Req_bool_spec r1 r2).
Qed.

Lemma Rltb_Rlt :
  forall r1 r2, Raux.Rlt_bool r1 r2 = true -> (r1 < r2)%R.
Proof.
  intros.
  now destruct (Raux.Rlt_bool_spec r1 r2).
Qed.

Lemma Rsign_split :
  forall (r : R), (r < 0 \/ r = 0 \/ r > 0)%R.
Proof.
  intros. lra.
Qed.

End Rutils.

(*********************************************************
       Simple & usefull results on floats
**********************************************************)

#[global] Notation "x <= y" := (Bleb x y = true).
#[global] Notation "x <= y <= z" := (Bleb x y = true /\ Bleb y z = true).
#[global] Notation "'+oo'" := (B754_infinity false).
#[global] Notation "'-oo'" := (B754_infinity true).
#[global] Notation "'NaN'" := (B754_nan).

Ltac fdestruct f :=
  destruct f as [ [ ] | [ ] | | ]; try easy.

Section Utils.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float := binary_float prec emax.

Definition is_inf (x : float) :=
  match x with
  | B754_infinity _ => true
  | _ => false
  end.

Definition is_infp (x : float) :=
  match x with
  | B754_infinity s => negb s
  | _ => false
  end.

Definition is_infm (x : float) :=
  match x with
  | B754_infinity s => s
  | _ => false
  end.

Lemma le_not_nan :
  forall x y : float, Bleb x y = true -> is_nan x = false /\ is_nan y = false.
Proof. now intros [ ] [ ]. Qed.

Lemma le_not_nan_l :
  forall x y : float, Bleb x y = true -> is_nan x = false.
Proof.
  intros.
  exact (proj1 (le_not_nan x y H)).
Qed.

Lemma le_not_nan_r :
  forall x y : float, Bleb x y = true -> is_nan y = false.
Proof.
  intros.
  exact (proj2 (le_not_nan x y H)).
Qed.

Lemma infm_min :
  forall (x : float), is_nan x = false -> -oo <= x.
Proof. fdestruct x. Qed.

Lemma infp_max :
  forall (x : float), is_nan x = false -> x <= +oo.
Proof. fdestruct x. Qed.

Lemma infp_le_is_infp :
  forall x : float, +oo <= x -> x = +oo.
Proof.
  now intros [ [ ] | [ ] | | ] H.
Qed.

Lemma le_infm_is_infm :
  forall x : float, x <= -oo -> x = -oo.
Proof.
  now intros [ [ ] | [ ] | | ] H.
Qed.

Lemma is_infm_inv:
  forall x : float, is_infm x = true -> x = -oo.
Proof. now intros [ [ ] | [ ] | | ]. Qed.

Lemma is_infp_inv:
  forall x : float, is_infp x = true -> x = +oo.
Proof. now intros [ [ ] | [ ] | | ]. Qed.

Lemma is_nan_inv:
  forall x : float, is_nan x = true -> x = NaN.
Proof. now intros [ ]. Qed.

Lemma le_infp_finite:
  forall x : float, is_finite x = true -> +oo <= x -> False.
Proof. now intros [ ]. Qed.

Lemma le_infm_finite:
  forall x : float, is_finite x = true -> x <= -oo -> False.
Proof. now intros [ ]. Qed.

Lemma Bplus_finites_not_nan :
  forall m (x y : float),
  is_finite x = true ->
  is_finite y = true ->
  is_nan (Bplus m x y) = false.
Proof.
  intros m [[ ] | [ ] | | ] [ [ ] | [ ] | | ] Fx Fy; try easy.
  - now destruct m.
  - now destruct m.
  - unfold Bplus.
    auto using (is_nan_binary_normalize prec emax).
Qed.

Lemma Bplus_nan_inv :
  forall (m : mode) (x y:float), is_nan (Bplus m x y) = true ->
  x = +oo /\ y = -oo \/ x = -oo /\ y = +oo \/ x = NaN \/ y = NaN.
Proof.
  intros; fdestruct x; fdestruct y; auto.
  - now destruct m.
  - now destruct m.
  - now rewrite Bplus_finites_not_nan in H.
Qed.

Lemma Bplus_not_nan_inv :
  forall (m : mode) (x y:float), is_nan (Bplus m x y) = false ->
    ~(x = +oo /\ y = -oo) /\ ~(x = -oo /\ y = +oo) /\ (is_nan x = false) /\ (is_nan y = false).
Proof.
  intros; repeat split; fdestruct x; fdestruct y.
Qed.

(* Lemma Bplus_nan_if :
  forall m (x y : float),
  is_nan x = false ->
  is_nan y = false ->
  is_nan (Bplus m x y) = true ->
  (x = +oo /\ y = -oo) \/ (x = -oo /\ y = +oo).
Proof.
  intros.
  fdestruct x; fdestruct y; try now destruct m; intuition.
  assert (is_nan (Bplus m (B754_finite s m0 e e0) (B754_finite s0 m1 e1 e2)) = false) by auto using Bplus_finites_not_nan.
  rewrite H1 in H2; discriminate.
Qed. *)

Lemma Bplus_zero :
  forall m b (x : float),
    B2R (Bplus m (B754_zero b) x) = B2R x.
Proof.
  intros ? [ ] [ [ ] | [ ] | | ]; try easy.
  - simpl; destruct m; reflexivity.
  - simpl; destruct m; reflexivity.
Qed.

Lemma pos_Bopp_neg :
  forall m e Hb, @B754_finite prec emax true m e Hb = Bopp (B754_finite false m e Hb).
Proof. reflexivity. Qed.

Lemma neg_Bopp_pos :
  forall m e Hb, @B754_finite prec emax false m e Hb = Bopp (B754_finite true m e Hb).
Proof. reflexivity. Qed.

Lemma Rle_Bleb :
  forall (x y : float),
    is_finite x = true ->
    is_finite y = true ->
    (B2R x <= B2R y)%R ->
    Bleb x y = true.
Proof.
  intros x y Fx Fy Hxy.
  unfold Bleb, SpecFloat.SFleb.
  replace (SpecFloat.SFcompare (_ x) (_ y)) with (Bcompare x y) by auto.
  rewrite (Bcompare_correct _ _ x y Fx Fy).
  destruct Raux.Rcompare eqn:E; try easy.
  apply Raux.Rcompare_Gt_inv in E; lra.
Qed.

Lemma Rlt_Bltb :
  forall (x y : float),
    is_finite x = true ->
    is_finite y = true ->
    (B2R x < B2R y)%R ->
    Bltb x y = true.
Proof.
  intros x y Fx Fy Hxy.
  unfold Bltb, SpecFloat.SFltb.
  replace (SpecFloat.SFcompare (_ x) (_ y)) with (Bcompare x y) by auto.
  rewrite (Bcompare_correct _ _ x y Fx Fy).
  destruct Raux.Rcompare eqn:E; auto.
  - apply Raux.Rcompare_Eq_inv in E; lra.
  - apply Raux.Rcompare_Gt_inv in E; lra.
Qed.

Lemma Bleb_Rle :
  forall x y : float, is_finite x = true -> is_finite y = true ->
    Bleb x y = true -> (B2R x <= B2R y)%R.
Proof.
  intros x y Fx Fy H.
  unfold Bleb, SpecFloat.SFleb in H.
  replace (SpecFloat.SFcompare (_ x) (_ y)) with (Bcompare x y) in H by auto.
  rewrite (Bcompare_correct _ _ x y Fx Fy) in H.
  destruct (Raux.Rcompare) eqn:E in H; try easy.
  + apply Raux.Rcompare_Eq_inv in E; lra.
  + apply Raux.Rcompare_Lt_inv in E; lra.
Qed.

Lemma Bltb_Rlt :
  forall x y : float, is_finite x = true -> is_finite y = true ->
    Bltb x y = true -> (B2R x < B2R y)%R.
Proof.
  intros x y Fx Fy H.
  unfold Bltb, SpecFloat.SFltb in H.
  replace (SpecFloat.SFcompare (_ x) (_ y)) with (Bcompare x y) in H by auto.
  rewrite (Bcompare_correct _ _ x y Fx Fy) in H.
  destruct (Raux.Rcompare) eqn:E in H; try easy.
  apply Raux.Rcompare_Lt_inv in E; lra.
Qed.

Lemma Bleb_trans :
  forall (x y z : float), x <= y -> y <= z -> x <= z.
Proof.
  intros x y z Hxy Hyz.
  fdestruct x; fdestruct y; fdestruct z;
  apply Rle_Bleb; auto;
  apply Bleb_Rle in Hxy; auto;
  apply Bleb_Rle in Hyz; auto;
  lra.
Qed.

Lemma Bltb_trans :
  forall (x y z : float), Bltb x y = true -> Bltb y z = true -> Bltb x z = true.
Proof.
  intros x y z Hxy Hyz.
  fdestruct x; fdestruct y; fdestruct z;
  apply Rlt_Bltb; auto;
  apply Bltb_Rlt in Hxy; auto;
  apply Bltb_Rlt in Hyz; auto;
  lra.
Qed.

Lemma Bltb_Bleb_trans :
  forall x y z : float, Bltb x y = true -> y <= z -> Bltb x z = true.
Proof.
  intros x y z Hxy Hyz.
  fdestruct x; fdestruct y; fdestruct z;
  apply Rlt_Bltb; auto;
  apply Bltb_Rlt in Hxy; auto;
  apply Bleb_Rle in Hyz; auto;
  lra.
Qed.

Lemma Bleb_Bltb_trans :
  forall x y z : float, Bleb x y = true -> Bltb y z = true -> Bltb x z = true.
Proof.
  intros x y z Hxy Hyz.
  fdestruct x; fdestruct y; fdestruct z;
  apply Rlt_Bltb; auto;
  apply Bleb_Rle in Hxy; auto;
  apply Bltb_Rlt in Hyz; auto;
  lra.
Qed.

Lemma Beqb_refl :
  forall x : float, is_nan x = false -> Beqb x x = true.
Proof.
  intros; fdestruct x.
  unfold Beqb; cbn.
  destruct s;
  rewrite (Zaux.Zcompare_Eq e e) by reflexivity;
  now rewrite (Pcompare_refl m).
Qed.

Lemma Beqb_nan_l :
  forall (x : float), Beqb NaN x = false.
Proof. fdestruct x. Qed.

Lemma Beqb_nan_r :
  forall (x : float), Beqb x NaN = false.
Proof. fdestruct x. Qed.

Lemma Beqb_Bleb :
  forall x y : float, Beqb x y = true -> Bleb x y = true.
Proof.
  intros x y Hxy.
  fdestruct x; fdestruct y; rewrite Beqb_correct in Hxy; auto;
  apply Rle_Bleb; auto; right;
  now apply Reqb_Req in Hxy.
Qed.


Lemma Bleb_refl :
  forall x:float, is_nan x = false -> Bleb x x = true.
Proof.
  intros x Hx; fdestruct x.
  apply Rle_Bleb; auto; lra.
Qed.

Lemma Bltb_Bleb :
  forall x y : float, Bltb x y  = true -> Bleb x y = true.
Proof.
  intros x y Hxy.
  fdestruct x; fdestruct y;
  apply Rle_Bleb; auto;
  apply Bltb_Rlt in Hxy; auto;
  lra.
Qed.

Axiom proof_irr :
  forall m e (H H' : SpecFloat.bounded prec emax m e = true), H = H'.

Lemma Bleb_antisymm_strict :
  forall x y : float, x <= y <= x -> Beqb x (B754_zero true) = false -> x = y.
Proof.
  intros x y [H1 H2].
  fdestruct x; fdestruct y;
  try (destruct s; try easy);
  try (destruct s0; try easy).
  - intros _.
    cbn in H1, H2.
    destruct (e ?= e1)%Z eqn:E1; rewrite (Z.compare_antisym _ _), E1 in H2; simpl in H2; try discriminate.
    rewrite <- ZC4 in H1.
    destruct (Pos.compare_cont Eq m0 m) eqn:E2; try easy.
    apply (Pcompare_Eq_eq _ _) in E2; subst.
    apply (Z.compare_eq) in E1; subst; cbn.
    rewrite (proof_irr _ _ e0 e2).
    reflexivity.
  - intros _.
    cbn in H1, H2.
    rewrite ZC4 in H2.
    destruct (e1 ?= e)%Z eqn:E1; rewrite (Z.compare_antisym _ _), E1 in H1; simpl in H2; try discriminate.
    destruct (Pos.compare_cont Eq m m0) eqn:E2; try easy.
    + apply (Pcompare_Eq_eq _ _) in E2; subst.
      apply (Z.compare_eq) in E1; subst; cbn.
      rewrite (proof_irr _ _ e0 e2).
      reflexivity.
Qed.


Lemma Bleb_antisymm :
  forall x y : float, x <= y <= x -> Beqb x y = true.
Proof.
  intros x y [H1 H2].
  fdestruct x; fdestruct y;
  try (destruct s; try easy);
  try (destruct s0; try easy).
  - cbn in H1, H2.
    destruct (e ?= e1)%Z eqn:E1; rewrite (Z.compare_antisym _ _), E1 in H2; simpl in H2; try discriminate.
    rewrite <- ZC4 in H1.
    destruct (Pos.compare_cont Eq m0 m) eqn:E2; try easy.
    apply (Pcompare_Eq_eq _ _) in E2; subst.
    apply (Z.compare_eq) in E1; subst; cbn.
    now rewrite Z.compare_refl, Pcompare_refl.
  - cbn in H1, H2.
    destruct (e ?= e1)%Z eqn:E1; rewrite (Z.compare_antisym _ _), E1 in H2; simpl in H2; try discriminate.
    destruct (Pos.compare_cont Eq m m0) eqn:E2; try easy.
    + apply (Pcompare_Eq_eq) in E2; subst.
      apply (Z.compare_eq) in E1; subst; cbn.
      now rewrite Z.compare_refl, Pcompare_refl.
    + destruct (Pos.compare_cont Eq m0 m) eqn:E3; try easy.
      * apply Pos.compare_nge_iff in E2.
        apply Pos.compare_eq_iff in E3.
        intuition.
      * apply Pos.compare_nge_iff in E2.
        apply Pos.compare_nge_iff in E3.
        intuition.
Qed.

Lemma Beqb_symm :
  forall x y : float, Beqb x y = true -> Beqb y x = true.
Proof.
  intros x y Hxy.
  fdestruct x; fdestruct y; unfold Beqb in Hxy; simpl in *; try (now destruct s).
  unfold SpecFloat.SFeqb in Hxy; simpl in *.
  destruct s, s0; auto.
  * rewrite <- ZC4 in Hxy.
    destruct (e ?= e1)%Z eqn:E1, (Pos.compare_cont Eq m0 m) eqn:E2; simpl in *; try discriminate.
    rewrite Z.compare_eq_iff in E1; subst.
    apply Pcompare_Eq_eq in E2; subst.
    rewrite Beqb_correct; auto; simpl.
    unfold Raux.Req_bool.
    rewrite Raux.Rcompare_Eq; reflexivity.
  * destruct (e ?= e1)%Z eqn:E1, (Pos.compare_cont Eq m m0) eqn:E2; simpl in *; try discriminate.
    rewrite Z.compare_eq_iff in E1; subst.
    apply Pcompare_Eq_eq in E2; subst.
    rewrite Beqb_correct; auto; simpl.
    unfold Raux.Req_bool.
    rewrite Raux.Rcompare_Eq; reflexivity.
Qed.

Lemma Beqb_trans :
  forall x y z : float, Beqb x y = true -> Beqb y z = true -> Beqb x z = true.
Proof.
  intros x y z H1 H2.
  apply Bleb_antisymm; split.
  - apply (Bleb_trans _ _ _ (Beqb_Bleb _ _ H1) (Beqb_Bleb _ _ H2)).
  - apply (Bleb_trans _ _ _ (Beqb_Bleb _ _ (Beqb_symm _ _ H2)) (Beqb_Bleb _ _ (Beqb_symm _ _ H1))).
Qed.

Lemma Bleb_false_Bltb :
  forall x y:float, is_nan x = false -> is_nan y = false -> Bleb x y = false -> Bltb y x = true.
Proof.
  intros x y Hx Hy Hxy.
  destruct x as [ | [ ] | | ] eqn:Ex, y as [ | [ ] | | ] eqn:Ey; try easy; rewrite <- Ex, <- Ey in *;
  unfold Bleb, SpecFloat.SFleb in Hxy;
  replace (SpecFloat.SFcompare (B2SF _) (B2SF _)) with (Bcompare x y) in Hxy by auto;
  assert (Fx: is_finite x = true) by (rewrite Ex; auto);
  assert (Fy: is_finite y = true) by (rewrite Ey; auto);
  rewrite (Bcompare_correct _ _ x y Fx Fy) in Hxy; auto;
  destruct (Raux.Rcompare _ _) eqn:E; try easy;
  apply Raux.Rcompare_Gt_inv in E;
  apply Rlt_Bltb; auto.
Qed.

Lemma Bltb_false_Bleb :
  forall x y:float, is_nan x = false -> is_nan y = false -> Bltb x y = false -> Bleb y x = true.
Proof.
  intros x y Hx Hy Hxy.
  destruct x as [ | [ ] | | ] eqn:Ex, y as [ | [ ] | | ] eqn:Ey; try easy; rewrite <- Ex, <- Ey in *;
  unfold Bltb, SpecFloat.SFltb in Hxy;
  replace (SpecFloat.SFcompare (B2SF _) (B2SF _)) with (Bcompare x y) in Hxy by auto;
  assert (Fx: is_finite x = true) by (rewrite Ex; auto);
  assert (Fy: is_finite y = true) by (rewrite Ey; auto);
  rewrite (Bcompare_correct _ _ x y Fx Fy) in Hxy; auto;
  destruct (Raux.Rcompare _ _) eqn:E; try easy;
  (apply Raux.Rcompare_Eq_inv in E || apply Raux.Rcompare_Gt_inv in E);
  apply Rle_Bleb; auto; lra.
Qed.

Lemma Bltb_true_Bleb :
  forall x y:float, is_nan x = false -> is_nan y = false -> Bltb x y = true -> Bleb y x = false.
Proof.
  intros x y Hx Hy Hxy.
  destruct x as [ | [ ] | | ] eqn:Ex, y as [ | [ ] | | ] eqn:Ey; try easy; rewrite <- Ex, <- Ey in *;
  assert (Fx: is_finite x = true) by (rewrite Ex; auto);
  assert (Fy: is_finite y = true) by (rewrite Ey; auto);
  apply (Bltb_Rlt _ _ Fx Fy) in Hxy;
  apply not_true_is_false; intros Hcontr;
  apply (Bleb_Rle _ _ Fy Fx) in Hcontr;
  lra.
Qed.

Lemma Bleb_true_Bltb :
  forall x y:float, is_nan x = false -> is_nan y = false -> Bleb x y = true -> Bltb y x = false.
Proof.
  intros x y Hx Hy Hxy.
  destruct x as [ | [ ] | | ] eqn:Ex, y as [ | [ ] | | ] eqn:Ey; try easy; rewrite <- Ex, <- Ey in *;
  assert (Fx: is_finite x = true) by (rewrite Ex; auto);
  assert (Fy: is_finite y = true) by (rewrite Ey; auto);
  apply (Bleb_Rle _ _ Fx Fy) in Hxy;
  apply not_true_is_false; intros Hcontr;
  apply (Bltb_Rlt _ _ Fy Fx) in Hcontr;
  lra.
Qed.

Definition Bmax (f1 f2 : float) : float :=
  if is_nan f1 || is_nan f2 then NaN
  else if Bleb f1 f2 then f2
  else f1.

Definition Bmin (f1 f2 : float) : float :=
  if is_nan f1 || is_nan f2 then NaN
  else if Bleb f1 f2 then f1
  else f2.

Lemma Bmax_max_1 :
  forall x y, (Bmax x y = x \/ Bmax x y = y).
Proof.
  intros [ ] [ ]; unfold Bmax; destruct Bleb; intuition.
Qed.

Lemma Bmax_max_2 :
  forall x y, is_finite x = true -> is_finite y = true -> x <= Bmax x y  /\ y <= Bmax x y.
Proof.
  intros x y Fx Fy; unfold Bmax.
  assert (HnanX: is_nan x = false) by fdestruct x.
  assert (HnanY: is_nan y = false) by fdestruct y.
  rewrite HnanX, HnanY; simpl.
  split.
  - destruct (Bleb x y) eqn:?; auto.
    apply Bleb_refl; fdestruct x.
  - destruct (Bleb x y) eqn:E.
    + apply Bleb_refl; fdestruct y.
    + apply Bleb_false_Bltb in E; auto.
      now apply Bltb_Bleb in E.
Qed.

Lemma Bmax_le :
  forall x y z : float, x <= z -> y <= z -> Bmax x y <= z.
Proof.
  intros x y z Hxz Hyz.
  assert (HnanX: is_nan x = false) by fdestruct x.
  assert (HnanY: is_nan y = false) by fdestruct y.
  unfold Bmax.
  rewrite HnanX, HnanY; simpl.
  now destruct (Bleb x y).
Qed.

Lemma Bmax_not_nan_inv :
  forall x y, is_nan (Bmax x y) = false -> is_nan x = false /\ is_nan y = false.
Proof.
  intros; split.
  + fdestruct x.
  + fdestruct x; fdestruct y.
Qed.

Lemma Bmin_not_nan_inv :
  forall x y, is_nan (Bmin x y) = false -> is_nan x = false /\ is_nan y = false.
Proof.
  intros; split.
  + fdestruct x.
  + fdestruct x; fdestruct y.
Qed.

Lemma Bmax_le_inv :
  forall x y z : float, Bmax x y <= z -> x <= z /\ y <= z.
Proof.
  intros x y z Hxyz.
  assert (is_nan (Bmax x y) = false) by (fdestruct (Bmax x y)).
  unfold Bmax in Hxyz.
  apply Bmax_not_nan_inv in H.
  destruct H as [H1 H2].
  rewrite H1, H2 in Hxyz.
  simpl in *.
  destruct (Bleb x y) eqn:E; split; auto.
  - now apply (Bleb_trans x y z).
  - apply Bleb_false_Bltb in E; auto.
    apply Bltb_Bleb in E; auto.
    now apply (Bleb_trans y x z).
Qed.

Lemma Bmin_min_1 :
  forall x y, (Bmin x y = x \/ Bmin x y = y).
Proof.
  intros [ ] [ ]; unfold Bmin; destruct Bleb; intuition.
Qed.

Lemma Bmin_min_2 :
  forall x y, is_finite x = true -> is_finite y = true -> Bmin x y <= x /\ Bmin x y <= y.
Proof.
  intros x y Fx Fy; unfold Bmin.
  assert (HnanX: is_nan x = false) by fdestruct x.
  assert (HnanY: is_nan y = false) by fdestruct y.
  rewrite HnanX, HnanY; simpl.
  split.
  - destruct (Bleb x y) eqn:?.
    + apply Bleb_refl; fdestruct x.
    + assert (Hx : is_nan x = false) by (fdestruct x).
      assert (Hy : is_nan y = false) by (fdestruct y).
      apply Bleb_false_Bltb in Heqb; auto.
      apply Bltb_Rlt in Heqb; auto.
      apply Rle_Bleb; auto.
      lra.
  - destruct (Bleb x y) eqn:E; auto.
    apply Bleb_refl; fdestruct y.
Qed.

Lemma Bmin_le :
  forall x y z : float, z <= x -> z <= y -> z <= Bmin x y.
Proof.
  intros x y z Hxz Hyz.
  assert (HnanX: is_nan x = false) by (fdestruct z; fdestruct x).
  assert (HnanY: is_nan y = false) by (fdestruct z; fdestruct y).
  unfold Bmin.
  rewrite HnanX, HnanY; simpl.
  now destruct (Bleb x y).
Qed.

Lemma Bmin_le_inv :
  forall x y z : float, z <= Bmin x y -> z <= x /\ z <= y.
Proof.
  intros x y z Hxyz.
  assert (is_nan (Bmin x y) = false) by (fdestruct (Bmin x y); fdestruct z).
  unfold Bmin in Hxyz.
  apply Bmin_not_nan_inv in H.
  destruct H as [H1 H2].
  rewrite H1, H2 in Hxyz.
  simpl in *.
  destruct (Bleb x y) eqn:E; split; auto.
  - now apply (Bleb_trans z x y).
  - apply Bleb_false_Bltb in E; auto.
    apply Bltb_Bleb in E.
    now apply (Bleb_trans z y x).
Qed.

Lemma Bpred_not_nan :
  forall (x : float), is_nan x = false -> is_nan (Bpred x) = false.
Proof.
  intros x <-.
  apply is_nan_Bpred.
Qed.

End Utils.

Arguments le_not_nan {prec} {emax}.
Arguments le_not_nan_l {prec} {emax}.
Arguments le_not_nan_r {prec} {emax}.
Arguments is_nan_inv {prec} {emax}.
Arguments is_infm {prec} {emax}.
Arguments is_infp {prec} {emax}.
Arguments is_inf {prec} {emax}.
Arguments Bplus_not_nan_inv {prec} {emax} {Hprec} {Hemax}.
Arguments Bplus_nan_inv {prec} {emax} {Hprec} {Hemax}.
Arguments Bmin {prec} {emax}.
Arguments Bmax {prec} {emax}.
Arguments Bmax_max_1 {prec} {emax}.
Arguments Bmax_max_2 {prec} {emax}.
Arguments Bmin_min_1 {prec} {emax}.
Arguments Bmin_min_2 {prec} {emax}.
Arguments Bleb_trans {prec} {emax}.
Arguments Bltb_Bleb_trans {prec} {emax}.
