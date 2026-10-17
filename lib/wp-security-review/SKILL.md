# WordPress Security Review

## Overview

**Three pillars:**
1. Sanitize input early
2. Validate authorization (nonce + capability)
3. Escape output late

Scan CRITICAL issues first, then WARNING, then INFO. Report each finding with line number, severity, CWE, and a BAD/GOOD code pair.

## Out of Scope

- Server hardening (Apache/nginx config, firewall rules), WAF config, or SSL/TLS setup
- Performance-only audits (use `/wp-performance`)
- Non-WordPress PHP security

## Intake

This procedure owns the review once loaded. Do not hand off to another review or security command partway through unless the user asks.

Before scanning, confirm scope in one round of questions (use `AskUserQuestion` when available). Ask only for what the request leaves open:

1. **Target**: plugin/theme directory, specific files, a diff, or a pasted snippet.
2. **Depth**: quick triage (scan plus top issues) or full audit.
3. **Exposure**: public site with anonymous visitors, logged-in members/customers, or admin-only tool. Also ask about multisite and WordPress VIP. Exposure drives severity.
4. **Output**: report only, or report plus suggested patches.

**Skip intake** when the request already names the target and the depth is clear, when running non-interactively (headless `-p`, CI, or a subagent), or when the user says to proceed. Then use defaults: target = directory or files named, else the current directory; full audit; public site, single site, not VIP; report only. State the defaults used in the first line of the report.

## Review Workflow

