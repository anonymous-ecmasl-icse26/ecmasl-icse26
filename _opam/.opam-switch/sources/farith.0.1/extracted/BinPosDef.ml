
module Pos =
 struct
  type mask =
  | IsNul
  | IsPos of Farith_Big.big_int
  | IsNeg
 end
