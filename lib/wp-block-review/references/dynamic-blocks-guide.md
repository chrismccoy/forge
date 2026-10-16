# WordPress Dynamic Blocks Reference

This reference catalogs server-side rendering patterns for WordPress blocks — when to use dynamic vs static blocks, render_callback vs render PHP file patterns, WP_Block object usage, block context, and the critical InnerBlocks gotcha. Covers decision-making, implementation patterns, escaping rules, and common mistakes.

## Quick Reference Table

### Dynamic Block Decision Table

| Approach | When to Use | PHP Complexity | WP Version | Example Use Case |
|----------|-------------|----------------|------------|------------------|
| **Static save** | Content fixed at save time | None | All | Buttons, spacers, testimonials |
| **render_callback** | Simple PHP logic, <50 LOC | Low-Medium | All | Latest posts, user info, date display |
| **render file** | Complex PHP, separate template | Medium-High | 6.1+ | Query loops, complex layouts, multiple queries |
| **Hybrid** | Static base + dynamic enhancement | Medium | All | Static HTML with dynamic counters/badges |

### Rendering Methods Comparison

| Method | Definition Location | PHP Execution | Best For |
|--------|---------------------|---------------|----------|
| **save() in JS** | JavaScript save function | None — outputs HTML | Fixed content, no server processing |
| **render_callback** | PHP function in plugin file | Every page load | Simple dynamic content |
| **render file** | PHP file (render.php) | Every page load | Complex templates, organized code |

## Static vs Dynamic Decision Guide

### When to Use Static Blocks (save function)

**Characteristics:**
- Content doesn't change after saving
- Simple HTML output
- No server-side processing needed
- Markup doesn't need to update site-wide

**Examples:**
- Button blocks
- Spacer/separator blocks
- Testimonial blocks
- Static hero sections
- Fixed layout containers

```javascript
// Static block pattern
function save( { attributes } ) {
	const blockProps = useBlockProps.save();
	return (
		<div { ...blockProps }>
			<h2>{ attributes.heading }</h2>
			<p>{ attributes.content }</p>
		</div>
	);
}
```

**Pros:**
- No server processing (faster page loads)
- HTML cached in database
- No PHP expertise required

**Cons:**
- Markup changes require re-saving all posts
- Can't display latest data
- Can't use server-side logic

### When to Use Dynamic Blocks (render_callback/render file)

**Characteristics:**
- Content changes (latest posts, current user, date/time)
- Needs server-side processing (queries, calculations)
- Markup should update site-wide without re-saving posts
- Requires data not available in JavaScript

**Examples:**
- Latest posts blocks
- User info blocks (current user name, avatar)
- Post query blocks
- Date/time blocks
- Conditional blocks (show if logged in)
- Blocks with complex calculations

```javascript
// Dynamic block pattern
function save() {
	return null; // Or <InnerBlocks.Content /> if has inner blocks
}
```

```php
// render_callback
function mypl_render_block( $attributes, $content, $block ) {
	$posts = get_posts( array( 'numberposts' => $attributes['count'] ) );
	// Output generation
}
```

**Pros:**
- Always shows latest data
- Markup updates without re-saving posts
- Can use WordPress PHP functions
- Can perform complex server-side logic

**Cons:**
- Server processing on every page load (slower)
- Not cached in database
- Requires PHP expertise

### Decision Tree

```
Does content change after saving?
├─ NO → Use static block (save function)
└─ YES → Does it need WordPress data (posts, users, etc)?
    ├─ YES → Use dynamic block
    └─ NO → Does it need server-side logic?
        ├─ YES → Use dynamic block
        └─ NO → Consider Interactivity API for frontend interaction
```

## render_callback Pattern

The `render_callback` parameter in `register_block_type()` specifies a PHP function to generate block output.

### Basic render_callback Pattern

