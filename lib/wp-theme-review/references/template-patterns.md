# WordPress Template Hierarchy and Patterns Reference

This reference covers the template hierarchy for block themes (HTML templates) and classic themes (PHP templates), template parts, custom templates and the template-level anti-patterns a theme review looks for. Block-markup examples marked GOOD round-trip validly: the comment attributes match the saved HTML.

## Contents

- [Template Hierarchy Side-by-Side](#template-hierarchy-side-by-side)
- [Block Theme Template Structure](#block-theme-template-structure)
- [Classic Theme Template Structure](#classic-theme-template-structure)
- [Template Hierarchy Fallback Chains](#template-hierarchy-fallback-chains)
- [Template Parts](#template-parts)
- [Custom Templates](#custom-templates)
- [Template Part Areas](#template-part-areas)
- [Anti-Patterns](#anti-patterns)
- [Cross-References](#cross-references)

## Template Hierarchy Side-by-Side

Block themes resolve the same hierarchy as classic themes. For each candidate name, a block template (`templates/{name}.html`) takes priority over a PHP file of the same name.

| Purpose | Classic Theme (.php) | Block Theme (.html) | Fallback Chain |
|---------|---------------------|---------------------|----------------|
| **Homepage (latest posts)** | `front-page.php`<br>`home.php` | `templates/front-page.html`<br>`templates/home.html` | index |
| **Static front page** | `front-page.php` | `templates/front-page.html` | assigned custom template > page-{slug} > page-{id} > page > singular > index |
| **Posts page (static front page set)** | `home.php` | `templates/home.html` | index |
| **Single post** | `single-{post-type}-{slug}.php`<br>`single-{post-type}.php`<br>`single.php` | `templates/single-{post-type}-{slug}.html`<br>`templates/single-{post-type}.html`<br>`templates/single.html` | singular > index |
| **Single page** | `page-{slug}.php`<br>`page-{id}.php`<br>`page.php` | `templates/page-{slug}.html`<br>`templates/page-{id}.html`<br>`templates/page.html` | singular > index |
| **Category archive** | `category-{slug}.php`<br>`category-{id}.php`<br>`category.php` | `templates/category-{slug}.html`<br>`templates/category-{id}.html`<br>`templates/category.html` | archive > index |
| **Tag archive** | `tag-{slug}.php`<br>`tag-{id}.php`<br>`tag.php` | `templates/tag-{slug}.html`<br>`templates/tag-{id}.html`<br>`templates/tag.html` | archive > index |
| **Author archive** | `author-{nicename}.php`<br>`author-{id}.php`<br>`author.php` | `templates/author-{nicename}.html`<br>`templates/author-{id}.html`<br>`templates/author.html` | archive > index |
| **Date archive** | `date.php` | `templates/date.html` | archive > index |
| **Custom post type archive** | `archive-{post-type}.php` | `templates/archive-{post-type}.html` | archive > index |
| **Taxonomy archive** | `taxonomy-{taxonomy}-{term}.php`<br>`taxonomy-{taxonomy}.php`<br>`taxonomy.php` | `templates/taxonomy-{taxonomy}-{term}.html`<br>`templates/taxonomy-{taxonomy}.html`<br>`templates/taxonomy.html` | archive > index |
| **Search results** | `search.php` | `templates/search.html` | index |
| **404 error** | `404.php` | `templates/404.html` | index |
| **Attachment** | `{mime-type}-{subtype}.php`, `{subtype}.php`, `{mime-type}.php`<br>`attachment.php` | `templates/attachment.html` | single > singular > index |
| **Embed** | `embed-{post-type}-{format}.php`<br>`embed-{post-type}.php`<br>`embed.php` | `templates/embed.html` | core default embed template |

`front-page` is used whenever it exists, whichever "Your homepage displays" option is set. With a static front page, it also overrides the template assigned to that page.

## Block Theme Template Structure

### Required Files

**Minimal block theme:**

```
block-theme/
├── style.css              # Required: theme header
├── theme.json             # Strongly recommended (WARNING if missing)
└── templates/
    └── index.html         # Required: final fallback template
```

Only `style.css` and `templates/index.html` are required. The legacy `block-templates/index.html` location is also recognized. A block theme without theme.json works but is a WARNING.

**Typical complete block theme:**

```
block-theme/
├── style.css
├── theme.json
├── functions.php          # Optional
├── templates/
│   ├── index.html
│   ├── home.html
│   ├── front-page.html
│   ├── single.html
│   ├── page.html
│   ├── singular.html
│   ├── archive.html
│   ├── search.html
│   └── 404.html
├── parts/
│   ├── header.html
│   └── footer.html
├── patterns/              # Optional: PHP or static pattern files
└── styles/                # Optional: style variations
```

None of the optional templates, parts, patterns or styles is a finding when absent.

### Block Template Anatomy

**templates/single.html:**

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
	<!-- wp:post-title {"level":1} /-->

	<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap"}} -->
	<div class="wp-block-group">
		<!-- wp:post-author {"showAvatar":true,"showBio":false} /-->
		<!-- wp:post-date /-->
		<!-- wp:post-terms {"term":"category"} /-->
	</div>
	<!-- /wp:group -->

	<!-- wp:post-featured-image {"align":"wide"} /-->

	<!-- wp:post-content {"layout":{"type":"constrained"}} /-->

	<!-- wp:post-terms {"term":"post_tag"} /-->

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

**Key blocks for templates:**

| Block | Purpose | Notes |
|-------|---------|-------|
| `wp:template-part` | Include a template part | `{"slug":"header","area":"header"}` |
| `wp:pattern` | Include a registered pattern | The way to get PHP-generated output into a template |
| `wp:query` + `wp:post-template` | Query loop | The block equivalent of The Loop; archive templates normally use `"inherit":true` |
| `wp:post-title` | Post title | Uses the current post in context |
| `wp:post-content` | Post content | Outputs the current post's content |
| `wp:post-featured-image` | Featured image | Renders nothing when there is no image |
| `wp:post-author` / `wp:post-date` / `wp:post-terms` | Post meta | `{"term":"category"}` or `{"term":"post_tag"}` |
| `wp:comments` | Comments section | Contains `wp:comment-template` |
| `wp:site-title` / `wp:site-logo` | Site identity | From site settings |
| `wp:navigation` | Navigation menu | Editable in the Site Editor |

### Block Markup in Templates

PHP never executes in `.html` templates or parts. Any `<?php … ?>` in an `.html` file is printed as literal text or stripped, so report it as CRITICAL. Dynamic output belongs in a PHP pattern included with `wp:pattern`, in a core block, or in static text.

**BAD: Hand-written inline styles in a template**

```html
<div style="background-color: #333; padding: 2rem;">
	<!-- wp:post-title /-->
</div>
```

Raw HTML with hand-written inline CSS and a hex color cannot be edited in the Site Editor and ignores the theme presets (WARNING).

**GOOD: Block attributes using theme.json presets**

```html
<!-- wp:group {"backgroundColor":"primary","style":{"spacing":{"padding":{"top":"var:preset|spacing|50","right":"var:preset|spacing|50","bottom":"var:preset|spacing|50","left":"var:preset|spacing|50"}}}} -->
<div class="wp-block-group has-primary-background-color has-background" style="padding-top:var(--wp--preset--spacing--50);padding-right:var(--wp--preset--spacing--50);padding-bottom:var(--wp--preset--spacing--50);padding-left:var(--wp--preset--spacing--50)">
	<!-- wp:post-title /-->
</div>
<!-- /wp:group -->
```

A palette color is stored as the slug (`"backgroundColor":"primary"`) and serializes to the `has-primary-background-color has-background` classes. Spacing presets are stored as `var:preset|spacing|50` and serialize to matching inline `padding-*` declarations. These block-serialized styles are valid and are never flagged. A comment attribute without its matching class or inline style in the HTML is invalid block markup (CRITICAL).

**GOOD: A registered block style, styled from theme.json**

Register the style in `functions.php`:

```php
register_block_style(
	'core/group',
	array(
		'name'  => 'hero-section',
		'label' => __( 'Hero', 'mytheme' ),
	)
);
```

Apply it in the template. The block-style class is `is-style-{name}`:

```html
<!-- wp:group {"className":"is-style-hero-section"} -->
<div class="wp-block-group is-style-hero-section">
	<!-- wp:post-title /-->
</div>
<!-- /wp:group -->
```

Style it in theme.json:

```json
{
	"styles": {
		"blocks": {
			"core/group": {
				"variations": {
					"hero-section": {
						"color": {
							"background": "var:preset|color|primary"
						}
					}
				}
			}
		}
	}
}
```

`styles.blocks.<block>.variations.<slug>` targets only the registered block style `is-style-<slug>`. It does not apply to an arbitrary `className` such as `hero-section`. Since WordPress 6.6 a block style variation can also be defined as a JSON partial in `styles/` with a `blockTypes` key, which registers it without PHP.

## Classic Theme Template Structure

### Required Files

**Minimal classic theme:**

```
classic-theme/
├── style.css              # Required: theme header
├── index.php              # Required: final fallback template
├── screenshot.png         # Required for WordPress.org
└── functions.php          # Optional, but nearly always present
```

Optional templates follow the hierarchy above. `header.php`, `footer.php`, `sidebar.php` and `comments.php` are loaded with `get_header()`, `get_footer()`, `get_sidebar()` and `comments_template()`. Reusable partials normally live in `template-parts/` and load with `get_template_part()`.

### Template Tags and Escaping

`echo` of a `get_*()` value needs escaping. The `the_*()` tags echo for themselves and are not flagged.

| Function | Behavior | Reviewer note |
|----------|----------|---------------|
| `the_title()` | Echoes the title through the `the_title` filter | Do not flag. Inside an HTML attribute, `the_title_attribute()` is correct |
| `get_the_title()` | Returns the title | `esc_html()` when echoed; `the_title_attribute( array( 'echo' => false ) )` or `esc_attr()` in attributes |
| `the_permalink()` | Echoes the URL, escaped with `esc_url()` | Do not flag |
| `get_permalink()` | Returns the URL | `esc_url()` when echoed |
| `the_author()` | Echoes the author display name | Do not flag |
| `get_the_author()` | Returns the display name | `esc_html()` when echoed |
| `the_date()` / `the_time()` | Echo the formatted date | Do not flag. `the_date()` prints only once per day in a loop, so `get_the_date()` is often intended |
| `get_the_date()` | Returns the formatted date | `esc_html()` when echoed |
| `the_content()` | Echoes content through the `the_content` filter (blocks, shortcodes, `wpautop`) | Filtered, not escaped. Never wrap in `esc_html()`, which breaks the markup |
| `the_excerpt()` | Echoes the excerpt through the `the_excerpt` filter | Do not flag |
| `the_category()` / `the_tags()` / `the_post_thumbnail()` | Echo core-built HTML | Do not flag |
| `get_the_category_list()` / `get_the_tag_list()` / `get_the_post_thumbnail()` | Return core-built HTML | Echoing as-is is the accepted pattern; `wp_kses_post()` if the result is modified |

Unescaped output in classic templates is a WARNING. Hand off a full audit to `/wp-security`.

```php
// BAD: unescaped get_* output
<h1><?php echo get_the_title(); ?></h1>
<a href="<?php echo get_permalink(); ?>">Read more</a>

// GOOD
<h1><?php echo esc_html( get_the_title() ); ?></h1>
<a href="<?php echo esc_url( get_permalink() ); ?>"><?php esc_html_e( 'Read more', 'mytheme' ); ?></a>
```

### Conditional Tags Commonly Misused

| Function | True when |
|----------|-----------|
| `is_front_page()` | The site front page, whether it shows latest posts or a static page |
| `is_home()` | The posts index: the front page when it shows latest posts, otherwise the assigned posts page |
| `is_singular()` | Any single post, page or attachment |
| `is_page_template( 'template-full-width.php' )` | The current page uses that custom template |

Code that uses `is_home()` to mean "front page" is wrong when a static front page is set.

## Template Hierarchy Fallback Chains

The chains below use classic filenames. Block themes use the same names under `templates/` with `.html`.

### Front Page

**"Your homepage displays" = Latest posts:**

```
front-page.php → home.php → index.php
```

**"Your homepage displays" = A static page:**

Front page:
```
front-page.php → {assigned custom template} → page-{slug}.php → page-{id}.php → page.php → singular.php → index.php
```

Posts page:
```
home.php → index.php
```

### Single Post

```
{assigned custom template} → single-{post-type}-{slug}.php → single-{post-type}.php → single.php → singular.php → index.php
```

For post type `product` with slug `widget`, a block theme checks `templates/single-product-widget.html`, then `single-product.html`, `single.html`, `singular.html` and `index.html`.

### Page

```
{assigned custom template} → page-{slug}.php → page-{id}.php → page.php → singular.php → index.php
```

### Archives

```
category-{slug}.php → category-{id}.php → category.php → archive.php → index.php
tag-{slug}.php → tag-{id}.php → tag.php → archive.php → index.php
author-{nicename}.php → author-{id}.php → author.php → archive.php → index.php
date.php → archive.php → index.php
archive-{post-type}.php → archive.php → index.php
taxonomy-{taxonomy}-{term}.php → taxonomy-{taxonomy}.php → taxonomy.php → archive.php → index.php
```

## Template Parts

### Block Theme Template Parts

**parts/header.html:**

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

**parts/footer.html:**

```html
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|50","bottom":"var:preset|spacing|50"}}},"backgroundColor":"contrast","textColor":"base","layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull has-base-color has-contrast-background-color has-text-color has-background" style="padding-top:var(--wp--preset--spacing--50);padding-bottom:var(--wp--preset--spacing--50)">
	<!-- wp:group {"layout":{"type":"flex","justifyContent":"space-between","flexWrap":"wrap"}} -->
	<div class="wp-block-group">
		<!-- wp:pattern {"slug":"mytheme/footer-copyright"} /-->

		<!-- wp:social-links {"className":"is-style-logos-only"} -->
		<ul class="wp-block-social-links is-style-logos-only">
			<!-- wp:social-link {"url":"#","service":"facebook"} /-->
			<!-- wp:social-link {"url":"#","service":"instagram"} /-->
		</ul>
		<!-- /wp:social-links -->
	</div>
	<!-- /wp:group -->
</div>
<!-- /wp:group -->
```

The copyright year comes from a PHP pattern, because PHP in the `.html` part would never run.

**patterns/footer-copyright.php:**

```php
<?php
/**
 * Title: Footer copyright
 * Slug: mytheme/footer-copyright
 * Inserter: no
 */
?>
<!-- wp:paragraph -->
<p>&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?> <?php echo esc_html( get_bloginfo( 'name' ) ); ?></p>
<!-- /wp:paragraph -->
```

Static text such as `<p>&copy; Site Name</p>` is also acceptable.

**Template part registration (theme.json excerpt):**

```json
{
	"templateParts": [
		{
			"name": "header",
			"title": "Header",
			"area": "header"
		},
		{
			"name": "footer",
			"title": "Footer",
			"area": "footer"
		},
		{
			"name": "sidebar",
			"title": "Sidebar",
			"area": "uncategorized"
		}
	]
}
```

`name` is the file name in `parts/` without `.html`. A registered `name` with no matching file, including a `name` that ends in `.html`, is a WARNING. A `parts/` file that is not registered is INFO.

**Classic and hybrid themes** can include a block template part from PHP with `block_template_part( 'header' );`.

### Classic Theme Template Parts

The checks that matter in `header.php` and `footer.php` are the required hooks:

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
```

```php
<?php wp_footer(); ?>
</body>
</html>
```

- Missing `wp_head()` or `wp_footer()`: CRITICAL.
- Missing `wp_body_open()`: WARNING.

`get_template_part( 'template-parts/content', get_post_format() )` loads `template-parts/content-{format}.php` and falls back to `template-parts/content.php`.

## Custom Templates

### Block Theme Custom Templates

**theme.json excerpt:**

```json
{
	"customTemplates": [
		{
			"name": "page-no-title",
			"title": "Page Without Title",
			"postTypes": ["page"]
		},
		{
			"name": "portfolio-wide",
			"title": "Portfolio Wide",
			"postTypes": ["portfolio"]
		}
	]
}
```

Each entry needs a matching file, here `templates/page-no-title.html`. A `templates/` file that is not part of the hierarchy and not listed in `customTemplates` is INFO: it is not offered in the editor's template picker. Hierarchy templates such as `page.html` or `single-portfolio.html` apply automatically and do not belong in `customTemplates`. A custom template name that collides with a hierarchy name (for example `page-about`) applies to that page automatically as well as appearing in the picker, which is usually unintended.

**templates/page-no-title.html:**

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
	<!-- wp:post-content {"layout":{"type":"constrained"}} /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

### Classic Theme Custom Templates

```php
<?php
/**
 * Template Name: Full Width Page
 * Template Post Type: page, post
 */

get_header();
// Template content.
get_footer();
```

The `Template Name` header makes the file selectable in the editor's Template panel. `Template Post Type` (WordPress 4.7+) extends it beyond pages.

## Template Part Areas

Core defines three areas:

- `header`
- `footer`
- `uncategorized` (sidebars, content sections and anything else)

Custom areas only come from the `default_wp_template_part_areas` PHP filter. theme.json alone cannot add an area: an unknown `area` value in `templateParts` is treated as `uncategorized`.

## Anti-Patterns

### PHP in a Block Template or Part

```html
<!-- BAD: never executes -->
<!-- wp:paragraph -->
<p>&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?></p>
<!-- /wp:paragraph -->
```

Fix: move the dynamic output into a PHP pattern and include it with `<!-- wp:pattern {"slug":"mytheme/name"} /-->`, use a core block, or use static text. See the footer example above.

### Hardcoded Navigation in Block Templates

```html
<!-- BAD: raw links inside a group cannot be managed as a menu -->
<!-- wp:group -->
<div class="wp-block-group">
	<a href="/about">About</a>
	<a href="/contact">Contact</a>
</div>
<!-- /wp:group -->
```

```html
<!-- GOOD: editable navigation -->
<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"}} /-->
```

### Direct Database Queries in Templates

```php
// BAD: raw SQL in a template
global $wpdb;
$results = $wpdb->get_results( "SELECT * FROM {$wpdb->posts} WHERE post_type = 'post'" );

// GOOD: WordPress query API
$query = new WP_Query(
	array(
		'post_type'      => 'post',
		'posts_per_page' => 10,
	)
);
```

A custom `WP_Query` loop must end with `wp_reset_postdata()`. Hand off any SQL built from request data to `/wp-security`.

## Cross-References

- **theme.json configuration:** theme-json-guide.md
- **Full Site Editing features:** fse-guide.md
- **Classic to block theme migration:** classic-to-block-guide.md
- **Escaping and security in templates:** `/wp-security`
- **Custom block development:** `/wp-build`
- **Plugin-territory functionality in a theme:** `/wp-review`
