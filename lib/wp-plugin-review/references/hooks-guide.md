# WordPress Hooks System Reference

Actions and filters for plugin review: lifecycle timing, priority, `accepted_args`, removal, custom hooks, and debugging. WordPress 6.x+. Examples follow WordPress PHP Coding Standards.

## Contents

- Quick Reference Table
- Actions vs Filters
- Hook Lifecycle (execution order, timing mistakes)
- Priority
- Accepted Args
- Removing Hooks (functions, class methods, timing)
- Custom Hooks for Extensibility
- Common Hooks by Task
- Hook Debugging
- Hook Anti-Patterns

## Quick Reference Table

| Function | Purpose | Parameters | Returns |
|----------|---------|------------|---------|
| `add_action()` | Register action callback | `$hook_name, $callback, $priority = 10, $accepted_args = 1` | `true` |
| `add_filter()` | Register filter callback | `$hook_name, $callback, $priority = 10, $accepted_args = 1` | `true` |
| `remove_action()` | Unregister action | `$hook_name, $callback, $priority = 10` | `bool` |
| `remove_filter()` | Unregister filter | `$hook_name, $callback, $priority = 10` | `bool` |
| `do_action()` | Fire custom action | `$hook_name, ...$args` | `void` |
| `do_action_ref_array()` | Fire action with array args | `$hook_name, $args` | `void` |
| `apply_filters()` | Fire custom filter | `$hook_name, $value, ...$args` | `mixed` |
| `has_action()` / `has_filter()` | Check registration; returns priority when callback given | `$hook_name, $callback = false` | `bool\|int` |
| `did_action()` | Count how many times action fired | `$hook_name` | `int` |
| `current_filter()` | Name of hook currently running | None | `string` |
| `doing_action()` / `doing_filter()` | Check if hook is currently running | `$hook_name = null` | `bool` |

## Actions vs Filters

**Actions** perform side effects. Return values are ignored.

**Filters** transform a value. Every code path must return a value.

```php
// ✅ GOOD: Action performs side effect, no return needed
add_action( 'save_post', 'mypl_save_metadata' );

function mypl_save_metadata( $post_id ) {
	update_post_meta( $post_id, 'mypl_processed', 1 );
}

// ❌ CRITICAL: Filter without return
add_filter( 'the_content', 'mypl_add_footer' );

function mypl_add_footer( $content ) {
	if ( is_single() ) {
		$content .= '<p>Footer text</p>';
	}
	// Missing return: filter yields null, post content disappears,
	// and later callbacks typed for string hit TypeErrors
}

// ✅ GOOD: Return on every path, even when unchanged
add_filter( 'the_content', 'mypl_add_footer' );

function mypl_add_footer( $content ) {
	if ( is_single() ) {
		$content .= '<p>Footer text</p>';
	}
	return $content;
}
```

**Which type a core hook is:**

| Use Case | Hook | Type |
|----------|------|------|
| Save metadata | `save_post` | Action |
| Log event | `wp_login` | Action |
| Enqueue scripts | `wp_enqueue_scripts` | Action |
| Adjust main query | `pre_get_posts` | Action (query object passed by reference; modify it, no return) |
| Modify post content | `the_content` | Filter |
| Change outgoing mail | `wp_mail` | Filter (array of `to`, `subject`, `message`, `headers`, `attachments`) |
| Change mail sender | `wp_mail_from` | Filter |

## Hook Lifecycle

### Execution Order (front-end and admin requests)

```
muplugins_loaded     Fires after mu-plugins and (multisite) network-activated plugins load,
                     BEFORE site-level plugins load. A site-activated plugin's callback never runs.
plugins_loaded       All active plugins loaded. Earliest hook for site-activated plugins.
                     Use for dependency checks and plugin bootstrapping.
setup_theme
after_setup_theme    Theme functions.php loaded.
init                 Register post types, taxonomies, shortcodes, blocks.
  widgets_init       Fires during init (priority 1).
wp_loaded            WordPress, plugins, and theme fully loaded.
```

**Admin requests (`wp-admin/admin.php`):**

```
admin_menu           Fires when wp-admin/menu.php loads.
admin_init           Fires after admin_menu on admin pages.
                     admin-ajax.php and admin-post.php fire admin_init WITHOUT admin_menu.
admin_enqueue_scripts( $hook_suffix )
```

**Front-end requests:**

```
parse_request        REST_REQUEST constant defined here for REST requests.
template_redirect    Before template loads. Safe place for redirects.
wp_enqueue_scripts
wp_head
(content filters such as the_content, the_title run during template rendering)
wp_footer
shutdown             Very last hook.
```

**REST requests:** `rest_api_init` fires when the REST server initializes. Register routes there.

### Hook Timing Mistakes

