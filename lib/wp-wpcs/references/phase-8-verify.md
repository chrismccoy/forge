# Phase 8: Final verification

Goal: proof that the converted plugin behaves exactly like the baseline, on a fresh site and on a site that ran the old version.

Work in this order, so the tagged commit is the one that was tested: write the README section and commit it, run the static and flow checks with the gate, run the smoke test, run the upgrade test, remove the mock, tag. The tag waits on all of them, the smoke and upgrade tests included.

## Which PHP every live check runs on

Run the real flows, the smoke test and the upgrade test on the floor binary, with the baseline on that same binary, and not only the test suite: bugs that exist only on old PHP never show on a newer one.
- Prove the binary for each run: `php -v`, `wp eval 'echo PHP_VERSION;'`, and the server's `X-Powered-By` or `/proc/<pid>/exe`. A `PATH` shim works for scripts that call `php`, but this procedure's own scripts need PHP 8.1: call them with an explicit binary. Run Composer on the local PHP with `config.platform.php` set to the floor: that setting is what selects the packages, and a system Composer may not parse on an old binary.
- Start the server with the same `-d` flags on every binary (opcache, realpath cache, memory, output buffering), since one may have no `php.ini`. Extensions can differ too: a missing GD changes core's admin output. Mask only that difference, and list the mask.
- A changed port needs `siteurl` and `home` updated in the database.
- `wp media import` needs GD or Imagick, whatever the plugin needs. If the floor binary has neither and nothing may be installed, create the attachment with `wp_insert_attachment()` through `wp eval`. Never hide a setup step's output with `>/dev/null 2>&1`, and keep `Deprecated` lines.
- **The baseline fails where the conversion works.** This is a baseline bug, not a regression: report it, and compare past it with a labelled control, a throwaway copy of the baseline with only that line changed. Code that a dead gate makes unreachable on both versions (for example a `REST_REQUEST` check at `init`) gets the same treatment: a labelled control on each version, such as a mu-plugin in the flow site that opens the gate, so renamed code behind it still runs. The control replaces the baseline in the gate. Keep the raw baseline diff and report it.
- **The baseline can't parse on the floor** (intake lowered it). Compare baseline and `HEAD` at the lowest PHP that parses the baseline, then `HEAD` on the floor against `HEAD` on that PHP, with the same WordPress. If that lowest PHP is below the baseline's real floor, the baseline fails there too: use a control on it, and also compare the unmodified baseline with `HEAD` at the baseline's real floor. The control alone is a modified baseline.
- **The dev site's WordPress doesn't run on the floor.** A second site on an older WordPress, with the same SQLite setup, replaces the dev site for the smoke and upgrade tests. Restore step 6 then applies to that site.
- Below the floor, activation can succeed and then every request can fail. If the header has no `Requires PHP:`, report that, with the version that fails.

## Static and test checks

