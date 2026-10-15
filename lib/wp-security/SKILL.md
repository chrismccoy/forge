# WordPress Security Review

WordPress theme/plugin security review. Three pillars: sanitize input early, authorize every state change (nonce + capability), escape output late.

**Out of scope:** server hardening (web server, WAF, TLS), performance, non-WordPress PHP.

`<skill-dir>` below is `${CLAUDE_PLUGIN_ROOT}/lib/wp-security`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it.

## Workflow

1. **Run the scanner:** `bash <skill-dir>/scripts/wp-sec-scan.sh <dir-or-file>` (needs GNU grep `-P`; runs phpcs WordPress sniffs if installed). Exit 1 = CRITICAL candidates; 2 = environment error or unreadable files (results incomplete). Hits are candidates: confirm each by reading the code. Heuristic checks (`is_admin`, token `==`, weak randomness, public GET routes, unescaped-variable echoes, `printf`/`_e`/`wp_die` sinks) report WARNING; escalate once confirmed. Without phpcs, also read every `echo`/`print` of a variable.
2. **Read what grep cannot see:** every `register_rest_route` args array, and every request-reading callback on `admin_post_*`, `wp_ajax_*`, `admin_init`, `init`, `wp_loaded` or `template_redirect`.
3. **Apply the checks below.** Trace each superglobal or `$request` value from input to sink.
4. **Rate and report** with the severity rules and output format below, CRITICAL first.

## File-Type Checks

### Any PHP file
- `eval`, `assert` (string arg), `create_function`, `preg_replace` `/e` → CRITICAL (CWE-95)
- `exec`, `shell_exec`, `system`, `passthru`, `popen`, `proc_open`, backticks with input → CRITICAL (CWE-78)
- `unserialize` / `maybe_unserialize` on `$_GET`/`$_POST`/`$_REQUEST`/`$_COOKIE` (also through `wp_unslash` or `base64_decode`) → CRITICAL (CWE-502). Use `json_decode`. `base64_decode` alone → INFO; the sink sets severity.
- `update_option()` with a user-controlled option name, or user-controlled values for `default_role` / `users_can_register` → CRITICAL privilege escalation (CWE-269). Allow-list option names.
- `extract( $_POST )` → CRITICAL (CWE-621)
- `include`/`require`, or `get_template_part`/`locate_template`/`load_template`, with a path or slug from user input → CRITICAL (CWE-22/98). Map request values to an allow-list.
- File read/write/delete with a user-controlled path (`unlink`, `wp_delete_file`, `readfile`, `file_get_contents`, `file_put_contents`, `copy`, `rename`, `fopen`) → CRITICAL (CWE-22/73). Deleting `wp-config.php` leads to reinstall and RCE. Require `basename()`, a fixed base dir, and a `realpath()` prefix check.
- `call_user_func(_array)`, variable functions `$fn()`, `do_action`/`apply_filters` with a request-chosen name, or `do_shortcode()` on request data → CRITICAL (CWE-94). Allow-list callables.
- `wp_set_auth_cookie()`/`wp_set_current_user()` with a request user ID, or custom login/reset tokens compared with `==`, made with `rand`/`mt_rand`/`uniqid`, or never expiring → CRITICAL auth bypass (CWE-287/330). Use `hash_equals` and `wp_generate_password`.
- `wp_insert_user`/`wp_create_user`/`wp_update_user` with `role` from the request → CRITICAL (CWE-269). Self-registration must use `get_option( 'default_role' )`.
- Request arrays passed to `wp_insert_post`/`wp_update_post` (`ID`, `post_author`, `meta_input`) or as `$wpdb->insert/update/replace` data (keys become column names) → CRITICAL (CWE-915/89). Build data from allow-listed keys.
- `update_user_meta`/`update_post_meta`/`add_*_meta` with a request-chosen meta key → CRITICAL (CWE-269/915). User meta `{prefix}capabilities` grants roles. Allow-list keys.
- `in_array()` allow-list without `true` as third argument, or `==` on user input → WARNING (CWE-697); CRITICAL if it gates auth or roles.
- Hardcoded API keys, tokens, or passwords → WARNING; CRITICAL if a live production secret (CWE-798). Exports, backups, or logs written to `uploads/` with guessable names → CRITICAL if they hold private data (CWE-552).
- `is_admin()` used as a permission check → CRITICAL (CWE-863). It reports admin-area context only and is `true` for anonymous `admin-ajax.php` requests.
- `is_user_logged_in()` as the only guard on a privileged action → CRITICAL (CWE-862). Any Subscriber passes.
- Superglobal read without `wp_unslash()` + `sanitize_*` → WARNING (CWE-20)
- No `ABSPATH` guard → INFO

