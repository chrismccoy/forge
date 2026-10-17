# WordPress Plugin API Patterns Reference

WordPress core APIs for plugin review: Settings API, Options API, REST API, Transients API, custom database tables, AJAX handlers, Cron API, and Admin Menu API. WordPress 6.x+. Examples follow WordPress PHP Coding Standards. For security depth (nonces, capability checks, sanitization), see the `/wp-security-review` command.

## Contents

- Quick Reference Table
- Settings API Complete Workflow
- Options API (autoload, single vs multiple options)
- REST API Endpoint Registration (methods, args, responses, schema)
- Transients API
- Custom Database Tables (dbDelta, upgrades)
- AJAX Handler Patterns
- Cron API
- Admin Menu API (menus, action links)

## Quick Reference Table

| API | Key Function | Hook | Purpose |
|-----|--------------|------|---------|
| **Settings API** | `register_setting()` | `admin_init` (or `init` when `show_in_rest`) | Structured settings pages with automatic validation |
| **Options API** | `update_option()` | Any | Store plugin configuration in database |
| **REST API** | `register_rest_route()` | `rest_api_init` | Create custom REST endpoints |
| **Transients API** | `set_transient()` | Any | Temporary cached data with expiration |
| **Custom DB Tables** | `dbDelta()` | Activation hook | Create custom database tables |
| **AJAX API** | `wp_ajax_{action}` | Hook | Handle AJAX requests |
| **Cron API** | `wp_schedule_event()` | Activation hook | Schedule recurring tasks |
| **Admin Menu API** | `add_menu_page()` | `admin_menu` | Create admin menu pages |

## Settings API Complete Workflow

### Registration Process

**Hook choice:**
- `add_settings_section()` and `add_settings_field()` are admin-only (defined in `wp-admin/includes/template.php`). Hook them to `admin_init`.
- `register_setting()` lives in `wp-includes`. `admin_init` is fine for admin-only settings. A setting with `show_in_rest` must be registered on `init` or `rest_api_init`, because `admin_init` doesn't fire on REST requests. Don't flag `register_setting()` on `init`.

```php
add_action( 'admin_init', 'mypl_register_settings' );

function mypl_register_settings() {
	// Step 1: Register setting (option name in database)
	register_setting(
		'mypl_options_group',  // Option group (used in settings_fields())
		'mypl_settings',        // Option name (database key)
		array(
			'type'              => 'array',
			'sanitize_callback' => 'mypl_sanitize_settings',
			'default'           => array(
				'api_key' => '',
				'enabled' => false,
			),
			'show_in_rest'      => false, // Don't expose in REST API
		)
	);

	// Step 2: Add settings section
	add_settings_section(
		'mypl_main_section',         // Section ID
		__( 'Main Settings', 'my-plugin' ), // Section title
		'mypl_section_callback',     // Callback for section description
		'mypl-settings'              // Page slug (must match do_settings_sections())
	);

	// Step 3: Add settings fields to section
	add_settings_field(
		'mypl_api_key',              // Field ID
		__( 'API Key', 'my-plugin' ), // Field label
		'mypl_api_key_callback',     // Callback to render field HTML
		'mypl-settings',             // Page slug (must match section)
		'mypl_main_section'          // Section ID (must match add_settings_section())
	);

	add_settings_field(
		'mypl_enabled',
		__( 'Enable Feature', 'my-plugin' ),
		'mypl_enabled_callback',
		'mypl-settings',
		'mypl_main_section'
	);
}
```

### Field Render Callbacks

```php
/**
 * Section description callback.
 */
function mypl_section_callback() {
	echo '<p>' . esc_html__( 'Configure your plugin settings below.', 'my-plugin' ) . '</p>';
}

/**
 * Text field callback.
 */
function mypl_api_key_callback() {
	$options = get_option( 'mypl_settings', array() );
	$value = isset( $options['api_key'] ) ? $options['api_key'] : '';
	?>
	<input type="text"
	       name="mypl_settings[api_key]"
	       value="<?php echo esc_attr( $value ); ?>"
	       class="regular-text">
	<p class="description">
		<?php esc_html_e( 'Enter your API key from the provider dashboard.', 'my-plugin' ); ?>
	</p>
	<?php
}

/**
 * Checkbox field callback.
 */
function mypl_enabled_callback() {
	$options = get_option( 'mypl_settings', array() );
	$checked = isset( $options['enabled'] ) && $options['enabled'];
	?>
	<label>
		<input type="checkbox"
		       name="mypl_settings[enabled]"
		       value="1"
		       <?php checked( $checked, true ); ?>>
		<?php esc_html_e( 'Enable this feature', 'my-plugin' ); ?>
	</label>
	<?php
}

```

