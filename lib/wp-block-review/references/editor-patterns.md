# WordPress Block Editor Patterns Reference

This reference catalogs React/JSX patterns for WordPress block editor development — the components, hooks, and data access patterns used to build block edit interfaces. Covers @wordpress/* packages, useBlockProps, RichText, controls, InnerBlocks, data API, deprecations, and build toolchain patterns.

## Quick Reference Table

### Core @wordpress Packages

| Package | Key Exports | When to Use |
|---------|-------------|-------------|
| `@wordpress/block-editor` | useBlockProps, RichText, InspectorControls, BlockControls, InnerBlocks, useInnerBlocksProps | Block UI components and editor interface |
| `@wordpress/blocks` | registerBlockType, createBlock, getBlockType | Block registration and manipulation |
| `@wordpress/components` | Button, TextControl, ToggleControl, PanelBody, SelectControl, RangeControl | UI primitives for settings and controls |
| `@wordpress/data` | useSelect, useDispatch, select, dispatch | State management and data access |
| `@wordpress/element` | createElement, Fragment, useState, useEffect | React abstraction layer |
| `@wordpress/i18n` | __, _x, _n, _nx, sprintf | Internationalization functions (no `_e`: echo variants are PHP only) |
| `@wordpress/compose` | compose, useInstanceId, useViewportMatch | Higher-order components and utility hooks |
| `@wordpress/hooks` | addFilter, addAction, doAction, applyFilters | JavaScript hooks system |
| `@wordpress/api-fetch` | apiFetch | WordPress REST API communication |
| `@wordpress/core-data` | useEntityProp, useEntityRecord | Post meta and entity data access |

### Common Hooks

| Hook | Purpose | Package |
|------|---------|---------|
| `useBlockProps()` | Get block wrapper attributes for edit function | @wordpress/block-editor |
| `useBlockProps.save()` | Get block wrapper attributes for save function | @wordpress/block-editor |
| `useInnerBlocksProps()` | Get props for InnerBlocks with custom wrapper | @wordpress/block-editor |
| `useSelect()` | Read from WordPress data stores | @wordpress/data |
| `useDispatch()` | Dispatch actions to WordPress data stores | @wordpress/data |
| `useEntityProp()` | Access post meta or entity properties | @wordpress/core-data |

## useBlockProps Deep Dive

The `useBlockProps()` hook is required for apiVersion 2+ blocks. It provides wrapper attributes including data-* attributes, class names, and styles.

### useBlockProps in Edit Function

```javascript
import { useBlockProps } from '@wordpress/block-editor';

function Edit( { attributes, setAttributes } ) {
	const blockProps = useBlockProps();

	return (
		<div { ...blockProps }>
			<p>{ attributes.content }</p>
		</div>
	);
}
```

**What useBlockProps() adds:**
- `data-block` — Block client ID
- `className` — Block classes (alignment, color, custom classes)
- `style` — Inline styles (colors, spacing, typography from supports)
- Other attributes based on block supports configuration

**BAD: Not using useBlockProps**

```javascript
function Edit( { attributes } ) {
	return (
		<div className="my-custom-block">
			<p>{ attributes.content }</p>
		</div>
	);
}
// Missing: Block wrapper attributes, supports styles, editor functionality
```

**GOOD: Using useBlockProps**

```javascript
function Edit( { attributes } ) {
	const blockProps = useBlockProps();
	return (
		<div { ...blockProps }>
			<p>{ attributes.content }</p>
		</div>
	);
}
// Includes: All wrapper attributes, supports applied, proper block wrapper
```

### Merging Custom Props with useBlockProps

```javascript
// BAD: Overwriting blockProps
const blockProps = useBlockProps();
return (
	<div className="my-class" style={ { color: 'red' } }>
		Content
	</div>
);
// Loses all blockProps attributes

// GOOD: Merging custom props
const blockProps = useBlockProps( {
	className: 'my-custom-class',
	style: { marginTop: '20px' },
	'data-custom': 'value',
} );
return <div { ...blockProps }>Content</div>;
// Merges custom props with useBlockProps output
```

**How merging works:**
- `className` — Concatenated with block classes
- `style` — Merged with block styles
- Other attributes — Added to wrapper

### useBlockProps.save() in Save Function

```javascript
import { useBlockProps } from '@wordpress/block-editor';

function save( { attributes } ) {
	const blockProps = useBlockProps.save();

	return (
		<div { ...blockProps }>
			<p>{ attributes.content }</p>
		</div>
	);
}
```

**Why useBlockProps.save():**
- Generates consistent wrapper attributes for frontend
- Matches editor wrapper structure
- Required for apiVersion 2+ blocks: only apiVersion 1 gets the wrapper props (`wp-block-*` class, supports classes and styles) added automatically. apiVersion 3 additionally renders the editor in an iframe; it does not change save.

**BAD: Missing useBlockProps.save() in apiVersion 2+**

```javascript
// block.json: "apiVersion": 2 or 3

function save( { attributes } ) {
	return (
		<div className="wp-block-my-plugin-block">
			<p>{ attributes.content }</p>
		</div>
	);
}
// CRITICAL: hardcoded class misses supports classes and styles; apiVersion 2+ requires useBlockProps.save()
// Adding it changes saved markup, so the fix needs a deprecation entry
```

**GOOD: Using useBlockProps.save()**

```javascript
function save( { attributes } ) {
	const blockProps = useBlockProps.save();
	return (
		<div { ...blockProps }>
			<p>{ attributes.content }</p>
		</div>
	);
}
// Correct wrapper attributes, passes validation
```

### useInnerBlocksProps and useBlockProps Integration

When using InnerBlocks with custom wrapper, call `useBlockProps()` FIRST, then pass result to `useInnerBlocksProps()`:

**BAD: Wrong hook order**

```javascript
const innerBlocksProps = useInnerBlocksProps();
const blockProps = useBlockProps( innerBlocksProps );
return <div { ...blockProps }><InnerBlocks /></div>;
// Wrong order — wrapper attributes not properly merged
```

**GOOD: Correct hook order**

```javascript
const blockProps = useBlockProps();
const innerBlocksProps = useInnerBlocksProps( blockProps );
return <div { ...innerBlocksProps } />;
// Correct order — useInnerBlocksProps receives and merges blockProps
```

**Complete pattern:**

```javascript
import { useBlockProps, useInnerBlocksProps } from '@wordpress/block-editor';
import { __ } from '@wordpress/i18n';

function Edit() {
	const blockProps = useBlockProps();
	const innerBlocksProps = useInnerBlocksProps( blockProps, {
		allowedBlocks: [ 'core/paragraph', 'core/image' ],
		template: [
			[ 'core/paragraph', { placeholder: __( 'Add content...', 'my-plugin' ) } ],
		],
	} );

	return <div { ...innerBlocksProps } />;
}
```

## RichText Component

The `RichText` component provides rich text editing with formatting controls.

### Basic RichText Pattern

```javascript
import { useBlockProps, RichText } from '@wordpress/block-editor';
import { __ } from '@wordpress/i18n';

function Edit( { attributes, setAttributes } ) {
	const blockProps = useBlockProps();

	return (
		<RichText
			{ ...blockProps }
			tagName="p"
			value={ attributes.content }
			onChange={ ( content ) => setAttributes( { content } ) }
			placeholder={ __( 'Enter text...', 'my-plugin' ) }
		/>
	);
}
```

**Key props:**
- `tagName` — HTML element (p, h1, h2, div, span)
- `value` — Attribute value (HTML string)
- `onChange` — Update callback
- `placeholder` — Placeholder text when empty

### RichText.Content in Save

```javascript
import { useBlockProps, RichText } from '@wordpress/block-editor';

function save( { attributes } ) {
	const blockProps = useBlockProps.save();

	return (
		<RichText.Content
			{ ...blockProps }
			tagName="p"
			value={ attributes.content }
		/>
	);
}
```

**CRITICAL:** Use `RichText.Content` in save, NOT `RichText`.

**BAD: Using RichText in save**

```javascript
function save( { attributes } ) {
	return <RichText tagName="p" value={ attributes.content } />;
}
// Error: RichText is editor component, not for save
```

**GOOD: Using RichText.Content in save**

```javascript
function save( { attributes } ) {
	return <RichText.Content tagName="p" value={ attributes.content } />;
}
// Correct: Static HTML output for frontend
```

### Allowed Formats

Restrict formatting options with `allowedFormats`:

```javascript
<RichText
	tagName="h2"
	value={ attributes.heading }
	onChange={ ( heading ) => setAttributes( { heading } ) }
	allowedFormats={ [ 'core/bold', 'core/italic' ] }
	placeholder={ __( 'Enter heading...', 'my-plugin' ) }
/>
```

**Available formats:**
- `core/bold`
- `core/italic`
- `core/link`
- `core/strikethrough`
- `core/underline`
- `core/text-color`
- `core/subscript`
- `core/superscript`

**Disable all formatting:**

```javascript
<RichText
	tagName="p"
	value={ attributes.plainText }
	onChange={ ( plainText ) => setAttributes( { plainText } ) }
	allowedFormats={ [] }
/>
```

### Multiline RichText (deprecated)

**WARNING:** the `multiline` prop is deprecated. Use `InnerBlocks` limited to `core/paragraph` (or the relevant child block), or a separate `RichText` per item stored in an array attribute. Removing `multiline` changes saved markup or attribute shape, so the fix needs a deprecation entry.

```javascript
// BAD: deprecated multiline prop
<RichText
	tagName="div"
	multiline="p"
	value={ attributes.content }
	onChange={ ( content ) => setAttributes( { content } ) }
/>

// GOOD: paragraphs as inner blocks
<div { ...useInnerBlocksProps( useBlockProps(), {
	allowedBlocks: [ 'core/paragraph' ],
	template: [ [ 'core/paragraph' ] ],
} ) } />
```

### BAD: contentEditable Instead of RichText

```javascript
// BAD: Manual contentEditable
<div
	contentEditable
	onInput={ ( e ) => setAttributes( { content: e.target.innerHTML } ) }
>
	{ attributes.content }
</div>
// Missing: Formatting toolbar, undo/redo, paste handling, block splitting
```

**GOOD: Use RichText**

```javascript
<RichText
	tagName="div"
	value={ attributes.content }
	onChange={ ( content ) => setAttributes( { content } ) }
/>
// Includes: All editor features, proper formatting, accessibility
```

## InspectorControls and BlockControls

### InspectorControls (Settings Sidebar)

```javascript
import { InspectorControls, useBlockProps } from '@wordpress/block-editor';
import { PanelBody, ToggleControl, TextControl } from '@wordpress/components';
import { __ } from '@wordpress/i18n';

function Edit( { attributes, setAttributes } ) {
	return (
		<>
			<InspectorControls>
				<PanelBody title={ __( 'Settings', 'my-plugin' ) }>
					<ToggleControl
						label={ __( 'Show featured image', 'my-plugin' ) }
						checked={ attributes.showImage }
						onChange={ ( showImage ) => setAttributes( { showImage } ) }
					/>
					<TextControl
						__next40pxDefaultSize
						label={ __( 'Custom CSS class', 'my-plugin' ) }
						value={ attributes.customClass }
						onChange={ ( customClass ) => setAttributes( { customClass } ) }
					/>
				</PanelBody>
			</InspectorControls>

			<div { ...useBlockProps() }>
				{/* Block content */}
			</div>
		</>
	);
}
```

**InspectorControls placement:** Outside block content wrapper, inside Fragment or parent element.

### InspectorControls group Prop (WP 6.2+)

```javascript
<InspectorControls group="settings">
	<TextControl
		__next40pxDefaultSize
		label={ __( 'Subtitle', 'my-plugin' ) }
		value={ attributes.subtitle }
		onChange={ ( subtitle ) => setAttributes( { subtitle } ) }
	/>
