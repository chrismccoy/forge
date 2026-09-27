# Safety Rules

These scripts run against real sites, often many at once. Every rule here exists because getting it wrong loses data on many sites in one run.

## Dry Run by Default

- Any script that changes data (deletes, updates options, runs updates, writes files, commits, pushes) is a **dry run unless `-f` is given**. The dry run does every read and prints exactly what it would change, site by site, with real counts and old -> new values.
- Every path that changes data checks the apply flag. No write happens in dry-run mode, including "harmless" ones such as emptying the trash.
- Pure reports and audits (listing plugins, counting media) have no `-f`, because they change nothing.

## Inspect, Back Up, Dry Run, Apply, Verify

Every script that changes data runs in these stages, and the summary shows which ones ran:
1. **Inspect:** read the current state (counts, values, versions).
2. **Back up:** export whatever the change can destroy (see Updates, and Backups and Archives), when the task calls for it.
3. **Dry run:** print exactly what would change.
4. **Apply:** only with `-f`.
5. **Verify:** read the state again with a read-only command and confirm it matches what was intended. Examples: `option get` after `option update`, a count after a delete, `core version` after an update, `wp core is-installed` plus an HTTP check after any update. A site whose check fails is reported as `FAILED (not verified)`, not as changed.

## Read-Only Scripts

A script that audits, lists, checks, or reports never writes: no options, no meta, no trash-emptying, no cache flushes, no `.part` cleanup. Its name says so (`audit-*`, `list-*`, `check-*`, `report-*`). Names for scripts that change things say what they change (`purge-*`, `update-*`, `set-*`, `backup-*`). Never mix the two: an audit that finds problems prints them, and a separate script (or `-f`) fixes them.

## Confirmation

- With `-f`, before the first change, print how many sites and what will happen. Require the user to type `yes` (not `y`).
- `-y` skips the prompt, for cron. With `-f` and no `-y`, and no terminal (`[[ -t 0 ]]` fails), refuse and exit 1 rather than hang or assume yes.
- Never confirm once per site in a fleet run. Confirm once, up front.

## Destructive Operations

- **Say exactly what happens.** "Delete" in a comment or log means permanent removal (`--force`). "Trash" means moving to trash. The header comment, log lines, and summary must all match what the command really does.
- **Trash before permanent delete** where WordPress has a trash (posts, comments). Permanent deletion is its own explicit option or the script's stated purpose.
- **Mass deletion** (all media, all comments in a range, users) shows the count per site in the dry run and the grand total before the confirmation.
- **Users:** never delete a user who has content without `--reassign=<id>`. Never delete administrators. Check `--post_type=any` counts across all post statuses, not just published.
- **Large ID lists:** delete in batches (for example 500 IDs per `wp ... delete` call) to stay under the shell's argument limit.

## Updates

Before applying core, plugin, or theme updates with `-f`:
1. Offer a database export first (`wp db export` to `BACKUP_DIR`, named `<site>-<timestamp>.sql`), on by default, off with an explicit flag.
2. Update with `wp maintenance-mode activate` around core updates, and always deactivate it in a trap.
3. After updating, check the site still answers: run `wp core is-installed` and fetch the home URL with `curl -fsS -o /dev/null`. Report any site that fails as FAILED, with the backup file name.
4. Never use `--all` when the user asked for a named plugin or theme.

## Backups and Archives

- Write to a temporary `.part` file and move it into place only after an integrity check (`zip -T`, `gzip -t`). Clean up stale `.part` files from earlier runs.
- Write a `.sha256` beside each archive.
- Retention pruning (`-k N`) only touches files matching this script's own naming pattern, and obeys dry-run.

## Git

- Commit and push only with `-f`. The dry run lists each repository, the files that would be committed, and the branch.
- Never push without a configured upstream. Report "no upstream" and skip.
- Never `git add -A` or `git add .`. Add the exact paths the task is about.
- Never force-push, rebase, reset, or stash.
- Fetching is a network call. Allow skipping it with a flag.

## Multisite Scope

On a network, every command's scope is decided and stated: this site only (the default), one named site (`--url=<site>`), or every site (`--network`, or a loop over `wp site list`). Network-wide changes print the subsite count in the dry run, and need that count repeated in the confirmation text. See `fleet.md`.

## URLs and Search-Replace

- Changing `siteurl`/`home` is per-site and explicit. Never apply a blanket rule (like forcing `https://www.`) to every site. Skip subdomains, IP addresses, `localhost`, and `.test`/`.local` hosts unless told otherwise.
- Content URL changes use `wp search-replace` with `--dry-run` first, `--precise`, `--skip-columns=guid`, and `--report-changed-only`, and only after a database export.
- On multisite, `wp search-replace` only touches the current site's tables unless `--network` is given. Choose deliberately, and say which in the dry run.
- Narrow the tables where the change is known to live (`wp_posts wp_postmeta wp_options`). All tables is a choice, not a default.
- `--regex` is much slower and easy to get wrong. Use it only when a plain string can't express the change, and say why.

## External Downloads

- `curl -fsSL --max-time N` so HTTP errors fail instead of saving an error page as the file.
- Check the downloaded file's type (`file --mime-type`) and size before importing it.
- Download into a `mktemp -d` folder, removed in the EXIT trap.
- Name any third-party API the script depends on in the header, because it can change or disappear.

## Never

- Never read or print `wp-config.php` secrets (DB passwords, salts, keys).
- Never run `wp db query` with a destructive statement, `wp db reset`, or `wp site empty` unless that is the script's stated purpose, and then only under the dry-run and confirmation rules.
- Never test a script against the user's live sites. See the Testing section in `SKILL.md`.
