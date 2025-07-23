type t =
  | Success
  | Failure
  | Anomaly
  | Skipped
  | Timeout

let equal a b =
  match (a, b) with
  | (Success, Success)
  | (Failure, Failure)
  | (Anomaly, Anomaly)
  | (Skipped, Skipped)
  | (Timeout, Timeout) ->
    true
  | ((Success | Failure | Anomaly | Skipped | Timeout), _) -> false

let pp ppf =
  let open Ecma_sl in
  function
  | Success -> Font.pp_text_out [ Green ] ppf "SUCCESS"
  | Failure -> Font.pp_text_out [ Red ] ppf "FAILURE"
  | Anomaly -> Font.pp_text_out [ Purple ] ppf "ANOMALY"
  | Skipped -> Font.pp_text_out [ Yellow ] ppf "SKIPPED"
  | Timeout -> Font.pp_text_out [ Cyan ] ppf "TIMEOUT"
