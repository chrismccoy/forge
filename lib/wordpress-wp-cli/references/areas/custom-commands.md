# Custom WP-CLI Commands (PHP)

A bash script that calls `wp` once per item boots WordPress once per call. At a few thousand items that takes minutes, and complex logic in bash (or in a long `wp eval` string) is hard to review. A small custom command runs inside one WordPress boot and can use WordPress APIs directly.

## When to Suggest One

Suggest a custom command, and write it only if the user agrees, when:
- The script makes 2 or more `wp` calls per item (per user, per post, or per order).
- The logic needs WordPress functions that bash can only reach through `wp eval` (querying with conditions, computing values, calling a plugin's API).
- The same `wp eval` snippet would be reused, or is more than a line or two.

Keep bash for looping over sites. The bash fleet script calls the custom command once per site: `wp_run "$path" <prefix> <command> --dry-run`.

## Where It Lives

- A single-file must-use plugin (`wp-content/mu-plugins/<prefix>-cli.php`) is loaded on every site, but only when `WP_CLI` is defined.
- Or pass the file per run with `wp --require=<file> <command>`, which installs nothing on the site. For a fleet, this is usually the better choice, and the bash script passes `--require` through `wp_run`.

## Rules

- Start with `if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) { return; }`.
- Use a class extending `WP_CLI_Command`, registered with `WP_CLI::add_command( '<prefix> <verb-noun>', ... )`. The name says what it does and whether it writes (`<prefix> audit-users` never writes, and `<prefix> purge-users` does).
- Write a full docblock synopsis: `## OPTIONS` for every argument, with defaults, and `## EXAMPLES` including a `--dry-run` example. WP-CLI turns this into `wp help` and uses it to validate arguments.
- Validate every argument before touching data, and `WP_CLI::error()` on bad input.
- Commands that change data support `--dry-run`. The dry run counts exactly what it would change, and reports that count.
- Batch with `'fields' => 'ids'` and `'no_found_rows' => true`, logging each batch. When the command deletes the items it queries, re-query the first page every time rather than paging, because deleting shifts the pages.
- Use WordPress APIs (`wp_delete_user()` with a reassign ID, `wp_trash_comment()`), not raw SQL.
- End with `WP_CLI::success()` and the counts. Use `WP_CLI\Utils\format_items()` for tables, so `--format=json` works too.
- Lint with `php -l`. If the user points at a throwaway test install, run it there with `--require=<file>`, as a dry run first and then for real, and confirm both counts match (see Testing in `SKILL.md`).

See `examples/custom-command.php` for a complete example.
