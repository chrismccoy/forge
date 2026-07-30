# Always-Active Rules

These rules apply to **every phase, every chunk, every file**. When in doubt, refer back here.

## Naming Conventions

All names derive from the confirmed theme name (set during the Initialization Gate).

| Artifact | Convention | Example |
|----------|-----------|---------|
| `THEME_NAME` | Title Case display name | Flavor Studio |
| `THEME_SLUG` | lowercase, hyphens only | flavor-studio |
| `THEME_PREFIX` | lowercase, underscores, trailing `_` | flavor_studio_ |
| Function/hook names | `{THEME_PREFIX}snake_case` | `flavor_studio_setup()` |
| Class names | `{THEME_PREFIX}PascalCase` | `Flavor_Studio_Walker` |
| Enqueue handles | `{THEME_SLUG}-descriptor` | `flavor-studio-main-style` |
| Constants | `{THEME_PREFIX}UPPER_SNAKE` | `FLAVOR_STUDIO_VERSION` |
| Text domain | Always equals `THEME_SLUG` | `flavor-studio` |

---

## Escaping & Security

Every dynamic value output in a template **must** be escaped. No exceptions. No shortcutting.

### Output Escaping

| Output Context | Required Function(s) |
|----------------|----------------------|
| HTML text content | `esc_html()`, `esc_html__()`, `esc_html_e()` |
| HTML attributes | `esc_attr()`, `esc_attr__()`, `esc_attr_e()` |
| URLs (href, src, action) | `esc_url()` |
| JavaScript strings | `esc_js()` |
| Rich HTML (arbitrary HTML strings) | `wp_kses_post()` - see note below |
| Inline CSS property values | `esc_attr()` or `safecss_filter_attr()` |
| JSON in data attributes | `wp_json_encode()` then `esc_attr()` |

> **Note on `wp_kses_post()`:** This is a sanitizer that strips disallowed HTML tags - it is NOT an escaper. Use it only for arbitrary HTML strings that come from outside the normal post content pipeline (e.g. custom fields, option values, widget inputs). For post body output, always use `the_content()` which is self-escaping. Do NOT use `wp_kses_post()` as a substitute for `esc_html()` on plain text values.

### Input Sanitization

Any value received from user input (POST, GET, custom fields, option values) must be sanitized before use or storage:

| Input Context | Required Function |
|---------------|-------------------|
| Plain text strings | `sanitize_text_field()` |
| Email addresses | `sanitize_email()` |
| URLs | `esc_url_raw()` |
| Integers | `absint()` or `intval()` |
| Slugs / keys | `sanitize_key()` |
| HTML content | `wp_kses_post()` |
| Textarea (no HTML) | `sanitize_textarea_field()` |

### Custom Form Security

Any custom form that processes POST data must include a nonce:

```php
// In the form template:
wp_nonce_field( 'flavor_studio_form_action', 'flavor_studio_nonce' );

// When processing the form:
if ( ! isset( $_POST['flavor_studio_nonce'] ) ||
     ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['flavor_studio_nonce'] ) ), 'flavor_studio_form_action' ) ) {
	wp_die( esc_html__( 'Security check failed.', 'flavor-studio' ) );
}
```

### Self-Escaping vs. Not

**Self-escaping template tags** that do NOT need wrapping:
`the_title()`, `the_content()`, `the_permalink()`, `the_post_thumbnail()`, `the_ID()`, `the_category()`, `the_tags()`, `comment_form()`, `wp_list_comments()`

> **Note on `the_excerpt()`:** Generally safe, but manual excerpts may contain HTML (this is expected WordPress behavior, not a security issue). Call it normally; do not wrap in `esc_html()`.
>
> **Note on `the_author()`:** NOT self-escaping. It echoes raw database content without sanitization. Always use `echo esc_html( get_the_author() )` instead.

**Everything else** returned by `get_*` functions MUST be escaped.

```php
// FORBIDDEN - unescaped output
echo $variable;
echo get_the_title();
echo get_the_author();
echo '<a href="' . get_permalink() . '">';

// REQUIRED - escaped output
echo esc_html( $variable );
echo esc_html( get_the_title() );
echo esc_html( get_the_author() );
echo '<a href="' . esc_url( get_permalink() ) . '">';
the_title(); // Self-escaping - allowed
```

### Helper Functions and the Escape Boundary

**Helpers in `inc/template-functions.php` return raw values. Templates do the escaping.**

This rule keeps the escape boundary at the call site, where context is visible. A helper that returns `esc_html(...)` will be double-escaped by any caller who (correctly) escapes its return value, and entity-encoded twice in output. A helper that returns raw data lets each call site choose the right escaper for its context (`esc_html` in body text, `esc_attr` in attributes, `esc_url` in href).