```php
<?php
function mypl_register_block() {
	register_block_type( __DIR__ . '/build/my-block', array(
		'render_callback' => 'mypl_render_callback',
	) );
}
add_action( 'init', 'mypl_register_block' );

function mypl_render_callback( $attributes, $content, $block ) {
	$wrapper_attributes = get_block_wrapper_attributes();

	return sprintf(
		'<div %1$s><p>Count: %2$d</p></div>',
		$wrapper_attributes,
		absint( $attributes['count'] )
	);
}
```

**Function signature:**
```php
function callback_name( $attributes, $content, $block ) { }
```

**Parameters:**
- `$attributes` (array) — Block attributes from block.json/JavaScript
- `$content` (string) — Saved HTML from InnerBlocks (empty if no inner blocks)
- `$block` (WP_Block) — Block instance with context, parsed_block

**Named vs anonymous callback (INFO, style preference only):** a closure works. A named function or method is easier to unit test and for other code to reference or replace. Never report a closure above INFO; judge its body by the escaping and side-effect rules instead.

```php
register_block_type( __DIR__ . '/build', array(
	'render_callback' => 'mypl_render_latest_posts',
) );

function mypl_render_latest_posts( $attributes, $content, $block ) {
	// ...
}
```

### Accessing Attributes

```php
function mypl_render_block( $attributes, $content, $block ) {
	// Attributes are associative array
	$count = isset( $attributes['count'] ) ? absint( $attributes['count'] ) : 5;
	$show_image = isset( $attributes['showImage'] ) ? (bool) $attributes['showImage'] : true;
	$title = isset( $attributes['title'] ) ? sanitize_text_field( $attributes['title'] ) : '';

	// Always validate and sanitize even though from JS
	// Attributes stored in database, could be manipulated
}
```

**Why validate:** Attributes come from database (post content). Could be:
- Modified via SQL
- Imported from untrusted source
- Changed by other plugins

**Type coercion:**

```php
// Number attributes
$count = absint( $attributes['count'] ); // Ensures positive integer
$columns = max( 1, min( 6, intval( $attributes['columns'] ) ) ); // Clamp 1-6

// Boolean attributes
$enabled = (bool) $attributes['enabled'];

// String attributes
$label = sanitize_text_field( $attributes['label'] );
```

### Using $content Parameter (InnerBlocks)

```php
function mypl_render_wrapper( $attributes, $content, $block ) {
	if ( empty( $content ) ) {
		return ''; // No inner blocks
	}

	$wrapper_attributes = get_block_wrapper_attributes( array(
		'class' => 'custom-wrapper',
	) );

	return sprintf(
		'<div %1$s>%2$s</div>',
		$wrapper_attributes,
		$content // Inner blocks HTML already escaped by WordPress
	);
}
```

**CRITICAL:** `$content` contains inner blocks HTML already rendered by core (each inner block escaped its own output, and post content passed kses on save for users without `unfiltered_html`). **Do NOT use wp_kses_post() on $content** (see "Escaping in Render Code" below).

### Using $block Parameter (WP_Block)

```php
function mypl_render_context_aware( $attributes, $content, $block ) {
	// Access block context
	$post_id = isset( $block->context['postId'] ) ? $block->context['postId'] : get_the_ID();

	// Access parsed block data
	$block_name = $block->name;
	$inner_blocks = $block->parsed_block['innerBlocks'];

	// Generate output based on context
	$post = get_post( $post_id );
	if ( ! $post ) {
		return '';
	}

	$wrapper_attributes = get_block_wrapper_attributes();
	return sprintf(
		'<div %1$s><h3>%2$s</h3></div>',
		$wrapper_attributes,
		esc_html( $post->post_title )
	);
}
```

## render PHP File Pattern

The `render` property in block.json specifies a PHP template file for block output.

### Basic render File Pattern

**block.json:**

```json
{
	"apiVersion": 3,
	"name": "my-plugin/dynamic-block",
	"title": "Dynamic Block",
	"render": "file:./render.php"
}
```

**render.php:**

