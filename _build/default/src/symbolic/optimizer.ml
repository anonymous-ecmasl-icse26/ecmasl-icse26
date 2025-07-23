type t = O : (module Smtml.Optimizer_intf.S with type t = 'a) * 'a Lazy.t -> t

let create solver_type =
  let module M = (val Smtml.Solver_dispatcher.mappings_of_solver solver_type) in
  let module Opt = Smtml.Optimizer.Make (M) in
  O ((module Opt), lazy (Opt.create ()))

let push (O (opt_mod, opt)) =
  let module Opt = (val opt_mod) in
  let opt = Lazy.force opt in
  Opt.push opt

let pop (O (opt_mod, opt)) =
  let module Opt = (val opt_mod) in
  let opt = Lazy.force opt in
  Opt.pop opt

let add (O (opt_mod, opt)) pc =
  let module Opt = (val opt_mod) in
  let opt = Lazy.force opt in
  Opt.add opt pc

let maximize (O (opt_mod, opt)) e =
  let module Opt = (val opt_mod) in
  let opt = Lazy.force opt in
  Opt.maximize opt e

let minimize (O (opt_mod, opt)) e =
  let module Opt = (val opt_mod) in
  let opt = Lazy.force opt in
  Opt.minimize opt e
