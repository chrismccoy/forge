# WordPress plugin documentation pass

Do a documentation-only pass over every PHP and JavaScript file in the target plugin: full PHPDoc / JSDoc on every file, class, constant, property, method, function and closure (see **Coverage** in `references/rules-core.md` for the exemptions), plus inline comments where the logic is non-obvious. Rewrite existing comments that are wrong, vague or below this standard, and keep everything on the **Preserve** list exactly. **Code must not change at all**, and you must prove that mechanically before reporting. Some comments are code (WP-CLI help text, PHPUnit annotations, lint directives, bundler hints), so the proof covers them too.

`<skill-dir>` below is `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-doc-pass`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it. `<scratchpad>` is the session's scratch directory (or a new temporary folder outside the plugin when there is none). Nothing from this pass except comments is ever written inside the plugin.

## Files in this folder

- `references/rules-core.md`: the **Hard rule**, **Failure protocol** and **Universal rules** (coverage, content, hooks, templates, **Preserve**, inline comments). Read it in full before step 1's frozen scan.
- `references/profile-a-wpcs.md`, `references/profile-b-psr.md`, `references/profile-c-legacy.md`: the PHP coding-standard profiles. Read only the one that step 1 chooses.
- `references/javascript.md`: the JavaScript rules. Read it when JS is in scope.
- `references/agent-verification.md`: what each agent checks on its own files. Agents get it through `rules.md`; read it yourself before step 4.
- `references/checker-spec.md`: the checker's specification. Read it only when you must write or debug a checker.
- `scripts/checker/`: the reference checker (`verify.mjs`, `coverage.mjs`, `lib.mjs`, `php-tokens.php`, `package.json`).

## 0. Intake (only when no path is set)

The target is the plugin path the user gave. If they gave none, or the path does not exist, do not guess. Collect these with `AskUserQuestion`, one question at a time:

1. **Plugin path** (required). If the current working directory contains a WordPress plugin header (a `*.php` file with `Plugin Name:`), offer it as the first, recommended option. Also offer any plugin folders found one level down. The user can type another path through "Other". Confirm that the path exists and contains a plugin header. If it doesn't, say so and ask again.
2. **Scope** (multi-select): `Plugin PHP (src, root, views/templates)`, `JS assets (JSDoc)`, `Tests / test harness`. Default is all three.
3. **Bug report** (single-select): `Report bugs/smells found, don't fix (Recommended)`, `Skip bug report`.

Skip any question whose answer was already given in the request (e.g. "php-only" means scope = PHP). Then continue with step 1 using the chosen path and scope.

## 1. Discover

- **Git state.** If the plugin is inside a git repository, run `git status --porcelain` on it. If any in-scope file has uncommitted changes, ask the user once whether to continue (recommend committing or stashing first, so `git diff` shows only this pass). Note the result for the report.
- List every `*.php`, `*.inc`, `*.phtml`, `*.js`, `*.jsx`, `*.mjs`, `*.cjs`, `*.ts` and `*.tsx` file. Skip `vendor/`, `node_modules/`, `build/`, `dist/`, minified files (`*.min.js`), generated bundles (anything a build step writes from a `src/` directory: document the source, never the output), `.git/`, and dotfile tool folders.
- Read the main plugin file header. Take the `Version`, the `Text Domain`, and a package name for `@package` (the namespace root, or the plugin name in StudlyCaps or Words_With_Underscores to match the code).
- Read `readme.txt` (its changelog), `phpcs.xml(.dist)` / `.phpcs.xml(.dist)`, `.editorconfig`, `.php-cs-fixer*`, `phpstan.neon*`, `psalm.xml`, `phpunit.xml*`, `composer.json`, `package.json`, `.eslintrc*` / `eslint.config.*`, `.prettierrc*` and `tsconfig.json`.
- **Find the minimum PHP version** from the `Requires PHP` header, `composer.json` `require.php`, or the syntax in use. This decides which type notation is allowed (see the profiles).
- **Choose the coding-standard profile** (A, B or C), using these rules in order:
  1. The phpcs ruleset references `WordPress`, `WordPress-Core`, `WordPress-Extra` or `WordPress-Docs` as the *style* standard: **profile A (WPCS)**. If it only pulls in `WordPress.Security.*` / `WordPress.WP.I18n` sniffs and uses `PSR12` / `PSR2` for style, it is profile B.
  2. The ruleset uses `PSR12` / `PSR2` / `PSR1`, or php-cs-fixer uses `@PSR12` / `@PER-CS` / `@Symfony`: **profile B (PSR)**.
  3. No ruleset at all: infer from the code. Tabs, snake_case functions, `array()` / spaces inside parentheses, and `Class_Name` naming mean profile A. Spaces, camelCase methods, namespaces and PSR-4 layout mean profile B. A mixed or inconsistent codebase, or older code with no clear convention, means **profile C (legacy / no standard)**.
  4. If the signals clearly conflict (e.g. a WPCS ruleset but PSR-formatted code), ask the user once with `AskUserQuestion` and recommend the one the ruleset enforces.

  Then read `references/rules-core.md` and the chosen profile file.