- `composer lint`: 0 errors and 0 warnings against `<standard>`.
- If intake chose prefixed globals: no `namespace` line outside `includes/deprecated-functions.php`. If it chose to remove `strict_types`: `git grep strict_types -- '*.php'` finds nothing.
- All tests pass. Assertion counts have not dropped without an explanation.
- Golden copies match. Generated post content is byte-identical to the baseline: compare the raw output, without the whitespace normalization the golden tests use.
- The `msgid` set matches the baseline exactly, using the command in `phase-6-lint.md`, and no baseline `translators:` comment is lost or changed.
- The class-name string tests from Phase 1 still pass with the old values.
- **No trace of the conversion** (Hard rule 8). Run `git grep -n -iE 'conver(t|sion)|migrat|refactor|flatten|psr-?[0-9]|wpcs|strict.?types|phase [0-9]|safety net|old-to-|renamed|previous(ly)? (name|namespace)' -- . ':!composer.lock' ':!composer.json' ':!package-lock.json' ':!dist'` and read every hit. Run the same command at `wpcs-v0-baseline` and compare using `git grep -h` and `sort -u` with `LC_ALL=C`, since refs and line numbers make every line differ, and strip leading whitespace with `sed 's/^[[:space:]]*//'`, since re-indenting does too. Renames and spacing still change lines, so read what remains. On a plugin with its own database migrations, drop `migrat` from the pattern and search for `migrat.*(wpcs|namespace|psr)` instead. A hit that was already there, or an unrelated one such as `convertErrorsToExceptions`, stays. Reword the rest.
- **Outward-facing names are unchanged.** Run `<skill-dir>/scripts/surface.php` on the baseline and on the current tree, and diff everything except the `literal` lines. The diff must be empty. Run these commands in bash, because they use process substitution.
  ```
  mkdir -p <scratch>/surface-v0 && git archive wpcs-v0-baseline | tar -x -C <scratch>/surface-v0
  php <skill-dir>/scripts/surface.php <scratch>/surface-v0 > <scratch>/surface-v0.txt
  php <skill-dir>/scripts/surface.php . > <scratch>/surface-head.txt
  diff <(grep -v '^literal' <scratch>/surface-v0.txt) <(grep -v '^literal' <scratch>/surface-head.txt)
  ```
  Then read the `literal` diff too (`diff <(grep '^literal' <scratch>/surface-v0.txt) <(grep '^literal' <scratch>/surface-head.txt)`): a changed name in a function `surface.php` doesn't watch shows up only there. Autoloader and class-map strings are expected. `surface.php` reads PHP only, so also check `git diff wpcs-v0-baseline HEAD -- assets/` (or wherever the plugin's JS lives). Remove `<scratch>/surface-v0` afterwards. `surface.php` shows values built from expressions as `<expr>`, so the diff can't catch a class-name string that changed. The Phase 1 tests cover those.
