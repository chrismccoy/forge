# WordPress Classic to Block Theme Migration Guide

Reference for reviewing a classic-to-block (or classic-to-hybrid) theme migration and judging how ready a classic theme is to migrate. It maps classic features to their block equivalents and lists what to check in the converted files. Severities follow the canonical model in SKILL.md.

## Contents

- Quick reference table
- Migration approaches and readiness
- functions.php to theme.json mapping
- Template conversion (PHP to HTML)
- Sidebar to template part migration
- Menu to Navigation block migration
- Customizer to Global Styles migration
- Hybrid themes
- Reviewing a migration: common pitfalls
- Cross-references

## Quick Reference Table

### Classic Feature to Block Equivalent

| Classic Feature | Block Theme Equivalent | Complexity | Migration Priority |
|-----------------|------------------------|------------|-------------------|
| **add_theme_support('align-wide')** | theme.json `settings.layout` (`contentSize`, `wideSize`) | Low | High (fundamental) |
| **add_theme_support('custom-line-height')** | theme.json `settings.typography.lineHeight` | Low | High |
| **add_theme_support('custom-spacing')** | theme.json `settings.spacing.padding` / `margin` | Low | High |
| **add_theme_support('custom-units')** | theme.json `settings.spacing.units` | Low | High |
| **add_theme_support('editor-color-palette')** | theme.json `settings.color.palette` | Low | High |
| **add_theme_support('editor-gradient-presets')** | theme.json `settings.color.gradients` | Low | High |
| **add_theme_support('editor-font-sizes')** | theme.json `settings.typography.fontSizes` | Low | High |
| **register_nav_menus()** | `wp:navigation` block | Medium | High (user-visible) |
| **register_sidebar()** | Template parts (`parts/*.html`) | Medium | High (layout) |
| **header.php / footer.php** | `parts/header.html`, `parts/footer.html` | Medium | High (structure) |
| **index.php, single.php, etc.** | `templates/*.html` | High | High (core templates) |
| **Customizer API** | Global Styles (Site Editor) | High | Medium (optional) |
| **get_template_part()** | `wp:template-part` block, or `wp:pattern` for reusable chunks | Low | Medium |
| **Dynamic sidebars / widgets** | Core blocks inside a template part | Medium | Medium |
| **the_title(), the_content()** | `wp:post-title`, `wp:post-content` blocks | Medium | High |
| **Template-level PHP logic** | PHP pattern in `patterns/`, included with `wp:pattern` | High | Depends on theme |

## Migration Approaches and Readiness

Three routes exist. Identify which one the theme is on before reviewing, because the expected file set differs.

| Approach | What it produces | Fits when |
|----------|------------------|-----------|
| Full conversion | Block theme: `templates/`, `parts/`, theme.json, no PHP templates | Few templates, little custom PHP logic in templates |
| Hybrid | Classic PHP templates plus theme.json, optionally block template parts | Large theme, live sites, migration in stages |
| Create Block Theme plugin export | Block theme files generated from Site Editor state | Heavily customized site whose edits should be preserved |

Plugin-exported themes need the same review as hand-written ones. Exports often carry user edits into templates as hand-written hex colors, px font sizes or inline styles (WARNING), and any PHP logic from the classic theme is not converted.

**Readiness signals in a classic theme:**

- Templates are mostly template tags with direct block equivalents (see the mapping tables below): easy.
- theme.json already present (hybrid): presets and layout are done; templates are the remaining work.
- Heavy conditional PHP in templates, custom walkers, or Customizer-driven layout switches: each needs a PHP pattern, a custom block (hand off to `/wp-build`) or a design decision. Flag these as the main migration cost.
- Customizer settings that change markup rather than colors or fonts: no direct Global Styles equivalent.

A classic theme that could go hybrid is INFO.

## functions.php to theme.json Mapping

### Theme Support Equivalents

**Classic functions.php:**

