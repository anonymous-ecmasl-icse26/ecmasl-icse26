# Changelog

## [8.0.4] - 2025-06-22

### Fixed

- Squelch uninitialized-value warnings. Thanks to Nathan Taylor for the
  contribution.

## [8.0.3] - 2025-02-18

- Removed export on `caml_alloc_some` to prevent linking issues.
- Added OUnit2-based test suite.

Thanks to Chet Murthy for these contribution.

## [8.0.2] - 2025-01-06

### Added

- Support for OCaml 4.08. Thanks to Chet Murthy for this contribution.

## [8.0.1] - 2024-12-20

### Fixed

- Fixed a bug in the `full_split` function where non-capturing groups were not
  identified as such.

### Removed

- Removed obsolete base-bytes dependency.

## [7.5.1] - 2024-12-07

### Added

- GitHub workflow for automated CI/CD.

### Changed

- Reformatted all OCaml and C-files for consistency.
- Improved and fixed documentation.
- Enhanced README and example README for clarity.

### Fixed

- Fixed macro instantiation formatting and minor C preprocessing issues.
- Corrected license typo.

## [7.5.0] - 2021-07-22

### Added

- Support for JIT-compilation of patterns to improve matching performance. Users
  need to add the `jit_compile` flag to request JIT-compilation when creating
  regular expressions.

## [7.4.6] - 2020-08-04

### Removed

- Mistakenly kept base library configuration dependency.

## [7.4.5] - 2020-08-04

### Removed

- Excessive build dependency on `base` package.

## [7.4.4] - 2020-07-30

### Added

- Missing dune-configurator dependency.
- Support for const char strings in stubs due to stricter handling in newer
  OCaml runtimes, eliminating C-compiler warnings.

## [7.4.3] - 2019-10-27

### Changed

- Switched from `caml_alloc_custom` to `caml_alloc_custom_mem` to improve memory
  usage and GC performance.
- Switched to OPAM file generation via `dune-project`.

## [7.4.2] - 2019-10-11

### Fixed

- Warnings in C-stubs.

## [7.4.1] - 2019-02-21

### Fixed

- Pattern execution bug due to DFA implementation.

## [7.4.0] - 2019-02-05

### Added

- DFA support with new functions:

  - `pcre_dfa_exec`
  - `unsafe_pcre_dfa_exec`

  Thanks to Chas Emerick <chas@cemerick.com> for this contribution.

## [7.3.5] - 2018-10-25

### Changed

- Switched to dune, dune-release, and OPAM 2.0.

## [7.3.4] - 2017-11-22

### Improved

- Finalization of regular expressions and tables for better performance.

## [7.3.3] - 2017-10-17

### Fixed

- External declaration bug in internal regexp compile function.

## [7.3.2] - 2017-10-10

### Improved

- Compatibility with MSVC.

## [7.3.1] - 2017-10-08

### Changed

- Used untagged integers when declaring external functions.

## [7.3.0] - 2017-07-27

### Changed

- Switched to jbuilder and topkg.

## Changes Before Version 7.3.0