```php
// CORRECT - helper returns raw, template escapes for context
function brewline_read_more_label() {
	return __( 'Read more', 'brewline' );
}

// In template:
echo esc_html( brewline_read_more_label() );           // body text
echo '<a aria-label="' . esc_attr( brewline_read_more_label() ) . '">'; // attribute

// WRONG - helper returns pre-escaped, template double-escapes
function brewline_read_more_label() {
	return esc_html__( 'Read more', 'brewline' );      // already escaped
}
echo esc_html( brewline_read_more_label() );           // double-escaped → "Read more" becomes "Read&#x20;more"
```

The exception: template tags in `inc/template-tags.php` that **echo** complete markup blocks (rather than return values). Those escape internally because they are responsible for their own output. The naming convention helps: `brewline_posted_on()` echoes; `brewline_get_posted_on()` returns.

---

## Internationalization

- All user-facing strings must use translation functions
- Text domain is always `THEME_SLUG` (hyphenated)
- Prefer combined escape+translate functions: `esc_html__()`, `esc_attr__()`
- Plural strings use `_n()` with proper singular/plural forms
- Context-dependent strings use `_x()` or combined `esc_html_x()`, `esc_attr_x()` for disambiguation:

```php
// Correct - context helps translators distinguish identical English strings
echo esc_html_x( 'Read', 'past tense', 'flavor-studio' );
echo esc_html_x( 'Read', 'imperative verb', 'flavor-studio' );

printf(
	/* translators: %s: post title */
	esc_html_x( 'Read more about %s', 'post link text', 'flavor-studio' ),
	esc_html( get_the_title() )
);
```

- Strings with variables use `sprintf()` + `esc_html__()`:

```php
// Correct
printf(
	/* translators: %s: author name */
	esc_html__( 'Posted by %s', 'flavor-studio' ),
	esc_html( get_the_author() )
);
```

```php
// FORBIDDEN - concatenated translatable string
echo esc_html__( 'Posted on ', 'flavor-studio' ) . $date;

// FORBIDDEN - variable inside translation function
echo esc_html__( "Posted on $date", 'flavor-studio' );

// FORBIDDEN - missing translators comment with sprintf
printf( esc_html__( 'Results: %d', 'flavor-studio' ), $count );
```

- Every `translators:` comment must be present when format strings are used
- Never concatenate translatable strings - use placeholders

---

## PHP Coding Standards

Follow WordPress PHP Coding Standards exactly:

| Rule | Correct | Wrong |
|------|---------|-------|
| Indentation | Tabs | Spaces |
| Yoda conditions | `if ( 'value' === $var )` | `if ( $var === 'value' )` |
| Spaces inside parentheses | `if ( $condition )` | `if ($condition)` |
| Opening braces | `function foo() {` (same line) | `function foo()\n{` (new line) |
| Naming | `snake_case` for functions/vars | `camelCase` |
| Array syntax | Short arrays `[]` - see note | Long arrays `array()` |
| String quoting | Single quotes `'text'` | Double quotes `"text"` (unless interpolating) |
| Trailing commas | Include in multiline arrays | Omit trailing comma |
| Comparison | Strict `===` / `!==` | Loose `==` / `!=` (unless intentional + commented) |

> **Note on array syntax:** WordPress core historically uses `array()`, and the official WordPress PHP Coding Standards still list `array()` as the convention. This document intentionally prefers `[]` for new theme code because it is more concise and widely adopted in modern PHP. Both syntaxes pass PHPCS with appropriate configuration. If the user explicitly requests `array()` syntax, honor that preference and apply it consistently throughout the theme.

### PHP 8.1+ Patterns

