# Interactivity API Guide

Reference for reviewing blocks that use the Interactivity API (WordPress 6.5+): `data-wp-*` directives in server-rendered markup, a `store()` in a script module, and server-side state. Covers the stable public API as of WordPress 6.9. Load it for any block with `viewScriptModule`, `@wordpress/interactivity`, or `data-wp-*` attributes.

## Review Checklist

| Check | Severity |
|-------|----------|
| Code importing `@wordpress/interactivity` loaded via `viewScript` instead of `viewScriptModule` | CRITICAL |
| Raw template output around directives (e.g. `echo $meta`) | CRITICAL (Contributor/remote data) |
| Render output has directives but block.json lacks `supports.interactivity` | WARNING |
| Namespace differs between `data-wp-interactive`, `store()`, `wp_interactivity_state()` | WARNING |
| Directive references an undefined `actions.*` / `state.*` / `callbacks.*`, or uses an expression | CRITICAL when the feature visibly breaks; WARNING when a fallback hides it |
| Pre-6.5 action signature `( { state, context } ) =>` | CRITICAL (action does not work) |
| `preventDefault()` / `currentTarget` in an action without `withSyncEvent()` (6.8+) | WARNING |
| State key read by the store but initialized by only some blocks; SSR derived state without a PHP value | WARNING |
| Hand-written `data-wp-context` JSON, `uniqid()` context, pre-escaped values in state | WARNING |
| `navigate()` without `data-wp-router-region`; hard-coded `/` URLs | WARNING |
| Click handlers on non-interactive elements; toggles without bound ARIA state | WARNING |
| `Requires at least` below 6.5 | WARNING |
| Duplicate stores, missing `clientNavigation` on static blocks in router regions, undebounced navigation | INFO |

The scan cross-checks namespaces, directive references, `supports.interactivity`, module type, router regions, `withSyncEvent`, click handlers on `<div>`, and hand-written context.

## Contents

1. Architecture
2. Setup checklist
3. Store API (JS)
4. Directives
5. Server side (PHP)
6. Client-side navigation (router)
7. Security and escaping
8. Accessibility
9. Common mistakes
10. Versions

## 1. Architecture

- PHP renders the block. Core processes `data-wp-*` directives on the server (for blocks with `supports.interactivity`), so the first paint already reflects state and context.
- A script module imports `@wordpress/interactivity`, defines a `store()` for the same namespace, and hydrates the server markup.
- State is global per namespace. Context is local to an element subtree. Directives read both by reference.
- The editor is unaffected: `edit` stays React. Interactivity is frontend only.

Review consequence: the server and the client must compute the same values. A value that only the client can compute, but that a server-processed directive reads, renders wrong on first paint and then flips (layout shift, flash of wrong state).

## 2. Setup Checklist

```json
{
	"apiVersion": 3,
	"supports": { "interactivity": true },
	"render": "file:./render.php",
	"viewScriptModule": "file:./view.js"
}
```

- `viewScriptModule`, NOT `viewScript`, for code that imports `@wordpress/interactivity`. A classic script cannot use `import` (CRITICAL).
- `supports.interactivity`: `true`, or `{ "interactive": true, "clientNavigation": true }`. Missing while the render output has directives: WARNING (core skips server-side processing). Blocks with no directives that should survive router navigation declare `{ "clientNavigation": true }`.
- `interactivity: true` without a view module of its own is fine only when another loaded block's store handles the namespace. Confirm.
- `Requires at least: 6.5` or higher in the plugin header and readme.
- wp-scripts emits `viewScriptModule` files only with `--experimental-modules` on `build` and `start` (still required in @wordpress/scripts 36.1). Without it the built block.json points at a missing `view.js` and the block has no frontend behavior (CRITICAL). The `create-block` interactive template adds the flag when it scaffolds a plugin, but `--no-plugin` into an existing plugin does not.

## 3. Store API (JS)

```javascript
import { store, getContext, getElement, withSyncEvent } from '@wordpress/interactivity';

const { state, actions } = store( 'myPlugin', {
	state: {
		// Derived state: a getter, recomputed from other state or context.
		get isOpen() {
			const context = getContext();
			return context.openId === context.id;
		},
	},
	actions: {
		toggle() {
			const context = getContext();
			context.openId = context.openId === context.id ? null : context.id;
		},
		// Needs the event synchronously (preventDefault): wrap in withSyncEvent (6.8+).
		submit: withSyncEvent( ( event ) => {
			event.preventDefault();
			actions.save();
		} ),
		// Async work: generator functions; yield promises.
		*save() {
			const { ref } = getElement(); // read before the first yield
			const response = yield fetch( state.endpoint );
			state.saved = ( yield response.json() ).ok;
		},
	},
	callbacks: {
		logOpen() {
			if ( state.isOpen ) {
				// runs from data-wp-watch / data-wp-init
			}
		},
	},
} );
```

