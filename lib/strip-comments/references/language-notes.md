# Per-Language Rules and False Positives

## Where the header ends, by language

The header comment is the first comment block in the file, before any executable
statement or import. Its exact boundary differs:

| Language | Header starts | Notes |
|---|---|---|
| JS/TS | line 1, or line 2 after a shebang | Ends at the first non-comment, non-blank line. A `'use strict'` prologue comes *after* the header, so the header ends before it. |
| Python | line 1, or after a shebang and any coding declaration (`# -*- coding: utf-8 -*-`) | A module **docstring** is not a comment; see below. |
| Go | before the `package` clause | A doc comment attached to `package x` with no blank line between them is the package doc — keep it. A comment separated from `package` by a blank line is a free-floating header — also keep it. |
| Rust | `//!` inner doc comments at the top | `//!` documents the enclosing module and is compiled into rustdoc. Treat the leading `//!` run as the header. |
| C/C++ | before any `#include` or `#pragma` | `#pragma once` is not a comment; the header ends before it. |
| Shell | after the shebang | |
| CSS/SCSS | line 1 | |
| SQL | line 1 | |
| Vue/Svelte/Astro | first comment inside each `<script>` block | The file has no single header; treat each `<script>` block as its own file. |

Keep the header **byte for byte**, including its trailing blank-line separator.
Do not reflow it, do not re-indent it, do not merge it with anything.

## Python: docstrings

A docstring is a string expression, not a comment. Three consequences:

1. Removing a docstring that is a function's or class's **only body** produces a
   syntax error. Replace it with `pass` in that case, or leave the docstring.
2. Docstrings are readable at runtime via `__doc__`, and `doctest`, `pydoc`,
   Sphinx, `click`/`argparse` help text, and FastAPI endpoint descriptions all
   consume them. Removing them can change program output.
3. A triple-quoted string that is *not* in docstring position is ordinary data.

Default policy: strip `#` comments; **keep docstrings unless the request names
them**. When the request does name them (the base prompt does list docstrings as
removable), still keep any docstring that FastAPI, `argparse`, `click`, or
`doctest` reads, and flag each one kept in the report.

## JSX / TSX

`{/* ... */}` inside markup is a JSX expression container holding a comment. It
renders nothing, so it is removable — but the braces must go with it. Deleting
only the inner `/* ... */` leaves `{}`, which renders as an empty child and is
valid but meaningless. Delete the whole `{/* ... */}` node.

A comment inside a JSX **attribute** position or between attributes uses plain
`/* */` with no braces. Removing it is safe; removing the surrounding whitespace
is not.

## Go

`gofmt` attaches comments to the following declaration. A doc comment on an
exported identifier is what `go doc` and `golint` read. The base task removes
these; expect `golint`/`revive` "exported X should have comment" warnings after
the run, and say so in the report rather than re-adding them.

## Templates: Vue, Svelte, Blade, EJS, Handlebars, Astro

Process only the code regions:

- `<script>` and `<script setup>` blocks — JS/TS rules apply
- `<style>` blocks — CSS rules apply
- `@php ... @endphp` and `<?php ?>` in Blade — PHP rules apply
- `<% ... %>` in EJS — JS rules apply, but `<%# ... %>` is an EJS comment and is
  out of scope by default

Leave `<template>` and raw markup alone unless HTML comments were explicitly
requested. Blade's `{{-- --}}` and Handlebars' `{{! }}` / `{{!-- --}}` are
template comments, out of scope by the same rule.

## Shell

`#` inside a double-quoted string, a heredoc body, a `case` pattern, or a
parameter expansion default (`${x:-#}`) is data. `#` is only a comment when it
starts a word — i.e. preceded by start-of-line, whitespace, `;`, `|`, `&`, or an
opening paren. `${#arr[@]}`, `$#`, and `#!` are never comments.

## SQL

`--` is a comment, but `--` also appears inside string literals and in some
dialects inside operators. MySQL requires `-- ` (with a trailing space or
control character) to be a comment; a bare `--` is not. Postgres does not have
that rule. When the dialect is unknown, require whitespace after `--` before
treating it as a comment, and flag the rest.

`/* */` in MySQL with a `!` prefix (`/*! 40101 SET ... */`) is a **version-gated
executable hint**, not a comment. Never remove it.

## Ruby

`=begin` / `=end` block comments must start at column 0. `#` inside `%w[]`,
string interpolation, or a regex is data. Magic comments (`# frozen_string_literal: true`,
`# encoding: utf-8`) are load-bearing — preserve them.

## The recurring false positives

1. **URLs**: `https://example.com` contains `//`. The single most common
   mis-strip. Same for protocol-relative `//cdn.example.com`.
2. **Regex literals**: `/\/\/+/`, `s#a#b#`, `re.compile(r"#\d+")`.
3. **String and template literals**: `"/* not a comment */"`, `` `${x} // y` ``.
4. **Heredocs**: everything between the delimiters is data, in every language
   that has them.
5. **Fragment identifiers**: `"#main"`, `element.querySelector('#id')`,
   CSS `#id` selectors, colour literals `#fff`.
6. **Division vs regex vs comment** in JS: `a / b / c` versus `a //comment`.
   Depends on the preceding token.

None of these are decidable by line-level regex. Read enough surrounding context
to tell code from data, or use the language's own tooling.

## Multi-line trailing comments

```js
const x = 1; /* this comment
   continues onto the next line */ const y = 2;
```

The span is one comment. Removing it must not swallow `const y = 2;`. Cases like
this get flagged in the report rather than resolved silently — state the file,
the line range, and what was left alone.
