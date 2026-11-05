# Phase 3: Tier B naming (snake_case), one class or group at a time

Goal: snake_case method, function, property and variable names, renamed in small, tested steps. Class names change in Phase 4, not here.

Read `renaming.md` in full first. It lists the positions to rename, the names never to rename, names built at runtime, and the stored and output names that keep their value.

On any plugin, first run the `scan` in step 1 of **Large plugins**: if it lists no names to change, record that and skip this phase.

## Converting a name

- Split on case boundaries and join with `_` in lowercase: `getVideoId` becomes `get_video_id`.
- An acronym run stays one word, and the split goes before its last capital when a lowercase letter follows: `getHTTPClient` becomes `get_http_client`, and `parseURL` becomes `parse_url`.
- Digits stay attached to the word before them: `getV2Items` becomes `get_v2_items`.
- A brand or compound name is one word when the plugin already spells it as one in its options, hooks or strings. For example `YouTube` becomes `youtube` when the plugin has an option `ytbi_youtube_key`. Otherwise follow WordPress core's spelling where one exists.
- If an earlier forward migration left a name map (see Intake), use the original snake_case name when the method still exists with the same job.
- Check each new name against the class's other names, and against inherited ones, before renaming. Two camelCase names can map to one snake_case name, and a new name can collide with a parent's method.
- Record every old-to-new name in `WPCS_MIGRATION_LOG.md`, grouped by class where the steps are per class. The large-plugin route records the flat map from `names.json`.

## Order of steps

Order from lowest risk to highest, and tag each step `wpcs-v3-tier-b-<step>`. Skip a step with nothing to rename, and make no tag for it. If no step applies, record that in the log and go on to Phase 4.

1. **Methods, one class or coupled group per step** (`wpcs-v3-tier-b-<class-or-group>`)
   - An interface and its implementers share method names, so rename them in the same step. The same goes for a parent class and every subclass that overrides its methods.
   - **Classes that call each other's renamed methods in both directions must be renamed in one commit.** A class that only calls into another one can go in a later step: rename the callee first, and update the caller's calls in the same commit.
   - Go from interfaces and small helpers, to API clients, to settings, admin and REST together if they are coupled, and last the class that writes data (the importer or post writer).
   - Leave `__construct` and other magic methods alone, and apply the "never rename" list in `renaming.md`.
   - A method whose name WordPress stored in the database (for example an uninstall callback) gets renamed like the others. Keep a static wrapper with the old name that calls the new one, with `// phpcs:ignore WordPress.NamingConventions.ValidFunctionName.MethodNameInvalid -- name stored in the database` (Hard rule 1).
2. **Namespaced functions** (`wpcs-v3-tier-b-functions`). Rename them to snake_case now, keeping them in their namespace. Phase 4 adds the `<prefix>_` and makes them global.
3. **Properties, one class per step** (`wpcs-v3-tier-b-props-<class>`)
   - Rename the declaration, every `$this->x`, `self::$x` and `static::$x`, and accesses from other plugin classes. For a promoted constructor parameter (`private readonly Client $youTubeClient`), the parameter name changes too, so also update named arguments at the call sites.
   - Skip properties the plugin doesn't define, and properties whose names are stored or reach output (Hard rule 1). Give each skipped property the reasoned `phpcs:ignore`.
   - Before renaming, grep for `property_exists(`, `->{`, `get_object_vars(`, `(array)` casts on plugin objects, `json_encode(`, `wp_localize_script(` and `__get`/`__set`. Each hit can turn a property name into data.
   - **Public properties and methods of objects that reach other code** through a public hook (`do_action()`, `apply_filters()`) or the plugin's docs. Hard rule 1 doesn't settle these, so ask the user, listing each class and the hook or doc line: keep the names, with the reasoned `phpcs:ignore` (Recommended if released or documented), or rename them and update the docs. Record the answer.
   - Other public properties of a released plugin can be read by other code too. Rename them, and list each in the final report.
4. **Parameters and local variables, one file or class per step** (`wpcs-v3-tier-b-vars-<file-or-class>`)
   - Parameter renames break named-argument calls (`foo(videoId: $id)`). Grep for named arguments to every renamed function or method, and update them in the same commit.
   - A container that autowires by parameter name matches array keys too: `make( X::class, array( 'templateDir' => $dir ) )`. `apply variables` leaves those keys alone, and the override is then dropped silently. Grep for `->make(` with an array, and rename the keys in the same commit.
   - **Templates share the scope of the method that includes them.** A view file that reads `$pageTitle` needs the same rename as the method that `include`s it. Rename them as one unit. Watch for `compact('pageTitle')` and `extract()`: the variable name is a string there. Arguments passed through `load_template()` arrive in `$args` with their keys, which are data and stay as they are.
   - Leave superglobals, WordPress globals (`$wpdb`, `$post`, `$wp_query`) and shared plugin globals alone (Hard rule 1).
   - `$this`, `static` closures and arrow-function captures need no special handling. Do update `use ($x)` lists and `static $x` declarations.
   - Update the `@param` names in existing docblocks in the same commit.
5. **Tests** (`wpcs-v3-tier-b-tests`). Test methods (`test_*`), `set_up` and `tear_down` are already snake_case. Rename camelCase helper methods, data providers and test-case properties. Update `@dataProvider` annotations and `#[DataProvider]` attributes with the provider. Keep names the test framework calls by name (`renaming.md`).

## Large plugins

On a plugin with more than a few dozen names, use `scripts/snake-case.php` instead of per-class steps. Tag `wpcs-v3-tier-b-methods` and `wpcs-v3-tier-b-variables`.
1. Run `php <skill-dir>/scripts/snake-case.php scan --wp <wordpress>/wp-includes <paths> > <scratch>/names.json`, including `tests/`. Always pass `--wp`: without it, core's camelCase methods aren't checked.
2. Review it. Add to `skip_sites` every call in `external_overlap` made on an object the plugin doesn't own, for example `getName()` on a `ReflectionParameter`, or `getAll()` on the headers from `wp_remote_retrieve_headers()`. Check Composer dependencies by hand too. Resolve every `collisions` entry. Check `string_hits`. Names in `external_properties` are never renamed. Fill in `skip_properties` for kept properties: a plain name applies in every file, and `Class::$name` keeps one class's property while another's of the same name renames. `skip_methods` takes `Class::name` the same way. Each prints `CHECK` for an outside `->name` it would rename: run `apply` with `--dry-run` first, read those lines, and add the ones on that class to `skip_sites`. Collisions are checked across all classes, so a private helper elsewhere can raise a false one. Fix brand words by hand (`checkWordPressVersion` comes out as `check_word_press_version`).
3. Run `apply methods`, then the tests. It updates comments only where a name is followed by `(`, so grep comments for the rest. Map method names in golden files through `names.json` rather than regenerating them. Commit.
4. Scan again. Check that no file holds both `$fooBar` and `$foo_bar`, because they would merge.
5. List the camelCase variables in templates (ignore JS variables inside `<script>`), and find the array keys that feed them through `extract()` at the render calls. Rename those keys by hand: `apply variables` doesn't touch strings.
6. Run `apply variables`, then the tests. Commit.

After each, list remaining old names by token, and review them.

## After each step

Grep for leftovers of the old names, run the tests (Hard rule 2), commit, tag, and update `WPCS_MIGRATION_LOG.md`. Then run `phpcs --sniffs=WordPress.NamingConventions.ValidFunctionName,WordPress.NamingConventions.ValidVariableName`. Check that no new report appeared outside the step's scope, which would mean a rename leaked.
