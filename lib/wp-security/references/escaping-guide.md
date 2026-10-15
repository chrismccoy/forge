# WordPress Output Escaping Guide

Output escaping is the final defense against Cross-Site Scripting (XSS) attacks. This guide covers WordPress's context-specific escaping functions, the late escaping principle, and common mistakes.

**Contents:** Quick Reference Table · The Late Escaping Principle · Context-Specific Escaping Functions (`esc_html`, `esc_attr`, `esc_url`, esc_attr() is not a URL escaper, `esc_js`, `esc_textarea`, `esc_url_raw`) · wp_kses() Family · Escaping in Different Contexts (templates, printf, non-echo output sinks, heredoc, JavaScript Localization, REST responses, add_query_arg() and request URLs, shortcode output, block render_callback output) · Common Escaping Mistakes · WordPress i18n + Escaping

## Quick Reference Table

| Function | Output Context | Example | Notes |
|----------|---------------|---------|-------|
| `esc_html()` | HTML body text | `<p><?php echo esc_html( $text ); ?></p>` | Encodes `< > & " '` as entities (does not strip tags); leaves existing entities alone |
| `esc_attr()` | HTML attributes | `<div class="<?php echo esc_attr( $class ); ?>">` | Safe for quoted attributes |
| `esc_url()` | URL in href/src | `<a href="<?php echo esc_url( $url ); ?>">` | Validates scheme, rejects `javascript:` |
| `esc_js()` | Inline event-handler attributes | `<a onclick="go('<?php echo esc_js( $val ); ?>')">` | Not for `<script>` blocks (HTML-entity-encodes, corrupts values); there use `wp_json_encode( $v, JSON_HEX_TAG \| JSON_HEX_AMP )` |
| `esc_textarea()` | Textarea content | `<textarea><?php echo esc_textarea( $text ); ?></textarea>` | Like `esc_html()` but double-encodes existing entities so they round-trip in the textarea |
| `esc_url_raw()` | URL in database/redirect | `update_option( 'url', esc_url_raw( $url ) );` | No encoding, validation only |
| `wp_kses()` | HTML with allowed tags | `echo wp_kses( $html, $allowed_tags );` | Whitelist specific tags/attributes |
| `wp_kses_post()` | Post content HTML | `echo wp_kses_post( $content );` | Allows post editor tags (trusted only) |
| `sanitize_text_field()` | Single-line text input | `$name = sanitize_text_field( wp_unslash( $_POST['name'] ) );` | **INPUT sanitization, not output** |

## The Late Escaping Principle

WordPress follows "late escaping" — data is sanitized on input (to ensure safe storage) and escaped on output (to ensure safe display). This allows the same data to be used in multiple contexts.

### Why Late Escaping?

```php
// ❌ BAD: Early escaping prevents reuse in different contexts
// (Data-integrity / best-practice issue, not an exploitable flaw by itself.)
function prefix_save_title() {
    if ( ! isset( $_POST['title'] ) ) {
        return;
    }
    $title = esc_html( wp_unslash( $_POST['title'] ) ); // Escaped for HTML context
    update_post_meta( $post_id, 'title', $title ); // Stored with HTML entities
}

function prefix_display_title() {
    $title = get_post_meta( $post_id, 'title', true ); // Contains &lt; &gt; entities

    // In HTML: esc_html() does NOT double-encode existing entities
    // (_wp_specialchars() runs with double_encode = false), so this renders OK.
    echo '<h1>' . esc_html( $title ) . '</h1>';

    // In a textarea: esc_textarea() DOES double-encode, so the user sees "&lt;"
    echo '<textarea>' . esc_textarea( $title ) . '</textarea>';

    // In JSON API: escaping wrong for context
    return array( 'title' => $title ); // Still HTML-escaped!

    // In email: HTML entities in plain text
    wp_mail( $email, $title, $body ); // Subject has &lt; entities
}

// ✅ GOOD: Late escaping allows context-appropriate output
function prefix_save_title() {
    if ( ! isset( $_POST['title'] ) ) {
        return;
    }
    $title = sanitize_text_field( wp_unslash( $_POST['title'] ) ); // Sanitize, don't escape
    update_post_meta( $post_id, 'title', $title ); // Store clean data
}

function prefix_display_title() {
    $title = get_post_meta( $post_id, 'title', true ); // Clean data

    // In HTML: escape for HTML
    echo '<h1>' . esc_html( $title ) . '</h1>';

    // In JSON API: no escaping needed (json_encode handles it)
    return array( 'title' => $title );

    // In email: use as-is
    wp_mail( $email, $title, $body );

    // In attribute: escape for attribute
    echo '<div data-title="' . esc_attr( $title ) . '">';
}
```

### Input vs Output Functions

