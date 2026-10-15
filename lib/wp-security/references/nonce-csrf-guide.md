# WordPress Nonce and CSRF Protection Guide

WordPress nonces provide Cross-Site Request Forgery (CSRF) protection. Despite the name ("number used once"), WordPress nonces are **not single-use**: the same token stays valid and reusable for 12-24 hours and gives **no replay protection**. A nonce proves the request came from a page WordPress rendered for this user/session and action; it is not authorization and not a one-time token. For true one-time operations, store and invalidate a custom token server-side.

This guide covers nonce lifecycle, form/AJAX/URL/REST patterns, bypass patterns, when nonces aren't needed, and common debugging issues.

**Contents:** Quick Reference Table · Nonce Lifecycle (ticks, per-user nonces, `nonce_user_logged_out`, nopriv handlers, naming) · Form Nonces · AJAX Nonces · URL Nonces · REST API Nonces · Nonce Bypass Patterns (incl. no-action `check_admin_referer()` bypass) · When Nonces Are NOT Needed · Nonce Debugging

## Quick Reference Table

| Function | Purpose | Returns | Use Case |
|----------|---------|---------|----------|
| `wp_create_nonce( $action )` | Create nonce token | String | Generate nonce for action |
| `wp_verify_nonce( $nonce, $action )` | Verify nonce token | false/1/2 | Validate nonce manually |
| `wp_nonce_field( $action, $name )` | Output hidden input | Void | Add nonce to forms |
| `wp_nonce_url( $url, $action )` | Add nonce to URL | String (`&amp;`-escaped for HTML) | Create nonce-protected link; not for redirects |
| `check_admin_referer( $action, $name )` | Verify form nonce | 1 or 2 (int); dies on failure when `$action` is passed. With no action (`-1`) it can return `false` without dying (see Nonce Bypass Patterns (d)) | Form submission verification |
| `check_ajax_referer( $action, $query_arg, $die )` | Verify AJAX nonce | 1 or 2 (int); on failure dies (`-1`, or 403 for AJAX), or returns `false` when `$die` is `false` | AJAX request verification |
| `wp_create_nonce( 'wp_rest' )` | Create REST nonce | String | Cookie authentication for REST |

## Nonce Lifecycle

Understanding how nonces work is critical to using them correctly.

### Creation and Validation

```php
// Creation
$nonce = wp_create_nonce( 'my_action' );
// Result: "a1b2c3d4e5" (10-character token)

// Validation (returns false, 1, or 2)
$result = wp_verify_nonce( $nonce, 'my_action' );
// false: Invalid or expired nonce
// 1: Valid, generated in the CURRENT tick
// 2: Valid, generated in the PREVIOUS tick (expires at the next tick boundary)
```

### Validity Period (Two Ticks)

`wp_nonce_tick()` returns `ceil( time() / ( DAY_IN_SECONDS / 2 ) )`. Ticks are **fixed 12-hour windows aligned to the Unix epoch** (UTC), not windows that start when the nonce is created. A nonce is accepted during the tick it was created in and the following tick.

```
Epoch-aligned ticks:  |---- tick N (12h) ----|---- tick N+1 (12h) ----|---- tick N+2 ----
Nonce created at A:      A                                              ^ invalid from here
                         └── returns 1 ──────┘└──── returns 2 ────────┘
Lifetime = (rest of tick N) + 12h  →  between just over 12h and 24h
```

- Created just after a tick boundary → valid almost 24 hours.
- Created just before a tick boundary → valid just over 12 hours.
- The `nonce_life` filter changes the window length (default `DAY_IN_SECONDS`, i.e. two 12h ticks).

**Why two ticks?** A form loaded at 11:55 UTC and submitted at 12:05 UTC crosses a tick boundary. Accepting the previous tick keeps that submission valid.

### Per-User Nonces

Nonces are derived from the action, the tick, the user ID, and the user's session token. Same action, different logged-in users = different nonces.

```php
// User 1 (ID: 5) creates nonce
$user_1_nonce = wp_create_nonce( 'delete_post' );
// Result: "a1b2c3d4e5"

// User 2 (ID: 10) creates nonce for same action
$user_2_nonce = wp_create_nonce( 'delete_post' );
// Result: "f9g8h7i6j5" (different!)

// User 2's nonce won't validate for User 1
wp_verify_nonce( $user_2_nonce, 'delete_post' ); // false (wrong user)

// Logged-out users: user ID is 0 and session token is empty
// ALL logged-out visitors get the SAME nonce for a given action and tick
// Any anonymous attacker can load the page and read a valid nonce
// (unless a plugin hooks nonce_user_logged_out, see below)
```

**Exception: the `nonce_user_logged_out` filter.** For user ID 0, `wp_create_nonce()` and `wp_verify_nonce()` pass the ID through `apply_filters( 'nonce_user_logged_out', 0, $action )`. Plugins can return a per-guest value there. WooCommerce does this to give each guest session (cart cookie) its own nonce. The shared-anonymous-nonce rule applies only when nothing hooks this filter. Check the codebase and active plugins before relying on it either way.

