# Step 3 - how the importer must work

Arguments, guards, flagging and cleanup, the settings backup, the run order, and the
runtime rules.

**Arguments.** `wp eval-file` only accepts positional arguments; flags like `--reset` are rejected. Read these from `$args`, and accept every one of them even where the theme makes one meaningless (`no-comments` on a theme with no comments): the parser rejects arguments it doesn't know, so a meaningless one is accepted and ignored.
- `reset`: delete the existing demo content, then import.
- `purge`: delete the demo content and stop.
- `count=N`: import the first N posts. Pages, menus, and settings are always created. A small import only has to cover one of each kind; the occasional states (an item with no video, an unset badge) belong to the full run, so inspect those there.
- `seed=N`: make every random choice repeatable (dates, terms, tags, image sizes, counters, comments). Call `mt_srand( crc32( "{$seed}:{$type}:{$index}" ) )` before generating each item, where `$type` names the kind of item (post, term, user, or comment set), then discard one `mt_rand()` draw, so a failed download or skipped item doesn't shift later items. Compute every date as an offset from an anchor of today at 00:00 UTC (`gmdate( 'Y-m-d 00:00:00' )`), never from the current time, and keep every date at or before the anchor. Without `seed`, use `seed=1` and print the seed in the success line.
- `no-comments`: skip comment generation.
- `verify`: change nothing. Check every demo item against the data model and list each field that is empty where it should be filled, or stored in the wrong shape or with an invalid value, then exit with `WP_CLI::error` if anything failed. Apply the same conditions as the import (optional fields, "paid items only", and so on), so a correctly empty field isn't reported. Check a URL's shape with `filter_var( $url, FILTER_VALIDATE_URL )`, never with `wp_http_validate_url()`, which resolves DNS and so fails on the `example.com` placeholders this procedure asks for.

**Guards.**
- Start the file with `defined( 'ABSPATH' ) || exit;` and exit unless `WP_CLI` is defined. Only two statements may come before the guard, in this order: `declare(strict_types=1);` if the theme's files use it, then a `namespace` line if the theme's code is namespaced and you namespace the importer class (PHP requires both to come first).
- If `is_multisite()`, stop with a `WP_CLI::error`: users are network-wide, and `wp_delete_user()` only removes them from one site. Otherwise run on any environment type, production included.
- If demo content already exists and neither `reset` nor `purge` was passed, stop with a `WP_CLI::error` that explains both.

