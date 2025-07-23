open BinPos

(** val shift_pos :
    Farith_Big.big_int -> Farith_Big.big_int -> Farith_Big.big_int **)

let shift_pos n z =
  Pos.iter (fun x -> Farith_Big.double x) z n
