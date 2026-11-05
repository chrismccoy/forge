# WordPress plugin: PSR-12, PSR-4 and strict types back to WPCS

Convert the WordPress plugin in the current directory from PSR-12, PSR-4 namespaces and `declare(strict_types=1)` to the WordPress Coding Standards (WPCS). Rename methods, functions, properties and variables to snake_case. Intake decides the exact result, so the user gets precisely the version they asked for:
- **Layout:** prefixed global classes in `includes/class-*.php` (the default), or namespaces kept with WordPress class and file names
- **Types:** remove `strict_types` and keep the types (the default), keep everything, or lower the PHP floor
- **Ruleset:** the full `WordPress` standard with docblocks (the default), `WordPress-Extra`, or `WordPress-Core`

Carry out the whole migration, not just a plan. Run from the plugin's root directory. Nothing visible from outside the plugin may change. Every phase ends with the full test suite, an assertion-count comparison, a commit and a tag.

`<skill-dir>` below is `${CLAUDE_PLUGIN_ROOT}/lib/wp-wpcs`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it.

## Intake (do this first)

Read `references/intake.md` in full and follow it before changing anything. It decides whether this procedure applies and what to look for in the code. It also covers using an earlier forward migration's records, the questions to ask the user in four `AskUserQuestion` calls, and the placeholders (`<PREFIX>`, `<prefix>`, `<Old\Namespace>`, `<plugin-slug>`, `<domain>`, `<package>`, `<current-floor>`, `<wp-floor>`, `<standard>`, `<scratch>`). Don't start Phase 0 until the user has answered every question. Record the answers in the log: every later phase depends on them.

## Decisions and approvals

The user decides every point below, so the result matches their exact parameters. Ask each one with `AskUserQuestion`, recommended option first and marked "(Recommended)", with the question written to stand on its own. Never decide for the user, and never reuse an answer given for another plugin. Record every answer in the log's **Intake** section, or under the phase it belongs to, and list them in the final report. If a new decision comes up that isn't listed here, ask it the same way and record it.

| When | Decision | Where |
|------|----------|-------|
| Intake | Prefix; released or not; test setup; PHP floor if missing or wrong | `references/intake.md`, first call |
| Intake | Layout; types; ruleset; autoloader | `references/intake.md`, second call |
| Intake | Where to pause; docblocks in tests; `@since` tags; what may be downloaded | `references/intake.md`, third call |
| Intake | How to handle bugs found during the run | `references/intake.md`, fourth call |
| Phase 3 | Public properties and methods of objects passed to hooks or documented: keep or rename | `references/phase-3-tier-b.md` |
| Phase 4 | Released names: eager or lazy aliases | `references/phase-4-flatten.md` |
| Phase 4 | Approve the class and file tree and naming calls | `references/phase-4-flatten.md` |
| Phase 4 | Each name that would start resolving after flattening (prefixed globals only) | `references/phase-4-flatten.md` |
| Phase 6 | Each real security hit, and any sniff fix that changes behaviour | `references/phase-6-lint.md` |
| Any phase | Each bug found in the plugin, security or not: fix it now or report it | `references/intake.md`, question 13 |
| Any phase | A test failure or assertion drop the phase can't explain | Hard rule 2 |
| Phase 8 | Installing a runtime for the PHP floor | `references/phase-8-verify.md` |
| Phase 8 | Whether to copy the finished plugin somewhere, and where | `references/phase-8-verify.md` |
| Any phase | Anything irreversible or outward-facing | Hard rule 6 |

## Hard rules

These apply in every phase.

