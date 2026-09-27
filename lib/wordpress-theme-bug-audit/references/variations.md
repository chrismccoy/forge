# Section 3, part 3: step 12, variations

Read this in full before step 12. Each variation below is its own checklist item, with its own entry in the state file (`step12.<id>`), written the moment that variation finishes. A variation counts as done only when every line of its **Run** list has been carried out in full and its **Evidence** file exists; a shortened run (a few URLs instead of the full lists, no error capture) is not done.

Unless a variation says otherwise, **the standard pass** means: fetch every URL in `<work>/urls.tsv` with `fetch.sh`, and every URL in `<work>/admin-urls.tsv` logged in, run `shot` with `capture.js` on the home page, one archive, and one single view at 1440 and 390 wide, then summarize with `jslog.py` and `html-check.py`. Compare everything with the baseline from steps 6, 7, and 9: a difference that only appears in this variation is what you're looking for. Undo each variation before the next, and confirm it's undone.

Order: start `cache` first (its replay needs time to pass), run the others, finish `cache`, and run `multisite` last, on its own site.

Record in the coverage file, for every variation: what ran, what it found (bug numbers), or why it doesn't apply to this theme.

---

**`cache`: page cache**
- Run: add a must-use plugin on the throwaway site that sets `nonce_life` to 4 seconds. Log out, fetch every page that uses AJAX, REST, or a nonce (likes, votes, load more, forms, filters, search) and save the HTML. Fetch one such page twice logged out with different cookies and different `User-Agent` values, and diff the HTML. Check whether any counter increments in PHP while the page renders. At least 10 seconds after saving the HTML (after other variations), replay each feature's request with the nonce from the saved HTML, as a cached page would. Remove the plugin.
- Bugs: a replayed request that fails (CACHE-01), HTML that differs per visitor (CACHE-03, CACHE-06), a counter that increments during rendering (CACHE-02).
- Evidence: `<work>/var-cache.txt` with each feature's replay result and the HTML diff summary.

**`layouts`: every layout option**
- Run: for every select, radio, or checkbox setting that changes layout or markup (sidebar positions, header and footer styles, grid columns, card styles, pagination types, archive layouts), set each value in turn, and run the standard pass on the pages that setting affects: at least the home page, one archive, one single view of each kind, and every page where the setting's markup appears (a representative list of about 10–15 URLs per value is enough; list it once in the evidence file). List every setting and value you rendered.
- Bugs: errors, broken markup, or missing content for any one value. Sampling some values isn't enough.
- Evidence: `<work>/var-layouts.txt`, one line per setting and value, with its result.

**`plain`: plain permalinks**
- Run: `wp rewrite structure ''`, then the standard pass using `?p=`, `?cat=`, `?page_id=`, and `?s=` URLs in place of pretty ones, and the step 8 calls. Every link the theme outputs must work in plain form. Restore pretty permalinks with `wp rewrite structure '/%postname%/'` and confirm.
- Evidence: `<work>/var-plain.txt`.

**`subdir`: WordPress in a subdirectory**
- Run: `ln -s . <tmp>/wordpress/wp`, then `wp option update siteurl "$WP_TEST_URL/wp"` (leave `home` alone), then the standard pass, checking every link, form action, and asset the theme outputs: `site_url()` used where `home_url()` belongs, or the reverse, breaks here. Restore `siteurl`, remove the symlink, and confirm.
- Evidence: `<work>/var-subdir.txt`.

**`child`: child theme**
- Run: create a blank child theme in `<tmp>/wordpress/wp-content/themes/<slug>-child/` (`style.css` with `Template: <slug>`, an empty `functions.php`), activate it, and run the standard pass. Check that every asset loads, every template renders, and nothing reads files from the wrong folder (`get_stylesheet_directory()` where `get_template_directory()` was meant, or the reverse). Keep the child theme for step 16, but switch back to the theme.
- Evidence: `<work>/var-child.txt`.

**`rtl`: right to left**
- Run: switch the site to a right-to-left language: `wp language core install ar --activate` if the network allows (this also exercises the theme's translations); otherwise a must-use plugin that sets `$GLOBALS['wp_locale']->text_direction = 'rtl'` on `after_setup_theme` at priority 0. Setting it on `init` is too late: stylesheet direction is already decided, so a missing `rtl.css` wouldn't show. Then the standard pass, and look at the screenshots. Undo it (`wp site switch-language en_US`, or remove the plugin).
- Bugs: no `rtl.css` and no logical CSS properties, or RTL styles that break the layout.
- Evidence: `<work>/var-rtl.txt` and the screenshots.

**`long`: long strings**
- Run: add a must-use plugin that filters `gettext`, `gettext_with_context`, and `ngettext` for the theme's text domain only and makes each string about 40% longer, wrapped in markers (for example `⟦Read more·····⟧`), then the standard pass, and look at the screenshots. Remove the plugin.
- Bugs: text that overflows or overlaps; visible text the theme outputs without the markers, which isn't translatable (strings from core or plugins don't count).
- Evidence: `<work>/var-long.txt` and the screenshots.

