
type __ = Obj.t

module type Inhabited =
 sig
  type t

  val dummy : t
 end

module Assert :
 functor (M:Inhabited) ->
 sig
  val coq_assert : bool -> (__ -> M.t) -> M.t
 end
