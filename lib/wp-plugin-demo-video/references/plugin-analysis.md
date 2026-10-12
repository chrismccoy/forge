# Plugin Analysis

How to turn a WordPress plugin's source into a feature map, and how to check it on the live site: which admin screens exist, what each one does, which selectors drive it, and which actions change data.

## Contents

1. Run the scanner
2. Admin pages: from registration call to URL
3. Settings pages
4. Post types, list tables and meta boxes
5. JavaScript-driven screens
6. Endpoints and side effects
7. Blocks, shortcodes and front-end output
8. Feature map template
9. Check the live site

## 1. Run the scanner

```sh
node scan-plugin.js "<plugin dir>"
```

The scanner prints, per category, every matching call with its file, line and the full call joined onto one line (multi-line calls are followed until the parentheses balance). The full list of skipped files and the flags `--include-tests` and `--include-build` are in `scene-api.md` section 6. In short: symlinks, dependency and build folders, tests, and minified code are skipped. Pass `--include-tests` when the tests hold useful fixtures, such as sample API responses or golden HTML.

Sections, in order:

| Section | Use it for |
| --- | --- |
| Plugin header | Name, version, text domain. The text domain helps when searching translated strings. |
| Admin pages | Menu titles, page titles and slugs: the scene start URLs. |
| Settings | Option names, sections and field IDs. |
| Post types and taxonomies | List screens and editors the plugin adds. |
| REST routes | Endpoints the UI calls; wait on these for async results. |
| AJAX and admin-post actions | Older-style endpoints; same use. |
| Scripts and localized data | Which JS file runs on which screen, and the config object it receives. When a script is enqueued by handle only, find its `wp_register_script` call for the file path. |
| UI extras | Meta boxes, dashboard widgets, shortcodes, blocks, list columns, plugin action links, notices. |
| String constants | Resolves `self::SLUG`, `self::PAGE` and similar references in the calls above. |
| JS requests | `fetch`, `apiFetch`, `$.post` and `ajaxurl` calls in the plugin's JS. |
| Blocks (block.json) | Block names and titles for the inserter. |
| DOM hooks per file | IDs and names in PHP views; selector strings and `data-*` attributes in JS. |

The scanner finds where things are. Read the files it points to before planning: the admin page render callbacks, the view templates, and the JS that drives each screen.

### Without Node.js

In hand-off mode the scanner may not run. Search the source with the available tools for these patterns instead (skip `vendor/` and `node_modules/`):

| Looking for | Search for |
| --- | --- |
| Plugin header | `Plugin Name:` in the main PHP file |
| Admin pages | `add_menu_page`, `add_submenu_page`, `add_options_page`, `add_management_page`, `add_theme_page` |
| Settings | `register_setting`, `add_settings_section`, `add_settings_field` |
| Post types | `register_post_type`, `register_taxonomy` |
| Endpoints | `register_rest_route`, `wp_ajax_`, `admin_post_` |
| Scripts | `wp_register_script`, `wp_enqueue_script`, `wp_enqueue_script_module`, `wp_localize_script`, `wp_add_inline_script` |
| UI extras | `add_meta_box`, `wp_add_dashboard_widget`, `add_shortcode`, `register_block_type`, `block.json`, `plugin_action_links`, `_columns` |
| Constants | `const `, `define(` |
| JS requests | `fetch(`, `apiFetch`, `ajaxurl`, `$.post`, `/wp-json/` |

Registration calls often span several lines. Read each match with the lines that follow it.

## 2. Admin pages: from registration call to URL

Resolve the slug first. When an argument is a constant (`self::SLUG`) or a method (`self::listUrl()`), look it up in "String constants" or open the class.

