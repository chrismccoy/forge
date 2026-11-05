# Phase 1: Tooling and safety net

Goal: a linter that measures the starting point against the ruleset chosen at intake, and tests that fail if a rename or a move breaks the plugin's wiring or output.

## Composer and test runner

Record the starting violation counts (see **Ruleset**) before writing any test file. If there's no `composer.json`, create a minimal one first (name, `"type": "wordpress-plugin"`, the license the plugin declares, if any, `"require-dev": {}`, and `config.process-timeout` 0 so long test runs aren't cut off). Composer stays a dev-only tool, unless intake chose to keep a runtime Composer autoloader.

When building the safety net from scratch, also add a test runner: `phpunit/phpunit:^9.6`, `yoast/phpunit-polyfills`, and the `wp-phpunit/wp-phpunit` version that matches the dev site's WordPress, or the nearest lower one if that release doesn't exist. Use PHPUnit 9.6: it runs on PHP 8.1 and supports the docblock annotations these instructions use (`@runInSeparateProcess`). PHPUnit 10 and later drop those annotations. If `composer.json` already pins a newer PHPUnit, use `composer require --dev -W`. If intake lowers the floor below PHP 7.3, use `^8.5 || ^9.6`, because 9.6 needs 7.3.

Also write `phpunit.xml.dist`, `tests/bootstrap.php` and the tests config from Phase 0. In the bootstrap:
- load the plugin from a `muplugins_loaded` callback
- put any `wp_doing_ajax` filter inside that callback too: core calls the filter from `wp_debug_mode()`, before `__return_true` exists
- if the plugin creates tables, drop them and run its activation after the test bootstrap has finished, since activation can need `$wp_rewrite`: the test installer drops only core tables, so a second run fails on `Duplicate key name`
- set `WP_TESTS_SKIP_INSTALL=1` after the parent process has installed, or every `@runInSeparateProcess` child runs the installer again

If intake lowers the floor, write all test code in the target version's syntax from the start. wp-phpunit declares no PHP requirement, so Composer won't hold it back: pin it to the newest release that runs on the target for the floor run, or report the stack as unusable there.

Add the lint dependencies. WPCS 3 is required: the sniff names and the `minimum_wp_version` setting below are from 3.x.
```
composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer require --dev squizlabs/php_codesniffer "wp-coding-standards/wpcs:^3" \
  phpcompatibility/phpcompatibility-wp dealerdirect/phpcodesniffer-composer-installer
composer config scripts.lint phpcs
composer config scripts.lint:fix "phpcbf --exclude=WordPress.WP.I18n"
composer config scripts.test "<the command that runs the test setup chosen at intake>"
```
`composer test` must run the full suite and accept extra PHPUnit arguments such as `--log-junit`. Update existing Composer scripts that name a removed ruleset (`phpcs --standard=phpcs.xml`).

If `slevomat/coding-standard` is in `require-dev` only for the old PSR-12 ruleset, remove it with `composer remove --dev`. Keep it if anything else uses it.

## Ruleset

Replace the existing `phpcs.xml.dist` (a PSR-12 ruleset, usually) with the one below. Keep any `exclude-pattern` from the old file that still applies, such as a bundled third-party library.

```xml
<?xml version="1.0"?>
<ruleset name="<plugin-slug>">
	<file>.</file>
	<exclude-pattern>/vendor/*</exclude-pattern>
	<exclude-pattern>/node_modules/*</exclude-pattern>
	<exclude-pattern>/build/*</exclude-pattern>
	<arg name="extensions" value="php"/>
	<arg value="sp"/>

	<!-- The standard chosen at intake. -->
	<rule ref="<standard>"/>

	<config name="minimum_wp_version" value="<wp-floor>"/>
	<config name="testVersion" value="<current-floor>-"/>
	<rule ref="PHPCompatibilityWP"/>

	<rule ref="WordPress.WP.I18n">
		<properties>
			<property name="text_domain" type="array">
				<element value="<domain>"/>
			</property>
		</properties>
	</rule>
	<rule ref="WordPress.NamingConventions.PrefixAllGlobals">
		<properties>
			<property name="prefixes" type="array">
				<element value="<prefix>_"/>
			</property>
		</properties>
		<!-- Test config and bootstrap files define globals that nothing else loads. -->
		<exclude-pattern>/tests/*</exclude-pattern>
	</rule>

	<!-- Tests: fixtures read from disk, debug output allowed. Docblocks are not required unless intake says so. -->
	<rule ref="Squiz.Commenting.FileComment"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="Squiz.Commenting.ClassComment"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="Squiz.Commenting.FunctionComment"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="Squiz.Commenting.VariableComment"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="Generic.Commenting.DocComment.MissingShort"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.Security"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.WP.AlternativeFunctions"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.PHP.DevelopmentFunctions"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.WP.GlobalVariablesOverride"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.DB.PreparedSQL"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.PHP.DiscouragedPHPFunctions"><exclude-pattern>/tests/*</exclude-pattern></rule>
	<rule ref="WordPress.PHP.NoSilencedErrors"><exclude-pattern>/tests/*</exclude-pattern></rule>
</ruleset>
```

