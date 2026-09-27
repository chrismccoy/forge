# WordPress Template Hierarchy and Patterns Reference

This reference catalogs the block theme template hierarchy (HTML templates in `templates/`), template parts, custom templates, and template selection logic, with block markup examples for each.

## Quick Reference Table

### Template Hierarchy

| Purpose | Block Theme Template | Fallback Chain |
|---------|----------------------|----------------|
| **Homepage (blog)** | `templates/home.html` | index.html |
| **Static front page** | `templates/front-page.html` | home.html > index.html |
| **Single post** | `templates/single-{post-type}-{slug}.html`<br>`templates/single-{post-type}.html`<br>`templates/single.html` | singular.html > index.html |
| **Single page** | `templates/page-{slug}.html`<br>`templates/page-{id}.html`<br>`templates/page.html` | singular.html > index.html |
| **Category archive** | `templates/category-{slug}.html`<br>`templates/category-{id}.html`<br>`templates/category.html` | archive.html > index.html |
| **Tag archive** | `templates/tag-{slug}.html`<br>`templates/tag-{id}.html`<br>`templates/tag.html` | archive.html > index.html |
| **Author archive** | `templates/author-{nicename}.html`<br>`templates/author-{id}.html`<br>`templates/author.html` | archive.html > index.html |
| **Date archive** | `templates/date.html` | archive.html > index.html |
| **Custom post type archive** | `templates/archive-{post-type}.html` | archive.html > index.html |
| **Taxonomy archive** | `templates/taxonomy-{taxonomy}-{term}.html`<br>`templates/taxonomy-{taxonomy}.html`<br>`templates/taxonomy.html` | archive.html > index.html |
| **Search results** | `templates/search.html` | index.html |
| **404 error** | `templates/404.html` | index.html |
| **Attachment** | `templates/attachment.html` | single.html > singular.html > index.html |
| **Embed template** | `templates/embed.html` | index.html |

## Block Theme Template Structure

### Required Files

**Minimal block theme:**

```
block-theme/
├── style.css              # Required: Theme metadata
├── theme.json             # Required: Settings and styles
└── templates/
    └── index.html         # Required: Fallback template
```

**Complete block theme:**

```
block-theme/
├── style.css
├── theme.json
├── functions.php          # Optional: Hooks and setup
├── templates/
│   ├── index.html         # Fallback
│   ├── home.html          # Blog homepage
│   ├── front-page.html    # Static front page
│   ├── single.html        # Single post
│   ├── page.html          # Single page
│   ├── archive.html       # Archives
│   ├── category.html      # Category archives
│   ├── tag.html           # Tag archives
│   ├── author.html        # Author archives
│   ├── date.html          # Date archives
│   ├── search.html        # Search results
│   ├── 404.html           # 404 error
│   └── singular.html      # Fallback for single post/page
└── parts/
    ├── header.html        # Header template part
    ├── footer.html        # Footer template part
    └── sidebar.html       # Sidebar template part
```

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
		<!-- wp:comments-pagination /-->
		<!-- wp:post-comments-form /-->
	</div>
	<!-- /wp:comments -->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

**Key blocks for templates:**

| Block | Purpose | Usage |
|-------|---------|-------|
| `wp:template-part` | Include template part | `{"slug":"header","area":"header"}` |
| `wp:post-title` | Display post title | Auto-populated from post |
| `wp:post-content` | Display post content | The Loop equivalent |
| `wp:post-featured-image` | Display featured image | Conditional on image existence |
| `wp:post-author` | Display post author | With avatar, bio options |
| `wp:post-date` | Display post date | Configurable format |
| `wp:post-terms` | Display taxonomy terms | `{"term":"category"}` or `{"term":"post_tag"}` |
| `wp:comments` | Display comments section | Contains comment-template |
| `wp:query` | Custom post query loop | Archive template queries |
| `wp:site-title` | Display site title | From Settings > General |
| `wp:site-logo` | Display site logo | From Site Editor |
| `wp:navigation` | Display navigation menu | User-editable in Site Editor |

### Block Markup in Templates

**BAD: Inline styles in template**

```html
<!-- BAD: Hardcoded styles prevent user customization -->
<div style="background-color: #333; padding: 2rem;">
	<!-- wp:post-title /-->
</div>
```

**GOOD: Block attributes using theme.json presets**

```html
<!-- GOOD: References theme.json settings, user-customizable -->
<!-- wp:group {"style":{"color":{"background":"var(--wp--preset--color--primary)"},"spacing":{"padding":"var(--wp--preset--spacing--50)"}}} -->
<div class="wp-block-group">
	<!-- wp:post-title /-->
</div>
<!-- /wp:group -->
```

**GOOD: Class-based styling via theme.json**

