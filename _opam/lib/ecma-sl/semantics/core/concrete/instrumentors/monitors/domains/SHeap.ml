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

open EslBase
open EslSyntax

type 'sl t = (Loc.t, 'sl SObject.t) Hashtbl.t

let create () : 'sl t = Hashtbl.create !Base.default_hashtbl_sz

let insert (heap : 'sl t) (loc : Loc.t) (obj : 'sl SObject.t) : unit =
  if Hashtbl.mem heap loc then
    raise (SException.Exists "Location already exists")
  else Hashtbl.replace heap loc obj

let create_object (heap : 'sl t) (loc : Loc.t) : unit =
  let obj = SObject.create () in
  insert heap loc obj

let get (heap : 'sl t) (loc : Loc.t) : 'sl SObject.t option =
  Hashtbl.find_opt heap loc

let get_field (heap : 'sl t) (loc : Loc.t) (fn : string) : 'sl option =
  let obj = get heap loc in
  match obj with
  | None -> raise (SException.Exists "Cannot find object")
  | Some obj' -> SObject.get obj' fn

let set_field (heap : 'sl t) (loc : Loc.t) (fn : string) (lvl : 'sl) : unit =
  let obj = get heap loc in
  match obj with
  | None -> raise (SException.Exists "Cannot find object")
  | Some obj' -> SObject.set obj' fn lvl

let delete_field (heap : 'sl t) (loc : Loc.t) (fn : string) : unit =
  let obj = get heap loc in
  match obj with
  | None -> raise (SException.Exists "Cannot find object")
  | Some obj' -> SObject.delete obj' fn

let str (sl_printer : 'sl -> string) (heap : 'sl t) : string =
  let binding_str (loc, obj) =
    Fmt.str "%a|-> {%s}" Loc.pp loc (SObject.str sl_printer obj)
  in
    Hashtbl.to_seq heap 
    |> List.of_seq 
    |> List.sort (fun (a, _) (b, _) -> compare a b) 
    |> List.map binding_str
    |> String.concat "\n"