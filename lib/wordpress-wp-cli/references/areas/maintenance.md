# Maintenance: Cron, Cache, Transients, Rewrites, Database

## Inspect First (read-only)

- Environment: `wp cli info` (PHP binary, WP-CLI version, config paths) and `wp core version`.
- Cron: `wp cron test` checks that WordPress can spawn cron over HTTP. `wp cron event list --fields=hook,next_run_relative,recurrence` lists events. Find overdue events by checking `next_run_gmt` against the current time. Check whether `DISABLE_WP_CRON` is set with `wp config get DISABLE_WP_CRON`, which means a system cron should be calling `wp cron event run --due-now`.
- Object cache: `wp cache type` shows which backend is in use (Default, Redis, Memcached, and so on).
- Transients: `wp transient list --format=count` (WP-CLI 2.5+), and expired ones with `wp transient list --expired`, where available.
- Database: `wp db size --tables --format=json`, and `wp db check`.

## Changing Things

- **Cron:** `wp cron event run --due-now` runs overdue events. Deleting an event (`wp cron event delete <hook>`) is a write. Dry run and confirm it like any deletion, and never delete core hooks (`wp_version_check`, `wp_update_plugins`, `wp_scheduled_delete`, and so on).
- **Cache:** `wp cache flush` empties the **whole object cache backend**. With Redis or Memcached shared between sites, that flushes every site using it. Only do it with `-f`, and name the backend from `wp cache type` in the dry run. Prefer flushing one group (`wp cache flush-group <group>`, where the backend supports it) or deleting known keys.
- **Transients:** `wp transient delete --expired` is the safe default. `--all` also removes live transients, which some plugins rebuild slowly. Make it opt-in. On multisite, add `--network` for site transients.
- **Rewrite rules:** `wp rewrite flush` (add `--hard` only if the server config should be rewritten too). This is cheap but a write, so it still needs `-f`.
- **Database:** `wp db optimize` locks tables on MyISAM, so run it off-peak and say so. `wp db repair` only when `wp db check` reports errors. Always `wp db export` first.

## Rules

- Maintenance scripts that only report (cron health, cache type, database size) are read-only and named `check-*` or `report-*`.
- A combined "maintenance" script runs its steps in a fixed order (inspect, export, act, verify), each step can be turned off with a flag, and the summary shows each step's result per site.
- On multisite, cron and transients are per-site. Loop over subsites with `--url` (see `fleet.md`), except for network transients.
- Verify after acting: count transients again, list due cron events again, and run `wp db check` again.
