# WordPress Input Sanitization Guide

Input sanitization ensures user-provided data is safe to store and process. This guide covers WordPress's type-specific sanitization functions, the distinction between sanitization and validation, and the critical `wp_unslash()` requirement.

**Contents:** Quick Reference Table · Sanitization vs Validation · Type-Specific Sanitization Functions · The wp_unslash() Requirement · Sanitizing Arrays and Complex Data (arrays, nested arrays, JSON, allow-lists) · REST API Arguments · Sanitization Is Not SQL Escaping · When NOT to Sanitize · Complete Input Handling Example

## Quick Reference Table

| Function | Input Type | Returns | When to Use |
|----------|-----------|---------|-------------|
| `sanitize_text_field()` | Single-line text | String | Text inputs, titles, single-line fields |
| `sanitize_textarea_field()` | Multi-line text | String | Textareas, descriptions, multi-line content |
| `sanitize_email()` | Email address | String or empty | Email inputs, returns valid email or empty |
| `sanitize_url()` | URL | String | URL inputs, removes invalid characters |
| `esc_url_raw()` | URL (strict) | String | URL storage, validates scheme, no encoding |
| `sanitize_file_name()` | Filename | String | File uploads, removes special chars |
| `sanitize_key()` | Option names, keys | String | Option keys, meta keys, lowercase alphanumeric |
| `sanitize_title()` | Slug-friendly text | String | Post slugs, URL-safe strings |
| `sanitize_html_class()` | CSS class name | String | CSS class inputs, alphanumeric + hyphen/underscore |
| `absint()` | Integer (positive) | Integer | IDs, counts, non-negative numbers |
| `intval()` | Integer (any) | Integer | Signed integers |
| `floatval()` | Float/decimal | Float | Prices, percentages, decimals |
| `wp_unslash()` | Any POST/GET/COOKIE/REQUEST/SERVER | String/Array | **ALWAYS call first** — core slashes all superglobals via `wp_magic_quotes()` |
| `wp_kses()` | HTML with allowed tags | String | Rich text with specific HTML tags allowed |
| `wp_kses_post()` | Post content HTML | String | Trusted user content (editors/admins) |

## Sanitization vs Validation

**Sanitization** transforms input to make it safe, removing or encoding dangerous content.
**Validation** checks if input meets requirements and rejects invalid input.

Use **sanitization** to accept input and make it safe.
Use **validation** when input must meet strict requirements or be rejected.

```php
// ❌ BAD: Validation when sanitization needed
$title = $_POST['title'];
if ( preg_match( '/^[a-zA-Z0-9 ]+$/', $title ) ) { // Too strict! Rejects many valid titles
    update_post_meta( $post_id, 'title', $title );
} else {
    wp_die( 'Invalid title' );
}

// ✅ GOOD: Sanitization accepts and cleans input
$title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
update_post_meta( $post_id, 'title', $title ); // Stores safe version

// ❌ BAD: Sanitization when validation needed
$email = sanitize_email( wp_unslash( $_POST['email'] ) ); // Returns empty if invalid
if ( empty( $email ) ) {
    // Too late! Lost original input for error message
    wp_die( 'Invalid email' );
}

// ✅ GOOD: Validation first, then sanitization
$email_raw = isset( $_POST['email'] ) ? wp_unslash( $_POST['email'] ) : '';
if ( ! is_email( $email_raw ) ) {
    wp_die( 'Please enter a valid email address: ' . esc_html( $email_raw ) );
}
$email = sanitize_email( $email_raw );
update_user_meta( $user_id, 'email', $email );
```

### When to Use Each

**Use sanitization for:**
- User-generated content (titles, descriptions, bios)
- Optional fields (can be empty or contain various characters)
- Content that should be cleaned and accepted

**Use validation for:**
- Required fields
- Specific formats (email, phone, date)
- Business logic constraints (stock > 0, price > minimum)
- Access control (checking permissions before allowing action)

```php
// Sanitization example: Accept and clean user bio
$bio = isset( $_POST['bio'] ) ? sanitize_textarea_field( wp_unslash( $_POST['bio'] ) ) : '';
update_user_meta( $user_id, 'bio', $bio ); // Always succeeds

// Validation example: Require valid email
$email = isset( $_POST['email'] ) ? wp_unslash( $_POST['email'] ) : '';
if ( ! is_email( $email ) ) {
    return new WP_Error( 'invalid_email', 'Please provide a valid email' );
}
update_user_meta( $user_id, 'contact_email', sanitize_email( $email ) );
```

## Type-Specific Sanitization Functions

### sanitize_text_field() — Single-Line Text

Use for text inputs, titles, names, and any single-line text field. Strips tags, line breaks, octets, and extra whitespace.