</InspectorControls>

<InspectorControls group="styles">
	<RangeControl
		__next40pxDefaultSize
		label={ __( 'Border radius', 'my-plugin' ) }
		value={ attributes.borderRadius }
		onChange={ ( borderRadius ) => setAttributes( { borderRadius } ) }
	/>
</InspectorControls>
```

**Groups:**
- `settings` — Settings tab (default)
- `styles` — Appearance/Styles tab

Auto-sorted into appropriate sidebar tabs.

### BlockControls (Block Toolbar)

```javascript
import { BlockControls, AlignmentControl, useBlockProps } from '@wordpress/block-editor';
import { ToolbarGroup, ToolbarButton } from '@wordpress/components';
import { __ } from '@wordpress/i18n';

function Edit( { attributes, setAttributes } ) {
	return (
		<>
			<BlockControls group="block">
				<AlignmentControl
					value={ attributes.textAlign }
					onChange={ ( textAlign ) => setAttributes( { textAlign } ) }
				/>

				<ToolbarGroup>
					<ToolbarButton
						icon="admin-links"
						label={ __( 'Toggle link', 'my-plugin' ) }
						isActive={ attributes.hasLink }
						onClick={ () => setAttributes( { hasLink: ! attributes.hasLink } ) }
					/>
				</ToolbarGroup>
			</BlockControls>

			<div { ...useBlockProps() }>
				{/* Block content */}
			</div>
		</>
	);
}
```

**Toolbar components:**
- `AlignmentControl` — Text alignment. `AlignmentToolbar` is deprecated: WARNING, replace with `AlignmentControl`. Store text alignment in its own attribute (`textAlign`), not `align` (reserved for block alignment support).
- `ToolbarGroup` — Group of toolbar buttons
- `ToolbarButton` — Single toolbar button

### Common Control Components

Examples assume `import { __ } from '@wordpress/i18n';`. Size-variant controls without `__next40pxDefaultSize` (6.7+) are WARNING.

**ToggleControl — Boolean switch**

```javascript
import { ToggleControl } from '@wordpress/components';

