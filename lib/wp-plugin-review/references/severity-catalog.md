# Severity Catalog

Classify every finding with these tables. Load this file before classifying any finding. Per-file detail for each PLG ID is in `review-checklist.md`.

"WordPress.org:" marks a severity for that context only. Findings not in the catalog are WARNING at most, labelled "(uncatalogued)", unless they cause rejection or a fatal error (say which).

## CRITICAL: rejection, broken behavior, or fatal errors

| ID | Check |
|---|---|
| PLG-01 | `register_uninstall_hook()` with a closure or object-instance callback (never runs). mu-plugin whose setup (tables, options, rewrite flush) relies on activation/deactivation hooks (never fire) |
| PLG-02 | Main file lacks `Plugin Name` header |
| PLG-03 | File that executes code at load lacks `defined( 'ABSPATH' ) \|\| exit;` |
| PLG-04 | Unprefixed global function, class, global variable, or `define()` constant. Generic root namespace (`App\`). String callback to a namespaced function without its namespace |
| PLG-05 | `uninstall.php` lacks `WP_UNINSTALL_PLUGIN` guard |
| PLG-06 | Post type or taxonomy registered before `init` (fatal on `plugins_loaded`: `$wp_rewrite` is null). `flush_rewrite_rules()` on `init` or any per-request hook |
| PLG-06/07 | Post type key over 20 chars, taxonomy over 32 (not registered), or unprefixed |
| PLG-08 | `add_settings_field()` with no `register_setting()` (never saves). `add_settings_section()`/`add_settings_field()` on a front-end hook such as `init` (fatal) |
| PLG-10 | Filter callback without `return` (yields `null`; confirm the hook is a filter). `accepted_args` below the callback's required parameters (`ArgumentCountError`) |
| PLG-11 | WordPress.org: text domain differs from slug or uses underscores. WordPress.org: i18n call without text domain (WARNING when it reuses a verbatim core string) |
| PLG-13 | `register_rest_route()` without `permission_callback`, or `__return_true` on a write route |
| — | `eval()`, encoded payloads, obfuscation. WordPress.org: no `readme.txt` or `readme.md` (any capitalization), or non-GPL-compatible license |
| — | Fatal at load, e.g. requiring a `vendor/autoload.php` that isn't shipped |

## WARNING: non-standard but functional

| ID | Check |
|---|---|
| PLG-01 | Setup or cleanup with no activation/deactivation hook. Deactivation flush without `unregister_post_type()` |
| PLG-04/18 | Unprefixed option, transient, meta keys, or custom hook names. Transients without expiration |
| PLG-05 | No uninstall cleanup of options, transients, tables, or user meta |
| PLG-06/07 | No `show_in_rest => true` on editor-facing types and their taxonomies |
| PLG-08/09 | `register_setting()` without `sanitize_callback` or `type`. Mismatched page/section slugs. Form missing `settings_fields()`/`do_settings_sections()` |
| PLG-10 | `remove_*()` priority mismatch. Default priority where order matters. `accepted_args` too low for optional parameters |
| PLG-11 | Outside WordPress.org: i18n call without text domain (none for a verbatim core string), or more than one domain (none if one domain is used consistently and loaded with `load_plugin_textdomain()`). Variable in a translatable string. if/else plurals instead of `_n()`. Translation before `after_setup_theme` (6.7+ notice) |
| PLG-13 | REST namespace without version. Args without sanitize/validate callbacks |
| PLG-14/15 | Heavy `admin-ajax.php` use where REST fits. Settings menu capability as broad as `read` |
| PLG-16 | `CREATE TABLE` via `$wpdb->query()` instead of `dbDelta()`. SQL `dbDelta()` can't parse (`IF NOT EXISTS`, fields not one per line). Hardcoded `wp_` prefix. Zero-date defaults |
| PLG-17 | `wp_schedule_event()` without `wp_next_scheduled()` guard, or not cleared on deactivation |
| — | Hardcoded `/wp-content/` paths. WordPress.org: deprecated functions (INFO elsewhere). WordPress.org: `readme.txt` with missing or invalid headers (`Stable tag`, `Tested up to`, `License`) |
| — | Autoloader without a namespace-prefix guard. Bundled libraries not namespace-scoped |

## INFO: improvements

| ID | Check |
|---|---|
| PLG-02 | Missing `Version`, `Text Domain`, `Domain Path`, `Requires at least`, or `Requires PHP` (last two WARNING on WordPress.org). Missing `License` header (CRITICAL on WordPress.org when no license is stated anywhere) |
| PLG-03 | Definition-only file without ABSPATH guard (recommend the guard) |
| PLG-04/10/11 | Namespaces instead of prefixes. Custom extensibility hooks. `_x()` or `esc_html__()` variants |
| PLG-15 | Page callback without its own `current_user_can()` |
| PLG-19 | No `function_exists()`/`class_exists()` guard around pluggable or bundled code |
| PLG-20 | Admin code or assets loading on the front end |
