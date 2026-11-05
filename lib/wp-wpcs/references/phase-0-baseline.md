# Phase 0: Baseline

Goal: a git repository with a `wpcs-v0-baseline` tag on code whose test suite is known to pass, before any refactor.

Order matters: set up git, build the environment, run the tests, and only then tag.

## Git

- If the folder is not a git repo, run `git init`. Built assets the plugin loads (`dist/`) stay committed, or `git archive` copies lack them. Keep personal and editor files out of the history with `.git/info/exclude`: scratch notes, `*.swp`, and `WPCS_MIGRATION_LOG.md`. Project build output that every developer has (`vendor/`, `node_modules/`, `build/`, `.phpunit.result.cache`) goes in `.gitignore`. Commit everything else, but don't tag yet.
- If the repo already exists and the working tree is clean, add `WPCS_MIGRATION_LOG.md` to `.git/info/exclude`; don't commit.
- If the tree is dirty, stop and ask the user.
- If tags or a `MIGRATION_LOG.md` from an earlier `/wp-modernize` run exist, leave them untouched. Note in the new log which forward tags exist and whether the forward log has an old-to-new name map.
- Create `WPCS_MIGRATION_LOG.md` with an empty **Report items** section.

## Test environment

- Install the dev dependencies, if there are any. Build whatever test environment the plugin uses: wp-env, a sandbox script, or the WP test suite.
- **Throwaway WordPress on SQLite.** The test suite, WP-CLI and the smoke test all run without a database server. Download WordPress and the SQLite Database Integration plugin, and install its `db.copy` as `wp-content/db.php`, replacing `{SQLITE_IMPLEMENTATION_FOLDER_PATH}` with the plugin's folder and `{SQLITE_PLUGIN}` with `sqlite-database-integration/load.php`. Define `DB_DIR` and `DB_FILE` in `wp-config.php`. Give the test suite its own `DB_FILE`, because it drops all tables on every run.
- After `wp core install`, read back `wp option get siteurl` and `home`, and correct them with `wp option update` if they differ from the URL the server uses. If WP-CLI floods stderr with deprecations on a new PHP, filter them in a small `wp` wrapper (`2> >(grep -v Deprecated >&2)`): `php -d` settings don't stop them, because `WP_DEBUG` resets error reporting.
- **WP test suite on SQLite.** Write a `wp-tests-config.php` that sets `ABSPATH`, `WP_TESTS_DOMAIN`, `WP_TESTS_EMAIL`, `WP_TESTS_TITLE`, `WP_PHP_BINARY`, the `DB_*` constants and the test `DB_FILE`, and point `WP_PHPUNIT__TESTS_CONFIG` at it before the bootstrap loads wp-phpunit. Make the WordPress path an environment variable, so the suite runs from any checkout, and say so in the README.
- Install the plugin in the dev site, as a copy (Recommended) or a symlink, and note which: the Phase 8 smoke test and restore step use it.
- If the plugin has none and one gets written (for example `bin/sandbox.sh`), keep it uncommitted until Phase 1. A new `composer.lock` and any new environment script get committed in Phase 1, not in the baseline.
- If the environment links the working tree into the dev site's plugins folder with a symlink, note it in `WPCS_MIGRATION_LOG.md`. Never run `wp plugin uninstall` or `wp plugin delete` against that site while the symlink is in place: either command deletes the folder it points to, which is the repository. See the upgrade test in `phase-8-verify.md`.
- If the environment runs a local web server, use a port that nothing else is listening on (check with `ss -ltn`), make the port configurable, and stop the server at the end of each phase. Never send requests to a site this run didn't start.

## Green before any refactor, then tag

Run the full suite with `--log-junit <scratch>/junit-wpcs-v0-baseline.xml`. Don't trust an old `.phpunit.result.cache`; run the suite.

- If the tests pass, tag the current commit `wpcs-v0-baseline`.
- If tests fail for reasons other than environment setup, stop and report them. Don't change code or tests before `wpcs-v0-baseline`.

If there are no tests:
- if intake said "No tests, build the safety net from scratch", tag the current commit `wpcs-v0-baseline` and go on to Phase 1. Tell the user that the Phase 1 net is the minimum and may not be enough, and add that to the log's **Report items**.
- otherwise, stop and tell the user.

Update `WPCS_MIGRATION_LOG.md` and go on to Phase 1.