<ToggleControl
	label={ __( 'Enable feature', 'my-plugin' ) }
	checked={ attributes.enabled }
	onChange={ ( enabled ) => setAttributes( { enabled } ) }
	help={ __( 'Description text', 'my-plugin' ) }
/>
```

**TextControl — Text input**

```javascript
import { TextControl } from '@wordpress/components';

<TextControl
	__next40pxDefaultSize
	label={ __( 'Button text', 'my-plugin' ) }
	value={ attributes.buttonText }
	onChange={ ( buttonText ) => setAttributes( { buttonText } ) }
/>
```

**SelectControl — Dropdown**

```javascript
import { SelectControl } from '@wordpress/components';

<SelectControl
	__next40pxDefaultSize
	label={ __( 'Layout', 'my-plugin' ) }
	value={ attributes.layout }
	options={ [
		{ label: __( 'Grid', 'my-plugin' ), value: 'grid' },
		{ label: __( 'List', 'my-plugin' ), value: 'list' },
		{ label: __( 'Masonry', 'my-plugin' ), value: 'masonry' },
	] }
	onChange={ ( layout ) => setAttributes( { layout } ) }
/>
```

**RangeControl — Number slider**

```javascript
import { RangeControl } from '@wordpress/components';

<RangeControl
	__next40pxDefaultSize
	label={ __( 'Columns', 'my-plugin' ) }
	value={ attributes.columns }
	onChange={ ( columns ) => setAttributes( { columns } ) }
	min={ 1 }
	max={ 6 }
	step={ 1 }
