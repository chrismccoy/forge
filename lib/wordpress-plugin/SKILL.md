# WordPress Plugin Generator

Generate a complete, enterprise-grade WordPress plugin from scratch. Output is a full directory tree with production-ready PHP, JavaScript, CSS, and metadata files. No placeholders, no `TODO` comments, no missing security measures.

The skill takes seven inputs (five multiple-choice, two free-text), infers the plugin slug and architecture from those inputs, and produces every file required to install, activate, configure, and uninstall the plugin on a real WordPress site.

**Scope:** this skill only generates a brand-new plugin tree from scratch. For changes to an already-existing plugin (add a feature, settings page, endpoint, hook, or fix), defer to wp-builder-pro.

## Workflow

1. **Run the multiple-choice intake.** Use `AskUserQuestion` to ask all seven questions. Two are free-text (plugin name, feature detail). Five are multiple-choice - four `multiSelect: true`, one single-select.
2. **Derive the slug and constants.** From the plugin name, derive `kebab-case` slug, `snake_case` text domain (same as slug), `SCREAMING_SNAKE` constant prefix, and `PascalCase` namespace.
3. **Resolve scope.** From the multiple-choice answers, decide which classes to generate (Admin, Frontend, Database, AJAX, REST), which assets to enqueue, and which integration scaffolds to include.
4. **Generate the full plugin tree.** Every file must be fully filled in. **Forbidden-sentinel list (canonical):** no `TODO`, `TBD`, `FIXME`, or generic `{placeholder}` / "coming soon" text anywhere. This is distinct from the legitimate template tokens this skill derives and substitutes - `{plugin-slug}`, `{Namespace}`, `{Plugin Name}`, `{slug}` - which MUST be replaced with real values, not left literal. The "no placeholders" checks below refer to the forbidden list, not these template tokens.
5. **Write to disk.** Default root: `./{plugin-slug}/` in the current working directory. If that directory already exists, write to `./{plugin-slug}-new/` instead and tell the user.
6. **Verify, then report back.** Do not report completion until every item in the Quality checklist below is confirmed against the generated files. Then report the directory path, file count, and a one-line summary. Do not paste full file contents into chat - they are on disk.

## Intake

Collect all seven inputs before generating. `AskUserQuestion` allows at most 4 options per question and at most 4 questions per call, so the intake cannot be a single call:

- **Free-text (Q1 plugin name, Q3 feature detail):** ask as plain chat prompts - `AskUserQuestion` cannot take free text.
- **Multiple-choice (Q2, Q4, Q5, Q6, Q7):** each option list below exceeds the 4-option cap. Present each as a plain-text **"select all that apply"** numbered checklist (Q4 is single-select) and let the user reply with the numbers or names. Use `AskUserQuestion` only for a narrowing sub-decision that genuinely fits within 4 options.
- **Every multi-select MUST offer an `Other (specify)` escape** so the user can name an unlisted mechanism, surface, or integration; route that free text into the relevant component scope.

If a plugin name arrived via `$ARGUMENTS`, pre-fill Q1 and confirm.

### Q1 - Plugin name (free text)

```
What is the plugin called? (e.g. "Acme Bookings", "Smart Redirects Pro", "Membership Tiers")
```

Use this exact name in the plugin header, `Plugin Name:` field, and main display labels.

### Q2 - Functionality (multi-select MC)

