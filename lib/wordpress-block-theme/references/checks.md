# File Checks

Check every file of each type present. Severity labels follow the definitions in `report-format.md`.

### theme.json

**version field:**
- CRITICAL: Missing version, or any value other than 3 → this procedure targets theme.json version 3 (WordPress 6.6+)
- Pattern: `"version": 3`

**$schema field:**
- INFO: Missing $schema → Can't validate in IDE
- Pattern: `"$schema": "https://schemas.wp.org/trunk/theme.json"`

**settings.color:**
- WARNING: Missing palette → Users can't customize colors via Site Editor
- WARNING: Hardcoded color hex values without palette definitions
- Pattern: color.palette array with slug, color, name
- Available properties: palette, gradients, duotone, custom, defaultPalette, link, heading, button, caption

**settings.typography:**
- WARNING: Missing fontSizes → Users can't customize font sizes
- CRITICAL: theme defines fontSizes but missing `"defaultFontSizes": false` → WordPress defaults override theme sizes
- WARNING: Using Google Fonts CDN instead of local font files (GDPR, performance)
- Pattern: typography.fontSizes array, fontFamilies with fontFace for local fonts
- Available properties: fontSizes, fontFamilies, fluid, lineHeight, fontWeight, letterSpacing, textDecoration, textTransform, defaultFontSizes

**settings.spacing:**
- WARNING: Missing spacingSizes → Users can't customize spacing via Site Editor
- CRITICAL: theme defines spacingSizes but missing `"defaultSpacingSizes": false` → WordPress defaults override theme sizes
- Pattern: spacing.spacingSizes array with slug, size, name
- Available properties: spacingSizes, padding, margin, blockGap, units, customSpacingSize, spacingScale, defaultSpacingSizes

**settings.layout:**
- WARNING: Missing contentSize and wideSize → Full-width blocks may not work correctly
- Pattern: `"contentSize": "640px", "wideSize": "1200px"`

**settings.useRootPaddingAwareAlignments:**
- WARNING: Missing useRootPaddingAwareAlignments with root-level padding → Full-width blocks won't reach viewport edges
- CRITICAL: useRootPaddingAwareAlignments true but padding uses CSS shorthand → Must use object notation
- Pattern: Set to true when styles.spacing.padding present

**styles section:**
- WARNING: Hardcoded values instead of CSS variables → Defeats theme.json purpose
- Pattern: Use `var(--wp--preset--color--primary)` not `"#0073aa"`
- Available properties: color, typography, spacing, border, shadow, elements, blocks

**templateParts array:**
- INFO: Missing templateParts registration → Template parts work but won't show in UI with proper labels
- Pattern: Array with name, title, area (header/footer/uncategorized)

**customTemplates array:**
- INFO: Missing customTemplates → Users can't select custom templates in editor
- Pattern: Array with name, title, postTypes

### style.css

**Required header fields:**
- CRITICAL: Missing "Theme Name" → WordPress won't recognize theme
- WARNING: Missing "Text Domain" → Internationalization won't work
- WARNING: Missing "Version" → Updates won't work correctly
- INFO: Missing "Requires at least", "Tested up to", "Requires PHP" → Can't enforce version requirements
- WordPress.org required: Theme Name, Theme URI, Author, Author URI, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain

**Block theme style patterns:**
- WARNING: Block theme with extensive CSS instead of theme.json → Defeats FSE purpose
- INFO: Could move hardcoded color/font values to theme.json presets
- Pattern: Block themes should have minimal style.css (metadata + critical CSS only), styling comes from theme.json

**Child theme patterns:**
- CRITICAL: Child theme missing "Template:" header → Won't inherit from parent
- WARNING: Child theme template not matching parent directory name → Won't find parent

### Block templates (templates/*.html)

**Required template:**
- CRITICAL: Missing templates/index.html in block theme → Theme won't work

**Template file naming:**
- INFO: Could add specific templates (single.html, page.html, archive.html, 404.html, search.html, home.html, front-page.html) for better hierarchy coverage

