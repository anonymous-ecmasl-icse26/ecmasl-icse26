(* SPDX-License-Identifier: AGPL-3.0-or-later *)
(* Copyright © 2024 The Prelude programmers *)

(* This module is automatically opened in all files in order to hide certain unwanted parts of the standard library. *)

include Stdlib

type ('a, 'b) result = ('a, 'b) Stdlib.result

module Empty = struct end

(* Hide unwanted functions. *)
type you_are_trying_to_use_a_function_that_has_been_hidden_by_prelude = |

type because_it_is_unwanted = |

type this_function_has_been_hidden_by_prelude_because_it_is_unwanted =
     you_are_trying_to_use_a_function_that_has_been_hidden_by_prelude
  -> because_it_is_unwanted

let hidden : this_function_has_been_hidden_by_prelude_because_it_is_unwanted =
 fun (_ : you_are_trying_to_use_a_function_that_has_been_hidden_by_prelude) ->
  (assert false : because_it_is_unwanted)

module Float = struct
  include Float

  let of_string = hidden

  module Infix = struct
    external ( < ) : float -> float -> bool = "%lessthan"

    external ( <= ) : float -> float -> bool = "%lessequal"

    external ( <> ) : float -> float -> bool = "%notequal"

    external ( = ) : float -> float -> bool = "%equal"

    external ( > ) : float -> float -> bool = "%greaterthan"

    external ( >= ) : float -> float -> bool = "%greaterequal"

    external compare : float -> float -> int = "%compare"

    external equal : float -> float -> bool = "%equal"
  end
end

module Int32 = struct
  include Int32

  module Infix = struct
    external ( < ) : int32 -> int32 -> bool = "%lessthan"

    external ( <= ) : int32 -> int32 -> bool = "%lessequal"

    external ( <> ) : int32 -> int32 -> bool = "%notequal"

    external ( = ) : int32 -> int32 -> bool = "%equal"

    external ( > ) : int32 -> int32 -> bool = "%greaterthan"

    external ( >= ) : int32 -> int32 -> bool = "%greaterequal"

    external compare : int32 -> int32 -> int = "%compare"

    external equal : int32 -> int32 -> bool = "%equal"
  end
end

module Int64 = struct
  include Int64

  module Infix = struct
    external ( < ) : int64 -> int64 -> bool = "%lessthan"

    external ( <= ) : int64 -> int64 -> bool = "%lessequal"

    external ( <> ) : int64 -> int64 -> bool = "%notequal"

    external ( = ) : int64 -> int64 -> bool = "%equal"

    external ( > ) : int64 -> int64 -> bool = "%greaterthan"

    external ( >= ) : int64 -> int64 -> bool = "%greaterequal"

    external compare : int64 -> int64 -> int = "%compare"

    external equal : int64 -> int64 -> bool = "%equal"
  end
end

module Hashtbl = struct
  include Hashtbl

  let find = hidden

  module type S = sig
    include Hashtbl.S

    val find : this_function_has_been_hidden_by_prelude_because_it_is_unwanted
  end

  module Make (H : HashedType) : S with type key = H.t = struct
    include Hashtbl.Make (H)

    let find = hidden
  end

  module type SeededS = sig
    include Hashtbl.SeededS

    val find : this_function_has_been_hidden_by_prelude_because_it_is_unwanted
  end

  module MakeSeeded (H : SeededHashedType) : SeededS with type key = H.t =
  struct
    include Hashtbl.MakeSeeded (H)

    let find = hidden
  end
end

module List = struct
  include List

  (* use a match to deconstruct the list *)
  let hd = hidden

  (* use a match to deconstruct the list *)
  let tl = hidden

  let nth = hidden

  let find = hidden

  let assoc = hidden

  let assq = hidden
end

module Map = struct
  module type OrderedType = Map.OrderedType

  module type S = sig
    include Map.S

    val min_binding :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val max_binding :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val choose : this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find : this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find_first :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find_last :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted
  end

  module Make (Ord : OrderedType) : S with type key = Ord.t = struct
    include Map.Make (Ord)

    let min_binding = hidden

    let max_binding = hidden

    let choose = hidden

    let find = hidden

    let find_first = hidden

    let find_last = hidden
  end
end

module Option = struct
  include Option

  let get = hidden
end

module Result = struct
  include Result

  let get_ok = hidden

  let get_error = hidden
end

module Queue = struct
  include Queue

  let take = hidden

  let pop = hidden

  let peek = hidden

  let top = hidden
end

module Stack = struct
  include Stack

  let pop = hidden

  let drop = hidden

  let top = hidden
end

module Set = struct
  module type OrderedType = Set.OrderedType

  module type S = sig
    include Set.S

    val min_elt :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val max_elt :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val choose : this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find : this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find_first :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted

    val find_last :
      this_function_has_been_hidden_by_prelude_because_it_is_unwanted
  end

  module Make (Ord : OrderedType) : S with type elt = Ord.t = struct
    include Set.Make (Ord)

    let min_elt = hidden

    let max_elt = hidden

    let choose = hidden

    let find = hidden

    let find_first = hidden

    let find_last = hidden
  end
end

(* Use Re instead. *)
module Str = Empty

