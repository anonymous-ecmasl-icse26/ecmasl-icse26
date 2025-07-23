From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import ZArith Psatz Reals.
From F Require Import Utils Correction_thms Rextended.

(** 
  The usual ordering relation on [binary_float] is [Bleb]. As defined
  in IEEE754, [Bleb] does'nt discriminate the signed zeros and thus 
  zeros are always in relation regardless of the sign.

  We introduce a new relation [Fle0] that extends [Bleb] but discriminates
  signed zeros. [Fle0] can be proven to be antisymmetric whereas [Bleb] is not.
*)
Section Fle0.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float := binary_float prec emax.

Definition Fle0 (x y : float) :=
  match x, y with
  | B754_zero s1, B754_zero s2 =>
    if negb s1 then negb s2
    else true
  | _, _ => Bleb x y
  end.

Notation "+0" := (B754_zero false).
Notation "-0" := (B754_zero true).

Example Fle0_PP :
  Fle0 +0 +0 = true.
Proof.
  reflexivity.
Qed.

Example Fle0_PN :
  Fle0 +0 -0 = false.
Proof.
  reflexivity.
Qed.

Example Fle0_NP :
  Fle0 -0 +0 = true.
Proof.
  reflexivity.
Qed.

Example Fle0_NN :
  Fle0 -0 -0 = true.
Proof.
  reflexivity.
Qed.


Example Fle0_sign_true:
  forall (x y : float),
    x <> NaN ->
    y <> NaN ->
    Bsign x = true ->
    Bsign y = false ->
    Fle0 x y = true.
Proof.
  intros.
  fdestruct x; fdestruct y.
  - now destruct s.
  - now destruct s.
  - now destruct s, s0.
Qed.


(**
  Contrary to Bleb, Fle0 is antisymmetric 
  with respect to Coq's default equality
*)
Lemma Fle0_antysim:
  forall (x y : float),
    Fle0 x y = true ->
    Fle0 y x = true ->
    x = y.
Proof.
  intros x y Hxy Hyx.
  fdestruct x; fdestruct y; try now destruct s.
  simpl in Hxy, Hyx.
  apply (Bleb_antisymm_strict _ _ _ _ (conj Hxy Hyx)).
  now destruct s.
Qed.

(** 
  [Fle0] is included in [Bleb].
*)
Lemma Fle0_Bleb:
  forall (x y : float),
  Fle0 x y = true -> Bleb x y = true.
Proof.
  fdestruct x; fdestruct y.
Qed.

(**
  [Fle0] is transitive
*)
Lemma Fle0_trans:
  forall (x y z : float),
  Fle0 x y = true -> Fle0 y z = true -> Fle0 x z = true.
Proof.
  intros.
  fdestruct y; fdestruct x; fdestruct z;
  try (now destruct s, s0);
  try (now destruct s).
  apply (Bleb_trans _ _ _ H H0).
Qed.

Lemma Fle0_refl:
  forall (x : float),
  is_nan x = false ->
  Fle0 x x = true.
Proof.
  intros. fdestruct x.
  now apply Beqb_Bleb, Beqb_refl.
Qed.

(* Inductive interv : Type :=
  | I_val : float -> interv
  | I_closed : forall (lo hi : float) (nan : bool) (H : Bltb lo hi = true), interv.

Definition contains (i : interv) (x : float) : Prop :=
  match i with
  | I_val v => x = v
  | I_closed lo hi nan _ =>
    (x = NaN /\ nan = true) \/ lo <= x <= hi
  end. *)



Inductive interv : Type :=
  | I_closed : forall (lo hi : float) (nan : bool) (H : Fle0 lo hi = true), interv
  | I_nan : interv.

Definition contains (i : interv) (x : float) : Prop :=
  match i with
  | I_nan => x = NaN
  | I_closed lo hi nan _ =>
    (x = NaN /\ nan = true) \/ Fle0 lo x = true /\ Fle0 x hi = true
  end.

Lemma contains_nan :
  forall (i : interv), contains i NaN ->
    (exists a b H, i = I_closed a b true H)
    \/ i = I_nan.
Proof.
  intros [ ].
  + intros [ [_ ->] | ]; try easy.
    left; repeat eexists.
  + now right.
Qed.

Example szerop := I_closed (+0) (+0) false eq_refl.

Example szerom := I_closed (-0) (-0) false eq_refl.

Example contains_szerop :
  forall x, contains szerop x -> x = +0.
