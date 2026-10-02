# Gate 6 — Verification

**Run first:** `scripts/static-checks.sh <theme-dir> <plugin-dir> <block-namespace> [plugin-function-prefix]` (read-only). It covers syntax (PHP, JSON, JS), block-feature sabotage, user-facing text in `.html` including block-attribute labels, pattern slugs, one `<main>` per template, hex/raw sizes, plugin territory and redundant supports in the theme (comment lines ignored), the theme calling no plugin functions, every called plugin function defined, block-comment balance, every theme-used plugin block existing, and a list of block-validation risk markers to review. The greps below remain for manual spot checks.

Complete MIGRATE mode with this checklist. Every item is objectively verifiable — a second developer scores it without judgment. Run commands from the block theme directory unless noted.

## Activation smoke test

1. New slug: activate the companion plugin first, then the block theme. Same slug: activate the plugin (data-layer mode), replace the theme folder, **restart PHP-FPM** (the realpath cache and opcache keep serving the old folder until PHP restarts), then load wp-admin once so the plugin's version-checked setup runs (no activation or switch events fire).
2. Open `/wp-admin/` — no PHP fatal errors or notices.
3. Open Appearance → Editor — the Site Editor loads without a blank screen.
4. Open a page, post, and archive on the front end — no 404s, no unstyled content.
5. CPT model only (core-post model: confirm the documented behavior instead): deactivate the companion plugin; reload the same pages and the Site Editor — no fatal errors, no "unsupported block" notices in `index`, `single`, `page`, `archive`, parts, or general patterns. Reactivate.

## Real-WordPress smoke test

WordPress Playground CLI gives a disposable real site in minutes: `npx @wp-playground/cli server --blueprint blueprint.json --mount ./theme:/wordpress/wp-content/themes/x --mount ./plugin:/wordpress/wp-content/plugins/x-functionality`. Use it for the smoke test, the plugin-off run, and classic-plus-plugin coexistence. Gotchas: auto-login answers the first request with a 302; run one server per ~7 GB of RAM.

## Acceptance checklist

- [ ] **`theme.json` is valid JSON, uses `"version": 3` (WP 6.6+), and validates against its `$schema`.**
  Verify: `python3 -m json.tool theme.json >/dev/null`; open the file in an editor that honors `$schema` (VS Code) — zero schema warnings; Site Editor → Styles opens without errors.

- [ ] **No hardcoded hex colors in block markup.**
  Verify: `grep -rnE '#[0-9a-fA-F]{3,8}\b' templates/ parts/ patterns/` → zero hits (review any hit that is not a color, e.g. an anchor link).

- [ ] **Font sizes and spacing use presets.**
  Verify: `grep -rnE '"fontSize":"[0-9]|"(top|bottom|left|right|blockGap)":"[0-9]' templates/ parts/ patterns/` → zero hits.

- [ ] **Templates are in `templates/`, parts in `parts/`; no PHP in either.**
  Verify: `find templates/ parts/ -name '*.php'` → zero results; `grep -rn '<?php' templates/ parts/` → zero hits.

- [ ] **No CPT, taxonomy, metabox, shortcode, or REST registration remains in the theme.**
  Verify: `grep -rnE "register_post_type|register_taxonomy|add_meta_box|add_shortcode|register_rest_route|wp_ajax_" --include='*.php' .` → zero hits.

- [ ] **Companion plugin active; all CPTs/taxonomies resolve.**
  Verify: `wp plugin status {original-slug}-functionality` shows Active; `wp post-type list --public=1 --fields=name` lists expected types; visit each CPT archive — no 404 (`wp rewrite flush` if needed).

- [ ] **Every migrated meta field is REST-exposed.**
  Verify: `wp eval 'print_r( array_keys( get_registered_meta_keys( "post", "event" ) ) );'` lists each field; `curl -s https://SITE/wp-json/wp/v2/event/ID | jq .meta` shows the values (authenticated if `auth_callback` restricts reads).

- [ ] **Repeater/relationship fields render via a registered dynamic block.**
  Verify: `wp eval 'var_dump( WP_Block_Type_Registry::get_instance()->is_registered( "mytheme/event-schedule" ) );'` → `bool(true)`; the block renders on a single event page.

- [ ] **Old metabox UI is gone.**
  Verify: open an `event` post in wp-admin — no legacy metabox panel; field is editable via the bound block (WP 6.7+) or the Custom Fields panel.

- [ ] **Legacy meta data migrated, not just re-registered.**
  Verify: `wp mytheme migrate-meta --dry-run` reports expected counts; after the real run, spot-check 3–5 posts: `wp post meta get <id> event_venue` equals `wp post meta get <id> _event_venue`.

