(* Copyright (C) 2022-2025 formalsec programmers
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *)

(* This code was based on: https://github.com/OCamlPro/owi/blob/main/src/intf/choice_intf.ml *)

module type P = sig
  module V : Value_intf.T

  type solver_t

  type memory_t

  type optimizer_t

  type thread_t

  type 'a t

  type value

  val create : ?timeout:int -> Smtml.Solver_type.t -> thread_t

  val solver : thread_t -> solver_t

  val pc : thread_t -> Smtml.Expr.Set.t

  val mem : thread_t -> memory_t

  val optimizer : thread_t -> optimizer_t

  val add_pc : thread_t -> value -> thread_t

  val clone : thread_t -> thread_t

  val is_sat : [> `Sat ] -> bool

  val return : 'a -> 'a t

  val stop : 'a t

  val run : 'a t -> thread_t -> ('a * thread_t) EslBase.Cont.t

  val bind : 'a t -> ('a -> 'b t) -> 'b t

  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t

  val map : 'a t -> ('a -> 'b) -> 'b t

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t

  val with_thread : (thread_t -> 'a) -> 'a t

  val get_memory : unit -> memory_t t

  val with_mutable_thread :
    ?check_sat:bool -> (thread_t -> 'a * thread_t) -> 'a t

  val check : ?add_to_pc:bool -> value -> bool t

  val branch : value -> bool t

  val select_val : value -> Smtml.Value.t t

  val from_list : 'a list -> 'a t
end
