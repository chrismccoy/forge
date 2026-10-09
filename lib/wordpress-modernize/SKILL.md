# WordPress plugin: WPCS to PSR-12, PSR-4 and strict PHP 8.1

Convert the WordPress plugin in the current directory from the WordPress Coding Standards (WPCS) to PSR-12. Put the classes in a PSR-4 `src/` tree grouped by role, and add strict typing for PHP 8.1. Carry out the whole migration, not just a plan. Commit after every phase.

Run from the plugin's root directory. Nothing visible from outside the plugin may change. Every phase ends with the full test suite, an assertion-count comparison, a commit and a tag.

`<skill-dir>` below is `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-modernize`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it.

## Intake (do this first)

- If no PHP file in the root has a `Plugin Name:` header, stop: this is not a WordPress plugin and this procedure doesn't apply.
- If the user asked for only part of the work (for example only strict types, or only a namespace), say that this procedure runs all eight phases, and confirm before starting.

Before changing anything, read the code. Find:
- the main plugin file (the one with the `Plugin Name:` header). If more than one file in the root has a `Plugin Name:` header, the folder holds several plugins: see **Several plugins in one folder** in `references/phase-4-namespace.md`.
- the text domain and the current function/class prefix
- how the tests run, if there are any
- whether the plugin already uses namespaces, or loads `vendor/autoload.php` at runtime
- any `register_uninstall_hook()` call, and any objects stored in options, post meta or transients (these keep class names in the database)
- classes that extend a WordPress core, WP-CLI or third-party class (`WP_List_Table`, `WP_Widget`, `WP_REST_Controller`, `Walker`, `WP_Customize_Control`, a WP-CLI command), and method names built at runtime (see Hard rule 3)
- the PHP floor the header claims (`Requires PHP:`), which sets `<current-floor>`

Then ask the user these three questions in **one** `AskUserQuestion` call. Make the inferred answer the first option and mark it "(Recommended)". Don't start Phase 0 until the user has answered.

1. **Root namespace.** Suggest a PascalCase name based on the plugin name, for example `YtBulkImporter` for "YT Bulk Importer". Offer one or two alternatives, such as a `Vendor\Plugin` form.
2. **Released to users already?**
   - **No:** make a clean break. Rename classes and move global functions with no compatibility layer.
   - **Yes:** keep a `class_alias` shim for every old class name, plus a wrapper for every old global function, both marked deprecated. List them in the final report.
3. **How to run the tests.** Offer what was detected, for example:
   - an existing sandbox or `bin/` script
   - `wp-env`
   - the WP test suite with a MySQL database
   - "No tests, build the safety net from scratch"

   If the answer means a database or services need setting up, say what will be installed before installing it.

If the plugin already loads `vendor/autoload.php` at runtime, add a fourth question in the same call: keep the Composer autoloader (and map `<Root\Namespace>` in `composer.json`), or replace it with the small autoloader from Phase 4. Recommend keeping it when the plugin has runtime Composer dependencies. If the plugin is already namespaced but has no Composer autoloader, don't ask: use the Phase 4 autoloader, and keep the existing namespace as the suggested root namespace.

Use the answers wherever the instructions say `<Root\Namespace>`, `<plugin-slug>`, `<PREFIX>`, `<domain>` or `<current-floor>`. `<current-floor>` is the `Requires PHP:` value, or `7.4` when the header has none. Get the slug, prefix and text domain from the code, not from the user.

## Hard rules

These apply in every phase.

1. **No behaviour change.** Leave all of these exactly as they are:
   - option names, post meta and transient keys
   - REST namespaces and routes
   - hook and filter names, and the text domain
   - error codes, HTML output and JS config keys
   - callbacks and class names that WordPress has already stored in the database: the `register_uninstall_hook()` callback (saved in the `uninstall_plugins` option), and the class names inside serialized objects in options, meta and transients.

   Renaming stored names breaks existing installs: uninstall fatals, and stored objects come back as `__PHP_Incomplete_Class`. Keep a `class_alias`, or a wrapper method or function, for every such name (a stored global-function callback such as `'<prefix>_uninstall'` needs a wrapper function), even when intake says "not released", and list each in the final report. If both the class and the method of a stored callback get renamed (for example `['Old_Class', 'on_uninstall']`), keep both: a `class_alias` for the old class name, and a static wrapper with the old snake_case method name that calls the new one. Give the wrapper a `phpcs:ignore PSR1.Methods.CamelCapsMethodName.NotCamelCaps` with the reason "name stored in the database". New activations register the new name. Don't mark these aliases and wrappers deprecated: sites keep the stored name until the plugin is reinstalled.

   Activation and deactivation callbacks are not stored: the main file registers them again on every load, so they only need Hard rule 3. Objects of WordPress core classes, such as a `WP_Error` in a transient, are not affected.

   The only allowed changes are the type work in Phase 6, and any narrow fix it forces. List each such fix in the final report.
