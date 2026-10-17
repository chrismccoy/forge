# WordPress Plugin OOP Patterns Reference

Review-focused rules for class-based and namespaced plugins: what namespaces do and don't protect, hooking namespaced and class-method callbacks, autoloading, and bundled Composer dependencies. WordPress 6.x+. Core's minimum PHP rises over time (7.2.24 for WP 6.6, 7.4 in current trunk); check the current minimum on wordpress.org/about/requirements before flagging PHP-version issues.

The main-file singleton pattern lives in `architecture-patterns.md` → "Main Plugin File Patterns". Removing class-method hooks lives in `hooks-guide.md` → "Removing Hooks".

## Contents

- Choosing a Structure
- PHP Namespaces
- Hooking Namespaced and Class-Method Callbacks
- What Still Needs Prefixing
- Autoloading
- Bundled Composer Dependencies
- OOP Review Anti-Patterns

## Choosing a Structure

| Structure | Fits | Review note |
|-----------|------|-------------|
| Procedural, prefixed functions | Small plugins, a handful of hooks | Fine. Do not flag as "should be OOP" |
| Prefixed classes (`MyPL_Admin`) | Medium plugins | Each class name needs the prefix |
| Namespaced classes + autoloader | Larger plugins, many classes | Function/class prefixes unnecessary; WordPress-scope names still need prefixes |

Report over-engineering (a service container or abstract hierarchy for a 100-line plugin) as INFO at most. Architecture style is not a defect by itself.

## PHP Namespaces

A namespace protects PHP symbols only: functions, classes, interfaces, traits, and `const` constants.

```php
<?php
namespace MyPlugin\Admin;

defined( 'ABSPATH' ) || exit;

class Settings {
	public function register_hooks() {
		add_action( 'admin_init', array( $this, 'register_settings' ) );
	}

	public function register_settings() {
		register_setting( 'mypl_options', 'mypl_settings', array(
			'type'              => 'array',
			'sanitize_callback' => array( $this, 'sanitize' ),
		) );
	}

	public function sanitize( $input ) {
		return is_array( $input ) ? array_map( 'sanitize_text_field', $input ) : array();
	}
}
```

`define()` ignores namespaces. `define( 'VERSION', '1.0' )` inside `namespace MyPlugin;` creates the global constant `VERSION`. Flag unprefixed `define()` calls even in namespaced files.

Use a vendor-unique root namespace (`AcmeBooks\`), not a generic one (`Plugin\`, `App\`, `Admin\`). A generic root namespace collides the same way an unprefixed class does.

## Hooking Namespaced and Class-Method Callbacks

```php
namespace MyPlugin;

function load_textdomain() { /* ... */ }

// ❌ BAD: String callbacks are resolved in the global namespace
add_action( 'init', 'load_textdomain' ); // Calls global load_textdomain() or fails

// ✅ GOOD
add_action( 'init', __NAMESPACE__ . '\\load_textdomain' );
add_action( 'init', 'MyPlugin\\load_textdomain' );

// ✅ GOOD: Instance method
add_action( 'init', array( $this, 'on_init' ) );

// ✅ GOOD: Static method, fully qualified or via ::class
add_action( 'init', array( Utils::class, 'helper' ) );
add_action( 'init', array( 'MyPlugin\\Utils', 'helper' ) );
```

**Registering hooks in constructors:** This works and is common. The review concern is narrower: if the instance is created and discarded (`new MyPL_Admin();` with no reference kept), nobody can remove its hooks later, and unit tests can't build the object without side effects. Flag as INFO only when extensibility or testability matters. Do not report it as a defect by itself.

## What Still Needs Prefixing

WordPress stores these by string name in shared global registries. Namespaces do not apply to them.

```php
namespace MyPlugin;

register_post_type( 'mypl_book', $args );               // Post type key
register_taxonomy( 'mypl_genre', 'mypl_book', $args );  // Taxonomy name (arg 2 is object type)
add_option( 'mypl_settings', $data );                   // Option name
set_transient( 'mypl_cache', $data, HOUR_IN_SECONDS );  // Transient name
update_post_meta( $id, 'mypl_field', $value );          // Meta key
do_action( 'mypl_custom_hook' );                        // Custom hook name
add_shortcode( 'mypl_form', $callback );                // Shortcode tag
register_rest_route( 'mypl/v1', '/items', $args );      // REST namespace
wp_enqueue_script( 'mypl-admin', $src );                // Script/style handle
define( 'MYPL_VERSION', '1.0.0' );                      // define() is always global
```

## Autoloading

**Composer PSR-4** (`composer.json`):

```json
{
	"autoload": {
		"psr-4": {
			"MyPlugin\\": "src/"
		}
	}
}
```

```php
// my-plugin.php
defined( 'ABSPATH' ) || exit;
require_once __DIR__ . '/vendor/autoload.php';
```

**Manual autoloader (no Composer):**

```php
spl_autoload_register( function ( $class ) {
	$prefix = 'MyPlugin\\';
	if ( 0 !== strncmp( $prefix, $class, strlen( $prefix ) ) ) {
		return; // Not ours: let other autoloaders handle it
	}
	$file = __DIR__ . '/src/' . str_replace( '\\', '/', substr( $class, strlen( $prefix ) ) ) . '.php';
	if ( is_readable( $file ) ) {
		require $file;
	}
} );
```

**Review checks:**
- WARNING: Autoloader without the namespace-prefix guard → Tries to load every class in the request, including other plugins' classes
- CRITICAL: `require` of `vendor/autoload.php` with no `vendor/` shipped → Fatal on install (see next section)

## Bundled Composer Dependencies

WordPress.org installs the plugin zip as-is. Users never run `composer install`.

- Ship `vendor/` in the release zip. Build it with `composer install --no-dev --optimize-autoloader`.
- Do not ship dev dependencies (PHPUnit, PHPCS) or their test fixtures.
- WARNING: Bundled third-party libraries in their original namespaces (e.g. `GuzzleHttp\`, `Monolog\`) → Two plugins bundling different versions of the same library load whichever version loads first, causing version conflicts or fatals. Fix: prefix vendor namespaces with a build tool such as PHP-Scoper or Strauss.
- WordPress.org also rejects bundled copies of libraries that WordPress core already ships (jQuery, PHPMailer, SimplePie). Use the core copy.

## OOP Review Anti-Patterns

| Anti-Pattern | Effect | Severity | Fix |
|--------------|--------|----------|-----|
| Generic root namespace (`App\`, `Plugin\`) | Class collisions across plugins | CRITICAL | Vendor-unique namespace |
| Unprefixed `define()` in namespaced file | Global constant collision | CRITICAL | Prefix constant or use namespaced `const` |
| String callback to namespaced function without namespace | Wrong function called, or fatal | CRITICAL | `__NAMESPACE__ . '\\fn'` |
| Unscoped bundled libraries | Version conflicts with other plugins | WARNING | PHP-Scoper / Strauss |
| Autoloader with no prefix guard | Wasted file lookups, possible wrong-file loads | WARNING | Return early for foreign classes |
| Hooks on discarded instances or closures | Other code can't remove them | INFO | Keep an accessible instance or use static methods |
| Heavy OOP for a tiny plugin | Maintenance cost | INFO | Procedural with prefixes is fine |

## Cross-References

- Main-file patterns, singleton, constants, lifecycle: `architecture-patterns.md`
- Removing class-method hooks, priority, timing: `hooks-guide.md`
- Settings, REST, AJAX, Cron, database APIs: `api-patterns.md`