- Do the same for JS: `@wordpress/eslint-plugin` / `@wordpress/scripts` mean WordPress JS docs. Other ESLint configs (airbnb, standard, typescript-eslint) mean plain JSDoc, or TSDoc for TypeScript. With no config, match the code. Note whether the JS is ES5 + jQuery, modern ES modules, React/JSX, or TypeScript. When JS is in scope, read `references/javascript.md`.
- **Choose the `@since` policy.** `@since` records when code was *introduced*, so never invent history:
  1. A `@since` already in a docblock stays as it is.
  2. Otherwise, if the plugin is in git and has version tags, find the first tag that contains the symbol (`git log -S '<function or class name>' --reverse --format=%H -- <file>` on the first commit, then `git tag --contains <commit> --sort=v:refname | head -1`). The `readme.txt` changelog is an equal source only when the entry names the symbol itself being added; an entry about a parameter or option does not date the function. An entry that dates a class also dates its members, unless git history shows a member was added later.
  3. Otherwise, under profiles A and C, ask the user once: `Use current Version <x> for undated code` or `Omit @since where unknown`. Profile B never asks: it omits `@since` unless the project already uses it (see profile B).

  Under profile A, write new versions with three parts (`1.0.0`). Under profiles B and C, write new versions in the form the project already uses. Never change an existing value, even when it looks wrong (for example, higher than the current Version); list it in the report instead.
- **Find comments that are code.** Scan every in-scope file and list each comment in the **Frozen** class (see **Preserve** in `references/rules-core.md`), with `file:line`. This list goes into the rules file, and the checker enforces it.
- **Build the hook map.** List every `apply_filters` / `apply_filters_ref_array` / `do_action` / `do_action_ref_array` call by hook name. For a hook fired in more than one place, choose the file that gets the full docblock: the existing documented one, or else the first firing in the main code path (prefer `src/` / `includes/` over templates and tests). Every other firing gets the `This filter/action is documented in …` line. A WordPress core hook fired by the plugin or its tests (for example `do_action( 'rest_api_init' )` in a test) gets only the `This action is documented in wp-includes/…` line that points to core.
- **List shared JS shapes.** Find localized config objects (`wp_localize_script` / `wp_add_inline_script`), block attribute sets (`block.json`) and data records used in more than one JS file. Choose one file per shape to hold its `@typedef`; the others reference it by name or `import('./file').Name`.
- Find the test commands (composer scripts, package.json scripts, `tests/`). If the tests are included in scope, document them too.
- **Plan the groups.** Split the files into disjoint groups by directory or module, at most 7, balanced by line count. Aim for 500–900 lines per group; when the plugin is larger than 7 × 900 lines, keep 7 groups and balance them, and the limit of 7 wins. If the whole scope is under about 900 lines, do it in the main session with no agents.
- Show the user the file list with line counts, the detected profile with its evidence (one line), the minimum PHP version, the `@since` policy, the frozen comment count, the hooks fired more than once, and the planned groups. If intake did not run and the scope looks wrong, ask once (e.g. "include tests?"). Otherwise proceed.

