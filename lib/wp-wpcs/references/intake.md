# Intake

Do all of this before Phase 0. Don't change any file yet.

## Does this procedure apply?

- If no PHP file in the root has a `Plugin Name:` header, stop: this is not a WordPress plugin and this procedure doesn't apply.
- If the code already follows WPCS (no namespaced classes, snake_case methods, tab indentation), say so and stop. A plugin that is only partly modern is in scope, for example one with WPCS layout and snake_case names that only adds namespaces and `strict_types`. Phases then have less to do, and Phase 3 may have no steps at all.
- If the user asked for only part of the work (for example only snake_case, or only docblocks), say that this procedure runs all nine phases, and confirm before starting.
- If tags starting with `wpcs-v` exist already, this is a resume: follow Hard rule 7 in `SKILL.md`.

## Read the code

Find:
- the main plugin file (the one with the `Plugin Name:` header). If more than one file in the root has that header, the folder holds several plugins: see **Several plugins in one folder** in `phase-4-flatten.md`.
- the text domain, and the prefix the plugin already uses for constants, options, hooks and functions (for example `YTBI_DIR`, `ytbi_settings`)
- every namespace the plugin declares; the root one is `<Old\Namespace>`
- how the tests run, if there are any
- whether the plugin loads `vendor/autoload.php` at runtime, or has a hand-written `spl_autoload_register()`
- objects passed to public hooks, and public properties or methods the plugin's docs show. Phase 3 asks about these.
- any `register_uninstall_hook()` call, and any objects stored in options, post meta or transients. These keep both class names *and property names* in the database.
- classes that extend a WordPress core, WP-CLI or third-party class, classes that implement a PHP built-in interface (`JsonSerializable`, `ArrayAccess`, `IteratorAggregate`, `Countable`) or a third-party interface, and method or property names built at runtime (see `renaming.md`)
- a dependency container or anything else that reads names by reflection. Autowiring by parameter name ties a parameter's name to its binding, and `::class` keys in config files are class references too.
- whether the plugin already owns `build/`, `dist/` or a ruleset such as `phpcs.xml`. If a release script uses or empties `build/`, `<scratch>` is `.wpcs/`, listed in `.git/info/exclude`; otherwise `build/`. `phpcs.xml` takes precedence over `phpcs.xml.dist`, so replace whichever exists.
- strings built from class names (`::class`, `__CLASS__`, `__NAMESPACE__`, `get_class()`, `get_called_class()`) that end up stored or shown: option, cache or transient keys, hook names, CSS classes, log lines (see `renaming.md`)
- which PHP versions are installed (`ls /usr/bin/php[0-9]*`), since Phase 8 runs the tests on the floor with a real binary
- the PHP floor the header claims (`Requires PHP:`), which sets `<current-floor>`, and the WordPress floor (`Requires at least:`), which sets `<wp-floor>`. If the header has no `Requires PHP:`, infer the floor from the newest syntax the code uses: typed properties and arrow functions need 7.4; union types, `mixed`, `match`, constructor promotion and nullsafe need 8.0; `readonly`, enums and `never` need 8.1; a `true` type, a standalone `false` or `null` type and `readonly class` need 8.2; typed class constants need 8.3. To check, run `php <skill-dir>/scripts/floor-scan.php <claimed-floor> <every-php-path>` (`src`, `config`, `views`, the main file, `uninstall.php`), using the inferred floor when nothing is claimed: anything listed means the claimed floor is wrong. If that version is installed, also run `php<version> -l` on every PHP file now: a parse error found here costs a question, and found in Phase 8 it costs seven phases. Under `strict_types`, the syntax floor is only a lower bound: an internal function whose signature changed can need a newer PHP (`ob_implicit_flush( true )` needs 8.0), and `REVIEW` lines show the ones the scan knows. `<current-floor>` is the higher of the two. If it has no `Requires at least:`, use the oldest WordPress version that has every core API and script handle the plugin uses.

Record the findings in the log as soon as Phase 0 creates it.

## Earlier forward migration

If `/wp-modernize` converted this plugin earlier, its tags (`v0-baseline` to `v7-verified`) and possibly its `MIGRATION_LOG.md` are still in the repo. Its old-to-new name map, inverted, gives the original WordPress names, and `git show v0-baseline:<file>` shows the old layout. Use them as hints in Phases 3 and 4, where the code still matches: the code may have changed since. Never edit or delete that log or those tags. This skill's tags all start with `wpcs-`, and it logs to `WPCS_MIGRATION_LOG.md`, so nothing clashes.

## Ask the user

Ask every question below, in four `AskUserQuestion` calls (a call holds at most 4 questions). Make the inferred answer the first option and mark it "(Recommended)". Never assume an answer, even one that looks obvious or that was given for another plugin, unless the user's request already states it. Don't start Phase 0 until the user has answered.

### First call: the plugin

1. **Prefix.** Suggest the prefix the plugin's constants and options already use, for example `YTBI`. Explain what it gives: classes `YTBI_Import_Page`, global functions and constants `ytbi_*` and `YTBI_*`. Offer one alternative based on the plugin name. WPCS needs at least 4 characters, and the trailing underscore counts, so a short prefix such as `msd` works in the ruleset as `msd_`. It rejects reserved prefixes such as `wp`, `wordpress` and `php`: ask again if the suggestion is one of those.
2. **Released to users already?**
   - **No:** make a clean break. Old namespaced class and function names go away, except names stored in the database (Hard rule 1).
   - **Yes:** keep an alias for every old namespaced class name, eager or lazy as Phase 4 asks, plus a wrapper for every old namespaced function, both marked `@deprecated` (see `phase-4-flatten.md`). Renamed public methods get no wrapper. List all of these in the final report, so the user can decide about the methods.
