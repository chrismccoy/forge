# Per-File Review Checklist

Detailed checks by file type, with severity and impact. Load during step 3 of the review workflow in SKILL.md.

Severities follow the canonical model: CRITICAL (breaks, or WordPress.org rejects it), WARNING (works, but has quality issues), INFO (opportunity). Items listed as "Not a problem" are never reported.

## theme.json

**version field:**
- CRITICAL: Missing `version` → `WP_Theme_JSON_Schema::migrate()` replaces the contents with `{version: LATEST}`, so the whole file is discarded
- CRITICAL: theme.json is not valid JSON
- WARNING: `"version": 1` → Deprecated; core still migrates it at runtime, but upgrade to v3
- WARNING: `"version": 2` → Upgrade to v3 (6.6+); review the `defaultFontSizes`/`defaultSpacingSizes` behavior when upgrading
- Pattern: `"version": 3`

**$schema field:**
- INFO: Missing `$schema` → No IDE validation or autocomplete
- Pattern: `"$schema": "https://schemas.wp.org/trunk/theme.json"`

**settings.color:**
- Not a problem: No `palette` (core defaults apply)
- Not a problem: Hex values inside `palette` (that is where raw colors belong)
- Pattern: `color.palette` array with slug, color, name

**settings.typography:**
- Not a problem: No `fontSizes` (core defaults apply)
- CRITICAL (v3): Theme `fontSizes` use a core slug (small, medium, large, x-large, xx-large) while `defaultFontSizes` is not `false` → Core defaults are `prevent_override`, so the colliding theme values are silently ignored
- WARNING (v3): Theme `fontSizes` with no slug collision while `defaultFontSizes` is not `false` → A duplicate "Default" preset group appears in the UI
- Google Fonts or another external font CDN: INFO normally (local `fontFace` files are better for privacy); CRITICAL in a WordPress.org context
- Pattern: `typography.fontSizes` array; `fontFamilies` with `fontFace` pointing to `file:./assets/fonts/...`

**settings.spacing:**
- Not a problem: No `spacingSizes` (core defaults apply)
- CRITICAL (v3): Theme `spacingSizes` use a core slug (20, 30, 40, 50, 60, 70, 80) while `defaultSpacingSizes` is not `false` → Core defaults are `prevent_override`, so the colliding theme values are silently ignored
- WARNING (v3): Theme `spacingSizes` with no slug collision (a `spacingScale` with `steps` > 0 always collides: CRITICAL) while `defaultSpacingSizes` is not `false` → A duplicate "Default" preset group appears in the UI
- Pattern: `spacing.spacingSizes` array with slug, size, name

**settings.layout:**
- WARNING: Block theme missing `contentSize` or `wideSize` → Constrained layouts and wide/full alignment have no reference widths
- Pattern: `"contentSize": "640px", "wideSize": "1200px"`

**settings.useRootPaddingAwareAlignments:**
- WARNING: Root `styles.spacing.padding` sets `left`/`right` without `useRootPaddingAwareAlignments` → Full-width blocks don't reach the viewport edges. Top/bottom-only padding never needs it.
- CRITICAL: `useRootPaddingAwareAlignments: true` with root `styles.spacing.padding` written as a shorthand string → Must use object notation (`top`, `right`, `bottom`, `left`)

**styles section:**
- INFO: Raw values in theme.json `styles` where a preset exists (for example `"#0073aa"` when a `primary` palette color exists) → Global Styles changes don't propagate
- Pattern: `var(--wp--preset--color--primary)` or `var:preset|color|primary`
- Facts: A root `styles.css` (6.2+) is output globally, not scoped. `styles.blocks.<name>.css` is scoped to that block's selector. `styles.blocks.<name>.variations.<slug>` styles a registered block style (class `is-style-<slug>`), not an arbitrary `className`.

**templateParts array:**
- WARNING: Entry registered with no matching file in `parts/`, including a `name` ending in `.html` (the name is the filename without extension)
- INFO: A `parts/` file not registered → Works by filename, but has no title or area in the UI
- Pattern: Array with name, title, area. Valid areas are header, footer, uncategorized; custom areas only come from the `default_wp_template_part_areas` filter.

**customTemplates array:**
- INFO: A non-hierarchy template in `templates/` not registered in `customTemplates` → Not selectable in the editor's template picker
- Pattern: Array with name, title, postTypes

## style.css

**Required header fields:**
- CRITICAL: `style.css` missing, or `Theme Name` missing → WordPress won't recognize the theme
- WARNING: Missing `Text Domain` → Translation tools can't identify the domain (runtime falls back to the theme slug)
- WARNING: Missing `Version` → Cache-busting via `wp_get_theme()->get( 'Version' )` and update display break
- INFO: Missing `Requires at least`, `Tested up to` or `Requires PHP` (outside a WordPress.org context)
- WordPress.org context: see "WordPress.org submission" below