> Which WordPress mechanisms does the plugin use? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Custom Post Types & Taxonomies | `register_post_type()` + `register_taxonomy()` with capability mapping |
| Settings / Options Page | Full Settings API implementation with tabs and sanitization callbacks |
| Gutenberg Blocks | `block.json` + `register_block_type()` + edit.js + save.js + style.scss |
| Shortcodes | `add_shortcode()` with attribute sanitization and output escaping |
| REST API endpoints | `register_rest_route()` with `permission_callback` + schema |
| WP-CLI commands | `WP_CLI::add_command()` with subcommands and synopsis |
| Cron / Scheduled tasks | `wp_schedule_event()` + activation hook registration + cleanup on deactivate |
| Custom Database Tables | `dbDelta()` schema, charset/collation, indexes, version-bump migrations |
| User Roles / Capabilities | `add_role()` + `add_cap()` with proper cleanup on uninstall |
| Email Notifications | `wp_mail()` wrapper with templates and HTML headers |
| Frontend Forms | Nonced AJAX form with server-side validation |
| Dashboard Widget | `wp_add_dashboard_widget()` with cached data fetch |
| Import / Export | JSON/CSV export endpoint and import handler with file validation |
| Analytics / Activity Logging | Custom log table + admin viewer with filters |
| Custom User Meta | `register_meta()` + profile field rendering with sanitization |
| Other (specify) | Generate scaffolding for the mechanism the user names |

### Q3 - Specific feature detail (free text)

```
In 2-4 sentences, describe what the plugin actually DOES at the user level.
What problem does it solve? What is the happy-path user flow?
(Example: "Lets shop owners offer time-slot bookings on any WooCommerce product.
Customers pick a date and slot at checkout; staff see all bookings in a calendar
view in WP admin and receive an email when one is made.")
```

This drives the domain logic, naming of classes, and copy in the README.txt.

### Q4 - Target users (single-select MC)

> Who is the primary audience using this plugin? Pick one.

| Option | Implication |
|--------|-------------|
| Site administrators only | Generate admin-side features; minimal/no frontend output |
| Editors and authors | Generate role-aware capability checks; meta boxes on post screens |
| Frontend site visitors | Generate public-facing shortcodes/blocks; minimize admin surface |
| Developers (extending via hooks/API) | Generate documented hooks, filters, and REST endpoints; ship a `docs/` folder |
| Multisite network administrators | Generate network-activation support, `is_multisite()` branches, network settings page |
| Mixed / multiple of the above | Generate full surface (admin + frontend + extensibility) |
| Other (specify) | Adapt the surface to the audience the user names |

### Q5 - Admin interface components (multi-select MC)

> Which admin UI components does the plugin need? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Top-level admin menu | `add_menu_page()` with custom icon (dashicons) |
| Submenu under Settings | `add_options_page()` |
| Submenu under Tools | `add_management_page()` |
| Meta boxes on post types | `add_meta_box()` with nonce + capability check on save |
| Custom post type list-table screens | `WP_List_Table` subclass with sortable columns and bulk actions |
| Dashboard widget | `wp_add_dashboard_widget()` |
| Admin notices | Dismissible notices with user-meta persistence |
| Help tabs on plugin screens | `get_current_screen()->add_help_tab()` |
| None (frontend-only plugin) | Skip all admin UI scaffolding |
| Other (specify) | Generate the admin component the user names |

### Q6 - Frontend display surfaces (multi-select MC)

> How does the plugin render on the public site? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| Shortcodes | `add_shortcode()` handlers |
| Gutenberg blocks | `block.json` + React edit component + save function + frontend `render_callback` |
| Classic widgets | `WP_Widget` subclass |
| Template tags / functions | Public `acme_render_*()` functions for themes to call |
| Auto-injected via `the_content` filter | Filter-based injection with opt-out via post meta |
| REST-driven SPA / headless | REST endpoints + minimal client-side fetch demo |
| Custom page templates | `page-*.php` templates registered via `theme_page_templates` filter |
| None (admin-only plugin) | Skip all frontend scaffolding |
| Other (specify) | Generate the frontend surface the user names |

### Q7 - Third-party integrations (multi-select MC)

> Which external services or plugins does this integrate with? Select all that apply.

