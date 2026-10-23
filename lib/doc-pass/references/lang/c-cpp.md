## C and C++ rules

### Files and tools

- In scope: `.c`, `.h`, `.cc`, `.cpp`, `.cxx`, `.c++`, `.hpp`, `.hh`, `.hxx`, `.ipp`, `.inl`.
- Out of scope: build trees, generated sources (`*.pb.h`, `moc_*.cpp`, `ui_*.h`, flex and bison output, configure-generated `config.h`), vendored `third_party/` code, assembly, linker scripts, `CMakeLists.txt` and Makefiles.
- Syntax check: the project's build (`cmake --build`, `make`; the main session, once per wave, in its work copy), or `-fsyntax-only` with the flags from `compile_commands.json`, which writes nothing and agents may run.
- Baselines before and after: clang-tidy, cppcheck, `clang-format --dry-run -Werror` (it reflows long comments: stay within `ColumnLimit`), clang's `-Wdocumentation` (checks `@param` names). Then the project's test runner (`ctest`, `make check`).
- `.h` files parse with the C++ grammar, so C code using C++ keywords as identifiers (`new`, `class`) parses as an error; the `.c` grammar is older. The checker locks the broken region byte for byte, comments included (`--list-frozen` prints `LOCKED:`): the enclosing declaration, or the broken statement and its neighbours. Edit comments only outside locked regions.

### Doc comment style

- Doxygen. Doc forms: `/** … */`, `/*! … */`, `///`, `//!`; for a member, a trailing `///<`, `/**<` or `//!<` on the same line. Plain `/* */` and `//` never count.
- Follow the project's prefix: `@brief` or `\brief` (default `@`). With `JAVADOC_AUTOBRIEF` or `QT_AUTOBRIEF`, the first sentence is the brief.
- `@param[in]`, `@param[out]`, `@param[in,out]` per parameter; `@tparam` per template parameter; `@return` unless `void`; `@retval VALUE` per distinct return code; `@throws` (C++) per exception thrown on purpose; `@pre`, `@post`, `@note`, `@warning` where they carry weight.
- Each file: a `/** @file … */` header saying what it declares or implements.
- Never repeat types. Say units, ranges, whether a pointer may be `NULL`, buffer sizes in bytes or elements.

### Coverage

- At file scope, in a `namespace` body, inside `#if` / `#ifdef` blocks, or after `template<…>` (the doc goes above the `template` line): function definitions; function prototypes in `.h`, `.hh`, `.hpp`, `.hxx`; `struct`, `union`, `enum` and `class` with a body; `typedef`s; `#define` macros.
- Every member declaration inside a `struct`, `union` or `class` body (data members and member function declarations).
- Exempt: a definition whose name has a documented prototype in a header (matched by unqualified name), and include guards (`#define FOO_H` with no value; names ending `_H`, `_H_`, `_HPP`, `_HPP_` or `_INCLUDED`).
- Checked by reading: member functions defined in a class body, nested types, enumerators, `using` aliases.
- The doc comment sits directly above the declaration, with no blank line between.

### Comments that are code

- Whole comment frozen when its first line starts with `NOLINT` (`NOLINTNEXTLINE`, `NOLINTBEGIN` …), `clang-format off` / `clang-format on`, `IWYU pragma:`, `cppcheck-suppress`, `NOTREACHED`, `LINTED`, `lint`, `ARGSUSED`, `VARARGS`, `coverity[`, `cspell:`, `spell-checker:`, `noinspection`, `NOSONAR` or `language=`; and when any line starts with `@generated`, `@license`, `Copyright`, `(c) 2024`, `©`, `SPDX-License-Identifier`, `Permission is hereby granted` or `Licensed under the`, or names the GNU (Lesser, Affero) General Public License.
- Fall-through markers, frozen whole when the comment is only the marker (GCC's `-Wimplicit-fallthrough` form): `FALLTHROUGH`, `FALLTHRU`, `fall through`, `falls through`, `fall-through`, `fallthrough` (any case), optionally after `intentional` / `intentionally` / `else,` and before a `- reason`. A comment with more prose (`Fall through to the default case.`) is not a marker for GCC or the checker: never reword an existing marker into one.
- Frozen tag lines: `@deprecated` / `\deprecated`, `@internal`, `@cond` / `@endcond` (Doxygen hides the item or section). Kept lines (keep each exactly; new ones allowed): `@see`, `@since`, `@author` and their `\` forms.
- Last before their code: `NOLINTNEXTLINE`, `cppcheck-suppress`, fall-through markers.
- Each `//` line is its own comment: never start any line with these words, and never write a new comment that is only a fall-through marker.
- `#pragma` and attributes (`[[fallthrough]]`, `__attribute__`) are code.

### Headers and ownership

- Document a function once, at its header prototype. The definition then needs no doc comment; implementation notes there are `//` comments. A `static` function is documented at its definition.
- **Ownership:** who frees a returned pointer and how (`free`, `foo_destroy()`); whether a pointer parameter is borrowed, taken over or stored; how long a returned pointer, reference, `string_view` or `span` stays valid. In C++: `unique_ptr` parameters transfer ownership, `shared_ptr` shares it, raw pointers and references borrow; say what a moved-from object holds.
- **Classes:** what a RAII type owns, its copy and move semantics, and its exception guarantee (basic, strong, nothrow).
- **Thread safety:** whether a function is reentrant or thread-safe; which mutex guards which field (on the field); which thread runs a callback.
- **Error conventions:** the return-code scheme (0 or negative `errno`, `NULL`, `false`), whether `errno` is set, and the state of out-parameters on failure.
- **Macros:** what it expands to in words, whether an argument is evaluated more than once, and for configuration macros the default and who defines it (`-D`, `config.h`). Never put a comment inside a backslash-continued macro: document above the `#define`.

### Embedded and systems code

- **ISRs:** the vector, its priority, the shared state it touches, what it must not do (block, allocate), and how main code synchronizes with it.
- **`volatile`:** say why the object is volatile (memory-mapped register, ISR-shared flag).
- **Registers:** each field or bit mask names the register or bit and its access (read-only, write-one-to-clear). Never invent reset values or offsets.
- **Alignment and packing:** why a struct is packed or aligned (DMA, cache line, wire format).
- **Endianness:** the byte order of each wire or storage field, and where it is converted (`htons`).
- **Timing:** units for every delay.

### Bug report additions

- Buffer sizes: `strcpy`, `sprintf`, `strncpy` without a terminating NUL, off-by-one on the NUL, size math that can overflow or truncate.
- Undefined behavior: signed overflow, uninitialized reads, shifts by the type width or more, strict-aliasing casts, `NULL` dereference.
- Use after free, double free, leaks on error paths, format strings from input, data races, `volatile` used as thread synchronization.
- C++: missing rule of three or five, exceptions escaping destructors or `extern "C"` functions.