```php
// INPUT (sanitization) — when receiving data
$title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
$email = isset( $_POST['email'] ) ? sanitize_email( wp_unslash( $_POST['email'] ) ) : '';
$url   = isset( $_POST['website'] ) ? sanitize_url( wp_unslash( $_POST['website'] ) ) : '';
update_post_meta( $post_id, 'data', array(
    'title' => $title,
    'email' => $email,
    'url'   => $url,
) );

// OUTPUT (escaping) — when displaying data
$data = get_post_meta( $post_id, 'data', true );
echo '<h1>' . esc_html( $data['title'] ) . '</h1>';
echo '<a href="' . esc_url( 'mailto:' . $data['email'] ) . '">Email</a>'; // href = URL context

echo '<a href="' . esc_url( $data['url'] ) . '">Website</a>';
```

## Context-Specific Escaping Functions

### esc_html() — HTML Body Text

Use for text content within HTML tags. Converts `<`, `>`, `&`, `"`, `'` to HTML entities.

```php
// ❌ BAD: Unescaped output
$user_name = get_user_meta( $user_id, 'display_name', true );
echo '<p>Welcome, ' . $user_name . '</p>'; // XSS if name contains <script>

// ⚠️ WRONG FUNCTION: esc_attr() in body text
$user_input = isset( $_POST['comment'] ) ? wp_unslash( $_POST['comment'] ) : '';
echo '<div>' . esc_attr( $user_input ) . '</div>'; // Encodes the same chars, but WPCS flags it; use esc_html()

// ✅ GOOD: Escape HTML context
$user_name = get_user_meta( $user_id, 'display_name', true );
echo '<p>Welcome, ' . esc_html( $user_name ) . '</p>';

// ✅ GOOD: Escaping translated strings
echo '<h1>' . esc_html__( 'Settings', 'textdomain' ) . '</h1>';

// ✅ GOOD: Escaping dynamic content
$post_title = get_the_title();
echo '<h2>' . esc_html( $post_title ) . '</h2>';
```

**What it does:**
- Converts: `<script>` → `&lt;script&gt;` (encodes tags, does not strip them)
- Converts: `"Hello"` → `&quot;Hello&quot;`
- Leaves existing entities (`&amp;`, `&lt;`) as-is — no double-encoding
- Returns empty string for invalid UTF-8

### esc_attr() — HTML Attributes

Use for text within HTML attributes (class, id, data-*, etc.).

```php
// ❌ BAD: Unescaped attribute
$user_id = $_GET['user'];
echo '<div data-user="' . $user_id . '">'; // XSS via quote injection: user=1" onmouseover="alert(1)

// ❌ BAD: Wrong context (doesn't validate URL scheme)
$url = isset( $_GET['url'] ) ? wp_unslash( $_GET['url'] ) : '';
echo '<a href="' . esc_attr( $url ) . '">'; // javascript: URLs pass through!

// ✅ GOOD: Escape attribute context
$user_id = isset( $_GET['user'] ) ? absint( $_GET['user'] ) : 0;
echo '<div data-user="' . esc_attr( $user_id ) . '">';

// ✅ GOOD: CSS class from user input
$class = isset( $_GET['theme'] ) ? sanitize_html_class( wp_unslash( $_GET['theme'] ) ) : '';
echo '<div class="' . esc_attr( $class ) . '">';

// ✅ GOOD: Data attributes
$status = get_post_meta( $post_id, 'status', true );
echo '<button data-status="' . esc_attr( $status ) . '">Update</button>';
```

**What it does:**
- Converts: `"` → `&quot;`
- Converts: `<` → `&lt;`
- Safe for single/double quoted attributes

**Note:** Always quote attributes: `class="<?php echo esc_attr( $val ); ?>"` not `class=<?php echo esc_attr( $val ); ?>`

### esc_url() — URLs in href/src/action

Use for URLs in href, src, action, and other URL contexts. Validates URL schemes and rejects dangerous ones.

```php
// ❌ BAD: Unescaped URL
$redirect = $_GET['redirect_to'];
echo '<a href="' . $redirect . '">Next</a>'; // XSS via javascript: URL

// ❌ BAD: Wrong context (doesn't validate scheme)
$url = isset( $_GET['url'] ) ? wp_unslash( $_GET['url'] ) : '';
echo '<a href="' . esc_html( $url ) . '">Link</a>'; // javascript: passes!

// ⚠️ OPEN REDIRECT: esc_url() blocks javascript: but allows any external host
$redirect = isset( $_GET['redirect_to'] ) ? wp_unslash( $_GET['redirect_to'] ) : home_url();
echo '<a href="' . esc_url( $redirect ) . '">Next</a>';

// ✅ GOOD: Restrict to allowed hosts, then escape
$redirect = isset( $_GET['redirect_to'] )
    ? wp_validate_redirect( wp_unslash( $_GET['redirect_to'] ), admin_url() )
    : admin_url();
echo '<a href="' . esc_url( $redirect ) . '">Next</a>';

// ✅ GOOD: User-submitted website
$website = get_user_meta( $user_id, 'website', true );
echo '<a href="' . esc_url( $website ) . '">' . esc_html( $website ) . '</a>';

// ✅ GOOD: Image src
$avatar_url = get_user_meta( $user_id, 'avatar', true );
echo '<img src="' . esc_url( $avatar_url ) . '" alt="Avatar">';

// ✅ GOOD: With allowed protocols
$custom_url = get_option( 'custom_protocol_url' );
echo '<a href="' . esc_url( $custom_url, array( 'http', 'https', 'ftp' ) ) . '">Download</a>';
```

