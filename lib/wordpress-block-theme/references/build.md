# Building a Block Theme (BUILD mode)

Build a complete block theme with full site editing, one that passes this procedure's own review with a `SHIP` verdict. Use `patterns.md` for file shapes, `theme-json-guide.md` for theme.json keys, `template-patterns.md` for the template set, and `fse-guide.md` for patterns, variations, fonts, and layout.

## 1. Intake

Take what the request already gives, and ask for the rest (with `AskUserQuestion` where the options fit):

| Input | Required | Default |
|---|---|---|
| Theme name | yes | — |
| What the site is for (niche, content type) | yes | — |
| Design direction: colors, fonts, mood, or a named style | no | a neutral, readable palette and a system font stack |
| Distribution: WordPress.org or private | no | private |
| Parent theme (build a child theme of an existing block theme) | no | none (a standalone theme) |
| Extra templates, patterns, or style variations | no | the standard set below |

- **Named styles:** if the user names a design style (for example "bento" or "swiss") and `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-theme-mockup/references/styles/<slug>.md` exists (the 53 styles behind `/wp-mockup`), read it, and carry its colors, fonts, radii, shadows, and spacing into theme.json presets. Otherwise work from the description.
- **Non-interactive runs:** if you can't ask questions (`-p` mode) and a required input is missing, list what's missing and stop.
- **Derived names:**
  - **Slug:** kebab-case of the name.
  - **Text domain:** the slug.
  - **Function prefix:** the slug in snake_case.
  - **Pattern namespace:** the slug.

## 2. Files to Create

Write to `./<slug>/`. If that folder exists, ask for a different name or folder; in a non-interactive run, use `./<slug>-new/` (stop if that exists too) and say so. Never overwrite anything.

```
<slug>/
├── style.css                 header (see below) and only CSS theme.json can't express
├── theme.json                version 3 (see rules below)
├── functions.php             ABSPATH guard; enqueue style.css only if it has CSS; pattern categories
├── readme.txt                WordPress.org distribution only
├── screenshot.png            WordPress.org only: 1200×900 (see Testing)
├── templates/
│   ├── index.html            fallback: post list with pagination
│   ├── home.html             blog posts page
│   ├── front-page.html       only if the site has a designed front page
│   ├── single.html           post: title, meta, featured image, content, tags, comments, post navigation
│   ├── page.html             page: title and content
│   ├── archive.html          archive title and description, post list, pagination
│   ├── search.html           search title, search form, results, no-results message
│   └── 404.html              message, search form, link home
├── parts/
│   ├── header.html           site title or logo, Navigation block
│   ├── footer.html           footer text, secondary Navigation, credits
│   └── post-meta.html        date, author, categories (reused by single and the lists)
├── patterns/                 3-6 patterns that fit the niche (for example a hero, call to action, featured posts, or FAQ)
├── styles/                   1-2 style variations (for example a dark one) that change colors and fonts only
└── assets/fonts/             local .woff2 files, only when using web fonts
```

A **child theme** gets only `style.css` (with `Template: <parent-slug>`), a `theme.json` holding the overrides, and the templates, parts, or patterns it changes, with the same filenames as the parent's.

## 3. Rules

**theme.json**
- `"$schema"` and `"version": 3`.
- `appearanceTools: true` and `useRootPaddingAwareAlignments: true`, with root padding in object notation.
- **Color palette:** named, meaningful slugs (`base`, `contrast`, `accent`, …). Every text/background pair used together passes WCAG AA contrast (4.5:1 for body text). Add `"defaultPalette": false` if the theme's palette should be the only one.
- **Font sizes:** `fluid: true`, and `"defaultFontSizes": false` with the theme's own scale.
- **Font families:** a system stack, or local `fontFace` entries pointing to `file:./assets/fonts/...`. Never a font CDN.
- **Spacing:** `spacingSizes` (or `spacingScale`), and `"defaultSpacingSizes": false` when defining a custom scale.
- **Layout:** `contentSize` and `wideSize`.
- **styles:** elements (link with `:hover` and `:focus`, headings, button, caption) and core blocks, all referencing presets (`var:preset|color|accent`), never raw values.
- `templateParts` registers every part with its area. `customTemplates` registers any template that isn't in the standard hierarchy.