```php
<?php
/**
 * Render template for my-plugin/dynamic-block
 *
 * @var array    $attributes     Block attributes.
 * @var string   $content        Block content (inner blocks).
 * @var WP_Block $block          Block instance.
 */

defined( 'ABSPATH' ) || exit;

$count = isset( $attributes['count'] ) ? absint( $attributes['count'] ) : 5;
$posts = get_posts( array(
	'numberposts' => $count,
	'post_status' => 'publish',
) );

$wrapper_attributes = get_block_wrapper_attributes();
?>
<div <?php echo $wrapper_attributes; ?>>
	<?php if ( $posts ) : ?>
		<ul>
			<?php foreach ( $posts as $post ) : ?>
				<li>
					<a href="<?php echo esc_url( get_permalink( $post ) ); ?>">
						<?php echo esc_html( $post->post_title ); ?>
					</a>
				</li>
			<?php endforeach; ?>
		</ul>
	<?php else : ?>
		<p><?php esc_html_e( 'No posts found.', 'my-plugin' ); ?></p>
	<?php endif; ?>
</div>
```

**Available variables in render.php:**
- `$attributes` — Block attributes (associative array)
- `$content` — Inner blocks HTML
- `$block` — WP_Block instance

**BAD: Separate require/include**

```php
// plugin.php
register_block_type( __DIR__ . '/build/my-block', array(
	'render_callback' => function() {
		require __DIR__ . '/templates/block.php';
	},
) );
// The closure echoes instead of returning a string (WARNING), and duplicates
// what the block.json render property does automatically
```

**GOOD: render property in block.json**

```json
{
	"render": "file:./render.php"
}
```

PHP registration:

```php
register_block_type( __DIR__ . '/build/my-block' );
// WordPress automatically loads render.php
```

### File Resolution

WordPress resolves render file relative to block.json location:

```
/wp-content/plugins/my-plugin/
├── my-plugin.php
└── build/
    └── my-block/
        ├── block.json           # "render": "file:./render.php"
        ├── render.php           # Resolved relative to block.json
        └── index.js
```

**BAD: Absolute path**

```json
{
	"render": "file:/var/www/html/wp-content/plugins/my-plugin/build/render.php"
}
// Breaks on different server paths
```

**GOOD: Relative path**

```json
{
	"render": "file:./render.php"
}
// Resolves relative to block.json
```

### Precedence: render File vs render_callback

If both are specified, **the `render_callback` passed in PHP wins**. `register_block_type_from_metadata()` first sets `$settings['render_callback']` to a closure that includes the render file, then runs `$settings = array_merge( $settings, $args )`, so a `render_callback` in `$args` overrides it:

```json
{
	"render": "file:./render.php"
}
```

```php
register_block_type( __DIR__ . '/build', array(
	'render_callback' => 'mypl_render', // This runs; render.php is never included
) );
```

**Both present: WARNING.** The render file is dead code, and edits to it have no effect. Keep one: the render file, or the callback.

## get_block_wrapper_attributes()

Generates wrapper attributes matching what `useBlockProps()` provides in JavaScript.

### Basic Usage

```php
$wrapper_attributes = get_block_wrapper_attributes();

echo '<div ' . $wrapper_attributes . '>Content</div>';
```

**What it generates:**
- `class` — Block classes (alignment, color classes, custom classes)
- `style` — Inline styles from block supports
- `id` — Anchor ID if set

**Example output:**

```html
<div class="wp-block-my-plugin-block has-text-align-center has-background" style="background-color:#f0f0f0">Content</div>
```

### Merging Custom Classes and Attributes

```php
$wrapper_attributes = get_block_wrapper_attributes( array(
	'class' => 'custom-class another-class',
	'data-count' => $count,
	'aria-label' => $attributes['label'], // escaped by get_block_wrapper_attributes()
) );
```

**BAD: Manual class concatenation**

