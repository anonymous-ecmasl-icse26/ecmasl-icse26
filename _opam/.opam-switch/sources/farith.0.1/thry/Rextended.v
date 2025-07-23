(*********************************************************
       Extension of R with special values +oo, -oo
**********************************************************)

From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import ZArith Psatz Reals SpecFloat.
Require Import Utils.

Set Implicit Arguments.

(**
  Inject BinarySingleNan in R extended with infinities
*)
Section Rextended.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float := binary_float prec emax.

(** Reals extended with +oo, -oo *)
Inductive Rx : Type :=
  | Real : R -> Rx
  | Inf  : bool -> Rx.

Definition R_imax : R := Raux.bpow Zaux.radix2 emax.

Definition R_fmax : R := Raux.bpow Zaux.radix2 emax - Raux.bpow Zaux.radix2 (emax - prec).

Program Definition F_fmax : float := B754_finite false (Z.to_pos (Zpower 2 prec - 1)%Z) (emax - prec) _.
Next Obligation.
  refine (binary_overflow_correct prec emax _ _ mode_ZR false).
Defined.

Lemma R2F_fmax:
  R_fmax = B2R (F_fmax).
Proof.
  unfold FLX.Prec_gt_0 in Hprec.
  unfold Prec_lt_emax in Hemax.
  assert (0 < emax)%Z by lia.
  unfold R_fmax, F_fmax, B2R, Defs.F2R; simpl.
  destruct prec eqn:E; try easy.
  rewrite Z2Pos.id.
  - rewrite <- E, minus_IZR.
    replace 2%Z with (Zaux.radix_val Zaux.radix2) by auto.
    rewrite Raux.IZR_Zpower by lia.
    rewrite Rmult_minus_distr_r.
    rewrite <- Raux.bpow_plus.
    replace (prec + (emax - prec))%Z with emax by lia.
    lra.
  - assert (1 < 2 ^ (Z.pos p))%Z.
    + replace 2%Z with (Zaux.radix_val Zaux.radix2) by auto.
      apply Zaux.Zpower_gt_1; lia.
    + lia.
Qed.

Lemma F_fmax_max :
  forall (x : float), is_finite x = true -> Bleb x F_fmax = true. 