**Templates, parts, and patterns**
- Valid block markup only, and every block comment closes.
- **No inline styles.** No hand-written `style=""`, hex colors, or pixel sizes in markup. Use block attributes that reference presets, and keep the `style=""` WordPress generates from those attributes (for example `style="padding-top:var(--wp--preset--spacing--40)"`) so the markup matches the block comment.
- **Structure:**
  - Every template includes the header and footer through `<!-- wp:template-part {"slug":"header","area":"header"} /-->`.
  - Main content sits in a `<main>` group.
  - Menus come from the Navigation block only.
- **Queries:** lists use `wp:query` with `"inherit": true` on archive, search, and home templates. Each has a `wp:query-no-results`.
- **Patterns:**
  - Headers: `Title`, `Slug` (`<slug>/<name>`), `Categories`, and `Description`.
  - Every visible string goes through `esc_html_e()`/`esc_html__()` with the text domain, and every image URL through `esc_url( get_theme_file_uri( '…' ) )`.
  - Images are the theme's own files in `assets/images/`, or omitted. Never hotlinked.
- **Accessibility:**
  - Heading levels in order.
  - Visible focus styles.
  - Alt text on theme images.
  - Keyboard access through the Navigation block's own markup.

**PHP**
- `functions.php` starts with the ABSPATH guard, and uses the prefix on every function.
- `add_theme_support()` only for what theme.json can't do (for example `wp-block-styles` or `editor-styles`, if used).
- `register_block_pattern_category()` for any custom pattern category.
- Prefer per-block stylesheets through `wp_enqueue_block_style()` over one large stylesheet.

**style.css header**
- Theme Name, Theme URI (only if real), Author, Description, Version, and Text Domain.
- Requires at least: 6.6, Tested up to (the current version), and Requires PHP: 7.4.
- License: GPL-2.0-or-later, and License URI.
- Tags for WordPress.org (for example `full-site-editing`, `block-patterns`, `style-variations`, `wide-blocks`).
- Placeholders like example.com never ship. Leave a line out rather than invent a value.

**WordPress.org distribution**
- Everything in the WordPress.org requirements in `fse-guide.md`.
- A `readme.txt` with its header and a Copyright/Resources section listing the license of every bundled font and image.
- No upsells or phone-home code.

## 4. Testing

1. **Syntax:** every JSON file parses (`python3 -m json.tool` or `jq`), and `php -l` passes on every PHP file.
2. **Block markup:** in every template, part, and pattern, each `<!-- wp:name` opener has a matching `<!-- /wp:name -->` closer, unless it self-closes with `/-->`. Check this with a small script, not by eye.
3. **Self-review:** run REVIEW mode on the new theme (every check in `checks.md`) and fix everything until the verdict is `SHIP`. Show the final summary.
4. **Live check (optional):** if `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-theme-bug-audit/scripts/setup-test-site.sh` exists (the throwaway SQLite site builder bundled with `/wp-bug-audit`; run it with `bash`, never edit it), and the machine has PHP and network access:
   - Build a throwaway site with the new theme, and fetch the home page, a post, a page, an archive, a search, and a 404 page.
   - Confirm each returns the expected status with no PHP errors.
   - With WordPress.org distribution and `shot` available, take a 1200×900 screenshot of the front page as `screenshot.png`.
   - Tear the site down afterwards.

   If any of this can't run, say so.

## 5. Report

End with:
- the theme folder and file list
- the design choices (palette with contrast ratios, fonts, and layout sizes)
- the self-review summary and verdict
- the test results (or what couldn't run)
- next steps: activate the theme, and set the front page if `front-page.html` exists
