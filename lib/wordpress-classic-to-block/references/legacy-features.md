# Legacy Features: Content, Front-end JS, Widgets, Menus

## Existing post content (Classic editor)

Posts written in the Classic editor have no block markup. They load as a single `core/freeform` (Classic) block and render unchanged.

Inventory:
```bash
wp db query "SELECT post_type, COUNT(*) FROM $(wp db prefix)posts WHERE post_status IN ('publish','draft','future','private') AND post_type IN ('post','page') AND post_content NOT LIKE '%<!-- wp:%' AND post_content <> '' GROUP BY post_type"
```

Options:
| Option | When |
|---|---|
| Leave as Classic blocks | Default. Output is identical; editors convert per post via "Convert to blocks" when they next edit |
| Convert key pages by hand | Home, landing, and high-traffic pages that need block layouts |
| Bulk convert with a converter plugin | Large archives with simple markup; review a sample first — conversion can change markup and break layouts |

Also:
- Deactivate Classic Editor / Disable Gutenberg plugins, or the block theme's patterns and bindings are unusable.
- `[gallery]`, `[caption]`, `[embed]` keep working in Classic blocks; convert to blocks only when editing.
- `<!--more-->` maps to `core/more`; `<!--nextpage-->` to `core/nextpage`.
- Inline styles and `<font>` tags in old content override `theme.json`; flag if widespread.

## Front-end JavaScript

Classic themes enqueue jQuery plugins globally (sliders, tabs, accordions, sticky header, mobile menu). In a block theme:

| Classic script | Replacement |
|---|---|
| Mobile menu toggle | Navigation block overlay (`"overlayMenu":"mobile"`) — delete the script |
| Accordion / FAQ toggle | `core/details` block — delete the script |
| Tabs, sliders, filters, "load more" | A plain per-block `viewScript` port of the existing script (same per-block loading, no rewrite risk). Rewrite with the Interactivity API only when it pays off: shared state across blocks, client-side navigation, or server-rendered state that must hydrate |
| Sticky header | `position: sticky` on the **template-part block** (`className` on `wp:template-part`), not on the part's root group — the part wrapper is exactly as tall as its contents, so a sticky child has no room to stick. Offset for the admin bar (`top: var(--wp-admin--admin-bar--height, 0)`) |
| Smooth scroll, lazy load | CSS `scroll-behavior`; native `loading="lazy"` (core adds it) |
| Analytics, tracking | Plugin, not theme |

No-build Interactivity API module (WP 6.5+ resolves `@wordpress/interactivity` through the import map):

```json
// block.json
"supports": { "interactivity": true },
"viewScriptModule": "file:./view.js"
```

```js
// view.js — ES module, no build step
import { store, getContext } from '@wordpress/interactivity';

store( 'mytheme/toggle', {
	actions: {
		toggle() {
			const ctx = getContext();
			ctx.isOpen = ! ctx.isOpen;
		},
	},
} );
```

```php
// render.php
<div <?php echo get_block_wrapper_attributes(); ?>
	data-wp-interactive="mytheme/toggle"
	<?php echo wp_interactivity_data_wp_context( array( 'isOpen' => false ) ); ?>>
	<button data-wp-on--click="actions.toggle" data-wp-bind--aria-expanded="context.isOpen">…</button>
	<div data-wp-bind--hidden="!context.isOpen">…</div>
</div>
```

Add `view.asset.php` returning `array( 'dependencies' => array( '@wordpress/interactivity' ), 'version' => '1.0.0' )`. Module scripts load only where the block renders. Do not enqueue jQuery from the theme.

## Custom widgets (`WP_Widget` classes)

Full migration path, per widget type. **Run the conversion before activating a block theme with a new slug** — activation moves every instance to `wp_inactive_widgets`; afterwards the old layout survives only in `theme_mods_{old-slug}['sidebars_widgets']['data']`.