**What it does:**
- Validates URL structure
- Allows (default `wp_allowed_protocols()`): `http`, `https`, `ftp`, `ftps`, `mailto`, `news`, `irc`, `irc6`, `ircs`, `gopher`, `nntp`, `feed`, `telnet`, `mms`, `rtsp`, `sms`, `svn`, `tel`, `fax`, `xmpp`, `webcal`, `urn` (filterable via `kses_allowed_protocols`)
- Rejects: `javascript:`, `data:`, `vbscript:`, etc.
- Encodes special characters

**Note:** For database storage or `wp_safe_redirect()`, use `esc_url_raw()` instead (no encoding).

### esc_attr() Is Not a URL Escaper

`esc_attr()` only encodes characters (`<`, `>`, `&`, `"`, `'`). It does not check the URL scheme, so `javascript:` and `data:` URLs pass through unchanged. In `href`, `src`, `action`, `formaction`, `poster` or `srcset`, that is XSS → CRITICAL (CWE-79). Use `esc_url()`, which strips disallowed protocols and also encodes for the attribute.

```php
$url = isset( $_GET['next'] ) ? wp_unslash( $_GET['next'] ) : '';

// ❌ BAD: javascript:alert(document.cookie) survives esc_attr()
echo '<a href="' . esc_attr( $url ) . '">Continue</a>';
echo '<form action="' . esc_attr( $url ) . '">';
echo '<img src="' . esc_attr( $image_url ) . '">';

// ✅ GOOD: esc_url() for every URL-valued attribute
echo '<a href="' . esc_url( $url ) . '">Continue</a>';
echo '<form action="' . esc_url( $url ) . '">';
echo '<img src="' . esc_url( $image_url ) . '">';
```

### esc_js() — Inline Event-Handler Attributes (Rare)

Use only for string literals inside inline event-handler attributes (`onclick="..."`), where the browser HTML-decodes the attribute before running it. `esc_js()` backslash-escapes single quotes (`O'Brien` → `O\'Brien`) and newlines, and HTML-entity-encodes `<`, `>`, `&` and `"`. Inside a `<script>` block nothing is HTML-decoded, so those entities show up literally and values are corrupted. **For `<script>` blocks and data passing, use `wp_add_inline_script()` + `wp_json_encode( $v, JSON_HEX_TAG | JSON_HEX_AMP )`.**

```php
// ❌ BAD: Unescaped JS
$user_name = get_user_meta( $user_id, 'name', true );
echo '<script>var name = "' . $user_name . '";</script>'; // XSS via quote escape

// ❌ BAD: Using esc_html in JS context
echo '<script>var name = "' . esc_html( $user_name ) . '";</script>'; // Wrong escaping!

// ⚠️ WRONG FUNCTION: esc_js() inside <script> (`Tom & "Jerry"` becomes `Tom &amp; &quot;Jerry&quot;`)
$user_name = get_user_meta( $user_id, 'name', true );
echo '<script>var name = "' . esc_js( $user_name ) . '";</script>';

// ✅ GOOD: esc_js() in its intended context, an inline event-handler attribute
echo '<button onclick="greet(\'' . esc_js( $user_name ) . '\')">Hi</button>';

// ✅ GOOD: wp_add_inline_script() + wp_json_encode() (preserves types)
wp_add_inline_script(
    'my-script',
    'const myData = ' . wp_json_encode( array(
        'userName' => get_user_meta( $user_id, 'name', true ),
    ), JSON_HEX_TAG | JSON_HEX_AMP ) . ';',
    'before'
);
// In JS file: console.log( myData.userName );

// ⚠️ OK: wp_localize_script() — note it casts top-level scalars to strings
// (true → "1", 5 → "5"). Intended for i18n strings, not typed config.
wp_localize_script( 'my-script', 'myData', array(
    'userName' => get_user_meta( $user_id, 'name', true ),
) );
```

**When to use:**
- Only for string literals in inline event-handler attributes
- Never inside `<script>` blocks; use `wp_json_encode( $v, JSON_HEX_TAG | JSON_HEX_AMP )` there

