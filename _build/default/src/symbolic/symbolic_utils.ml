type expr = Smtml.Expr.t

type value = Symbolic_value.value

type value_set = Smtml.Expr.Set.t

let set_summ a b = Smtml.Expr.Set.union a b

let set_diff a b = Smtml.Expr.Set.diff a b

let set_empty = Smtml.Expr.Set.empty

let set_single a = Smtml.Expr.Set.singleton a

let equal = Symbolic_value.equal

let undef = Symbolic_value.mk_symbol "undefined"

let none = Symbolic_value.mk_symbol "none"

let str s = Smtml.Expr.value (Str s)

let true_ = Smtml.Expr.(Bool.v true)

let false_ = Smtml.Expr.(Bool.v false)

let ite c v1 v2 = Smtml.Expr.(Bool.ite c v1 v2)

let not_ = Smtml.Expr.Bool.not

let eq v1 v2 = Smtml.Expr.(relop Ty_bool Eq v1 v2)

let ne v1 v2 = Smtml.Expr.(unop Ty_bool Not (eq v1 v2))

let and_ v1 v2 = Smtml.Expr.Bool.and_ v1 v2

let or_ v1 v2 = Smtml.Expr.Bool.or_ v1 v2

let is_val v = match Smtml.Expr.view v with Val _ -> true | _ -> false

let set_to_value set = Smtml.Expr.Set.fold (fun e acc -> and_ acc e) set true_

let list_to_value lst = Smtml.Expr.naryop Ty_bool Smtml.Ty.Naryop.Logand lst

let is_sat solver (exprs : expr list) : bool =
  match Smtml.Expr.view (Smtml.Expr.naryop Ty_bool Logand exprs) with
  | Val True -> true
  | Val False -> false
  | _ -> (
    match Solver.check solver exprs with
    | `Sat -> true
    | `Unsat -> false
    | `Unknown ->
      Fmt.epr "Unknown exprs: %a@." Smtml.Expr.pp_list exprs;
      assert false )

let branch_types (lst : (value * value) list) =
  match lst with
  | [] -> []
  | [ (v, cond) ] -> [ ([ (v, cond) ], cond) ]
  | _ ->
    let tbl = Hashtbl.create 16 in
    List.iter
      (fun (v, pc) ->
        let ty = Smtml.Expr.ty v in
        match Hashtbl.find_opt tbl ty with
        | None -> Hashtbl.replace tbl ty ([ (v, pc) ], pc)
        | Some (lst, expr) ->
          Hashtbl.replace tbl ty ((v, pc) :: lst, or_ expr pc) )
      lst;
    (* Reverse each list to preserve original order *)
    Hashtbl.to_seq_values tbl
    |> Seq.map (fun (vs, pc) -> (List.rev vs, pc))
    |> List.of_seq

let must_be solver cond pc = not (is_sat solver [ not_ cond; pc ])

let is_true_set set =
  Smtml.Expr.Set.cardinal set = 1 && Smtml.Expr.Set.mem true_ set

let is_true_list lst =
  match lst with [ x ] when equal x true_ -> true | _ -> false

let mk_ite_v solver (lst : (value * value) list) (pc : value) : value =
  let check_none v = if equal v none then undef else v in
  let rec mk_ite_v' lst global_pc eq_expr =
    match lst with
    | [] -> undef
    | [ (v, cond) ] ->
      let eq_expr = or_ eq_expr cond in
      let v' = check_none v in
      if must_be solver eq_expr global_pc then v' else ite cond v' undef
    | (v, cond) :: rest ->
      let v' = check_none v in
      let eq_expr = or_ eq_expr cond in
      ite cond v' (mk_ite_v' rest global_pc eq_expr)
  in
  mk_ite_v' lst pc false_

let rec mk_ite_bool (lst : (value * value) list) : value =
  match lst with
  | [] -> false_
  | [ (_, pc) ] -> ite pc true_ false_
  | (_, pc) :: rest -> ite pc true_ (mk_ite_bool rest)

let implies solver (e1 : expr) (e2 : expr) : bool =
  not (is_sat solver [ and_ e1 (not_ e2) ])

let idx_symbol expr =
  match Smtml.Expr.view expr with
  | Symbol _ ->
    let index = Smtml.Symbol.make Ty_str "index" in
    Ok (Smtml.Expr.app index [ expr ])
  | _ -> Error "invalid argument"

let get_idx expr =
  match Symbolic_value.func expr with
  | Ok (_, args) -> ( match args with [ a ] -> Ok a | _ -> assert false )
  | _ -> Error "invalid argument"

let is_idx_symbol expr =
  match Symbolic_value.func expr with
  | Ok ("index", [ arg ]) when Symbolic_value.is_symbolic arg -> (
    match Smtml.Expr.ty arg with Ty_real -> true | _ -> true )
  | _ -> false
