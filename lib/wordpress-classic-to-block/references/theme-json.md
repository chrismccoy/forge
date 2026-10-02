# Gate 2 — theme.json Derivation

`theme.json` is the single source of truth for all design tokens. Map the classic theme's CSS variables, `wp_enqueue_scripts` color/font values, Customizer settings, and hardcoded hex values into it.

**Existing classic `theme.json`:** read it as input, not as a blank slate. Its locks (`appearanceTools: false`, `color.custom: false`, typography toggles off) are editorial intent — carry them forward as guardrails. An **empty palette** is not a lock to keep: define the palette (styles, section styles, and variations need it) and express "editors pick no colors" by turning color UI off (`color.text`/`background`/`link: false`, re-enabled per block under `settings.blocks`). Locks also hide controls in the Site Editor: build with locks relaxed on a dev branch, re-apply them before release, and diff the exported markup for style attributes editors could no longer change. Global styles are already printed by the classic theme, so the parity baseline includes them. Upgrade v2 → v3 (`defaultFontSizes`/`defaultSpacingSizes` behavior changes). The hybrid path's main benefit is then already spent; note that in the go/no-go.

Scaffold from `examples/block-theme/theme.json` (valid `"version": 3`, WP 6.6+). Replace placeholder values with values derived from the classic theme.

## Mapping rules

| Classic source | theme.json destination |
|---|---|
| CSS `--color-*` vars / Customizer color options | `settings.color.palette` |
| `@font-face` / Customizer font settings | `settings.typography.fontFamilies` (+ `fontFace` for self-hosted files) |
| Font size Customizer options / CSS `--font-size-*` | `settings.typography.fontSizes` |
| Grid max-width, content width | `settings.layout.contentSize`, `settings.layout.wideSize` |
| Spacing scale / padding CSS vars | `settings.spacing.spacingSizes` |
| `body { background-color }` | `styles.color.background` |
| `body { color }` | `styles.color.text` |
| `a { color }` / `a:hover` | `styles.elements.link.color.text` / `styles.elements.link[":hover"]` |
| `h1..h6` font sizes | `styles.elements.h1..h6.typography.fontSize` |
| `button`, `.btn` rules | `styles.elements.button` |
| `figcaption`, `cite`, all headings at once | `styles.elements.caption`, `.cite`, `.heading` |
| `box-shadow` values | `settings.shadow.presets` |
| `border-radius` / border tokens | `settings.border` + `styles.elements.*.border` |
| Aspect ratios, min-height tokens | `settings.dimensions` |
| `body { background-image }` / `custom-background` support | `styles.background` |
| `.section-dark`-style modifier classes | Section styles (`references/style-variations.md`) |
| Customizer color schemes | Style variations (`references/style-variations.md`) |
| Anything else (transitions, z-index, misc. vars) | `settings.custom` → `--wp--custom--*` |

## Worked example: CSS in → theme.json slice out

Classic source: `examples/classic/style.css`.

```css
:root {
  --color-primary: #1a1a2e;
  --color-accent: #e94560;
  --font-size-base: 16px;
}
body { background-color: #ffffff; color: var(--color-primary); font-size: var(--font-size-base); }
a { color: var(--color-accent); }
```

Derived slice:

```json
{
  "settings": {
    "color": {
      "palette": [
        { "color": "#1a1a2e", "name": "Contrast", "slug": "contrast" },
        { "color": "#e94560", "name": "Accent", "slug": "accent" },
        { "color": "#ffffff", "name": "Base", "slug": "base" }
      ]
    },
    "typography": {
      "fontSizes": [ { "name": "Medium", "size": "1rem", "slug": "medium" } ]
    }
  },
  "styles": {
    "color": {
      "background": "var(--wp--preset--color--base)",
      "text": "var(--wp--preset--color--contrast)"
    },
    "typography": { "fontSize": "var(--wp--preset--font-size--medium)" },
    "elements": {
      "link": { "color": { "text": "var(--wp--preset--color--accent)" } }
    }
  }
}
```

Repeat for every CSS variable and hardcoded value found during audit:
1. Extract the raw value.
2. Assign a role-based slug (for **new** slugs — when the classic `theme.json` already defines slugs, audit saved content first: `wp db query "SELECT COUNT(*) FROM wp_posts WHERE post_content REGEXP 'has-(pug-[0-9]+|cream)-(background-)?color'"`; keep slugs in use as legacy aliases with the same values, and add role slugs beside them): `base`, `base-2`, `contrast`, `accent` — never a color name (`white`, `red`). Style variations reassign values under the same slugs, so a slug called `white` ends up holding a dark color.
3. Place it in `settings`.
4. Reference it everywhere via `styles` using `var(--wp--preset--*)`.

## settings.custom for leftover variables

CSS variables with no preset category go to `settings.custom`. Nested keys become kebab-cased custom properties:

```json
"custom": { "transition": { "base": "150ms ease-in-out" }, "zIndex": { "header": "100" } }
```

