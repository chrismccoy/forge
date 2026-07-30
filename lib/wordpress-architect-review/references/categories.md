# Finding Categories

Group every finding under one of these categories. For each finding cite `file:line`, quote the exact offending code, tag severity (SEVERE / MODERATE / MINOR), and explain impact and fix. Maximum 5 findings per category, most severe first.

- **Architecture** - OOP vs procedural, namespacing, separation of concerns, file organization, prefix consistency, autoloading, dependency injection, single responsibility
- **Performance** - DB query count, `get_option` patterns, autoload flag usage, transient/object caching, output buffering cost, asset enqueue strategy, regex complexity, N+1 queries, `WP_Query` efficiency, lazy loading
- **Security** - nonce verification, capability checks, ABSPATH guard, sanitization (correct filter for data type - whitelist for enums, `sanitize_text_field` for strings, `esc_url_raw` for URLs, `absint` for IDs), escaping on output (`esc_html`, `esc_attr`, `esc_url`, `wp_kses_post`), SQL prepared statements, CSRF, file upload validation, SSRF, deserialization, `eval`/`create_function` usage, direct `$_GET`/`$_POST` access without `wp_unslash`
- **Correctness** - edge cases, type juggling (`==` vs `===`), null handling, magic string collisions, encoding handling, regex catastrophic backtracking, race conditions, idempotency of activation/deactivation hooks
- **WordPress Standards** - Settings API usage, `register_setting`, `wp_enqueue_style`/`_script` instead of inline, jQuery dependency declaration, `load_plugin_textdomain` / `load_theme_textdomain`, text domain matching slug, i18n functions (`__`, `_e`, `_n`, `_x`), `wp_localize_script` for JS data, REST API patterns, hook priorities, filter vs action correctness, transient API, options API, capability mapping, multisite awareness
- **Theme-specific (if theme)** - `wp_head()` / `wp_footer()` calls, `body_class()` / `post_class()`, template hierarchy adherence, `get_template_part`, `get_header`/`get_footer`, child theme compatibility, theme support declarations (`add_theme_support`), `the_content` filter usage, comment template, pagination, accessibility (skip links, ARIA, keyboard nav, focus states, alt text), block theme vs classic theme, `theme.json`, full-site editing readiness
- **Plugin-specific (if plugin)** - activation/deactivation/uninstall hooks, `uninstall.php` cleanup, `register_activation_hook`, DB schema migrations with `dbDelta`, version constants, version comparison on upgrade, plugin row meta, settings link in plugin row, capability requirements declared
- **Maintainability** - code duplication, function/method length, naming clarity, comment quality, dead code, hardcoded values vs constants, configuration vs convention, testability
- **Missing Infrastructure** - `readme.txt` (plugin) / `style.css` header (theme) completeness, `Requires PHP`, `Requires at least`, `Tested up to`, license file, changelog, screenshots, banner/icon assets, `composer.json`, autoloader, unit tests (PHPUnit), integration tests, CI workflow, coding standards config (`phpcs.xml`, WPCS), `.editorconfig`, `.gitignore`
- **Compatibility** - PHP version range support, WP version range, deprecated function usage (`get_currentuserinfo`, `mysql_*`, etc.), block editor compatibility, classic editor fallback, multisite, RTL support

## How categories roll up into the 10 scored areas

The scorecard scores 10 areas; the categories above map onto them as follows:

- **Security, Performance, Architecture, Correctness, WordPress Standards, Maintainability** - scored directly from the same-named categories.
- **Documentation** and **Testing** - scored from the **Missing Infrastructure** category (readme/headers/changelog → Documentation; PHPUnit/integration/CI → Testing).
- **Accessibility (theme) / UX (plugin admin)** - scored from the accessibility items in **Theme-specific** (themes) or admin-UX observations in **Plugin-specific** (plugins).
- **Internationalization** - scored from the i18n items in **WordPress Standards**.
- **Compatibility** findings fold into **WordPress Standards** and **Correctness** scores (deprecated APIs, version-range breaks); call them out explicitly in the Notes column.
