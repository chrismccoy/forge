# Phase 2 - Implementation

## Chunk Planning

**Do not use the default chunk plan blindly.** At the end of Phase 1B, propose a custom chunk plan based on the actual file manifest (⑪).

Rules for chunk planning:
- No file may be split across chunks - each file must be complete in one chunk
- Aim for 3-6 chunks depending on theme complexity
- Group files by dependency (files that reference each other go in the same or adjacent chunks)
- File count guidelines: ≤15 files → 3 chunks | 16-25 files → 4-5 chunks | >25 files → 6 chunks
- Always put `functions.php` and config files in Chunk 1
- Always put documentation and audit in the final chunk

**Default chunk plan** (use as baseline, adjust per above):

| Chunk | Contents |
|-------|----------|
| 1 - Foundation | `style.css`, `functions.php`, `package.json`, `tailwind.config.js`, `src/input.css`, `inc/*.php`, `.editorconfig`, `theme.json` (if applicable) |
| 2 - Core Templates | `header.php`, `footer.php`, `sidebar.php` (if applicable), `index.php`, `single.php`, `page.php`, `comments.php` |
| 3 - Archive & Utility | `archive.php`, `category.php`, `tag.php`, `search.php`, `searchform.php` (if applicable), `404.php` |
| 4 - Parts & JS | All `template-parts/*.php`, all `template-pages/*.php` (if applicable), all `js/*.js` |
| 5 - Docs & Audit | `README.md`, `screenshot-instructions.md`, file tree, self-audit |

Present the proposed chunk plan to the user for approval before generating Chunk 1.

### Chunk Size Estimation

Before outputting a chunk, estimate total lines across all files in that chunk. Follow these guidelines:

| Estimated Lines | Action |
|-----------------|--------|
| ≤ 800 lines | Output as a single chunk |
| 801-1200 lines | Output as a single chunk but monitor for truncation |
| > 1200 lines | Split the chunk into sub-chunks and notify user |

These line counts are approximations. The real constraint is output token limits. If you sense you are approaching the limit, stop at the next clean file boundary regardless of line count and state: "Approaching output limits. Remaining files deferred to next sub-chunk."

Additional rules:
- If a single file exceeds ~400 lines, it gets its own sub-chunk
- If estimated total exceeds ~1000 lines, split the chunk and notify user: "Chunk N is large (~X lines). Splitting into Chunk Na and Chunk Nb."
- Track running line count as you output. If approaching limits mid-chunk, stop cleanly at the next file boundary and state: "Remaining files for this chunk deferred to next sub-chunk."

---

## Implementation Rules

These apply to every file in every chunk:

1. **Every file must be complete and functional.** No stubs, no `// TODO`, no `/* add content here */`, no placeholder functions that return nothing.

```php
// FORBIDDEN - stub function
function flavor_studio_setup() {
	// TODO: Add theme supports
}

// FORBIDDEN - placeholder content
function flavor_studio_widgets_init() {
	// Add widget areas here
}

// REQUIRED - complete implementation
function flavor_studio_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'post-thumbnails' );
	add_theme_support( 'html5', [
		'search-form',
		'comment-form',
		'comment-list',
		'gallery',
		'caption',
		'style',
		'script',
	] );
	add_theme_support( 'automatic-feed-links' );
	register_nav_menus( [
		'primary' => esc_html__( 'Primary Menu', 'flavor-studio' ),
		'footer'  => esc_html__( 'Footer Menu', 'flavor-studio' ),
	] );
}
```

2. **Every file must start with the required docblock** (see `references/rules.md` § PHP Coding Standards).
3. **All escaping rules from `references/rules.md` § Escaping & Security must be followed in every file.**
4. **All naming conventions must be followed in every file.**
5. **All accessibility requirements must be followed in every file.**
6. **Visual structure must faithfully match the source HTML.** Do not rearrange, simplify, or "improve" the layout unless the user asks.
7. **Preserve all Tailwind utility classes from the source HTML** unless they need modification for WordPress template logic.
8. **Run the Pre-Output Self-Check (in `SKILL.md`) on every file before including it in the response.**

---

## Template Architecture Reference

Use this section as a reference during implementation. These rules supplement the file-specific decisions made in Phase 1.

### `inc/` File Responsibilities

Maintain a clear separation between the two main include files:

| File | Contains | Does NOT contain |
|------|----------|-----------------|
| `inc/template-tags.php` | Functions that output markup directly - called in templates with no `echo` needed | Utility logic, data transformation |
| `inc/template-functions.php` | Utility/helper functions that return values or perform logic - called by template tags or other functions | Markup output |