### esc_textarea() — Textarea Content

Use for content within `<textarea>` tags. Similar to `esc_html()`, but it double-encodes existing entities (`htmlspecialchars` with `double_encode = true`) so text like `&lt;` round-trips intact when the form is resubmitted.

```php
// ❌ BAD: Unescaped textarea
$bio = get_user_meta( $user_id, 'bio', true );
echo '<textarea>' . $bio . '</textarea>'; // XSS via </textarea> injection

// ✅ GOOD: Escape textarea
$bio = get_user_meta( $user_id, 'bio', true );
echo '<textarea name="bio">' . esc_textarea( $bio ) . '</textarea>';

// ✅ GOOD: With translation
echo '<textarea placeholder="' . esc_attr__( 'Enter bio...', 'textdomain' ) . '">';
echo esc_textarea( get_the_author_meta( 'description' ) );
echo '</textarea>';
```

**What it does:**
- Like `esc_html()` but double-encodes existing entities (both keep line breaks)
- Escapes `</textarea>` to prevent tag injection

### esc_url_raw() — URLs for Database/Redirects

Use when storing URLs or passing to `wp_safe_redirect()`. Validates but doesn't encode.

```php
// ❌ BAD: Storing escaped URL
$website = esc_url( wp_unslash( $_POST['website'] ) ); // Encoded for output
update_user_meta( $user_id, 'website', $website ); // Stores encoded URL!

// ✅ GOOD: Store raw, display escaped
$website = isset( $_POST['website'] ) ? esc_url_raw( wp_unslash( $_POST['website'] ) ) : ''; // Validates, no encoding
update_user_meta( $user_id, 'website', $website );

$stored_url = get_user_meta( $user_id, 'website', true );
echo '<a href="' . esc_url( $stored_url ) . '">'; // Encode for output

// ✅ GOOD: wp_safe_redirect() needs raw URL (and only allows same-host / allowed_redirect_hosts)
$redirect_to = isset( $_GET['redirect_to'] ) ? esc_url_raw( wp_unslash( $_GET['redirect_to'] ) ) : home_url();
wp_safe_redirect( $redirect_to );
exit;
```

**Difference from esc_url():**
- `esc_url()`: Validates + encodes → for HTML output
- `esc_url_raw()`: Validates only → for storage/redirects

## wp_kses() Family — HTML Whitelist Filtering

For allowing specific HTML tags while stripping everything else.

### wp_kses() — Custom Allowed Tags

```php
// ❌ BAD: Allowing all HTML
$bio = $_POST['bio'];
update_user_meta( $user_id, 'bio', $bio ); // Stores <script>, <iframe>, etc.!

// ❌ BAD: Strip all HTML when some is needed
$bio = sanitize_text_field( wp_unslash( $_POST['bio'] ) );
update_user_meta( $user_id, 'bio', $bio ); // Removes even <em>, <strong>

// ✅ GOOD: Allow specific formatting tags
$allowed_tags = array(
    'a' => array(
        'href'  => array(),
        'title' => array(),
    ),
    'br'     => array(),
    'em'     => array(),
    'strong' => array(),
    'p'      => array(),
);

$bio = isset( $_POST['bio'] ) ? wp_kses( wp_unslash( $_POST['bio'] ), $allowed_tags ) : '';
update_user_meta( $user_id, 'bio', $bio );

// Output: still escape late (stored data may have been written by another path)
echo '<div class="bio">' . wp_kses( get_user_meta( $user_id, 'bio', true ), $allowed_tags ) . '</div>';
```

**Allowed tag structure:**
```php
$allowed_tags = array(
    'tagname' => array(
        'attribute_name' => array(), // Allow attribute
        'class' => array(),          // Allow class attribute
        'id'    => array(),          // Allow id attribute
        'data-*' => true,            // Allow all data- attributes (wildcard supported since WP 5.0)
    ),
);
```

**Common allowed sets:**
```php
// Basic formatting
$basic_tags = array(
    'strong' => array(),
    'em'     => array(),
    'b'      => array(),
    'i'      => array(),
    'br'     => array(),
);

// Links and formatting
$formatted_tags = array(
    'a' => array( 'href' => array(), 'title' => array(), 'target' => array() ),
    'strong' => array(),
    'em'     => array(),
    'br'     => array(),
    'p'      => array(),
);

// Rich text (user bios, comments)
$rich_tags = array(
    'a' => array( 'href' => array(), 'title' => array() ),
    'br' => array(),
    'em' => array(),
    'strong' => array(),
    'p' => array(),
    'ul' => array(),
    'ol' => array(),
    'li' => array(),
    'blockquote' => array(),
);
```

### wp_kses_post() — Post Content HTML

