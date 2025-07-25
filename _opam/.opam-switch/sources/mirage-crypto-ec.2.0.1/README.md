# mirage-crypto - Cryptographic primitives for MirageOS

v2.0.1

mirage-crypto is a small cryptographic library that puts emphasis on the
applicative style and ease of use. It includes basic ciphers (AES, 3DES, RC4,
ChaCha20/Poly1305), AEAD primitives (AES-GCM, AES-CCM, ChaCha20/Poly1305),
public-key primitives (RSA, DSA, DH), elliptic curves (NIST P-256, P-384, P-521,
and curve 25519), and a strong RNG (Fortuna).

RSA timing attacks are countered by blinding. AES timing attacks are avoided by
delegating to AES-NI.

Mirage-crypto is a fork of the
[ocaml-nocrypto](https://github.com/mirleft/ocaml-nocrypto) written by David
Kaloper.  It was forked with the permission of the original author in order to
facilitate changes (e.g. build system) required by Mirage that the upstream
didn't have time to keep up with.

Mirage-crypto-rng embeds the former mirage-entropy opam package, which
implements various entropy sources:
- non-deterministic execution time (used at initial seeding, see the [whirlwind RNG paper](https://www.ieee-security.org/TC/SP2014/papers/Not-So-RandomNumbersinVirtualizedLinuxandtheWhirlwindRNG.pdf))
- a hook into the Lwt event loop that collects a timestamp of each event
- rdseed and rdrand (x86/x86-64 only)

[API documentation online](https://mirage.github.io/mirage-crypto/doc)

## Build

```bash
dune build
dune runtest
```

## FAQ

#### RNG seeding

If RNG fails with `Fatal error: exception Unseeded_generator`, you need to
seed it.

```OCaml
let () = Mirage_crypto_rng_unix.use_default ()
```
