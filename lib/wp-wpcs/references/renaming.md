# Renaming and stored names

Details for Hard rules 1 and 3. Read this in full before Phases 3, 4 and 6, and before any rename made in another phase.

## Names that must keep their value (Hard rule 1)

Besides option, meta and transient keys, REST routes, hook names, the text domain, error codes, HTML output and JS config keys, these must also stay as they are:
- names of global variables (`global $x`, `$GLOBALS['x']`) shared with code outside the plugin
- callbacks and class names that WordPress has already stored in the database: the `register_uninstall_hook()` callback (saved in the `uninstall_plugins` option), and the class names inside serialized objects in options, meta and transients
- property names of any object that is serialized and stored, or reaches output. It reaches output through `json_encode()`, `wp_localize_script()`, `get_object_vars()`, an `(array)` cast or a REST response.
- every string built from a class name that is stored or shown (found at intake). When the class gets renamed, replace the expression with the old literal string, add a comment saying the value is stored or shown, and list each one in the final report. `static::class` in a base class has one value per subclass: override it in each subclass with that class's old literal.

A public method that returns a class-name string with no caller, and log text naming an old class, aren't stored or shown to users: leave them, and list them in the log's **Report items** for the user to decide.

Public properties and methods of objects passed to public hooks or documented in the plugin's docs are not in this list: the user decides them, as `phase-3-tier-b.md` says.

Renaming stored names breaks existing installs: uninstall fatals, and stored objects come back as `__PHP_Incomplete_Class` or lose their property values. So:
- Keep an alias for every stored class name (the `$aliases` map in `phase-4-flatten.md`), even when intake says "not released".
- Keep the old name of every stored method or function callback with a wrapper that calls the new one, with `// phpcs:ignore WordPress.NamingConventions.ValidFunctionName.MethodNameInvalid -- name stored in the database` (or the function-name sniff code).
- A property that must keep its camelCase name keeps it, with `// phpcs:ignore WordPress.NamingConventions.ValidVariableName.PropertyNotSnakeCase -- <reason>`.
- An alias doesn't remap private or protected properties of a stored object: they are keyed by the old class name, so they come back empty. Such a class needs `__unserialize()` or a data migration: ask the user which, because either changes code.
- Don't mark these deprecated: sites keep the stored name until the plugin is reinstalled. List each one in the final report.

Activation and deactivation callbacks are not stored: the main file registers them again on every load, so they only need the rename rules below. Objects of WordPress core classes, such as a `WP_Error` in a transient, are not affected.

## Where to rename (Hard rule 3)

Names often match other strings: hook names, settings keys, JS config keys, HTML ids and API field names. Rename by tokens (`token_get_all`) or by position-exact patterns, only in these positions:
- definitions: `function x(`, `class X`, `interface X`, `trait X`, `enum X`, property declarations, promoted constructor parameters
- calls and references: `->x(`, first-class callables `->x(...)`, `?->x(`, `self::x(`, `static::x(`, `parent::x(`, `ClassName::x(`, `new ClassName`, `ClassName::CONST`, `instanceof`, `catch`, type declarations, `extends` and `implements`, trait `use` inside a class body
- property access: `$this->x`, `self::$x`, `static::$x`
- variables: every `T_VARIABLE` token, including inside double-quoted strings and heredocs (`"$x"`, `"{$x}"`), closure `use ($x)`, `static $x` and `global $x`
- array and string callbacks: `[$this, 'x']`, `[self::class, 'x']`, `['ClassName', 'x']`, `'ClassName::x'`, `'<prefix>_function'`
- name checks and indirect uses: `method_exists()`, `property_exists()`, `is_callable()`, `function_exists()`, `class_exists()`, `compact('x')`, named arguments (`x: $value`), `@dataProvider x`, `#[DataProvider('x')]`

Rename only the plugin's own names. Array keys are data, not names: `fileUrl` in block attributes or a JS config key stays as it is, and the sniffs don't flag it. After each rename, grep for the old name and review every hit by hand.

## Names never to rename

Something outside the plugin calls or defines these:
- methods that override or implement a WordPress core, WP-CLI or third-party method
- methods of PHP built-in interfaces: `jsonSerialize`, `offsetExists`, `offsetGet`, `offsetSet`, `offsetUnset`, `getIterator`
- magic methods
- test-framework hooks that are called by name, such as `wpSetUpBeforeClass` and `wpTearDownAfterClass`
- properties declared by a parent class
- properties of objects the plugin doesn't define: decoded JSON (`$response->nextPageToken`), SDK objects

Keep the name, add a `phpcs:ignore` for the exact sniff with the reason (for example `-- implements JsonSerializable::jsonSerialize`), and list each in the final report.

## Names built at runtime

These don't show up in a grep for the old name:
- `'get' . ucfirst($field)`
- `[$this, 'render' . $tab]`
- `$this->{$prop}`
- `$$name`
- `extract()`
- names passed to `call_user_func`, `method_exists` or `property_exists` from variables

Before renaming, grep for concatenated and interpolated names. Leave the matching names alone unless every place that builds them is updated in the same commit.
