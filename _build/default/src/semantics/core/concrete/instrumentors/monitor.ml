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
include Monitor_intf

module Nop : Monitor_intf.S = struct
  type sl = unit
  type state = unit

  type t = { mutable state : state }

  let initial_state () : t = { state = () }

  let eval_small_step (_ : t) (_ : label) : Value.t = Nothing

  let interceptor (_ : string) (_ : string) (_ : Value.t list) (_ : Expr.t list) :
    label option =
    None
end

module Printer : Monitor_intf.S = struct
  type sl = unit
  type state = unit

  type t = { mutable state : state }

  let initial_state () : t = { state = () }

  let eval_small_step (_ : t) (label : label) : Value.t =
    Fmt.pr "Label: %a@." pp_label label; Nothing

  let interceptor (_ : string) (_ : string) (_ : Value.t list) (_ : Expr.t list) :
    label option =
    None
end

module TaintTracker (SLevel : Level_intf.S) : Monitor_intf.S = struct
  module SSet = Set.Make(String)
  type sl = SLevel.t
  type state = (sl SStore.t) * (sl SHeap.t) * (sl SCallStack.t) * (SSet.t)

  type t = { mutable state : state }

  let store_safe_get (ssto : sl SStore.t) (x : string) : sl =
    match SStore.get ssto x with
    | None -> SLevel.get_low None
    | Some l -> l

  let rec expr_lvl (ssto : sl SStore.t) (exp : Expr.t) : sl =
    match exp.it with
    | Val _ -> SLevel.get_low None

    | Var x -> store_safe_get ssto x

    | UnOpt (op, e) ->
      let l = expr_lvl ssto e in
      SLevel.eval_un_op op l

    | BinOpt (op, e1, e2) ->
      let l1 = expr_lvl ssto e1 in
      let l2 = expr_lvl ssto e2 in
      SLevel.eval_bin_op op l1 l2

    | TriOpt (op, e1, e2, e3) ->
      let l1 = expr_lvl ssto e1 in
      let l2 = expr_lvl ssto e2 in
      let l3 = expr_lvl ssto e3 in
      SLevel.eval_tri_op op l1 l2 l3

    | NOpt (op, es) ->
      let lvls = List.map (expr_lvl ssto) es in
      SLevel.eval_n_op op lvls

    | Curry (e, es) ->
      let lvl = expr_lvl ssto e in
      let lvls = List.map (expr_lvl ssto) es in
      SLevel.eval_curry_exp lvl lvls

  let initial_state () : t = { state = SStore.create [], SHeap.create (), SCallStack.create (), SSet.empty }

  let eval_small_step (state : t) (label : label) : Value.t =
    let (sstore, sheap, scs, sinks) = state.state in
    match label with
    | AssignLab(id, e) ->
      let lvl = expr_lvl sstore e in
      SStore.set sstore id lvl;
      Nothing

    | AssignCallLab(id, fn, fe, params, es) ->
      let flvls = expr_lvl sstore fe |> SLevel.eval_func_expr in
      let lvls = flvls @ List.map (expr_lvl sstore) es in
      if SSet.mem fn sinks && (SLevel.lubn lvls) = SLevel.get_high () then (
        Printf.printf "HALT!!!\n"
      );
      let scs' = SCallStack.push scs (Intermediate(sstore, id)) in
      let sstore' = SStore.create (List.combine params lvls) in
      state.state <- sstore', sheap, scs', sinks;
      Nothing

    | AssignECallLab(id, fn, es, vs) -> (
      let lvls = List.map (expr_lvl sstore) es in
      match fn with
      | "node_function" ->
        let eval_bool v =
          match v with
          | Value.True -> true
          | Value.False -> false
          | _ -> raise (SException.Except("Unexpected argument type in node_function call"))
        in
        if eval_bool (List.hd (List.rev vs)) && (SLevel.lubn lvls) = SLevel.get_high () then (
          Printf.printf "HALT!!!\n"
        );
        let lvl = SLevel.taint_track_extern_call fn lvls vs in
        SStore.set sstore id lvl;
        Nothing
      | _ ->
        let lvl = SLevel.taint_track_extern_call fn lvls vs in
        SStore.set sstore id lvl;
        Nothing
    )

    | ReturnLab(e) -> (
      let (frame, scs') = SCallStack.pop scs in
      match frame with
      | Toplevel -> Nothing
      | Intermediate(sstore', id) ->
        let lvl = expr_lvl sstore e in
        SStore.set sstore' id lvl;
        state.state <- sstore', sheap, scs', sinks;
        Nothing
    )

    | NewObjLab(id, loc) ->
      SHeap.create_object sheap loc;
      SStore.set sstore id (SLevel.get_low None);
      Nothing

    | AssignObjToListLab(id, _, _) ->
      SStore.set sstore id (SLevel.get_low None);
      Nothing

    | AssignObjFieldsLab(id, _, _, v) -> (
      match v with
      | Value.List l ->
        let len = List.length l in
        SStore.set sstore id (SLevel.get_low (Some len));
        Nothing
      | _ -> raise (SException.Except("Unexpected value in list expression"))
    )

    | FieldLookupLab(id, loc, fn, _, _) -> (
      match SHeap.get_field sheap loc fn with
      | None ->
        SStore.set sstore id (SLevel.get_low None);
        Nothing
      | Some plvl ->
        SStore.set sstore id plvl;
        Nothing
    )

    | FieldAssignLab(loc, fn, _, _, e) ->
      let lvl = expr_lvl sstore e in
      SHeap.set_field sheap loc fn lvl;
      Nothing

    | FieldDeleteLab(loc, fn, _, _) ->
      SHeap.delete_field sheap loc fn;
      Nothing

    | AssignInObjCheckLab(id, _, _, _, _) ->
      SStore.set sstore id (SLevel.get_low None);
      Nothing

    | UpgVarLab(x, id, slvl) ->
      let lvl = SLevel.of_str slvl in
      SStore.set sstore id lvl;
      SStore.set sstore x (SLevel.get_low (Some 2));
      Nothing

    | UpgPropLab(x, loc, fn, _, _, slvl) ->
      let lvl = SLevel.of_str slvl in
      SHeap.set_field sheap loc fn lvl;
      SStore.set sstore x (SLevel.get_low (Some 2));
      Nothing

    | GetVarLevLab(x, id) -> (
      match SStore.get sstore id with
      | Some lvl ->
        SStore.set sstore x (SLevel.get_low (Some 2));
        Str (SLevel.str lvl)
      | None -> raise (SException.Exists("Cannot find variable " ^ id ^ " in store"))
    )

    | GetPropLevLab(x, loc, fn) -> (
      match SHeap.get_field sheap loc fn with
      | Some lvl ->
        SStore.set sstore x (SLevel.get_low (Some 2));
        Str (SLevel.str lvl)
      | None -> raise (SException.Exists("Cannot find property " ^ fn ^ " in object"))
    )

    | SetSinkLab(x, fn) ->
      Printf.printf "Adding sink %s\n" fn;
      let sinks' = SSet.add fn sinks in
      state.state <- sstore, sheap, scs, sinks';
      SStore.set sstore x (SLevel.get_low (Some 2));
      Nothing

    | _ -> Nothing

  let interceptor (x : string) (f : string) (vs : Value.t list) (es : Expr.t list) : label option =
    match f, vs, es with
    | "upg_var", [ _; Str id; Str slvl ], _ -> Some (UpgVarLab(x, id, slvl))
    | "upg_prop", [ _; App (`Op "loc", [ Int loc ]); Str fn; Str slvl ], [ _; oe; fe; _ ] -> Some (UpgPropLab(x, loc, fn, oe, fe, slvl))
    | "get_var_level", [ _; Str id ], _ -> Some (GetVarLevLab(x, id))
    | "get_prop_level", [ _; App (`Op "loc", [ Int loc ]); Str fn ], _ -> Some (GetPropLevLab(x, loc, fn))
    | "set_sink", [ _; Str fn ], _ -> Some (SetSinkLab(x, fn))
    | _ -> None
end