### Nonces on Logged-Out (`nopriv`) Handlers

Because every anonymous visitor shares the same nonce (absent a `nonce_user_logged_out` filter), a nonce on a `wp_ajax_nopriv_*` or public `admin-post.php` handler adds little CSRF protection. CSRF abuses a victim's authenticated session; an unauthenticated request carries no session to abuse.

- A nonce on a nopriv handler is still useful as light anti-automation and to confirm the request came from a rendered page.
- Rate a missing nonce on a nopriv-only handler by impact: **INFO** for read-only or harmless actions, **WARNING** for state changes such as spam-prone submissions.
- Rate it **CRITICAL** only when the same callback is also registered on `wp_ajax_*` (logged-in) and changes state for the logged-in user. Then CSRF against logged-in visitors is real.
- Rate abuse controls separately: rate limiting, CAPTCHA, and input validation.

### Nonce Naming Convention

Use descriptive action names that describe the operation, not the form.

```php
// ❌ BAD: Generic or form-focused names
wp_create_nonce( 'nonce' );          // Too generic
wp_create_nonce( 'form' );           // What form?
wp_create_nonce( 'submit' );         // What action?
wp_create_nonce( 'settings_form' );  // Form name, not action

// ✅ GOOD: Action-focused names
wp_create_nonce( 'delete_post' );
wp_create_nonce( 'update_user_profile' );
wp_create_nonce( 'publish_draft' );
wp_create_nonce( 'export_data' );

// ✅ GOOD: Include context for similar actions
wp_create_nonce( 'delete_post_' . $post_id );
wp_create_nonce( 'update_user_' . $user_id );
```

## Form Nonces

Standard form protection with three-step process.

### Step 1: Add Nonce to Form

```php
// ❌ BAD: Form without nonce
<form method="post">
    <input type="text" name="title" />
    <button type="submit">Save</button>
</form>

// ✅ GOOD: wp_nonce_field() adds hidden input
<form method="post">
    <?php wp_nonce_field( 'save_post_action', 'save_post_nonce' ); ?>
    <input type="text" name="title" />
    <button type="submit">Save</button>
</form>

// Outputs:
// <input type="hidden" id="save_post_nonce" name="save_post_nonce" value="a1b2c3d4e5" />
// <input type="hidden" name="_wp_http_referer" value="/wp-admin/post.php?post=123" />
```

**wp_nonce_field() parameters:**
```php
wp_nonce_field(
    $action,      // Action name (string)
    $name,        // Field name (string, default: '_wpnonce')
    $referer,     // Include referer field (bool, default: true)
    $echo         // Echo or return (bool, default: true)
);
```

### Step 2: Verify Nonce on Submission

```php
// ❌ BAD: No nonce verification
function prefix_handle_form() {
    if ( isset( $_POST['submit'] ) ) {
        // Anyone can submit! CSRF vulnerability
        update_option( 'title', $_POST['title'] );
    }
}
add_action( 'admin_init', 'prefix_handle_form' );

// ✅ GOOD: Verify nonce before processing
// The early return is safe because NOTHING is processed when the field is absent.
// Compare "Nonce Bypass Patterns" (a): processing that continues without the field is the bug.
function prefix_handle_form() {
    if ( ! isset( $_POST['save_post_nonce'] ) ) {
        return; // Not our form: do nothing
    }

    if ( ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['save_post_nonce'] ) ), 'save_post_action' ) ) {
        wp_die( 'Invalid nonce' );
    }

    // admin_init also runs for admin-ajax.php / admin-post.php, so check capability too
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions' );
    }

    $title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
    update_option( 'post_title', $title );
}
add_action( 'admin_init', 'prefix_handle_form' );

// ✅ GOOD: Using check_admin_referer() (dies automatically)
function prefix_handle_form() {
    if ( ! isset( $_POST['save_post_nonce'] ) ) {
        return; // Not our form: do nothing
    }

    check_admin_referer( 'save_post_action', 'save_post_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions' );
    }

    $title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
    update_option( 'post_title', $title );
}
add_action( 'admin_init', 'prefix_handle_form' );
```

Prefer a dedicated `admin_post_{action}` hook over `admin_init` for form handlers: it only runs when that action is submitted.

**check_admin_referer() vs wp_verify_nonce():**
- `check_admin_referer()`: Dies with error if nonce invalid; returns 1 or 2 when valid. This holds only when an action is passed: with no action it can return `false` and continue (Nonce Bypass Patterns (d))
- `wp_verify_nonce()`: Returns false/1/2; caller handles failure response

### Step 3: Check Capability (Full Protection)

Nonce alone isn't enough. Always check user capability.

