
module Z :
 sig
  type t = Farith_Big.big_int

  val pow : Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int

  val to_nat : Farith_Big.big_int -> Farith_Big.big_int

  val to_pos : Farith_Big.big_int -> Farith_Big.big_int

  val pos_div_eucl :
    Farith_Big.big_int -> Farith_Big.big_int ->
    Farith_Big.big_int * Farith_Big.big_int

  val even : Farith_Big.big_int -> bool
 end