1. **No behaviour change.** Leave every outward-facing name and output exactly as it is. That means option, meta and transient keys, REST routes, hook names and the text domain. It also means error codes, HTML output, JS config keys and shared global variables, plus names WordPress stored in the database: uninstall callbacks, and class *and property* names inside serialized objects. It also covers property names that reach output, and strings built from class names that are stored or shown. Keep an alias or wrapper for every stored name, even when intake says "not released". Details: `references/renaming.md`. Three kinds of change are allowed:
   - what intake chose for Phase 7: removing `strict_types`, which changes error paths only, or lowering the floor, which is listed in `references/phase-7-coercive.md`
   - the swaps `references/phase-6-lint.md` lists as provably identical
   - a narrow fix that either of those forces

   List each one in the final report.
2. **Prove each step.** After every phase:
   - run the full test suite with `--log-junit <scratch>/junit-<tag>.xml`, with `build/` listed in `.gitignore`. `.wpcs/` is the `<scratch>` when a release script empties `build/`.
   - compare the `assertions` attribute of every `<testcase>` with the previous file, using `scripts/junit-compare.php`, through the old-to-new test-name map in the log when tests were renamed. A test that disappeared counts as a drop.
   - investigate any drop

   If a failure or a drop can't be explained within the phase, stop. Report the failing tests and the diff, and wait for the user. Never change test expectations or golden files to make a failure go away. There are three exceptions:
   - a name this migration renames (Phases 3 and 4, or an old name removed because intake said "not released"). Update the tests that name it in the same commit, and record the old-to-new name in the log.
   - a test expecting a TypeError that only strict mode raised (Phase 7). Change it to assert the coerced result, and report it as a behaviour change.
   - a golden that holds machine-specific or core-version output: fix its mask, and change nothing else.

   List every test change under an exception in the final report.
3. **Never rename by blind find-and-replace.** Rename by tokens, in the exact positions listed in `references/renaming.md`, then grep for the old name and review every hit by hand. Rename only the plugin's own names. Never rename overrides of core, WP-CLI or third-party methods, PHP built-in interface methods, magic methods, test-framework hooks called by name, or properties of objects the plugin doesn't define. Give each kept name a reasoned `phpcs:ignore`. Check for names built at runtime before renaming.
4. **Translatable strings stay one literal.** Never split or concatenate the string inside `__()`, `_e()`, `esc_html__()` and similar. Never change the text of a `/* translators: */` comment, or move it away from its call.
5. **Keep the PHP floor,** unless intake chose to lower it. Set `testVersion` to `<current-floor>-`. Leave `Requires PHP:` and the `php` requirement in `composer.json` as they are. Don't remove type declarations: removing a scalar type changes how values are coerced. If the code needs a newer PHP than the header claims, intake settles which version to lint against; the header stays as it is and the mismatch goes in the log's **Report items**.
6. **Ask before** anything irreversible or outward-facing. Never push.
7. **Keep a progress log.** Keep `WPCS_MIGRATION_LOG.md` in the plugin root and list it in `.git/info/exclude`. After every commit, record:
   - the phase and step, and the last tag
   - the test and assertion totals, and the violation count
   - the old-to-new name map
   - any open issues or decisions

   Keep a **Report items** section and add to it whenever a phase file says to report something. The final report is written after the context has been summarized, so anything not in the log is lost. On resume, or after the context is summarized, read the log and `git tag --list 'wpcs-*'` first, and continue from the last tag.
8. **Leave no trace of the conversion.** Comments, docblocks, `phpcs:ignore` reasons, READMEs, test names and test file names describe the code as it is now. They never mention the conversion, its phases, PSR-12, old names or "safety nets". A stored-name comment says `Stored in the database.`, not what the name used to be. Comments already in the plugin stay, except that class and method names in them follow the rename. Alias maps, their tests and README text about compatibility aliases must name old classes, and those are the only exception. Phase 8 checks this.
9. **Tag every phase** for rollback: `wpcs-v0-baseline`, `wpcs-v1-safety-net`, `wpcs-v2-tier-a`, `wpcs-v3-tier-b-<step>` for each Phase 3 step that changes something, `wpcs-v4-flatten`, `wpcs-v5-docs`, `wpcs-v6-lint-zero`, `wpcs-v7-coercive`, `wpcs-v8-verified`. A phase that intake skipped gets no tag. The `wpcs-` prefix keeps them apart from an earlier `/wp-modernize` run's tags.

