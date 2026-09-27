# Media: Audits, Cleanup, Imports

## Commands

- Count: `wp post list --post_type=attachment --post_status=inherit --format=count`.
- Unattached: `wp post list --post_type=attachment --post_parent=0 --format=ids`.
- Delete: `wp post delete <ids> --force` deletes the attachment and its files. Core WP-CLI's `media` commands are `import`, `regenerate`, `image-size` and `fix-orientation`. There is no `wp media delete`, unless a package adds it (check `wp help media`).
- Regenerate thumbnails: `wp media regenerate --yes --only-missing` (plugins and themes must be loaded, so their image sizes register).
- Sizes: `wp media image-size --format=json`.
- Disk use: `du -sh "$(wp_run "$p" eval 'echo wp_upload_dir()["basedir"];')"`.

## Rules

- **Audits** report per site: attachment count, unattached count, and uploads folder size. Sort by site name and end with totals. They change nothing, so they have no `-f`.
- **Deleting all media** is the most destructive task in the collection. It needs the dry run's per-site counts, a typed `yes`, and a line telling the user to export the database and back up `wp-content/uploads` first. Offer to delete only unattached media instead.
- **Batch deletions** (500 IDs per call).
- **Orphan files** (files in uploads with no attachment) are a separate audit. Never delete them from a script without an explicit option and a dry run listing the paths.

## Traps Seen in Real Scripts

- A relative `SEARCH_DIR="webapps"`, which scans nothing, or the wrong place, depending on where you run the script.
- Calling a WP-CLI subcommand that doesn't exist. Check `wp help <command>` before using one.