```php
$classes = 'wp-block-my-plugin-block';
if ( $attributes['alignment'] ) {
	$classes .= ' has-text-align-' . $attributes['alignment'];
}
if ( $attributes['backgroundColor'] ) {
	$classes .= ' has-background';
}
// Missing many block support classes, fragile
```

**GOOD: get_block_wrapper_attributes()**

```php
$wrapper_attributes = get_block_wrapper_attributes( array(
	'class' => 'custom-class',
) );
// Automatically includes all block support classes
```

### Multiple Wrapper Attributes

```php
// Outer wrapper
$outer_wrapper = get_block_wrapper_attributes( array(
	'class' => 'outer-container',
) );

// Inner wrapper (manual, not block wrapper)
$inner_class = 'inner-content';

?>
<div <?php echo $outer_wrapper; ?>>
	<div class="<?php echo esc_attr( $inner_class ); ?>">
		<?php echo $content; ?>
	</div>
</div>
```

**Only call get_block_wrapper_attributes() ONCE per block** — for the outermost wrapper.

## WP_Block Object

The `WP_Block` instance provides access to block context, parsed block data, and block type information.

### WP_Block Properties

```php
function mypl_render( $attributes, $content, $block ) {
	// $block->name
	// Block name: "my-plugin/my-block"

	// $block->context
	// Array of context values from parent blocks

	// $block->parsed_block
	// Parsed block structure with innerBlocks, attributes

	// $block->block_type
	// WP_Block_Type instance with block configuration
}
```

### Accessing Block Context

```php
function mypl_render_post_aware( $attributes, $content, $block ) {
	// Context provided by parent blocks
	$post_id = isset( $block->context['postId'] ) ? $block->context['postId'] : get_the_ID();
	$post_type = isset( $block->context['postType'] ) ? $block->context['postType'] : 'post';

	if ( ! $post_id ) {
		return '';
	}

	$post = get_post( $post_id );
	// Use post data in rendering
}
```

**Cross-reference:** See block.json `providesContext` and `usesContext` configuration.

### Checking for Context Availability

```php
function mypl_render_conditional( $attributes, $content, $block ) {
	// Check if context exists before using
	if ( ! isset( $block->context['postId'] ) ) {
		return '<p>' . esc_html__( 'This block requires post context.', 'my-plugin' ) . '</p>';
	}

	$post_id = $block->context['postId'];
	// Render with post context
}
```

## Block Context in PHP

Block context allows parent blocks to pass data to child blocks.

### Receiving Context in render_callback

**Parent block.json:**

```json
{
	"name": "my-plugin/card",
	"providesContext": {
		"myPlugin/cardId": "cardId",
		"myPlugin/cardType": "cardType"
	},
	"attributes": {
		"cardId": { "type": "string" },
		"cardType": { "type": "string", "default": "default" }
	}
}
```

**Child block.json:**

```json
{
	"name": "my-plugin/card-title",
	"usesContext": [ "myPlugin/cardId", "myPlugin/cardType" ]
}
```

**Child render.php:**

```php
<?php
defined( 'ABSPATH' ) || exit;

$card_id = isset( $block->context['myPlugin/cardId'] ) ? $block->context['myPlugin/cardId'] : '';
$card_type = isset( $block->context['myPlugin/cardType'] ) ? $block->context['myPlugin/cardType'] : 'default';

if ( ! $card_id ) {
	return ''; // No card context
}

$wrapper_attributes = get_block_wrapper_attributes( array(
	'class' => 'card-title-' . sanitize_html_class( $card_type ),
) );
?>
<h3 <?php echo $wrapper_attributes; ?>>
	<?php echo esc_html( $attributes['title'] ); ?>
</h3>
```

**Context naming convention:** Use namespaced keys (`pluginName/contextKey`) to avoid collisions.

## InnerBlocks with Dynamic Blocks (CRITICAL)

### The #1 Dynamic Block Gotcha

**CRITICAL:** Dynamic blocks with InnerBlocks MUST have a save function that returns `<InnerBlocks.Content />`.

