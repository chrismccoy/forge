# Phase 4: Namespace and PSR-4 role folders

Goal: every class under `<Root\Namespace>` in a `src/` folder that says what it does, loaded by a small autoloader, with all hook wiring in `Plugin::boot()`.

## Propose the tree, then wait

Put `src/Plugin.php` at the root. Group every other class into a folder by what it does. Use these names, or the closest match:
- `Admin/`: admin screens, menus, list-table columns
- `Settings/`: option model and settings screen
- `Rest/`: REST controllers
- `<ServiceName>/`: external API clients (for example `YouTube/YouTubeClient.php`)
- `Import/` or `Domain/`: the core business logic
- `Contracts/`: interfaces
- `Support/`: the container, helpers and small utilities

Give classes descriptive names (`ImportPage`, `RestController`, `YouTubeClient`). A folder's main class may share the folder's name when that name already describes it (`Settings\Settings`, `Import\Importer`). Avoid names that only repeat the folder and say nothing about the role, such as `Admin\Admin` for an import screen.

If one large class does several jobs (admin page, settings, REST, API client), split it into one class per role. Extracting methods into new classes is a Phase 4 rename: the Hard rule 2 exception covers test updates for methods that move, and the old-to-new map in `MIGRATION_LOG.md` must record the new class of each moved method.

**Show the user the proposed tree and wait for approval before moving anything.**

## Several plugins in one folder

Give each plugin its own sub-namespace and its own `Plugin` class, for example `<Root\Namespace>\Client\Plugin` in `src/Client/Plugin.php` and `<Root\Namespace>\Server\Plugin` in `src/Server/Plugin.php`.
- Each main file registers an autoloader for its own sub-namespace, so one plugin still works when the other is inactive.
- Classes both plugins use go in a shared folder (for example `src/Shared/`), and both autoloaders cover it.
- In the ruleset, add every main file to the `SideEffects` and `LineLength` excludes.
- WP-CLI names each plugin `<folder>/<file-without-.php>`, so use that slug in every `wp plugin` command.

## Moving files

- Use `git mv` for every move. When splitting a class, `git mv` the file that keeps most of the code and create the extracted files new. If the class lives in the main file, which has to stay at the root with its header, all `src/` files are new; git can't record that as a move.
- Template files, if there are any, go to `views/`. Leave markup that lives inside class methods where it is.
- In each file, put the header in the PSR-12 order: `<?php`, file docblock, `declare`, `namespace`, `use`, then the `defined('ABSPATH') || exit;` guard.
- Add `use` statements for the WP global classes each file uses: `WP_Error`, `WP_Query`, `WP_REST_Request`, `WP_REST_Response`, `WP_REST_Server`, and so on. Unqualified global *functions* and *constants* fall back to the global namespace; *classes* don't.
- Inside `[Class, 'method']` callbacks, replace string class names with `Foo::class`.
- Move global helper functions (logging, capability checks, textdomain loading) into static methods on `Plugin`.
- Move the hook wiring from the main file into `Plugin::boot()`.

## Pitfalls

- **Check stored names before moving a class.** Grep for `register_uninstall_hook`, and for `serialize(`, `maybe_serialize(`, `update_option(`, `set_transient(` and `update_post_meta(` calls that store objects. Apply Hard rule 1 to every hit of a plugin class. Hits that store only core objects (for example a `WP_Error` in a transient) need no alias: add them to the log's **Report items** and move on.
- **Define the path constants first.** The main file defines `<PREFIX>_FILE` (`__FILE__`) and `<PREFIX>_DIR` (`plugin_dir_path(__FILE__)`) before the autoloader, or reuses existing equivalents.
- **Watch for `__FILE__`.** Any code that used `__FILE__` from the main file, such as `plugin_basename(__FILE__)`, `plugin_dir_path(__FILE__)` or `register_uninstall_hook(__FILE__, ...)`, must use a `<PREFIX>_FILE` constant once it moves. If the plugin already defines constants for the file and directory (for example `<PREFIX>_PLUGIN_FILE`, `<PREFIX>_PLUGIN_DIR`), reuse them instead of adding new ones, here and in the autoloader.
- **`uninstall.php` runs without the plugin loaded.** WordPress doesn't load the main file, the autoloader or the plugin's hooks first. If `uninstall.php` uses plugin classes, require the autoloader in it, or keep it self-contained.

## Main file and autoloader

The main file keeps the plugin header, the ABSPATH guard, the `define`s and a small autoloader, then calls `Plugin::boot()`. Composer is not a runtime dependency (unless intake chose to keep an existing runtime Composer autoloader). The autoloader:

```php
spl_autoload_register(
    function (string $class): void {
        $prefix = '<Root\\Namespace>\\';
        if (0 !== strpos($class, $prefix)) {
            return;
        }
        $file = <PREFIX>_DIR . 'src/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
        if (is_readable($file)) {
            require $file;
        }
    }
);
```

If `<current-floor>` is below 7.1, leave out `string` and `: void` on the closure until Phase 6 (Hard rule 5).

With several plugins in one folder, each main file registers this autoloader once for its own sub-namespace (`$prefix = '<Root\\Namespace>\\Client\\'` with the base directory `src/Client/`), and once for `Shared\` if that folder exists.

Keep any `class_alias` lines for stored class names (Hard rule 1) in the main file, after the autoloader, so they exist whenever WordPress loads the plugin to run a stored callback.

## Tests

- Remove `require_once` lines that point at the old class files.
- Add `use` statements.
- Rename test classes to PascalCase (`ImporterTest`, `<Prefix>TestCase`). If the test files get renamed too, update the test discovery in `phpunit.xml.dist` (`prefix`/`suffix`), then check that the test count hasn't changed.
- Update any test that looked for plugin callbacks by the old prefix, so it doesn't pass while checking nothing. Watch for case-insensitive substring checks: a check for the old prefix in a callback name (for example `ytbi`) still matches the new namespace (`YtBulkImporter\...`), so it keeps passing without checking the new names. Match the exact namespace prefix instead.
- Cover the hooks listed as a known gap in Phase 1 (`is_admin()` wiring) by calling `set_current_screen('dashboard')` and then `Plugin::boot()`.

Run the tests (Hard rule 2, comparing through the test-name map), commit and tag `v4-namespace`, and update `MIGRATION_LOG.md`.