/>
```

**ColorPalette — Color picker**

```javascript
import { ColorPalette } from '@wordpress/block-editor';

<ColorPalette
	value={ attributes.backgroundColor }
	onChange={ ( backgroundColor ) => setAttributes( { backgroundColor } ) }
/>
```

**MediaUpload — Media library**

```javascript
import { MediaUpload, MediaUploadCheck } from '@wordpress/block-editor';
import { Button } from '@wordpress/components';

<MediaUploadCheck>
	<MediaUpload
		onSelect={ ( media ) => setAttributes( { imageId: media.id, imageUrl: media.url } ) }
		allowedTypes={ [ 'image' ] }
		value={ attributes.imageId }
		render={ ( { open } ) => (
			<Button __next40pxDefaultSize variant="secondary" onClick={ open }>
				{ attributes.imageUrl
					? __( 'Replace image', 'my-plugin' )
					: __( 'Select image', 'my-plugin' ) }
			</Button>
		) }
	/>
</MediaUploadCheck>
```

## InnerBlocks Patterns

### Basic InnerBlocks

```javascript
import { useBlockProps, InnerBlocks } from '@wordpress/block-editor';

function Edit() {
	const blockProps = useBlockProps();

	return (
		<div { ...blockProps }>
			<InnerBlocks />
		</div>
	);
}

function save() {
	const blockProps = useBlockProps.save();

	return (
		<div { ...blockProps }>
			<InnerBlocks.Content />
		</div>
	);
}
```

**CRITICAL:** Save function MUST include `<InnerBlocks.Content />`.

### Allowed Blocks

```javascript
<InnerBlocks
	allowedBlocks={ [ 'core/paragraph', 'core/heading', 'core/image' ] }
