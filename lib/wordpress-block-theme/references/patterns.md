# Block Theme Patterns

Working examples of correct block theme files, used as the GOOD side of findings.

Common theme patterns organized by concern. PHP examples use WordPress PHP Coding Standards (spaces in parentheses, array() not [], Yoda conditions). HTML templates use valid block markup. JSON examples use valid theme.json v3 syntax.

### theme.json v3 Complete Structure

```json
{
	"$schema": "https://schemas.wp.org/trunk/theme.json",
	"version": 3,
	"settings": {
		"appearanceTools": true,
		"useRootPaddingAwareAlignments": true,
		"color": {
			"defaultPalette": false,
			"palette": [
				{
					"slug": "primary",
					"color": "#0073aa",
					"name": "Primary"
				},
				{
					"slug": "secondary",
					"color": "#005177",
					"name": "Secondary"
				},
				{
					"slug": "foreground",
					"color": "#333333",
					"name": "Foreground"
				},
				{
					"slug": "background",
					"color": "#ffffff",
					"name": "Background"
				}
			]
		},
		"typography": {
			"defaultFontSizes": false,
			"fluid": true,
			"fontFamilies": [
				{
					"fontFamily": "\"Inter\", -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif",
					"name": "Inter",
					"slug": "inter",
					"fontFace": [
						{
							"fontFamily": "Inter",
							"fontWeight": "400",
							"fontStyle": "normal",
							"src": [ "file:./assets/fonts/inter-regular.woff2" ]
						},
						{
							"fontFamily": "Inter",
							"fontWeight": "700",
							"fontStyle": "normal",
							"src": [ "file:./assets/fonts/inter-bold.woff2" ]
						}
					]
				}
			],
			"fontSizes": [
				{
					"slug": "small",
					"size": "0.875rem",
					"name": "Small"
				},
				{
					"slug": "medium",
					"size": "1rem",
					"name": "Medium"
				},
				{
					"slug": "large",
					"size": "1.5rem",
					"name": "Large"
				}
			]
		},
		"spacing": {
			"defaultSpacingSizes": false,
			"spacingSizes": [
				{
					"slug": "30",
					"size": "1rem",
					"name": "Small"
				},
				{
					"slug": "40",
					"size": "1.5rem",
					"name": "Medium"
				},
				{
					"slug": "50",
					"size": "2rem",
					"name": "Large"
				}
			],
			"units": [ "px", "rem", "vh", "vw", "%" ]
		},
		"layout": {
			"contentSize": "640px",
			"wideSize": "1200px"
		},
		"border": {
			"radius": true,
			"color": true,
			"style": true,
			"width": true
		}
	},
	"styles": {
		"color": {
			"background": "var(--wp--preset--color--background)",
			"text": "var(--wp--preset--color--foreground)"
		},
		"typography": {
			"fontFamily": "var(--wp--preset--font-family--inter)",
			"fontSize": "var(--wp--preset--font-size--medium)",
			"lineHeight": "1.6"
		},
		"spacing": {
			"padding": {
				"top": "var(--wp--preset--spacing--50)",
				"right": "var(--wp--preset--spacing--50)",
				"bottom": "var(--wp--preset--spacing--50)",
				"left": "var(--wp--preset--spacing--50)"
			}
		},
		"elements": {
			"link": {
				"color": {
					"text": "var(--wp--preset--color--primary)"
				}
			},
			"heading": {
				"typography": {
					"fontWeight": "700",
					"lineHeight": "1.2"
				}
			}
		},
		"blocks": {
			"core/button": {
				"color": {
					"background": "var(--wp--preset--color--primary)",
					"text": "var(--wp--preset--color--background)"
				}
			}
		}
	},
	"customTemplates": [
		{
			"name": "page-no-title",
			"title": "Page Without Title",
			"postTypes": [ "page" ]
		}
	],
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
		}
	]
}
```

### Block Template Structure (templates/single.html)

**❌ BAD: Hardcoded inline styles defeat theme.json**
```html
<!-- wp:template-part {"slug":"header"} /-->

<main style="max-width: 1200px; margin: 0 auto; padding: 2rem; color: #333;">
	<h1 style="font-size: 32px; color: #0073aa;">Post Title</h1>
	<div style="font-size: 16px; line-height: 1.6;">
		<!-- wp:post-content /-->
	</div>
</main>

<!-- wp:template-part {"slug":"footer"} /-->
```