| Pattern | Status |
|---------|--------|
| Named arguments | Allowed but not required |
| Enums | Not used (WordPress core doesn't use them yet) |
| `str_contains()`, `str_starts_with()`, `str_ends_with()` | Allowed |
| Null safe operator `?->` | Allowed where it improves readability |
| Union types in docblocks | Use PHPDoc syntax `int\|string` (not native type hints, for WP ecosystem consistency) |
| Fibers, readonly properties | Not used in theme code |
| `declare(strict_types=1)` | Not used - WordPress core does not use strict types, and mixing strict/non-strict in the same runtime causes unexpected type coercion failures with WP functions |

### Docblocks

**File-level docblocks** - every PHP file must begin with:

```php
/**
 * [Brief description of what this file does]
 *
 * @package Theme_Name
 * @since   1.0.0
 */
```

**Function docblocks** - every function must have:

```php
/**
 * Brief description.
 *
 * @since 1.0.0
 *
 * @param  type  $param_name  Description.
 * @return type               Description.
 */
```

---

## Asset Pipeline Rules

**Tailwind CSS v3 via CLI. No CDN. No v4. No PostCSS. No Webpack. No Vite.**

The build system must use the standalone Tailwind CLI only. Do not introduce PostCSS, Webpack, Vite, or any other build tool unless the user explicitly requests it.

If the source HTML contains Tailwind v4 syntax (`@import "tailwindcss"`, `@theme`, `@variant`, CSS-first config), convert everything to v3 equivalents.

### Forbidden Patterns

If ANY of these appear in your output, the build is failed:

```html
<!-- ALL FORBIDDEN -->
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://cdn.tailwindcss.com?plugins=forms,typography"></script>
<script>tailwind.config = { ... }</script>
<link href="https://unpkg.com/tailwindcss@..." rel="stylesheet">
<style type="text/tailwindcss">...</style>
```

Also forbidden:
- Any other CSS framework CDN links
- Hardcoded `<link>` or `<script>` tags in any template file (all assets must go through `wp_enqueue_style()` / `wp_enqueue_script()`)
- Google Fonts loaded via `<link>` tags in templates (use `wp_enqueue_style()` or `@import` in `src/input.css`)

### Required Build Files

| File | Purpose |
|------|---------|
| `package.json` | `tailwindcss` `^3.4` as devDependency, build + watch scripts |
| `tailwind.config.js` | v3 format, design tokens in `theme.extend`, content paths |
| `src/input.css` | `@tailwind` directives + custom CSS extracted from source HTML |
| `assets/css/theme.css` | Compiled output - the ONLY CSS file WordPress loads |
| `style.css` (root) | WordPress header comment ONLY - zero CSS rules, zero imports |

### Required `package.json` Scripts

```json
{
  "scripts": {
    "build": "npx tailwindcss -i ./src/input.css -o ./assets/css/theme.css --minify",
    "watch": "npx tailwindcss -i ./src/input.css -o ./assets/css/theme.css --watch"
  }
}
```

### `src/input.css` Structure

The file must follow this exact order:

1. Font imports (if using `@import` strategy)
2. `@tailwind base;`
3. `@tailwind components;`
4. Custom `@layer base {}` overrides (typography defaults, etc.)
5. Custom `@layer components {}` (extracted reusable patterns from source HTML)
6. `@tailwind utilities;`
7. Custom `@layer utilities {}` (one-off utilities not in Tailwind core)

Every custom CSS rule must include a comment referencing the source HTML element it was extracted from.

### Content Paths in `tailwind.config.js`

```javascript
content: [
	'./*.php',
	'./template-parts/**/*.php',
	'./template-pages/**/*.php',
	'./inc/**/*.php',
	'./js/**/*.js',
],
```

### Enqueuing Rules

- Primary stylesheet: `assets/css/theme.css`
- Root `style.css` is NEVER enqueued
- All JS via `wp_enqueue_script()` with correct dependency arrays
- All scripts must load in the footer unless they must block rendering (rare)
- Use the WP 6.3+ `$args` array syntax for script registration:

```php
// REQUIRED - footer loading with defer strategy
wp_enqueue_script(
	'flavor-studio-navigation',
	get_template_directory_uri() . '/js/navigation.js',
	[],
	$version,
	[ 'in_footer' => true, 'strategy' => 'defer' ]
);
```

- Conditional comment-reply script:

```php
if ( is_singular() && comments_open() && get_option( 'thread_comments' ) ) {
	wp_enqueue_script( 'comment-reply' );
}
```

### Version Strings

Use `filemtime()` for cache busting during development, with a fallback for when the compiled CSS file does not yet exist (e.g. fresh clone before `npm run build` has been run):

```php
$css_path = get_template_directory() . '/assets/css/theme.css';
$version  = file_exists( $css_path )
	? filemtime( $css_path )
	: FLAVOR_STUDIO_VERSION;

wp_enqueue_style(
	'flavor-studio-style',
	get_template_directory_uri() . '/assets/css/theme.css',
	[],
	$version
);
```

Define a theme version constant for the production fallback:

```php
define( 'FLAVOR_STUDIO_VERSION', wp_get_theme()->get( 'Version' ) );
```

### Image Performance

- All non-hero images in templates must include `loading="lazy"`.
- Featured images that appear above the fold (hero/banner position) should include `fetchpriority="high"` and must NOT use `loading="lazy"`.
- Apply these as attributes on the `<img>` tag or via `the_post_thumbnail()` size with a custom `$attr` array argument.

---

## Accessibility Baseline

**Target: WCAG 2.1 AA compliance.**

### Structural Requirements

| Requirement | Implementation |
|-------------|----------------|
| Skip link | First focusable element in `<body>`, immediately after `<?php wp_body_open(); ?>`. Links to `#primary`. Visually hidden until focused. |
| Landmarks | `<header>`, `<nav>`, `<main id="primary">`, `<aside>`, `<footer>` |
| Single `<h1>` | One per page. Logical heading hierarchy (no skipping levels). |
| Language attribute | `<html <?php language_attributes(); ?>>` |
| WP body open hook | `<?php wp_body_open(); ?>` immediately after `<body>` tag |

### Interactive Elements

| Requirement | Implementation |
|-------------|----------------|
| Focus visibility | All interactive elements must have visible focus styles. `outline: none` alone is forbidden. Use `focus-visible` ring/outline with sufficient contrast. |
| Keyboard navigation | All menus, dropdowns, modals, and toggles must be fully keyboard operable (Tab, Enter, Escape, Arrow keys as appropriate). |
| Touch targets | Minimum 44×44 CSS pixels for all tappable elements (links, buttons, form controls). |
| Reduced motion | Wrap all animations/transitions in `@media (prefers-reduced-motion: no-preference) { }`. Provide static fallback. |

### Color & Contrast

| Requirement | Threshold |
|-------------|-----------|
| Normal text (< 18px / < 14px bold) | 4.5:1 minimum contrast ratio |
| Large text (≥ 18px / ≥ 14px bold) | 3:1 minimum contrast ratio |
| UI components & graphical objects | 3:1 minimum against adjacent colors |
| Focus indicators | 3:1 minimum against surrounding background |

During Phase 1, flag any color pairs from the source HTML that appear to violate these ratios. Note them in the validation report with measured or estimated ratios and proposed fixes.

### Forms

- Every `<input>`, `<select>`, `<textarea>` must have an associated `<label>` with matching `for`/`id`
- Required fields indicated visually AND via `aria-required="true"`
- Error states use `aria-describedby` pointing to error message elements
- Search forms use `role="search"` on the `<form>` element

### Content

- Text must be resizable up to 200% without loss of content or function
- Links must be distinguishable from surrounding text by more than color alone (underline or other visual indicator)
- Images: decorative images get `alt=""`, informative images get descriptive alt text
- `aria-label` on `<nav>` elements when multiple navs exist (e.g. `aria-label="Primary"`, `aria-label="Footer"`)

### RTL (Right-to-Left) Support

Do not generate RTL styles by default. If the user explicitly requests multilingual or RTL language support:

- Use Tailwind's `rtl:` variant for directional styles
- Prefer logical properties (`ms-*`/`me-*`) over physical (`ml-*`/`mr-*`)
- Ensure `dir="rtl"` is handled via `language_attributes()` on `<html>`
- Test that navigation, sidebars, and content flow reverse correctly
- Flag RTL as a decision in ⑨ Decision Log

Only include RTL support if the user raises it - do not propose it proactively.

---

## Error Recovery Protocol

If at any point during implementation you discover:

1. **A contradiction** between source HTML and WordPress capabilities
2. **A missed ambiguity** not caught in Phase 1
3. **A plugin dependency** that can't be replicated in theme code
4. **An impossible design pattern** without JavaScript framework

Then follow this exact protocol:

1. Add an inline comment: `/* {THEME_PREFIX}TODO: [description of issue] */`
2. Implement the best possible fallback
3. Add the issue to a running list in your response
4. In the **final chunk**, compile all issues into a "Known Limitations" section
5. **Never silently work around an issue** - always surface it

---

## Pattern Abstraction Rules

When converting HTML to template parts, follow these rules for repeated markup patterns:

| Scenario | Action |
|----------|--------|
| Markup block appears 2+ times identically | Extract to a `template-parts/` file |
| Markup block appears 2+ times with **data-only** variations (text, images, links) | Single template part using WP template tags - the loop handles variation |
| Markup block appears 2+ times with **structural** variations (different layout/elements) | Separate template parts (e.g. `content.php` vs `content-single.php`) |
| Markup block appears 2+ times with **minor structural** differences (e.g. optional badge) | Single template part with conditional logic and passed `$args` |

```php
// Passing args to template parts when needed
get_template_part( 'template-parts/card', null, [
	'show_excerpt' => true,
	'show_author'  => false,
] );

// Inside the template part:
$args = wp_parse_args( $args, [
	'show_excerpt' => true,
	'show_author'  => true,
] );
```

Document every abstraction decision with an inline comment explaining why the pattern was extracted or kept inline.

---

## Child Theme Compatibility

All generated themes must be child-theme-friendly. Follow these rules:

| Rule | Correct | Wrong |
|------|---------|-------|
| Parent theme assets | `get_template_directory_uri()` | `get_stylesheet_directory_uri()` |
| Parent theme file paths | `get_template_directory()` | `get_stylesheet_directory()` |
| Hook callbacks | Named functions | Anonymous closures on `add_action` / `add_filter` |
| Template functions | Wrap in `if ( ! function_exists() )` only when designed as overridable - see below | Wrapping every function indiscriminately |

### Overridable Functions

Not every function should be wrapped in `function_exists()`. Apply this decision:

| Function Type | Wrap in `function_exists()`? | Rationale |
|---------------|------------------------------|-----------|
| Template tags that output markup (in `inc/template-tags.php`) | Yes | Child themes may need to customize markup output |
| Utility/helper functions (in `inc/template-functions.php`) | No | These return data and should be consistent; child themes can use filters instead |
| Setup functions (`{prefix}setup`, `{prefix}scripts`, `{prefix}widgets_init`) | No | Child themes should use `after_setup_theme` at a later priority or `add_filter` / `remove_action` |
| Walker classes | No | Child themes can pass a different walker to `wp_nav_menu()` |

```php
// Overridable template tag
if ( ! function_exists( 'flavor_studio_posted_on' ) ) :
	/**
	 * Print post date markup.
	 *
	 * @since 1.0.0
	 */
	function flavor_studio_posted_on() {
		// ... full implementation
	}
endif;

// Non-overridable utility - child themes use filters instead
/**
 * Get the estimated reading time for the current post.
 *
 * @since 1.0.0
 *
 * @return int Reading time in minutes.
 */
function flavor_studio_reading_time() {
	// ... full implementation
}
```

### Documentation Requirement

The generated `README.md` must include a "Child Theme Support" section listing:
- All overridable functions (those wrapped in `function_exists()`)
- All removable hook callbacks (with `remove_action` / `remove_filter` examples)
- Template files that can be overridden by copying to a child theme

---

## Source HTML JavaScript Handling

When source HTML contains JavaScript beyond simple nav toggles, apply this decision table:

| Source JS Pattern | Action |
|-------------------|--------|
| Nav toggle / simple show-hide interactions | Rewrite in `js/navigation.js` |
| Standalone vanilla components (carousel, tabs, accordion, lightbox) | Port to `js/{component}.js`, enqueue conditionally on templates that use them |
| Small utility scripts (scroll-to-top, copy-to-clipboard) | Port to `js/{utility}.js`, enqueue conditionally |
| Framework-dependent (Alpine.js, HTMX, jQuery plugins) | Rewrite as vanilla JS if feasible. If not feasible, flag in ⑩ Ambiguities and discuss with user. Enter degraded mode if pervasive. |
| Third-party library (Swiper, GSAP, Lottie, AOS) | Ask user: keep as npm dependency and enqueue, replace with vanilla JS, or remove. Document decision in ⑨. |
| Inline `<script>` blocks | Extract to standalone `.js` files. Never leave inline scripts in templates. |
| `<script>` with CDN `src` | Identify the library and version. Ask user whether to install via npm or rewrite. Never keep CDN references. |

**Enqueue rules for additional JS files:**
- Each file gets its own `wp_enqueue_script()` call with correct dependencies
- Load in footer unless the script must block rendering (rare)
- Use `defer` strategy when supported (WP 6.3+)
- Conditional loading example:

```php
if ( is_page_template( 'template-pages/template-landing.php' ) ) {
	wp_enqueue_script(
		'flavor-studio-carousel',
		get_template_directory_uri() . '/js/carousel.js',
		[],
		$version,
		[ 'in_footer' => true, 'strategy' => 'defer' ]
	);
}
```

Add all additional JS files to the file manifest (⑪) and assign them to the appropriate chunk.

---

## Target Environment

| Parameter | Value |
|-----------|-------|
| WordPress | Latest stable release |
| PHP | 8.1+ |
| Browsers | Last 2 versions of Chrome, Firefox, Safari, Edge |
| Responsive breakpoints | Mobile-first: 320px+ → 640px+ → 768px+ → 1024px+ → 1280px+ |
| Tailwind CSS | v3.4.x (via CLI) |
| Node.js | 18+ (for Tailwind build) |
| License | GPL-2.0-or-later (or as specified by user during initialization) |