```php
// ❌ BAD: Registering CPT on plugins_loaded
add_action( 'plugins_loaded', 'mypl_register_post_type' );
// $wp_rewrite is created after plugins_loaded (wp-settings.php). A post type with
// rewrites (the default for public types) fatals: "Call to a member function
// add_rewrite_tag() on null". Core expects post types on init.

// ✅ GOOD
add_action( 'init', 'mypl_register_post_type' );

// ❌ BAD: Enqueuing scripts on init
add_action( 'init', 'mypl_enqueue_scripts' );
// Works, but the asset loads on every admin, front-end, AJAX, and REST request.

// ✅ GOOD: Enqueue on the context-specific hook
add_action( 'wp_enqueue_scripts', 'mypl_enqueue_scripts' );         // Front end
add_action( 'admin_enqueue_scripts', 'mypl_enqueue_admin_scripts' ); // Admin

// ❌ BAD: Settings sections/fields on init
add_action( 'init', 'mypl_add_settings_fields' );
// add_settings_section()/add_settings_field() are admin-only: fatal on front-end requests.

// ✅ GOOD: Sections and fields on admin_init
add_action( 'admin_init', 'mypl_add_settings_fields' );
// register_setting() may run on init; it must when the setting uses show_in_rest,
// because admin_init doesn't fire on REST requests.

// ❌ BAD: Checking for another plugin at file load
if ( class_exists( 'WooCommerce' ) ) { /* ... */ } // Fails if my-plugin loads first

// ✅ GOOD: Check after all plugins loaded
add_action( 'plugins_loaded', 'mypl_boot' );
```

## Priority

Lower number runs earlier. Default is 10. Callbacks with equal priority run in registration order.

```php
add_action( 'init', 'mypl_early', 5 );    // Before default-priority callbacks
add_action( 'init', 'mypl_default' );     // Priority 10
add_action( 'init', 'mypl_late', 20 );    // After default-priority callbacks
```

Core uses many priorities, not only 10. For example, core registers its own post types on `init` priority 0, and `widgets_init` fires from `init` priority 1. Do not assume "lower than 10 runs before core".

**When explicit priority matters:**

```php
// ❌ BAD: Order-dependent callbacks relying on registration order
add_filter( 'the_content', 'mypl_add_wrapper' ); // Must run last
add_filter( 'the_content', 'mypl_add_header' );  // Must run first

// ✅ GOOD: Explicit priorities state the dependency
add_filter( 'the_content', 'mypl_add_header', 5 );
add_filter( 'the_content', 'mypl_add_wrapper', 15 );

// ❌ BAD: Extreme priority with no reason
add_action( 'init', 'mypl_simple_function', -999 );
```

Do not flag default priority as a problem unless the callback demonstrably depends on another callback's output.

## Accepted Args

Parameter 4 of `add_action()`/`add_filter()` sets how many arguments WordPress passes. Default is 1.

```php
// ❌ BAD: Callback requires 2 args, registration passes 1
add_filter( 'the_title', 'mypl_modify_title' );

function mypl_modify_title( $title, $post_id ) {
	// Never runs: PHP throws ArgumentCountError ("Too few arguments") before the body
}

// ✅ GOOD
add_filter( 'the_title', 'mypl_modify_title', 10, 2 );

function mypl_modify_title( $title, $post_id ) {
	return 123 === $post_id ? 'Modified: ' . $title : $title;
}
```

**Common multi-arg hooks:**

| Hook | Args | Parameters |
|------|------|------------|
| `save_post` | 3 | `$post_id, $post, $update` |
| `the_title` | 2 | `$title, $post_id` |
| `wp_insert_post_data` | 4 | `$data, $postarr, $unsanitized_postarr, $update` |
| `post_updated` | 3 | `$post_id, $post_after, $post_before` |
| `transition_post_status` | 3 | `$new_status, $old_status, $post` |

Check the hook's `apply_filters()`/`do_action()` call on developer.wordpress.org for the full list.

## Removing Hooks

### Functions

Callback and priority must match the original registration.

```php
add_action( 'init', 'mypl_init_function', 15 );

remove_action( 'init', 'mypl_init_function', 15 ); // ✅ Removed
remove_action( 'init', 'mypl_init_function' );     // ❌ No-op: priority 10
```

### Class Methods

```php
class MyPL_Plugin {
	public function register_hooks() {
		add_action( 'init', array( $this, 'init' ) );
	}

	public function init() { /* ... */ }

	public function remove_hooks() {
		remove_action( 'init', array( $this, 'init' ) ); // ✅ Same instance
	}
}

// ❌ BAD: A different instance can't remove the first instance's hook
$a = new MyPL_Plugin();
$a->register_hooks();
$b = new MyPL_Plugin();
remove_action( 'init', array( $b, 'init' ) ); // No-op

// ✅ GOOD: Static methods remove by class name
add_action( 'init', array( 'MyPL_Static', 'init' ) );
remove_action( 'init', array( 'MyPL_Static', 'init' ) );
```

**Review implication:** If a plugin registers hooks on an instance it never exposes (no singleton accessor, no global, no static method), other code cannot remove those hooks. Flag as INFO when extensibility matters. Closures have the same problem and can't be removed at all.

### Removal Timing

Removal must run after the hook is added and before it fires.