Rules:
- Actions and callbacks receive the DOM event (actions) or nothing (callbacks). They read context with `getContext()`, the element with `getElement()`, and state through the object `store()` returned. The old `( { state, context, event } ) =>` signature is pre-6.5 experimental API: flag it (CRITICAL; the action does not work).
- Derived values are getters on `state` (or on context), not values written by callbacks.
- Async actions are generators (`*name() { yield promise; }`). `getContext()` / `getElement()` after a `yield` or inside `setTimeout`/`then` need the scope captured first, or `withScope( fn )` for plain callbacks.
- WP 6.8+: actions run asynchronously by default. Actions that call `event.preventDefault()`, `stopPropagation()`, or read `event.currentTarget` must be wrapped in `withSyncEvent()`; otherwise a deprecation warning appears and the call may happen too late (WARNING).
- Several `store( 'ns', … )` calls for one namespace merge. Identical stores duplicated across blocks are INFO (extract a shared module).
- `getConfig()` reads `wp_interactivity_config()`. `getServerState()` / `getServerContext()` (6.7+) read the values the server sent for the current page, mainly after router navigation.

## 4. Directives

Directive values are REFERENCES: a path into the store (`state.isOpen`, `context.item.title`, `actions.toggle`) with an optional leading `!` for negation. No expressions, ternaries, string concatenation, comparisons, or method calls. `data-wp-text="state.count + 1"` does not work (WARNING). Move logic into a getter.

| Directive | Purpose |
|-----------|---------|
| `data-wp-interactive="ns"` | Namespace for the subtree. Required on the root (a JSON object form with `namespace` also exists) |
| `data-wp-context='…'` | Local context object; children inherit and can override |
| `data-wp-bind--{attr}` | Set an attribute (`hidden`, `href`, `aria-expanded`, `disabled`). `false`/`null` removes it |
| `data-wp-class--{name}` | Toggle a class |
| `data-wp-style--{prop}` | Set an inline style property |
| `data-wp-text` | Set text content (escaped as text) |
| `data-wp-on--{event}` | Run an action on an element event |
| `data-wp-on-async--{event}` | Same, for actions that do not need the event synchronously (preferred for performance) |
| `data-wp-on-window--{event}`, `data-wp-on-document--{event}` | Global event listeners |
| `data-wp-watch` | Run a callback when its dependencies change |
| `data-wp-init` | Run a callback once on hydration |
| `data-wp-run` | Run a callback during render (can use hooks) |
| `data-wp-each` (+ `data-wp-each-key`) on a `<template>` | Render a list from an array; `data-wp-each-child` marks server-rendered items |
| `data-wp-key` | Stable identity for elements in lists |
| `data-wp-router-region="id"` | Region replaced on router navigation |

WP 6.9 allows several directives of the same type on one element by adding a unique ID after three hyphens (`data-wp-on--click---plugin-a`). Supported on `wp-on`, `wp-on-window`, `wp-on-document`, `wp-watch`, `wp-init`, `wp-run`; `wp-each` skips directives with an ID and `wp-style` ignores them.

## 5. Server Side (PHP)

```php
<?php
defined( 'ABSPATH' ) || exit;

wp_interactivity_state(
	'myPlugin',
	array(
		'likedIds' => array(), // initialize EVERY key the store reads
		'endpoint' => esc_url_raw( rest_url( 'my-plugin/v1/like' ) ),
		'isLiked'  => function () { // derived state for SSR (closure)
			$context = wp_interactivity_get_context();
			return in_array( $context['id'], wp_interactivity_state( 'myPlugin' )['likedIds'], true );
		},
	)
);

$context = array( 'id' => get_the_ID(), 'openId' => null );
?>
<div
	<?php echo get_block_wrapper_attributes(); ?>
	data-wp-interactive="myPlugin"
	<?php echo wp_interactivity_data_wp_context( $context ); ?>
>
	<button
		type="button"
		data-wp-on-async--click="actions.toggle"
		data-wp-bind--aria-pressed="state.isLiked"
	>
		<?php esc_html_e( 'Like', 'my-plugin' ); ?>
	</button>
</div>
```

