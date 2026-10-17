# Plugin Code Examples Reference

Short BAD/GOOD pairs, one per finding ID, for review reports. Adapt the `mypl_` prefix and `my-plugin` text domain to the reviewed plugin. Each section names the topic reference that holds the full workflow.

All examples follow WordPress PHP Coding Standards (spaces inside parentheses, `array()`, Yoda conditions).

## PLG-01: Lifecycle Hooks

Full lifecycle, version upgrades: `architecture-patterns.md` → "Activation / Deactivation / Uninstall".

**❌ BAD: Deactivation flush leaves CPT rules in place**
```php
function mypl_deactivate() {
    flush_rewrite_rules(); // mypl_book was registered on init, so its rules are rebuilt
}
```

**✅ GOOD**
```php
register_activation_hook( __FILE__, 'mypl_activate' );
function mypl_activate() {
    mypl_register_cpt();   // Register first so the flush includes the CPT rules
    flush_rewrite_rules();
}

register_deactivation_hook( __FILE__, 'mypl_deactivate' );
function mypl_deactivate() {
    unregister_post_type( 'mypl_book' );
    flush_rewrite_rules();
}
```

## PLG-02: Plugin Headers

**❌ BAD**
```php
<?php
/**
 * Plugin Name: My Plugin
 */
```

**✅ GOOD**
```php
<?php
/**
 * Plugin Name:       My Plugin
 * Description:       Short description.
 * Version:           1.0.0
 * Requires at least: 6.0
 * Requires PHP:      7.4
 * Author:            Example Co
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       my-plugin
 * Domain Path:       /languages
 */
```

## PLG-03: Direct Access Guard

**❌ BAD**
```php
<?php
require_once __DIR__ . '/includes/class-mypl-core.php';
mypl_boot();
```

**✅ GOOD**
```php
<?php
defined( 'ABSPATH' ) || exit;

require_once __DIR__ . '/includes/class-mypl-core.php';
mypl_boot();
```

## PLG-04: Prefixing and Namespacing

Namespaces, PSR-4: `oop-patterns.md`. What to prefix: `architecture-patterns.md` → "Prefixing".

**❌ BAD**
```php
function save_settings() { /* ... */ }
class Settings { /* ... */ }
update_option( 'settings', $value );
```

**✅ GOOD: Prefix**
```php
function mypl_save_settings() { /* ... */ }
class MyPL_Settings { /* ... */ }
update_option( 'mypl_settings', $value );
```

**✅ GOOD: Namespace (option names still prefixed)**
```php
namespace MyPlugin\Admin;

function save_settings() { /* ... */ }
add_action( 'admin_init', __NAMESPACE__ . '\save_settings' );
update_option( 'mypl_settings', $value );
```

## PLG-05: Uninstall

**❌ BAD**
```php
<?php // uninstall.php
delete_option( 'mypl_settings' );
```

**✅ GOOD**
```php
<?php // uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
    exit;
}

delete_option( 'mypl_settings' );
delete_option( 'mypl_db_version' );
delete_transient( 'mypl_cache' );
delete_metadata( 'user', 0, 'mypl_prefs', '', true );

global $wpdb;
$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}mypl_logs" );
```

## PLG-06 / PLG-07: Post Types and Taxonomies

**❌ BAD**
```php
add_action( 'init', function () {
    register_post_type( 'book', array( 'public' => true ) ); // Unprefixed, no REST
    flush_rewrite_rules();                                   // DB write every request
} );
```

**✅ GOOD**
```php
add_action( 'init', 'mypl_register_cpt' );
function mypl_register_cpt() {
    register_post_type( 'mypl_book', array(        // <= 20 chars
        'label'        => __( 'Books', 'my-plugin' ),
        'public'       => true,
        'show_in_rest' => true,
        'rewrite'      => array( 'slug' => 'books' ),
    ) );
    register_taxonomy( 'mypl_genre', 'mypl_book', array( // <= 32 chars
        'label'        => __( 'Genres', 'my-plugin' ),
        'show_in_rest' => true,
    ) );
}
// Flush only in activation/deactivation (see PLG-01).
```