**✅ GOOD: Use block attributes and theme.json presets**
```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
	<!-- wp:post-title {"level":1} /-->

	<!-- wp:group {"layout":{"type":"flex","flexWrap":"nowrap"}} -->
	<div class="wp-block-group">
		<!-- wp:post-author {"showAvatar":true} /-->
		<!-- wp:post-date /-->
	</div>
	<!-- /wp:group -->

	<!-- wp:post-content {"layout":{"type":"constrained"}} /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

### Template Part Structure (parts/header.html)

**❌ BAD: Hardcoded colors and spacing**
```html
<div style="background: #ffffff; padding: 20px; border-bottom: 1px solid #cccccc;">
	<div style="max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between;">
		<h1 style="font-size: 24px; color: #0073aa;">Site Title</h1>
		<nav>Navigation</nav>
	</div>
</div>
```

**✅ GOOD: Use block attributes with theme.json preset references**
```html
<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|40","bottom":"var:preset|spacing|40"}}},"layout":{"type":"constrained"}} -->
<div class="wp-block-group alignfull" style="padding-top:var(--wp--preset--spacing--40);padding-bottom:var(--wp--preset--spacing--40)">
	<!-- wp:group {"layout":{"type":"flex","justifyContent":"space-between","flexWrap":"nowrap"}} -->
	<div class="wp-block-group">
		<!-- wp:site-logo {"width":60} /-->
		<!-- wp:site-title {"level":0} /-->

		<!-- wp:navigation {"layout":{"type":"flex","orientation":"horizontal"}} /-->
	</div>
	<!-- /wp:group -->
</div>
<!-- /wp:group -->
```

### useRootPaddingAwareAlignments

**❌ BAD: Root padding without useRootPaddingAwareAlignments**
```json
{
	"version": 3,
	"styles": {
		"spacing": {
			"padding": {
				"left": "2rem",
				"right": "2rem"
			}
		}
	}
}
```
Result: Full-width blocks have white space on left/right edges

**❌ BAD: useRootPaddingAwareAlignments with CSS shorthand**
```json
{
	"version": 3,
	"settings": {
		"useRootPaddingAwareAlignments": true
	},
	"styles": {
		"spacing": {
			"padding": "2rem"
		}
	}
}
```
Result: Won't work, must use object notation

**✅ GOOD: useRootPaddingAwareAlignments with object notation**
```json
{
	"version": 3,
	"settings": {
		"useRootPaddingAwareAlignments": true
	},
	"styles": {
		"spacing": {
			"padding": {
				"top": "var(--wp--preset--spacing--50)",
				"right": "var(--wp--preset--spacing--50)",
				"bottom": "var(--wp--preset--spacing--50)",
				"left": "var(--wp--preset--spacing--50)"
			}
		}
	}
}
```

### Block Pattern in Theme (patterns/hero.php)

**❌ BAD: Pattern without required headers**
```php
<?php
// Missing Title and Slug headers
?>
<!-- wp:cover -->
<div class="wp-block-cover">
	<h1>Welcome</h1>
</div>
<!-- /wp:cover -->
```

**✅ GOOD: Complete pattern with headers and dynamic values**
```php
<?php
/**
 * Title: Hero Section
 * Slug: mytheme/hero
 * Categories: featured, banner
 * Keywords: hero, banner, header
 * Block Types: core/cover
 * Viewport Width: 1400
 * Description: Full-width hero section with heading and CTA
 */
