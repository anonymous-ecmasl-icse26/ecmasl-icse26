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

type 'sl t = (string, 'sl) Hashtbl.t

let create () : 'sl t = Hashtbl.create !Base.default_hashtbl_sz

let get (obj : 'sl t) (fn : string) : 'sl option =
  Hashtbl.find_opt obj fn

let set (obj : 'sl t) (fn : string) (lvl : 'sl) : unit =
  Hashtbl.replace obj fn lvl

let delete (obj : 'sl t) (fn : string) : unit = Hashtbl.remove obj fn

let str (sl_printer : 'sl -> string) (obj : 'sl t) : string =
  let fld_str prop lvl =
    Printf.sprintf "%s: (%s)" prop (sl_printer lvl)
  in
  let obj_str_f prop lvl acc =
    fld_str prop lvl :: acc
  in
  Hashtbl.fold obj_str_f obj [] |> String.concat ", "
