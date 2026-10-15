# theme.json v3 Review Reference

Review reference for theme.json in block, hybrid and classic themes (v3 = WordPress 6.6+). Covers the keys a reviewer checks, the severity of each finding and the fix. Severities follow the skill's canonical model in SKILL.md.

## Contents

- Top-level keys
- Versions and migration
- v3 default font and spacing sizes
- settings.color
- settings.typography
- settings.spacing
- settings.layout and useRootPaddingAwareAlignments
- settings.appearanceTools
- Other settings (border, shadow, dimensions, position)
- styles
- templateParts
- customTemplates
- patterns
- Validation
- Findings table
- WordPress.org context
- Cross-references

## Top-level keys

| Key | Type | Required | Notes |
|-----|------|----------|-------|
| `$schema` | string | No | `"https://schemas.wp.org/trunk/theme.json"` (or a versioned URL). Missing is INFO. |
| `version` | integer | Yes | `3` is current. Missing is CRITICAL (see Versions). |
| `settings` | object | No | Editor controls and presets. |
| `styles` | object | No | Global and per-block styles. |
| `customTemplates` | array | No | Custom templates in `templates/`. |
| `templateParts` | array | No | Template parts in `parts/`. |
| `patterns` | array | No | Pattern Directory slugs to register. |

## Versions and migration

| Version | WordPress | Severity |
|---------|-----------|----------|
| missing | any | CRITICAL |
| 1 | 5.8 | WARNING (deprecated; core still migrates it at runtime) |
| 2 | 5.9-6.5 | WARNING (upgrade to v3) |
| 3 | 6.6+ | Current |

**Missing `version` (CRITICAL).** `WP_Theme_JSON_Schema::migrate()` treats a file without `version` as unusable and replaces its contents with `{"version": <latest>}`. Every setting and style in the file is discarded, so the theme silently falls back to core defaults. The same applies to each style variation JSON in `styles/`: each one is migrated independently, so its version does not need to match the main theme.json, but it must be present.

**v1 (WARNING).** Core migrates v1 at runtime, renaming the old `custom*` keys (for example `typography.customLineHeight` to `typography.lineHeight`, `border.customRadius` to `border.radius`, `spacing.customPadding` to `spacing.padding`). Fix: move to v3 with the current key names.

**v2 to v3 (WARNING on v2).** When core migrates a v2 file it sets `defaultFontSizes: false` if the theme defines `fontSizes`, and `defaultSpacingSizes: false` if it defines `spacingSizes` or `spacingScale`. This preserves v2 behaviour. Changing `"version": 2` to `3` by hand removes that implicit migration, so the upgrade steps are:

1. Set `"version": 3`.
2. If the theme defines `typography.fontSizes`, add `"defaultFontSizes": false` (unless the theme intentionally offers the core sizes too).
3. If the theme defines `spacing.spacingSizes` or `spacing.spacingScale`, add `"defaultSpacingSizes": false` (same exception).
4. Check the Site Editor Styles panel for duplicate or missing size presets.

## v3 default font and spacing sizes

In v3, `defaultFontSizes` and `defaultSpacingSizes` default to `true`. Core registers its default presets with `prevent_override` tied to these settings. With the setting left at `true` and the theme defining its own presets:

- **Slug collision (CRITICAL).** Where a theme preset uses a core default slug, the default wins and the theme value is silently ignored.
  - Core fontSize slugs: `small`, `medium`, `large`, `x-large`, `xx-large`.
  - Core spacing slugs: `20`, `30`, `40`, `50`, `60`, `70`, `80`.
- **No collision (WARNING).** Both sets apply, and the UI shows a duplicate "Default" preset group next to the theme group.

Fix in both cases: set `"defaultFontSizes": false` / `"defaultSpacingSizes": false`, or rename the theme slugs if offering both sets is intended.

Example of the CRITICAL case (theme `medium` and `40` are ignored):

```json
{
	"version": 3,
	"settings": {
		"typography": {
			"fontSizes": [
				{ "slug": "medium", "size": "1.125rem", "name": "Medium" }
			]
		},
		"spacing": {
			"spacingSizes": [
				{ "slug": "40", "size": "1.5rem", "name": "Medium" }
			]
		}
	}
}
```

Fixed:

```json
{
	"version": 3,
	"settings": {
		"typography": {
			"defaultFontSizes": false,
			"fontSizes": [
				{ "slug": "medium", "size": "1.125rem", "name": "Medium" }
			]
		},
		"spacing": {
			"defaultSpacingSizes": false,
			"spacingSizes": [
				{ "slug": "40", "size": "1.5rem", "name": "Medium" }
			]
		}
	}
}
```

