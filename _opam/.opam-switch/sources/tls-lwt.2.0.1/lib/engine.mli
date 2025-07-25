(** Transport layer security

    [TLS] is an implementation of
    {{:https://en.wikipedia.org/wiki/Transport_Layer_Security}transport
    layer security} in OCaml.  TLS is a widely used security protocol
    which establishes an end-to-end secure channel (with optional
    (mutual) authentication) between two endpoints.  It uses TCP/IP as
    transport.  This library supports all four versions of TLS:
    {{:https://tools.ietf.org/html/rfc8446}1.3, RFC8446},
    {{:https://tools.ietf.org/html/rfc5246}1.2, RFC5246},
    {{:https://tools.ietf.org/html/rfc4346}1.1, RFC4346}, and
    {{:https://tools.ietf.org/html/rfc2246}1.0, RFC2246}.  SSL, the
    previous protocol definition, is not supported.

    TLS is algorithmically agile: protocol version, key exchange
    algorithm, symmetric cipher, and message authentication code are
    negotiated upon connection.

    This library implements several extensions of TLS,
    {{:https://tools.ietf.org/html/rfc3268}AES ciphers},
    {{:https://tools.ietf.org/html/rfc4366}TLS extensions} (such as
    server name indication, SNI),
    {{:https://tools.ietf.org/html/rfc5746}Renegotiation extension},
    {{:https://tools.ietf.org/html/rfc7627}Session Hash and Extended
    Master Secret Extension}.

    This library does not contain insecure cipher suites (such as
    single DES, export ciphers, ...).  It does not expose the server
    time in the server random, requires secure renegotiation.

    This library consists of a core, implemented in a purely
    functional matter ({!Engine}, this module), and effectful parts:
    {!Tls_lwt} and {!Tls_mirage}.

    {e v2.0.1} *)


(** {1 Abstract state type} *)

(** The abstract type of a TLS state. *)
type state

(** {1 Constructors} *)

(** [client client] is [tls * out] where [tls] is the initial state,
    and [out] the initial client hello *)
val client : Config.client -> (state * string)

(** [server server] is [tls] where [tls] is the initial server
    state *)
val server : Config.server -> state

(** {1 Protocol failures} *)

(** failures which can be mitigated by reconfiguration *)
type error = [
  | `AuthenticationFailure of X509.Validation.validation_error
  | `NoConfiguredCiphersuite of Ciphersuite.ciphersuite list
  | `NoConfiguredVersions of Core.tls_version list
  | `NoConfiguredSignatureAlgorithm of Core.signature_algorithm list
  | `NoMatchingCertificateFound of string
  | `CouldntSelectCertificate
]

(** failures from received garbage or lack of features *)
type fatal = [
  | `Protocol_version of [
      | `None_supported of Core.tls_any_version list
      | `Unknown_record of int * int
      | `Bad_record of Core.tls_any_version
    ]
  | `Unexpected of [
      | `Content_type of int
      | `Message of string
      | `Handshake of Core.tls_handshake
    ]
  | `Decode of string
  | `Handshake of [
      | `Message of string
      | `Fragments
      | `BadDH of string
      | `BadECDH of Mirage_crypto_ec.error
    ]
  | `Bad_certificate of string
  | `Missing_extension of string
  | `Bad_mac
  | `Record_overflow of int
  | `Unsupported_extension
  | `Inappropriate_fallback
  | `No_application_protocol
]

(** type of failures *)
type failure = [
  | `Error of error
  | `Fatal of fatal
  | `Alert of Packet.alert_type
]

(** [alert_of_failure failure] is [alert], the TLS alert type for this failure. *)
val alert_of_failure : failure -> Packet.alert_level * Packet.alert_type

(** [string_of_failure failure] is [string], the string representation of the [failure]. *)
val string_of_failure : failure -> string

(** [pp_failure failure] pretty-prints failure. *)
val pp_failure : failure Fmt.t

(** {1 Protocol handling} *)

(** result type of {!handle_tls}: either failed to handle the incoming
    buffer ([`Fail]) with {!failure} and potentially a message to send
    to the other endpoint, or sucessful operation ([`Ok]) with a new
    {!state}, an end of file ([`Eof]), or an incoming ([`Alert]).
    Possibly some [`Response] to the other endpoint is needed, and
    potentially some [`Data] for the application was received. *)
type ret =
  (state * [ `Eof ] option
   * [ `Response of string option ]
   * [ `Data of string option ],
   failure * [ `Response of string ]) result

(** [handle_tls state buffer] is [ret], depending on incoming [state]
    and [buffer], the result is the appropriate {!ret} *)
val handle_tls           : state -> string -> ret

(** [handshake_in_progrss state] is a predicate which indicates whether there
    is a handshake in progress or scheduled. *)
val handshake_in_progress : state -> bool

(** [send_application_data tls outs] is [Some (tls', out)] where
    [tls'] is the new tls state, and [out] the cstruct to send over the
    wire (encrypted [outs]) when the TLS session is ready. When the TLS
    session is not ready it is [None]. *)
val send_application_data : state -> string list -> (state * string) option

(** [send_close_notify tls] is [tls' * out] where [tls'] is the new
    tls state, and out the (possible encrypted) close notify alert. *)
val send_close_notify     : state -> state * string

(** [reneg ~authenticator ~acceptable_cas ~cert tls] initiates a renegotation on
    [tls], using the provided [authenticator]. It is [tls' * out] where [tls']
    is the new tls state, and [out] either a client hello or hello request
    (depending on which communication endpoint [tls] is). *)
val reneg : ?authenticator:X509.Authenticator.t ->
  ?acceptable_cas:X509.Distinguished_name.t list -> ?cert:Config.own_cert ->
  state -> (state * string) option

(** [key_update ~request state] initiates a KeyUpdate (TLS 1.3 only). If
    [request] is provided and [true] (the default), the KeyUpdate message
    contains a request that the peer should update their traffic key as well. *)
val key_update : ?request:bool -> state -> (state * string, failure) result

(** {1 Session information} *)

(** [epoch state] is [epoch], which contains the session
    information. If there's no established session yet, an error is returned. *)
val epoch : state -> (Core.epoch_data, unit) result

(** [export_key_material epoch_data ?context label length] is the RFC 5705
    exported key material of [length] bytes using [label] and, if provided,
    [context]. *)
val export_key_material : Core.epoch_data -> ?context:string -> string -> int ->
  string

(** [channel_binding epoch_data mode] is the RFC 5929 and RFC 9266 specified
    channel binding. Please note that [`Tls_unique] will error for TLS 1.3
    sessions, and [`Tls_exporter] is not recommended for TLS < 1.3 sessions
    (unless the uniqueness is ensured via another path). *)
val channel_binding : Core.epoch_data ->
  [ `Tls_exporter | `Tls_unique | `Tls_server_endpoint ] ->
  (string, [ `Msg of string ]) result