```php
// ❌ BAD: Only nonce check (any logged-in user can delete!)
function prefix_delete_post() {
    check_admin_referer( 'delete_post_nonce', 'nonce' );
    wp_delete_post( $_POST['post_id'] );
}

// ✅ GOOD: Three-step security (nonce + capability + sanitization)
function prefix_delete_post() {
    // 1. Verify nonce
    if ( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['nonce'] ) ), 'delete_post_action' ) ) {
        wp_die( 'Invalid nonce' );
    }

    // 2. Check capability
    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_die( 'Insufficient permissions' );
    }

    // 3. Sanitize input and perform action
    wp_delete_post( $post_id, true );

    wp_safe_redirect( admin_url( 'edit.php' ) );
    exit;
}
add_action( 'admin_post_delete_post', 'prefix_delete_post' );
```

### Complete Form Example

```php
// Display form
function prefix_display_settings_form() {
    $current_title = get_option( 'prefix_site_title', '' );
    ?>
    <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
        <?php wp_nonce_field( 'save_settings_action', 'settings_nonce' ); ?>
        <input type="hidden" name="action" value="prefix_save_settings" />

        <label for="site_title">Site Title:</label>
        <input type="text" id="site_title" name="site_title" value="<?php echo esc_attr( $current_title ); ?>" />

        <button type="submit">Save Settings</button>
    </form>
    <?php
}

// Handle form submission
function prefix_handle_settings_form() {
    // 1. Verify nonce
    if ( ! isset( $_POST['settings_nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['settings_nonce'] ) ), 'save_settings_action' ) ) {
        wp_die( 'Invalid security token' );
    }

    // 2. Check capability
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'You do not have permission to modify settings' );
    }

    // 3. Sanitize and save
    $title = isset( $_POST['site_title'] ) ? sanitize_text_field( wp_unslash( $_POST['site_title'] ) ) : '';
    update_option( 'prefix_site_title', $title );

    // 4. Redirect back
    wp_safe_redirect( add_query_arg( 'settings-updated', 'true', wp_get_referer() ) );
    exit;
}
add_action( 'admin_post_prefix_save_settings', 'prefix_handle_settings_form' );
```

## AJAX Nonces

AJAX requests need nonces passed via JavaScript.

### Step 1: Create and Localize Nonce

```php
// ❌ BAD: Nonce in inline script (harder to maintain)
function prefix_enqueue_ajax_script() {
    wp_enqueue_script( 'prefix-ajax', plugin_dir_url( __FILE__ ) . 'ajax.js', array( 'jquery' ), '1.0', true );
    ?>
    <script>
        var prefixAjax = {
            ajaxurl: '<?php echo esc_url( admin_url( 'admin-ajax.php' ) ); ?>',
            nonce: '<?php echo wp_create_nonce( 'prefix_ajax_action' ); ?>'
        };
    </script>
    <?php
}
add_action( 'wp_enqueue_scripts', 'prefix_enqueue_ajax_script' );

// ✅ GOOD: Use wp_localize_script()
function prefix_enqueue_ajax_script() {
    wp_enqueue_script( 'prefix-ajax', plugin_dir_url( __FILE__ ) . 'ajax.js', array( 'jquery' ), '1.0', true );

    wp_localize_script( 'prefix-ajax', 'prefixAjax', array(
        'ajaxurl' => admin_url( 'admin-ajax.php' ),
        'nonce'   => wp_create_nonce( 'prefix_ajax_action' ),
    ) );
}
add_action( 'wp_enqueue_scripts', 'prefix_enqueue_ajax_script' );
```

### Step 2: Send Nonce with AJAX Request

```javascript
// ❌ BAD: No nonce sent
jQuery.post(
    prefixAjax.ajaxurl,
    {
        action: 'prefix_delete_post',
        post_id: 123
    },
    function(response) {
        console.log(response);
    }
);

// ✅ GOOD: Include nonce in data (jQuery)
jQuery.post(
    prefixAjax.ajaxurl,
    {
        action: 'prefix_delete_post',
        post_id: 123,
        nonce: prefixAjax.nonce
    },
    function(response) {
        if (response.success) {
            console.log('Deleted:', response.data);
        } else {
            console.error('Error:', response.data);
        }
    }
);

// ✅ GOOD: Modern fetch API
fetch(prefixAjax.ajaxurl, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
        action: 'prefix_delete_post',
        post_id: 123,
        nonce: prefixAjax.nonce
    })
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        console.log('Deleted:', data.data);
    }
});

// ✅ GOOD: Axios
axios.post(prefixAjax.ajaxurl, new URLSearchParams({
    action: 'prefix_delete_post',
    post_id: 123,
    nonce: prefixAjax.nonce
}))
.then(response => {
    if (response.data.success) {
        console.log('Deleted:', response.data.data);
    }
});
```

### Step 3: Verify Nonce in Handler