Allows tags that the post editor allows. **Use only for content from users with `edit_posts` (Contributors and up) who lack `unfiltered_html`** — the same filter core applies to their post content. Do not use it for Subscribers, commenters, or anonymous input.

```php
// ❌ BAD: Using wp_kses_post() on arbitrary user input
$user_comment = wp_kses_post( wp_unslash( $_POST['comment'] ) ); // Too permissive for comments!
wp_insert_comment( array( 'comment_content' => $user_comment ) );

// ❌ BAD: On untrusted user roles
$user_bio = wp_kses_post( wp_unslash( $_POST['bio'] ) ); // Subscribers get forms, tables, styled markup, phishing links
update_user_meta( $user_id, 'bio', $user_bio );

// ✅ GOOD: Nonce + meta capability on THIS post, then kses
check_admin_referer( 'save_custom_content_' . $post_id, 'custom_content_nonce' );
if ( current_user_can( 'edit_post', $post_id ) && isset( $_POST['content'] ) ) {
    $custom_content = wp_kses_post( wp_unslash( $_POST['content'] ) );
    update_post_meta( $post_id, 'custom_content', $custom_content );
}

// ✅ GOOD: For actual post content (after the same nonce + edit_post check)
$post_content = isset( $_POST['post_content'] ) ? wp_kses_post( wp_unslash( $_POST['post_content'] ) ) : '';
wp_update_post( array(
    'ID'           => $post_id,
    'post_content' => $post_content,
) );
```

**What wp_kses_post() allows:**
- All post editor tags: `<p>`, `<h1-h6>`, `<blockquote>`, `<code>`, `<pre>`
- Media: `<img>`, `<audio>`, `<video>`, `<figure>`. `<object>` is allowed since WP 5.9, but only with a `data` attribute of type `application/pdf` (kses checks this). `<iframe>`, `<embed>` and `<script>` are NOT in `$allowedposttags`.
- Formatting: `<strong>`, `<em>`, `<a>`, `<ul>`, `<ol>`, `<li>`, `<table>`
- Forms: `<form>`, `<button>`, `<textarea>`, `<label>`, `<fieldset>` and `<legend>` are allowed; `<input>`, `<select>` and `<option>` are NOT in `$allowedposttags`. Allowed `<form>` + `<button>` still enable phishing-style markup from low-trust users.
- Embeds in post content come from oEmbed at render time, not from kses

**When to use:** Only for content from users with `edit_posts` (Contributors and up) who lack `unfiltered_html`.

## Escaping in Different Contexts

### Template Output

```php
// ❌ BAD: Multiple escaping mistakes in one template
<div class="user-card" data-id="<?php echo $user_id; ?>">
    <h3><?php echo $user_name; ?></h3>
    <a href="<?php echo $website; ?>">Visit Website</a>
    <p><?php echo $bio; ?></p>
</div>

// ✅ GOOD: Context-appropriate escaping
<div class="user-card" data-id="<?php echo esc_attr( $user_id ); ?>">
    <h3><?php echo esc_html( $user_name ); ?></h3>
    <a href="<?php echo esc_url( $website ); ?>"><?php echo esc_html__( 'Visit Website', 'textdomain' ); ?></a>
    <p><?php echo wp_kses_post( $bio ); ?></p>
</div>
```

### printf() / sprintf() Patterns

```php
// ❌ BAD: Escaping after printf
printf( '<a href="%s">%s</a>', $url, $text );
// String built before escaping!

// ✅ GOOD: Escape before printf
printf(
    '<a href="%s">%s</a>',
    esc_url( $url ),
    esc_html( $text )
);

// ✅ GOOD: With translation
printf(
    /* translators: %s: user name */
    esc_html__( 'Welcome, %s!', 'textdomain' ),
    esc_html( $user_name )
);
```

### Non-echo Output Sinks

`echo` and `print` are not the only output paths. Each sink below prints HTML, so unescaped variables reaching them are XSS → CRITICAL (CWE-79).

- `printf()` / `vprintf()`: every argument must be escaped, and the format string must never be user-controlled (`printf( $fmt )` with a request-supplied format is XSS and can leak arguments).
- `_e()` / `_ex()`: never escape. `_e( $var )` echoes the variable raw (XSS). Even with a literal, the translation is not escaped, so a malicious or compromised translation file can inject markup. Use `esc_html_e()` / `esc_attr_e()` / `echo esc_html__( ... )` for literals and `echo esc_html( $var )` for variables.
- `wp_die( $msg )`, `die( $msg )`, `exit( $msg )`: print their string argument as HTML.
- Concatenation where only the first operand is escaped: `echo esc_html( $a ) . $b` leaves `$b` raw. Escape each operand.