### Form handlers, AJAX, and state-changing hooks
Applies to `admin_post_*`, `wp_ajax_*`, and state-changing `admin_init`/`init`/`wp_loaded`/`template_redirect` callbacks (`admin_init` also runs for logged-out `admin-ajax.php`/`admin-post.php`). Every state-changing handler needs all three:
1. Nonce: `check_admin_referer()` / `check_ajax_referer()` / `wp_verify_nonce()` → CRITICAL if missing (CWE-352)
2. Capability: `current_user_can()`. Use a meta cap with the object ID for object actions, e.g. `edit_post`, `edit_user`, `delete_user`. → CRITICAL if missing (CWE-862). Wrong cap → WARNING (CWE-863). Primitive cap without the object ID (e.g. `edit_posts` before editing post `$id`) → WARNING (CWE-639); CRITICAL if a low role can modify other users' data.
3. Sanitization: `sanitize_*( wp_unslash( ... ) )`, `absint()` → WARNING if missing (CWE-20)

Role changes: check `promote_user` for the target user, block changes to the current user's own role, and accept only roles from `get_editable_roles()` (load `wp-admin/includes/user.php` first outside wp-admin). Missing any of these → CRITICAL (CWE-269).

Nonce bypass patterns → CRITICAL (CWE-352):
- `if ( isset( $_POST['n'] ) && ! wp_verify_nonce( ... ) )`: omitting the field skips the check.
- `wp_verify_nonce()` return value ignored, or `check_ajax_referer( $a, $b, false )` with the result unchecked.
- `check_admin_referer()` with no action: core skips the nonce check when the attacker-supplied `_wp_http_referer` is an absolute wp-admin URL, and the call returns `false` without dying. Full bypass.

Nonce created without an action → WARNING (the `-1` nonce is shared).

Nonce facts that drive severity:
- WordPress nonces are **not single-use**. A nonce is valid for 12–24h and can be replayed. It is never authorization.
- Logged-out visitors all get the **same** nonce (user 0, no session) unless `nonce_user_logged_out` is filtered, as WooCommerce does. Missing nonce on `wp_ajax_nopriv_*` → INFO/WARNING by impact; CRITICAL only if the callback is also on `wp_ajax_*` and changes logged-in state.

### REST API (`register_rest_route`)
- Missing `permission_callback` → CRITICAL on write routes (CWE-862). WordPress only emits a notice; the route stays **public**.
- `'__return_true'` on POST/PUT/PATCH/DELETE → CRITICAL. On GET, OK only if the data is already public. Returning other users' PII, user meta, or private posts to anonymous users (REST or `nopriv`) → CRITICAL (CWE-200).
- Permission callback without `current_user_can()` on private data → WARNING (CWE-863)
- `register_meta`/`register_post_meta` with `show_in_rest` on private data → CWE-200; without `auth_callback`, unprotected keys are writable by any post editor. `WP_Query`/`get_posts`/`get_users` args (`post_status`, `author`, `meta_query`) from the request → CRITICAL when unauthenticated (CWE-200). Build args server-side.
- `args` without `sanitize_callback`/`validate_callback` or a schema `type`/`enum`, and the callback uses the value raw → WARNING (CWE-20)
- Custom `sanitize_callback` with no `validate_callback`: it replaces the default handler, so schema `type`/`enum`/`minimum`/`maximum` are NOT enforced. Add `'validate_callback' => 'rest_validate_request_arg'` → WARNING

