# Gates 5, 5b, 5c — Business Logic → Companion Plugin

**Plugin name:** name it after the product or the original theme slug (`{original-slug}-functionality`) — it runs beside both the classic and the block theme during coexistence, so it must not be named after a new slug.

Complete example plugin: `examples/functionality-plugin/`.

## Gate 5 — What moves to the plugin

Classic `functions.php` often holds code that vanishes on theme switch. Move all non-presentation code to `{original-slug}-functionality/` (sibling directory, deployed as a separate plugin).

| Classic `functions.php` code | Moves? | Rationale |
|---|---|---|
| `register_post_type()` / `register_taxonomy()` | Yes | Content structure must survive a theme switch |
| `add_meta_box()` registrations | Yes | Data capture, not presentation — Gate 5b |
| `register_rest_route()` | Yes | API contracts must not depend on the active theme |
| AJAX handlers (`wp_ajax_*`) | Yes | Business logic |
| `add_shortcode()` | Yes | Content-level, theme-agnostic — Gate 5c |
| Third-party integrations (newsletter, payment, CRM) | Yes | Data layer |
| ACF field group registration (`acf_add_local_field_group`) | Yes | Data — see ACF note |
| `wp_enqueue_scripts` for theme styles/fonts | No | Theme assets |
| `add_theme_support()` | No — mostly remove | Block themes add `post-thumbnails`, `responsive-embeds`, `editor-styles`, `html5`, `automatic-feed-links`, title tag automatically. `custom-header`, `custom-background`, `widgets` do nothing — remove. |
| `register_nav_menus()` / `register_nav_menu()` | Remove | No menu locations in block themes; classic menus are imported by the Navigation block |
| Image sizes (`add_image_size`) | No | Presentation |
| `register_sidebar()` / widgets | Remove | Replace widget areas with template parts or patterns (`site-state-migration.md`) |
| `register_block_style()` (CSS only) | Remove | Becomes a section style JSON (`style-variations.md`) |
| `register_block_pattern()` | Remove | Becomes a `patterns/*.php` file |
| Feed removal, XML-RPC off, emoji removal, generator tag, REST discovery links, speculation rules | Yes | Site policy, not presentation |
| `remove_action( 'rest_api_init', 'wp_oembed_register_route' )` | Delete | Removes `/oembed/1.0/proxy`; `core/embed` previews break in the block editor |
| `use_block_editor_for_post*` / `use_widgets_block_editor` filters, dequeued block CSS, unhooked global styles | Delete | Block-feature sabotage; never ported (SKILL.md Gate 0) |
| `add_rewrite_rule` / `add_rewrite_tag` / `add_rewrite_endpoint` / `query_vars` (endpoint URLs such as `/rtf/x/page/N/` are contracts; check `core/query-pagination` builds matching links), rewrites coupled to page slugs (`pagename=x`) | Yes | URL contracts; check CPT-slug vs page-slug collisions (`/downloads/` as both); never flush on every request or version check at `init` — flush on activation and after slug changes |
| `add_feed` + feed templates, `pre_get_posts` / `posts_clauses` / `the_posts` query changes, core sitemap filters | Yes — except query changes that exist only to fit the theme's own layout (posts per page for a 6-3-6 grid, sticky pinning for that grid), which stay in the theme | Site behavior |
| `wp_headers` / `send_headers` (CSP, security headers), `map_meta_cap` / capability maps | Yes | Site policy; see `legacy-features.md` → Content-Security-Policy |
| Theme SEO stack: page-type JSON-LD, canonical/OG/robots, aggregate ratings from meta | Yes (or an SEO plugin) | Block templates render before `wp_head`, so a block's `render.php` can queue head output (JSON-LD, meta) for that page. Consequence: existing `wp_head` callbacks run **after** the loop — `have_posts()` is false, globals may be moved; use `get_queried_object_id()`, `$wp_query->post_count` / `found_posts`, never loop functions. Diff `<head>` per view at Gate 6. Do not build head output from caches written later in the same request (ordinary fragment caching and transients on GET are fine) |
| Custom database tables (`dbDelta`, `CREATE TABLE`) and their version-check installs | Yes | Activation owns the install; uninstall policy; one installer during coexistence (`coded-metaboxes.md` → Custom tables) |
| Theme-defined hooks (`apply_filters( 'x_*' )`, `do_action( 'x_*' )`) | Yes, names unchanged | A public API: mu-plugins and child code hook them; rename functions, never hook names |
| WP-Cron (`wp_schedule_event`, `wp_schedule_single_event`, `wp_next_scheduled`) | Yes | Schedule on plugin activation, unschedule on plugin deactivation. `wp_next_scheduled( 'hook' )` without args misses events queued **with** args (a classic batch chain `[110]`): scan `_get_cron_array()` for the hook with any args before scheduling, or a duplicate chain starts at cut-over. **Rename functions, never hook names** — queued events fire by hook name. The classic theme's `switch_theme` unscheduler deletes the plugin's schedule at cut-over: neutralize it first, then re-check `wp cron event list` after every theme switch |
| Theme lifecycle hooks (`after_switch_theme`, `switch_theme`): seeders, flushes, cron scheduling, writes to core options, onboarding redirects | Yes, rewritten | They never fire from a plugin, and left in the classic theme they re-run on every fallback switch. Move to `register_activation_hook` plus idempotent WP-CLI seeders; test switching to the fallback and back |
| Admin tool screens (setup wizards, importers, tools runners, moderation queues, dashboard widgets, row actions, menu-order filters) | Yes, unchanged | Not presentation; move as is, prefixed |
| Taxonomy/CPT rewrite bases colliding with core bases (`category`, `tag`, `author`, `search`, `page`) | Fix while moving | Custom rules on a core base shadow core archives |
| Privacy exporters/erasers (`wp_privacy_personal_data_exporters`/`_erasers`), policy text (`wp_add_privacy_policy_content`), PII retention cron | Yes | Audit new meta and tables for exporter coverage (meta added by the migration needs an exporter too) |
| Virtual files and custom feeds: `robots_txt` filter, `/llms.txt`-style rewrites, custom XML sitemaps outside `wp-sitemap` | Yes | URL contracts; keep paths identical |
| Image-format negotiation (`Vary: Accept`, URL swaps) and media features core now has (EXIF rotation, big-image threshold) | Keep only what core lacks | Delete duplicates of core behavior; keep negotiation in the plugin with cache rules |
| Theme admin help tabs, docs, dashboard widgets describing classic screens (Menus, Widgets, Customizer) | Rewrite or delete | They go stale at migration; list as a deliverable |
| Admin list-table columns, `restrict_manage_posts` filters, dashboard glance items, media/upload tweaks (`big_image_size_threshold`) | Yes (`inc/admin.php`) | Admin behavior, not presentation |
| UI-only metaboxes that duplicate block-editor UI (a category picker) | Delete | Obsolete in the block editor |
| Metaboxes that drive their own REST/AJAX writes (a video frame picker) | Keep as legacy boxes, or port to a panel | They store through their own route; deleting them removes a working tool |
| `template_redirect` redirects (disabled search, 404 → home) and endpoint templates (a page that streams a file) | Yes | Site policy; record SEO effects |
| Integration hooks tied to IDs or URLs (form-plugin form/field IDs, cache-plugin filters with production URLs) | Yes, IDs as settings or constants | Hardcoded IDs break portability |
| Form POST handling inside a template (before `get_header()`) | Yes | Move to `template_redirect` or `init` in the plugin; keep the no-JS POST fallback working |