```text
2016-02-25:  Minor version release v7.2.3:

               Fixed callout bug introduced with v7.2.0.

             Thanks to Raman Varabets for the bug report.

2016-02-23:  Fixed linking problem with old versions of PCRE (< 8.20).

             Fixed backward compatibility issue with OCaml <= 3.12.

2016-02-22:  Fixed a subgroup matching bug.

             Thanks to Cheng Lou for the bug report.

2015-08-21:  Made GC less aggressive reclaiming regexps and chartables.

2014-12-10:  Fixed another limit handling bug in the full_split function.

2014-12-02:  Fixed a limit handling bug in the full_split function.

             Thanks to Rudi Grinberg <rudi.grinberg@gmail.com> for the report.

2014-10-23:  Fixed string handling for new OCaml version 4.02 (String/Bytes
             modules). Requires new findlib version (>= 1.5).

2014-07-06:  Moved to GitHub.

2014-06-04:  Bug fixes:

               * Allcation bug when performing callouts
               * Unprotected root when performing callouts
               * More portable offset copying in the C-stubs
               * Fixed a PERL-compatibility bug in the splitting routines

            The bug fixes required a minor API-change in an unsafe function,
            which is almost surely not directly called by any users.

2012-07-20:  Downgraded findlib version constraint to support the Debian
             testing branch.

             Added --with-pcre-config flag to configure location of PCRE
             configuration generator.

2012-07-15:  New major release version 7.0.0:

               * Upgraded to OCaml 4.00
               * Switched to Oasis for packaging
               * Switched to OCamlBuild for the build process
               * Rewrote README in Markdown
               * Added stricter compilation flags
               * Minor bugfixes

2012-01-04:  Fixed native code debug build target by updating OCamlMakefile.

             Thanks to Stéphane Glondu <glondu@debian.org> for the patch.

2011-12-15:   Fixed a Windows portability bug in the C-bindings.

             Thanks to Evgenii Lepikhin <johnlepikhin@gmail.com> for the patch.

2011-11-09:  Updated OCamlMakefile to fix linking order.

2011-01-16:  Added support for limit recursion flag.

             Thanks to Delphin Lecucq <Delphin.LECUCQ@3ds.com> for the patch.

2010-10-31:  Improved Windows support with MSVC.

             Thanks to Sylvain Le Gall <sylvain@le-gall.net> for the patch.

2010-04-01:  Added new function:

               * regexp_or

2009-06-20:  Fixed bug in configuration functions that could lead to a segfault.

             Thanks to Gerd Stolpmann <gerd@gerd-stolpmann.de> for the patch.

2009-05-07:  Changed API wrt. error handling and thus made a major release.

             Improved behavior in the presence of recursion limit errors.
             Thanks to Martin Jambon <martinj@mylife.com> for this patch.

2009-04-23:  Fixed build problem on MinGW.

             Thanks to Gerd Stolpmann <gerd@gerd-stolpmann.de> for the patch.

2009-03-08:  Fixed build problem on Mac OS X with macports.

             Thanks to Ralph Douglass <ralph@grayskies.net> for the
             initial patch.

             Update OCamlMakefile.

             Improved Godi-distribution.

2008-05-06:  Fixed build problem with newer versions of PCRE.

2008-03-14:  Synced with Jane Street tree.

2008-01-25:  Added new function:

               * names

             This function returns the names of all named substrings in a
             regular expression.

             Thanks to Benedikt Grundmann <bgrundmann@janestreet.com>
             for the patch.

2007-07-12:  Improved build scripts for Windows.

             Thanks to Christophe Troestler
             <Christophe.Troestler@umh.ac.be> for the patch.

2007-07-12:  Improved documentation for Win32 builds, and added some build
             scripts usable on Windows.

             Thanks to Christophe Troestler
             <Christophe.Troestler@umh.ac.be> for this contribution.

2007-04-23:  callback_exn -> caml_callback_exn.

             Updated OCamlMakefile.

2006-11-22:  Updated OCamlMakefile.

2006-06-11:  Updated to pcre-5.0.

             New representation for callbacks: they now take one
             argument (a record of the callback data).

             Added partial matching and auto callouts.

2006-01-16:  Updated OCamlMakefile.

             Removed a superfluous binding.

2005-08-18:  Fixed a small compilation problem on rare platforms by
             upgrading OCamlMakefile.

2005-06-08:  Relaxed license. Fixed copyright headers.

2005-05-31:  Fixed some uncleanliness reported by Saffire (FFI-type checker).

2004-09-17:  Fixed a bug for null patterns in exec_all (extract_all
             and extract_all_opt are also affected).

             Updated OCamlMakefile.

2004-05-19:  Updated Makefile.mingw.
             Thanks to Jeff Henrikson <jehenrik@yahoo.com> for the patch.

             Updated OCamlMakefile.

2004-04-29:  *** Changed behaviour of "get_substring" ***

             It now does not return the empty string anymore if an
             accessed substring was not captured. It raises the exception
             "Not_found" instead.

             Three new functions:

               * get_opt_substrings
               * extract_opt
               * extract_all_opt

             These behave like the functions without "opt", but return
             "Some substring" for captured substrings, and "None"
             otherwise.

2004-04-27:  Updated OCamlMakefile.

2004-04-24:  Updated OCamlMakefile.

2004-03-28:  Changed interface to build-time configuration functions
             of PCRE.

             Updated OCamlMakefile.

2004-02-21:  Added CAMLprim in the C-interface where appropriate.

2004-02-08:  Fixed a minor bug with returning unit values from C.

2004-01-31:  Added pcre_make.win32/Makefile.mingw. Thanks to Jeffrey
             Henrikson <JEFHEN@SAFECO.com> for this contribution.

             Update OCamlMakefile.

2004-01-13:  Updated `pcre_make.win32/pcre.h`.

2003-12-30:  Fixed documentation.

2003-12-21:  Updated to pcre-4.5.

             New function:

               * config_stackrecurse

             New exception:

               * BadUTF8Offset

             Updated OCamlMakefile.

2003-12-19:  Fixed a small (but probably unnoticable) bug with
             allocation of optional values in the C-stubs.

2003-12-12:  Updated OCamlMakefile. Renamed stubs (invisible to users).

2003-11-16:  Updated `pcre_make.win32/pcre.h` to reflect newest PCRE-version.
             May help Windows users.

2003-10-08:  Upgraded to pcre-4.4.

             New flag for compiling patterns: NO_UTF8_CHECK
             New exception: BadUTF8

             Updated OCamlMakefile.

2003-09-30:  Fixed a bug in the documentation.
             Updated OCamlMakefile.

2003-06-17:  Fixed a bug in the documentation.
             Updated OCamlMakefile.

2003-05-29:  Updated to pcre-4.3.

             Major change: callouts are now fully supported. This allows
             the matching engine call OCaml-code while matching.
             Please see the interface specification for more information.

             Small changes (improvements) in C-code. Updated
             documentation.

2003-04-08:  Updated OCamlMakefile. Reformatted documentation.

2003-03-20:  Added new function `get_subject`. Patched OCamlMakefile.

2003-03-18:  Major update: upgraded to pcre-4.1.

             Better UTF8-support.
             New flag "NO_AUTO_CAPTURE".

             New values:

               * config_utf8
               * config_newline
               * config_link_size
               * config_match_limit

             Renamed all occurrences of "firstchar" to "firstbyte".

             New functions:

               * studysize
               * namecount
               * nameentrysize
               * get_stringnumber

             Updated OCamlMakefile.

2003-01-07:  Updated OCamlMakefile to make use of "findlib".

             Added support for UTF-8 character encodings.

             Better installation and documentation for Win32.

             Thanks to Artem Prisyznuk <tema@sit.kiev.ua> for the above
             patches.

2002-12-14:  Fixed a bug with zero-sized matches effecting
             `replace`, `qreplace`, `substitute_substrings` and
             `substitute`.

             Updated OCamlMakefile.

2002-12-08:  Improved documentation of `pcre_exec`.

2002-11-24:  Fixed a bug in `full_split` with matched subgroups.

2002-11-12:  Added a new function `extract_all` (see interface
             documentation).

2002-08-16:  Fixed a bug in the `split`-function:

             The Perl-splitting semantics was not fully adhered to:
             we stripped leading whitespace after the matching process
             rather than before, which lead to incompatible behaviour
             with limits.

             Thanks to Yutaka Oiwa <oiwa@yl.is.s.u-tokyo.ac.jp> for the
             bug report.

             Updated OCamlMakefile.

2002-07-31:  Fixed a bug in the following functions:

               * replace
               * qreplace
               * substitute_substrings

             Transformed most part of the library to make it slightly
             more efficient and simple. The interface is still the same.

             Updated OCamlMakefile + documentation.

2002-07-15:  Fixed a mistake in the documentation.

2002-05-05:  Fixed a bug with the generation of byte-code libraries that
             dynamically link the PCRE.

2002-05-01:  Removed C-library from distribution. Users must install it
             on their own now. Reorganized whole distribution and updated
             OCamlMakefile again for better support of dynamic and/or
             static libraries.

2002-04-30:  Updated OcamlMakefile: it does not ask for confirmation
             during installation anymore.

2002-03-06:  Upgraded to pcre-3.9. This should not change anything for
             OCaml-users.

2002-03-01:  Updated OcamlMakefile.

2002-02-24:  Separated compilation of library and examples to prevent
             confusions when the library requires installation before
             one can build the examples.

2002-02-15:  Fixed a bug in the `pcre_exec`-function introduced
             ten days ago during correction of another bug (thanks to
             Gerd Stolpmann for the report).

2002-02-15:  Added the option to compile the library statically.

             Updated INSTALL-notes to explain possible installation
             problems associated with support of dynamic linking.

             Added META-file for findlib.

2002-02-12:  Rewrote interface documentation to support OCamldoc.

             Fixed a portability bug with shared libraries.

2002-02-10:  Removed project from Sourceforge for simpler maintainance.

2002-02-07:  Important news: library linked dynamically now by default.

2002-02-06:  Fixed a stupid bug affecting the following functions
             (thanks to Jacek Chrzaszcz for the bug report):

               * num_of_subs
               * get_substring
               * get_substring_ofs
               * get_substrings
               * extract

             Also done: converted literal pattern strings in the library
             and the cloc-example so that the escape char (backslash) does
             not cause warnings anymore with the new OCaml-release. The
             latter is more paranoid about unknown escape combinations,
             requiring the user to add extra backslashes.

2002-01-07:  Fixed a stupid bug: the position argument (offset) was
             incorrectly handled in replacement and substitution
             functions, leading to wrong results. As it seems, people
             seldom use arguments other than zero...

             The "subst"-example now assumes that offsets other than zero
             should not lead to an error if it exceeds the line length.
             We copy the line instead.

2001-12-28:  Added README.win32 (courtesy of John W. Small).

             Updated README so that Hevea generates it.

2001-11-19:  Upgraded to the newest release of the underlying C-library
             (PCRE-3.7).

             Added a patch to compile with the Visual C++ compiler under
             W2K (thanks to John W. Small).

             Updated contact address.

2001-11-17:  Updated OcamlMakefile.

2001-09-15:  Upgraded to the newest release of the underlying C-library
             (PCRE-3.5).

             Added a new function: substitute_substrings

             Like "substitute", but takes the full substring information of the
             match rather than the matching string.
             Thanks to Patrick M. Doane for proposing this missing feature.

2001-09-07:  Updated OcamlMakefile

2001-08-27:  Fixed a bug in the splitting function: leading whitespace was
             always removed incorrectly when using a regular expression
             rather than a pattern. This behaviour should happen
             with the default whitespace pattern, which gets used if you
             do not specify any pattern or regexp in the function call.

2001-06-30:  Removed "Printexc.catch" from examples: is going to be
             deprecated in upcoming OCaml-release.

2001-05-22:  Fixed typo in documentation.

2001-04-25:  Added a new function: asplit

             Identical to "split" with the exception that it returns a string
             array instead of a string list. This makes it easier for the user
             to access strings by index.

             Added a new option to "get_substrings" and "extract": full_match

             When "full_match" is true (default: yes), then the resulting
             string array will contain the full match at index 0,
             otherwise the result will contain captured substrings.

             Removed superfluous comments in "pcre.ml": they are already
             present in the interface documentation anyway.

2001-04-08:  Small patch that makes this library compile on OpenBSD, too.

2001-01-30:  Made Makefile more general (allows simpler addition of
             further examples).

2001-01-24:  Updated OcamlMakefile: made default definition of
             "OCAMLLIBPATH" backwards compatible again: some people
             do not use the CVS-version of OCaml, which supports the
             "-where"-option. People with the new compiler will not
             notice any effect.

2001-01-06:  Added a new function: `exec_all`

             It allows you to execute pattern matching over a whole
             string until we find no more matches: then it returns
             the array of all matching "substrings". You can extract
             subpatterns of each of those matching substrings again with
             the usual functions.

             Fixed a minor inconsistency in "next_match".

2000-12-23:  Updated OcamlMakefile: makes use of the new "-where"-keyword
             to find the path to the standard library if undefined.

2000-12-14:  Pedantry in the C-interface: added "const" qualifiers.

2000-12-09:  Made some functions tail-recursive (unlikely to cause
             any noticable effect for most people).

2000-12-02:  Cleaned up the code a bit for distribution on SourceForge.
             Speed of some operations should be slightly improved, too.

2000-11-16:  Fixed a stupid bug that could crash your programs under rare
             circumstances (when you use faulty regular expressions).

             Added an internally used exception (InternalError) to the
             interface of the library. This allows the user to handle
             the case when the C-engine exhibits undefined behaviour
             (should never happen, anyway).

2000-09-27:  Upgraded to the newest release of the underlying C-library
             (PCRE-3.4).

             See "pcre-C/ChangeLog" for more information (minor bugfixes).

             Renamed "pgrep" to "pcregrep" to prevent name hiding on
             Solaris (change as suggested in the C-library distribution).

2000-06-24:  Updated OcamlMakefile

2000-06-13:  Updated OcamlMakefile

2000-06-12:  Mini-optimisation: lifted a pure value out of a function body.

2000-06-11:  Updated OcamlMakefile

2000-06-08:  Added installation routine + updated OcamlMakefile again:

             This upgrade makes installation much easier. Read the
             updated INSTALL-file.

2000-06-07:  Updated to new OcamlMakefile

2000-06-05:  Added a new function:

               get_substring_ofs substrings n

             This allows you to get the offset positions of the matching
             pattern and the substrings directly from a value of type
             "substring". See the interface documentation for details.

2000-05-15:  Upgraded to the newest release of the underlying C-library
             (PCRE-3.2).

             This does not add new features, but should fix some
             PERL-compatibility bugs and improves portability.

2000-05-04:  Minor update of C-interface:

             Use the new "hash_variant"-function to compute the hash value of
             variants (used Callback.register before - a bit clumsy).

2000-04-24:  New release: compiles with OCaml-3.00.

             Lots of changes in interface. OCaml-3.00 introduced some syntax
             changes for labels. No keywords allowed for them.
             All this required renamings. I tried to stick to
             the new labels of the "str"-library as close as makes sense.
             Sorry for this inconvenience, but I think that adhering to some
             "standard" is a Good Thing...

             For further information on the changes, look at the documentation
             of the interface file.

2000-04-23:  Minor cleanup of C-interface:

             Made local functions + variables static and moved a check for
             error codes (lint should be happier now).

2000-04-01:  Changed linking of the library again (marginally):

             The new linking semantics for byte code libraries allows passing
             of now remembered flags. This then requires linking executables
             against "pcre.cma" - the C-library ("libpcre.a") links
             automatically.

2000-03-30:  Cleaned up the C-interface:

             Removed a possible bug in the allocation of firstchar values.

             Saner handling of polymorphic variants (not hard-wired
             integers anymore - registered via callbacks).

             Better GC-settings: much nicer to the GC now (fewer full
             cycles - marginally more memory consumption). Should make
             programs run slightly faster when regular expressions are
             often allocated.

             Changed linking of the library to suit the semantics of
             the upcoming OCaml-major release (backward compatible).

2000-02-07:  Changed interface of function `foreach_file`:

             No idea why I implemented a tuple in the interface instead of a
             curried function. Must have been the drugs... ;-)

             Former interface:

               val foreach_file :
                 string list -> (string * in_channel -> unit) -> unit

             Current interface:

               val foreach_file :
                 string list -> (string -> in_channel -> unit) -> unit

             This function now also closes the file channel in case of an
             exception. The exception gets reraised, of course.

2000-02-05:  Eliminated a PERL-incompatibility of the "split"-function:

             When we specify neither the pattern nor the compiled regular
             expression, "split" defaults to a whitespace pattern.
             PERL also strips leading whitespace when in "default" mode.

             This last "feature" (?) was overseen during the introduction
             of labels and default arguments.

2000-02-05:  Updated the C-library to the newest release (pcre-3.0).

             This is a major release, but the changes to the OCaml-part
             are rather small: the functionality for information on compiled
             patterns has changed.

             Instead of the former "info"-function, we provide more than one.
             I think this is the most convenient way to handle
             this, because it does not force the user to do explicit
             pattern matching on results: due to the number of new
             info-options this would have been rather confusing.

             Because the old PCRE-function "pcre_info" is obsolete, I chose to
             drop its OCaml-interface. This part is infrequently used anyway.

             See the interface file and the ChangeLog + documentation
             of the C-library to see, what has changed in detail.

             The other changes marginally effect efficiency. One
             bug was present in the last release in the "info"-part
             (polymorphic variants were incorrectly represented).
             This has changed anyway and should work fine now.

2000-01-10:  `foreach_line` uses stdin as labeled (label: 'in') default
             argument now.

1999-12-29:  Lots of changes:

             * Uses the new features of OCaml 2.99:

               Labeled parameters and default arguments for much more
               convenience. E.g. write

                 split pos:1 "foo bar"

               to get the list ["oo"; "bar"].

               Polymorphic variants for passing options: this change allows,
               for example, using the data constructor "ANCHORED" for both
               compiling flags and at matching time instead of "C_ANCHORED"
               and "R_ANCHORED".

             * Got rid of all the superfluous shortcuts, like "bounded_psplit"
               and the like. Labeled parameters are much more readable and
               convenient.

             * Removed the functions compatible to the "Str"-module. It's
               probably rather confusing for people to see two different kinds
               of implementations.

             * Renamed functions due to the use of labels and the removing of
               the obsolete compatibility functions.

             * Updated documentation with more details on using the library.

1999-12-21:  Small change (2 chars...) to make the C-interface compile with
             the newest release (OCaml 2.99).

1999-09-27:  Fixed a bug which occurs, when replacements or substitutions
             in strings are longer than the subject string itself.
             This concerns functions `replace_all`, `qreplace_all` and
             `substitute_all` + their variants.

             THANKS to GERD STOLPMANN (Gerd.Stolpmann@darmstadt.netsurf.de)
             for finding another bug.

1999-09-21:  Fixed some bugs in `pcre_intf.c`:

             We used `Store_field` inappropriately throughout the file,
             which could lead to segfaults in the garbage collector. We
             corrected this by using the "Field"-macro where appropriate.

             Protected an input parameter from untimely reclamation.

             Initialized a field before throwing an exception to please
             the GC.

             The GC should be happy now...

             THANKS to GERD STOLPMANN (Gerd.Stolpmann@darmstadt.netsurf.de)
             for the patch.

1999-08-31:  Updated to pcre-2.08 - this should fix some bugs. See
             "pcre-C/ChangeLog" for details.

             Renamed directory "pcre-C-2.07" to "pcre-C" to allow for
             easier upgrading.

             Added CVS-info to sources.

1999-08-24:  Updated to pcre-2.07. Splitting is 100% PERL-compatible now.
             New runtime option: NOTEMPTY (see interface for details).

             Two more examples: cloc and count_hash.

             New functions: sregexpo, sregexp, sregexp_case_fold.

1999-08-02:  Exception handling more regular now:

             Raises [Invalid_argument] instead of [Failure] where
             appropriate.
             Raises [InternalError] if C-library exhibits undefined
             behaviour (has never happened so far).

             Updated comments.

1999-07-30:  Bugfix in `pcre_intf.c`:

             `pcre_ocaml` should work now on 64-bit architectures...

1999-07-29:  Small fix in `pcre_intf.c`:

             Strict compilers (gcc is not strict) otherwise complain
             about undefined behaviour in a certain line.

             Explicitely mention all include files.
             Removed unused variable.

             Also moved a line for efficiency...

1999-07-28:  First release.
```
