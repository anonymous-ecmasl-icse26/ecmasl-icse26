# 1 "extracted/BinPosDef.mli"

module Pos :
 sig
  type mask =
  | IsNul
  | IsPos of Farith_Big.big_int
  | IsNeg
 end