```php
// ❌ BAD: Using raw $_POST data
$name = $_POST['name'];
update_user_meta( $user_id, 'display_name', $name ); // Stores HTML tags, scripts!

// ❌ BAD: Forgetting wp_unslash()
$name = sanitize_text_field( $_POST['name'] ); // Sanitizer sees slashed input ("O\'Reilly")
update_option( 'prefix_display_name', $name );  // Stored with the backslash

// ✅ GOOD: isset() + wp_unslash() + sanitize_text_field()
$name = isset( $_POST['name'] ) ? sanitize_text_field( wp_unslash( $_POST['name'] ) ) : '';
update_option( 'prefix_display_name', $name );

// ✅ GOOD: Meta API — update_*_meta() calls wp_unslash() itself, so re-slash first
// (otherwise real backslashes in the value are stripped)
update_user_meta( $user_id, 'prefix_display_name', wp_slash( $name ) );

// ✅ GOOD: With empty check
$title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
if ( ! empty( $title ) ) {
    update_post_meta( $post_id, 'custom_title', $title );
}

// ✅ GOOD: Array of text fields
$fields = isset( $_POST['fields'] ) ? (array) wp_unslash( $_POST['fields'] ) : array();
$fields = array_map( 'sanitize_text_field', $fields );
update_option( 'prefix_fields', $fields );
```

**What it does:**
- Removes all HTML tags
- Removes line breaks (`\n`, `\r`)
- Strips percent-encoded octets (`%XX`)
- Returns an empty string for invalid UTF-8
- Removes extra whitespace
- Trims leading/trailing spaces

**Use for:**
- Text inputs: `<input type="text">`
- Post titles
- User names
- Product names
- Short descriptions

### sanitize_textarea_field() — Multi-Line Text

Use for textarea content. Like `sanitize_text_field()` but preserves line breaks.

```php
// ❌ BAD: Using sanitize_text_field() on textarea
$description = sanitize_text_field( wp_unslash( $_POST['description'] ) );
// Line breaks removed! Multi-paragraph text becomes single line.

// ✅ GOOD: Use sanitize_textarea_field()
$description = isset( $_POST['description'] ) ? sanitize_textarea_field( wp_unslash( $_POST['description'] ) ) : '';
update_post_meta( $post_id, 'description', $description );

// ✅ GOOD: User bio with line breaks
$bio = isset( $_POST['bio'] ) ? sanitize_textarea_field( wp_unslash( $_POST['bio'] ) ) : '';
update_user_meta( $user_id, 'bio', $bio );

// ✅ GOOD: Admin notes field
$notes = isset( $_POST['admin_notes'] ) ? sanitize_textarea_field( wp_unslash( $_POST['admin_notes'] ) ) : '';
update_option( 'prefix_admin_notes', $notes );
```

**What it does:**
- Removes all HTML tags
- Preserves line breaks (`\n`, `\r`)
- Removes octets
- Trims leading/trailing spaces

**Use for:**
- Textareas: `<textarea>`
- Multi-line descriptions
- User bios
- Admin notes
- Any text that needs line breaks

### sanitize_email() — Email Addresses

Use for email inputs. Returns valid email or empty string.

```php
// ❌ BAD: Storing unvalidated email
$email = $_POST['email'];
update_user_meta( $user_id, 'contact_email', $email ); // Could be invalid!

// ❌ BAD: Not checking return value
$email = sanitize_email( wp_unslash( $_POST['email'] ) ); // Returns empty if invalid
update_user_meta( $user_id, 'contact_email', $email ); // Stores empty string!

// ✅ GOOD: Validate before storing
$email = isset( $_POST['email'] ) ? sanitize_email( wp_unslash( $_POST['email'] ) ) : '';
if ( empty( $email ) || ! is_email( $email ) ) {
    return new WP_Error( 'invalid_email', 'Please provide a valid email address' );
}
update_user_meta( $user_id, 'contact_email', $email );

// ✅ GOOD: Optional email field
$email = isset( $_POST['secondary_email'] ) ? sanitize_email( wp_unslash( $_POST['secondary_email'] ) ) : '';
if ( ! empty( $email ) ) {
    // Only store if valid email provided
    update_user_meta( $user_id, 'secondary_email', $email );
}
```

**What it does:**
- Strips characters not allowed in an email (local part keeps RFC "atext" such as `!#$%&'*+/=?^_{|}~-`; domain keeps letters, digits, `-`, `.`)
- Returns empty string if result is not a valid email

**Use with:**
- `is_email()` for validation
- Check return value before storing

### sanitize_url() and esc_url_raw() — URLs

Use `sanitize_url()` (or `esc_url_raw()`) for storing URLs (validates scheme, no HTML encoding).
In current WordPress the two are equivalent for storage: one wraps the other, and both run `esc_url()` in `'db'` context (scheme check, no HTML encoding). Prefer `sanitize_url()` for storage and database contexts in new code.

