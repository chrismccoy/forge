# WP facts
Covers: WordPress plugins (PHP), CPTs/taxonomies, Gutenberg blocks, block themes (theme.json, patterns), REST, roles/capabilities, MySQL custom tables, WP-Cron, WooCommerce
Verified: 2026-09-29 against official documentation (WP 7.1.2; trunk 7.2-alpha). Re-verify facts older than 12 months.

## Architecture

### WP-01 Data and logic belong in a plugin, not the theme
- Trap: the theme registers CPTs, taxonomies, roles, REST routes or custom blocks, or loads the data plugin.
- Reality: a CPT registered in a theme vanishes from admin on theme switch. Theme rules call CPTs, blocks and roles plugin territory.
- Detect: CPT/REST/role registration in theme files; theme loading the plugin.
- Fix: data/logic in a plugin or mu-plugin; the theme only presents it.
- Source: register_post_type() - https://developer.wordpress.org/reference/functions/register_post_type/

### WP-02 mu-plugins: no subfolders, no activation hooks
- Trap: `mu-plugins/x/x.php` loads itself and runs its activation hook.
- Reality: only PHP files directly in `mu-plugins/` load; activation hooks never run there.
- Detect: mu-plugin folder with no root loader; setup in an activation hook.
- Fix: a root loader that `require`s the subfolder; setup via WP-03's version check.
- Source: Must Use Plugins - https://developer.wordpress.org/advanced-administration/plugins/mu-plugins/

### WP-03 Activation hooks do not run on update
- Trap: schema changes or new capabilities in `register_activation_hook` reach existing sites on update.
- Reality: activation hooks skip updates; roles/caps persist, and a repeat `add_role()` is a no-op.
- Detect: activation hook as the only migration path.
- Fix: store a schema-version option, compare on load, run migrations and cap grants when it changes.
- Source: Dev note - https://make.wordpress.org/core/2010/10/27/plugin-activation-hooks-no-longer-fire-for-updates/

## Data model

### WP-04 Native IDs, taxonomies, options
- Trap: UUID keys for posts/users; custom category tables; a one-row settings table.
- Reality: core objects use `bigint(20) unsigned` auto-increment IDs that REST, WP_Query and meta key on. Taxonomies are the native classification (REST filters, admin UI).
- Detect: `uuid` columns referencing posts/users; `*_categories` tables; a `settings` table.
- Fix: reference integer `ID`s; register taxonomies; use the Options/Settings API for singletons.
- Source: Taxonomies - https://developer.wordpress.org/plugins/taxonomies/

### WP-05 Post type keys and statuses
- Trap: post type `event_registration_entry`; status `scheduled`.
- Reality: keys max 20 chars, lowercase/`-`/`_`; core names (post, page, wp_block, wp_template…) are reserved. Scheduled posts use status `future`. The REST route is `/wp/v2/<post_type key>` (so `cvb_table`, not `cvb-tables`) unless `rest_base` is set; the same applies to taxonomies.
- Detect: keys over 20 chars; `scheduled` status; REST paths that differ from the key with no `rest_base`.
- Fix: short prefixed keys; `future`, or `register_post_status()`; set `rest_base` to match the documented route.
- Source: register_post_type() - https://developer.wordpress.org/reference/functions/register_post_type/

### WP-06 Autoload (6.6+) and transients
- Trap: `autoload='yes'` everywhere; logs in options; transients as the only copy of data.
- Reality: 6.6+ uses `on`/`off`/`auto*` (`yes`/`no` deprecated 6.7). Autoloaded options load every request; over 150 KB are not autoloaded by default. Transients may vanish before expiry.
- Detect: growing option arrays; transient-only data.
- Fix: autoload off for rare options; tables for growing data; transients only for regenerable data.
- Source: Transients - https://developer.wordpress.org/apis/transients/

## REST API

### WP-07 Collection filters take term IDs; unknown params are dropped
- Trap: `?department=sales`, `?meta_key=…`, `?per_page=500`.
- Reality: taxonomy params accept term ID arrays, not slugs. Only registered params reach WP_Query; others are ignored. `per_page` max 100.
- Detect: slug or custom params on core routes.
- Fix: resolve slugs to IDs, or register params via `rest_{post_type}_collection_params` and map them in `rest_{post_type}_query`.
- Source: REST Posts reference - https://developer.wordpress.org/rest-api/reference/posts/

### WP-08 Post response shape and meta
- Trap: custom top-level fields (`price`, `status`); `title` as a string.
- Reality: core owns id, date, slug, status, type, title, content, excerpt, author, meta and taxonomy keys; `title`/`content` are `{rendered, raw}` objects. Meta shows under `meta` only if registered `show_in_rest` and the type supports `custom-fields`; `_` keys are protected.
- Detect: flat custom fields or overwritten core keys.
- Fix: `register_post_meta()` with `show_in_rest`, or prefixed `register_rest_field()`.
- Source: Modifying Responses - https://developer.wordpress.org/rest-api/extending-the-rest-api/modifying-responses/