```php
// ❌ BAD: Removing before the other plugin registers
remove_action( 'wp_footer', 'other_plugin_footer', 20 ); // At file load; may run first

// ✅ GOOD: Remove once all plugins have loaded
add_action( 'plugins_loaded', function () {
	remove_action( 'wp_footer', 'other_plugin_footer', 20 );
} );
```

## Custom Hooks for Extensibility

```php
function mypl_process_order( $order_id ) {
	$order = mypl_get_order( $order_id );

	/**
	 * Fires before an order is processed.
	 *
	 * @since 1.0.0
	 *
	 * @param int   $order_id Order ID.
	 * @param array $order    Order data.
	 */
	do_action( 'mypl_before_process_order', $order_id, $order );

	$result = mypl_internal_process( $order );

	/**
	 * Filters the order processing result.
	 *
	 * @since 1.0.0
	 *
	 * @param array $result   Processing result.
	 * @param int   $order_id Order ID.
	 */
	return apply_filters( 'mypl_order_result', $result, $order_id );
}
```

**Naming:** Prefix every custom hook (`mypl_`). Use `{prefix}_{noun}_{verb}` or before/after pairs (`mypl_before_save_order`, `mypl_after_save_order`). Avoid vague names like `mypl_process` or `hook_1`. Document each hook with a docblock containing `@since` and `@param`.

## Common Hooks by Task

| Task | Hook | Detail in |
|------|------|-----------|
| Register CPTs, taxonomies, shortcodes | `init` | `code-examples.md` PLG-06/07 |
| Settings sections and fields | `admin_init` (`register_setting()` on `init` if `show_in_rest`) | `api-patterns.md` → Settings API |
| Admin menu pages | `admin_menu` | `api-patterns.md` → Admin Menu API |
| REST routes | `rest_api_init` | `api-patterns.md` → REST API |
| AJAX handlers | `wp_ajax_{action}`, `wp_ajax_nopriv_{action}` | `api-patterns.md` → AJAX |
| Cron callbacks | Custom hook name passed to `wp_schedule_event()` | `api-patterns.md` → Cron API |
| Plugin action links | `plugin_action_links_{basename}` | `api-patterns.md` → Admin Menu API |
| Front-end assets | `wp_enqueue_scripts` | Below |
| Admin assets | `admin_enqueue_scripts` | Below |

```php
add_action( 'wp_enqueue_scripts', 'mypl_enqueue_assets' );

function mypl_enqueue_assets() {
	wp_enqueue_style( 'mypl-style', MYPL_PLUGIN_URL . 'public/css/style.css', array(), MYPL_VERSION );
	wp_enqueue_script( 'mypl-script', MYPL_PLUGIN_URL . 'public/js/script.js', array(), MYPL_VERSION, true );
}

add_action( 'admin_enqueue_scripts', 'mypl_admin_assets' );

function mypl_admin_assets( $hook_suffix ) {
	if ( 'toplevel_page_my-plugin' !== $hook_suffix ) {
		return; // Only on this plugin's page
	}
	wp_enqueue_script( 'mypl-admin', MYPL_PLUGIN_URL . 'admin/js/admin.js', array(), MYPL_VERSION, true );
}
```

## Hook Debugging

```php
// Priority of a registered callback (false if not registered)
$priority = has_action( 'init', 'mypl_init_function' );

// Has init fired yet?
if ( did_action( 'init' ) ) { /* ... */ }

// Which hook is running this callback?
error_log( 'Running on: ' . current_filter() );

// Inspect all callbacks on a hook (debug only)
global $wp_filter;
error_log( print_r( $wp_filter['init']->callbacks, true ) );
```

Enable `WP_DEBUG` and `WP_DEBUG_LOG` in `wp-config.php` to capture `_doing_it_wrong` notices for timing mistakes.

## Hook Anti-Patterns

| Anti-Pattern | Effect | Fix |
|--------------|--------|-----|
| Filter without return | Filter yields `null`; content vanishes or TypeErrors downstream | Return on every path |
| Too few `accepted_args` | `ArgumentCountError` (fatal) before callback body runs | Match `accepted_args` to signature |
| CPT registration before `init` | Fatal on `plugins_loaded` or file load when rewrites are on (`$wp_rewrite` is null) | Register on `init` |
| Checking other plugins at file load | Depends on alphabetical load order | Check on `plugins_loaded` |
| Closures or unexposed instances as callbacks | Other code can't remove them | Named functions, static methods, or an accessible instance |
| Priority mismatch on removal | `remove_action()` silently does nothing | Match registration priority |
| Removing before registration | Nothing to remove yet | Remove on a later hook |
| Unprefixed custom hook names | Collide with other plugins | Prefix every custom hook |

## Cross-References

- Lifecycle hooks (activation, deactivation, uninstall): `architecture-patterns.md`
- Namespaced callbacks and class-method callbacks: `oop-patterns.md`
- API-specific hooks (Settings, REST, AJAX, Cron, Menus): `api-patterns.md`
- Nonces, capabilities, sanitization: `/wp-security-review` command
