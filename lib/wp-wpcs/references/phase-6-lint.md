# Phase 6: Lint to zero

Goal: `composer lint` at 0 errors and 0 warnings against `<standard>`, with the rendered output and the translatable strings unchanged.

Read `renaming.md` in full first: the naming leftovers below follow its rules.

Work through `phpcs --report=source`, one sniff at a time, from most reports to fewest. For every report, either make a change that is provably identical, or add a scoped `phpcs:ignore` with a reason. **Never make a change that alters behaviour to satisfy a sniff** (Hard rule 1). Name the sniff in every ignore, and never use a `phpcs:disable` without sniff names.
- Put an ignore at the end of the flagged line, or on the line before. On a line with inline HTML after `?>`, put it before the `?>`, or the comment prints into the page.
- An ignore on a known, reported bug says so: `Existing behaviour, kept.` Never word it as a false positive.
- For a function signature, use the end of the line: a comment between a docblock and its function breaks the Docs sniffs.
- If the line already has a `phpcs:ignore` for another sniff, add to that comment. A second comment doesn't work.

Whatever the ruleset, run `vendor/bin/phpcs --sniffs=WordPress.Security.ValidatedSanitizedInput --standard=WordPress --extensions=php --ignore=vendor,node_modules,tests,build .` once as a read-only audit, and apply the `$_SERVER` check in the `WordPress.Security.*` bullet below to each hit. `WordPress-Extra` and `WordPress-Core` don't include that sniff, so a real bug can pass unreported.

## Changes that are provably identical

Make these, and list each kind with its count in the log's **Report items**:
- **Yoda conditions** (`WordPress.PHP.YodaConditions`). Run `vendor/bin/phpcs -q --report=json --sniffs=WordPress.PHP.YodaConditions > <scratch>/yoda.json`, then `php <skill-dir>/scripts/yoda.php <scratch>/yoda.json`. `yoda.php` prints `CHECK` for every non-plain operand it swapped: read those lines. It prints `HAND` for every comparison it left alone: fix those by hand. A non-zero exit means it skipped a file: read the error. Swap the operands of `==`, `===`, `!=` and `!==` when one side is a literal or a constant. Comparison is symmetric and a literal has no side effects. Only swap when the other side is a plain variable, property or array element. When it's a function call, the order doesn't matter either, but check the line by hand.
- **`date()` to `gmdate()`** (`WordPress.DateTime.RestrictedFunctions`). WordPress sets the PHP default timezone to UTC in `wp-settings.php`, so the two return the same value in plugin code. Check that no plugin code calls `date_default_timezone_set()`. If it does, ignore with the reason instead.
- **`parse_url()` to `wp_parse_url()`**, only when the input is an absolute URL with a scheme. For path-only and protocol-relative input, the wrapper takes a different route: ignore with the reason instead.
- **Short ternary** (`Universal.Operators.DisallowShortTernary`). Rewrite `$a ?: $b` as `$a ? $a : $b` only when `$a` is a plain variable, property or array element with no side effects. Otherwise ignore with the reason `expression must be evaluated once`.
- **Assignments in conditions** (`Generic.CodeAnalysis.AssignmentInCondition`, `WordPress.CodeAnalysis.AssignmentInTernaryCondition`). Move the assignment to the line before only when the condition is evaluated once (an `if`, not a `while`), and nothing between would change it. In loops, ignore with a reason.
- **Multiple assignments** (`Squiz.PHP.DisallowMultipleAssignments`). Split `$a = $b = 0;` into two statements, right to left, and `return $this->x[ $k ] = $v;` into the assignment and then `return $this->x[ $k ];`, unless the property has magic access.

## Changes to ignore with a reason

These sniffs ask for a different function or comparison that can behave differently. Keep the code, and add a `phpcs:ignore` with the reason:
- `WordPress.PHP.StrictComparisons` (`==` to `===`) and `WordPress.PHP.StrictInArray`. Change one only when every value that can reach it provably has the same type, for example two values both cast with `(int)` just before. Otherwise ignore with the reason `loose comparison kept, <what types reach it>`.
- `WordPress.WP.AlternativeFunctions`:
  - `strip_tags` to `wp_strip_all_tags`: the wrapper also removes `<script>` and `<style>` contents and trims
  - `json_encode` to `wp_json_encode`: the wrapper handles invalid UTF-8 differently
  - `rand` and `mt_rand` to `wp_rand`
  - `file_get_contents` and the `curl_*` functions to the HTTP API
  - `fopen`, `fwrite` and the other file functions to `WP_Filesystem`
