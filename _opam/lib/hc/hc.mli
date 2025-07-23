(** Hash-consing library.

    The implementation is based on the paper
    {{:https://dl.acm.org/doi/pdf/10.1145/1159876.1159880} Type-Safe Modular
     Hash-Consing} by Jean-Christophe-Filliâtre and Sylvain Conchon.

    The implementation should be multi-core safe. *)

(** The type of hash-consed values. The [node] field is the actual value and
    [tag] is a unique integer identifier. *)
type +'a hash_consed = private
  { node : 'a
  ; tag : int
  }

(** The output signature of the various functors [Make], [MakeStrong], [Fake]
    and [Mk]. *)
module type S = sig
  (** The type of value that are being hash-consed. *)
  type key

  (** Removes all elements from the table. *)
  val clear : unit -> unit

  (** [hashcons v] hash-cons the value [v], i.e. returns any existing value
      equal to [v] that has already been hash-consed, if any; otherwise,
      allocates a new hash-consed value with [v] as a node and returns it. As a
      consequence the returned value is physically equal to any equal value
      already hash-consed. *)
  val hashcons : key -> key hash_consed

  (** Return statistics about the hash-consing table. *)
  val stats : unit -> Hashtbl.statistics

  (** The number of hash-consed values. *)
  val length : unit -> int
end

(** Hash-consing module using [Ephemeron.K1.Make] as a back-end cache. Not
    thread-safe. *)
module Make (H : Hashtbl.HashedType) : S with type key = H.t

(** Hash-consing module using [Ephemeron.K1.Make] as a back-end cache.
    Thread-safe. *)
module Make_thread_safe (H : Hashtbl.HashedType) : S with type key = H.t

(** Hash-consing module using [Hashtbl.Make] as a back-end cache. Not
    thread-safe. *)
module Make_strong (H : Hashtbl.HashedType) : S with type key = H.t

(** Hash-consing module using [Hashtbl.Make] as a back-end cache. Thread-safe.
*)
module Make_strong_thread_safe (H : Hashtbl.HashedType) : S with type key = H.t

(** Hash-consing module that does not perform hash-consing. This is useful to
    easily benchmark the impact of hash-consing without having to change your
    code too much: simply replace [Make] or [Makestrong] by [Fake]. *)
module Fake (H : Hashtbl.HashedType) : S with type key = H.t

(** The size that will be used to create a cache. *)
val get_initial_cache_size : unit -> int

(** Change the size that will be used to create a cache. *)
val set_initial_cache_size : int -> unit

(** Reset the size that will be used to create a cache to its default value. *)
val reset_initial_cache_size : unit -> unit

(** The type of custom cache modules. *)
module type Cache = sig
  (** The type of keys. *)
  type key

  (** The type of caches with ['a] values. *)
  type !'a t

  (** [create n] creates a new, empty cache, with initial size [n]. For best
      results, [n] should be on the order of the expected number of elements
      that will be in the cache. The cache must grow as needed, so [n] is just
      an initial guess. *)
  val create : int -> 'a t

  (** Empty a cache. *)
  val clear : 'a t -> unit

  (** [add cache key v] adds a binding of [key] to [v] in cache [cache]. *)
  val add : 'a t -> key -> 'a -> unit

  (** [find cache v] returns the current binding of [v] in [cache], or must
      raise [Not_found] if [v] is not in [cache]. *)
  val find : 'a t -> key -> 'a

  (** [length cache] returns the number of bindings in [cache]. *)
  val length : 'a t -> int

  (** [stats cache] return statistics about the cache [cache]. *)
  val stats : 'a t -> Hashtbl.statistics
end

(** Hash-consing module using a custom user-defined cache. Not thread-safe. *)
module Mk (Cache : Cache) : S with type key = Cache.key

(** Hash-consing module using a custom user-defined cache. Thread-safe. *)
module Mk_thread_safe (Cache : Cache) : S with type key = Cache.key