| Option | What it generates |
|--------|-------------------|
| None | Skip integration scaffolding |
| WooCommerce | Hooks into WC actions/filters; checks `class_exists( 'WooCommerce' )` before booting integration |
| BuddyPress / bbPress | Hooks into BP/bbP actions with `function_exists()` guards |
| Advanced Custom Fields (ACF) | Registers field groups via PHP; gracefully degrades if ACF inactive |
| Elementor | Custom widget class extending `Widget_Base` |
| External REST API | HTTP client wrapper using `wp_remote_get()` / `wp_remote_post()` with retries and error handling |
| Stripe or PayPal | Server-side payment intent / order creation with webhook handler |
| Mailchimp / ConvertKit / SendGrid | Newsletter signup handler; read the API key from a `wp-config.php` constant (recommended) or store it in an option, documented as plaintext - WordPress has no built-in option encryption, so never claim it is encrypted |
| Google Analytics / Tag Manager | Frontend tracking snippet enqueue with cookie-consent gate |
| OAuth providers (Google, GitHub, etc.) | OAuth callback handler + state nonce + user linking |
| Webhooks (incoming) | REST endpoint with HMAC signature verification |
| Webhooks (outgoing) | Async dispatcher using Action Scheduler if available, falls back to wp-cron |
| Other (specify) | Generate an integration scaffold for the service the user names |

## Inference rules

From the answers, derive without asking:

- **Slug** - `sanitize_title( plugin_name )`. Example: "Acme Bookings" → `acme-bookings`.
- **Text domain** - same as slug.
- **Constant prefix** - uppercase slug with hyphens → underscores. Example: `ACME_BOOKINGS_`.
- **PHP namespace** - PascalCase of slug. Example: `AcmeBookings`.
- **Main file name** - `{slug}.php`.
- **Singleton class name** - `{Namespace}\\Plugin`.
- **Minimum WordPress version** - `6.0`.
- **Minimum PHP version** - `7.4` (8.0+ recommended).
- **License** - `GPL-2.0-or-later` with `License URI: https://www.gnu.org/licenses/gpl-2.0.html`.

## Required file structure

Always produce this baseline tree. Skip files that correspond to unselected features (e.g. no `includes/class-rest-controller.php` if REST endpoints not picked).

```
{plugin-slug}/
├── {plugin-slug}.php                 ← main plugin file (header + bootstrap)
├── uninstall.php                     ← runs on plugin deletion
├── readme.txt                        ← WordPress.org format
├── readme.md                         ← GitHub-friendly mirror
├── composer.json                     ← autoload definition, dev deps optional
├── .gitignore
├── languages/
│   └── {plugin-slug}.pot             ← translation template (header populated)
├── includes/
│   ├── class-plugin.php              ← singleton, loads other components
│   ├── class-activator.php           ← activation hook handler
│   ├── class-deactivator.php         ← deactivation hook handler
│   ├── class-i18n.php                ← text domain loader
│   ├── class-admin.php               ← admin pages, menus, settings (if admin features picked)
│   ├── class-frontend.php            ← shortcodes, scripts, public hooks (if frontend picked)
│   ├── class-database.php            ← dbDelta schema, migrations (if custom tables picked)
│   ├── class-ajax.php                ← admin-ajax handlers (if AJAX picked)
│   ├── class-rest-controller.php     ← REST routes (if REST picked)
│   ├── class-cron.php                ← scheduled events (if cron picked)
│   ├── class-cli.php                 ← WP-CLI commands (if CLI picked)
│   ├── class-roles.php               ← role/capability management (if roles picked)
│   ├── class-cpt.php                 ← custom post types/taxonomies (if CPT picked)
│   ├── class-meta-boxes.php          ← meta box registration (if meta boxes picked)
│   ├── class-list-table.php          ← WP_List_Table subclass (if list tables picked)
│   ├── class-dashboard-widget.php    ← dashboard widget (if picked)
│   ├── class-notices.php             ← dismissible admin notices (if picked)
│   ├── class-integration-{name}.php  ← one per third-party integration picked
│   └── helpers.php                   ← procedural utilities
├── assets/
│   ├── css/
│   │   ├── admin.css
│   │   └── public.css
│   ├── js/
│   │   ├── admin.js
│   │   └── public.js
│   └── images/
│       └── icon.svg
├── blocks/                           ← only if Gutenberg blocks picked
│   └── {block-slug}/
│       ├── block.json
│       ├── edit.js
│       ├── save.js
│       ├── index.js
│       ├── editor.scss
│       └── style.scss
├── templates/                        ← user-overridable theme templates (if frontend picked)
│   └── {feature}-display.php
└── tests/
    └── README.md                     ← brief notes on running PHPUnit/WPCS
```