- [ ] **Shortcodes are shims only.**
  Verify: each callback in `inc/shortcodes.php` returns `render_block( … )` and contains no rendering logic of its own; a post containing the shortcode renders identical output to the block.

- [ ] **All patterns appear in the inserter.**
  Verify: `wp eval 'echo implode( "\n", array_column( WP_Block_Patterns_Registry::get_instance()->get_all_registered(), "name" ) );' | grep '^{theme-slug}/'` lists every file in `patterns/`.

- [ ] **Head and footer output intact.**
  Verify: view front-end page source — `<title>`, SEO plugin meta tags, enqueued theme stylesheet, and footer scripts are present.

- [ ] **No PHP notices or deprecations.**
  Verify: `WP_DEBUG=true`, `WP_DEBUG_LOG=true`, `WP_DEBUG_DISPLAY=false`; visit index, single, page, archive, search, 404, and each CPT single/archive; `wp-content/debug.log` gains zero new entries.

- [ ] **No block validation errors.**
  Verify: open every template, part, and pattern in the Site Editor with the network panel open — no HTTP 4xx from `block-renderer`, no "Error loading block", no "This block contains unexpected or invalid content" notices.

- [ ] **Visual parity on all template types.**
  Verify: side-by-side screenshots (classic vs. block) of homepage, single post, page, archive, search results, 404, and each CPT. Flag layout shift > 20px or color mismatch as a regression.

- [ ] **Classic theme retained as a tagged fallback.**
  Verify: `git tag --list 'classic-pre-migration'` returns the tag; reactivation with `wp theme activate {classic-slug}` takes under 5 minutes.

- [ ] **Legacy `style.css` does not fight block styles.**
  Verify: in devtools, no `style.css` selector overrides `.wp-block-*` or `.wp-element-button` rules unintentionally. Prefer deleting migrated rules from `style.css` over overriding them.

## Completion per view

- [ ] **Every classic rendered view is mapped.** List each view from the ASSESS (front page, blog index, single, page, each archive, search, 404, each slug template) with its block template and the blocks that replace each classic template part. No view may fall back to `index.html` unintentionally.

## Block-validation risk

Hand-written core markup fails validation most often on: `are-vertically-aligned-*` / `is-vertically-aligned-*` classes and Column `flex-basis` style that must match `verticalAlignment` / `width` attributes; Group `anchor` (attribute) vs `id` (HTML); Cover `dimRatio` ↔ `has-background-dim-*` class; Button `has-*-color` classes ↔ color attributes; `style` attribute objects ↔ inline `style=""`. Open every template, part, and pattern in the Site Editor, or build them there and copy the serialized markup.

## Block-theme specifics

- [ ] **The theme stylesheet is enqueued and loads in the editor.**
  Verify: front-end page source contains the theme stylesheet handle; `grep -n "wp_enqueue_style\|add_editor_style" functions.php` → both present.

- [ ] **No block-feature sabotage remains.**
  Verify: `grep -rnE "use_block_editor_for_post|use_widgets_block_editor|wp-block-library|global-styles|wp_enqueue_global_styles|wp_oembed_register_route" --include=*.php .` → zero hits in theme and plugin.

- [ ] **No hardcoded user-facing text or theme asset paths in `.html` files.**
  Verify: `grep -rnE '<(p|h[1-6]|a|span|li)[^>]*>[^<{]*[A-Za-z]{3,}' templates/ parts/` → zero hits (keep bound-block placeholders empty); `grep -rn 'wp-content/themes' templates/ parts/` → zero hits.

- [ ] **Every `wp:pattern` slug in templates/parts exists.**
  Verify: `for s in $(grep -rhoE '"slug":"mytheme/[a-z0-9-]+"' templates/ parts/ patterns/ | cut -d'"' -f4 | sort -u); do grep -lq "Slug: $s\$" patterns/*.php || echo "MISSING $s"; done` → no output.

- [ ] **Text domain loads and strings are translatable.**
  Verify: `wp i18n make-pot . languages/mytheme.pot --domain=mytheme` succeeds and the POT includes the hidden-pattern strings.

- [ ] **Redundant theme supports, menus, and sidebars removed.**
  Verify: `grep -nE "add_theme_support\( *'(post-thumbnails|responsive-embeds|editor-styles|html5|automatic-feed-links|title-tag|custom-header|custom-background|widgets)'|register_nav_menus?\b|register_sidebar" --include=*.php -r .` → zero hits (whole theme, not only `functions.php`).

- [ ] **Style variations load and swap cleanly.**
  Verify: `for f in styles/*.json; do python3 -m json.tool "$f" >/dev/null || echo "BAD $f"; done`; switch each variation in Site Editor → Styles — no validation errors, contrast AA.

