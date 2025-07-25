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

module Type = struct
  type t =
    | In of in_channel
    | Out of out_channel

  let get_in = function
    | In ic -> Ok ic
    | Out _ -> Error (`Failure "cannot use 'out_channel' for input operations")

  let get_out = function
    | Out oc -> Ok oc
    | In _ -> Error (`Failure "cannot use 'in_channel' for output operations")
end

module Ptr = struct
  type t = Smtml.Value.t

  let make id = Smtml.Value.Int id

  let to_int = function
    | Smtml.Value.Int id -> Ok id
    | _ -> Error (`Failure "invalid channel pointer")
end

type t =
  { mutable count : int
  ; data : (int, Type.t) Hashtbl.t
  }

let make () = { count = 0; data = Hashtbl.create 16 }

let alloc tbl channel =
  let id = tbl.count in
  tbl.count <- succ tbl.count;
  Hashtbl.replace tbl.data id channel;
  Ptr.make id

let open_in tbl fpath = alloc tbl @@ In (open_in fpath)

let open_out tbl fpath = alloc tbl @@ Out (open_out fpath)

let find tbl ptr =
  let open Smtml_prelude.Result in
  let* id = Ptr.to_int ptr in
  match Hashtbl.find tbl.data id with
  | exception Not_found -> Error (`Failure "trying to use a closed channel")
  | ch -> Ok ch

let close tbl ptr =
  let open Smtml_prelude.Result in
  let* id = Ptr.to_int ptr in
  let* () =
    match Hashtbl.find tbl.data id with
    | exception Not_found -> Error (`Failure "trying to use a closed channel")
    | In ch -> Ok (close_in ch)
    | Out ch -> Ok (close_out ch)
  in
  Ok (Hashtbl.remove tbl.data id)