An absent palette, `fontSizes` or `spacingSizes` is not a problem: core defaults apply.

## settings.color

Defaults are core's base theme.json values (WordPress 6.6+).

| Property | Default | Notes |
|----------|---------|-------|
| `defaultPalette` | true | Core palette shown alongside the theme palette. |
| `defaultGradients` | true | |
| `defaultDuotone` | true | |
| `custom` | true | Custom color picker. |
| `customGradient` | true | |
| `customDuotone` | true | |
| `background` | true | |
| `text` | true | |
| `link` | false | Enabled by `appearanceTools`. |
| `heading` | true | |
| `button` | true | |
| `caption` | true | |
| `palette`, `gradients`, `duotone` | core presets | Theme presets add a "Theme" group. |

Each palette entry generates `--wp--preset--color--<slug>` and the `has-<slug>-color` / `has-<slug>-background-color` classes. Hex values inside `palette` are expected; never flag them.

## settings.typography

Defaults are core's base theme.json values (WordPress 6.6+).

| Property | Default | Notes |
|----------|---------|-------|
| `defaultFontSizes` | true | See v3 default sizes. |
| `fluid` | false | `true` or an object turns preset sizes into `clamp()`. |
| `customFontSize` | true | |
| `fontStyle` | true | |
| `fontWeight` | true | |
| `letterSpacing` | true | |
| `textDecoration` | true | |
| `textTransform` | true | |
| `lineHeight` | false | Enabled by `appearanceTools`. |
| `dropCap` | true | |
| `fontFamilies` | none | Theme font presets, with optional `fontFace`. |
| `fontSizes` | core presets | |

**fontFace sources.** Bundled font files use the `file:` prefix, resolved relative to the theme root:

```json
{
	"fontFamily": "Inter",
	"fontWeight": "400",
	"fontStyle": "normal",
	"src": ["file:./assets/fonts/inter-regular.woff2"]
}
```

- A relative path without `file:` is treated as a URL and the font does not load: WARNING.
- A Google Fonts or other CDN URL in `src`: CRITICAL in a WordPress.org context, INFO otherwise. Fix by bundling the files locally.

**Fluid sizes.** A preset can set `"fluid": {"min": "1.25rem", "max": "1.5rem"}` or `"fluid": false`. Per-preset `fluid` only takes effect when `settings.typography.fluid` is enabled.

## settings.spacing

| Property | Notes |
|----------|-------|
| `defaultSpacingSizes` | Default `true`. See v3 default sizes. |
| `customSpacingSize` | Default `true`. |
| `padding`, `margin` | Off by default; enabled by `appearanceTools`. |
| `blockGap` | `true` enables the control and gap styles; `false` outputs gap styles without the control; `null` (core default) outputs neither. Enabled by `appearanceTools`. |
| `units` | Default `["px", "em", "rem", "vh", "vw", "%"]`. |
| `spacingSizes` | Explicit presets; slug becomes `--wp--preset--spacing--<slug>`. |
| `spacingScale` | Generates presets with numeric slugs from `operator`, `increment`, `steps`, `mediumStep`, `unit`. |

Slugs generated from `spacingScale` are centred on `50` (the medium step) and step by 10, so they overlap the core slugs above whenever `steps` > 0. A theme that uses `spacingScale` therefore needs `defaultSpacingSizes: false` in v3 for its scale to take effect.

## settings.layout and useRootPaddingAwareAlignments

```json
{
	"settings": {
		"layout": {
			"contentSize": "640px",
			"wideSize": "1200px"
		},
		"useRootPaddingAwareAlignments": true
	}
}
```

- `layout.contentSize`: max width of children in a constrained layout. `layout.wideSize`: max width of `alignwide`. Missing either in a block theme is WARNING.
- `useRootPaddingAwareAlignments` is a direct child of `settings`, not of `settings.layout`.

**What it does.** With it enabled, root left/right padding (`styles.spacing.padding.left/right`) is applied to `.has-global-padding` containers instead of `body`, and full-width children get negative margins so they reach the viewport edges:

```css
.has-global-padding {
	padding-right: var(--wp--style--root--padding-right);
	padding-left: var(--wp--style--root--padding-left);
}
.has-global-padding > .alignfull {
	margin-right: calc(var(--wp--style--root--padding-right) * -1);
	margin-left: calc(var(--wp--style--root--padding-left) * -1);
}
```

Without it, root padding sits on `body`, so `alignfull` blocks stop short of the viewport edges by the padding amount.

**Findings.**

