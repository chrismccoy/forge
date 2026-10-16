# Example Review Report

Complete example of the report format defined in SKILL.md. Findings are grouped by file (PHP and JS intermixed by path), each with line number, severity, one-line impact, and a BAD/GOOD pair. INFO findings may skip the BAD block when only an addition is needed.

````markdown
# WordPress Block Review: my-block-plugin

## FILE: src/index.js

### Line 3: WARNING - Legacy global access
window.wp.* access is legacy pattern. Use @wordpress/* package imports so wp-scripts generates correct dependencies in index.asset.php.

❌ **BAD:**
```javascript
const { registerBlockType } = window.wp.blocks;
```

✅ **GOOD:**
```javascript
import { registerBlockType } from '@wordpress/blocks';
```

## FILE: src/edit.js

### Line 12: CRITICAL - Missing useBlockProps
useBlockProps() not called in edit function. Block won't be selectable or receive supports styles in editor.

❌ **BAD:**
```javascript
export default function Edit() {
	return <div className="my-block">Content</div>;
}
```

✅ **GOOD:**
```javascript
import { useBlockProps } from '@wordpress/block-editor';

export default function Edit() {
	const blockProps = useBlockProps();
	return <div { ...blockProps }>Content</div>;
}
```

## FILE: src/save.js

### Line 5: CRITICAL - Missing useBlockProps.save()
apiVersion 2+ blocks require useBlockProps.save(). Wrapper classes and supports styles are lost. Adding it changes saved markup, so keep the old save in a deprecated entry.

❌ **BAD:**
```javascript
function save() {
	return <div className="my-block">Content</div>;
}
```

✅ **GOOD:**
```javascript
import { useBlockProps } from '@wordpress/block-editor';

const deprecated = [
	{
		// Old markup, so existing posts still validate
		save() {
			return <div className="my-block">Content</div>;
		},
	},
];

function save() {
	const blockProps = useBlockProps.save();
	return <div { ...blockProps }>Content</div>;
}
```

## FILE: src/render.php

### Line 15: CRITICAL - wp_kses_post on InnerBlocks content
wp_kses_post() on $content strips iframes and scripts that embed blocks produce. InnerBlocks content is already rendered by core.

❌ **BAD:**
```php
<?php echo wp_kses_post( $content ); ?>
```

✅ **GOOD:**
```php
<?php echo $content; // InnerBlocks HTML, already rendered by core ?>
```

### Line 1: WARNING - Missing ABSPATH check
Add ABSPATH check at top of file to prevent direct access.

❌ **BAD:**
```php
<?php
$wrapper_attributes = get_block_wrapper_attributes();
```

✅ **GOOD:**
```php
<?php
defined( 'ABSPATH' ) || exit;

$wrapper_attributes = get_block_wrapper_attributes();
```

## FILE: src/block.json

### Line 1: INFO - Missing $schema field
Add $schema field for IDE validation support.

✅ **GOOD:**
```json
{
	"$schema": "https://schemas.wp.org/trunk/block.json",
	"apiVersion": 3
}
```

### Line 2: INFO - apiVersion 2 (upgrade available)
apiVersion 2 works, but apiVersion 3 is required for the iframed editor (WP 6.3+). Check save output after the upgrade.

✅ **GOOD:**
```json
{
	"apiVersion": 3
}
```

## SUMMARY

**Total issues: 7** (CRITICAL: 3, WARNING: 2, INFO: 2)

**Block validation risk:** HIGH - Missing useBlockProps.save() changes saved markup.
**Not verifiable:** none (src/ and build/ present; no git history, so past markup changes are a risk note only)
**Sampled:** single-block plugin, all files read

Security issues detected. Run `/wp-security` for a full security audit.
````
