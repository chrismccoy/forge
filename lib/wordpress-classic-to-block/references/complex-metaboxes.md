# Gate 5d — Complex Metaboxes → Editor UI

Gate 5b handles simple fields (register meta, bind to a core block). This gate handles everything Block Bindings cannot: options, conditional fields, repeaters, relationships, media pickers, validation, and site-wide or term-level fields.

Themes with hand-written `add_meta_box()` code (no ACF, no CMB2): start with `coded-metaboxes.md` — reading the save handler, the field inventory table, legacy-metabox coexistence, and per-field recipes — then return here for UI patterns.

All editor JavaScript in this procedure is **no-build**: plain JS against `wp.*` globals with `wp.element.createElement`, plus a hand-written `*.asset.php` listing script handles. Example code: `examples/functionality-plugin/inc/blocks/` and `inc/editor/`.

## Step 1 — Decide where each field's data lives

Decide before writing any UI. Changing storage later requires another data migration.

| Field behavior | Storage | Why |
|---|---|---|
| Queried, sorted, filtered (event date, price, featured) | **Post meta** | `WP_Query`, Query Loop, REST, SEO/feeds can read it |
| Shown in many places for one post | **Post meta** | One value, many renderers |
| Presentation option for one block instance (layout, show CTA) | **Block attribute** | Per-instance, no query needs |
| Repeater rows displayed as content (sessions, FAQ, team) | **Child blocks** (`InnerBlocks`) | Native add / remove / reorder, revisions, no custom UI |
| Repeater rows queried or reused elsewhere | **Meta array** (`type: array` + REST schema) | Queryable, but needs a custom list control |
| Relationship (related posts, speakers) | **Post meta** (array of IDs) | Queryable both ways |
| Site-wide value (phone, address, social links) | **Option** (`register_setting`) | Not per post |
| Per-term or per-user value (category color, author role) | **Term / user meta** | Belongs to the term or user |

Record the decision per field in the Gate 1 risk register.

## Step 2 — Pick the editor UI

| Need | Component (`wp.components` / `wp.blockEditor`) | Example |
|---|---|---|
| Per-block options | `InspectorControls` + `PanelBody` with `SelectControl`, `ToggleControl`, `TextControl`, `RangeControl` | `blocks/event-details/editor.js` |
| Conditional fields | Render the control only when a sibling value matches | CTA label/URL shown when "Show button" is on |
| Image / file | `MediaUploadCheck` + `MediaUpload` (store attachment ID) | `bannerId` in `event-details` |
| Post-level meta fields | `PluginDocumentSettingPanel` + `useEntityProp( 'postType', type, 'meta' )` | `editor/event-panel.js` |
| Relationship picker | `FormTokenField` or `ComboboxControl` fed by `useSelect( select => select( 'core' ).getEntityRecords( … ) )` | `event_related` in `event-panel.js` |
| Required field | `lockPostSaving( key )` / `unlockPostSaving( key )` from `core/editor` + server-side check | `event_date` |
| Repeater as blocks | Parent with `useInnerBlocksProps` + `allowedBlocks` + `template`; child block with `parent` | `blocks/event-sessions`, `blocks/event-session` |
| Live preview of server markup | `wp.serverSideRender` with `urlQueryArgs: { post_id }` **only when the ID is numeric** — in the Site Editor the current post ID is a template ID (`theme//slug`) and the block renderer answers HTTP 400 | `event-details` |

Every dynamic `render.php` must tolerate editor renders through REST (`ServerSideRender`, Site Editor previews): there is no main query, so `$wp_query->posts` can be null, `get_queried_object()` returns null, and `postId` context may be missing. Guard each before use or the Site Editor logs PHP warnings.

`PluginDocumentSettingPanel` moved from `wp.editPost` to `wp.editor` in WP 6.6. Fall back to `wp.editPost` for older versions (see `event-panel.js`), and list both handles in the asset file.

