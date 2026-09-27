# Severity and Report Format

## Severity

| Severity | Definition | Examples |
|----------|------------|----------|
| **CRITICAL** | Theme won't work OR WordPress.org rejection | Missing required files (templates/index.html, theme.json, style.css), theme.json version missing or not 3, missing style.css "Theme Name" header, template hierarchy violations, child theme missing "Template:" header, theme.json with custom fontSizes/spacingSizes but missing defaultFontSizes/defaultSpacingSizes: false (WordPress defaults override theme), useRootPaddingAwareAlignments with CSS shorthand padding (must use object notation), pattern file missing Title or Slug header |
| **WARNING** | Theme works but has quality/compatibility issues | hardcoded styles in block theme templates (inline style attributes, hardcoded hex colors, pixel font sizes), missing useRootPaddingAwareAlignments with root padding (full-width blocks won't reach edges), add_theme_support() calls whose settings belong in theme.json (editor-color-palette, editor-font-sizes, custom-line-height, custom-spacing should be in theme.json), missing ABSPATH check in functions.php, template part files without theme.json registration, hardcoded WordPress paths (/wp-content/themes/) |
| **INFO** | Best practice improvements OR optimization opportunities | Missing $schema in theme.json (IDE validation), missing style variations directory, missing block patterns directory, missing templateParts or customTemplates registration, Google Fonts CDN instead of local fonts (GDPR, performance), could add specific templates (single.html, page.html) for better hierarchy, child theme could use unregister_block_pattern() to remove parent patterns, missing version requirements in style.css (Requires at least, Tested up to, Requires PHP) |

## Report Format

Report findings grouped by FILE (PHP, HTML, and JSON files mixed, in path order), with line numbers and severity labels, and a BAD/GOOD code pair for each finding. End the SUMMARY with one verdict line: `SHIP` (no CRITICAL or WARNING), `FIX WARNINGS`, or `DO NOT SHIP` (any CRITICAL).

~~~markdown
# WordPress Theme Review: my-theme

## Theme Type: Block Theme
**Detected:** templates/index.html + theme.json + style.css

## FILE: theme.json

### Line 14: CRITICAL - Custom fontSizes without defaultFontSizes: false
The theme defines its own font sizes, but WordPress's default sizes are still shown next to them in the editor.

❌ **BAD:**
```json
{
	"version": 3,
	"settings": {
		"typography": {
			"fontSizes": [ /* custom sizes */ ]
		}
	}
}
```

✅ **GOOD:**
```json
{
	"version": 3,
	"settings": {
		"typography": {
			"defaultFontSizes": false,
			"fontSizes": [ /* custom sizes */ ]
		}
	}
}
```

### Line 45: WARNING - Missing useRootPaddingAwareAlignments
Root-level padding present but useRootPaddingAwareAlignments not set. Full-width blocks won't reach viewport edges.

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

### Line 8: WARNING - Hardcoded inline style
Inline style attribute defeats theme.json purpose. Users can't customize via Site Editor.

❌ **BAD:**
```html
<div style="max-width: 1200px; padding: 2rem;">
```

✅ **GOOD:**
```html
<!-- wp:group {"layout":{"type":"constrained"}} -->
<div class="wp-block-group">
```

## FILE: functions.php

### Line 1: WARNING - Missing ABSPATH check
Add ABSPATH check at top of file to prevent direct access.

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

### Line 15: WARNING - Color palette set with add_theme_support()
The palette belongs in theme.json, where the Site Editor and Global Styles can use it.

❌ **BAD:**
```php
add_theme_support( 'editor-color-palette', array(
	array( 'name' => 'Primary', 'slug' => 'primary', 'color' => '#0073aa' ),
) );
```

✅ **GOOD:**
```json
// In theme.json:
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
Add Requires at least, Tested up to, Requires PHP for version enforcement.

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
- CRITICAL: 1
- WARNING: 3 (quality/compatibility improvements needed)
- INFO: 2 (best practice enhancements)

**Hardcoded styles:** Found in templates. Replace them with theme.json presets so users can customize them.
**Verdict:** DO NOT SHIP
~~~

## Not a Bug

Patterns that look like issues but are NOT problems:

| Pattern | Why It's NOT a Problem | Context |
|---------|------------------------|---------|
| **Block theme with minimal style.css** | Block themes use theme.json for styling, style.css is primarily metadata | Correct for block themes - style.css contains theme header, minimal CSS |
| **Template part without theme.json registration** | Template parts work by filename, registration is for UI labels only | Works correctly - registration enhances Site Editor UI but not required |
| **Style variation missing some settings sections** | Variations only need to override specific settings, not full schema | Intentional - variations merge with main theme.json |
| **Block template without template-part blocks** | Not all templates need header/footer, valid for custom layouts | Intentional for special templates (404, search results without chrome) |
| **functions.php with add_theme_support() in block theme** | Some add_theme_support() calls are still valid (wp-block-styles, responsive-embeds, editor-styles) | Valid - these can't be replaced by theme.json |
| **Pattern file with only static markup (no PHP)** | If pattern doesn't need dynamic values, static HTML is fine | Valid - PHP optional for static patterns |
| **Child theme without functions.php** | Child themes don't need functions.php if only overriding styles/templates | Valid minimal child theme - functions.php is optional |
| **Block theme without patterns/ directory** | Patterns are optional, not all themes need bundled patterns | Valid - themes can rely on WordPress.org pattern directory |
| **Missing viewScript in theme** | Themes typically don't need frontend JavaScript, unlike blocks | Expected - most themes are HTML/CSS only |
| **CSS variables in style.css referencing theme.json** | Correct usage - theme.json generates CSS variables that style.css can reference | Intentional integration between theme.json and style.css |

## Version Compatibility Reference

Quick reference for WordPress version requirements:

| Feature | WordPress Version | Notes |
|---------|-------------------|-------|
| Block themes (FSE) | 5.9+ | Full Site Editing stable release |
| theme.json version 3 | 6.6+ | Required by this procedure. Set defaultFontSizes/defaultSpacingSizes false when defining custom scales |
| useRootPaddingAwareAlignments | 6.1+ | Full-width alignment with root padding |
| Template parts areas | 6.0+ | header, footer, uncategorized areas |
| fontFace support in theme.json | 6.0+ | Local font hosting via theme.json |
| Block theme patterns (patterns/) | 6.3+ | Auto-registration of PHP pattern files |
| Navigation block | 5.9+ | Site menus, edited in the Site Editor |
| Site Editor | 5.9+ | Full Site Editing interface |
| Global Styles | 5.9+ | User customization of theme.json via UI |
| Style variations | 6.0+ | Alternate theme.json files in styles/ |
