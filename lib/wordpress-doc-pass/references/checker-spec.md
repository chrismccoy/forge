# Checker specification

The bundled checker in `scripts/checker/` implements this spec. Read this file only when the bundled checker cannot be used (for example, it is missing or fails its self-test in a way you cannot explain) and you must write your own, or when you need to understand a checker failure.

## Setup

`verify.mjs` is an ES module: use `import`, and use `createRequire(import.meta.url)` if you need `require`. For JS parsing, install `@babel/parser` into `<scratchpad>/checker/` and use it (`sourceType: 'unambiguous'`, plugins `jsx` for `.js` / `.jsx` / `.mjs` / `.cjs`, `typescript` plus `jsx` for `.tsx`, `typescript` for `.ts`, `tokens: true`). Do not use prettier internals.

## verify.mjs

`node <scratchpad>/checker/verify.mjs <orig-dir> <current-dir> [files…]` compares each original file with the current one and runs three checks:

1. **Code check.**
   - PHP: tokenize with `token_get_all()` (in `php-tokens.php`). Drop `T_COMMENT`, `T_DOC_COMMENT` and `T_WHITESPACE`, and keep every other token verbatim, including `T_INLINE_HTML` (template markup outside `<?php ?>`) byte for byte, because whitespace there is real output. Compare the two token lists.
   - JS: deep-compare the Babel ASTs after dropping the keys `start, end, loc, range, comments, leadingComments, trailingComments, innerComments, extra, tokens, errors`.
2. **Layout check.** This catches reformatting, which the code check ignores. Remove every comment from both versions together with the spaces and tabs right after it (for a PHP `//` or `#` comment that ends in a newline, keep the newline), strip trailing whitespace from each line, drop empty lines, and compare the remaining lines exactly, including indentation. A docblock opened mid-line therefore passes only when the code after `*/ ` keeps its original line.
3. **Comment-is-code check.** Anchor every comment to the index of the next code token (from the code check's token list, so anchors match across versions when the code check passes).
   - **Frozen** comments must be identical: same text, same anchor, nothing added, nothing removed. For a `translators:` comment, it must also still be the last comment before its anchor. One exception: a new `translators:` comment is allowed when the code after it reaches a gettext function call (`__`, `_e`, `_x`, `_n`, `esc_html__` …) before the end of its statement (`;`, `{` or `}`), so it may sit before the statement or before an inner line of it.
   - **Frozen tag lines** inside docblocks (one line each, trimmed) must be identical as a multiset per anchor: nothing added, nothing removed.
   - **Kept tag lines** in the original must still exist at the same anchor. Adding new ones is allowed.
   - **Header fields** that WordPress reads with `get_file_data()` (plugin, theme, page-template and block pattern headers: `Plugin Name:`, `Theme Name:`, `Template Name:`, `Title:`, `Slug:` etc.) are frozen tag lines wherever they appear, so none may be added, removed or edited.

Print `CODE CHANGED: <file>`, `LAYOUT CHANGED: <file>:<line>` or `FROZEN COMMENT CHANGED: <file>: <text>` for each failure, then `OK: N files, code identical` or the failure count. Exit non-zero on any failure.

The Frozen and Kept classes are defined under **Preserve** in `rules-core.md`.

## coverage.mjs

`node <scratchpad>/checker/coverage.mjs <project> [--no-since] [files…]` scans the given files (relative to `<project>`), or every file when none are given. It prints one `MISSING …` line per gap followed by `GAPS: n` and exits 1, or prints `OK: N files fully documented` and exits 0. A gap is:

- PHP (tokenizer): every `class` / `interface` / `trait` / `enum`, named `function`, `function` closure, `const`, and property declaration not directly preceded by a `T_DOC_COMMENT` (allowing for modifiers and attributes such as `public`, `static`, `final`, `abstract`, `readonly`, `#[…]`); every hook call with no docblock and no `This … is documented in` line before its statement; and, unless `--no-since` is passed, every docblock missing `@since`. WP-CLI command classes and public methods are skipped (their docblocks are frozen). Arrow functions are not scanned (their rule needs judgement).
- JS (Babel AST): every file with no header comment, and every `FunctionDeclaration`, class method, top-level or exported `const`-bound function or class, and `ns.member = function` assignment with no leading `/** … */` comment.