## Step 3 — Structured edit screen with a CPT template

A metabox-heavy edit screen is a form. Recreate the form as a locked block layout on the post type:

```php
'template'      => array(
	array( 'mytheme/event-details' ),
	array( 'mytheme/event-sessions', array(), array( array( 'mytheme/event-session' ) ) ),
	array( 'core/paragraph', array( 'placeholder' => __( 'Describe the event…', 'mytheme-functionality' ) ) ),
),
'template_lock' => 'insert',
```

| `template_lock` | Effect |
|---|---|
| `'all'` | No add, remove, or move |
| `'insert'` | No add or remove; move allowed |
| `'contentOnly'` | Only text/media editable; structure hidden |
| `false` | Template is a starting point only |

The template applies to **new** posts. Existing posts get the blocks through a content migration (Step 6).

## Step 4 — Repeaters: child blocks vs meta array

**Child blocks** (recommended when rows are displayed content):
- Parent `mytheme/event-sessions`: `allowedBlocks` in `block.json`, `useInnerBlocksProps` in edit, `save: () => el( InnerBlocks.Content )` so children persist, `render.php` wraps `$content`.
- Child `mytheme/event-session`: `"parent": ["mytheme/event-sessions"]`, attributes per column, `save: () => null`, `render.php` outputs one row.
- Rows live in `post_content`; revisions, copy/paste, and reordering work for free.
- Cannot query rows with `WP_Query`.

**Meta array** (when rows are queried or reused):
```php
register_post_meta( 'event', 'event_sessions', array(
	'type'         => 'array',
	'single'       => true,
	'default'      => array(),
	'show_in_rest' => array( 'schema' => array(
		'type'  => 'array',
		'items' => array(
			'type'       => 'object',
			'properties' => array(
				'time'  => array( 'type' => 'string' ),
				'title' => array( 'type' => 'string' ),
			),
		),
	) ),
	'auth_callback' => fn( $a, $k, $id ) => current_user_can( 'edit_post', $id ),
) );
```
UI: a sidebar panel that maps the array to rows of `TextControl`s with add/remove/move buttons, writing back through `setMeta( { ...meta, event_sessions: rows } )`. Render with a dynamic block (`blocks/event-schedule`).

## Step 5 — Validation

- Editor: `lockPostSaving` disables Publish/Update and shows why through control `help` text.
- Server: always re-validate. The block editor saves through REST and sends meta in the same request, so validate in `rest_pre_insert_{post_type}` using the incoming `meta` param, falling back to stored meta. Return a `WP_Error` with status 400 — the editor shows its message. See `inc/post-meta.php`.
- `wp_insert_post_data` is the wrong hook for REST: meta is saved *after* the post, so it sees the old value.

## Step 6 — Data migration for complex fields

| From | To | Tool |
|---|---|---|
| Serialized repeater meta (`_event_sessions`) | Child blocks in `post_content` | `wp mytheme migrate-sessions [--dry-run]` (`inc/cli-migrations.php`) |
| Serialized repeater meta | Structured meta array (new key) | `update_post_meta( $id, 'event_sessions', array_values( $rows ) )` loop |
| Comma-separated IDs | Integer array meta | `array_map( 'absint', explode( ',', $old ) )` |
| Options-page array (`get_option( 'mytheme_options' )['phone']`) | Individual registered options | `update_option( 'mytheme_phone', $old['phone'] )` |

Block migration rules:
- Parse with `parse_blocks()`, append or insert block arrays, write with `serialize_blocks()`.
- A parent with inner blocks needs one `null` in `innerContent` per child.
- Wrap the update in `wp_slash()` — `wp_update_post()` unslashes its input.
- Skip posts that already contain the block (`has_block()`); keep old meta until verified.

## Step 7 — Query Loop variation instead of custom loops

Classic `new WP_Query( array( 'post_type' => 'event', 'meta_key' => 'event_date', … ) )` loops become a Query Loop variation:

