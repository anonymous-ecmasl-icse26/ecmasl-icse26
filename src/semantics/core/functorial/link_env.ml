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
open Prelude
open EslSyntax

module type S = sig
  type 'a t

  type memory

  val clone : 'a t -> 'a t

  val get_memory : 'a t -> memory

  val get_func : 'a t -> string -> (Func.t, string) Result.t

  val get_extern_func : 'a t -> string -> ('a, string) Result.t

  val add_memory : 'a t -> memory -> 'a t
end

module SMap = Map.Make (String)

module type Memory = sig
  type t

  val create : unit -> t

  val clone : t -> t
end

module type Extern_func = sig
  type extern_func
end

module Make (Extern_func : Extern_func) = struct
  type t =
    { functions : Prog.t
    ; extern_funcs : Extern_func.extern_func SMap.t
    }

  let clone (env : t) = env

  let get_func (env : t) id =
    match Prog.func env.functions id with
    | Some f -> Result.ok f
    | None -> Result.error (Fmt.str "Cannot find function '%s'." id)

  let get_extern_func (env : t) id =
    match SMap.find_opt id env.extern_funcs with
    | None -> Error (Fmt.str "unable to find external function '%s'" id)
    | Some f -> Ok f

  let add_func (env : t) fid f = Prog.add_func env.functions fid f

  module Build = struct
    let empty () = { functions = Prog.default (); extern_funcs = SMap.empty }

    let add_functions functions (env : t) = { env with functions }

    let add_extern_functions extern_funcs (env : t) =
      let extern_funcs' =
        SMap.fold
          (fun key data accum -> SMap.add key data accum)
          extern_funcs env.extern_funcs
      in
      { env with extern_funcs = extern_funcs' }
  end
end