```php
<?php
function mytheme_setup() {
	add_theme_support( 'align-wide' );
	add_theme_support( 'custom-line-height' );
	add_theme_support( 'custom-spacing' );

	add_theme_support( 'editor-color-palette', array(
		array( 'name' => 'Primary',    'slug' => 'primary',    'color' => '#0073aa' ),
		array( 'name' => 'Secondary',  'slug' => 'secondary',  'color' => '#005177' ),
		array( 'name' => 'Foreground', 'slug' => 'foreground', 'color' => '#333333' ),
		array( 'name' => 'Background', 'slug' => 'background', 'color' => '#ffffff' ),
	) );

	add_theme_support( 'editor-font-sizes', array(
		array( 'name' => 'Small',       'size' => 14, 'slug' => 'small' ),
		array( 'name' => 'Medium',      'size' => 16, 'slug' => 'medium' ),
		array( 'name' => 'Large',       'size' => 24, 'slug' => 'large' ),
		array( 'name' => 'Extra Large', 'size' => 36, 'slug' => 'x-large' ),
	) );

	add_theme_support( 'responsive-embeds' );
	add_theme_support( 'editor-styles' );
	add_theme_support( 'custom-units', 'px', 'rem', 'em', 'vh', 'vw' );
}
add_action( 'after_setup_theme', 'mytheme_setup' );
```

**Block theme theme.json equivalent:**

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"settings": {
		"layout": {
			"contentSize": "640px",
			"wideSize": "1200px"
		},
		"typography": {
			"lineHeight": true,
			"defaultFontSizes": false,
			"fontSizes": [
				{ "slug": "small", "size": "0.875rem", "name": "Small" },
				{ "slug": "medium", "size": "1rem", "name": "Medium" },
				{ "slug": "large", "size": "1.5rem", "name": "Large" },
				{ "slug": "x-large", "size": "2.25rem", "name": "Extra Large" }
			]
		},
		"spacing": {
			"padding": true,
			"margin": true,
			"blockGap": true,
			"units": ["px", "rem", "em", "vh", "vw", "%"]
		},
		"color": {
			"defaultPalette": false,
			"custom": true,
			"palette": [
				{ "slug": "primary", "color": "#0073aa", "name": "Primary" },
				{ "slug": "secondary", "color": "#005177", "name": "Secondary" },
				{ "slug": "foreground", "color": "#333333", "name": "Foreground" },
				{ "slug": "background", "color": "#ffffff", "name": "Background" }
			]
		}
	}
}
```

**Key differences:**

- Font sizes move from px to rem, which scales with browser settings.
- The slugs `small`, `medium`, `large` and `x-large` collide with core default fontSize slugs. In v3 that makes `"defaultFontSizes": false` mandatory: without it the core defaults are `prevent_override` and the theme values are silently ignored (CRITICAL). Custom slugs with no collision and defaults left on produce a duplicate "Default" preset group (WARNING).
- `"defaultPalette": false` hides the core default colors. It is a design choice, not a requirement.
- `align-wide` becomes `layout.contentSize` and `layout.wideSize`.
- `responsive-embeds` and `editor-styles` need no theme.json entry; core adds them for block themes (see below).

Leaving the replaceable supports (editor-color-palette, editor-font-sizes, editor-gradient-presets, custom-line-height, custom-spacing, custom-units, align-wide) in a block theme's functions.php is a WARNING.

### add_theme_support() in Block Themes

Core calls `_add_default_theme_supports()` for block themes, which adds `post-thumbnails`, `responsive-embeds`, `editor-styles`, `html5` and `automatic-feed-links` automatically. Calling them again is redundant but harmless. Never flag them.

Supports that still carry meaning in a block theme:

- `wp-block-styles`: a genuine opt-in to core's opinionated block styles. Never flag it.
- `custom-logo`: optional; only needed to set logo size/crop arguments.
- `block-template-parts`: classic and hybrid themes only (see Hybrid themes).

`title-tag` is not needed in a block theme: block templates print the title tag through core's own `wp_head` callback regardless of theme support.

**What stays in functions.php:**

- `wp-block-styles` (if wanted) and `custom-logo` arguments
- Text domain loading, if the theme bundles its own translations
- Block style and pattern category registration
- Custom post types and taxonomies (these belong in a plugin for WordPress.org themes)

**What moves to theme.json:**

- Color palette and gradients
- Font sizes and font families
- Layout settings
- Spacing, typography and border controls

## Template Conversion (PHP to HTML)

PHP never executes in `.html` templates or parts. Any `<?php ... ?>`, `esc_html_e()` or template tag left in a converted file is sent to the browser as literal text and does nothing. For dynamic or translatable content, use one of:

- a PHP pattern in `patterns/`, included with `<!-- wp:pattern {"slug":"mytheme/name"} /-->`,
- a core block (site-title, post-date, and so on), or
- static text.

Strings typed as static text in `.html` files are not translatable. A theme that needs translatable template strings must move them into PHP patterns.

### header.php to parts/header.html

**Classic header.php:**

```php
<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<?php wp_head(); ?>
</head>

