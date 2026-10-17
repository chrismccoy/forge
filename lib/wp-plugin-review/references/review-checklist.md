# Plugin Review Checklist Reference

Detailed per-file checks and distribution-context rules. Load when reviewing a specific file type or when plugin context (WordPress.org, private, mu-plugin, drop-in) changes severity.

Every finding ID (PLG-01 to PLG-20, except PLG-12) has a section below. PLG-12 is the platform context that adjusts severity. It is not a finding.

## File-Type Checks

### Main Plugin File (e.g., `my-plugin.php`)

**Lifecycle hooks (PLG-01):**
- WARNING: Plugin has setup needs (tables, default options, rewrite rules) but no `register_activation_hook()` → No way to initialize
- WARNING: Plugin has temporary data (cron events, transients, rewrite rules) but no `register_deactivation_hook()` → No cleanup on deactivation
- WARNING: Deactivation flushes rewrite rules without first calling `unregister_post_type()` → The CPT was already registered on `init` this request, so the flush regenerates its rules
- Pattern: `register_activation_hook( __FILE__, 'callback' )` in the main plugin file (`__FILE__` must resolve to the main file)
- CRITICAL: `register_uninstall_hook()` with a closure or object-instance callback → Stored in the `uninstall_plugins` option, so it can't be called; uninstall cleanup never runs. Use a named function or static method
- Not applicable: plugins with no setup or temporary data, mu-plugins, drop-ins

**Plugin headers (PLG-02):**
- CRITICAL: Missing `Plugin Name` field → WordPress won't recognize plugin
- INFO: Missing `Text Domain` → Optional since WordPress 4.6 (defaults to slug). Recommended for clarity
- INFO: Missing `Requires at least` or `Requires PHP` → Can't enforce version requirements (WARNING on WordPress.org)
- INFO: Missing `Version` or `Domain Path`
- Text domain/slug mismatch is a PLG-11 finding. Do not report it again here

**ABSPATH check (PLG-03):**
- CRITICAL: File that executes code at load (output, `add_action()`, `require`, logic) lacks `defined( 'ABSPATH' ) || exit;` (or `WPINC` equivalent) → Direct request runs code outside WordPress
- INFO: Definition-only file (classes/functions, no top-level code) lacks the guard → Direct request executes nothing; guard still recommended
- Exempt: `uninstall.php` guarded by `WP_UNINSTALL_PLUGIN`
- Pattern to detect: PHP file with no ABSPATH or WPINC check. `scan.sh` classifies each one with the PHP tokenizer (`[executes code, line N]` / `[definition-only]`); HTML or calls inside a function or method body do not count. Confirm by reading the file

**Prefixing (PLG-04):**
- CRITICAL: Unprefixed function in global scope → Fatal "cannot redeclare" if another plugin uses same name
- CRITICAL: Unprefixed class in global scope → Fatal error if another plugin uses same name
- CRITICAL: Unprefixed global variables → Variable collision risk
- WARNING: Options/transients/meta keys without prefix → Database key collision
- Pattern: `function [a-z_]+\(` without plugin prefix (4-5 char minimum)
- Alternative: PHP namespaces remove the need to prefix functions and classes. Option, transient, and hook names still need a prefix

### Uninstall File (`uninstall.php`)

**WP_UNINSTALL_PLUGIN constant check (PLG-05):**
- CRITICAL: `uninstall.php` without `WP_UNINSTALL_PLUGIN` check → Can be executed directly
- Pattern: `if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) { exit; }`

**Cleanup completeness (PLG-05):**
- WARNING: No option cleanup (`delete_option()`) → Leaves plugin data in database
- WARNING: No transient cleanup (`delete_transient()`) → Database bloat
- WARNING: No custom table cleanup (`DROP TABLE`) → Orphaned tables
- WARNING: No user meta cleanup (`delete_metadata( 'user', ... )`) → User data remains
- Context: Only applies if plugin creates these data types. On multisite, cleanup must loop over sites

### Custom Post Type Files

