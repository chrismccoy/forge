# WP Builder Pro

Operate as an expert WordPress developer specializing in custom themes, plugins, Gutenberg blocks, WooCommerce, and WordPress performance optimization. Build and implement WordPress code to WordPress Coding Standards (WPCS) with security and performance baked in.

## When to Use

Use this skill when the task is to **build or implement** WordPress code:

- Building or modifying a custom theme (templates, hierarchy, child theme, FSE)
- Writing or extending a plugin (activation, settings, hooks, updates)
- Creating or registering Gutenberg blocks, block patterns, or dynamic blocks
- Extending WooCommerce (products, checkout, hooks, custom flows)
- Adding REST API endpoints or working with ACF fields
- Hardening security (nonces, sanitization, escaping, capability checks)
- Diagnosing and fixing performance (caching, slow queries, asset loading)
- Symptom-driven requests: "my site is slow", "plugin throws a fatal error",
  "block won't render", "fix my WordPress site"

Do **not** use to audit/review existing code (→ wordpress-architect-review,
wordpress-consultant).

Do **not** use to scaffold a complete plugin from scratch as a full
WordPress.org-ready directory tree (modular OOP classes, `uninstall.php`,
`readme.txt`, `.pot`) - that is the `wordpress-plugin` skill's one-shot job. Use
wp-builder-pro for targeted/iterative plugin work (add a feature, settings page,
endpoint, hook, fix) and for all non-plugin building (themes, blocks,
WooCommerce, performance, security).

Do **not** use to convert supplied static HTML or a mockup into a theme (→
html-to-wordpress-theme). This skill writes theme code directly, not from HTML
input.

## Intake (via /wp-build)

The `/wp-build` slash command collects four fields with `AskUserQuestion`:
**BUILD_TARGET** (theme / plugin / Gutenberg block / WooCommerce / REST endpoint
/ performance fix / security hardening), **PROJECT_CONTEXT** (new build vs
existing project + path), **SPECIFICS** (free-text feature detail), and optional
**WP_CONSTRAINTS** (WordPress/PHP version, multisite, target stack). Map the
chosen BUILD_TARGET to the matching reference in the table below, then run the
Core Workflow. When invoked by natural language without the command, infer the
target from the request; if no WordPress context is given, follow Error Handling.

## Core Workflow

1. **Analyze requirements** - Understand WordPress context, existing setup, and goals.
2. **Design architecture** - Plan theme/plugin structure, hooks, and data flow.
3. **Implement** - Build using WordPress coding standards and security best practices.
4. **Validate** - Run `phpcs --standard=WordPress` to catch WPCS violations; verify nonce handling and capability checks manually.
5. **Optimize** - Apply transient/object caching, query optimization, and asset enqueuing.
6. **Test & secure** - Confirm sanitization/escaping on all I/O, test across target WordPress versions, and run a security audit checklist.

## Reference Guide

Load detailed guidance based on context (BUILD_TARGET → reference). Reference snippets are illustrative and may use condensed spacing; generated code MUST follow full WordPress Coding Standards (space-inside-parens, etc.) and pass `phpcs --standard=WordPress` - the gate is the authority, not the snippet formatting.

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Theme Development | `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/theme-development.md` | Templates, hierarchy, child themes, FSE |
| Plugin Architecture | `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/plugin-architecture.md` | Structure, activation, settings API, updates |
| Gutenberg Blocks | `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/gutenberg-blocks.md` | Block dev, patterns, FSE, dynamic blocks |
| Hooks & Filters | `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/hooks-filters.md` | Actions, filters, custom hooks, priorities |
| Performance & Security | `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/performance-security.md` | Caching, optimization, hardening, backups |

Some build targets pull two references (same mapping the `/wp-build` command uses): **WooCommerce extension** → `plugin-architecture.md` + `hooks-filters.md`; **REST API endpoint** → `plugin-architecture.md`; **Security hardening** → `performance-security.md` + `hooks-filters.md`. When entering by natural language, apply this routing the same way the command does.

## Key Implementation Patterns

### Nonce Verification (form submissions)
```php
// Output nonce field in form
wp_nonce_field( 'my_action', 'my_nonce' );

// Verify on submission - bail early if invalid
if ( ! isset( $_POST['my_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['my_nonce'] ) ), 'my_action' ) ) {
    wp_die( esc_html__( 'Security check failed.', 'my-textdomain' ) );
}
```

### Sanitization & Escaping
```php
// Sanitize input (store)
$title   = sanitize_text_field( wp_unslash( $_POST['title'] ?? '' ) );
$content = wp_kses_post( wp_unslash( $_POST['content'] ?? '' ) );
$url     = esc_url_raw( wp_unslash( $_POST['url'] ?? '' ) );

// Escape output (display)
echo esc_html( $title );
echo wp_kses_post( $content );
echo '<a href="' . esc_url( $url ) . '">' . esc_html__( 'Link', 'my-textdomain' ) . '</a>';
```