```php
// ❌ BAD: Storing unvalidated URL
$website = $_POST['website'];
update_user_meta( $user_id, 'website', $website ); // Could be javascript: URL!

// ❌ BAD: Using esc_url() for storage
$website = esc_url( wp_unslash( $_POST['website'] ) ); // Encoded for output, wrong for storage!
update_user_meta( $user_id, 'website', $website );

// ✅ GOOD: sanitize_url() / esc_url_raw() for storage
$website = isset( $_POST['website'] ) ? sanitize_url( wp_unslash( $_POST['website'] ) ) : '';
update_user_meta( $user_id, 'website', $website );

// ✅ GOOD: With empty check
$website = isset( $_POST['website'] ) ? esc_url_raw( wp_unslash( $_POST['website'] ) ) : '';
if ( ! empty( $website ) ) {
    update_option( 'prefix_external_url', $website );
}

// ✅ GOOD: Multiple URLs
$social_links = array();
foreach ( array( 'twitter', 'facebook', 'linkedin' ) as $network ) {
    $social_links[ $network ] = isset( $_POST[ $network ] ) ? esc_url_raw( wp_unslash( $_POST[ $network ] ) ) : '';
}
update_user_meta( $user_id, 'social_links', $social_links );
```

**What it does:**
- Strips characters not allowed in URLs
- Removes the URL entirely if its scheme is not in `wp_allowed_protocols()` (so `javascript:`, `data:`, `vbscript:` are dropped)
- No HTML encoding (safe for storage)
- Does **not** validate URL structure: `http://` or `https://not a host` can come back non-empty. To validate, use `wp_http_validate_url()` (also rejects local/private hosts) or `filter_var( $url, FILTER_VALIDATE_URL )`.

**Use for:**
- URL inputs
- Social media links
- External website URLs

**Not sufficient for redirects:** `sanitize_url()` accepts any external host, so redirecting to it is an open redirect (CWE-601). Redirect with `wp_safe_redirect()` (allows only the site host and `allowed_redirect_hosts`), or check with `wp_validate_redirect( $url, $fallback )` first.

### sanitize_file_name() — Filenames

Use for file uploads and user-provided filenames. Removes special characters, spaces to dashes.

```php
// ❌ BAD: Using raw filename
$filename = $_FILES['upload']['name'];
$target = WP_CONTENT_DIR . '/uploads/' . $filename; // Path traversal! ../../evil.php

// ❌ BAD: Only basename() without sanitization
$filename = basename( $_FILES['upload']['name'] ); // Still allows special chars
$target = WP_CONTENT_DIR . '/uploads/' . $filename;

// ⚠️ PARTIAL: sanitize_file_name() cleans the name but does NOT check type/extension
$filename = sanitize_file_name( $_FILES['upload']['name'] );
$target = WP_CONTENT_DIR . '/uploads/' . $filename;
// Use wp_handle_upload() (type checks + unique name) instead of building upload paths manually!

// ⚠️ PARTIAL: With unique suffix — still no MIME/extension validation
$filename = sanitize_file_name( $_FILES['upload']['name'] );
$unique_filename = wp_unique_filename( WP_CONTENT_DIR . '/uploads/', $filename );
$target = WP_CONTENT_DIR . '/uploads/' . $unique_filename;

// ✅ GOOD: Custom export filename from user input
$export_name = isset( $_POST['export_name'] ) ? sanitize_file_name( wp_unslash( $_POST['export_name'] ) ) : '';
if ( empty( $export_name ) ) {
    $export_name = 'export';
}
$filename = $export_name . '-' . date( 'Y-m-d' ) . '.csv';
```

**What it does:**
- Removes special characters: `<>:"/\|?*`
- Converts spaces to dashes
- Preserves extension
- Removes path components

**Use for:**
- File upload names
- User-provided export filenames
- Attachment filenames
- Any filename from user input

### sanitize_key() — Option Names and Keys

Use for option names, meta keys, transient keys. Returns lowercase alphanumeric with underscores and dashes.