## Code-generation rules

These rules are non-negotiable. Every generated file is held to them.

### Security

- **Direct access guard** on every PHP file: `defined( 'ABSPATH' ) || exit;` immediately after the docblock.
- **Nonces** on every form, AJAX request, and REST mutation. `wp_create_nonce()` + `check_admin_referer()` / `wp_verify_nonce()` / `permission_callback`.
- **Capability checks** before any privileged action: `current_user_can( 'manage_options' )` (or stricter mapped capability for CPTs).
- **Sanitization on input** - `sanitize_text_field()`, `sanitize_email()`, `absint()`, `wp_kses_post()`, `esc_url_raw()` matched to the data type. Never store raw `$_POST`/`$_GET` values.
- **Escaping on output** - `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`. No `echo $var;` - only escaped variables reach the page.
- **Prepared statements** - every `$wpdb` query uses `$wpdb->prepare()` with `%s`/`%d`/`%f` placeholders. Never interpolate into SQL.
- **REST `permission_callback`** - never `__return_true` unless the route is intentionally public; document why if so.
- **Forbidden constructs** - no dynamic code execution helpers, no `extract()`, no `create_function()`, no remote includes, no unsafe deserialization.

### Standards & Style

- WordPress Coding Standards (WPCS) compliant. Spaces around array brackets `[ 'foo' ]`, Yoda conditions where applicable, `elseif` not `else if`.
- PHPDoc block on every class, every public method, every filter/action. `@since`, `@param`, `@return`, `@throws` where relevant.
- Class file naming: `class-{kebab-case}.php`.
- PHP open tag only - no `?>` at end of pure PHP files.

### Architecture

- Singleton main plugin class with `get_instance()` and a `private __construct()` that wires sub-components.
- Composition over inheritance for components - each class accepts its dependencies in the constructor.
- Hooks registered in dedicated `register_hooks()` methods on each component, called once from the bootstrapper.
- No business logic in the main plugin file beyond constants and the bootstrap call.

### Performance

- Object-cache-aware: `wp_cache_get()` / `wp_cache_set()` around expensive queries with the plugin slug as cache group.
- Transients for cross-request caching with sensible expirations.
- Asset enqueueing is **conditional** - never load admin assets on the frontend, never load on screens that don't need them. Use `get_current_screen()` checks.
- Versioned asset URLs (`filemtime()` or plugin version constant) for cache busting.
- Dependency arrays passed to `wp_enqueue_*()` - never assume globals.

### Database

- Custom tables created via `dbDelta()` (not raw `CREATE TABLE`) with charset/collation from `$wpdb->get_charset_collate()`.
- Indexes on every foreign key and every WHERE/ORDER BY column the plugin actually queries.
- Schema version stored in an option; activation hook compares it and runs migrations.
- `uninstall.php` drops all custom tables, options, user meta, post meta, and scheduled events the plugin created. No orphaned data.

### Internationalization

- Every user-facing string wrapped in `__()`, `_e()`, `esc_html__()`, `esc_html_e()`, `_n()`, `_x()`, etc. - with the plugin's text domain (matches slug).
- Text domain loaded on `plugins_loaded` via `load_plugin_textdomain()`.
- `.pot` file shipped in `languages/` with all extracted strings and full header (Project-Id-Version, Last-Translator, Language-Team, etc.).
- Translator comments where placeholders are non-obvious: `/* translators: %s is the user display name */`.

### Documentation