**Block markup validation:**
- CRITICAL: Invalid block comment syntax → Template won't parse
- WARNING: Hardcoded inline style attributes → Defeats theme.json, users can't customize
- WARNING: Hardcoded color hex values instead of theme.json presets
- WARNING: Hardcoded pixel font sizes instead of theme.json fluid typography
- Pattern: Use block attributes with theme.json preset references, not inline styles

**Template part usage:**
- WARNING: Missing template part references (header/footer) → Users expect standard structure
- Pattern: `<!-- wp:template-part {"slug":"header","area":"header"} /-->`

**useBlockProps equivalent:**
- INFO: Block templates don't need wrapper attributes like dynamic blocks (static HTML)

### Template parts (parts/*.html)

**Template part files:**
- WARNING: templateParts registered in theme.json but files missing → 404 in Site Editor
- WARNING: Template part files exist but not registered in theme.json → Won't show in UI with proper labels
- Pattern: parts/header.html, parts/footer.html, parts/sidebar.html

**Area designation:**
- WARNING: Template part area mismatch between theme.json and usage → May not render in correct location
- Available areas: header, footer, uncategorized (or custom areas in WP 6.0+)

**Block markup:**
- Same validation as block templates: no hardcoded styles, use theme.json presets

### functions.php

**ABSPATH check:**
- WARNING: Missing `defined( 'ABSPATH' ) || exit;` → Direct file access possible

