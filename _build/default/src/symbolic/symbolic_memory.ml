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
open Symbolic_utils

module Make (O : Object_intf.S with type value = Symbolic_value.value) :
  Memory_intf.S with type value = Symbolic_value.value and type object_ = O.t =
struct
  type object_ = O.t

  type t =
    { parent : t option
    ; data : object_ Loc.Tbl.t
    }

  type value = Symbolic_value.value

  let create_object () = O.create ()

  let to_list_object o = O.to_list o

  let get_fields_object o = O.get_fields o

  let create () : t = { parent = None; data = Loc.Tbl.create 512 }

  let clone (m : t) : t = { parent = Some m; data = Loc.Tbl.create 16 }

  let insert ({ data = memory; _ } : t) (o : object_) : value =
    let loc = Loc.create () in
    Loc.Tbl.replace memory loc o;
    Smtml.Expr.(value (App (`Op "loc", [ Int loc ])))

  let remove (m : t) (l : Loc.t) : unit = Loc.Tbl.remove m.data l

  let set ({ data = memory; _ } : t) (key : Loc.t) (data : object_) : unit =
    Loc.Tbl.replace memory key data

  let find memory l =
    let open Option in
    let rec aux { parent; data } l from_parent =
      match Loc.Tbl.find_opt data l with
      | Some o -> Some (o, from_parent)
      | None ->
        let* parent in
        aux parent l true
    in
    aux memory l false

  let get memory l =
    let open Smtml_prelude.Option in
    let+ (obj, from_parent) = find memory l in
    match from_parent with
    | false -> obj
    | true ->
      let obj = O.clone obj in
      set memory l obj;
      obj

  let has_field (h : t) (loc : Loc.t) (field : value) : value =
    match get h loc with
    | None -> Symbolic_value.Bool.const false
    | Some o -> O.has_field o field

  let get_field (h : t) (loc : Loc.t) (field : value) solver (pc : value) :
    (value * value list) list =
    match get h loc with None -> [] | Some o -> O.get o field solver pc

  let clone_with_objs h loc objs =
    List.fold_left
      (fun acc (o, pc) ->
        let h' = clone h in
        set h' loc o;
        (h', pc) :: acc )
      [] objs

  let set_field (h : t) (loc : Loc.t) ~(field : value) ~(data : value) solver
    (pc : value) : (t * value list) list =
    match get h loc with
    | None -> []
    | Some o ->
      let objs = O.set o ~key:field ~data solver pc in
      clone_with_objs h loc objs

  let delete_field (h : t) (loc : Loc.t) (field : value) solver (pc : value) :
    (t * value list) list =
    match get h loc with
    | None -> []
    | Some o ->
      let objs = O.delete o field solver pc in
      clone_with_objs h loc objs

  let rec pp ppf ({ data; parent } : t) =
    let pp_v ppf (key, data) = Fmt.pf ppf "%a: %a" Loc.pp key O.pp data in
    let pp_parent ppf v =
      Fmt.option (fun ppf h -> Fmt.pf ppf "%a@ <-@ " pp h) ppf v
    in
    Fmt.pf ppf "%a{ %a }" pp_parent parent
      (Loc.Tbl.pp (fun fmt -> Fmt.string fmt ", ") pp_v)
      data

  let rec unfold_ite ~(accum : value) (e : value) :
    (int option * value list) list =
    match Smtml.Expr.view e with
    | Val (App (`Op "loc", [ Int x ])) -> [ (Some x, [ accum ]) ]
    | Val (App (`Op "symbol", [ Str "undefined" ])) -> [ (None, [ accum ]) ]
    | Triop (_, Ite, c, a, e) ->
      let r1 = unfold_ite ~accum:(and_ accum c) a in
      let r2 = unfold_ite ~accum:(and_ accum (not_ c)) e in
      r1 @ r2
    | _ -> assert false

  let loc (e : value) : (int option * value list) list =
    match Smtml.Expr.view e with
    | Val (App (`Op "symbol", [ Str "undefined" ])) ->
      (* We're in an unsat path *)
      [ (None, []) ]
    | Val (App (`Op "loc", [ Int l ])) -> [ (Some l, []) ]
    | Triop (_, Ite, c, a, v) -> (
      match Smtml.Expr.view a with
      | Val (App (`Op "loc", [ Int l ])) ->
        (Some l, [ c ]) :: unfold_ite ~accum:(not_ c) v
      | _ ->
        Logs.err (fun k ->
          k "Value '%a' is not a loc expression" Smtml.Expr.pp e );
        [ (None, []) ] )
    | _ ->
      Logs.err (fun k ->
        k "Value '%a' is not a loc expression" Smtml.Expr.pp e );
      [ (None, []) ]

  let pp_val (h : t) fmt (e : value) : unit =
    match Smtml.Expr.view e with
    | Val (App (`Op "loc", [ Int l ])) -> (
      match get h l with None -> Loc.pp fmt l | Some o -> O.pp fmt o )
    | _ -> Symbolic_value.pp fmt e
end
