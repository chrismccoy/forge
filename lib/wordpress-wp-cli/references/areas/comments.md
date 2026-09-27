# Comments: Spam, Pending, Date-Range Cleanup

## Commands

- Count: `wp comment list --status=<spam|hold|trash|approve> --format=count`.
- IDs: `wp comment list --status=... --format=ids`.
- Date range: `wp comment list --date_query='{"after":"2024-01-01 00:00:00","before":"2024-01-31 23:59:59","inclusive":true}' --format=ids`. Build the JSON with `jq -n` or `printf`, never by hand-escaping quotes.
- Trash: `wp comment trash <ids>`. Permanent: `wp comment delete <ids> --force`.
- Spam: `wp comment spam <ids>`. Empty the trash: `wp comment delete $(wp comment list --status=trash --format=ids) --force`.

## Rules

- **Say which it is.** Pending (`hold`) comments may be real people. Trash them by default. Permanent deletion of pending comments is an explicit option. Spam and trash may be deleted permanently.
- **Dry run first**, with per-site counts for each status, then the grand total before confirming.
- **Batch large ID lists** (500 per call) to stay under the argument limit.
- **Comment counts:** WordPress updates each post's comment count when its comments are deleted. If counts look wrong afterwards, `wp comment recount <post-ids>` fixes them.
- **Dates:** check both dates are real (`date -d "$d" +%F` must round-trip) and that start <= end.
- **One script, two scopes:** date-range deletion is one script with `-s SITE` for a single install. It is never a single-site copy and a bulk copy.

## Traps Seen in Real Scripts

- `continue` inside a `( cd ...; ... )` subshell, and totals counted inside it that always come out 0.
- A header saying "moves to trash" over code that runs `--force`.
- `set -e` plus a fleet loop, where one broken site stops the rest.