**Flagging and cleanup.**
- The site is empty, so demo slugs, usernames, and emails won't clash with real content; no collision handling is needed, and every demo item uses the exact slug templates expect (for example `contact`).
- Mark every item the importer creates with a `_<theme>_demo` flag: post meta on posts and attachments, user meta on users, term meta on terms, comment meta on comments, and an option for anything else. Menus are `nav_menu` terms and their items are `nav_menu_item` posts, so both take the flag the same way, and so does any per-item meta the theme's own handler saves. Never flag anything the importer didn't create; side effects such as the `post-format-*` terms `set_post_format()` adds count as created only if they didn't exist before. Meta on demo items is deleted with them; never add meta to other content, except seeded items (below).
- `reset` and `purge` delete only flagged items. Delete attachments with `wp_delete_attachment( $id, true )` so the files go too.
- Seeded items are never flagged. Record each meta key you add to a seeded item in an option, including keys the theme's own save handler adds when you call it, and `purge` deletes exactly those keys and leaves the item. Never overwrite a value a seeded item already has.
- If the theme has its own demo system, also tag everything you create with the theme's demo key, and add to its tracked settings list only the keys that were empty or at their default before the import (a key that held the owner's own value would be deleted by the theme's remove tool). Then run the theme's own remove or reset tool once on the test site and record what it removes and what it leaves. The importer's own flag and `purge` must still work on their own, including straight after the theme's tool has run, and are the authority for cleanup. If the theme's tool deletes seeded content or the owner's settings, or misses demo content, report that as a theme bug; don't work around it.
- `purge` recounts the terms it touched (a crashed import can leave deferred counts stale), removes the demo widget instances from their `widget_<id_base>` options, and unschedules cron events the import caused (events whose arguments name a demo item, and theme events that didn't exist before the import). Skip whichever of these the import cannot have caused, and say so in the report.

**Settings backup.** Before changing anything, save every current Customizer and theme options value (the whole option array where the theme uses one) to a `_<theme>_demo_settings_backup` option. Never overwrite a backup that already exists; a second or crashed run must keep the original.
- The backup covers the whole `theme_mods_<stylesheet>` option (which holds `nav_menu_locations`, `custom_logo`, and the header and background mods) and the options `site_logo`, `sidebars_widgets`, `sticky_posts`, every `widget_<id_base>` option the import writes to, `blogname`, `blogdescription`, `site_icon`, `show_on_front`, `page_on_front`, and `page_for_posts`. For each, record whether it existed.
- `reset` and `purge` restore those values exactly, delete settings that didn't exist before, and delete the backup. Restore `theme_mods_<stylesheet>` first, then set or delete `site_logo` to match its backed-up state, then write `theme_mods_<stylesheet>` again: core copies every `set_theme_mod( 'custom_logo' )` into `site_logo` and reads `site_logo` first, and deleting `site_logo` removes `custom_logo` from the theme mods.
- Read and write sidebars through `get_option( 'sidebars_widgets' )`, not `wp_get_sidebars_widgets()`, which is cached per request and goes stale after a restore.
- Three things are exempt from exact restore: values core adds on its own (`custom_css_post_id` in the theme mods, empty `widget_<id_base>` options), and cache-version counters the theme bumps to invalidate its caches, which must never go back down.

**Order.** One method per content type, called from a single `run()` in this order:
1. For `reset` only: the purge (which restores the settings and deletes the old backup).
2. The settings backup.
3. Default-content removal.
4. Users.
5. Terms.
6. Pages.
7. Posts.
8. Media, sideloaded with the parent post's ID. Then update any post bodies that embed attachment IDs or URLs, keeping `post_modified` at its intended value, because `wp_update_post()` stamps the current time and would show "Updated" labels and dates after the anchor.
9. Meta.
10. Comments.
11. Menus and widgets.
12. Customizer and options.
13. Cache clearing: clear the theme's own transients and cache groups and call any cache-bust helpers it defines, so the front end shows the new content immediately; if a helper only works once per request and has already run, bump the theme's cache version yourself. Never call `wp_cache_flush()`, which empties a shared persistent cache for every site that uses it.

**Runtime.**
- Load `wp-admin/includes/file.php`, `media.php`, `image.php`, and `user.php`. If no user is set, switch to the first administrator so kses and capability checks behave.
- Send no pings, trackbacks, enclosure checks, or emails; media downloads (images, and the small video or audio pool when a template needs attachment IDs) are the only outbound requests the importer makes. At the start, `define( 'WP_IMPORTING', true )` so `_publish_post_hook` adds no `_pingme`/`_encloseme` meta and schedules no `do_pings` event, and don't change the site's `default_pingback_flag` or `default_ping_status` options. Create comments with `wp_insert_comment()` so no notification emails go out. All user and comment emails use `@example.com`.
- Wrap the import in `wp_defer_term_counting( true )` and `wp_defer_comment_counting( true )`, and turn both off at the end.
- Pass a timeout of 60 seconds to `download_url()` (the default is 300), and retry each image download up to 3 times. On failure, log a warning and keep going.
- Cache each download in `sys_get_temp_dir() . '/<theme>-demo-cache'` (outside the theme and uploads; it follows `TMPDIR`), keyed by seed and size, and reuse it on later runs. Write each download's photo ID to a small sidecar file beside the cached image, so the duplicate check still works on a cache hit, when no response header arrives. On the test site `TMPDIR` points inside `<tmp>`, so the cache speeds up later runs on that site but doesn't survive `teardown`. Let an environment variable (for example `<THEME>_DEMO_CACHE`) override the cache directory, and point it somewhere outside `<tmp>` while you test, or every import downloads everything again. Before sideloading, copy the cached file to a new `wp_tempnam()` file and pass that copy as `tmp_name`, because `media_handle_sideload()` deletes `tmp_name` after copying it into uploads. Unlink the copy if sideloading fails.
- Show a WP-CLI progress bar that ticks once per item created, not once per phase (WP-CLI hides it when output isn't a terminal; that's fine), then a success line with the number of posts and images, the number of failed downloads, and the seed.

**Code.** Write it in the theme's existing code style (array syntax, naming prefix, comment density), as a single `final class` with the theme prefix and no global functions or variables. WP-CLI messages and demo content don't need the text domain.