### Sanitization Callback

```php
/**
 * Sanitize settings.
 *
 * @param array $input Raw input from form.
 * @return array Sanitized settings.
 */
function mypl_sanitize_settings( $input ) {
	$sanitized = array();

	// Text field
	if ( isset( $input['api_key'] ) ) {
		$sanitized['api_key'] = sanitize_text_field( $input['api_key'] );
	}

	// Checkbox (boolean)
	$sanitized['enabled'] = isset( $input['enabled'] ) && $input['enabled'] ? true : false;

	// Select (whitelist)
	if ( isset( $input['mode'] ) && in_array( $input['mode'], array( 'basic', 'advanced' ), true ) ) {
		$sanitized['mode'] = $input['mode'];
	} else {
		$sanitized['mode'] = 'basic';
	}

	// Number (range)
	if ( isset( $input['timeout'] ) ) {
		$timeout = absint( $input['timeout'] );
		$sanitized['timeout'] = max( 5, min( 300, $timeout ) ); // Clamp to 5-300
	}

	// Array field
	if ( isset( $input['allowed_ips'] ) && is_array( $input['allowed_ips'] ) ) {
		$sanitized['allowed_ips'] = array_map( 'sanitize_text_field', $input['allowed_ips'] );
	}

	return $sanitized;
}
```

### Settings Page HTML

```php
/**
 * Render settings page.
 */
function mypl_settings_page() {
	// Check user capability
	if ( ! current_user_can( 'manage_options' ) ) {
		return;
	}

	// Pages under Settings (add_options_page) print settings_errors()
	// automatically. Only top-level or other-menu pages need to call it,
	// or "Settings saved" shows twice.
	?>
	<div class="wrap">
		<h1><?php echo esc_html( get_admin_page_title() ); ?></h1>

		<form method="post" action="options.php">
			<?php
			// Output nonce, action, option_page fields
			settings_fields( 'mypl_options_group' );

			// Output sections and fields
			do_settings_sections( 'mypl-settings' );

			// Output save button
			submit_button( __( 'Save Settings', 'my-plugin' ) );
			?>
		</form>
	</div>
	<?php
}
```

### Common Settings API Mistakes

```php
// ❌ BAD: Field won't save (missing register_setting)
add_action( 'admin_init', 'mypl_bad_settings' );

function mypl_bad_settings() {
	add_settings_field( 'mypl_field', 'Field', 'mypl_callback', 'mypl-page', 'section' );
	// Missing register_setting() - form won't save!
}

// ❌ BAD: Section doesn't appear (wrong page slug)
add_settings_section( 'section', 'Title', 'callback', 'wrong-page' );
do_settings_sections( 'mypl-settings' ); // Slug mismatch

// ❌ BAD: Missing sanitize_callback (security risk)
register_setting( 'group', 'mypl_settings' ); // No sanitization!

// ✅ GOOD: Complete registration
register_setting( 'group', 'mypl_settings', array(
	'sanitize_callback' => 'mypl_sanitize',
) );
```

## Options API Best Practices

### Autoloading Options

**Autoload:** An autoloaded option is loaded into memory on every request.

WordPress 6.6+ changed the `$autoload` parameter of `add_option()`/`update_option()`:
- Pass `true` or `false`. The legacy `'yes'`/`'no'` strings still work but are deprecated in favor of booleans.
- The default is `null`: WordPress decides. Options larger than about 150 KB are not autoloaded by default.

