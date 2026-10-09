# Phase 1: Tooling and safety net

Goal: a linter that measures the starting point, and tests that fail if a rename breaks the plugin's wiring or output.

## Composer and test runner

If there's no `composer.json`, create a minimal one first (name, `"type": "wordpress-plugin"`, license, `"require-dev": {}`). Composer stays a dev-only tool, unless intake chose to keep a runtime Composer autoloader.

When building the safety net from scratch, also add a test runner: `phpunit/phpunit:^9.6`, `yoast/phpunit-polyfills`, and the `wp-phpunit/wp-phpunit` version that matches the dev site's WordPress. Use PHPUnit 9.6: it runs on PHP 8.1 and supports the docblock annotations these instructions use (`@runInSeparateProcess`). PHPUnit 10 and later drop those annotations.

Add the lint dependencies:
```
composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer require --dev squizlabs/php_codesniffer wp-coding-standards/wpcs \
  phpcompatibility/phpcompatibility-wp dealerdirect/phpcodesniffer-composer-installer \
  slevomat/coding-standard
composer config scripts.lint phpcs
composer config scripts.lint:fix phpcbf
composer config scripts.test "<the test command chosen at intake>"
```
`composer test` must run the full suite and accept extra PHPUnit arguments such as `--log-junit`.

## Ruleset

Create `phpcs.xml.dist`. In the ruleset below, `/<plugin-slug>\.php$` stands for the main file. If the main file isn't named after the folder, or the folder holds several plugins, list every main file in those exclude patterns.

Start with PSR-12 and the PHP floor the header claims now (Hard rule 5). If the header has no `Requires PHP:`, use `7.4-`. Add the strict-types and type-hint rules from Phase 6 only when Phase 6 starts.

```xml
<?xml version="1.0"?>
<ruleset name="<plugin-slug>">
	<file>.</file>
	<exclude-pattern>/vendor/*</exclude-pattern>
	<exclude-pattern>/node_modules/*</exclude-pattern>
	<exclude-pattern>/build/*</exclude-pattern>
	<arg name="extensions" value="php"/>
	<arg value="sp"/>

	<rule ref="PSR12"/>
	<rule ref="Generic.Arrays.DisallowLongArraySyntax"/>
	<rule ref="NormalizedArrays.Arrays.ArrayBraceSpacing"/>
	<rule ref="Squiz.Arrays.ArrayBracketSpacing"/>

	<!-- PSR-12 has no security sniffs; keep the WPCS ones. -->
	<rule ref="WordPress.Security"/>
	<rule ref="WordPress.DB.PreparedSQL"/>
	<rule ref="WordPress.DB.PreparedSQLPlaceholders"/>

	<!-- The floor the header claims now; Phase 6 raises it to 8.1-. -->
	<config name="testVersion" value="<current-floor>-"/>
	<rule ref="PHPCompatibilityWP"/>

	<!-- PSR-1 says SHOULD. Class files keep the ABSPATH guard; the main file must define constants and boot. -->
	<rule ref="PSR1.Files.SideEffects">
		<exclude-pattern>/src/*</exclude-pattern>
		<exclude-pattern>/includes/*</exclude-pattern>
		<exclude-pattern>/<plugin-slug>\.php$</exclude-pattern>
		<exclude-pattern>/tests/*</exclude-pattern>
	</rule>
	<!-- WordPress reads each plugin header field from a single line. -->
	<rule ref="Generic.Files.LineLength">
		<exclude-pattern>/<plugin-slug>\.php$</exclude-pattern>
	</rule>
	<!-- WP_UnitTestCase requires set_up()/tear_down(); test files are not autoloaded. -->
	<rule ref="PSR1.Methods.CamelCapsMethodName"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="PSR1.Classes.ClassDeclaration.MissingNamespace"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.Security"><exclude-pattern>/tests/*</exclude-pattern></rule>
</ruleset>
```

Record the starting violation count with `vendor/bin/phpcs --report=source` **before** adding the safety-net test file, so it measures the original code only.

## Safety-net tests

Add `tests/test-refactor-safety.php` containing the following.

### Hook wiring test
- Boot the plugin the way a wp-admin request does. Call the plugin's methods that add admin and settings hooks directly (for example an admin `init()` and a settings `register()`). Don't fire `admin_init`: it starts core update checks over HTTP.
- Fire `admin_menu`. Pages added with `add_options_page()` and similar register under `admin_page_*` unless the parent menu exists, so check hook names against what core really registered.
- To test admin enqueue, call `set_current_screen()` with the plugin's page hook first, then call the plugin's enqueue callback directly. Firing core's `admin_enqueue_scripts` without a screen fatals inside `wp_auth_check_load()`.
- Walk `$wp_filter` and assert that every plugin callback is `is_callable`.
- Also assert that an **explicit list** of expected `hook => Class::method` pairs is present, so the test can't pass while checking nothing. Don't assert a count: the REST server is a singleton, so counts change with test order.
- Match plugin callbacks by the plugin's class prefix only, never by a loose pattern that also matches test classes.
- Hooks that the main file adds behind `if (is_admin())` at load time can't be asserted this way, because `is_admin()` is false while the test bootstrap loads the plugin. Add them to the log's **Report items** as a known gap. From Phase 4 on, cover them by calling `set_current_screen('dashboard')` and then `Plugin::boot()` in the test.

### REST wiring test
For every plugin route, check that `callback`, `permission_callback` and every argument's `sanitize_callback`/`validate_callback` are callable. Skip the namespace index route that core adds.

### Settings wiring test
Check that the `register_setting` sanitize callback and every settings field callback are callable.

### Golden-copy tests
Save the rendered HTML of every admin screen to `tests/fixtures/golden/`. Also save the content of every post the plugin generates: one case for each output format (for example block and classic) and for each setting that changes the content (for example a title or embed-only option).
- Save post content raw as `.txt`, with no normalization, so Phase 7 can compare it byte for byte.
- For HTML, hide values that change between runs: nonces, `_wp_http_referer`.
- For HTML, collapse runs of spaces and tabs, and strip indentation at line starts, so the tab-to-space change in templates doesn't count as a diff.
- For HTML, also collapse every whitespace run inside a start tag (between `<` and `>`, newlines included) to one space, so wrapping attributes over several lines in Phase 5 doesn't count as a diff. Whitespace between tags still counts, because the browser shows it.
- Rewrite the golden files when `GOLDEN_UPDATE=1` is set.

### Other coverage
- Cover anything the existing tests miss that a rename could break: uninstall, list-table filters, admin enqueue.
- **Adapt the net to the plugin.** Some plugins have no settings, admin pages, list tables or generated posts. Skip the tests that don't apply, and cover the nearest equivalents that drive output instead: meta box HTML, admin notices, post type and taxonomy arguments, enqueued script config, REST payloads. Add what was skipped and what was covered instead to the log's **Report items**.
- If plugin code caches results in a `static` variable or a static property for the whole request, one process can only see one state. Test the other states with `@runInSeparateProcess`.

## Check that the net catches a break

Rename one callback string by hand, confirm the wiring test fails, then revert.

Run the suite with JUnit output (Hard rule 2), commit and tag `v1-safety-net`, and update `MIGRATION_LOG.md`.
