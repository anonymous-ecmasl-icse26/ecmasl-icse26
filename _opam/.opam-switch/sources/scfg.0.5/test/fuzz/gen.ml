open Crowbar

let ( let* ) = dynamic_bind

let ( let+ ) = map

let unicode_bytes =
  let+ values = [ list1 uchar ] in
  let buf = Buffer.create (List.length values) in
  List.iter (fun u -> Buffer.add_utf_8_uchar buf u) values;
  Buffer.contents buf

let directive =
  fix (fun directive ->
    let* name = unicode_bytes in
    let* params = list unicode_bytes in
    let+ children = [ list directive ] in
    let open Scfg.Types in
    { name; params; children } )

let config = list directive