1. **Run quick scan** to get candidate lines. `<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/wp-security-review`, the folder that contains this procedure file; every relative `references/...` or `scripts/...` path below is inside it. Run the scanner as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rule matches:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/lib/wp-security-review/scripts/scan.sh <plugin-or-theme-dir> [path/to/wp-config.php]
   ```
   Output groups are `HIGH-RISK SINK`, `REVIEW`, and `HARDENING`. These are search buckets, not severities. Every hit is a candidate only.
2. **Verify each candidate.** Open the file. Trace whether user-controlled data reaches the sink. Check for guards on earlier lines (nonce, capability, sanitize, prepare), mitigations further along (allowlist, `wp_kses*` filter, signature/HMAC check, `realpath` containment), and whether the code is reachable at all (dead branch, undefined variables). Values read back from storage (options, post/user/comment meta, custom tables, transients, imported or restored data) count as user-controlled when a lower-privileged path wrote them, such as a `nopriv` handler, form entry, profile field, or comment. Find the write side before discarding a stored-data sink as trusted (second-order injection). Discard false positives (see Common Mistakes).
3. **Manual pass by file type** using checks below. The scan misses multi-line flows, wrong capabilities, and logic flaws.
4. **Rate severity from the exploit path, not the sink** (see Severity Definitions). Before rating CRITICAL, write the exploit path: entry point → who can reach it → missing guard → concrete impact. If any link is unconfirmed or mitigated, rate lower or mark "needs confirmation".
5. **Report** using Output Format.

For a single snippet pasted in chat, skip step 1 and apply steps 3–5 directly.

## File-Type Specific Checks

Severities below are the ceiling for a confirmed exploit path. A matching sink with a guard, a mitigation, or low-value impact rates lower.

### Any Plugin/Theme PHP File

- `eval(` → CRITICAL: code injection (CWE-95)
- `exec(`, `shell_exec(`, `system(`, `passthru(`, `popen(`, `proc_open(`, backticks → CRITICAL if user input reaches it (CWE-78)
- `unserialize(` / `maybe_unserialize(` on request or cookie data, or on a stored value a lower-privileged user can write (form entry, user meta, comment) → CRITICAL: object injection (CWE-502). Fix: store JSON, or `unserialize( $v, [ 'allowed_classes' => false ] )`
- `base64_decode()` whose output reaches `eval`, `unserialize`, `include`, or `file_put_contents` → CRITICAL; alone → INFO (possible backdoor indicator)
- `include` / `require` with request data → CRITICAL: path traversal / file inclusion (CWE-22)
- User-controlled path to `file_get_contents`, `readfile`, `fopen`, `file`, or download handler → CRITICAL: arbitrary file read, e.g. `wp-config.php` (CWE-22)
- User-controlled path to `unlink`, `wp_delete_file`, `rmdir` → CRITICAL: arbitrary file delete; deleting `wp-config.php` triggers reinstall takeover (CWE-22/CWE-73)
- `update_option()` with user-controlled option NAME → CRITICAL: privilege escalation via `default_role`, `users_can_register` (CWE-269)
- User-controlled role or `{$wpdb->prefix}capabilities` meta via `wp_update_user()`, `update_user_meta()`, `set_role()` → CRITICAL (CWE-269)
- `$_GET[`, `$_POST[`, `$_REQUEST[`, `$_COOKIE[` used without `sanitize_*` or cast → WARNING (CWE-20)
- Missing `defined( 'ABSPATH' ) || exit;` → INFO (WARNING if file runs logic on include)

### Form Handlers (`admin_post_*`, `admin_post_nopriv_*`)

All three steps required for state-changing operations:
1. Nonce: `check_admin_referer()` or `wp_verify_nonce()` → CRITICAL if missing, or if `wp_verify_nonce()` is called but its return value is not enforced (CWE-352)
2. Capability: `current_user_can()` with the correct capability → CRITICAL if missing (CWE-862)
3. Sanitization: `sanitize_*()` / `absint()` on every input, after `wp_unslash()` → WARNING if missing (CWE-20)

### AJAX Handlers (`wp_ajax_*`, `wp_ajax_nopriv_*`)

- `check_ajax_referer()` missing on state-changing handler → CRITICAL (CWE-352)
- `check_ajax_referer( $action, $field, false )` with result not checked → CRITICAL: third arg `false` disables the built-in `die` (CWE-352)
- `current_user_can()` missing when action needs privilege → CRITICAL (CWE-862)
- `wp_ajax_nopriv_*` doing writes → CRITICAL unless deliberately public (contact form, vote) and rate-limited or CAPTCHA-protected. A nonce here is not protection: all logged-out users share one nonce per action, readable from the page.
- `is_admin()` used as auth check → CRITICAL: returns true for every `admin-ajax.php` request, including logged-out users (CWE-863)

### REST API Endpoints (`register_rest_route`)

- No `permission_callback` on write methods or non-public data → CRITICAL (CWE-862). WP 5.5+ only emits a `_doing_it_wrong` notice; route stays public.
- No `permission_callback` on public-data GET → INFO (notice only; add `'__return_true'` explicitly)
- `'permission_callback' => '__return_true'` on POST/PUT/PATCH/DELETE → CRITICAL, unless deliberately public (webhook, contact form) and protected by signature check, nonce, or rate limit
- `__return_true` on public GET → OK
- Permission callback that checks login only (`is_user_logged_in()`) for privileged actions → WARNING (CWE-863)
- Args without `sanitize_callback` / `validate_callback`, and `$request->get_param()` used raw → WARNING (CWE-20)
- REST uses `X-WP-Nonce` (cookie auth) or application passwords, not form nonces

### Database Code (`$wpdb`)

- `query`, `get_results`, `get_var`, `get_row`, `get_col` with user-controlled value interpolated or concatenated, not cast, no `prepare()` → CRITICAL (CWE-89)
- Same, but value already cast with `absint()`/`intval()` → INFO (coding standard; prefer `prepare()` with `%d`)
- `esc_sql()` on a value placed outside quotes (`"WHERE id = " . esc_sql( $id )`, `IN (`, `LIMIT`) → CRITICAL: `esc_sql()` only escapes quote characters, so `0 UNION SELECT ...` passes (CWE-89). Fix: `absint()` or `prepare()` with `%d`
- Stored values (meta, options, imported or restored rows) concatenated into SQL → treat as user input when a lower-privileged user wrote them (second-order SQLi)
- Import/restore code that regex-parses dumps or remote text and builds SQL from the captures → trace each capture; dumps contain user-written rows, so an unanchored regex can match inside data. CRITICAL if a capture reaches a query unescaped (CWE-89)
- User-controlled variable inside the `prepare()` format string itself (`prepare( "... $var ..." )`) → CRITICAL (CWE-89). Exempt: `{$wpdb->table}` properties, code-built placeholder lists, allowlisted identifiers.
- Numbered or formatted placeholders (`%1$s`, `%1s`) → `prepare()` adds no quotes, so `WHERE id = %1s` with a string is CRITICAL SQLi (CWE-89). Use `%d` or `%s`
- `LIKE` with variable not passed through `$wpdb->esc_like()` → WARNING (wildcard abuse, not injection)
- User input in table or column names → CRITICAL unless allowlisted. `%i` (WP 6.2+; plugin header `Requires at least: 6.2`) quotes the identifier but does not authorize it: `%i` with user input can still read `wp_users`.
- `ASC`/`DESC` from input → CRITICAL unless whitelisted; `%i` does not cover keywords
- `prepare()` on an already-prepared string → WARNING: double-prepare
- `{$wpdb->prefix}` / `{$wpdb->posts}` in queries → OK

### Templates and Output

- `echo $var` / `<?= $var ?>` without escaping → CRITICAL on public pages (CWE-79)
- Wrong escape for context (for example, `esc_html()` inside `href`) → CRITICAL (CWE-79)
- PHP variables inside `<script>` → CRITICAL; use `wp_json_encode()` or `wp_localize_script()` / `wp_add_inline_script()`
- Rich HTML without `wp_kses()` / `wp_kses_post()` → WARNING
- Escaping before storage instead of at output → WARNING: data corruption and false sense of safety; not itself a vulnerability

### Redirects and Outbound Requests

- `wp_redirect()` / `header( 'Location: ' )` with user-supplied URL → WARNING: open redirect (CWE-601). Use `wp_safe_redirect()`.
- `wp_remote_get()` / `wp_remote_post()` / `file_get_contents()` / `curl_*` on user-supplied URL → WARNING: SSRF (CWE-918); CRITICAL if unauthenticated or response is returned to the caller. Use `wp_safe_remote_*()`, which rejects local and private IPs.

### File Upload Handlers

- `move_uploaded_file()` instead of `wp_handle_upload()` → CRITICAL (CWE-434)
- No `current_user_can( 'upload_files' )` → CRITICAL (CWE-862), unless deliberately public (for example, a job application form) and restricted to a small type allowlist and size limit
- `wp_handle_upload()` / `media_handle_upload()` with `'test_type' => false` → CRITICAL: disables file type check (CWE-434)
- Custom upload path with no `wp_check_filetype_and_ext()` or MIME allowlist → WARNING (CWE-434). Default `wp_handle_upload()` already runs this check.
- SVG added to `upload_mimes` without SVG sanitization → WARNING: stored XSS
- No size limit → INFO

### JavaScript (`*.js`, `*.jsx`, `*.ts`, `*.tsx`)

- `innerHTML`, `outerHTML`, `document.write`, `dangerouslySetInnerHTML`, jQuery `.html()` with untrusted data → CRITICAL: DOM XSS (CWE-79)
- `fetch()` / `$.ajax()` / `$.post()` state change without nonce (`X-WP-Nonce` header or `nonce` field) → WARNING (CWE-352); `@wordpress/api-fetch` adds the nonce automatically
- `eval(` / `new Function(` with data → CRITICAL (CWE-95)

## Safe-Function Cheat Sheet

| Context | Use |
|---------|-----|
| HTML body text | `esc_html()` |
| HTML attribute | `esc_attr()` |
| URL in `href`/`src` | `esc_url()` |
| URL for DB or redirect | `esc_url_raw()` / `wp_safe_redirect()` |
| `<textarea>` content | `esc_textarea()` |
| Data into JS | `wp_json_encode()`, `wp_localize_script()` |
| Trusted rich HTML | `wp_kses_post()` |
| Custom allowed HTML | `wp_kses( $html, $allowed )` |
| Text input | `sanitize_text_field( wp_unslash( $_POST['x'] ) )` |
| Multi-line text | `sanitize_textarea_field()` |
| Email / key / filename | `sanitize_email()` / `sanitize_key()` / `sanitize_file_name()` |
| Integer ID | `absint()` |
| Fixed choice | `in_array( $v, $allowed, true )` |
| SQL values | `$wpdb->prepare()` with `%d`, `%s`, `%f` |
| SQL identifiers | Allowlist, then `%i` (WP 6.2+); `ASC`/`DESC` allowlist only |
| Redirect to user URL | `wp_safe_redirect( wp_validate_redirect( $url, $fallback ) )` |
| Fetch user URL | `wp_safe_remote_get()` / `wp_safe_remote_post()` |
| SQL `LIKE` | `'%' . $wpdb->esc_like( $term ) . '%'` then `%s` |
| Form nonce | `wp_nonce_field()` + `check_admin_referer()` |
| AJAX nonce | `wp_create_nonce()` + `check_ajax_referer()` |
| Specific object | `current_user_can( 'edit_post', $post_id )` |
| Upload | `wp_handle_upload( $f, array( 'test_form' => false, 'mimes' => $allowlist ) )` |
| Shell arg (avoid shell) | `escapeshellarg()` + whitelist |
| User-supplied structured data | `json_decode()`, never `unserialize()` |

For full BAD/GOOD code pairs, load the matching reference file (see Deep-Dive References).

## Severity Definitions

| Severity | Meaning | Examples |
|----------|---------|----------|
| **CRITICAL** | Exploitable without authentication, OR leads to RCE, data breach, or privilege escalation | SQL injection on public endpoint; reflected XSS; stored XSS from a visitor or low-privilege user that renders anywhere, including wp-admin; missing nonce or capability on state-changing action; upload without capability check; arbitrary file read/delete; `eval()` on user input |
| **WARNING** | Needs authentication or specific conditions to exploit | XSS where only Author/Contributor-level users supply the data; SQL injection reachable only by admins; incomplete sanitization; `LIKE` without `esc_like()` |
| **INFO** | Defense-in-depth or hardening | Missing ABSPATH guard; hardening constants unset; placeholder auth keys; debug output left in code |

**CRITICAL needs a confirmed exploit path.** Name the entry point, who can reach it, the missing guard, and the concrete impact (data read, code run, account or site takeover, destructive write). Do not rate CRITICAL when:
- an allowlist, `wp_kses*` filter, signature check, or `realpath` containment already blocks the attack
- the branch is unreachable (dead code, undefined variables)
- the impact is disclosure of non-sensitive data, a duplicate or redundant control, or resource use only
- exploitation needs a precondition you did not confirm (mark "needs confirmation" and rate WARNING at most)

**Context adjustments:**
- Rate XSS by who supplies the data, not where it renders. Stored XSS from a visitor, subscriber, or contributor that runs in an admin's session is privilege escalation: CRITICAL. XSS where only admins or editors supply the data: INFO, since those roles already have `unfiltered_html` on single site (WARNING on multisite, where they do not).
- Admin-only code (requires `manage_options` or similar) with admin-supplied input: lower one level. Exception: CSRF against admin stays CRITICAL, since attacker needs no account.
- WP-CLI and WP-Cron: nonces not required (no browser request, no CSRF).
- REST API: auth via `permission_callback`, not form nonces.
- Public-facing code: highest severity.
- Hosting WAF or platform blocks: never lower severity of a code-level finding.

## Output Format

Group findings by file, then severity:

~~~markdown
## Security Review: path/to/file.php

### CRITICAL Issues

**Line 42** | CWE-79 | Reflected XSS via unescaped output
- **Issue**: `$_GET['title']` echoed without escaping
- **Risk**: Attacker-crafted link runs JavaScript in victim's session
- **Exploit path**: `GET ?title=<script>…` → any visitor → no escaping on output → script runs in viewer's session
- **Context**: Public template (defaults: full audit, public single site)

❌ **BAD:**
```php
<h1><?php echo $_GET['title']; ?></h1>
```

✅ **GOOD:**
```php
<?php $title = isset( $_GET['title'] ) ? sanitize_text_field( wp_unslash( $_GET['title'] ) ) : ''; ?>
<h1><?php echo esc_html( $title ); ?></h1>
```

### WARNING Issues

**Line 88** | CWE-20 | Unsanitized input stored
- **Issue**: ...
- **Risk**: ...
- **Context**: Admin-only (lowered from CRITICAL)

[BAD/GOOD pair]

### INFO Recommendations

**Line 1** | Defense-in-depth | Missing ABSPATH guard
- Add `defined( 'ABSPATH' ) || exit;` at top of file

### Summary
- **Total**: 1 CRITICAL, 1 WARNING, 1 INFO
- **Risk level**: HIGH (unauthenticated CRITICAL present)
- **Fix first**: Line 42
~~~

If no issues are found, say so explicitly and list what was checked.

## Common Mistakes (False Positives)

| Do not flag | Reason |
|-------------|--------|
| Missing nonce in WP-CLI command or cron callback | No browser request, no CSRF |
| `wp_kses_post()` on post content | Correct for trusted rich HTML |
| `$wpdb->query()` with hardcoded SQL, no variables | No input, no injection |
| `current_user_can()` inside REST `permission_callback` | Correct location, not redundant |
| `esc_html( get_the_title() )` as double-escaping | WP stores raw data; late escaping is correct |
| `update_option()` after capability + nonce check | Options API is safe once authorized |
| `__return_true` on GET routes returning public data | Public read is intentional |
| Raw `$_POST` inside `register_setting()` flow with `sanitize_callback` | Settings API sanitizes via callback |
| `$_POST['x']` inside `isset()` / `empty()` / `wp_verify_nonce()` | Read for checks, not used as data |
| Scan hits in `vendor/` or bundled libraries | Report separately as dependency risk, not code finding |
| `wp_handle_upload()` without separate `wp_check_filetype_and_ext()` | Default `test_type` already validates type |
| `prepare( "SELECT ... FROM {$wpdb->posts} ..." )` | `$wpdb` table properties are trusted, not user input |
| `prepare( "... IN ($placeholders)" )` where `$placeholders` is built from `array_fill( ..., '%d' )` | Code-built placeholders, values still bound |
| `esc_attr()` used in HTML body | Wrong function but not exploitable; encodes same characters as `esc_html()` |
| `if ( is_admin() )` used to load admin-only code | Fine for loading; flag only when it gates a state change |
| Missing ABSPATH guard in `uninstall.php` with `WP_UNINSTALL_PLUGIN` check | That constant is the correct guard |
| `absint( $id )` interpolated into SQL as CRITICAL | Cast integer is not injectable; INFO at most |
| Placeholder `put your unique phrase here` keys as CRITICAL | `wp_salt()` ignores placeholders and uses random DB-stored salts; INFO |
| `update_option()` in an importer as "arbitrary option write" | Check for an option-name allowlist first; with one, not privilege escalation |
| Logged or stored data as stored XSS | Check whether it passes through `wp_kses_post_deep()` / `wp_kses*` before storage or output |
| Delete or write gated by an HMAC/signature as CRITICAL | Signed token blocks forgery; rate the signing scheme, not the sink |
| A second or duplicate nonce as CRITICAL | Redundant control is at most INFO |
| Sink in a branch with undefined variables | Dead code is not exploitable; INFO note at most |
| Path traversal needing a specially named directory to exist | Unconfirmed precondition; WARNING at most, mark "needs confirmation" |
| Unauthenticated write whose only effect is junk rows or meta on a nonexistent ID, as CRITICAL | No privilege, data, or code impact; WARNING at most (storage abuse) |

## Deep-Dive References

Read only the needed section: grep the file for the `## ` heading below, then read from that line.

| Task | Reference | Key `## ` sections |
|------|-----------|--------------------|
| SQLi (LIKE, ORDER BY, IN, identifiers, double-prepare), XSS types, object injection, path traversal, open redirect, SSRF, dangerous functions | `references/vulnerability-patterns.md` | Quick Lookup Table; SQL Injection Patterns; Cross-Site Scripting; Open Redirect; Server-Side Request Forgery; Dangerous Function Catalog |
| Escaping by context, `wp_kses` config, i18n escaping | `references/escaping-guide.md` | The Late Escaping Principle; Context-Specific Escaping Functions; wp_kses() Family; WordPress i18n + Escaping |
| Sanitization by data type, `wp_unslash()`, arrays and JSON | `references/sanitization-guide.md` | Type-Specific Sanitization Functions; The wp_unslash() Requirement; Sanitizing Arrays and Complex Data |
| Capabilities vs roles, meta caps, REST/AJAX authorization (canonical `permission_callback` guide) | `references/auth-patterns.md` | Capabilities vs Roles; REST API Permission Callbacks; AJAX Handler Authorization; Common Authorization Mistakes |
| Nonce lifecycle, form/AJAX/URL/REST nonces, logged-out nonces, when nonces are not needed | `references/nonce-csrf-guide.md` | Nonce Lifecycle; Form Nonces; AJAX Nonces; When Nonces Are NOT Needed; Nonce Debugging |
| ABSPATH guards, `wp-config.php` constants, debug display, upload MIME limits, hosting platform context | `references/hardening.md` | Direct File Access Prevention; Security Constants; Debug Constants; Upload MIME Restrictions; Platform Context |

## Scripts

- **`scripts/scan.sh [dir] [wp-config.php]`** — grep triage across PHP and JS (see Review Workflow step 1). Skips `vendor/`, `vendor-prefixed/`, `node_modules/`, `.git/`, `build/`, `dist/`, `*.min.js`. Also checks per-file REST `permission_callback`, handler capability/nonce checks, ABSPATH guards, and `wp-config.php` keys and constants. Exits 0, or 2 if target is not a directory.