**ACF note:** When ACF PRO 6.3+ is installed, do NOT migrate ACF fields to `register_post_meta()`. ACF 6.3+ registers its own Block Bindings source (`acf/field`). Migrating creates a redundant parallel meta layer. Apply Gate 5b only to raw `add_meta_box()` fields. On ACF < 6.3, recommend upgrading over re-implementing.

**Form-only CPT** (no `editor` support, fields in a metabox, staff-authored): either keep it on the classic screen as a recorded `static-checks:allow` exception, or flip `show_in_rest` and move the fields to a panel (3–4 h). If other block-editor UI needs the CPT in REST (a picker), flip it.

### Plugin dependency model

Decide which model applies before building templates:

| Model | When | Rule |
|---|---|---|
| **CPT model** | Business content is a custom post type | Theme works fully without the plugin; plugin blocks only in CPT templates (below) |
| **Core-post model** | Business content lives on core `post`/`page` (e.g. products as posts) | Plugin blocks must appear in `single.html`, home/archive loops, and usually header/footer parts. Usually: accept and document the dependency. `register_block_template()` (WP 6.7+) only helps when the theme ships **no** template of the same slug — theme files take precedence — which moves the design into the plugin; template **parts** cannot be plugin-registered at all. Minimum plugin-off behavior: no fatal, parts render, an admin notice explains the missing plugin |

WordPress.org themes must use the CPT model or plugin-registered templates. For a single client site built "to WordPress.org standards anyway", the core-post dependency wins; record it as a deviation.

**Build order:** build and activate the plugin first (data layer, then blocks), then the theme. See `coded-metaboxes.md` → Coexistence for running the plugin beside the classic theme.

### Theme must work without the plugin (CPT model)