```html
<!-- GOOD: Apply styles via theme.json blocks configuration -->
<!-- wp:group {"className":"hero-section"} -->
<div class="wp-block-group hero-section">
	<!-- wp:post-title /-->
</div>
<!-- /wp:group -->
```

Then in theme.json:

```json
{
	"styles": {
		"blocks": {
			"core/group": {
				"variations": {
					"hero-section": {
						"color": {
							"background": "var(--wp--preset--color--primary)"
						}
					}
				}
			}
		}
	}
}
```

## Template Hierarchy Fallback Chain

WordPress picks the most specific template in `templates/` that exists, then falls back step by step to `templates/index.html`.

### Front Page Display

**Settings > Reading > "Your homepage displays"**

- **Latest posts:** `front-page.html → home.html → index.html`
- **A static page:** front page `front-page.html → page-{slug}.html → page-{id}.html → page.html → singular.html → index.html`; posts page `home.html → index.html`

### Single Post

```
templates/single-{post-type}-{slug}.html
→ templates/single-{post-type}.html
→ templates/single.html
→ templates/singular.html
→ templates/index.html
```

Example for post type "product" with slug "widget": `single-product-widget.html → single-product.html → single.html → singular.html → index.html`

### Page

```
templates/page-{slug}.html → page-{id}.html → page.html → singular.html → index.html
```

Custom page templates are registered in theme.json `customTemplates` and live in `templates/` (see Custom Templates below).

### Archives

- **Category:** `category-{slug}.html → category-{id}.html → category.html → archive.html → index.html`
- **Tag:** `tag-{slug}.html → tag-{id}.html → tag.html → archive.html → index.html`
- **Author:** `author-{nicename}.html → author-{id}.html → author.html → archive.html → index.html`
- **Date:** `date.html → archive.html → index.html`
- **Custom post type:** `archive-{post-type}.html → archive.html → index.html`
- **Taxonomy:** `taxonomy-{taxonomy}-{term}.html → taxonomy-{taxonomy}.html → taxonomy.html → archive.html → index.html`

## Template Parts Deep Dive

### Block Theme Template Parts

**parts/header.html:**

```html
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|40","bottom":"var:preset|spacing|40"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull">
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
<div class="wp-block-group alignfull has-contrast-background-color has-base-color has-text-color has-background">
	<!-- wp:group {"layout":{"type":"flex","justifyContent":"space-between","flexWrap":"wrap"}} -->
	<div class="wp-block-group">
		<!-- wp:paragraph -->
		<p>&copy; <?php echo esc_html( date( 'Y' ) ); ?> <?php echo esc_html( get_bloginfo( 'name' ) ); ?></p>
		<!-- /wp:paragraph -->

		<!-- wp:social-links {"iconColor":"base","iconColorValue":"#ffffff","className":"is-style-logos-only"} -->
		<ul class="wp-block-social-links has-icon-color is-style-logos-only">
			<!-- wp:social-link {"url":"#","service":"twitter"} /-->
			<!-- wp:social-link {"url":"#","service":"facebook"} /-->
		</ul>
		<!-- /wp:social-links -->
	</div>
	<!-- /wp:group -->
</div>
<!-- /wp:group -->
```

**Template part registration in theme.json:**

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

**Using template parts in templates:**

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- Main content here -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

## Custom Templates

### Block Theme Custom Templates

**In theme.json:**

```json
{
	"customTemplates": [
		{
			"name": "page-full-width",
			"title": "Full Width Page",
			"postTypes": ["page"]
		},
		{
			"name": "page-no-title",
			"title": "Page Without Title",
			"postTypes": ["page"]
		},
		{
			"name": "single-portfolio",
			"title": "Portfolio Single",
			"postTypes": ["portfolio"]
		}
	]
}
```

**Create template file:**

`templates/page-full-width.html`:

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","align":"full","layout":{"type":"constrained","contentSize":"100%"}} -->
<main class="wp-block-group alignfull">
	<!-- wp:post-title {"level":1} /-->
	<!-- wp:post-content {"layout":{"type":"constrained","contentSize":"100%"}} /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

## Template Part Areas

**Available areas in theme.json:**

- `header` — Header area (typically site-wide header)
- `footer` — Footer area (typically site-wide footer)
- `uncategorized` — General area (sidebar, content sections)

**Custom areas (WordPress 6.0+):**

Can define custom areas, but WordPress doesn't provide UI labels for them.

**Best practice:** Stick to `header`, `footer`, `uncategorized` for theme directory submission.

## Anti-Patterns

### BAD: Hardcoded Navigation in Block Templates

```html
<!-- BAD: Hardcoded menu items -->
<!-- wp:group -->
<div class="wp-block-group">
	<a href="/about">About</a>
	<a href="/contact">Contact</a>
</div>
<!-- /wp:group -->
```

**GOOD: Navigation block**

```html
<!-- GOOD: User-editable navigation -->
<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"}} /-->
```