**`roles`: user roles**
- Run: create an editor, an author, a contributor, and a subscriber; log each in with `curl` against `wp-login.php` the way `login` does, each with its own cookie jar. Have each load the admin screens it's allowed to reach, and have each role that can edit posts save a post with the theme's meta boxes.
- Bugs: errors; meta boxes that let a role save what it shouldn't (FLD-08, FLD-10); meta that silently fails to save for a role that should be able to.
- Evidence: `<work>/var-roles.txt`.

**`zones`: time zones and date formats**
- Run: set `timezone_string` to `Pacific/Kiritimati` (UTC+14), then `Pacific/Pago_Pago` (UTC−11); on each, fetch the pages that show dates, times, relative times, "new" badges, or countdowns, and compare each with `wp_date()` of the stored GMT value. Check a post scheduled 30 minutes ahead doesn't appear. Set a non-default `date_format` and `time_format` and check the theme uses them. Restore the settings.
- Evidence: `<work>/var-zones.txt`.

**`switch`: theme switch**
- Run: record the theme mods, menu locations, and `sidebars_widgets`; switch to a core default theme with `wp theme activate`, load its home page, switch back, and compare.
- Bugs: lost settings, widgets, or menu locations; errors from `switch_theme` or `after_switch_theme` handlers; content duplicated by activation code.
- Evidence: `<work>/var-switch.txt`.

**`blocks`: blocks** (only if section 1 found blocks, block styles, or block templates)
- Run: deactivate the Classic Editor plugin. Check each block is registered (`WP_Block_Type_Registry::get_instance()->get_registered( '<name>' )`). Create a probe post per block with its markup, once with every attribute set and once with none, and run the standard pass on them. Render every dynamic block with `render_block()` through `wp eval` with no attributes, every attribute, wrong-type attributes, and inner blocks, and compare each with its `ServerSideRender` preview from `/wp/v2/block-renderer/<name>` called as an editor. Check a colour or alignment set through `supports` shows in the front-end markup. For no-build blocks, confirm every `wp.*` global each script uses is in its dependency list. Check each block's style and view script load on pages that use it and not on others. Open the block editor for the probe posts with `shot`, `login-js.sh`, and `capture.js`, and look for `Block validation failed` messages; if the editor doesn't finish loading in the time `shot` waits, mark the editor check SKIPPED and compare each static block's `save()` with its `deprecated` entries by reading the code. Load the widgets screen in block mode if the theme allows it. Leave the Classic Editor plugin off for `patterns`.
- Evidence: `<work>/var-blocks.txt`.

**`patterns`: patterns** (only if the theme has patterns)
- Run: with the Classic Editor plugin off, list every registered pattern (`WP_Block_Patterns_Registry::get_instance()->get_all_registered()`) against the section 1 list; a pattern file that never registers is a bug. For each, check every block name in `parse_blocks()` is registered, render it with `do_blocks()`, and check its image URLs don't 404. Put each in its own probe page, run the standard pass on those pages, and open each in the block editor as `blocks` describes. Check synced and starter-content patterns appear where their `Block Types` and `Post Types` say. Reactivate the Classic Editor plugin and confirm with `wp plugin status classic-editor`.
- Evidence: `<work>/var-patterns.txt`.

**`rebuilt`: rebuilt assets** (only if the build step succeeded)
- Run: build a second site from the built copy (`new-site.sh <work> <work>/build/<slug>`), take the home page, one archive, and one single view at 1440 and 390 wide, and compare them with the step 11 shots. If pages show random content, compare the CSS selector sets instead. Tear that site down.
- Bugs: a visible difference means the committed files are stale or the build is broken; say which, from the build comparison.
- Evidence: `<work>/var-rebuilt.txt`.

**`plugins`: extra plugins** (only if intake question 3 named extra plugins)
- Run: activate them all together, then the standard pass and the step 8 calls. Deactivate them.
- Bugs: any error, broken layout, or feature that stops working only with those plugins active is a conflict bug; name the plugin and the file on each side.
- Evidence: `<work>/var-plugins.txt`.

**`multisite`: multisite** (last)
- Run: build a second site with `new-site.sh`, convert it with `wp core multisite-convert`, network-enable the theme, create a sub-site with `wp site create`, activate the theme there, and run step 2 and the front-end fetches on the sub-site. `php -S` has no rewrite rules, so a sub-directory sub-site's admin screens can't load: test its admin behaviour through `wp --url=<sub-site URL> eval` and mark the admin screens BLOCKED with that reason. If the conversion fails on SQLite, mark `multisite` BLOCKED with the error. Tear the site down with `site-down.sh`.
- Evidence: `<work>/var-multisite.txt`.
