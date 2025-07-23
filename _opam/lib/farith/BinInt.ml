# 1 "extracted/BinInt.ml"

module Z =
 struct
  type t = Farith_Big.big_int

  (** val pow :
      Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

  let pow x y =
    Farith_Big.z_case
      (fun _ -> Farith_Big.one)
      (fun p -> Farith_Big.pow_pos x p)
      (fun _ -> Farith_Big.zero)
      y

  (** val to_nat : Farith_Big.big_int -> Farith_Big.big_int **)

  let to_nat z =
    Farith_Big.z_case
      (fun _ -> Farith_Big.zero)
      (fun p -> Farith_Big.identity p)
      (fun _ -> Farith_Big.zero)
      z

  (** val to_pos : Farith_Big.big_int -> Farith_Big.big_int **)

  let to_pos z =
    Farith_Big.z_case
      (fun _ -> Farith_Big.one)
      (fun p -> p)
      (fun _ -> Farith_Big.one)
      z

  (** val pos_div_eucl :
      Farith_Big.big_int -> Farith_Big.big_int ->
      Farith_Big.big_int * Farith_Big.big_int **)

  let rec pos_div_eucl a b =
    Farith_Big.positive_case
      (fun a' ->
      let (q, r) = pos_div_eucl a' b in
      let r' =
        Farith_Big.add (Farith_Big.mult (Farith_Big.double Farith_Big.one) r)
          Farith_Big.one
      in
      if Farith_Big.lt r' b
      then ((Farith_Big.mult (Farith_Big.double Farith_Big.one) q), r')
      else ((Farith_Big.add
              (Farith_Big.mult (Farith_Big.double Farith_Big.one) q)
              Farith_Big.one), (Farith_Big.sub r' b)))
      (fun a' ->
      let (q, r) = pos_div_eucl a' b in
      let r' = Farith_Big.mult (Farith_Big.double Farith_Big.one) r in
      if Farith_Big.lt r' b
      then ((Farith_Big.mult (Farith_Big.double Farith_Big.one) q), r')
      else ((Farith_Big.add
              (Farith_Big.mult (Farith_Big.double Farith_Big.one) q)
              Farith_Big.one), (Farith_Big.sub r' b)))
      (fun _ ->
      if Farith_Big.le (Farith_Big.double Farith_Big.one) b
      then (Farith_Big.zero, Farith_Big.one)
      else (Farith_Big.one, Farith_Big.zero))
      a

  (** val even : Farith_Big.big_int -> bool **)

  let even z =
    Farith_Big.z_case
      (fun _ -> true)
      (fun p ->
      Farith_Big.positive_case
        (fun _ -> false)
        (fun _ -> true)
        (fun _ -> false)
        p)
      (fun p ->
      Farith_Big.positive_case
        (fun _ -> false)
        (fun _ -> true)
        (fun _ -> false)
        p)
      z
 end