```php
// ❌ BAD: No nonce verification
function prefix_delete_post_ajax() {
    $post_id = absint( $_POST['post_id'] );
    wp_delete_post( $post_id );
    wp_send_json_success();
}
add_action( 'wp_ajax_prefix_delete_post', 'prefix_delete_post_ajax' );

// ✅ GOOD: Verify nonce with check_ajax_referer()
function prefix_delete_post_ajax() {
    // Verify nonce (dies automatically if invalid)
    check_ajax_referer( 'prefix_ajax_action', 'nonce' );

    // Check capability
    $post_id = absint( $_POST['post_id'] );
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_send_json_error( array( 'message' => 'Permission denied' ) );
    }

    // Perform action
    wp_delete_post( $post_id, true );
    wp_send_json_success( array( 'message' => 'Post deleted' ) );
}
add_action( 'wp_ajax_prefix_delete_post', 'prefix_delete_post_ajax' );

// ✅ GOOD: Manual verification with custom response
function prefix_delete_post_ajax() {
    $nonce = isset( $_POST['nonce'] ) ? sanitize_key( wp_unslash( $_POST['nonce'] ) ) : '';

    if ( ! wp_verify_nonce( $nonce, 'prefix_ajax_action' ) ) {
        wp_send_json_error( array(
            'message' => 'Invalid security token. Please refresh the page.',
        ) );
    }

    $post_id = absint( $_POST['post_id'] );
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_send_json_error( array( 'message' => 'Permission denied' ) );
    }

    wp_delete_post( $post_id, true );
    wp_send_json_success( array( 'message' => 'Post deleted successfully' ) );
}
add_action( 'wp_ajax_prefix_delete_post', 'prefix_delete_post_ajax' );
```

**check_ajax_referer() parameters:**
```php
check_ajax_referer(
    $action,      // Action name (string)
    $query_arg,   // Nonce field name (string|false, default: false = check $_REQUEST['_ajax_nonce'], then $_REQUEST['_wpnonce'])
    $die          // Die on failure (bool, default: true)
);
```

### Complete AJAX Example

```php
// PHP: Enqueue script with nonce
function prefix_enqueue_scripts() {
    wp_enqueue_script( 'prefix-voting', plugin_dir_url( __FILE__ ) . 'voting.js', array( 'jquery' ), '1.0', true );

    wp_localize_script( 'prefix-voting', 'votingData', array(
        'ajaxurl' => admin_url( 'admin-ajax.php' ),
        'nonce'   => wp_create_nonce( 'vote_action' ),
    ) );
}
add_action( 'wp_enqueue_scripts', 'prefix_enqueue_scripts' );

// PHP: AJAX handler (wp_ajax_ only, so the user is logged in; voting is open to
// every logged-in user by design, so read capability on the post is the check)
function prefix_handle_vote() {
    check_ajax_referer( 'vote_action', 'nonce' );

    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
    if ( ! current_user_can( 'read_post', $post_id ) ) {
        wp_send_json_error( array( 'message' => 'Cannot vote on this post' ), 403 );
    }

    $vote = isset( $_POST['vote'] ) ? sanitize_key( wp_unslash( $_POST['vote'] ) ) : '';

    if ( ! in_array( $vote, array( 'up', 'down' ), true ) ) {
        wp_send_json_error( array( 'message' => 'Invalid vote' ) );
    }

    // Record vote
    $current_votes = absint( get_post_meta( $post_id, '_votes_' . $vote, true ) );
    update_post_meta( $post_id, '_votes_' . $vote, $current_votes + 1 );

    wp_send_json_success( array(
        'message' => 'Vote recorded',
        'total'   => $current_votes + 1,
    ) );
}
add_action( 'wp_ajax_prefix_vote', 'prefix_handle_vote' );
```

```javascript
// JavaScript: voting.js
jQuery(document).ready(function($) {
    $('.vote-button').on('click', function(e) {
        e.preventDefault();

        var button = $(this);
        var postId = button.data('post-id');
        var voteType = button.data('vote-type');

        $.post(
            votingData.ajaxurl,
            {
                action: 'prefix_vote',
                post_id: postId,
                vote: voteType,
                nonce: votingData.nonce
            },
            function(response) {
                if (response.success) {
                    button.find('.count').text(response.data.total);
                    alert(response.data.message);
                } else {
                    alert(response.data.message);
                }
            }
        );
    });
});
```

## URL Nonces

For action links (delete, trash, approve).

### Creating Nonce URLs

