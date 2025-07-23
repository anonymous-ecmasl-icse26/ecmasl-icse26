type t =
  | Success
  | Failure
  | Anomaly
  | Skipped
  | Timeout

val equal : t -> t -> bool

val pp : t Fmt.t
