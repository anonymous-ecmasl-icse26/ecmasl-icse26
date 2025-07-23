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

module M : Level_intf.S = struct
  type t =
    | High
    | Low

  let str (l : t) = match l with High -> "high" | Low -> "low"
  let get_low (_ : int option) : t = Low
  let get_high () : t = High

  let of_str (lvl : string) : t =
    match lvl with
    | "Low"  | "low"  | "L" -> Low
    | "High" | "high" | "H" -> High
    | _ -> raise (SException.Except ("Unknown Level - " ^ lvl))

  let lub (l1 : t) (l2 : t) : t =
    match (l1, l2) with (High, _) | (_, High) -> High | (_, _) -> Low

  let glb (l1 : t) (l2 : t) : t =
    match (l1, l2) with (Low, _) | (_, Low) -> Low | (_, _) -> High

  let lubn (lst : t list) : t = List.fold_left lub Low lst

  let leq (l1 : t) (l2 : t) : bool =
    match (l1, l2) with (_, High) -> true | (Low, _) -> true | (_, _) -> false

  let eval_un_op (_ : Operator.unopt) (l : t) : t =
    l

  let eval_bin_op (_ : Operator.binopt) (l1 : t) (l2 : t) : t =
    lub l1 l2

  let eval_tri_op (_ : Operator.triopt) (l1 : t) (l2 : t) (l3 : t) : t =
    lubn [l1; l2; l3]

  let eval_n_op (_ : Operator.nopt) (ls : t list) : t =
    lubn ls

  let eval_curry_exp (fl : t) (ls : t list) : t =
    lubn ([fl] @ ls)

  let eval_func_expr (_ : t) : t list =
    raise (SException.Except ("Not Implemented"))

  let taint_track_extern_call (_ : string) (arg_levs : t list) (_ : Value.t list) : t = 
    lubn arg_levs

end
