## Theme rules

These rules apply when the project is a theme (classic, block, hybrid or child). They add to the Universal rules and the chosen profile. Where they conflict, these rules win.

- **Theme kinds:**
  - **Classic theme:** PHP templates in the theme root (`index.php`, `single.php`, `header.php` …), `template-parts/`, `functions.php` and `inc/`.
  - **Block theme:** `templates/*.html`, `parts/*.html`, `theme.json`, and usually `patterns/*.php` and a small `functions.php`.
  - **Hybrid theme:** a classic theme with some block theme files. Apply both lists.
  - **Child theme:** `style.css` has a `Template:` field that names the parent theme's folder. Document only the child theme's files. Read the parent theme read-only to learn what the child overrides.
- **Files that stay out of scope.** Read them for facts, but never edit them:
  - `style.css` and other CSS. The theme header is in `style.css`, and WordPress reads it.
  - `theme.json`, `styles/*.json` and `block.json`. JSON has no comments.
  - `templates/*.html` and `parts/*.html`. Their `<!-- wp:… -->` comments are block delimiters, which are code.
  - `screenshot.png`, fonts, images and `languages/`.
- **Project facts** come from the `style.css` header: `Theme Name`, `Version`, `Text Domain`, `Requires PHP`, `Requires at least`, and `Template` for a child theme. `readme.txt` (when present) gives the changelog.
- **`@package`:** follow the theme's existing docblocks. WordPress default themes use `@package WordPress` with `@subpackage Twenty_Twenty_Four`; other themes often use `@package Theme_Name` alone. With no existing docblocks, use the theme name in Words_With_Underscores (`@package Acme_Blog`).
- **`@since` format:** WordPress default themes write the theme name before the version (`@since Twenty Twenty-Four 1.0`). When the theme already uses that form, write new values the same way. Otherwise write the version alone. Use the version form that `style.css` uses (for example `1.0`); this replaces profile A's three-part rule for themes.
- **Header files.** WordPress reads `Template Name:` / `Template Post Type:` page-template headers and block pattern headers (`Title:`, `Slug:`, `Categories:`, `Keywords:`, `Block Types:`, `Post Types:`, `Template Types:`, `Inserter:`, `Viewport Width:`, `Description:`) with `get_file_data()`. WordPress matches these names in any letter case, so `slug:` and `inserter:` are header fields too. Keep every header field exactly. When the header is a `/** */` docblock, add `@package` and `@since` as new lines after the last header field, as in the WordPress default themes. The `Title:` or `Template Name:` line acts as the summary; a short description before the tags is optional:

  ```
  <?php
  /**
   * Title: Hero
   * Slug: acme-blog/hero
   * Categories: banner
   *
   * @package Acme_Blog
   * @since 1.2
   */
  ?>
  ```
- **Template hierarchy files** (`index.php`, `single.php`, `archive.php`, `404.php`, `header.php`, `comments.php` …): the file docblock says which requests the template renders, and under profile A adds a `@link` to the handbook, as the default themes do. Use the template-hierarchy page for hierarchy templates, `https://developer.wordpress.org/themes/basics/template-files/#template-partials` for `header.php`, `footer.php` and `sidebar.php`, and `https://developer.wordpress.org/themes/template-files-section/page-template-files/` for page templates. Template parts need no `@link`.

  ```
  /**
   * The template for displaying all single posts.
   *
   * @link https://developer.wordpress.org/themes/basics/template-hierarchy/#single-post
   *
   * @package Acme_Blog
   * @since 1.0
   */
  ```

  Most of these files declare no functions, so the file docblock and inline "why" comments are all they need.
- **Template parts:** a part loaded with `get_template_part( $slug, $name, $args )` documents `$args` in its file docblock with hash notation. Find the keys from every caller, including callers that build the slug at runtime. Don't list loop globals (`$post`, `$wp_query`) as `@var`; the template hierarchy implies them. Don't list variables the part assigns itself.
- **Pluggable functions:** the docblock of a function inside an `if ( ! function_exists( '…' ) )` guard goes inside the guard (see **Coverage**). Its description says that a child theme can replace the function by defining one with the same name first. When every function in a file is pluggable, say it once in the file docblock instead.
- **Child theme overrides:** a child template or function that replaces a parent one says so in its summary or description (`Overrides the parent theme's single post template.`), but only when the parent really has that file or function.
- **Theme setup and procedural code** (`functions.php`, `inc/*.php`): document every function and name the hook that calls it (`Hooked to 'after_setup_theme'.`). For a setup function, list in the description what it registers: theme supports, menus, sidebars, image sizes, block styles, editor styles.
- **Template tags** (functions that echo markup, often in `inc/template-tags.php`): say what they print and who escapes it, with a fixed phrase: `All output is escaped here.`, `The caller must escape the result.`, or, for markup from a helper that escapes its own output (an SVG icon helper, say), `The <helper>() markup is printed as is; that function escapes it.`
- **Customizer:** document `customize_register` callbacks with the settings, controls and sections they add (IDs and `transport`), and every `sanitize_callback`, `active_callback` and selective refresh `render_callback`. In `customize-preview.js` / `customize-controls.js`, each `wp.customize( 'setting', … )` callback with a multi-statement body gets JSDoc under the JavaScript rules.
- **Patterns in PHP:** the markup outside `<?php ?>` is code, byte for byte, including its `<!-- wp:… -->` comments. Add comments only inside existing PHP blocks. A gettext call with placeholders there still needs its `translators:` comment.
- **Theme hooks:** custom `do_action` / `apply_filters` calls in templates follow the Hooks rule. Inside a template, the hook docblock goes in the PHP block before the call, using the mid-line form from the Hard rule when the block opens inside an HTML line.
- **Bug report additions for themes:** unescaped output in templates; a missing or wrong text domain; unprefixed functions, classes, globals or handles; scripts and styles printed directly instead of enqueued; `get_template_directory*()` and `get_stylesheet_directory*()` mixed up in code that a child theme must be able to override; a missing `wp_head()`, `wp_footer()` or `wp_body_open()`; and functions deprecated for the theme's `Requires at least` version.
