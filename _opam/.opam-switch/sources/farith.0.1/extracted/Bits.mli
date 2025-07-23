open BinInt
open Binary
open SpecFloat

val join_bits :
  Farith_Big.big_int -> Farith_Big.big_int -> bool -> Farith_Big.big_int ->
  Farith_Big.big_int -> Farith_Big.big_int

val split_bits :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  (bool * Farith_Big.big_int) * Farith_Big.big_int

val bits_of_binary_float :
  Farith_Big.big_int -> Farith_Big.big_int -> binary_float ->
  Farith_Big.big_int

val binary_float_of_bits_aux :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int -> full_float

val binary_float_of_bits :
  Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int ->
  binary_float
