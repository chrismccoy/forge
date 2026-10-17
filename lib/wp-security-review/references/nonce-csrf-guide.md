# WordPress Nonce and CSRF Protection Guide

WordPress nonces (number used once) provide Cross-Site Request Forgery (CSRF) protection. This guide covers nonce lifecycle, form/AJAX/URL/REST patterns, when nonces aren't needed, and common debugging issues.

## Contents

- [Quick Reference Table](#quick-reference-table)
- [Nonce Lifecycle](#nonce-lifecycle)
- [Form Nonces](#form-nonces)
- [AJAX Nonces](#ajax-nonces)
- [URL Nonces](#url-nonces)
- [REST API Nonces](#rest-api-nonces)
- [When Nonces Are NOT Needed](#when-nonces-are-not-needed)
- [Nonce Debugging](#nonce-debugging)
- [Summary](#summary)

## Quick Reference Table

| Function | Purpose | Returns | Use Case |
|----------|---------|---------|----------|
| `wp_create_nonce( $action )` | Create nonce token | String | Generate nonce for action |
| `wp_verify_nonce( $nonce, $action )` | Verify nonce token | false/1/2 | Validate nonce manually |
| `wp_nonce_field( $action, $name )` | Output hidden input | Void | Add nonce to forms |
| `wp_nonce_url( $url, $action )` | Add nonce to URL | String | Create nonce-protected link |
| `check_admin_referer( $action, $name )` | Verify form nonce | 1/2 (dies on failure) | Form submission verification |
| `check_ajax_referer( $action, $query_arg, $die )` | Verify AJAX nonce | 1/2 (dies on failure; false if `$die` is false) | AJAX request verification |
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
// false: Invalid nonce
// 1: Valid, generated in the current tick
// 2: Valid, generated in the previous tick (expires at next tick boundary)
```

### Validity Period (Two Ticks)

Ticks are **fixed 12-hour boundaries** derived from the clock, not offsets from nonce creation:

```php
// wp_nonce_tick() (default lifespan: DAY_IN_SECONDS)
$tick = ceil( time() / ( DAY_IN_SECONDS / 2 ) );
```

A nonce is valid for the **remainder of the tick it was created in plus the whole next tick**: anywhere from just over 12 hours to 24 hours total, depending on when in the tick it was created.

```
             boundary              boundary              boundary
Tick N:   [===== CREATED HERE ====]
Tick N+1:                         [===== STILL VALID =====]
Tick N+2:                                                 [ EXPIRED ]
                     └─────────────────────────────────┘
                    rest of tick N + all of tick N+1 (12-24h)
```

`wp_verify_nonce()` recomputes the hash for the current tick and the previous tick:
- Returns `1`: nonce matches the current tick
- Returns `2`: nonce matches the previous tick (expires at the next boundary)
- Returns `false`: matches neither

**Why two ticks?**
- Prevents a nonce from expiring the moment a tick boundary passes
- User loads form at 11:50, boundary at 12:00, submits at 12:05
- Nonce still valid because it matches the previous tick (returns `2`)

```php
// Example: Tick boundaries fall at 00:00 and 12:00 UTC (time() is UTC)
// Nonce created at 10:00 UTC, inside the 00:00-12:00 tick
$nonce = wp_create_nonce( 'my_action' );

// Validation results over time:
// 10:00 - 12:00 UTC (2h):  Returns 1 (current tick)
// 12:00 - 00:00 UTC (12h): Returns 2 (previous tick)
// After 00:00 UTC:         Returns false (expired, ~14h total lifetime)

// Nonce created at 00:05 UTC would last ~24h; at 11:55 UTC only ~12h
```

### Per-User Nonces

Nonces are tied to the logged-in user ID and session token. Same action, different logged-in users = different nonces.

```php
// User 1 (ID: 5) creates nonce
$user_1_nonce = wp_create_nonce( 'delete_post' );
// Result: "a1b2c3d4e5"

// User 2 (ID: 10) creates nonce for same action
$user_2_nonce = wp_create_nonce( 'delete_post' );
// Result: "f9g8h7i6j5" (different!)

// User 2's nonce won't validate for User 1
wp_verify_nonce( $user_2_nonce, 'delete_post' ); // false (wrong user)

// Logged-out users all have user ID 0 and an empty session token,
// so every visitor gets the SAME nonce for a given action and tick
// (unless a nonce_user_logged_out filter assigns a per-visitor ID)
```

### Logged-Out Users (nopriv)

A nonce on a `wp_ajax_nopriv_` handler or public form gives no real CSRF or abuse protection: anyone can load the page, read a valid nonce, and reuse it from a script or another site. Do not treat a nopriv nonce as authentication, authorization, or rate limiting.

- Keep the nonce if desired (harmless, blocks naive drive-by posts), but do not rate it as a control
- Protect public state-changing endpoints with rate limiting, CAPTCHA, honeypot fields, or input validation that bounds abuse
- Verify webhooks and server-to-server callbacks with a shared-secret signature (HMAC), not a nonce

```php
// ❌ BAD: Treating a nopriv nonce as protection
function prefix_public_signup() {
    check_ajax_referer( 'prefix_signup', 'nonce' ); // Any visitor can fetch this nonce
    prefix_add_subscriber( sanitize_email( wp_unslash( $_POST['email'] ?? '' ) ) );
    wp_send_json_success();
}
add_action( 'wp_ajax_nopriv_prefix_signup', 'prefix_public_signup' );

// ✅ GOOD: Abuse controls carry the weight; nonce is optional
function prefix_public_signup() {
    if ( ! empty( $_POST['website_hp'] ) ) { // Honeypot field, hidden from humans
        wp_send_json_error( null, 400 );
    }

    $ip  = isset( $_SERVER['REMOTE_ADDR'] ) ? sanitize_text_field( wp_unslash( $_SERVER['REMOTE_ADDR'] ) ) : '';
    $key = 'prefix_signup_' . md5( $ip );
    $hits = (int) get_transient( $key );
    if ( $hits >= 5 ) {
        wp_send_json_error( 'Too many requests', 429 );
    }
    set_transient( $key, $hits + 1, HOUR_IN_SECONDS );

    $email = isset( $_POST['email'] ) ? sanitize_email( wp_unslash( $_POST['email'] ) ) : '';
    if ( ! is_email( $email ) ) {
        wp_send_json_error( 'Invalid email', 400 );
    }

    prefix_add_subscriber( $email );
    wp_send_json_success();
}
add_action( 'wp_ajax_nopriv_prefix_signup', 'prefix_public_signup' );
```

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
function prefix_handle_form() {
    if ( ! isset( $_POST['save_post_nonce'] ) ) {
        return; // No nonce field
    }

    if ( ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['save_post_nonce'] ) ), 'save_post_action' ) ) {
        wp_die( 'Invalid nonce', 403 );
    }

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions', 403 );
    }

    // Safe to process
    $title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
    update_option( 'post_title', $title );
}
add_action( 'admin_init', 'prefix_handle_form' );

// ✅ GOOD: Using check_admin_referer() (dies automatically)
function prefix_handle_form() {
    if ( ! isset( $_POST['save_post_nonce'] ) ) {
        return;
    }

    check_admin_referer( 'save_post_action', 'save_post_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions', 403 );
    }

    // Nonce and capability valid, safe to process
    $title = isset( $_POST['title'] ) ? sanitize_text_field( wp_unslash( $_POST['title'] ) ) : '';
    update_option( 'post_title', $title );
}
add_action( 'admin_init', 'prefix_handle_form' );
```

### Nonce Checked but Result Ignored

Calling a verification function without acting on its result provides no protection. Flag as **CRITICAL (CWE-352)**: `wp_verify_nonce()` return value not tested, or `check_ajax_referer( $action, $field, false )` (no auto-die) with the result unchecked.

```php
// ❌ BAD: Return value discarded, request always proceeds
function prefix_handle_form() {
    wp_verify_nonce( $_POST['save_post_nonce'], 'save_post_action' );
    update_option( 'post_title', sanitize_text_field( wp_unslash( $_POST['title'] ) ) );
}

// ❌ BAD: $die = false suppresses auto-die, result never checked
function prefix_ajax_save() {
    check_ajax_referer( 'prefix_save', 'nonce', false );
    update_option( 'prefix_setting', sanitize_text_field( wp_unslash( $_POST['value'] ) ) );
    wp_send_json_success();
}

// ✅ GOOD: Test the return value and stop on failure
function prefix_handle_form() {
    if ( ! isset( $_POST['save_post_nonce'] )
        || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['save_post_nonce'] ) ), 'save_post_action' ) ) {
        wp_die( 'Invalid nonce', 403 );
    }
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions', 403 );
    }
    update_option( 'post_title', sanitize_text_field( wp_unslash( $_POST['title'] ?? '' ) ) );
}

// ✅ GOOD: Check result when $die = false (or omit it to auto-die)
function prefix_ajax_save() {
    if ( ! check_ajax_referer( 'prefix_save', 'nonce', false ) ) {
        wp_send_json_error( 'Invalid nonce', 403 );
    }
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( 'Insufficient permissions', 403 );
    }
    update_option( 'prefix_setting', sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) ) );
    wp_send_json_success();
}
```

**check_admin_referer() vs wp_verify_nonce():**
- `check_admin_referer()`: Dies with error if nonce invalid
- `wp_verify_nonce()`: Returns false/1/2; the caller must test the result and stop on failure

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
    if ( ! isset( $_POST['nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['nonce'] ) ), 'delete_post_action' ) ) {
        wp_die( 'Invalid nonce', 403 );
    }

    // 2. Check object-level capability
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
    if ( ! isset( $_POST['settings_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['settings_nonce'] ) ), 'save_settings_action' ) ) {
        wp_die( 'Invalid security token', 403 );
    }

    // 2. Check capability
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Insufficient permissions to modify settings', 403 );
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

    // Check object-level capability
    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
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
    $nonce = isset( $_POST['nonce'] ) ? sanitize_text_field( wp_unslash( $_POST['nonce'] ) ) : '';

    if ( ! wp_verify_nonce( $nonce, 'prefix_ajax_action' ) ) {
        wp_send_json_error( array(
            'message' => 'Invalid security token. Please refresh the page.',
        ), 403 );
    }

    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
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
    $query_arg,   // Nonce field name (string, default: '_ajax_nonce')
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

// PHP: AJAX handler
function prefix_handle_vote() {
    check_ajax_referer( 'vote_action', 'nonce' );

    if ( ! is_user_logged_in() ) {
        wp_send_json_error( array( 'message' => 'Login required to vote' ), 401 );
    }

    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;
    $vote    = isset( $_POST['vote'] ) ? sanitize_key( wp_unslash( $_POST['vote'] ) ) : '';

    // Object-level check: only published, readable posts accept votes
    if ( 'publish' !== get_post_status( $post_id ) || ! current_user_can( 'read_post', $post_id ) ) {
        wp_send_json_error( array( 'message' => 'Invalid post' ), 403 );
    }

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
// Outputs: .../admin-post.php?action=delete_post&post_id=123&_wpnonce=a1b2c3d4e5

// ✅ GOOD: Custom nonce parameter name
$delete_url = wp_nonce_url(
    admin_url( 'admin-post.php?action=delete_post&post_id=' . $post_id ),
    'delete_post_' . $post_id,
    'delete_nonce' // Custom parameter name
);
// Outputs: .../admin-post.php?action=delete_post&post_id=123&delete_nonce=a1b2c3d4e5
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
    if ( ! isset( $_GET['_wpnonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['_wpnonce'] ) ), 'delete_post_' . $post_id ) ) {
        wp_die( 'Invalid security token', 403 );
    }

    // Check object-level capability
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_die( 'Insufficient permissions to delete this post', 403 );
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

    if ( ! isset( $_GET['delete_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['delete_nonce'] ) ), 'delete_post_' . $post_id ) ) {
        wp_die( 'Invalid security token', 403 );
    }

    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_die( 'Insufficient permissions', 403 );
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
echo $current_status ? 'Disable Feature' : 'Enable Feature';
echo '</a>';
```

## REST API Nonces

REST API uses nonces only for cookie authentication.

### Cookie Authentication (X-WP-Nonce Header)

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

### REST API Permission Callbacks

The X-WP-Nonce header only proves the request came from the logged-in user's browser session; it does not authorize anything. If the header is missing or invalid, WordPress treats the request as unauthenticated (user 0) or rejects it with `rest_cookie_invalid_nonce`. Every route still needs a `permission_callback` with an object-level check (e.g. `current_user_can( 'delete_post', $post_id )`).

See auth-patterns.md → REST API Permission Callbacks for full patterns.

## When Nonces Are NOT Needed

Some WordPress operations don't require nonces because they're not vulnerable to CSRF.

### 1. WP-CLI Commands

```php
// ✅ NO NONCE NEEDED: WP-CLI runs server-side, no HTTP request
// Run with --user=<id|login>: WP-CLI runs as user 0 by default,
// so current_user_can() always returns false without it.
// wp myapp delete-post --post-id=42 --user=admin
function prefix_cli_command( $args, $assoc_args ) {
    // No check_admin_referer() needed
    // WP-CLI commands can't be triggered via CSRF

    $post_id = absint( $assoc_args['post-id'] );

    // Still check capability! (requires --user, see above)
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        WP_CLI::error( 'Permission denied. Pass --user=<id|login> with delete_post capability.' );
    }

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

    $results = get_posts( array(
        's' => $query,
        'post_status' => 'publish',
    ) );

    // Return only public fields (full WP_Post objects leak post_password, etc.)
    $data = array_map( function( $post ) {
        return array(
            'id'        => $post->ID,
            'title'     => get_the_title( $post ),
            'permalink' => get_permalink( $post ),
        );
    }, $results );

    // Return results (no nonce needed for read-only)
    wp_send_json_success( $data );
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
| Logged-out / nopriv (state-changing) | ⚠️ NO VALUE | Shared nonce, anyone can fetch it; use rate limiting, CAPTCHA, honeypot, or signatures |

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
$nonce = isset( $_POST['nonce'] ) ? sanitize_text_field( wp_unslash( $_POST['nonce'] ) ) : '';
if ( ! wp_verify_nonce( $nonce, 'action' ) ) {
    wp_die(
        'Security token expired. Go back, reload the page, and try again.',
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
// Note: the nopriv variant hands a valid nonce to any visitor. That is
// acceptable only because logged-out nonces never were a security control
// (see Logged-Out Users above); the handler must still check capability.
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

### 5. User Switch/Logout

**Cause:** A nonce is bound to the user ID and the current session token. Logging out, logging in as another user, or the session expiring invalidates every nonce issued to the old session. The failure is correct behavior; no extra user-ID check adds security, because the old nonce already fails for any other user.

**Fix:** Refresh the nonce instead of trying to rescue the stale one.

```php
// ❌ BAD: Extra user-ID field adds nothing; reads $_POST without isset/unslash
function prefix_handle_form() {
    $nonce            = $_POST['nonce'];
    $expected_user_id = absint( $_POST['user_id'] );
    if ( ! wp_verify_nonce( $nonce, 'action' ) ) {
        wp_die( 'Invalid nonce' );
    }
    if ( get_current_user_id() !== $expected_user_id ) { // Unreachable for a different user
        wp_die( 'User changed.' );
    }
}

// ✅ GOOD: Refresh long-lived page nonces via Heartbeat
add_filter( 'wp_refresh_nonces', 'prefix_refresh_nonces', 10, 2 );
function prefix_refresh_nonces( $response, $data ) {
    if ( isset( $data['prefix_nonce_check'] ) ) {
        $response['prefix_nonce'] = wp_create_nonce( 'prefix_ajax_action' );
    }
    return $response;
}
// JS: on 'heartbeat-tick.wp-refresh-nonces', replace the stored nonce with data.prefix_nonce.
// Core also fires this after the re-login modal (wp-auth-check), so the page keeps working.

// ✅ GOOD: On failure, tell the client to reload rather than proceed
function prefix_handle_form() {
    $nonce = isset( $_POST['nonce'] ) ? sanitize_text_field( wp_unslash( $_POST['nonce'] ) ) : '';
    if ( ! wp_verify_nonce( $nonce, 'prefix_ajax_action' ) ) {
        wp_send_json_error( array( 'code' => 'nonce_expired', 'message' => 'Session changed. Reload the page.' ), 403 );
    }
    // Capability check + sanitize + process
}
```

### 6. Multiple Tabs

```php
// Problem: User loads form in Tab 1, logs out in Tab 2, submits Tab 1 form
// User is now logged out, nonce invalid

// ✅ SOLUTION: Graceful error handling
$nonce = isset( $_POST['nonce'] ) ? sanitize_text_field( wp_unslash( $_POST['nonce'] ) ) : '';
if ( ! wp_verify_nonce( $nonce, 'action' ) ) {
    if ( ! is_user_logged_in() ) {
        wp_die( 'Session expired. <a href="' . esc_url( wp_login_url( wp_get_referer() ) ) . '">Log in</a> and try again.', '', array( 'response' => 403 ) );
    } else {
        wp_die( 'Security token invalid. Go back, reload the page, and try again.', '', array( 'response' => 403 ) );
    }
}
```

## Summary

Key principles for WordPress nonce usage:

1. **Always use nonces for state-changing operations** — Forms, AJAX, action links
2. **Match action and field names exactly** — Creation and verification must match
3. **Combine with capability checks** — Nonce alone isn't authorization
4. **Use correct nonce type**:
   - Forms: `wp_nonce_field()` + `check_admin_referer()`
   - AJAX: `wp_create_nonce()` + `check_ajax_referer()`
   - URLs: `wp_nonce_url()` + `wp_verify_nonce()`
   - REST: `wp_create_nonce( 'wp_rest' )` + X-WP-Nonce header
5. **Know when nonces aren't needed** — WP-CLI, cron, app passwords, read-only GET
6. **Don't rely on nopriv nonces** — Logged-out users share one nonce per action; protect public endpoints with rate limiting, CAPTCHA, honeypots, or signatures
7. **Debug common issues** — Action mismatch, expiration, caching, session changes (refresh via `wp_refresh_nonces`)

Cross-references:
- Authorization patterns → auth-patterns.md
- CSRF vulnerabilities → vulnerability-patterns.md
- Complete security review → SKILL.md