### Database (`$wpdb`)
- Query built by concatenation/interpolation without `prepare()` → CRITICAL (CWE-89)
- Variable interpolated inside the `prepare()` format string (e.g. `"... LIKE '%%{$term}%%'"`) → CRITICAL (CWE-89). Exception: a variable built only from `%d`/`%s` placeholders for `IN (...)` (`implode( ',', array_fill( 0, count( $ids ), '%d' ) )`) is correct.
- User-controlled table/column/`ORDER BY` → use `%i` (WP 6.2+) or an allow-list. Always allow-list `ASC`/`DESC`. Unvalidated → CRITICAL.
- `esc_sql()` on a value placed outside quotes (numeric, `IN (...)`, `LIMIT`) → CRITICAL (CWE-89). `esc_sql()` only protects inside quoted strings. `sanitize_text_field()` is not SQL escaping.
- `intval()`/`absint()`-cast value interpolated → INFO (WPCS style, not exploitable)
- `LIKE %s` value not passed through `$wpdb->esc_like()` → WARNING (CWE-20; wildcard injection, not SQLi)
- Double-prepare → WARNING. `%` sequences in user data are re-read as placeholders (CVE-2017-16510; mitigated by placeholder escaping since 4.8.3).
- `{$wpdb->prefix}`/`{$wpdb->posts}` in the query → OK

### Output and templates
- `echo`/`print`/`<?=`, `printf`, `_e( $var )`, or `wp_die`/`die`/`exit` with an unescaped variable → CRITICAL (CWE-79). Check every operand (`esc_html( $a ) . $b` leaves `$b` raw) and double-quoted interpolation. `esc_attr()` on `href`/`src` lets `javascript:` through; use `esc_url()`. Match the escaping function to the context: `esc_html`, `esc_attr`, `esc_url`, `esc_textarea`, `wp_kses_post`/`wp_kses`.
- PHP values inside `<script>` that are unencoded, or encoded with `esc_html`/`esc_attr`/`esc_js` instead of JSON → CRITICAL. Use `wp_json_encode( $v, JSON_HEX_TAG | JSON_HEX_AMP )`, ideally via `wp_add_inline_script()`. `esc_js()` is for inline event-handler attributes only. `wp_localize_script()` turns scalars into strings.
- Shortcode attributes or block attributes output without escaping (including in a block `render_callback`) → CRITICAL stored XSS (CWE-79). `shortcode_atts()` does not sanitize, and Contributors can save both. kses filters string block attributes (5.3.1+), but quote breakout and `javascript:` URLs survive. `get_block_wrapper_attributes()` is already escaped.
- `add_query_arg()`/`remove_query_arg()` output, or `$_SERVER['REQUEST_URI']`/`PHP_SELF`/`HTTP_REFERER`, echoed without `esc_url()` → CRITICAL reflected XSS (CWE-79). Without a URL argument, `add_query_arg()` builds on `REQUEST_URI`.
- Escaping before storage → INFO

### Uploads
- `move_uploaded_file()` instead of `wp_handle_upload()` / `media_handle_upload()`, or no type restriction (executable files possible) → CRITICAL (CWE-434)
- No `current_user_can( 'upload_files' )` → CRITICAL (CWE-862)
- `upload_mimes` adding `svg` without an SVG sanitizer → CRITICAL (CWE-79). Author-level stored XSS runs in admin sessions. The sanitizer must select by lowercased extension, not `$file['type']`, and hook both `wp_handle_upload_prefilter` and `wp_handle_sideload_prefilter` (REST uploads).
- No `wp_check_filetype_and_ext()` alongside custom handling → WARNING (CWE-434)
- Raw `ZipArchive::extractTo()`/`PclZip` on user archives without entry-name checks → CRITICAL Zip Slip (CWE-22). `unzip_file()` already rejects `../` entries; its risk is `.php` files landing in a web-served directory → CRITICAL (CWE-434).
- `wp_upload_bits()`/`file_put_contents()` where the user picks the file name or extension (`.php`, `.phtml`, `.htaccess`, `.user.ini`) → CRITICAL (CWE-434). Use a server-chosen name and an extension allow-list.
- XML imports parsed with `LIBXML_NOENT`/`LIBXML_DTDLOAD` → CRITICAL XXE (CWE-611)
- Filesystem calls (`file_exists`, `getimagesize`, ...) on a raw user path → CRITICAL on PHP < 8 via `phar://` (CWE-502). Reject stream wrappers (`wp_is_stream()`).

### Redirects and outbound requests
- `wp_redirect()`/`wp_safe_redirect()` used as an access check without `exit` → CRITICAL (CWE-698). Execution continues into the privileged code.
- `wp_redirect()` to a user-controlled URL → WARNING (CWE-601). Use `wp_safe_redirect()` + `allowed_redirect_hosts`.
- `wp_remote_*`, `file_get_contents`, or `curl` with a user-controlled URL → WARNING/CRITICAL (CWE-918). `wp_safe_remote_*` does NOT block `169.254.169.254` (cloud metadata), 100.64/10, dual-stack hosts, or DNS rebinding. Require a host allow-list.

