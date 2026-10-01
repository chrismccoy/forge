# Mode B - reader helper and frontend handoff

Load this before writing the reader helper or `MENU-ICON-FRONTEND.md` (Mode B, or the
half-built edge case).

## Reader helper

A one-liner the frontend can call:

```php
function mytheme_get_menu_icon( $item_id ) {
	return (string) get_post_meta( $item_id, '_mytheme_menu_icon', true );
}
```

Name it `<theme>_get_menu_icon( $item_id )` with the theme's real prefix and meta key. The
stored value is already render-ready (Rule 5), so no normalizing is needed at read time. The
reader returns the stored value unescaped; the caller escapes at output (`esc_attr` /
`esc_html`).

## Why the frontend is not edited

The theme has no icon in its menus today. Adding one is a visible frontend change, so leave
the choice to the user: write `MENU-ICON-FRONTEND.md` into the theme root instead of editing
templates, and summarize it in the final message.

## Contents of `MENU-ICON-FRONTEND.md`

Adapt both render options from `sources/DOCS.md` to the theme's actual prefix and meta key.
Give the user two choices, clearly labeled:

- **Option 1 - drop-in filter (no template edits).** A `nav_menu_item_title` filter that
  prepends the icon to every menu item. Simplest; works immediately once pasted into
  `functions.php` (or the new include). Note it affects *all* `wp_nav_menu` output.
- **Option 2 - custom walker (full control).** A `Walker_Nav_Menu` subclass that prepends the
  icon, plus the `wp_nav_menu( [ 'walker' => new … ] )` call, for icons on one menu only or
  custom markup.

Both snippets print the stored class **directly** via the reader helper -
`<i class="<?php echo esc_attr( <theme>_get_menu_icon( $item->ID ) ); ?>" aria-hidden="true"></i>`.
**Omit** the render-time normalizer (`mytheme_mip_class`) that `sources/DOCS.md` shows:
values are already normalized on save (Rule 5), so re-normalizing at render is dead code.
`sources/DOCS.md` reflects the reference's older store-bare model - use it for the
filter/walker shape only, not its normalization.

**Font Awesome on the frontend.** The picker enqueues Font Awesome in *admin* only.
Greenfield themes often don't load it on the front end, so the icon markup would render
blank. Include a `wp_enqueue_scripts` snippet that enqueues Font Awesome (the same CDN
version the picker uses, per Rule 6) - and tell the user to skip it if the theme already
loads Font Awesome.

Add a short CSS hint for spacing the injected `<i>`, and tell the user exactly which file to
paste into. If the theme has an obvious single primary-menu `wp_nav_menu()` call, point out
where Option 2's walker would slot in - but do not apply it without the user's go-ahead.