- Root left/right padding without `useRootPaddingAwareAlignments`: WARNING. Fix: set `"useRootPaddingAwareAlignments": true`. Top/bottom-only root padding never needs it.
- `useRootPaddingAwareAlignments: true` with root `styles.spacing.padding` as a shorthand string: CRITICAL. The root padding variables are only generated from the object form, so the alignment logic breaks. Fix: use the object form.

BAD:

```json
{
	"settings": { "useRootPaddingAwareAlignments": true },
	"styles": { "spacing": { "padding": "2rem" } }
}
```

GOOD:

```json
{
	"settings": { "useRootPaddingAwareAlignments": true },
	"styles": {
		"spacing": {
			"padding": {
				"top": "0",
				"right": "var:preset|spacing|50",
				"bottom": "0",
				"left": "var:preset|spacing|50"
			}
		}
	}
}
```

## settings.appearanceTools

`"appearanceTools": true` opts into a set of controls in one line. The list grows between releases; the authoritative source is `WP_Theme_JSON::APPEARANCE_TOOLS_OPT_INS`. As of WordPress 6.6 it covers at least:

- `background.backgroundImage`, `background.backgroundSize`
- `border.color`, `border.radius`, `border.style`, `border.width`
- `color.link`, `color.heading`, `color.button`, `color.caption`
- `dimensions.aspectRatio`, `dimensions.minHeight`
- `position.sticky`
- `spacing.blockGap`, `spacing.margin`, `spacing.padding`
- `typography.lineHeight`

Treat this list as non-exhaustive. An explicit `false` for one of these keys overrides `appearanceTools` for that key. Setting the same keys to `true` alongside `appearanceTools` is redundant, not a finding.

## Other settings

- `settings.border`: `color`, `radius`, `style`, `width` (booleans).
- `settings.shadow`: `defaultPresets` (default `true`) and `presets` (`slug`, `shadow`, `name`), generating `--wp--preset--shadow--<slug>`.
- `settings.dimensions`: `aspectRatio`, `minHeight`.
- `settings.position`: `sticky`.
- `settings.blocks.<block-name>`: per-block overrides of any of the above.

Unknown keys are silently ignored, so a misspelled key (for example `useRootPaddingAwareAlignment`) has no effect. The `$schema` reference lets an editor catch these.

## styles

**Root styles** (`styles.color`, `styles.typography`, `styles.spacing`, ...) apply to `body`. `styles.css` (6.2+) is output globally, not scoped.

**Elements** (`styles.elements`): `link`, `heading`, `h1`-`h6`, `button`, `caption`, `cite`, among others. Pseudo-classes such as `:hover`, `:focus`, `:focus-visible` and `:active` are supported only on `link` and `button`; `:visited` is for links.

**Blocks** (`styles.blocks.<name>`): scoped to the block's selector. `styles.blocks.<name>.css` is scoped to that block. `styles.blocks.<name>.variations.<slug>` styles a registered block style, applied as the class `is-style-<slug>`; it does not apply to an arbitrary `className`.

**Origins.** Core defaults, then theme.json, then user Global Styles; later origins win. Within the generated stylesheet, block-level styles override element and root styles for that block.

**Preset references.** Both `"var:preset|color|primary"` and `"var(--wp--preset--color--primary)"` work in theme.json styles. Raw hex or px values in theme.json `styles` where a matching preset exists are INFO: the value still works and users can override it in Global Styles, but palette changes do not propagate to it. Raw values in template or part markup follow the WARNING rule in SKILL.md (hand-written styles only; block-serialized styles from comment attributes are valid).

```json
{
	"styles": {
		"color": {
			"background": "var:preset|color|background",
			"text": "var:preset|color|foreground"
		},
		"elements": {
			"link": {
				"color": { "text": "var:preset|color|primary" },
				":hover": {
					"color": { "text": "var:preset|color|secondary" }
				}
			}
		}
	}
}
```

## templateParts

```json
{
	"templateParts": [
		{ "name": "header", "title": "Header", "area": "header" },
		{ "name": "footer", "title": "Footer", "area": "footer" },
		{ "name": "sidebar", "title": "Sidebar", "area": "uncategorized" }
	]
}
```

- `name`: file name in `parts/` without the extension. `"header"` maps to `parts/header.html`.
- `title`: label shown in the editor.
- `area`: `header`, `footer` or `uncategorized` (the default). Custom areas only come from the `default_wp_template_part_areas` PHP filter, not theme.json.

Findings:

- An entry with no matching file: WARNING. This includes a `name` ending in `.html` (`"header.html"` looks for `parts/header.html.html`). Fix: `"name": "header"`.
- A `parts/` file not registered in `templateParts`: INFO. It still works, but gets no title or area.

## customTemplates

```json
{
	"customTemplates": [
		{ "name": "page-no-title", "title": "Page Without Title", "postTypes": ["page"] },
		{ "name": "single-wide", "title": "Wide Post", "postTypes": ["post"] }
	]
}
```