/>
```

Restricts which blocks can be inserted.

### Template (Pre-Defined Blocks)

```javascript
<InnerBlocks
	template={ [
		[ 'core/heading', { placeholder: __( 'Card title', 'my-plugin' ) } ],
		[ 'core/paragraph', { placeholder: __( 'Card description...', 'my-plugin' ) } ],
		[ 'core/button', { text: __( 'Learn more', 'my-plugin' ) } ],
	] }
/>
```

Pre-populates inner blocks on insertion.

**Template array structure:**
```javascript
[ 'blockName', { attributes }, [ innerBlocks ] ]
```

### Template Lock

```javascript
<InnerBlocks
	template={ [
		[ 'core/heading' ],
		[ 'core/paragraph' ],
	] }
	templateLock="all"
/>
```

**Lock options:**
- `false` — No lock (default), can add/remove/reorder
- `"all"` — Can't add, remove, or reorder blocks
- `"insert"` — Can't add new blocks, can remove/reorder existing
- `"contentOnly"` — Can only edit content, not structure

**Use case for "all":** Fixed layout blocks where structure shouldn't change.

### Orientation

```javascript
<InnerBlocks
	orientation="horizontal"
/>
```

**Values:**
- `"vertical"` — Default, vertical stacking
- `"horizontal"` — Horizontal layout

### InnerBlocks with Dynamic Blocks (CRITICAL)

**BAD: Dynamic block with null save**

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

**InnerBlocks won't be saved to database — they'll disappear.**

**GOOD: Dynamic block with InnerBlocks.Content in save**

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
import { InnerBlocks } from '@wordpress/block-editor';

function save() {
	return <InnerBlocks.Content />;
}
// InnerBlocks saved to database
```

**render.php receives InnerBlocks content:**

```php
<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>
<div <?php echo get_block_wrapper_attributes(); ?>>
	<div class="custom-wrapper">
		<?php echo $content; // Inner blocks HTML, already filtered: never wp_kses_post() it ?>
	</div>
</div>
```

`$content` parameter contains the saved inner blocks HTML.

## Attributes and State Management

### Receiving and Updating Attributes

```javascript
function Edit( { attributes, setAttributes } ) {
	// Read attribute
	const heading = attributes.heading;

	// Update attribute
	setAttributes( { heading: 'New heading' } );

	// Update multiple attributes
	setAttributes( {
		heading: 'New heading',
		subheading: 'New subheading',
	} );
}
```

**Controlled component pattern:**

```javascript
import { TextControl } from '@wordpress/components';

function Edit( { attributes, setAttributes } ) {
	return (
		<TextControl
			__next40pxDefaultSize
			label={ __( 'Heading', 'my-plugin' ) }
			value={ attributes.heading }
			onChange={ ( heading ) => setAttributes( { heading } ) }
		/>
	);
}
```

### Attribute Defaults

Defined in block.json:

```json
{
	"attributes": {
		"columns": {
			"type": "number",
			"default": 3
		},
		"showImage": {
			"type": "boolean",
			"default": true
		}
	}
}
```

Accessed in edit:

```javascript
function Edit( { attributes } ) {
	const columns = attributes.columns; // 3 if not set
	const showImage = attributes.showImage; // true if not set
}
```

### Using Attributes in Save

```javascript
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

**Attributes available in save are the final values stored in the database.**

### React State vs Block Attributes

**BAD: Using React state for block data**

```javascript
import { useState } from '@wordpress/element';

function Edit() {
	const [ heading, setHeading ] = useState( 'Hello' );

	return (
		<div { ...useBlockProps() }>
			<input value={ heading } onChange={ ( e ) => setHeading( e.target.value ) } />
		</div>
	);
}
// React state is lost when block unmounts or page reloads
```

**GOOD: Using block attributes**

```javascript
function Edit( { attributes, setAttributes } ) {
	return (
		<div { ...useBlockProps() }>
			<input
				value={ attributes.heading }
				onChange={ ( e ) => setAttributes( { heading: e.target.value } ) }
			/>
		</div>
	);
}
// Attributes persisted to database
```

**When to use React state:**
- Temporary UI state (modal open/closed, active tab)
- Derived values calculated from attributes
- NOT for data that needs to persist

## useSelect and useDispatch (Data API)

### useSelect for Reading Data

```javascript
import { useSelect } from '@wordpress/data';

