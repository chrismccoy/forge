# Phase 5: Lint to zero

Goal: `composer lint` at 0 errors and 0 warnings, with the rendered output and the translatable strings unchanged.

## Lines over 120 characters

- Wrap function arguments and ternaries.
- Split long *non-translatable* literals with `.` concatenation.
- Put a long translatable literal on its own line. If it is still over 120, add `// phpcs:ignore Generic.Files.LineLength -- translatable strings stay one literal.` on the line before.
- If there's a `/* translators: */` comment, it must stay directly above the call, or make-pot drops it. In that case, wrap the statement in `// phpcs:disable Generic.Files.LineLength` and `// phpcs:enable Generic.Files.LineLength`, with the translators comment inside, just above the call.

## Templates

Break lines only *inside a start tag* (between attributes) or *inside a `<?php ... ?>` block*. Never break between inline elements, because that adds a visible space.

The golden tests collapse whitespace inside start tags (Phase 1), so they must pass unchanged. Don't regenerate the golden files in this phase. A failure means the wrap changed visible output: undo it.

## Remaining WPCS security hits

Fix real ones. For false positives, add a scoped `phpcs:ignore` or `phpcs:disable`/`enable` with a reason. Examples: `IN (%s,%s)` placeholders built with `array_fill`, or a read-only `$_GET` filter flag.

## Translations

Regenerate the `.pot`:
```
wp i18n make-pot . languages/<domain>.pot --exclude=vendor,tests,build
```
- Use the global `wp` or the sandbox's `wp-cli.phar`, whichever exists, and create `languages/` if it's missing.
- Make a worktree of `v0-baseline` outside the plugin (for example `git worktree add ../<plugin-slug>-v0 v0-baseline`), extract a `.pot` from it the same way, and diff the sorted `msgid` lists. They must be identical. Don't diff against the old committed `.pot`; it may be stale. Remove the worktree afterwards with `git worktree remove`.
- Check that each `translators:` comment in the baseline `.pot` is still there.
- make-pot reads only one plugin header per folder. With several plugins in one folder, the other headers' strings are missing from both `.pot` files. Add it to the log's **Report items** rather than working around it.

Run the tests (Hard rule 2), commit and tag `v5-lint-zero`, and update `MIGRATION_LOG.md`.
