# Legacy and No-build JS Blocks

Checklists for blocks whose JS is not a modern `@wordpress/scripts` + block.json setup. Load when `scan-blocks.sh` reports `Mode: NO-BUILD` or `apiVersion: 1`, or when `registerBlockType()` carries attributes in JS.

## No-build blocks

Plain-JS blocks loaded without a bundler. `wp.*` globals are correct here, not a finding.
- Script is browser-parsable: no JSX, no `import`/`export`. Either is CRITICAL (syntax error, block never registers). Uses `wp.element.createElement` instead of JSX.
- Every `wp.<package>` global used appears as `wp-<package>` in the sibling `*.asset.php` `dependencies` (or in `wp_register_script()` deps). Missing is CRITICAL (global undefined at load). Unused entries are INFO.
- A block.json `file:./x.js` script without `x.asset.php` loads with NO dependencies. CRITICAL unless deps are registered another way.
- Globals aliased once at the top of an IIFE (`var useBlockProps = wp.blockEditor.useBlockProps;`) is fine.
- Cache-busting `version` in `*.asset.php` changes when the file changes (`filemtime()` or plugin version).
- i18n: block.json `textdomain` makes core call `wp_set_script_translations()` for the editor script. No extra PHP needed.

## Legacy JS blocks (apiVersion 1)

`registerBlockType()` without `apiVersion` and no block.json means apiVersion 1. Skip `useBlockProps` rules. Report the upgrade once as WARNING (it changes saved markup, so it needs deprecations).
- `wp.editor.*` block components and helpers (`RichText`, `InspectorControls`, `getColorClassName`, `withColors`, `MediaUpload`) are WARNING. Use `wp.blockEditor` / `@wordpress/block-editor`.
- `source: 'children'` / `'node'` attributes are WARNING (deprecated). Moving to `source: 'html'` (string) changes the attribute shape, so it needs a deprecation plus `migrate()`.
- JS `__()` / `_n()` without a text domain is WARNING. Strings land in the `default` domain and the plugin's JSON translations never apply.
- Editor script deps: every `wp.*` global used must be listed. Missing deps that load only through another package (often `wp-edit-post`) are WARNING. `wp-edit-post` as a dependency is WARNING (`_doing_it_wrong` in the widgets and site editors).
- Deprecated `save()` functions that call shared live helpers (class or style builders imported from other files) are WARNING. A later helper change silently changes the deprecation too, so old content stops matching. Deprecations must snapshot the markup logic they replaced.
- Frontend scripts enqueued with `has_block()` miss blocks in widgets, templates, template parts, and synced patterns (WARNING). Use `viewScript` in registration or a `render_block` filter.
- Prop typos in save (`styles=` for `style=`) change saved markup. Fixing them needs a deprecation.