function Edit() {
	const postTitle = useSelect( ( select ) => {
		return select( 'core/editor' ).getEditedPostAttribute( 'title' );
	}, [] );

	return <div>Post title: { postTitle }</div>;
}
```

**Common data stores:**
- `'core'` — WordPress core data (posts, users, taxonomies)
- `'core/editor'` — Current post being edited
- `'core/block-editor'` — Block editor state
- `'core/edit-post'` — Edit post UI state

**useSelect dependency array:**

```javascript
const postTitle = useSelect( ( select ) => {
	return select( 'core/editor' ).getEditedPostAttribute( 'title' );
}, [] ); // Empty array — subscribe once
```

**Always include dependency array** to prevent unnecessary re-subscriptions.

### Multiple useSelect Calls (INFO)

**BAD: Multiple useSelect calls**

```javascript
function Edit() {
	const postTitle = useSelect( ( select ) => {
		return select( 'core/editor' ).getEditedPostAttribute( 'title' );
	}, [] );

	const postMeta = useSelect( ( select ) => {
		return select( 'core/editor' ).getEditedPostAttribute( 'meta' );
	}, [] );

	const postType = useSelect( ( select ) => {
		return select( 'core/editor' ).getCurrentPostType();
	}, [] );

	// 3 separate store subscriptions — performance issue with many blocks
}
```

**GOOD: Single useSelect call**

```javascript
function Edit() {
	const { postTitle, postMeta, postType } = useSelect( ( select ) => {
		const { getEditedPostAttribute, getCurrentPostType } = select( 'core/editor' );
		return {
			postTitle: getEditedPostAttribute( 'title' ),
			postMeta: getEditedPostAttribute( 'meta' ),
			postType: getCurrentPostType(),
		};
	}, [] );

	// Single store subscription — better performance
}
```

### useDispatch for Actions

```javascript
import { useDispatch } from '@wordpress/data';

function Edit() {
	const { editPost } = useDispatch( 'core/editor' );

	const updatePostMeta = () => {
		editPost( {
			meta: {
				my_custom_field: 'value',
			},
		} );
	};

	return <button onClick={ updatePostMeta }>Update Meta</button>;
}
```

**Common dispatch actions:**
- `editPost( changes )` — Update current post
- `savePost()` — Save current post
- `insertBlock( block )` — Insert block
- `removeBlock( clientId )` — Remove block

### Common Selectors

**Get current post attributes:**

```javascript
const { postTitle, postDate, postStatus } = useSelect( ( select ) => {
	const { getEditedPostAttribute } = select( 'core/editor' );
	return {
		postTitle: getEditedPostAttribute( 'title' ),
		postDate: getEditedPostAttribute( 'date' ),
		postStatus: getEditedPostAttribute( 'status' ),
	};
}, [] );
```

**Get blocks in editor:**

```javascript
const blocks = useSelect( ( select ) => {
	return select( 'core/block-editor' ).getBlocks();
}, [] );
```

**Get block attributes:**

```javascript
const blockAttributes = useSelect( ( select ) => {
	return select( 'core/block-editor' ).getBlockAttributes( clientId );
}, [ clientId ] );
```

## useEntityProp Hook

Replacement for deprecated `source: 'meta'` attribute pattern.

### Accessing Post Meta

```javascript
import { useEntityProp } from '@wordpress/core-data';

