# Render Security and PHP Block Registration

Review guide for any PHP render code (render files, `render_callback`) and for blocks registered from PHP. Load it for every dynamic block, for blocks registered with `register_block_type( 'ns/name', array( ... ) )`, when render code concatenates HTML, or when only compiled JS ships.

## Contents

1. PHP attribute schemas
2. Escaping matrix
3. Severity by who controls the value
4. Render side effects
5. Endpoints that feed a block
6. PHP i18n
7. Missing JS source
8. Registration from PHP
9. Vendored libraries

## 1. PHP Attribute Schemas

Legacy registration passes the same keys that block.json holds:

```php
register_block_type(
	'my-plugin/card',
	array(
		'attributes'      => array(
			'title'   => array( 'type' => 'string', 'default' => '' ),
			'columns' => array( 'type' => 'number', 'default' => 3 ),
		),
		'render_callback' => array( $this, 'render' ),
	)
);
```

Checks:
- **apiVersion and supports are invisible from PHP.** The JS `registerBlockType()` call sets them. When only compiled JS ships, report "apiVersion: not verifiable" as INFO. Do not assume a value.
- **Reserved attribute names:** `style` (block supports object), `className`, `lock`, `metadata`, `anchor`. Declaring `style` as a string is WARNING. It clashes with color, spacing, and typography supports.
- **`selector` without `source`:** does nothing. Values live in the comment delimiter (INFO).
- **Runtime defaults:** defaults from `get_option()`, `is_rtl()`, `uniqid()`, `generateId()`, or `__()` at registration time differ per request and can differ from JS defaults (INFO, WARNING if they affect saved markup).
- **Type coercion:** `WP_Block_Type::prepare_attributes_for_render()` validates DECLARED attributes against their schema. `number`, `integer`, and `boolean` values that fail validation fall back to the default, so they are safe to print as numbers. `string`, `object`, and `array` values are NOT sanitized. Undeclared attributes are passed through untouched.
- **`extract( $attributes )`:** WARNING. Undeclared attributes overwrite locals, including references from `global $post`. Undeclared keys also cause "Undefined variable" notices. If an overwritten local is printed raw, raise to CRITICAL.
- **Registration path:** follow indirect registration (loader classes, integration classes, `WP_Block_Type_Registry::is_registered()` guards) to confirm the call runs on `init`.

## 2. Escaping Matrix

**Core kses does not make attribute context safe.** For users without `unfiltered_html`, core runs block attribute strings through kses. Kses removes disallowed TAGS. A tag-free string such as `" onmouseover=alert(1) x="` passes unchanged, so any raw value inside a quoted HTML attribute (`fill="' . $color . '"`, `data-x="%s"` with raw `json_encode()`) is exploitable by a Contributor. `json_encode()` turns `"` into `\"`, which still closes an HTML attribute.

Escape late, at the point of output. When HTML is assembled across many helpers and echoed by a template, require escaping where the value enters the HTML string, or at the final echo. Do not rely on sanitizing "somewhere earlier".

| Output context | Correct function | Common mistake |
|----------------|------------------|----------------|
| Text node | `esc_html()` | Raw `$attributes['x']` |
| Attribute value | `esc_attr()` | Raw value in `attr="%s"` |
| URL (`href`, `src`) | `esc_url()` | `esc_attr()` only, so `javascript:` passes |
| Class fragment | `sanitize_html_class()` or `esc_attr()` | Raw value in `class="prefix-%s"` |
| Rich-text attribute (from RichText) | `wp_kses_post()` | Raw output: attribute strings are NOT trusted HTML |
| JSON in an HTML attribute | `esc_attr( wp_json_encode( $data ) )` in double quotes | `json_encode()` in `data-x='%s'`: `json_encode` does not escape `'` |
| JSON in `<script>` | `wp_json_encode()` (escapes `/`, so `</script>` cannot close the tag) | String concatenation |
| Tag name from an attribute | Allowlist: `in_array( $tag, array( 'h2', 'h3', 'p' ), true )` | `'<' . $attributes['tag']` |
| Inline CSS value | Validate format (`sanitize_hex_color()`, `absint()`), then `esc_attr()` | `esc_attr()` alone: still allows `red;background:url(...)` |
| Inner blocks `$content` | Output as-is | `wp_kses_post( $content )` |
| Wrapper attributes | `get_block_wrapper_attributes( array( 'data-x' => $raw ) )` | Pre-escaping values (double escape) |

