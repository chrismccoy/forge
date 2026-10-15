# WordPress Full Site Editing (FSE) Review Guide

## Contents

- Quick Reference
- Global Styles
- Style Variations
- Block Patterns in Themes
- Navigation
- Font Management
- Layout System
- Custom CSS in theme.json
- Block Locking
- WordPress.org Submission
- Anti-Patterns
- Cross-References

Reference for reviewing Full Site Editing features in block themes (WordPress 6.6+): global styles, style variations, theme patterns, navigation, fonts, layout, custom CSS and block locking. Severities follow the canonical model in SKILL.md (CRITICAL, WARNING, INFO, NOT a problem).

## Quick Reference

| Feature | Files | theme.json section | WP version |
|---------|-------|--------------------|------------|
| Global Styles | theme.json | settings, styles | 5.9+ |
| Style Variations | styles/*.json | standalone files | 6.0+ |
| Block Patterns | patterns/*.php | N/A (auto-registered) | 6.0+ |
| Navigation | templates/*.html, parts/*.html with wp:navigation | N/A | 5.9+ |
| Templates | templates/*.html | customTemplates (optional) | 5.9+ |
| Template Parts | parts/*.html | templateParts | 5.9+ |
| Fonts | theme.json, assets/fonts/* | settings.typography.fontFamilies | 6.0+ |
| Custom CSS | theme.json | styles.css, styles.blocks.<name>.css | 6.2+ |

**Hard rule (CRITICAL):** PHP never executes in block theme `.html` templates or parts. Any `<?php` in a `.html` file is broken: the code never runs. The fix is one of:
- a PHP pattern in `patterns/`, included with `<!-- wp:pattern {"slug":"theme/name"} /-->`,
- a core block (site-title, post-date, query, and so on),
- static text.

## Global Styles

theme.json defines defaults. User changes made in Appearance > Editor > Styles are saved in a `wp_global_styles` post and merged over theme.json at runtime. In classic and hybrid themes, theme.json still affects the editor and also outputs frontend global styles and preset CSS variables.

### Mapping presets to styles

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"settings": {
		"color": {
			"palette": [
				{"slug": "background", "color": "#ffffff", "name": "Background"},
				{"slug": "foreground", "color": "#1a1a1a", "name": "Foreground"},
				{"slug": "primary", "color": "#0073aa", "name": "Primary"}
			]
		}
	},
	"styles": {
		"color": {
			"background": "var(--wp--preset--color--background)",
			"text": "var(--wp--preset--color--foreground)"
		},
		"typography": {
			"fontSize": "var(--wp--preset--font-size--medium)"
		}
	}
}
```

Review points:
- Every `var(--wp--preset--color--<slug>)` referenced in `styles` must exist in the palette (theme or core default). A reference to an undefined slug silently resolves to nothing.
- `medium` above is a core default font size slug, so it resolves without a theme `fontSizes` entry. An absent palette, fontSizes or spacingSizes is NOT a problem.
- Hex values inside the palette are NOT a problem.

### Style precedence (highest first)

1. Block-level attributes (the `style`, `backgroundColor`, `fontSize` and similar attributes on a block instance).
2. User global styles (`wp_global_styles`).
3. Theme styles (child theme.json merged over parent theme.json).
4. Core defaults.

Values hardcoded in templates outrank global styles, so a template that hardcodes colors or sizes stops users changing them from the Styles panel. This is why hand-written inline styles and raw values in templates are WARNING.

## Style Variations

### File format

Files in `styles/` (subdirectories are also read). Example `styles/dark.json`:

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"title": "Dark",
	"settings": {
		"color": {
			"palette": [
				{"slug": "background", "color": "#1a1a1a", "name": "Background"},
				{"slug": "foreground", "color": "#ffffff", "name": "Foreground"},
				{"slug": "primary", "color": "#3dadff", "name": "Primary"}
			]
		}
	},
	"styles": {
		"color": {
			"background": "var(--wp--preset--color--background)",
			"text": "var(--wp--preset--color--foreground)"
		},
		"elements": {
			"link": {
				"color": {
					"text": "var(--wp--preset--color--primary)"
				}
			}
		}
	}
}
```

| Field | Status | Severity if missing |
|-------|--------|---------------------|
| `version` | Required | CRITICAL. Without it, `WP_Theme_JSON_Schema::migrate()` replaces the contents with `{version: LATEST}` and the whole variation is discarded. |
| `title` | Optional | INFO. The filename without extension is used instead (`dark.json` shows as "dark"). |
| `$schema` | Optional | INFO. |
| `settings`, `styles` | Optional | NOT a problem. Partial variations are fine. |

Each variation is migrated independently, so its `version` does not need to match the main theme.json. It only has to exist. A v1 or v2 variation is WARNING, as for theme.json.

The v3 preset-slug rules also apply to variations: a variation defining `fontSizes` or `spacingSizes` with core slugs while `defaultFontSizes`/`defaultSpacingSizes` is not `false` (in the merged settings) is CRITICAL, because the core defaults win.

### What variations can change

Variation `settings` and `styles` are merged over the theme's own, so a variation can change palettes, font families, font sizes, spacing, layout sizes (`settings.layout.contentSize`/`wideSize`) and any style property. A variation is a starting point: users can customize further after selecting it.

`customTemplates`, `templateParts` and `patterns` belong in the main theme.json. In a variation they are not expected to have any effect (low confidence; verify before flagging).

### Variation types (6.6+)

- A file with a `blockTypes` key is a block style variation (section style), applied to the listed blocks as `is-style-<slug>`. It is not a theme-wide variation and does not appear under Browse styles.
- A variation containing only color, or only typography, settings and styles is offered as a color or typography preset in the Styles panel rather than as a full style.

## Block Patterns in Themes

### Pattern file structure

Files in `patterns/` with a PHP header comment. Patterns may contain PHP; static pattern files without PHP are NOT a problem. Example `patterns/hero.php`:

```php
<?php
/**
 * Title: Hero
 * Slug: mytheme/hero
 * Categories: banner, featured
 * Keywords: hero, banner
 * Viewport Width: 1400
 * Description: Full-width hero with heading, text and a button.
 */
