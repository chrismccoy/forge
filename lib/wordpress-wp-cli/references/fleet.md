# Working Across Many Sites

Most of these scripts run the same task on every WordPress install under one folder. This is how to find them, talk to each one, and report back. `examples/skeleton.sh` implements all of it.

## Finding Installs

- Search `SITES_ROOT` for `wp-config.php` to a limited depth (`-m`, default 2). Unlimited depth finds staging copies, backups, and plugin test fixtures.
- Skip anything under `node_modules/`, `vendor/`, `.git/`, and folders named `backup*` below the sites root (prune by folder name, so a sites root that is itself called `backup*` still works).
- Sort shallowest first, and treat each `wp-config.php`'s folder as the install root.
- `-s SITE` narrows the run to one install: a folder name under the root, or an absolute path. The single-site and whole-fleet versions of a task are **one script**, never two copies.
- `wp-config.php` may sit one level above the WordPress files (a supported WordPress layout). If `wp-settings.php` isn't beside it, look one level down for the real root, or skip it with a clear message.

## Checking It Is WordPress

A `wp-config.php` file isn't proof. Before doing anything, run `wp core is-installed` on each install. If it fails (not installed, or a broken database connection), record the site as `SKIPPED (not installed / DB error)` and move on.

## The `wp_run` Wrapper

Every WP-CLI call goes through one function:

```bash
wp_run() {
  local wp_path="$1"; shift
  local -a flags=(--path="$wp_path" --no-color --quiet)
  (( EUID == 0 )) && flags+=(--allow-root)
  "$WP_CLI" "$@" "${flags[@]}"
}
```

- `--path` on every call. Never `cd` into the site in a subshell to run `wp`, which hides state from the loop.
- `--allow-root` only when actually running as root. Adding it always hides a real permissions mistake.
- Add `--skip-plugins --skip-themes` for tasks that only read or write core data (options, core checksums, user and comment lists, theme paths), because it's faster and survives a broken plugin. **Leave plugins and themes loaded** when the result depends on them: filters (`apply_filters` in `wp eval`), custom post types and taxonomies, `wp post list` on a custom post type, `wp media regenerate`, and anything that fires hooks.
- Keep stderr visible for calls whose failure you report. Capture it with `2>&1` into a variable, or let it reach the terminal. Send it to `/dev/null` only for probe calls whose failure is itself the answer (`core is-installed`, `plugin is-active`).
- Prefer machine formats and fields: `--format=ids`, `--format=count`, `--format=json` with `jq`, `--field=name`, `--porcelain` for new IDs. Never parse WP-CLI's table output (`tail -n +2`, `awk` on columns). Use `--field=<name>` for one value per line, or `--format=json` with `jq` for several fields.

## Multisite

- Detect it with `wp_run "$path" core is-installed --network` (or by checking `MULTISITE` with `wp config get`).
- **Scope is always explicit** on a network. Pick one and say it in the dry run:
  - **Main site only:** no `--url`. WP-CLI acts on the main site.
  - **One subsite:** `--url=<site url>`.
  - **Every subsite:** loop over `wp site list --field=url` (add `--archived=0 --deleted=0 --spam=0` to skip inactive ones) and pass `--url="$url"` each time. Commands that are network-wide by nature (`wp plugin activate --network`, `wp search-replace --network`, `wp super-admin`) use `--network` instead, and never also loop.
- Discover before changing: list the subsites (`wp site list --fields=blog_id,url`) in the dry run, so the user sees what "every site" means.
- Say in the summary whether a site is a network, and how many subsites were processed.

## The Site Loop

```bash
for wp_path in "${installs[@]}"; do
  (( INTERRUPTED )) && break
  rc=0
  process_site "$wp_path" || rc=$?
  # tally rc: 0 changed, 3 nothing to do, anything else failed
done
```

- `process_site` returns a status and records one summary row. It never exits the script.
- The EXIT trap prints the summary, including after Ctrl-C (marked "partial results"), so an interrupted run still shows what it did.
- A lock (`mkdir` of a lock folder keyed on `SITES_ROOT`) stops two runs of the same script on the same root at once. The EXIT trap removes it. Only one `trap ... EXIT` may exist, because a second replaces the first.

## Progress on Long Jobs

A run that takes more than a few seconds must show that it is moving:
- One line per site as it starts (`[3/41] alpha`), unless `-q`.
- For batched work inside a site, one line per batch with running totals (`[alpha] batch 4/12: 2000/5832 comments`).
- Progress goes to stderr, like all log lines, and never replaces the final summary.

## Summary and Exit

The summary is a table of every site processed with its status (`changed`, `would change`, `unchanged`, `SKIPPED (reason)`, `FAILED (reason)`), then one totals line. Exit 2 if any site failed or was skipped for an error, or the run was interrupted. See `conventions.md` for exit codes.

## Reports by Email or Log

When a script supports `-l FILE` (log) or `-e ADDRESS` (mail):
- Write the log with the same summary format.
- Mail it only after the run finishes.
- Check that `mail` exists during preflight.
- Never mail the log without writing it first.