**Why:** InnerBlocks are saved to the database from the save function. The render_callback/render file receives this saved HTML via the `$content` parameter. The render function generates the WRAPPER — `$content` contains the inner blocks.

**BAD: Dynamic block with InnerBlocks returning null**

```javascript
// edit.js
function Edit() {
	return (
		<div { ...useBlockProps() }>
			<InnerBlocks />
		</div>
	);
}

// save.js
function save() {
	return null; // WRONG — InnerBlocks lost!
}
```

**Result:** Inner blocks disappear when post is saved. Users add inner blocks, save, reload — gone.

**GOOD: Dynamic block with InnerBlocks.Content in save**

```javascript
// edit.js
import { useBlockProps, InnerBlocks } from '@wordpress/block-editor';

function Edit() {
	return (
		<div { ...useBlockProps() }>
			<InnerBlocks />
		</div>
	);
}

// save.js
import { InnerBlocks } from '@wordpress/block-editor';

function save() {
	return <InnerBlocks.Content />; // Saves inner blocks to database
}
```

**render.php uses $content:**

```php
<?php
defined( 'ABSPATH' ) || exit;

$wrapper_attributes = get_block_wrapper_attributes( array(
	'class' => 'custom-wrapper',
) );
?>
<div <?php echo $wrapper_attributes; ?>>
	<div class="inner-content">
		<?php echo $content; // Inner blocks HTML from save function ?>
	</div>
</div>
```

### Why This Happens

**WordPress block lifecycle:**

1. **Edit function:** User adds InnerBlocks in editor
2. **Save function:** InnerBlocks.Content writes inner blocks HTML to database
3. **Frontend render:** render_callback/render.php receives saved HTML in `$content` parameter

**If save returns null:**
- Step 2 skipped — inner blocks NOT saved to database
- Step 3 receives empty `$content`
- Inner blocks lost

**Save function responsibility:**
- Static blocks: Generate ALL HTML (wrapper + content)
- Dynamic blocks: Generate inner blocks HTML only (wrapper added by render_callback)

### Complete Pattern

**edit.js:**

```javascript
import { useBlockProps, InnerBlocks } from '@wordpress/block-editor';

function Edit() {
	const blockProps = useBlockProps();

	return (
		<div { ...blockProps }>
			<InnerBlocks
				allowedBlocks={ [ 'core/paragraph', 'core/image' ] }
				template={ [
					[ 'core/paragraph', { placeholder: 'Add content...' } ],
				] }
			/>
		</div>
	);
}
```

**save.js:**

```javascript
import { InnerBlocks } from '@wordpress/block-editor';

function save() {
	// CRITICAL: Return InnerBlocks.Content to save inner blocks
	return <InnerBlocks.Content />;
}
```

**render.php:**

```php
<?php
/**
 * @var string $content — Contains saved inner blocks HTML
 */

defined( 'ABSPATH' ) || exit;

if ( empty( $content ) ) {
	return ''; // No inner blocks
}

$wrapper_attributes = get_block_wrapper_attributes();
?>
<div <?php echo $wrapper_attributes; ?>>
	<?php echo $content; // Output inner blocks ?>
</div>
```

## Escaping in Render Code

Full rules: `references/render-security.md` §2 (escaping matrix) and §3 (severity by who controls the value). Summary:

- **Escape late, by output context:** `esc_html()` for text, `esc_attr()` for attribute values, `esc_url()` for `href`/`src`, `wp_kses_post()` for RichText attribute strings, `wp_json_encode()` inside `<script>`. Raw attribute output: CRITICAL (CWE-79).
- **Kses does NOT make attribute context safe.** A tag-free `" onmouseover=... x="` passes kses unchanged, so any raw value inside a quoted HTML attribute is exploitable by a Contributor.
- **`get_block_wrapper_attributes()` escapes every value itself.** Pass raw values; pre-escaping with `esc_attr()` double-escapes (`&amp;amp;`).
- **Inner blocks `$content`: output as-is.** NEVER `wp_kses_post( $content )` or any `wp_kses( $content, ... )`: it strips embeds, iframes, and other inner-block markup. CRITICAL. Each inner block is responsible for escaping its own output.

