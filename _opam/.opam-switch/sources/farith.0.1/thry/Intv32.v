From Coq Require Import ZArith Extraction Bool Psatz ExtrOcamlBasic.
From Flocq Require Import IEEE754.BinarySingleNaN FLX.
Require Import Utils Interval B32.



Notation "x '+⊥'" := (option x) (at level 80).

Module Intv32.
  Definition prec := 24%Z.
  Definition emax := 128%Z.
  Definition float32 := B32.t.

  Lemma Hprec : Prec_gt_0 prec.
  Proof. unfold Prec_gt_0, prec; lia. Qed.

  Lemma Hemax : Prec_lt_emax prec emax.
  Proof. unfold Prec_lt_emax, prec, emax; lia. Qed.

  Definition t := Interval prec emax.

  Definition t_opt := Interval_opt prec emax.
  
  Program Definition contains : t -> float32 -> Prop := contains prec emax.

  Program Definition contains_opt : t_opt -> float32 -> Prop := contains_opt prec emax.

  Definition inter (x y : t) : t_opt :=
    @inter prec emax x y.

  Definition add : mode -> t -> t -> t :=
    @Iadd prec emax Hprec Hemax.

  Program Lemma inter_correct :
    forall (i1 i2 : t) (x : float32),
      contains i1 x -> contains i2 x -> contains_opt (inter i1 i2) x. 
  Proof. 
    apply (inter_correct prec emax).
  Qed.

  Lemma inter_precise :
    forall (i1 i2 : t) (x : float32),
      contains_opt (inter i1 i2) x -> contains i1 x /\ contains i2 x.
  Proof.
    intros; split.
    - apply (inter_precise_l prec emax _ _ _ H).
    - apply (inter_precise_r prec emax _ _ _ H).
  Qed.

  Lemma add_correct :
    forall (m : mode) (i1 i2 : t) (x y : float32),
      contains i1 x -> contains i2 y -> contains (add m i1 i2) (@Bplus prec emax Hprec Hemax m x y).
  Proof. apply Iadd_correct. Qed.

  Program Definition top : t := Intv prec emax -oo +oo true.

  Program Definition bot : t_opt := None.

  Lemma top_correct :
    forall (x : float32), contains top x.
  Proof with auto.
    unfold top, contains; fdestruct x; simpl...
  Qed.

  Lemma bot_correct :
    forall (x : float32), contains_opt bot x -> False.
  Proof with auto.
    unfold bot, contains; fdestruct x.
  Qed.

  Program Definition is_singleton (I : t) : option float32 :=
    match I with
    | Inan _ _ => Some NaN
    | Intv _ _ a b n =>
      if Beqb a b && (negb (Beqb a (B754_zero false))) && negb n then Some a
      else None
    end.

  Program Definition s0 : Interval prec emax := Intv _ _ (B754_zero false) (B754_zero true) false.

  Program Theorem is_singleton_correct :
    forall (I : t) (x : float32), (is_singleton I = Some x) -> (forall y, contains I y -> x = y).
  Proof.
    intros [[| a b n] H] x; cbn.
    - intros H1; inversion H1; fdestruct y.
    - intros H' y [[H1 H2] | H2].
      + destruct (Beqb a b) eqn:?E, (negb n) eqn:?E,    (negb (Beqb a (B754_zero false))) eqn:?; try  easy; simpl in *.
        assert (a <= y <= a) by eauto using E, Beqb_symm, Beqb_Bleb, Bleb_trans.
        apply Bleb_antisymm_strict in H0.
        * inversion H'; subst; reflexivity.
        * now apply Bool.negb_true_iff in Heqb0.
      + destruct (Beqb a b) eqn:?E, (negb n) eqn:?E,    (negb (Beqb a (B754_zero false))) eqn:?; try  easy; simpl in *.
        destruct n; try easy.
        fdestruct y.
  Qed.

  Program Definition singleton (x : float32) : t :=
    match x with
    | B754_nan => Inan prec emax
    | _ => Intv _ _ x x false
    end.
  Next Obligation.
    apply Bleb_refl.
    fdestruct x.
  Defined.

  Program Example s00 : t := Intv prec emax (B754_zero false) (B754_zero false) false.
  Program Example s01 : t := Intv prec emax (B754_zero false) (B754_zero true) false.
  Program Example s10 : t := Intv prec emax (B754_zero true) (B754_zero false) false.
  Program Example s11 : t := Intv prec emax (B754_zero true) (B754_zero true) false.

  (** /!\ Série alternante !!! *)
  (* Compute (inter s10 s00) (* s00*). *)
  (* Compute (inter s00 s10) (* s10 *). *)
  (* Compute (inter s00 s10) (* s10*). *)
  (* Compute (inter s10 s00) (* s00 *). *)



  Program Theorem singleton_correct :
    forall (x : float32), Beqb x (B754_zero true) = false -> is_singleton (singleton x) = Some x.
  Proof.
    intros [ [ ] | [ ] | | [ ] ] H; try easy; cbn.
    - rewrite Z.compare_refl, Pcompare_refl; reflexivity.
    - rewrite Z.compare_refl, Pcompare_refl; reflexivity.
  Qed.

  Program Definition ge : t -> t_opt := @Ige prec emax.
  Program Definition le : t -> t_opt := @Ile prec emax.
  Program Definition lt : t -> t_opt := @Ilt prec emax.
  Program Definition gt : t -> t_opt := @Igt prec emax.

  Program Definition le_inv : t -> t -> (t_opt * t_opt) := @Ile_inv prec emax.
  Program Definition ge_inv : t -> t -> (t_opt * t_opt) := @Ige_inv prec emax.
  Program Definition lt_inv : t -> t -> (t_opt * t_opt) := @Ilt_inv prec emax.
  Program Definition gt_inv : t -> t -> (t_opt * t_opt) := @Igt_inv prec emax.
  Program Definition eq_inv : t -> t -> (t_opt * t_opt) := @Ieq_inv prec emax.

  Theorem le_inv_correct :
    forall (I1 I2 : t) (x y : float32),
      contains I1 x -> contains I2 y -> x <= y ->
      contains_opt (fst (le_inv I1 I2)) x /\ contains_opt (snd (le_inv I1 I2)) y.
  Proof. apply (@Ile_inv_correct prec emax). Qed.

  Theorem ge_inv_correct :
    forall (I1 I2 : t) (x y : float32),
      contains I1 x -> contains I2 y -> y <= x ->
      contains_opt (fst (ge_inv I1 I2)) x /\ contains_opt (snd (ge_inv I1 I2)) y.
  Proof. apply (@Ige_inv_correct prec emax). Qed.

  Theorem gt_inv_correct :
    forall (I1 I2 : t) (x y : float32),
      contains I1 x -> contains I2 y -> Bltb y x = true ->
      contains_opt (fst (gt_inv I1 I2)) x /\ contains_opt (snd (gt_inv I1 I2)) y.
  Proof. apply (@Igt_inv_correct prec emax). Qed.

  Theorem lt_inv_correct :
    forall (I1 I2 : t) (x y : float32),
      contains I1 x -> contains I2 y -> Bltb x y = true ->
      contains_opt (fst (lt_inv I1 I2)) x /\ contains_opt (snd (lt_inv I1 I2)) y.
  Proof. apply (@Ilt_inv_correct prec emax). Qed.

  Theorem eq_inv_correct :
    forall (I1 I2 : t) (x y : float32),
      contains I1 x -> contains I2 y -> Beqb x y = true ->
      contains_opt (fst (eq_inv I1 I2)) x /\ contains_opt (snd (eq_inv I1 I2)) y.
  Proof. apply (@Ieq_inv_correct prec emax). Qed.

  Theorem le_correct :
    forall (I : t) (x y : float32), contains I y -> x <= y -> contains_opt (le I) x.
  Proof. apply (@Ile_correct prec emax). Qed.

  Theorem lt_correct :
    forall (I : t) (x y : float32), contains I y -> Bltb x y = true -> contains_opt (lt I) x.
  Proof. apply (@Ilt_correct prec emax). Qed.

  Theorem ge_correct :
    forall (I : t) (x y : float32), contains I y -> y <= x -> contains_opt (ge I) x.
  Proof. apply (@Ige_correct prec emax). Qed.

  Theorem gt_correct :
    forall (I : t) (x y : float32), contains I y -> Bltb y x = true -> contains_opt (gt I) x.
  Proof. apply (@Igt_correct prec emax). Qed.

End Intv32.
