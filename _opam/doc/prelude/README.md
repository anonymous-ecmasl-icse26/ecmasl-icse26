# prelude

[prelude] is an [OCaml] library hiding some parts of the stdlib.

## Installation

`prelude` can be installed with [opam]:

```sh
opam install prelude
```

If you don't have `opam`, you can install it following the [how to install opam] guide.

If you can't or don't want to use `opam`, consult the [opam file] for build instructions.

## Quickstart

To add it to your library or executable, you simply need to depend on `prelude`, you can also pass a flag to the compiler to open it automatically:

```dune
(library
 (name my_amazing_library)
 (modules foo bar)
 (flags
  (:standard -open Prelude))
 (libraries prelude))
```

Prelude is re-exporting some dependencies such as `fmt` or `bos`, you should not need to explicitly add them to the `libraries` field or your dune file.

## About

- [LICENSE]
- [CHANGELOG]

[CHANGELOG]: ./CHANGES.md
[LICENSE]: ./LICENSE.md
[opam file]: ./prelude.opam
[test suite]: ./test

[how to install opam]: https://opam.ocaml.org/doc/Install.html
[OCaml]: https://ocaml.org
[opam]: https://opam.ocaml.org/
[prelude]: https://git.zapashcanon.fr/zapashcanon/prelude