- [ ] **No database overrides hiding theme files.**
  Verify: `wp post list --post_type=wp_template,wp_template_part,wp_global_styles --fields=ID,post_name,post_modified` → empty on a fresh install; on the live site every listed item is intentional or exported via Create Block Theme then reset.

- [ ] **Site state migrated.**
  Verify against the Gate 0 export (`site-state-migration.md`): logo and site icon visible; navigation shows the imported menu; former widget content present in parts/patterns; Additional CSS carried over; pages that used custom PHP templates now use the mapped `customTemplates` slug.

- [ ] **Accessibility basics.**
  Verify: every template contains exactly one `"tagName":"main"` (`grep -c '"tagName":"main"' templates/*.html` → 1 each); the skip link appears on Tab from page top; one `h1` per view; visible focus outline on links and buttons.

## Complex fields (Gate 5d)

- [ ] **Every complex field has a recorded storage decision** (meta, attribute, child blocks, option, term/user meta) in the risk register.
- [ ] **New CPT posts open with the template layout.**
  Verify: Add New Event shows Event Details, Event Sessions with one row, and the description paragraph; top-level blocks cannot be added or removed.
- [ ] **Required fields block publishing in the editor and in REST.**
  Verify: Publish is disabled with no date; `curl -X POST -u user:app-password https://SITE/wp-json/wp/v2/event -d status=publish -d title=Test` returns `400 mytheme_event_date_required`.
- [ ] **Array meta round-trips through REST.**
  Verify: set related events in the panel, save, reload — tokens persist; `wp post meta get <id> event_related --format=json` shows integer IDs.
- [ ] **Repeater migration complete.**
  Verify: `wp mytheme migrate-sessions --dry-run` count equals events with `_event_sessions`; after the run, spot-check 3–5 events render the same rows; no "invalid content" warnings on open.
- [ ] **Query Loop variation orders by event date on the front end.**
  Verify: insert "Upcoming events"; the front end lists only today-or-later events, soonest first, and pagination counts match.
- [ ] **Site options render through bindings.**
  Verify: set Phone on Settings → General; a paragraph bound to `mytheme/site-option` with `key: mytheme_phone` shows it; an unknown key renders the placeholder.

## Hand-coded metaboxes

- [ ] **Field inventory table complete**, one row per key with `file:line`, target storage, target control, and migration.
- [ ] **Meta registered on every request.** Verify: `wp eval 'echo count( get_registered_meta_keys( "post", "post" ) );'` matches the inventory count from WP-CLI (not only in wp-admin).
- [ ] **No legacy metabox edits a key the panel owns.** Verify: block editor shows no "Product Details"-style boxes below the canvas; change a field in the panel, save, reload — value persists.
- [ ] **Empty values delete rows.** Verify: clear the download file in the panel, save; `wp eval 'var_dump( metadata_exists( "post", <id>, "mytheme_filename" ) );'` → `bool(false)` and the item leaves `EXISTS`-based lists. (`wp post meta get` prints the registered default and exits 0, so it cannot prove deletion.)
- [ ] **Derived values update.** Verify: pick a new file; `mytheme_file_size` and `mytheme_file_format` change without visiting the classic screen.
- [ ] **Save-without-changes leaves meta identical.** Verify: `wp post meta list <id> --format=json > a.json`, open and Update in the editor, export again, and diff with core bookkeeping keys removed — `jq 'map(select(.meta_key | test("^(_pingme|_encloseme|footnotes|_edit_lock|_edit_last|_wp_old_slug|_wp_old_date)$") | not))'` on both files — → no output. Core adds `_pingme`, `_encloseme`, and `footnotes` on any REST save; they are not migration defects.
- [ ] **Normalization done.** Verify: `wp mytheme normalize-meta --dry-run` reports 0 changes after the real run.

## Quality

- [ ] **Visual regression suite passes** (`examples/tools/visual-regression.spec.js`, see `quality-and-deployment.md`).
- [ ] **Performance not worse than classic** on LCP, CLS, INP, and bytes of CSS/JS for home, single, archive.
- [ ] **Plugin compatibility table completed**, every plugin function formerly called from template PHP replaced.
- [ ] **No theme-enqueued jQuery** unless a remaining script truly needs it: `grep -rn "jquery" functions.php` → zero hits.

## WordPress.org release (when distributing)

- [ ] `style.css` header complete: `Requires at least: 6.6`, current `Tested up to`, `Requires PHP`, license, `Text Domain`, `Tags` include `full-site-editing`.
- [ ] `readme.txt` lists copyright, license, and source for every bundled font and image.
- [ ] `screenshot.png` is 1200 × 900.
- [ ] Theme Check plugin: zero REQUIRED items.
- [ ] No external font or script CDN requests (devtools Network tab, filter by domain).
- [ ] Theme Unit Test data imported; long titles, nested comments, galleries, sticky posts, and pagination render correctly.
