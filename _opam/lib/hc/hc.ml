type +'a hash_consed =
  { node : 'a
  ; tag : int
  }

let get_initial_cache_size, set_initial_cache_size, reset_initial_cache_size =
  let default = 512 in
  let initial_cache_size = ref default in
  ( (fun () -> !initial_cache_size)
  , (fun size -> initial_cache_size := size)
  , fun () -> initial_cache_size := default )

module type Cache = sig
  type key

  type !'a t

  val create : int -> 'a t

  val clear : 'a t -> unit

  val add : 'a t -> key -> 'a -> unit

  val find : 'a t -> key -> 'a

  val length : 'a t -> int

  val stats : 'a t -> Hashtbl.statistics
end

module type S = sig
  type key

  val clear : unit -> unit

  val hashcons : key -> key hash_consed

  val stats : unit -> Hashtbl.statistics

  val length : unit -> int
end

module Mk (Cache : Cache) : S with type key = Cache.key = struct
  type key = Cache.key

  let tbl = Cache.create (get_initial_cache_size ())

  let tag = ref ~-1

  let hashcons node =
    try Cache.find tbl node
    with Not_found ->
      incr tag;
      let tag = !tag in
      let v = { tag; node } in
      Cache.add tbl node v;
      v

  let clear () = Cache.clear tbl

  let stats () = Cache.stats tbl

  let length () = Cache.length tbl
end

module Mk_thread_safe (Cache : Cache) : S with type key = Cache.key = struct
  type key = Cache.key

  let tbl = Cache.create (get_initial_cache_size ())

  let tag = ref ~-1

  let mutex = Mutex.create ()

  let hashcons node =
    Mutex.lock mutex;
    let v =
      match Cache.find tbl node with
      | exception Not_found ->
        incr tag;
        let tag = !tag in
        let v = { tag; node } in
        Cache.add tbl node v;
        v
      | v -> v
    in
    Mutex.unlock mutex;
    v

  let clear () =
    Mutex.lock mutex;
    Cache.clear tbl;
    Mutex.unlock mutex

  let stats () =
    Mutex.lock mutex;
    let stats = Cache.stats tbl in
    Mutex.unlock mutex;
    stats

  let length () =
    Mutex.lock mutex;
    let len = Cache.length tbl in
    Mutex.unlock mutex;
    len
end

module Make (H : Hashtbl.HashedType) : S with type key = H.t =
  Mk [@inlined hint] (Ephemeron.K1.Make [@inlined hint] (H))

module Make_thread_safe (H : Hashtbl.HashedType) : S with type key = H.t =
  Mk_thread_safe [@inlined hint] (Ephemeron.K1.Make [@inlined hint] (H))

module Make_strong (H : Hashtbl.HashedType) : S with type key = H.t =
  Mk [@inlined hint] (Hashtbl.Make [@inlined hint] (H))

module Make_strong_thread_safe (H : Hashtbl.HashedType) :
  S with type key = H.t =
  Mk_thread_safe [@inlined hint] (Hashtbl.Make [@inlined hint] (H))

module Fake (H : Hashtbl.HashedType) : S with type key = H.t =
Mk [@inlined hint] (struct
  type key = H.t

  type 'a t = Unit

  let create (_size : int) = Unit

  let clear Unit = ()

  let add (Unit : 'a t) (_v : key) (_ : 'a) = ()

  let find Unit (_v : key) = raise_notrace Not_found

  let length Unit = 0

  let stats Unit =
    { Hashtbl.num_bindings = 0
    ; num_buckets = 0
    ; max_bucket_length = 0
    ; bucket_histogram = [||]
    }
end)