```php
// ❌ BAD
printf( '<p>%s</p>', $title );
printf( wp_unslash( $_GET['fmt'] ), $name );   // user-controlled format
_e( $message, 'textdomain' );                  // variable passed to _e()
wp_die( wp_unslash( $_GET['msg'] ) );
die( $error_message );
echo esc_html( $first ) . ' ' . $last;         // $last unescaped

// ✅ GOOD
printf( '<p>%s</p>', esc_html( $title ) );
esc_html_e( 'Settings saved.', 'textdomain' );
echo esc_html( $message );
wp_die( esc_html__( 'Invalid request.', 'textdomain' ) );
wp_die( esc_html( $error_message ) );
echo esc_html( $first ) . ' ' . esc_html( $last );
```

### Heredoc / Nowdoc Syntax

```php
// ❌ BAD: Unescaped heredoc
$output = <<<HTML
<div class="card">
    <h3>$title</h3>
    <p>$description</p>
</div>
HTML;
echo $output;

// ✅ GOOD: Escape within heredoc
$title_escaped = esc_html( $title );
$desc_escaped = esc_html( $description );
$output = <<<HTML
<div class="card">
    <h3>$title_escaped</h3>
    <p>$desc_escaped</p>
</div>
HTML;
echo $output;

// ✅ BETTER: Nowdoc with concatenation
$output = <<<'HTML'
<div class="card">
    <h3>
HTML;
$output .= esc_html( $title );
$output .= <<<'HTML'
</h3>
    <p>
HTML;
$output .= esc_html( $description );
$output .= <<<'HTML'
</p>
</div>
HTML;
echo $output;
```

### JavaScript Localization

```php
// ❌ BAD: Inline data without escaping
<script>
var config = {
    apiUrl: "<?php echo get_option( 'api_url' ); ?>",
    userName: "<?php echo $user_name; ?>"
};
</script>

// ✅ GOOD: wp_add_inline_script() + wp_json_encode() (current recommended pattern)
wp_add_inline_script(
    'my-script',
    'const myConfig = ' . wp_json_encode( array(
        'apiUrl'   => get_option( 'api_url' ),
        'userName' => $user_name,
        'nonce'    => wp_create_nonce( 'my_action' ),
        'enabled'  => true, // stays boolean
    ), JSON_HEX_TAG | JSON_HEX_AMP ) . ';',
    'before'
);

// ⚠️ OK: wp_localize_script() works but casts top-level scalars to strings
// ('enabled' => true becomes "1"). Keep it for i18n strings.

// In my-script.js:
// console.log( myConfig.apiUrl );
// console.log( myConfig.userName );

// ✅ GOOD: wp_json_encode() for complex data in a template
// JSON_HEX_TAG | JSON_HEX_AMP encode < > & as \u003C etc., so values containing
// "</script>" or "<!--" cannot break out of (or confuse) the inline <script> block.
// PHP values inside <script> are safe when JSON-encoded this way. The dangerous
// cases are unencoded values, and values encoded with esc_html()/esc_attr(),
// which are HTML escapes and do not make a value safe in a JS context.
<script>
var userData = <?php echo wp_json_encode( array(
    'id'    => get_current_user_id(),
    'name'  => wp_get_current_user()->display_name,
    'email' => wp_get_current_user()->user_email,
), JSON_HEX_TAG | JSON_HEX_AMP ); ?>;
</script>
```

Use the same flags with `wp_add_inline_script()`: `wp_json_encode( $data, JSON_HEX_TAG | JSON_HEX_AMP )`. The output is still printed inside a `<script>` element.

### REST API Responses

```php
// ❌ BAD: Escaping in REST response (breaks JSON)
function prefix_get_user( $request ) {
    $user = get_user_by( 'id', $request['id'] );

    return array(
        'name' => esc_html( $user->display_name ), // Don't escape here!
        'bio'  => esc_html( $user->description ),
    );
}

// ✅ GOOD: Return raw data, escape on frontend
function prefix_get_user( $request ) {
    $user = get_user_by( 'id', $request['id'] );

    return array(
        'name' => $user->display_name, // Raw data
        'bio'  => $user->description,  // Frontend escapes when rendering
    );
}

// Frontend JavaScript:
// fetch('/wp-json/myapp/v1/user/1')
//   .then(res => res.json())
//   .then(data => {
//     document.getElementById('name').textContent = data.name; // textContent escapes
//   });
```

### Reflected XSS via add_query_arg() and Request URLs

`add_query_arg()` and `remove_query_arg()` called without a URL argument build on `$_SERVER['REQUEST_URI']`, and they return the result **unescaped**. An attacker controls the request URI, so echoing that output, or echoing `$_SERVER['REQUEST_URI']`, `$_SERVER['PHP_SELF']` or `$_SERVER['HTTP_REFERER']` directly, is reflected XSS (CRITICAL, CWE-79). Always wrap these in `esc_url()` for `href`/`action`/`src`, or `esc_attr()`/`esc_html()` in other contexts.

