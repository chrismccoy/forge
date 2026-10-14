## Hard rule

Only add, edit or remove comments, plus blank lines next to comments where the comment style needs them (never to satisfy a formatting sniff). No reformatting, renaming, reordering, or changes to string literals. If keeping a line unchanged forces an awkward comment placement (e.g. a closure inline in an expression), put a block comment above the statement rather than splitting the line.

In templates:

- Never add HTML comments (`<!-- -->`). They are output.
- Never add or remove blank lines or whitespace outside `<?php ?>`.
- Put the file docblock inside the first existing `<?php` block. If the file starts with HTML, add it inside the first PHP block, never as a new `<?php ?>` at the top of the file.
- Never change the whitespace right after `<?php`: it is part of the open tag. When the first PHP block sits inside an HTML line, open the docblock on that line after `<?php `, and close it with `*/ ` directly before the existing code, so the code keeps its line:

  ```
  <h1><?php /**
   * Settings page view.
   *
   * @since 1.3.0
   *
   * @var string $tab Current tab slug.
   */ esc_html_e( 'Acme Notes', 'acme-notes' ); ?></h1>
  ```
- Never add anything after a closing `?>` at the end of a file.

## Failure protocol

- When the checker reports `CODE CHANGED`, `LAYOUT CHANGED` or `FROZEN COMMENT CHANGED`, a lint fails, or a test count moves, the cause is your edit. Restore that file from `<scratchpad>/orig/`, then redo only its comments.
- **Never edit code, tests, configs or the checker to make a check pass.** If you believe the checker is wrong, stop and report it with the exact output.
- If the same file fails twice, leave it restored to the original and list it in your report as not documented, with the reason.

## Universal rules (every profile)

- **Coverage:**
  - A file docblock on every PHP file (after `<?php`, before `declare` / `namespace`).
  - A docblock on every class, interface, trait and enum.
  - A docblock on every constant and property. A `define()` constant gets its docblock directly before the `define()` statement: summary and `@since`, with `@var` optional.
  - A global variable assigned at file scope (for example `$content_width` in a theme) gets a docblock before the assignment: summary, `@since` and `@var type`.
  - A docblock on every named function and method.
  - A docblock on every `function` closure, and on every arrow function (`fn`, `=>`) that is a hook callback, is stored in a variable or property, or has a non-obvious purpose. That includes `register_activation_hook` / `register_deactivation_hook` / `register_uninstall_hook` callbacks. A trivial one-expression arrow passed inline, such as `fn( $p ) => $p->ID`, needs none. A callback passed inline gets its docblock directly before the statement that passes it (for example, before `add_action( … )`).
  - A function inside an `if ( ! function_exists( '…' ) )` guard gets its docblock directly before `function`, inside the guard. The coverage scan accepts only that position, so move an existing docblock that sits before the `if` there, keeping its Kept lines.
  - **Header files** keep every header field, and any license or copyright comment, exactly as they are. Header files are the main plugin file and, in themes, page templates and block patterns (see the Theme rules). When the header is a `/** */` docblock, add an optional description, then `@package` and `@since`, as new lines after the last header field. When it is a `/* */` comment, or a license comment follows it, put a separate file docblock after them, before the first statement. When license or copyright lines sit inside the header docblock, add the new lines after the last of them.
  - Docblock indentation always matches the code it documents in that file. A profile's indentation rule applies only where the file already follows it; never re-indent code to match a profile.
  - Exception: a WP-CLI command class or public method with no docblock gets none, because any docblock becomes its help text. Explain it with a `//` comment inside the body if needed.
- **Content:**
  - A summary sentence ending in a period.
  - For a hook callback, name the hook in the description: `Hooked to 'init'.`, or `Added to the 'comments_open' filter by acme_comments_setup().` when another function adds it. A function that no hook calls needs no hook line.
  - A longer description when behavior isn't trivial: side effects, hooks fired, DB writes (and which tables or options), filesystem writes, HTTP calls, caching / transients, locking, cron scheduling, error paths and `WP_Error` codes, and capability / nonce requirements.
  - `@since`, following the `@since` policy and the profile.
  - `@param` for every parameter. Promoted constructor properties are documented with `@param` in the constructor docblock, not with a property docblock.
  - `@return` (see the profile for `void`).
  - `@throws` when it throws.