**Node-tree renderers.** Some blocks store rich text as a JSON node tree (`{ "type": "a", "props": { "href": ..., "children": [...] } }`) and rebuild HTML in PHP. Core kses cannot help here: no single string contains HTML. Require ALL of these:
- `type` allowlisted against a fixed tag list.
- Text children through `esc_html()`.
- `href` and `src` through `esc_url()`, other props through `esc_attr()`.
- Final HTML through `wp_kses_post()`.
Missing any one is CRITICAL.

**Decoding after kses is CRITICAL.** Core runs `filter_block_kses_value()` on attribute strings for users without `unfiltered_html`. Any code that turns `u003c`, `u003e`, `u0022`, `&lt;`, or HTML entities back into markup AFTER that point (in render, or after a `wp_kses_post()` call) re-opens stored XSS. Order must be: decode, then kses, then output.

**Custom sanitizers.** Treat a hand-written HTML sanitizer (regex `on\w+=` stripping, DOMDocument element removal) as unescaped output unless it ends in `wp_kses()` with an allowlist. Check that any declared allowlist is actually used. For embed code, gate raw output on `current_user_can( 'unfiltered_html' )` at save time, or use `wp_oembed_get()`.

**Global kses changes.** `add_filter( 'wp_kses_allowed_html', ... )` or `add_filter( 'safe_style_css', ... )` inside a render callback widens kses for every later `wp_kses_post()` call in the request, including other plugins. WARNING. Pass a local allowlist to `wp_kses()` instead.

## 3. Severity by Who Controls the Value

Unescaped output is CRITICAL by default. Calibrate by source:

| Value source | Severity when output unescaped |
|--------------|--------------------------------|
| Block attribute (string/object/array), editable by Contributor/Author | CRITICAL (stored XSS) |
| Remote data (HTTP fetch, third-party JSON-LD, external API) | CRITICAL |
| Request data (`$_GET`, `$_POST`) in an unauthenticated endpoint | CRITICAL |
| Post meta or terms written from block attributes | CRITICAL |
| Plugin option editable only with `manage_options` | WARNING (admins have `unfiltered_html` on single site, not on multisite) |
| Validated `number`/`integer`/`boolean` attribute | Not a finding. Recommend `absint()` / `%d` as INFO |
| Hard-coded or computed internal value | Not a finding |

## 4. Render Side Effects

A render callback runs on every view, for anonymous visitors, in REST previews, and in feeds. It must be read-only. WARNING for each of these in a render path:
- Network calls: `wp_remote_get()`, `wp_safe_remote_get()`, `file_get_contents( 'http...' )`. Slow, blocking renders. Fetch on `save_post` or via cron and cache the result.
- Writes: `wp_insert_term()`, `update_post_meta()`, `update_option()`, `media_handle_sideload()`, `wp_insert_post()`.
- Exempt: transient and object-cache reads and writes used for caching (`get_transient()` / `set_transient()`, `wp_cache_get()` / `wp_cache_set()`). The cache key must identify the item; wildcard `delete_transient()` calls do nothing.
- Global state changes: `add_filter()` / `add_action()`, assigning to `global $post` or its properties (`get_post()` returns the global instance when called without an ID), `query_posts()`, a `WP_Query` loop without `wp_reset_postdata()`.
- Recursion: nested `render_block()` or `do_blocks()` of other posts with no stack guard against self-embedding.
- Access control: rendering another post's content without `post_password_required()` and `post_status` checks.
- Fatal error risk: `global $post` read without a `WP_Post` check (null in widgets, templates, REST).
- Caching: transient keys must identify the cached item. A cache keyed by a loop index or an array position caches the wrong item.

Unbounded queries (`posts_per_page => -1`, `numberposts => -1`) and per-item `parse_blocks()` / `get_post()` in a loop: WARNING. Defer deep analysis to `/wp-performance`.