**Block theme setup:**
- WARNING: add_theme_support() calls whose settings belong in theme.json (editor-color-palette, editor-font-sizes, custom-line-height, custom-spacing, custom-units) → Move the values into theme.json settings
- Acceptable add_theme_support() in block themes: wp-block-styles, responsive-embeds, editor-styles (theme.json can't replace these)

**Theme hooks:**
- Pattern: after_setup_theme for theme setup, wp_enqueue_scripts for assets, init for custom post types

**Asset enqueuing:**
- WARNING: Enqueuing assets on every page without conditional checks → Performance issue
- Pattern: Enqueue only what the theme needs; per-block styles via wp_enqueue_block_style() so they load only when the block is on the page

### Block patterns (patterns/*.php)

**Pattern file headers:**
- CRITICAL: Pattern file missing Title or Slug header → Won't register
- WARNING: Pattern slug not namespaced (themename/pattern-slug) → Collision risk
- Pattern: PHP file with comment block containing Title, Slug, Categories, Description, Keywords, Block Types, Viewport Width

**Pattern file structure:**
- WARNING: Pattern file without PHP tags → Won't process dynamic values
- Pattern: `<?php ?>` tags for PHP code, then block markup

**Block markup in patterns:**
- Same validation as templates: use theme.json presets, no hardcoded styles
- Use PHP functions for dynamic values: `get_theme_file_uri()`, `esc_url()`, `esc_html()`, translation functions

**Pattern registration:**
- INFO: Patterns in patterns/ directory auto-register, no manual register_block_pattern() needed (themes only, not plugins)

### Style variations (styles/*.json)

**Variation file structure:**
- WARNING: Style variation missing version field → May not load correctly
- WARNING: Style variation missing title → Shows filename in UI
- Pattern: JSON file with version, title, settings, styles

**Variation naming:**
- INFO: Variation filename becomes variation slug (dark.json → "dark"), title overrides display name
- Pattern: Use descriptive filenames (dark.json, minimal.json, high-contrast.json)

**Variation schema:**
- WARNING: Variation with invalid theme.json structure → Won't apply
- Pattern: Same schema as theme.json (settings, styles sections), version should match main theme.json

### Child themes

**Child theme detection:**
- Pattern: style.css with "Template:" header

**Template overrides:**
- WARNING: Child block theme parts/header.html doesn't override parent → Filename must match exactly
- WARNING: Child theme.json doesn't override parent templateParts → Must copy and modify templateParts array
- Pattern: Child theme files override parent by exact filename match

**Child theme compatibility:**
- WARNING: Child theme depends on parent template parts that might change → Fragile override
- INFO: Child theme could use unregister_block_pattern() to remove parent patterns

# Quick Scans

Run from the theme root. The hits decide the reading order, and every file they point to is read in full. A scan hit is a candidate, never a finding by itself.

### CRITICAL Patterns

```bash
# Missing required files for block theme
[ ! -f templates/index.html ] && [ -f theme.json ] && echo "CRITICAL: Block theme missing templates/index.html"
[ ! -f theme.json ] && [ -d templates ] && echo "CRITICAL: templates/ exists but theme.json missing"

# theme.json with invalid or missing version
test -f theme.json && ! rg -q "\"version\"" theme.json && echo "CRITICAL: theme.json missing version"
rg -n '"version"' theme.json styles/*.json  # every file must say 3

# Missing style.css required header
test -f style.css && ! rg -q "Theme Name:" style.css && echo "CRITICAL: style.css missing Theme Name header"

# theme.json with custom fontSizes but missing defaultFontSizes: false
rg -n "\"fontSizes\"" theme.json
# Manual follow-up: if custom fontSizes are defined, confirm defaultFontSizes is explicitly false.

# theme.json with custom spacingSizes but missing defaultSpacingSizes: false
rg -n "\"spacingSizes\"" theme.json
# Manual follow-up: if custom spacingSizes are defined, confirm defaultSpacingSizes is explicitly false.

# Child theme missing Template header
test -f style.css && ! rg -q "Template:" style.css && echo "CRITICAL: If this is a child theme, style.css is missing Template header"
```

### WARNING Patterns

```bash
# Hardcoded inline styles in block templates
rg -n "style=\"" templates/ parts/ -g '*.html'

# Hardcoded color hex values in templates
rg -n "#[0-9a-fA-F]{6}" templates/ parts/ -g '*.html'

# Hardcoded pixel font sizes in templates
rg -n "font-size:\s*[0-9]+px" templates/ parts/ -g '*.html'

# Root padding without useRootPaddingAwareAlignments
rg -n "\"padding\"" theme.json
# Manual follow-up: if root padding is present, confirm useRootPaddingAwareAlignments is enabled.

# useRootPaddingAwareAlignments with CSS shorthand padding (won't work)
rg -n "useRootPaddingAwareAlignments.*true" theme.json
rg -n "\"padding\":\s*\"" theme.json

# Block theme with add_theme_support() that should be in theme.json
rg -n "add_theme_support.*editor-color-palette" functions.php
rg -n "add_theme_support.*editor-font-sizes" functions.php
rg -n "add_theme_support.*custom-line-height" functions.php
rg -n "add_theme_support.*custom-spacing" functions.php

# Missing ABSPATH check in functions.php
test -f functions.php && ! sed -n '1,10p' functions.php | rg -q "defined.*ABSPATH" && echo "WARNING: functions.php missing ABSPATH check in first 10 lines"

# Pattern file without required headers
rg -L "Title:" patterns -g '*.php'
rg -L "Slug:" patterns -g '*.php'
```

### INFO Patterns

```bash
# Missing $schema in theme.json
test -f theme.json && ! rg -q "\"\\$schema\"" theme.json && echo "INFO: theme.json missing \$schema"

# Missing style variations directory
[ ! -d styles ] && echo "INFO: Could add style variations in styles/"

# Missing block patterns directory
[ ! -d patterns ] && echo "INFO: Could add block patterns in patterns/"

# Missing templateParts registration in theme.json
test -f theme.json && ! rg -q "\"templateParts\"" theme.json && echo "INFO: theme.json missing templateParts registration"

# Missing customTemplates registration in theme.json
test -f theme.json && ! rg -q "\"customTemplates\"" theme.json && echo "INFO: theme.json missing customTemplates registration"

# Google Fonts CDN usage (could use local fonts)
rg -n "fonts.googleapis.com" .

```