```php
// ❌ BAD: Large, rarely-read data forced into autoload
update_option( 'mypl_import_log', $large_data, true );

// ✅ GOOD: Large or rarely-read data, explicitly not autoloaded
update_option( 'mypl_import_log', $large_data, false );

// ✅ GOOD: Small option read on most requests
update_option( 'mypl_settings', $settings, true );

// ❌ BAD: Using options for temporary data
update_option( 'mypl_cache_' . $key, $data ); // Use transients instead

// ✅ GOOD: Use transients for temporary data
set_transient( 'mypl_cache_' . $key, $data, HOUR_IN_SECONDS );
```

### Single Option vs Multiple Options

**Pattern 1: Single array option (RECOMMENDED)**

```php
// ✅ GOOD: One option, multiple settings
$settings = array(
	'api_key' => 'key',
	'enabled' => true,
	'timeout' => 30,
	'mode'    => 'advanced',
);
update_option( 'mypl_settings', $settings );

// Retrieve
$settings = get_option( 'mypl_settings' );
$api_key = $settings['api_key'];
```

**Pattern 2: Multiple separate options**

```php
// ❌ LESS EFFICIENT: One DB query per option when not autoloaded
// (autoloaded options share one alloptions query), and more cache entries either way
update_option( 'mypl_api_key', 'key' );
update_option( 'mypl_enabled', true );
update_option( 'mypl_timeout', 30 );
update_option( 'mypl_mode', 'advanced' );

// Each get_option() is a separate query if the option isn't autoloaded
$api_key = get_option( 'mypl_api_key' );
$enabled = get_option( 'mypl_enabled' );
// ...
```