## PLG-08 / PLG-09: Settings API

Full workflow with field callbacks and page HTML: `api-patterns.md` → "Settings API Complete Workflow".

**❌ BAD: Field without registered setting (never saves)**
```php
add_settings_section( 'mypl_main', 'Settings', '__return_null', 'mypl-settings' );
add_settings_field( 'mypl_api_key', 'API Key', 'mypl_api_key_cb', 'mypl-settings', 'mypl_main' );
```

**✅ GOOD**
```php
register_setting( 'mypl_group', 'mypl_settings', array(
    'type'              => 'array',
    'sanitize_callback' => 'mypl_sanitize_settings',
    'default'           => array(),
) );
add_settings_section( 'mypl_main', __( 'Settings', 'my-plugin' ), '__return_null', 'mypl-settings' );
add_settings_field( 'mypl_api_key', __( 'API Key', 'my-plugin' ), 'mypl_api_key_cb', 'mypl-settings', 'mypl_main' );

// In the page callback form (action="options.php"):
settings_fields( 'mypl_group' );       // Matches register_setting() group
do_settings_sections( 'mypl-settings' ); // Matches section/field page slug
```

## PLG-10: Hooks

Priority, removal of class-method hooks, custom hooks: `hooks-guide.md`.

**❌ BAD: Filter without return**
```php
add_filter( 'the_content', 'mypl_append' );
function mypl_append( $content ) {
    if ( is_single() ) {
        $content .= '<p>Footer</p>';
    }
} // Returns null: post content vanishes
```

**✅ GOOD**
```php
add_filter( 'the_content', 'mypl_append' );
function mypl_append( $content ) {
    if ( is_single() ) {
        $content .= '<p>Footer</p>';
    }
    return $content;
}
```

**❌ BAD: Second argument used but not requested**
```php
add_filter( 'the_title', 'mypl_title' ); // accepted_args defaults to 1
function mypl_title( $title, $post_id ) { /* ArgumentCountError */ }
```

**✅ GOOD**
```php
add_filter( 'the_title', 'mypl_title', 10, 2 );
function mypl_title( $title, $post_id ) {
    return 'mypl_book' === get_post_type( $post_id ) ? 'Book: ' . $title : $title;
}
```

**❌ BAD / ✅ GOOD: Removal must match priority**
```php
add_action( 'wp_footer', 'mypl_footer', 15 );
remove_action( 'wp_footer', 'mypl_footer' );     // ❌ Priority 10: no-op
remove_action( 'wp_footer', 'mypl_footer', 15 ); // ✅
```

## PLG-11: Internationalization

**❌ BAD**
```php
echo __( "You have $count messages", 'my-plugin' ); // Variable breaks extraction
echo __( 'Save Settings' );                          // No text domain
echo __( 'Save', 'my_plugin' );                      // Underscores, not the slug
```

**✅ GOOD**
```php
printf(
    /* translators: %d: number of messages */
    esc_html( _n( 'You have %d message', 'You have %d messages', $count, 'my-plugin' ) ),
    (int) $count
);
echo esc_html__( 'Save Settings', 'my-plugin' );
echo esc_html_x( 'Post', 'verb: submit', 'my-plugin' );
```

## PLG-13: REST Routes

Args, schema, responses: `api-patterns.md` → "REST API Endpoint Registration".

**❌ BAD**
```php
register_rest_route( 'mypl', '/items/(?P<id>\d+)', array(
    'methods'  => 'DELETE',
    'callback' => 'mypl_delete_item',
    // No version in namespace, no permission_callback: notice + public route
) );
```

**✅ GOOD**
```php
add_action( 'rest_api_init', function () {
    register_rest_route( 'mypl/v1', '/items/(?P<id>\d+)', array(
        'methods'             => WP_REST_Server::DELETABLE,
        'callback'            => 'mypl_delete_item',
        'permission_callback' => function () {
            return current_user_can( 'delete_posts' );
        },
        'args'                => array(
            'id' => array( 'type' => 'integer', 'required' => true, 'sanitize_callback' => 'absint' ),
        ),
    ) );
} );
```

## PLG-14: AJAX Handlers