**register_post_type() usage (PLG-06):**
- CRITICAL: Post type key exceeds 20 characters → `register_post_type()` returns `WP_Error` and the type is not registered
- CRITICAL: Post type key not prefixed → Query var conflict with WordPress core or other plugins
- CRITICAL: `flush_rewrite_rules()` on `init` or any per-request hook → Expensive DB write on every page load
- CRITICAL: `register_post_type()`/`register_taxonomy()` before `init` (file load, `plugins_loaded`) → `$wp_rewrite` is created after `plugins_loaded`: fatal `Error: Call to a member function add_rewrite_tag() on null` when rewrites are on (the default for public types; verified on WordPress 7.1). With `rewrite => false` it registers, but core still expects `init`
- WARNING: Missing `show_in_rest => true` on an editor-facing type → Classic editor only, no Block Editor
- Pattern: `register_post_type( 'key', array( ... ) )` hooked to `init`
- Correct flush: Activation hook, after registering the post type. Deactivation hook, after `unregister_post_type()`
- Best practice: Post type key max 20 chars, lowercase alphanumeric + dash/underscore

### Taxonomy Files

**register_taxonomy() usage (PLG-07):**
- CRITICAL: Taxonomy name exceeds 32 characters → `register_taxonomy()` returns `WP_Error` and the taxonomy is not registered
- CRITICAL: Taxonomy name not prefixed → Collision with core taxonomies or other plugins
- WARNING: Missing `show_in_rest => true` on a taxonomy attached to an editor-facing post type → Taxonomy panel missing in Block Editor
- Not a problem: Backend-only taxonomies without `show_in_rest`
- Pattern: `register_taxonomy( 'name', 'post_type', array( ... ) )` hooked to `init`

### Settings API Files

**register_setting() usage (PLG-08):**
- CRITICAL: `add_settings_field()` without corresponding `register_setting()` → `options.php` rejects the option; value never saves
- WARNING: `register_setting()` without `sanitize_callback` → Unsanitized data stored
- WARNING: `register_setting()` without `type` parameter → Type inference unreliable, REST schema missing
- Pattern: `register_setting( 'option_group', 'option_name', array( ... ) )` on `admin_init`, or on `init`/`rest_api_init` when `show_in_rest` is set. Don't flag `register_setting()` on `init`
- CRITICAL: `add_settings_section()`/`add_settings_field()` on a hook that fires on front-end requests (`init`, `plugins_loaded`) → Fatal: functions are only loaded in admin

**Settings API workflow (PLG-09):**
- WARNING: `add_settings_section()` page slug doesn't match `do_settings_sections()` call → Section won't render
- WARNING: `add_settings_field()` section ID doesn't match `add_settings_section()` ID → Field won't render
- WARNING: Form missing `settings_fields()` call → No nonce or option_page fields, options won't save
- WARNING: Form missing `do_settings_sections()` call → Fields won't render
- Pattern: Complete workflow requires `register_setting()` → `add_settings_section()` → `add_settings_field()` → form HTML with `settings_fields()` and `do_settings_sections()`

### Hooks Usage Files