| Registration | Arguments that matter | Admin URL |
| --- | --- | --- |
| `add_menu_page($page_title, $menu_title, $cap, $slug, ...)` | `$slug` | `admin.php?page=<page-slug>` |
| `add_submenu_page($parent, $page_title, $menu_title, $cap, $slug, ...)` | `$parent`, `$slug` | `admin.php?page=<page-slug>` when `$parent` is a plugin slug; `<parent>?page=<page-slug>` when `$parent` is a PHP file such as `tools.php` or `edit.php?post_type=book` (joined with `&page=`) |
| `add_options_page(...)` | `$slug` | `options-general.php?page=<page-slug>` |
| `add_management_page(...)` | `$slug` | `tools.php?page=<page-slug>` |
| `add_theme_page(...)` | `$slug` | `themes.php?page=<page-slug>` |
| `add_users_page(...)` | `$slug` | `users.php?page=<page-slug>` |
| `add_dashboard_page(...)` | `$slug` | `index.php?page=<page-slug>` |
| `add_posts_page`, `add_media_page`, `add_pages_page`, `add_comments_page`, `add_plugins_page` | `$slug` | `edit.php`, `upload.php`, `edit.php?post_type=page`, `edit-comments.php`, `plugins.php` with `?page=<page-slug>` |

Special cases:

- A submenu whose slug is a URL or a PHP file (for example `edit.php?post_type=ytbi_video`) is a link to another screen, not a plugin page. Use that URL directly.
- A submenu that repeats the parent slug renames the first menu entry. It is the same page as the top-level item.
- `$menu_title` is the text in the admin menu. Use it to click through the menu in the video: `page.locator('#adminmenu').getByRole('link', { name: '<menu title>' })`.
- `$page_title` usually becomes the `<h1>`. Wait for that heading after navigation.
- Confirm every URL on the live site with `inspect-page.js --menu`. Menu titles shown there can differ from the source because of translations or filters.

## 3. Settings pages

- `register_setting($group, $option, ...)` names the stored option. Field `name` attributes are usually `<option>[<key>]`.
- `add_settings_field($id, $title, $callback, $page, $section, $args)`: `$title` is the visible label. When `$args['label_for']` is set, WordPress wraps the title in `<label for="...">`, so `page.getByLabel('<title>')` works. Otherwise find the input in the field callback.
- Find buttons that act without saving: "Test connection", "Validate key", "Send test email" and similar. These make good demo moments because they show live feedback without changing anything.
- Find secrets: API keys, tokens, passwords. Check how the plugin renders them. Masked fields (`type="password"` or a placeholder such as `••••`) are safe to show. Unmasked secrets must not appear in the video (see `storyboard.md`).
- Do not click "Save Changes" in a demo unless the user asks for it. Saving rewrites the site's settings.

## 4. Post types, list tables and meta boxes

- `register_post_type('<type>', ['show_ui' => true, ...])` adds `edit.php?post_type=<type>` (list) and `post-new.php?post_type=<type>` (editor). `show_in_menu` decides where the menu entry appears.
- Opening an editor writes. `post-new.php` saves an auto-draft on every load, and `post.php?post=<id>&action=edit` sets an edit lock. `demo.open` and `inspect-page.js` refuse `post-new.php` without approval. Count both kinds of writes in the side-effect tally.
- `manage_<type>_posts_columns` and `manage_<type>_posts_custom_column` add list table columns. Show them on the list screen.
- `add_meta_box($id, $title, $callback, $screen)` adds a box with ID `#<id>` to the editor for `$screen`. In the block editor, meta boxes appear below the content area. Scroll to them.
- `register_taxonomy` adds `edit-tags.php?taxonomy=<tax>&post_type=<type>`.

## 5. JavaScript-driven screens

Many plugin screens render an empty container in PHP and build the UI in JS. For these:

1. Find the view or render callback. Note the container IDs and any `<template>` elements.
2. Open the JS file enqueued for that screen. "Scripts and localized data" shows the handle, and the file path from the `wp_register_script` or `wp_enqueue_script` call.
3. Read how the UI changes state. Look for:
   - Event handlers on buttons and forms: the actions the scenes will perform.
   - State attributes such as `data-state`, `aria-busy`, `disabled` and `is-loading` classes: what to wait for.
   - Text the JS writes to the page: result messages and empty states.
   - Startup requests: a button can stay disabled until a bootstrap request returns. Wait until it is enabled.
4. Note items that may already be in a finished state from an earlier run (imported, sent, published). Choose items that are still unused, for example with `[data-state="idle"]`, instead of `.first()`.

`wp_localize_script($handle, '<objectName>', [...])` passes config and translated strings to the JS. Button text often comes from there, which helps when writing `getByRole` names.