## 2. Safety net (before any edit)

- Copy all in-scope files to `<scratchpad>/orig/` with the directory structure kept.
- Run the test suites and record the baseline pass, fail and skip counts. If they already fail, note it and continue. If they cannot run at all (missing tools or dependencies), say so; step 4 then skips the test comparison. If running them needs dependencies or a sandbox that would write into the plugin or next to it, run them in a copy under `<scratchpad>` instead, and run the same copy again in step 4 with the documented files. Do the same, or turn caching off (e.g. `--do-not-cache-result`), when a run would leave cache files such as `.phpunit.result.cache` in the plugin.
- If PHPStan or Psalm is installed and configured, run it and save the error count per identifier (or per message when there are no identifiers).
- **phpcs baseline:** if `vendor/bin/phpcs` (or a global `phpcs` with the needed standards installed) exists, run it with the project ruleset and `--report=json`, and save the counts per `(file, source)` pair (`source` is the sniff code, e.g. `Squiz.Commenting.FunctionComment.Missing`). Line numbers move when comments are added, so never compare by line. For profile C, or when there is no ruleset, skip this and say so.
- **Write the rules file** `<scratchpad>/rules.md`, once. Build it by concatenating the reference files verbatim, never by retyping them, so every agent works from the exact same text:

  ```sh
  for f in rules-core.md PROFILE_FILE javascript.md agent-verification.md; do
    cat "<skill-dir>/references/$f"; echo
  done > "<scratchpad>/rules.md"
  ```

  Replace `PROFILE_FILE` with the one chosen profile file (`profile-a-wpcs.md`, `profile-b-psr.md` or `profile-c-legacy.md`). Under profile C, when no file in the plugin has docblocks to copy conventions from, add `profile-a-wpcs.md` after it, because profile C falls back to A. Leave out `javascript.md` when JS is not in scope. Then append: the absolute path that `<scratchpad>` stands for (agents need it to find `<scratchpad>/orig/` in the Failure protocol); the plugin facts (package name, `@since` policy and value, text domain, minimum PHP version, indentation, line limit); the frozen comment list; the hook map; and the shared JS shapes. Agents read this file. Never retype or summarize the rules in agent prompts.
- **Set up the checker.** Copy `<skill-dir>/scripts/checker/` (`verify.mjs`, `coverage.mjs`, `lib.mjs`, `php-tokens.php`, `package.json`) into `<scratchpad>/checker/`, make the copy writable (`chmod -R u+w`, since the installed plugin folder may be read-only), and run `npm install` there. Never install into `<skill-dir>` or the target plugin. If the bundled checker is missing, write one into `<scratchpad>/checker/` following `<skill-dir>/references/checker-spec.md`.

  `node <scratchpad>/checker/verify.mjs <orig-dir> <current-dir> [files…]` runs three checks on each file: the **code** check (PHP tokens / JS AST identical), the **layout** check (no reformatting), and the **comment-is-code** check (Frozen comments and tag lines identical, Kept tag lines still present, header fields unchanged). It prints `CODE CHANGED`, `LAYOUT CHANGED` or `FROZEN COMMENT CHANGED` lines, or `OK: N files, code identical`, and exits non-zero on any failure. Its Babel parse is also the syntax check for `.jsx`, `.ts` and `.tsx` files: a file that fails to parse is reported as `CODE CHANGED: <file>: parse error …`.
