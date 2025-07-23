(** Module defining types used to represent a config. *)

(** A directive has a name, a list of parameters and children (a list of
    directive). *)
type directive =
  { name : string
  ; params : string list
  ; children : directive list
  }

(** A config is a list of directives. *)
type config = directive list
