open Farith2

let eps n = Stdlib.ldexp 1.0 n

let pp_class fmt u =
  Format.pp_print_string fmt
    begin
      match classify_float u with
      | FP_zero -> "zero"
      | FP_normal -> "normal"
      | FP_subnormal -> "sub-normal"
      | FP_infinite -> "infinity"
      | FP_nan -> "nan"
    end

let test_of_float n =
  let u = eps n in
    let f = F.of_float u in
    Format.printf "of-float 1p%d = %a (%a)@." n F.pp f pp_class u

(* let test_to_float n =
 *   begin
 *     let u = eps n in
 *     let f = F.power2 n in
 *     let v = F.to_float f in
 *     Format.printf "to-float %a = %f (%a)@." F.pp f v pp_class v ;
 *     let fu,eu = Stdlib.frexp u in
 *     let fv,ev = Stdlib.frexp v in
 *     Format.printf "   expected = %fp%d@\n" fu eu ;
 *     Format.printf "   obtained = %fp%d@." fv ev ;
 *   end *)

let limits = [ 1023;1024;-1022;-1023;-1048;-1074;-1075 ]

let () =
  begin
    List.iter test_of_float limits ;
    (* List.iter test_to_float limits ; *)
  end