Data passing, REST vs AJAX: `api-patterns.md` → "AJAX Handler Patterns".

**✅ GOOD: Minimal secure handler**
```php
add_action( 'wp_ajax_mypl_save', 'mypl_ajax_save' );
function mypl_ajax_save() {
    check_ajax_referer( 'mypl_save', 'nonce' );
    if ( ! current_user_can( 'edit_posts' ) ) {
        wp_send_json_error( null, 403 );
    }
    $data = isset( $_POST['data'] ) ? sanitize_text_field( wp_unslash( $_POST['data'] ) ) : '';
    update_option( 'mypl_data', $data );
    wp_send_json_success();
}
```

## PLG-15: Admin Menus

**❌ BAD: Settings page reachable by subscribers**
```php
add_menu_page( 'My Plugin', 'My Plugin', 'read', 'mypl', 'mypl_page' );
```

**✅ GOOD**
```php
add_action( 'admin_menu', function () {
    add_menu_page( __( 'My Plugin', 'my-plugin' ), __( 'My Plugin', 'my-plugin' ), 'manage_options', 'mypl', 'mypl_page' );
} );
```

## PLG-16: Custom Tables

Version upgrades, common mistakes: `api-patterns.md` → "Custom Database Tables".

**❌ BAD**
```php
$wpdb->query( "CREATE TABLE wp_mypl_logs (id int NOT NULL AUTO_INCREMENT, PRIMARY KEY (id))" );
```

**✅ GOOD**
```php
global $wpdb;
$table = $wpdb->prefix . 'mypl_logs';
$sql   = "CREATE TABLE $table (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  user_id bigint(20) unsigned NOT NULL,
  created datetime DEFAULT NULL,
  PRIMARY KEY  (id),
  KEY user_id (user_id)
) {$wpdb->get_charset_collate()};";

require_once ABSPATH . 'wp-admin/includes/upgrade.php';
dbDelta( $sql );
```

## PLG-17: Cron

Custom schedules: `api-patterns.md` → "Cron API".

**❌ BAD**
```php
add_action( 'init', function () {
    wp_schedule_event( time(), 'hourly', 'mypl_sync' ); // New event every request
} );
```

**✅ GOOD**
```php
function mypl_activate() {
    if ( ! wp_next_scheduled( 'mypl_sync' ) ) {
        wp_schedule_event( time(), 'hourly', 'mypl_sync' );
    }
}
function mypl_deactivate() {
    wp_clear_scheduled_hook( 'mypl_sync' );
}
register_activation_hook( __FILE__, 'mypl_activate' );
register_deactivation_hook( __FILE__, 'mypl_deactivate' );
```

## PLG-18: Transients

**❌ BAD**
```php
set_transient( 'feed', $data ); // Unprefixed, no expiry: autoloaded forever
```

**✅ GOOD**
```php
$data = get_transient( 'mypl_feed' );
if ( false === $data ) {          // Transients can vanish at any time
    $data = mypl_fetch_feed();
    set_transient( 'mypl_feed', $data, HOUR_IN_SECONDS );
}
```

## PLG-19: Existence Guards

**✅ GOOD: Guard bundled third-party code, not your own prefixed functions**
```php
if ( ! class_exists( 'Parsedown' ) ) {
    require_once __DIR__ . '/vendor/parsedown/Parsedown.php';
}
```

## PLG-20: Conditional Loading

Admin/public separation: `architecture-patterns.md` → "Conditional Loading".

**❌ BAD**
```php
add_action( 'wp_enqueue_scripts', function () {
    wp_enqueue_script( 'mypl-admin', plugins_url( 'admin.js', __FILE__ ) ); // Admin JS on frontend
} );
```

**✅ GOOD**
```php
if ( is_admin() ) {
    require_once __DIR__ . '/admin/class-mypl-admin.php';
}

add_action( 'admin_enqueue_scripts', function ( $hook_suffix ) {
    if ( 'toplevel_page_mypl' !== $hook_suffix ) {
        return;
    }
    wp_enqueue_script( 'mypl-admin', plugins_url( 'admin/admin.js', __FILE__ ), array(), '1.0.0', true );
} );
```