### WP-09 show_in_rest makes published posts public
- Trap: `public=false`/`publicly_queryable=false` keeps a CPT private over REST.
- Reality: with `show_in_rest=true` any `publish` post is readable by anonymous GET; `public` is not checked.
- Detect: private records in a show_in_rest CPT.
- Fix: non-public status, no show_in_rest, or custom routes. 5.5+ routes need `permission_callback` (`__return_true` if public).
- Source: Adding Custom Endpoints - https://developer.wordpress.org/rest-api/extending-the-rest-api/adding-custom-endpoints/

## Auth and capabilities

### WP-10 CPT and taxonomy capabilities
- Trap: a CPT gets its own caps; admins get invented caps automatically.
- Reality: `capability_type` defaults to `post` (any `edit_posts` role can create it); a custom one leaves `map_meta_cap` false unless set. No role, admin included, gets new caps until added. Taxonomy `assign_terms` defaults to `edit_posts`.
- Detect: restricted CPT without capability_type; `edit_others_posts` gating.
- Fix: own `capability_type` + `map_meta_cap => true`; grant caps to roles incl. admin; taxonomy `capabilities`; a dedicated cap per privileged action.
- Source: register_post_type() - https://developer.wordpress.org/reference/functions/register_post_type/

### WP-11 unfiltered_html skips kses
- Trap: "kses sanitizes all HTML".
- Reality: Administrators and Editors hold `unfiltered_html` on single site (only super admins on multisite), so their content is unfiltered; `DISALLOW_UNFILTERED_HTML` removes it. kses covers post fields and comments, never meta or custom tables.
- Detect: user HTML with no explicit sanitizing.
- Fix: sanitize each field (`sanitize_callback`, REST schema), escape on output; remove the cap or set the constant.
- Source: capabilities.php - https://github.com/WordPress/wordpress-develop/blob/trunk/src/wp-includes/capabilities.php

### WP-12 Nonces and REST auth
- Trap: nonces as one-time tokens or auth; REST fetch without a nonce.
- Reality: nonces last 12-24 h, are reusable and CSRF-only. Cookie REST calls without `X-WP-Nonce` (`wp_rest`) run as user 0, silently. External clients use Application Passwords (5.6+).
- Detect: "single-use" nonces.
- Fix: random DB-stored tokens for one-time links; `current_user_can()` for authorization.
- Source: Nonces - https://developer.wordpress.org/apis/security/nonces/

### WP-13 Salts, HMAC, environment
- Trap: one secret constant; `wp_hash_hmac()`; `WP_ENV`.
- Reality: 8 constants (AUTH/SECURE_AUTH/LOGGED_IN/NONCE `_KEY`+`_SALT`). `wp_hash_hmac()` does not exist; `wp_hash()` takes an algorithm in 6.8+. Core reads `WP_ENVIRONMENT_TYPE` (local/development/staging/production, default production).
- Detect: calls to `wp_hash_hmac`; `WP_ENV` checks.
- Fix: `hash_hmac('sha256', $d, wp_salt())`; `wp_get_environment_type()`.
- Source: wp-config.php - https://developer.wordpress.org/advanced-administration/wordpress/wp-config/

## Blocks and block themes

### WP-14 Block templates are static markup
- Trap: PHP or `__()` in .html templates; `register_nav_menus`; theme updates reach edited templates.
- Reality: a block theme needs `templates/index.html` (core checks it). Templates are block markup only; translatable text goes in `/patterns` PHP via `wp:pattern`. Site Editor saves go to the DB, override the file and inline pattern output. Navigation menus are `wp_navigation` posts.
- Detect: no `templates/index.html`; PHP in templates; menu locations.
- Fix: per-request data via dynamic blocks or bindings; Navigation block for menus.
- Source: Templates - https://developer.wordpress.org/themes/templates/introduction-to-templates/

### WP-15 Static blocks freeze output
- Trap: a JS `save` block shows live availability or prices.
- Reality: static output is stored at save. Dynamic blocks render per request via `render_callback` or block.json `render`. apiVersion 3 is current (6.3+).
- Detect: live data, no render callback.
- Fix: dynamic block, or client fetch.
- Source: Static vs dynamic - https://developer.wordpress.org/block-editor/getting-started/fundamentals/static-dynamic-rendering/

