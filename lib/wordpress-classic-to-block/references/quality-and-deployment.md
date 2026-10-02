# Plugin Compatibility, Visual Regression, Performance, Deployment

## Plugin compatibility

Check every active plugin against block-theme behavior during Gate 0. Common cases:

| Plugin type | Classic integration | Block-theme check |
|---|---|---|
| SEO (Yoast, Rank Math, AIOSEO) | `wp_head`, breadcrumb function in template PHP | Head output unaffected; breadcrumbs → the plugin's breadcrumb block in parts/templates |
| Multilingual (WPML, Polylang) | Translated menus, string translation of theme mods | Templates, parts, patterns, and `wp_navigation` need translating in the plugin's FSE support; theme strings via the text domain; test language switcher block |
| Forms (Gravity Forms, WPForms, CF7) | Shortcodes in content / template PHP | Shortcodes in content still work; template-level forms → the plugin's block |
| Caching / optimization | Combines global CSS/JS | Per-block CSS loads conditionally; disable "combine CSS" if it breaks per-page styles; purge after template changes (DB overrides) |
| Page builders | Own templates | Out of scope (Gate 0) |
| WooCommerce | `woocommerce/*.php` overrides | See `template-conversion.md` → WooCommerce scope |
| Membership / restrict content | Template conditionals | Dynamic block or plugin block; flag MANUAL |
| Related posts, social share | Function calls in `single.php` | Plugin's block, or a Query Loop variation |

Any plugin function called directly from classic template PHP (`yoast_breadcrumb()`, `pll_the_languages()`) has no `.html` equivalent: use the plugin's block or wrap it in a small dynamic block in the companion plugin.

## Visual regression

Replace eyeballed screenshots with automated diffs. Example: `examples/tools/visual-regression.spec.js` (Playwright Test, plain JS).

1. Staging site with production data copy, classic theme active.
2. `SITE_URL=… npx playwright test --update-snapshots` — records classic baselines.
3. Activate block theme (and companion plugin).
4. `SITE_URL=… npx playwright test` — diffs written to `test-results/`.

Rules:
- Cover every template type, each CPT single/archive, and three widths (375, 768, 1280).
- Mask volatile regions (dates, admin bar, randomized content).
- Start with `maxDiffPixelRatio: 0.02`; tighten as parity improves. Intentional design changes get approved by re-running with `--update-snapshots` after sign-off.

## Test data: wp-demo

For classic themes with hand-coded fields, generate full field coverage with the importer from `/wp-demo` in this plugin (optional; without it, build test content by hand from the field inventory) before migrating, then run the visual-regression suite and a save-without-changes meta diff. Procedure: `coded-metaboxes.md` → Step 9.

## Performance

Measure before and after (Lighthouse or PageSpeed Insights, same URLs, mobile profile):
- LCP, CLS, INP; total CSS and JS transferred; request count.

Expected wins and their causes:
- Block themes load core block CSS per block (`should_load_separate_core_block_assets`) — keep it on.
- `theme.json` generates only used presets' CSS.
- Script modules load only with their block.

Regressions to watch:
- A large `style.css` carried over wholesale — move rules to `theme.json` and per-block CSS.
- Self-hosted fonts without `font-display` or with many weights — use variable fonts and limit `fontFace` entries.
- jQuery still enqueued by the theme.
- Hero image as CSS background — use a Cover block image so core adds `fetchpriority` / sizes.

## Deployment workflow

The theme lives in version control; Site Editor edits live in the database. Keep them from diverging:

1. **Develop locally or on staging**, editing in the Site Editor when convenient.
2. **Export** with Create Block Theme ("Save changes to theme") so templates, parts, and global styles are written to files.
3. **Reset** the database copies (Site Editor → Clear customizations) so files are authoritative again.
4. **Commit** and deploy the theme folder.
5. **Production:** before deploying, list overrides — `wp post list --post_type=wp_template,wp_template_part,wp_global_styles --fields=ID,post_name,post_modified`. Decide per item: keep (client edit), export back to the repo, or reset.
6. **Lock production** if clients must not edit templates: remove `edit_theme_options` from their role, or use theme.json guardrails and pattern locking for softer limits.
7. Purge page cache after template changes.

CI suggestions: `php -l` on all PHP, JSON validation for `theme.json` and `styles/*.json`, Theme Check via WP-CLI on a disposable install, and the visual regression suite against staging.