- **Test the checker before trusting it.** In a scratch copy of a few in-scope files:
  - Change one operator: it must be flagged (code check).
  - Add only a comment and a blank line next to it: it must pass.
  - Re-indent one code line, and separately join two code lines: each must be flagged (layout check).
  - If there are templates, add a blank line to the HTML outside the PHP tags: it must be flagged.
  - If the frozen list is not empty: delete one frozen tag line, move one frozen comment one statement down, and add a new `phpcs:ignore` (or `eslint-disable-next-line`) comment: each must be flagged.
  - If there are JSX or TSX files: one must parse and pass unchanged.
  - Skip any case the plugin has nothing to test with, and say which ones you skipped.
  - Fix the checker until every case behaves as stated before you continue. This self-test is the only time the checker may change; once editing starts, the **Failure protocol** forbids it.

## 3. Document (parallel agents)

Launch one general-purpose agent per group, all in a single message. Give each agent:

- its exact file list;
- the path to `<scratchpad>/rules.md`, with the instruction to read it in full before editing;
- the verify command, run on its own files only;
- its own scratch folder, `<scratchpad>/agent-<n>/`, for any helper scripts.

Tell it to read collaborators read-only when it needs types or callers, and to report code smells **without fixing them**. With no agents (a small plugin), read `<scratchpad>/rules.md` yourself and do the same work in the main session.

## 4. Final verification (main session)

After all agents finish:

1. Run `verify.mjs` over the whole tree. All three checks must pass for every file. If not, apply the **Failure protocol** yourself.
2. Syntax-check everything as in **Agent verification**.
3. Rerun the test suites. The pass, fail and skip counts must equal the baseline. If the suites could not run in step 2, say so in the report instead.
4. **Coverage scan.** Run `node <scratchpad>/checker/coverage.mjs <plugin> [--no-since] [files…]`. Pass `--no-since` when the `@since` policy omits it, and pass the in-scope files (relative to `<plugin>`) when the scope is partial, so out-of-scope files are not counted as gaps. It must print `OK: N files fully documented` and exit 0; otherwise it prints `MISSING …` lines and `GAPS: n`. Files left undocumented under the Failure protocol are listed separately, not counted as passes.
5. Check line lengths against the project limit (profile A usually has none for comments, but keep them around 100–120 for readability). Rewrap any overlong doc paragraphs, and watch for awkward breaks inside quoted text.
6. Grep for `@return` / `@param` types that reference undefined PHPStan / Psalm aliases or classes that don't exist, and fix the comments.
7. **Check style consistency:** spot-check one file per agent group and confirm every group used the same profile conventions (voice, `@return void`, type notation, tag order). Check that each multi-fire hook has exactly one full docblock and each shared `@typedef` exists once. Fix any drift.
8. Run phpcs (project ruleset) and compare with the baseline per `(file, source)`: no new violations, and comment sniffs reduced. Run ESLint if it is installed. Rerun PHPStan / Psalm if step 2 recorded a baseline and compare per identifier: fix any new error caused by a wrong docblock type in the comment, and list the rest (including errors on a correct type that only appear because WordPress stubs are missing). Say which tools were not available.

## 5. Report

- Detected profile with its evidence, the minimum PHP version, and the `@since` policy used.
- Git state at the start, and how to review the change (`git diff --stat`, then `git diff`), or the scratchpad backup path when there is no git.
- Files documented, grouped by area, and any files left undocumented with the reason.
- Verification results: the three checker checks, lint, tests before and after, the coverage scan, phpcs before and after (counts), and which tools were not run. Include the number of frozen comments the checker protected.
- Annotation fixes made, such as a broken type alias.
- Unless intake chose `Skip bug report`: a ranked, de-duplicated list of the **bugs and code smells the agents found**, with `file:line`, a one-line problem and a one-line fix. Lead with security issues (missing nonce or capability checks, unescaped output, unprepared SQL) and race conditions. Then deprecated WordPress or PHP APIs for the minimum versions. Do **not** fix them. Ask the user which ones to fix.

If the user then asks for fixes: add a regression test for each one, and confirm it **fails against the original code** in a scratch copy and passes against the new code. Watch for async tests that hang and make the runner exit 0. If the plugin has no test harness, say so and propose the smallest one before writing fixes. Update the README / `readme.txt` where behavior changes.