```php
// ❌ BAD: Action link without nonce
$delete_url = admin_url( 'admin-post.php?action=delete_post&post_id=' . $post_id );
echo '<a href="' . esc_url( $delete_url ) . '">Delete</a>';
// CSRF vulnerability! Anyone can craft this URL

// ✅ GOOD: Use wp_nonce_url()
$delete_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=delete_post&post_id=' . $post_id ),
    'delete_post_' . $post_id
);
echo '<a href="' . esc_url( $delete_url ) . '">Delete</a>';
// Outputs: .../admin-post.php?action=delete_post&amp;post_id=123&amp;_wpnonce=a1b2c3d4e5

// ✅ GOOD: Custom nonce parameter name
$delete_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=delete_post&post_id=' . $post_id ),
    'delete_post_' . $post_id,
    'delete_nonce' // Custom parameter name
);
// Outputs: .../admin-post.php?action=delete_post&amp;post_id=123&amp;delete_nonce=a1b2c3d4e5
```

`wp_nonce_url()` escapes its output for HTML (`&` becomes `&amp;`). Use it only for links. For a redirect target, build the URL with `add_query_arg()`; passing `wp_nonce_url()` output to `wp_safe_redirect()` sends a literal `&amp;` and breaks the query string:

```php
// ❌ BAD: &amp; in a Location header
wp_safe_redirect( wp_nonce_url( admin_url( 'admin.php?page=prefix&step=2' ), 'prefix_step' ) );

// ✅ GOOD: Unescaped URL for redirects
wp_safe_redirect( add_query_arg( '_wpnonce', wp_create_nonce( 'prefix_step' ), admin_url( 'admin.php?page=prefix&step=2' ) ) );
exit;
```

**wp_nonce_url() parameters:**
```php
wp_nonce_url(
    $actionurl,   // URL to add nonce to (string)
    $action,      // Action name (string, default: -1)
    $name         // Nonce parameter name (string, default: '_wpnonce')
);
```

### Verifying URL Nonces

```php
// ❌ BAD: No nonce verification
function prefix_handle_delete() {
    $post_id = absint( $_GET['post_id'] );
    wp_delete_post( $post_id );
    wp_safe_redirect( admin_url( 'edit.php' ) );
    exit;
}
add_action( 'admin_post_delete_post', 'prefix_handle_delete' );

// ✅ GOOD: Verify nonce before deleting
function prefix_handle_delete() {
    $post_id = isset( $_GET['post_id'] ) ? absint( $_GET['post_id'] ) : 0;

    // Verify nonce (default parameter name: _wpnonce)
    if ( ! isset( $_GET['_wpnonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_GET['_wpnonce'] ) ), 'delete_post_' . $post_id ) ) {
        wp_die( 'Invalid security token' );
    }

    // Check capability
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_die( 'You do not have permission to delete this post' );
    }

    // Perform deletion
    wp_delete_post( $post_id, true );

    wp_safe_redirect( admin_url( 'edit.php?deleted=1' ) );
    exit;
}
add_action( 'admin_post_delete_post', 'prefix_handle_delete' );

// ✅ GOOD: Custom parameter name
function prefix_handle_delete() {
    $post_id = isset( $_GET['post_id'] ) ? absint( $_GET['post_id'] ) : 0;

    if ( ! isset( $_GET['delete_nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_GET['delete_nonce'] ) ), 'delete_post_' . $post_id ) ) {
        wp_die( 'Invalid security token' );
    }

    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_die( 'Insufficient permissions' );
    }

    wp_delete_post( $post_id, true );
    wp_safe_redirect( admin_url( 'edit.php?deleted=1' ) );
    exit;
}
add_action( 'admin_post_delete_post', 'prefix_handle_delete' );
```

### Common URL Nonce Patterns

```php
// ✅ GOOD: Trash link
$trash_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=trash_post&post_id=' . $post_id ),
    'trash_post_' . $post_id
);
echo '<a href="' . esc_url( $trash_url ) . '">Move to Trash</a>';

// ✅ GOOD: Approve comment link
$approve_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=approve_comment&comment_id=' . $comment_id ),
    'approve_comment_' . $comment_id
);
echo '<a href="' . esc_url( $approve_url ) . '">Approve</a>';

// ✅ GOOD: Toggle feature
$current_status = get_option( 'prefix_feature_enabled' );
$toggle_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=toggle_feature' ),
    'toggle_feature_action'
);
echo '<a href="' . esc_url( $toggle_url ) . '">';
echo $current_status ? esc_html__( 'Disable Feature', 'textdomain' ) : esc_html__( 'Enable Feature', 'textdomain' );
echo '</a>';
```

## REST API Nonces

REST API uses nonces only for cookie authentication.

### Cookie Authentication (X-WP-Nonce Header or `_wpnonce` Parameter)

Core accepts the `wp_rest` nonce from the `X-WP-Nonce` header or from a `_wpnonce` request parameter (query string or body). The header is the usual choice for `fetch()`; `_wpnonce` suits plain links and form posts.

```php
// PHP: Localize nonce for REST API
function prefix_enqueue_rest_script() {
    wp_enqueue_script( 'prefix-rest', plugin_dir_url( __FILE__ ) . 'rest.js', array(), '1.0', true );

    wp_localize_script( 'prefix-rest', 'wpApiSettings', array(
        'root'  => esc_url_raw( rest_url() ),
        'nonce' => wp_create_nonce( 'wp_rest' ), // Standard REST nonce
    ) );
}
add_action( 'wp_enqueue_scripts', 'prefix_enqueue_rest_script' );
```