- If intake chose **keep namespaces**, add the root namespace as a second `<element>` under `prefixes`.
- If `<scratch>` is `.wpcs/`, add `<exclude-pattern>/.wpcs/*</exclude-pattern>`, because `phpcs` scans that folder. It is the one allowed hit in Phase 8's search. Otherwise leave it out.
- With `WordPress-Extra` or `WordPress-Core`, leave out the `Squiz.Commenting` and `DocComment` excludes. A `<rule ref>` added only to scope tests also switches that sniff on. Compare `phpcs -e | grep -v PHPCompatibility` for the project ruleset and for `--standard=<standard>`, and change every test-exclude rule that adds a sniff. With Extra, replace `WordPress.Security` with `WordPress.Security.EscapeOutput` and `WordPress.Security.NonceVerification`. With Core, most of these rules go, or the ruleset grows past formatting and naming.
- If the plugin's old ruleset is `phpcs.xml`, remove it: it takes precedence over `phpcs.xml.dist`.
- `<wp-floor>` is the `Requires at least:` value. If the header has none, use the oldest WordPress version the plugin's code needs, and add that to the log's **Report items**.
- Keep the trailing underscore in the prefix: WPCS counts it towards the 4-character minimum, and `MSD_Crypto` matches `msd_` because the check ignores case. If `phpcs` still reports the prefix as too short or reserved (`ShortPrefixPassed`), go back to the user (intake question 1).
- If the user wants the tests documented too, leave out the four `Squiz.Commenting` and the `DocComment` excludes, and reword the comment above them. Say in the report which way it went.
- If the test classes extend a plugin base class (for example `<Old\Namespace>\Tests\TestCase`), add that class to the `custom_test_classes` property of `WordPress.Files.FileName`. Otherwise the sniff treats the tests as plugin classes. Classes that extend a known test class are exempt from it entirely.

Record the starting violation counts **before** writing any test file, the bootstrap included, so they measure the original code only. Run `vendor/bin/phpcs --report=summary` and `vendor/bin/phpcs --report=source`, and keep both outputs in the log. For the counts by ruleset, also run `vendor/bin/phpcs -q --report=summary --extensions=php --standard=<name> <plugin PHP paths, without vendor>` once each for `WordPress-Core`, `WordPress-Extra` and `WordPress-Docs` (Extra includes Core). Expect a large number: indentation and spacing alone flag most lines.

## Safety-net tests

If a wiring test file already exists (for example from a forward migration), reuse and extend it rather than adding a second one. Check that it still asserts an explicit list of hooks, not a count.

Otherwise add `tests/test-plugin-wiring.php` containing the following. Name and describe it by what it tests (Hard rule 8).

