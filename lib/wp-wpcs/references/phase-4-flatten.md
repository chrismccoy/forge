# Phase 4: WordPress class and file names, flattened or namespaced

Goal: every class a prefixed global class (`<PREFIX>_Import_Page`) in a WordPress-named file under `includes/`, loaded by a classmap autoloader, with no `namespace` or import `use` statements left. If intake chose to keep namespaces, the classes keep their namespaces: see that section, which overrides the rest of this file.

Read `renaming.md` in full first. Class renames follow the same position rules, and its stored-name section decides which old names need an alias.

## Propose the tree, then wait

Keep the role grouping from `src/` as lowercase folders under `includes/`. Name every class and file the WordPress way:
- **Class names:** `<PREFIX>_` plus the old short name split into capitalized words joined with `_`. For example `ImportPage` becomes `<PREFIX>_Import_Page`. Keep acronyms uppercase, core's newer form (`WP_HTTP_Response`, not `WP_Http`) (`<PREFIX>_REST_Controller`, like `WP_REST_Controller`; `ClientIp` becomes `Client_IP`), and keep brand words as one word (`<PREFIX>_YouTube_Client`).
- **File names:** `class-` plus the class name in lowercase, with `_` replaced by `-`: `includes/admin/class-ytbi-import-page.php`. `WordPress.Files.FileName` enforces the `class-` prefix for classes only. Interfaces, traits and enums just need lowercase hyphenated names, and by convention use `interface-`, `trait-` and `enum-`. Drop a doubled word: `<PREFIX>_Crypto_Interface` goes in `interface-<prefix>-crypto.php`. Test classes are exempt from the sniff.
- **Interfaces** keep an `Interface` or `Contract` suffix if the plugin has one, written as `<PREFIX>_Crypto_Interface`. Dropping it often collides with the implementing class. Don't invent a suffix.
- **Collisions.** Flattening can map two classes to one name, for example `Admin\Settings` and `Settings\Settings`. Add the role word to one of them (`<PREFIX>_Admin_Settings`) rather than using numbers.
- `src/Plugin.php` becomes `includes/class-<prefix>-plugin.php` with class `<PREFIX>_Plugin`; a nested one such as `src/Core/Plugin.php` keeps its folder as `includes/core/`. Keep its entry method (`boot()`, or `run()` on an instance) and the hook wiring in it: moving the wiring back into the main file is not required by WPCS and adds risk. `boot()` below means whatever that method is called.
- Templates stay where they are (`views/` usually). Their file names must be lowercase with hyphens.

If an earlier forward migration left a map (see Intake), prefer the original class names where the class still has the same job.

Ask for approval with one `AskUserQuestion` call, and **move nothing until the user approves**:
- The question states the class count, the file layout, and every naming call made: how acronyms are written, suffixes kept, doubled prefixes removed, collisions resolved, and what happens to namespaced functions.
- The first option is "Approve as shown (Recommended)", with the tree in its `preview`: folders with class counts, and an example file in each.
- Offer a real alternative as the second option, such as title-case acronyms or a flat `includes/`.
- If the user picks an alternative or describes changes, update the map and ask again.

## If intake chose to keep namespaces

This section overrides the rest of the file. Differences:
- Classes stay in their namespaces, with WordPress names: `<Old\Namespace>\Admin\ImportPage` becomes `<Old\Namespace>\Admin\Import_Page` in `includes/admin/class-import-page.php`. There is no `<PREFIX>_`.
- The second column of the map holds the new full name. Run `flatten.php` with `--keep-namespaces`: `namespace` lines stay, and imports are rewritten one per line.
- Skip `$aliases` for old names unless a class short name changed and intake said "released" and the aliases load lazily, or a stored name needs one: an alias then maps the old full name to the new one. Keys in `$classes` are full names in lowercase.
- Composer can't find `class-import-page.php` by PSR-4, so the classmap autoloader or a Composer `classmap` is still needed.