```javascript
// ❌ BAD: No X-WP-Nonce header
fetch('/wp-json/myapp/v1/posts/123', {
    method: 'DELETE'
})
.then(response => response.json());
// Fails with 401 if permission_callback requires authentication

// ✅ GOOD: Include X-WP-Nonce header
fetch(wpApiSettings.root + 'myapp/v1/posts/123', {
    method: 'DELETE',
    headers: {
        'X-WP-Nonce': wpApiSettings.nonce
    }
})
.then(response => response.json())
.then(data => console.log('Deleted:', data));

// ✅ GOOD: With jQuery
jQuery.ajax({
    url: wpApiSettings.root + 'myapp/v1/posts/123',
    method: 'DELETE',
    beforeSend: function(xhr) {
        xhr.setRequestHeader('X-WP-Nonce', wpApiSettings.nonce);
    },
    success: function(response) {
        console.log('Deleted:', response);
    }
});

// ✅ GOOD: Axios with default headers
axios.defaults.headers.common['X-WP-Nonce'] = wpApiSettings.nonce;
axios.delete(wpApiSettings.root + 'myapp/v1/posts/123')
    .then(response => console.log('Deleted:', response.data));
```

### How REST Cookie Auth Uses the Nonce

- Core (`rest_cookie_check_errors()`) verifies the `wp_rest` nonce from the `X-WP-Nonce` header or `_wpnonce` parameter. Route callbacks never verify it themselves.
- Valid cookie + **missing** nonce → the request runs as **logged-out** (user 0). It does not error; it simply fails any `permission_callback` that needs a capability. This is what makes cookie-authenticated REST CSRF-safe.
- Valid cookie + **invalid** nonce → `403 rest_cookie_invalid_nonce`.
- So a REST route's CSRF protection depends entirely on a real `permission_callback`. A route with `__return_true` or a missing callback is open to anyone, nonce or not. For `permission_callback` patterns, see auth-patterns.md → REST API Permission Callbacks.

## Nonce Bypass Patterns

Each pattern below has a nonce call that looks present but can be skipped. Rate each **CRITICAL** (CWE-352) when the handler changes state for a logged-in user, except (e), which is WARNING unless a `-1` nonce is exposed.

### (a) Verification only runs when the field is present

```php
// ❌ BAD: Attacker omits 'prefix_nonce'; the check is skipped and processing continues
if ( isset( $_POST['prefix_nonce'] ) && ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['prefix_nonce'] ) ), 'prefix_save' ) ) {
    wp_die( 'Invalid nonce' );
}
update_option( 'prefix_setting', sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) ) );

// ✅ GOOD: Missing field = failure
if ( ! isset( $_POST['prefix_nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['prefix_nonce'] ) ), 'prefix_save' ) ) {
    wp_die( 'Invalid nonce', 403 );
}
```

### (b) `check_ajax_referer()` with `$die = false` and the result ignored

```php
// ❌ BAD: Third argument false = returns false instead of dying; nothing checks it
check_ajax_referer( 'prefix_save', 'nonce', false );
update_option( 'prefix_setting', $value );

// ✅ GOOD: Default $die = true, or act on the return value
if ( false === check_ajax_referer( 'prefix_save', 'nonce', false ) ) {
    wp_send_json_error( 'Invalid nonce', 403 );
}
```

### (c) `wp_verify_nonce()` result not acted on

```php
// ❌ BAD: Result only logged, or assigned and never used
$valid = wp_verify_nonce( $nonce, 'prefix_save' );
if ( ! $valid ) {
    error_log( 'Bad nonce' ); // ...and execution continues
}
wp_delete_post( $post_id );

// ✅ GOOD: Stop on failure
if ( ! wp_verify_nonce( $nonce, 'prefix_save' ) ) {
    wp_die( 'Invalid nonce', 403 );
}
```

### (d) `check_admin_referer()` with no action: full bypass

With no `$action`, `check_admin_referer()` uses `-1` and falls back to a referer check. When the nonce fails, core calls `wp_nonce_ays()` (which dies) only if `wp_get_referer()` does **not** start with `admin_url()`. `wp_get_referer()` reads the request's `_wp_http_referer` parameter first, and that value only has to pass a same-host check (`wp_validate_redirect()`). The comparison is against the absolute `admin_url()`, so a relative `/wp-admin/` does not work; an attacker's forged form sets `_wp_http_referer=https://victim.example/wp-admin/` (same host, absolute URL), the call returns `false` without dying, and the handler continues. Core has emitted a `_doing_it_wrong` notice for the missing action since WP 3.2, but the request is not blocked. Rate **CRITICAL** (CWE-352).