<body <?php body_class(); ?>>
<?php wp_body_open(); ?>

<div id="page" class="site">
	<header id="masthead" class="site-header">
		<div class="site-branding">
			<?php the_custom_logo(); ?>
			<p class="site-title">
				<a href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home"><?php bloginfo( 'name' ); ?></a>
			</p>
			<p class="site-description"><?php echo esc_html( get_bloginfo( 'description', 'display' ) ); ?></p>
		</div>

		<nav id="site-navigation" class="main-navigation">
			<?php wp_nav_menu( array( 'theme_location' => 'primary' ) ); ?>
		</nav>
	</header>
```

**Block theme parts/header.html:**

```html
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|40","bottom":"var:preset|spacing|40"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull" style="padding-top:var(--wp--preset--spacing--40);padding-bottom:var(--wp--preset--spacing--40)">
	<!-- wp:group {"layout":{"type":"flex","justifyContent":"space-between","flexWrap":"nowrap"}} -->
	<div class="wp-block-group">
		<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap"}} -->
		<div class="wp-block-group">
			<!-- wp:site-logo {"width":60} /-->
			<!-- wp:site-title {"level":0} /-->
		</div>
		<!-- /wp:group -->

		<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"},"style":{"spacing":{"blockGap":"var:preset|spacing|40"}}} /-->
	</div>
	<!-- /wp:group -->
</div>
<!-- /wp:group -->
```

The inline `style` on the outer wrapper is block-serialized from the `style.spacing.padding` attribute. It must be present for the markup to be valid, and it is never a hand-written-style finding.

**Key conversions:**

| Classic PHP | Block Equivalent |
|-------------|------------------|
| `the_custom_logo()` | `wp:site-logo` block |
| `bloginfo('name')` | `wp:site-title` block |
| `get_bloginfo('description')` | `wp:site-tagline` block |
| `wp_nav_menu()` | `wp:navigation` block |
| `<div class="site-header">` | `wp:group` block |

DOCTYPE, `<html>`, `<head>`, `<body>`, `wp_head()`, `wp_body_open()` and `wp_footer()` are output by core's block template canvas. They must not appear in block templates or parts.

### footer.php to parts/footer.html

**Classic footer.php:**

```php
	<footer id="colophon" class="site-footer">
		<div class="site-info">
			<p>&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?> <?php bloginfo( 'name' ); ?></p>
			<p>
				<a href="<?php echo esc_url( __( 'https://wordpress.org/', 'mytheme' ) ); ?>">
					<?php
					/* translators: %s: CMS name (WordPress) */
					printf( esc_html__( 'Proudly powered by %s', 'mytheme' ), 'WordPress' );
					?>
				</a>
			</p>
		</div>
	</footer>
</div><!-- #page -->

<?php wp_footer(); ?>

