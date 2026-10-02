# WordPress.org Theme Requirements and Packaging

Apply when the theme ships to the WordPress.org directory or to clients who expect directory-quality code. Private client themes still benefit from the same rules.

Examples: `examples/block-theme/style.css`, `readme.txt`, `functions.php`.

## Required files

| File | Requirement |
|---|---|
| `style.css` | Header with Theme Name, Author, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain, Tags |
| `templates/index.html` | Required for a block theme |
| `theme.json` | Required in practice for FSE |
| `readme.txt` | Required. Copyright, license, and source for every bundled third-party resource (fonts, images, icons, scripts) |
| `screenshot.png` | 1200 × 900, ≤ 1 MB recommended, shows the theme (no logos of other brands) |

Header values:
- `Requires at least: 6.6` when `theme.json` is version 3.
- `Tested up to:` the current major WordPress release at submission time.
- `Version:` bump the major version (e.g. 1.x → 2.0.0) — converting to a block theme is a breaking change for users.
- `Tags:` must include `full-site-editing` for a block theme. Use only tags from the official list (`block-patterns`, `block-styles`, `style-variations`, `wide-blocks`, `editor-style`, `template-editing`, `translation-ready`, `accessibility-ready`, …).

## Code rules that affect migration

- **Custom blocks and core-feature switches are plugin territory:** registering blocks, disabling the block editor, feeds, XML-RPC, or emoji belongs in a plugin.
- **No plugin territory.** CPTs, taxonomies, shortcodes, meta registration, REST routes, analytics, SEO meta — all belong in the companion plugin (Gate 5). The theme must work fully with the plugin inactive.
- **No required plugins.** Recommending one is allowed; breaking without it is not.
- **Prefix everything:** functions, handles, pattern slugs, pattern category, block style slugs, option names (`mytheme_`, `mytheme/`).
- **Translation:** every user-facing string in PHP is wrapped with the theme text domain. `.html` templates contain no hardcoded text — use hidden patterns (`patterns.md`).
- **Escaping:** `esc_html__`, `esc_attr__`, `esc_url` in every pattern PHP output.
- **Assets bundled locally:** no Google Fonts, icon-font CDNs (Font Awesome on cdnjs), or other CDN calls. Self-host icon fonts and list their licences (Font Awesome Free: icons CC BY 4.0, fonts SIL OFL 1.1, code MIT) in `readme.txt`. Conditional loading tied to classic menu locations (`has_nav_menu()`) stops working in block themes; load per block (`wp_enqueue_block_style`), globally, or at render time: block templates render before `wp_head`, so `wp_enqueue_style()` called from a `render_block` filter or `render.php` still prints in `<head>` — the clean replacement for classic location-based gates. Self-host fonts via `fontFace` with `file:./assets/fonts/…`. Include unminified sources for any minified JS/CSS.
- **License:** GPL-compatible for all code and assets. Fonts under OFL are fine; list them in `readme.txt`.
- **No admin nags, no upsell notices beyond one dismissible notice, no tracking.**
- **Credit links:** at most one footer credit link, to WordPress.org or the theme author.
- **Remove redundant theme supports** (block themes add these automatically): `post-thumbnails`, `responsive-embeds`, `editor-styles`, `html5`, `automatic-feed-links`, `title-tag`. Remove `custom-header`, `custom-background`, and `widgets` support — they do not work in block themes.

## Accessibility (`accessibility-ready` tag)

- Every template has exactly one `<main>` (Group with `"tagName":"main"`). WordPress adds the skip link automatically for block themes only when a `main` element exists.
- Template parts use landmark tags via the template-part block: `"tagName":"header"`, `"footer"`, `"aside"`.
- One `h1` per view: `wp:post-title {"level":1}` on single/page, `wp:query-title` on archives/search. Site title uses `"level":0` (not a heading) everywhere except where it is the only h1.
- Visible focus styles (`:focus-visible` in `theme.json`).
- Navigation has an accessible name; overlay menu works by keyboard.
- Text contrast ≥ 4.5:1 in the default style and every style variation.
- Links inside text are distinguishable without color (underline).

## Review tooling

- **Theme Check** plugin — run and fix every REQUIRED item.
- **Create Block Theme** plugin — export clean markup and validate the theme folder.
- **Theme Unit Test** data (`wp import` of `themeunittestdata.wordpress.xml`) — exercises long titles, nested comments, galleries, sticky posts, pagination.
- **WordPress Playground** or `wp-env` — quick clean installs to compare classic vs. block theme side by side and to test with the companion plugin off.
