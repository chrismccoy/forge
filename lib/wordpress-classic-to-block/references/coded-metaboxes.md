# Hand-Coded Metaboxes (no ACF, no CMB2)

Classic themes built without a field framework register fields with `add_meta_box()`, render HTML forms by hand, and save in one or more `save_post` handlers. There is no schema anywhere — the **save handler is the schema**. This reference covers reading those handlers, inventorying fields, and converting them. Gate 5d (`complex-metaboxes.md`) covers the editor UI patterns these recipes plug into.

Example (modeled on a real theme whose "products" are regular posts with three metaboxes and one save handler): `examples/functionality-plugin/inc/products/` and `inc/editor/product-panel.js`. Use it for repeaters, derived values, and config-driven panels; for a few scalar fields on a CPT, `register_post_meta()` + `core/post-meta` bindings (or the `event-details` block) is enough.

## Step 1 — Read the handler, not the form

Grep the theme (including `inc/`, `includes/`, `lib/`, `classes/`) for:

```bash
grep -rnE "add_meta_box|save_post|pre_post_update|edit_post|wp_insert_post|transition_post_status|wp_verify_nonce|update_post_meta|delete_post_meta|add_post_meta|get_post_meta|update_term_meta|get_term_meta|wp_nav_menu_item_custom_fields|wp_update_nav_menu_item|get_theme_mod|get_option\(" --include=*.php .
```

Themes often wrap these in one-line helpers (`mytheme_option( $key )` around `get_theme_mod()`, `mytheme_meta()` around `get_post_meta()`). The grep above finds only the wrapper's definition. Find each wrapper, then grep its name to reach every call site.

**Resolve keys first:** keys behind class constants (`Keys::META_PRICE`), `define()`, or built strings (`META_REACTIONS . '_' . $type`) are invisible to a literal grep. Resolve constants and string-built keys before inventorying; report key families with their suffix allowlist.

**Readers that write:** lazy migrations (a getter that converts a legacy key on read, a backfill cron) mean the stored shape is still changing. Inventory them, finish them in Phase 0 with a one-off command, and only then register keys or move code.

**Custom tables** (`dbDelta`, `CREATE TABLE`, `$wpdb->prefix . 'x_views'`): storage outside meta. The plugin owns them — install on activation, keep the version-check upgrade, define an uninstall policy; during coexistence exactly one side runs the install. Installs that also delete legacy meta are lazy migrations (finish them in Phase 0).

**Every writer, not only the handler:** grep importers, seeders, WP-CLI commands, and `tools/` scripts that write the same keys — they often store a different shape (serialized arrays where the reader expects JSON). Admin JavaScript is part of the schema too: grep `assets/js/admin` for `JSON.stringify` and hidden `name=` inputs; a script may reshape the POST before the handler sees it.

For each save handler record (`save_post`, `save_post_{type}`, `pre_post_update` — fires before the update and only for existing posts —, `edit_post`, `wp_insert_post`):
- **Nonce:** field name and action. One metabox often prints the nonce for several (a "Pricing" box with no nonce of its own saves only because the "Details" box printed one).
- **Keys:** every `$_POST` key read and every meta key written. Form field names and meta keys can differ (`x_headline` posted → `x_cat_headline` stored).
- **Sanitizer per key:** `sanitize_text_field`, `sanitize_textarea_field`, `wp_kses_post`, `esc_url_raw`, `absint`, `sanitize_key`, allowlist checks, clamps (`max( 0, min( 100, … ) )`).
- **Empty behavior:** stores `''` or **deletes the row**. Many coded themes delete; queries then use `'compare' => 'EXISTS'`.
- **Derived writes:** values computed from other fields (file size and format from an attachment ID).
- **Side effects:** transients deleted, caches flushed, terms set.
- **Post-type scope:** `save_post_post` vs `save_post_page`; the same key on two types with different sanitizers.

Where the save handler and a template disagree on shape, migrate from the **handler's** shape and report the mismatch.