```php
// ❌ BAD: User input as option name
$setting_name = $_POST['setting_name'];
update_option( $setting_name, $value ); // Could overwrite core options!

// ❌ BAD: Sanitize + prefix is NOT an allow-list
// The request can still overwrite ANY of the plugin's own options (e.g. prefix_license_key, prefix_admin_email)
$setting_name = isset( $_POST['setting_name'] ) ? sanitize_key( wp_unslash( $_POST['setting_name'] ) ) : '';
update_option( 'prefix_' . $setting_name, $value );

// ✅ GOOD: Nonce + capability + explicit allow-list of option names
check_admin_referer( 'prefix_save_setting', 'prefix_nonce' );
if ( ! current_user_can( 'manage_options' ) ) {
    wp_die( esc_html__( 'Insufficient permissions.', 'textdomain' ) );
}
$allowed_settings = array( 'prefix_color', 'prefix_layout', 'prefix_items_per_page' );
$setting_name     = isset( $_POST['setting_name'] ) ? sanitize_key( wp_unslash( $_POST['setting_name'] ) ) : '';
if ( in_array( $setting_name, $allowed_settings, true ) ) {
    update_option( $setting_name, $value );
}

// ❌ BAD: Request-chosen meta key (no nonce, no capability, prefix is not an allow-list)
$field_key   = isset( $_POST['field_key'] ) ? sanitize_key( wp_unslash( $_POST['field_key'] ) ) : '';
$field_value = isset( $_POST['field_value'] ) ? sanitize_text_field( wp_unslash( $_POST['field_value'] ) ) : '';
update_post_meta( $post_id, 'prefix_' . $field_key, $field_value );

// ✅ GOOD: Nonce + per-post capability + explicit allow-list of meta keys
check_admin_referer( 'prefix_save_field_' . $post_id, 'prefix_field_nonce' );
if ( ! current_user_can( 'edit_post', $post_id ) ) {
    wp_die( esc_html__( 'Insufficient permissions.', 'textdomain' ) );
}
$allowed_keys = array( 'subtitle', 'byline', 'source_url' );
$field_key    = isset( $_POST['field_key'] ) ? sanitize_key( wp_unslash( $_POST['field_key'] ) ) : '';
$field_value  = isset( $_POST['field_value'] ) ? sanitize_text_field( wp_unslash( $_POST['field_value'] ) ) : '';
if ( in_array( $field_key, $allowed_keys, true ) ) {
    update_post_meta( $post_id, 'prefix_' . $field_key, wp_slash( $field_value ) );
}

// ✅ GOOD: Transient key (md5 keeps arbitrary queries within key length)
$cache_key = isset( $_GET['query'] ) ? md5( sanitize_text_field( wp_unslash( $_GET['query'] ) ) ) : '';
$cached = get_transient( 'prefix_search_' . $cache_key );
if ( false === $cached ) {
    // Generate and cache
    set_transient( 'prefix_search_' . $cache_key, $results, HOUR_IN_SECONDS );
}
```

**What it does:**
- Converts to lowercase
- Keeps only: `a-z`, `0-9`, `_`, `-`
- Removes all other characters

**Use for:**
- Option names and meta keys, always together with an explicit allow-list when the name comes from the request (a prefix is not an allow-list)
- Transient keys
- Array keys
- Slug-like identifiers

### sanitize_title() — URL-Safe Strings

Use for post slugs and URL-safe strings. Converts to lowercase, replaces spaces/special chars with dashes.

```php
// ❌ BAD: Using slug directly from user input
$slug = $_POST['custom_slug'];
wp_update_post( array( 'ID' => $post_id, 'post_name' => $slug ) ); // Could be invalid!

// ✅ GOOD: sanitize_title() for slugs
$slug = isset( $_POST['custom_slug'] ) ? sanitize_title( wp_unslash( $_POST['custom_slug'] ) ) : '';
wp_update_post( array( 'ID' => $post_id, 'post_name' => $slug ) );

// ✅ GOOD: Generate slug from title
$title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
$slug  = sanitize_title( $title );
update_post_meta( $post_id, 'custom_slug', $slug );

// ✅ GOOD: Category slug
$cat_name = isset( $_POST['category_name'] ) ? sanitize_text_field( wp_unslash( $_POST['category_name'] ) ) : '';
$cat_slug = sanitize_title( $cat_name );
wp_insert_term( $cat_name, 'category', array( 'slug' => $cat_slug ) );
```

**What it does:**
- Converts to lowercase
- Replaces spaces with dashes
- Removes special characters
- Removes accents (configurable)
- URL-safe result

**Use for:**
- Post slugs
- Term slugs
- URL segments
- Permalink components

### sanitize_html_class() — CSS Class Names

Use for CSS class inputs. Returns alphanumeric with hyphens, underscores.

```php
// ❌ BAD: User CSS class without sanitization
$class = $_POST['theme_class'];
echo '<div class="' . $class . '">'; // XSS via quote injection!

// ✅ GOOD: sanitize_html_class()
$class = isset( $_POST['theme_class'] ) ? sanitize_html_class( wp_unslash( $_POST['theme_class'] ) ) : '';
if ( ! empty( $class ) ) {
    echo '<div class="' . esc_attr( $class ) . '">';
}

// ✅ GOOD: Multiple classes
$classes = isset( $_POST['classes'] ) ? (array) wp_unslash( $_POST['classes'] ) : array();
$classes = array_map( 'sanitize_html_class', $classes );
$classes = array_filter( $classes ); // Remove empty values
$class_string = implode( ' ', $classes );
echo '<div class="' . esc_attr( $class_string ) . '">';

// ✅ GOOD: Fallback class
$theme = isset( $_POST['theme'] ) ? sanitize_html_class( wp_unslash( $_POST['theme'] ) ) : '';
if ( empty( $theme ) ) {
    $theme = 'default';
}
echo '<body class="theme-' . esc_attr( $theme ) . '">';
```

**What it does:**
- Keeps only: `a-z`, `A-Z`, `0-9`, `_`, `-`
- Removes all other characters
- Returns empty string if result is invalid