</body>
</html>
```

The year, site name and translatable credit are dynamic, so they move into a PHP pattern.

**patterns/footer-credits.php:**

```php
<?php
/**
 * Title: Footer credits
 * Slug: mytheme/footer-credits
 * Inserter: no
 */
?>
<!-- wp:paragraph {"align":"center"} -->
<p class="has-text-align-center">&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?> <?php echo esc_html( get_bloginfo( 'name' ) ); ?></p>
<!-- /wp:paragraph -->

<!-- wp:paragraph {"align":"center"} -->
<p class="has-text-align-center"><a href="<?php echo esc_url( __( 'https://wordpress.org/', 'mytheme' ) ); ?>"><?php
	/* translators: %s: CMS name (WordPress) */
	printf( esc_html__( 'Proudly powered by %s', 'mytheme' ), 'WordPress' );
?></a></p>
<!-- /wp:paragraph -->
```

**Block theme parts/footer.html:**

```html
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|50","bottom":"var:preset|spacing|50"}}},"backgroundColor":"contrast","textColor":"base","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull has-base-color has-contrast-background-color has-text-color has-background" style="padding-top:var(--wp--preset--spacing--50);padding-bottom:var(--wp--preset--spacing--50)">
	<!-- wp:pattern {"slug":"mytheme/footer-credits"} /-->
