type t = Symbolic

let p f = Fpath.to_string f

module ObjModels = struct
  type t =
    | Default
    | Logging
    | Lifting
    | LogLifting

  let to_string = function
    | Default -> "default"
    | Logging -> "logging"
    | Lifting -> "lifting"
    | LogLifting -> "loglifting"

  let opts =
    [ (to_string Default, to_string Default)
    ; (to_string Logging, to_string Logging)
    ; (to_string Lifting, to_string Lifting)
    ; (to_string LogLifting, to_string LogLifting)
    ]
end

let cmd tool ~workspace ~file ~objmodel =
  match tool with
  | Symbolic ->
    ( "ecma-sl"
    , [| "ecma-sl"
       ; "symbolic"
       ; "--workspace"
       ; p workspace
       ; p file
       ; "--objmodel"
       ; objmodel
       ; "-A"
       ; "--continue-on-error"
      |] )
