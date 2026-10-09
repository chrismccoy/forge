# Phase 6: Strict types (PHP 8.1)

Goal: `declare(strict_types=1)` in every file, full parameter, return and property types, and no new TypeErrors at the boundaries with WordPress.

If the code is already strict and fully typed, this phase is mostly a check. Add the rules, fix what they report, and add that to the log's **Report items**.

If `<current-floor>` was below 7.1, now add the deferred `public` on class constants (Phase 2) and the types on the autoloader closure (Phase 4).

## Ruleset additions

Set `testVersion` to `8.1-`, and add this to `phpcs.xml.dist`:
```xml
<rule ref="Generic.PHP.RequireStrictTypes"/>
<!-- Templates start with a one-line `declare` block that must add no output. -->
<rule ref="PSR12.Files.FileHeader"><exclude-pattern>/views/*</exclude-pattern></rule>
<rule ref="SlevomatCodingStandard.TypeHints.ParameterTypeHint">
	<exclude name="SlevomatCodingStandard.TypeHints.ParameterTypeHint.UselessAnnotation"/>
	<exclude name="SlevomatCodingStandard.TypeHints.ParameterTypeHint.MissingTraversableTypeHintSpecification"/>
</rule>
<rule ref="SlevomatCodingStandard.TypeHints.ReturnTypeHint">
	<exclude name="SlevomatCodingStandard.TypeHints.ReturnTypeHint.UselessAnnotation"/>
	<exclude name="SlevomatCodingStandard.TypeHints.ReturnTypeHint.MissingTraversableTypeHintSpecification"/>
</rule>
<rule ref="SlevomatCodingStandard.TypeHints.PropertyTypeHint">
	<exclude name="SlevomatCodingStandard.TypeHints.PropertyTypeHint.UselessAnnotation"/>
	<exclude name="SlevomatCodingStandard.TypeHints.PropertyTypeHint.MissingTraversableTypeHintSpecification"/>
</rule>
```

The type-hint sniffs cover `tests/` too, so test helpers and test-case properties need types as well. Test methods keep their snake_case names.

## `declare(strict_types=1)`

Add it to **every** PHP file: `src/`, `views/`, `tests/`, the main file and `uninstall.php`.
- It goes after the file docblock and before `namespace`. The file docblock is the one right after `<?php`.
- If that first docblock belongs to a class (for example it carries `@runTestsInSeparateProcesses`), put `declare` before it, so the annotations stay attached to the class.
- In a template that starts with HTML, make the first line `<?php declare(strict_types=1); ?>`. PHP drops the newline right after `?>`, so the output doesn't change.

## Types

Run `phpcbf --sniffs=SlevomatCodingStandard.TypeHints.ReturnTypeHint` once. It adds `: void` only where a function returns nothing.

Then type every parameter, return value and property by hand:
- Use union returns for WP-style failures: `array|WP_Error`, `string|WP_Error`, `WP_REST_Response|WP_Error`.
- Use `bool|WP_Error` where the value is "`true` or an error". A standalone `true` type needs PHP 8.2.
- Use `mixed` for values WordPress passes through without a fixed type: `rest_pre_dispatch` results, `validate_callback` values, `register_setting` sanitize input, option getters.
- Use **nullable** types for filter callbacks that core can call with `null`. `parent_file` and `submenu_file` take and return `?string`.
- Type WordPress objects exactly: `WP_Query $query` for `pre_get_posts`, `WP_REST_Request`, `WP_REST_Server`.
- Declare injected dependencies and immutable config as `private readonly`.
- Type closures too, including `sanitize_callback` closures and `array_filter` callbacks.

## Coercion checks

- **Calls from core.** WordPress core files are not strict, so core calls the plugin's callbacks in coercive mode. Even so, `null` passed to a non-nullable parameter still throws a TypeError. For every hook callback, check what core can pass.
- **Filter results.** Where a filter result feeds a typed return, cast it, for example `(string) apply_filters(...)`. Report each cast as a behaviour change.
- **PHP internal functions.** Inside strict files, calls to internal functions are strict. Look for `int|false` or `string|false` results passed straight into internal functions.
- **Strict test files.** Tests are strict now too. A test that passes a value core would pass coercively (for example `'5'` for an `int`) fails here but not in production. Change that argument to the type core really passes, under the second Hard rule 2 exception. If core itself can pass that value, fix the plugin instead (a nullable type or a cast).
- **Plugin-to-plugin calls.** These are strict too, and they are the most common source of new TypeErrors. WordPress returns strings where other types are expected: `get_option()`, `get_post_meta()`, `get_user_meta()`, `$wpdb` results, `$_GET`/`$_POST` values and shortcode attributes. Trace each of these values to the typed parameter it reaches, and cast or validate it where it enters the plugin. Report each cast.

## PHP version fields

- Set `Requires PHP: 8.1` in every plugin header, adding the field if it's missing.
- Update the README too if it has that field (a `readme.txt` usually does) or states the PHP version in prose.
- Set `"php": ">=8.1"` under `require` in `composer.json`, adding it if it's missing.

Run the tests (Hard rule 2), commit and tag `v6-strict-types`, and update `MIGRATION_LOG.md`.
