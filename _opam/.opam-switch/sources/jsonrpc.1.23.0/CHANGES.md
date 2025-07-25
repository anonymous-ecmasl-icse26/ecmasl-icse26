# 1.23.0

## Features

- Make `inlay-hint` for function parameters configurable (#1515)
- Add custom `ocamllsp/jumpToTypedHole` to navigate through typed holes (#1516)
- Add a code-action for combining pattern cases (just relaying on regex) (#1514)
- Allow (by configuration) shortening of diagnostics (just highlighting the first line) (#1513)
- Fix `yojson_of_t` for `Nullable_option`: serialize `None` as `Null` instead of asserting false (#1525 fixes #1524)

## Fixes

- Support for `class`, `class type`, `method` and `property` for `DocumentSymbol` query (#1487 fixes #1449)
- Fix `inlay-hint` for function parameters (#1515)
- More precise diagnostics in the event of a failed identifier search (`Definition_query`) (#1518)
- Remove `ocamlformat` application after `destruct` (that remove some useful parenthesis) (#1519)

# 1.22.0

## Features

- Enable experimental project-wide renaming of identifiers (#1431)

# 1.21.0

## Features

- Add a new server option `standardHover`, that can be used by clients to
  disable the default hover provider.  When `standardHover = false`
  `textDocument/hover` requests always returns with empty result. (#1416)

# 1.20.1

## Fixes

- Deactivate the `jump` code actions by default. Clients can enable them with
  the `merlinJumpCodeActions` configuration option. Alternatively a custom
  request is provided for ad hoc use of the feature. (#1411)

# 1.20.0

## Features

- Add custom
  [`ocamllsp/typeSearch`](/ocaml-lsp-server/docs/ocamllsp/typeSearch-spec.md) request (#1369)

- Make MerlinJump code action configurable (#1376)
- Add support for OCaml 5.3 (#1386)

- Add custom [`ocamllsp/jump`](/ocaml-lsp-server/docs/ocamllsp/merlinJump-spec.md) request (#1374)

## Fixes

- Fix fd leak in running external processes for preprocessing (#1349)

- Fix prefix parsing for completion of object methods (#1363, fixes #1358)

- Remove some duplicates in the `selectionRange` answers (#1368)

# 1.19.0

## Features

- Add custom [`ocamllsp/getDocumentation`](/ocaml-lsp-server/docs/ocamllsp/getDocumentation-spec.md) request (#1336)

- Add support for OCaml 5.2 (#1233)

- Add a code-action for syntactic and semantic movement shortcuts based on Merlin's Jump command (#1364)

## Fixes

- Kill unnecessary ocamlformat processes with sigterm rather than sigint or
  sigkill (#1343)

## Features

- Add custom [`ocamllsp/construct`](https://github.com/ocaml/ocaml-lsp/blob/ocaml-lsp-server/docs/ocamllsp/construct-spec.md) request (#1348)

# 1.18.0

## Features

- Introduce a configuration option to control dune diagnostics. The option is
  called `duneDiganostics` and it may be set to `{ enable: false }` to disable
  diagnostics. (#1221)

- Support folding of `ifthenelse` expressions (#1031)

- Improve hover behavior (#1245)

  Hovers are no longer displaye on useless parsetree nodes such as keywords,
  comments, etc.

  Multiline hovers are now filtered away.

  Display expanded ppx's in the hover window.

- Improve document symbols (#1247)

  Use the parse tree instead of the typed tree. This means that document
  symbols will work even if the source code doesn't type check.

  Include symbols at arbitrary depth.

  Differentiate functions / types / variants / etc.

  This now includes PPXs like `let%expect_test` or `let%bench` in the outline.

- Introduce a `destruct-line` code action. This is an improved version of the
  old `destruct` code action. (#1283)

- Improve signature inference to only include types for elements that were
  absent from the signature. Previously, all signature items would always be
  inserted. (#1289)

- Add an `update-signature` code action to update the types of elements that
  were already present in the signature (#1289)

- Add custom
  [`ocamllsp/merlinCallCompatible`](https://github.com/ocaml/ocaml-lsp/blob/e165f6a3962c356adc7364b9ca71788e93489dd0/ocaml-lsp-server/docs/ocamllsp/merlinCallCompatible-spec.md)
  request (#1265)

- Add custom [`ocamllsp/typeEnclosing`](https://github.com/ocaml/ocaml-lsp/blob/109801e56f2060caf4487427bede28b824f4f1fe/ocaml-lsp-server/docs/ocamllsp/typeEnclosing-spec.md) request (#1304)

## Fixes

- Detect document kind by looking at merlin's `suffixes` config.

  This enables more lsp features for non-.ml/.mli files. Though it still
  depends on merlin's support. (#1237)

- Correctly accept the `--clientProcessId` flag. (#1242)

- Disable automatic completion and signature help inside comments (#1246)

- Includes a new optional/configurable option to toggle syntax documentation. If
  toggled on, allows display of syntax documentation on hover tooltips. Can be
  controlled via environment variables and by GUI for VS code. (#1218)

- For completions on labels that the LSP gets from merlin, take into account
  whether the prefix being completed starts with `~` or `?`. Change the label
  completions that start with `?` to start with `~` when the prefix being
  completed starts with `~`. (#1277)

- Fix document syncing (#1278, #1280, fixes #1207)

- Stop generating inlay hints on generated code (#1290)

- Fix parenthesizing of function types in `SignatureHelp` (#1296)

- Fix syntax documentation rendering (#1318)

# 1.17.0

## Fixes

- Fix missing super & subscripts in markdown documentation. (#1170)

- Do not invoke dune at all if `--fallback-read-dot-merlin` flag is on. (#1173)

- Fix semantic highlighting of infix operators that contain '.'. (#1186)

- Disable highlighting unit as an enum member to fix comment highlighting bug. (#1185)

- Improve type-on-hover and type-annotate efficiency by only formatting the type
  of the first enclosing. (#1191, #1196)

- Fix the encoding of URI's to match how vscode does it (#1197)

- Fix parsing of completion prefixes (#1181)

## Features

- Compatibility with Odoc 2.3.0, with support for the introduced syntax: tables,
  and "codeblock output" (#1184)

- Display text of references in doc strings (#1166)

- Add mark/remove unused actions for open, types, for loop indexes, modules,
  match cases, rec, and constructors (#1141)
- Add inlay hints for types on let bindings (#1159)

- Offer auto-completion for the keyword `in` (#1217)

# 1.16.2

## Fixes

- Fix file permissions used when specifying output files of pp and ppx. (#1153)

# 1.16.1

## Fixes

- Support building with OCaml 5.0 and 5.1 (#1150)

# 1.16.0

## Fixes

- Disable code lens by default. The support can be re-enabled by explicitly
  setting it in the configuration. (#1134)

- Fix initilization of `ocamlformat-rpc` in some edge cases when ocamlformat is
  initialized concurrently (#1132)

- Kill unnecessary `$ dune ocaml-merlin` with SIGTERM rather than SIGKILL
  (#1124)

- Refactor comment parsing to use `odoc-parser` and `cmarkit` instead of
  `octavius` and `omd` (#1088)

  This allows users who migrated to omd 2.X to install ocaml-lsp-server in the
  same opam switch.

  We also slightly improved markdown generation support and fixed a couple in
  the generation of inline heading and module types.

- Allow opening documents that were already open. This is a workaround for
  neovim's lsp client (#1067)

- Disable type annotation for functions (#1054)

- Respect codeActionLiteralSupport capability (#1046)

- Fix a document syncing issue when utf-16 is the position encoding (#1004)

- Disable "Type-annotate" action for code that is already annotated.
  ([#1037](https://github.com/ocaml/ocaml-lsp/pull/1037)), fixes
  [#1036](https://github.com/ocaml/ocaml-lsp/issues/1036)

- Fix semantic highlighting of long identifiers when using preprocessors
  ([#1049](https://github.com/ocaml/ocaml-lsp/pull/1049), fixes
  [#1034](https://github.com/ocaml/ocaml-lsp/issues/1034))

- Fix the type of DocumentSelector in cram document registration (#1068)

- Accept the `--clientProcessId` command line argument. (#1074)

- Accept `--port` as a synonym for `--socket`. (#1075)

- Fix connecting to dune rpc on Windows. (#1080)

## Features

- Add "Remove type annotation" code action. (#1039)

- Support settings through `didChangeConfiguration` notification (#1103)

- Add "Extract local" and "Extract function" code actions. (#870)

- Depend directly on `merlin-lib` 4.9 (#1070)

# 1.15.1

## Fixes

- Fix race condition when a document was being edited and dune in watch mode was
  running ([#1005](https://github.com/ocaml/ocaml-lsp/pull/1005), fixes
  [#941](https://github.com/ocaml/ocaml-lsp/issues/941),
  [#1003](https://github.com/ocaml/ocaml-lsp/issues/1003))

# 1.15.0

## Features

- Enable [semantic highlighting](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens)
  support by default (#933)

- Support connecting over pipes and socket. Pipes on Windows aren't yet
  supported (#946)

  [More](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#implementationConsiderations)
  about communication channels in LSP specification.

- Re-enable `ocamlformat-rpc` for formatting code snippets (but not files and
  not on Windows) (#920, #939)

  One needs to have installed either `ocamlformat` package version > 0.21.0 or,
  otherwise, `ocamlformat-rpc` package. Note that previously `ocamlformat-rpc`
  came in a standalone OPAM package, but since `ocamlformat` version > 0.21.0,
  it comes within `ocamlformat` package.

- Add custom
  [`ocamllsp/hoverExtended`](https://github.com/ocaml/ocaml-lsp/blob/e165f6a3962c356adc7364b9ca71788e93489dd0/ocaml-lsp-server/docs/ocamllsp/hoverExtended-spec.md#L1)
  request (#561)

- Support utf-8 position encoding clients (#919)

  [More](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#position) about position encoding in LSP specification.

- Show unwrapped module alias types on hovering over module names. This is due
  to upgrading to merlin 4.7 and using merlin's `verbosity=smart` by default
  (#942)

## Fixes

- Respect the client's completion item resolve and preSelect capabilities
  (#925, #936)

- Disable polling for dune's watch mode on Windows and OCaml 4.14.0 (#935)

- Fix semantic highlighting of "long identifiers," e.g., `Foo.Bar.x` (#932)

- Fix syncing of document contents:

  - For ranges that span an entire line (#927)
  - Previously, whole line edits would incorrectly eat the newline characters (#971)

# 1.14.2

## Fixes

- Fix random requests failing after switching documents (#904, fixes #898)

- Do not offer related diagnostic information unless the user enables in client
  capabilities (#905)

- Do not offer diagnostic tags unless the client supports them (#909)

- Do not attach extra data to diagnostics unless the client supports this
  (#910)

- Use /bin/sh instead of /bin/bash. This fixes ocamllsp on NixOS

# 1.14.1

## Fixes

- Fix various server crashes when opening non OCaml/Reason files. Files such as
  dune, cram, etc. would cause the server to crash. (#884, fixes #871)

- Ignore unknown tags in merlin configuration to improve forward compatibility
  with Dune. (#883)

# 1.14.0

## Features

- Code action for inlining let bindings within a module or expression. (#847)

- Tag "unused code" and "deprecated" warnings, allowing clients to better
  display them. (#848)

- Refresh merlin configuration after every dune build in watch mode (#853)

## Fixes

- Respect `showDocument` capabilities. Do not offer commands or code actions
  that rely on this request without client support. (#836)

- Fix signatureHelp on .mll files: avoid "Document.dune" exceptions

# 1.13.1

## Fixes

- Fix cwd when executing ppx (#805)

# 1.13.0

## Features

- Code actions for jumping to related files (`.ml`, `.mli`, etc.) (#795)

# 1.12.4

- Allow cancellation of workspace symbols requests (#777)

- Fix unintentionally interleaved jsonrpc IO that would corrupt the session
  (#786)

- Ignore `SIGPIPE` . (#788)

# 1.12.3

## Fixes

- Fix a bad interaction between inferred interfaces and promotion code actions
  in watch mode (#753)

- Fix URI parsing (#739 fixes #471 and #459)

# 1.12.2

## Fixes

- Fix shutting down an already closed socket (#740)

# 1.12.1

## Fixes

- Fix preprocessing, ppx, and reason support (#735 fixes #696, #706)

- Support `include` in folding ranges (#730)

# 1.12.0

## Features

- Fix cancellation mechanism for all requests (#707)

- Allow cancellation of formatting requests (#707)

- Add `--fallback-read-dot-merlin` to the LSP Server (#705). If `ocamllsp` is
  started with this new flag, it will fall back to looking for Merlin
  configuration in `.merlin` files rather than calling `dune ocaml-merlin`.
  (#705)

- Support folding more ranges (#692)

# 1.11.6

## Fixes

- Stop leaking file descriptors like a sieve (#701)

# 1.11.5

- Fix process termination. Once the lsp server is stepped, the process will
  gracefully terminate (#697, fixes #694)

- Forward stderr from dune's merlin configuration to the lsp server's stderr
  (#697)

# 1.11.4

## Fixes

- Fix bug with large buffers being resized incorrectly in Lev

- Add folding ranges for more AST types (#680)

# 1.11.3

## Fixes

- Enable dune rpc integration by default (#691, fixes #690)

# 1.11.2

## Fixes

- Fix running external processes on Windows

# 1.11.1

## Fixes

- Fix Uri handling on Windows

- Fix build on MSVC 2015

# 1.11.0

## Features

- Add support for dune in watch mode. The lsp server will now display build
  errors in the diagnostics and offer promotion code actions.

- Re-introduce ocamlformat-rpc (#599, fixes #495)

## Fixes

- Fix workspace symbols that could have a wrong path in some cases
  ([#675](https://github.com/ocaml/ocaml-lsp/pull/671))

# 1.10.6

## Fixes

- Compatiblity with OCaml 4.14.0

# 1.10.5

## Fixes

- Patch merlin to remove the result module

# 1.10.4

## Fixes

- Use newer versions of ocamlformat-rpc-lib (fixes #697)

# 1.10.3

## Fixes

- Fix more debouncing bugs (#629)

# 1.10.2

## Fixes

- Catch merlin desturct exceptions (#626)

- Fix broken debouncing (#627)

# 1.10.1

## Fixes

- Fix executing ppx executables

# 1.10.0

## Features

- Add better support for code folding: more folds and more precise folds

## Fixes

- Fix infer interface code action crash when implementation source does not
  exist (#597)

- Improve error message when the reason plugin for merlin is absent (#608)

- Fix `chdir` races when running ppx (#550)

- More accurate completion kinds.
  New completion kinds for variants and fields. Removed inaccurate completion
  kinds for constructors and types. (#510)

- Fix handling request cancellation (#616)

# 1.9.1

## Fixes

- Disable functionality reliant on ocamlformat-rpc for now (#555)

- 4.13 compatiblity

# 1.9.0 (11/21/2021)

## Fixes

- Ppx processes are now executed correctly (#513)

## Breaking Change

- ocamllsp drops support for `.merlin` files, and as a consequence no longer
  depends on dot-merlin-reader. (#523)

## Features

- New code action to automatically remove values, types, opens (#502)

# 1.8.3 (09/26/2021)

- Fix debouncing of document updates. It was essentially completely broken in
  all but the most trivial cases. (#509 fixes #504)

- Fix completion when passing named and functional arguments (#512)

# 1.8.2 (09/14/2021)

- Disable experimental dune support. It was accidentally left enabled.

# 1.8.1 (09/12/2021)

- Update to latest merlin.

# 1.8.0 (08/19/2021)

## Fixes

- Handle workspace change notifications. Previously, the server would only use
  the set of workspaces given at startup to search for workspace symbols. After
  this change, workspace folders that are added later will also be considered.
  (#498)

## Features

- Add a new code action `Add missing rec keyword`, which is available when
  adding a `rec` keyword can fix `Unbound value ...` error, e.g.,

  ```ocaml
  let fact n = if n = 0 then 1 else n * fact (n - 1)
                                     (* ^^^^ Unbound value fact *)
  ```

  Adding `rec` to the definition of `fact` will fix the problem. The new code
  action offers adding `rec`.

- Use ocamlformat to properly format type snippets. This feature requires the
  `ocamlformat-rpc` opam package to be installed. (#386)

- Add completion support for polymorphic variants, when it is possible to pin
  down the precise type. Examples (`<|>` stands for the cursor) when completion
  will work (#473)

  Function application:

  ```
  let foo (a: [`Alpha | `Beta]) = ()

  foo `A<|>
  ```

  Type explicitly shown:

  ```
  let a : [`Alpha | `Beta] = `B<|>
  ```

  Note: this is actually a bug fix, since we were ignoring the backtick when
  constructing the prefix for completion.

- Parse merlin errors (best effort) into a more structured form. This allows
  reporting all locations as "related information" (#475)

- Add support for Merlin `Construct` command as completion suggestions, i.e.,
  show complex expressions that could complete the typed hole. (#472)

- Add a code action `Construct an expression` that is shown when the cursor is
  at the end of the typed hole, i.e., `_|`, where `|` is the cursor. The code
  action simply triggers the client (currently only VS Code is supported) to
  show completion suggestions. (#472)

- Change the formatting-on-save error notification to a warning notification
  (#472)

- Code action to qualify ("put module name in identifiers") and unqualify
  ("remove module name from identifiers") module names in identifiers (#399)

  Starting from:

  ```ocaml
  open Unix

  let times = Unix.times ()
  let f x = x.Unix.tms_stime, x.Unix.tms_utime
  ```

  Calling "remove module name from identifiers" with the cursor on the open
  statement will produce:

  ```ocaml
  open Unix

  let times = times ()
  let f x = x.tms_stime, x.tms_utime
  ```

  Calling "put module name in identifiers" will restore:

  ```ocaml
  open Unix

  let times = Unix.times ()
  let f x = x.Unix.tms_stime, x.Unix.tms_utime
  ```

## Fixes

- Do not show "random" documentation on hover

  - fixed by [merlin#1364](https://github.com/ocaml/merlin/pull/1364)
  - fixes duplicate:
    - [ocaml-lsp#344](https://github.com/ocaml/ocaml-lsp/issues/344)
    - [vscode-ocaml-platform#111](https://github.com/ocamllabs/vscode-ocaml-platform/issues/111)

- Correctly rename a variable used as a named/optional argument (#478)

- When reporting an error at the beginning of the file, use the first line not
  the second (#489)

# 1.7.0 (07/28/2021)

## Features

- Add sub-errors as "related" information in diagnostics (#457)

- Add support for navigating to a symbol inside a workspace (#398)

- Show typed holes as errors

  Merlin has a concept of "typed holes" that are syntactically represented as `_`. Files
  that incorporate typed holes are not considered valid OCaml, but Merlin and OCaml-LSP
  support them. One example when such typed holes can occur is when on "destructs" a value,
  e.g., destructing `(Some 1)` will generate code `match Some 1 with Some _ -> _ | None -> _`. While the first underscore is a valid "match-all"/wildcard pattern, the rest of
  underscores are typed holes.

# 1.6.1 (05/17/2020)

## Fixes

- Switch `verbosity` from 1 to 0. This is the same default that merlin uses.
  The old value for verbosity (#433)

- Get fresh diagnostics (warning and error messages) on a file save (#438)

  Note: If you want the fresh diagnostics to take into account changes in other
  files, you likely need to rebuild your project. An easy way to get automatic
  rebuilds is to run `dune` in a watching mode, e.g.,[dune build --watch].

# 1.6.0 (04/30/2020)

## Features

- Code action to annotate a value with its type (#397)

## Fixes

- Fix interface/implementation switching on Windows (#427)

- Correctly parse project paths with spaces and other special characters that
  must be escaped.

- Print types with `-short-paths` even if the project wasn't built yet

# 1.5.0 (03/18/2020)

- Support 4.12 and drop support for all earlier versions

- Update to the latest version of merlin

# 1.4.1 (03/16/2020)

## Fixes

- Backport fixes from merlin (#382, #383)

- Encode request & notification `params` in a list. This is required by the
  spec. (#351)

# 1.4.0 (12/17/2020)

## Features

- Support cancellation notifications when possible. (#323)

- Implement signature help request for functions (#324)

- Server LSP requests & notifications concurrently. Requests that require merlin
  are still serialized. (#330)

# 1.3.0 (11/23/2020)

## Features

- Code action to insert inferred module interface (#308)

- Filter keywords by context (#307)

# 1.2.0 (11/16/2020)

## Features

- Add keyword completion

- Add go to declaration functionality to jump to a value's specification in a
  .mli file (#294)

## Fixes

- #245: correctly use mutexes on OpenBSD (#264)

- #268: Do not use vendored libraries when building the lsp package (#260)

- #271: Clear diagnostics when files are closed

- Disable non-prefix completion. There's no reliably way to trigger it and it
  can be slow.

# 1.1.0 (10/14/2020)

## Features

- Implement a command to switch between module interfaces and implementations
  (#254)

## Fixes

- Do not crash on invalid positions (#248)

- add missing record fields to list of completions (#253)

- do not offer `destruct` as a code action in interface files (#255)

# 1.0.0 (08/28/2020)

- Initial Release