- `name` maps to `templates/<name>.html`.
- `postTypes` limits where the template is offered. When omitted, it defaults to `["page"]` only, so a template meant for posts or custom post types must list them.
- A non-hierarchy template in `templates/` not registered here: INFO.

## patterns

`patterns` lists slugs from the WordPress.org Pattern Directory, which core fetches and registers. These are directory slugs (for example `"partner-logos"`), not `namespace/name` pattern names. Theme-bundled patterns in `patterns/*.php` register on `init` from their file headers and do not belong in this key. A missing `patterns` key or `patterns/` directory is not a finding.

## Validation

- **Invalid JSON: CRITICAL.** Common causes: trailing commas, unquoted keys, single quotes, comments. Check with `python3 -m json.tool theme.json` or `jq . theme.json`.
- **`version` type.** The schema defines `version` as an integer. Flag `"version": "3"` and fix to `3`. Low-confidence: core's runtime handling of a string version has not been verified here, so do not rate it above WARNING without testing.
- **Unknown keys.** Ignored silently; check spelling against the schema when a setting "does nothing".
- **Style variations.** Each JSON in `styles/` needs its own `version`. A missing `title` is INFO (the filename is used). Partial variations are normal.

## Findings table

| Finding | Severity | Fix |
|---------|----------|-----|
| Missing `version` (theme.json or style variation) | CRITICAL | Add `"version": 3`. Without it the whole file is discarded. |
| Invalid JSON | CRITICAL | Fix the syntax. |
| v3 `fontSizes` slug collides with a core slug, `defaultFontSizes` not `false` | CRITICAL | Set `"defaultFontSizes": false` or rename the slug. |
| v3 `spacingSizes`/`spacingScale` slug collides with a core slug, `defaultSpacingSizes` not `false` | CRITICAL | Set `"defaultSpacingSizes": false` or rename the slug. |
| v3 custom `fontSizes`/`spacingSizes`, no collision, `default*Sizes` not `false` (a `spacingScale` with `steps` > 0 counts as a collision: CRITICAL) | WARNING | Set the matching `default*Sizes` to `false` (duplicate "Default" group otherwise). |
| `useRootPaddingAwareAlignments: true` with shorthand string root padding | CRITICAL | Use the `{top, right, bottom, left}` object. |
| Root left/right padding without `useRootPaddingAwareAlignments` | WARNING | Add `"useRootPaddingAwareAlignments": true`. |
| v1 | WARNING | Upgrade to v3 with current key names. |
| v2 | WARNING | Upgrade to v3 (see migration steps). |
| `templateParts` entry with no file, including a `name` ending in `.html` | WARNING | Point `name` at an existing file, without the extension. |
| Missing `layout.contentSize` or `wideSize` (block theme) | WARNING | Add both. |
| `fontFace` path without `file:` | WARNING | Use `"file:./assets/fonts/<file>.woff2"`. |
| Google Fonts or CDN in `fontFace` | CRITICAL (WordPress.org) / INFO (otherwise) | Bundle the font files. |
| Raw hex/px in theme.json `styles` where a preset exists | INFO | Reference the preset. |
| Missing `$schema` | INFO | Add the schema URL. |
| `parts/` file not in `templateParts` | INFO | Register it with a title and area. |
| Template not in `customTemplates` | INFO | Register it. |
| Absent palette, `fontSizes` or `spacingSizes` | Not a problem | |
| Hex values inside `palette` | Not a problem | |

## WordPress.org context

These apply only when the theme targets the WordPress.org directory. Each is CRITICAL in that context:

- Any Theme Check required-level error (Appearance > Theme Check).
- Google Fonts or another external CDN, including in `fontFace.src`.
- A missing required header or file: Theme Name, Author, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain, readme.txt, screenshot.png.
- Non-GPL-compatible assets (fonts, images, scripts). Bundled resources should have their copyright and license declared in readme.txt.

theme.json itself must have `version` and be valid JSON; both are CRITICAL in every context. A v1 or v2 file stays WARNING here too.

Accessibility checks (WCAG AA contrast, keyboard navigation, skip links, visible focus) are required only for themes using the `accessibility-ready` tag.

These remain WARNING and are not rejection reasons on their own:

- Hand-written inline styles or hex colors in templates or parts.
- Root left/right padding without `useRootPaddingAwareAlignments`.

## Cross-references

- Template structure and hierarchy: template-patterns.md
- Full Site Editing features and theme pattern registration: fse-guide.md
- Classic to block theme migration: classic-to-block-guide.md
- Classic template security: `/wp-security`