- **Run the tests on the PHP floor** (`<current-floor>`, which is the target if Phase 7 lowered it, and the binary Phase 7's **The floor after this phase** chose, with a WordPress version that runs on it). Use an installed binary first (`/usr/bin/php7.4`); it needs every extension the plugin requires, or the plugin's own checks stop the suite. Also run the suite on each newer installed version with the dev site's WordPress, to catch what newer PHP deprecates. Work in a copy of the plugin at the same path depth, so relative sandbox paths still resolve, and:
  1. From the repository, since a `git archive` copy has no `.git`, lint every plugin file with the floor binary: `git ls-files -z '*.php' | xargs -0 -n1 php7.4 -l > /dev/null`, which exits non-zero for the gate. A fatal here means the floor is wrong and intake missed it: tell the user, and run every live check on the lowest PHP that parses the baseline.
  2. Unless Phase 7 already locked for the floor, set `config.platform.php` to the floor and run `composer update`, because dev packages were locked on the local PHP.
  3. If the dev site's WordPress doesn't run on the floor, install an older one with the same SQLite setup, and pin `wp-phpunit` to match (`composer require --dev -W "wp-phpunit/wp-phpunit:<x>.*"`). Also run the suite once on the oldest obtainable WordPress at or above `<wp-floor>`, even if the floor's WordPress is newer: a core function newer than the header's claim shows only there.
  4. Run the suite. If a test fails only on the older WordPress, repeat with that WordPress on a newer PHP: the same failure there clears PHP. If it is a golden holding core-version output, fix its mask under the third Hard rule 2 exception.

  If no binary exists, try a container, after checking that `docker info` works: the socket is often limited to root and the `docker` group, and pass the WordPress path with `-e`. For example:
  ```
  docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/..:$PWD/.." -w "$PWD" php:<current-floor>-cli php vendor/bin/phpunit
  ```
  Mount the parent directory so a sandbox next to the plugin is reachable. The `php:*-cli` images include SQLite but not `mysqli`. For the WP test suite on MySQL, build a small image with `docker-php-ext-install mysqli`, and run it with `--network host` (or point it at the database host the sandbox uses). If no runtime for the floor is available, ask the user before installing one, and add the unverified run to the log's **Report items**.

- **Run the real flows on both versions and diff the output.** Tests only cover what they reach. Build a second sandbox site for this, and copy each version in with `git archive <ref> | tar -x -C <folder>`, into a real directory: never over a symlink to the repository. If the plugin keeps a runtime Composer autoloader, run `composer install --no-dev` in each copy. Before diffing, prove each copy really loaded by listing a callback whose code is inside the plugin folder: two broken copies produce identical output, and `has_action( 'init' )` passes with no plugin at all. Reset the site's data between versions. Run the flows on a block theme and on a classic theme, and assert that every value a flow extracts from a page (a nonce, a config key, the localized config object) is non-empty. A value missing on both versions is not a match: report that path as not run. Add a listener that dumps the public properties and methods of every object passed to a plugin hook: `surface.php` and the flows both pass a renamed public property. Run the plugin's main flows with HTTP mocked by real shapes (WP-CLI commands and real HTTP requests are ideal, including paths that end in `exit`), and save stdout and stderr. Repeat on `HEAD` and diff. Run the baseline twice first: what differs between those two runs (times, UUIDs, random keys) is what to mask. Mask every date, even one that matched (classic-editor date inputs too), collapse whitespace in markup as Phase 1 does, and sort lists with no fixed order. Compare status codes, sizes and body hashes too: a helper that hides stderr can make two failures look identical, and a fatal after `Content-Length` was sent can match a good download's size. Any difference that isn't an intended behaviour change is a regression.
- **Gate the finish.** Tag, log and deliver only after every check has passed, because a tag on a failing state looks the same as a good one. Script it, and don't rely on `set -e` alone: `diff a b && echo ok` doesn't stop the script, and neither does a failure inside a pipe or an `if`. Write each check as `if ! <check>; then echo "FAILED: <name>"; exit 1; fi`, end with `echo PASS`, and prove the gate can fail by breaking one input and running it.

## Live smoke test in the dev site

If the dev site runs on PHP's built-in server, start it with `php -d opcache.enable=0 -d realpath_cache_size=0 -S 127.0.0.1:<port> -t <wordpress-dir> <router>`. `<router>` is a small script that returns `false` for existing files and otherwise includes `index.php`, so pretty permalinks work. Without `-t`, a router that returns `false` for static files serves them from the wrong root, and scripts 404. With opcache on, a request right after a file changes can run the old code, which makes a comparison between versions meaningless. The realpath cache is worse: for two minutes after a symlink is replaced, a running server keeps loading the symlink's old target, with no error. Stop it by the PID listening on the port: `pkill -f` can match the shell running it.

1. **Block outbound HTTP and mail** with a temporary mu-plugin that hooks `pre_http_request`. A plugin fatal otherwise sends WordPress's recovery email.
   - Return canned responses for every external API the plugin, or a plugin it depends on, needs to show its screens, and an error for everything else, including core update checks.
   - Include canned **error** responses too (a timeout, a 500, a bad body), so the plugin's error paths run and store whatever they store.
   - **Prove the block works before loading any page:** `wp eval 'var_dump(wp_remote_get("https://api.wordpress.org/core/version-check/1.7/"));'` must print the mock's `WP_Error`.
   - Run each setup command on its own, or with `set -e`, so a failed step can't be skipped silently.
2. Empty `debug.log`, and write one canary line through a web request: an empty log can't be told from logging that is off.
3. Log in.
4. Load every plugin admin screen, plus `edit.php` and the dashboard, since list-table hooks run there. If the plugin outputs anything on the front end, load a page that uses it on a block theme and on a classic theme, and check it in a real browser. Run the plugin's main editor or admin feature in the browser the same way (Playwright, or whichever browser tool is available; its MCP server saves downloads and logs under the working folder, so run it from the sandbox or use a standalone script). Recent WordPress ships block themes only, so write a minimal classic one (`style.css`, and an `index.php` that calls `wp_head()`, the loop and `wp_footer()`). Classic-editor output needs a temporary `use_block_editor_for_post` filter returning false. Every script loads with status 200, localized data exists, and the feature works, or the same failure happens on the baseline. A feature that fails on both is still a dead feature: report it on its own, not as a pass. Block themes render content before `wp_head`, so unit tests don't show what these pages get. If a result contradicts what the user sees on a live site, report the exact setup tested, and don't generalize from it.
5. Call every REST route (use `?rest_route=` on plain permalinks) with the authentication it really uses (a cookie and nonce, or the plugin's own API key header), including failed authentication and any validation-failure paths. Each auth method needs one proven success: a valid and an invalid credential that both get 403 look like a passing failed-auth check. If an auth method fails on the baseline too, record it as a bug and use one that works.
6. Save the settings form, or the plugin's main edit form if it has no settings.
7. Check `debug.log` for notices, deprecations and errors whose file path is inside the plugin. Look especially for `Passing null to parameter` deprecations, which Phase 7 can turn up where strict mode used to throw. Lines from core or WP-CLI don't count; list them separately if there are many.
8. Reset any sandbox state that changed. Keep the mu-plugin for the upgrade test, then remove it.

Skip any step that doesn't apply, and add which ones to the log's **Report items**.

## Upgrade test

Tests start from a fresh database, so they never see the names WordPress saved under the old code. Here the old code is the namespaced version: stored objects carry `<Old\Namespace>\...` class names and camelCase property names. Check those on a site that ran the old version.

**Use copies only.** `wp plugin uninstall` deletes the plugin folder recursively. If that folder is a symlink to the working tree or a worktree, it can delete the repository. Step 1 replaces any symlink with a real directory. Make every copy with `git archive <ref> | tar -x -C <folder>`: it leaves out `.git`, `vendor/` and `build/`. It includes `tests/` and the dev config files, which does no harm here. If the plugin keeps a runtime Composer autoloader, run `composer install --no-dev` in each copy before activating it.

1. **Reset and install the old version.**
   - Deactivate the plugin while its folder is still in place.
   - Delete its stored data with `wp option delete`, `wp transient delete` and `wp eval`, using the option and transient names `surface.php` listed. Remove any capabilities it added to roles, and drop its custom tables too, or migrations that aren't idempotent fail on reactivation. Clear the uploads folder and delete the attachment rows too, because stale files change file names and replace paths. **Never use `wp plugin uninstall` here:** the folder may still be the symlink to the repository.
   - To clear old entries in `uninstall_plugins`, remove only the plugin's keys from that array with `wp eval`. Don't delete the whole option: core then saves a `0 => false` entry.
   - Remove the symlink (`unlink`, never `rm -r`), create a real directory in its place, and copy `wpcs-v0-baseline` into it with `git archive wpcs-v0-baseline`.
   - Restart the server, so nothing cached survives the swap. Activate the plugin. **Prove the old code is what runs:** a web request must show a loaded file from the old layout (`get_included_files()` in a temporary mu-plugin, or the old code's known behaviour). Do the same after step 3 for the new layout. If it uses `register_uninstall_hook()`, check that `uninstall_plugins` now holds the old callback, with its namespaced class name.
2. **Store data with the old code.** Save the settings through the real form, with non-default values, and run whatever writes options, meta or transients, especially anything that stores objects. Keep the HTTP mock active. If the old code can't parse on the floor, do steps 1 and 2 on the lowest PHP that parses it, then switch the server and WP-CLI to the floor binary at step 3 and prove the switch.
3. **Update without deactivating.** Replace the folder's contents with a copy of `HEAD` from `git archive HEAD`, the way an update does. Empty `debug.log`, and write a canary line through a web request.
4. **Use, then uninstall.** Load every plugin admin screen and call one REST route. If aliases exist, check old names with `instanceof` in a fresh process. Read back every stored object with `wp eval`, and check that it comes back as the new class with its property values intact, not as `__PHP_Incomplete_Class` and not with empty properties. Then run `wp plugin deactivate <plugin-slug>` and `wp plugin uninstall <plugin-slug>`.
5. **Judge.** The test passes when the stored objects read back correctly and the uninstall cleanup really ran (the options, transients or tables it should remove are gone). `debug.log` must have no fatal error, `__PHP_Incomplete_Class`, dynamic-property deprecation or plugin warning. If something is left behind, run the same uninstall on the baseline code. If the baseline leaves the same data, the gap predates the migration: add it to the log's **Report items**; don't fix it.
6. **Restore.** The uninstall deleted the copied folder. Put the dev site's plugin folder back as Phase 0 set it up (recreate the symlink if there was one), and reactivate the plugin.

With several plugins in one folder, run steps 4 and 5 for each plugin in turn. Uninstalling one plugin deletes the shared folder and the other plugin's files with it, so copy the current tree in again before uninstalling the next one.

If the plugin has no `register_uninstall_hook()` and stores no plugin objects, still run all six steps once as a basic update check, and add that to the log's **Report items**. Cleanup in `uninstall.php` counts as a basic update check.

## README

Do this first, as the order above says. Update the **Development** section of the plugin's `README.md` (any capitalization, such as `readme.md`), creating the section or the file if it's missing. Replace any text about PSR-12, PSR-4 or `src/`. Never put it in `readme.txt`: that file is published on wordpress.org. Cover:
- the `includes/` layout, the class and file naming, and the classmap autoloader (add new classes to the map)
- `composer test`, `composer lint`, `composer lint:fix`, and which standard the ruleset uses
- how to regenerate the golden files
- any compatibility aliases: stored-name aliases must stay; released-name aliases stay until users have had time to move
- why some names keep camelCase (the reasoned `phpcs:ignore` list), if any do

Regenerate the `.pot` before committing: later phases shift its line references. If the plugin has a release script, run it only in a clone, because it may delete `build/` or other untracked files (Hard rule 6). Say why if it can't run, and check that the paths it names exist.

## Finish

Remove the HTTP mock mu-plugin, stop every server this run started, then tag `wpcs-v8-verified` on the tested commit. Ask whether to copy the finished plugin somewhere. Never overwrite the original: clone into a new folder so the tags come along, and add the log. Update `WPCS_MIGRATION_LOG.md`, then write the final report.

## Final report

Build it from `WPCS_MIGRATION_LOG.md`, not from memory. Report the following:
- the intake answers, and which phases they skipped
- the before and after violation counts, by ruleset (Core, Extra, Docs; mark any standard intake didn't choose as not in scope). The project ruleset reaches 0; a plain `--standard` run doesn't once ruleset scoping applies, so give that count as well, for plugin code and with `tests/` separately, and name every whole-file exclude behind it
- the list of commits and tags
- every place behaviour changed: the error paths opened by removing `strict_types`, and every Phase 6 swap
- every `phpcs:ignore` and why it's there, grouped by sniff
- every name kept unrenamed: public names of objects passed to hooks, overrides, built-in interface methods, external properties, stored or output property names, and names built at runtime
- every compatibility alias or wrapper kept for stored names and for released old names, what they don't cover (`phase-4-flatten.md`), and the result of the upgrade test
- renamed public methods with no wrapper (if intake said "released")
- every class-name string replaced with its old literal (Hard rule 1)
- every test changed under a Hard rule 2 exception
- what could not be verified (for example, no runtime for the PHP floor)
- safety-net tests that were skipped or replaced, and known gaps (Phase 1)
- smoke or upgrade test steps that were skipped, and gaps that predate the migration
- every other entry in the **Report items** section of the log
- anything the user needs to decide
