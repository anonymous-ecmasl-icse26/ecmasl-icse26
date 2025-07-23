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

type label =
  | EmptyLab
  | BranchLab of Expr.t
  | MergeLab
  | PrintLab of Expr.t
  | AssignLab of (string * Expr.t)
  | AssignCallLab of (string * string * Expr.t * string list * Expr.t list)
  | AssignECallLab of (string * string * Expr.t list * Value.t list)
  | ReturnLab of (Expr.t)
  | NewObjLab of (string * Loc.t)
  | AssignObjToListLab of (string * Loc.t * Expr.t)
  | AssignObjFieldsLab of (string * Loc.t * Expr.t * Value.t)
  | AssignInObjCheckLab of (string * string * Loc.t * Expr.t * Expr.t)
  | FieldLookupLab of (string * Loc.t * string * Expr.t * Expr.t)
  | FieldAssignLab of (Loc.t * string * Expr.t * Expr.t * Expr.t)
  | FieldDeleteLab of (Loc.t * string * Expr.t * Expr.t)
  | FailLab of Expr.t
  | AssertLab of Expr.t
  | UpgVarLab of (string * string * string)
  | UpgPropLab of (string * Loc.t * string * Expr.t * Expr.t * string)
  | GetVarLevLab of (string * string)
  | GetPropLevLab of (string * Loc.t * string)
  | SetSinkLab of (string * string)

let pp_label fmt = function
  | EmptyLab -> Fmt.pf fmt "EmptyLab"
  | BranchLab _ -> Fmt.pf fmt "BranchLab "
  | MergeLab -> Fmt.pf fmt "MergeLab"
  | PrintLab _ -> Fmt.pf fmt "PrintLab "
  | AssignLab _ -> Fmt.pf fmt "AssignLab "
  | AssignCallLab _ -> Fmt.pf fmt "AssignCallLab "
  | AssignECallLab _ -> Fmt.pf fmt "AssignECallLab "
  | ReturnLab _ -> Fmt.pf fmt "ReturnLab "
  | NewObjLab _ -> Fmt.pf fmt "NewObjLab "
  | AssignObjToListLab _ -> Fmt.pf fmt "AssignObjToListLab "
  | AssignObjFieldsLab _ -> Fmt.pf fmt "AssignObjFieldsLab "
  | AssignInObjCheckLab _ -> Fmt.pf fmt "AssignInObjCheckLab "
  | FieldLookupLab _ -> Fmt.pf fmt "FieldLookupLab "
  | FieldAssignLab _ -> Fmt.pf fmt "FieldAssignLab "
  | FieldDeleteLab _ -> Fmt.pf fmt "FieldDeleteLab "
  | FailLab _ -> Fmt.pf fmt "FailLab "
  | AssertLab _ -> Fmt.pf fmt "AssertLab "
  | UpgVarLab _-> Fmt.pf fmt "UpgVar "
  | UpgPropLab _ -> Fmt.pf fmt "UpgPropLab "
  | GetVarLevLab _ -> Fmt.pf fmt "GetVarLev "
  | GetPropLevLab _ -> Fmt.pf fmt "GetPropLevLab "
  | SetSinkLab _ -> Fmt.pf fmt "SetSinkLab "

module type S = sig
  type sl
  type state

  type t = { mutable state : state }

  val initial_state : unit -> t
  val eval_small_step : t -> label -> Value.t
  val interceptor : string -> string -> Value.t list -> Expr.t list -> label option
end
