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
  - A docblock on every constant and property.
  - A docblock on every named function and method.
  - A docblock on every `function` closure, and on every arrow function (`fn`, `=>`) that is a hook callback, is stored in a variable or property, or has a non-obvious purpose. That includes `register_activation_hook` / `register_deactivation_hook` / `register_uninstall_hook` callbacks. A trivial one-expression arrow passed inline, such as `fn( $p ) => $p->ID`, needs none. A callback passed inline gets its docblock directly before the statement that passes it (for example, before `add_action( … )`).
  - The main plugin file keeps every header field, and any license or copyright comment, exactly as it is. When the header is a `/** */` docblock, add the description, `@package` and `@since` as new lines after the last header field. When it is a `/* */` comment, or a license comment follows it, put a separate file docblock after them, before the first statement. When license or copyright lines sit inside the header docblock, add the new lines after the last of them.
  - Docblock indentation always matches the code it documents in that file. A profile's indentation rule applies only where the file already follows it; never re-indent code to match a profile.
  - Exception: a WP-CLI command class or public method with no docblock gets none, because any docblock becomes its help text. Explain it with a `//` comment inside the body if needed.
- **Content:**
  - A summary sentence ending in a period.
  - A longer description when behavior isn't trivial: side effects, hooks fired, DB writes (and which tables or options), filesystem writes, HTTP calls, caching / transients, locking, cron scheduling, error paths and `WP_Error` codes, and capability / nonce requirements.
  - `@since`, following the `@since` policy and the profile.
  - `@param` for every parameter. Promoted constructor properties are documented with `@param` in the constructor docblock, not with a property docblock.
  - `@return` (see the profile for `void`).
  - `@throws` when it throws.
- **Hooks:** put a WordPress hook docblock before every `apply_filters` / `apply_filters_ref_array` / `do_action` / `do_action_ref_array`: `Filters the …` / `Fires when …` (or `Fires after/before …`), `@since`, and `@param` for each value passed. Follow the hook map in the rules file: the full docblock goes only in the chosen file, and every other firing gets `/** This filter is documented in path/to/file.php */` (or `This action …`).
- **Templates / views:** the file docblock lists every variable in scope as `@var type $name Description.` Find them from the code that includes the view (`include`, `load_template`, `get_template_part` `$args`, `wc_get_template`).
- **Legacy `global` usage:** document globals the function reads or writes with `@global type $name Description.`, in WordPress order (after `@since`, before `@param`).
- **Preserve.** These comments fall into two classes. The checker enforces both.
  - **Frozen** (never add, remove, move or edit; the whole comment or line stays byte for byte):
    - Lint and tool directives: `phpcs:ignore` / `phpcs:disable` / `phpcs:enable`, legacy `@codingStandardsIgnore*`, `@noinspection`, `@codeCoverageIgnore*`, `eslint-disable*` / `eslint-enable`, `/* global … */`, `/* eslint-env … */`, `// @ts-*`, `prettier-ignore`, `istanbul ignore`, `c8 ignore`.
    - Translator comments: `/* translators: … */` and `// translators: …`, which must stay immediately before their gettext call. Exception: **add** a missing one when a gettext string has placeholders (`%s`, `%d`, `%1$s`) and its statement has no translators comment. Put it on its own line directly before the statement, describe each placeholder (`/* translators: 1: Post title, 2: Author name. */`), and never add a second one where one exists.
    - Bundler and compiler hints: `/*#__PURE__*/` / `/*@__PURE__*/`, webpack magic comments (`/* webpackChunkName: … */` etc.), `/** @jsx … */` / `@jsxRuntime` / `@jsxImportSource` / `@jsxFrag` pragmas, `// @flow`, and `/*! … */` or `@preserve` / `@license` comments that minifiers keep.
    - License, copyright and credit headers: any comment with `Copyright`, `@license`, `SPDX-License-Identifier`, `GNU General Public License` or an author credit. Never delete one, in any profile. A plugin header docblock with a `License:` field is a plugin header, not a license comment: its header fields stay, and the description and tags may be added after them.
    - **WP-CLI command docblocks**, whole: any docblock on a class that extends `WP_CLI_Command`, on a class or callable registered with `WP_CLI::add_command`, or on any of their public methods, and any docblock containing `## OPTIONS`, `## EXAMPLES`, `@subcommand`, `@alias` or `@when`. WP-CLI turns these into the command's help and argument parsing.
    - **Behavior annotation lines** in docblocks: PHPUnit (`@test`, `@dataProvider`, `@depends`, `@group`, `@ticket`, `@covers*`, `@uses`, `@requires`, `@runInSeparateProcess`, `@runTestsInSeparateProcesses`, `@preserveGlobalState`, `@backupGlobals`, `@backupStaticAttributes`, `@doesNotPerformAssertions`, `@expectedException*`, `@expectedDeprecated`, `@expectedIncorrectUsage`, `@before*` / `@after*`, `@testWith`), and Doctrine-style annotations (any tag starting with a capital letter or containing a backslash, e.g. `@ORM\Column`, `@Route`). Also any docblock the plugin itself reads with `getDocComment()`: if you find such a call, treat the docblocks it reads as frozen whole.
  - **Kept** (keep the existing line; you may add new ones): `@since` values already present (they record history), `@deprecated`, `@see`, `@link`, `@internal`, `@ignore`, `@phpstan-*` / `@psalm-*` / `@template*` annotations, and existing `@var` lines with shapes or generics. Never replace an existing generic or shape type in a `@param`, `@return` or `@var` with a vaguer one; you may add a description after it.
- **Inline comments:**
  - They explain **why**, not what: security reasons (nonce, capability, escaping, SSRF or path guards), race conditions, ordering constraints, edge cases, back-compat shims, and fallbacks.
  - Don't narrate trivial lines.
  - Describe only what the code actually does. Never invent behavior. If unsure, read the caller.
  - A comment may state a fact a reader needs ("The value is not escaped here."), but never a verdict, a fix or a `TODO`. Bugs go in the report.
