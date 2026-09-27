# Backups: Theme, Database, Uploads

## What to Back Up

- **Theme:** the active theme folder, plus the parent theme for child themes (skip it with `-P`). Exclude `.git/`, `node_modules/`, and `.DS_Store`.
- **Database:** `wp db export <file> --add-drop-table` (gzip it afterwards, or pipe it: `wp db export - | gzip > file.sql.gz`).
- **Uploads:** the uploads folder (from `wp_upload_dir()['basedir']`). It's large, so it's opt-in.

## Rules

- One script covers one site (`-s SITE`) or the whole fleet. Never keep two copies.
- **Naming:** `<site>-<what>-<slug>-<YYYYmmdd-HHMMSS>.<ext>` in `BACKUP_DIR`, so retention can match on the prefix.
- **Atomic writes:** write `.<name>.part`, test it (`zip -T`, `gzip -t`), then `mv` it into place. On startup, remove stale `.part` files from earlier runs (obeying dry run).
- Write a `.sha256` file beside every archive.
- **Retention:** `-k N` keeps the newest N per site and slug. `0` keeps all. Pruning obeys dry run.
- A lock stops overlapping runs (backups often run from cron).
- The summary lists site, item, and result (`OK <file>`, `SKIPPED (reason)`, `FAILED (reason)`), plus totals and the backup folder.
- **Restore notes:** the script's header says how to restore each kind (unzip into `wp-content/themes/`, `wp db import`).

## Traps Seen in Real Scripts

- Help text defaults (`/var/www`, `/var/backups/...`) that don't match the code's defaults.
- A `TMP_DIR` created and removed but never used.
- A near-identical single-site copy of the fleet script.
