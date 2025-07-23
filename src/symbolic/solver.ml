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

(* include Smtml.Solver.Cached (Smtml.Z3_mappings) *)

type t = S : (module Smtml.Solver.S with type t = 'a) * 'a -> t

let create ?(timeout = 60) solver_type =
  let module M = (val Smtml.Solver_dispatcher.mappings_of_solver solver_type) in
  let module Solver = Smtml.Solver.Cached (M) in
  let params = Smtml.Params.(default () $ (Timeout, timeout * 1000)) in
  S ((module Solver), Solver.create ~params ())

let solver_time (S (solver_module, _)) =
  let module Solver = (val solver_module) in
  !Solver.solver_time

let solver_count (S (solver_module, _)) =
  let module Solver = (val solver_module) in
  !Solver.solver_count

let check (S (solver_module, solver)) assumptions =
  let module Solver = (val solver_module) in
  if List.mem Smtml.Expr.Bool.false_ assumptions then `Unsat
  else begin
    Logs.debug (fun k ->
      k "@[<hov 1>solver_check:@ %a@]" Smtml.Expr.pp_list assumptions );
    Solver.check solver assumptions
  end

let pp_set fmt v = Smtml.Expr.Set.pretty ~pp_sep:Fmt.sp Smtml.Expr.pp fmt v

let check_set (S (solver_module, solver)) assumptions =
  let module Solver = (val solver_module) in
  if Smtml.Expr.Set.mem Smtml.Expr.Bool.false_ assumptions then `Unsat
  else begin
    Logs.debug (fun k ->
      k "@[<hov 1>solver_check_set:@ %a@]" pp_set assumptions );
    Solver.check_set solver assumptions
  end

let get_value (S (solver_module, solver)) x =
  let module Solver = (val solver_module) in
  Solver.get_value solver x

let get_sat_model (S (solver_module, solver)) pc =
  let module Solver = (val solver_module) in
  Solver.get_sat_model solver pc