- IP from `HTTP_X_FORWARDED_FOR`/`HTTP_CLIENT_IP` for rate limits or allow-lists → WARNING; CRITICAL if it gates auth (CWE-348). Use `REMOTE_ADDR` unless behind a trusted proxy.
- `Access-Control-Allow-Origin` reflecting the request Origin with `Allow-Credentials: true` → WARNING/CRITICAL (CWE-942)

### JavaScript
- `innerHTML`/`insertAdjacentHTML`/`dangerouslySetInnerHTML`/jQuery `.html()`/`.append()` with untrusted data, or `eval`/`new Function` → CRITICAL (CWE-79/95)
- Request sent without a nonce → INFO. Report CSRF on the PHP handler.

### wp-config.php (when in scope)
- Placeholder keys/salts (`put your unique phrase here`) → CRITICAL
- Missing `DISALLOW_FILE_EDIT`, `FORCE_SSL_ADMIN`, `DISALLOW_UNFILTERED_HTML` → INFO
- `WP_DEBUG_DISPLAY`/`display_errors` on in production → WARNING (CWE-215). Public `wp-content/debug.log` → WARNING (CWE-532).

## Severity

| Severity | Meaning |
|----------|---------|
| **CRITICAL** | Exploitable without authentication, or leads to data breach, RCE, or privilege escalation |
| **WARNING** | Needs authentication or specific conditions; incomplete validation |
| **INFO** | Defense-in-depth or hardening |

**Context adjustments:**
- Admin-only code: lower one level, **except** CSRF and privilege escalation. CSRF targets privileged users, so admin CSRF stays CRITICAL.
- Public / `nopriv` code: highest severity, except the nopriv-nonce rule.
- WP-CLI and cron: no nonce needed (WP-CLI runs as user 0 without `--user`).
- REST: auth model is `permission_callback`. Cookie auth requires a nonce in the `X-WP-Nonce` header or `_wpnonce` parameter.

## Output Format

````markdown
## Security Review: path/to/file.php

### CRITICAL
**Line 42** | CWE-79 | Reflected XSS
- **Issue**: `$_GET['title']` echoed without escaping
- **Risk**: Script injection for any visitor following a crafted link

❌ BAD:
```php
<h1><?php echo $_GET['title']; ?></h1>
```
✅ GOOD:
```php
<h1><?php echo esc_html( wp_unslash( $_GET['title'] ?? '' ) ); ?></h1>
```

### WARNING / ### INFO (same layout)

### Summary
- **Total**: N CRITICAL, N WARNING, N INFO
- **Fix first**: line 42
````

## False Positives to Avoid

| Do not flag | Reason |
|-------------|--------|
| Missing nonce in WP-CLI or cron | No HTTP request, so no CSRF |
| `wp_kses_post()` on post content | Correct for trusted rich HTML |
| Hardcoded SQL without user input | No injection path |
| `current_user_can()` inside `permission_callback` | Correct REST location |
| `esc_html( get_the_title() )` as double escaping | `esc_html()` does not double-encode entities |
| `__return_true` on public GET routes | Intentional public read |
| `register_setting()` with `sanitize_callback` | Settings API sanitizes through the callback |

## References

Load a file for depth, edge cases, or full BAD/GOOD examples:

| Topic | File |
|-------|------|
| SQL edge cases, uploads/Zip Slip/file writes, deserialization, XXE, path traversal, function execution, redirects, SSRF, IP spoofing, CORS, info disclosure, loose comparison, wp-config, function catalog | `references/vulnerability-patterns.md` |
| Escaping by context, `wp_kses`, JS data, non-echo sinks, URL attributes, request-URL XSS, shortcode/block output | `references/escaping-guide.md` |
| Sanitizers by type, `wp_unslash`/meta slashing, arrays/JSON, REST arg callbacks | `references/sanitization-guide.md` |
| Capabilities, REST permissions, data exposure (read routes, REST meta, query args), role/option/meta escalation, auth bypass | `references/auth-patterns.md` |
| Nonce lifecycle, nopriv behavior, bypass patterns, AJAX/REST/form patterns | `references/nonce-csrf-guide.md` |

The reference files are large (4–10k words). Do not read them whole: run `grep -n '^##' <skill-dir>/references/<file>.md` (each file opens with a Contents list), then read only the matching section.