Proof.
  intros x [ [Hx ? ] | ]; try easy.
  now apply Fle0_antysim.
Qed.

Example contains_szerom :
  forall x, contains szerom x -> x = -0.
Proof.
  intros x [ [Hx ? ] | ]; try easy.
  now apply Fle0_antysim.
Qed.

Example szero := I_closed (-0) (+0) false eq_refl.

Example contains_szero:
  forall x, contains szero x -> (x = -0 \/ x = +0).
Proof.
  intros x [ [Hx ? ] | ]; try easy.
  fdestruct x; cbn in *.
  + now left.
  + now right.
  + now destruct s.
Qed.

Lemma Bsign_B2SF:
  forall ( x : float ), sign_SF (B2SF x) = Bsign x.
Proof.
  fdestruct x.
Qed.

Lemma Bsign_Bplus :
  forall m (x y : float),
    Bsign x = Bsign y -> Bsign (Bplus m x y) = Bsign x.
Proof.
  intros m x y H.
  fdestruct x; fdestruct y.
  pose proof (BinarySingleNaN.Bplus_correct _ _ _ _ m (B754_finite s m0 e e0) (B754_finite s0 m1 e1 e2) eq_refl eq_refl).
  destruct Raux.Rlt_bool; intuition.
  + destruct Raux.Rcompare eqn:E;
    replace s with s0 in *.
    * now destruct m, s0.
    * rewrite H3.
      destruct s0; try easy; simpl.
      apply Raux.Rcompare_Lt_inv in E.
      cbn in E.
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.pos m0; Defs.Fexp := e |} >= 0)%R. unfold Defs.F2R; simpl.
      pose proof (IZR_pos m0).
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
      nra.
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.pos m1; Defs.Fexp := e1 |} >= 0)%R. unfold Defs.F2R; simpl.
      pose proof (IZR_pos m1).
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e1).
      nra.
      nra.
    * rewrite H3.
      destruct s0; try easy; simpl.
      apply Raux.Rcompare_Gt_inv in E.
      cbn in E.
      pose proof (IZR_neg m0).
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.neg m0; Defs.Fexp := e |} <= 0)%R. unfold Defs.F2R; simpl. nra.
      pose proof (IZR_neg m1).
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e1).
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.neg m1; Defs.Fexp := e1 |} < 0)%R. unfold Defs.F2R; simpl. nra.
      nra.
  + replace s with s0. destruct s0, s; try easy.
    * rewrite <- Bsign_B2SF.
      rewrite H1. simpl.
      unfold binary_overflow.
      destruct overflow_to_inf; reflexivity.
    * rewrite <- Bsign_B2SF.
      rewrite H1. simpl.
      unfold binary_overflow.
      destruct overflow_to_inf; reflexivity.
Qed.