Proof.
  intros [ [ ] | [ ] | | [ ] m e Hbound'] Fx; auto.
  apply Rle_Bleb; auto.
  rewrite <- R2F_fmax.
  now apply bounded_le_emax_minus_prec.
Qed.

Lemma F_fmax_min :
  forall (x : float), is_finite x = true -> Bleb (Bopp F_fmax) x = true. 
Proof.
  intros [ [ ] | [ ] | | [ ] m e Hbound'] Fx; auto.
  apply Rle_Bleb; auto.
  rewrite pos_Bopp_neg, B2R_Bopp, B2R_Bopp, <- R2F_fmax.
  apply Ropp_le_contravar.
  now apply bounded_le_emax_minus_prec.
Qed.

Lemma Rimax_Rfmax :
  (R_fmax < R_imax)%R.
Proof.
  apply minus_pos_lt, Raux.bpow_gt_0.
Qed.

Definition leb (x y : Rx) :=
  match x with
  | Inf true => true
  | Inf false =>
    match y with
    | Inf s => negb s
    | _ => false
    end
  | Real r1 =>
    match y with
    | Inf b => negb b
    | Real r2 => Raux.Rle_bool r1 r2
    end
  end.

Definition fexp := SpecFloat.fexp prec emax.

Definition do_overflow (m : mode) (x : R) : bool :=
  let fexp := SpecFloat.fexp prec emax in
  let rsum := Generic_fmt.round Zaux.radix2 fexp (round_mode m) x in
  Raux.Rle_bool R_imax (Rabs rsum).

Definition dont_overflow (m : mode) (x : R) : bool :=
  let fexp := SpecFloat.fexp prec emax in
  let rsum := Generic_fmt.round Zaux.radix2 fexp (round_mode m) x in
  Raux.Rlt_bool (Rabs rsum) R_imax.

Lemma do_overflow_false :
  forall m r, do_overflow m r = false -> dont_overflow m r = true.
Proof.
  intros. unfold do_overflow, dont_overflow in *.
  now rewrite <- Raux.negb_Rlt_bool, H.
Qed.

Lemma do_overflow_true :
  forall m r, do_overflow m r = true -> dont_overflow m r = false.
Proof.
  intros. unfold do_overflow, dont_overflow in *.
  now rewrite <- Raux.negb_Rlt_bool, H.
Qed.

Lemma dont_overflow_true : 
  forall m r, dont_overflow m r = true -> do_overflow m r = false.
Proof.
  intros. unfold do_overflow, dont_overflow in *.
  now rewrite <- Raux.negb_Rle_bool, Bool.negb_false_iff.
Qed.

Lemma dont_overflow_false : 
  forall m r, dont_overflow m r = false -> do_overflow m r = true.
Proof.
  intros. unfold do_overflow, dont_overflow in *.
  now rewrite <- Bool.negb_false_iff, Raux.negb_Rlt_bool.
Qed.

Lemma F2R_congr :
  forall m1 e1 m2 e2, m1 = m2 -> e1 = e2 ->
  @Defs.F2R Zaux.radix2 {| Defs.Fnum := m1; Defs.Fexp := e1 |} = 
  @Defs.F2R Zaux.radix2 {| Defs.Fnum := m2; Defs.Fexp := e2 |}.
Proof. congruence. Qed.

Definition round (m : mode) (r : Rx) : Rx :=
  match r with
  | Real x =>
    if do_overflow m x then
      if overflow_to_inf m (sign x) then Inf (sign x)
      else Real (B2R (if sign x then Bopp F_fmax else F_fmax))
    else
      Real (Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode m) x)
  | _  => r
  end.

(* Lemma about_Zceil :
  forall (r : R), (0 < r)%R -> (0 < Raux.Zceil r)%Z.
Proof.
  intros.
  Search (_ <= Raux.Zceil _)%Z.
  unfold Raux.Zceil, Raux.Zfloor.
  apply Z.opp_lt_mono.
  rewrite Z.opp_involutive.
  simpl.
  pose proof (archimed r).
  destruct H0. *)

Lemma about_Zneg :
  forall z, (Z.neg z = - Z.pos z)%Z.
Proof. reflexivity. Qed.
  
(**
  TODO : In fact, this one can be obtained from Flocq's bounded_canonical_lt_emax
*)
Lemma dont_overflow_inv :
  forall m (r : R),
    do_overflow m r = false ->
    exists (f : float), Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode m) r = B2R f /\ is_finite f = true.
