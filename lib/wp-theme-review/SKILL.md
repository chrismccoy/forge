# WordPress Theme Review

Code review for WordPress 6.6+ themes, block themes first. **Core principle:** theme.json v3 is the single source of truth for design. Flag anything that bypasses it: hand-written styles, raw values where presets exist, and `add_theme_support()` calls that theme.json replaces.

**Hand off:**
- Building a block theme, or a full block-theme build review: `/wp-block-theme`
- Migrating a classic theme to blocks: `/wp-classic-to-block`
- Custom blocks: `/wp-build`
- Plugin-territory code and architecture: `/wp-review`
- Full security audits: `/wp-security`
- Performance: `/wp-performance`

WooCommerce and visual design are out of scope.

## Workflow

1. **Scan.** If unclear, first ask whether the theme targets WordPress.org. `<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/wp-theme-review`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it. Run `bash ${CLAUDE_PLUGIN_ROOT}/lib/wp-theme-review/scripts/scan-theme.sh <theme-dir>` as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rule matches. Add `--wporg` after the path for WordPress.org submissions. The script prints the theme type and `file:line` candidates grouped by severity. Without `jq`, it skips JSON validity, exact slug-collision detection, padding, layout, template-part, and customTemplates checks. Verify those by hand. It never checks `page-*`/`single-*` templates against customTemplates.
2. **Confirm type.**
   - Block: `templates/index.html`.
   - Hybrid: `index.php` + `theme.json`.
   - Classic: `index.php` only.
   - Child: `Template:` header in style.css.
3. **Verify each candidate** in the source. Then apply **`references/review-checklist.md`** for what the scanner cannot see. The checklist has per-file checks, block-markup validity, classic PHP, and WordPress.org requirements.
4. **Assign severity** with the table below. Drop anything listed in "Not Problems".
5. **Report** in the **`references/report-format.md`** format:
   - Group findings by file.
   - Give each one a line, severity, one-sentence impact, and BAD/GOOD pair (an INFO finding may give just the fix). Adapt pairs from **`references/code-examples.md`**.
   - End with a SUMMARY: counts, top recommendation, and hand-offs.

## Traps Worth Knowing

- **v3 default presets.** `defaultFontSizes` and `defaultSpacingSizes` default to `true`, and core defaults are protected from override.
  - If a theme slug collides with a core slug, the theme value is silently ignored (CRITICAL). Core font-size slugs: small, medium, large, x-large, xx-large. Core spacing slugs: 20–80. A `spacingScale` with `steps` > 0 always generates colliding slugs.
  - Without a collision, only a duplicate "Default" group appears in the UI (WARNING).
- **Missing `version`** in theme.json or a style variation makes core discard the whole file.
- **Root padding.** `useRootPaddingAwareAlignments` needs `styles.spacing.padding` as an object. A shorthand string breaks it. Only left/right root padding needs the setting at all.
- **Block-serialized styles are valid.**
  - Core blocks save inline styles generated from their comment attributes, for example `style="padding-top:var(--wp--preset--spacing--40)"` from `{"style":{"spacing":{"padding":{"top":"var:preset|spacing|40"}}}}`.
  - Inline CSS on a block wrapper with no matching attribute is a save mismatch: treat it as invalid markup (CRITICAL).
  - Hand-written styles on raw HTML outside blocks, or raw values where a preset exists, are WARNING.
- **Invalid block markup** means any of:
  - unbalanced `<!-- wp:x -->`/`<!-- /wp:x -->` delimiters,
  - comment JSON that does not parse,
  - saved HTML that does not match the attributes (for example, missing `has-background` classes or a missing inline style).
  
  The editor shows "This block contains unexpected or invalid content".
- **No PHP in `.html` templates or parts.** It never executes. Use a PHP pattern included with `<!-- wp:pattern {"slug":"theme/name"} /-->`.
- **add_theme_support() in block themes.**
  - `wp-block-styles` is a real opt-in.
  - `responsive-embeds`, `editor-styles`, `post-thumbnails`, `html5`, and `automatic-feed-links` are added automatically. Calling them is redundant, not wrong.
  - Palette, font sizes, spacing, line-height, units, and `align-wide` belong in theme.json.
