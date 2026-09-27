# Content: Posts, Galleries, Imports, Multisite Sites

## Commands

- Create: `wp post create --post_title=... --post_status=draft --porcelain` prints the new ID. For long or multi-line content, write it to a temp file and pass the file as the first argument (`wp post create "$tmpfile" --post_title=...`), rather than using `--post_content=` with shell quoting.
- Update: `wp post update <id> --post_content=...` (or with a file).
- Media: `wp media import <url-or-file> --post_id=<id> --title=... --porcelain` prints the attachment ID. Add `--featured_image` to set it as the featured image in the same call, rather than writing `_thumbnail_id` meta by hand.
- Lists: `wp post list --post_type=<type> --post_status=publish --format=ids|count` or `--field=url`.
- Public post types: `wp post-type list --public=1 --field=name` (never parse a CSV with awk).
- Multisite: `wp site create --slug=<slug> --title=... --email=...`. Check for an existing slug first by listing (`wp site list --field=url`) and matching the path, because core WP-CLI has no `wp site exists` subcommand.

## Rules

- **New posts are drafts by default.** Publishing is an explicit option (`-p` / `--publish`).
- **Editor-aware content.** Check which editor the post type uses before writing markup (see `settings.md`, Editor Detection). The classic editor gets shortcodes (`[gallery ids="1,2,3"]`, `[video src=... poster=...]`). The block editor gets block markup (`<!-- wp:gallery -->` with inner `wp:image` blocks, `<!-- wp:video {"id":N} -->`).
- **Imports from a list file.** Skip blank lines and `#` comments, and trim whitespace. Validate each URL (`^https?://`) before trying it. A failed import is a warning, not a stop. If nothing was imported, create no post.
- **Slugs.** Build them with `sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'` after lowercasing. Reject an empty result. Check for duplicates before creating.
- **Idempotency.** A rerun must not create duplicates. Record a source marker as post meta (for example `_source_url`) and skip items that already have one.
- **Third-party APIs** (such as a video metadata service): name them in the header, check the response code and every field you use, and fail cleanly if the shape changes. Downloads follow the External Downloads rules in `safety.md`.
- Print the new post's edit link (`wp post get <id> --field=url`, plus the admin edit URL built from `wp option get siteurl`) and its status at the end.

## Traps Seen in Real Scripts

- Building a comma list inside `( ... )` and using it outside, which leaves it empty. Use `local IFS=,` inside a function, or `printf -v`.
- Removing the temp file before checking the import's exit status.
- Slug `sed` without `-E`.