## Step 2 — Field inventory table

One row per field, cited `file:line` (loop-generated key families may be one row with the key pattern and count). Columns: **Key**; **Storage** (post/term/user meta, theme mod, option, widget option, cookie, localStorage, transient); **Type**; **Allowed / checked value**; **Sanitizer** (core for Customizer: the setting's `sanitize_callback`); **Empty** (stored `''`, deleted, or falls back); **Shape**; **Applies to**; **Saved at** (handler or `customize_save`); **Printed at**; **Live?**; then the three migration columns. Transients and caches get rows only when they must be flushed after migration. The rows below use fictional keys and paths — cite the real ones:

| Key | Storage | Type | Allowed / checked value | Sanitizer | Empty | Shape | Applies to | Saved at | Printed at | Live? | **Target storage** | **Target control** | **Migration** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `x_featured` | post meta | checkbox | `'1'` | none (literal) | delete | scalar | post | inc/save-x.php:NN | parts/card-x.php:NN | yes | meta string `''`/`'1'` | ToggleControl | none |
| `x_icon` | post meta | select | `x_icon_keys()` | `sanitize_key` + allowlist | delete | scalar | post | inc/save-x.php:NN | parts/single-x.php:NN | yes | meta string, schema `enum` | SelectControl | none |
| `x_overview` | post meta | textarea | — | `wp_kses_post` (post) / `sanitize_textarea_field` (page) | delete | scalar | post, page | inc/save-x.php:NN | parts/single-x.php:NN, page-x.php:NN | yes | meta per post type | TextareaControl | none |
| `x_filename` | post meta | media picker | attachment ID | `absint` | delete (+ derived) | scalar | post | inc/save-x.php:NN | inc/helpers-x.php:NN | yes | meta integer | MediaUpload | derived → hooks |
| `x_terminal` | post meta | repeater | `pct` 0–100, `color` slug | per column | drop empty rows | serialized array | post | inc/save-x.php:NN | parts/single-x.php:NN | yes | meta array + schema | Repeater | none |
| `x_accent` | term meta | select | palette slugs | `sanitize_key` + allowlist | delete | scalar | category | inc/save-x.php:NN | inc/helpers-x.php:NN | yes | term meta (keep classic form) | — | none |
| `_x_menu_icon` | nav item meta | text | FA classes | custom normalizer | delete | scalar | nav_menu_item | inc/save-x.php:NN | inc/nav-x.php:NN | yes | link `className` `icon-*` | Additional CSS class | `migrate-nav-icons` |

If `/wp-demo` already produced its table for the theme, extend that table instead of re-reading the code.

**Security deviation rule:** when the classic handler saves raw `$_POST` or templates print stored values unescaped, do not port the hole — add the narrowest sanitizer that keeps valid stored values intact, escape on output everywhere, and record each deviation in the inventory (the save-without-changes identity check will flag these keys; list them as expected).

**Scope beyond metaboxes:** the inventory also covers comment meta (ratings, votes — `register_meta( 'comment', … )`), user meta read by templates, cookies used as state, widget instance options, core keys the theme reads, and data embedded in post content (shortcode attributes). Inventory hardcoded site data too — term/post/attachment IDs, category slugs, form IDs, absolute production URLs — each becomes a block attribute, a setting, or a constant.

Allowlists, sanitizers, clamps, and keys are copied **verbatim** from the theme's handler and helper functions. The example in `examples/functionality-plugin/inc/products/` shows the pattern, not the values — never copy its lists. Keep the original meta keys; rename only when unavoidable, and then add a `migrate-meta` mapping.

## Step 3 — Registration must load everywhere

Coded themes often load metabox files only in admin:

```php
if ( is_admin() || ( defined( 'REST_REQUEST' ) && REST_REQUEST ) ) {
	require 'inc/meta-boxes.php';
}
```

`REST_REQUEST` is defined during request parsing, after the theme loads, so that check is always false at include time, and `is_admin()` is false for REST. Block-editor saves are REST requests. Put `register_post_meta()` in the companion plugin on `init`, unconditionally.

## Step 4 — Legacy metaboxes inside the block editor

Applies to the hybrid path and to any interim phase where the classic theme (or its metabox code) is still active with the block editor on. In a full migration the metaboxes leave with the classic theme; ship no `remove_meta_box()` code for them.

When the block editor is enabled while the classic theme (or its metabox code) is still active, WordPress renders legacy metaboxes below the canvas. On save it sends the REST request first, then posts the metabox form to `post.php?meta-box-loader=1`, which runs the old `save_post` handler.

- **Overwrite risk:** if a sidebar panel and a legacy metabox edit the same key, the metabox POST runs second and silently restores the stale form value. Remove each metabox the moment the panel owns its keys (`remove_meta_box()` at priority 99 — see `inc/products/editor.php`), or register it with `'__back_compat_meta_box' => true` so it shows only in the classic editor.
- **Shared nonce:** when one box prints the nonce that a single handler checks for several boxes, removing that box alone silently stops the others from saving. Boxes sharing a nonce leave together, in the same deploy.
- **Interim phase (optional):** keep legacy metaboxes working inside the block editor and migrate field by field. Legal, but every migrated key must leave the old form in the same deploy.
- **Block editor disabled:** by the Classic Editor plugin, or by the theme itself (`use_block_editor_for_post` / `use_block_editor_for_post_type` filters returning false). The panel approach needs the block editor; remove the filters or deactivate the plugin when Gate 5d ships. Every existing post then opens in the block editor at once (content as Classic blocks) — schedule and announce it.

## Coexistence: plugin active beside the classic theme

Activating the companion plugin while the classic theme is still active (hybrid path, or plugin-first rollout) duplicates everything moved out of the theme.
- Never copy classic functions verbatim: same names fatal with "Cannot redeclare". Prefix plugin code (`{prefix}_func_`).
- **Namespaced, autoloaded themes** do not fatal on duplicates: whichever PSR-4 autoloader registered first wins, so the theme can silently run plugin classes. Give the plugin a distinct namespace.
- **Guard:** `'classic-slug' === get_template() && ! wp_is_block_theme()` — true only while the classic theme is active, under either slug strategy (`! wp_is_block_theme()` alone would also match an unrelated classic theme; `get_template()` alone stays true after a same-slug cut-over). Evaluate it on `after_setup_theme` and register the remaining hooks there. `class_exists( 'Theme_Walker_Nav', false )` (no autoload) is an alternative detector.
- While the guard is true, load only the **data layer** (meta registration, derived hooks, migrations). Load REST routes, shortcodes, Customizer settings, term-form fields, and JSON-LD only in full mode, or each one exists twice.
- **Same-slug cut-over fires no activation or switch events:** run installs, seeding, and cron scheduling from an idempotent version check on `admin_init` (or `init`) in full mode. Plugin **deactivation** during coexistence must not unschedule cron hooks the classic theme still owns.

## Step 5 — Reproduce the handler's storage exactly

| Classic handler behavior | Registered-meta equivalent |
|---|---|
| Empty → `delete_post_meta()` | Three parts: register a `default` (`''`, `0`, `[]`) for every key so REST does not write empty rows for untouched keys when the editor echoes the whole meta object; the panel maps `''` → `null` on edit; an `added_post_meta`/`updated_post_meta` hook deletes empty values written by any other client (REST, CLI, imports). A `sanitize_callback` cannot delete |
| Checkbox `'1'` or deleted | `type: string`, `default: ''`, sanitize truthy → `'1'`, else `''` (then deleted by the hook). No schema `enum` |
| Select whose sanitizer falls back to a default (first allowed value) | Same fallback in `sanitize_callback`; never store `''`; default registered as that value |
| Select that ignores invalid input (keeps the old value) | A `sanitize_callback` receives `( $value, $meta_key, $object_type )` — no object ID — so it cannot read the stored value. Use the `update_post_metadata` / `add_post_metadata` short-circuit filter (it receives `$object_id` and the value): return `true` to skip the write when the value is off-list. Same for term meta (`update_term_metadata`) |
| Select with allowlist function | Allowlist in the `sanitize_callback` (same function, moved into the plugin), never a REST schema `enum` or `additionalProperties: false`: the editor echoes stored values back, and one legacy off-list value fails the whole save with a 400. The editor control must still show a stored off-list value, labelled "removed on save" when the sanitizer allowlists it (the classic handler deleted it too; expect that key in save-identity diffs). Audit stored values before tightening any list |
| Number clamped 0–100 | Clamp in `sanitize_callback`; schema `minimum` / `maximum` |
| Repeater: sanitize per column, drop empty rows | `type: array` + item `properties`; `sanitize_callback` loops rows, drops empties, applies row limit |
| Same key, different sanitizer per post type | Register the key separately per post type |
| Value computed on save (match the handler's edge cases too — e.g. whether stale values are kept when the source disappears) | `added_post_meta` / `updated_post_meta` / `deleted_post_meta` hooks (`inc/products/derived.php`) — fire for REST, CLI, and code |
| Value derived from **post format, terms, or featured image** | `wp_after_insert_post` (WP 5.6+) — REST sets `format`, `featured_media`, and terms **after** `wp_update_post()` fires `save_post` (content is written before, so content-derived values such as reading time are fine on `save_post`), so a `save_post` handler reads the old state on every block-editor save (the classic `post.php` path set them first, which hid the bug). Meta hooks only when the inputs are meta. Backfill existing posts once |
| Cache/transient flushed on `save_post` | Also flush on meta hooks: REST writes meta after `save_post`, and migrations never fire it |

One field map drives both registration and the editor panel (`inc/products/fields.php` → `register.php` and `wp_add_inline_script` → `product-panel.js`), so labels, choices, and columns cannot drift.

## Step 6 — Recipes by field type

| Classic field | Target | Migration |
|---|---|---|
| Checkbox `'on'` / `'yes'` / `'true'` | `'1'`/deleted (or boolean meta) | `wp mytheme normalize-meta`; fix templates comparing `=== 'on'` |
| Score with stored label/badge/verdict | Store only the score; compute label in render | Drop the label keys after verifying |
| Image stored as URL | Attachment ID | `attachment_url_to_postid()`; log misses |
| `[gallery ids="…"]` whose list mixes attachment IDs with video URLs (a theme filter renders them) | **Data-loss trap:** `core/gallery` holds images only. Keep the shortcode (and its filter, moved to the plugin), or split into `core/gallery` + `core/embed` blocks with a migration that preserves order | Never bulk-convert without checking each list for non-numeric entries |
| Gallery via child attachments (`menu_order`) | `core/gallery` block in content, or ID-list meta + `MediaUpload` `multiple`/`gallery` | Block route: build `core/gallery` + `core/image` blocks with `serialize_blocks()` |
| `[gallery]` filtered by `post_gallery` | Keep the shortcode in old content; style `core/gallery` via `theme.json` + block CSS | Optional conversion |
| Video/audio URL in meta | `core/embed` / `core/video` in content, or keep meta + bound block | Store real duration from attachment metadata, never typed |
| Download file (attachment ID) + derived size/format | Integer meta + derived hooks; render via dynamic block or `core/file` | None |
| Colour stored as a named data slug (`emerald`) → dynamic utility class (`bg-{slug}-400`) | Keep the stored data. Do **not** add colour-named slugs to the theme palette (role-based rule). Map data slug → colour in render code: plugin CSS custom properties (`.has-accent-emerald{--accent:…}`), `settings.custom.accent.emerald` (→ `--wp--custom--accent--emerald`), or a safelisted utility build scoped to plugin blocks | Audit stored values; map off-list ones |
| Colour as hex | `ColorPalette` limited to theme colours; store slug if variations must restyle it | Map hex → nearest slug or keep hex |
| Date in `d/m/Y` or free text | `Y-m-d` string, `DatePicker` / `type: date` | `normalize-meta` repeater date rule |
| Repeater as one row per value (`add_post_meta` duplicates) | `single => false` registration | None; editor sends an array |
| Repeater as JSON string or comma list | Real array meta — **after** the classic fallback is retired (the classic reader expects the string) | Audit first: `update_post_meta( $id, $k, wp_json_encode( … ) )` without `wp_slash()` is unslashed by `update_metadata()`, so `\"` becomes `"` and `\uXXXX` becomes `uXXXX` — those rows fail `json_decode` silently. Find them (`SELECT post_id, LEFT(meta_value,2) FROM wp_postmeta WHERE meta_key='k'` plus a decode scan), repair, then convert. While the fallback lives, keep the string shape and register it as `type: string` |
| Counter (views, votes, likes) | Meta kept, readable in REST, not writable through post saves (`auth_callback` false) so the editor's echoed meta cannot overwrite concurrent increments; increments through a plugin REST endpoint. If admins must correct the count, give it a separate admin-only control that writes through that endpoint | Move AJAX incrementers to `register_rest_route` |
| Embed/iframe code textarea | `core/embed` with a URL field | Extract `src` URLs; never migrate raw HTML (needs `unfiltered_html`) |
| Per-post custom CSS/JS | Drop; global Additional CSS for real needs | Report keys; never migrate code |
| Theme SEO title/description | SEO plugin fields | Plugin's importer or a meta-key copy; plugin territory |
| Layout metabox (sidebar left/right/none, full width, hide title) | `customTemplates` + `_wp_page_template` | `wp mytheme migrate-layout` |
| Field shown only for a page template | Panel condition `getEditedPostAttribute( 'template' )`; branch on `getEditedPostAttribute( 'slug' )` too when visibility follows the page slug | Keep `_wp_page_template` values while the classic fallback exists (see `template-conversion.md` → Code around page templates) |
| Field shown only for a post format | Panel condition `getEditedPostAttribute( 'format' )` | None |
| "Paid only" / driven by another field | Panel condition on that field's value | None |
| Term meta (select / text) | Keep classic term-form fields (move to plugin); register with `show_in_rest` | Fix form-name vs meta-key mismatches while moving |
| Nav menu item meta (icon) | `className` with `icon-*` markers + `render_block` filter | `wp mytheme migrate-nav-icons <menu> <navigation>` after "Import Classic Menus" |

## Display: section blocks in the template, not one block per post

Three layers, kept separate as in the classic theme:

| Layer | Classic | Block theme |
|---|---|---|
| Data | Post meta | Same meta, same keys |
| Editing | Metaboxes | Sidebar panels (`PluginDocumentSettingPanel`) |
| Display | `template-parts/content-single-x.php` | Several dynamic **section blocks** in `single.html` (or `single-{type}.html`), each reading `postId` context |

Split the classic display template into one block per visual section (header/meta row, preview, tabs, sidebar, download). Each block renders nothing when its fields are empty, mirroring the classic `if` checks. Layout changes then happen once in the Site Editor for every post.

Do not put one "product" block into each post's content: it copies the layout into every post, so a design change becomes a content migration. Put blocks in content only when the layout varies per post (editor-built lists such as event sessions).

## Per-item conditional styling in loops

A meta value that changes a card's classes (a "featured" product rendered as a dark card) cannot be expressed by core post-template blocks. Options, simplest first:
1. `post_class` filter in the **plugin** (the meta belongs to the plugin; keep theme PHP free of plugin data) — `core/post-template` renders each item with `get_post_class()`, so `add_filter( 'post_class', fn( $c, $cls, $id ) => '1' === get_post_meta( $id, 'x_featured', true ) ? array_merge( $c, array( 'is-featured' ) ) : $c, 10, 3 )` adds a class the theme styles.
2. A dynamic card block reading `postId` context (when markup, not just classes, changes).

**Listing threshold:** when the main-query layout reorders, groups, or inserts non-post items (cards chosen by a site option, regrouped chunks, a sponsor card every N items), use one dynamic listing block that renders the global main query (core pagination still works). For insert-every-N alone, a `render_block_core/post-template` filter inserting markup between `<li>` items is enough.

Position-driven variation (the first post of an archive rendered as a featured card): `core/post-template` cannot vary by position, and `offset` breaks `inherit: true` pagination. Style the first item on page one only — `body:not(.paged) .wp-block-post-template > li:first-child` — or, when markup differs, a dynamic card block that keeps a static per-request counter and renders the featured markup for the first item when not paged.

## Structured edit screen on the core `post` type

When the "products" are regular posts, there is no `register_post_type()` call to add `template` to. Use the args filter:

```php
add_filter( 'register_post_type_args', static function ( array $args, string $type ): array {
	if ( 'post' === $type ) {
		$args['template']      = array( array( 'mytheme/product-hero' ), array( 'core/paragraph' ) );
		$args['template_lock'] = false; // A starting layout only; existing posts are unaffected.
	}
	return $args;
}, 10, 2 );
```

## Media output filters vs media blocks

Themes that restyle media through `wp_video_shortcode`, `wp_audio_shortcode`, `wp_playlist_shortcode`, `post_gallery`, or `post_thumbnail_html` keep working for **old** shortcode content — but new posts written in the block editor use `core/video`, `core/audio`, `core/gallery`, which never pass through those filters. The regression is invisible in a parity run on old content.
- Pair each filter with `render_block_core/video` / `audio` / `gallery` (read `src`/IDs with `WP_HTML_Tag_Processor`) sharing one renderer.
- Code that scans content for `[video` or `[gallery` must also parse blocks (`has_block()`, `parse_blocks()`, `get_post_galleries()` covers both).
- **`embed_oembed_html` / `oembed_dataparse` are the exception — they DO run for `core/embed`** (autoembed processes the URL inside `.wp-block-embed__wrapper`). A theme wrapper (`.video-wrapper` with its own 56.25% padding) then nests inside core's `figure.wp-has-aspect-ratio` (block themes get `responsive-embeds`), doubling the height. Scope the filter to non-block content, or unwrap inside `render_block_core/embed`.
- Test data must include block-content variants, not only shortcodes.

## Step 7 — Post-format branching

Three cases — decide which one the theme has:
- **Style only** (title size, spacing per format): core already emits `single-format-{slug}` on `<body>` and `format-{slug}` on each `post-template` item — CSS only, no block.
- **Media swap:** formats differ only in the media element → one `format-media` block (below).
- **Card structure differs** (no title on some formats, meta before or after content, avatar + author on status, media first on video) → one dynamic **format card** block rendered inside `core/post-template` that branches its whole markup on `get_post_format()`, with `postId` context. Prefer one card block over per-format block variations: the Query Loop cannot pick a variation per item. When the layout is **format × a per-post layout meta × an option default**, give the card or single block a resolved `layout` (meta, else option) and branch on both. When media is pulled out of the content for a header and must be suppressed inside it, scope a `render_block_core/post-content` filter (remove the first `core/gallery` / gallery shortcode output) to that view instead of a global shortcode swap. Keep the classic single-vs-loop difference (a single view may use a different card than the loop) as a block attribute (`context: "single" | "loop"`).


Coded themes often route by format: `get_template_part( 'content', get_post_format() )`, with format-specific meta (video URL only on video posts). Block themes have no single-post template per format, and the Query Loop cannot branch on format.

Use one dynamic block that branches in PHP and drop it into `single.html` and the Query Loop's post template:

```php
// render.php of mytheme/format-media
$post_id = $block->context['postId'] ?? get_the_ID();
switch ( get_post_format( $post_id ) ) {
	case 'video':
		$url = (string) get_post_meta( $post_id, 'mytheme_video_url', true );
		echo $url ? wp_oembed_get( esc_url_raw( $url ) ) : get_the_post_thumbnail( $post_id, 'large' );
		break;
	case 'gallery':
		// The gallery the author chose (ids and order), not every attached image.
		$galleries = get_post_galleries( $post_id, false );
		$ids       = $galleries ? wp_parse_id_list( $galleries[0]['ids'] ?? '' ) : array();
		foreach ( $ids as $id ) {
			echo wp_get_attachment_image( $id, 'medium' );
		}
		break;
	case 'quote':
		// Format-specific meta or content rendering.
		break;
	default:
		echo get_the_post_thumbnail( $post_id, 'large' );
}
```

Archives per format still work through the hierarchy (`taxonomy-post_format-post-format-video.html`).

## Step 8 — Migration commands

`examples/functionality-plugin/inc/cli-migrations.php`:

| Command | Purpose |
|---|---|
| `wp mytheme normalize-meta [--dry-run]` | Checkbox values → `'1'`, media URL → ID, repeater dates → `Y-m-d`. Idempotent |
| `wp mytheme migrate-meta [--dry-run]` | Renamed keys (old → new map) |
| `wp mytheme migrate-sessions [--dry-run]` | Serialized repeater → child blocks in content |
| `wp mytheme migrate-layout [--dry-run]` | Layout meta → `_wp_page_template` |
| `wp mytheme migrate-nav-icons <menu> <navigation> [--dry-run]` | Menu-item icon meta → Navigation link classes |
| `wp mytheme migrate-widgets <sidebar-id> <part-slug> [--source=live\|theme-mods:<slug>] [--theme=<target>] [--file=<path>] [--dry-run]` | Widget instances in one sidebar → database copy of the replacing part |

Run each with `--dry-run` first, then for real, then flush caches (`wp transient delete --all` or the theme's own keys) — direct meta updates bypass `save_post`-based flushing unless the derived/flush hooks are active.

## Step 9 — Test with real field coverage (wp-demo loop)

Optional: uses `/wp-demo`, a separate command in this plugin. **If it has not been run for this theme and the user does not want it run, skip to the manual alternative in the next sentence and ignore the rest of this step.** A test-data importer the theme ships itself is a dependency: update it in Phase 1 (plugin function names, Classic Editor assumption, block-content variants of media) or it breaks with the migration. It must run against both stacks (classic for baselines, new for parity): resolve functions at runtime — prefer `x_func_name()` when the plugin is in full mode, else the classic `x_name()`; call the save handler when present, else `update_post_meta()`. Without it, build a test-content list by hand from the field inventory — one item per field state (empty, typical, extreme, maximum rows) — and follow the same steps.

`/wp-demo` builds an importer that fills every hand-coded field in every state (empty, occasional, extremes, maximum rows). Use it to test the conversion:

1. On a throwaway site with the **classic** theme: run the wp-demo importer (`wp eval-file demo/demo-import.php seed=1`).
2. Record visual baselines (`examples/tools/visual-regression.spec.js --update-snapshots`) and export meta: `wp post meta list <id> --format=json` for one item of each kind.
3. Activate the companion plugin, run the migration commands, activate the block theme.
4. Run the visual regression suite; diff the meta exports (only intended keys changed).
5. Open each item kind in the block editor: every panel shows the imported values; saving without changes leaves meta identical (`wp post meta list` before and after).
6. wp-demo's `purge` resets the site for the next run.

Save-without-changes identity (5) is the key check (ignore core bookkeeping keys added by any REST save: `_pingme`, `_encloseme`, `footnotes`, `_edit_lock`, `_edit_last`): it proves the registered sanitizers reproduce the classic handler.
