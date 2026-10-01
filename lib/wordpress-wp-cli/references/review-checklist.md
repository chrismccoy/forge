# Review Checklist

Use this in review mode. Check an existing script against every item, and cite each finding by line number. Items are grouped by kind. The examples come from real scripts.

## Quick Scan (a folder of scripts)

When asked to review a folder rather than one script, map it before reading, then read every file the scans hit in full:

```bash
rg -n '\bwp [a-z0-9:-]+' . -g '*.sh' -g '*.md'                                      # every WP-CLI call
rg -n 'search-replace|db (reset|drop|query|import)|site (delete|empty)|--force|delete .*--all' . -g '*.sh'  # high-risk writes
rg -n 'wp eval|eval-file' . -g '*.sh'                                               # PHP run through eval
rg -n -- '--network|--url=|wp site ' . -g '*.sh'                                     # multisite scope
rg -n 'WP_CLI::add_command|extends WP_CLI_Command' . -g '*.php'                      # custom commands
```

The scans decide the reading order. They are never the basis for a finding.

## Bugs (the script does the wrong thing)

- [ ] **State lost in a subshell.** A variable set inside `( ... )` or a `cmd | while read` loop is used afterwards. *Example: `( IFS=,; id_string="${ids[*]}" )` leaves `id_string` empty, and under `set -u` the script crashes.*
- [ ] **`continue`/`break` inside a subshell** within a loop. It doesn't skip the iteration. *Example: `continue` inside `( cd "$wp_path"; ... )`.*
- [ ] **Totals counted in a subshell** always print 0.
- [ ] **`$?` checked after another command.** *Example: `id=$(wp media import ...); rm "$tmp"; if [ $? -eq 0 ]` tests the `rm`.*
- [ ] **A flag that can never be turned off.** *Example: `DRY_RUN=1` by default and `--dry-run` sets it to 1 again, with no way to set 0.*
- [ ] **`sed` with `+` and no `-E`.** *Example: `sed 's/[^a-z0-9]+/-/g'` never replaces spaces, so slugs come out broken.*
- [ ] **`curl` without `-f`.** An HTTP error page is saved and imported as if it were the file.
- [ ] **A numeric test on empty output.** *Example: `[ "$(... | jq length)" -gt 0 ]` errors when WP-CLI fails and prints nothing.*
- [ ] **`set -e` with a fleet loop.** One broken site aborts every site after it.
- [ ] **`((x++))` under `set -e`** exits when `x` is 0.
- [ ] **The comment and the behaviour disagree.** *Example: the header says "moves to trash" but the code runs `--force`.*
- [ ] **A progress message printed after the step it announces.**
- [ ] **Two `trap ... EXIT` lines.** The second replaces the first, so the lock or temp cleanup never runs.

## Safety (the script could do damage)

- [ ] A destructive or outward-facing action (delete, update, option write, commit, push) runs without dry-run as the default.
- [ ] A read-only script (an audit, list, check, or report) that writes anything, even a "harmless" cleanup. A name like `audit-*` or `list-*` promises no changes.
- [ ] A change that is never verified (no read-back after the write).
- [ ] Multisite scope left implicit: a site-specific command with no `--url` on a network, `--network` used without saying why, or `wp search-replace` on a network with no decision about `--network`.
- [ ] A confirmation that accepts `y`, prompts once per site, or hangs or assumes yes in cron.
- [ ] Updates applied with no database export and no maintenance mode.
- [ ] Users deleted without `--reassign`, or with only published posts counted.
- [ ] Blanket URL rewrites applied to every site (forcing `https://www.`).
- [ ] Predictable temp paths (`/tmp/name_$site`), or temp files never cleaned up.
- [ ] `--allow-root` always on, rather than only when running as root.
- [ ] `git add .`, pushing without checking for an upstream, or pushing by default.

## Robustness (it works until something unusual happens)

- [ ] A hardcoded home path (`/home/<user>/...`) or a relative default (`webapps`).
- [ ] Help text defaults that don't match the code.
- [ ] `find` for `wp-config.php` with no depth limit and no exclusions (it picks up backups, staging copies, `node_modules`).
- [ ] Treating `wp-config.php` existing as proof of a working install (no `wp core is-installed` check).
- [ ] Parsing table output (`tail -n +2`, `awk -F,` on a table) instead of `--field`, `--format=ids`, or JSON.
- [ ] A missing dependency check for `jq`, `zip`, `curl`, `mail`, or `git`.
- [ ] Unquoted expansions and paths that break on spaces (`for f in $(find ...)`).
- [ ] WP-CLI errors thrown away with `2>/dev/null` when the error is exactly what the user needs to see.
- [ ] A long job with no progress output (no batch or per-site lines), which looks hung.
- [ ] A calls-per-item loop (`wp user get` plus `wp post list` for every user) that boots WP-CLI thousands of times. Batch it, or suggest a custom command (see `areas/custom-commands.md`).
- [ ] Recurring logic in a long `wp eval` string. Suggest a custom command.
- [ ] No summary, a summary that can be lost on Ctrl-C, or an associative-array summary in random order.
- [ ] An exit code of 0 even when sites failed.

## Style (house conventions)

- [ ] `echo` with colour variables but no `-e`, which prints raw escape codes.
- [ ] Emoji in log output.
- [ ] Logging to stdout where it mixes with data output.
- [ ] Colours printed to a pipe or file.
- [ ] Two near-identical scripts (single-site and whole-fleet copies). Merge them with `-s SITE`.
- [ ] Unused variables or temp folders (`TMP_DIR` created, never used).
- [ ] shellcheck warnings.

## Severity

Tag every finding with one severity:
- **CRITICAL:** can lose or corrupt data, or change the wrong thing. Examples: a destructive or network-wide action with no dry run or confirmation, wrong multisite scope, `search-replace` with no dry run or no backup, deleting users with content, a subshell bug that makes a delete run on the wrong set, a push by default.
- **WARNING:** the script breaks, misleads, or can't be trusted. Examples: a bug that crashes or reports wrong totals, `set -e` killing a fleet loop, no verification, ambiguous targeting, hidden writes in a report, no batching or progress on a long job.
- **INFO:** style and polish. Examples: emoji, colours in pipes, unused variables, duplicated scripts, missing help text.

## Reporting Findings

List findings most severe first. Each one gets:
1. Severity: `CRITICAL`, `WARNING`, or `INFO`
2. `file:line`, with the quoted code
3. The operational risk, in one sentence: what goes wrong, and on how many sites
4. Why it happens (the bash or WP-CLI behaviour behind it)
5. The fix: the safer pattern, as code

Then list the fixes that change behaviour the user will notice (a new default dry run, a renamed flag, a changed default path), because those need their agreement.

If nothing is found, say so plainly, then name any remaining gaps, such as no rollback notes, no log file for cron runs, or no verification step.