If a function outputs an entire HTML block, it belongs in `template-tags.php`. If a function computes, filters, or returns a value, it belongs in `template-functions.php`.

### `functions.php` Load Order

`functions.php` must load includes in dependency order, then register hooks:

```php
<?php
/**
 * Theme functions and definitions.
 *
 * @package Flavor_Studio
 * @since   1.0.0
 */

// 1. Constants - defined at file scope before anything else.
define( 'FLAVOR_STUDIO_VERSION', wp_get_theme()->get( 'Version' ) );

// 2. Content width - set at file scope, not inside a hook.
if ( ! isset( $content_width ) ) {
	$content_width = 1200;
}

// 3. Requires - in dependency order.
require get_template_directory() . '/inc/template-functions.php';
require get_template_directory() . '/inc/template-tags.php';
require get_template_directory() . '/inc/navigation.php';
require get_template_directory() . '/inc/widgets.php';

// 4. Action hooks - registered after all classes/functions are defined.
add_action( 'after_setup_theme', 'flavor_studio_setup' );
add_action( 'widgets_init',      'flavor_studio_widgets_init' );
add_action( 'wp_enqueue_scripts', 'flavor_studio_scripts' );
```

> **Why `require` and not `require_once`?** WordPress guarantees that `functions.php` loads exactly once per request. Using `require` (without `_once`) is intentional: if a file is missing, `require` produces a fatal error immediately, making the problem obvious. In contrast, `require_once` can silently mask issues where a file was unexpectedly loaded earlier. Do not "fix" these to `require_once`.

### Theme Setup (`after_setup_theme`)

**Always register:**
- `title-tag`
- `html5` (for `search-form`, `comment-form`, `comment-list`, `gallery`, `caption`, `style`, `script`)

**Conditionally register** (only if design uses/benefits):
- `automatic-feed-links` - if the theme has a post archive or blog functionality
- `post-thumbnails` - if any template uses featured images
- `custom-logo` - if header has a logo area
- `custom-background` - if design supports background customization
- `editor-styles` - if providing editor stylesheet (see below)
- `align-wide` - if using wide/full-width blocks
- `responsive-embeds` - if embedding media

**Editor stylesheet:** If `editor-styles` is registered, add:
```php
add_editor_style( 'assets/css/theme.css' );
```
This loads the same compiled Tailwind CSS in the block editor so fonts, colors, and max-widths match the front end. Verify that prose/container classes render correctly in editor context.

**Set `$content_width` at file scope** (not inside a hook), before any hooks fire, based on the design's main content column width in pixels:

```php
// In functions.php at file scope - not inside after_setup_theme.
if ( ! isset( $content_width ) ) {
	$content_width = 1200; // Adjust to match your design's max content column width.
}
```

> **Single source of truth:** The content width originates from the design token extracted in ⑤. Three locations must stay in sync:
>
> | Location | Key | Example |
> |----------|-----|---------|
> | `functions.php` | `$content_width` | `1200` |
> | `theme.json` | `settings.layout.contentSize` | `"1200px"` |
> | `tailwind.config.js` | `theme.extend.maxWidth.content` | `'1200px'` |
>
> If these values diverge, block editor content and front-end content will render at different widths. During Phase 1 (⑤ Design Token Extraction), record this value once and reference it in all three locations. During the self-audit, verify they match.

**Register image sizes** for every custom size identified in ⑦:

```php
add_image_size( 'flavor-studio-hero', 1920, 800, true );
add_image_size( 'flavor-studio-card', 600, 400, true );
```

### Useful Conditional Template Tags

Use these inside templates to adapt output per context:

| Function | True when |
|----------|-----------|
| `is_home()` | Blog posts index (front page or Posts page) |
| `is_front_page()` | Static front page OR blog index if set as front page |
| `is_singular()` | Any single post, page, or CPT |
| `is_single()` | Single post only |
| `is_page()` | Single page only |
| `is_archive()` | Any archive (category, tag, date, author) |
| `is_category()` | Category archive |
| `is_tag()` | Tag archive |
| `is_search()` | Search results page |
| `is_404()` | 404 not found page |
| `is_active_sidebar( 'id' )` | Sidebar has active widgets |
| `comments_open()` | Comments are open on current post |
| `have_comments()` | Post has at least one comment |

### Critical WordPress Hooks in Templates