```php
// ❌ CRITICAL: No action; forged POST with _wp_http_referer=https://victim.example/wp-admin/ passes
add_action( 'admin_post_prefix_reset', function() {
    check_admin_referer();
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Denied', 403 );
    }
    delete_option( 'prefix_settings' );
} );

// ✅ GOOD: Explicit action (and field name); failure always dies
add_action( 'admin_post_prefix_reset', function() {
    check_admin_referer( 'prefix_reset', 'prefix_nonce' );
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Denied', 403 );
    }
    delete_option( 'prefix_settings' );
} );
```

### (e) Missing or generic `$action` on nonce creation and verification

A nonce created or verified without an action uses `-1`. Every `-1` nonce on the site is interchangeable, so a nonce leaked from any other `-1` form (core or plugin) passes here. Rate WARNING; CRITICAL when combined with a leaked `-1` nonce on a page the attacker can read.

```php
// ❌ BAD: Shared -1 nonce
wp_nonce_field();
wp_create_nonce();
wp_verify_nonce( $nonce );           // Action -1

// ✅ GOOD: Specific action, ideally scoped to the object
wp_nonce_field( 'prefix_delete_item_' . $item_id, 'prefix_nonce' );
check_admin_referer( 'prefix_delete_item_' . $item_id, 'prefix_nonce' );
```

### (f) State changes on broad hooks without a nonce

`admin_init` fires for every `/wp-admin/` request, **including `admin-ajax.php` and `admin-post.php` from logged-out visitors**. `init`, `wp_loaded`, and `template_redirect` fire on every front-end request. A handler there that reads `$_GET`/`$_POST` and changes state is reachable by a plain link or auto-submitting form.

```php
// ❌ BAD: Any logged-in admin who visits a crafted link resets settings
add_action( 'admin_init', function() {
    if ( isset( $_GET['prefix_reset'] ) ) {
        delete_option( 'prefix_settings' );
    }
} );

// ✅ GOOD: Nonce + capability, or move to admin_post_{action}
add_action( 'admin_init', function() {
    if ( ! isset( $_GET['prefix_reset'] ) ) {
        return;
    }
    check_admin_referer( 'prefix_reset' );
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions', 403 );
    }
    delete_option( 'prefix_settings' );
} );
```

## When Nonces Are NOT Needed

Some WordPress operations don't require nonces because they're not vulnerable to CSRF.

### 1. WP-CLI Commands

```php
// ✅ NO NONCE NEEDED: WP-CLI runs server-side, no HTTP request
function prefix_cli_command( $args, $assoc_args ) {
    // No check_admin_referer() needed
    // WP-CLI commands can't be triggered via CSRF

    $post_id = absint( $assoc_args['post-id'] );

    // NOTE: WP-CLI runs as user ID 0 unless invoked with --user=<id|login>.
    // current_user_can() always returns false for user 0, so a capability
    // check here only works when the command is run with --user. Anyone with
    // shell access already has full control, so a check is optional.
    // Example: wp myapp delete-post --post-id=123 --user=admin

    wp_delete_post( $post_id, true );
    WP_CLI::success( 'Post deleted' );
}
WP_CLI::add_command( 'myapp delete-post', 'prefix_cli_command' );
```

### 2. WP-Cron Scheduled Tasks

```php
// ✅ NO NONCE NEEDED: Cron runs server-initiated, no user request
function prefix_daily_cleanup() {
    // No nonce verification needed
    // Cron jobs can't be triggered via CSRF

    $old_posts = get_posts( array(
        'post_status' => 'trash',
        'date_query'  => array(
            array( 'before' => '30 days ago' ),
        ),
    ) );

    foreach ( $old_posts as $post ) {
        wp_delete_post( $post->ID, true );
    }
}
add_action( 'prefix_daily_cleanup_hook', 'prefix_daily_cleanup' );
```

### 3. REST API with Application Passwords or OAuth

```php
// ✅ NO NONCE NEEDED: Application passwords/OAuth provide authentication
// REST route (same as before)
register_rest_route( 'myapp/v1', '/posts', array(
    'methods'             => 'POST',
    'callback'            => 'prefix_create_post_rest',
    'permission_callback' => function() {
        return current_user_can( 'publish_posts' );
    },
) );

// Authenticated with application password via Basic Auth:
// Authorization: Basic base64(username:app_password)

// No X-WP-Nonce header needed! Application password is sufficient.
```

### 4. Public Read-Only GET Requests

