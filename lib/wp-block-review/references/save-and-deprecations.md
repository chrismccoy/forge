# Save and Deprecations

Detailed rules for static `save()` output and the `deprecated` array. Load this reference for any static block, any block with a `deprecated` array, or when the report concerns block validation errors ("This block contains unexpected or invalid content").

## Contents

1. How validation works
2. Deterministic save
3. Wrapper props and InnerBlocks
4. Deprecation entries
5. Detecting missing deprecations
6. Pre-rendered HTML and capability gates
7. Validation hiding

## 1. How Validation Works

On load, the editor re-runs `save( attributes )` for every static block and compares the output with the HTML stored in post content. Any difference marks the block invalid. The editor then tries each `deprecated` entry in order. The first entry whose `save` matches wins, and its `migrate()` (if any) upgrades the attributes.

Consequences:
- Anything that makes `save` output differ between two users, two page loads, or two plugin versions breaks validation.
- Attribute defaults are NOT serialized into the block comment. `save` recomputes them every time, so a default that varies (translated, computed, filtered) varies the saved markup.

## 2. Deterministic Save

`save` must return identical markup for identical attributes. Follow `save` into every component and helper it imports: a non-deterministic child breaks the parent. Each of these is WARNING (validation error when another user opens the post), unless noted:

| Source of variation | Examples | Fix |
|---------------------|----------|-----|
| Time and randomness | `Math.random()`, `Date.now()`, `new Date()` formatting, `uniqid` | Store the value in an attribute when editing |
| Locale | `__()` text rendered into markup, `default: __( 'Copy' )`, `navigator.language`, `toLocaleString()`, `Intl.*` | Save locale-neutral markup or raw values; translate in the editor UI or in a view script |
| Timezone | Local date formatting | Save ISO strings (`dateTime` attribute); format on the frontend |
| Runtime filters | `applyFilters()` shaping classes, styles, or attributes | Resolve the filter at edit time and store the result in attributes |
| Third-party components | Library components rendered in save (`react-tweet`, icon sets, `@wordpress/icons` SVGs) | Store the rendered SVG/markup in an attribute, pin the library, or make the block dynamic |
| Data fetching / store reads | `useSelect`, `apiFetch`, `select()` in save | Never in save. Store what is needed in attributes |

## 3. Wrapper Props and InnerBlocks

- apiVersion 2+ static save: `useBlockProps.save()` spread on the outermost element. Missing is CRITICAL. Adding it changes saved markup, so the fix MUST include a `deprecated` entry with the old save.
- Blocks with inner blocks: `save` returns `<InnerBlocks.Content />` (inside the wrapper for static blocks, bare for dynamic blocks). Returning `null` or omitting it loses nested blocks. CRITICAL.
- `useInnerBlocksProps.save( useBlockProps.save() )` is the apiVersion 3 pattern for wrapper plus children.
- Props passed to `<InnerBlocks.Content {...useBlockProps.save()} />` are ignored. Harmless, misleading (INFO).

## 4. Deprecation Entries

```javascript
const v2 = {
	apiVersion: 2, // the apiVersion that produced the OLD markup
	attributes: { /* frozen copy of the old schema */ },
	supports: { /* old supports, if they affected markup */ },
	save( { attributes } ) {
		/* frozen copy of the old save, no live imports */
	},
	migrate( attributes ) {
		return { ...attributes, newField: 'default' };
	},
};

export default [ v3, v2, v1 ]; // newest first
```

Checks:
- **Order:** newest first. Oldest-first is WARNING (slower; and an older entry may match first and run the wrong `migrate`).
- **apiVersion:** entries inherit the block's apiVersion. An apiVersion 1 save relies on the auto-added `wp-block-*` class; under an apiVersion 2+ block without `apiVersion: 1` it stops matching old content. CRITICAL when the entry's save has no `useBlockProps.save()`, otherwise WARNING.
- **Frozen snapshots:** a deprecated save must not import live components, helpers, or icon libraries from outside the deprecation file. WARNING. CRITICAL when the live code already changed: render the deprecated save mentally with only the props it passes. A child component that now destructures a prop the old save does not pass throws during parsing, and every old block fails.
- **Attributes:** each entry carries the attribute schema that matches its markup. Sharing the current `attributes` object by reference is WARNING.
- **`wp.editor.RichText` inside a deprecation:** works through the deprecated proxy and gives identical markup. INFO only.
- **Dual registration:** a legacy block name kept with `inserter: false` beside its replacement is a back-compat parser. Review each registration's `deprecated` array against its own apiVersion.
- **Typos in saved props** (`styles=` for `style=`, `area-expanded` for `aria-expanded`): fixing them changes markup, so the fix needs a deprecation entry.

## 5. Detecting Missing Deprecations

A save change without a matching entry is CRITICAL (existing content fails validation). Evidence:
- `git log -p` on save files and on every component save imports.
- Saved post content from a real site, compared with current save output.
- Back-compat branches in save (`x === undefined // bw compatibility`), version bumps in the changelog that mention markup.

With evidence of a past markup change (history, saved content, or back-compat branches that prove an older markup existed), a missing entry is CRITICAL. Without evidence, report a risk note in the summary, not a finding. The scan's "Static save with no deprecated array" line is only this risk prompt (INFO).

## 6. Pre-rendered HTML and Capability Gates

Some blocks store pre-rendered HTML in an attribute and output it with `RawHTML` or `RichText.Content` (code highlighters, embeds). This is safe only because core kses filters post content on save for users without `unfiltered_html`. A client-side capability check (hiding the editor for users without `unfiltered_html`) is UX, not security:
- Confirm the server never trusts the client gate.
- The hidden editor should be `readOnly`, not just covered by an overlay that keyboard users can tab past.
- Effects that call `setAttributes()` with HTML should not run for users who cannot edit HTML.

Editor JS that writes remote or third-party data (API responses, author names, URLs) into attributes or captions must escape it (`escapeHTML` from `@wordpress/escape-html`, `encodeURIComponent` for URL parts). WARNING: `unfiltered_html` users skip kses, so a compromised remote source stores live HTML.

## 7. Validation Hiding

Code that hides, relabels, or auto-dismisses the core invalid-block warning (DOM rewrites of `.block-editor-warning`, CSS hiding it, auto-clicking "Attempt recovery") is WARNING. It masks real breakage (tampered content, a removed filter, a missing deprecation) and trains users to accept data loss.
