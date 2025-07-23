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

type t =
  | Nop
  | Printer
  | TaintTracker

let pp fmt mon =
  match mon with
  | Nop -> Fmt.pf fmt "nop"
  | Printer -> Fmt.pf fmt "pp"
  | TaintTracker -> Fmt.pf fmt "tt"

let of_string str =
  match String.lowercase_ascii str with
  | "nop" -> Ok Nop
  | "pp" | "printer" -> Ok Printer
  | "tt" | "taint-tracker" -> Ok TaintTracker
  | _ -> Error "Unknown monitor"

let conv =
  let parser str =
    match of_string str with Ok v -> `Ok v | Error err -> `Error err
  in
  (parser, pp)
