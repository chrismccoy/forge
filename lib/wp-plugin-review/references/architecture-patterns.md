# WordPress Plugin Architecture Patterns Reference

Plugin file organization, main-file patterns, constants, lifecycle (activation, deactivation, uninstall, upgrades), conditional loading, prefixing, and plugin dependencies. WordPress 6.x+. Examples follow WordPress PHP Coding Standards.

## Contents

- Quick Reference Table
- Recommended File Structure
- Main Plugin File Patterns (procedural, singleton class, namespaced)
- Plugin Constants
- Activation / Deactivation / Uninstall
- Version Upgrades
- Conditional Loading
- Prefixing
- Plugin Dependencies
- Architecture Anti-Patterns

## Quick Reference Table

| Pattern | When to Use | Review expectation |
|---------|-------------|--------------------|
| Procedural, single file | Simple utility plugins | Every function, option, and hook prefixed |
| Procedural, multi-file | Small plugins with admin/public split | Plus ABSPATH guard in every file |
| Class-based (singleton accessor) | Medium plugins | Prefixed class names; instance reachable for hook removal |
| Namespaced + PSR-4 autoload | Large plugins | Vendor-unique namespace; `vendor/` shipped; WordPress-scope names still prefixed |

## Recommended File Structure

```
/my-plugin/
├── my-plugin.php              # Main file with header (folder name = slug = text domain)
├── uninstall.php              # Uninstall cleanup
├── readme.txt                 # Required for WordPress.org
├── /languages/                # .pot and local translations
├── /includes/                 # Shared classes/functions
├── /admin/                    # Admin-only code and assets
└── /public/                   # Front-end code and assets
```

Namespaced variant: replace `/includes/`, `/admin/`, `/public/` with `/src/` mapped to the root namespace, plus a shipped `/vendor/` and `composer.json`.

Do not flag a different layout as a defect. Flag only what breaks: admin code loading on the front end, missing ABSPATH guards, unshipped `vendor/`.

## Main Plugin File Patterns

### Pattern 1: Procedural

```php
<?php
/**
 * Plugin Name: My Simple Plugin
 * Version:     1.0.0
 * Text Domain: my-simple-plugin
 */

defined( 'ABSPATH' ) || exit;

define( 'MYSP_VERSION', '1.0.0' );

add_filter( 'the_content', 'mysp_add_footer' );

function mysp_add_footer( $content ) {
	if ( is_single() ) {
		$content .= '<p>' . esc_html__( 'Thanks for reading!', 'my-simple-plugin' ) . '</p>';
	}
	return $content;
}
```

A plugin with no setup needs no activation hook. Do not flag its absence.

### Pattern 2: Class with Singleton Accessor

```php
<?php
/**
 * Plugin Name: My Plugin
 * Version:     1.0.0
 * Text Domain: my-plugin
 */

defined( 'ABSPATH' ) || exit;

define( 'MYPL_VERSION', '1.0.0' );
define( 'MYPL_PLUGIN_FILE', __FILE__ );
define( 'MYPL_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'MYPL_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

final class MyPL_Plugin {
	private static $instance = null;

	public static function instance() {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	private function __construct() {
		// add_action() only registers callbacks; nothing runs until each hook fires.
		add_action( 'init', array( $this, 'register_post_types' ) );
		add_action( 'admin_menu', array( $this, 'add_admin_menu' ) );
		add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_public_assets' ) );
	}

	public function register_post_types() {
		register_post_type( 'mypl_book', array( /* ... */ ) );
	}

	public function add_admin_menu() { /* ... */ }

	public function enqueue_public_assets() {
		wp_enqueue_style( 'mypl-style', MYPL_PLUGIN_URL . 'public/css/style.css', array(), MYPL_VERSION );
	}
}

add_action( 'plugins_loaded', array( 'MyPL_Plugin', 'instance' ) );
```

**Why the accessor matters for review:** `MyPL_Plugin::instance()` gives other code the same object, so it can call `remove_action( 'init', array( MyPL_Plugin::instance(), 'register_post_types' ) )`. A plugin that does `new MyPL_Plugin();` and discards the object makes its hooks unremovable (INFO).

Constants are defined in the main file, not inside a class file, so `__FILE__` points at the main plugin file.