**`header.php` must include (in order):**
1. `<!DOCTYPE html>`
2. `<html <?php language_attributes(); ?>>`
3. `<head>` with `<meta charset="<?php bloginfo( 'charset' ); ?>">`
4. `<meta name="viewport" content="width=device-width, initial-scale=1">`
5. `<?php wp_head(); ?>` immediately before `</head>`
6. `<body <?php body_class(); ?>>`
7. `<?php wp_body_open(); ?>` immediately after `<body>` tag
8. Skip-to-content link as first visible element

**`footer.php` must include:**
1. `<?php wp_footer(); ?>` immediately before `</body>`
2. `</body></html>`

### Navigation

- `register_nav_menus()` for every location identified in ②
- `wp_nav_menu()` with `theme_location`, `container`, `container_class`, `menu_class`, `fallback_cb`, `depth`
- Walker class if decision tree in ② determined one is needed
- Mobile menu: vanilla JS, keyboard accessible, focus trapping, ARIA states
- Current page styling via `current-menu-item` / `current_page_item` classes

### The Loop & Template Parts

**Minimum required parts** (adjust per ⑪):
- `template-parts/content.php` - archive/index post card
- `template-parts/content-single.php` - full single post layout
- `template-parts/content-page.php` - page layout
- `template-parts/content-none.php` - no results found

Pass the post type to `get_template_part()`:
```php
get_template_part( 'template-parts/content', get_post_type() );
```

### Custom Page Templates

For one-off page layouts (landing pages, contact pages, etc.) detected in ① - create `template-pages/template-{name}.php` with a header comment:

```php
<?php
/**
 * Template Name: Landing Page
 *
 * @package Flavor_Studio
 * @since   1.0.0
 */

get_header();
// ... unique layout markup
get_footer();
```

WordPress will surface this in the Page Attributes → Template dropdown in wp-admin automatically.

### Sidebars & Widgets

- `register_sidebar()` with `before_widget`, `after_widget`, `before_title`, `after_title` matching source HTML structure (as specified in ③)
- Check before output:
```php
if ( is_active_sidebar( 'sidebar-1' ) ) :
	dynamic_sidebar( 'sidebar-1' );
endif;
```

### Comments

- `comments.php` is always created, even if source HTML has no comment design
- Must handle all states: open with comments, open with zero comments, closed, password-protected
- `wp_list_comments()` with custom callback if markup requires it
- `comment_form()` with args matching design
- `comment_form()` field ordering: pass identity inputs (`author`, `email`, `url`, `cookies`) via the `fields` array; pass the textarea via the separate `comment_field` arg. The `cookies` opt-in field must come **after** `url` in the `fields` array - putting it first or omitting it (when the discussion setting is enabled) produces a broken form. Any field you don't override is filled in by WordPress defaults, so only list the ones you customize.

### Pagination

- Use `the_posts_pagination()` with `mid_size` ≤ 3
- Add `aria-label` to navigation element
- Style to match design using Tailwind classes

### Search

- Use `get_search_form()` - create `searchform.php` only if the source HTML search markup is not achievable via `get_search_form()` args alone (e.g. custom classes, icons inside the input, additional wrapper elements, or layout beyond a standard input + submit button). If in doubt, create `searchform.php` - the cost is low and it ensures design fidelity.
- Search form must have `role="search"`, labeled input, and accessible submit button
- No-results template includes a retry search form

### 404 Page

- Friendly, translated message
- Search form via `get_search_form()`
- Optional: recent posts list, category list
- Styled consistently with rest of theme

### Environment-Aware Enqueuing (Optional)

Do not implement environment-aware asset loading by default. If the user explicitly requests development/production differentiation, use `wp_get_environment_type()` to conditionally load minified vs. unminified assets:

```php
$suffix = ( 'production' === wp_get_environment_type() ) ? '.min' : '';

wp_enqueue_script(
	'flavor-studio-navigation',
	get_template_directory_uri() . "/js/navigation{$suffix}.js",
	[],
	$version,
	true
);
```

Add this as a decision in ⑨ Decision Log only if the user raises it.

### .editorconfig

