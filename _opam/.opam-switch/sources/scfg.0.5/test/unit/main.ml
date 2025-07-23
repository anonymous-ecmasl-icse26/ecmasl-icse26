open Scfg

(** Testing other functions in Parse module. *)
let () =
  let chan = open_in "test_chan.scfg" in
  match Parse.from_channel chan with
  | Error _e -> assert false
  | Ok config ->
    let expected = "a b c" in
    let s = Format.asprintf "%a" Pp.config config in
    assert (s = expected)

let () =
  let s = {|a b c|} in
  match Parse.from_string s with
  | Error (`Msg e) ->
    Format.eprintf "ERROR: %s@\n" e;
    assert false
  | Ok config ->
    let expected = {|a b c|} in
    let s = Format.asprintf "%a" Pp.config config in
    assert (s = expected)

(** Testing queries. *)
let file =
  match Fpath.of_string "query.scfg" with
  | Error _e -> assert false
  | Ok file -> file

let () =
  let config =
    match Parse.from_file file with
    | Error _e -> assert false
    | Ok config -> config
  in
  assert (List.length config = 5);
  let n1 = Query.get_dirs "n1" config in
  assert (List.length n1 = 2);
  let n11 = Query.get_dir "n1" n1 in
  let n11 = match n11 with None -> assert false | Some n11 -> n11 in
  let n12 =
    match Query.get_dir "n1.2" n11.children with
    | None -> assert false
    | Some n12 -> n12
  in
  let pn12 =
    match Query.get_params 2 n12 with
    | Error _e -> assert false
    | Ok pn12 -> pn12
  in
  assert (pn12 = [ "p1"; "p2" ]);
  begin
    match Query.get_params 3 n12 with
    | Error (`Msg "directive n1.2: want 3 params, got only 2") -> ()
    | Error _ | Ok _ -> assert false
  end;
  begin
    match Query.get_param 0 n12 with
    | Error _ -> assert false
    | Ok p -> assert (p = "p1")
  end;
  match Query.get_param 5 n12 with
  | Error (`Msg "directive n1.2: want param at index 5, got only 2") -> ()
  | Error _ | Ok _ -> assert false

let () = Format.printf "all tests OK! 🐱"
