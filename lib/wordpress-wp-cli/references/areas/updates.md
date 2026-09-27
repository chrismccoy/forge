# Updates, Integrity, Inventory

## Commands

- Core: `wp core check-update --format=json` prints a JSON list of available versions, and prints **no JSON** (just a success message) when the site is up to date. Check the exit status first, then treat output that isn't a JSON array as "no updates". Also `wp core update` and `wp core update-db`.
- Plugins: `wp plugin list --update=available --format=json --fields=name,version,update_version`, `wp plugin update <names...>` or `--all`.
- Themes: `wp theme list --update=available ...`, `wp theme update ...`.
- Integrity: `wp core verify-checksums` and `wp plugin verify-checksums --all` (plugins from WordPress.org only; report others as "not verifiable").
- Inventory: `wp plugin list --format=json --fields=name,status,version,update`.

## Rules

- **Checking is the default.** Applying needs `-f`, a typed `yes`, and the steps in `safety.md` (Updates): database export, maintenance mode for core, and a health check afterwards.
- `-c`, `-p`, `-t` pick core, plugins, and themes. None of them means all three.
- **Named updates:** `-P plugin1,plugin2` updates only those. Never fall back to `--all`.
- Record before and after versions per site in the summary.
- **Inventory reports** can pivot: per site (which plugins are on this site), or per plugin (which sites run this plugin, at which versions). The second view is the useful one for "where is plugin X installed" and "which sites run an outdated X".
- **Checksum reports** list the modified and added files per site, not just pass or fail. Optionally write them to a log (`-l FILE`) and email it (`-e ADDRESS`).

## Traps Seen in Real Scripts

- `[ "$(... | jq length)" -gt 0 ]` fails when WP-CLI prints nothing, which `core check-update` does whenever the site is up to date. Check the value is a number, and default to 0.
- Listing the same data twice (a table call plus a JSON call). Call once with JSON and format it yourself.
- Printing usage and quitting when run with no arguments, although every argument has a default.