**Block theme style.css:**
- INFO: Hardcoded color/font values in style.css could move to theme.json presets
- Pattern: Block themes keep style.css minimal (metadata plus CSS theme.json can't express)

**Child themes:**
- A child theme is identified by the `Template:` header. Without it, the theme is treated as standalone and must pass the index template check below (CRITICAL if it has neither `templates/index.html` nor `index.php`).
- CRITICAL: `Template:` value doesn't match an installed parent directory name → WordPress reports the parent as missing and the theme is broken

## Block templates (templates/*.html)

**Required template:**
- CRITICAL: Non-child theme with neither `templates/index.html` (or legacy `block-templates/index.html`) nor `index.php`
- WARNING: Block theme without theme.json

**Markup:**
- CRITICAL: Invalid block markup (see "Block markup validity")
- WARNING: Hand-written inline styles, hex colors or px font sizes (see "Block markup validity" for how to tell these from block-serialized styles)
- WARNING: Hardcoded `/wp-content/themes/...` image or asset URLs → Move to a PHP pattern using `get_theme_file_uri()`
- CRITICAL: PHP in `.html` templates or parts. PHP never executes there. For dynamic content use a PHP pattern (`<!-- wp:pattern {"slug":"theme/name"} /-->`), a core block (site-title, post-date, ...) or static text.

**Not a problem:**
- Templates without header/footer template parts
- Pattern: `<!-- wp:template-part {"slug":"header","area":"header"} /-->` when parts are used

**Hierarchy fact:** With a static front page, WordPress uses `front-page` and then the page template hierarchy, not `home`.

## Template parts (parts/*.html)

- Same markup checks as block templates
- WARNING / INFO for registration: see "templateParts array"
- Pattern: parts/header.html, parts/footer.html

## Block markup validity

Applies to templates, parts and patterns. CRITICAL when any of these fail:
- Delimiters are unbalanced (every `<!-- wp:name -->` has a matching `<!-- /wp:name -->`, or is self-closing `/-->`)
- The comment attribute JSON does not parse
- The saved HTML does not match what the comment attributes serialize to. Examples:
  - `style.spacing.padding` must produce the matching inline `style="padding-…"` on the wrapper
  - `backgroundColor` must produce `has-<slug>-background-color has-background` classes
  - `align` must produce the `align<value>` class
  - `tagName` on a group must change the wrapper element (`"tagName":"main"` → `<main class="wp-block-group">`)

**Block-serialized vs. hand-written inline styles:**
- Block-serialized (valid, never flag): the inline style is exactly what the comment attributes generate. Example: `style="padding-top:var(--wp--preset--spacing--40)"` matching `{"style":{"spacing":{"padding":{"top":"var:preset|spacing|40"}}}}`.
- Hand-written (WARNING): inline CSS that doesn't come from comment attributes (for example raw HTML between blocks), or raw values (hex, px font sizes) where a preset exists, even when serialized correctly from attributes.
- Inline CSS on a block's own wrapper with no matching comment attribute is a save mismatch, so report it as invalid markup (CRITICAL), not as WARNING.

## functions.php

**ABSPATH guard:**
- INFO: Missing `defined( 'ABSPATH' ) || exit;` in theme PHP files

**Block theme setup:**
- WARNING: `add_theme_support()` replaceable by theme.json in a block theme: editor-color-palette, editor-font-sizes, editor-gradient-presets, custom-line-height, custom-spacing, custom-units, align-wide
- Not a problem: `add_theme_support( 'wp-block-styles' )` → A genuine opt-in
- Not a problem: `responsive-embeds`, `editor-styles`, `post-thumbnails`, `html5`, `automatic-feed-links` → Core adds these automatically in block themes via `_add_default_theme_supports()`, so calling them is redundant but harmless

**Classic theme setup:**
- INFO: Classic theme could go hybrid by moving palette, font sizes, line height and spacing support into theme.json

**Theme hooks:**
- Pattern: `after_setup_theme` for setup, `wp_enqueue_scripts` for assets
- Hand-off: Custom post types, taxonomies or other plugin territory in functions.php → `/wp-review`

**Hardcoded paths:**
- WARNING: Hardcoded `/wp-content/themes/...` paths or URLs → Break on renamed theme dirs, child themes, custom content dirs
- Pattern: `get_theme_file_uri()`, `get_theme_file_path()`, `get_template_directory_uri()`

**Asset enqueues:**
- Not a problem: enqueue strategy and other performance concerns; hand off to `/wp-performance`

## Classic/hybrid PHP templates

- CRITICAL: Missing `wp_head()` (header.php or equivalent) or `wp_footer()` (footer.php or equivalent)
- WARNING: Missing `wp_body_open()` after `<body>`
- WARNING: Unescaped output (`echo` of variables or `get_*` values without `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`) → Hand off to `/wp-security` for depth
- CRITICAL: Request data echoed unescaped, for example `action="<?php echo $_SERVER['PHP_SELF']; ?>"` → Reflected XSS. Use `esc_url( home_url( '/' ) )` for search forms. Hand off to `/wp-security`
- WARNING: A file reads `$_POST`/`$_REQUEST` and saves it (`update_option`, `set_theme_mod`, meta or `$wpdb` writes) with no `wp_verify_nonce()`/`check_admin_referer()` → CSRF. Also check `current_user_can()` and sanitizing. Hand off to `/wp-security`. Reading POST data without saving it (a comment honeypot, for example) needs no nonce
- WARNING: Deprecated functions. Common ones in old themes: `attribute_escape()` → `esc_attr()`, `wp_specialchars()` → `esc_html()`, `clean_url()` → `esc_url()`, `js_escape()` → `esc_js()`, `get_settings()` → `get_option()`, `get_userdatabylogin()` → `get_user_by( 'login', ... )`, `get_currentuserinfo()` → `wp_get_current_user()`, `the_author_*()`/`get_the_author_*()` field functions → `the_author_meta()`/`get_the_author_meta()`, `get_page_by_title()` → `WP_Query`. They still run but emit deprecation notices when `WP_DEBUG` is on
- WARNING: Hardcoded `<title>` in header.php without `add_theme_support( 'title-tag' )` → Plugins and SEO filters can't change the title. Remove the tag and add the support (CRITICAL for WordPress.org)
- WARNING: Hardcoded `<link rel="stylesheet">` or `<script src>` in templates → Bypasses dependency handling, versioning and plugin dequeuing. Use `wp_enqueue_style()`/`wp_enqueue_script()` on `wp_enqueue_scripts` (CRITICAL for WordPress.org)
- WARNING: Translation calls without a text domain, such as `_e( 'Reply' )` → Strings load from core's domain and can't be translated per theme. Add the theme's text domain (CRITICAL for WordPress.org)
- INFO: WordPress PHP Coding Standards nits
- INFO: Classic theme that could go hybrid
- Facts: Classic templates include block template parts with `block_template_part( 'header' )`. In classic and hybrid themes, theme.json affects the editor and also outputs frontend global styles and preset CSS variables.

## Block patterns (patterns/*.php)

**Pattern file headers:**
- CRITICAL: Missing `Title` or `Slug` header → Won't register
- Pattern: Comment block with Title, Slug, Categories, Description, Keywords, Block Types, Viewport Width

**Pattern content:**
- WARNING: Hardcoded `/wp-content/themes/...` asset URLs → Use `get_theme_file_uri()`
- Same markup checks as templates
- Not a problem: Static pattern files without PHP
- Not a problem: No `patterns/` directory
- Fact: `patterns/*.php` register on `init` on every request (the file list is cached since 6.4). No `register_block_pattern()` call needed.

## Style variations (styles/*.json)

- CRITICAL: Missing `version` → Migrated to `{version: LATEST}` and discarded
- CRITICAL: Not valid JSON
- INFO: Missing `title` → The filename is used as the display name
- Not a problem: Partial variations (only some settings or styles)
- Not a problem: No `styles/` directory
- Fact: Each variation is migrated independently, so its `version` doesn't need to match the main theme.json; it only needs to exist.

## Child themes

- Child theme files override parent files by exact path and filename (`parts/header.html` overrides the parent's `parts/header.html`)
- Child theme.json is merged over the parent theme.json
- Review only what the child adds or overrides; parent issues belong to the parent

## WordPress.org submission

Apply only when the theme targets the WordPress.org directory. CRITICAL:
- Any Theme Check required-level error (Appearance > Theme Check)
- Google Fonts or another external CDN
- Missing required header: Theme Name, Author, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain
- Missing required file: readme.txt, screenshot.png
- Non-GPL-compatible assets (fonts, images, scripts)

## Review Focus by Theme Type

### Block theme
**Structure:** templates/index.html + theme.json + style.css, optional parts/, patterns/, styles/
**Focus:** theme.json v3 validity and preset slug collisions, block markup validity, hand-written styles in templates, root left/right padding with `useRootPaddingAwareAlignments`
**Common mistakes:** v3 presets colliding with core slugs, invalid saved markup after hand edits, PHP in `.html` files

### Classic theme
**Structure:** index.php + style.css + functions.php, header.php, footer.php, template files
**Focus:** `wp_head()`/`wp_footer()`/`wp_body_open()`, escaping (hand off to `/wp-security`), hybrid opportunity
**Common mistakes:** Missing `wp_body_open()`, unescaped output

### Hybrid theme
**Structure:** index.php + theme.json + functions.php
**Focus:** Both the classic PHP checks and the theme.json checks. theme.json outputs frontend global styles and preset CSS variables here too, so classic templates can use `var(--wp--preset--...)`.
**Common mistakes:** Duplicating theme.json presets in style.css, `add_theme_support()` palettes that conflict with theme.json

### Child theme
**Structure:** style.css with `Template:` header, optional overrides
**Focus:** Parent directory name match, exact override filenames

## WordPress Version Reference

| Feature | WordPress |
|---------|-----------|
| theme.json v1 | 5.8 |
| Block themes, Site Editor, Global Styles, Navigation block, theme.json v2 | 5.9 |
| Style variations (`styles/`), template part areas, `fontFace` in theme.json, `patterns/` auto-registration | 6.0 |
| `useRootPaddingAwareAlignments` | 6.1 |
| `styles.css` custom CSS property | 6.2 |
| theme.json v3 (`defaultFontSizes` / `defaultSpacingSizes` change) | 6.6 |
