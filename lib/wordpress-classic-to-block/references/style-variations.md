# Style Variations and Section Styles

Examples: `examples/block-theme/styles/`.

## Theme style variations

A style variation is a partial `theme.json` in `styles/` with a `title`. It merges over the base `theme.json` when selected in Site Editor → Styles → Browse styles.

- File: `styles/dark.json`. Contains `version`, `title`, and only the `settings`/`styles` keys it changes.
- Keep slugs identical to the base palette. Templates and patterns reference slugs, so a variation that reuses `base`/`contrast`/`accent` restyles the whole site with zero markup changes. This only works when slugs are role-based (see `theme-json.md`).
- Do not add new slugs in a variation that templates depend on — switching back to the default style would leave those references empty.

### Migrating Customizer color schemes

The same applies when the scheme lives in a Settings API option array instead of `get_theme_mod()` (see `large-themes.md` → Huge option arrays).

Classic themes often expose "color scheme" or "skin" options through `get_theme_mod()`. Map each scheme to one variation file:

| Classic | Block theme |
|---|---|
| `get_theme_mod( 'color_scheme' ) === 'dark'` + conditional CSS | `styles/dark.json` |
| Customizer accent-color picker | Global Styles → Colors (user edits stored in `wp_global_styles`) |
| Per-scheme font choice | Typography preset (below) |

The site's *current* scheme choice does not transfer. Record it during Gate 0 and select the matching variation after activation (see `site-state-migration.md`).

## Per-visitor color-scheme toggle (dark mode)

Not a style variation (site-wide, admin-chosen) and not a template-part variation. Recipe:
1. Role-based palette in `theme.json` holds the light values.
2. Re-declare the same preset variables for dark: `@media (prefers-color-scheme: dark){ :root:not(.is-light){ --wp--preset--color--base:…; … } }` and `.is-dark{ … }` in the theme stylesheet — every block that uses presets follows.
3. A tiny boot script in `wp_head` (before paint, CSP-nonced) reads the visitor's stored choice (`localStorage`) and sets `is-dark` / `is-light` on `<html>`; the site default comes from a plugin option.
4. A toggle block (plugin, `viewScript` or Interactivity API) flips the class and stores the choice.
Classic Tailwind `darkMode: 'class'` utilities map to step 2; keep the same storage key so returning visitors keep their choice.

## Color and typography presets (WP 6.6+)

A variation that contains only color settings/styles appears as a **color palette preset**; one with only typography appears as a **typography preset**. Users mix them independently of full variations.

- Color preset: `styles/color-ocean.json` — `settings.color.palette` only.
- Typography preset: `styles/typography-serif.json` — `styles.typography` and `styles.elements.heading` only.

Keep variation files flat in `styles/`. File-name prefixes (`color-`, `typography-`, `section-`) keep the folder readable.

## Section styles (block style variations, WP 6.6+)

Section styles replace classic modifier classes (`.section-dark`, `.bg-brand`) and PHP `register_block_style()` calls that only add CSS. They style a block *and its inner elements and blocks*.

File: `styles/section-dark.json`:
- `slug` — becomes the class `is-style-section-dark`.
- `blockTypes` — blocks that offer the style in the Styles panel.
- `styles` — colors, `elements` (link, heading, button), and nested `blocks`.

Usage in markup:

```html
<!-- wp:group {"className":"is-style-section-dark","layout":{"type":"constrained"}} -->
<div class="wp-block-group is-style-section-dark">…</div>
<!-- /wp:group -->
```

Alternative: define section styles inline in `theme.json` under `styles.variations` and attach via `styles.blocks.{block}.variations`. The file approach keeps `theme.json` smaller.

### Migrating `register_block_style()`

- CSS-only block styles → section style JSON. Remove the PHP call and its stylesheet.
- Block styles with markup or behavior (rare) → keep `register_block_style()` in `functions.php`.

## Verify

- Site Editor → Styles → Browse styles lists each variation; color and typography presets show under Colors → Palette and Typography.
- Switching variations changes every template without block validation errors.
- Every variation passes WCAG AA contrast for text/background pairs.