Output: `--wp--custom--transition--base`, `--wp--custom--z-index--header`. Reference them in `style.css` or per-block CSS. Classic `var(--color-primary)` references in leftover CSS become `var(--wp--preset--color--contrast)`.

## Utility-CSS themes (Tailwind and similar)

Decide up front, and record the decision in the ASSESS. **No plugin blocks** (fast path): the utility build goes away entirely — tokens move to `theme.json`, layout to block supports. **Component classes** (`.x-card`, `.x-btn` built with `@apply`) are neither utilities nor presets: they become block style variations (`styles/*.json` with `blockTypes`, or `styles.blocks.*.variations`) or element styles. Default rule otherwise: **theme markup uses presets only; utility classes live only inside plugin block render markup, built by the plugin's own build** (the theme's build never globs plugin files; the plugin's build globs its own render files and config).
- **Tailwind v4** (`@import "tailwindcss"`): automatic source detection plus `@source` directives replace `content` globs; the JS-config `safelist` is gone — use `@source inline("…")` (4.1+); scope with `@import "tailwindcss" important;` or a wrapper selector and verify. The rest of this section is written for v3.
- **Keep the build, add block sources:** add `templates/**/*.html`, `parts/**/*.html`, `patterns/**/*.php` (and, in the plugin's build, its own render files) to the purge/`content` globs, or utility classes used only there are stripped. Rebuild and diff the selector list.
- **Tailwind used only as a purger** (no utilities, no `@apply`; it supplies preflight and purges hand-written CSS): the purge is the risk — core-rendered classes (`wp-block-*`, `is-layout-*`, `has-*-color`, `wp-container-*`) appear in no theme file and get stripped. Drop the purge or the build and follow `template-conversion.md` → Plain hand-written CSS.
- **RGB-triplet tokens** (`--accent: 62 166 255` for `rgb(var(--accent) / <alpha-value>)`): presets are full colors, so a style variation changes `--wp--preset--color--*` while plugin utilities keep reading the old triplets — variations silently miss plugin blocks. Either duplicate each color as `settings.custom.rgb.{slug}` in `theme.json` and every variation and point the Tailwind config at `--wp--custom--rgb--{slug}`, comma-form triplets (`245, 230, 66` for `rgba(var(--x-rgb), a)`) need the same treatment; or use relative color syntax `rgb(from var(--wp--preset--color--accent) r g b / <alpha-value>)` (check the browser floor). Classic `html[data-theme]` palette switching maps to style variations (admin choice) or the per-visitor toggle recipe in `style-variations.md`.
- **Class strings in the database** (option values such as a headline `<span class="text-brand-500">`, post content): purge globs cannot see them. Audit options and content for utility classes; safelist or map them.
- **Class strings in PHP data** (config arrays, helper maps returning `"bg-emerald-50 text-emerald-700"`): the plugin build's `content` globs must include those config/helper files, not only `render.php`.
- **Dynamic classes** built at runtime (`bg-{slug}-400`) survive only through a safelist. Replace them with preset variables (`var(--wp--preset--color--{slug})`) or classes generated from `theme.json`.
- **Post-body "prose" styles built from utilities** (arbitrary variants on the content wrapper: `[&>p]:mt-6`, `[&>ol:not([data-shortcode])]:…`, or `@tailwindcss/typography`): map to `styles.elements` and `styles.blocks["core/post-content"]` (or its `css` property), keeping exclusions such as `:not([data-shortcode])` as block-scoped selectors.
- **Utility classes in theme block `className`:** not allowed — they bypass Global Styles and the token rule. Utilities inside plugin `render.php` output are allowed, scoped under a wrapper class.
- **Container widths:** Tailwind `max-w-[X] px-6` containers are border-box, so `contentSize` = X − 2 × padding when root padding supplies the gutter (a 1200px container with 24px padding → `contentSize: 1152px`).
- **Icon fonts:** Font Awesome 7 renders icons fixed-width by default; restore 6.x behavior with `:root{--fa-width:auto}` when the classic layout relied on natural widths.
- **Form plugins:** `@tailwindcss/forms` sets input line-height, padding, and borders the classic markup relied on; include those rules in the scoped preflight.
- **Root block gap:** `styles.spacing.blockGap` adds a top margin between top-level template blocks (header part, `main`, footer part); zero it on `main` or set the gap to match the classic spacing.
- **Map the config:** Tailwind `theme.colors`, `fontSize`, `spacing`, and `maxWidth` become `theme.json` palette, font sizes, spacing sizes, and `layout`.
- **Preflight/reset:** classic markup silently depends on it — without `border-style: solid` every `border` utility renders nothing; without link/heading resets theme element styles leak in. Scope a minimal reset to the plugin wrapper class rather than dropping it.
- **Specificity:** utilities (0,1,0) tie with `theme.json` global styles (`:root :where(…)` is 0,1,0 after `:root`), so print order decides, and it differs between front end and editor. Scope utilities with Tailwind's `important: '.x-ui'` (selector strategy) on the plugin wrapper.
  Tailwind v3's `important: '.x-ui'` emits descendant selectors (`.x-ui .bg-foo`), so utilities on the wrapper element itself never match, and the editor iframe needs scoping too. Working setup: a body class added by the plugin plus `important: ':is(.x-tw, .editor-styles-wrapper)'`, and a **separate** `.x-ui` class for the scoped preflight. Do not use `:where(.x-ui)` for the reset: its zero-specificity link and heading rules lose to `theme.json` element styles printed later (`a:where(:not(.wp-element-button))`, `h1`–`h6`), so plugin links turn into theme links. Write the reset as `.x-ui a`, `.x-ui :is(h1,h2,h3,h4,h5,h6)` (0,1,1) with `color`, `line-height`, `letter-spacing`, and `text-decoration` set to `inherit`.
- **Core layout CSS:** `.is-layout-flex > :is(*, div) { margin: 0 }` (0,1,1) overrides single-class `margin-left: auto`, and `> * { margin-block: 0 }` removes block gaps — target with two classes or use block `layout` settings.
- **Container classes:** strip classic section containers (`max-w-* mx-auto px-*`) when markup moves into blocks inside a constrained `main` with root padding, or gutters and max-widths double.

## Per-request CSS variables

Classic themes sometimes print an inline variable that changes per view (`<main style="--accent: …">` by category, tag, or search). Recipes:
- Theme `functions.php`: `wp_add_inline_style( 'mytheme-style', ':root{--accent:' . $value . '}' )` on `wp_enqueue_scripts`, computed with conditional tags (`is_category()`, `get_queried_object()`).
- Or a `render_block` filter adding the variable to the `main` group's `style` attribute with `WP_HTML_Tag_Processor`.

## Token syntax by location

| Location | Syntax |
|---|---|
| `theme.json` `styles` | `var(--wp--preset--color--contrast)` |
| Block comment attributes, named preset | `"textColor":"contrast"`, `"fontSize":"small"`, `"backgroundColor":"base"` |
| Block comment attributes, `style` object | `"var:preset|spacing|30"`, `"var:preset|color|contrast"` |
| Rendered inline `style=""` in block HTML | `var(--wp--preset--spacing--30)` |

Mismatched syntax causes block validation errors ("This block contains unexpected or invalid content") in the editor.

## Critical token rule

Once `theme.json` exists, ALL template parts, templates, and patterns reference design tokens — never hardcoded hex values or font sizes in block markup. Structural one-off dimensions (logo width, cover min-height, a pattern's narrow `contentSize`) are acceptable; colors, font sizes, and spacing are not.

## Version notes

- `"version": 3` requires WP 6.6+. On WP 6.5 use `"version": 2` (drop `defaultSpacingSizes` and `defaultFontSizes`).
- Per-preset `fluid` min/max values apply only when `settings.typography.fluid` is `true`.
- Version 3 changes defaults: `defaultFontSizes` and `defaultSpacingSizes` gate core presets. Set both to `false` to stop core presets from mixing with the theme's own presets.

## Responsive behavior

`theme.json` has no media queries. Replace breakpoints with:
- Fluid typography: `settings.typography.fluid: true` + per-size `fluid` min/max.
- Fluid spacing: `clamp()` values in `spacingSizes` (see the example's `60` and `70`), or `spacingScale` for a generated scale.
- Layout blocks that wrap and stack natively (Columns `isStackedOnMobile`, Group flex/grid with `minimumColumnWidth`).
- `useRootPaddingAwareAlignments: true` plus `styles.spacing.padding` left/right — gives page gutters while letting `alignfull` blocks reach the viewport edge.

Breakpoint CSS that remains goes in per-block stylesheets (`wp_enqueue_block_style()` in `functions.php`), not a global `style.css`.

## Editor guardrails

Restrict what editors can change — often the reason a client funds the migration. Turn off free-form choices globally, then re-enable per block where needed:

```json
"settings": {
  "color": { "custom": false, "customGradient": false, "defaultPalette": false, "defaultGradients": false, "defaultDuotone": false },
  "typography": { "customFontSize": false, "fontStyle": true, "letterSpacing": false },
  "spacing": { "customSpacingSize": false },
  "blocks": {
    "core/button": { "border": { "radius": true } }
  }
}
```

Lock structure in patterns and parts with block attributes:
- `"lock":{"move":true,"remove":true}` on a block.
- `"templateLock":"contentOnly"` on a Group — editors change text and images, not layout.

Users with `edit_theme_options` still edit everything in the Site Editor; guardrails limit choices, not capabilities.

## Accessibility tokens

- Focus: `styles.elements.link[":focus-visible"].outline` and `styles.elements.button[":focus-visible"].outline`. Never remove outlines without a replacement.
- Contrast: every text/background pair in the palette and in every style variation meets WCAG AA (4.5:1 body text).