2. **Prove each step.** After every phase:
   - run the full test suite with `--log-junit build/junit-<tag>.xml`, named after the tag about to be created (for example `build/junit-v3-tier-b-youtube.xml`). List `build/` in `.gitignore`. If the plugin had no tests at v0, the first JUnit file is the one from Phase 1, and comparisons start there.
   - compare the `assertions` attribute of every `<testcase>` with the previous file. A test that disappeared counts as a drop. When test classes or files are renamed (Phase 4), keep an old-to-new name map in `MIGRATION_LOG.md` and compare through it.
   - investigate any drop before moving on.

   If a test failure or an assertion drop can't be explained within the phase, stop. Report the failing tests and the diff, and wait for the user. Don't change test expectations or golden files to make a failure go away. There are two exceptions. The first is a name this migration itself changes: a method renamed in Phase 3, a class moved or renamed in Phase 4, a method moved to a new class in Phase 4, or an old class or global function removed because intake said "not released". Update tests that name it (for example the explicit `hook => Class::method` list, or `function_exists('<prefix>_log')`) in the same commit as the rename, and record each old-to-new name in `MIGRATION_LOG.md`. The second is a test that fails only because the test file became strict in Phase 6 and passes a value core would pass coercively (for example `'5'` for an `int`): change that argument to the type core really passes. If core itself can pass that value, the fix belongs in the plugin (a nullable type or a cast), not in the test. List every test change under either exception in the final report.
3. **Never rename by blind find-and-replace.** Method names often match other strings: hook names (`parent_file`), settings keys (`strip_emojis`), variable names, and HTML ids (`ytbi_test_key`). Rename only in these positions:
   - definitions: `function x(`
   - calls: `->x(`, `self::x(`, `static::x(`, `parent::x(`, `ClassName::x(`
   - array callbacks: `[__CLASS__, 'x']`, `[self::class, 'x']`, `[$this, 'x']`, `['ClassName', 'x']`
   - string callbacks: `'prefix_function'` and `'ClassName::x'`, as passed to `add_action()`, `add_filter()`, `register_*_hook()`, `call_user_func()` and similar
   - name checks: `method_exists($obj, 'x')`, `is_callable([$obj, 'x'])`, `function_exists('x')`

   Rename only methods of the plugin's own classes. A call to another plugin's or WordPress's method keeps its name, even when it is snake_case (for example `method_exists($feature, 'is_enabled')` on another plugin's class). After each rename, grep for the old name and review every hit by hand.

   **Never rename a method that overrides or implements a method of a WordPress core, WP-CLI or third-party class or interface.** WordPress calls these by name, so a renamed one stops running without an error. Examples: `WP_List_Table::column_default`, `column_<name>`, `get_columns`, `prepare_items`, `get_bulk_actions`; `WP_Widget::widget`, `form`, `update`; `WP_REST_Controller::register_routes`, `get_items`, `get_item_schema`; `Walker::start_el`; `WP_Customize_Control::render_content`; and the public methods of a WP-CLI command class, which are command names. Keep the name, add `// phpcs:ignore PSR1.Methods.CamelCapsMethodName.NotCamelCaps -- overrides <Parent>::<method>`, and list each in the final report.

   **Method names built at runtime** don't show up in a grep for the old name: `'column_' . $name`, `[$this, 'render_' . $tab]`, `"handle_{$action}"`, and names passed to `call_user_func` or `method_exists` from variables. Before renaming, grep for concatenated and interpolated names. Leave the matching methods alone unless every place that builds the name is updated in the same commit.