```ini
root = true

[*]
indent_style = tab
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{css,js,json,yml,yaml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

### screenshot.png Protocol

Since you cannot generate images, create `screenshot-instructions.md` with:
- Required dimensions: 1200×900px
- Which page to capture (typically the homepage with sample content)
- Browser viewport settings for the capture
- Recommended tools (browser DevTools screenshot, or OS screenshot utility)
- Note: this is a required file for WordPress.org theme submission

If the user provides a `screenshot.png`, place it in the theme root directory as-is. Do not generate, modify, or resize image files.

If no screenshot is provided:
1. Create `screenshot-instructions.md` with capture guidance (as above)
2. Create `screenshot-placeholder.txt` in the theme root containing:

```text
REQUIRED: Replace this file with screenshot.png (1200×900px).
See screenshot-instructions.md for instructions.
WordPress.org theme submissions require a screenshot.png in the theme root.
```

This ensures the missing screenshot is immediately obvious to anyone browsing the theme directory, rather than being silently absent.

---

## Optional Features Implementation Patterns

These patterns apply only when the user opted into a feature during the Initialization Gate. If a feature wasn't opted in, do NOT implement it (don't add unrequested helpers, files, or hooks). Each opted-in feature should also have a corresponding row in ⑨ Decision Log and a self-audit row in Phase 3.

### Customizer Settings

- File: `inc/customizer.php`, hooked via `add_action( 'customize_register', '{prefix}_customize_register' )`
- For each setting: `add_setting()` (transport `refresh` unless selective refresh / live preview is justified), then `add_control()` attached to a section (`add_section()`)
- Always provide a `sanitize_callback`: `sanitize_text_field`, `esc_url_raw`, `wp_kses_post`, `absint`, `sanitize_hex_color` - never accept raw input
- Output via `get_theme_mod( '{setting_id}', 'default value' )` in templates, escaped for context

### Transient Caching

- Helper sits next to the function it caches in `inc/template-functions.php`
- Cache key naming: `{prefix}_{function_name}` plus a per-resource suffix where applicable (e.g. `_post_{ID}`)
- TTL: minutes for hot lists (`MINUTE_IN_SECONDS * 15`), hours for medium-cost data (`HOUR_IN_SECONDS`), day-plus for stable data
- Invalidate on relevant hooks: `save_post`, `deleted_post`, `switch_theme`, `customize_save_after` - register named callbacks that call `delete_transient()`
- Wrap the expensive call in `if ( false === ( $value = get_transient( $key ) ) ) { ... set_transient( $key, $value, $ttl ); }`

### Reading Time

- Helper: `{prefix}_get_reading_time( $post_id = null )` in `inc/template-functions.php` - returns int minutes
- Compute: `(int) ceil( str_word_count( wp_strip_all_tags( get_post_field( 'post_content', $post_id ) ) ) / $wpm )` with `$wpm = 225` default
- Wrap in transient if caching is opted in, key includes post ID + post modified timestamp (so edits auto-invalidate)
- Template tag `{prefix}_reading_time()` in `inc/template-tags.php` echoes: `printf( esc_html( _n( '%d min read', '%d min read', $minutes, '{slug}' ) ), (int) $minutes );` (with the required `translators:` comment)

### Related Posts

- Helper: `{prefix}_get_related_posts( $post_id, $count = 4 )` in `inc/template-functions.php` - returns `WP_Post[]`
- Strategy: prefer same primary category + overlapping tags, exclude current post via `post__not_in`, `posts_per_page` to `$count`, `orderby` `rand` or `date`
- Use `WP_Query` (not `get_posts` for complex filtering) with `no_found_rows => true, update_post_meta_cache => false, update_post_term_cache => false` for performance
- Wrap in transient if caching opted in
- Render via `template-parts/related-posts.php`, called from `single.php` between `the_content()` and `comments_template()`

### Schema.org JSON-LD

- File: `inc/schema.php`, hooked to `wp_head` at priority 20 (after WP's own meta output)
- Conditional logic per page type: `Article` for single posts, `WebPage` for pages, `BreadcrumbList` for hierarchical pages, `WebSite` + `Organization`/`Person` on the front page
- Output `<script type="application/ld+json">...</script>` using `wp_json_encode()` - never raw JSON string concatenation
- Source from real WP data: `get_the_title()`, `get_the_excerpt()`, `get_permalink()`, `get_the_author_meta()`, `get_the_post_thumbnail_url()`, `get_the_date( 'c' )` (ISO 8601 for `datePublished`/`dateModified`)
- Document a manual validation step in `README.md`: paste a sample URL into Google's Rich Results Test

### Social Share Buttons

- Template part: `template-parts/social-share.php`, called from `single.php`
- Build URLs server-side; no third-party JavaScript: e.g. `https://twitter.com/intent/tweet?url=` + `urlencode( get_permalink() )` + `&text=` + `urlencode( get_the_title() )`. Same pattern for Facebook (`sharer.php?u=`), LinkedIn (`sharing/share-offsite/?url=`), Reddit (`submit?url=...&title=...`), Email (`mailto:?subject=...&body=...`)
- Each link: `<a target="_blank" rel="noopener noreferrer">` with `aria-label` and visually-hidden text for screen readers (icons must always be paired with accessible text)
- Confirm the network list during the Initialization Gate