**When to use multiple options:**
- Settings in different contexts (some autoload, some don't)
- Very large individual values
- Options updated independently by different features

Option names need the plugin prefix. Full prefix table: `architecture-patterns.md` → "Prefixing".

## REST API Endpoint Registration

**Note:** For security patterns (permission_callback, capability checks, nonces), see the `/wp-security-review` command. This section covers non-security aspects.

### Basic Endpoint Registration

```php
add_action( 'rest_api_init', 'mypl_register_rest_routes' );

function mypl_register_rest_routes() {
	register_rest_route(
		'mypl/v1',              // Namespace (plugin/version)
		'/books',               // Route
		array(
			'methods'             => 'GET',
			'callback'            => 'mypl_get_books',
			'permission_callback' => '__return_true', // Public endpoint
			'args'                => array(
				'per_page' => array(
					'default'           => 10,
					'sanitize_callback' => 'absint',
					'validate_callback' => 'mypl_validate_per_page',
				),
			),
		)
	);
}
```

### Route Parameters with Regex

```php
// Route with ID parameter
register_rest_route(
	'mypl/v1',
	'/books/(?P<id>\d+)', // Regex: \d+ = one or more digits
	array(
		'methods'             => 'GET',
		'callback'            => 'mypl_get_book',
		'permission_callback' => '__return_true',
		'args'                => array(
			'id' => array(
				'validate_callback' => function( $param ) {
					return is_numeric( $param );
				},
			),
		),
	)
);

function mypl_get_book( $request ) {
	$book_id = $request->get_param( 'id' );
	$book = get_post( $book_id );

	if ( ! $book || 'mypl_book' !== $book->post_type ) {
		return new WP_Error(
			'not_found',
			__( 'Book not found', 'my-plugin' ),
			array( 'status' => 404 )
		);
	}

	return rest_ensure_response( $book );
}
```

### HTTP Methods

```php
// Multiple methods on same route
register_rest_route(
	'mypl/v1',
	'/books/(?P<id>\d+)',
	array(
		// GET method
		array(
			'methods'             => 'GET',
			'callback'            => 'mypl_get_book',
			'permission_callback' => '__return_true',
		),
		// PUT method
		array(
			'methods'             => 'PUT',
			'callback'            => 'mypl_update_book',
			'permission_callback' => 'mypl_update_book_permission',
			'args'                => array(
				'title' => array(
					'required'          => true,
					'sanitize_callback' => 'sanitize_text_field',
					'validate_callback' => function( $param ) {
						return ! empty( $param ) && strlen( $param ) <= 200;
					},
				),
			),
		),
		// DELETE method
		array(
			'methods'             => 'DELETE',
			'callback'            => 'mypl_delete_book',
			'permission_callback' => 'mypl_delete_book_permission',
		),
	)
);

// Use WP_REST_Server constants
register_rest_route(
	'mypl/v1',
	'/books',
	array(
		'methods'             => WP_REST_Server::READABLE, // GET
		'callback'            => 'mypl_get_books',
		'permission_callback' => '__return_true',
	)
);

// Other constants:
// WP_REST_Server::CREATABLE  - POST
// WP_REST_Server::EDITABLE   - POST, PUT, PATCH
// WP_REST_Server::DELETABLE  - DELETE
// WP_REST_Server::ALLMETHODS - All methods
```

### Args: Sanitize, Validate, Default

```php
register_rest_route(
	'mypl/v1',
	'/search',
	array(
		'methods'             => 'GET',
		'callback'            => 'mypl_search',
		'permission_callback' => '__return_true',
		'args'                => array(
			// String parameter
			'query' => array(
				'required'          => true,
				'sanitize_callback' => 'sanitize_text_field',
				'validate_callback' => function( $param ) {
					return ! empty( $param ) && strlen( $param ) <= 100;
				},
			),
			// Integer parameter
			'page' => array(
				'default'           => 1,
				'sanitize_callback' => 'absint',
				'validate_callback' => function( $param ) {
					return $param > 0 && $param <= 1000;
				},
			),
			// Boolean parameter
			'include_private' => array(
				'default'           => false,
				'sanitize_callback' => 'rest_sanitize_boolean',
			),
			// Array parameter
			'categories' => array(
				'default'           => array(),
				'sanitize_callback' => function( $param ) {
					return array_map( 'absint', (array) $param );
				},
				'validate_callback' => function( $param ) {
					return is_array( $param );
				},
			),
		),
	)
);
```

### Responses

Return `rest_ensure_response( $data )` or a `WP_REST_Response` on success and a `WP_Error` with a `status` on failure. Returning a raw array also works.

### Schema Definition

`schema` is a route-level option. Put endpoints in a numerically indexed array and `schema` beside them. If `schema` sits inside a single-endpoint array (next to `callback`), `register_rest_route()` wraps that array as endpoint `[0]` and ignores `schema`.

```php
// ❌ BAD: schema inside the endpoint array (ignored)
register_rest_route( 'mypl/v1', '/books', array(
	'methods'             => 'GET',
	'callback'            => 'mypl_get_books',
	'permission_callback' => '__return_true',
	'schema'              => 'mypl_book_schema',
) );

// ✅ GOOD: Endpoints as a list, schema at route level
register_rest_route( 'mypl/v1', '/books', array(
	array(
		'methods'             => WP_REST_Server::READABLE,
		'callback'            => 'mypl_get_books',
		'permission_callback' => '__return_true',
	),
	'schema' => 'mypl_book_schema',
) );

function mypl_book_schema() {
	return array(
		'$schema'    => 'http://json-schema.org/draft-04/schema#',
		'title'      => 'book',
		'type'       => 'object',
		'properties' => array(
			'id'     => array(
				'description' => __( 'Unique identifier for the book.', 'my-plugin' ),
				'type'        => 'integer',
				'readonly'    => true,
			),
			'title'  => array(
				'description' => __( 'Book title.', 'my-plugin' ),
				'type'        => 'string',
			),
			'author' => array(
				'description' => __( 'Book author.', 'my-plugin' ),
				'type'        => 'string',
			),
		),
	);
}
```

## Transients API

### Basic Transient Operations

```php
// Set transient with expiration
set_transient( 'mypl_api_cache', $api_data, HOUR_IN_SECONDS );

// Get transient
$cached = get_transient( 'mypl_api_cache' );
if ( false === $cached ) {
	// Cache miss - fetch fresh data
	$cached = mypl_fetch_api_data();
	set_transient( 'mypl_api_cache', $cached, HOUR_IN_SECONDS );
}

// Delete transient
delete_transient( 'mypl_api_cache' );
```

### Transient Naming

```php
// ❌ BAD: Generic name (collision risk)
set_transient( 'cache', $data, HOUR_IN_SECONDS );

// ❌ BAD: Too long. Limit is 172 chars for the name you pass, because
// '_transient_timeout_' (19 chars) is prepended and option_name holds 191
set_transient( 'mypl_this_is_a_very_long_transient_name_that_exceeds_the_database_field_length_limit_and_will_be_truncated_causing_issues', $data, HOUR_IN_SECONDS );

// ✅ GOOD: Prefixed, descriptive, under 172 chars
set_transient( 'mypl_api_response', $data, HOUR_IN_SECONDS );
set_transient( 'mypl_user_' . $user_id . '_posts', $posts, DAY_IN_SECONDS );
```

### Choosing Expiration Time

```php
// ✅ GOOD: API response (1 hour)
set_transient( 'mypl_api_data', $data, HOUR_IN_SECONDS );

// ✅ GOOD: Daily report (24 hours)
set_transient( 'mypl_daily_report', $report, DAY_IN_SECONDS );

// ✅ GOOD: Expensive query (10 minutes)
set_transient( 'mypl_complex_query', $results, 10 * MINUTE_IN_SECONDS );

// ❌ BAD: No expiration. Without an object cache the transient is stored
// autoloaded and never expires. Use an option instead.
set_transient( 'mypl_permanent_data', $data, 0 );
```

### When to Invalidate Transients

```php
// Clear transient when data changes
add_action( 'save_post_mypl_book', 'mypl_clear_book_cache' );

function mypl_clear_book_cache( $post_id ) {
	delete_transient( 'mypl_all_books' );
	delete_transient( 'mypl_book_' . $post_id );
}

// Clear transient on settings update
add_action( 'update_option_mypl_settings', 'mypl_clear_cache_on_settings_change' );

function mypl_clear_cache_on_settings_change() {
	delete_transient( 'mypl_api_cache' );
}
```

## Custom Database Tables

### When to Use Custom Tables

**Decision guide:**

| Use Case | Solution | Why |
|----------|----------|-----|
| Plugin settings | Options API | Simple, cached, Multisite-compatible |
| Post metadata | Post Meta API | Attached to posts, WP_Query integration |
| User preferences | User Meta API | Attached to users, per-user storage |
| Large datasets | Custom table | Performance, complex queries |
| Logs/analytics | Custom table | High write volume, archiving |
| Relationships | Custom table | Many-to-many relationships |

### Creating Tables with dbDelta()

`dbDelta()` parses the SQL itself. Rules below are verified against `wp-admin/includes/upgrade.php`.

```php
register_activation_hook( __FILE__, 'mypl_create_tables' );

function mypl_create_tables() {
	global $wpdb;

	$table_name = $wpdb->prefix . 'mypl_logs';
	$charset_collate = $wpdb->get_charset_collate();

	// dbDelta() requirements:
	// - "CREATE TABLE name" exactly: no IF NOT EXISTS (parsed as the table name)
	// - Each field and key on its own line (the column list is split on newlines)
	// Normalized since WP 4.2, so not required: two spaces after PRIMARY KEY,
	// KEY vs INDEX, backticks, key order. Two spaces is a harmless convention.
	// datetime DEFAULT NULL: '0000-00-00' defaults fail under MySQL NO_ZERO_DATE
	$sql = "CREATE TABLE $table_name (
		id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
		user_id bigint(20) unsigned NOT NULL,
		action varchar(50) NOT NULL,
		data text,
		ip_address varchar(45) NOT NULL,
		user_agent varchar(255) NOT NULL DEFAULT '',
		created datetime DEFAULT NULL,
		PRIMARY KEY  (id),
		KEY user_id (user_id),
		KEY created (created)
	) $charset_collate;";

	require_once ABSPATH . 'wp-admin/includes/upgrade.php';
	dbDelta( $sql );

	// Store database version for upgrades
	add_option( 'mypl_db_version', '1.0' );
}
```

### dbDelta() Common Mistakes

```php
// ❌ BAD: Using $wpdb->query() (no upgrade path)
$wpdb->query( "CREATE TABLE $table_name (...)" );

// ❌ BAD: Missing charset/collate
$sql = "CREATE TABLE $table_name (...)";

// ✅ GOOD: Include charset/collate
$sql = "CREATE TABLE $table_name (...) $charset_collate;";

// ❌ BAD: IF NOT EXISTS (dbDelta reads the table name as "IF")
$sql = "CREATE TABLE IF NOT EXISTS $table_name (...)";

// ❌ BAD: Several fields on one line (dbDelta splits columns on newlines)
$sql = "CREATE TABLE $table_name (id int NOT NULL AUTO_INCREMENT, name varchar(50), PRIMARY KEY (id))";

// ✅ GOOD
$sql = "CREATE TABLE $table_name (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(50) NOT NULL,
	PRIMARY KEY  (id)
) $charset_collate;";
```

### Database Version Upgrades

```php
function mypl_check_db_version() {
	$installed_version = get_option( 'mypl_db_version', '0.0' );
	$current_version = '1.1';

	if ( version_compare( $installed_version, $current_version, '<' ) ) {
		mypl_upgrade_db( $installed_version, $current_version );
		update_option( 'mypl_db_version', $current_version );
	}
}

function mypl_upgrade_db( $from, $to ) {
	// Schema 1.1 added the user_agent column to the CREATE TABLE in
	// mypl_create_tables(). Rerunning it lets dbDelta() add the column.
	mypl_create_tables();
}

// Run on every load (cheap option read), not only on activation:
// activation hooks don't fire on plugin updates.
add_action( 'plugins_loaded', 'mypl_check_db_version' );
```

`dbDelta()` adds missing tables, columns, and keys, and alters changed column definitions. It never drops or renames columns. Use a guarded `ALTER TABLE` only for drops and renames.

## AJAX Handler Patterns

**Note:** For security patterns (nonces, capability checks), see the `/wp-security-review` command.

### Basic AJAX Handler

```php
// For logged-in users
add_action( 'wp_ajax_mypl_action', 'mypl_ajax_handler' );

// For logged-out users
add_action( 'wp_ajax_nopriv_mypl_action', 'mypl_ajax_handler' );

function mypl_ajax_handler() {
	// Nonce verification (see wp-security-review for details)
	check_ajax_referer( 'mypl_nonce', 'nonce' );

	// Capability check (see wp-security-review for details)
	if ( ! current_user_can( 'edit_posts' ) ) {
		wp_send_json_error( array(
			'message' => __( 'Permission denied', 'my-plugin' ),
		), 403 );
	}

	// Get and sanitize input
	$data = isset( $_POST['data'] ) ? sanitize_text_field( wp_unslash( $_POST['data'] ) ) : '';

	// Process
	$result = mypl_process_data( $data );

	// Send JSON response
	if ( $result ) {
		wp_send_json_success( array(
			'message' => __( 'Success', 'my-plugin' ),
			'result'  => $result,
		) );
	} else {
		wp_send_json_error( array(
			'message' => __( 'Failed', 'my-plugin' ),
		) );
	}
}
```

### Passing Data to JavaScript

```php
add_action( 'wp_enqueue_scripts', 'mypl_enqueue_ajax_script' );

function mypl_enqueue_ajax_script() {
	wp_enqueue_script( 'mypl-ajax', MYPL_URL . 'js/ajax.js', array( 'jquery' ), MYPL_VERSION, true );

	wp_localize_script( 'mypl-ajax', 'myplAjax', array(
		'ajaxurl' => admin_url( 'admin-ajax.php' ),
		'nonce'   => wp_create_nonce( 'mypl_nonce' ),
	) );
}
```

### REST API vs AJAX

**Prefer REST API for new code:**

| Aspect | AJAX (admin-ajax.php) | REST API |
|--------|----------------------|----------|
| **Bootstrap** | Full WordPress load, plus admin includes and every `admin_init` callback | Full WordPress load, no admin bootstrap |
| **Caching** | Harder | Easier |
| **Discoverability** | No | Yes (self-documenting) |
| **Standard** | WordPress-specific | Industry standard |
| **Use case** | Legacy support | New development |

## Cron API

### Scheduling Events

```php
register_activation_hook( __FILE__, 'mypl_schedule_cron' );

function mypl_schedule_cron() {
	// Check if already scheduled (prevent duplicates)
	if ( ! wp_next_scheduled( 'mypl_daily_sync' ) ) {
		wp_schedule_event( time(), 'daily', 'mypl_daily_sync' );
	}
}

// Hook to cron event
add_action( 'mypl_daily_sync', 'mypl_run_daily_sync' );

function mypl_run_daily_sync() {
	// Sync logic
	$data = mypl_fetch_remote_data();
	update_option( 'mypl_synced_data', $data );
}
```

### Unscheduling Events

```php
register_deactivation_hook( __FILE__, 'mypl_unschedule_cron' );

function mypl_unschedule_cron() {
	$timestamp = wp_next_scheduled( 'mypl_daily_sync' );
	if ( $timestamp ) {
		wp_unschedule_event( $timestamp, 'mypl_daily_sync' );
	}

	// Clear all scheduled events for this hook
	wp_clear_scheduled_hook( 'mypl_daily_sync' );
}
```

### Custom Cron Schedules

```php
add_filter( 'cron_schedules', 'mypl_add_cron_schedules' );

function mypl_add_cron_schedules( $schedules ) {
	// Prefix schedule keys: the array is shared with core and other plugins.
	$schedules['mypl_every_five_minutes'] = array(
		'interval' => 5 * MINUTE_IN_SECONDS,
		'display'  => __( 'Every 5 Minutes', 'my-plugin' ),
	);

	return $schedules;
}

// Core already provides 'hourly', 'twicedaily', 'daily', and 'weekly'.
// Don't redefine them under new names.

// Use custom schedule (guarded, in the activation callback)
function mypl_schedule_frequent_sync() {
	if ( ! wp_next_scheduled( 'mypl_frequent_sync' ) ) {
		wp_schedule_event( time(), 'mypl_every_five_minutes', 'mypl_frequent_sync' );
	}
}
```

WP-Cron runs only when someone visits the site. Short intervals on low-traffic sites fire late. For exact timing, recommend disabling WP-Cron and running a real system cron.

## Admin Menu API

### Adding Menu Pages

```php
add_action( 'admin_menu', 'mypl_add_admin_menu' );

function mypl_add_admin_menu() {
	// Top-level menu
	add_menu_page(
		__( 'My Plugin', 'my-plugin' ),  // Page title
		__( 'My Plugin', 'my-plugin' ),  // Menu title
		'manage_options',                 // Capability
		'my-plugin',                      // Menu slug
		'mypl_main_page',                 // Callback function
		'dashicons-book',                 // Icon
		20                                // Position
	);

	// Submenu page
	add_submenu_page(
		'my-plugin',                      // Parent slug
		__( 'Settings', 'my-plugin' ),    // Page title
		__( 'Settings', 'my-plugin' ),    // Menu title
		'manage_options',                 // Capability
		'my-plugin-settings',             // Menu slug
		'mypl_settings_page'              // Callback function
	);

	// Add to existing menu (Settings)
	add_options_page(
		__( 'My Plugin Settings', 'my-plugin' ),
		__( 'My Plugin', 'my-plugin' ),
		'manage_options',
		'my-plugin-settings',
		'mypl_settings_page'
	);
}
```

### Plugin Action Links

```php
add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), 'mypl_plugin_action_links' );

function mypl_plugin_action_links( $links ) {
	$settings_link = sprintf(
		'<a href="%s">%s</a>',
		esc_url( admin_url( 'admin.php?page=my-plugin-settings' ) ),
		esc_html__( 'Settings', 'my-plugin' )
	);

	array_unshift( $links, $settings_link );

	return $links;
}
```

## Cross-References

- **Plugin architecture and lifecycle:** See `architecture-patterns.md`
- **Hooks system for API integration:** See `hooks-guide.md`
- **OOP patterns for API classes:** See `oop-patterns.md`
- **Security patterns (nonces, capabilities, sanitization, permission_callback):** See the `/wp-security-review` command