Checks:
- Every state key the store reads is initialized on the server by EVERY block that uses it, not only by one block that may be absent from the page. A getter calling `state.likedIds.includes()` throws when no block on the page initialized `likedIds` (WARNING).
- Derived state used in server-processed directives gets a PHP value (static value or closure with `wp_interactivity_get_context()`) that matches the JS getter. A static placeholder is acceptable only if it matches the initial client value.
- Context through `wp_interactivity_data_wp_context( $context, $namespace = '' )`, never hand-written JSON in an attribute (WARNING: quoting breaks on `'`, values are not escaped).
- Context identifiers come from real data (`get_the_ID()`, block attributes), not `uniqid()` (non-deterministic, breaks caching).
- `wp_interactivity_state()` and `wp_interactivity_config()` JSON-encode values into a script tag safely. Do not pre-escape values (`esc_attr()` inside state double-escapes: `get_search_query()` already returns an escaped string; use `get_search_query( false )`).
- Current user: `wp_get_current_user()`. PHP's `get_current_user()` returns the process owner name (a string), not a `WP_User` (bug).

## 6. Client-side Navigation (router)

- Import lazily: `const { actions } = yield import( '@wordpress/interactivity-router' );` then `yield actions.navigate( url )`, `actions.prefetch( url )`.
- The swapped area needs `data-wp-router-region="unique-id"` (on an element with `data-wp-interactive`). Without a router region, `navigate()` only works with full-page client navigation, which is still a Gutenberg experiment: relying on it is WARNING for a plugin.
- Build navigation URLs from server data (`getConfig()` with `home_url()`), not hard-coded `/` (breaks subdirectory installs).
- Debounce navigation triggered by typing (INFO).
- Blocks inside a router region need `clientNavigation: true`.
- After navigation, the server sends fresh state; read it with `getServerState()` instead of assuming client state persisted. In 6.7-6.8 navigation only ADDS server state properties; since 6.9 server state and context are fully overwritten (properties absent on the new page are removed).

## 7. Security and Escaping

- Template output around directives follows normal render escaping: `esc_html()`, `esc_attr()`, `esc_url()`. Raw `echo $meta` in render.php is CRITICAL when Contributors can edit the meta (Custom Fields panel, `show_in_rest`) or it comes from remote/imported data.
- `data-wp-text` sets text content: safe. `data-wp-bind--href` / `--src` with user-controlled values can produce `javascript:` URLs: validate URLs on the server (`esc_url_raw()`) before putting them in state or context.
- Never build HTML strings in actions and assign them to `innerHTML`.
- REST endpoints called from actions: nonce (`X-WP-Nonce` from `wp_interactivity_config()`), `permission_callback`, args schema.

## 8. Accessibility

- Click handlers go on `<button type="button">` or links, not on `<div>`/`<span>` (WARNING: not keyboard reachable, no role).
- Toggles bind state to ARIA: `data-wp-bind--aria-pressed`, `--aria-expanded`, `--aria-controls`, `--hidden`.
- Dynamic results announce changes (`aria-live` region). Iframes get a `title`.
- `role="search"` belongs on the form (landmark), not on the input.

## 9. Common Mistakes

| Mistake | Effect | Fix |
|---------|--------|-----|
| `viewScript` for interactivity code | `import` fails, nothing works | `viewScriptModule` |
| Namespace differs between `data-wp-interactive`, `store()`, `wp_interactivity_state()` | Directives silently do nothing | One namespace string |
| No `supports.interactivity` | No server-side directive processing | Add it |
| Expressions in directive values | Directive ignored or wrong | Getter on state |
| `( { state, context } ) =>` actions | Pre-6.5 API; context undefined | `getContext()`, returned `state` |
| `event.preventDefault()` without `withSyncEvent` | Deprecation warning (6.8+), default may run | `withSyncEvent()` |
| `getContext()` after `yield` without captured scope | Wrong or missing context | Read before `yield` or use `withScope` |
| State key initialized by only one block | TypeError when that block is absent | Initialize in every block |
| Hand-written `data-wp-context` JSON | Broken quoting, injection | `wp_interactivity_data_wp_context()` |
| `navigate()` without router region | Depends on an experiment | `data-wp-router-region` |
| Click handler on `<div>` | Not keyboard accessible | `<button>` |

## 10. Versions

| Feature | WordPress |
|---------|-----------|
| Interactivity API, `viewScriptModule`, `data-wp-each`, `wp_interactivity_data_wp_context()` | 6.5 |
| Derived state closures in `wp_interactivity_state()`, `wp_interactivity_get_context()` | 6.6 |
| `getServerState()` / `getServerContext()` | 6.7 |
| Async actions by default, `withSyncEvent()` | 6.8 |
| Unique directive IDs (`---suffix`) | 6.9 |

Sources: make.wordpress.org dev notes "Updates to the Interactivity API in 6.6", "Subscribe to changes ... on client-side navigation in 6.7", "Interactivity API best practices in 6.8", "Changes to the Interactivity API in WordPress 6.9"; developer.wordpress.org Interactivity API reference.
