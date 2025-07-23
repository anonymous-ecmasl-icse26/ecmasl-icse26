open BinPosDef

module Pos :
 sig
  val add_carry :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int

  val pred : Farith_Big.big_int -> Farith_Big.big_int

  type mask = Pos.mask =
  | IsNul
  | IsPos of Farith_Big.big_int
  | IsNeg

  val succ_double_mask : mask -> mask

  val double_mask : mask -> mask

  val double_pred_mask : Farith_Big.big_int -> mask

  val sub_mask : Farith_Big.big_int -> Farith_Big.big_int -> mask

  val sub_mask_carry : Farith_Big.big_int -> Farith_Big.big_int -> mask

  val sub : Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int

  val iter : ('a1 -> 'a1) -> 'a1 -> Farith_Big.big_int -> 'a1

  val div2 : Farith_Big.big_int -> Farith_Big.big_int

  val div2_up : Farith_Big.big_int -> Farith_Big.big_int

  val sqrtrem_step :
    (Farith_Big.big_int -> Farith_Big.big_int) -> (Farith_Big.big_int ->
    Farith_Big.big_int) -> (Farith_Big.big_int * mask) ->
    Farith_Big.big_int * mask

  val sqrtrem : Farith_Big.big_int -> Farith_Big.big_int * mask

  val iter_op : ('a1 -> 'a1 -> 'a1) -> Farith_Big.big_int -> 'a1 -> 'a1
 end