Proof.
  (*Check bounded_canonical_lt_emax.
  intros mode r Hr.
  apply do_overflow_false in Hr.
  unfold dont_overflow in Hr.
  apply Rltb_Rlt in Hr.
  unfold R_imax in Hr.
  set (r' := Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode mode) r).
  set (e := Generic_fmt.cexp Zaux.radix2 (SpecFloat.fexp prec emax) r').
  set (m' := Generic_fmt.scaled_mantissa Zaux.radix2 (SpecFloat.fexp prec emax) r').
  destruct (Zaux.Zcompare_spec (round_mode mode (Generic_fmt.scaled_mantissa Zaux.radix2 (SpecFloat.fexp prec emax) r')) 0%Z).
  + assert (Generic_fmt.generic_format Zaux.radix2 (SpecFloat.fexp prec emax) r').
    unfold r'. apply Generic_fmt.generic_format_round; intuition.
    now apply fexp_correct.
    elim (Generic_fmt.canonical_generic_format Zaux.radix2 (SpecFloat.fexp prec emax) (Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode mode) r) H0).
    intros [ ] [H1 H2].
    set (m := Z.to_pos (Z.abs Fnum)).
    assert (Hbound : SpecFloat.bounded prec emax m e = true).
    apply bounded_canonical_lt_emax; auto.
    unfold m. admit.
    Check (binary_normalize). *)
  intros mode r Hr.
  apply do_overflow_false in Hr.
  unfold dont_overflow in Hr.
  apply Rltb_Rlt in Hr.
  set (e := Generic_fmt.cexp Zaux.radix2 (SpecFloat.fexp prec emax) r).
  set (m' := Generic_fmt.scaled_mantissa Zaux.radix2 (SpecFloat.fexp prec emax) r).
  set (m := Z.to_pos (Z.abs (round_mode mode m'))).
  destruct (Zaux.Zcompare_spec (round_mode mode (Generic_fmt.scaled_mantissa Zaux.radix2 (SpecFloat.fexp prec emax) r)) 0%Z).
  + assert (Hbound : SpecFloat.bounded prec emax m e = true) by admit.
    eexists (B754_finite true m e Hbound); split; auto.
    unfold Generic_fmt.round; simpl.
    apply F2R_congr; try easy.
    unfold m, m'.
    rewrite about_Zneg.
    rewrite Z2Pos.id; lia.
  + eexists (B754_zero _); split; auto.
    unfold Generic_fmt.round, Defs.F2R.
    rewrite H. simpl. lra.
  + eexists (B754_finite false m e _); split; auto.
    unfold Generic_fmt.round; simpl.
    apply F2R_congr; try easy.
    unfold m, m'.
    rewrite Z2Pos.id; lia.
Admitted.

Lemma R_imax_gt_0: (R_imax > 0)%R.
  apply Raux.bpow_gt_0.
Qed.

Lemma F_fmax_ge_0: (B2R F_fmax >= 0)%R.
  simpl.
  unfold Defs.F2R; simpl.
  apply Rle_ge, Rmult_le_pos.
  + apply IZR_le; lia.
  + left; apply Raux.bpow_gt_0.
Qed.

Ltac fformat :=
  try intuition; try apply fexp_correct.

Theorem generic_format_Rimax :
  Generic_fmt.generic_format Zaux.radix2 fexp R_imax.
Proof.
  intros.
  red; unfold Defs.F2R, R_imax; simpl.
  rewrite <- Generic_fmt.scaled_mantissa_generic.
  + unfold Generic_fmt.scaled_mantissa.
    rewrite Rmult_assoc, Rmult_comm.
    rewrite <- Raux.bpow_plus.
    rewrite (Zplus_comm)%R.
    rewrite Zegal_left by lia; simpl; lra.
  + apply (Generic_fmt.generic_format_bpow Zaux.radix2 fexp emax).
    unfold fexp, SpecFloat.fexp, SpecFloat.emin.
    unfold FLX.Prec_gt_0 in *.
    unfold Prec_lt_emax in *.
    lia.
Qed.

Theorem round_Rimax :
  forall m, Generic_fmt.round Zaux.radix2 fexp (round_mode m) R_imax = R_imax.
Proof.
  intros.
  apply Generic_fmt.round_generic; intuition.
  apply generic_format_Rimax.
Qed.

Lemma Rltb_lt :
  forall x y, Raux.Rlt_bool x y = true -> (x < y)%R.
Proof.
  intros.
  pose proof (Hp := Raux.Rlt_bool_spec x y).
  rewrite H in Hp.
  now inversion Hp.
Qed.

Lemma Rimax_float :
  exists m e, R_imax = Defs.F2R (Defs.Float Zaux.radix2 m e).
Proof.
  exists 1%Z.
  unfold R_imax, Defs.F2R; simpl.
  eexists.
  symmetry.
  apply Rmult_1_l.
Qed.

Lemma incr_R_fmax_R_imax :
  @Defs.F2R Zaux.radix2 {| Defs.Fnum := (Zpower 2 prec - 1 + 1)%Z ; Defs.Fexp := (emax - prec) |} = R_imax.
Proof.
  unfold Defs.F2R, R_imax; simpl.
  replace (2 ^ prec - 1 + 1)%Z with (2 ^ prec)%Z by lia.
  rewrite (Raux.IZR_Zpower Zaux.radix2).
  + rewrite <- Raux.bpow_plus.
    replace (prec + (emax - prec))%Z with (emax) by lia.
    reflexivity.
  + unfold FLX.Prec_gt_0 in Hprec.
    unfold Prec_lt_emax in Hemax.
    lia.
Qed.

Theorem do_overflow_iff:
  forall m x,
    let fexp := SpecFloat.fexp prec emax in
    let rx := Generic_fmt.round Zaux.radix2 fexp (round_mode m) x in
    do_overflow m x = true <-> (Raux.Rle_bool R_imax rx = true \/ Raux.Rle_bool rx (-R_imax)%R = true).
Proof.
  intros; split; intros.
  - unfold do_overflow in H.
    unfold Rabs in H.
    destruct Rcase_abs.
    + apply Rleb_Rle in H.
      right. apply Raux.Rle_bool_true.
      apply Ropp_le_contravar in H.
      replace (rx) with (--rx)%R by lra.
      subst rx; auto.
    + apply Rleb_Rle in H.
      left. apply Raux.Rle_bool_true.
      auto.
  - destruct H; apply Raux.Rle_bool_true; apply Rleb_Rle in H.
    + eauto using Rle_trans, H, Rle_abs.
    + apply Ropp_le_contravar in H.
      replace (--R_imax)%R with R_imax in H by lra.
      pose proof R_imax_gt_0.
      assert (0 <= -rx)%R by lra.
      assert (0 > rx)%R by lra.
      assert (-rx > rx)%R by lra.
      assert (Rabs rx = - rx)%R by auto using Rabs_left.
      rewrite <- H4 in H.
      auto.
Qed.

Lemma overflow_is_le :
  forall m r1 r2, 
    (r1 <= r2)%R ->
    (0 <= r1)%R ->
    do_overflow m r1 = true ->
    do_overflow m r2 = true.
Proof.
  intros m r1 r2 Hle Hr1 Ho.
  rewrite do_overflow_iff in Ho. destruct Ho as [H | H].
  - apply Rleb_Rle in H.
    rewrite do_overflow_iff. left.
    apply Raux.Rle_bool_true.
    eapply Generic_fmt.round_le in Hle.
    + eapply Rle_trans; [apply H | apply Hle].
    + now apply fexp_correct.
    + intuition.
  - apply Rleb_Rle in H.
    assert (-R_imax < 0)%R.
    { assert (R_imax > 0)%R by apply R_imax_gt_0. lra. }
    pose proof H0.
    apply Rlt_le in H1.
    eapply Generic_fmt.round_le in Hr1.
    + erewrite Generic_fmt.round_0 in Hr1.
      assert (0 < 0)%R.
      eapply Rle_lt_trans.
      apply Hr1.
      eapply Rle_lt_trans.
      apply H.
      apply H0.
      lra.
      intuition.
    + now apply fexp_correct.
    + intuition.
Qed.

Lemma overflow_is_ge :
  forall m r1 r2, 
    (r1 <= r2)%R ->
    (r2 <= 0)%R ->
    do_overflow m r2 = true ->
    do_overflow m r1 = true.
Proof.
  intros m r1 r2 Hle Hr1 Ho.
  rewrite do_overflow_iff in Ho. destruct Ho as [H | H].
  - apply Rleb_Rle in H.
    rewrite <- (round_Rimax m) in H.
    eapply (Generic_fmt.round_le Zaux.radix2 fexp (round_mode m)) in Hr1; intuition.
    rewrite Generic_fmt.round_0 in Hr1.
    assert (Generic_fmt.round Zaux.radix2 fexp (round_mode m) R_imax <= 0)%R.
    + eapply Rle_trans.
      * apply H.
      * apply Hr1.
    + pose proof R_imax_gt_0.
      rewrite (round_Rimax m) in H0.
      lra.
    + intuition.
  - apply Rleb_Rle in H.
    rewrite do_overflow_iff. right.
    apply Raux.Rle_bool_true.
    apply (Generic_fmt.round_le Zaux.radix2 fexp (round_mode m)) in Hle.
    eapply Rle_trans.
    + apply Hle.
    + apply H.
Qed.

Lemma round_0:
  forall m,
  Real 0 = round m (Real 0).
Proof.
  intros m.
  unfold round.
  assert (H: do_overflow m 0 = false).
  { unfold do_overflow, R_imax.
    rewrite Generic_fmt.round_0 by fformat.
    rewrite Rabs_R0.
    apply Raux.Rle_bool_false.
    apply Raux.bpow_gt_0.
  }
  rewrite H.
  now rewrite Generic_fmt.round_0 by fformat.
Qed.

Theorem round_le:
  forall (m : mode) (r1 r2 : Rx), leb r1 r2 = true -> leb (round m r1) (round m r2) = true.
Proof.
  intros m [ r1 | [] ] [r2 | []] H; try easy.
  Ltac fbounded :=
    match goal with
    | [ Ho1 : do_overflow _ _ = false |- _ ] =>
      apply Raux.Rle_bool_true;
      destruct (dont_overflow_inv _ _ Ho1) as (f & [?Hreq ?Hf]);
      rewrite ?Hreq; first [now apply Bleb_Rle, F_fmax_min | now apply Bleb_Rle, F_fmax_max ]
  end.
  Ltac freals :=
    match goal with
    | [ H : Raux.Rle_bool _ _ = true |- _ ] =>
      apply Raux.Rle_bool_true; apply Rleb_Rle in H;
      now apply Generic_fmt.round_le; fformat
  end.
  Ltac finfinites :=
    simpl; now destruct overflow_to_inf eqn:?, do_overflow eqn:?, sign eqn:?.
  Ltac absurd_sign :=
    match goal with
    | [ Hs2 : sign _ = true, Hs1 : sign _ = false, H : Raux.Rle_bool _ _ = true |- _ ] =>
      now rewrite (pos_Rleb_neg _ _ Hs1 Hs2) in H
  end.
  Ltac absurd_mode :=
    match goal with
    | [ m : mode |- _] => now destruct m
  end.
  Ltac absurd_overflow :=
    match goal with
    | [ H : Raux.Rle_bool _ _ = true,
        Hs : sign _ = false,
        Ho1 : do_overflow _ _ = true,
        Ho2 : do_overflow _ _ = false
        |- _ 
      ] => apply Rleb_Rle in H; now rewrite (overflow_is_le _ H (sign_pos_inv _ Hs) Ho1) in Ho2
    | [ H : Raux.Rle_bool _ _ = true,
        Hs : sign _ = true,
        Ho1 : do_overflow _ _ = false,
        Ho2 : do_overflow _ _ = true
      |- _
      ] => apply Rleb_Rle in H; now rewrite (overflow_is_ge _ H (sign_neg_inv _ Hs) Ho2) in Ho1
    | [ H : Raux.Rle_bool _ _ = false,
      Hs : sign _ = true,
      Ho1 : do_overflow _ _ = true,
      Ho2 : do_overflow _ _ = false
      |- _ 
    ] => apply Rleb_Rle in H; now rewrite (overflow_is_ge _ H (sign_neg_inv _ Hs) Ho2) in Ho1
    | [ H1 : overflow_to_inf _ _ = true, H2 : overflow_to_inf _ _ = false |- _ ] =>
      now rewrite H1 in H2
    end.
  Ltac absurd_case :=
    match goal with
    | [r1 : R, r2 : R |- _ ] =>
      try absurd_mode; try absurd_sign; absurd_overflow
  end.
  Ltac sign_analysis :=
    match goal with
    | [r1 : R, r2 : R |- _ ] =>
      destruct (sign r1) eqn:Hs1, (sign r2) eqn:Hs2; auto
  end.
  - simpl in H. unfold round.
    destruct (do_overflow m r1) eqn:Ho1;
    destruct (do_overflow m r2) eqn:Ho2;
    destruct (overflow_to_inf m (sign r1)) eqn:Hi1;
    destruct (overflow_to_inf m (sign r2)) eqn:Hi2;
    (try freals); sign_analysis; try absurd_case; try fbounded ; simpl.
    + unfold Raux.Rle_bool.
      destruct Raux.Rcompare eqn:E; try easy.
      apply Raux.Rcompare_Gt_inv in E; lra.
    + unfold Raux.Rle_bool.
      destruct Raux.Rcompare eqn:E; try easy.
      apply Raux.Rcompare_Gt_inv in E.
      unfold Defs.F2R in E; simpl in E.
      apply Rmult_lt_reg_r in E.
      * apply lt_IZR in E; lia.
      * apply Raux.bpow_gt_0.
    + unfold Raux.Rle_bool.
      destruct Raux.Rcompare eqn:E; try easy.
      apply Raux.Rcompare_Gt_inv in E; lra.
    (* + apply Raux.Rle_bool_true.
      apply do_overflow_false in Ho2.
      unfold dont_overflow in Ho2.
      apply Rltb_Rlt in Ho2.
      apply Raux.Rabs_lt_inv in Ho2.
      destruct Ho2 as [Ho2 Ho2'].
      Search ()
      assert (- R_imax)
      assert (R_imax < (Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax)
      (round_mode m) r2))%R.

      unfold R_imax in Ho2.

      destruct (dont_overflow_inv _ _ Ho2) as (f & [?Hreq ?Hf]).
      unfold Generic_fmt.round, Defs.F2R; simpl.
      Raux.bpow_simplify.
      unfold FLX.Prec_gt_0 in Hprec.
      unfold Prec_lt_emax in Hemax.
      rewrite <- Raux.IZR_Zpower by lia.
      rewrite <- mult_IZR.
      rewrite <- Raux.IZR_Zpower.
      unfold Generic_fmt.cexp.
      rewrite <- mult_IZR.
      apply IZR_le.
      rewrite Hreq.
      unfold Generic_fmt.round. apply F2R_congr. *)
  - finfinites.
Qed.

Lemma round_inf :
  forall m b, round m (Inf b) = Inf b.
Proof. reflexivity. Qed.


Example leb_infp_true :
  forall x, leb x (Inf false) = true.
Proof. now induction x as [ | [ ] ]. Qed.

Example leb_infm_true :
  forall x, leb (Inf true) x = true.
Proof. now induction x as [ | [ ] ]. Qed.

Example leb_real :
  forall r1 r2, leb (Real r1) (Real r2) = Raux.Rle_bool r1 r2.
Proof. reflexivity. Qed.

Example leb_refl :
  forall x, leb x x = true.
Proof.
  induction x as [ | [ ] ]; auto.
  apply Raux.Rle_bool_true; lra.
Qed.

Definition add (x y : Rx) : Rx :=
  match x with
  | Inf true => x
  | Inf false =>
    match y with
    | Inf true => Inf true
    | _ => x
    end
  | Real r =>
    match y with
    | Inf _ => y
    | Real r' => Real (r + r')%R
    end
  end.

Lemma leb_trans :
  forall x y z : Rx, leb x y = true -> leb y z = true -> leb x z = true.
Proof.
  intros [ rx | [ ] ] [ ry | [ ] ] [ rz | [ ] ] Hxy Hyz; simpl in *; try easy.
  apply Rleb_Rle in Hxy.
  apply Rleb_Rle in Hyz.
  apply Raux.Rle_bool_true.
  lra.
Qed.

Lemma add_leb_mono_l :
  forall x y z : Rx,
  leb x y = true -> leb (add x z) (add y z) = true.
Proof.
  intros [ ] [ ] [ ] H.
  - simpl in *.
    apply Rleb_Rle in H.
    apply Raux.Rle_bool_true.
    lra.
  - now destruct b.
  - now destruct b.
  - now destruct b, b0.
  - now destruct b.
  - now destruct b, b0.
  - now destruct b, b0.
  - now destruct b, b0, b1.
Qed.

Lemma add_leb_mono_r :
  forall x y z : Rx,
  leb x y = true -> leb (add z x) (add z y) = true.
Proof.
  intros [ | [ ]] [ | [ ]] [ | [ ]] H; try easy.
  simpl in *.
  apply Rleb_Rle in H.
  apply Raux.Rle_bool_true.
  lra.
Qed.

Lemma add_real :
  forall (r1 r2 : R), add (Real r1) (Real r2) = Real (r1 + r2)%R.
Proof. reflexivity. Qed.

Lemma add_0_l:
  forall r : Rx, add (Real 0) r = r.
Proof. destruct r; simpl; intuition. Qed.

Lemma add_0_r:
  forall r : Rx, add r (Real 0) = r.
Proof. destruct r; try destruct b; simpl; intuition. Qed.

Definition mult (x y : Rx) : Rx :=
  match x, y with
  | Inf sx, Inf sy => Inf (xorb sx sy)
  | Real rx, Inf sy => Inf (xorb (sign rx) sy)
  | Inf sx, Real ry => Inf (xorb sx (sign ry))
  | Real rx, Real ry => Real (rx * ry)%R
  end.

Lemma mult_leb_mono_l :
  forall x y z : Rx,
  leb (Real 0) z = true ->
  leb x y = true -> leb (mult x z) (mult y z) = true.
Admitted.

Definition B2Rx (x : float) :=
  match x with
  | B754_infinity b => Inf b
  | _ => Real (B2R x)
  end.


Lemma B2Rx_finite :
  forall (f : float),
  is_finite f = true -> B2Rx f = Real (B2R f).
Proof. now destruct f. Qed.

Lemma bounded_dont_overflow :
  forall mode s m e (H : SpecFloat.bounded prec emax m e = true),
    dont_overflow mode (B2R (B754_finite s m e H)) = true.
Proof.
  intros.
  unfold dont_overflow.
  apply Raux.Rlt_bool_true.
  apply Raux.Rabs_lt; split.
  + rewrite Generic_fmt.round_generic by (intuition; apply generic_format_B2R).
    rewrite <- Ropp_involutive.
    apply Ropp_lt_contravar.
    rewrite <- B2R_Bopp; simpl (Bopp _).
    apply (Rle_lt_trans _ R_fmax).
    - rewrite R2F_fmax. auto using Bleb_Rle, F_fmax_max.
    - apply Rimax_Rfmax.
  + rewrite Generic_fmt.round_generic by (intuition; apply generic_format_B2R).
    apply (Rle_lt_trans _ R_fmax).
    - rewrite R2F_fmax. auto using Bleb_Rle, F_fmax_max.
    - apply Rimax_Rfmax.
Qed.

Lemma round_id :
  forall m (f : float),
    B2Rx f = round m (B2Rx f).
Proof.
  intros m; destruct f as [ [ ] | [ ] | | ]; try easy.
  + simpl (B2Rx _); apply round_0.
  + simpl (B2Rx _); apply round_0.
  + simpl (B2Rx _); apply round_0.
  + unfold B2Rx, round.
    rewrite (dont_overflow_true _ _ (bounded_dont_overflow m s m0 e e0)).
    now rewrite Generic_fmt.round_generic by (intuition; apply generic_format_B2R).
Qed.

Lemma B2Rx_le :
  forall (x y : float),
  is_nan x = false ->
  is_nan y = false ->
  leb (B2Rx x) (B2Rx y) = true ->
  Bleb x y = true.
Proof.
  intros x y Hx Hy Hxy.
  fdestruct x; fdestruct y;
  repeat (unfold B2Rx in Hxy);
  unfold leb in Hxy;
  apply Rle_Bleb; try easy;
  now apply Rleb_Rle.
Qed.

Ltac fdestruct f :=
  destruct f as [ [ ] | [ ] | | ] eqn:?E; try easy.

Lemma B2Rx_B2R :
  forall (x : float),
  is_finite x = true ->
  B2Rx x = Real (B2R x).
Proof. now intros [ ] Fx. Qed.

Lemma le_B2Rx :
  forall (x y : float),
  Bleb x y = true ->
  leb (B2Rx x) (B2Rx y) = true.
Proof.
  Ltac by_comparison :=
    match goal with
    | [ x : _, y : _, E : _, E0 : _, H : _ |- _ ] =>
      rewrite <- E, <- E0 in H;
      unfold Bleb, SpecFloat.SFleb in H;
      replace (SpecFloat.SFcompare (B2SF _) (B2SF _)) with (Bcompare x y) in H by auto;
      rewrite E, E0 in *;
      rewrite Bcompare_correct in H by auto;
      rewrite B2Rx_B2R by auto;
      rewrite B2Rx_B2R, leb_real by auto;
      destruct (Raux.Rcompare _) eqn:Cmp in H; try easy;
      [ apply Raux.Rcompare_Eq_inv in Cmp | apply Raux.Rcompare_Lt_inv in Cmp ];
      apply Raux.Rle_bool_true; lra
    end.
  Ltac by_computation :=
      simpl; apply Raux.Rle_bool_true; lra.
  intros.
  fdestruct x; fdestruct y; try by_computation; by_comparison.
Qed.

Definition SF2Rx (x : SpecFloat.spec_float) :=
  match x with
  | S754_infinity b => Inf b
  | _ => Real (SF2R Zaux.radix2 x)
  end.

Lemma B2Rx_SF2Bx :
  forall (x : SpecFloat.spec_float) (Hx : SpecFloat.valid_binary prec emax x = true),
       B2Rx (SF2B x Hx) = SF2Rx x.
Proof.
  destruct x; trivial.
Qed.

End Rextended.

Arguments round {prec} {emax} {Hprec} {Hemax}.
Arguments round_le {prec} {emax} {Hprec} {Hemax}.
Arguments B2Rx {prec} {emax}.
Arguments B2Rx_le {prec} {emax}.
Arguments le_B2Rx {prec} {emax}.
Arguments B2Rx_B2R {prec} {emax}.
Arguments B2Rx_finite {prec} {emax}.
