# Phase 2: Tier A (PSR-12 layout only)

Goal: PSR-12 layout with a proof that no code changed.

- Run `vendor/bin/phpcbf` until it reports no fixable errors. Two passes are usually enough, but not always.
- Add `public` to class constants that have no visibility (`public const`). Skip this if `<current-floor>` is below 7.1 (Hard rule 5); Phase 6 adds it.

## Prove the change is layout only

Write a small PHP script in `build/` (never committed) that runs `token_get_all` on both the old version of each file (`git show HEAD:<file>`) and the new one. Normalize both streams, then compare them:
- drop whitespace tokens, and collapse whitespace inside comments and inline HTML
- trim trailing whitespace from `T_OPEN_TAG` and `T_CLOSE_TAG`, which carry the newline after `<?php` and `?>`
- rewrite `array(...)` to `[...]` by matching brackets; clear the "pending array" flag on any token that isn't `(`, because `array` is also a parameter type
- compare keywords, type names and `true`/`false`/`null` case-insensitively
- map long cast forms to short ones: `(integer)` to `(int)`, `(boolean)` to `(bool)`, `(double)`/`(real)` to `(float)`
- treat `new X` and `new X()` as equal, and `else if` and `elseif` as equal
- sort runs of modifier tokens (`public`, `protected`, `private`, `static`, `abstract`, `final`, `readonly`) before comparing, so `static public` equals `public static`
- ignore a final `T_CLOSE_TAG` at the end of a file
- ignore a leading `\` in `use` statements

After that normalization, the only allowed differences are the added `public` on constants. Any other difference: revert that file's fix and investigate (Hard rule 2).

Run the tests (Hard rule 2), commit and tag `v2-tier-a`, and update `MIGRATION_LOG.md`.
