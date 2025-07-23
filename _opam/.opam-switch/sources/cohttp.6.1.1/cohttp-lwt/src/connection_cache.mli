(** This functor establishes a new connection for each request. *)
module Make_no_cache (Connection : S.Connection) : sig
  include S.Connection_cache

  val create : ?ctx:Connection.Net.ctx -> unit -> t
  (** [create ?ctx ()] creates a connection for handling a single request. The
      connection accepts only a single request and will automatically be closed
      as soon as possible.
      @param ctx See {!Connection.Net.ctx} *)
end

(** This functor keeps a cache of connections for reuse. Connections are reused
    based on their remote {!type:Conduit.endp} (effectively IP / port). *)
module Make (Connection : S.Connection) (Sleep : S.Sleep) : sig
  include S.Connection_cache

  val create :
    ?ctx:Connection.Net.ctx ->
    ?keep:int64 ->
    ?retry:int ->
    ?parallel:int ->
    ?depth:int ->
    ?proxy:Uri.t ->
    unit ->
    t
  (** Create a new connection cache

      @param ctx Conduit context to use. See {!type:Connection.Net.ctx}.
      @param keep Number of nanoseconds to keep an idle connection around.
      @param retry
        Number of times a {e gracefully} failed request is automatically
        retried. {e graceful} means failed with {!exception:Connection.Retry}.
        Requests with a [`Stream] {!module:Body} cannot be retried
        automatically. Such requests will fail with
        {!exception:Connection.Retry} and a new {!module:Body} will need to be
        provided to retry.
      @param parallel
        maximum number of connections to establish to a single endpoint. Beware:
        A single hostname may resolve to multiple endpoints. In such a case
        connections may be created in excess to what was intended.
      @param depth
        maximum number of requests to queue and / or send on a single
        connection.
      @param proxy A direct (non-tunneling) proxy to use. *)
end
[@@warning "-unused-functor-parameter"]

(** This functor keeps a cache of connections for reuse. Connections are reused
    based on their remote {!type:Conduit.endp} (effectively IP / port). It also
    supports automatically connecting and reconnecting to direct and tunneling
    proxies, based on the remote URI scheme (HTTP will select direct proxies,
    HTTPS tunneling proxies). *)
module Make_proxy (Connection : S.Connection) (Sleep : S.Sleep) : sig
  include S.Connection_cache

  val create :
    ?ctx:Connection.Net.ctx ->
    ?keep:int64 ->
    ?retry:int ->
    ?parallel:int ->
    ?depth:int ->
    ?scheme_proxy:(string * Uri.t) list ->
    ?all_proxy:Uri.t ->
    ?no_proxy:string ->
    ?proxy_headers:Http.Header.t ->
    unit ->
    t
  (** Create a new connection cache. The outer connections to the proxy and the
      inner connections share the same parameters.

      @param ctx Conduit context to use. See {!type:Connection.Net.ctx}.
      @param keep Number of nanoseconds to keep an idle connection around.
      @param retry
        Number of times a {e gracefully} failed request is automatically
        retried. {e graceful} means failed with {!exception:Connection.Retry}.
        Requests with a [`Stream] {!module:Body} cannot be retried
        automatically. Such requests will fail with
        {!exception:Connection.Retry} and a new {!module:Body} will need to be
        provided to retry.
      @param parallel
        maximum number of connections to establish to a single endpoint. Beware:
        A single hostname may resolve to multiple endpoints. In such a case
        connections may be created in excess to what was intended.
      @param depth
        maximum number of requests to queue and / or send on a single
        connection.
      @param scheme_proxy The proxy URI associated to each (remote) scheme.
      @param all_proxy
        The default proxy to use. Proxy for specific schemes have precedence
        over this.
      @param no_proxy
        Disable proxies for specific hosts, specified as curl's [NO_PROXY].
      @see <https://everything.curl.dev/usingcurl/proxies/env.html#no-proxy>
      @param proxy_headers Headers to pass to the proxy. *)
end
[@@warning "-unused-functor-parameter"]
