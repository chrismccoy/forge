# Phase 2: Tier A (WPCS layout only)

Goal: WPCS layout (tab indentation, long `array()` and `list()` syntax, spaces inside parentheses, `elseif`, short casts), with a proof that no code changed.

**Two fixers change content, not layout. Deal with both first:**
- `WordPress.WP.I18n` rewrites translatable strings (`%d of %d` becomes `%1$d of %2$d`), which changes the msgid and breaks existing translations. Always run `phpcbf` with `--exclude=WordPress.WP.I18n`. Phase 6 handles the reports.
- `Generic.WhiteSpace.DisallowSpaceIndent` and `Universal.WhiteSpace.PrecisionAlignment` rewrite inline HTML, including inside `<pre>` and `<script>` blocks, where indentation is content. Find every file that holds these blocks, classes included (`git grep -l -E '<(pre|script|textarea)\b' -- '*.php'`). Add a scoped `exclude-pattern` for those two sniffs and files to the ruleset, with a comment saying why. The exclude covers the whole file, so its PHP stays space-indented and a plain `--standard` run still reports it: in Phase 6, re-indent by hand only lines inside `<?php ... ?>` that sit outside those blocks, and only in a class or code file, not a template. Inline HTML lines stay exactly as they are, and appear in the plain count (Hard rule 1 wins). List every excluded file in the log's **Report items**. Phase 4 moves files, so it must update these paths.

- Run `vendor/bin/phpcbf --exclude=WordPress.WP.I18n` until only reports from excluded sniffs stay marked fixable. Several passes are often needed, because the WordPress array and alignment fixers interact.
- Don't fix anything by hand in this phase. Non-fixable reports wait for Phases 3 to 6.

## Prove the change is layout only

Run `php <skill-dir>/scripts/token-proof.php HEAD`. It runs `token_get_all` on the old version of each changed file and on the new one, normalizes both streams, and compares them. To trust it the first time, plant a real change (`===` to `==`), confirm it reports `CODE DIFF`, and revert. It applies these rules:
- drop whitespace tokens, and collapse whitespace inside inline HTML. Exception: compare the inline HTML inside `<pre>`, `<textarea>` and `<script>` elements byte for byte, and compare heredoc and nowdoc bodies byte for byte.
- trim trailing whitespace from `T_OPEN_TAG` and `T_CLOSE_TAG`, which carry the newline after `<?php` and `?>`
- rewrite `array(...)` and `list(...)` to `[...]` by matching brackets. Clear the "pending array" flag on any token that isn't `(`, because `array` is also a parameter type.
- drop a trailing `,` directly before the closing bracket of an array (`WordPress.Arrays.CommaAfterArrayItem` adds them)
- drop a `;` directly before a `T_CLOSE_TAG` (`Squiz.PHP.EmbeddedPhp` adds them; `?>` already ends the statement)
- compare `T_CONSTANT_ENCAPSED_STRING` tokens by value, not by spelling, so `"foo"` equals `'foo'` (`Squiz.Strings.DoubleQuoteUsage`). Decode single-quoted strings by unescaping only `\'` and `\\`. Decode double-quoted ones with PHP's escape rules: `stripcslashes()` is close, but check `\$` and `\u{...}` by hand if they appear.
- compare keywords, type names and `true`/`false`/`null` case-insensitively
- map long cast forms to short ones: `(integer)` to `(int)`, `(boolean)` to `(bool)`, `(double)`/`(real)` to `(float)`
- treat `new X` and `new X()` as equal, and `else if` and `elseif` as equal
- treat a standalone `$x++;` and `++$x;` as equal, and likewise for `--` (`Universal.Operators.DisallowStandalonePostIncrementDecrement`). "Standalone" means the result is unused: the whole statement, or the third expression of a `for`.
- sort runs of modifier tokens (`public`, `protected`, `private`, `static`, `abstract`, `final`, `readonly`) before comparing
- ignore a final `T_CLOSE_TAG` at the end of a file
- ignore a leading `\` in `use` statements
- treat `dirname( __FILE__ )` and `__DIR__` as equal (`Modernize.FunctionCalls.Dirname`)
- compare comments with whitespace collapsed and a single trailing `.` ignored. WordPress-Docs fixers edit comment text, and comment text is not code, so a remaining comment-only difference is allowed. Two parts of comments must still match exactly: `phpcs:` directives, and these docblock annotations: `@runInSeparateProcess`, `@runTestsInSeparateProcesses`, `@preserveGlobalState`, `@backupGlobals`, `@dataProvider`, `@depends`, `@group`, `@covers`, `@requires`, `@ticket`, `@expectedDeprecated`, `@expectedIncorrectUsage`. Compare their set per docblock.

After that normalization, there should be no differences. `phpcbf` also rewrites indentation in inline HTML, which the whitespace rule above absorbs. Two kinds of difference can be reviewed by hand and accepted:
- braces added around a single-statement control-structure body (`Generic.ControlStructures.InlineControlStructure`)
- comment-only changes as described above

Any other difference: revert that file's fix and investigate (Hard rule 2).

Run the tests (Hard rule 2), commit and tag `wpcs-v2-tier-a`, and update `WPCS_MIGRATION_LOG.md`. Record the violation count after the fix in the log.
