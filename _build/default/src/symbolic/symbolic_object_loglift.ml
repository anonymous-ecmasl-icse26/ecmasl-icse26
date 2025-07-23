open Symbolic_utils

type value = Symbolic_value.value

type pc_value = Symbolic_value.value

module SMap = Map.Make (String)

type t = t' list

and t' =
  | Srec of (value * value)
  | Crec of value SMap.t
  | If of (pc_value * t * t)

let equal = Symbolic_value.equal

let create () : t = []

let rec clone' (x : t') : t' =
  match x with
  | Srec (v1, v2) -> Srec (v1, v2)
  (* SMap is immutable *)
  | Crec map -> Crec map
  | If (pc, t1, t2) -> If (pc, clone t1, clone t2)

and clone (lst : t) : t = List.map clone' lst

let to_list_aux' (o : t') (tbl : (value, value) Hashtbl.t) :
  value_set * value_set * (value, value) Hashtbl.t =
  match o with
  | Srec (p, v) when equal v none -> (set_empty, set_single p, tbl)
  | Srec (p, v) ->
    Hashtbl.replace tbl p v;
    (set_single p, set_empty, tbl)
  | Crec cmap ->
    let (s1, s2) =
      SMap.fold
        (fun p v (s1, s2) ->
          let p' = str p in
          if equal v none then (s1, Smtml.Expr.Set.add p' s2)
          else (
            Hashtbl.replace tbl p' v;
            (Smtml.Expr.Set.add p' s1, s2) ) )
        cmap (set_empty, set_empty)
    in
    (s1, s2, tbl)
  | If _ -> assert false

let rec to_list_aux (o : t) (tbl : (value, value) Hashtbl.t) :
  value_set * value_set * (value, value) Hashtbl.t =
  match o with
  | [] -> (set_empty, set_empty, tbl)
  | o1 :: o2 ->
    let (fs_1, fs_1', tbl) = to_list_aux' o1 tbl in
    let (fs_2, fs_2', tbl) = to_list_aux o2 tbl in
    ( set_summ fs_1 (set_diff fs_2 fs_1')
    , set_summ fs_1' (set_diff fs_2' fs_1)
    , tbl )

let to_list o : (value * value) list =
  let (set1, _, tbl) = to_list_aux o (Hashtbl.create 0) in
  Smtml.Expr.Set.fold
    (fun p acc ->
      match Hashtbl.find_opt tbl p with
      | Some v -> (p, v) :: acc
      | None -> assert false )
    set1 []

let get_fields o : value list =
  let (set1, _, _) = to_list_aux o (Hashtbl.create 0) in
  Smtml.Expr.Set.to_list set1

let is_empty o = List.is_empty (get_fields o)

let set_aux (obj' : t') prop v pc : t' =
  if equal pc true_ then
    match (Smtml.Expr.view prop, obj') with
    | (Val (Str field), Crec map) -> Crec (SMap.add field v map)
    | (Val (Str field), _) -> Crec (SMap.singleton field v)
    | _ -> Srec (prop, v)
  else If (pc, [ Srec (prop, v) ], [])

let set obj ~key ~data _ _ =
  let pc = true_ in
  match (obj, Smtml.Expr.view key) with
  | (r1 :: r2, _) -> (
    let r = set_aux r1 key data pc in
    match r1 with
    | Crec _ -> (
      match r with
      | Crec map -> [ (Crec map :: r2, []) ]
      | _ -> [ (r :: obj, []) ] )
    | _ -> [ (r :: obj, []) ] )
  | ([], Val (Str field)) -> [ ([ Crec (SMap.singleton field data) ], []) ]
  | ([], _) -> [ ([ Srec (key, data) ], []) ]

let extend_with_cond lst b = List.map (fun (v, cond) -> (v, and_ cond b)) lst

let rec get_vals' (obj : t') (prop : value) solver (pc : pc_value) :
  (value * pc_value) list * pc_value =
  match (obj, Smtml.Expr.view prop) with
  | (Crec map, Val (Str field)) -> (
    match SMap.find_opt field map with
    | Some v -> ([ (v, true_) ], false_)
    | None -> ([], true_) )
  | (Crec map, _) ->
    SMap.fold
      (fun prop' v (acc, not_found) ->
        let prop' = str prop' in
        if is_sat solver [ eq prop' prop; pc ] then
          ((v, eq prop prop') :: acc, and_ not_found (ne prop prop'))
        else (acc, not_found) )
      map ([], true_)
  | (Srec (prop', v), _) ->
    if is_sat solver [ eq prop' prop; pc ] then
      ([ (v, eq prop prop') ], ne prop prop')
    else ([], true_)
  | (If (cond, o1, o2), _) ->
    let (lst1, pi_1) = get_vals o1 prop solver (and_ pc cond) in
    let (lst2, pi_2) = get_vals o2 prop solver (and_ pc (not_ cond)) in
    let lst1' = extend_with_cond lst1 cond in
    let lst2' = extend_with_cond lst2 (not_ cond) in
    (lst1' @ lst2', or_ (and_ cond pi_1) (and_ (not_ cond) pi_2))

and get_vals (obj : t) (prop : value) solver (pc : pc_value) :
  (value * pc_value) list * pc_value =
  match obj with
  | [] -> ([], true_)
  | r :: obj' -> (
    let (lst1, pi1) = get_vals' r prop solver pc in
    match Smtml.Expr.view pi1 with
    | Val False -> (lst1, pi1)
    | _ ->
      if is_sat solver [ and_ pc pi1 ] then
        let (lst2, pi2) = get_vals obj' prop solver (and_ pc pi1) in
        (lst1 @ lst2, and_ pi1 pi2)
      else (lst1, pi1) )

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

let delete (o : t) (prop : value) solver (pc : value) =
  set o ~key:prop ~data:none solver pc

let pp_map fmt v =
  let map_iter f m = SMap.iter (fun k d -> f (k, d)) m in
  Fmt.iter ~sep:Fmt.comma map_iter
    (fun fmt (key, data) ->
      Fmt.pf fmt {|%a: %a|} Fmt.string key Symbolic_value.pp data )
    fmt v

let rec pp_t' fmt (t' : t') =
  match t' with
  | Srec (prop, v) ->
    Fmt.pf fmt "Srec(%a -> %a)" Symbolic_value.pp prop Symbolic_value.pp v
  | Crec map -> Fmt.pf fmt "[%a]" pp_map map
  | If (cond, o1, o2) ->
    Fmt.pf fmt "If(%a, %a, %a)" Symbolic_value.pp cond pp_list o1 pp_list o2

and pp_list fmt (l : t' list) =
  let list_iter f l = List.iter (fun o' -> f o') l in
  Fmt.iter ~sep:Fmt.comma list_iter
    (fun fmt o' -> Fmt.pf fmt "%a" pp_t' o')
    fmt l

let pp fmt (o : t) : unit = Fmt.pf fmt "@[<hov 2> { %a } @]" pp_list o

let to_string o = Fmt.str "%a" pp o

let to_json = to_string