### Pattern 3: Namespaced with PSR-4 Autoloading

```php
<?php
/**
 * Plugin Name: Acme Books
 * Version:     1.0.0
 * Text Domain: acme-books
 */

namespace AcmeBooks;

defined( 'ABSPATH' ) || exit;

require_once __DIR__ . '/vendor/autoload.php'; // vendor/ must ship in the zip

add_action( 'plugins_loaded', function () {
	( new Plugin() )->register_hooks();
} );
```

Namespacing rules, callback syntax, and bundled-library scoping: `oop-patterns.md`.

## Plugin Constants

```php
// ❌ BAD: Hardcoded paths break on custom installs and moved content dirs
define( 'MYPL_PLUGIN_DIR', '/var/www/html/wp-content/plugins/my-plugin/' );
define( 'MYPL_PLUGIN_URL', 'https://example.com/wp-content/plugins/my-plugin/' );

// ✅ GOOD: Derive from the main file
define( 'MYPL_VERSION', '1.0.0' );
define( 'MYPL_PLUGIN_FILE', __FILE__ );
define( 'MYPL_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );      // Trailing slash
define( 'MYPL_PLUGIN_URL', plugin_dir_url( __FILE__ ) );       // Trailing slash
define( 'MYPL_PLUGIN_BASENAME', plugin_basename( __FILE__ ) ); // my-plugin/my-plugin.php
```

`__FILE__` and `__DIR__` evaluate to the file they appear in. Defining these constants in `includes/class-x.php` points them at `includes/`, not the plugin root.

## Activation / Deactivation / Uninstall

### Activation

Runs once when a user activates the plugin. **It does not run on plugin updates** (core stopped doing that in 3.1). Anything an update needs must use a version check (see "Version Upgrades").

```php
register_activation_hook( __FILE__, 'mypl_activate' );

function mypl_activate() {
	// 1. Default options (add_option does nothing if the option exists)
	add_option( 'mypl_settings', array( 'api_key' => '', 'enabled' => false ) );

	// 2. Tables and schema (dbDelta; see api-patterns.md → Custom Database Tables)
	mypl_install_schema();

	// 3. Register CPTs, then flush once
	mypl_register_post_types();
	flush_rewrite_rules();

	// 4. Custom capabilities
	$role = get_role( 'administrator' );
	if ( $role ) {
		$role->add_cap( 'manage_mypl_books' );
	}

	// 5. Cron (guarded against duplicates)
	if ( ! wp_next_scheduled( 'mypl_daily_sync' ) ) {
		wp_schedule_event( time(), 'daily', 'mypl_daily_sync' );
	}

	update_option( 'mypl_version', MYPL_VERSION );
}
```

**Common activation mistakes:**
- `flush_rewrite_rules()` before registering the CPT → CPT URLs 404
- `$wpdb->query( 'CREATE TABLE ...' )` instead of `dbDelta()` → No upgrade path
- `update_option()` for defaults → Overwrites user settings on reactivation
- Relying on activation for upgrade work → Never runs for users who update in place
- Multisite network activation → The hook runs once, in the main site's context. Per-site setup must loop over sites or run lazily on each site

### Deactivation

Temporary cleanup. The user may reactivate, so keep permanent data.

```php
register_deactivation_hook( __FILE__, 'mypl_deactivate' );

function mypl_deactivate() {
	// 1. Clear transients
	delete_transient( 'mypl_cache' );

	// 2. Unschedule cron
	wp_clear_scheduled_hook( 'mypl_daily_sync' );

	// 3. Unregister CPTs, then flush. The CPT was already registered on init
	//    this request, so flushing alone would regenerate its rules.
	unregister_post_type( 'mypl_book' );
	flush_rewrite_rules();
}
```

**Never in deactivation:** deleting options, dropping tables, removing capabilities, or deleting meta. Those belong in uninstall.

### Uninstall

Permanent removal when the user deletes the plugin.

**Method 1: `uninstall.php` (preferred)**

