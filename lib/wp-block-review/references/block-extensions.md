# Block Extensions Reference

Patterns for features that extend a block beyond edit/save/render: registration, transforms, variations, block hooks, block context in the editor, block styles, block patterns, Block Bindings, and the `@wordpress/scripts` toolchain. Most of these are INFO-level opportunities in a review. Block hooks on a static block is the main exception (see below).

For block.json-side configuration of variations and hooks, see `block-json-guide.md` ("Block Variations in block.json", "Block Hooks in block.json"). For PHP-side context access, see `dynamic-blocks-guide.md` ("Block Context in PHP").

## Block Registration (PHP)

**❌ BAD: Not hooked to init**
```php
<?php
function my_plugin_register_block() {
	register_block_type( __DIR__ . '/build/my-block' );
}
my_plugin_register_block(); // Runs immediately, not on init
```

**✅ GOOD: ABSPATH guard, init hook, one call per block**
```php
<?php
defined( 'ABSPATH' ) || exit;

function my_plugin_register_blocks() {
	register_block_type( __DIR__ . '/build/block-one' );
	register_block_type( __DIR__ . '/build/block-two' );
	// render file comes from block.json "render": "file:./render.php"
}
add_action( 'init', 'my_plugin_register_blocks' );
```

Review checks:
- CRITICAL: a block with no registration path (e.g. one `register_block_type()` in a multi-block plugin). Unregistered blocks never appear.
- Accept loops over `glob()` of build directories, `wp_register_block_metadata_collection()` (6.7+), and `wp_register_block_types_from_metadata_collection()` (6.8+) with `build/blocks-manifest.php`.
- WARNING: registration outside `init`.
- Theme blocks: `init` or `after_setup_theme` both acceptable.

## Block Transforms

Severity: INFO when a block obviously maps to or from a core block (paragraph, heading, list) but has no transforms.

```javascript
import { createBlock } from '@wordpress/blocks';

export default {
	edit: Edit,
	save,
	transforms: {
		from: [
			{
				type: 'block',
				blocks: [ 'core/paragraph' ],
				transform: ( { content } ) => {
					return createBlock( 'my-plugin/my-block', {
						content,
					} );
				},
			},
		],
		to: [
			{
				type: 'block',
				blocks: [ 'core/paragraph' ],
				transform: ( { content } ) => {
					return createBlock( 'core/paragraph', {
						content,
					} );
				},
			},
		],
	},
};
```

Check that the transform maps attributes that exist on both sides. A transform that reads a missing attribute silently produces an empty block.

## Block Variations (JS)

Variations are presets of ONE block. Patterns are multi-block layouts. Do not confuse them.

```javascript
import { registerBlockVariation } from '@wordpress/blocks';

registerBlockVariation( 'core/columns', {
	name: 'three-columns-equal',
	title: 'Three Columns (Equal)',
	description: 'Three columns with equal width',
	icon: 'columns',
	isDefault: false,
	scope: [ 'block' ],
	attributes: {
		columns: 3,
	},
	innerBlocks: [
		[ 'core/column' ],
		[ 'core/column' ],
		[ 'core/column' ],
	],
} );
```

Review checks:
- `title` and `description` wrapped in `__()`.
- `isActive` defined when several variations share one block. Without it, the editor cannot tell which variation is selected.

## Block Hooks (WP 6.4+)

Block hooks auto-insert a block next to an anchor block in templates, template parts, and patterns (later releases extend this to navigation menus and post content). The hooked block is inserted as a bare comment delimiter with no saved markup.

Alternative to `blockHooks` in block.json: the PHP filters `hooked_block_types` (conditional insertion) and `hooked_block_{$hooked_block_type}` (set attributes or inner blocks on the inserted block).

**CRITICAL:** a hooked block with a static save function. The inserted delimiter has no HTML, so the frontend renders nothing and the editor reports a validation error. Hooked blocks must be dynamic.