- `MissingUnslash` on `$_POST` values that get stored is a real data bug: `O'Brien` is saved as `O\'Brien`. Handle it as intake question 13 says.
- `WordPress.WP.I18n.UnorderedPlaceholders*`: numbering the placeholders changes the msgid, so existing translations stop matching. Ignore with that reason, or ask the user if they want the change.
- `WordPress.DB.DirectDatabaseQuery` (`DirectQuery`, `NoCaching`, `SchemaChange`): adding object caching changes behaviour
- `WordPress.WP.EnqueuedResourceParameters` (missing `ver` or `in_footer`): adding them changes the HTML
- `WordPress.PHP.DiscouragedPHPFunctions.obfuscation_base64_*`, `WordPress.PHP.IniSet.Risky` and `Generic.CodeAnalysis.UnusedFunctionParameter` on a callback signature
- `WordPress.PHP.DevelopmentFunctions` (`error_log`, `print_r` in the plugin's own logger), `WordPress.PHP.NoSilencedErrors`, `WordPress.PHP.DontExtract`
- `WordPress.NamingConventions.PrefixAllGlobals` for hook names, shared global variables and option names that already exist: renaming them is outward-facing (Hard rule 1). A variable that nothing outside its file reads is different: rename it with the prefix. That covers file-scope variables in `uninstall.php`, which core includes from inside a function, and in the main file.
- `WordPress.NamingConventions.ValidHookName` for existing hook names with uppercase letters or other separators
- `WordPress.Security.*` hits. A plugin converted by an earlier `to-modern` run should have few; others can have many. Read each one in context. A real one is a bug: handle it as intake question 13 says. Ignore false positives with the reason, for example `IN (%s,%s)` placeholders built with `array_fill`, or a `$_SERVER` value that can't hold a quote or backslash and is only compared, hashed or validated, never output. **A `$_SERVER` value that can hold them is not a false positive.** `wp_magic_quotes()` adds slashes to `$_SERVER`, so an `If-Range` or `If-None-Match` ETag (`"abc"`) arrives as `\"abc\"` and never matches. Check each such value through a real HTTP request, because PHPUnit doesn't slash `$_SERVER`: start the dev site for it now, or add it to the Phase 8 flows and record it in the log. If it misbehaves, it is a bug: handle it as intake question 13 says. Adding `wp_unslash()` changes behaviour either way, so never add it just to quiet the sniff.

## Many reports of one kind

When one false positive repeats across a whole area, scope it once instead of adding dozens of comments, and give the reason in a comment:
- in the ruleset: `WordPress.DB.DirectDatabaseQuery` for a plugin that owns its tables, `ExceptionNotEscaped` if no exception message is printed unescaped, `PrefixAllGlobals` for templates (they run in method scope), and PHPCompatibility 9 sniffs for enums, which it predates
- list custom capabilities under the `custom_capabilities` property of `WordPress.WP.Capabilities`
- for interpolated table names, one `phpcs:disable` naming the sniffs, above the class docblock (a comment between that docblock and the class breaks the Docs sniffs)
- for a class that checks nonces in its own helper method, a file `exclude-pattern` for `WordPress.Security.NonceVerification`: `customNonceVerificationFunctions` doesn't match `$this->` calls. Read that the helper runs on every path first

Parse `phpcs` output with `-q --report=json`: without `-q` the ruleset's progress dots corrupt the JSON, and CSV escaping breaks on messages with commas. Add a `/* translators: */` comment for `MissingTranslatorsComment` rather than an ignore: it adds to the `.pot` and changes no msgid. Give it its own line above a call that starts a line, or `PEAR.Functions.FunctionCallSignature` reports it.

To place many ignores, write a rules file and run `php <skill-dir>/scripts/add-ignores.php <report.json> <rules.json> --dry-run`, then without the flag. Each `NO RULE` line is a report still to fix or to reason about.

## Naming leftovers

Fix any remaining `ValidFunctionName`, `ValidVariableName`, `NoReservedKeywordParameterNames` or `FileName` reports the same way as in Phases 3 and 4, with tests in the same commit. A parameter rename also changes named-argument callers. For reserved words, add a noun: `$class_name`, `$default_value`, `$return_output`. These count as Phase 3 or 4 renames under the Hard rule 2 exception.

## Templates

WPCS has no line-length limit, so templates don't need wrapping. Only fix the reports inside `<?php ... ?>` blocks: spacing, `echo` escaping (see the security bullet), and missing semicolons. Never add or remove whitespace between inline elements. The golden tests must pass unchanged. Don't regenerate the golden files in this phase.

## Translations

Regenerate the `.pot`:
```
wp i18n make-pot . languages/<domain>.pot --slug=<plugin-slug> --exclude=vendor,node_modules,tests,build
```
- Use the global `wp` or the sandbox's `wp-cli.phar`, whichever exists, and create `languages/` if it's missing. Commit the `.pot`. Leave the header's `Domain Path` as it is, and add a missing one to the log's **Report items**.
- Make a worktree of `wpcs-v0-baseline` outside the plugin (for example `git worktree add ../<plugin-slug>-wpcs-v0 wpcs-v0-baseline`), extract a `.pot` from it the same way (with the same `--slug`, after `mkdir languages`), and diff the sorted lists from the command below. They must be identical. It joins wrapped strings, which a plain `grep '^msgid'` shows as `msgid ""`:
  ```
  awk '/^msg(ctxt|id|id_plural) /{if(f)print s;f=1;s=$0;next} f&&/^"/{s=s $0;next} {if(f)print s;f=0}' <file>.pot | LC_ALL=C sort
  ```
  Don't diff against the old committed `.pot`; it may be stale. Keep the baseline `.pot` in `<scratch>` for Phase 8, and remove the worktree afterwards with `git worktree remove --force`.
- Check that each `translators:` comment in the baseline `.pot` is still there, with the same text. New ones from this phase are fine.
- make-pot reads only one plugin header per folder. With several plugins in one folder, the other headers' strings are missing from both `.pot` files. Add it to the log's **Report items** rather than working around it.

Autoloader code from Phase 4 can leave fixable alignment reports: run `phpcbf --exclude=WordPress.WP.I18n` at the start of this phase, with the token proof.

Run the tests (Hard rule 2), commit and tag `wpcs-v6-lint-zero`, and update `WPCS_MIGRATION_LOG.md`.