```php
<?php
// uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit;
}

function mypl_uninstall_site() {
	global $wpdb;

	delete_option( 'mypl_version' );
	delete_option( 'mypl_settings' );
	delete_transient( 'mypl_cache' );
	delete_post_meta_by_key( 'mypl_custom_field' );

	$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}mypl_data" );

	$role = get_role( 'administrator' );
	if ( $role ) {
		$role->remove_cap( 'manage_mypl_books' );
	}

	$post_ids = get_posts( array(
		'post_type'   => 'mypl_book',
		'post_status' => 'any',
		'numberposts' => -1,
		'fields'      => 'ids',
	) );
	foreach ( $post_ids as $post_id ) {
		wp_delete_post( $post_id, true );
	}
}

if ( is_multisite() ) {
	// Per-site data lives in each site's tables and options.
	foreach ( get_sites( array( 'fields' => 'ids', 'number' => 0 ) ) as $site_id ) {
		switch_to_blog( $site_id );
		mypl_uninstall_site();
		restore_current_blog();
	}
	delete_site_option( 'mypl_network_settings' ); // Network-wide option
} else {
	mypl_uninstall_site();
}

// User meta is network-wide (one usermeta table), so delete it once.
delete_metadata( 'user', 0, 'mypl_user_setting', '', true );
```

On large networks, looping every site in one request can time out. Flag that as INFO for plugins aimed at large multisite installs.

**Method 2: `register_uninstall_hook()`**

```php
// In the main plugin file, during activation
register_uninstall_hook( __FILE__, 'mypl_uninstall' ); // Or array( 'MyPL_Plugin', 'uninstall' )
```

Constraints to check in review:
- The callback is stored in the `uninstall_plugins` option, so it must be a named function or a static method. Closures and object instances do not work.
- WordPress loads the main plugin file to run it, so main-file code with side effects runs during uninstall.
- If `uninstall.php` exists, WordPress uses it and ignores the hook.

| Action | Deactivation | Uninstall |
|--------|--------------|-----------|
| Delete options, tables, meta, capabilities | ❌ No | ✅ Yes |
| Clear transients/cache | ✅ Yes | ✅ Yes |
| Unschedule cron | ✅ Yes | ✅ Yes (if not already) |
| Unregister CPT + flush rewrites | ✅ Yes | Not needed |

## Version Upgrades

Activation doesn't run on updates. Compare a stored version on every load, cheaply:

```php
add_action( 'plugins_loaded', 'mypl_maybe_upgrade' );

function mypl_maybe_upgrade() {
	$installed = get_option( 'mypl_version', '0.0.0' );
	if ( version_compare( $installed, MYPL_VERSION, '>=' ) ) {
		return;
	}

	// Schema changes: rerun dbDelta() with the updated CREATE TABLE.
	// dbDelta() adds missing columns and keys; no raw ALTER TABLE needed.
	mypl_install_schema();

	// Data migrations, oldest first
	if ( version_compare( $installed, '1.2.0', '<' ) ) {
		$old = get_option( 'mypl_old_format' );
		if ( false !== $old ) {
			update_option( 'mypl_settings', mypl_migrate_option_format( $old ) );
			delete_option( 'mypl_old_format' );
		}
	}

	update_option( 'mypl_version', MYPL_VERSION );
}
```

`dbDelta()` does not drop or rename columns. Use a guarded `ALTER TABLE` only for those operations.

## Conditional Loading

```php
// ❌ BAD: Everything loads on every request
require_once MYPL_PLUGIN_DIR . 'admin/class-mypl-admin.php';
require_once MYPL_PLUGIN_DIR . 'public/class-mypl-public.php';

// ✅ GOOD
if ( is_admin() ) {
	require_once MYPL_PLUGIN_DIR . 'admin/class-mypl-admin.php';
}
if ( ! is_admin() || wp_doing_ajax() ) {
	require_once MYPL_PLUGIN_DIR . 'public/class-mypl-public.php'; // Front-end AJAX handlers live here too
}
```

**Context caveats:**
- `is_admin()` is true for `admin-ajax.php`, including front-end AJAX calls. Code that front-end AJAX needs must load when `wp_doing_ajax()` is true.
- `REST_REQUEST` is defined on `parse_request`. It can't gate loading at plugin load time; check it only inside hooks that fire after `parse_request`, or use `rest_api_init` to load REST code.
- `wp_doing_cron()` identifies WP-Cron requests.