**Use for:**
- User-selected CSS classes
- Theme class inputs
- Dynamic class names
- Body/wrapper classes

### absint(), intval(), floatval() — Numbers

Numeric casts cannot carry an injection payload, so they need `isset()` but not `wp_unslash()`. They do not enforce range or authorization: check both.

```php
// ✅ GOOD: ID with absint() + object-level capability check
$post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
if ( $post_id > 0 && current_user_can( 'delete_post', $post_id ) ) {
    wp_delete_post( $post_id );
}

// ✅ GOOD: Signed value with intval(); decimal with floatval() + range check
$offset   = isset( $_POST['offset'] ) ? intval( $_POST['offset'] ) : 0;
$discount = isset( $_POST['discount'] ) ? floatval( $_POST['discount'] ) : 0.0;
if ( $discount < 0 || $discount > 100 ) {
    wp_die( esc_html__( 'Invalid discount.', 'textdomain' ) );
}
```

| Function | Behavior | Use for |
|----------|----------|---------|
| `absint()` | Absolute value: `absint( -5 )` is `5` (sign flipped, not rejected). Non-numeric → `0` | IDs, page numbers, counts |
| `intval()` | Keeps sign. Non-numeric → `0` | Offsets, signed values |
| `floatval()` | Keeps decimals. Non-numeric → `0.0` | Prices, percentages |

## The wp_unslash() Requirement

WordPress always adds slashes to `$_POST`, `$_GET`, `$_COOKIE`, `$_SERVER`, and `$_REQUEST` (core's `wp_magic_quotes()` runs on every request, regardless of PHP's removed magic_quotes setting). **Always call `wp_unslash()` before sanitizing user input.** Numeric casts (`absint()`, `intval()`, `floatval()`) are the exception — slashes can't survive them.

```php
// ❌ BAD: Sanitizing without wp_unslash()
$title = sanitize_text_field( $_POST['title'] );
// If title is: O'Reilly
// update_option() / $wpdb->insert() store: O\'Reilly (backslash remains!)

// ✅ GOOD: wp_unslash() before sanitizing
$title = sanitize_text_field( wp_unslash( $_POST['title'] ) );
// Stored correctly as: O'Reilly

// ❌ BAD: Multiple fields without wp_unslash()
$data = array(
    'name'  => sanitize_text_field( $_POST['name'] ),
    'email' => sanitize_email( $_POST['email'] ),
    'bio'   => sanitize_textarea_field( $_POST['bio'] ),
);
// All may have unwanted backslashes!

// ✅ GOOD: wp_unslash() entire array first
$post_data = wp_unslash( $_POST );
$data = array(
    'name'  => isset( $post_data['name'] ) ? sanitize_text_field( $post_data['name'] ) : '',
    'email' => isset( $post_data['email'] ) ? sanitize_email( $post_data['email'] ) : '',
    'bio'   => isset( $post_data['bio'] ) ? sanitize_textarea_field( $post_data['bio'] ) : '',
);

// ✅ GOOD: Per-field with isset() + wp_unslash()
$name  = isset( $_POST['name'] ) ? sanitize_text_field( wp_unslash( $_POST['name'] ) ) : '';
$email = isset( $_POST['email'] ) ? sanitize_email( wp_unslash( $_POST['email'] ) ) : '';
$bio   = isset( $_POST['bio'] ) ? sanitize_textarea_field( wp_unslash( $_POST['bio'] ) ) : '';
```

**Why it's needed:**
- WordPress adds slashes to preserve quotes/backslashes
- Must be removed before sanitizing, so sanitizers and validators see the real value
- `update_option()` and `$wpdb->insert()`/`update()` store the value as given, so skipping `wp_unslash()` stores `\'`, `\"`, `\\`

**Meta API exception:** `update_metadata()` (behind `update_post_meta()`, `update_user_meta()`, `add_*_meta()`) calls `wp_unslash()` on the key and value itself. The order is: unslash the superglobal, sanitize, then `wp_slash()` the value before `update_*_meta()` when it may contain backslashes. Without `wp_slash()`, real backslashes are stripped. The same applies to `wp_insert_post()`/`wp_update_post()` fields.

**When to use:**
- **Always** with `$_POST`, `$_GET`, `$_COOKIE`, `$_REQUEST`, `$_SERVER`
- Before any sanitization function
- Can unslash entire array or individual values

## Sanitizing Arrays and Complex Data

### Array of Text Fields

```php
// ❌ BAD: Storing array without sanitization
$tags = $_POST['tags']; // Array of user input
update_post_meta( $post_id, 'custom_tags', $tags ); // Unsafe!

// ✅ GOOD: array_map with sanitization
$tags = isset( $_POST['tags'] ) ? (array) wp_unslash( $_POST['tags'] ) : array();
$tags = array_map( 'sanitize_text_field', $tags );
update_post_meta( $post_id, 'custom_tags', $tags );

// ✅ GOOD: Filter empty values
$tags = isset( $_POST['tags'] ) ? (array) wp_unslash( $_POST['tags'] ) : array();
$tags = array_map( 'sanitize_text_field', $tags );
$tags = array_filter( $tags ); // Remove empty strings
update_post_meta( $post_id, 'custom_tags', $tags );
```

