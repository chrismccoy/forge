# WordPress Block Review

Review WordPress 6.x+ block editor (Gutenberg) code and report findings by file, line, and severity.

**Core model:** every block has two halves. The editor half is React (`edit`). The frontend half is either static HTML from `save` or server-rendered PHP (`render` file or `render_callback`). `block.json` is the single source of truth. Most serious bugs come from the halves disagreeing: saved markup that no longer matches `save`, nested blocks that `save` never persists, wrapper props missing on one side, or a server schema that differs from block.json.

**Coding standards** (WPCS PHP: spaces in parentheses, `array()`, Yoda; WP JS: tabs, camelCase, JSDoc) are ONE aggregated INFO finding, never per line. Skip JS formatting rules when the project ships its own lint config (Biome, Prettier, ESLint).

## Scope

**In scope:** single- and multi-block plugins, block libraries, theme blocks, block.json, edit/save, render files and callbacks, attributes, InnerBlocks, deprecations, Interactivity API, block context, build setup, the REST/AJAX endpoints a block calls, block validation errors.

**Out of scope (hand off):** building blocks (`/wp-build`), theme.json and block themes (`/wp-theme-review`, `/wp-block-theme`), full security audits (`/wp-security`), performance audits (`/wp-performance`), plugin architecture (`/wp-review`), WooCommerce block extensions, generic React apps. A plugin that registers no blocks (scan prints `SCOPE: no blocks registered`) gets only a block-editor integration review (filters, patterns, style variations).

## Review Workflow

### 1. Run the candidate scan

