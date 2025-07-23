(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2015     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** [Big] : a wrapper around ocaml [Big_int] with nicer names,
    and a few extraction-specific constructions *)

(** To be linked with [nums.(cma|cmxa)] *)

open Big_int_Z

type big_int = Big_int_Z.big_int

(* The type of big integers. *)
let zero = zero_big_int

(* The big integer [0]. *)
let one = unit_big_int

(* The big integer [1]. *)
let two = big_int_of_int 2
(* The big integer [2]. *)

(* {6 Arithmetic operations} *)

let opp = minus_big_int

(* Unary negation. *)
let abs = abs_big_int

(* Absolute value. *)
let add = add_big_int

(* Addition. *)
let succ = succ_big_int

(* Successor (add 1). *)
let add_int = add_int_big_int

(* Addition of a small integer to a big integer. *)
let sub = sub_big_int

(* Subtraction. *)
let pred = pred_big_int

(* Predecessor (subtract 1). *)
let mult = mult_big_int

(* Multiplication of two big integers. *)
let mult_int = mult_int_big_int

(* Multiplication of a big integer by a small integer *)
let _square = square_big_int

(* Return the square of the given big integer *)
let sqrt = sqrt_big_int

(* [sqrt_big_int a] returns the integer square root of [a],
    that is, the largest big integer [r] such that [r * r <= a].
    Raise [Invalid_argument] if [a] is negative. *)
let quomod = quomod_big_int

(* Euclidean division of two big integers.
    The first part of the result is the quotient,
    the second part is the remainder.
    Writing [(q,r) = quomod_big_int a b], we have
    [a = q * b + r] and [0 <= r < |b|].
    Raise [Division_by_zero] if the divisor is zero. *)
let div = div_big_int

(* Euclidean quotient of two big integers.
    This is the first result [q] of [quomod_big_int] (see above). *)
let modulo = mod_big_int

(* Euclidean modulus of two big integers.
    This is the second result [r] of [quomod_big_int] (see above). *)
let gcd = gcd_big_int

(* Greatest common divisor of two big integers. *)
let power = power_big_int_positive_big_int
(* Exponentiation functions.  Return the big integer
    representing the first argument [a] raised to the power [b]
    (the second argument).  Depending
    on the function, [a] and [b] can be either small integers
    or big integers.  Raise [Invalid_argument] if [b] is negative. *)

(* {6 Comparisons and tests} *)

let sign = sign_big_int

(* Return [0] if the given big integer is zero,
    [1] if it is positive, and [-1] if it is negative. *)
let compare = compare_big_int

(* [compare_big_int a b] returns [0] if [a] and [b] are equal,
    [1] if [a] is greater than [b], and [-1] if [a] is smaller
    than [b]. *)
let eq = eq_big_int

let le = le_big_int

let ge = ge_big_int

let lt = lt_big_int

let gt = gt_big_int

(* Usual boolean comparisons between two big integers. *)
let max = max_big_int

(* Return the greater of its two arguments. *)
let min = min_big_int

(* Return the smaller of its two arguments. *)
(* {6 Conversions to and from strings} *)

let to_string = string_of_big_int

(* Return the string representation of the given big integer,
    in decimal (base 10). *)
let of_string = big_int_of_string
(* Convert a string to a big integer, in decimal.
    The string consists of an optional [-] or [+] sign,
    followed by one or several decimal digits. *)

(* {6 Conversions to and from other numerical types} *)

let of_int = big_int_of_int

(* Convert a small integer to a big integer. *)
let is_int = is_int_big_int

(* Test whether the given big integer is small enough to
    be representable as a small integer (type [int])
    without loss of precision.  On a 32-bit platform,
    [is_int_big_int a] returns [true] if and only if
    [a] is between 2{^30} and 2{^30}-1.  On a 64-bit platform,
    [is_int_big_int a] returns [true] if and only if
    [a] is between -2{^62} and 2{^62}-1. *)
let to_int = int_of_big_int
(* Convert a big integer to a small integer (type [int]).
    Raises [Failure "int_of_big_int"] if the big integer
    is not representable as a small integer. *)

(* Functions used by extraction *)

let double n = Z.shift_left n 1

let succ_double n = Z.succ (Z.shift_left n 1)

let pred_double n = Z.pred (Z.shift_left n 1)

let nat_case fO fS n = if sign n <= 0 then fO () else fS (pred n)

let positive_case f2p1 f2p f1 p =
  if le p one then f1 ()
  else
    let q, r = quomod p two in
    if eq r zero then f2p q else f2p1 q

let n_case fO fp n = if sign n <= 0 then fO () else fp n

let z_case fO fp fn z =
  let s = sign z in
  if s = 0 then fO () else if s > 0 then fp z else fn (opp z)

let sgn z = Z.of_int (Z.sign z)

let compare_case e l g x y =
  let s = compare x y in
  if s = 0 then e else if s < 0 then l else g

let nat_rec fO fS =
  let rec loop acc n = if sign n <= 0 then acc else loop (fS acc) (pred n) in
  loop fO

let positive_rec f2p1 f2p f1 =
  let rec loop n =
    if le n one then f1
    else
      let q, r = quomod n two in
      if eq r zero then f2p (loop q) else f2p1 (loop q)
  in
  loop

let z_rec fO fp fn = z_case (fun _ -> fO) fp fn

let rec nat_rect acc f n =
  if sign n <= 0 then acc else nat_rect (f () acc) f (pred n)

let rec iter_nat f n acc =
  if sign n <= 0 then acc else iter_nat f (pred n) (f acc)

external identity : 'a -> 'a = "%identity"

let shiftl_pos a p = Z.shift_left a (Z.to_int p)

let modulo_pos a b =
  assert (sign a >= 0);
  assert (sign b >= 0);
  modulo a b

let div_pos a b =
  assert (sign a >= 0);
  assert (sign b > 0);
  div a b

let square a = Z.mul a a

let pow_pos a p = Z.pow a (Z.to_int p)

let div2_trunc n = Z.shift_right_trunc n 1

let div_floor = Z.fdiv

let div2_floor n = Z.shift_right n 1

let mod_floor a b =
  let r = Z.rem a b in
  if Stdlib.( lxor ) (Z.sign a) (Z.sign b) >= 0 || Z.equal r Z.zero then r
  else Z.add b r

let div_mod_floor a b =
  let ((p, r) as pr) = Z.div_rem a b in
  if Stdlib.( lxor ) (Z.sign a) (Z.sign b) >= 0 || Z.equal r Z.zero then pr
  else (Z.pred p, Z.add b r)

let pos_div_eucl a b =
  assert (sign a >= 0);
  assert (sign b > 0);
  Z.div_rem a b

let shiftl a n =
  let n = Z.to_int n in
  if n < 0 then Z.shift_right a (-n) else Z.shift_left a n

let shiftr a n =
  let n = Z.to_int n in
  if n < 0 then Z.shift_left a (-n) else Z.shift_right a n

let ldiff a b = Z.logand a (Z.lognot b)

module Z = Z (* zarith *)

(* Q *)
(* must be already normalize *)
let q_mk (num, den) = { Q.den; Q.num }

let q_case f q = f q.Q.den q.Q.num

let q_den q = q.Q.den

let q_num q = q.Q.num

type mode = NE | ZR | DN | UP | NA

type classify =
  | Zero of bool
  | Infinity of bool
  | NaN
  | Finite of bool * Z.t * Z.t

let combine_hash acc n = (n * 65599) + acc
