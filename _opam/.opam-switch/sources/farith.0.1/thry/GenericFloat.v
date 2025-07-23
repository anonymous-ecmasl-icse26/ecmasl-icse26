From Flocq Require Import Core.Core IEEE754.BinarySingleNaN IEEE754.Bits.
From Coq Require Import Program ZArith Bool Lia Reals Qreals ZBits SpecFloat FloatClass.
Require Import Assert  Utils Interval Qextended Rextended Op.

Definition cprec mw := (Z.succ mw)%Z.

Definition cemax ew := Zpower 2 (ew - 1).
  (* (if Z.eqb ew 1 then 1 else Z.pow_pos 2 (Z.to_pos (ew - 1)))%Z. *)

Definition check_param mw ew :=
  andb (andb (0 <? mw)%Z (0 <? ew)%Z) (cprec mw <? cemax ew)%Z.

Record Generic { v } : Type := {
    mw : Z;
    ew : Z;
    HG: check_param mw ew = true;
    value : v (cprec mw) (cemax ew);
  }.

Lemma check_param_is_Hprec : forall mw ew, (check_param mw ew = true) -> FLX.Prec_gt_0 (cprec mw).
Proof.
  intros mw ew H.
  unfold check_param in H.
rewrite !Bool.andb_true_iff in H.
rewrite <- !Zlt_is_lt_bool in H.
intuition.
unfold FLX.Prec_gt_0.
unfold cprec.
lia.
Qed.

Lemma check_param_is_Hw : forall mw ew, (check_param mw ew = true) -> FLX.Prec_gt_0 mw.
Proof.
  intros mw ew H.
  unfold check_param in H.
rewrite !Bool.andb_true_iff in H.
rewrite <- !Zlt_is_lt_bool in H.
intuition.
Qed.

Lemma check_param_is_Hemax : forall mw ew, (check_param mw ew = true) -> Prec_lt_emax (cprec mw) (cemax ew).
Proof.
  intros mw ew H.
  unfold check_param in H.
rewrite !Bool.andb_true_iff in H.
rewrite <- !Zlt_is_lt_bool in H.
intuition.
Qed.

Definition prec { v } (f: @Generic v) := cprec (mw f).

Definition emax { v } (f: @Generic v) := cemax (ew f).

Definition Hprec { v } (f: @Generic v) := check_param_is_Hprec (mw f) (ew f) (HG f).

Definition Hemax { v } (f: @Generic v) := check_param_is_Hemax (mw f) (ew f) (HG f).

Definition mk_generic { v } mw ew (H: check_param mw ew = true) (x: forall prec emax, FLX.Prec_gt_0 prec -> Prec_lt_emax prec emax -> v prec emax) : @Generic v :=
  let prec := cprec mw in
  let emax := cemax ew in
  let Hprec : FLX.Prec_gt_0 prec := check_param_is_Hprec _ _ H in
  let Hemax : Prec_lt_emax prec emax := check_param_is_Hemax _ _ H in
    {|
      mw := mw;
      ew := ew;
      HG := H;
      value := x prec emax Hprec Hemax;
    |}.

Program Definition unify { v } (p e p' e' : Z) (f : v p' e') (Hp : p = p') (Hp : e = e') : v p e := f.

Program Definition same_format_cast {v } {p e p' e' : Z} (H : ((p =? p') && (e =? e') = true)%Z) (f : v p' e') : v p e := f.
Next Obligation.
  apply andb_true_iff in H as [A _].
  now rewrite (proj1 (Z.eqb_eq _ _) A).
Defined.
Next Obligation.
  apply andb_true_iff in H as [_ B].
  now rewrite (proj1 (Z.eqb_eq _ _) B).
Defined.


Definition same_format { v1 v2 } (x : @Generic v1) (y : @Generic v2) : bool :=
  Z.eqb (prec x) (prec y) && Z.eqb (emax x) (emax y).

Definition mk_with {v1 v2} (x : @Generic v1) (y:v2 (prec x) (emax x)) : @Generic v2 :=
   {|
      mw := mw x;
      ew := ew x;
      HG := HG x;
      value := y;
   |}.


Definition mk_witho {v1 v2 } (x:@Generic v1) (y:option (v2 (prec x) (emax x))) : option (@Generic v2) :=
  match y with
    | Some r => Some (mk_with x r)
    | None => None
  end.


