# Site Settings: Visibility, URLs, Editor Detection

## Commands

- Options: `wp option get <name>`, `wp option update <name> <value>`.
- Search engine visibility: option `blog_public` (`0` means discourage search engines).
- URLs: options `siteurl` and `home`. Also check `WP_HOME`/`WP_SITEURL` with `wp config get WP_HOME` (constants override options, so updating the option alone does nothing).
- Content URLs: `wp search-replace <old> <new> <tables...> --dry-run --precise --skip-columns=guid --report-changed-only`. On multisite, add `--network` only when every subsite should change, and say which in the dry run. Without it, only the current site's tables change.
- Multisite per-site settings: `wp option get <name> --url=<site>`, looping over `wp site list --field=url`.

## Rules

- **Read, compare, then write.** Show current -> target per site. Write only when they differ. Report "unchanged" otherwise.
- **URL normalisation is rule-based and explicit.** The user gives the rule (for example https on, www on, www off). Skip hosts it shouldn't touch: subdomains other than `www`, IP addresses, `localhost`, and `.test`, `.local`, and `.localhost` domains. If `WP_HOME` or `WP_SITEURL` is defined, report it and don't change the option.
- Changing `siteurl`/`home` doesn't change links in content. Mention `wp search-replace` in the summary, but don't run it unless asked. It's a separate step with its own database export and dry run.

## Editor Detection

A reusable function for scripts that write post content:
1. `wp plugin is-active classic-editor` means the classic editor is used (the plugin's own setting can still allow the block editor per user; mention that).
2. Otherwise `wp eval "echo (int) apply_filters( 'use_block_editor_for_post_type', true, '<type>' );"`. A result of 0 means classic for that type.
3. Plugins and themes must be **loaded** for this check (no `--skip-plugins` / `--skip-themes`), because the filters live in them.

Report per public post type. Scripts that create content call this once and choose shortcodes or block markup from the result.

## Traps Seen in Real Scripts

- Forcing `https://www.` onto every site, including subdomains and local installs.
- `echo` with a colour variable and no `-e`, which prints the raw escape code.
- Error logs written to predictable `/tmp/wp_err_<site>.log` paths. Use `mktemp`, or capture stderr into a variable.
