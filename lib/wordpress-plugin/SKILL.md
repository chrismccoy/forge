# WordPress Plugin Generator

Generate a complete, enterprise-grade WordPress plugin from scratch. Output is a full directory tree with production-ready PHP, JavaScript, CSS, and metadata files. No placeholders, no `TODO` comments, no missing security measures.

The skill takes seven inputs (five multiple-choice, two free-text), infers the plugin slug and architecture from those inputs, and produces every file required to install, activate, configure, and uninstall the plugin on a real WordPress site.

**Scope:** this skill only generates a brand-new plugin tree from scratch. For changes to an already-existing plugin (add a feature, settings page, endpoint, hook, or fix), defer to wp-builder-pro.

## Workflow

1. **Run the intake.** Collect all seven answers as described in the Intake section. Two are free-text (plugin name, feature detail). Five are multiple-choice checklists - four multi-select, one single-select.
2. **Derive the slug and constants.** From the plugin name, derive `kebab-case` slug, text domain (same as slug), `SCREAMING_SNAKE` constant prefix, and `PascalCase` namespace.
3. **Resolve scope.** From the multiple-choice answers, decide which classes to generate (Admin, Frontend, Database, AJAX, REST), which assets to enqueue, and which integration scaffolds to include.
4. **Generate the full plugin tree.** Every file must be fully filled in. **Forbidden-sentinel list (canonical):** no `TODO`, `TBD`, `FIXME`, or generic `{placeholder}` / "coming soon" text anywhere. This is distinct from the legitimate template tokens this skill derives and substitutes - `{plugin-slug}`, `{Namespace}`, `{Plugin Name}`, `{slug}` - which MUST be replaced with real values, not left literal. The "no placeholders" checks below refer to the forbidden list, not these template tokens.
5. **Write to disk.** Default root: `./{plugin-slug}/` in the current working directory. If that directory already exists, write to `./{plugin-slug}-new/` instead and tell the user.
6. **Verify, then report back.** Do not report completion until every item in the Quality checklist below is confirmed against the generated files. Then report the directory path, file count, and a one-line summary. Do not paste full file contents into chat - they are on disk.

## Intake

Collect all seven inputs before generating. `AskUserQuestion` allows at most 4 options per question and at most 4 questions per call, so the intake cannot be a single call:

- **Free-text (Q1 plugin name, Q3 feature detail):** ask as plain chat prompts - `AskUserQuestion` cannot take free text.
- **Multiple-choice (Q2, Q4, Q5, Q6, Q7):** each option list exceeds the 4-option cap. Present each as a plain-text **"select all that apply"** numbered checklist (Q4 is single-select) and let the user reply with the numbers or names. Use `AskUserQuestion` only for a narrowing sub-decision that genuinely fits within 4 options.
- **Every multi-select MUST offer an `Other (specify)` escape** so the user can name an unlisted mechanism, surface, or integration; route that free text into the relevant component scope.

If a plugin name arrived via `$ARGUMENTS`, pre-fill Q1 and confirm.

**Load `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin/references/intake-questions.md` before asking any intake question.** It holds the exact prompt text and every option list with what each option generates. Ask the questions in this order:

1. **Q1 - Plugin name** (free text). Use this exact name in the plugin header, `Plugin Name:` field, and main display labels.
2. **Q2 - Functionality** (multi-select): which WordPress mechanisms the plugin uses.
3. **Q3 - Specific feature detail** (free text, 2-4 sentences). Drives the domain logic, class naming, and readme copy.
4. **Q4 - Target users** (single-select): the primary audience.
5. **Q5 - Admin interface components** (multi-select).
6. **Q6 - Frontend display surfaces** (multi-select).
7. **Q7 - Third-party integrations** (multi-select).

## Inference rules

From the answers, derive without asking:

- **Slug** - `sanitize_title( plugin_name )`. Example: "Acme Bookings" → `acme-bookings`.
- **Text domain** - same as slug.
- **Constant prefix** - uppercase slug with hyphens → underscores. Example: `ACME_BOOKINGS_`.
- **PHP namespace** - PascalCase of slug. Example: `AcmeBookings`.
- **Main file name** - `{slug}.php`.
- **Singleton class name** - `{Namespace}\Plugin`.
- **Minimum WordPress version** - `6.0`.
- **Minimum PHP version** - `7.4` (8.0+ recommended).
- **License** - `GPL-2.0-or-later` with `License URI: https://www.gnu.org/licenses/gpl-2.0.html`.

## Required file structure and header

**Load `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin/references/plugin-structure.md` before generating files (Workflow step 4).** It holds the baseline directory tree (produce it, skipping files for unselected features, including the conditional `docs/` and `blocks/` folders) and the main file header template every `{slug}.php` opens with. Fill in real values; for `Plugin URI` / `Author` / `Author URI`, use the author's real details if known, otherwise omit those lines rather than shipping literal `example.com`.

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
