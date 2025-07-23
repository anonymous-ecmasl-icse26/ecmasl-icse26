open Symbolic_utils

type value = Symbolic_value.value

type pc_value = Symbolic_value.value

module VMap = Map.Make (Symbolic_value)

type t = value VMap.t

let create () : t = VMap.empty

(* VMap is immutable *)
let clone o = o

let to_list (o : t) : (value * value) list =
  VMap.fold
    (fun k v acc -> if not (equal v none) then (k, v) :: acc else acc)
    o []

let get_fields (o : t) : value list =
  VMap.fold (fun k v acc -> if not (equal v none) then k :: acc else acc) o []

let is_empty o = List.is_empty (get_fields o)

let all_different (prop : value) (props : value list) : pc_value =
  List.fold_left (fun acc p -> and_ (ne prop p) acc) true_ props

let set' (obj : t) (possible_props : value list) (prop : value) (v : value)
  solver (pc : pc_value) =
  let rets =
    List.map (fun p -> (VMap.add p v obj, [ eq prop p ])) possible_props
  in
  let diff = all_different prop possible_props in
  if is_sat solver [ pc; diff ] then (VMap.add prop v obj, [ diff ]) :: rets
  else rets

let set obj ~key ~data solver pc =
  (* Get a list of possible props matching prop *)
  let props =
    VMap.fold
      (fun p _ acc -> if is_sat solver [ pc; eq p key ] then p :: acc else acc)
      obj []
  in

  (* prop differs from all props in obj *)
  if List.length props = 0 then [ (VMap.add key data obj, [ true_ ]) ]
  else if List.length props = 1 then
    match props with
    | [ p ] ->
      (* prop must be equal to p *)
      if must_be solver (eq p key) pc then
        [ (VMap.add key data obj, [ true_ ]) ]
      (* default branching cases *)
        else set' obj [ p ] key data solver pc
    | _ -> assert false
  else set' obj props key data solver pc

let get_vals (obj : t) (prop : value) solver (pc : pc_value) :
  (value * pc_value) list * pc_value =
  VMap.fold
    (fun p v (lst, expr) ->
      if is_sat solver [ pc; eq p prop ] then
        ((v, eq p prop) :: lst, and_ expr (ne p prop))
      else (lst, expr) )
    obj ([], true_)

let get (obj : t) (prop : value) solver (pc : pc_value) :
  (value * value list) list =
  let (lst, not_found_pc_) = get_vals obj prop solver pc in
  let lst' = branch_types lst in
  let lst'' =
    List.fold_left
      (fun acc (l, pc') ->
        let ite = mk_ite_v solver l (and_ pc pc') in
        (ite, [ pc' ]) :: acc )
      [] lst'
  in
  match Smtml.Expr.view not_found_pc_ with
  | Val False -> lst''
  | Val True -> (undef, [ not_found_pc_ ]) :: lst''
  | _ ->
    if is_sat solver [ not_found_pc_ ] then (undef, [ not_found_pc_ ]) :: lst''
    else lst''

let has_field (obj : t) (prop : value) =
  let fields = get_fields obj in
  List.fold_left
    (fun acc p ->
      match (Smtml.Expr.view p, Smtml.Expr.view prop) with
      | (Val (Str p'), Val (Str prop')) ->
        if String.compare p' prop' = 0 then true_ else acc
      | (_, _) -> ite (eq p prop) true_ acc )
    false_ fields

let delete (o : t) (prop : value) = set o ~key:prop ~data:none

let pp_map fmt v =
  let tbl_iter f m = VMap.iter (fun k d -> f (k, d)) m in
  Fmt.iter ~sep:Fmt.comma tbl_iter
    (fun ppf (key, data) ->
      Fmt.pf ppf {|%a: %a|} Symbolic_value.pp key Symbolic_value.pp data )
    fmt v

let pp fmt (o : t) = Fmt.pf fmt "@[<hov 2>{ %a }@]" pp_map o

let to_string o = Fmt.str "%a" pp o

let to_json = to_string
