# Site State Migration

Code migration (Gates 2–5) moves files. This reference moves the **site state** a classic theme stores in the database, most of which is silently lost when a block theme activates. Inventory it in Gate 0; migrate it in Phase 3; verify it in Gate 6.

## Offline ASSESS

Without site access, do not guess values. Reading settings (`show_on_front`, `page_on_front`, `page_for_posts`) decide which template renders the front page and blog index; offline, list both outcomes and plan templates for each. List the export commands below for later, infer expected state from code (no `register_sidebar` → no widgets, unless sidebars are registered in a loop over an option; no `Template Name:` header → no page-template assignments; `register_nav_menus` locations → menus to import), and mark each site-state row "value unknown — export before Phase 1".

## Inventory commands (run before switching themes)

```bash
wp theme mod list --format=json > theme-mods-classic.json      # Customizer settings stored as theme mods (includes nav_menu_locations)
wp option get <theme>_options --format=json > theme-options.json # Customizer settings with 'type' => 'option' and Settings API options
wp option list --search='widget_*' --format=json > widgets.json  # widget instance settings per widget type
wp option get sidebars_widgets --format=json > sidebars.json     # which widget instances sit in which sidebar
for o in show_on_front page_on_front page_for_posts; do echo "$o=$(wp option get $o)"; done   # Reading settings decide front-page.html / home.html
wp post list --post_type=custom_css --fields=ID,post_name       # Additional CSS (one post per theme)
wp widget list sidebar-1 --fields=name,id,position              # repeat per sidebar: wp sidebar list
wp menu list --fields=term_id,name,locations                    # classic menus and their locations
wp option get site_logo; wp option get site_icon                 # carried over by core
```

Commit the output next to the `classic-pre-migration` tag.

## What happens to each item

| Classic state | On block-theme activation | Migration action |
|---|---|---|
| `custom_logo` theme mod | Kept — core syncs it with the `site_logo` option | None; confirm `wp:site-logo` shows it |
| Site icon | Kept (`site_icon` option) | None |
| Customizer settings with `'type' => 'option'` (often one array, `<theme>_options`) | Kept — options are not per theme; they simply stop being read | Same mapping as theme mods; check each is **live** (read by code that runs) before mapping |
| `nav_menu_locations` theme mod | Kept in the same-slug case, but block themes have no locations | Tells which menu goes in which part; use it to drive the Navigation import |
| Colors/fonts in theme mods | Stored in `theme_mods_{stylesheet}`: kept when the block theme reuses the classic theme's folder slug, lost when the slug changes. The Customizer stays reachable in a block theme while code hooks `customize_register` | Map visual values into `theme.json` (Gate 2) or a style variation; move data values (emails, phone) to plugin options. If the slug changes, copy `theme_mods_{old}` first |
| Content in theme mods (hero heading, tagline pill, footer text, contact recipient) | Kept only while the folder slug is unchanged; moving the text into pattern copy orphans it | Copy to plugin options per the Customizer data rule below; keep the classic mods for the fallback |
| Layout toggles in theme mods (sidebar on/off, header style) | Lost | Custom templates, template-part variations, or patterns |
| Selected color scheme | Lost | Pick the matching style variation after activation |
| Additional CSS (`custom_css` post, keyed by stylesheet) | Kept under the same slug; hidden (attached to the old theme) when the slug changes | New slug: copy into Site Editor → Styles → Additional CSS, or fold rules into `theme.json` / `style.css` |
| Widgets in sidebars | Not rendered — block themes have no widget areas | Rebuild as a template part or pattern; text/HTML widgets by hand; custom widget types per `legacy-features.md` → Widgets |
| Sidebars created at runtime from an option (user-managed list) + per-post sidebar choice meta | Not rendered | One template part per used sidebar (from `sidebars_widgets`), and a custom template per sidebar choice, or a dynamic block that renders the chosen part; map the per-post meta to `_wp_page_template` or a block attribute |
| Menu locations | No locations in block themes | Navigation block offers to import a classic menu → creates a `wp_navigation` post |
| `custom-header` image | Lost | Cover block in the header part or a pattern |
| `custom-background` | Lost | `styles.background` in `theme.json` or Global Styles |
| Front page / posts page settings (`show_on_front`) | Kept | Ensure `front-page.html` / `home.html` match intent |
| Page template assignments (`_wp_page_template` meta = `page-full.php`) | Fall back to `page-{slug}.html` / `page.html` | Keep the values while the classic fallback exists; remap to `customTemplates` slugs (`wp post meta update <id> _wp_page_template full-width`) only when it retires |