</div>
<!-- /wp:group -->
```

The `contrast` and `base` slugs must exist in the theme.json palette.

### single.php to templates/single.html

The classic `single.php` loop (`get_header()`, `the_title()`, meta, thumbnail, `the_content()`, terms, `comments_template()`, `get_sidebar()`, `get_footer()`) maps to:

**Block theme templates/single.html:**

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
	<!-- wp:post-title {"level":1} /-->

	<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap"},"style":{"spacing":{"blockGap":"var:preset|spacing|30"}}} -->
	<div class="wp-block-group">
		<!-- wp:post-author {"showAvatar":true,"showBio":false} /-->
		<!-- wp:post-date /-->
	</div>
	<!-- /wp:group -->

	<!-- wp:post-featured-image {"align":"wide"} /-->

	<!-- wp:post-content {"layout":{"type":"constrained"}} /-->

	<!-- wp:group {"layout":{"type":"flex","flexWrap":"wrap"}} -->
	<div class="wp-block-group">
		<!-- wp:post-terms {"term":"category","prefix":"Posted in: "} /-->
		<!-- wp:post-terms {"term":"post_tag","prefix":"Tagged: "} /-->
	</div>
	<!-- /wp:group -->

	<!-- wp:comments -->
	<div class="wp-block-comments">
		<!-- wp:comments-title /-->
		<!-- wp:comment-template -->
			<!-- wp:comment-author-name /-->
			<!-- wp:comment-date /-->
			<!-- wp:comment-content /-->
			<!-- wp:comment-reply-link /-->
		<!-- /wp:comment-template -->
		<!-- wp:comments-pagination -->
		<!-- wp:comments-pagination-previous /-->
		<!-- wp:comments-pagination-numbers /-->
		<!-- wp:comments-pagination-next /-->
		<!-- /wp:comments-pagination -->
		<!-- wp:post-comments-form /-->
	</div>
	<!-- /wp:comments -->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

`blockGap` and `layout` are applied by layout support at render time, so they add no inline style to the saved HTML. Block markup with a `tagName` must use that tag (`<main>` here).

**Template tag to block mapping:**

| Classic Template Tag | Block Equivalent |
|---------------------|------------------|
| `the_title()` | `wp:post-title` |
| `the_content()` | `wp:post-content` |
| `the_post_thumbnail()` | `wp:post-featured-image` |
| `get_the_date()` | `wp:post-date` |
| `get_the_author()` | `wp:post-author` (or `wp:post-author-name`) |
| `the_category()` | `wp:post-terms {"term":"category"}` |
| `the_tags()` | `wp:post-terms {"term":"post_tag"}` |
| `comments_template()` | `wp:comments` |
| `get_header()` | `wp:template-part {"slug":"header"}` |
| `get_footer()` | `wp:template-part {"slug":"footer"}` |
| `get_sidebar()` | `wp:template-part {"slug":"sidebar"}` |

### archive.php to templates/archive.html

The classic `archive.php` loop (archive title and description, `while ( have_posts() )`, `the_posts_pagination()`, a no-posts message) maps to:

**Block theme templates/archive.html:**

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
	<!-- wp:query-title {"type":"archive"} /-->
	<!-- wp:term-description /-->

	<!-- wp:query {"query":{"perPage":10,"pages":0,"offset":0,"postType":"post","order":"desc","orderBy":"date","author":"","search":"","exclude":[],"sticky":"","inherit":true}} -->
	<div class="wp-block-query">
		<!-- wp:post-template {"layout":{"type":"grid","columnCount":3}} -->
			<!-- wp:post-featured-image {"isLink":true} /-->
			<!-- wp:post-title {"isLink":true} /-->
			<!-- wp:post-excerpt /-->
			<!-- wp:post-date /-->
		<!-- /wp:post-template -->

		<!-- wp:query-pagination -->
			<!-- wp:query-pagination-previous /-->
			<!-- wp:query-pagination-numbers /-->
			<!-- wp:query-pagination-next /-->
		<!-- /wp:query-pagination -->

		<!-- wp:query-no-results -->
			<!-- wp:paragraph -->
			<p>No posts found.</p>
			<!-- /wp:paragraph -->
		<!-- /wp:query-no-results -->
	</div>
	<!-- /wp:query -->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

The no-results text is static and therefore not translatable. To keep it translatable, put the paragraph in a PHP pattern and include it with `wp:pattern` inside `wp:query-no-results`.

**Loop to Query block mapping:**

| Classic Loop | Block Equivalent |
|--------------|------------------|
| `have_posts()` | `wp:query` with `"inherit":true` (uses the main query) |
| `while (have_posts())` | `wp:post-template` (loops automatically) |
| `the_post()` | Automatic in post-template context |
| `the_posts_pagination()` | `wp:query-pagination` |
| Archive title | `wp:query-title {"type":"archive"}` |
| Archive description | `wp:term-description` |
| No results message | `wp:query-no-results` |

## Sidebar to Template Part Migration

A classic sidebar is a `register_sidebar()` call on `widgets_init`, a `sidebar.php` that calls `dynamic_sidebar()`, and `get_sidebar()` in templates.

### Block Theme Equivalent

Block templates have no way to render a widget area, so `register_sidebar()` in a block theme is dead code. Existing widget content is not migrated automatically; the theme supplies default blocks and users edit the part in the Site Editor.

**parts/sidebar.html:**

```html
<!-- wp:group {"tagName":"aside","layout":{"type":"constrained"}} -->
<aside class="wp-block-group">
	<!-- wp:heading -->
	<h2 class="wp-block-heading">Recent Posts</h2>
	<!-- /wp:heading -->

	<!-- wp:latest-posts {"postsToShow":5,"displayPostDate":true} /-->

	<!-- wp:heading -->
	<h2 class="wp-block-heading">Categories</h2>
	<!-- /wp:heading -->

	<!-- wp:categories /-->

	<!-- wp:search {"label":"Search","showLabel":false,"buttonText":"Search"} /-->