- **Hybrid and classic themes.** theme.json still outputs global styles and preset CSS variables on the frontend. It does not restyle PHP template markup.

## Severity

| Severity | Findings |
|----------|----------|
| **CRITICAL** (breaks, or WordPress.org rejects it) | Missing `style.css` or `Theme Name`. No `templates/index.html` and no `index.php` (non-child). theme.json or variation missing `version`, or invalid JSON. v3 preset slug collision without `default*Sizes: false`. Shorthand padding with `useRootPaddingAwareAlignments`. Pattern missing Title or Slug. Invalid block markup. PHP in `.html`. Classic theme missing `wp_head()` or `wp_footer()`. Request data (`$_GET`, `$_SERVER`, ...) echoed unescaped (also hand off). Child `Template:` not matching the parent directory name. |
| **WARNING** (works, with quality issues) | theme.json v1 or v2. `version` written as a string. v3 custom presets without `default*Sizes: false` (no collision). Hand-written styles, raw hex or px in templates. Root left/right padding without `useRootPaddingAwareAlignments`. Replaceable `add_theme_support()`. Registered template part with no file, or a name ending in `.html`. Hardcoded `/wp-content/themes/` paths. Block theme without theme.json. Missing `contentSize`/`wideSize`. `fontFace` `src` without the `file:` prefix (that font falls back; the theme still works). Missing `Text Domain` or `Version`. Unescaped output in classic templates, or POST data saved without a nonce (both hand off). Missing `wp_body_open()`. Deprecated functions. Hardcoded `<title>` without `title-tag` support. Hardcoded `<link rel="stylesheet">`/`<script src>` instead of enqueueing. Translation calls without a text domain. |
| **INFO** (opportunity) | Missing `$schema`. Raw hex or px in theme.json `styles` instead of presets. Unregistered part file. Non-hierarchy template not in `customTemplates`. Variation missing `title`. Google Fonts CDN. Classic theme could go hybrid. Missing `Requires at least`, `Tested up to`, or `Requires PHP`. No ABSPATH guard. PHP coding-standards nits. |

**WordPress.org context:** these become CRITICAL:
- Theme Check required errors
- Google Fonts or other CDN links
- non-GPL-compatible assets
- missing readme.txt or screenshot.png
- hardcoded `<title>`, hardcoded stylesheet/script tags, or translation calls without a text domain
- missing style.css headers: Author, Description, Version, Requires at least, Tested up to, Requires PHP, License, License URI, Text Domain

Contrast rules apply only to the `accessibility-ready` tag.

## Not Problems

- Minimal style.css in a block theme.
- No theme.json in a classic theme.
- Both `index.php` and `theme.json` (hybrid theme).
- No palette, fontSizes, or spacingSizes defined. Core defaults apply.
- Partial style variations.
- Templates without header/footer parts.
- Static patterns without PHP.
- A child theme without functions.php.
- No `patterns/`, `styles/`, or frontend JS.
- `--wp--preset--*` variables in style.css.
- Hex values inside the theme.json `palette`.
- Cover block `customOverlayColor` (the editor samples it from the image).
- Block-serialized inline styles.
- Asset enqueue strategy (hand off to `/wp-performance`).

## References

- **`references/review-checklist.md`**: per-file checks, markup validity, classic PHP, WordPress.org list, version table. Load for every review.
- **`references/code-examples.md`**: BAD/GOOD pairs. Load when writing findings.
- **`references/report-format.md`**: example report. Load before writing the report.
- **`references/theme-json-guide.md`**: v3 schema and property catalog. Load for unfamiliar theme.json keys or a v2→v3 upgrade.
- **`references/template-patterns.md`**: template hierarchy, custom templates, parts. Load for hierarchy or missing-template questions.
- **`references/fse-guide.md`**: Global Styles, variations, patterns, fonts, layout. Load for variation, pattern, or font findings.
- **`references/classic-to-block-guide.md`**: migration mapping. Load for classic or hybrid themes and migration-readiness reviews.