### Nested Arrays

```php
// ❌ BAD: Sanitizing only top level
$settings = $_POST['settings']; // Multi-dimensional array
update_option( 'prefix_settings', $settings ); // Nested values unsafe!

// ❌ BAD: Writing sanitized keys back into the same array
// If sanitize_key() changes a key, the original raw key + raw value stay in the array,
// and keys of nested arrays are never sanitized.
foreach ( $array as $key => $value ) {
    $array[ sanitize_key( $key ) ] = sanitize_text_field( $value );
}

// ✅ GOOD: Recursive sanitization into a fresh array (keys sanitized at every level)
function prefix_sanitize_array( array $array ) {
    $out = array();
    foreach ( $array as $key => $value ) {
        $clean_key = is_int( $key ) ? $key : sanitize_key( $key );
        $out[ $clean_key ] = is_array( $value )
            ? prefix_sanitize_array( $value )
            : sanitize_text_field( (string) $value );
    }
    return $out;
}

// wp_unslash() is recursive, so unslash once at the top
$settings = isset( $_POST['settings'] ) ? (array) wp_unslash( $_POST['settings'] ) : array();
$settings = prefix_sanitize_array( $settings );
update_option( 'prefix_settings', $settings );

// ✅ GOOD: Type-specific nested sanitization
$post_data    = wp_unslash( $_POST );
$user_profile = array(
    'name'    => isset( $post_data['name'] ) ? sanitize_text_field( $post_data['name'] ) : '',
    'email'   => isset( $post_data['email'] ) ? sanitize_email( $post_data['email'] ) : '',
    'social'  => array(
        'twitter'  => isset( $post_data['twitter'] ) ? esc_url_raw( $post_data['twitter'] ) : '',
        'facebook' => isset( $post_data['facebook'] ) ? esc_url_raw( $post_data['facebook'] ) : '',
    ),
);
update_user_meta( $user_id, 'profile', $user_profile );
```

### JSON Data

```php
// ❌ BAD: Storing JSON without validation
$json_data = $_POST['data'];
update_option( 'prefix_json_data', $json_data ); // Could be malformed!

// ✅ GOOD: Decode, sanitize, re-encode
$json_raw = isset( $_POST['data'] ) ? wp_unslash( $_POST['data'] ) : '';
$data = json_decode( $json_raw, true );

if ( json_last_error() !== JSON_ERROR_NONE ) {
    return new WP_Error( 'invalid_json', 'Invalid JSON data' );
}

// Sanitize decoded data (must be an array; recurse for nested JSON)
if ( ! is_array( $data ) ) {
    return new WP_Error( 'invalid_json', 'Expected a JSON object' );
}
$data = prefix_sanitize_array( $data );

// Store as JSON
update_option( 'prefix_json_data', wp_json_encode( $data ) );
```

### Checkbox and Select Inputs (Whitelist)

```php
// ❌ BAD: Trusting select value
$status = $_POST['status'];
update_post_meta( $post_id, 'status', $status ); // User can submit any value!

// ✅ GOOD: Whitelist allowed values
$allowed_statuses = array( 'draft', 'pending', 'published', 'archived' );
$status = isset( $_POST['status'] ) ? sanitize_key( wp_unslash( $_POST['status'] ) ) : 'draft';

if ( ! in_array( $status, $allowed_statuses, true ) ) {
    $status = 'draft'; // Fallback to default
}

update_post_meta( $post_id, 'status', $status );

// ✅ GOOD: Checkbox (boolean)
$enabled = isset( $_POST['enabled'] ) && '1' === $_POST['enabled'];
update_option( 'prefix_feature_enabled', $enabled );

// ✅ GOOD: Multiple checkboxes
$selected_items = isset( $_POST['items'] ) ? (array) wp_unslash( $_POST['items'] ) : array();
$allowed_items  = array( 'item1', 'item2', 'item3', 'item4' );
$selected_items = array_map( 'sanitize_key', $selected_items );
$selected_items = array_values( array_intersect( $selected_items, $allowed_items ) ); // Only allowed values
update_option( 'prefix_selected_items', $selected_items );
```

## REST API Arguments (sanitize_callback / validate_callback)

For REST routes, declare per-argument validation and sanitization in `args`. WordPress runs `validate_callback` first (return `true` or `WP_Error`), then `sanitize_callback`, before the route callback sees `$request`.

