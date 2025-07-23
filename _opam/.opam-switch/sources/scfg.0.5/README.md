# scfg

scfg is an [OCaml] executable and library to work with the [scfg configuration file format].

## Installation

`scfg` can be installed with [opam]:

```sh
opam install scfg
```

If you don't have `opam`, you can install it following the [how to install opam] guide.

If you can't or don't want to use `opam`, consult the [opam file] for build instructions.

## Quickstart

Using the library to parse a `scfg` file and reprint nicely:

```ocaml
open Scfg

let config =
  match Parse.from_file "config.scfg" with
  | Ok config -> config
  | Error e -> begin
    Format.eprintf "error: %s@." e;
    exit 1
  end

let () =
  Format.printf "%a@." Pp.config config
```

The provided binary does exactly this. If you have the following `config.scfg` file:

```scfg
   name "a"        "b b b" 'c' {


       child1       ""    "I'm léo"

                child2 'nono'
     }
```

Running the binary on it will reprint it trying to make the output pretty:

```shell-session
$ scfg config.scfg
name a "b b b" c {
  child1 "" "I'm léo"
  child2 nono
}
```

For more, have a look at the [example] folder, at the [documentation] or at the [test suite].

## About

- [LICENSE]
- [CHANGELOG]

[CHANGELOG]: ./CHANGES.md
[example]: ./example
[LICENSE]: ./LICENSE.md
[opam file]: ./scfg.opam
[test suite]: ./test

[documentation]: https://doc.zapashcanon.fr/scfg
[how to install opam]: https://opam.ocaml.org/doc/Install.html
[OCaml]: https://ocaml.org
[opam]: https://opam.ocaml.org
[scfg configuration file format]: https://git.sr.ht/~emersion/scfg