## Prefixing

Everything in a shared namespace needs a unique prefix (4–5+ characters) or, for PHP symbols, a vendor-unique namespace.

| Item | Example | Collision risk |
|------|---------|----------------|
| Functions | `mypl_save_settings()` | Fatal "cannot redeclare" |
| Classes | `MyPL_Admin` | Fatal "cannot declare class" |
| Constants | `MYPL_VERSION` | Warning; wrong value used |
| Global variables | `$mypl_cache` | Silent overwrite |
| Options, transients, meta keys | `mypl_settings` | Data overwritten |
| Post types, taxonomies | `mypl_book` | Query var and registration conflicts |
| Shortcodes | `[mypl_form]` | Last registration wins |
| Custom hooks, cron hooks | `mypl_daily_sync` | Callbacks run for the wrong plugin |
| REST namespace | `mypl/v1` | Route conflicts |
| Admin page slugs, script/style handles | `mypl-settings`, `mypl-admin` | Wrong page or asset loads |

Prefixes like `wp_`, `wc_`, or `__` belong to core or other projects. Flag plugins that use them.

Namespaced code: see `oop-patterns.md` → "What Still Needs Prefixing".

## Plugin Dependencies

### `Requires Plugins` Header (WordPress 6.5+)

```php
/**
 * Plugin Name:      My WooCommerce Extension
 * Requires Plugins: woocommerce, advanced-custom-fields
 */
```

**Effect:**
- The plugin can't be activated until every listed plugin is installed **and active**.
- Listed plugins can't be deactivated while this plugin is active.
- Values must be WordPress.org slugs (comma-separated). Premium or non-directory plugins can't be declared here.
- It does not change load order and does not check versions.

### Runtime Checks

Plugins load in alphabetical order of their path. A check at file load runs before later-alphabet plugins load, so it fails even when the dependency is active.

```php
// ❌ BAD: Runs at file load; 'my-plugin' loads before 'woocommerce'
if ( ! class_exists( 'WooCommerce' ) ) {
	add_action( 'admin_notices', 'mypl_missing_wc_notice' );
	return;
}

// ✅ GOOD: Check once all plugins are loaded
add_action( 'plugins_loaded', 'mypl_boot' );

function mypl_boot() {
	if ( ! class_exists( 'WooCommerce' ) ) {
		add_action( 'admin_notices', 'mypl_missing_wc_notice' );
		return;
	}
	if ( defined( 'WC_VERSION' ) && version_compare( WC_VERSION, '8.0', '<' ) ) {
		add_action( 'admin_notices', 'mypl_old_wc_notice' );
		return;
	}
	MyPL_Plugin::instance();
}

function mypl_missing_wc_notice() {
	echo '<div class="notice notice-error"><p>' . esc_html__( 'My Plugin requires WooCommerce.', 'my-plugin' ) . '</p></div>';
}
```

## Architecture Anti-Patterns

| Anti-Pattern | Effect | Fix |
|--------------|--------|-----|
| Upgrade logic only in activation hook | Never runs for in-place updates | Stored-version check on `plugins_loaded` |
| Dependency check at file load | Fails based on alphabetical load order | Check on `plugins_loaded` |
| Admin code loaded on the front end | Wasted parsing on every page view | `is_admin()` gating |
| Hardcoded `wp-content/plugins` paths | Breaks custom installs | `plugin_dir_path()`, `plugin_dir_url()` |
| Constants defined from a subfile's `__FILE__` | Paths point at the wrong directory | Define in main file |
| Deleting data on deactivation | User loses data on a temporary toggle | Move to uninstall |
| No uninstall cleanup | Orphaned options and tables | `uninstall.php` |
| Uninstall that ignores multisite | Data left on every subsite | Loop `get_sites()` with `switch_to_blog()` |
| Raw SQL where a WordPress API exists | Bypasses object cache and filters | `get_posts()`, `get_option()`, meta APIs |

## Cross-References

- Hook timing, priority, removal: `hooks-guide.md`
- Namespaces, autoloading, bundled libraries: `oop-patterns.md`
- Settings, REST, transients, tables, AJAX, cron, menus: `api-patterns.md`
- Nonces, capabilities, sanitization: `/wp-security-review` command
