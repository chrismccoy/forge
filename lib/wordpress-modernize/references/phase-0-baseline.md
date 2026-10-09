# Phase 0: Baseline

Goal: a git repository with a `v0-baseline` tag on code whose test suite is known to pass, before any refactor.

Order matters: set up git, build the environment, run the tests, and only then tag.

## Git

- If the folder is not a git repo, run `git init`. Keep personal and editor files out of the history with `.git/info/exclude`: scratch notes, `*.swp`, and `MIGRATION_LOG.md`. Project build output that every developer has (`vendor/`, `build/`) goes in `.gitignore`. Commit everything else, but don't tag yet.
- If the repo already exists and the working tree is clean, add `MIGRATION_LOG.md` to `.git/info/exclude`; don't commit.
- If the tree is dirty, stop and ask the user.
- Create `MIGRATION_LOG.md` with an empty **Report items** section.

## Test environment

- Install the dev dependencies, if there are any. Build whatever test environment the plugin uses: wp-env, a sandbox script, or the WP test suite.
- If the plugin has none and one gets written (for example `bin/sandbox.sh`), keep it uncommitted until Phase 1. A new `composer.lock` and any new environment script get committed in Phase 1, not in the baseline.
- If the environment links the working tree into the dev site's plugins folder with a symlink, note it in `MIGRATION_LOG.md`. Never run `wp plugin uninstall` or `wp plugin delete` against that site while the symlink is in place: either command deletes the folder it points to, which is the repository. See the upgrade test in `phase-7-verify.md`.
- If the environment runs a local web server, use a port that nothing else is listening on (check with `ss -ltn`), make the port configurable, and stop the server at the end of each phase. Never send requests to a site this run didn't start.

## Green before any refactor, then tag

Run the full suite with `--log-junit build/junit-v0-baseline.xml`. Don't trust an old `.phpunit.result.cache`; run the suite.

- If the tests pass, tag the current commit `v0-baseline`.
- If tests fail for reasons other than environment setup, stop and report them. Don't change code or tests before `v0-baseline`.

If there are no tests:
- if intake said "No tests, build the safety net from scratch", tag the current commit `v0-baseline` and go on to Phase 1. Tell the user that the Phase 1 net is the minimum and may not be enough, and add that to the log's **Report items**.
- otherwise, stop and tell the user.

Update `MIGRATION_LOG.md` and go on to Phase 1.