?>
<!-- wp:cover {"url":"<?php echo esc_url( get_theme_file_uri( 'assets/images/hero.jpg' ) ); ?>","dimRatio":50,"align":"full","style":{"spacing":{"padding":{"top":"var:preset|spacing|60","bottom":"var:preset|spacing|60"}}}} -->
<div class="wp-block-cover alignfull" style="padding-top:var(--wp--preset--spacing--60);padding-bottom:var(--wp--preset--spacing--60)">
	<span aria-hidden="true" class="wp-block-cover__background has-background-dim"></span>
	<img class="wp-block-cover__image-background" alt="" src="<?php echo esc_url( get_theme_file_uri( 'assets/images/hero.jpg' ) ); ?>" data-object-fit="cover" />

	<div class="wp-block-cover__inner-container">
		<!-- wp:heading {"textAlign":"center","level":1} -->
		<h1 class="has-text-align-center"><?php echo esc_html_x( 'Welcome to Our Site', 'Pattern placeholder', 'mytheme' ); ?></h1>
		<!-- /wp:heading -->

		<!-- wp:buttons {"layout":{"type":"flex","justifyContent":"center"}} -->
		<div class="wp-block-buttons">
			<!-- wp:button -->
			<div class="wp-block-button">
				<a class="wp-block-button__link wp-element-button"><?php echo esc_html_x( 'Get Started', 'Pattern placeholder', 'mytheme' ); ?></a>
			</div>
			<!-- /wp:button -->
		</div>
		<!-- /wp:buttons -->
	</div>
</div>
<!-- /wp:cover -->
```

### Style Variation (styles/dark.json)

**❌ BAD: Variation missing version or title**
```json
{
	"settings": {
		"color": {
			"palette": [
				{ "slug": "background", "color": "#1a1a1a" }
			]
		}
	}
}
```

**✅ GOOD: Complete variation with version and title**
```json
{
	"version": 3,
	"title": "Dark Mode",
	"settings": {
		"color": {
			"palette": [
				{
					"slug": "foreground",
					"color": "#ffffff",
					"name": "Foreground"
				},
				{
					"slug": "background",
					"color": "#1a1a1a",
					"name": "Background"
				},
				{
					"slug": "primary",
					"color": "#3dadff",
					"name": "Primary"
				}
			]
		}
	},
	"styles": {
		"color": {
			"background": "var(--wp--preset--color--background)",
			"text": "var(--wp--preset--color--foreground)"
		}
	}
}
```

### functions.php for Block Themes

**❌ BAD: Using add_theme_support() instead of theme.json**
```php
<?php
function mytheme_setup() {
	add_theme_support( 'align-wide' );
	add_theme_support( 'custom-line-height' );
	add_theme_support( 'custom-spacing' );
	add_theme_support( 'editor-color-palette', array(
		array(
			'name'  => 'Primary',
			'slug'  => 'primary',
			'color' => '#0073aa',
		),
	) );
}
add_action( 'after_setup_theme', 'mytheme_setup' );
```

**✅ GOOD: Minimal functions.php, settings in theme.json**
```php
<?php
/**
 * Theme setup and initialization
 */

defined( 'ABSPATH' ) || exit;

/**
 * Theme setup
 */
function mytheme_setup() {
	// Still valid in block themes
	add_theme_support( 'wp-block-styles' );
	add_theme_support( 'responsive-embeds' );
	add_theme_support( 'editor-styles' );

	// Load editor stylesheet
	add_editor_style( 'style.css' );

	// Internationalization
	load_theme_textdomain( 'mytheme', get_template_directory() . '/languages' );
}
add_action( 'after_setup_theme', 'mytheme_setup' );

/**
 * Enqueue additional scripts (if needed)
 */
function mytheme_enqueue_assets() {
	// Only if theme needs custom JS
	if ( is_front_page() ) {
		wp_enqueue_script(
			'mytheme-interactions',
			get_theme_file_uri( '/assets/js/interactions.js' ),
			array(),
			wp_get_theme()->get( 'Version' ),
			true
		);
	}
}
add_action( 'wp_enqueue_scripts', 'mytheme_enqueue_assets' );
```

### Child Theme Pattern

**❌ BAD: Child theme style.css missing Template header**
```css
/*
Theme Name: My Child Theme
Description: A child theme
Author: Author Name
*/
```
Result: WordPress won't recognize parent theme

**✅ GOOD: Complete child theme style.css**
```css
/*
Theme Name: My Child Theme
Template: parent-theme-folder
Description: A child theme extending Parent Theme
Author: Author Name
Author URI: https://example.com
Version: 1.0.0
License: GNU General Public License v2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html
Text Domain: my-child-theme
*/
```

**Child theme template part override:**
```
parent-theme/
├── parts/
│   └── header.html

child-theme/
├── style.css (with Template: parent-theme)
└── parts/
    └── header.html  ← Must match filename exactly to override
```