4. **Translatable strings stay one literal.** Never split or concatenate the string inside `__()`, `_e()`, `esc_html__()` and similar. Doing so breaks makepot.
5. **Keep the PHP floor honest.** Until Phase 6, set `testVersion` to the floor the header claims now (for example `7.4-`), so Phases 1–5 don't add syntax the claimed floor can't run. In Phase 6, raise `testVersion` to `8.1-` and `Requires PHP:` in the plugin header to 8.1 together, and set `"php": ">=8.1"` in `composer.json`. The header changes in Phase 6, not earlier, because users see it. Use no syntax newer than 8.1: no `true`, `false` or `null` as standalone types, and no readonly classes. If `<current-floor>` is below 7.1, Phases 2–5 can't use syntax that needs 7.1: skip adding `public` to class constants in Phase 2, and leave the parameter and return types off the Phase 4 autoloader closure. Add both in Phase 6.
6. **Ask before** anything irreversible or outward-facing. Never push.
7. **Keep a progress log.** The migration outlasts the context window. Keep `MIGRATION_LOG.md` in the plugin root and list it in `.git/info/exclude`. After every commit, record the phase and step, the last tag, the test and assertion totals, the violation count, and any open issues or decisions. Keep a **Report items** section in the log, and add to it every time a phase file says to report something: the final report is written after the context has been summarized, so anything not in the log is lost. On resume, or after the context is summarized, read the log and `git tag --list` first, and continue from the last tag.
8. **Tag every phase** for rollback: `v0-baseline`, `v1-safety-net`, `v2-tier-a`, `v3-tier-b-<class-or-group>` for each Phase 3 step, `v4-namespace`, `v5-lint-zero`, `v6-strict-types`, `v7-verified`.

## Phases

Before starting each phase, read its reference file in full. Each file holds the exact steps, commands and pitfalls for that phase.

| Phase | Result | Tag | Read first |
|-------|--------|-----|------------|
| 0. Baseline | Git repo, dev environment, tests green before any change | `v0-baseline` | `references/phase-0-baseline.md` |
| 1. Safety net | PHPCS ruleset, wiring tests, golden copies of HTML and post output | `v1-safety-net` | `references/phase-1-safety-net.md` |
| 2. Tier A | `phpcbf` layout fixes, proved layout-only by a token-stream diff | `v2-tier-a` | `references/phase-2-tier-a.md` |
| 3. Tier B | snake_case methods to camelCase, one class or coupled group at a time | `v3-tier-b-<class-or-group>` | `references/phase-3-tier-b.md` |
| 4. Namespace | `src/` role folders, autoloader, `Plugin::boot()`; tree approved by the user | `v4-namespace` | `references/phase-4-namespace.md` |
| 5. Lint to zero | Line lengths, template wrapping, security ignores, `.pot` checked | `v5-lint-zero` | `references/phase-5-lint.md` |
| 6. Strict types | `declare(strict_types=1)`, full types, casts at WordPress boundaries, `Requires PHP: 8.1` | `v6-strict-types` | `references/phase-6-strict-types.md` |
| 7. Verify | Lint, tests, golden copies, PHP 8.1 run, smoke test, upgrade test | `v7-verified` | `references/phase-7-verify.md` |

Phase 4 pauses for the user to approve the proposed `src/` tree. Every other phase runs without stopping unless a hard rule says to stop.

## Final report

Report the following:
- the before and after violation counts
- the list of commits and tags
- every place behaviour changed (casts, nullable choices)
- every `phpcs:ignore` and why it's there
- what could not be verified (for example, no PHP 8.1 binary to run the tests on)
- every compatibility alias or wrapper kept for names stored in the database, and the result of the upgrade test
- every test changed under a Hard rule 2 exception
- every method kept unrenamed because it overrides a parent method or is called by a built name
- safety-net tests that were skipped or replaced, and known gaps (Phase 1)
- smoke or upgrade test steps that were skipped, and gaps that predate the migration (Phase 7)
- every other entry in the **Report items** section of `MIGRATION_LOG.md`
- anything the user needs to decide

## Additional resources

### Reference files
- **`references/phase-0-baseline.md`**: git setup, test environment, server and symlink safety
- **`references/phase-1-safety-net.md`**: Composer and PHPUnit setup, the `phpcs.xml.dist` ruleset, the safety-net tests
- **`references/phase-2-tier-a.md`**: phpcbf and the token-stream proof
- **`references/phase-3-tier-b.md`**: rename order and grouping
- **`references/phase-4-namespace.md`**: role folders, several plugins in one folder, the autoloader, stored names, test updates
- **`references/phase-5-lint.md`**: long lines, templates, security ignores, `.pot` check
- **`references/phase-6-strict-types.md`**: ruleset additions, `declare` placement, typing rules, coercion checks
- **`references/phase-7-verify.md`**: final checks, PHP 8.1 run, smoke test, upgrade test, README section

### Scripts
- **`scripts/surface.php`**: lists a plugin tree's outward-facing names (option, meta and transient keys, REST routes, hooks, script handles, menu slugs, nonces, `WP_Error` codes, translatable strings with their context, plural and domain). Phase 7 uses it to prove none of them changed. Needs PHP 8.0 or later.
