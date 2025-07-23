# 1 "extracted/BinPos.ml"
open BinPosDef

module Pos =
 struct
  (** val add_carry :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

  let rec add_carry = fun p q -> Farith_Big.succ (Farith_Big.add p q)

  (** val pred : Farith_Big.big_int -> Farith_Big.big_int **)

  let pred = fun n -> Farith_Big.max Farith_Big.one (Farith_Big.pred n)

  type mask = Pos.mask =
  | IsNul
  | IsPos of Farith_Big.big_int
  | IsNeg

  (** val succ_double_mask : mask -> mask **)

  let succ_double_mask = function
  | IsNul -> IsPos Farith_Big.one
  | IsPos p -> IsPos (Farith_Big.succ_double p)
  | IsNeg -> IsNeg

  (** val double_mask : mask -> mask **)

  let double_mask = function
  | IsPos p -> IsPos (Farith_Big.double p)
  | x0 -> x0

  (** val double_pred_mask : Farith_Big.big_int -> mask **)

  let double_pred_mask x =
    Farith_Big.positive_case
      (fun p -> IsPos (Farith_Big.double (Farith_Big.double p)))
      (fun p -> IsPos (Farith_Big.double
      (Farith_Big.pred_double p)))
      (fun _ -> IsNul)
      x

  (** val sub_mask : Farith_Big.big_int -> Farith_Big.big_int -> mask **)

  let rec sub_mask x y =
    Farith_Big.positive_case
      (fun p ->
      Farith_Big.positive_case
        (fun q -> double_mask (sub_mask p q))
        (fun q -> succ_double_mask (sub_mask p q))
        (fun _ -> IsPos (Farith_Big.double p))
        y)
      (fun p ->
      Farith_Big.positive_case
        (fun q -> succ_double_mask (sub_mask_carry p q))
        (fun q -> double_mask (sub_mask p q))
        (fun _ -> IsPos (Farith_Big.pred_double p))
        y)
      (fun _ ->
      Farith_Big.positive_case
        (fun _ -> IsNeg)
        (fun _ -> IsNeg)
        (fun _ -> IsNul)
        y)
      x

  (** val sub_mask_carry :
      Farith_Big.big_int -> Farith_Big.big_int -> mask **)

  and sub_mask_carry x y =
    Farith_Big.positive_case
      (fun p ->
      Farith_Big.positive_case
        (fun q -> succ_double_mask (sub_mask_carry p q))
        (fun q -> double_mask (sub_mask p q))
        (fun _ -> IsPos (Farith_Big.pred_double p))
        y)
      (fun p ->
      Farith_Big.positive_case
        (fun q -> double_mask (sub_mask_carry p q))
        (fun q -> succ_double_mask (sub_mask_carry p q))
        (fun _ -> double_pred_mask p)
        y)
      (fun _ -> IsNeg)
      x

  (** val sub :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

  let sub = fun n m -> Farith_Big.max Farith_Big.one (Farith_Big.sub n m)

  (** val iter : ('a1 -> 'a1) -> 'a1 -> Farith_Big.big_int -> 'a1 **)

  let rec iter f x n =
    Farith_Big.positive_case
      (fun n' -> f (iter f (iter f x n') n'))
      (fun n' -> iter f (iter f x n') n')
      (fun _ -> f x)
      n

  (** val div2 : Farith_Big.big_int -> Farith_Big.big_int **)

  let div2 p =
    Farith_Big.positive_case
      (fun p0 -> p0)
      (fun p0 -> p0)
      (fun _ -> Farith_Big.one)
      p

  (** val div2_up : Farith_Big.big_int -> Farith_Big.big_int **)

  let div2_up p =
    Farith_Big.positive_case
      (fun p0 -> Farith_Big.succ p0)
      (fun p0 -> p0)
      (fun _ -> Farith_Big.one)
      p

  (** val sqrtrem_step :
      (Farith_Big.big_int -> Farith_Big.big_int) -> (Farith_Big.big_int ->
      Farith_Big.big_int) -> (Farith_Big.big_int * mask) ->
      Farith_Big.big_int * mask **)

  let sqrtrem_step f g = function
  | (s, y) ->
    (match y with
     | IsPos r ->
       let s' = Farith_Big.succ_double (Farith_Big.double s) in
       let r' = g (f r) in
       if Farith_Big.le s' r'
       then ((Farith_Big.succ_double s), (sub_mask r' s'))
       else ((Farith_Big.double s), (IsPos r'))
     | _ ->
       ((Farith_Big.double s),
         (sub_mask (g (f Farith_Big.one)) (Farith_Big.double
           (Farith_Big.double Farith_Big.one)))))

  (** val sqrtrem : Farith_Big.big_int -> Farith_Big.big_int * mask **)

  let rec sqrtrem p =
    Farith_Big.positive_case
      (fun p0 ->
      Farith_Big.positive_case
        (fun p1 ->
        sqrtrem_step (fun x -> Farith_Big.succ_double x) (fun x ->
          Farith_Big.succ_double x) (sqrtrem p1))
        (fun p1 ->
        sqrtrem_step (fun x -> Farith_Big.double x) (fun x ->
          Farith_Big.succ_double x) (sqrtrem p1))
        (fun _ -> (Farith_Big.one, (IsPos (Farith_Big.double
        Farith_Big.one))))
        p0)
      (fun p0 ->
      Farith_Big.positive_case
        (fun p1 ->
        sqrtrem_step (fun x -> Farith_Big.succ_double x) (fun x ->
          Farith_Big.double x) (sqrtrem p1))
        (fun p1 ->
        sqrtrem_step (fun x -> Farith_Big.double x) (fun x ->
          Farith_Big.double x) (sqrtrem p1))
        (fun _ -> (Farith_Big.one, (IsPos Farith_Big.one)))
        p0)
      (fun _ -> (Farith_Big.one, IsNul))
      p

  (** val iter_op :
      ('a1 -> 'a1 -> 'a1) -> Farith_Big.big_int -> 'a1 -> 'a1 **)

  let rec iter_op op p a =
    Farith_Big.positive_case
      (fun p0 -> op a (iter_op op p0 (op a a)))
      (fun p0 -> iter_op op p0 (op a a))
      (fun _ -> a)
      p
 end
