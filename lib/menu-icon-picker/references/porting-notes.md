# Porting notes - reference picker to theme code

Load this before writing any PHP or JS for the picker. It expands Rules 3 and 5.

## Port the logic, not the plugin packaging

`sources/menu-icon-picker.php` is shaped as a plugin. When porting it into the theme:

- Drop the `Plugin Name:` header docblock, the `MIP_VERSION` / `MIP_URL` =
  `plugin_dir_url()` constants, the `MIP_META_KEY` constant, and the
  `new Menu_Icon_Picker();` bootstrap line.
- Re-express the logic in the theme's own style - hooks registered from theme functions, or
  a single theme-prefixed class if the theme uses classes.
- The `if ( ! defined( 'ABSPATH' ) ) { exit; }` guard may stay.
- Asset URLs and versions come from Rule 4, not the plugin constants.

## The JS↔PHP contract must stay in sync

These four cross-file identifiers are the most common silent break when rebranding. The
value on the left (JS) and right (PHP) must match exactly:

- **Field input name:** JS `input[name^="<slug>-menu-icon["]` ↔ the PHP field's
  `name="<slug>-menu-icon[<id>]"` (e.g. `crafted-menu-icon[…]`). The exact string is a
  choice - the reference uses `mip_icon[…]` - as long as JS and PHP use the identical string.
  In Mode A also reconcile it with the existing save handler per Rule 2.
- **Localized object:** JS `window.<obj>` ↔ PHP `wp_localize_script( handle, '<obj>', … )`.
- **Element IDs:** the modal, grid, and search IDs referenced in JS ↔ the IDs the PHP modal
  prints.
- **CSS class prefix:** the classes used in JS-built markup ↔ the CSS file's selectors ↔ the
  PHP field markup.

Rename the jQuery event namespaces too (`.mipOpen`, `.mipClear`, `.mipClose`, `.mipSearch`,
`.mipPick`) - Verify check 3 flags them otherwise.

## Why the save handler deviates from the reference (Rule 5)

`sources/menu-icon-picker.php` stores the *bare* picked value and adds the style prefix only
at display time (`resolve_icon_classes` + JS `withStylePrefix`); `sources/DOCS.md` then
normalizes *again* at render. Collapse all of that into one place: normalize on **save** so
the stored meta is render-ready, and print it raw everywhere else. The stored value is the
single source of truth. The JS `withStylePrefix` may stay for drawing the admin preview
only.