Module GenericFloat.

  Definition t : Type := @Generic binary_float.

  Module F_inhab.
    Definition t : Type := t.
    Program Definition dummy := {|
      mw := 24;
      ew := 128;
      value := BinarySingleNaN.B754_nan;
      HG := _;
    |}.
    Solve All Obligations with easy.
  End F_inhab.
  
  Module AssertF := Assert (F_inhab).

  Module B_inhab.
    Definition t : Type := bool.
    Program Definition dummy := true.
    Solve All Obligations with easy.
  End B_inhab.

  Module AssertB := Assert (B_inhab).

  Definition of_q' prec emax Hprec Hemax (m : mode) (q : Qx) : binary_float prec emax :=
    match Qx_classify q with
    | Qx_ZERO _ _ _ _ => B754_zero false
    | Qx_INF _ _ _ => B754_infinity false
    | Qx_MINF _ _ _ => B754_infinity true
    | Qx_UNDEF _ _ _ => B754_nan
    | Qx_NZERO _ _ _ _ _ =>
      match num q with
      | Z0 => B754_nan (** absurd *)
      | Z.pos pn =>
        SF2B _ (proj1 (Bdiv_correct_aux prec emax Hprec Hemax m false pn 0%Z false (Z.to_pos (den q)) 0%Z))
      | Z.neg nn =>
        SF2B _ (proj1 (Bdiv_correct_aux prec emax Hprec Hemax m true nn 0%Z false (Z.to_pos (den q)) 0%Z))
      end
    end.

  (* Lemma of_q_correct' : forall prec emax Hprec Hemax m q, Q2Rx q = B2Rx (of_q' prec emax Hprec Hemax m q). *)
  (*   Proof. *)
  (*     intros prec emax Hprec Hemax m q. *)
  (*     unfold of_q', Q2Rx; destruct (Qx_classify q). *)
  (*     - rewrite e, e0. reflexivity. *)
  (*     - rewrite e, e0. reflexivity. *)
  (*     - rewrite e, e0. reflexivity. *)
  (*     - rewrite e, e0. *)
  (*       destruct (Z.pos pq =? 0)%Z; try reflexivity. *)
  (*       unfold Rdefinitions.Q2R; simpl. *)
  (*       now rewrite Rmult_0_l. *)
  (*     - rewrite e. destruct s; rewrite e0; simpl. *)
  (*       * replace (Q2R (Z.pos nq # pq)) with *)
  (*       ((F2R (Float radix2 (cond_Zopp false (Z.pos nq)) 0)) *)
  (*          / (F2R (Float radix2 (cond_Zopp false (Z.pos pq)) 0)))%R. *)
  (*       exact (Bdiv_correct_aux' mode false nq 0 false pq 0). *)
  (*       compute [F2R cond_Zopp Q2R]; simpl. *)
  (*       rewrite <- !P2R_INR. *)
  (*       rewrite !Rmult_1_r. *)
  (*       reflexivity. *)
  (*     * replace (Q2R (Z.neg nq # pq)) with *)
  (*       ((F2R (Float radix2 (cond_Zopp true (Z.pos nq)) 0)) *)
  (*          / (F2R (Float radix2 (cond_Zopp false (Z.pos pq)) 0)))%R. *)
  (*       exact (Bdiv_correct_aux' mode true nq 0 false pq 0). *)
  (*       compute [F2R cond_Zopp Q2R]; simpl. *)
  (*       rewrite <- !P2R_INR. *)
  (*       rewrite !Rmult_1_r. *)
  (*       reflexivity. *)
  (*    Qed. *)

  Definition of_q mw ew (m : mode) (q : Qx) : t :=
    AssertF.assert (check_param mw ew)
                   (fun H => mk_generic mw ew H (fun prec emax Hprec Hemax => of_q' prec emax Hprec Hemax m q)).

  Definition add (m : mode) (x y : t) : t :=
    AssertF.assert (same_format x y) (fun H => mk_with x (@Bplus _ _ (Hprec x) (Hemax x) m (value x) (same_format_cast H (value y)))).

  Definition sub (m : mode) (x y : t) : t :=
    AssertF.assert (same_format x y) (fun H => mk_with x (@Bminus _ _ (Hprec x) (Hemax x) m (value x) (same_format_cast H (value y)))).

  Definition mul (m : mode) (x y : t) : t :=
    AssertF.assert (same_format x y) (fun H => mk_with x (@Bmult _ _ (Hprec x) (Hemax x) m (value x) (same_format_cast H (value y)))).

  Definition div (m : mode) (x y : t) : t :=
    AssertF.assert (same_format x y) (fun H => mk_with x (@Bdiv _ _ (Hprec x) (Hemax x) m (value x) (same_format_cast H (value y)))).

  Program Definition fma (m : mode) (x y z : t) : t :=
    AssertF.assert (andb (same_format x y) (same_format x z)) (fun H => mk_with x (@Bfma _ _ (Hprec x) (Hemax x) m (value x) (same_format_cast _ (value y)) (same_format_cast _ (value z)))).
  Next Obligation.
    rewrite !Bool.andb_true_iff in H.
    exact (proj1 H).
  Defined.
  Next Obligation.
    rewrite !Bool.andb_true_iff in H.
    exact (proj2 H).
  Defined.

  Definition sqrt (m : mode) (x : t) : t :=
    mk_with x (@Bsqrt _ _ (Hprec x) (Hemax x) m (value x)).

  Definition abs (x : t) : t :=
    mk_with x (@Babs _ _ (value x)).

  Definition succ (x : t) : t :=
    mk_with x (@Op.Fsucc _ _ (Hprec x) (Hemax x) (value x)).

  Definition pred (x : t) : t :=
    mk_with x (@Op.Fpred _ _ (Hprec x) (Hemax x) (value x)).

  Definition neg (x : t) : t :=
    mk_with x (@Op.Fneg _ _ (value x)).

  Fixpoint least_bit_Pnat (n : positive) :=
  match n with
  | xH => O
  | xO p => S (least_bit_Pnat p)
  | xI p => O
  end.

  
  Definition shiftr_pos a p := Wf_nat.iter_nat p _ Z.div2 a.

  Lemma shiftr_pos_is_shiftr :
    forall a p, shiftr_pos a p = Z.shiftr a (Z.of_nat p).
  Proof.
    intros.
    destruct p.
    reflexivity.
    unfold shiftr_pos, Z.shiftr, Z.shiftl, Z.of_nat, Z.opp.
    rewrite Pos2Nat.inj_iter.
    rewrite SuccNat2Pos.id_succ.
    reflexivity.
  Qed.

    Lemma least_bit_shiftr_pos :
    forall m (b:bool),
    let e' := least_bit_Pnat m in
    let m' := if b then Z.neg m else Z.pos m in
    let m'' := shiftr_pos m' e' in
    Z.odd m'' = true.
  Proof.
    induction m; intro b.
    - destruct b;reflexivity.
    - assert (H:= IHm b);
      destruct b;
      replace (least_bit_Pnat m~0) with (S (least_bit_Pnat m)) in * by reflexivity;
      intros e' m';
      replace (shiftr_pos m' e') with (shiftr_pos (Z.div2 m') (least_bit_Pnat m)) by
        (unfold shiftr_pos, e'; rewrite nat_rect_succ_r; reflexivity).
      * replace (Z.div2 m') with (Z.neg m) by reflexivity.
        exact H.
      * replace (Z.div2 m') with (Z.pos m) by reflexivity.
        exact H.
    - destruct b; reflexivity.
  Qed.

  
  Lemma gcd_odd_pow_2:
    forall (m:positive) n,
      match m with xO _ => False | _ => True end ->
      Pos.gcd m (Pos.shiftl 1%positive (Npos n)) = 1%positive.
  Proof.
    destruct m as [p|p|]; intros n H; destruct H; simpl.
    - induction n using Pos.peano_ind.
      * compute [Pos.iter Z.mul Pos.mul].
        unfold Pos.gcd.
        replace (Pos.size_nat 2) with (2)%nat by reflexivity.
        simpl.
        replace (Pos.size_nat p + 2)%nat with (S (S (Pos.size_nat p))) by auto with *.
        reflexivity.
      * rewrite Pos.iter_succ.
        unfold Pos.gcd.
        simpl.
        replace (Pos.size_nat p + S (Pos.size_nat (Pos.iter xO 1%positive n)))%nat
        with (S (Pos.size_nat p + Pos.size_nat (Pos.iter xO 1%positive n))) by auto with *.
        exact IHn.
    - unfold Pos.gcd.
      reflexivity.
  Qed.

  Lemma to_q (f:t) : Qx.
  Proof.
    refine (match value f with
              | B754_zero _  => Qx_zero
              | B754_infinity b  => if b then Qx_minus_inf else Qx_inf
              | B754_nan => Qx_undef
              | B754_finite b m e _ =>
                let e' := least_bit_Pnat m in
                let m'  := if b then Z.neg m else Z.pos m in
                let e'' := (e + (Z.of_nat e'))%Z in
                match e'' with
                  | Z0 => Qxmake (shiftr_pos m' e') 1%Z (refl_equal _) _
                  | Z.pos _ => Qxmake (Z.shiftl m' e)%Z 1%Z (refl_equal _) _
                  | Z.neg p => Qxmake (shiftr_pos m' e') (Z.shiftl 1%Z (Z.pos p)) _ _
                end
            end
           ).
    - rewrite Z.gcd_1_r.
      reflexivity.
    - rewrite Z.gcd_1_r.
      reflexivity.
    - rewrite Z.shiftl_1_l.
      apply Z.leb_le.
      apply Z.lt_le_incl.
      apply Zpower_pos_gt_0.
      reflexivity.
    - assert (Z.shiftl 1 (Z.pos p) =? 0 = false)%Z by
          (rewrite Z.shiftl_1_l;
           apply Z.eqb_neq;
           apply Z.neq_sym;
           apply Z.lt_neq;
           exact (Zpower_pos_gt_0 2%Z p (refl_equal _))).
      rewrite H.
      assert (Z.odd (shiftr_pos m' e') = true) by (exact (least_bit_shiftr_pos m b)).
      destruct (shiftr_pos m' e'); clear H e0 e' m' e''.
      discriminate H0.
      rewrite <- (shift_equiv _ _ (Pos2Z.is_nonneg _)).
      replace (shift (Z.pos p) 1) with (shift_pos p 1%positive) by reflexivity.
      rewrite shift_pos_equiv.
      compute [Z.gcd].
      rewrite gcd_odd_pow_2.
      reflexivity.
      unfold Z.odd in H0.
      destruct p0; [exact I| discriminate H0| exact I].
      rewrite <- (shift_equiv _ _ (Pos2Z.is_nonneg _)).
      replace (shift (Z.pos p) 1) with (shift_pos p 1%positive) by reflexivity.
      rewrite shift_pos_equiv.
      compute [Z.gcd].
      rewrite gcd_odd_pow_2.
      reflexivity.
      unfold Z.odd in H0.
      destruct p0; [exact I| discriminate H0| exact I].
  Defined.

  Definition le (x y : t) : bool :=
    AssertB.assert (same_format x y) (fun H => (@Bleb _ _ (value x) (same_format_cast H (value y)))).

  Definition lt (x y : t) : bool :=
    AssertB.assert (same_format x y) (fun H => (@Bltb _ _ (value x) (same_format_cast H (value y)))).

  Definition eq (x y : t) : bool :=
    AssertB.assert (same_format x y) (fun H => (@Beqb _ _ (value x) (same_format_cast H (value y)))).

  Definition ge (x y : t) : bool :=
    AssertB.assert (same_format x y) (fun H => (@Bleb _ _ (same_format_cast H (value y)) (value x))).

  Definition gt (x y : t) : bool :=
    AssertB.assert (same_format x y) (fun H => (@Bltb _ _ (same_format_cast H (value y)) (value x))).

(** ** 4. convertions to and from [Z] and [Q]*)

   Program Definition of_bits' mw ew (H:check_param mw ew = true) (b : Z) : binary_float (cprec mw) (cemax ew) :=
     match Bits.binary_float_of_bits mw ew _ _ _ b with
     | Binary.B754_nan _ _ _ _ _ => B754_nan
     | Binary.B754_zero _ _ s => B754_zero s
     | Binary.B754_infinity _ _ s => B754_infinity s
     | Binary.B754_finite _ _ s m e H => B754_finite s m e H
     end.
   Next Obligation.
   unfold check_param in H.
   rewrite !Bool.andb_true_iff in H.
   rewrite <- !Zlt_is_lt_bool in H.
   intuition.
   Defined.
   Next Obligation.
   unfold check_param in H.
   rewrite !Bool.andb_true_iff in H.
   rewrite <- !Zlt_is_lt_bool in H.
   intuition.
   Defined.
   Next Obligation.
   unfold check_param in H.
   rewrite !Bool.andb_true_iff in H.
   rewrite <- !Zlt_is_lt_bool in H.
   intuition.
   Defined.

   Definition of_bits mw ew (z : Z.t) : t :=
    AssertF.assert (check_param mw ew)
                   (fun H =>
    {|
      mw := mw;
      ew := ew;
      HG := H;
      value := of_bits' mw ew H z;
    |}
).

   Definition pl_cst mw := (Zaux.iter_nat xO (Z.to_nat (Z.pred mw)) xH)%Z.

   Lemma pl_valid mw (Hw:Prec_gt_0 mw) : (Z.pos (Digits.digits2_pos (pl_cst mw)) <? (cprec mw))%Z = true.
   Proof.
     assert (G:forall n, Digits.digits2_Pnat (Zaux.iter_nat xO n xH)%Z = n).
     - induction n.
       * reflexivity.
       * rewrite iter_nat_S; simpl.
         rewrite IHn; reflexivity.
     - rewrite Digits.Zpos_digits2_pos.
       rewrite <- Digits.Z_of_nat_S_digits2_Pnat.
       unfold pl_cst, cprec.  unfold Prec_gt_0 in Hw.
       rewrite G;clear G.
       rewrite Nat2Z.inj_succ.
       rewrite Z2Nat.id; [rewrite Z.ltb_lt | ]; lia.
   Qed.

   Definition to_bits (f : t) : Z :=
     match value f with
     | B754_nan =>
       Bits.bits_of_binary_float (mw f) (ew f) (Binary.B754_nan (prec f) (emax f) true (pl_cst (mw f)) (pl_valid (mw f) (check_param_is_Hw _ _ (HG f))))
     | B754_zero s => Bits.bits_of_binary_float (mw f) (ew f) (Binary.B754_zero (prec f) (emax f) s)
     | B754_infinity s => Bits.bits_of_binary_float (mw f) (ew f) (Binary.B754_infinity (prec f) (emax f) s)
     | B754_finite s m e H => Bits.bits_of_binary_float (mw f) (ew f) (Binary.B754_finite (prec f) (emax f) s m e H)
     end.

   Definition nan mw ew : t :=
    AssertF.assert (check_param mw ew) (fun H =>  mk_generic mw ew H (fun _ _ _ _ => B754_nan)).

   Definition zero mw ew b : t :=
    AssertF.assert (check_param mw ew) (fun H =>  mk_generic mw ew H (fun _ _ _ _ => B754_zero b)).

   Definition inf mw ew b : t :=
    AssertF.assert (check_param mw ew) (fun H =>  mk_generic mw ew H (fun _ _ _ _ => B754_infinity b)).

   (** SFclassify is currently false:
       https://github.com/coq/coq/issues/16096
    *)
   Definition classify f : float_class :=
    match value f with
    | B754_nan => FloatClass.NaN
    | B754_infinity false => PInf
    | B754_infinity true => NInf
    | B754_zero false => PZero
    | B754_zero true => NZero
    | B754_finite false m _ _ =>
      if (digits2_pos m =? Z.to_pos (prec f))%positive then PNormal
      else PSubn
    | B754_finite true m _ _ =>
      if (digits2_pos m =? Z.to_pos (prec f))%positive then NNormal
      else NSubn
    end.

End GenericFloat.

Module GenericInterval.

  Definition t : Type := @Generic Interval.

  Module I_inhab.
    Definition t : Type := t.
    Program Definition dummy : t := {|
      mw := 23;
      ew := 8;
      value := Intv 24 128 -oo +oo true;
      HG := _;
    |}.
    Solve All Obligations with easy.
  End I_inhab.

  Module AssertI := Assert (I_inhab).

  Module O_inhab.
    Definition t : Type := option t.
    Program Definition dummy : t := None.
    Solve All Obligations with easy.
  End O_inhab.

  Module AssertO := Assert (O_inhab).

  Definition inter (x:t) (y:t) : option t :=
    AssertO.assert (same_format x y) (fun H =>
      let r := inter (prec x) (emax x) (value x) (same_format_cast H (value y)) in
      match r with
       | Some r => Some (mk_with x (r : Interval _ _))
       | None => None
      end                                                                                                          ).

  Definition add (m:mode) (x:t) (y:t) : t :=
    AssertI.assert (same_format x y) (fun H =>
       mk_with x (Iadd (prec x) (emax x) (Hprec x) (Hemax x) m (value x) (same_format_cast H (value y)))
  ).

  Definition ge (x:t) : option t :=
    mk_witho x (Ige (prec x) (emax x) (value x)).
  Definition gt (x:t) : option t :=
    mk_witho x (Igt (prec x) (emax x) (value x)).
  Definition le (x:t) : option t :=
    mk_witho x (Ile (prec x) (emax x) (value x)).
  Definition lt (x:t) : option t :=
    mk_witho x (Ilt (prec x) (emax x) (value x)).
  Definition singleton (x:GenericFloat.t) : t :=
    mk_with x (singleton _ _ (value x)).
  Definition is_singleton (x:t) : option GenericFloat.t :=
    mk_witho x (is_singleton _ _ (value x)).
  Definition top (mw:Z) (ew:Z) : t :=
    AssertI.assert (check_param mw ew) (fun H => @mk_generic Interval mw ew H (fun prec emax _ _ => top prec emax)).

End GenericInterval.