The plugin is optional for the theme (WordPress.org rule, and basic robustness):
- Plugin blocks (`mytheme/event-schedule`) appear only in CPT-specific templates (`single-event.html`, `archive-event.html`) — never in `index.html`, `single.html`, `page.html`, parts, or general patterns. With the plugin off, those templates are never used because the CPT does not exist.
- No theme PHP calls plugin functions. If unavoidable, guard with `function_exists()`.
- Bindings to plugin-registered meta render the placeholder text when the plugin is off; keep placeholder text neutral or empty.
- Smoke-test with the plugin deactivated (Gate 6).

**Retire classic leftovers:** transients and options the classic theme cached (`{prefix}_uses_fa`-style flags, download caches) are deleted on plugin activation. A plugin with no CPTs does not need `flush_rewrite_rules()`.

### Plugin scaffold

`examples/functionality-plugin/mytheme-functionality.php`:
- Requires `inc/*.php` at include time. Each module only registers hooks.
- Do not defer `require_once` to `plugins_loaded`. That hook has already fired when a plugin is activated, so functions called from `register_activation_hook` would be undefined (fatal error on activation).
- Activation: register CPTs, then `flush_rewrite_rules()`. Deactivation: flush again.
- `inc/cli-migrations.php` loads only under WP-CLI.

CPT example: `inc/post-types.php`. Set `show_in_rest => true` (block editor; classic registrations often have `false`) and `'custom-fields'` in `supports` (needed for registered meta to reach REST / Block Bindings).

## Gate 5b — Metabox → block migration

Metaboxes have no direct block-editor equivalent: admin UI, storage, and front-end rendering each need re-architecture. Treat every metabox as a mini-project.

### Step 1 — Classify each field by data shape

| Field type | Block-era equivalent | Complexity |
|---|---|---|
| Single text/textarea/number/URL/checkbox **rendered unconditionally** | `register_post_meta()` + `core/post-meta` binding | Low |
| Single field with a hidden-when-empty wrapper, fallback value, prefix/suffix ("v1.2"), or class switch | `register_post_meta()` + dynamic block (bindings cannot hide wrappers, fall back, or switch classes) | Medium |
| Single image/file picker | `register_post_meta()` (store attachment ID) + binding on `core/image` `url`/`alt` via custom source | Medium |
| Select/radio (fixed options) | `register_post_meta()`, allowlist in `sanitize_callback` (no schema `enum`; see `coded-metaboxes.md` Step 5) + binding | Medium |
| Repeater (multiple rows) | Dynamic block with `render.php` — bindings do not support arrays | High |
| Relationship (post-to-post) | Dynamic block, or Query Loop with `query_loop_block_query_vars` filter | High |

Score with Gate 1's Impact² / Effort. Registration → PLUGIN bucket; rendering/UI → MANUAL bucket.

### Step 2 — Replace registration

- Before: `examples/classic/metabox.php` (`add_meta_box` + nonce + `save_post`).
- After: `examples/functionality-plugin/inc/post-meta.php`.

One `register_post_meta()` call replaces the metabox UI, the nonce handling, and the `save_post` handler. WordPress handles storage, REST exposure, sanitization, and capability checks. `show_in_rest => true` is mandatory — bindings fail silently without it.

Audit `auth_callback` per field. Classic metaboxes often hide field-level capability rules inside the render callback.

### Step 3 — Bind the field to a block

**Option A — Low/Medium: Block Bindings (WP 6.5+).** Bind native blocks to meta with the built-in `core/post-meta` source. No custom PHP needed:

```html
<!-- wp:paragraph {"metadata":{"bindings":{"content":{"source":"core/post-meta","args":{"key":"event_venue"}}}}} -->
<p></p>
<!-- /wp:paragraph -->
```

Full template: `examples/block-theme/templates/single-event.html`.

- Bindable attributes: `core/paragraph` `content`, `core/heading` `content`, `core/image` `url`/`alt`/`title`, `core/button` `url`/`text`/`linkTarget`/`rel`.
- WP 6.5–6.6: bindings are code-only. WP 6.7+: editors connect fields in the block sidebar UI and edit bound values inline.
- Register a custom source (`examples/functionality-plugin/inc/block-bindings.php`) only when the value must be computed or formatted.
- Keep block comment JSON on one line.

