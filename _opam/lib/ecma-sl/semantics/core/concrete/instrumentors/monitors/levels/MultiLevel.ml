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

module M (SL : Level_intf.S) : Level_intf.S = struct 

  type t' = SL.t

  type t = 
    | Base of t' 
    | Rec of t list 

  let rec basify (l : t) : t' =
    match l with
    | Base(l') -> l'
    | Rec(ll) -> SL.lubn (List.map basify ll)
    
  let rec str (l : t) : string =
    match l with
    | Base l' -> Printf.sprintf "(Base of %s)" (SL.str l')
    | Rec l' ->
      let inner = List.map str l' |> String.concat "; " in
      Printf.sprintf "(Rec of [%s])" inner

  let get_low (n : int option) : t =
    match n with
    | None -> Base(SL.get_low None)
    | Some n' -> Rec (List.init n' (fun _ -> Base(SL.get_low None)))

  let get_high () : t = Base(SL.get_high ())

  let of_str (lvl : string) : t =
    Base(SL.of_str lvl)

  let rec lub (l1 : t) (l2 : t) : t =
    match (l1, l2) with
    | Base(l1'), Base(l2') -> Base(SL.lub l1' l2')
    | Rec(ll1), Rec(ll2) when List.length ll1 = List.length ll2 ->
      let lll = List.combine ll1 ll2 in 
      let ll = List.map (fun (l1', l2') -> lub l1' l2') lll in
      Rec(ll)
    | _ -> 
      let l1' = basify l1 in
      let l2' = basify l2 in 
      Base(SL.lub l1' l2')

  let glb (_l1 : t) (_l2 : t) : t =
    raise (SException.Except ("Not Implemented"))

  let lubn (lst : t list) : t =
    List.fold_left lub (get_low None) lst

  let rec leq (l1 : t) (l2 : t) : bool =
    match (l1, l2) with
    | Base(l1'), Base(l2') -> SL.leq l1' l2'
    | Rec(ll1), Rec(ll2) when List.length ll1 = List.length ll2 ->
      let lll = List.combine ll1 ll2 in
      List.for_all (fun (l1', l2') -> leq l1' l2') lll
    | _ ->
      let l1' = basify l1 in
      let l2' = basify l2 in
      SL.leq l1' l2'

  let eval_un_op (op : Operator.unopt) (l : t) : t =
    match op with
    | ListHead -> (
      match l with
      | Rec ls -> List.hd ls
      | Base _ -> raise (SException.Except ("Unexpected Base level on list expression - hd"))
    )
    | ListTail -> (
      match l with
      | Rec ls -> Rec (List.tl ls)
      | Base _ -> raise (SException.Except ("Unexpected Base level on list expression - tl"))
    )
    | _ -> l

  let eval_bin_op (_op : Operator.binopt) (l1 : t) (l2 : t) : t =
    lub l1 l2

  let eval_tri_op (_op : Operator.triopt) (l1 : t) (l2 : t) (l3 : t) : t =
    lubn [l1; l2; l3]

  let eval_n_op (op : Operator.nopt) (ls : t list) : t =
    match op with
    | ListExpr -> Rec ls
    | _ -> lubn ls

  let eval_curry_exp (fl : t) (ls : t list) : t =
    Rec ([fl; Rec (ls)])

  let eval_func_expr (fl : t) : t list =
    match fl with
    | Base _ -> []
    | Rec [_ ; Rec ls] -> ls
    | _ -> raise (SException.Except ("Unexpected function expression level"))

  let taint_track_extern_call (fn : string) (arg_levs : t list) (vs : Value.t list) : t =
    match fn with
    | "node_child_process_exec" -> get_low (Some 3)
    | "in_list_external" -> get_low None
    | "l_len_external" -> get_low None
    | "l_nth_external" -> (
      match arg_levs with
      | [Rec l; Base _] -> (
        match vs with
        | [_; Int i] -> List.nth l i
        | _ -> raise (SException.Except ("Unexpected arg values on l_nth call")))
      | _ -> raise (SException.Except ("Unexpected arg levels on l_nth call"))
    )
    | "l_add_external" -> (
      match arg_levs with
      | [Rec l; lvl] -> Rec (List.append l [lvl])
      | _ -> raise (SException.Except ("Unexpected arg levels on l_add call"))
    )
    | "l_prepend_external" -> (
      match arg_levs with
      | [lvl; Rec l] -> Rec (lvl::l)
      | _ -> raise (SException.Except ("Unexpected arg levels on l_prepend call"))
    )
    | "l_concat_external" -> (
      match arg_levs with
      | [Rec l1; Rec l2] -> Rec (List.append l1 l2)
      | _ -> raise (SException.Except ("Unexpected arg levels on l_concat call")) 
    )
    | "l_remove_last_external" -> (
      match arg_levs with
      | [Rec l] -> Rec (List.rev (List.tl (List.rev l)))
      | _ -> raise (SException.Except ("Unexpected arg levels on l_remove_last call"))
    )
    | _ -> lubn arg_levs

end
