# WordPress Authorization Patterns Reference

Authorization ensures users can only perform actions they're permitted to. This guide covers WordPress's capability-based authorization system, REST API permission callbacks, AJAX handler security, and common authorization mistakes.

**Contents:** Quick Reference Table · Capabilities vs Roles (`is_admin()`, `is_user_logged_in()`, meta vs primitive caps) · Common Capability Checks by Operation (content, users/role changes, registration and user-creation escalation, arbitrary meta key writes, plugin/theme/site capability table, `update_option()` escalation, media) · REST API Permission Callbacks (incl. sensitive data exposure on read routes, meta exposed via REST, request-controlled query arguments) · AJAX Handler Authorization · Authentication Bypass (login/reset/magic-link tokens, `wp_set_auth_cookie`) · Custom Capabilities · Common Authorization Mistakes

## Quick Reference Table

| Function | Purpose | Returns | Use Case |
|----------|---------|---------|----------|
| `current_user_can( 'cap' )` | Check static capability | Boolean | General capability check |
| `current_user_can( 'cap', $id )` | Check meta capability | Boolean | Object-specific authorization |
| `user_can( $user, 'cap' )` | Check capability for user | Boolean | Check specific user's capabilities |
| `user_can( $user, 'cap', $id )` | Check meta cap for user | Boolean | Check user's access to specific object |
| `wp_get_current_user()` | Get current user object | WP_User | Access user data |
| `get_current_user_id()` | Get current user ID | Integer | Quick user ID check |
| `is_user_logged_in()` | Check if user is logged in | Boolean | Require authentication |
| `map_meta_cap()` | Map meta cap to primitives | Array | Custom capability mapping |
| `add_cap()` | Add capability to role | Void | Grant new capability |
| `remove_cap()` | Remove capability from role | Void | Revoke capability |

## Capabilities vs Roles

WordPress uses a capability-based system, not role-based. **Always check capabilities, never check roles.**

### Why Capabilities, Not Roles?

Roles are containers of capabilities. Checking roles breaks when:
- Custom roles are added
- Role capabilities are modified
- Multisite super admins need access
- Plugins change the capability model

```php
// ❌ BAD: Checking user role
$user = wp_get_current_user();
if ( in_array( 'administrator', $user->roles, true ) ) {
    // Breaks if custom role has permission
    // Breaks if admin caps are modified
    wp_delete_post( $post_id );
}

// ❌ BAD: Comparing user role
if ( 'editor' === $user->roles[0] ) {
    // Assumes single role
    // Breaks with custom roles
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
}

// ✅ GOOD: Check the object-specific (meta) capability
if ( current_user_can( 'delete_post', $post_id ) ) {
    // Works regardless of role, with custom roles, and with modified caps
    // Checks if user can delete THIS specific post (author, status, others' posts)
    wp_delete_post( $post_id );
}
// Note: current_user_can( 'delete_posts' ) here would be wrong (IDOR):
// it only says the user can delete SOME posts, not this one.
```

### `is_admin()` Is NOT an Authorization Check

`is_admin()` returns true when the **request targets the admin area** (any `/wp-admin/` URL). It says nothing about who the user is or what they may do. It is also **true for every request to `admin-ajax.php`**, including `wp_ajax_nopriv_*` requests from logged-out visitors, and for `admin-post.php`.

```php
// ❌ BAD: is_admin() used as a permission gate
if ( is_admin() ) {
    // True for any logged-in subscriber visiting /wp-admin/profile.php
    // True for anonymous requests to /wp-admin/admin-ajax.php
    wp_delete_user( $user_id );
}

// ❌ BAD: "Admin-only" AJAX handler guarded by is_admin()
function prefix_reset_ajax() {
    if ( ! is_admin() ) { // Always passes inside admin-ajax.php!
        wp_die();
    }
    delete_option( 'prefix_settings' );
}
add_action( 'wp_ajax_nopriv_prefix_reset', 'prefix_reset_ajax' );

// ✅ GOOD: Check capability (plus nonce for state changes)
if ( current_user_can( 'delete_user', $user_id ) ) {
    wp_delete_user( $user_id );
}
```

**Review rule:** Flag any `is_admin()` used to guard a privileged action as **CRITICAL** (CWE-863, incorrect authorization). `is_admin()` is fine for choosing which code to load (admin vs front-end assets), never for permission.

### `is_user_logged_in()` Is NOT Authorization

`is_user_logged_in()` is authentication only. On sites with open registration (or any WooCommerce/membership site), every Subscriber or Customer passes it. It never answers "may this user do this?".

```php
// ❌ BAD: Any logged-in Subscriber can change site settings
function prefix_save_settings_ajax() {
    check_ajax_referer( 'prefix_settings', 'nonce' );
    if ( ! is_user_logged_in() ) {
        wp_send_json_error( 'Login required', 401 );
    }
    update_option( 'prefix_settings', sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) ) );
    wp_send_json_success();
}
add_action( 'wp_ajax_prefix_save_settings', 'prefix_save_settings_ajax' );
// Note: wp_ajax_* hooks already require login, so the is_user_logged_in() check adds nothing.

// ✅ GOOD: Capability check
function prefix_save_settings_ajax() {
    check_ajax_referer( 'prefix_settings', 'nonce' );
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( 'Insufficient permissions', 403 );
    }
    update_option( 'prefix_settings', sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) ) );
    wp_send_json_success();
}
add_action( 'wp_ajax_prefix_save_settings', 'prefix_save_settings_ajax' );
```