## Phases

Before starting each phase, read its reference file in full. Each file holds the exact steps, commands and pitfalls for that phase. Skip Phase 5 unless the ruleset is the full `WordPress` standard, and skip Phase 7 if intake chose to keep everything; record each skip in the log.

| Phase | Result | Tag | Read first |
|-------|--------|-----|------------|
| 0. Baseline | Git repo, dev environment, tests green before any change | `wpcs-v0-baseline` | `references/phase-0-baseline.md` |
| 1. Safety net | The chosen ruleset, wiring tests, golden copies of HTML and post output | `wpcs-v1-safety-net` | `references/phase-1-safety-net.md` |
| 2. Tier A | `phpcbf` layout fixes (tabs, `array()`, spacing), proved layout-only by a token-stream diff | `wpcs-v2-tier-a` | `references/phase-2-tier-a.md` |
| 3. Tier B | camelCase methods, properties and variables to snake_case, one class or group at a time | `wpcs-v3-tier-b-<step>` | `references/phase-3-tier-b.md`, `references/renaming.md` |
| 4. Flatten | WordPress class and file names in `includes/`, prefixed globals or namespaces kept; tree approved by the user | `wpcs-v4-flatten` | `references/phase-4-flatten.md`, `references/renaming.md` |
| 5. Docs | Full ruleset only: docblocks for every file, class, function and property, proved comment-only | `wpcs-v5-docs` | `references/phase-5-docs.md` |
| 6. Lint to zero | Yoda, Extra sniffs, reasoned ignores, `.pot` checked | `wpcs-v6-lint-zero` | `references/phase-6-lint.md`, `references/renaming.md` |
| 7. Coercive | As intake chose: `strict_types` removed with types kept, or the floor lowered | `wpcs-v7-coercive` | `references/phase-7-coercive.md` |
| 8. Verify | Lint, tests, golden copies, unchanged names, run on the PHP floor, smoke test, upgrade test, final report | `wpcs-v8-verified` | `references/phase-8-verify.md` |

Phase 4 pauses for the user to approve the proposed `includes/` tree. Other phases pause only where intake chose a pause, or where a decision above comes up. The final report's contents are listed in `references/phase-8-verify.md`.

## Additional resources

### Reference files
- **`references/intake.md`**: applicability, code checks, user questions, placeholders
- **`references/renaming.md`**: stored names, rename positions, names never to rename
- **`references/phase-<n>-*.md`**: one file per phase, as the Phases table lists

### Scripts

All scripts need PHP 8.1 or later, and each one's header explains its arguments.

- **`scripts/token-proof.php`**: proves a change altered layout or comments only (Phases 2, 5, 7)
- **`scripts/junit-compare.php`**: compares per-test assertion counts between two JUnit files (Hard rule 2)
- **`scripts/unresolved-names.php`**: finds class names that resolve to nothing in namespaced code (Phase 4)
- **`scripts/snake-case.php`**: scans for and applies snake_case renames by tokens, and flags names PHP classes also define (Phase 3)
- **`scripts/floor-scan.php`**: lists syntax and functions newer than a target PHP version, which PHPCompatibility 9 misses (Phase 7)
- **`scripts/add-ignores.php`**: places reasoned ignores from a rules file (Phase 6)
- **`scripts/yoda.php`**: swaps the operands of reported Yoda conditions by tokens (Phase 6)
- **`scripts/flatten.php`**: removes namespaces and rewrites class references and docblock types by tokens from a map file (Phase 4)
- **`scripts/docblocks.php`**: lists the docblock descriptions needed, then places hand-written ones (Phase 5)
- **`scripts/surface.php`**: lists a plugin tree's outward-facing names, so Phase 8 can prove none of them changed
