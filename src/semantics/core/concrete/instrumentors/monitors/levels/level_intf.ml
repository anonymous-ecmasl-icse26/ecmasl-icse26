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

open EslSyntax

module type S = sig
  type t

  val str : t -> string
  val get_low : int option -> t
  val get_high : unit -> t
  val of_str : string -> t
  val lub : t -> t -> t
  val glb : t -> t -> t
  val lubn : t list -> t
  val leq : t -> t -> bool
  val eval_un_op : Operator.unopt -> t -> t
  val eval_bin_op : Operator.binopt -> t -> t -> t
  val eval_tri_op : Operator.triopt -> t -> t -> t -> t
  val eval_n_op : Operator.nopt -> t list -> t
  val eval_curry_exp : t -> t list -> t
  val eval_func_expr : t -> t list
  val taint_track_extern_call : string -> t list -> Value.t list -> t
end