3. **How to run the tests.** Offer what was detected, for example:
   - an existing sandbox or `bin/` script
   - `wp-env`
   - the WP test suite with a MySQL database
   - a throwaway WordPress on SQLite, which needs no database server (see `phase-0-baseline.md`)
   - "No tests, build the safety net from scratch"

   If the answer means a database or services need setting up, say what will be installed before installing it.

4. **PHP floor.** Ask this when the header has no `Requires PHP:`, or when the code needs a newer PHP than the header claims (enums under `Requires PHP: 8.0`, for example). Offer the version the code needs, as the lint target. Otherwise skip it. If an answer conflicts with what `floor-scan.php` or `php -l` shows the code needs, say so and ask again. If the user keeps the answer, or can't be reached, the code decides: `<current-floor>` is the version the code needs, and the conflict goes in the log's **Report items**. The header itself stays as it is, unless question 6 lowers the floor; add the mismatch or the missing field to the log's **Report items**.

### Second call: the result

5. **Layout.**
   - **Prefixed globals (Recommended):** `<Old\Namespace>\Admin\ImportPage` becomes `<PREFIX>_Import_Page` in `includes/admin/class-<prefix>-import-page.php`. Classic WordPress style.
   - **Keep namespaces:** the class becomes `<Old\Namespace>\Admin\Import_Page` in `includes/admin/class-import-page.php`. Fewer changes to references.
6. **Types.**
   - **Remove `strict_types`, keep types (Recommended):** working code can't break, because coercive mode accepts everything strict mode does.
   - **Keep everything:** `strict_types` and every type stay. Skip Phase 7.
   - **Lower the PHP floor:** also remove syntax newer than a target version, and ask for that version. The riskiest option: see `phase-7-coercive.md`.
7. **Ruleset.**
   - **Full `WordPress` (Recommended):** Core, Extra and Docs. Every file, class, function and property gets a docblock.
   - **`WordPress-Extra`:** Core plus best-practice sniffs, with no docblock requirement. Skip Phase 5.
   - **`WordPress-Core`:** formatting and naming only. Skip Phase 5.
8. **Autoloader.** Ask this when the plugin loads `vendor/autoload.php` at runtime. A hand-written PSR-4 autoloader can't find the new file names, so Phase 4 replaces it without asking. The choice is to keep the Composer autoloader, switching `composer.json` from `psr-4` to a `classmap` of `includes/`, or to replace it with the classmap autoloader from Phase 4. Recommend keeping it when the plugin has runtime Composer dependencies.

### Third call: the run

9. **Where to pause.** Multi-select: only where a decision comes up (Recommended), after Phase 2 to review the layout result, after Phase 3 to review renames, or after every phase.
10. **Docblocks in tests.** Only with the full ruleset. Leave tests undocumented (Recommended), or document them too, which drops the test excludes in the ruleset.
11. **`@since` tags.** Keep existing ones and add none (Recommended), or add `@since` with the current version to new docblocks. If tests get docblocks too, ask whether the tags go there as well.
12. **Downloads.** State what the test setup needs (for example WordPress, a database plugin, `wp-cli.phar`, Docker images), and ask whether to fetch it. Downloads go outside the plugin.

### Fourth call: bugs

13. **Bugs found during the run.** The conversion often uncovers existing bugs. A fix is a behaviour change, so the user decides:
    - **Ask about each one (Recommended):** stop, describe the bug, its impact and the fix, and ask "fix it" or "keep it and report it".
    - **Report only:** keep every bug, add a reasoned `phpcs:ignore` where a sniff flags it, and list it in the report.
    - **Fix security bugs, report the rest.** A security bug lets an attacker gain access or bypass a control. One that needs a non-default setting still counts, but ask before fixing it. Each fix is still listed as a behaviour change.

    A required step can remove a bug as a side effect. List that as a behaviour change, whichever option was chosen.

    Whichever is chosen, record each bug and its outcome in the log's **Report items**, and list fixes as behaviour changes in the final report. Commit each fix on its own, so it can be reverted alone.

## Placeholders

Use the answers wherever the instructions say:

| Placeholder | Value |
|---|---|
| `<PREFIX>` | the chosen prefix, uppercase, for classes and constants |
| `<prefix>` | the same prefix, lowercase, for functions and hooks |
| `<Old\Namespace>` | the plugin's root namespace |
| `<plugin-slug>` | the plugin folder name, from the code |
| `<domain>` | the text domain, from the code |
| `<package>` | the `@package` value: the old root namespace, or the plugin name in PascalCase if there is none |
| `<current-floor>` | the real floor settled above: the lowest PHP the code runs on, which may differ from a wrong `Requires PHP:` value |
| `<wp-floor>` | the `Requires at least:` value, or the version inferred above |
| `<standard>` | `WordPress`, `WordPress-Extra` or `WordPress-Core` |
| `<scratch>` | the directory for JUnit files, maps and other scratch output: `build/`, or `.wpcs/` if the plugin owns `build/` |