## 6. Endpoints and side effects

For every REST route, AJAX action and admin-post action, record:

- **Method.** `READABLE`/`GET` reads. `CREATABLE`/`POST`, `EDITABLE`, `DELETABLE` and admin-post handlers usually write.
- **What it writes.** Read the callback. Look for `wp_insert_post`, `wp_update_post`, `wp_delete_post`, `update_option`, `delete_option`, `wp_mail`, `$wpdb->insert/update/delete`, file writes and remote calls (`wp_remote_get`, `wp_remote_post`).
- **External cost.** Remote APIs can use quota or cost money for each call.

Classify each user-facing action:

| Class | Examples | Demo rule |
| --- | --- | --- |
| Read-only | Search, preview, test connection, view lists | Safe to record. |
| Creates content | Import, generate, duplicate | Record only with user approval. Report what was created so the user can delete it. |
| Changes settings | Save Changes, toggle a feature | Avoid. Show the fields without saving. |
| Destructive or outbound | Delete, bulk delete, reset, send email, publish to a third party | Never record without explicit approval, and suggest a staging site. |

REST routes also give stable things to wait for in scenes: `page.waitForResponse((r) => r.url().includes('/wp-json/<ns>/search') && r.ok())`.

## 7. Blocks, shortcodes and front-end output

- `block.json` gives the block name and title. In the editor, insert the block by searching its title in the inserter. Editor scenes are slower and less stable than admin screens. Add them only when the block is a main feature.
- `add_shortcode('<tag>', ...)`: front-end output needs a page that contains the shortcode. Ask the user for an existing page URL. Do not create pages without approval.
- Plugins that change post content (for example by adding an embed) are best shown by opening the created post on the front end at the end of the demo.

## 8. Feature map template

Write the feature map before the storyboard. Keep it short.

```
Plugin: <name> <version> (text domain <td>)

Screens
- <Menu title> → admin.php?page=<page-slug> (h1 "<page title>")
  Purpose: ...
  Key controls: <label or id> ..., <button text> ...
  Async: <what loads, endpoint, what to wait for>
  Optional parts: <fields hidden by settings, empty states>

Actions
- <action> (<screen>) → <METHOD endpoint> → <side effect class> → <what it writes>

Secrets on screen
- <field>: masked / unmasked

Open questions for the user
- ...
```

## 9. Check the live site

Step 4: confirm the feature map on the real site before planning.

```sh
node --env-file=.env inspect-page.js --menu 'plugins.php' 'admin.php?page=<page-slug>'
```

- **The plugin is active.** Its menu entries must appear in the `--menu` output. A `Refused:` line for the plugin's page usually means it is inactive. Ask the user to activate it; never activate it yourself. On `plugins.php`, compare the plugin's version with the scanner's header. If they differ, tell the user that the source and the site do not match.
- **Only safe URLs.** Inspect only page URLs taken from registration calls or the admin menu. `inspect-page.js` skips URLs that match common data-changing patterns (nonces, `action=` other than `edit`, parameter names or values such as `delete` and `trash`, and `post-new.php`), because many plugins change data on a plain page load. This is a heuristic, not a guarantee.
- **Plain-text secrets.** If the feature map shows a secret displayed as plain text on a page (not in an input field), ask the user before inspecting that page. The inspector blanks secret-looking input values, but not text elsewhere on the page.
- **Compare with the source.** Menu titles and URLs can differ from the source because of translations and filters.
- **Look at the page.** Read the screenshots and `.aria.yml` files in `output/inspect/` for the real layout, empty states and notices. Note disabled controls, empty lists, and missing preconditions such as an API key that is not set.
- **Async UIs** (results, dialogs) do not appear in this output. Take their selectors from the source.
- **Startup requests.** Opening a page can start the plugin's own requests, such as a remote API call. Mention this when the plugin uses a paid or rate-limited API.

**Login problems.** If login fails, stop and report the error. Do not try to get around two-factor authentication, CAPTCHAs or security plugins. If login stops at the "Administration email verification" screen, ask the user to log in once in a browser and confirm the email. Never confirm it yourself, because confirming writes an option.
