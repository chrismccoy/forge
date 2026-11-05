# Phase 7: Coercive typing (remove `strict_types`)

Skip this phase if intake chose to keep everything.

Goal: no `declare(strict_types=1)` left in any PHP file, and every type declaration kept. If intake chose to lower the floor, commit the `strict_types` removal on its own and run its proof first, then follow **Lowering the PHP floor** at the end.

## Why this is safe for working code

`strict_types` only changes how scalar arguments and return values are checked in calls made *from* a strict file. Coercive mode accepts every value that strict mode accepts, and gives it the same type. So every call that worked before still works and gets the same values. The change only affects calls that used to throw a TypeError:
- a numeric string passed to an `int` or `float` parameter is now converted instead of throwing
- an `int` returned from a `string` function is now converted
- `null` passed to a non-nullable parameter of a PHP internal function now gives a deprecation notice instead of a TypeError (PHP 8.1)

`null` passed to a non-nullable *user-defined* parameter, or returned from a function with a scalar return type, still throws in coercive mode. These are error-path changes: list "TypeError paths now coerce" once in the log's **Report items**, with any concrete case the tests or the code show.

## Removing the line

Remove `declare(strict_types=1);` from every PHP file: `includes/`, `views/`, `tests/`, the main file, `uninstall.php` and any `deprecated-functions.php`.
- In a class or code file, remove the line and the blank line it leaves, so the file docblock is followed by one blank line and then the rest of the file.
- In a template whose first line is `<?php declare(strict_types=1); ?>`, remove the whole line including its newline. PHP dropped the newline after `?>`, so the output doesn't change. A template with a docblock, then `declare`, then `?>` on its own line loses only the `declare` line. Check with the golden tests.
- Don't touch other `declare` statements (`ticks`, `encoding`).
- Afterwards, `git grep -n 'strict_types' -- '*.php'` must find nothing. That includes comments: reword any comment that explains code by `strict_types` or strict mode, since it's now wrong. Leave `strict` arguments of functions such as `base64_decode()` and `in_array()` alone.
- Prove nothing else changed: `php <skill-dir>/scripts/token-proof.php wpcs-v6-lint-zero --strip-comments --drop-declare` must report `OK` for every file.

## Tests

- A test that expects a TypeError which only strict mode raised now fails. Change it to assert the coerced result, under the second Hard rule 2 exception, and report it as a behaviour change.
- A test that passes a value core passes in production (for example `'5'` for an `int` parameter) still passes. Nothing to do.

## Keep, don't remove

Unless intake chose to lower the floor, keep all parameter, return and property types, `readonly`, union types, `mixed`, nullable types and casts. WPCS accepts them, and removing a scalar type changes coercion (Hard rule 5). Keep `Requires PHP:`, `"php"` in `composer.json` and `testVersion` as they are.

## Lowering the PHP floor

Only if intake chose it. Set `testVersion` to the target, run `phpcs` on the plugin and `tests/`, and rewrite each reported construct. PHPCompatibility 9 misses most syntax past 7.4 (`match`, enums, unions, promotion, nullsafe, named arguments, arrow functions), so also run `php <skill-dir>/scripts/floor-scan.php <target> <paths>` and rewrite everything it lists. Both must end clean, but neither is complete: only `php -l` with a real binary of the target proves every file parses. From here on, `<current-floor>` means the target, in Phase 8 too, and Hard rule 5 applies to it. The old value stays in the log as the baseline's floor.

- **Scalar type removal changes behaviour.** With `int $id`, a caller passing `'5'` gets the integer 5. Without the type it stays a string, so later `===` checks and JSON output change. When removing a scalar parameter or return type, add a cast at the same point (`$id = (int) $id;`) and list it as a behaviour change. A value that used to throw now gets cast.
- Typed properties (7.4): drop the type, keep the `@var` tag, and read every assignment site. Without the type nothing coerces or rejects, so add a cast where a value used to be coerced, and list the lost guarantee.
- Arrow functions become closures with `use`, `??=` becomes `??` with an assignment, and array spread becomes `array_merge()`. Spread drops string keys differently before 8.1: check each one.
- `match` becomes `switch` with strict comparison written out: `match` uses `===`, and `switch` uses `==`. Use `if`/`elseif` with `===` when types can differ, and keep the `UnhandledMatchError` path if a test or caller relies on it.
- Enums become classes with constants. Every `->value`, `::from()` and `::tryFrom()` needs rewriting, and stored enum values stay as they are.
- `readonly` properties become private properties with getters only if something outside the class reads them. List every lost guarantee.
- Constructor promotion, union types, `mixed`, nullsafe `?->`, named arguments and first-class callables each get the plain older form. Union and `mixed` types move to docblocks.
- Check PHP functions newer than the target too (`str_contains()`, `array_is_list()`). WordPress polyfills some of them. `floor-scan.php` also prints `REVIEW` lines for calls that act differently below the target: read each one, and add a test for it (better still in Phase 1, when intake already chose to lower the floor).
- Check behaviour that differs by version, not just syntax: `is_numeric( '60 ' )` (trailing spaces, 8.0), `0 == 'a'` (8.0), `substr()` returning false before 8.0, internal functions warning rather than throwing a TypeError before 8.0, `strtolower()` following the locale before 8.2, and internal signatures such as `ob_implicit_flush()`. The `REVIEW` lines cover only some of these: read the code for the rest.
- A return type that already coerces needs no cast when it is removed unless the value can really be a scalar string: a cast on an array gives `"Array"`.

Add or set `Requires PHP:` to the target, and state it in the README's Development section. Raise `Requires at least:` only if the target's WordPress needs it. In `composer.json`, add or update `require.php` and `config.platform.php`, then run `composer update` so the lock file holds packages that install on the target. PHPUnit may need widening (Phase 1). Keep the wp-phpunit pin that matches the dev site in the lock file: the floor run swaps it in a copy (Phase 8).

`token-proof.php` can't cover this step. Review the whole diff by hand and sort each change into the list above, in the log.

Run the tests on the target version in Phase 8, with a WordPress version that supports it: the dev site's may not. This option isn't verified without that run. If no runtime exists, say what stands in (`PHPCompatibility` and `floor-scan.php` at the target) and that neither one proves the code runs there.

## The floor after this phase

Removing `strict_types` can lower the real runtime floor: a call that needed PHP 8.0 only because strict mode rejected a coercion now works earlier. Recompute it from `floor-scan.php`, whether or not intake lowered the floor, and record it in the log as `<runtime-floor>`. `testVersion` and the header stay as intake set them. Phase 8's floor binary is the installed version closest to `<runtime-floor>`, at or below it if one parses the code. If no exact binary exists, use that one and the nearest installed version above it, and say which floor neither proved.

Run the tests (Hard rule 2), commit and tag `wpcs-v7-coercive`, and update `WPCS_MIGRATION_LOG.md`.
