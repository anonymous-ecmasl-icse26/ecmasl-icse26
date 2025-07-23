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

module Make (Memory : Memory_intf.S) = struct
  module Value = Symbolic_value
  module V = Value

  type solver_t = Solver.t

  type memory_t = Memory.t

  type optimizer_t = Optimizer.t

  type thread_t =
    { pc : Smtml.Expr.Set.t
    ; mem : memory_t
    ; solver : solver_t
    ; optimizer : optimizer_t
    }

  type 'a t = thread_t -> ('a * thread_t) Cont.t

  type value = Symbolic_value.value

  let create ?(timeout = 60) solver_type =
    { pc = Smtml.Expr.Set.empty
    ; mem = Memory.create ()
    ; solver = Solver.create ~timeout solver_type
    ; optimizer = Optimizer.create solver_type
    }

  let pc t = t.pc

  let mem t = t.mem

  let solver t = t.solver

  let optimizer t = t.optimizer

  let add_pc t (v : value) =
    match Smtml.Expr.view v with
    | Val True -> t
    | _ ->
      let pc =
        (* Prevent having a pc like: { true, cond1, ... } *)
        if Symbolic_utils.is_true_set t.pc then Smtml.Expr.Set.singleton v
        else Smtml.Expr.Set.add v t.pc
      in
      { t with pc }

  let clone t = { t with mem = Memory.clone t.mem }

  let is_sat = function `Sat -> true | _ -> false

  let return (v : 'a) : 'a t = fun t -> Cont.return (v, t)

  let stop : 'a t = fun _ -> Cont.empty

  let run (v : 'a t) (thread : thread_t) = v thread

  let bind (v : 'a t) (f : 'a -> 'b t) : 'b t =
   fun t ->
    let result = run v t in
    Cont.bind (fun (r, t') -> run (f r) t') result

  let ( let* ) v f = bind v f

  let map (v : 'a t) (f : 'a -> 'b) : 'b t = bind v (fun a -> return (f a))

  let ( let+ ) v f = map v f

  let with_thread (f : thread_t -> 'a) : 'a t =
   fun thread ->
    let result = f thread in
    Cont.return (result, thread)

  let get_memory () = with_thread mem

  let with_mutable_thread ?(check_sat = false) (f : thread_t -> 'a * thread_t) :
    'a t =
   fun thread ->
    let (result, thread') = f thread in
    if check_sat then (
      let solver_ = solver thread' in
      let pc_ = pc thread' in
      match Solver.check_set solver_ pc_ |> is_sat with
      | true -> Cont.return (result, thread')
      | false ->
        Fmt.epr "Stoping thread: unsat pc: %a@." Solver.pp_set pc_;
        Cont.empty )
    else Cont.return (result, thread')

  let check ?(add_to_pc = false) (cond : value) : bool t =
   fun t ->
    let solver_ = solver t in
    let pc_ = pc t in
    match Smtml.Expr.view cond with
    | Val True -> Cont.return (true, t)
    | Val False -> Cont.return (false, t)
    | _ -> (
      let pc = Smtml.Expr.Set.add cond pc_ in
      match Solver.check_set solver_ pc with
      | `Sat ->
        let t = if add_to_pc then add_pc t cond else t in
        Cont.return (true, t)
      | `Unsat -> Cont.return (false, t)
      | `Unknown ->
        Fmt.epr "Unknown pc: %a@." Solver.pp_set pc;
        Cont.empty )

  let branch (v : value) : bool t =
   fun t ->
    let solver_ = solver t in
    let pc_ = pc t in
    match Smtml.Expr.view v with
    | Val True -> Cont.return (true, t)
    | Val False -> Cont.return (false, t)
    | _ -> (
      let with_v = Smtml.Expr.Set.add v pc_ in
      let with_no = Smtml.Expr.Set.add (Value.Bool.not_ v) pc_ in
      let sat_true =
        if Smtml.Expr.Set.equal with_v pc_ then true
        else is_sat @@ Solver.check_set solver_ with_v
      in
      let sat_false =
        if Smtml.Expr.Set.equal with_no pc_ then true
        else is_sat @@ Solver.check_set solver_ with_no
      in
      match (sat_true, sat_false) with
      | (false, false) -> Cont.empty
      | (true, false) | (false, true) -> Cont.return (sat_true, t)
      | (true, true) ->
        let t0 = clone t in
        let t1 = clone t in
        Cont.cons (true, { t0 with pc = with_v })
        @@ Cont.return (false, { t1 with pc = with_no }) )

  let select_val (v : value) thread =
    match Smtml.Expr.view v with
    | Val v -> Cont.return (v, thread)
    | _ -> Fmt.failwith "Unable to select value from %a" Value.pp v

  (* FIXME: Clone state? *)
  let from_list vs : 'a t =
   fun (thread : thread_t) ->
    Cont.of_list
    @@ List.map
         (fun v ->
           let thread = clone thread in
           (v, thread) )
         vs
  (*
  module List = struct
    type thread = Thread.t

    type 'a t = thread -> ('a * thread) list

    let return (v : 'a) : 'a t = fun t -> [ (v, t) ]

    let stop : 'a t = fun _ -> []

    let run (v : 'a t) (thread : thread) = v thread

    let bind (v : 'a t) (f : 'a -> 'b t) : 'b t =
     fun t ->
      let lst = run v t in
      match lst with
      | [] -> []
      | [ (r, t') ] -> run (f r) t'
      | _ -> List.concat_map (fun (r, t') -> run (f r) t') lst

    let ( let* ) v f = bind v f

    let map (v : 'a t) (f : 'a -> 'b) : 'b t = bind v (fun a -> return (f a))

    let ( let+ ) v f = map v f

    let with_thread (f : thread -> 'a) : 'a t =
     fun thread ->
      let result = f thread in
      [ (result, thread) ]

    let with_mutable_thread (f : thread -> 'a * thread) : 'a t =
     fun thread ->
      let (result, thread) = f thread in
      [ (result, thread) ]

    let check (cond : Value.value) : bool t =
     fun t ->
      let solver = Thread.solver t in
      let pc = Thread.pc t in
      match Smtml.Expr.view cond with
      | Val True -> [ (true, t) ]
      | Val False -> [ (false, t) ]
      | _ -> (
        let pc = Smtml.Expr.Set.add cond pc in
        match Solver.check_set solver pc with
        | `Sat -> [ (true, t) ]
        | `Unsat -> [ (false, t) ]
        | `Unknown ->
          Fmt.epr "Unknown pc: %a@." (Smtml.Expr.Set.pretty Smtml.Expr.pp) pc;
          [] )

    let branch (v : Value.value) : bool t =
     fun t ->
      let solver = Thread.solver t in
      let pc = Thread.pc t in
      match Smtml.Expr.view v with
      | Val True -> [ (true, t) ]
      | Val False -> [ (false, t) ]
      | _ -> (
        let with_v = Smtml.Expr.Set.add v pc in
        let with_no = Smtml.Expr.Set.add (Value.Bool.not_ v) pc in
        let sat_true =
          if Smtml.Expr.Set.equal with_v pc then true
          else is_sat @@ Solver.check_set solver with_v
        in
        let sat_false =
          if Smtml.Expr.Set.equal with_no pc then true
          else is_sat @@ Solver.check_set solver with_no
        in
        match (sat_true, sat_false) with
        | (false, false) -> []
        | (true, false) | (false, true) -> [ (sat_true, t) ]
        | (true, true) ->
          let t0 = Thread.clone t in
          let t1 = Thread.clone t in
          [ (true, { t0 with pc = with_v }); (false, { t1 with pc = with_no }) ]
        )

    let select_val (v : Value.value) thread =
      match Smtml.Expr.view v with
      | Val v -> [ (v, thread) ]
      | _ -> Fmt.failwith "Unable to select value from %a" Value.pp v

    (* FIXME: Clone state? *)
    let from_list vs : 'a t =
     fun (thread : thread) -> List.map (fun v -> (v, thread)) vs
  end *)
end