| Part of this file | With namespaces kept |
|---|---|
| Moving files: `namespace` lines, import removal, leading `\`, global-class imports | Skip. `flatten.php --keep-namespaces` keeps them and rewrites imports |
| Moving files: namespaced functions and constants | Skip: they keep their names and namespace |
| Pitfalls: names that start resolving, unqualified functions | Skip: names resolve as before |
| Pitfalls: stored names, class-name strings, path constants, `uninstall.php`, Composer | Apply |
| Main file: `<PREFIX>_Plugin::boot()` | Call the namespaced class, as before |
| `includes/deprecated-functions.php` | Skip: functions didn't change |
| Tests: `use` statements | Keep them, and update the class names |
| Tests: `Test_<PREFIX>_` names | Keep the namespace; use `Test_` plus the class short name |
| Tests: wiring match | Keep matching `<Old\Namespace>\`; never switch to `<PREFIX>_`, which matches nothing |
| Everything else | Apply |

## Several plugins in one folder

Give each plugin its own sub-prefix and its own plugin class, for example `<PREFIX>_Client_Plugin` in `includes/client/` and `<PREFIX>_Server_Plugin` in `includes/server/`.
- Each main file registers a classmap autoloader for its own classes, so one plugin still works when the other is inactive.
- Classes both plugins use go in a shared folder (for example `includes/shared/`), and both classmaps list them.
- WP-CLI names each plugin `<folder>/<file-without-.php>`, so use that slug in every `wp plugin` command.

## Moving files

- Write the approved table to `<scratch>/flatten-map.txt`, one class per line, including classes whose names don't change: `Old\Namespace\Class New_Class includes/path/class-new-class.php`.
- Use `git mv` for every move, then edit. Commit moves and edits together; git still detects the rename when the content mostly stays. In shell loops, read the map with `read -r`: plain `read` eats the backslashes. Afterwards remove the folders `git mv` left empty: `find src -type d -empty -delete`.
- Run `php <skill-dir>/scripts/flatten.php <scratch>/flatten-map.txt <files>` on every PHP file outside `vendor/`: the moved files, `tests/`, config files, `views/`, the main file, `uninstall.php` and any bootstrap for static analysis. It does the `namespace`, import and class-reference work described in the next four bullets by tokens. Check its output, and grep for the old namespace and short class names afterwards: strings, comment text and the autoloader are not rewritten. Docblock type tags are. Existing comments that name a renamed class follow the rename (Hard rule 8): a word-bounded search and replace is allowed here, since comments have no token position, but review every hit. It reports `use function` and `use const`: rename namespaced functions by tokens, including their calls and any fully qualified uses. Pass `--functions <scratch>/function-map.txt`, with lines `Old\Namespace\func new_func`: it renames global definitions and calls, and leaves methods of the same name alone. String callbacks and `function_exists()` arguments stay hand work.
- In each file, the header order is: `<?php`, file docblock, the `declare` line (it stays until Phase 7), any ABSPATH guard the file already has, then the class. Don't add a guard to a file that has none: it's new code. Remove the `namespace` line.
- Remove import `use` statements (`use Foo\Bar;`, `use function`, `use const`), and replace every short name they imported with the new global name. Don't touch trait `use` inside a class body, except to rename the trait, or closure `use (...)`.
- Remove imports of global classes (`use WP_Error;`): in the global namespace PHP warns that such a `use` has no effect.
- A leading `\` on global classes and functions (`\WP_Error`, `\strlen()`) still works. Remove it for consistency, by tokens only.
- Namespaced functions become global `<prefix>_<name>()` functions in `includes/functions.php` or the file they were in. Namespaced constants become `<PREFIX>_<NAME>`. Update `function_exists()`, `defined()` and string callbacks that name them.
- `Foo::class` keeps working with the new name. Rename it to `<PREFIX>_Foo::class`, but see the class-name strings pitfall below.

## Pitfalls

- **Check stored names before moving a class.** Grep for `register_uninstall_hook`, and for `serialize(`, `maybe_serialize(`, `update_option(`, `set_transient(` and `update_post_meta(` calls that store objects. Apply Hard rule 1 to every hit of a plugin class. Hits that store only core objects need no alias: add them to the log's **Report items** and move on.
- **Strings built from class names.** `static::class . '_cache'`, `sanitize_key( __CLASS__ )`, `__NAMESPACE__` and `get_class( $this )` all change value when the class is renamed. `surface.php` shows them as `<expr>` both before and after, so its diff can't catch them. For each one that is stored or shown (Intake list), replace the expression with its old value as a literal string, and add a comment saying why. The Phase 1 test for these values must still pass.
- **Names that start resolving.** In namespaced code, an unqualified class name in `catch`, `instanceof` or a type declaration, with no `use` and no class of that name in the namespace, referred to a class that doesn't exist. For example `catch ( Exception $e )` in `<Old\Namespace>` never caught anything, and `instanceof WP_Post` was always false. Once flattened, the same code refers to the global class and starts matching. Before removing any `namespace` line, run `php <skill-dir>/scripts/unresolved-names.php src` (plus any other path that declares plugin classes). For each name it lists, stop and ask the user: keeping the old behaviour means writing it out on purpose, and the old behaviour is usually a bug.
- **Unqualified functions.** A call such as `strlen()` in namespaced code checks `<Old\Namespace>\strlen` first and then the global function. If the plugin defines a namespaced function with the same name as a global one, the flattened call now reaches the global one. Grep for namespaced function definitions whose names match PHP or WordPress functions, and rename the calls to the new prefixed name.
- **Define the path constants first.** The main file must define `<PREFIX>_FILE` and `<PREFIX>_DIR` before the autoloader, or reuse existing equivalents.
- **`uninstall.php` runs without the plugin loaded.** If it uses plugin classes, it must require the autoloader file (or the class files it needs) after the change, or stay self-contained.
- **Composer autoload sections.** Remove `psr-4` entries for the old namespace from `autoload` and `autoload-dev`, and update moved paths in `autoload.files`, or the plugin fatals at load. If intake chose to keep the Composer runtime autoloader, replace the entry with `"classmap": ["includes/"]` and run `composer dump-autoload`. Any aliases then need a small `spl_autoload_register()` of their own in the main file, holding only the `$aliases` branch below.

## Main file and autoloader

The main file keeps the plugin header, the ABSPATH guard, the `define`s and the autoloader, then calls `<PREFIX>_Plugin::boot()`. Composer is not a runtime dependency unless intake chose to keep it. PHP class names are case-insensitive, so the map is keyed in lowercase:

```php
spl_autoload_register(
	function ( string $class_name ): void {
		static $classes = array(
			'ytbi_plugin'      => 'includes/class-ytbi-plugin.php',
			'ytbi_import_page' => 'includes/admin/class-ytbi-import-page.php',
			// One line per class, interface, trait and enum.
		);
		static $aliases = array(
			// Old namespaced name (lowercase) => new class name.
			'ytbulkimporter\\import\\importer' => 'YTBI_Importer',
		);
		$key = strtolower( $class_name );
		if ( isset( $classes[ $key ] ) ) {
			require <PREFIX>_DIR . $classes[ $key ];
		} elseif ( isset( $aliases[ $key ] ) ) {
			class_alias( $aliases[ $key ], $class_name );
		}
	}
);
```

- The `$aliases` map makes old names work lazily, the moment something autoloads them: `unserialize()` meeting a stored object, `new`, `extends`, or a static call. `class_alias()` loads the new class through the same autoloader, and nothing loads at boot. PHP doesn't autoload for `instanceof` or a parameter type, so those fail on an old name until something else triggers the alias. Lazy is enough for stored names.
- Put a stored class name (Hard rule 1) in `$aliases` whatever intake said, with a comment `// Stored in the database.`
- If intake said "released", ask the user how aliases load: eagerly (Recommended), with `class_alias()` for each old name straight after the autoloader, so `instanceof` and type declarations in other code keep working at the cost of loading those classes on every request; or lazily, which breaks those two positions. Record the answer. For lazy, put every old namespaced class name in `$aliases`, with a comment `// @deprecated <version>: use <new name>.`, where `<version>` is the plugin's current version. For eager, put the same names in one list in the main file, under the same comment, with `<prefix>_`-prefixed variables:
  ```php
  // @deprecated <version>: use the new names.
  foreach ( array( '<Old\Namespace>\Old_Name' => '<New_Name>' ) as $<prefix>_old => $<prefix>_new ) {
  	class_alias( $<prefix>_new, $<prefix>_old );
  }
  ```
  No alias covers `get_class( $x ) === 'Old\Name'`, `class_implements()` or `serialize()`, which all give the new name: report that, because a rollback can't read what the new code stored. Add old namespaced functions as wrappers that call the new functions in `includes/deprecated-functions.php`. That file is the only one that keeps a `namespace <Old\Namespace>;` line. Load it from the main file and mark each wrapper `@deprecated`.
- With several plugins in one folder, each main file registers its own map.
- If `$aliases` would be empty, leave it and its `elseif` out.
- Generate the map from the tree, sorted, and check it: every class file is listed once, and every listed file exists.

## Tests

- Remove `use` statements and replace the imported names.
- Rename test classes and files the WordPress way: `ImporterTest` in `tests/ImporterTest.php` becomes `Test_<PREFIX>_Importer` in `tests/test-<prefix>-importer.php`. `tests/test-plugin-wiring.php` keeps its name, since it holds no class name. Update the test discovery in `phpunit.xml.dist` (`prefix`/`suffix`), then check that the test count hasn't changed. Add each test-class rename to the name map in the log.
- A plugin test base class (`TestCase`) becomes `<PREFIX>_Test_Case` in `tests/class-<prefix>-test-case.php`. Update the `custom_test_classes` setting in the ruleset to the new name.
- Update the wiring test to match the exact class prefix `<PREFIX>_`, case-sensitively. Watch for case-insensitive substring checks: a check for `ytbi` matches both `YtBulkImporter\...` and `YTBI_...`, so it keeps passing without checking the new names.
- Update `class_exists()` and `instanceof` checks in tests that name the old classes (Hard rule 2 exception).
- If an alias exists for a stored name, add a test that unserializes a stored object with the old class name and gets the new class. For aliases kept because intake said "released", add a test that each old name loads the new class. If they load eagerly, also test `instanceof` on an old name in a separate process, without calling `class_exists()` first: PHPUnit's `assertInstanceOf` calls it internally, which hides the failure.

Map class names in golden files through the map rather than regenerating them. Renames change the sort order of a sorted golden list: compare it as a set (`diff <(sort a) <(sort b)`) before accepting that. Also update paths in release scripts, static-analysis config (`src` to `includes`), and the scoped `exclude-pattern` entries from Phase 2: an outdated path silently stops protecting the file.

When replacing class names in comments, leave single-word names that are also English words (`Cache`, `Logger`, `View`) to be read by hand.

`junit-compare.php` takes class-level map lines (`OldClass<TAB>NewClass`). Data-set test names can hold class names: list those on their own lines, or they show as missing.

Run the tests (Hard rule 2, comparing through the test-name map), commit and tag `wpcs-v4-flatten`, and update `WPCS_MIGRATION_LOG.md`.