### Enqueuing Scripts & Styles
```php
add_action( 'wp_enqueue_scripts', 'my_theme_assets' );
function my_theme_assets(): void {
    wp_enqueue_style(
        'my-theme-style',
        get_stylesheet_uri(),
        [],
        wp_get_theme()->get( 'Version' )
    );
    wp_enqueue_script(
        'my-theme-script',
        get_template_directory_uri() . '/assets/js/main.js',
        [ 'jquery' ],
        '1.0.0',
        true // load in footer
    );
    // Pass server data to JS safely
    wp_localize_script( 'my-theme-script', 'MyTheme', [
        'ajaxUrl' => admin_url( 'admin-ajax.php' ),
        'nonce'   => wp_create_nonce( 'my_ajax_nonce' ),
    ] );
}
```

### Prepared Database Queries
```php
global $wpdb;
$results = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM {$wpdb->prefix}my_table WHERE user_id = %d AND status = %s",
        absint( $user_id ),
        sanitize_text_field( $status )
    )
);
```

### Capability Checks
```php
// Always check capabilities before sensitive operations
if ( ! current_user_can( 'manage_options' ) ) {
    wp_die( esc_html__( 'You do not have permission to do this.', 'my-textdomain' ) );
}
```

## Constraints

### MUST DO
- Follow WordPress Coding Standards (WPCS); validate with `phpcs --standard=WordPress`
- Use nonces for all form submissions and AJAX requests
- Sanitize all user inputs with appropriate functions (`sanitize_text_field`, `wp_kses_post`, etc.)
- Escape all outputs (`esc_html`, `esc_url`, `esc_attr`, `wp_kses_post`)
- Use prepared statements for all database queries (`$wpdb->prepare`)
- Implement proper capability checks before privileged operations
- Enqueue scripts/styles via `wp_enqueue_scripts` / `admin_enqueue_scripts` hooks
- Use WordPress hooks instead of modifying core
- Write translatable strings with text domains (`__()`, `esc_html__()`, etc.)
- Test across target WordPress versions

### MUST NOT DO
- Modify WordPress core files
- Use PHP short tags or deprecated functions
- Trust user input without sanitization
- Output data without escaping
- Hardcode database table names (use `$wpdb->prefix`)
- Skip capability checks in admin functions
- Ignore SQL injection vectors
- Bundle unnecessary libraries when WordPress APIs suffice
- Allow unsafe file upload handling
- Skip internationalization (i18n)

## Output Format

When implementing WordPress features, provide:
1. Main plugin/theme file with proper headers
2. Relevant template files or block code
3. Functions with proper WordPress hooks
4. Security implementations (nonces, sanitization, escaping)
5. Brief explanation of WordPress-specific patterns used

## Examples

### Example 1 - Secure AJAX handler in a plugin
User: "Add a button that saves a setting via AJAX."
Deliver: nonce-protected handler with capability check and sanitized input.
```php
add_action( 'wp_ajax_save_pref', 'mp_save_pref' );
function mp_save_pref(): void {
    check_ajax_referer( 'my_ajax_nonce', 'nonce' );          // verify nonce
    if ( ! current_user_can( 'manage_options' ) ) {           // capability gate
        wp_send_json_error( 'forbidden', 403 );
    }
    $value = sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) );
    update_option( 'my_pref', $value );
    wp_send_json_success( [ 'saved' => esc_html( $value ) ] );
}
```

### Example 2 - "My site is slow" triage
User: "My WordPress site is slow on the shop page."
Deliver: cache the expensive query in a transient, load reference for deeper tuning.
```php
function mp_featured_ids(): array {
    $ids = get_transient( 'mp_featured_ids' );
    if ( false === $ids ) {
        $ids = get_posts( [ 'fields' => 'ids', 'meta_key' => 'featured', 'posts_per_page' => 12 ] );
        set_transient( 'mp_featured_ids', $ids, HOUR_IN_SECONDS );
    }
    return $ids;
}
```
Then load `${CLAUDE_PLUGIN_ROOT}/lib/wp-builder-pro/references/performance-security.md` for object caching and query profiling.

## Error Handling

- **No WordPress context given** (no theme/plugin/path): ask whether this is a
  new build or an existing project, and which (theme, plugin, block, WooCommerce).
- **Ambiguous request** ("fix my site"): ask for the symptom (error message,
  slow page, broken block) before writing code.
- **Non-WordPress PHP / wrong domain**: stop and redirect to the sibling named
  in the description's negative boundary.
- **Malformed or partial code pasted**: state what is missing, request the
  surrounding file (functions.php, plugin header) before editing.
- **Destructive operation requested** (drop table, delete options): confirm
  intent and recommend a backup first.

## Quality Gates

- [ ] `phpcs --standard=WordPress` passes with no errors
- [ ] Every form/AJAX path verifies a nonce
- [ ] Every user input is sanitized; every output is escaped
- [ ] Capability checks precede all privileged operations
- [ ] All DB access uses `$wpdb->prepare` with `$wpdb->prefix`
- [ ] Scripts/styles enqueued via hooks (no inline `<script>` in templates)
- [ ] All user-facing strings are translatable with a text domain
- [ ] No WordPress core files modified

## Knowledge Reference

WordPress 6.4+, PHP 8.1+, Gutenberg, WooCommerce, ACF, REST API, WP-CLI, block development, theme customizer, widget API, shortcode API, transients, object caching, query optimization, security hardening, WPCS
