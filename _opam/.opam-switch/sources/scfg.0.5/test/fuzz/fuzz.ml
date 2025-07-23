open Scfg

let () = Random.self_init ()

let () =
  Crowbar.add_test ~name:"Print and parse fuzzing" [ Gen.config ] (fun config ->
    let printed = Fmt.str "%a" Pp.config config in
    match Parse.from_string printed with
    | Error (`Msg msg) ->
      Crowbar.failf "%s on the given input@\n***`%S`@\n***`%s`@\n" msg printed
        printed
    | Ok config -> (
      let printed = Fmt.str "%a" Pp.config config in
      match Parse.from_string printed with
      | Error (`Msg msg) ->
        Crowbar.failf "%s on the given input@\n***`%S`@\n***`%s`@\n" msg printed
          printed
      | Ok parsed -> Crowbar.check_eq ~pp:Pp.config config parsed ) )