- File-level docblocks with `@package`, `@since`, `@license`.
- Class-level docblocks describing responsibility and dependencies.
- `readme.txt` in WordPress.org format with all required sections: `=== Plugin Name ===`, `Contributors`, `Tags`, `Requires at least`, `Tested up to`, `Stable tag`, `License`, `License URI`, then `== Description ==`, `== Installation ==`, `== Frequently Asked Questions ==`, `== Screenshots ==`, `== Changelog ==`, `== Upgrade Notice ==`.
- `readme.md` mirrors the same content in GitHub-friendly markdown.

### Uninstall

- `uninstall.php` runs only when invoked by WordPress - guard with `if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) { exit; }`.
- Removes: all options (`delete_option()`), transients, user meta, post meta, custom tables (`DROP TABLE IF EXISTS`), scheduled cron events, registered roles, registered capabilities.
- Multisite-aware: loops over `get_sites()` and runs cleanup per site, plus network options cleanup.

## Main file header template

Every plugin's `{slug}.php` opens with this header. Fill in real values - never leave placeholders. For `Plugin URI` / `Author` / `Author URI`: use the author's real details if known; otherwise omit those lines entirely rather than shipping literal `example.com`.

```php
<?php
/**
 * Plugin Name:       {Plugin Name}
 * Plugin URI:        https://example.com/{slug}
 * Description:       {One-line description derived from Q3.}
 * Version:           1.0.0
 * Requires at least: 6.0
 * Requires PHP:      7.4
 * Author:            {Author Name}
 * Author URI:        https://example.com
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       {plugin-slug}
 * Domain Path:       /languages
 *
 * @package {Namespace}
 */

defined( 'ABSPATH' ) || exit;
```

## Output rules

- Root directory: `./{plugin-slug}/` by default. Fall back to `./{plugin-slug}-new/` if the first exists; report the chosen path to the user.
- Every PHP file ends with a newline and no trailing `?>`.
- Encoding UTF-8, LF line endings throughout.
- After writing, print one line to chat: `Wrote {N} files to {path}. Activate via the WordPress admin → Plugins → {Plugin Name}.`
- Do NOT paste full source into chat - the user opens the files directly.

## Quality checklist

Before declaring done, verify every item:

- [ ] All seven intake answers captured (5 multi-choice, 2 free-text).
- [ ] Plugin slug, text domain, namespace, and constant prefix all derived consistently from the plugin name.
- [ ] Main plugin file has a complete header with no `{placeholder}` text.
- [ ] `defined( 'ABSPATH' ) || exit;` guard at the top of every PHP file.
- [ ] Every form/AJAX/REST mutation has nonce verification.
- [ ] Every privileged action has a capability check.
- [ ] Every user input passes through a sanitizer matched to its type.
- [ ] Every echoed variable passes through an escaping function matched to its context.
- [ ] Every `$wpdb` query uses `$wpdb->prepare()` with placeholders - no string interpolation into SQL.
- [ ] Every user-facing string is wrapped in an i18n function with the correct text domain.
- [ ] `readme.txt` in WordPress.org format with all required headers populated.
- [ ] `uninstall.php` removes every artefact the plugin creates (options, tables, meta, cron, roles, caps).
- [ ] Asset enqueueing is conditional - no admin assets on frontend, no public assets on every admin screen.
- [ ] Custom tables (if any) use `dbDelta()` with charset/collation and have indexes on queried columns.
- [ ] Multisite-aware activation, deactivation, and uninstall when "Multisite network administrators" was selected.
- [ ] No forbidden sentinel (`TODO`, `TBD`, `FIXME`, `{placeholder}`, "coming soon") remains in any file, and no template token (`{plugin-slug}`, `{Namespace}`, `{Plugin Name}`, `{slug}`) is left unsubstituted.
- [ ] No literal `example.com` shipped - real author URLs or those header lines omitted.
- [ ] Zero filler comments. PHPDoc only where required by standards; no narrative commentary.