0. **Decide shared widget chrome first:** when every widget prints the same header or frame (a helper like `x_widget_header( $label, $status )`), choose once: a wrapper `core/group` with a block style around each core block (the command's `$group` helper), or one plugin `widget-frame` block with `InnerBlocks`; plugin widget blocks then take the same `label`/`status` attributes so the sidebar stays uniform. Mapping widgets one by one to core blocks otherwise drops the chrome from some of them.
1. **Map to core first:** tag cloud → `core/tag-cloud`; social links → `core/social-links` (check its services list); recent posts → Query Loop or `core/latest-posts`; search, archives, categories → their core blocks. Common **custom** widget kinds with core targets: image + link "ad" → `core/image` with a link and a block style; page list → `core/page-list`; category dropdown → `core/categories` with `displayAsDropdown`; recent/random posts with thumbnails → a Query Loop variation (random order or "has thumbnail" via `query_loop_block_query_vars`). Link Manager bookmarks have no core block.
2. **Otherwise a plugin dynamic block** reusing the widget's render logic; widget form fields become block attributes.
3. **Convert stored instances:** `wp mytheme migrate-widgets <sidebar-id> <part-slug> [--source=live|theme-mods:<slug>] [--theme=<target>] [--file=<path>] [--dry-run]` — before the switch use `--theme=<new-slug>` (the active theme is still the classic one); after it, `--source=theme-mods:<old-slug>` — (`examples/functionality-plugin/inc/cli-migrations.php`) reads `sidebars_widgets` + `widget_{id_base}`, maps each instance with a callable that returns the full block list — **including or omitting the title itself** (widgets that print their own title or a default title must not get an extra heading; horizontal ads print none) — and saves a **database copy** of the part. Instances carry site-specific IDs and URLs, so the result never goes into a theme file.
4. **Interim bridge — not cheap:** `core/legacy-widget` renders a widget class only while it is registered, so the plugin must carry the class and every helper it calls (often a cache layer, walkers, query helpers — the full "module moved unchanged" cost). Core's renderer reads only `instance.encoded` + `instance.hash` (`base64_encode( serialize( $i ) )`, `wp_hash( serialize( $i ) )`, site salts — valid only on that site); `raw` is for the editor. It renders through `the_widget()`, which sets every instance number to `-1` (cache keys and element IDs built from `$this->number` collide) and uses default `before_widget`/`after_widget` wrappers, not the sidebar's.
5. **Code that reads widget options outside the widget** (a cron precomputing from `widget_x` settings, an `update_option_widget_x` hook): after conversion those settings live in block attributes inside part database copies. Re-source them — scan the part's blocks, register on save (`save_post_wp_template_part`), or compute on miss and cache.
6. **Widget-specific CSS** printed in `wp_head` behind `is_active_widget()` moves to the block's own stylesheet. Per-item icon classes on list widgets use the same `icon-*` + render-filter approach as navigation links (`render_block_core/categories`, `render_block_core/page-list`).
7. **Cookie- or user-driven widgets** (a "liked posts" list) are uncachable fragments; render them client-side or exclude them from page caching.

Transforms from `core/legacy-widget` (the editor gets `instance.raw` only for widgets registered with `'show_instance_in_rest' => true`; transforms are moot when the theme disabled the widgets block editor, because no `core/legacy-widget` blocks exist then):

- Rebuild each widget as a block in the companion plugin (dynamic block reusing the widget's render logic).
- Add a transform so existing Legacy Widget instances convert in one click:

```js
transforms: {
	from: [ {
		type: 'block',
		blocks: [ 'core/legacy-widget' ],
		isMatch: ( { idBase, instance } ) => idBase === 'mytheme_cta' && !! instance?.raw,
		transform: ( { instance } ) => wp.blocks.createBlock( 'mytheme/cta', { title: instance.raw.title, url: instance.raw.url } ),
	} ],
},
```

- Block themes have no widget screens; transforms matter when the same plugin also serves classic sites or hybrid phases.
- Widget content stored in options (`widget_text`, `widget_custom_html`) is copied by hand into parts/patterns (see `site-state-migration.md`).

## Content-Security-Policy

A theme that sends a strict CSP (`script-src 'nonce-…' 'strict-dynamic'`) and adds nonces only through `script_loader_tag` blocks block-theme scripts: script modules and the import map print through `wp_print_script_tag()` / `wp_print_inline_script_tag()`, which use the `wp_script_attributes` and `wp_inline_script_attributes` filters. Move the CSP to the plugin and add the nonce in those two filters as well (plus `script_loader_tag` for classic scripts); test the Navigation overlay, Interactivity API blocks, and the editor with the header on.

## Server HTML that varies by cookie

Templates that branch on a cookie (layout view, density, saved filters) make every cached page wrong for some visitors. In a block theme render one markup and switch client-side (a class on `<html>` set by a boot script, like the color-scheme recipe), or exclude those URLs from page caching and send `Vary: Cookie` deliberately.

## AJAX handlers and front-end applications

Rule: **admin-ajax → REST** when the endpoint returns data or is called by new block scripts; keep admin-ajax only for an untouched legacy script during a transition.

- **HTML-fragment responses** (a portfolio panel, comment HTML): render through the same PHP as the block (`render_block()` with the block's attributes), so markup and classes stay identical to the template.
- **Nonces and URLs:** `wp_localize_script()` on a theme handle disappears with the theme. Pass data to block scripts with `wp_add_inline_script( $handle, 'window.x = …', 'before' )`, Interactivity API state (`wp_interactivity_state()`), or `data-*` attributes from `render.php`; REST requests use `wp_create_nonce( 'wp_rest' )`.
- **`history.pushState` deep links:** keep the URLs real (each must render the same panel server-side on a direct load), or use the Interactivity API router for client-side navigation.
- **Site-wide fetch-and-swap / PJAX loaders** (swap `<main>` from a partial-mode response): high-risk in a block theme — block-support layout CSS (`wp-container-*`) and on-demand block styles print in the head of the page that rendered them, so swapped-in markup arrives without its CSS and container class numbers collide; a PHP `is_partial_request()` header/footer branch has no block-template equivalent. Options: retire it, move to the Interactivity API router, or fall back to a full page load whenever the target page's styles differ.
- **AJAX comments** (submission, pagination): target the Comments block markup (`.wp-block-comments`, `.wp-block-post-comments-form`); test that the JS still finds its selectors.
- **Public (anonymous) form endpoints:** nonces in page-cached HTML expire — keep an existing refresh-and-retry pattern (nonce refresh endpoint + retry) when the theme has one; otherwise use a REST endpoint without a nonce for anonymous submissions, plus a honeypot field, rate limiting (transient per IP hash), and an origin/referrer check. Keep a no-JS POST path only where the classic form had one; JS-only forms stay JS-only (record it). During coexistence keep the admin-ajax action as a shim that calls the REST handler.
- **Features that die with widgets and the Customizer** (front-end `widgets-order` saves): list them as removed.

## Custom nav walkers and mega menus

| Classic | Block theme |
|---|---|
| Walker adding classes / icons | Navigation block + CSS on `.wp-block-navigation-item`; per-item icon meta → `icon-*` classes + `render_block` filter (`inc/products/navigation-icons.php`, `wp mytheme migrate-nav-icons`) |
| Description under menu items | Navigation link `description` attribute (CSS to show) |
| Multi-level dropdowns | `core/navigation-submenu` (native) |
| Mega menu (columns, images, CTAs in dropdown) | Not supported natively. Options: a custom block allowed inside Navigation (`"parent": ["core/navigation"]`), a mega-menu plugin, or a simpler IA. Flag MANUAL |
| Menu built from a query (e.g. all categories) | `core/page-list` for pages; a dynamic block for terms |
| Conditional items (logged-in only) | `core/loginout` or a dynamic block; flag MANUAL |