`<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/wp-block-review`, the folder that contains this procedure file; every relative `references/…` or `scripts/…` path below is inside it. Run the scanner as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rule matches:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/wp-block-review/scripts/scan-blocks.sh <plugin-dir>
```

The header reports the mode (BUILD, NO-BUILD, COMPILED-ONLY, SCOPE), apiVersion, legacy registration, inline edit/save files, and vendored third-party files. The body lists CRITICAL/WARNING/INFO candidates and build checks. Every hit is a CANDIDATE: open the file and confirm before reporting. The scan cannot judge intent or follow imports.

### 2. Classify the project

| Type | Signal | Do |
|------|--------|----|
| Modern build | `src/**/block.json`, wp-scripts, `build/` (or nested `public/build`) | Review `src/`; scan checks built output |
| Multi-block | many `block.json` | Registration path per block; see "Large plugins" |
| Compiled only | `Mode: COMPILED-ONLY`, no JS source | Mark edit/save/deprecations NOT VERIFIABLE; review PHP and built block.json |
| No-build | `Mode: NO-BUILD`, `wp.*` globals, hand-written `*.asset.php` | Load `references/legacy-js-blocks.md`. JSX/`import` in an unbuilt script or a `wp.*` global missing from dependencies: CRITICAL |
| Legacy JS (apiVersion 1) | `registerBlockType()` without `apiVersion`, `wp.editor` | Load `references/legacy-js-blocks.md`; skip `useBlockProps` rules; report the upgrade once (WARNING) |
| Legacy PHP | `register_block_type( 'ns/name', array( 'attributes' => ... ) )` | Load `references/render-security.md`; attribute checks apply to the PHP array |

Never review compiled output (`build/`, `dist/`, `*.build.js`) for code quality. Edit and save may live in `edit.*`/`save.*`, inline in the `registerBlockType` file, or in imported components: follow them.

**Large plugins (10+ blocks):** build a per-block matrix first (name, apiVersion, static/dynamic, has `deprecated`, parent/child, registration path). Deep-read a sample covering each row type: one simple static block, one dynamic block, one InnerBlocks parent with its child, every block with `deprecated`, every scan CRITICAL. List sampled vs scanned-only blocks in the summary.

### 3. Check each file type, filter, report

Apply the checklist below. Drop anything in "Not a Problem". Write the report in the output format.

## File Checklist

### block.json

- `apiVersion` 3 expected. Missing or 1: WARNING. 2: INFO (WP 6.9 logs a notice for < 3 under `SCRIPT_DEBUG`).
- `name` (`namespace/block-name`) or `title` missing/invalid: CRITICAL. `category`, `$schema`, `keywords`, `textdomain` missing: INFO.
- `attributes`: valid `type`; `type` matches `source` (WARNING); `source: "meta"` WARNING (use `useEntityProp`).
- `supports` missing: WARNING unless the block is intentionally minimal.
- `file:./` asset paths resolve against the BUILT block.json. A missing script or render file: CRITICAL; a missing stylesheet: WARNING. `style-index.css` exists only when an imported file is named `style.(s)css`.
- block.json is the only schema. JS `registerBlockType( name, { ...metadata, attributes } )` or PHP `'attributes' =>` that redeclare it: WARNING (server, REST, and render see a different schema; PHP `array` vs `object` silently resets values).
- `Requires at least` (plugin header AND `readme.txt`) covers the features used: apiVersion 3 needs 6.3, Interactivity API / `viewScriptModule` 6.5. Lower: WARNING.

Field-by-field detail: `references/block-json-guide.md`.

### edit

- apiVersion 2+: `useBlockProps()` called AND spread on the wrapper. Missing: CRITICAL.
- `@wordpress/*` imports, not `wp.*` globals, in build projects (WARNING: bypasses dependency extraction).
- Deprecated APIs: WARNING. `Button` `isSmall`/`isLarge`/`isPrimary`/`isSecondary`/`isTertiary`/`isLink`; `wp.editor` / `@wordpress/editor` block components; controls without `__next40pxDefaultSize` (6.7+).
- i18n: every string in `__()` with the plugin text domain; typos or domains differing from block.json `textdomain`; template literals in `__()` (not extractable): WARNING. Core sets editor-script translations automatically from block.json `textdomain`; `wp_set_script_translations()` given a block name is a no-op (INFO).
- Persistent data in attributes (never React state, never mutated in place: use `setAttributes`). `parent` must be an array (a string is ignored: WARNING).
- `RichText` needs `tagName`, `value`, `onChange` (WARNING). InnerBlocks `allowedBlocks`/`template`/`templateLock`, combinable `useSelect` calls, namespaced context keys (`ns/key`): INFO.

Detail: `references/editor-patterns.md`.

### save and deprecations

- Static apiVersion 2+: `useBlockProps.save()` spread on the wrapper. Missing: CRITICAL (the fix needs a deprecation entry).
- Inner blocks: save returns `<InnerBlocks.Content />`. `null` or omitted: CRITICAL (nested blocks lost).
- Deterministic: no time, randomness, locale (`__()` in markup, translated attribute defaults, `toLocale*`), timezone, `applyFilters`, store reads, or third-party component internals. Follow save into every component it imports. WARNING.
- Changed markup without a deprecation entry: CRITICAL; without git history, a risk note.
- Deprecation entries: newest first; `apiVersion` set when it differs (an apiVersion 1 save under a 2+ block without `apiVersion: 1` stops matching: CRITICAL when it lacks `useBlockProps.save()`); frozen copies, no live imports (WARNING, CRITICAL when the live code already broke it).
- Hiding or relabelling the core invalid-block warning: WARNING.

Full rules (validation mechanics, capability gates for stored HTML, detection): `references/save-and-deprecations.md`.

### render file / render_callback

- `get_block_wrapper_attributes()` on the wrapper (WARNING if missing; pass raw values, it escapes). ABSPATH guard in render files (WARNING).
- Escape late by context. Raw output: CRITICAL (CWE-79). Kses does NOT make attribute context safe: tag-free `"` breakout passes, so any raw value inside a quoted attribute is exploitable by a Contributor.
- NEVER `wp_kses_post( $content )` on inner blocks HTML (strips embeds): CRITICAL. Decoding `u003c`/entities back to markup after kses: CRITICAL.
- `render_callback` returns a string (echo: WARNING). `extract( $attributes )`: WARNING. `WP_Query` without `wp_reset_postdata()`: WARNING.
- Render is read-only: network calls, option/meta/term/post writes, `add_filter()`/`add_action()`, changing `global $post`, unguarded nested `render_block()`: WARNING. Transient or object-cache reads and writes for caching are exempt.
- Severity by who controls the value: Contributor attributes, remote data, public request data: CRITICAL; `manage_options` settings: WARNING.

Escaping matrix, node-tree renderers, side effects, PHP i18n: `references/render-security.md`. Render patterns: `references/dynamic-blocks-guide.md`.

### Registration, endpoints, build

- Every block registered on `init` through a PATH (`register_block_type()`, `register_block_type_from_metadata()`, a `glob()` loop, or `wp_register_block_types_from_metadata_collection()` 6.8+). A block with no working registration: CRITICAL (including a built block absent from `blocks-manifest.php`). A block name passed where a path is expected returns false.
- Hand-registered scripts take dependencies and version from the built `*.asset.php`. Missing dependencies: WARNING. `wp-editor`/`wp-edit-post` in an editor script: WARNING.
- Frontend assets gated by `has_block()` miss widgets, templates, and synced patterns: WARNING (use `viewScript`/`viewScriptModule`).
- Endpoints the block calls: `permission_callback` matches data scope (site options need `manage_options`), args schema or sanitize, public (`nopriv`) handlers never take client-built query args (CRITICAL).
- Build: `build/` matches `src/` (scan compares block.json content and `@wordpress/*` imports with `*.asset.php`). A gitignored, absent `build/` in a source checkout is not a finding.

### Interactivity API (WP 6.5+)

For any block with `viewScriptModule`, `@wordpress/interactivity`, or `data-wp-*` directives, load `references/interactivity-api-guide.md` and apply its Review Checklist. Interactivity code loaded via `viewScript` is CRITICAL; template output around directives follows the render escaping rules above.

### Extensions

Transforms, variations, styles, patterns, Block Bindings, `templateLock`: INFO opportunities. A hooked block (`blockHooks`) with a static save: CRITICAL. Detail: `references/block-extensions.md`.

## Severity

| Severity | Meaning |
|----------|---------|
| **CRITICAL** | Block fails to register or load, loses content, fails validation for existing posts, or is exploitable |
| **WARNING** | Works, but breaks compatibility, translation, styling, robustness, or maintainability |
| **INFO** | Improvement opportunity, style, or risk note |

Rate by effect, not by category: a rule listed as WARNING that demonstrably breaks validation or throws is CRITICAL.

## Not a Problem

| Pattern | Why it is fine |
|---------|----------------|
| Dynamic `save` returning `null` (no InnerBlocks) | PHP renders the frontend |
| Bare `<InnerBlocks.Content />` (or conditional `null`) in a dynamic save | Persists nested blocks only |
| Placeholder block: edit calls `replaceBlock()`, save returns `null` | Never persists its own markup |
| Legacy block name with `inserter: false` beside its replacement | Back-compat parser |
| `wp.editor.RichText` inside a deprecated save | Works; same markup (INFO at most) |
| Render FILE that echoes | Core buffers render files |
| No `viewScript`, no `style`, no `supports` on a minimal block | Intentional |
| apiVersion 2 | INFO only |
| New optional attribute without deprecation | Only markup changes need one |
| `wp.*` globals with hand-written `*.asset.php` in a no-build plugin | Valid setup |
| Line findings inside vendored third-party files | Review only how the plugin calls them |

## Output Format

Group findings by file path (PHP and JS intermixed). Within a file, order findings by severity, then line. One issue in many files is ONE multi-location finding (`## FILE: (8 blocks) a.js:12, b.js:40`), not one per file.

````markdown
## FILE: src/save.js

### Line 5: CRITICAL - Missing useBlockProps.save()
One sentence on impact.

❌ **BAD:**
```javascript
<offending code>
```

✅ **GOOD:**
```javascript
<fixed code>
```
````

End with:

```markdown
## SUMMARY
**Total issues: N** (CRITICAL: x, WARNING: y, INFO: z)
**Block validation risk:** HIGH | MEDIUM | LOW - one-line reason
**Not verifiable:** checks skipped for missing source or history
**Sampled:** (large plugins) blocks read in depth vs scanned only
```

Append when relevant: "Security issues detected. Run `/wp-security` for a full security audit." and "Plugin architecture issues detected. Run `/wp-review` for an architecture review." Full example: `references/report-example.md`.

## Version Requirements

| Feature | WordPress |
|---------|-----------|
| block.json registration | 5.8+ |
| apiVersion 3 (iframed editor) | 6.3+ |
| Block Hooks | 6.4+ |
| Interactivity API, `viewScriptModule`, Block Bindings | 6.5+ |
| `wp_register_block_metadata_collection()` | 6.7+ |
| `wp_register_block_types_from_metadata_collection()` | 6.8+ |

## Additional Resources

- **`scripts/scan-blocks.sh [path]`**: candidate scan. Detects project mode, inline edit/save, vendored files; checks built output against `src/`. Uses `rg`, falls back to `grep`.

| Topic | Reference |
|-------|-----------|
| block.json fields, attribute sources, supports, assets | `references/block-json-guide.md` |
| Editor components, InnerBlocks, data API, i18n, imports | `references/editor-patterns.md` |
| Save determinism, validation, deprecation entries, stored HTML | `references/save-and-deprecations.md` |
| Render patterns, wrapper attributes, WP_Block, queries | `references/dynamic-blocks-guide.md` |
| Escaping matrix, severity by source, side effects, endpoints, PHP registration, vendored libs | `references/render-security.md` |
| Interactivity API directives, state, store | `references/interactivity-api-guide.md` |
| Transforms, variations, hooks, context, styles, patterns, bindings, wp-scripts | `references/block-extensions.md` |
| No-build and apiVersion 1 blocks, `wp.editor`, dependency lists | `references/legacy-js-blocks.md` |
| Full example report | `references/report-example.md` |