**Schema enforcement rule:** when an arg has no custom callbacks, WordPress uses `rest_parse_request_arg()`, which validates against the schema (`type`, `enum`, `format`, `minimum`, `maximum`, ...) and then sanitizes. A custom `sanitize_callback` replaces that default. If the arg then has no `validate_callback`, the schema keywords are **not enforced**. Either let the schema do both (no custom callbacks), or add `'validate_callback' => 'rest_validate_request_arg'`.

```php
// ❌ BAD: No args schema — handler reads raw params
register_rest_route( 'myplugin/v1', '/items', array(
    'methods'             => 'POST',
    'callback'            => 'prefix_create_item',
    'permission_callback' => function () { return current_user_can( 'edit_posts' ); },
) );
function prefix_create_item( WP_REST_Request $request ) {
    $title = $request['title']; // Unvalidated, unsanitized
}

// ✅ GOOD: Validate + sanitize in args
register_rest_route( 'myplugin/v1', '/items', array(
    'methods'             => WP_REST_Server::CREATABLE,
    'callback'            => 'prefix_create_item',
    'permission_callback' => function () { return current_user_can( 'edit_posts' ); },
    'args'                => array(
        'title'  => array(
            'type'              => 'string',
            'required'          => true,
            'sanitize_callback' => 'sanitize_text_field',
            'validate_callback' => function ( $value ) {
                return is_string( $value ) && '' !== trim( $value );
            },
        ),
        'status' => array(
            'type'    => 'string',
            'enum'    => array( 'draft', 'publish' ), // Allow-list enforced by schema
            'default' => 'draft',
        ),
        'count'  => array(
            'type'    => 'integer',
            'minimum' => 1,
            'maximum' => 100,
            // No custom sanitize_callback: rest_parse_request_arg() enforces type/min/max.
            // With 'sanitize_callback' => 'absint' alone, 1000 would pass and -5 would become 5.
        ),
        'email'  => array(
            'type'   => 'string',
            'format' => 'email', // Validated by rest_validate_request_arg()
        ),
    ),
) );
```

**Notes:**
- REST params are NOT slashed — do not call `wp_unslash()` on `$request` values.
- A custom `sanitize_callback` without a `validate_callback` disables schema validation (`type`/`enum`/`minimum`/`maximum`/`format`) for that arg. Add `'validate_callback' => 'rest_validate_request_arg'` to keep it.
- A custom `validate_callback` does NOT disable schema enforcement as long as `sanitize_callback` is left unset: the default `rest_parse_request_arg()` still validates against the schema (then sanitizes). Only a custom `sanitize_callback` removes the schema checks.
- `sanitize_callback` and `validate_callback` receive `( $value, $request, $param )`. WordPress functions such as `sanitize_text_field` and `absint` ignore the extra arguments. PHP built-ins do not: `'sanitize_callback' => 'intval'` passes `$request` as `intval()`'s `$base` argument and throws a `TypeError` on PHP 8. Use `absint`, a schema `type`, or a closure (`function( $v ) { return (int) $v; }`).

## Sanitization Is Not SQL Escaping

Sanitizers make data safe to *store and display*; none of them make data safe to *concatenate into SQL*. Use `$wpdb->prepare()` placeholders for every value.

- `sanitize_text_field()` leaves quotes, backslashes, `--`, and SQL keywords intact → not SQL-safe.
- `esc_sql()` is **not a sanitizer**. It only escapes quotes/backslashes, so it is safe only inside a **quoted** string literal. Unquoted or numeric positions (`WHERE id = $id`, `LIMIT`, `ORDER BY`, `IN (...)`) remain injectable (CRITICAL, CWE-89).

```php
// ❌ CRITICAL: "Sanitized" value concatenated into SQL
$name = sanitize_text_field( wp_unslash( $_GET['name'] ) );
$wpdb->get_results( "SELECT * FROM {$wpdb->users} WHERE user_login = '$name'" );

// ❌ CRITICAL: esc_sql() in an unquoted position — "1 OR 1=1" passes through
$id = esc_sql( wp_unslash( $_GET['id'] ) );
$wpdb->get_row( "SELECT * FROM {$wpdb->posts} WHERE ID = $id" );

// ✅ GOOD: Placeholders
$wpdb->get_results( $wpdb->prepare( "SELECT * FROM {$wpdb->users} WHERE user_login = %s", $name ) );
$wpdb->get_row( $wpdb->prepare( "SELECT * FROM {$wpdb->posts} WHERE ID = %d", absint( $_GET['id'] ?? 0 ) ) );
```

## When NOT to Sanitize

### Post Content (Use wp_kses instead)

```php
// ❌ BAD: sanitize_textarea_field() on post content
$content = sanitize_textarea_field( wp_unslash( $_POST['post_content'] ) );
wp_update_post( array( 'ID' => $post_id, 'post_content' => $content ) );
// Removes ALL HTML! <p>, <strong>, <img> all stripped!

// ✅ GOOD: Use wp_kses_post() for post content
if ( isset( $_POST['post_content'] ) && current_user_can( 'edit_post', $post_id ) ) {
    $content = wp_kses_post( wp_unslash( $_POST['post_content'] ) );
    wp_update_post( array( 'ID' => $post_id, 'post_content' => $content ) );
}
```