**Option B — High: dynamic block.** For repeaters and relationships, register a dynamic block in the plugin:
- `inc/blocks/event-schedule/block.json` (`render: file:./render.php`, `editorScript: file:./editor.js`, `usesContext: ["postId"]`)
- `inc/blocks/event-schedule/render.php`
- `inc/blocks/event-schedule/editor.js` + `editor.asset.php` — minimal `registerBlockType` with `ServerSideRender` preview, no build step. Without an editor script the Site Editor reports the block as unsupported. In template editing there is no current post, so the preview renders empty; that is expected — but never send a non-numeric `post_id` (the Site Editor's `theme//slug`), which makes the renderer fail with HTTP 400 ("Error loading block"). With many dynamic blocks, register one shared script handle (`wp_register_script( 'x-blocks-editor', … )`) and name it in every `block.json` (`"editorScript": "x-blocks-editor"`); the script loops `registerBlockType( name, { edit, save } )` over the server-bootstrapped block names instead of shipping one file per block. A data-driven generic edit component works well: PHP passes attribute hints per block (control type: `SelectControl`, `TextareaControl`, `RangeControl`, `MediaUpload`), the shared script renders `InspectorControls` from them plus a `ServerSideRender` preview, and uses `useInnerBlocksProps` when the block declares `allowedBlocks` — about 120 lines covered 35 blocks in a real migration.
- `inc/blocks.php` (`register_block_type()`)

Insert `<!-- wp:mytheme/event-schedule /-->` in the template or pattern. Any custom `WP_Query` lives in the render file — never in theme templates.

### Step 4 — Migrate data for renamed meta keys

**Default: keep the existing key, underscore included** (SKILL.md: keep original keys). Protected (`_`-prefixed) keys need an explicit `auth_callback` and cannot use `core/post-meta` bindings — render them with a custom binding source or a dynamic block. Rename only when unavoidable; the rest of this step covers that case.

Classic metaboxes often use underscore-prefixed keys (`_event_venue`) to hide them from the Custom Fields panel. When the new registered key drops the underscore, existing content must be copied — re-registering does nothing for existing posts.

`examples/functionality-plugin/inc/cli-migrations.php` provides `wp mytheme migrate-meta [--dry-run]` with an old→new key map. Run `--dry-run` first, then for real, then spot-check.

Alternative: keep the underscore key and register it as is (`register_post_meta( 'event', '_event_venue', … )` with `show_in_rest` and an `auth_callback`). This avoids data migration, but the built-in `core/post-meta` binding source refuses protected (underscore-prefixed) keys and renders only the placeholder. Bind such keys through a custom source (`inc/block-bindings.php`) or a dynamic block instead. Choose this route only when content volume is large or other systems read the old key.

### Beyond simple fields

Options, conditional fields, repeaters edited in the editor, relationships, media pickers, validation, site-wide options, and term/user meta: **Gate 5d** (`complex-metaboxes.md`).

## Gate 5c — Shortcode → block bridge

Themes with metaboxes usually also have shortcodes consuming that meta. Moving shortcode PHP into the plugin is necessary but not sufficient: shortcodes are a content-authoring regression in the block editor.

Approach:
1. Build the forward-facing version as a dynamic block (Gate 5b Option B).
2. Keep the shortcode only as a backward-compatibility shim for existing content, delegating to the block via `render_block()` — one render path.

Shortcode tags:
- Generic tags (`[product]`, `[download]`, `[features]`) collide with WooCommerce, EDD, and others once they live in an always-on plugin. Always register prefixed aliases (`[x_product]`); register the bare legacy tag only if free, checked late (`init` priority 20+, after other plugins register on priority 10). Existing content using a taken bare tag renders the other plugin's output — list affected posts (`wp db query` LIKE search) and migrate them to the prefixed tag.
- **Shortcodes expanded before `wpautop`** (a `the_content` filter at priority < 10 that runs `do_shortcode` on selected tags — common for `[code]`, `[table]`, `[tabs]`): in block content that pass runs over serialized blocks before `do_blocks`, and `core/shortcode` then runs `wpautop` over the result, injecting `<p>`/`<br>` into tables and lists. Keep the pass for Classic content; route new content through dynamic blocks (or override `render_block_core/shortcode` for those tags).
- **Core static blocks are valid shim targets:** `render_block()` of a parsed `core/pullquote`, `core/buttons`, or `core/details` (with `innerHTML`) plus a block style keeps one render path without a plugin block.
- **Wrapper shortcodes** (`[features]…[feature]…[/features]`): the shim builds the parent block with pre-rendered children in `innerHTML`/`innerContent` so the parent's `$content` is filled, and strips wpautop debris (`<p>`, `<br />` between child tags) from the enclosed content first.
- Purely presentational shortcodes (callouts, stat rows, pros/cons) often fit better as patterns or core-block compositions than as dynamic blocks.

Example: `examples/functionality-plugin/inc/shortcodes.php`. `render_block()` returns the HTML string; return it directly. Wrapping it in `ob_start()`/`ob_get_clean()` without echoing produces empty output.

Find existing shortcode usage before deciding on removal:

```bash
wp db query "SELECT ID, post_type FROM $(wp db prefix)posts WHERE post_content LIKE '%[event_schedule%' AND post_status <> 'trash'"
```