```php
// ❌ CRITICAL: Unescaped URL built from the current request
<a href="<?php echo add_query_arg( 'tab', 'settings' ); ?>">Settings</a>
<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
<a href="<?php echo $_SERVER['HTTP_REFERER']; ?>">Back</a>
echo '<a href="' . remove_query_arg( 'updated' ) . '">Dismiss</a>';

// ✅ GOOD: Escape at output
<a href="<?php echo esc_url( add_query_arg( 'tab', 'settings' ) ); ?>">Settings</a>
echo '<a href="' . esc_url( remove_query_arg( 'updated' ) ) . '">Dismiss</a>';

// ✅ GOOD: Empty action posts back to the current URL; or build a known URL
<form action="" method="post">
<form action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" method="post">

// ✅ GOOD: Referer through core helper, then escape
<a href="<?php echo esc_url( wp_get_referer() ?: admin_url() ); ?>">Back</a>
```

### Shortcode Output

Shortcode attributes are user input. Contributors (no `unfiltered_html`) can save shortcodes in post content, so an attribute echoed raw is **stored XSS** that runs for editors and admins viewing the post (CRITICAL, CWE-79). `shortcode_atts()` only merges defaults; it does **not** sanitize. Escape every attribute at output for its context: `esc_attr()` in attributes, `esc_url()` in `href`/`src`, `esc_html()` in text.

```php
// ❌ BAD: Attribute echoed into markup
function prefix_button_shortcode( $atts ) {
    $atts = shortcode_atts( array( 'url' => '', 'label' => '', 'color' => 'blue' ), $atts, 'button' );
    return '<a class="btn-' . $atts['color'] . '" href="' . $atts['url'] . '">' . $atts['label'] . '</a>';
    // [button url="javascript:alert(1)" color='x" onmouseover="alert(1)']
}

// ✅ GOOD: Escape each attribute for its context
function prefix_button_shortcode( $atts ) {
    $atts = shortcode_atts( array( 'url' => '', 'label' => '', 'color' => 'blue' ), $atts, 'button' );
    return sprintf(
        '<a class="%s" href="%s">%s</a>',
        esc_attr( 'btn-' . sanitize_html_class( $atts['color'] ) ),
        esc_url( $atts['url'] ),
        esc_html( $atts['label'] )
    );
}
```

```php
// ❌ BAD: Unescaped shortcode attributes
function prefix_user_shortcode( $atts ) {
    $user_id = $atts['id'];
    $user = get_userdata( $user_id );

    return '<div class="user">' . $user->display_name . '</div>'; // XSS!
}
add_shortcode( 'user', 'prefix_user_shortcode' );

// ✅ GOOD: Sanitize attributes, escape output
function prefix_user_shortcode( $atts ) {
    $atts = shortcode_atts( array(
        'id' => 0,
    ), $atts, 'user' );

    $user_id = absint( $atts['id'] );
    $user = get_userdata( $user_id );

    if ( ! $user ) {
        return '';
    }

    return '<div class="user">' . esc_html( $user->display_name ) . '</div>';
}
add_shortcode( 'user', 'prefix_user_shortcode' );
```

### Block `render_callback` Output

Dynamic block attributes follow the same model as shortcode attributes: Contributors can save blocks with chosen attribute values. Since WP 5.3.1, `filter_block_kses()` runs kses on string attribute values for users without `unfiltered_html`, which strips disallowed tags. It does **not** make a value safe for every context: a quote in a value still breaks out of an HTML attribute, and a `javascript:` URL can survive. Unescaped output from a `render_callback` (or a `render.php` file) is therefore still stored XSS (CRITICAL, CWE-79). Escape each attribute for its output context. `get_block_wrapper_attributes()` returns already-escaped markup, so print it as is. The `$content` argument (inner blocks) is kses-filtered the same way.

```php
// ❌ BAD
function prefix_render_card( $attributes ) {
    return '<div class="' . $attributes['className'] . '">' . $attributes['title'] . '</div>';
}

// ✅ GOOD
function prefix_render_card( $attributes ) {
    $title = isset( $attributes['title'] ) ? $attributes['title'] : '';
    return sprintf(
        '<div %s>%s</div>',
        get_block_wrapper_attributes(), // Already escaped
        esc_html( $title )
    );
}
```

## Common Escaping Mistakes

### 1. Concatenation Before Escaping

```php
// ❌ BAD: Building string before escaping
$output = '<h1>' . $title . '</h1>';
echo esc_html( $output ); // Escapes the HTML tags too!

// ✅ GOOD: Escape data, not markup
echo '<h1>' . esc_html( $title ) . '</h1>';
```

### 2. Wrong Function for Context