**add_action/add_filter patterns (PLG-10):**
- WARNING: Hook priority left at default when order demonstrably matters (callback depends on another callback's output) → May run in wrong sequence
- CRITICAL: `accepted_args` lower than the callback's required parameter count → `ArgumentCountError` (fatal) when the hook fires
- WARNING: `accepted_args` too low for optional parameters → Callback silently uses defaults instead of the hook's data
- Pattern: `add_action( 'hook_name', 'callback', $priority, $accepted_args )`

**Filter return requirement (PLG-10):**
- CRITICAL: Filter callback doesn't return value → Filter yields `null`; content disappears or later callbacks hit TypeErrors
- Pattern: `add_filter( 'hook', 'callback' )` where callback has no return statement on some path
- Check: Every code path of every filter callback returns a value

**Hook removal (PLG-10):**
- WARNING: `remove_action()` or `remove_filter()` priority doesn't match registration → Won't remove hook
- Pattern: Callback and priority must match the original `add_action()`/`add_filter()` call
- Example: `add_action( 'init', 'callback', 15 )` requires `remove_action( 'init', 'callback', 15 )`
- Timing: Removal must run after the hook was added and before it fires

**Custom hooks for extensibility (PLG-10):**
- INFO: Plugin could provide custom hooks with `do_action()` or `apply_filters()` for extensibility
- Pattern: `do_action( 'myplugin_after_save', $data )` or `apply_filters( 'myplugin_modify_output', $output )`

### Internationalization (i18n) Files

**Text domain matching (PLG-11):**
- WordPress.org context: CRITICAL if the text domain differs from the plugin slug or uses underscores → translate.wordpress.org language packs never load; Plugin Check fails
- Other contexts: WARNING if i18n calls use more than one domain, or a domain the plugin never loads. No finding if one domain is used consistently and loaded with `load_plugin_textdomain()`
- Pattern: The WordPress.org slug is the directory name on wordpress.org/plugins/. A local checkout folder (`my-plugin-main`, `my-plugin-1.2`) may differ; confirm before reporting

**i18n function usage (PLG-11):**
- WARNING: `__()` or `_e()` without text domain parameter → Looks up the `default` (core) domain instead of the plugin's. CRITICAL on WordPress.org. Not a finding in private/mu context for a verbatim core string (WARNING on WordPress.org)
- WARNING: Variables embedded in translatable strings → Breaks translation extraction
- Pattern: ALWAYS `__( 'Text', 'text-domain' )` never `__( 'Text' )`
- Pattern: Use `sprintf( __( 'Text %s', 'domain' ), $var )` not `__( "Text $var", 'domain' )`

**Pluralization (PLG-11):**
- WARNING: Plural forms handled with if/else instead of `_n()` → Breaks languages with complex plural rules
- Pattern: Use `_n( 'singular', 'plural', $count, 'domain' )` for count-dependent strings

**Context-aware translation (PLG-11):**
- INFO: Could use `_x()` for disambiguation when same English word has different translations
- Pattern: `_x( 'Post', 'noun', 'domain' )` vs `_x( 'Post', 'verb', 'domain' )`

**Escaped translation variants (PLG-11):**
- INFO: Use `esc_html__()` or `esc_attr__()` for combined translation + escaping
- Pattern: `echo esc_html__( 'Text', 'domain' )` instead of `echo esc_html( __( 'Text', 'domain' ) )`

**Translation loading (PLG-11):**
- INFO: `load_plugin_textdomain()` optional for WordPress 4.6+ when translations come from translate.wordpress.org
- Pattern: Hook to `init` if called: `add_action( 'init', 'load_textdomain_callback' )`
- WARNING: Translation calls that run before `after_setup_theme` (at file load, on `plugins_loaded`, or on `setup_theme`) → WordPress 6.7+ logs a "Translation loading for the `<domain>` domain was triggered too early" `_doing_it_wrong` notice, and strings can resolve in the wrong locale. Core checks `! doing_action( 'after_setup_theme' ) && ! did_action( 'after_setup_theme' )`. Recommend loading on `init` or later, as the notice text does. Since 6.7.1 the notice fires only when a translation file exists for the current locale, so it never appears on en_US test sites. Check code order, not the debug log

### REST API Endpoints (PLG-13, surface-level)

**register_rest_route() usage:**
- CRITICAL: Missing `permission_callback` → WordPress 5.5+ `_doing_it_wrong` notice; route stays publicly reachable
- CRITICAL: `permission_callback => '__return_true'` on write operations → Unauthenticated access allowed
- Pattern: `register_rest_route( 'namespace/v1', '/route', array( ... ) )` on `rest_api_init` hook
- Note: `__return_true` is CORRECT for public read-only endpoints

**Namespace and versioning:**
- WARNING: Missing version in namespace → No API evolution path
- Pattern: Use `myplugin/v1` not just `myplugin`

**Parameter validation:**
- WARNING: Missing `sanitize_callback` in args → Unsanitized input
- WARNING: Missing `validate_callback` (or `type`/`enum` schema) in args → Invalid input accepted
- For security depth: See the `/wp-security-review` command

### AJAX Handlers (PLG-14, surface-level)

**Hook registration:**
- WARNING: Using `admin-ajax.php` for high-frequency calls → Loads full admin bootstrap per request; consider REST API
- Pattern: `add_action( 'wp_ajax_action_name', 'callback' )` for authenticated
- Pattern: `add_action( 'wp_ajax_nopriv_action_name', 'callback' )` for public

**Security checks:**
- Brief reminder: AJAX handlers need nonce verification (`check_ajax_referer()`) and capability checks
- For security depth: See the `/wp-security-review` command

### Admin Menus (PLG-15, surface-level)

**add_menu_page/add_submenu_page:**
- WARNING: Overly broad capability (e.g. `read`) for a page that changes settings → Subscribers can reach it
- INFO: Page callback doesn't repeat `current_user_can()` → Core already enforces the menu capability; a callback check is defense in depth
- Pattern: `add_menu_page( $title, $menu_title, 'manage_options', $slug, $callback )` on `admin_menu`

### Database Tables (PLG-16, surface-level)

**Table creation:**
- WARNING: Using `$wpdb->query( "CREATE TABLE..." )` instead of `dbDelta()` → Table works, but no schema upgrade path
- WARNING: Hardcoded `wp_` table prefix → Breaks on sites with custom `$table_prefix` and on multisite
- Pattern: `require_once ABSPATH . 'wp-admin/includes/upgrade.php'; dbDelta( $sql );`
- Pattern: `$wpdb->prefix` for table names, `$wpdb->get_charset_collate()` for charset/collation
- Note: `DROP TABLE` via `$wpdb->query()` in uninstall is correct; `dbDelta()` does not drop

**dbDelta SQL formatting requirements (verified against `wp-admin/includes/upgrade.php`):**
- WARNING: Several fields on one line → `dbDelta()` splits the column list on newlines, so it misreads the schema and issues wrong `ALTER` statements on upgrade
- WARNING: `CREATE TABLE IF NOT EXISTS ...` → `dbDelta()` matches `CREATE TABLE ([^ ]*)` and reads the table name as `IF`. Use plain `CREATE TABLE`, uppercase, one space before the name
- Not a finding: one space after `PRIMARY KEY`, `INDEX` instead of `KEY`, backticks around names, or keys listed before fields. Since WordPress 4.2 `dbDelta()` normalizes all of these. Two spaces after `PRIMARY KEY` is a harmless legacy convention
- WARNING: `DEFAULT '0000-00-00 00:00:00'` on datetime columns → Fails under MySQL `NO_ZERO_DATE` strict mode

### Cron Jobs (PLG-17, surface-level)

**wp_schedule_event() usage:**
- WARNING: `wp_schedule_event()` without checking `wp_next_scheduled()` → Duplicate schedules
- WARNING: Scheduled event not cleared on deactivation → Cron job continues after plugin disabled
- Pattern: Check `if ( ! wp_next_scheduled( 'hook' ) )` before `wp_schedule_event()`
- Pattern: `wp_clear_scheduled_hook( 'hook' )` in deactivation hook

### Transients (PLG-18, surface-level)

**set_transient() usage:**
- WARNING: Transient keys not prefixed → Key collision with other plugins
- WARNING: Transients without expiration → Autoloaded on every request like an option
- Note: Transients can vanish at any time (object cache eviction). Code must handle a `false` return
- Pattern: `set_transient( 'mypl_key', $value, HOUR_IN_SECONDS )`

### Function/Class Existence Checks (PLG-19)

- INFO: Pluggable or shared helper functions without `function_exists()` guard → Fatal if a bundled copy or another plugin declares the same name
- INFO: Bundled third-party library classes without `class_exists()` guard → Fatal when two plugins ship the same library
- Not needed: Prefixed or namespaced plugin-internal functions. Guards hide collisions there instead of fixing them

### Conditional Loading (PLG-20)

- INFO: Admin-only files required on every request → Wasted parsing on frontend; wrap in `is_admin()`
- INFO: Admin scripts/styles enqueued on `wp_enqueue_scripts`, or on every admin page → Use `admin_enqueue_scripts` and check `$hook_suffix`
- INFO: Frontend assets enqueued globally when only one shortcode/block uses them → Enqueue only when rendered
- Caveat: `is_admin()` is true for `admin-ajax.php` requests. `REST_REQUEST` is defined only from `parse_request` onward, so it can't gate loading at plugin load time

## Platform Context (PLG-12)

WordPress plugins operate in different distribution contexts. Adjust review severity based on context.

### WordPress.org Submission Context

**Strictest standards apply.** For submission reviews, confirm each item and list failures in the summary:

- [ ] `Plugin Name` header in main file
- [ ] Text domain equals plugin slug (lowercase, dashes). Confirm the real slug: a checkout folder like `my-plugin-main` is not the slug
- [ ] ABSPATH guard in every PHP file that executes code at load
- [ ] Every i18n call passes the text domain
- [ ] No deprecated WordPress functions (WARNING; detect with Plugin Check or `WP_DEBUG` deprecation notices; `scan.sh` does not check this)
- [ ] GPLv2-or-later compatible license header
- [ ] Valid `readme.txt` or `readme.md`, any capitalization (missing: CRITICAL; missing or invalid headers: WARNING)
- [ ] No hardcoded `/wp-content/` paths
- [ ] All global functions, classes, options, and transients prefixed
- [ ] No `eval()`, encoded payloads, or obfuscated code
- [ ] `Requires at least` and `Requires PHP` headers set (WARNING if missing)

Recommended, not required by WordPress.org: `uninstall.php` or `register_uninstall_hook()` removing the plugin's data.

If WP-CLI and a test site are available, recommend the official tool (in the admin: Tools > Plugin Check):

```bash
wp plugin install plugin-check --activate
wp plugin check <plugin-slug>
```

**WordPress.org context severity escalation:**
- Text domain differs from slug or uses underscores → CRITICAL (WARNING or no finding elsewhere)
- i18n call missing text domain → CRITICAL (WARNING elsewhere; WARNING on WordPress.org for a verbatim core string)
- Missing `Requires at least` or `Requires PHP` → WARNING (INFO elsewhere)
- Deprecated functions → WARNING (INFO elsewhere)
- Missing readme.txt or non-GPL-compatible license → CRITICAL (not applicable elsewhere)

### Private/Enterprise Plugin Context

**More flexibility.** No WordPress.org submission requirements.

**Relaxed requirements:**
- readme.txt not required (internal documentation acceptable)
- Can use proprietary license (no GPL requirement)
- Can use custom update mechanisms (no WordPress.org update system)

**Still important:**
- Prefixing to avoid conflicts with other plugins
- Lifecycle hooks for proper setup/cleanup
- Security best practices (see the `/wp-security-review` command)

### Must-Use Plugins (mu-plugins) Context

**Different loading behavior.** Must-use plugins load automatically before regular plugins.

**Key differences:**
- Only PHP files directly in `wp-content/mu-plugins/` load (alphabetically). Subfolders need a loader file
- Load before regular plugins
- Cannot be deactivated via admin UI
- **No activation/deactivation hooks** (they don't activate/deactivate, they just load)
- Can't be updated via WordPress admin (manual file replacement)

**Review adjustments for mu-plugins:**
- Not applicable: Missing `register_activation_hook()` / `register_deactivation_hook()` → Hooks never fire for mu-plugins
- CRITICAL: mu-plugin that *relies* on activation hooks for setup (tables, options, rewrite flush) → Setup never runs; move setup to a stored-version check on `init` or `plugins_loaded`
- Still need: Proper prefixing, ABSPATH checks, i18n, security practices

**Pattern to detect mu-plugin context:**
```php
// Check if plugin is loaded as must-use
if ( strpos( __FILE__, WPMU_PLUGIN_DIR ) !== false ) {
    // Running as must-use plugin - skip activation hooks
}
```

### Drop-In Plugins Context

**Special files with specific names.** Drop-ins replace WordPress core functionality.

**Drop-ins (from core's `_get_dropins()`):**
- `advanced-cache.php` → Page caching (needs `WP_CACHE`)
- `db.php` → Custom database class
- `db-error.php` → Custom database error page
- `install.php` → Custom installation script
- `maintenance.php` → Custom maintenance mode page
- `object-cache.php` → External object cache (Redis, Memcached)
- `php-error.php` → Custom PHP error page
- `fatal-error-handler.php` → Custom fatal error handler
- Multisite only: `sunrise.php` (needs `SUNRISE`), `blog-deleted.php`, `blog-inactive.php`, `blog-suspended.php`

**Review adjustments for drop-ins:**
- Skip standard plugin header checks (drop-ins don't use plugin headers)
- Skip activation hook checks (drop-ins load automatically)
- Skip text domain checks (usually internal, not user-facing)
- Focus on: Compatibility with WordPress core expectations for that drop-in type

**Pattern to detect drop-in:**
```php
// Drop-ins are in wp-content/ root, not plugins/
// Check filename against known drop-in names
// Compare against the list above, or call _get_dropins() in a WordPress context
```
