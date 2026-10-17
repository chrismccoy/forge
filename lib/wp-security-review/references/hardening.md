# WordPress Hardening and Platform Context

Defense-in-depth checks that sit outside the input/authorization/output pillars: direct file access guards, `wp-config.php` constants, upload MIME restrictions, and how hosting platforms change severity.

## Contents

- [Quick Reference Table](#quick-reference-table)
- [Direct File Access Prevention](#direct-file-access-prevention)
- [Security Constants (`wp-config.php`)](#security-constants-wp-configphp)
- [Debug Constants](#debug-constants)
- [Upload MIME Restrictions](#upload-mime-restrictions)
- [Platform Context](#platform-context)

## Quick Reference Table

| Check | Where | Severity if missing |
|-------|-------|---------------------|
| `defined( 'ABSPATH' ) \|\| exit;` | Top of every plugin/theme PHP file | INFO (WARNING if file runs logic on include) |
| `DISALLOW_FILE_EDIT` | `wp-config.php` | INFO |
| `FORCE_SSL_ADMIN` | `wp-config.php` | INFO (if SSL available) |
| `DISALLOW_UNFILTERED_HTML` | `wp-config.php` | INFO |
| `DISALLOW_FILE_MODS` | `wp-config.php` | INFO (high-security sites only) |
| Unique auth keys and salts | `wp-config.php` | INFO if placeholders; CRITICAL if real keys exposed (public repo, copied sample) |
| `WP_DEBUG_DISPLAY` / `display_errors` off in production | `wp-config.php` | INFO (WARNING if errors leak paths on public pages) |
| MIME allowlist on upload | Plugin handling uploads | CRITICAL if `'test_type' => false`; WARNING if custom upload path without type check |

## Direct File Access Prevention

PHP files under `wp-content/` are reachable by URL. Without a guard, a direct request runs the file outside WordPress: no auth, no nonce helpers, and often a full-path-disclosure error.

```php
// ❌ INFO: Missing ABSPATH check
<?php
// Plugin code here without security check

// ✅ GOOD: ABSPATH check at top of every PHP file
<?php
defined( 'ABSPATH' ) || exit;

// ✅ GOOD: Alternative pattern
if ( ! defined( 'ABSPATH' ) ) {
    die( 'Direct access not permitted.' );
}
```

**Severity:** INFO when the file only declares functions/classes (nothing executes). Raise to WARNING when the file runs logic at include time (reads `$_GET`, writes to DB, echoes output).

**Not needed:** the main `wp-config.php` and files intended as standalone endpoints.

**Template partials** loaded via `get_template_part()` produce output on include. A direct request usually fatals on the first WP function call, which leaks a path at most. Rate INFO unless the partial reads request data or writes data before the first WP call, then WARNING.

## Security Constants (`wp-config.php`)

```php
// ✅ Disable theme/plugin file editor in wp-admin
define( 'DISALLOW_FILE_EDIT', true );

// ✅ Force SSL for admin and login
define( 'FORCE_SSL_ADMIN', true );

// ✅ Remove unfiltered_html capability from all roles, including admins
define( 'DISALLOW_UNFILTERED_HTML', true );

// ✅ Disable plugin/theme install and update (high-security or deploy-managed sites)
define( 'DISALLOW_FILE_MODS', true );

// ❌ INFO: Placeholder keys
define( 'AUTH_KEY', 'put your unique phrase here' );

// ✅ GOOD: Unique keys from https://api.wordpress.org/secret-key/1.1/salt/
// AUTH_KEY, SECURE_AUTH_KEY, LOGGED_IN_KEY, NONCE_KEY,
// AUTH_SALT, SECURE_AUTH_SALT, LOGGED_IN_SALT, NONCE_SALT
```

Placeholder keys are not exploitable on their own. `wp_salt()` detects the placeholder (and any value duplicated across keys), ignores it, and uses a random salt stored in the database. Rate INFO: keys move with a DB dump, and config should be explicit.

Rate CRITICAL only when real keys are exposed: `wp-config.php` committed to a public repo, keys copied from a published tutorial, or keys shared across sites. Exposed keys allow forged auth cookies and nonces. Fix: rotate all eight values.

`DISALLOW_FILE_MODS` also blocks security updates from wp-admin. Recommend it only when deploys handle updates.

## Debug Constants

Debug output on a production site leaks file paths, plugin names, and query text to visitors. That helps an attacker map the site.

```php
// ❌ WARNING on production: errors print into public pages
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', true ); // default when WP_DEBUG is true

// ✅ GOOD: log privately, never display
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DEBUG_LOG', '/path/outside/webroot/debug.log' );
@ini_set( 'display_errors', '0' );

// ✅ GOOD: production default
define( 'WP_DEBUG', false );
```

`WP_DEBUG_LOG` set to `true` writes `wp-content/debug.log`, which is web-readable on most servers. Use a path outside the web root. Rate a public `debug.log` as WARNING.

Severity: INFO when display is on but no public page is shown to be affected; WARNING when errors appear on public pages or `debug.log` is reachable.

## Upload MIME Restrictions

`wp_handle_upload()` validates against `get_allowed_mime_types()` by default. That list already excludes `exe` and `swf`, never includes `php`, and drops `htm`/`html` for users without `unfiltered_html`. Removing those types in a filter changes nothing.

Restrict types per upload with an allowlist passed as `mimes`. The `upload_mimes` filter is global and changes every upload on the site, so use it only for site-wide policy.

```php
// ❌ CRITICAL: Type check disabled (CWE-434)
wp_handle_upload( $_FILES['upload'], array( 'test_form' => false, 'test_type' => false ) );

// ❌ No effect: types already excluded by core
add_filter( 'upload_mimes', function( $mimes ) {
    unset( $mimes['exe'], $mimes['php'] );
    return $mimes;
} );

// ✅ GOOD: Per-call allowlist
$file = wp_handle_upload( $_FILES['upload'], array(
    'test_form' => false,
    'mimes'     => array(
        'jpg|jpeg|jpe' => 'image/jpeg',
        'png'          => 'image/png',
        'pdf'          => 'application/pdf',
    ),
) );
```

**SVG warning:** adding `$mimes['svg'] = 'image/svg+xml'` allows stored XSS via `<script>` inside the SVG. Flag as WARNING unless the upload path sanitizes SVG markup (for example, with a dedicated SVG sanitizer library).

## Platform Context

Hosting changes which layers exist, not whether code must be secure. Never downgrade a code-level finding because the host has a WAF.

**Managed WordPress hosts** (WP Engine, Pantheon, Pressable, Kinsta, etc.):
- Often have platform WAF and malware scanning
- May block `eval`/`exec` at platform level
- Code must still be secure for portability

**WordPress VIP:**
- Strict code review; many functions prohibited (`eval`, `create_function`, direct filesystem writes, uncached remote requests)
- Provides `wpcom_vip_*` helpers; prefer them where VIP docs require
- Only when the target is VIP: flag prohibited functions as INFO tagged "VIP compliance" when not exploitable. VIP review rejects them, but severity tracks exploitability.

**Self-hosted / standard hosting:**
- No platform security layer beyond what code implements
- All three pillars (sanitize, authorize, escape) are the only defense