```php
// ❌ BAD: HTML escaping for URL
echo '<a href="' . esc_html( $url ) . '">'; // Doesn't validate scheme!

// ⚠️ WRONG FUNCTION: Attribute escaping for HTML body
echo '<p>' . esc_attr( $text ) . '</p>'; // Encodes, but semantically wrong; WPCS flags it

// ✅ GOOD: Use correct function
echo '<a href="' . esc_url( $url ) . '">' . esc_html( $text ) . '</a>';
```

### 3. Escaping Before Storage / Double-Escaping

See "Why Late Escaping?" above. Severity: INFO (data integrity), not an exploitable flaw. Note `esc_html()` and `esc_attr()` do **not** double-encode existing entities; `esc_textarea()` and raw `htmlspecialchars()` (default `double_encode = true`) do, so visible `&amp;lt;` artifacts usually come from those or from escaping twice in JS.

### 4. Missing Escaping in Loops

```php
// ❌ BAD: Forgetting to escape in loop
foreach ( $users as $user ) {
    echo '<li>' . $user->display_name . '</li>'; // XSS!
}

// ✅ GOOD: Escape each item
foreach ( $users as $user ) {
    echo '<li>' . esc_html( $user->display_name ) . '</li>';
}
```

### 5. Trusting "Safe" Data Sources

```php
// ❌ BAD: Assuming post titles are safe
$post = get_post( $post_id );
echo '<h1>' . $post->post_title . '</h1>'; // Can contain HTML if editor inserted it!

// ✅ GOOD: Always escape output
$post = get_post( $post_id );
echo '<h1>' . esc_html( $post->post_title ) . '</h1>';

// Exception: To allow HTML, use wp_kses_post()
echo '<div>' . wp_kses_post( $post->post_content ) . '</div>';
```

## WordPress i18n + Escaping

Translated strings must also be escaped. WordPress provides combined functions.

### Translation + Escaping Functions

```php
// ❌ BAD: Translating without escaping
echo '<h1>' . __( 'Welcome', 'textdomain' ) . '</h1>'; // If translation contains HTML...

// ❌ BAD: Escaping before translation
echo esc_html( '<h1>' . __( 'Welcome', 'textdomain' ) . '</h1>' ); // Escapes markup!

// ✅ GOOD: Use combined functions
echo '<h1>' . esc_html__( 'Welcome', 'textdomain' ) . '</h1>';

// ✅ GOOD: esc_html_e() echoes and returns null — never concatenate it
echo '<h1>';
esc_html_e( 'Welcome', 'textdomain' );
echo '</h1>';

// ❌ BAD: echo '<h1>' . esc_html_e( 'Welcome', 'textdomain' ) . '</h1>';
// Prints "Welcome" BEFORE "<h1></h1>" because esc_html_e() echoes during concatenation.

// ✅ GOOD: Attribute context
echo '<input type="text" placeholder="' . esc_attr__( 'Enter name...', 'textdomain' ) . '">';

// ✅ GOOD: With variables
printf(
    '<p>' . esc_html__( 'Hello, %s!', 'textdomain' ) . '</p>',
    esc_html( $user_name )
);
```

**Available combined functions:**
- `esc_html__()` — Translate and escape for HTML
- `esc_html_e()` — Translate, escape, and echo for HTML
- `esc_html_x()` — Translate with context and escape for HTML
- `esc_attr__()` — Translate and escape for attributes
- `esc_attr_e()` — Translate, escape, and echo for attributes
- `esc_attr_x()` — Translate with context and escape for attributes

### Translated Strings with HTML

```php
// ❌ BAD: HTML in translation that gets escaped
echo '<p>' . esc_html__( 'Please <a href="/terms">read terms</a>', 'textdomain' ) . '</p>';
// Outputs: Please &lt;a href="/terms"&gt;read terms&lt;/a&gt;

// ✅ GOOD: Use wp_kses() with allowed tags
$allowed = array( 'a' => array( 'href' => array() ) );
echo '<p>' . wp_kses( __( 'Please <a href="/terms">read terms</a>', 'textdomain' ), $allowed ) . '</p>';

// ✅ GOOD: sprintf with escaping
printf(
    /* translators: %s: terms URL */
    wp_kses( __( 'Please <a href="%s">read terms</a>', 'textdomain' ), array( 'a' => array( 'href' => array() ) ) ),
    esc_url( get_permalink( $terms_page_id ) )
);

// ✅ BETTER: Separate link from translation
printf(
    /* translators: %s: link to terms page */
    esc_html__( 'Please %s.', 'textdomain' ),
    '<a href="' . esc_url( get_permalink( $terms_page_id ) ) . '">' . esc_html__( 'read terms', 'textdomain' ) . '</a>'
);
```

Related: input sanitization → `sanitization-guide.md`; XSS vulnerability patterns → `vulnerability-patterns.md`.