### Hook wiring test
- Boot the plugin the way a wp-admin request does. Call the plugin's methods that add admin and settings hooks directly. For a modern plugin that is usually `set_current_screen('dashboard')`, then `Plugin::boot()`. Don't fire `admin_init`: it starts core update checks over HTTP. `WP_Ajax_UnitTestCase::_handleAjax()` fires it anyway, so remove `_maybe_update_core`, `_maybe_update_plugins` and `_maybe_update_themes` from it in those tests.
- Don't fire `init` again: it has already run during the bootstrap, and a second run re-registers block types and fails on the "already registered" notice. To test a callback on `init`, find it in `$wp_filter` and call it directly.
- Fire `admin_menu`. Pages added with `add_options_page()` and similar register under `admin_page_*` unless the parent menu exists, so check hook names against what core really registered.
- To test admin enqueue, call `set_current_screen()` with the plugin's page hook first, then call the plugin's enqueue callback directly. Firing core's `admin_enqueue_scripts` without a screen fatals inside `wp_auth_check_load()`.
- Walk `$wp_filter` and assert that every plugin callback is `is_callable`. First-class callables (`$this->x(...)`) are stored as `Closure` objects: unpack them with `ReflectionFunction` (`getName()`, `getClosureScopeClass()`), or the test sees nothing. On PHP 8.4 and later a closure's name is `{closure:file:line}`: normalize it to `{closure}`, or any line shift breaks a golden list. `activate_<path>` hook names hold an absolute path: mask it. A closure in a file included from a class reports that class as its scope.
- If registration depends on `is_admin()` or `wp_doing_ajax()`, set a fake `$GLOBALS['current_screen']` with an `in_admin()` method and add a `wp_doing_ajax` filter in the bootstrap's `muplugins_loaded` callback, before the plugin boots, and remove both once `init` has run. On a large plugin, snapshot the hook list to a golden file instead of writing it by hand. A golden hook list is still an explicit list.
- Also assert that an **explicit list** of expected `hook => Class::method` pairs is present, so the test can't pass while checking nothing. Don't assert a count: the REST server is a singleton, so counts change with test order.
- Match plugin callbacks by the exact current namespace prefix (`<Old\Namespace>\`), never by a loose pattern that also matches test classes. Phase 4 switches the match to the exact class prefix `<PREFIX>_`, unless intake chose to keep namespaces.

### REST wiring test
For every plugin route, check that `callback`, `permission_callback` and every argument's `sanitize_callback`/`validate_callback` are callable. Skip the namespace index route that core adds.

### Settings wiring test
Check that the `register_setting` sanitize callback and every settings field callback are callable.

### Golden-copy tests
Save the rendered HTML of every admin screen to `tests/fixtures/golden/`. Also save the content of every post the plugin generates: one case for each output format (for example block and classic) and for each setting that changes the content (for example a title or embed-only option).
- Save post content raw as `.txt`, with no normalization, so Phase 8 can compare it byte for byte.
- For HTML, hide values that change between runs: nonces, `_wp_http_referer`, dates and times in any format, memory figures, version strings, absolute paths, and random keys or prefixes.
- For HTML, collapse runs of spaces and tabs, and strip indentation at line starts, so the space-to-tab change in templates doesn't count as a diff. Leave the content of `<pre>`, `<textarea>` and `<script>` elements exactly as rendered: whitespace there is visible or meaningful, and Phase 2's indentation fixers can reach it.
- For HTML, also collapse every whitespace run inside a start tag (between `<` and `>`, newlines included) to one space. Whitespace between tags still counts, because the browser shows it.
- Rewrite the golden files when `GOLDEN_UPDATE=1` is set.
- A golden must hold no PHP notice or deprecation, and no absolute path or list of loaded extensions: each varies by PHP version or checkout, and fails the floor run for nothing. The same goes for output that core changed between versions, such as `\/` escaping in inline JSON. Mask them before tagging. If one slips through, fixing its mask is a third Hard rule 2 exception: list it in the report.
- Helper classes in `tests/` each go in their own file, to satisfy `FileName` and `OneObjectStructurePerFile`.
- Test helpers run on the floor too: for example, PHP before 8.2 rejects a null byte in a regex.
- Before tagging, run the suite twice at least a minute apart: a net that passes within one minute can still hold the time.

### Mocks must behave like the real thing
- A mock must return the same shapes as WordPress. For `pre_http_request`, `headers` is a `WpOrg\Requests\Utility\CaseInsensitiveDictionary`, not an array: code that calls methods on it fails in both versions with a plain array, which hides a broken rename.
- An AJAX handler that calls `wp_send_json_success()` inside `try`/`catch ( \Exception )` catches the test suite's die exception, so it writes a second response and closes an output buffer it doesn't own. Keep the first JSON body and restore the buffer level in the test helper.
- `ReflectionMethod::setAccessible()` prints a deprecation on PHP 8.5, which fails `@runInSeparateProcess` tests. Guard it with a version check.
- Check what each golden file recorded. A golden holding an error, such as a URL refused because a test domain doesn't resolve, passes forever and tests nothing. Use a public IP address in mocked URLs if the plugin checks DNS.
- Code gated on `REST_REQUEST`, `WP_CLI` or `DOING_CRON` at `init` can't be reproduced in the bootstrap, and calling its `register()` by hand hides timing bugs. List such code in the log, and exercise it with a real request in Phase 8, or through the labelled control there if no real request reaches it.
- WordPress test cases rewrite `CREATE TABLE` and `DROP TABLE` to temporary tables, so check table cleanup on the live site, not in a test.

### Output from objects and class names
- If any object reaches output through `json_encode()`, `wp_localize_script()`, `get_object_vars()` or a REST response, add a test that saves that output as a golden file. Phase 3 renames properties, and this test proves the keys didn't change.
- If an object goes to a public hook (`do_action()` or `apply_filters()`), intake's answer decides whether its public properties and methods change. If they stay, add a test that reads them by name.
- If intake found strings built from class names that are stored or shown (Hard rule 1), assert their current values literally, for example `assertSame( 'ytbulkimporter_import_importer_cache', $key )`. Phase 4 renames the classes, and this test proves the strings didn't change.

### Other coverage
- Cover anything the existing tests miss that a rename could break: uninstall, list-table filters, admin enqueue, templates that read variables from the calling method's scope.
- **Adapt the net to the plugin.** Some plugins have no settings, admin pages, list tables or generated posts. Skip the tests that don't apply, and cover the nearest equivalents that drive output instead: meta box HTML, admin notices, post type and taxonomy arguments, enqueued script config, REST payloads. Add what was skipped and what was covered instead to the log's **Report items**.
- Code that ends in `die()` or `exit` can't be reached by PHPUnit: use a fake for the last step if one can be injected, and leave the rest to the Phase 8 real flows. List it as a known gap.
- Objects booted once keep instance caches, so a test that changes stored settings must boot fresh objects.
- If plugin code caches results in a `static` variable or a static property for the whole request, one process can only see one state. Test the other states with `@runInSeparateProcess`.

## Check that the net catches a break

Rename one callback string by hand, confirm the wiring test fails, then revert. Change one string in a template, confirm the golden test fails, then revert. If a property reaches output, rename it too, confirm the golden test fails, then revert.

Run the suite with JUnit output (Hard rule 2), commit and tag `wpcs-v1-safety-net`, and update `WPCS_MIGRATION_LOG.md`.