## Hybrid Blocks

Blocks with static save AND server-side enhancement.

### When to Use Hybrid Blocks

**Use case:** Block has static base content BUT needs dynamic enhancement:
- Static HTML with dynamic view counters
- Static content with "latest update" timestamp
- Static blocks with dynamic badges/labels

**Pattern:**

```javascript
// save.js — Outputs base HTML
function save( { attributes } ) {
	const blockProps = useBlockProps.save();
	return (
		<div { ...blockProps }>
			<h2>{ attributes.heading }</h2>
			<p>{ attributes.content }</p>
			<div className="dynamic-placeholder"></div>
		</div>
	);
}
```

```php
// render_callback — Enhances static HTML
function mypl_render_hybrid( $attributes, $content, $block ) {
	if ( empty( $content ) ) {
		return '';
	}

	// Add dynamic counter
	$view_count = get_post_meta( get_the_ID(), 'view_count', true );
	$counter_html = sprintf(
		'<span class="view-counter">%s</span>',
		esc_html( sprintf( __( 'Views: %d', 'my-plugin' ), $view_count ) )
	);

	// Inject dynamic content into static HTML
	$content = str_replace( '<div class="dynamic-placeholder"></div>', $counter_html, $content );

	return $content;
}
```

**Caution:** String replacement is fragile. Appending after the saved markup is more robust.

**Better pattern:**

```php
function mypl_render_hybrid( $attributes, $content, $block ) {
	$view_count = absint( get_post_meta( get_the_ID(), 'view_count', true ) );

	return sprintf(
		'%1$s<div class="view-counter">%2$s</div>',
		$content, // Static HTML from save, already wrapped by useBlockProps.save()
		esc_html( sprintf( __( 'Views: %d', 'my-plugin' ), $view_count ) )
	);
}
```

In a hybrid block, `$content` already carries the wrapper from `useBlockProps.save()`. Wrapping it again with `get_block_wrapper_attributes()` duplicates block classes and styles (WARNING).

## Querying Data in Dynamic Blocks

Dynamic blocks commonly query WordPress data (posts, users, terms).

### WP_Query in render_callback

```php
function mypl_render_latest_posts( $attributes, $content, $block ) {
	$count = isset( $attributes['count'] ) ? absint( $attributes['count'] ) : 5;
	$category = isset( $attributes['category'] ) ? absint( $attributes['category'] ) : 0;

	$args = array(
		'posts_per_page' => $count,
		'post_status'    => 'publish',
		'no_found_rows'  => true, // Performance: skip pagination query
	);

	if ( $category ) {
		$args['cat'] = $category;
	}

	$query = new WP_Query( $args );

	if ( ! $query->have_posts() ) {
		return '<p>' . esc_html__( 'No posts found.', 'my-plugin' ) . '</p>';
	}

	ob_start();
	?>
	<div <?php echo get_block_wrapper_attributes(); ?>>
		<ul>
			<?php while ( $query->have_posts() ) : $query->the_post(); ?>
				<li>
					<a href="<?php echo esc_url( get_permalink() ); ?>">
						<?php echo esc_html( get_the_title() ); ?>
					</a>
				</li>
			<?php endwhile; ?>
		</ul>
	</div>
	<?php
	wp_reset_postdata();
	return ob_get_clean();
}
```

**Performance note:** `'no_found_rows' => true` skips SQL_CALC_FOUND_ROWS query (faster when not paginating).

### Caching Considerations

Dynamic blocks execute on every page load. For expensive queries, cache the output. Transient and object-cache reads and writes (`get_transient()`/`set_transient()`, `wp_cache_get()`/`wp_cache_set()`) are acceptable in render: they are exempt from the "render is read-only" rule. Option, meta, term, and post writes are not (WARNING, see `references/render-security.md` §4).