function Edit() {
	const [ meta, setMeta ] = useEntityProp( 'postType', 'post', 'meta' );

	const customField = meta.my_custom_field;

	const updateMeta = ( value ) => {
		setMeta( { ...meta, my_custom_field: value } );
	};

	return (
		<input
			value={ customField }
			onChange={ ( e ) => updateMeta( e.target.value ) }
		/>
	);
}
```

**useEntityProp parameters:**
1. Entity kind: `'postType'`
2. Entity name: `'post'`, `'page'`, custom post type slug
3. Property: `'meta'`, `'title'`, `'content'`, etc.

**BAD: Using deprecated source: 'meta'**

```json
{
	"attributes": {
		"metaValue": {
			"type": "string",
			"source": "meta",
			"meta": "my_meta_key"
		}
	}
}
```

Deprecated pattern, no longer recommended.

**GOOD: Using useEntityProp**

```javascript
const [ meta, setMeta ] = useEntityProp( 'postType', 'post', 'meta' );
const metaValue = meta.my_meta_key;
```

## Block Deprecations

Full rules, examples, and detection: `references/save-and-deprecations.md`. Core rules:

- **Newest first** in the `deprecated` array (oldest-first: WARNING).
- **`apiVersion`** on every entry whose markup came from a different apiVersion. An apiVersion 1 save under a 2+ block without `apiVersion: 1` stops matching old content: CRITICAL when the entry's save lacks `useBlockProps.save()`, otherwise WARNING.
- **Frozen copies:** each entry's `save` and `attributes` are snapshots, no live imports of components or helpers (WARNING; CRITICAL when the live code already changed).
- **`migrate()`** whenever the attribute schema changed (renamed, reshaped, or moved source).

## Import Patterns and Build

### @wordpress/* Package Imports

**GOOD: ES6 imports from @wordpress packages**

```javascript
import { registerBlockType } from '@wordpress/blocks';
import { useBlockProps, RichText } from '@wordpress/block-editor';
import { __ } from '@wordpress/i18n';
import metadata from './block.json';
```

**BAD (build projects): window.wp.* global access**

```javascript
const { registerBlockType } = window.wp.blocks;
const { useBlockProps, RichText } = window.wp.blockEditor;
```

Works at runtime, but bypasses dependency extraction: the packages never reach `index.asset.php`, so the script can load before them. WARNING in projects built with `@wordpress/scripts`. Valid in no-build plugins whose hand-written `*.asset.php` lists every `wp-*` dependency (see `references/legacy-js-blocks.md`).

### Import block.json Metadata

```javascript
import metadata from './block.json';

registerBlockType( metadata.name, {
	edit: Edit,
	save,
} );
```

Imports block.json as JavaScript object.

### @wordpress/scripts Build Process

**package.json scripts:**

```json
{
	"scripts": {
		"build": "wp-scripts build",
		"start": "wp-scripts start",
		"lint:js": "wp-scripts lint-js",
		"lint:css": "wp-scripts lint-style",
		"format": "wp-scripts format"
	},
	"devDependencies": {
		"@wordpress/scripts": "^36.1.0"
	}
}
```

Use the latest `@wordpress/scripts` release; an old major pins outdated Babel, webpack, and lint rules.

**How @wordpress/scripts works:**
1. Reads `src/index.js` as entry point
2. Compiles JSX to JavaScript
3. Compiles SCSS to CSS
4. Generates `build/index.js` and `build/index.asset.php`
5. Externalizes @wordpress/* packages (not bundled)

**index.asset.php auto-generated:**

```php
<?php
return array(
	'dependencies' => array(
		'wp-block-editor',
		'wp-blocks',
		'wp-element',
		'wp-i18n',
	),
	'version' => 'abc123def456',
);
```

WordPress reads this file to determine dependencies and version.

**Custom webpack config**

A `webpack.config.js` that extends the default config from `@wordpress/scripts` is valid:

```javascript
const defaultConfig = require( '@wordpress/scripts/config/webpack.config' );

module.exports = {
	...defaultConfig,
	entry: {
		...defaultConfig.entry(),
		'admin': './src/admin/index.js',
	},
};
```

Flag (WARNING) only a config that drops `DependencyExtractionWebpackPlugin` (no `*.asset.php`, `@wordpress/*` bundled instead of externalized) or the block.json copying (`CopyWebpackPlugin` / `--webpack-copy-php` behavior), so built block.json, render files, or asset files go missing.

## i18n in Block Editor

### Translating Block Strings

```javascript
import { __ } from '@wordpress/i18n';

registerBlockType( 'my-plugin/block', {
	title: __( 'My Block', 'my-plugin' ),
	description: __( 'A custom block', 'my-plugin' ),
	keywords: [
		__( 'custom', 'my-plugin' ),
		__( 'example', 'my-plugin' ),
	],
} );
```

**Text domain:** must match block.json `textdomain` (normally the plugin slug). A typo or different domain: WARNING.

### Translation Functions

```javascript
import { __, _n, sprintf } from '@wordpress/i18n';

// __() — Translate and return
const title = __( 'Settings', 'my-plugin' );

// sprintf() — Parameterized strings
const message = sprintf(
	/* translators: %s: search term. */
	__( 'Results for "%s"', 'my-plugin' ),
	searchTerm
);

