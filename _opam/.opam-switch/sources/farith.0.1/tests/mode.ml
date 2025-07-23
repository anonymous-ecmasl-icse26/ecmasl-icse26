module F = Farith2.F

let fpp mode fmt q = F.pp fmt (F.of_q mode ~mw:52 ~ew:11 q)

let () =
  begin
    let f = (F.of_float 3.1) in
    Format.printf "[F]  3.1 = %a@." F.pp f;
    let q = Q.make (Z.of_int 31) (Z.of_int 10) in
    Format.printf "[Fp] 3.1 = %a@." F.pp (F.round ~mw:24 ~ew:11 ZR (F.of_float 3.1)) ;
    Format.printf "[Fq] 3.1 = %a@." F.pp (F.of_q ~mw:24 ~ew:11 ZR q) ;
    Format.printf "-----------------------@." ;
    Format.printf " Simple Roundings@." ;
    let job m m2 q =
      begin
        Format.printf "-----------------------@." ;
        Format.printf "Q=%a@." Q.pp_print q ;
        Format.printf "[F-%s] %a@." m (fpp m2) q ;
        Format.printf "[F-%s] %a@." m (fpp m2) (Q.neg q) ;
      end in
    job "NE" Farith2.NE q ;
    job "NA" Farith2.NA q ;
    job "ZR" Farith2.ZR q ;
    job "UP" Farith2.UP q ;
    job "DN" Farith2.DN q ;
    Format.printf "-----------------------@." ;
    Format.printf " Tie Breaks (NE)@." ;
    let eps = Z.shift_left Z.one 51 in
    let e_ex = Q.make (Z.of_int 0b100) eps in
    let e_lo = Q.make (Z.of_int 0b101) eps in
    let e_ti = Q.make (Z.of_int 0b110) eps in
    let e_up = Q.make (Z.of_int 0b111) eps in
    job "NE-ex" Farith2.NE (Q.add Q.one e_ex) ;
    job "NE-lo" Farith2.NE (Q.add Q.one e_lo) ;
    job "NE-ti" Farith2.NE (Q.add Q.one e_ti) ;
    job "NE-up" Farith2.NE (Q.add Q.one e_up) ;
    Format.printf "-----------------------@." ;
    Format.printf " Tie Breaks (NA)@." ;
    job "NA-ex" Farith2.NA (Q.add Q.one e_ex) ;
    job "NA-lo" Farith2.NA (Q.add Q.one e_lo) ;
    job "NA-ti" Farith2.NA (Q.add Q.one e_ti) ;
    job "NA-up" Farith2.NA (Q.add Q.one e_up) ;
  end