### Binary Data

```php
// ⚠️ WRONG TOOL: Text sanitizer on encoded data
$image_data = sanitize_text_field( wp_unslash( $_POST['image_base64'] ) );
// Plain base64 mostly survives, but line-wrapped (MIME) base64 loses its newlines,
// and nothing here checks that the payload is really an image.

// ✅ GOOD: Validate the format, decode strictly, and verify the content
$image_data = isset( $_POST['image_base64'] ) ? wp_unslash( $_POST['image_base64'] ) : '';
if ( ! preg_match( '/^data:image\/(png|jpe?g|gif);base64,([A-Za-z0-9+\/=\s]+)$/', $image_data, $m ) ) {
    return new WP_Error( 'invalid_image', 'Invalid image format' );
}
$binary = base64_decode( $m[2], true ); // strict mode rejects invalid characters
if ( false === $binary || false === getimagesizefromstring( $binary ) ) {
    return new WP_Error( 'invalid_image', 'Invalid image data' );
}
```

### Already Sanitized WordPress Function Output

```php
// ❌ BAD: Re-sanitizing WordPress function output
$user_email = get_the_author_meta( 'user_email' ); // Already sanitized
$user_email = sanitize_email( $user_email ); // Unnecessary

// ✅ GOOD: Trust WordPress function output
$user_email = get_the_author_meta( 'user_email' );
// Use directly (escape on output if needed)
```

## Complete Input Handling Example

```php
/**
 * Handle form submission with proper sanitization
 */
function prefix_handle_profile_update() {
    // 1. Verify nonce
    if ( ! isset( $_POST['_nonce'] )
        || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['_nonce'] ) ), 'update_profile' ) ) {
        wp_die( esc_html__( 'Invalid nonce', 'textdomain' ), 403 );
    }

    // 2. Get target user ID
    $user_id = isset( $_POST['user_id'] ) ? absint( $_POST['user_id'] ) : 0;
    if ( $user_id <= 0 || ! get_userdata( $user_id ) ) {
        return new WP_Error( 'invalid_user', 'Invalid user ID' );
    }

    // 3. Check capability for THIS user (meta cap — not the generic 'edit_users')
    if ( ! current_user_can( 'edit_user', $user_id ) ) {
        wp_die( esc_html__( 'Insufficient permissions', 'textdomain' ), 403 );
    }

    // 4. Sanitize text fields
    $display_name = isset( $_POST['display_name'] ) ? sanitize_text_field( wp_unslash( $_POST['display_name'] ) ) : '';
    $bio          = isset( $_POST['bio'] ) ? sanitize_textarea_field( wp_unslash( $_POST['bio'] ) ) : '';

    // 5. Validate and sanitize email
    $email = isset( $_POST['email'] ) ? wp_unslash( $_POST['email'] ) : '';
    if ( ! is_email( $email ) ) {
        return new WP_Error( 'invalid_email', 'Please provide a valid email' );
    }
    $email = sanitize_email( $email );

    // 6. Sanitize URL
    $website = isset( $_POST['website'] ) ? esc_url_raw( wp_unslash( $_POST['website'] ) ) : '';

    // 7. Boolean checkbox
    $newsletter = isset( $_POST['newsletter'] ) && '1' === $_POST['newsletter'];

    // 8. Array of sanitized values
    $interests = isset( $_POST['interests'] ) ? (array) wp_unslash( $_POST['interests'] ) : array();
    $interests = array_filter( array_map( 'sanitize_text_field', $interests ) );

    // 9. Update user data (no role here)
    $userdata = array(
        'ID'           => $user_id,
        'display_name' => $display_name,
        'user_email'   => $email,
        'user_url'     => $website,
    );

    // 10. Role change: separate, stricter check (privilege escalation risk)
    //     - 'promote_user' for the target user (not just edit_user)
    //     - role must be one the CURRENT user may assign (get_editable_roles())
    //     - never let users change their own role
    if ( isset( $_POST['role'] ) && current_user_can( 'promote_user', $user_id ) && get_current_user_id() !== $user_id ) {
        $role = sanitize_key( wp_unslash( $_POST['role'] ) );
        if ( ! function_exists( 'get_editable_roles' ) ) {
            require_once ABSPATH . 'wp-admin/includes/user.php';
        }
        if ( array_key_exists( $role, get_editable_roles() ) ) {
            $userdata['role'] = $role;
        }
    }

    wp_update_user( $userdata );

    // 11. Update user meta
    update_user_meta( $user_id, 'bio', $bio );
    update_user_meta( $user_id, 'newsletter_opt_in', $newsletter );
    update_user_meta( $user_id, 'interests', $interests );

    return true;
}
```

Related: output escaping → `escaping-guide.md`; vulnerability patterns → `vulnerability-patterns.md`.
