# Review Report Format

Group findings by FILE (PHP, HTML, JSON intermixed by path). Give each finding a line number, severity, one-sentence impact, and BAD/GOOD pair. End with SUMMARY counts and hand-offs. Count every finding in the report exactly once, and make the SUMMARY totals add up.

## Full Example

````markdown
# WordPress Theme Review: my-theme

## Theme Type: Block Theme
**Detected:** templates/index.html + theme.json + style.css

## FILE: theme.json

### Line 2: WARNING - theme.json version 2 (upgrade to v3)
theme.json v2 still works, but v3 is current for WordPress 6.6+. When upgrading, set `defaultFontSizes` and `defaultSpacingSizes` to `false` if the theme defines its own sizes: core defaults are `prevent_override`, so theme presets with colliding slugs are silently ignored.

❌ **BAD:**
```json
{
	"version": 2
}
```

✅ **GOOD:**
```json
{
	"version": 3,
	"settings": {
		"typography": {
			"defaultFontSizes": false,
			"fontSizes": [
				{ "slug": "small", "size": "0.875rem", "name": "Small" }
			]
		}
	}
}
```

### Line 45: WARNING - Missing useRootPaddingAwareAlignments
Root left/right padding is set but `useRootPaddingAwareAlignments` is not, so full-width blocks don't reach the viewport edges.

❌ **BAD:**
```json
{
	"styles": {
		"spacing": {
			"padding": { "left": "2rem", "right": "2rem" }
		}
	}
}
```

✅ **GOOD:**
```json
{
	"settings": {
		"useRootPaddingAwareAlignments": true
	},
	"styles": {
		"spacing": {
			"padding": {
				"top": "2rem",
				"right": "2rem",
				"bottom": "2rem",
				"left": "2rem"
			}
		}
	}
}
```

## FILE: templates/single.html

### Line 8: WARNING - Hand-written inline style
Inline CSS that doesn't come from block attributes can't be edited in the Site Editor.

❌ **BAD:**
```html
<div style="max-width: 1200px; padding: 2rem;">
```

✅ **GOOD:**
```html
<!-- wp:group {"style":{"spacing":{"padding":{"top":"var:preset|spacing|50","bottom":"var:preset|spacing|50"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-group" style="padding-top:var(--wp--preset--spacing--50);padding-bottom:var(--wp--preset--spacing--50)">
</div>
<!-- /wp:group -->
```

## FILE: functions.php

### Line 1: INFO - Missing ABSPATH guard
Add an ABSPATH guard at the top of the file to stop direct access.

❌ **BAD:**
```php
<?php
function mytheme_setup() {
```

✅ **GOOD:**
```php
<?php
defined( 'ABSPATH' ) || exit;

function mytheme_setup() {
```

### Line 15: WARNING - add_theme_support() replaceable by theme.json
In a block theme, `editor-color-palette` belongs in theme.json `settings.color.palette`.

❌ **BAD:**
```php
add_theme_support( 'editor-color-palette', array(
	array( 'name' => 'Primary', 'slug' => 'primary', 'color' => '#0073aa' ),
) );
```

✅ **GOOD:** Remove the call and add the palette to theme.json:
```json
{
	"settings": {
		"color": {
			"palette": [
				{ "slug": "primary", "color": "#0073aa", "name": "Primary" }
			]
		}
	}
}
```

## FILE: style.css

### Line 1: INFO - Missing version requirements
Add `Requires at least`, `Tested up to` and `Requires PHP` so WordPress can enforce version requirements.

```css
/*
Theme Name: My Theme
Version: 1.0.0
Requires at least: 6.6
Tested up to: 6.7
Requires PHP: 7.4
*/
```

## SUMMARY

**Total issues: 6**
- CRITICAL: 0
- WARNING: 4 (theme.json v2, useRootPaddingAwareAlignments, hand-written inline style, add_theme_support)
- INFO: 2 (ABSPATH guard, version requirement headers)

**Upgrade recommendation:** Update theme.json to v3, setting `defaultFontSizes` and `defaultSpacingSizes` to `false` when the theme defines its own sizes.
**Hand-written styles:** Found in templates. Move them to block attributes that reference theme.json presets.
**Hand-offs:**
- Run `/wp-security` for escaping and security depth.
- Run `/wp-review` if functions.php contains plugin territory (custom post types, taxonomies, REST endpoints).
````