?>
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|60","bottom":"var:preset|spacing|60"}}},"backgroundColor":"primary","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull has-primary-background-color has-background" style="padding-top:var(--wp--preset--spacing--60);padding-bottom:var(--wp--preset--spacing--60)">
	<!-- wp:heading {"textAlign":"center","level":1,"fontSize":"xx-large"} -->
	<h1 class="wp-block-heading has-text-align-center has-xx-large-font-size"><?php echo esc_html_x( 'Welcome to Our Site', 'Pattern placeholder text', 'mytheme' ); ?></h1>
	<!-- /wp:heading -->

	<!-- wp:paragraph {"align":"center"} -->
	<p class="has-text-align-center"><?php echo esc_html_x( 'Discover our content and services.', 'Pattern placeholder text', 'mytheme' ); ?></p>
	<!-- /wp:paragraph -->

	<!-- wp:image {"sizeSlug":"large","align":"center"} -->
	<figure class="wp-block-image aligncenter size-large"><img src="<?php echo esc_url( get_theme_file_uri( 'assets/images/hero.jpg' ) ); ?>" alt=""/></figure>
	<!-- /wp:image -->

	<!-- wp:buttons {"layout":{"type":"flex","justifyContent":"center"}} -->
	<div class="wp-block-buttons">
		<!-- wp:button -->
		<div class="wp-block-button"><a class="wp-block-button__link wp-element-button"><?php echo esc_html_x( 'Get Started', 'Pattern placeholder text', 'mytheme' ); ?></a></div>
		<!-- /wp:button -->
	</div>
	<!-- /wp:buttons -->