### Author Bio Box

- Template part: `template-parts/author-bio.php`, called from `single.php` after `the_content()`
- Render only if `get_the_author_meta( 'description' )` is non-empty
- Avatar: `get_avatar( get_the_author_meta( 'ID' ), 96 )`
- Bio: `wp_kses_post( get_the_author_meta( 'description' ) )`
- Author archive link: `esc_url( get_author_posts_url( get_the_author_meta( 'ID' ) ) )`

### Last-Updated Date

- Helper: compare `(int) get_the_modified_date( 'U' )` to `(int) get_the_date( 'U' )` - only show "Updated" label if the diff exceeds a threshold (default `DAY_IN_SECONDS`) to avoid noise on minor edits
- Template tag in `inc/template-tags.php` echoes the formatted updated date with `<time datetime="...">` per HTML5
- Style with subdued color so it doesn't compete with the published date

### AJAX Comments / Pagination

- PHP: `inc/ajax-handlers.php` registers `wp_ajax_{prefix}_{endpoint}` and `wp_ajax_nopriv_{prefix}_{endpoint}` actions
- Every handler: `check_ajax_referer( '{prefix}_ajax_nonce', 'nonce' )` first; bail via `wp_send_json_error()` on failure
- Localize nonce + endpoint URL via `wp_localize_script()` in the enqueue function (or use `wp_add_inline_script()` with `wp_create_nonce()`)
- JS: `js/ajax-comments.js` or `js/ajax-pagination.js` - vanilla `fetch()` against `admin-ajax.php`. Use the localized nonce. Render server-returned HTML safely (innerHTML only with HTML you generated server-side and have already escaped)
- **Always** provide a non-JS fallback: the standard WP comment form and `the_posts_pagination()` must still work if JavaScript is disabled

### Custom Shortcodes

- File: `inc/shortcodes.php`
- Register via `add_shortcode( '{slug}', '{prefix}_shortcode_{name}' )` inside a `{prefix}_register_shortcodes()` function hooked to `init`
- Each callback: parse atts with `shortcode_atts()` providing defaults, escape all output per context, **return** (don't echo) the markup
- Document each shortcode's atts and example usage in a "Shortcodes" section of the generated `README.md`

### Plugin Integrations

- File: `inc/plugin-compat.php` (only created if any integrations are specified)
- For each plugin: wrap all calls in `function_exists()` or `class_exists()` guards so the theme degrades gracefully when the plugin is deactivated
- Common patterns:
  - **ACF**: `if ( function_exists( 'get_field' ) ) { $value = get_field( '{key}' ); ... }` - escape all output per context
  - **Yoast SEO**: detect via `defined( 'WPSEO_VERSION' )`; if present, suppress the theme's own meta description / OpenGraph / schema output to avoid duplicates
  - **WPForms**: use the `[wpforms id="{id}"]` shortcode; style via theme CSS targeting `.wpforms-*` classes (don't override structure)
  - **WP Rocket / page caches**: nothing required, but document any cache-bust headers or `nocache_headers()` calls in the README's "Compatibility" section
- Document the integration scope (which features of the plugin are honored, which are not) in ⑨ Decision Log

---

## Change Management Protocol

When a user requests changes to already-delivered files:

| Change Size | Action |
|-------------|--------|
| < 20 lines changed | Provide a `diff` block showing the change in context |
| > 20 lines changed OR structural changes | Re-output the full file |
| Change affects other files (dependency ripple) | List all affected files, then provide diffs or full files for each |

```diff
// Example diff format for small changes:
--- a/header.php
+++ b/header.php
@@ -15,7 +15,7 @@
 <nav class="main-nav" aria-label="<?php esc_attr_e( 'Primary', 'flavor-studio' ); ?>">
-    <?php wp_nav_menu( array( 'theme_location' => 'primary' ) ); ?>
+    <?php wp_nav_menu( array( 'theme_location' => 'primary', 'depth' => 3 ) ); ?>
 </nav>
```

After applying changes, always state:
- Which files were changed
- Which other files (if any) are affected by the change
- Whether any previously passing audit items are now affected

---

## Phase Gate 2 (Per Chunk)

After each chunk, output exactly:

> **Chunk N of M complete.** Files generated: [list files].
> Reply "Continue" to proceed to Chunk {N+1}, or request changes to any file above.

Wait for the user to reply before proceeding. Any message that does not explicitly ask for changes or corrections is treated as approval to continue. If the user requests changes, apply them per the Change Management Protocol before moving to the next chunk.