The key must identify the cached item (attributes, plus any context such as `postId` the output depends on) and must change when the data changes:

```php
function mypl_render_cached( $attributes, $content, $block ) {
	$version   = (int) get_option( 'mypl_cache_version', 1 );
	$cache_key = 'mypl_posts_' . md5( wp_json_encode( $attributes ) . '|' . $version );
	$cached = get_transient( $cache_key );

	if ( false !== $cached ) {
		return $cached;
	}

	// Expensive query
	$query = new WP_Query( array( /* ... */ ) );

	// Generate output
	ob_start();
	// ... output HTML ...
	$output = ob_get_clean();

	// Cache for 1 hour
	set_transient( $cache_key, $output, HOUR_IN_SECONDS );

	return $output;
}
```

**Invalidate on post save by bumping the version** (runs on `save_post`, not in render, so the option write is fine):

```php
add_action( 'save_post', 'mypl_bump_block_cache_version' );

function mypl_bump_block_cache_version() {
	update_option( 'mypl_cache_version', (int) get_option( 'mypl_cache_version', 1 ) + 1 );
}
```

`delete_transient( 'mypl_posts_*' )` does nothing: transients have no wildcard deletion. Use a versioned key as above, or delete explicit, known keys. With a persistent object cache, `wp_cache_get_last_changed( 'posts' )` in the key of a `wp_cache_get()`/`wp_cache_set()` pair works too. Without a persistent object cache that value changes on every request, so never put it in a transient key (every request writes a new transient).

### Avoiding N+1 Queries

**BAD: Querying in loop**

```php
$posts = get_posts( array( 'numberposts' => 10 ) );
foreach ( $posts as $post ) {
	$author = get_user_by( 'id', $post->post_author ); // N+1 query!
	echo esc_html( $author->display_name );
}
```

**GOOD: Batch query with cache_results**

```php
$posts = get_posts( array(
	'numberposts'    => 10,
	'cache_results'  => true, // Cache post and meta queries
) );

// Collect author IDs
$author_ids = array_unique( wp_list_pluck( $posts, 'post_author' ) );

// Batch query authors
$authors = get_users( array( 'include' => $author_ids ) );
$authors_by_id = array();
foreach ( $authors as $author ) {
	$authors_by_id[ $author->ID ] = $author;
}

// Use cached authors
foreach ( $posts as $post ) {
	$author = $authors_by_id[ $post->post_author ];
	echo esc_html( $author->display_name );
}
```

## Common Dynamic Block Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| **Dynamic block with InnerBlocks returning null in save** | Inner blocks disappear | Return `<InnerBlocks.Content />` in save |
| **Using wp_kses_post() on $content** | Breaks embed blocks | Output `$content` directly |
| **Unescaped attribute output** | Stored XSS (CRITICAL) | Escape late by context (`references/render-security.md` §2) |
| **Not using get_block_wrapper_attributes()** | Missing block classes/styles | Always use get_block_wrapper_attributes() |
| **Expensive query without caching** | Slow page loads | Cache results with transients |
| **N+1 queries in loop** | Database overload | Batch queries, use WordPress object cache |
| **Forgetting wp_reset_postdata()** | Breaks template tags after WP_Query | Call wp_reset_postdata() after custom query |
| **Not checking for empty $content** | Outputting empty wrappers | Check if $content empty before rendering |
| **Hardcoded strings** | Not translatable | Wrap all strings with __() or esc_html_e() |

## Cross-References

- **block.json render property configuration:** `references/block-json-guide.md`
- **JavaScript save function and InnerBlocks patterns:** `references/editor-patterns.md`
- **Save determinism, validation, deprecation entries:** `references/save-and-deprecations.md`
- **Interactivity API for frontend enhancement:** `references/interactivity-api-guide.md`
- **Escaping matrix, severity by source, render side effects, endpoints:** `references/render-security.md`
- **Comprehensive security or performance audits:** `/wp-security` or `/wp-performance`
