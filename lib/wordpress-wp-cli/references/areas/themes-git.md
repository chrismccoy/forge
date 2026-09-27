# Themes and Git: Audits and Commits

## Finding the Theme

- Active theme: `wp eval 'echo get_stylesheet();'`. Parent (for child themes): `wp eval 'echo get_template();'`. They differ only for child themes.
- Folder: `wp theme path <slug> --dir`. Fall back to `wp-content/themes/<slug>` with a warning.
- Use `--skip-plugins` (plugins aren't needed). Leave themes loaded, or the active-theme functions still work from options. Either is fine here.

## Git Audit Checks (per theme repository)

- Is it a repository at all (`git -C "$dir" rev-parse --is-inside-work-tree`)?
- Uncommitted changes: `git -C "$dir" status --porcelain`, split into modified and untracked counts.
- Upstream: `git -C "$dir" rev-parse --abbrev-ref '@{u}'`. None means "no upstream".
- Ahead or behind: `git -C "$dir" rev-list --left-right --count 'HEAD...@{u}'`, after an optional `git fetch --quiet` (skip it with `-F`, and give fetch a timeout).
- Size: `git -C "$dir" ls-files | wc -l` for committed file count.
- Current branch: `git -C "$dir" branch --show-current`.

Use `git -C`, never `cd`/`pushd` in the loop. The report groups themes by state: problems first, then not in git, then clean.

## Committing and Pushing

- Dry run by default. It lists each repository, the exact paths that would be committed, the branch, and whether an upstream exists.
- Add only the named paths (`git -C "$dir" add -- README.md`). Commit with the message the user gives (`-M "message"`), with a sensible default.
- Push only with `-f`, only to the configured upstream, never with `--force`. Report push failures per repository.
- Never commit files the user didn't name, and never touch other uncommitted changes.

## Traps Seen in Real Scripts

- Three separate audit scripts that each run the same theme lookup. One audit script with report sections (status, sizes, not-in-git) replaces them all.
- Committing and pushing by default, with dry run as the opt-in.
