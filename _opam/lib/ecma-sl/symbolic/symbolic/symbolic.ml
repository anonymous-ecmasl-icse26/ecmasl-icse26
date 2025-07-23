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

open Ecma_sl

module Make (Memory : Memory_intf.S with type value = Symbolic_value.value) :
  Interpreter_functor_intf.P
    with type value = Symbolic_value.value
     and type solver_t = Solver.t
     and type optimizer_t = Optimizer.t
     and type object_ = Memory.object_ = struct
  module Choice = Choice_monad.Make (Memory)

  type solver_t = Choice.solver_t

  type optimizer_t = Choice.optimizer_t

  type value = Symbolic_value.value

  type store = Symbolic_value.Store.t

  type memory = Memory.t

  type object_ = Memory.object_

  module Value = Symbolic_value
  module Extern_func = Extern_func.Make (Symbolic_value) (Choice)
  module Env = Link_env.Make (Extern_func)

  type env = Env.t

  module Store = Symbolic_value.Store

  let handle_cond thread cond ~on_success =
    let pc_thread = Choice.pc thread in
    let solver = Choice.solver thread in
    match cond with
    | [] -> Some (on_success thread)
    | _ when Symbolic_utils.is_true_list cond ->
      (* Path condition is [ true ]: return immediately *)
      Some (on_success thread)
    | _ -> (
      let pc' =
        (* If current pc_thread is { true }, override it with the new pc *)
        if Symbolic_utils.is_true_set pc_thread then Smtml.Expr.Set.of_list cond
        else
          (* Otherwise, merge current and new pc sets *)
          Smtml.Expr.Set.union pc_thread (Smtml.Expr.Set.of_list cond)
      in
      let pc_list = Smtml.Expr.Set.to_list pc' in
      let pc_expr =
        (* Leverage smart constructor to simplify to True/False if possible *)
        Smtml.Expr.naryop Ty_bool Smtml.Ty.Naryop.Logand pc_list
      in
      match Smtml.Expr.view pc_expr with
      | Val True -> Some (on_success thread)
      | Val False -> None
      | _ -> (
        (* Check satisfiability of new pc set and update if sat *)
        match Solver.check_set solver pc' with
        | `Sat -> Some (on_success { thread with pc = pc' })
        | `Unsat | `Unknown -> None ) )

  module Memory = struct
    type t = memory

    type nonrec object_ = object_

    type nonrec value = value

    let create_obj () = Memory.create_object () [@@inline]

    let to_list_obj o = Memory.to_list_object o [@@inline]

    let fields_of_obj o = Memory.get_fields_object o [@@inline]

    let create () = Memory.create () [@@inline]

    let clone m = Memory.clone m [@@inline]

    let insert m o = Memory.insert m o [@@inline]

    let remove m loc = Memory.remove m loc [@@inline]

    let set m loc o = Memory.set m loc o [@@inline]

    let get m loc = Memory.get m loc [@@inline]

    let has_field m x v = Memory.has_field m x v [@@inline]

    let get_field h loc v =
      let return thread (v, cond) =
        handle_cond thread cond ~on_success:(fun thread -> (Some v, thread))
      in
      fun thread ->
        let pc = Choice.pc thread in
        let pc = Symbolic_utils.set_to_value pc in
        let solver = Choice.solver thread in
        let field_vals = Memory.get_field h loc v solver pc in

        match field_vals with
        | [] -> Cont.return (None, thread)
        | [ (v, pc) ] -> (
          match return thread (v, pc) with
          | None -> Cont.empty
          | Some a -> Cont.return a )
        | _ ->
          let thread = Choice.clone thread in
          Cont.of_list @@ List.filter_map (return thread) field_vals

    let set_field m loc ~field ~data =
      let return_h (thread : Choice.thread_t) (h, cond) =
        let thread' = { thread with mem = h } in
        handle_cond thread' cond ~on_success:(fun thread -> (h, thread))
      in
      fun thread ->
        let pc = Choice.pc thread in
        let pc = Symbolic_utils.set_to_value pc in
        let solver = Choice.solver thread in
        let field_vals = Memory.set_field m loc ~field ~data solver pc in

        match field_vals with
        | [] -> assert false
        | [ (h, pc) ] -> (
          match return_h thread (h, pc) with
          | None -> Cont.empty
          | Some a -> Cont.return a )
        | _ ->
          let thread = Choice.clone thread in
          Cont.of_list @@ List.filter_map (return_h thread) field_vals

    let delete_field m loc field =
      let return_h (thread : Choice.thread_t) (h, cond) =
        let thread' = { thread with mem = h } in
        handle_cond thread' cond ~on_success:(fun thread -> (h, thread))
      in
      fun thread ->
        let pc = Choice.pc thread in
        let pc = Symbolic_utils.set_to_value pc in
        let solver = Choice.solver thread in
        let field_vals = Memory.delete_field m loc field solver pc in

        match field_vals with
        | [] -> assert false
        | [ (h, pc) ] -> (
          match return_h thread (h, pc) with
          | None -> Cont.empty
          | Some a -> Cont.return a )
        | _ ->
          let thread = Choice.clone thread in
          Cont.of_list @@ List.filter_map (return_h thread) field_vals

    let to_string h = Fmt.str "%a" Memory.pp h [@@inline]

    let loc value =
      let err v t =
        (Error (Fmt.str "'%a' invalid memory location" Smtml.Expr.pp v), t)
      in
      let return_l thread (l, cond) =
        handle_cond thread cond ~on_success:(fun thread ->
          match l with Some l' -> (Ok l', thread) | None -> err value thread )
      in
      let locs = Memory.loc value in
      fun thread ->
        match locs with
        | [] -> Cont.return (err value thread)
        | [ loc ] -> (
          match return_l thread loc with
          | Some l -> Cont.return l
          | None -> Cont.return (err value thread) )
        | _ -> (
          let thread = Choice.clone thread in
          let lst = List.filter_map (return_l thread) locs in
          match lst with
          | [] -> Cont.return (err value thread)
          | _ -> Cont.of_list lst )

    let pp ppf v = Memory.pp ppf v [@@inline]

    let pp_val m fmt v = Memory.pp_val m fmt v [@@inline]
  end
end
