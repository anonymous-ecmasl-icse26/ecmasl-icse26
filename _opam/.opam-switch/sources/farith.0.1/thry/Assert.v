From Flocq Require Import IEEE754.BinarySingleNaN.
From Coq Require Import Program ZArith.

Module Type Inhabited.
  Parameter t : Type.
  Parameter dummy : t.
End Inhabited.

Module Assert (M : Inhabited).
  Program Definition assert (x : bool) (f : x = true -> M.t) : M.t :=
    match x with
    | true => f _
    | false => M.dummy
    end.

  Extract Inlined Constant assert => "(fun x f -> assert x; f ())".

  Lemma assert_spec:
    forall (pre : bool) (f : M.t),
      pre = true -> assert pre (fun _ => f) = f.
  Proof.
    intros.
    unfold assert.
    now rewrite H.
  Qed.
End Assert.
