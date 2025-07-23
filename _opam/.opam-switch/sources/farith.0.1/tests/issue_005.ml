open Format
open Farith2

let f_convert r =
  let fp = F.of_float r in
  printf "[F] %f : %a@." r F.pp fp ; fp

let () =
  begin
    ignore (f_convert 0.1) ;
  end