// _n() — Pluralization (returns the format string; sprintf fills %d)
const itemsLabel = sprintf(
	/* translators: %d: number of items. */
	_n( '%d item', '%d items', count, 'my-plugin' ),
	count
);
```

### block.json Title and Description Auto-Translated

```json
{
	"title": "My Block",
	"description": "A custom block",
	"textdomain": "my-plugin"
}
```

WordPress automatically translates `title` and `description` using text domain.

**BAD: Hardcoded strings**

```javascript
<PanelBody title="Settings">
	<p>Configure your block settings below.</p>
</PanelBody>
```

Not translatable.

**GOOD: Wrapped strings**

```javascript
import { __ } from '@wordpress/i18n';

<PanelBody title={ __( 'Settings', 'my-plugin' ) }>
	<p>{ __( 'Configure your block settings below.', 'my-plugin' ) }</p>
</PanelBody>
```

## Anti-Patterns

### Using React State Instead of Block Attributes

**BAD:**

```javascript
import { useState } from '@wordpress/element';

function Edit() {
	const [ heading, setHeading ] = useState( '' );
	return <input value={ heading } onChange={ ( e ) => setHeading( e.target.value ) } />;
}
// Lost on save, block unmount, page reload
```

**GOOD:**

```javascript
function Edit( { attributes, setAttributes } ) {
	return (
		<input
			value={ attributes.heading }
			onChange={ ( e ) => setAttributes( { heading: e.target.value } ) }
		/>
	);
}
```

### Not Spreading blockProps

**BAD:**

```javascript
function Edit() {
	const blockProps = useBlockProps();
	return <div className="my-block">Content</div>;
}
// Loses all wrapper attributes
```

**GOOD:**

```javascript
function Edit() {
	const blockProps = useBlockProps();
	return <div { ...blockProps }>Content</div>;
}
```

### Inline Styles Instead of Block Supports

**BAD:**

```javascript
function Edit( { attributes } ) {
	return (
		<div style={ { backgroundColor: attributes.bgColor } }>
			Content
		</div>
	);
}
// Manual color handling, doesn't integrate with theme
```

**GOOD:**

```json
{
	"supports": {
		"color": {
			"background": true
		}
	}
}
```

```javascript
function Edit() {
	const blockProps = useBlockProps();
	return <div { ...blockProps }>Content</div>;
}
// Color support via useBlockProps, integrates with theme
```

### Fetching Data in Save Function

**BAD:**

```javascript
function save() {
	const posts = apiFetch( { path: '/wp/v2/posts' } ); // returns a Promise, never data
	return <div>{ posts.length } posts</div>;
}
// Save must be synchronous and deterministic: no fetches, no store reads (WARNING)
```

**GOOD: Use dynamic rendering**

```javascript
function save() {
	return null;
}
```

```php
<?php
// render.php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$posts = get_posts( array( 'numberposts' => 10 ) );
$count = count( $posts );
?>
<div <?php echo get_block_wrapper_attributes(); ?>>
	<?php
	echo esc_html(
		sprintf(
			/* translators: %d: number of posts. */
			_n( '%d post', '%d posts', $count, 'my-plugin' ),
			$count
		)
	);
	?>
</div>
```

### Using className Prop Directly

**BAD:**

```javascript
function Edit( { className } ) {
	return <div className={ className }>Content</div>;
}
// Loses other wrapper attributes
```

**GOOD:**

```javascript
function Edit() {
	const blockProps = useBlockProps();
	return <div { ...blockProps }>Content</div>;
}
// Includes className plus all other wrapper attributes
```

## Cross-References

- **block.json schema and configuration:** `references/block-json-guide.md`
- **Save determinism, validation, deprecations:** `references/save-and-deprecations.md`
- **Dynamic blocks with render_callback/render.php:** `references/dynamic-blocks-guide.md`
- **Escaping and render security:** `references/render-security.md`
- **No-build and apiVersion 1 blocks:** `references/legacy-js-blocks.md`
- **Interactivity API for frontend JavaScript:** `references/interactivity-api-guide.md`
- **Full security audit (capabilities, nonces):** `/wp-security`
