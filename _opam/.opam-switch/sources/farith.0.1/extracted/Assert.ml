
type __ = Obj.t
let __ = let rec f _ = Obj.repr f in Obj.repr f

module type Inhabited =
 sig
  type t

  val dummy : t
 end

module Assert =
 functor (M:Inhabited) ->
 struct
  (** val coq_assert : bool -> (__ -> M.t) -> M.t **)

  let coq_assert x f =
    if x then f __ else M.dummy
 end