## 5. Endpoints That Feed a Block

The worst bugs often sit in the AJAX/REST handlers a block's frontend calls. Find them: `wp_ajax_nopriv_`, `wp_ajax_`, `register_rest_route` in the block's classes. Check:
- `nopriv` / public handlers: no client-supplied query args. `json_decode( $_POST['query'] )` passed into `WP_Query` is CRITICAL. Rebuild args server-side and allowlist pagination only.
- Nonce on state-changing actions (`check_ajax_referer()`).
- REST: `permission_callback` present and meaningful. Args validated by schema.
- Client-supplied `attributes` re-rendered through a template: same escaping rules as render.

Report briefly and add the security note. Defer depth to `/wp-security`.

## 6. PHP i18n

- Text domain on every `__()` / `_e()` / `esc_html__()` call.
- Translated attribute defaults and labels built during registration need the text domain loaded first. WordPress 6.7+ loads plugin translations just in time, but calls before `init` trigger a `_load_textdomain_just_in_time` notice. Bundled `/languages/` files loaded with `load_plugin_textdomain()` on `init` at the same priority as registration load too late. Load at an earlier priority, or translate when read instead of at registration.
- Output: `esc_html__()` / `esc_attr__()`, not bare `__()` in HTML.
- Units and labels (`g`, `mg`, `kcal`, `min`) translatable when they are words, not symbols.

## 7. Missing JS Source

When only compiled JS ships (`dist/`, `build/` without `src/`):
- Do not review compiled bundles for code quality.
- Mark edit/save, deprecation, apiVersion, and supports checks as **NOT VERIFIABLE** in the summary. Do not invent findings.
- Wrapper findings still apply: without `get_block_wrapper_attributes()`, the "Additional CSS class" setting (`customClassName` is on by default) and anchor are dropped on the frontend even when no supports are declared.
- Attribute type changes (e.g. string to integer) need a JS deprecation. Recommend them as INFO with that caveat.
- Ask for the JS source if edit/save review matters.

## 8. Registration from PHP

- `register_block_type_from_metadata( $path )` takes a PATH to a block.json (or its directory). Passing a block name returns false silently and the block never registers server-side (CRITICAL when the block depends on PHP render or server attributes).
- Passing `'attributes' => ...` while registering from block.json REPLACES the block.json schema on the server. Drift is common (renamed keys, extra keys, `array` vs `object` types). An associative value declared as `array` fails validation and silently resets to the default, which is why such plugins end up reading `$block->parsed_block['attrs']` unvalidated. WARNING; recommend block.json as the single schema.
- Collection registration (`wp_register_block_types_from_metadata_collection( $build_dir, $manifest )`, 6.8+): the manifest path must exist after build, the build scripts must run `--blocks-manifest` (or `build-blocks-manifest`), and `blocks-manifest.php` must list exactly the built blocks. A built block missing from the manifest never registers (CRITICAL); entries without a built block.json or with different names mean a stale manifest (WARNING). The scan checks all three.
- Blocks registered only in JS (no PHP registration) have no server-side attributes or render. Inventory them and confirm that is intended.
- Shared asset handles: when block.json names registered handles instead of `file:` paths, find each `wp_register_script()` / `wp_register_style()`, the hook it runs on, and confirm the file exists. Hard-coded dependency arrays should come from the built `*.asset.php` (`$asset['dependencies']`, `$asset['version']`). Missing entries load only transitively (WARNING); `wp-editor` / `wp-edit-post` in an editor script trigger notices in the widgets and site editors.
- `Requires at least` in BOTH the plugin header and `readme.txt` must cover the features used.

## 9. Vendored Libraries

Third-party code copied into the plugin (e.g. `simple_html_dom.php`, minified sliders, polyfills) is identified by its license header (MIT, BSD, Apache) or a known project name. The scan lists these and excludes them from line heuristics.
- Do not report line findings inside vendored files.
- Review how the plugin CALLS them: size limits (simplehtmldom refuses input over its max size and returns false, so the block renders empty), re-serialization that mangles HTML5/SVG, outdated versions with known CVEs.
- Prefer core APIs where they exist (`WP_HTML_Tag_Processor` for HTML parsing).
