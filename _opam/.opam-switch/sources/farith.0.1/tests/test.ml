open Format

let () =
  printf "Flocq version: %a@."
    Z.pp_print Farith2.flocq_version

open Farith2

module Run = struct
  let () =
    printf "@[<3>Run tests with %s@\n" "Farith2.F";
    let add u v =
      let fu = F.of_float u in
      let fv = F.of_float v in
      let fr = F.add NE fu fv in
      let r = F.to_float NE fr in
      printf "%f + %f = %f@\n" u v r;
      printf "%f : %a@\n" u F.pp fu;
      printf "%f : %a@\n" v F.pp fv;
      printf "%f : %a@]@\n" r F.pp fr;
    in
    add (0.1)   (2.0);
    add (-.0.1) (2.0);
    add (-.0.1) (-.2.0);
    add (0.1)   (-.2.0)
end