```php
// ✅ NO NONCE NEEDED: Read-only, no state change
function prefix_handle_search() {
    // Public search, no authentication, no state change
    $query = isset( $_GET['q'] ) ? sanitize_text_field( wp_unslash( $_GET['q'] ) ) : '';

    $posts = get_posts( array(
        's'            => $query,
        'post_status'  => 'publish',
        'has_password' => false, // Exclude password-protected posts
        'numberposts'  => 10,
    ) );

    // Return only public fields. Never send raw WP_Post objects:
    // they include post_content and post_password.
    $results = array_map( function( $post ) {
        return array(
            'id'    => $post->ID,
            'title' => get_the_title( $post ),
            'url'   => get_permalink( $post ),
        );
    }, $posts );

    wp_send_json_success( $results );
}
add_action( 'wp_ajax_nopriv_prefix_search', 'prefix_handle_search' );
add_action( 'wp_ajax_prefix_search', 'prefix_handle_search' );
```

### Summary: When to Skip Nonces

| Scenario | Nonce Needed? | Why |
|----------|---------------|-----|
| Form submission (POST) | ✅ YES | User-initiated, state-changing |
| AJAX request (state-changing) | ✅ YES | User-initiated via browser |
| URL action link (GET, state-changing) | ✅ YES | User-initiated, clickable |
| REST API (cookie auth) | ✅ YES | Cookie-based, needs X-WP-Nonce |
| REST API (app password/OAuth) | ❌ NO | Alternative authentication |
| WP-CLI command | ❌ NO | Server-side, not HTTP request |
| WP-Cron task | ❌ NO | Server-initiated, not user request |
| Public GET (read-only) | ❌ NO | No state change, no CSRF risk |
| `wp_ajax_nopriv_*` only (state-changing) | ⚠️ Optional | All anonymous users share one nonce; little CSRF value. Rate by impact (INFO/WARNING) |
| Admin-area state change | ✅ YES | CSRF targets privileged users; missing nonce stays CRITICAL |

## Nonce Debugging

Common issues and solutions.

### 1. Action Name Mismatch

```php
// ❌ BAD: Different action names
wp_nonce_field( 'save_post', 'nonce' ); // Creating with 'save_post'

check_admin_referer( 'update_post', 'nonce' ); // Verifying 'update_post' — FAILS!

// ✅ GOOD: Same action name
wp_nonce_field( 'save_post_action', 'nonce' );
check_admin_referer( 'save_post_action', 'nonce' ); // Matches!
```

### 2. Field Name Mismatch

```php
// ❌ BAD: Different field names
wp_nonce_field( 'save_post', 'my_nonce' ); // Field name: my_nonce

check_admin_referer( 'save_post', 'nonce' ); // Looking for 'nonce' — FAILS!

// ✅ GOOD: Same field name
wp_nonce_field( 'save_post', 'my_nonce' );
check_admin_referer( 'save_post', 'my_nonce' ); // Matches!
```

### 3. Expired Nonces

```php
// Nonce expires after 12-24 hours
// User loads form at 9 AM Monday
// User submits form at 11 AM Tuesday (26 hours later)
// Nonce expired!

// ✅ SOLUTION: Show friendly error
if ( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['nonce'] ) ), 'prefix_action' ) ) {
    wp_die(
        'Your security token has expired. Please <a href="javascript:history.back()">go back</a> and try again.',
        'Security Token Expired',
        array( 'response' => 403 )
    );
}
```

### 4. Caching Plugins

```php
// Problem: Nonce cached in HTML, expires, form fails

// ✅ SOLUTION 1: Exclude pages with forms from caching
// Add to caching plugin settings or .htaccess

// ✅ SOLUTION 2: Fetch nonce via AJAX for cached pages
// JavaScript:
jQuery(document).ready(function($) {
    $.get('/wp-admin/admin-ajax.php?action=get_nonce', function(response) {
        if (response.success) {
            $('input[name="my_nonce"]').val(response.data.nonce);
        }
    });
});

// PHP:
function prefix_get_nonce_ajax() {
    wp_send_json_success( array(
        'nonce' => wp_create_nonce( 'my_action' ),
    ) );
}
add_action( 'wp_ajax_get_nonce', 'prefix_get_nonce_ajax' );
add_action( 'wp_ajax_nopriv_get_nonce', 'prefix_get_nonce_ajax' );
```

### 5. User Switch, Logout, or Multiple Tabs

Nonces are bound to the user ID **and** session token. If the user logs out, logs in again, or another user logs in (for example in another tab), every nonce rendered earlier fails verification. No extra "same user" check is needed: the nonce already enforces it. Handle the failure gracefully:

```php
// ✅ SOLUTION: Graceful error handling
if ( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['nonce'] ) ), 'prefix_action' ) ) {
    if ( ! is_user_logged_in() ) {
        $redirect = isset( $_SERVER['REQUEST_URI'] ) ? wp_unslash( $_SERVER['REQUEST_URI'] ) : '';
        wp_die( 'Your session has expired. Please <a href="' . esc_url( wp_login_url( $redirect ) ) . '">log in</a> and try again.' );
    } else {
        wp_die( 'Security token invalid. Please go back and try again.' );
    }
}
```

Related: capability checks and REST `permission_callback` → auth-patterns.md. Other vulnerability classes → vulnerability-patterns.md.
