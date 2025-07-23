open Farith2

(** not tested *)

let tiebreak a b n =
  begin
    (* Tie breaks at [2^(n-1) + e] with [n] bits precision *)
    let m = n-1 in
    let up = Q.mul_2exp Q.one m in
    let q = Q.(up + Q.make (Z.of_int a) (Z.of_int b)) in
    let f0 = F.of_qint ~bits:(n+1) q in (* exact *)
    let f1,f2 = F.seize ~bits:n f0 in
    Format.printf "------------------------------------------@\n" ;
    Format.printf "         - %a    (%a)@\n" F.pp f1 F.pp f1 ;
    Format.printf "1p%d+%d/%d = %a (%a)@\n" m a b pp f0 F.pp f0 ;
    Format.printf "         + %a    (%a)@\n" pp f2 F.pp f2 ;
    Format.printf "mantissa =  %a@\n" Z.pp_print (Z.shift_left Z.one n) ;
    let f1 = F.neg f0 in
    let pos_ne = F.round ~mode:F.NE ~bits:n f0 in
    let pos_na = F.round ~mode:F.NA ~bits:n f0 in
    let neg_ne = F.round ~mode:F.NE ~bits:n f1 in
    let neg_na = F.round ~mode:F.NA ~bits:n f1 in
    Format.printf "+NE %a (%a)@\n" F.pp pos_ne pp pos_ne ;
    Format.printf "-NE %a (%a)@\n" F.pp neg_ne pp neg_ne ;
    Format.printf "+NA %a (%a)@\n" F.pp pos_na pp pos_na ;
    Format.printf "-NA %a (%a)@\n" F.pp neg_na pp neg_na ;
    Format.print_flush () ;
  end

let () =
  begin
    tiebreak 1 2 F.b64 ;
    tiebreak 3 2 F.b64 ;
  end