Lemma sum_to_0 :
  forall mode m e H m' e' H',
    Bplus mode (B754_finite true m e H) (B754_finite true m' e' H') <> -0.
Proof.
  intros. intros Hcontr.
  pose proof (BinarySingleNaN.Bplus_correct _ _ _ _ mode (B754_finite true m e H) (B754_finite true m' e' H') eq_refl eq_refl).
  destruct Raux.Rlt_bool; intuition.
  + destruct Raux.Rcompare eqn:E.
    * apply Raux.Rcompare_Eq_inv in E.
      cbn in E.
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.neg m; Defs.Fexp := e |} < 0)%R. unfold Defs.F2R; simpl.
      pose proof (IZR_neg m).
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
      nra.
      assert (@Defs.F2R Zaux.radix2 {| Defs.Fnum := Z.neg m'; Defs.Fexp := e' |} < 0)%R. unfold Defs.F2R; simpl.
      pose proof (IZR_neg m').
      pose proof (Raux.bpow_gt_0 Zaux.radix2 e').
      nra.
      nra.
    * apply Raux.Rcompare_Lt_inv in E.
      apply Rlt_le in E.
      apply (Generic_fmt.round_le Zaux.radix2 (SpecFloat.fexp prec emax)
      (round_mode mode)) in E.
      rewrite Generic_fmt.round_0 in E by intuition.
      rewrite <- H1 in E.
      assert (B2R (Bplus mode (B754_finite true m e H) (B754_finite true m' e' H')) = 0%R) by now rewrite Hcontr.
      destruct E.
      - nra.

Admitted.

Theorem Fle0_is_Bleb_r:
  forall (x y : float),
    (y <> +0 /\ y <> -0) ->
    Fle0 x y = Bleb x y.
Proof.
  fdestruct x; fdestruct y.
Qed.

Theorem Fle0_is_Bleb_l:
  forall (x y : float),
    (x <> +0 /\ x <> -0) ->
    Fle0 x y = Bleb x y.
Proof.
  fdestruct x; fdestruct y.
Qed.

Theorem Bsign_Fle0:
  forall x y,
  is_nan x = false ->
  is_nan y = false ->
  Bsign x = true -> Bsign y = false -> Fle0 x y = true.
Proof.
  intros.
  fdestruct x; fdestruct y.
  + now destruct s.
  + now destruct s.
  + now destruct s, s0.
Qed.

Theorem Bplus_pos:
  forall (x y : float) m,
    Fle0 -0 x = true ->
    Fle0 -0 y = true ->
    Fle0 -0 (Bplus m x y) = true.
Proof.
  intros.
  pose proof Bsign_Bplus m x y.
  fdestruct x; fdestruct y.
  + now destruct m.
  + now destruct m.
  + simpl in H, H0.
    destruct s, s0; try easy.
    apply Bsign_Fle0; try easy.
    - now apply Bplus_finites_not_nan.
    - now apply H1.
Qed.

Theorem finite_Fle0_pos:
  forall (f : float), is_nan f = false -> Bsign f = false -> Fle0 -0 f = true.
Proof.
  intros.
  fdestruct f.
  now destruct s.
Qed.

Theorem finite_Fle0_neg:
  forall (f : float), is_nan f = false -> Bsign f = true -> Fle0 f +0 = true.
Proof.
  intros.
  fdestruct f.
  now destruct s.
Qed.

Inductive Rx0 : Type :=
  | Rx0_NaN  : Rx0
  | Rx0_zero : bool -> Rx0
  | Rx0_inf  : bool -> Rx0
  | Rx0_real : R -> Rx0.

Definition B2Rx0 (f : float) : Rx0 :=
  match f with
  | B754_zero s => Rx0_zero s
  | B754_infinity s => Rx0_inf s
  | NaN => Rx0_NaN
  | B754_finite _ _ _ _ => Rx0_real (B2R f)
  end.

Definition Rx0le (x y : Rx0) : bool :=
  match x with
  | Rx0_NaN => false
  | Rx0_zero s =>
    match y with
    | Rx0_NaN => false
    | Rx0_zero s' => if negb s then negb s' else true
    | Rx0_inf s' => negb s'
    | Rx0_real r => Raux.Rle_bool 0%R r
    end
  | Rx0_inf s =>
    match y with
    | Rx0_NaN => false
    | Rx0_zero s' => s
    | Rx0_inf s' =>
      if negb s then negb s' else true
    | Rx0_real r => s
    end
  | Rx0_real r =>
    if Raux.Req_bool r 0%R then
      match y with
      | Rx0_NaN => false
      | Rx0_zero s' => negb s'
      | Rx0_inf s' => negb s'
      | Rx0_real r' => Raux.Rle_bool r r'
      end
    else
      match y with
      | Rx0_NaN => false
      | Rx0_zero s' => Raux.Rle_bool r 0%R
      | Rx0_inf s' => negb s'
      | Rx0_real r' => Raux.Rle_bool r r'
      end
  end.

Theorem B2Rx0_le:
  forall (x y : float),
    Rx0le (B2Rx0 x) (B2Rx0 y) = true -> x <= y.
Proof.
  intros.
  destruct x as [[ ] | [ ] | | ] eqn:E1; destruct y as [ [ ] | [ ] | | ] eqn:E2; try easy.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    apply Rleb_Rle in H; now apply Rle_Bleb.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    apply Rleb_Rle in H; now apply Rle_Bleb.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    destruct Raux.Req_bool eqn:E.
    * apply Reqb_Req in E.
      apply Rle_Bleb; auto; rewrite E; simpl; lra.
    * apply Rleb_Rle in H.
      now apply Rle_Bleb.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    destruct Raux.Req_bool eqn:E.
    * apply Reqb_Req in E.
    apply Rle_Bleb; auto; rewrite E; simpl; lra.
    * apply Rleb_Rle in H.
      now apply Rle_Bleb.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    now destruct Raux.Req_bool eqn:E.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    now destruct Raux.Req_bool eqn:E.
  + repeat (unfold B2Rx0 in H); unfold Rx0le in H.
    destruct Raux.Req_bool eqn:E;
    apply Rle_Bleb; auto;
    now apply Rleb_Rle in H.
Qed.

Theorem Fle0_B2Rx0 :
  forall (x y : float),
    Fle0 x y = true -> Rx0le (B2Rx0 x) (B2Rx0 y) = true.
Proof.
  intros.
  fdestruct x; fdestruct y;
  repeat (unfold B2Rx0);
  unfold Rx0le.
  - apply Raux.Rle_bool_true; now apply Bleb_Rle in H.
  - apply Raux.Rle_bool_true; now apply Bleb_Rle in H.
  - destruct Raux.Req_bool eqn:E; auto.
    + apply Reqb_Req in E.
      unfold B2R, Defs.F2R in E.
      destruct s; simpl in E.
      * pose proof (IZR_neg m);
        pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
        nra.
      * pose proof (IZR_pos m);
        pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
        nra.
    + apply Raux.Rle_bool_true.
      now apply Bleb_Rle in H.
  - destruct Raux.Req_bool eqn:E; auto.
    apply Raux.Rle_bool_true.
    now apply Bleb_Rle in H.
  - now destruct Raux.Req_bool eqn:E.
  - destruct Raux.Req_bool eqn:E;
    apply Bleb_Rle in H; auto;
    now apply Raux.Rle_bool_true.
Qed.

Theorem B2Rx0_Fle0 :
  forall (x y : float), Rx0le (B2Rx0 x) (B2Rx0 y) = true -> Fle0 x y = true.
Proof.
  intros.
  fdestruct x; fdestruct y;
  repeat (unfold B2Rx0 in H);
  unfold Rx0le in H;
  apply Rle_Bleb; try easy.
  + now apply Rleb_Rle.
  + now apply Rleb_Rle.
  + destruct Raux.Req_bool eqn:E in H.
    - rewrite (Reqb_Req _ _ E); simpl; lra.
    - now apply Rleb_Rle in H.
  + destruct Raux.Req_bool eqn:E in H.
    - apply Reqb_Req in E.
      unfold B2R, Defs.F2R in E.
      destruct s; simpl in E.
      * pose proof (IZR_neg m);
        pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
        nra.
      * pose proof (IZR_pos m);
        pose proof (Raux.bpow_gt_0 Zaux.radix2 e).
        nra.
    - now apply Rleb_Rle in H.
  + now destruct Raux.Req_bool eqn:E in H.
  + now destruct Raux.Req_bool eqn:E in H.
  + now destruct Raux.Req_bool eqn:E in H.
  + now destruct Raux.Req_bool eqn:E in H.
  + destruct Raux.Req_bool eqn:E in H.
    - rewrite (Reqb_Req _ _ E) in *.
      now apply Rleb_Rle in H.
    - now apply Rleb_Rle in H.
Qed.

Definition add (x y : Rx0) :=
  match x with
  | Rx0_NaN => x
  | Rx0_inf true =>
    match y with
    | Rx0_NaN => Rx0_NaN
    | Rx0_inf false => Rx0_NaN
    | _ => x
    end
  | Rx0_inf false =>
    match y with
    | Rx0_NaN => Rx0_NaN
    | Rx0_inf true => Rx0_NaN
    | _ => x
    end
  | Rx0_zero _ =>
    match y with
    | Rx0_zero _ => Rx0_real 0%R
    | _ => y
    end
  | Rx0_real r =>
    match y with
    | Rx0_NaN => Rx0_NaN
    | Rx0_inf _ => y
    | Rx0_zero _ => x
    | Rx0_real r' => Rx0_real (r + r')%R
    end
  end.

Compute (add (Rx0_real R0) (Rx0_zero true)).
Compute (add (Rx0_real R0) (Rx0_zero false)).

Lemma Req_0_true:
  Raux.Req_bool 0 0 = true.
Proof.
  now apply Raux.Req_bool_true.
Qed.

Definition add_Rx0le_mono_l :
  forall (x y z : Rx0),
    add x z <> Rx0_NaN ->
    add y z <> Rx0_NaN ->
    Rx0le x y = true -> Rx0le (add x z) (add y z) = true.
Proof.
  intros.
  destruct x eqn:Ex, y eqn:Ey, z eqn:Ez; simpl; try easy;
  try (destruct b; try easy; destruct b0; try easy; destruct b1; try easy);
  try (rewrite Req_0_true; apply Raux.Rle_bool_true; lra).
  + destruct Raux.Req_bool eqn:E;
    apply Raux.Rle_bool_true; lra.
  + now destruct Raux.Req_bool eqn:E.
  + now destruct Raux.Req_bool eqn:E.
  + now destruct Raux.Req_bool eqn:E.
  + now destruct Raux.Req_bool eqn:E.
  + destruct Raux.Req_bool eqn:E; now destruct b0.
  + now destruct Raux.Req_bool eqn:E.
  + destruct Raux.Req_bool eqn:E.
    - rewrite (Reqb_Req _ _ E).
      apply Rleb_Rle in H1.
      apply Raux.Rle_bool_true.
      lra.
    - apply Raux.Rle_bool_true.
      apply Rleb_Rle in H1.
      lra.
  + destruct Raux.Req_bool eqn:E.
    - rewrite (Reqb_Req _ _ E).
      apply Raux.Rle_bool_true; lra.
    - apply Raux.Rle_bool_true.
      simpl in H1.
      destruct Raux.Req_bool eqn:E' in H1.
      * rewrite (Reqb_Req _ _ E'); lra.
      * now apply Rleb_Rle in H1.
  + destruct (Raux.Req_bool r 0) eqn:E.
    - rewrite (Reqb_Req _ _ E) in *.
      destruct (Raux.Req_bool (0 + r0) 0) eqn:E'.
      * rewrite Rplus_0_l, (Reqb_Req _ _ E') in *.
        apply Raux.Rle_bool_true; lra.
      * rewrite Rplus_0_l.
        apply Raux.Rle_bool_true; lra.
    - simpl in H1.
      rewrite E in H1.
      apply Rleb_Rle in H1.
      destruct (Raux.Req_bool (r + r0) 0) eqn:E';
      apply Raux.Rle_bool_true; lra.
  + destruct (Raux.Req_bool (r + r0) 0) eqn:E';
    destruct b; auto;
    simpl in H1;
    now destruct Raux.Req_bool.
  + simpl in H1.
    destruct (Raux.Req_bool r 0) eqn:E.
    - rewrite (Reqb_Req _ _ E), Rplus_0_l in *.
      destruct (Raux.Req_bool r1 0) eqn:E'.
      * now rewrite (Reqb_Req _ _ E'), Rplus_0_r in *.
      * apply Rleb_Rle in H1.
        apply Raux.Rle_bool_true; lra.
    - destruct (Raux.Req_bool (r + r1) 0) eqn:E'.
      * apply Reqb_Req in E'.
        assert (r = -r1)%R by lra.
        subst.
        apply Raux.Rle_bool_true.
        apply Rleb_Rle in H1.
        lra.
      * apply Raux.Rle_bool_true.
        apply Rleb_Rle in H1.
        lra.
Qed.

Definition round (m : mode) (r : Rx0) : Rx0 :=
  match r with
  | Rx0_NaN => Rx0_NaN
  | Rx0_real x =>
    if Raux.Req_bool x 0%R then
      Rx0_zero false
      (* match m with
      | mode_DN => Rx0_zero true
      | _ => Rx0_zero false
      end *)
    else if do_overflow prec emax m x then
      if overflow_to_inf m (sign x) then Rx0_inf (sign x)
      else Rx0_real (B2R (if sign x then Bopp (F_fmax _ _) else (F_fmax _ _)))
    else
      Rx0_real (Generic_fmt.round Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode m) x)
  | _  => r
  end.

Lemma round_Rx0le :
  forall m (x y : Rx0),
    Rx0le x y = true -> Rx0le (round m x) (round m y) = true.
Proof.
  intros m [ ] [ ] Hxy; try easy; unfold Rx0le, round.
  + destruct Raux.Req_bool eqn:E.
    rewrite (Reqb_Req _ _ E) in *.
    simpl in Hxy.
    * destruct m, b; auto.
    * simpl in Hxy.
      assert (sign r = false).
      apply Rleb_Rle in Hxy.
      unfold sign.
      now apply Raux.Rlt_bool_false.
      rewrite H.
      destruct do_overflow, overflow_to_inf; auto.
      - apply Raux.Rle_bool_true.
        pose proof (F_fmax_ge_0 _ _).
        lra.
      - apply Raux.Rle_bool_true.
        rewrite <- (Generic_fmt.round_0 Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode m)).
        apply Generic_fmt.round_le.
        now apply fexp_correct.
        intuition.
        now apply Rleb_Rle in Hxy.
      - apply Raux.Rle_bool_true.
        rewrite <- (Generic_fmt.round_0 Zaux.radix2 (SpecFloat.fexp prec emax) (round_mode m)).
        apply Generic_fmt.round_le.
        now apply fexp_correct.
        intuition.
        now apply Rleb_Rle in Hxy.
  + destruct Raux.Req_bool eqn:E.
    - now destruct b.
    - destruct do_overflow, overflow_to_inf; auto.
      now destruct b.
  + destruct Raux.Req_bool eqn:E.
    - simpl in Hxy. now destruct (Raux.Req_bool r 0).
    - destruct do_overflow, overflow_to_inf; auto;
      simpl in Hxy; now destruct (Raux.Req_bool r 0).
  + simpl in Hxy.
    destruct (Raux.Rcompare r 0) eqn:E.
    - rewrite (Raux.Rcompare_Eq_inv _ _ E) in *.
      rewrite Req_0_true in *.
      now destruct b.
    - pose proof (Raux.Rcompare_Lt_inv _ _ E).
      assert (Raux.Req_bool r 0 = false).
      apply Raux.Req_bool_false. lra.
      rewrite H0 in *.
      unfold sign.
      rewrite (Raux.Rlt_bool_true _ _ H).
      destruct (do_overflow prec emax m r) eqn:E1, (overflow_to_inf m true) eqn:E2; auto.
      * rewrite B2R_Bopp.
        rewrite <- (R2F_fmax _ _).
        assert (Raux.Req_bool (- R_fmax prec emax) 0 = false).
        apply Raux.Req_bool_false.
        assert (R_fmax prec emax > 0)%R.
        unfold R_fmax. 
        unfold FLX.Prec_gt_0, Prec_lt_emax.
        admit.
        admit.
        rewrite H1.
        apply Raux.Rle_bool_true.
        rewrite (R2F_fmax _ _).
        replace 0%R with (@B2R prec emax +0) by auto.
        rewrite <- B2R_Bopp.
        apply Bleb_Rle; auto.
      (* * 

  simpl in Hxy.
    destruct (Raux.Req_bool r 0) eqn:E.
    - now destruct b.
    - destruct do_overflow eqn:Er, overflow_to_inf; auto.
      * apply Rleb_Rle in Hxy.
        unfold sign.
        destruct (Raux.Req_bool_spec r 0); try easy.
        rewrite Raux.Rlt_bool_true by lra.
        reflexivity.
      * apply Rleb_Rle in Hxy.
        unfold sign.
        destruct (Raux.Req_bool_spec r 0); try easy.
        rewrite Raux.Rlt_bool_true by lra.
        unfold Rx0le.
        destruct Raux.Req_bool. *)

Admitted.

Theorem add_Fle0_mono :
  forall (x y z : float) m,
    Fle0 x y = true ->
    is_nan (Bplus m x z) = false ->
    is_nan (Bplus m y z) = false ->
    Fle0 (Bplus m x z) (Bplus m y z) = true.
Proof.
  intros.
  fdestruct x; fdestruct y; try (fdestruct z; now destruct m).
  - now apply Fle0_refl.
  - fdestruct z; try now destruct m.
    now apply Fle0_refl.
  - fdestruct z. now destruct m.
    now apply Bplus_le_mono_l.
  - now apply Fle0_refl.
  - fdestruct z. now destruct m.
    now apply Bplus_le_mono_l.
  - fdestruct z.
    now apply Bplus_le_mono_l.
  - fdestruct z. now destruct m.
    simpl (Bplus m -0 _).
    rewrite Fle0_is_Bleb_r by easy.
    replace (B754_finite s0 m1 e1 e2) with
    (Bplus m -0 (B754_finite s0 m1 e1 e2)) by reflexivity.
    now apply Bplus_le_mono_l.
  - fdestruct z. now destruct m.
    simpl (Bplus m +0 _).
    rewrite Fle0_is_Bleb_r by easy.
    replace (B754_finite s0 m1 e1 e2) with
    (Bplus m +0 (B754_finite s0 m1 e1 e2)) by reflexivity.
    now apply Bplus_le_mono_l.
  - fdestruct z.
    simpl (Bplus m +oo _).
    rewrite Fle0_is_Bleb_r by easy.
    now apply infp_max.
  - fdestruct z.
    apply B2Rx0_Fle0.
    apply Fle0_B2Rx0 in H.
Admitted.

End Fle0.