**Review rule:** `is_user_logged_in()` as the only guard on a privileged action (settings, other users' data, content changes, file operations) → **CRITICAL** (CWE-862). It is fine for "own account" features that act only on `get_current_user_id()`.

### Role Hierarchy

WordPress doesn't enforce role hierarchy. Don't assume Administrator > Editor > Author.

```php
// ❌ BAD: Assuming role hierarchy
$user_role = $user->roles[0];
$allowed_roles = array( 'administrator', 'editor' );
if ( in_array( $user_role, $allowed_roles, true ) ) {
    // Brittle! Breaks with custom roles
}

// ✅ GOOD: Check capability regardless of hierarchy
if ( current_user_can( 'edit_others_posts' ) ) {
    // Editors and admins have this, custom roles might too
}
```

### Meta Capabilities vs Primitive Capabilities

**Primitive capabilities**: Direct permissions attached to roles
- `edit_posts`, `edit_others_posts`, `delete_posts`, `manage_options`

**Meta capabilities**: Context-dependent, mapped to primitives by `map_meta_cap()`
- `edit_post`, `delete_post`, `edit_user`, `delete_user`

```php
// ❌ BAD: Checking primitive cap for specific post
if ( current_user_can( 'edit_posts' ) ) {
    // User can edit SOME posts, but can they edit THIS post?
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
}

// ✅ GOOD: Check meta capability with object ID
if ( current_user_can( 'edit_post', $post_id ) ) {
    // Checks if user can edit THIS specific post
    // Considers post author, post status, etc.
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
}

// ✅ GOOD: Meta capability for user editing
if ( current_user_can( 'edit_user', $user_id ) ) {
    // Can this user edit THIS user?
    // Prevents privilege escalation
    wp_update_user( array( 'ID' => $user_id, 'display_name' => $name ) );
}
```

**How meta capabilities work:**
1. `current_user_can( 'edit_post', $post_id )` is called
2. WordPress calls `map_meta_cap( 'edit_post', $user_id, $post_id )`
3. `map_meta_cap()` returns primitive caps like `['edit_posts']` or `['edit_others_posts']`
4. WordPress checks if user has those primitive capabilities

## Common Capability Checks by Operation

### Content Management

```php
// Create posts
// 'create_posts' is a post-type cap name, not a role cap: no role has it by default,
// so current_user_can( 'create_posts' ) is always false. Read the mapped cap from the
// post type object (maps to edit_posts for 'post', or a custom cap for CPTs).
if ( current_user_can( get_post_type_object( 'post' )->cap->create_posts ) ) {
    wp_insert_post( $post_data );
}

// Edit posts in general (primitive cap; Contributors and above)
if ( current_user_can( 'edit_posts' ) ) {
    // Can edit OWN posts and access the post editor; says nothing about a specific post
}

// Edit OTHERS' posts
if ( current_user_can( 'edit_others_posts' ) ) {
    // Can edit posts by other users
}

// Edit THIS specific post
if ( current_user_can( 'edit_post', $post_id ) ) {
    // Most secure: checks ownership, status, etc.
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
}

// Publish THIS post: check edit + publish for the specific post (after a nonce check)
check_admin_referer( 'prefix_publish_' . $post_id );
if ( current_user_can( 'edit_post', $post_id ) && current_user_can( 'publish_post', $post_id ) ) {
    wp_update_post( array( 'ID' => $post_id, 'post_status' => 'publish' ) );
}
// ❌ current_user_can( 'publish_posts' ) alone lets an Author publish ANOTHER user's draft (IDOR)

// Delete posts
if ( current_user_can( 'delete_post', $post_id ) ) {
    wp_delete_post( $post_id, true );
}

// Read private posts
if ( current_user_can( 'read_private_posts' ) ) {
    // Can access private posts in queries
}
```

### User Management

```php
// List users
if ( current_user_can( 'list_users' ) ) {
    $users = get_users();
}

// Edit users (any)
if ( current_user_can( 'edit_users' ) ) {
    // Can edit some users
}

// Edit THIS specific user
if ( current_user_can( 'edit_user', $user_id ) ) {
    // Prevents privilege escalation
    // Contributors can't edit admins
    wp_update_user( array( 'ID' => $user_id, 'display_name' => $name ) );
}

// Delete users
if ( current_user_can( 'delete_user', $user_id ) ) {
    wp_delete_user( $user_id );
}

// Create users
if ( current_user_can( 'create_users' ) ) {
    wp_insert_user( $user_data );
}

// Promote THIS user (change role) — meta cap with target user ID
// map_meta_cap() maps promote_user to promote_users (plus multisite checks).
// It does NOT stop a user changing their own role, and it does NOT limit
// which role can be assigned. Add both checks explicitly:
// get_editable_roles() lives in wp-admin/includes/user.php: not loaded for REST, init, or front-end.
if ( ! function_exists( 'get_editable_roles' ) ) {
    require_once ABSPATH . 'wp-admin/includes/user.php';
}
$user_id  = isset( $_POST['user_id'] ) ? absint( $_POST['user_id'] ) : 0; // int, so !== below compares ints
$new_role = isset( $_POST['role'] ) ? sanitize_key( wp_unslash( $_POST['role'] ) ) : '';
if (
    $user_id
    && current_user_can( 'promote_user', $user_id )
    && get_current_user_id() !== $user_id                // No self-promotion
    && array_key_exists( $new_role, get_editable_roles() ) // Only roles this user may assign
) {
    $user = new WP_User( $user_id );
    $user->set_role( $new_role );
}
```

Core's `get_editable_roles()` applies the `editable_roles` filter, which is where sites restrict assignable roles. Never pass a role from the request straight to `set_role()` or `wp_insert_user( array( 'role' => ... ) )`. See sanitization-guide.md → "Complete Input Handling Example" for the full handler.

### Registration and User-Creation Privilege Escalation (CWE-269)

Custom registration, checkout, or profile forms that pass request data into `wp_insert_user()`, `wp_create_user()` + `set_role()`, or `wp_update_user()` let an attacker pick their own role. The same applies to request-chosen meta keys written with `update_user_meta()` (`wp_capabilities`, `wp_user_level`). Rate **CRITICAL**: one request creates an administrator.

```php
// ❌ CRITICAL: Role from the request on self-registration
function prefix_register() {
    check_ajax_referer( 'prefix_register', 'nonce' );
    $user_id = wp_insert_user( array(
        'user_login' => sanitize_user( wp_unslash( $_POST['login'] ?? '' ) ),
        'user_email' => sanitize_email( wp_unslash( $_POST['email'] ?? '' ) ),
        'user_pass'  => wp_generate_password(),
        'role'       => sanitize_key( wp_unslash( $_POST['role'] ?? '' ) ), // role=administrator
    ) );
}
add_action( 'wp_ajax_nopriv_prefix_register', 'prefix_register' );

// ❌ CRITICAL: Whole request array passed through (role, user_level, ID all attacker-chosen)
wp_update_user( array_merge( array( 'ID' => get_current_user_id() ), wp_unslash( $_POST ) ) );

// ✅ GOOD: Self-registration always gets the site default role
$user_id = wp_insert_user( array(
    'user_login' => $login,
    'user_email' => $email,
    'user_pass'  => wp_generate_password(),
    'role'       => get_option( 'default_role' ), // never from the request
) );

// ✅ GOOD: Admin-created users: capability + allow-listed role
if ( current_user_can( 'create_users' ) && current_user_can( 'promote_users' ) ) {
    if ( ! function_exists( 'get_editable_roles' ) ) {
        require_once ABSPATH . 'wp-admin/includes/user.php';
    }
    $role = sanitize_key( wp_unslash( $_POST['role'] ?? '' ) );
    if ( ! array_key_exists( $role, get_editable_roles() ) ) {
        wp_die( esc_html__( 'Invalid role.', 'textdomain' ) );
    }
    wp_insert_user( array( 'user_login' => $login, 'user_email' => $email, 'role' => $role ) );
}

// ✅ GOOD: Profile updates copy only allow-listed fields
$update = array( 'ID' => get_current_user_id() );
if ( isset( $_POST['display_name'] ) ) {
    $update['display_name'] = sanitize_text_field( wp_unslash( $_POST['display_name'] ) );
}
wp_update_user( $update );
```

### Arbitrary Meta Key Writes (CWE-269, CWE-915)

`update_user_meta()`, `update_post_meta()`, `update_term_meta()`, and `add_*_meta()` with a meta **key** chosen by the request, or a loop that writes every `$_POST` key as meta, are mass assignment.

- **User meta → CRITICAL (CWE-269).** Keys `{$wpdb->prefix}capabilities` and `{$wpdb->prefix}user_level` hold the user's roles. Writing `wp_capabilities = array( 'administrator' => true )` makes the requester an admin.
- **Post/term meta → WARNING, CRITICAL when it reaches a sensitive key (CWE-915).** Attackers overwrite `_wp_page_template` (template swap), `_thumbnail_id`, `_wp_attached_file` (file path used in later file operations), or other plugins' private `_` keys that drive logic.
- `is_protected_meta()` only hides `_` keys from the custom-fields UI. It is not an authorization check.

```php
// ❌ CRITICAL: Request chooses the user meta key
function prefix_save_profile_field() {
    check_ajax_referer( 'prefix_profile', 'nonce' );
    $key   = sanitize_key( wp_unslash( $_POST['key'] ?? '' ) );   // key=wp_capabilities
    $value = wp_unslash( $_POST['value'] ?? '' );                 // value[administrator]=1
    update_user_meta( get_current_user_id(), $key, $value );
}
add_action( 'wp_ajax_prefix_save_profile_field', 'prefix_save_profile_field' );

// ❌ CRITICAL: Mass assignment of every posted field
foreach ( wp_unslash( $_POST ) as $key => $value ) {
    update_post_meta( $post_id, sanitize_key( $key ), $value );
}

// ✅ GOOD: Allow-listed keys, nonce, per-object capability
function prefix_save_post_fields( $post_id ) {
    check_admin_referer( 'prefix_save_fields', 'prefix_fields_nonce' );
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        wp_die( esc_html__( 'Not allowed.', 'textdomain' ) );
    }
    $allowed = array( 'prefix_subtitle', 'prefix_color' );
    $key     = sanitize_key( wp_unslash( $_POST['field'] ?? '' ) );
    if ( ! in_array( $key, $allowed, true ) ) {
        wp_die( esc_html__( 'Invalid field.', 'textdomain' ) );
    }
    $value = sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) );
    update_post_meta( $post_id, $key, $value );
}
```

Sanitizing or prefixing the key (`'prefix_' . sanitize_key( ... )`) is not an allow-list: it still lets the request write any key in the plugin's own namespace.

### Plugin, Theme, and Site Management

Use the primitive capability that matches the operation. These are site-wide actions, so no object ID is needed.

| Operation | Capability |
|-----------|-----------|
| Install / activate / delete plugins | `install_plugins` / `activate_plugins` / `delete_plugins` |
| Install / switch themes | `install_themes` / `switch_themes` |
| Plugin or theme file editor | `edit_plugins` / `edit_themes` (also blocked by `DISALLOW_FILE_EDIT`) |
| Site settings (`update_option`) | `manage_options` |
| Categories and tags | `manage_categories` |
| Import / export | `import` / `export` |
| Core updates | `update_core` |

### Privilege Escalation via `update_option()` (CWE-269)

A handler that lets the request choose the option **name** (or writes a security-relevant option from request data) lets an attacker rewrite any site setting. Classic exploit: set `users_can_register` to `1` and `default_role` to `administrator`, then register an admin account. Rate CRITICAL even behind a nonce or a low capability.

```php
// ❌ CRITICAL: User-controlled option name and value
function prefix_save_option_ajax() {
    check_ajax_referer( 'prefix_save', 'nonce' );
    if ( ! current_user_can( 'edit_posts' ) ) { // Contributors pass
        wp_send_json_error( 'Denied', 403 );
    }
    $name  = sanitize_text_field( wp_unslash( $_POST['option'] ?? '' ) );
    $value = sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) );
    update_option( $name, $value ); // default_role = administrator ...
    wp_send_json_success();
}

// ✅ GOOD: Fixed allow-list of the plugin's own options + correct capability
function prefix_save_option_ajax() {
    check_ajax_referer( 'prefix_save', 'nonce' );
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( 'Denied', 403 );
    }
    $allowed = array( 'prefix_color', 'prefix_layout' );
    $name    = sanitize_key( wp_unslash( $_POST['option'] ?? '' ) );
    if ( ! in_array( $name, $allowed, true ) ) {
        wp_send_json_error( 'Invalid option', 400 );
    }
    update_option( $name, sanitize_text_field( wp_unslash( $_POST['value'] ?? '' ) ) );
    wp_send_json_success();
}
```

Same rule for `update_user_meta()` with a request-chosen meta key: `wp_capabilities` / `{$wpdb->prefix}capabilities` and `wp_user_level` grant roles directly. Allow-list meta keys.

### Media/Upload Management

```php
// Upload files
if ( current_user_can( 'upload_files' ) ) {
    $attachment_id = media_handle_upload( 'file', $post_id );
}

// Delete THIS attachment
if ( current_user_can( 'delete_post', $attachment_id ) ) {
    // Attachments are posts, use same caps
    wp_delete_attachment( $attachment_id, true );
}
```

## REST API Permission Callbacks

`permission_callback` is **not enforced**. Since WP 5.5, a route registered without it triggers a `_doing_it_wrong` notice (visible only with `WP_DEBUG`), and the route **still registers and is publicly accessible**. Nothing blocks the request. That is why a missing `permission_callback` on a write route (POST/PUT/PATCH/DELETE) is CRITICAL. On a GET route it is CRITICAL whenever the route returns non-public data (see Sensitive Data Exposure on Read Routes).

### Missing permission_callback (CWE-862)

```php
// ❌ BAD: Missing permission_callback
register_rest_route( 'myapp/v1', '/data', array(
    'methods'  => 'POST',
    'callback' => 'prefix_create_data',
    // No permission_callback: _doing_it_wrong notice, route is PUBLIC.
    // Anyone, including logged-out visitors, can POST.
) );

// ❌ BAD: null is treated as missing (same notice, still public)
register_rest_route( 'myapp/v1', '/data', array(
    'methods'             => 'POST',
    'callback'            => 'prefix_create_data',
    'permission_callback' => null,
) );

// ❌ BAD: __return_true on a write route (public write access)
register_rest_route( 'myapp/v1', '/data', array(
    'methods'             => 'POST',
    'callback'            => 'prefix_create_data',
    'permission_callback' => '__return_true',
) );

// ✅ GOOD: Explicit permission check
register_rest_route( 'myapp/v1', '/data', array(
    'methods'             => 'POST',
    'callback'            => 'prefix_create_data',
    'permission_callback' => function() {
        return current_user_can( 'edit_posts' );
    },
) );

// ✅ GOOD: Public read-only endpoint, returning only data that is already public
register_rest_route( 'myapp/v1', '/public-data', array(
    'methods'             => 'GET',
    'callback'            => 'prefix_get_public_data', // e.g. published post titles, public settings
    'permission_callback' => '__return_true', // Explicitly public
) );
```

### Sensitive Data Exposure on Read Routes (CWE-200)

`__return_true` on a GET route (or a `wp_ajax_nopriv_*` handler) is only safe when **everything the callback can return is already public**. Read-only does not mean harmless. Rate **CRITICAL** when an unauthenticated or low-privilege request can read:
- other users' emails, phone numbers, addresses, IPs, or arbitrary user meta
- order, payment, form-submission, or membership data
- private, draft, or password-protected post content (`post_content`, `post_password`)
- API keys, tokens, or plugin settings from `get_option()`
- raw `WP_User` / `WP_Post` objects, `get_users()` / `get_posts()` results passed through unfiltered

```php
// ❌ CRITICAL: Public route returns every user's email
register_rest_route( 'myapp/v1', '/members', array(
    'methods'             => 'GET',
    'callback'            => function() {
        return get_users( array( 'fields' => array( 'ID', 'user_email', 'display_name' ) ) );
    },
    'permission_callback' => '__return_true',
) );

// ❌ CRITICAL: Public route returns any option by name
register_rest_route( 'myapp/v1', '/option/(?P<name>[a-z_]+)', array(
    'methods'             => 'GET',
    'callback'            => function( $request ) { return get_option( $request['name'] ); },
    'permission_callback' => '__return_true',
) );

// ✅ GOOD: Public route maps to public fields only
register_rest_route( 'myapp/v1', '/members', array(
    'methods'             => 'GET',
    'callback'            => function() {
        return array_map(
            function( $u ) { return array( 'id' => $u->ID, 'name' => $u->display_name ); },
            get_users( array( 'has_published_posts' => true ) ) // authors already public via archives
        );
    },
    'permission_callback' => '__return_true',
) );
// ✅ GOOD: Private data behind a capability or own-account check (see User-Specific Data Access)
```

Review each `__return_true` GET route and each nopriv handler by reading what the callback returns, not the HTTP method.

### Meta Exposed via REST (CWE-200, CWE-862)

`register_meta()`, `register_post_meta()`, and `register_term_meta()` with `'show_in_rest' => true` add the value to every REST response for that object. For published posts that includes anonymous requests to `/wp/v2/posts`. Rate **WARNING**, or **CRITICAL** when the value is private (emails, addresses, internal notes, tokens) (CWE-200).

Write access is controlled by `auth_callback`. Without one, core's default depends on the key:
- Protected keys (leading `_`, see `is_protected_meta()`): default is `__return_false`, so nobody can write them via REST.
- Unprotected keys: default allows any user who can edit the object (`edit_post` for post meta). A Contributor editing their own draft can set the value. If the plugin trusts that value elsewhere (pricing, flags, templates, roles), rate **CRITICAL** (CWE-862).

```php
// ❌ BAD: Private value exposed to anonymous readers, writable by any editor of the post
register_post_meta( 'product', 'supplier_email', array(
    'type'         => 'string',
    'single'       => true,
    'show_in_rest' => true,
) );

// ✅ GOOD: Public field with explicit write rule; private data kept out of REST
register_post_meta( 'product', 'display_color', array(
    'type'              => 'string',
    'single'            => true,
    'show_in_rest'      => true,
    'sanitize_callback' => 'sanitize_hex_color',
    'auth_callback'     => function( $allowed, $meta_key, $post_id ) {
        return current_user_can( 'edit_post', $post_id );
    },
) );

register_post_meta( 'product', '_supplier_email', array( // underscore = protected
    'type'         => 'string',
    'single'       => true,
    'show_in_rest' => false,
) );
```

Keep private meta underscore-prefixed and out of `show_in_rest`. Give every REST-exposed key an `auth_callback` with the capability the business rule needs, which is often stricter than `edit_post`.

### Request-Controlled Query Arguments (CWE-200)

Passing request data into `WP_Query`, `get_posts()`, `get_users()`, or `new WP_User_Query()` lets the caller choose `post_status` (`draft`, `private`, `any`), `author`, `post_type`, `meta_query`, `has_password`, `fields`, or `perm`. Results then include drafts, private posts, password-protected content, or user data. Rate **CRITICAL** when reachable unauthenticated (nopriv AJAX, `__return_true` route); **WARNING** for low-role users.

```php
// ❌ CRITICAL: Caller controls every query argument
add_action( 'wp_ajax_nopriv_prefix_search', function() {
    $args  = isset( $_POST['args'] ) ? (array) wp_unslash( $_POST['args'] ) : array();
    $posts = get_posts( $args ); // args[post_status]=private, args[post_type]=any ...
    wp_send_json_success( $posts );
} );

// ✅ GOOD: Arguments built server-side; only allow-listed values come from the request
add_action( 'wp_ajax_nopriv_prefix_search', function() {
    $allowed_types = array( 'post', 'page' );
    $type = isset( $_POST['type'] ) ? sanitize_key( wp_unslash( $_POST['type'] ) ) : 'post';
    if ( ! in_array( $type, $allowed_types, true ) ) {
        wp_send_json_error( 'Invalid type', 400 );
    }

    $query = new WP_Query( array(
        'post_type'      => $type,
        'post_status'    => 'publish',   // forced
        'has_password'   => false,       // forced
        'perm'           => 'readable',
        's'              => isset( $_POST['s'] ) ? sanitize_text_field( wp_unslash( $_POST['s'] ) ) : '',
        'posts_per_page' => 10,
        'no_found_rows'  => true,
    ) );

    wp_send_json_success( array_map( function( $p ) {
        return array( 'id' => $p->ID, 'title' => get_the_title( $p ), 'url' => get_permalink( $p ) );
    }, $query->posts ) );
} );
```

Never pass `$_GET`/`$_POST`/`$request->get_params()` as a whole args array. Map each accepted parameter to a fixed key, validate its value against an allow-list, and force `post_status`/`has_password` on public endpoints.

### Context-Aware Authorization

```php
// ❌ BAD: Same permission for all methods
register_rest_route( 'myapp/v1', '/posts/(?P<id>\d+)', array(
    array(
        'methods'             => WP_REST_Server::READABLE, // GET
        'callback'            => 'prefix_get_post',
        'permission_callback' => function() {
            return current_user_can( 'edit_posts' ); // Too restrictive for GET!
        },
    ),
    array(
        'methods'             => WP_REST_Server::EDITABLE, // POST, PUT, PATCH
        'callback'            => 'prefix_update_post',
        'permission_callback' => function() {
            return current_user_can( 'edit_posts' ); // Too permissive! Should check specific post
        },
    ),
) );

// ✅ GOOD: Context-aware permissions
register_rest_route( 'myapp/v1', '/posts/(?P<id>\d+)', array(
    array(
        'methods'             => WP_REST_Server::READABLE,
        'callback'            => 'prefix_get_post',
        'permission_callback' => function( $request ) {
            $post_id = absint( $request['id'] );
            $post    = get_post( $post_id );
            if ( ! $post ) {
                return false;
            }
            // Public: published, not password-protected, public post type.
            // (read_post alone maps to 'read' for published posts, so logged-out
            // visitors would be denied content that is already public.)
            $type = get_post_type_object( $post->post_type );
            if ( 'publish' === get_post_status( $post ) && ! post_password_required( $post )
                && $type && $type->public ) {
                return true;
            }
            // Private, draft, password-protected, or non-public type: per-post capability.
            return current_user_can( 'read_post', $post_id );
        },
    ),
    array(
        'methods'             => WP_REST_Server::EDITABLE,
        'callback'            => 'prefix_update_post',
        'permission_callback' => function( $request ) {
            $post_id = absint( $request['id'] );
            // Check if user can edit THIS specific post
            return current_user_can( 'edit_post', $post_id );
        },
    ),
    array(
        'methods'             => WP_REST_Server::DELETABLE,
        'callback'            => 'prefix_delete_post',
        'permission_callback' => function( $request ) {
            $post_id = absint( $request['id'] );
            // Check if user can delete THIS specific post
            return current_user_can( 'delete_post', $post_id );
        },
    ),
) );
```

### Multiple Method Endpoints

```php
// ✅ GOOD: Different permissions per method
register_rest_route( 'myapp/v1', '/settings', array(
    array(
        'methods'             => WP_REST_Server::READABLE,
        'callback'            => 'prefix_get_settings',
        'permission_callback' => function() {
            // Anyone with edit_posts (Contributors and above) can view settings
            return current_user_can( 'edit_posts' );
        },
    ),
    array(
        'methods'             => WP_REST_Server::CREATABLE,
        'callback'            => 'prefix_update_settings',
        'permission_callback' => function() {
            // Only admins can modify settings
            return current_user_can( 'manage_options' );
        },
    ),
) );
```

### User-Specific Data Access

```php
// ❌ BAD: Returning any user's private data
function prefix_get_user_data( $request ) {
    $user_id = absint( $request['id'] );
    $user = get_userdata( $user_id );

    return array(
        'email'    => $user->user_email, // Private data!
        'password' => $user->user_pass,  // Never return this!
    );
}

register_rest_route( 'myapp/v1', '/users/(?P<id>\d+)', array(
    'methods'             => WP_REST_Server::READABLE,
    'callback'            => 'prefix_get_user_data',
    'permission_callback' => '__return_true', // Anyone can access!
) );

// ✅ GOOD: Check if user can edit target user
function prefix_get_user_data( $request ) {
    $user_id = absint( $request['id'] );

    // Return only public data
    $user = get_userdata( $user_id );

    return array(
        'id'           => $user->ID,
        'display_name' => $user->display_name,
        'avatar'       => get_avatar_url( $user_id ),
    );
}

register_rest_route( 'myapp/v1', '/users/(?P<id>\d+)', array(
    'methods'             => WP_REST_Server::READABLE,
    'callback'            => 'prefix_get_user_data',
    'permission_callback' => function( $request ) {
        $user_id = absint( $request['id'] );

        // Logged-out: get_current_user_id() is 0, so /users/0 would match without this check
        if ( ! is_user_logged_in() ) {
            return false;
        }

        // Allow user to access own data, or admins to access any
        return get_current_user_id() === $user_id || current_user_can( 'edit_user', $user_id );
    },
) );

// ✅ GOOD: Separate private endpoint
function prefix_get_private_user_data( $request ) {
    $user_id = absint( $request['id'] );
    $user = get_userdata( $user_id );

    return array(
        'email' => $user->user_email,
        'phone' => get_user_meta( $user_id, 'phone', true ),
    );
}

register_rest_route( 'myapp/v1', '/users/(?P<id>\d+)/private', array(
    'methods'             => WP_REST_Server::READABLE,
    'callback'            => 'prefix_get_private_user_data',
    'permission_callback' => function( $request ) {
        $user_id = absint( $request['id'] );

        // Logged-out users have ID 0; never let 0 === 0 grant access
        if ( ! is_user_logged_in() ) {
            return false;
        }

        // Only allow user to access own private data
        if ( get_current_user_id() === $user_id ) {
            return true;
        }

        // Or admins with edit_user capability
        return current_user_can( 'edit_user', $user_id );
    },
) );
```

### Returning WP_Error for Better Error Messages

```php
// ✅ GOOD: Return WP_Error with specific message
register_rest_route( 'myapp/v1', '/premium-content', array(
    'methods'             => 'GET',
    'callback'            => 'prefix_get_premium_content',
    'permission_callback' => function() {
        if ( ! is_user_logged_in() ) {
            return new WP_Error(
                'rest_not_logged_in',
                'You must be logged in to access premium content.',
                array( 'status' => 401 )
            );
        }

        $user_id = get_current_user_id();
        $has_subscription = get_user_meta( $user_id, 'active_subscription', true );

        if ( ! $has_subscription ) {
            return new WP_Error(
                'rest_no_subscription',
                'Active subscription required.',
                array( 'status' => 403 )
            );
        }

        return true;
    },
) );
```

## AJAX Handler Authorization

AJAX requests need the same authorization checks as form submissions.

### wp_ajax_ vs wp_ajax_nopriv_

```php
// ✅ GOOD: Logged-in users only
function prefix_delete_post_ajax() {
    // Check nonce
    check_ajax_referer( 'delete_post_nonce', 'nonce' );

    // Check capability
    $post_id = absint( $_POST['post_id'] );
    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_send_json_error( array( 'message' => 'Permission denied' ) );
    }

    // Perform action
    wp_delete_post( $post_id, true );
    wp_send_json_success();
}
add_action( 'wp_ajax_delete_post', 'prefix_delete_post_ajax' );
// No wp_ajax_nopriv_ hook = logged-out users can't access

// ✅ GOOD: Public AJAX (logged in OR logged out)
function prefix_get_public_data_ajax() {
    // Read-only and returns only public data (see Sensitive Data Exposure on Read Routes).
    // Nopriv nonces are shared by all anonymous users (see nonce-csrf-guide.md)
    $data = get_option( 'prefix_public_data' );
    wp_send_json_success( $data );
}
add_action( 'wp_ajax_get_public_data', 'prefix_get_public_data_ajax' );
add_action( 'wp_ajax_nopriv_get_public_data', 'prefix_get_public_data_ajax' );
```

### Admin AJAX Capability Patterns

```php
// ❌ BAD: No capability check in AJAX handler
function prefix_update_settings_ajax() {
    check_ajax_referer( 'update_settings_nonce', 'nonce' );

    // Anyone logged in can update settings!
    update_option( 'prefix_setting', $_POST['value'] );
    wp_send_json_success();
}
add_action( 'wp_ajax_update_settings', 'prefix_update_settings_ajax' );

// ✅ GOOD: Capability check before action
function prefix_update_settings_ajax() {
    check_ajax_referer( 'update_settings_nonce', 'nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Insufficient permissions' ) );
    }

    $value = sanitize_text_field( wp_unslash( $_POST['value'] ) );
    update_option( 'prefix_setting', $value );
    wp_send_json_success();
}
add_action( 'wp_ajax_update_settings', 'prefix_update_settings_ajax' );
```

### Object-Specific Capabilities in AJAX

```php
// ❌ BAD: Generic capability check
function prefix_edit_post_ajax() {
    check_ajax_referer( 'edit_post_nonce', 'nonce' );

    if ( ! current_user_can( 'edit_posts' ) ) { // Can edit ANY post?
        wp_send_json_error( 'No permission' );
    }

    $post_id = absint( $_POST['post_id'] );
    // User can edit ANY post, not necessarily THIS one
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $_POST['title'] ) );
}

// ✅ GOOD: Object-specific capability check
function prefix_edit_post_ajax() {
    check_ajax_referer( 'edit_post_nonce', 'nonce' );

    $post_id = absint( $_POST['post_id'] );

    if ( ! current_user_can( 'edit_post', $post_id ) ) { // Can edit THIS post?
        wp_send_json_error( array( 'message' => 'Permission denied' ) );
    }

    $title = sanitize_text_field( wp_unslash( $_POST['title'] ) );
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
    wp_send_json_success();
}
add_action( 'wp_ajax_edit_post', 'prefix_edit_post_ajax' );
```

## Authentication Bypass (CWE-287, CWE-288, CWE-330)

Custom login, password reset, "magic link", OTP, and social-login code often decides who the user is. Any flaw logs the attacker in as someone else. Rate **CRITICAL**.

Flag:
- `wp_set_auth_cookie()` or `wp_set_current_user()` called with a user ID, email, or login taken from the request, without first proving the requester owns that account (CWE-288).
- Token comparison with `==` / `===` / `strcmp()` instead of `hash_equals()` (timing leak); loose `==` also allows type juggling (`"0e123" == "0e456"`).
- Tokens generated with `rand()`, `mt_rand()`, `uniqid()`, `md5( time() )`, or the user ID (predictable, CWE-330). Use `wp_generate_password( 32, false )` or `bin2hex( random_bytes( 32 ) )`.
- Tokens stored in plain text, with no expiry, or not deleted after use (replayable).
- Social/OAuth login that trusts an email from the provider response without verifying the provider's signature/ID token, or that links to an existing account by email alone.

```php
// ❌ CRITICAL: Logs in whoever the request names
function prefix_magic_login() {
    $user_id = absint( $_GET['uid'] ?? 0 );
    $token   = sanitize_text_field( wp_unslash( $_GET['token'] ?? '' ) );
    if ( $token == get_user_meta( $user_id, 'prefix_login_token', true ) ) { // loose compare, '' == '' when no token set
        wp_set_current_user( $user_id );
        wp_set_auth_cookie( $user_id );
    }
}
add_action( 'init', 'prefix_magic_login' );

// ❌ CRITICAL: Predictable token
update_user_meta( $user_id, 'prefix_login_token', md5( $user_id . time() ) );

// ✅ GOOD: Random token, hashed at rest, expiring, single-use, constant-time compare
// Keyed HMAC works on every WP version. On WP 6.8+, wp_fast_hash( $token ) /
// wp_verify_fast_hash( $token, $hash ) are the core equivalents.
// Do NOT use wp_check_password( $token, $hash, $user_id ) for tokens: with a user ID
// and a legacy hash it can call wp_set_password(), overwriting the account password.
function prefix_token_hash( $token ) {
    return hash_hmac( 'sha256', $token, wp_salt( 'auth' ) );
}

function prefix_issue_login_token( $user_id ) {
    $token = wp_generate_password( 32, false );
    update_user_meta( $user_id, 'prefix_login_token', array(
        'hash'    => prefix_token_hash( $token ),
        'expires' => time() + 15 * MINUTE_IN_SECONDS,
    ) );
    return $token; // send by email only
}

function prefix_magic_login() {
    if ( ! isset( $_GET['uid'], $_GET['token'] ) ) {
        return;
    }
    $user_id = absint( $_GET['uid'] );
    $token   = sanitize_text_field( wp_unslash( $_GET['token'] ) );
    $stored  = get_user_meta( $user_id, 'prefix_login_token', true );

    delete_user_meta( $user_id, 'prefix_login_token' ); // single-use, even on failure

    if (
        ! is_array( $stored ) || '' === $token
        || time() > (int) $stored['expires']
        || ! is_string( $stored['hash'] ?? null )
        || ! hash_equals( $stored['hash'], prefix_token_hash( $token ) )
    ) {
        wp_die( esc_html__( 'Invalid or expired link.', 'textdomain' ) );
    }
    wp_set_current_user( $user_id );
    wp_set_auth_cookie( $user_id );
    wp_safe_redirect( admin_url() );
    exit;
}
add_action( 'init', 'prefix_magic_login' );
```

For plain (unhashed) tokens, compare with `hash_equals( $stored, $token )` after checking both are non-empty strings. Prefer core flows (`get_password_reset_key()` / `check_password_reset_key()`) over custom reset code.

## Custom Capabilities

For custom post types and scenarios, register custom capabilities.

### Custom Post Type Capabilities

```php
// ✅ GOOD: Custom post type with custom capabilities
function prefix_register_custom_post_type() {
    register_post_type( 'product', array(
        'public'       => true,
        'label'        => 'Products',
        'capability_type' => 'product',
        'capabilities' => array(
            'edit_post'          => 'edit_product',
            'read_post'          => 'read_product',
            'delete_post'        => 'delete_product',
            'edit_posts'         => 'edit_products',
            'edit_others_posts'  => 'edit_others_products',
            'delete_posts'       => 'delete_products',
            'publish_posts'      => 'publish_products',
            'read_private_posts' => 'read_private_products',
        ),
        'map_meta_cap' => true,
    ) );
}
add_action( 'init', 'prefix_register_custom_post_type' );

// Grant capabilities to role
function prefix_add_product_caps() {
    $role = get_role( 'shop_manager' );
    if ( $role ) {
        $role->add_cap( 'edit_products' );
        $role->add_cap( 'edit_others_products' );
        $role->add_cap( 'publish_products' );
        $role->add_cap( 'read_private_products' );
        $role->add_cap( 'delete_products' );
    }
}
register_activation_hook( __FILE__, 'prefix_add_product_caps' );

// Check custom capability
if ( current_user_can( 'edit_product', $product_id ) ) {
    wp_update_post( array( 'ID' => $product_id, 'post_title' => $title ) );
}
```

### Map Meta Cap Filter

```php
// ✅ GOOD: Custom meta capability mapping
function prefix_map_meta_cap( $caps, $cap, $user_id, $args ) {
    // Custom capability: manage_team_settings
    if ( 'manage_team_settings' === $cap ) {
        $team_id = isset( $args[0] ) ? $args[0] : 0;

        // Get team
        $team = get_post( $team_id );
        if ( ! $team || 'team' !== $team->post_type ) {
            // Require impossible capability if team doesn't exist
            return array( 'do_not_allow' );
        }

        // Team owner can manage
        if ( absint( $team->post_author ) === absint( $user_id ) ) {
            return array( 'edit_posts' );
        }

        // Team admins can manage
        $team_admins = get_post_meta( $team_id, '_team_admins', true );
        if ( is_array( $team_admins ) && in_array( $user_id, $team_admins, true ) ) {
            return array( 'edit_posts' );
        }

        // Otherwise require manage_options
        return array( 'manage_options' );
    }

    return $caps;
}
add_filter( 'map_meta_cap', 'prefix_map_meta_cap', 10, 4 );

// Check custom meta capability
if ( current_user_can( 'manage_team_settings', $team_id ) ) {
    update_post_meta( $team_id, '_team_settings', $settings );
}
```

## Common Authorization Mistakes

Checklist of mistakes covered in earlier sections:

| # | Mistake | Severity | See |
|---|---------|----------|-----|
| 1 | Primitive cap (`edit_posts`) instead of meta cap (`edit_post`, `$id`) | WARNING (CWE-639, IDOR); CRITICAL when a low role (Contributor/Subscriber) can modify others' data or escalate | Meta Capabilities vs Primitive Capabilities |
| 2 | `is_admin()` used as permission check | CRITICAL (CWE-863) | `is_admin()` Is NOT an Authorization Check |
| 3 | `is_user_logged_in()` as the only guard on a privileged action | CRITICAL (CWE-862) | `is_user_logged_in()` Is NOT Authorization |
| 4 | Missing `permission_callback`, or `__return_true` on write route (GET `__return_true` is OK only for already-public data) | CRITICAL (CWE-862) | REST API Permission Callbacks |
| 5 | Nonce-only AJAX handler, no capability check | CRITICAL (CWE-862) | Admin AJAX Capability Patterns |
| 6 | Role changes guarded by `edit_users` instead of `promote_user` + self-check + `get_editable_roles()` | CRITICAL (CWE-269) | User Management |
| 7 | `update_option()` with a request-chosen name | CRITICAL (CWE-269) | Privilege Escalation via `update_option()` |
| 7a | `update_user_meta()` / `update_post_meta()` with a request-chosen key, or all `$_POST` keys | CRITICAL for user meta (CWE-269); WARNING/CRITICAL for post meta (CWE-915) | Arbitrary Meta Key Writes |
| 8 | `wp_insert_user()` / `wp_update_user()` with a role or fields from the request | CRITICAL (CWE-269) | Registration and User-Creation Privilege Escalation |
| 9 | `__return_true` GET route or nopriv handler returning non-public data (emails, PII, private posts, options) | CRITICAL (CWE-200) | Sensitive Data Exposure on Read Routes |
| 10 | `wp_set_auth_cookie()` with a request-chosen user, `==` token compare, predictable or non-expiring tokens | CRITICAL (CWE-287/288/330) | Authentication Bypass |
| 11 | `register_*_meta()` with `show_in_rest` on private data, or without `auth_callback` on a trusted key | WARNING; CRITICAL for private data or trusted values (CWE-200/862) | Meta Exposed via REST |
| 12 | `WP_Query`/`get_posts`/`get_users` args taken from the request | CRITICAL unauthenticated, else WARNING (CWE-200) | Request-Controlled Query Arguments |

Two more mistakes not shown above:

### Checking Authorization After Action

```php
// ❌ BAD: Authorization check after performing action
function prefix_update_post_handler() {
    // Action performed first
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );

    // Check too late!
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        wp_die( 'No permission' );
    }
}

// ✅ GOOD: Check nonce and authorization BEFORE action
function prefix_update_post_handler() {
    check_admin_referer( 'prefix_update_post', 'prefix_nonce' );

    $post_id = isset( $_POST['post_id'] ) ? absint( $_POST['post_id'] ) : 0;

    // Check first
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        wp_die( 'No permission' );
    }

    // Then perform action
    $title = sanitize_text_field( wp_unslash( $_POST['title'] ) );
    wp_update_post( array( 'ID' => $post_id, 'post_title' => $title ) );
}
```

### Trusting Client-Side Authorization

```php
// ❌ BAD: Only hiding UI, no server-side check
// JavaScript:
// if (userData.role === 'admin') {
//     showDeleteButton();
// }

function prefix_delete_handler() {
    // No server-side check! Anyone who knows the endpoint can delete
    wp_delete_post( $_POST['id'] );
}

// ✅ GOOD: Always check on server (nonce + object capability)
function prefix_delete_handler() {
    check_ajax_referer( 'prefix_delete', 'nonce' );

    $post_id = isset( $_POST['id'] ) ? absint( $_POST['id'] ) : 0;

    if ( ! current_user_can( 'delete_post', $post_id ) ) {
        wp_send_json_error( 'Permission denied', 403 );
    }

    wp_delete_post( $post_id );
    wp_send_json_success();
}
add_action( 'wp_ajax_prefix_delete', 'prefix_delete_handler' );
```

Related: CSRF and nonce bypass patterns → nonce-csrf-guide.md. Other vulnerability classes → vulnerability-patterns.md.
