# Users: Purges and Audits

## Commands

- List: `wp user list --role=<role> --field=ID` (or `--format=json --fields=ID,user_login,user_registered`).
- Posts by a user across all types and statuses: `wp post list --author=<id> --post_type=any --post_status=any --format=count`. Note that `any` excludes trash and auto-draft, which is the right count here.
- Comments by a user: `wp comment list --user_id=<id> --format=count`.
- Delete: `wp user delete <id> --yes`, or `--reassign=<id>` when the user has content.
- Multisite: `wp user delete` on a network removes the user from one site only. Use `--network` to delete from the whole network.

## Rules

- **Target role is required and checked** against `wp role list --field=role`. It is never `administrator`: refuse outright.
- **Content check** counts posts of any type and status, plus comments. A user with any content is skipped, or reassigned only if `--reassign` is given.
- **Optional filters:** registered before a date (`user_registered`), and no login since (only if a last-login meta key is known on these sites).
- **Dry run by default, with `-f` to apply.** The dry run lists every user it would delete (ID, login, registered date), per site.
- Delete in batches (IDs in one `wp user delete` call).

## Traps Seen in Real Scripts

- `DRY_RUN=1` hardcoded, with a `--dry-run` flag that also sets 1, so the script can never delete.
- Per-user `wp user get` plus `wp post list` calls. That's 2 WP-CLI boots per user, which is very slow on big sites. Get counts in one `wp eval` or one JSON list per site.