- JS (`inc/editor/query-variations.js`): `registerBlockVariation( 'core/query', { name, isActive: [ 'namespace' ], attributes: { namespace, query: { postType: 'event', … } }, allowedControls, innerBlocks } )`.
- PHP (`inc/query-loop.php`): the `namespace` attribute does not reach inner blocks, so flag `attrs.query` in `render_block_data`; then `query_loop_block_query_vars` reads `$block->context['query']` and adds `meta_key`, `orderby`, `meta_query`.
- The flag also reaches pagination blocks, so page counts match.
- Editor preview runs through REST and ignores the PHP filter — previews show default order. Acceptable; document for the client.

## Step 8 — Editable custom binding sources (WP 6.7+)

PHP `register_block_bindings_source()` is read-only. To let editors edit a computed or custom-source value inline, register the same source name in JS:

```js
wp.blocks.registerBlockBindingsSource( {
	name: 'mytheme/event-meta',
	getValues( { select, context, bindings } ) {
		const meta = select( 'core' ).getEditedEntityRecord( 'postType', context.postType, context.postId )?.meta || {};
		const values = {};
		for ( const [ attr, { args } ] of Object.entries( bindings ) ) values[ attr ] = meta[ args.key ];
		return values;
	},
	setValues( { dispatch, context, bindings } ) {
		const meta = {};
		for ( const { args, newValue } of Object.values( bindings ) ) meta[ args.key ] = newValue;
		dispatch( 'core' ).editEntityRecord( 'postType', context.postType, context.postId, { meta } );
	},
	canUserEditValue: () => true,
} );
```

Use `core/post-meta` whenever plain meta suffices; it already supports inline editing on 6.7+.

## Site-wide fields (classic theme options pages)

Classic "Theme Options" pages (Settings API, Redux, Kirki, ACF options) and Customizer settings follow the Customizer data rule in `site-state-migration.md`. They split three ways:
- **Visual settings** (colors, fonts, layout widths) → `theme.json` / Global Styles. Stop reading the option; delete it only when the classic fallback retires.
- **Data** (phone, address, social URLs) → `register_setting()` with `show_in_rest`, one option per field — or one `type: object` setting with a schema when the theme already stores a structured option. Display with a custom binding source that reads an allowlist of options (`inc/site-options.php`).
- **Admin UI** → fields on Settings → General for a handful of values; a plugin settings page for more.
- Never bind arbitrary option names — allowlist keys in the source callback.
- **Behavior settings:** per-instance behavior (slider transition, autoplay) becomes a block attribute; site-wide behavior read by several templates or by admin code (a site mode) stays an option.
- **Dead settings:** a setting whose output function is unhooked, or whose value no running code reads, is not migrated as a token — derive tokens from what is actually printed (often a frozen CSS file). Mark it "Live? no" in the inventory.
- **Orphaned option data** with no admin UI left: migrate only if a block reads it; otherwise record and leave it.
- **Settings on core screens** (`add_settings_section` on Discussion or Reading): move to the plugin unchanged.
- **Defaults that disagree** between the Customizer registration and a seeder: pick the one users actually saw and record the choice.

## Term meta and user meta

- Register with `register_term_meta( 'category', 'mytheme_color', array( 'show_in_rest' => true, … ) )` / `register_meta( 'user', … )`.
- Display on term archives: a custom binding source or dynamic block reading `get_queried_object()`; inside a Query Loop, read the post's terms via `get_the_terms( $block->context['postId'], … )`.
- Author fields: a dynamic block reading `get_the_author_meta()` for the post author (`postId` context).
- Editing UI: term and user edit screens stay classic forms — register fields there with `{$taxonomy}_edit_form_fields` / `show_user_profile` hooks.

## Scope boundary

In scope: everything above, built no-build with `wp.*` globals. Out of scope: large React applications (multi-step wizards, drag-and-drop builders, custom data stores). Flag those as MANUAL and estimate separately.
