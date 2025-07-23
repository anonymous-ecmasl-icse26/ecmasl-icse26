From Coq Require Import ZArith Reals Qreals Extraction.
Require Import Rextended.

(** * A type of rationals suitable for conversions from and to fp
  and compatible with zarith Q
*)

Record Qx := Qxmake {
  num : Z.t; den : Z.t;
  Hden1 : (0 <=? den)%Z = true;
  Hden2 : (if den =? 0 then orb (orb (num =? -1) (num =? 0)) (num =? 1) else Z.gcd num den =? 1)%Z = true
}.

Lemma Hden2' :
  forall q, (den q = 0 -> num q = -1 \/ num q = 0 \/ num q = 1)%Z.
Proof.
  intros q H.
  rewrite <- !Z.eqb_eq in *.
  assert (H2 := Hden2 q).
  rewrite H in H2.
  destruct (num q =? -1)%Z; destruct (num q =? 0)%Z; destruct (num q =? 1)%Z;
  tauto.
Qed.

Definition Qx_zero := Qxmake 0%Z 1%Z (refl_equal _) (refl_equal _).
Definition Qx_undef := Qxmake 0%Z 0%Z (refl_equal _) (refl_equal _).
Definition Qx_inf := Qxmake 1%Z 0%Z (refl_equal _) (refl_equal _).
Definition Qx_minus_inf := Qxmake (-1)%Z 0%Z (refl_equal _) (refl_equal _).
Definition Qx_half := Qxmake (1)%Z 2%Z (refl_equal _) (refl_equal _).
Definition Qx_one := Qxmake (1)%Z 1%Z (refl_equal _) (refl_equal _).
Definition Qx_two := Qxmake (2)%Z (1)%Z (refl_equal _) (refl_equal _).

Inductive Qx_kind (q : Qx) := (* cf Q of Zarith *)
  | Qx_INF:  (num q = 1)%Z  -> (den q = 0)%Z -> Qx_kind q
  | Qx_MINF: (num q = -1)%Z -> (den q = 0)%Z -> Qx_kind q
  | Qx_UNDEF: (num q = 0)%Z -> (den q = 0)%Z -> Qx_kind q
  | Qx_ZERO: (num q = 0)%Z  -> forall pq, (den q = Z.pos pq)%Z -> Qx_kind q
  | Qx_NZERO: forall nq (s:{num q = Z.pos nq} + {num q = Z.neg nq}) pq, (den q = Z.pos pq)%Z -> Qx_kind q.

Extraction Implicit Qx_ZERO [pq].
Extraction Implicit Qx_NZERO [nq s pq].

Lemma Qx_classify (q: Qx) : Qx_kind q.
Proof.
  intros.
    case_eq (den q); [intros Hd | intros pd Hd| intros nd Hd].
  - case_eq (num q); [intros Hn | intros pn Hn| intros nn Hn].
    * exact (Qx_UNDEF q Hn Hd).
    * assert (H: num q = ( 1)%Z) by (destruct (Hden2' q Hd) as [H|[H|H]]; rewrite Hn in *;
                                       [discriminate H| discriminate H | assumption ]).
      exact (Qx_INF q H Hd).
    * assert (H: num q = (-1)%Z) by (destruct (Hden2' q Hd) as [H|[H|H]]; rewrite Hn in *;
                                       [assumption| discriminate H | discriminate H]).
      exact (Qx_MINF q H Hd).
  - case_eq (num q); [intros Hn | intros nq Hn| intros nq Hn].
    * exact (Qx_ZERO  q Hn pd Hd).
    * exact (Qx_NZERO q nq (left Hn) pd Hd).
    * exact (Qx_NZERO q nq (right Hn) pd Hd).
  - assert (A := Hden1 q).
    rewrite Hd in A.
    discriminate A.
Defined.

Definition Q2Rx q : Rx :=
  if (den q =? 0)%Z then
    if (num q =? 0)%Z then Real (0%R)
    else Inf (num q <? 0)%Z
  else Real (Q2R (Qmake (num q) (Z.to_pos (den q)))).