</aside>
<!-- /wp:group -->
```

Headings are static text here. For translatable headings, move the content into a PHP pattern and include it with `wp:pattern`.

**Usage in templates:**

```html
<!-- wp:template-part {"slug":"sidebar","area":"uncategorized"} /-->
```

**Widget to block mapping:**

| Classic Widget | Block Equivalent |
|----------------|------------------|
| Recent Posts widget | `wp:latest-posts` |
| Categories widget | `wp:categories` |
| Tag Cloud widget | `wp:tag-cloud` |
| Search widget | `wp:search` |
| Archives widget | `wp:archives` |
| Calendar widget | `wp:calendar` |
| RSS widget | `wp:rss` |
| Custom HTML widget | `wp:html` |

## Menu to Navigation Block Migration

### Classic Menu Pattern

```php
<?php
function mytheme_menus() {
	register_nav_menus( array(
		'primary' => __( 'Primary Menu', 'mytheme' ),
		'footer'  => __( 'Footer Menu', 'mytheme' ),
	) );
}
add_action( 'after_setup_theme', 'mytheme_menus' );
```

Output with `wp_nav_menu( array( 'theme_location' => 'primary' ) )`; users manage menus under Appearance > Menus.

### Block Theme Equivalent

Block themes use the Navigation block instead of menu locations:

```html
<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"}} /-->
```

Menus are stored as `wp_navigation` posts and edited in the Site Editor. With no `ref` attribute, the block falls back to the most recently created Navigation menu, then to a Page List, so an empty header is not a migration risk. Classic menus can be imported into the Navigation block from its settings.

See fse-guide.md for Navigation block configuration.

## Customizer to Global Styles Migration

### Classic Customizer Pattern

```php
<?php
function mytheme_customize_register( $wp_customize ) {
	$wp_customize->add_setting( 'primary_color', array(
		'default'           => '#0073aa',
		'sanitize_callback' => 'sanitize_hex_color',
	) );
	$wp_customize->add_control( new WP_Customize_Color_Control( $wp_customize, 'primary_color', array(
		'label'   => __( 'Primary Color', 'mytheme' ),
		'section' => 'colors',
	) ) );
}
add_action( 'customize_register', 'mytheme_customize_register' );

function mytheme_customizer_css() {
	$primary_color = get_theme_mod( 'primary_color', '#0073aa' );
	?>
	<style>
		.button { background-color: <?php echo esc_attr( $primary_color ); ?>; }
	</style>
	<?php
}
add_action( 'wp_head', 'mytheme_customizer_css' );
```

### Block Theme Equivalent

The setting becomes a palette preset and the CSS becomes a theme.json style. Users change it under Appearance > Editor > Styles; changes are saved in a `wp_global_styles` post and applied site-wide.

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"settings": {
		"color": {
			"palette": [
				{ "slug": "primary", "color": "#0073aa", "name": "Primary" }
			]
		}
	},
	"styles": {
		"elements": {
			"button": {
				"color": {
					"background": "var(--wp--preset--color--primary)"
				}
			}
		}
	}
}
```