**❌ BAD: Block hooks with static block**
```json
{
	"blockHooks": {
		"core/post-content": "after"
	}
}
```

```javascript
// save.js - Static save = block hooks won't work
function save() {
	return <div>Content</div>;
}
```

**✅ GOOD: Block hooks with dynamic block**
```json
{
	"blockHooks": {
		"core/post-content": "after"
	},
	"render": "file:./render.php"
}
```

```javascript
// save.js - Dynamic block (null save) = block hooks work
function save() {
	return null;
}
```

## Block Context (Editor Side)

Parent provides, child consumes. Namespace context keys as `namespace/key` to avoid collisions with core keys (`postId`, `postType`, `queryId`).

```json
// Parent block.json
{
	"providesContext": {
		"myPlugin/userId": "userId",
		"myPlugin/userName": "userName"
	},
	"attributes": {
		"userId": { "type": "number" },
		"userName": { "type": "string" }
	}
}
```

```json
// Child block.json
{
	"usesContext": [ "myPlugin/userId", "myPlugin/userName" ]
}
```

```javascript
// Child edit.js
export default function Edit( { context } ) {
	const userId = context['myPlugin/userId'];
	const userName = context['myPlugin/userName'];

	return (
		<div>
			<p>User: { userName } ({ userId })</p>
		</div>
	);
}
```

Review checks:
- Every `providesContext` value names an attribute that exists on the parent.
- Child reads a key that is listed in its `usesContext`. Unlisted keys arrive as `undefined`.
- Child handles a missing context value. The child block can be inserted outside the parent unless `parent` or `ancestor` is set in block.json.

## Block Styles

INFO: style variations can replace custom "style" attributes and toggles.

```json
{
	"styles": [
		{ "name": "default", "label": "Default", "isDefault": true },
		{ "name": "outline", "label": "Outline" }
	]
}
```

PHP alternative for blocks the plugin does not own:

```php
register_block_style(
	'core/quote',
	array(
		'name'  => 'fancy-quote',
		'label' => __( 'Fancy Quote', 'my-plugin' ),
	)
);
```

The editor adds the class `is-style-{name}` to the wrapper. CSS must target that class.

## Block Patterns

`register_block_pattern()` registers multi-block layouts. Since WP 6.0, themes can also place pattern files in `/patterns/`.

Review checks:
- `title` translated, `categories` set, `content` is valid serialized block markup.
- Pattern does not hardcode block names that the plugin may not register.

## Block Bindings API (WP 6.5+)

Connects block attributes to dynamic sources (post meta, custom sources) without a custom block. Surface-level detection only:

```html
<!-- wp:paragraph {"metadata":{"bindings":{"content":{"source":"core/post-meta","args":{"key":"my_meta_key"}}}}} -->
<p></p>
<!-- /wp:paragraph -->
```

INFO when a custom block exists only to display one meta value: a bound core block may be enough. The meta key must be registered with `show_in_rest => true`.

## @wordpress/scripts Toolchain

**❌ BAD: Missing build scripts**
```json
{
	"scripts": {
		"test": "echo \"No build toolchain configured\""
	}
}
```

**✅ GOOD: Complete @wordpress/scripts configuration**
```json
{
	"scripts": {
		"build": "wp-scripts build",
		"start": "wp-scripts start",
		"lint:js": "wp-scripts lint-js",
		"format": "wp-scripts format",
		"packages-update": "wp-scripts packages-update"
	},
	"devDependencies": {
		"@wordpress/scripts": "^36.1.0"
	}
}
```

Review checks:
- Interactivity API blocks: `build` and `start` need `--experimental-modules` (still required in @wordpress/scripts 36.1). Without it no `viewScriptModule` file is emitted and the block has no frontend behavior (CRITICAL; the scan reports the missing built file).
- Multi-block plugins: wp-scripts auto-detects every `src/**/block.json`. Custom `webpack.config.js` must keep that behavior or list every entry.
- Review `src/`, never `build/`. Flag only a missing or stale `build/`.