- **Hooks:** put a WordPress hook docblock before every `apply_filters` / `apply_filters_ref_array` / `do_action` / `do_action_ref_array`: `Filters the …` / `Fires when …` (or `Fires after/before …`), `@since`, and `@param` for each value passed. Follow the hook map in the rules file: the full docblock goes only in the chosen file, and every other firing gets `/** This filter is documented in path/to/file.php */` (or `This action …`).
- **Templates / views:** the file docblock lists, as `@var type $name Description.`, every variable the view reads that the including code passes or sets. Find them from the code that includes the view (`include`, `load_template`, `get_template_part` `$args`, `wc_get_template`), or from the template variable map in the rules file. Don't list variables the view assigns itself. A view loaded with a plain `include` also sees all of the includer's variables; list only the ones it reads, and say in the description that the includer's scope is visible.
- **Legacy `global` usage:** document globals the function reads or writes with `@global type $name Description.`, in WordPress order (after `@since`, before `@param`).
- **Preserve.** These comments fall into two classes. The checker enforces both.
  - **Frozen** (never add, remove, move or edit; the whole comment or line stays byte for byte):
    - Lint and tool directives: `phpcs:ignore` / `phpcs:disable` / `phpcs:enable`, legacy `@codingStandardsIgnore*`, `@noinspection`, `@codeCoverageIgnore*`, `eslint-disable*` / `eslint-enable`, `/* global … */`, `/* eslint-env … */`, `// @ts-*`, `prettier-ignore`, `istanbul ignore`, `c8 ignore`.
    - Translator comments: `/* translators: … */` and `// translators: …`, which must stay immediately before their gettext call. Exception: **add** a missing one when a gettext string has placeholders (`%s`, `%d`, `%1$s`) and has no translators comment. Put it on its own line directly before the line that holds the gettext call, or the `sprintf` / `printf` that wraps it, because translation tools attach a comment to the next gettext call. That can be inside a multi-line statement (before an array element or an argument line). When one statement holds several placeholder strings, each gets its own comment. Describe each placeholder (`/* translators: 1: Post title, 2: Author name. */`), and never add a second one where one exists. In a PHP block that opens inside an HTML line, write it inline after `<?php ` (`<?php /* translators: %s: Category name. */ echo …`); the line-length guidance does not apply to that line.
    - Bundler and compiler hints: `/*#__PURE__*/` / `/*@__PURE__*/`, webpack magic comments (`/* webpackChunkName: … */` etc.), `/** @jsx … */` / `@jsxRuntime` / `@jsxImportSource` / `@jsxFrag` pragmas, `// @flow`, and `/*! … */` or `@preserve` / `@license` comments that minifiers keep.
    - License, copyright and credit headers: any comment with `Copyright`, `@license`, `SPDX-License-Identifier`, `GNU General Public License` or an author credit. Never delete one, in any profile. A header docblock with a `License:` field is a file header, not a license comment: its header fields stay, and the description and tags may be added after them.
    - **File header fields**, one line each, in any comment: plugin headers (`Plugin Name:`, `Version:`, `Text Domain:` …), theme headers (`Theme Name:`, `Template:` …), page-template headers (`Template Name:`, `Template Post Type:`) and block pattern headers (`Title:`, `Slug:`, `Categories:` …). WordPress reads them with `get_file_data()`, which ignores letter case and takes the first match anywhere in the first 8 KB of the file. So never write a new comment line that starts with one of these names (in any letter case) followed by a colon, in any file; reword it (`The description is …`). Keep existing lowercase fields (`slug:`, `inserter:`) exactly as they are.
    - **WP-CLI command docblocks**, whole: any docblock on a class that extends `WP_CLI_Command`, on a class or callable registered with `WP_CLI::add_command`, or on any of their public methods, and any docblock containing `## OPTIONS`, `## EXAMPLES`, `@subcommand`, `@alias` or `@when`. WP-CLI turns these into the command's help and argument parsing.
    - **Behavior annotation lines** in docblocks: PHPUnit (`@test`, `@dataProvider`, `@depends`, `@group`, `@ticket`, `@covers*`, `@uses`, `@requires`, `@runInSeparateProcess`, `@runTestsInSeparateProcesses`, `@preserveGlobalState`, `@backupGlobals`, `@backupStaticAttributes`, `@doesNotPerformAssertions`, `@expectedException*`, `@expectedDeprecated`, `@expectedIncorrectUsage`, `@before*` / `@after*`, `@testWith`), and Doctrine-style annotations (any tag starting with a capital letter or containing a backslash, e.g. `@ORM\Column`, `@Route`). Also any docblock the project itself reads with `getDocComment()`: if you find such a call, treat the docblocks it reads as frozen whole.
  - **Kept** (keep the existing line; you may add new ones): `@since` values already present (they record history), `@deprecated`, `@see`, `@link`, `@internal`, `@ignore`, `@phpstan-*` / `@psalm-*` / `@template*` annotations, and existing `@var` lines with shapes or generics. Never replace an existing generic or shape type in a `@param`, `@return` or `@var` with a vaguer one; you may add a description after it.
- **Inline comments:**
  - They explain **why**, not what: security reasons (nonce, capability, escaping, SSRF or path guards), race conditions, ordering constraints, edge cases, back-compat shims, and fallbacks.
  - Don't narrate trivial lines.
  - Describe only what the code actually does. Never invent behavior. If unsure, read the caller.
  - A comment may state a fact a reader needs ("The value is not escaped here."), but never a verdict, a fix or a `TODO`. Bugs go in the report.