module String = struct
  include String

  type nonrec t = t

  let index_from = hidden

  let rindex_from = hidden

  let index = hidden

  let rindex = hidden
end

(* Use the fmt library instead. *)
module Printf = Empty

(* USe the fmt library instead. *)
module Format = struct
  type nonrec formatter = Format.formatter
end

(* Use Cmdliner instead. *)
module Arg = Empty

(* Use unlabeled version instead. *)
module ArrayLabels = Empty
module BytesLabels = Empty
module ListLabels = Empty
module MoreLabels = Empty
module StdLabels = Empty
module StringLabels = Empty

(* Use Fpath instead. *)
module Filename = Empty

(* Be safe instead. *)
(* TODO: enable it again, it is disabled otherwise the generated menhir file does not compile.
   module Obj = Empty
*)

(* Use Menhir instead. *)
module Parsing = Empty

(* Hidden to avoid exposing an escape hatch to get access to the previously hiddden modules. *)
module Stdlib = Empty

(* Use Bos instead. *)
module Sys = struct
  (* Signals *)
  type signal_behavior = Sys.signal_behavior =
    | Signal_default
    | Signal_ignore
    | Signal_handle of (int -> unit)

  let set_signal = Sys.set_signal

  let sigabrt = Sys.sigabrt

  let sigalrm = Sys.sigalrm

  let sigfpe = Sys.sigfpe

  let sighup = Sys.sighup

  let sigill = Sys.sigill

  let sigint = Sys.sigint

  let sigkill = Sys.sigkill

  let sigpipe = Sys.sigpipe

  let sigquit = Sys.sigquit

  let sigsegv = Sys.sigsegv

  let sigterm = Sys.sigterm

  let sigusr1 = Sys.sigusr1

  let sigusr2 = Sys.sigusr2

  let sigchld = Sys.sigchld

  let sigcont = Sys.sigcont

  let sigstop = Sys.sigstop

  let sigtstp = Sys.sigtstp

  let sigttin = Sys.sigttin

  let sigttou = Sys.sigttou

  let sigvtalrm = Sys.sigvtalrm

  let sigprof = Sys.sigprof

  let sigbus = Sys.sigbus

  let sigpoll = Sys.sigpoll

  let sigsys = Sys.sigsys

  let sigtrap = Sys.sigtrap

  let sigurg = Sys.sigurg

  let sigxcpu = Sys.sigxcpu

  let sigxfsz = Sys.sigxfsz

  (* Other stuff *)
  let opaque_identity = Sys.opaque_identity
end

(* Hide dangerous polymorphic operations. *)

let ( <> ) (a : int) (b : int) = a <> b

let ( = ) (a : int) (b : int) = Int.equal a b

let ( < ) (a : int) (b : int) = a < b

let ( > ) (a : int) (b : int) = a > b

let ( <= ) (a : int) (b : int) = a <= b

let ( >= ) (a : int) (b : int) = a >= b

let compare (a : int) (b : int) = Int.compare a b

let min (a : int) (b : int) = Int.min a b

let max (a : int) (b : int) = Int.max a b

(* Rename some functions. *)
let phys_equal = ( == )

(* Make some functions safe. *)
(* TODO: there's no `_opt` version in the Stdlib for now, there's a PR for it.
   We should enforce its use once it has been added, and remove the unsafe one.

let char_of_int = hidden
*)

let bool_of_string = hidden

let int_of_string = hidden

let float_of_string = hidden

(* Use a proper Result type. *)
let invalid_arg = hidden

let failwith = hidden

(* Use phys_equal instead. *)
let ( == ) = hidden

(* Use not_phys_equal instead. *)
let ( != ) = hidden

(* Use Fmt instead. *)
let ( ^ ) = hidden

(* Use a proper `let (_ : t) = e1` construct, don't forget to annotate the type to avoid getting partial application bugs. *)
let ignore = hidden

(* Use Fmt instead. *)
let print_char = hidden

let print_string = hidden

let print_bytes = hidden

let print_int = hidden

let print_float = hidden

let print_endline = hidden

let print_newline = hidden

let prerr_char = hidden

let prerr_string = hidden

let prerr_bytes = hidden

let prerr_int = hidden

let prerr_float = hidden

let prerr_endline = hidden

let prerr_newline = hidden

(* Use Bos instead. *)
let read_line = hidden

let read_int = hidden

let read_int_opt = hidden

let read_float = hidden

let read_float_opt = hidden

let open_out = hidden

let open_out_bin = hidden

let open_out_gen = hidden

let flush = hidden

let flush_all = hidden

let output_char = hidden

let output_string = hidden

let output_bytes = hidden

let output = hidden

let output_substring = hidden

let output_byte = hidden

let output_binary_int = hidden

let output_value = hidden

let seek_out = hidden

let pos_out = hidden

let out_channel_length = hidden

let close_out = hidden

let close_out_noerr = hidden

let set_binary_mode_out = hidden

let open_in = hidden

let open_in_bin = hidden

let open_in_gen = hidden

let input_char = hidden

let input_line = hidden

let input = hidden

let really_input = hidden

let really_input_string = hidden

let input_byte = hidden

let input_binary_int = hidden

let input_value = hidden

let seek_in = hidden