### WP-16 Block Bindings scope
- Trap: binding any block or attribute to meta.
- Reality: 6.5+; only listed core blocks/attributes (paragraph, heading, image, button; more in later releases). 6.9+ `block_bindings_supported_attributes` extends it. `core/post-meta` needs `show_in_rest` meta without `_` prefix.
- Detect: bindings on unlisted blocks or `_` meta.
- Fix: filter the list (6.9+) or use a dynamic block.
- Source: Bindings - https://developer.wordpress.org/block-editor/reference-guides/block-api/block-bindings/

## Jobs and caching

### WP-17 WP-Cron runs only on traffic
- Trap: "draw at 20:00 exactly"; reminders on quiet sites.
- Reality: WP-Cron fires on page loads; with no visits jobs wait.
- Detect: time-critical jobs, no system cron.
- Fix: `DISABLE_WP_CRON` + system cron requesting `wp-cron.php`; idempotent jobs.
- Source: Cron - https://developer.wordpress.org/plugins/cron/hooking-wp-cron-into-the-system-task-scheduler/

### WP-18 Page caches freeze values and nonces
- Trap: counts, availability or nonces in cached public HTML.
- Reality: cached HTML is served until purged; embedded nonces expire (12-24 h). REST sends no-cache only for logged-in users.
- Detect: page cache + server-rendered live values.
- Fix: volatile data and nonces via REST; purge on change.
- Source: Cache - https://developer.wordpress.org/advanced-administration/performance/cache/

## Custom tables

### WP-19 dbDelta and $wpdb
- Trap: dbDelta renames/drops columns or adds FKs; `$wpdb` has transactions.
- Reality: dbDelta needs one column per line, `PRIMARY KEY  (id)` (two spaces), no backticks; never drops columns; no FOREIGN KEY. No transaction API (raw `START TRANSACTION` needs InnoDB). `prepare()` has `%i` since 6.2.
- Detect: concatenated SQL; dbDelta renames.
- Fix: `$wpdb->prepare()` always; explicit ALTERs; `SELECT … FOR UPDATE` for seat/stock locks.
- Source: dbDelta() - https://developer.wordpress.org/reference/functions/dbdelta/

## WooCommerce

### WP-20 Orders are not posts (HPOS)
- Trap: `get_post()`, `WP_Query` or `get_post_meta()` on orders.
- Reality: HPOS is default on new stores since WooCommerce 8.2.
- Detect: orders via post APIs.
- Fix: `wc_get_order(s)`, `$order->update_meta_data()` + `save()`; declare `custom_order_tables` compatibility.
- Source: HPOS recipe book - https://developer.woocommerce.com/docs/features/high-performance-order-storage/recipe-book/

## Testing

### WP-21 Toolchain versions
- Trap: PHPUnit 10+ with `WP_UnitTestCase`; wp-scripts 28+ with a pre-6.6 minimum.
- Reality: core's suite needs yoast/phpunit-polyfills ^1.1, capping PHPUnit at 9.x. wp-scripts 28+ compiles JSX for the `react-jsx-runtime` handle added in WP 6.6.
- Detect: `phpunit ^10`; `Requires at least` < 6.6 with wp-scripts 28+.
- Fix: PHPUnit 9.6 + polyfills 1.x; older minimums: wp-scripts 27 or polyfill.
- Source: JSX in WordPress 6.6 - https://make.wordpress.org/core/2024/06/06/jsx-in-wordpress-6-6/ ; composer.json - https://github.com/WordPress/wordpress-develop/blob/trunk/composer.json

### WP-22 Test harness order and isolation
- Trap: an empty REST request expecting 403; lock/race tests in `WP_UnitTestCase`.
- Reality: REST validates args before `permission_callback` (missing required args give 400, not 403). Each `WP_UnitTestCase` test runs in a rolled-back transaction and `CREATE TABLE` becomes `CREATE TEMPORARY TABLE`, invisible to other connections.
- Detect: auth tests without args; concurrency tests in PHPUnit.
- Fix: valid args in auth tests; test concurrency on a real DB with parallel clients.
- Source: Test base - https://github.com/WordPress/wordpress-develop/blob/trunk/tests/phpunit/includes/abstract-testcase.php ; REST server - https://github.com/WordPress/wordpress-develop/blob/trunk/src/wp-includes/rest-api/class-wp-rest-server.php

### WP-23 Distributed plugins run on hosts you do not control
- Trap: a plugin for other sites requires Redis, system cron, a PHP extension or a deploy pipeline.
- Reality: installs vary; object cache, real cron and extensions may be missing. Unmet `Requires at least`/`Requires PHP` (`Requires Plugins` 6.5+) block activation: plugins since 5.2, themes (style.css) since 5.5.
- Detect: required Redis/cron/extensions.
- Fix: headers = tested range; check `wp_using_ext_object_cache()`/`extension_loaded()` and degrade; settings in options; `uninstall.php`.
- Source: validate_plugin_requirements - https://developer.wordpress.org/reference/functions/validate_plugin_requirements/

