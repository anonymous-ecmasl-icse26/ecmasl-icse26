open Lwt
open Ex_common

let mypsk = ref None

let ticket_cache = {
  Tls.Config.lookup = (fun _ -> None) ;
  ticket_granted = (fun psk epoch -> mypsk := Some (psk, epoch)) ;
  lifetime = 0l ;
  timestamp = Ptime_clock.now
}

let test_client _ =
(*  X509_lwt.private_of_pems
    ~cert:server_cert
    ~priv_key:server_key >>= fun cert -> *)
  let port = 4433 in
  let host = "127.0.0.1" in
  let authenticator = null_auth in
  Tls_lwt.Unix.connect
    (get_ok Tls.Config.(client ~version:(`TLS_1_0, `TLS_1_3) (* ~certificates:(`Single cert) *) ?cached_ticket:!mypsk ~ticket_cache ~authenticator ~ciphers:Ciphers.supported ()))
    (host, port) >>= fun t ->
  let (ic, oc) = Tls_lwt.of_t t in
  let req = String.concat "\r\n" [
    "GET / HTTP/1.1" ; "Host: " ^ host ; "Connection: close" ; "" ; ""
  ] in
  Lwt_io.(write oc req >>= fun () ->
          read ~count:3 ic >>= print >>= fun () ->
          close oc >>= fun () ->
          printf "++ done.\n%!")

let jump _ =
  try
    Lwt_main.run (test_client ()) ; `Ok ()
  with
  | Tls_lwt.Tls_alert alert as exn ->
      print_alert "remote end" alert ; raise exn
  | Tls_lwt.Tls_failure alert as exn ->
      print_fail "our end" alert ; raise exn

open Cmdliner

let cmd =
  let term = Term.(ret (const jump $ setup_log))
  and info = Cmd.info "test_client" ~version:"2.0.1"
  in
  Cmd.v info term

let () = exit (Cmd.eval cmd)
