# Gate 4 — Patterns

Extract repeating sections into `patterns/*.php`. WP 6.0+ auto-registers every file in `patterns/` from its comment header — do NOT call `register_block_pattern()` for them.

Examples in `examples/block-theme/patterns/`: `hero-banner.php` (section), `header-centered.php` (template-part variation), `page-landing.php` (starter page), `footer-default.php` and `hidden-*.php` (template text).

## Header field reference

| Field | Required | Description |
|---|---|---|
| `Title` | Yes | Human-readable name shown in the inserter |
| `Slug` | Yes | `{theme-slug}/{pattern-name}` — must be unique |
| `Description` | No | Shown on hover in the inserter |
| `Categories` | No | Comma-separated. Core: `text`, `query`, `featured`, `banner`, `buttons`, `columns`, `footer`, `gallery`, `header`, `testimonials`, `call-to-action`, `about`, `services` |
| `Keywords` | No | Extra search terms |
| `Viewport Width` | No | Canvas width for the preview |
| `Block Types` | No | Offers the pattern as a starting variation for that block (e.g. `core/template-part/header`) |
| `Post Types` | No | Limits pattern to specific post types |
| `Template Types` | No | Offers the pattern when creating a template (e.g. `404`, `single`) |
| `Inserter` | No | `no` hides the pattern from the inserter (template-only patterns) |

## Rules

- Pattern files are PHP: use `get_theme_file_uri()` for asset URLs and `esc_html_e()` for translatable strings. This is the only place in the theme where PHP and block markup mix.
- Reference design tokens by preset slug (`"textColor":"base"`, `"fontSize":"huge"`, `"backgroundColor":"accent"`). Do not repeat styles already set in `theme.json` `styles.elements` (e.g. button padding/radius).
- Block attributes and the rendered HTML must agree exactly — every attribute that adds a class or inline style must appear in the HTML. Mismatch triggers editor block-validation errors. When unsure, build the pattern in the editor and copy the serialized markup (Code editor view).
- Use `wp:pattern {"slug":"mytheme/hero-banner"}` to place a pattern inside a template. Patterns may nest other patterns the same way.
- Convert sections that change per page into patterns; convert sections identical on every page into template parts.

## Pattern roles

| Role | Header fields | Shown where |
|---|---|---|
| Section pattern | `Categories` | Inserter → Patterns |
| Template text holder | `Inserter: no` | Nowhere; referenced from `.html` via `wp:pattern` — text and global blocks only; context blocks (post-terms, comments-title, query blocks) lose their context inside patterns |
| Template-part variation | `Block Types: core/template-part/header` (or `/footer`) | Replace-part UI when editing the header/footer |
| Starter page | `Block Types: core/post-content` + `Post Types: page` | "Choose a pattern" modal when creating a page |
| Template starter | `Template Types: 404` (or `single`, `archive`, …) | Offered when creating that template in the Site Editor |

Classic theme sources for each role:
- Header/footer layout options in the Customizer → template-part variations.
- `page-landing.php`, `page-about.php` templates with fixed layout → starter page patterns (content belongs in the page, not the template).
- `get_template_part( 'template-parts/cta' )` used in several templates → section pattern.

## Custom categories

Register in `functions.php` with `register_block_pattern_category( 'mytheme', array( 'label' => __( 'MyTheme', 'mytheme' ) ) )`, then use `Categories: mytheme` in headers. Unregistered category slugs fall into "Uncategorized".

## Theme patterns vs synced patterns

| | Theme pattern (`patterns/*.php`) | Synced pattern (`wp_block` post) |
|---|---|---|
| Stored in | Theme files | Database |
| Edit propagates | No — inserting copies the markup | Yes — every instance updates |
| Ships with theme | Yes | No (site content) |

Classic reusable "global sections" (a CTA edited once, shown everywhere) become synced patterns created on the site after migration, or template parts if they belong to the layout. Theme files cannot ship synced patterns.

## Pattern overrides (WP 6.6+)

Synced patterns can allow per-instance content changes: in the synced pattern, name a block (`"metadata":{"name":"CTA heading"}`) and enable overrides; WordPress binds it to `core/pattern-overrides`. Supported blocks: paragraph, heading, image, button. Use for repeated cards whose layout is fixed but text differs. Applies only to synced patterns, so set it up on the site, not in theme files.

## Locking

- `"lock":{"move":true,"remove":true}` on a block in a pattern prevents restructuring.
- `"templateLock":"contentOnly"` on a wrapping Group lets editors change text and images only.
Use on client-facing patterns where layout drift is a risk (see "Editor guardrails" in `theme-json.md`).