Find page template assignments:

```bash
for id in $(wp post list --post_type=page --meta_key=_wp_page_template --format=ids); do echo "$id $(wp post meta get $id _wp_page_template)"; done
```

**Customizer data rule:** classify every setting. **Presentation** settings (colors, fonts, widths, layout toggles) → `theme.json`, style variations, or template-part variations. **Content/data** settings (headings, footer text, contact recipient, social URLs, tokens) → copy into plugin options (`register_setting()`, one per field — or keep an existing structured option as one `type: object` setting with a schema; splitting a working array buys nothing), read by plugin blocks or a binding source; leave the classic theme mods untouched so the classic fallback keeps working. Plugin code never reads `get_theme_mod()` for data: theme mods live in `theme_mods_{stylesheet}` and follow the theme folder. Secrets (API tokens) move to options or constants and never into block markup. **Marketing copy** (homepage hero, how-it-works steps) that editors should change in the Site Editor is written once into the database copy of the front-page template or part as plain block content, from the current values — bindings for dozens of strings defeat the Site Editor.

**Template defaults vs Customizer defaults:** when a template's `get_theme_mod( 'k', 'x' )` fallback differs from the `add_setting` default, visitors saw the template value — that one wins; record both. Also record orphan reads (mods read but never registered) and settings registered but never read.

## Navigation migration

1. Open the header part in the Site Editor and select the Navigation block.
2. In the block's menu picker choose **Import Classic Menus** → the primary menu.
3. WordPress creates a `wp_navigation` post.

Pitfalls and a scriptable route:
- **Several locations:** loop over `nav_menu_locations` in the scripted import — one `wp_navigation` post per menu, `ref` set in the part that replaces each location — in one pass before the first front-end view. Give each Navigation block a `className` naming its former location so location-specific styles and filters (numbering, current-item badge, forced `target="_blank"`) can target it in a `render_block_core/navigation-link` filter.
- **Order:** import menus before the first front-end page view after activating the block theme. After the import, header/footer parts with the `ref` live in the database, so later theme updates to `parts/*.html` no longer apply until those copies are reset or re-saved from the theme files (export → reset workflow in `quality-and-deployment.md`).
- A Navigation block **without** `ref` auto-creates a fallback `wp_navigation` post (from the classic menu or a page list) on its first front-end render. If the import is done afterwards, that fallback is orphaned. Set `ref` before the first visit, or delete the fallback (`wp post list --post_type=wp_navigation`).
- Scripted import (no editor UI): convert with core's `WP_Classic_To_Block_Menu_Converter::convert( wp_get_nav_menu_object( $menu_id ) )`, create the post (`wp_insert_post( array( 'post_type' => 'wp_navigation', 'post_status' => 'publish', 'post_title' => $name, 'post_content' => $blocks ) )`), then save the header part (database copy) with `"ref":<id>` on its Navigation block. Run `wp mytheme migrate-nav-icons` after. Optionally set `"ref":<id>` on the block in `parts/header.html` for the deployed site only — never in the distributable theme, since the ID differs per site.

## Database overrides: templates, parts, global styles

Once anyone saves a template, part, or Global Styles in the Site Editor, WordPress stores a copy in the database and **that copy wins over the theme file**. Deployed theme changes then appear not to work.

| Post type | Overrides |
|---|---|
| `wp_template` | `templates/*.html` |
| `wp_template_part` | `parts/*.html` |
| `wp_global_styles` | `theme.json` styles/settings (user layer) |
| `wp_navigation` | Navigation content (not a file override, but site-specific) |

Workflow:
- Check before every deploy: `wp post list --post_type=wp_template,wp_template_part,wp_global_styles --fields=ID,post_name,post_modified`.
- To ship file changes over a customized template: reset it in Site Editor (⋮ → Reset / Clear customizations), or delete the post after confirming the customization is not wanted.
- To keep client edits: export them into the theme with the **Create Block Theme** plugin (Save changes to theme), commit, then reset the database copies.
- During development, edit in the Site Editor and export with Create Block Theme — then markup is serialized correctly and validation errors are avoided.

## Hidden-state checklist for ASSESS

Add these to the Gate 1 inventory as their own rows (bucket MANUAL unless trivial):
- Theme mods with non-default values.
- Additional CSS (line count).
- Active widgets per sidebar.
- Menus assigned to locations.
- Pages using custom page templates.