</div>
<!-- /wp:group -->
```

The markup round-trips: `backgroundColor` produces `has-primary-background-color has-background`, the `style.spacing.padding` object produces the matching inline `padding-*` declarations, and `fontSize` produces `has-xx-large-font-size`. Those inline declarations are block-serialized, not hand-written; never flag them.

### Pattern header fields

| Field | Required | Notes |
|-------|----------|-------|
| `Title` | Yes | Missing is CRITICAL. |
| `Slug` | Yes | Missing is CRITICAL. Convention is `themeslug/pattern-name`. |
| `Categories` | No | Comma-separated category slugs. |
| `Keywords` | No | Search terms. |
| `Block Types` | No | For example `core/template-part/header`. |
| `Post Types` | No | Limits where the pattern is offered. |
| `Template Types` | No | Offers the pattern when creating those templates. |
| `Viewport Width` | No | Preview width in pixels. |
| `Description` | No | Shown in the inserter. |
| `Inserter` | No | `no` hides the pattern from the inserter (still usable via `wp:pattern`). |

Core category slugs include banner, buttons, call-to-action, columns, featured, footer, gallery, header, media, posts, query, text, and others. A custom category must be registered with `register_block_pattern_category()` on `init`; an unregistered category slug leaves the pattern under "Uncategorized".

### Registration

`patterns/*.php` files are registered on `init` on every request (`_register_theme_block_patterns()`). Since 6.4 the file list is cached. They are not scanned "on activation". Parent and child theme patterns are both registered. No `register_block_pattern()` call is needed for files in `patterns/`.

### Dynamic content in patterns

PHP in a pattern runs when the pattern is registered or rendered, and the resulting markup is what gets inserted. Use it for:
- theme asset URLs (`get_theme_file_uri()`),
- translatable text (`esc_html_x()`, `esc_html__()`).

When a pattern is inserted into a post, its output is saved as static content. A PHP loop over `get_posts()` therefore freezes the list at insertion time; live lists need a `core/query` block. Also avoid assigning to `$post` in pattern PHP, as it overwrites the global.

Escape all output in pattern PHP (`esc_html()`, `esc_attr()`, `esc_url()`). Escaping depth belongs to `/wp-security`.

## Navigation

```html
<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"},"style":{"spacing":{"blockGap":"var:preset|spacing|40"}}} /-->
```

Review points:
- Menus are stored as `wp_navigation` posts. A template or part that hardcodes `"ref":<id>` points at a post ID that exists only on the author's site. On other sites the block falls back. Prefer no `ref` in shipped templates, or put the links as inner `core/navigation-link` blocks.
- Without a `ref`, the block uses the most recent `wp_navigation` menu, a classic menu converted to blocks, or a Page List fallback. This cannot be configured in theme.json.
- Block-level settings can be scoped with `settings.blocks["core/navigation"]` in theme.json.

## Font Management

### Local fonts via theme.json

```json
{
	"version": 3,
	"settings": {
		"typography": {
			"fontFamilies": [
				{
					"fontFamily": "\"Inter\", -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
					"name": "Inter",
					"slug": "inter",
					"fontFace": [
						{
							"fontFamily": "Inter",
							"fontWeight": "100 900",
							"fontStyle": "normal",
							"src": ["file:./assets/fonts/inter-variable.woff2"]
						},
						{
							"fontFamily": "Inter",
							"fontWeight": "400",
							"fontStyle": "italic",
							"src": ["file:./assets/fonts/inter-italic.woff2"]
						}
					]
				}
			]
		}
	}
}
```

Core generates the `@font-face` rules and the variable `--wp--preset--font-family--inter`.

Review points:
- `src` paths use `file:./` relative to the theme root. Check each referenced file exists.
- `fontFace.fontFamily` must match the family name used in `fontFamily`.
- A range such as `"100 900"` is correct for a variable font.
- `.woff2` is the preferred format. `.ttf`/`.otf` work but are larger; this is not a severity-model finding.
- `src` pointing at Google Fonts or another external CDN: CRITICAL in a WordPress.org context, INFO otherwise.

### Font licensing (WordPress.org)

- Fonts must be GPL-compatible. SIL Open Font License fonts are accepted. Non-GPL-compatible assets are CRITICAL in a WordPress.org context.
- Copyright and license information for bundled fonts (and other third-party resources) goes in `readme.txt`, not in `LICENSE.txt`.

## Layout System

### contentSize and wideSize

```json
{
	"version": 3,
	"settings": {
		"layout": {
			"contentSize": "640px",
			"wideSize": "1200px"
		}
	}
}
```

- `contentSize`: max width of blocks with no alignment inside a constrained layout.
- `wideSize`: max width of `alignwide` blocks.
- `alignfull`: the full width of the container. With root padding and `useRootPaddingAwareAlignments`, full-width blocks extend to the viewport edges through negative margins.

Missing `contentSize`/`wideSize` in a block theme is WARNING.

| Attribute | Class | Width |
|-----------|-------|-------|
| none | none | contentSize |
| `"align":"wide"` | `alignwide` | wideSize |
| `"align":"full"` | `alignfull` | full container width |

### Root padding

See theme-json-guide.md for full `useRootPaddingAwareAlignments` coverage. Summary:

```json
{
	"version": 3,
	"settings": {
		"useRootPaddingAwareAlignments": true
	},
	"styles": {
		"spacing": {
			"padding": {
				"top": "0",
				"right": "var:preset|spacing|40",
				"bottom": "0",
				"left": "var:preset|spacing|40"
			}
		}
	}
}
```

- `useRootPaddingAwareAlignments: true` with root `styles.spacing.padding` written as a shorthand string: CRITICAL. Use the object form above.
- Root left/right padding without `useRootPaddingAwareAlignments`: WARNING. Top/bottom-only padding never needs it.

## Custom CSS in theme.json

### styles.css (6.2+)

```json
{
	"version": 3,
	"styles": {
		"css": ".site-tagline::before { content: \"\\2014 \"; }",
		"blocks": {
			"core/button": {
				"css": "& .wp-block-button__link { text-underline-offset: 0.2em; }"
			}
		}
	}
}
```

- Root `styles.css` is output globally as written. It is not scoped to `.wp-site-blocks` or any other selector.
- Per-block `styles.blocks.<name>.css` is scoped to that block's selector; `&` refers to the block selector.
- Use it for what theme.json properties cannot express (pseudo-elements, complex selectors). No preprocessing or `@import`.
- Users can override it from Additional CSS in the Styles panel.

## Block Locking

### lock attribute

```html
<!-- wp:group {"lock":{"move":true,"remove":true}} -->
<div class="wp-block-group">
	<!-- wp:site-title /-->
</div>
<!-- /wp:group -->
```

- `"move": true`: the block cannot be moved.
- `"remove": true`: the block cannot be deleted.

### templateLock (inner blocks)

```html
<!-- wp:group {"templateLock":"all"} -->
<div class="wp-block-group">
	<!-- wp:paragraph -->
	<p>Locked content.</p>
	<!-- /wp:paragraph -->
</div>
<!-- /wp:group -->
```

| Value | Effect |
|-------|--------|
| `"all"` | Prevents moving, inserting and removing inner blocks. |
| `"insert"` | Prevents inserting and removing; moving is allowed. |
| `"contentOnly"` | Only content can be edited; blocks cannot be moved, inserted, removed or restyled. |
| `false` | No restriction (overrides an inherited lock). |

Locking is not in the severity model. Heavy locking in shipped templates reduces user flexibility; mention it in prose only if it obviously blocks normal editing.

## WordPress.org Submission

Apply this section only in a WordPress.org context. These are the block-theme items that matter for submission.

CRITICAL (rejection):
- Any Theme Check required-level error.
- A missing required header or file: Theme Name, Author, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain, readme.txt, screenshot.png.
- No `templates/index.html` (or legacy `block-templates/index.html`) and no `index.php`.
- Google Fonts or another external CDN.
- Non-GPL-compatible assets, including fonts and images.

Not requirements:
- theme.json v3 is not required. v1 is WARNING (deprecated, still migrated at runtime) and v2 is WARNING (upgrade to v3). A missing `version` is CRITICAL.
- Color contrast (WCAG AA) is only required for themes using the `accessibility-ready` tag. Without that tag, do not treat contrast as a rejection reason.
- Hand-written inline styles, hex colors and px font sizes in templates or parts are WARNING-level quality issues, not rejection reasons. Block-serialized styles that match the comment attributes are valid and never flagged.

Good practice:
- Colors, typography and spacing come from theme.json presets.
- readme.txt lists copyright and license for every bundled third-party resource, including fonts and images.
- Test with Theme Unit Test data and the Theme Check plugin (Appearance > Theme Check), and check every style variation renders.

## Anti-Patterns

### Hand-written inline styles in templates (WARNING)

BAD:

```html
<div style="background-color: #333; font-size: 18px;">
	<!-- wp:post-title /-->
</div>
```

The raw `<div>` is outside any block, so the editor cannot edit it, and the hardcoded values bypass global styles.

GOOD:

```html
<!-- wp:group {"style":{"spacing":{"padding":{"top":"var:preset|spacing|40","bottom":"var:preset|spacing|40"}}},"backgroundColor":"primary","fontSize":"medium","layout":{"type":"constrained"}} -->
<div class="wp-block-group has-primary-background-color has-background has-medium-font-size" style="padding-top:var(--wp--preset--spacing--40);padding-bottom:var(--wp--preset--spacing--40)">
	<!-- wp:post-title /-->
</div>
<!-- /wp:group -->
```

Preset slugs go in `backgroundColor` and `fontSize`, which produce the `has-*` classes. Padding is an object of `var:preset|spacing|<slug>` values, which serializes to the matching inline declarations.

### PHP in a .html template (CRITICAL)

BAD (`parts/footer.html`):

```html
<!-- wp:paragraph -->
<p>&copy; <?php echo date( 'Y' ); ?> My Site</p>
<!-- /wp:paragraph -->
```

The PHP never runs. GOOD: move the dynamic markup to `patterns/footer-copyright.php` (with `Title`, `Slug` and `Inserter: no` headers) and include it:

```html
<!-- wp:pattern {"slug":"mytheme/footer-copyright"} /-->
```

### Google Fonts CDN

BAD:

```json
{
	"fontFace": [
		{
			"fontFamily": "Inter",
			"src": ["https://fonts.googleapis.com/css2?family=Inter"]
		}
	]
}
```

External dependency and a privacy concern. CRITICAL in a WordPress.org context, INFO otherwise.

GOOD: bundle the font locally.

```json
{
	"fontFace": [
		{
			"fontFamily": "Inter",
			"fontWeight": "400",
			"fontStyle": "normal",
			"src": ["file:./assets/fonts/inter-regular.woff2"]
		}
	]
}
```

### Pattern slug without namespace

BAD: `Slug: hero`. GOOD: `Slug: mytheme/hero`. The namespace avoids collisions with core and plugin patterns. This is a convention, not a severity-model finding.

## Cross-References

- theme.json v3 reference: theme-json-guide.md
- Template structure and hierarchy: template-patterns.md
- Classic to block migration: classic-to-block-guide.md
- Custom block development: `/wp-build`
- Escaping and security in theme PHP: `/wp-security`
- Plugin-territory functionality found in a theme: `/wp-review`