Existing `theme_mod` values are not carried over. Use the classic defaults (or the live site's values) as the theme.json preset values. Customizer settings that switch layouts or toggle markup have no Global Styles equivalent; they become template variations, patterns or style variations.

## Hybrid Themes

A hybrid theme is a classic theme (PHP templates) that adds theme.json, and optionally block template parts.

Typical files: style.css, functions.php, theme.json, and PHP templates (index.php, single.php, header.php, footer.php).

### What theme.json Does in a Classic or Hybrid Theme

theme.json affects both the editor and the frontend:

- Editor: presets (palette, font sizes, spacing) and enabled controls.
- Frontend: core outputs the global styles stylesheet, including the preset CSS custom properties (`--wp--preset--color--primary` and so on), preset classes (`has-primary-color`) and any `styles` defined in theme.json.

What it does not do is restyle classic markup that uses the theme's own selectors (`.site-header`, `.button`). Those selectors keep their style.css rules until the theme's CSS references the preset variables.

**Example hybrid theme.json:**

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"settings": {
		"color": {
			"palette": [
				{ "slug": "primary", "color": "#0073aa", "name": "Primary" },
				{ "slug": "secondary", "color": "#005177", "name": "Secondary" }
			]
		},
		"typography": {
			"defaultFontSizes": false,
			"fontSizes": [
				{ "slug": "small", "size": "0.875rem", "name": "Small" },
				{ "slug": "medium", "size": "1rem", "name": "Medium" }
			]
		},
		"layout": {
			"contentSize": "640px",
			"wideSize": "1200px"
		}
	}
}
```

`"defaultFontSizes": false` is required here because `small` and `medium` collide with core default slugs.

**Connecting classic selectors to presets** (in style.css or an enqueued stylesheet):

```css
.site-header {
	background-color: var(--wp--preset--color--primary);
}
.button {
	background-color: var(--wp--preset--color--secondary);
}
```

### Block Template Parts in Classic Templates

A hybrid theme can use block parts inside PHP templates. Classic PHP templates include them with `block_template_part()`, not with a `wp:template-part` comment:

```php
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<?php block_template_part( 'header' ); ?>
```

The PHP template still owns DOCTYPE, `<head>`, `wp_head()`, `wp_body_open()` and `wp_footer()`; missing `wp_head()` or `wp_footer()` is still CRITICAL, missing `wp_body_open()` a WARNING. `add_theme_support( 'block-template-parts' )` (WordPress 6.1+) makes the parts editable in the Site Editor for classic themes.

### Staged Migration Order

1. Add theme.json (presets, layout).
2. Convert header and footer to `parts/*.html`, included in PHP templates with `block_template_part()`.
3. Convert templates to `templates/*.html`, starting with `index.html`. Once `templates/index.html` exists, WordPress treats the theme as a block theme.
4. Remove PHP templates and the functions.php supports replaced by theme.json.

## Reviewing a Migration: Common Pitfalls

| Pitfall | Problem | Fix | Severity |
|---------|---------|-----|----------|
| **PHP left in `.html` templates or parts** | Never executed; sent to the browser as literal text | PHP pattern via `wp:pattern`, core block, or static text | CRITICAL |
| **Block attributes without matching saved HTML** (for example `style.spacing.padding` with no inline `style`, `backgroundColor` without `has-…-background-color has-background`) | Block validation fails in the editor | Make the HTML match what the attributes serialize to | CRITICAL |
| **No `templates/index.html` and no `index.php`** (non-child theme) | Theme does not work | Add `templates/index.html` | CRITICAL |
| **theme.json missing `version`** | Whole file discarded on migration | Add `"version": 3` | CRITICAL |
| **v3 preset slugs colliding with core defaults** while `defaultFontSizes`/`defaultSpacingSizes` is not `false` | Theme values silently ignored | Set the default flag to `false` | CRITICAL |
| **`useRootPaddingAwareAlignments: true` with shorthand string root padding** | Root padding breaks | Use the object form (`top`, `right`, `bottom`, `left`) | CRITICAL |
| **Root left/right padding without `useRootPaddingAwareAlignments`** | Full-width blocks are inset by the root padding | Add `"useRootPaddingAwareAlignments": true` | WARNING |
| **Hand-written hex colors, px font sizes or inline CSS in templates** | Users cannot change them through Global Styles | Use presets via block attributes | WARNING (block-serialized styles are fine) |
| **Replaceable `add_theme_support()` left in functions.php** | Duplicates theme.json | Remove after moving to theme.json | WARNING |
| **Template part registered with `name` ending in `.html`** | Registered part has no file | Use `"header"`, not `"header.html"` | WARNING |
| **Expecting theme.json to restyle classic selectors** | Hybrid header/footer CSS unchanged | Reference preset variables in the theme's CSS | Not a finding by itself |
| **Over-locked templates** (`templateLock: "all"`) | Users cannot move, insert or remove blocks | Use `"contentOnly"` or `"insert"` where appropriate | Judgment call |
| **Theme Check not run** | WordPress.org rejection | Run the Theme Check plugin (Appearance > Theme Check) before submission | CRITICAL for any required-level error in a WordPress.org context |

## Cross-References

- theme.json v3 reference: theme-json-guide.md
- Template structure and hierarchy: template-patterns.md
- Full Site Editing features: fse-guide.md
- Custom blocks and Query Loop block development: hand off to `/wp-build`
- Escaping in classic PHP templates and full security audits: hand off to `/wp-security`
- Performance (including Query Loop performance): hand off to `/wp-performance`.
