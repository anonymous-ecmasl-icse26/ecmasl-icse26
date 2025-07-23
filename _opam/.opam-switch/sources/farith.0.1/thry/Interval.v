From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import QArith Psatz Reals Extraction.
Require Import  Utils Correction_thms Rextended.

(*********************************************************
       Interval arithmetic over floatting points
**********************************************************)

Section Finterval.

Variable prec : Z.
Variable emax : Z.
Context (Hprec : FLX.Prec_gt_0 prec).
Context (Hemax : Prec_lt_emax prec emax).

Definition float := binary_float prec emax.

Inductive Interval' :=
 | Inan : Interval'
 | Intv : forall (lo hi : float) (nan : bool), Interval'.

Definition valid (I : Interval') :=
  match I with
  | Intv lo hi _ => lo <= hi
  | _ => True
  end.

Definition valid_opt (I : option Interval') :=
  match I with
  | Some i => valid i
  | _ => True
  end.

Definition Interval := { I : Interval' | valid I }.

Definition Interval_opt := option Interval.

Program Definition contains (I : Interval') (x : float) : Prop :=
  match I with
  | Inan => is_nan x = true
  | Intv lo hi nan =>
    lo <= x <= hi \/ (is_nan x && nan = true)
  end.

Definition contains_opt' (I : option Interval') (x : float) : Prop :=
  match I with
  | None => False
  | Some i => contains i x
  end.

Definition contains_opt (I : option Interval) (x : float) : Prop :=
  match I with
  | None => False
  | Some i => contains (proj1_sig i) x
  end.

Program Definition to_Interval_opt (I: option Interval') (P:valid_opt I) : Interval_opt :=
  match I with
  | None => None
  | Some J => Some (J:Interval)
  end.

Lemma contains_to_Interval_opt (I: option Interval') (P:valid_opt I):
  forall x, contains_opt (to_Interval_opt I P) x = contains_opt' I x.
Proof.
  intros x.
  destruct I;reflexivity.
Qed.


  Program Definition top : Interval := Intv -oo +oo true.

  Program Definition bot : Interval_opt := None.

  Lemma top_correct :
    forall (x : float), contains (proj1_sig top) x.
  Proof with auto.
    unfold top, contains; fdestruct x; simpl...
  Qed.

  Lemma bot_correct :
    forall (x : float), contains_opt bot x -> False.
  Proof with auto.
    unfold bot, contains; fdestruct x.
  Qed.

  Program Definition is_singleton (I : Interval) : option float :=
    match proj1_sig I with
    | Inan => Some NaN
    | Intv a b n =>
      if Beqb a b && (negb (Beqb a (B754_zero false))) && negb n then Some a
      else None
    end.

  Program Definition s0 : Interval := Intv (B754_zero false) (B754_zero true) false.

  Program Theorem is_singleton_correct :
    forall (I : Interval) (x : float), (is_singleton I = Some x) -> (forall y, contains I y -> x = y).
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

  Program Definition singleton (x : float) : Interval :=
    match x with
    | B754_nan => Inan
    | _ => Intv x x false
    end.
  Next Obligation.
    apply Bleb_refl.
    fdestruct x.
  Defined.

  Program Theorem singleton_correct :
    forall (x : float), Beqb x (B754_zero true) = false -> is_singleton (singleton x) = Some x.
  Proof.
    intros [ [ ] | [ ] | | [ ] ] H; try easy; cbn.
    - rewrite Z.compare_refl, Pcompare_refl; reflexivity.
    - rewrite Z.compare_refl, Pcompare_refl; reflexivity.
  Qed.

Program Definition inter' (I1 I2 : Interval') : option Interval' :=
  match I1, I2 with
  | Inan, Inan => Some Inan
  | Inan, Intv _ _ nan =>
    if nan then Some Inan else None
  | Intv _ _ nan, Inan =>
    if nan then Some (Inan) else None
  | Intv lo1 hi1 nan1, Intv lo2 hi2 nan2 =>
    if Bltb hi1 lo2 || Bltb hi2 lo1 then
      if nan1 && nan2 then Some Inan else None
    else
      Some (Intv (Bmax lo1 lo2) (Bmin hi1 hi2) (nan1 && nan2))
  end.

Ltac ieasy :=
  simpl in *; try easy; try (intuition; fail).

Ltac sdestruct x :=
  try destruct x; simpl; easy.

Program Definition inter (I1 I2 : Interval) : Interval_opt :=
  to_Interval_opt (inter' I1 I2) _.
Next Obligation.
  destruct I1 as [[|lo1 hi1 nan1] H1], I2 as [[|lo2 hi2 nan2] H2]; ieasy; try (now destruct nan1 || now destruct nan2).
  case (Bltb (hi1) (lo2)) eqn:?, (Bltb (hi2) (lo1)) eqn:?; simpl; try (destruct nan1, nan2; simpl; easy).
  pose proof (le_not_nan_l _ _ H1).
  pose proof (le_not_nan_r _ _ H2).
  pose proof (le_not_nan_r _ _ H1).
  pose proof (le_not_nan_l _ _ H2).
  auto using Bmax_le, Bmin_le, Bltb_false_Bleb.
Defined.

Lemma contains_opt_inter I1 I2:
  forall x, contains_opt (inter I1 I2) x = contains_opt' (inter' (proj1_sig I1) (proj1_sig I2)) x.
Proof.
  intros x. unfold inter. rewrite contains_to_Interval_opt.
  reflexivity.
Qed.

Program Lemma inter_precise_l :
  forall I1 I2, forall x, contains_opt (inter I1 I2) x -> contains I1 x.
Proof with auto.
  intros [[|lo1 hi1 nan1] H1] [[|lo2 hi2 nan2] H2] x Hx; rewrite contains_opt_inter in Hx; simpl in *...
  + destruct nan2; fdestruct x.
  + right; destruct nan1; fdestruct x.
  + case (Bltb hi1 lo2) eqn:?, (Bltb hi2 lo1) eqn:?; simpl in *;
      try (right; destruct nan1, nan2; simpl in *; fdestruct x; fail).
    destruct Hx as [[Hc1 Hc2] | H ].
    - left; split; [ apply (Bmax_le_inv _ _ _ _ _ Hc1) | apply (Bmin_le_inv _ _ _ _ _ Hc2) ].
    - repeat rewrite andb_true_iff in H; intuition.
Qed.

Program Lemma inter_precise_r :
  forall I1 I2, forall x, contains_opt (inter I1 I2) x -> contains I2 x.
Proof with auto.
  intros [[|lo1 hi1 nan1] H1] [[|lo2 hi2 nan2] H2] x Hx; rewrite contains_opt_inter in Hx; simpl in *...
  + right; destruct nan2; fdestruct x.
  + destruct nan1; fdestruct x.
  + case (Bltb hi1 lo2) eqn:?, (Bltb hi2 lo1) eqn:?; simpl in *;
    try (right; destruct nan1, nan2; simpl in *; fdestruct x; fail).
    destruct Hx as [[Hc1 Hc2] | H ].
    - left; split; [ apply (Bmax_le_inv _ _ _ _ _ Hc1) | apply (Bmin_le_inv _ _ _ _ _ Hc2) ].
    - repeat rewrite andb_true_iff in H; intuition.
Qed.

Program Lemma inter_correct :
  forall (I1 I2 : Interval), forall x,  contains I1 x -> contains I2 x -> contains_opt (inter I1 I2) x.
Proof with auto.
  intros [[|lo1 hi1 nan1] H1] [[|lo2 hi2 nan2] H2] x Hx1 Hx2; rewrite contains_opt_inter; simpl in *...
  - fdestruct x; destruct nan2, Hx2; try easy.
  - fdestruct x; destruct nan1, Hx1; try easy.
  - pose proof (le_not_nan_l _ _ H1).
    pose proof (le_not_nan_r _ _ H1).
    pose proof (le_not_nan_l _ _ H2).
    pose proof (le_not_nan_r _ _ H2).
    destruct Hx1 as [[Hc1 Hc1'] |], Hx2 as [[Hc2 Hc2'] |]; try (fdestruct x ; fail).
    + pose proof (Hlt1 := Bleb_trans _ _ _ Hc2 Hc1').
      apply Bleb_true_Bltb in Hlt1...
      pose proof (Hlt2 := Bleb_trans _ _ _ Hc1 Hc2').
      apply Bleb_true_Bltb in Hlt2...
      rewrite Hlt1, Hlt2; simpl; left; split; auto using Bmax_le, Bmin_le.
    + fdestruct x; destruct nan2, nan1, (Bltb hi1 _), (Bltb hi2); simpl; try easy.
      now right.
Qed.

Definition Iadd' (m : mode) (I1 I2 : Interval') : Interval' :=
  match I1, I2 with
  | Inan, _ => Inan
  | _, Inan => Inan
  | Intv l h n, Intv l' h' n' =>
    let sum1 := Bplus m l l' in
    let sum2 := Bplus m h h' in
    match is_nan sum1 with
    | true =>
      match is_nan sum2 with
      | true => Inan
      | false => Intv +oo +oo true
      end
    | false =>
      match is_nan sum2 with
      | true => Intv -oo -oo true
      | false => Intv sum1 sum2 (n || n' || (Beqb h +oo && Beqb l' -oo) || (Beqb h' +oo && Beqb l -oo))
      end
    end
  end.

Program Definition Iadd (m : mode) (I1 I2 : Interval) : Interval :=
  Iadd' m I1 I2.
Next Obligation.
  destruct I1 as [[|l1 h1] H1], I2 as [[|l2 h2] H2]; simpl in *; auto.
  destruct (is_nan (Bplus m l1 l2)) eqn:E1, (is_nan (Bplus m h1 h2)) eqn:E2; try easy; simpl.
  now apply Bplus_le_compat.
Qed.

Program Lemma Iadd_correct :
  forall m (I1 I2 : Interval) (x y : float), contains I1 x -> contains I2 y -> contains (Iadd m I1 I2) (Bplus m x y).
Proof with auto.
  intros m [[|l1 h1] H1] [[|l2 h2] H2] x y Hx Hy; simpl in *; try (fdestruct x; fdestruct y; fail).
  case (is_nan (Bplus m l1 l2)) eqn:E1, (is_nan (Bplus m h1 h2)) eqn:E2; intuition; simpl.
  all: try (fdestruct x; fdestruct y; simpl; auto; fail).
  - destruct (Bplus_nan_inv _ _ _ E1); intuition; subst; try easy.
    * rewrite (infp_le_is_infp _ _ _ H0) in *.
      rewrite (infp_le_is_infp _ _ _ H1) in *.
      fdestruct h2.
      rewrite (le_infm_is_infm _ _ _ H5) in *...
    * rewrite (infp_le_is_infp _ _ _ H4) in *.
      rewrite (infp_le_is_infp _ _ _ H2) in *.
      fdestruct h1.
      rewrite (le_infm_is_infm _ _ _ H3) in *...
  - destruct (Bplus_nan_inv _ _ _ E1) as [[ -> -> ] | [ [ -> -> ] | [ -> | -> ]]]; try easy;
    fdestruct x; fdestruct y; simpl...
  - destruct (Bplus_nan_inv _ _ _ E2) as [[ -> -> ] | [ [ -> -> ] | [ -> | -> ]]]; try easy;
    fdestruct x; fdestruct y; simpl...
  - destruct (is_nan (Bplus m x y)) eqn:E.
    + right. destruct (Bplus_nan_inv _ _ _ E) as [ [-> ->] | [ [ -> -> ] | ] ].
      * rewrite (infp_le_is_infp _ _ _ H3) in *.
        rewrite (le_infm_is_infm _ _ _ H4) in *.
        fdestruct l2; simpl; fdestruct h1; simpl; intuition.
      * rewrite (infp_le_is_infp _ _ _ H5) in *.
        rewrite (le_infm_is_infm _ _ _ H0) in *.
        fdestruct h1; simpl; fdestruct l2; simpl; intuition.
      * destruct H as [ -> | -> ]; fdestruct h1.
    + left. split; now apply Bplus_le_compat.
  - right; fdestruct y; fdestruct x; destruct nan0; simpl; intuition.
  - right; fdestruct y; fdestruct x; destruct nan; simpl; intuition.
  - right; fdestruct y; fdestruct x; destruct nan; simpl; intuition.
Qed.

Notation "'Interval+⊥'" := Interval_opt.

Program Definition Ile (I : Interval) : Interval+⊥ :=
  match I with
  | Inan => None
  | Intv a b n =>
    Some (Intv -oo b n)
  end.
Next Obligation.
  destruct I as [[|l1 h1] H1]; simpl in *; fdestruct b.
  inversion Heq_I; subst.
  fdestruct l1.
Defined.


Program Theorem Ile_correct :
  forall (I : Interval) (x y : float), contains I y -> x <= y -> contains_opt (Ile I) x.
Proof.
  intros [[| l1 h1] H1] x y Hx Hxy; simpl in *.
  - fdestruct y; fdestruct x.
  - destruct (is_nan x), Hx as [ [H H'] | ];
    try (left ; idtac; split; [ fdestruct x | apply (Bleb_trans _ _ _ Hxy H')]);
    try (right ; fdestruct y; fdestruct x).
Qed.

Program Definition Ilt (I : Interval) : Interval+⊥ :=
  match I with
  | Inan => None
  | Intv a b n =>
    Some (Intv -oo b n)
  end.
Next Obligation.
  destruct I as [[|l1 h1] H1]; simpl in *; fdestruct b;
  inversion Heq_I; subst; fdestruct l1.
Defined.


Program Theorem Ilt_correct :
  forall (I : Interval) (x y : float), contains I y -> Bltb x y = true -> contains_opt (Ilt I) x.
Proof.
  intros [[| l1 h1] H1] x y Hx Hxy; simpl in *.
  - fdestruct y; fdestruct x.
  - apply Bltb_Bleb in Hxy.
    destruct (is_nan x), Hx as [ [H H'] | ];
    try (left ; idtac; split; [ fdestruct x | apply (Bleb_trans _ _ _ Hxy H')]);
    try (right ; fdestruct y; fdestruct x).
Qed.

Program Definition Ige (I : Interval) : Interval+⊥ :=
  match I with
  | Inan => None
  | Intv a b n =>
    Some (Intv a +oo n)
  end.
Next Obligation.
  destruct I as [[|l1 h1] H1]; simpl in *; fdestruct b;
  inversion Heq_I; subst; fdestruct l1.
Defined.

Program Theorem Ige_correct :
  forall (I : Interval) (x y : float), contains I y -> Bleb y x = true -> contains_opt (Ige I) x.
Proof.
  intros [[| l1 h1] H1] x y Hx Hxy; simpl in *.
  - fdestruct y; fdestruct x.
  - destruct (is_nan x), Hx as [ [H H'] | ];
    try (left ; idtac; split; [ apply (Bleb_trans _ _ _ H Hxy) | fdestruct x; fdestruct y ]);
    try (right ; fdestruct y; fdestruct x).
Qed.

Program Definition Igt (I : Interval) : Interval+⊥ :=
  match I with
  | Inan => None
  | Intv a b n =>
    Some (Intv a +oo n)
  end.
Next Obligation.
  destruct I as [[|l1 h1] H1]; simpl in *; fdestruct b;
  inversion Heq_I; subst; fdestruct l1.
Defined.

Program Theorem Igt_correct :
  forall (I : Interval) (x y : float), contains I y -> Bltb y x = true -> contains_opt (Igt I) x.
Proof.
  intros [[| l1 h1] H1] x y Hx Hxy; simpl in *.
  - fdestruct y; fdestruct x.
  - apply Bltb_Bleb in Hxy.
    destruct (is_nan x), Hx as [ [H H'] | ];
    try (left ; idtac; split; [ apply (Bleb_trans _ _ _ H Hxy) | fdestruct x; fdestruct y ]);
    try (right ; fdestruct y; fdestruct x).
Qed.

Program Definition inter_opt (I1 I2 : Interval+⊥) : Interval+⊥ :=
  match I1, I2 with
  | None, _ => None
  | _, None => None
  | Some i1, Some i2 => inter i1 i2
  end.

Program Definition to_opt (I : Interval) : Interval+⊥ :=
  (Some (proj1_sig I)).
Next Obligation.
  now destruct I as [[| l h n ] H].
Defined.

Coercion to_opt : Interval >-> Interval_opt.

Ltac fall_cases x :=
  try (fdestruct x; fail).

Ltac fall_cases2 x y :=
  try (fdestruct x; fdestruct y; fail).


Definition Ige_inv (I1 I2 : Interval) : Interval+⊥ * Interval+⊥ :=
  (inter_opt (Ige I2) I1, inter_opt (Ile I1) I2).

Program Theorem Ige_inv_correct : 
  forall (I1 I2 : Interval) (x y : float),
    contains I1 x -> contains I2 y ->
    y <= x ->
    contains_opt (fst (Ige_inv I1 I2)) x /\
    contains_opt (snd (Ige_inv I1 I2)) y.
Proof.
  intros [[|l1 h1 n1] H1] [[|l2 h2 n2] H2] x y Hx Hy Hxy; fall_cases2 x y.
  split; apply inter_correct; simpl in *; auto.
  + destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; fall_cases2 y x.
    left; split; [ apply (Bleb_trans _ _ _ Hy Hxy) | fdestruct x ].
  + destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; fall_cases2 y x.
    left; split; [ fdestruct y; fdestruct x | apply (Bleb_trans _ _ _ Hxy Hx') ].
Qed.


Definition Igt_inv (I1 I2 : Interval) : Interval+⊥ * Interval+⊥ :=
  (inter_opt (Igt I2) I1, inter_opt (Ilt I1) I2).

Program Theorem Igt_inv_correct : 
  forall (I1 I2 : Interval) (x y : float),
    contains I1 x -> contains I2 y ->
    Bltb y x = true ->
    contains_opt (fst (Igt_inv I1 I2)) x /\
    contains_opt (snd (Igt_inv I1 I2)) y.
Proof.
  intros [[|l1 h1 n1] H1] [[|l2 h2 n2] H2] x y Hx Hy Hxy; fall_cases2 x y.
  split; apply inter_correct; simpl in *; auto; destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; auto; fall_cases2 x y.
  + left; split.
    * apply (Bleb_trans _ _ _ Hy (Bltb_Bleb _ _ _ _ Hxy)).
    * fdestruct x.
  + left; split.
    * fdestruct y.
    * apply (Bleb_trans _ _ _ (Bltb_Bleb _ _ _ _ Hxy) Hx').
Qed.

Definition Ilt_inv (I1 I2 : Interval) : Interval+⊥ * Interval+⊥ :=
  (inter_opt (Ilt I2) I1, inter_opt (Igt I1) I2).

Program Theorem Ilt_inv_correct : 
  forall (I1 I2 : Interval) (x y : float),
    contains I1 x -> contains I2 y ->
    Bltb x y = true ->
    contains_opt (fst (Ilt_inv I1 I2)) x /\
    contains_opt (snd (Ilt_inv I1 I2)) y.
Proof.
  intros [[|l1 h1 n1] H1] [[|l2 h2 n2] H2] x y Hx Hy Hxy; fall_cases2 x y.
  split; apply inter_correct; simpl in *; auto; destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; auto; fall_cases2 x y.
  + left; split; fall_cases x.
    apply (Bleb_trans _ _ _ (Bltb_Bleb _ _ _ _ Hxy) Hy').
  + left; split; fall_cases y.
    apply (Bleb_trans _ _ _ Hx (Bltb_Bleb _ _ _ _ Hxy)).
Qed.

Definition Ile_inv (I1 I2 : Interval) : Interval+⊥ * Interval+⊥ :=
  (inter_opt (Ile I2) I1, inter_opt (Ige I1) I2).

Program Theorem Ile_inv_correct : 
  forall (I1 I2 : Interval) (x y : float),
    contains I1 x -> contains I2 y ->
    x <= y ->
    contains_opt (fst (Ile_inv I1 I2)) x /\
    contains_opt (snd (Ile_inv I1 I2)) y.
Proof.
  intros [[|l1 h1 n1] H1] [[|l2 h2 n2] H2] x y Hx Hy Hxy; fall_cases2 x y.
  split; apply inter_correct; simpl in *; auto; destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; auto; fall_cases2 x y.
  + left; split; fall_cases x.
    apply (Bleb_trans _ _ _ Hxy Hy').
  + left; split; fall_cases y.
    apply (Bleb_trans _ _ _ Hx Hxy).
Qed.

Definition Ieq_inv (I1 I2 : Interval) : Interval+⊥ * Interval+⊥ :=
  (inter_opt I1 I2, inter_opt I1 I2).

Program Theorem Ieq_inv_correct : 
  forall (I1 I2 : Interval) (x y : float),
    contains I1 x -> contains I2 y ->
    Beqb x y = true ->
    contains_opt (fst (Ieq_inv I1 I2)) x /\
    contains_opt (snd (Ieq_inv I1 I2)) y.
Proof.
  intros [[|l1 h1 n1] H1] [[|l2 h2 n2] H2] x y Hx Hy Hxy; fall_cases2 x y.
  split; apply inter_correct; simpl in *; auto; destruct Hx as [[Hx Hx'] | Hx], Hy as [[Hy Hy'] | Hy]; auto; fall_cases2 x y.
  + left; split.
    * apply (Bleb_trans l2 y x Hy (Beqb_Bleb _ _ _ _ (Beqb_symm _ _ _ _ Hxy))).
    * apply (Bleb_trans x y h2 (Beqb_Bleb _ _ _ _ Hxy) Hy').
  + left; split.
    * apply (Bleb_trans l1 x y Hx (Beqb_Bleb _ _ _ _ Hxy)).
    * apply (Bleb_trans y x h1 (Beqb_Bleb _ _ _ _ (Beqb_symm _ _ _ _ Hxy)) Hx').
Qed.

Definition Iopp' (I1 : Interval') : Interval' :=
  match I1 with
  | Inan => Inan
  | Intv l h n =>
    let opp1 := Bopp l in
    let opp2 := Bopp h in
    Intv opp2 opp1 n
  end.

Program Definition Iopp (I1 : Interval) : Interval :=
  Iopp' I1.
Admit Obligations.

Program Definition union' (I1 I2 : Interval') : Interval' :=
  match I1, I2 with
  | Inan, Inan => Inan
  | Inan, Intv _ _ true => I2
  | Inan, Intv l h false => Intv l h true
  | Intv _ _ true, Inan => I1
  | Intv l h false, Inan => Intv l h true
  | Intv lo1 hi1 nan1, Intv lo2 hi2 nan2 =>
      (Intv (Bmin lo1 lo2) (Bmax hi1 hi2) (nan1 || nan2))
  end.


End Finterval.
