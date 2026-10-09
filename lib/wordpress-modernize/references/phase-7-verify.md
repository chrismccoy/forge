# Phase 7: Final verification

Goal: proof that the converted plugin behaves exactly like the baseline, on a fresh site and on a site that ran the old version.

## Static and test checks

- `composer lint`: 0 errors and 0 warnings.
- All tests pass. Assertion counts have not dropped without an explanation.
- Golden copies match. Generated post content is byte-identical to the baseline: compare the raw output, without the whitespace normalization the golden tests use.
- The `msgid` set matches the baseline exactly.
- **Outward-facing names are unchanged.** Run `<skill-dir>/scripts/surface.php` on the baseline and on the current tree, and diff everything except the `literal` lines. The diff must be empty. Run these commands in bash, because they use process substitution.
  ```
  mkdir -p build/surface-v0 && git archive v0-baseline | tar -x -C build/surface-v0
  php <skill-dir>/scripts/surface.php build/surface-v0 > build/surface-v0.txt
  php <skill-dir>/scripts/surface.php . > build/surface-head.txt
  diff <(grep -v '^literal' build/surface-v0.txt) <(grep -v '^literal' build/surface-head.txt)
  ```
  `<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-modernize`. Remove `build/surface-v0` afterwards.
- **Run the tests on PHP 8.1.** If the local PHP is newer, try a container, for example:
  ```
  docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/..:$PWD/.." -w "$PWD" php:8.1-cli php vendor/bin/phpunit
  ```
  Mount the parent directory so a sandbox next to the plugin is reachable. The `php:8.1-cli` image includes SQLite but not `mysqli`. For the WP test suite on MySQL, build a small image with `docker-php-ext-install mysqli`, and run it with `--network host` (or point it at the database host the sandbox uses). If no 8.1 runtime is available, ask the user before installing one, and add the unverified 8.1 run to the log's **Report items**.

## Live smoke test in the dev site

1. **Block outbound HTTP** with a temporary mu-plugin that hooks `pre_http_request`.
   - Return canned responses for every external API the plugin, or a plugin it depends on, needs to show its screens, and an error for everything else, including core update checks.
   - Include canned **error** responses too (a timeout, a 500, a bad body), so the plugin's error paths run and store whatever they store.
   - **Prove the block works before loading any page:** `wp eval 'var_dump(wp_remote_get("https://api.wordpress.org/core/version-check/1.7/"));'` must print the mock's `WP_Error`.
   - Run each setup command on its own, or with `set -e`, so a failed step can't be skipped silently.
2. Empty `debug.log`.
3. Log in.
4. Load every plugin admin screen, plus `edit.php` and the dashboard, since list-table hooks run there.
5. Call every REST route with the authentication it really uses (a cookie and nonce, or the plugin's own API key header), including failed authentication and any validation-failure paths.
6. Save the settings form, or the plugin's main edit form if it has no settings.
7. Check `debug.log` for notices, deprecations and TypeErrors whose file path is inside the plugin. Lines from core or WP-CLI don't count; list them separately if there are many.
8. Reset any sandbox state that changed. Keep the mu-plugin for the upgrade test, then remove it.

Skip any step that doesn't apply, and add which ones to the log's **Report items**.

## Upgrade test

Tests start from a fresh database, so they never see the names WordPress saved under the old code. Check those names on a site that ran the old version.

**Use copies only.** `wp plugin uninstall` deletes the plugin folder recursively. If that folder is a symlink to the working tree or a worktree, it can delete the repository. Step 1 replaces any symlink with a real directory. Make every copy with `git archive <ref> | tar -x -C <folder>`: it leaves out `.git`, `vendor/` and `build/`. If the plugin keeps a runtime Composer autoloader, run `composer install --no-dev` in each copy before activating it.

1. **Reset and install the old version.**
   - Deactivate the plugin while its folder is still in place.
   - Delete its stored data with `wp option delete`, `wp transient delete` and `wp eval`, using the option and transient names `surface.php` listed. **Never use `wp plugin uninstall` here:** the folder may still be the symlink to the repository.
   - To clear old entries in `uninstall_plugins`, remove only the plugin's keys from that array with `wp eval`. Don't delete the whole option: core then saves a `0 => false` entry.
   - Remove the symlink (`unlink`, never `rm -r`), create a real directory in its place, and copy `v0-baseline` into it with `git archive v0-baseline`.
   - Activate the plugin. If it uses `register_uninstall_hook()`, check that `uninstall_plugins` now holds the old callback.
2. **Store data with the old code.** Save the settings, and run whatever writes options, meta or transients, especially anything that stores objects. Keep the HTTP mock active.
3. **Update without deactivating.** Replace the folder's contents with a copy of `HEAD` from `git archive HEAD`, the way an update does. Empty `debug.log`.
4. **Use, then uninstall.** Load every plugin admin screen and call one REST route. Then run `wp plugin deactivate <plugin-slug>` and `wp plugin uninstall <plugin-slug>`.
5. **Judge.** The test passes when the uninstall cleanup really ran (the options, transients or tables it should remove are gone), and `debug.log` has no fatal error, `__PHP_Incomplete_Class` or plugin warning. If something is left behind, run the same uninstall on the baseline code. If the baseline leaves the same data, the gap predates the migration: add it to the log's **Report items**; don't fix it.
6. **Restore.** The uninstall deleted the copied folder. Put the dev site's plugin folder back as it was before step 1, and reactivate the plugin.

With several plugins in one folder, run steps 4 and 5 for each plugin in turn. Uninstalling one plugin deletes the shared folder and the other plugin's files with it, so copy the current tree in again before uninstalling the next one.

If the plugin has no `register_uninstall_hook()` and stores no plugin objects, still run all six steps once as a basic update check, and add that to the log's **Report items**. Cleanup in `uninstall.php` counts as a basic update check.

## README

Add a **Development** section to the plugin's `README.md`, creating the file if it's missing. Never put it in `readme.txt`: that file is published on wordpress.org. Cover:
- the layout and the autoloader
- `composer test`, `composer lint`, `composer lint:fix`
- how to regenerate the golden files
- why test methods keep snake_case
- JS and CSS staying on the WordPress standards

## Finish

Remove the HTTP mock mu-plugin, stop every server this run started, then commit and tag `v7-verified`. Update `MIGRATION_LOG.md`, then write the final report described in `SKILL.md`, including every entry in the log's **Report items**.
