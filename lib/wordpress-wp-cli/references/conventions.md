# House Style

Every script follows these rules. `examples/skeleton.sh` shows all of them working together. Start new scripts from it.

## File and Header

- Bash, starting with `#!/usr/bin/env bash`. File name in kebab-case, ending `.sh`, describing the task and its side effect (`wp-comment-purge.sh`, not `script2.sh`). Read-only scripts start `audit-`, `list-`, `check-`, or `report-`, and scripts that change things name the change (`purge-`, `update-`, `set-`, `backup-`). See Read-Only Scripts in `safety.md`. Make it executable.
- A header comment: the name, one line on what it does, a `Usage:` block listing every option with its default and env var, and the exit codes. `-h` prints this block (`sed -n '<first>,<last>p' "$0"`). Keep the line range in `usage()` in step with the header.
- `readonly PROG="${0##*/}"`, plus `readonly VERSION="x.y.z"` and a `-V` flag if the script is meant to be versioned.

## Strict Mode

- `set -euo pipefail` by default.
- Drop `-e` (keep `-uo pipefail`) only when the script traps signals to print a partial summary, and say why in a comment. Then check every command that matters explicitly with `if` or `||`.
- Inside a site loop, one site's failure must never end the run. The per-site function returns a status, and the loop records it. Never `exit` from per-site code.

## Configuration

- Settings the user may change sit at the top, each overridable by an env var: `SITES_ROOT="${SITES_ROOT:-$HOME/webapps}"`, `BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"`, `MAX_DEPTH="${MAX_DEPTH:-2}"`, `WP_CLI="${WP_CLI:-wp}"`.
- Never a hardcoded home path (`/home/<user>/...`) and never a relative default (`webapps`), which silently depends on the directory the script is run from. Resolve roots to absolute paths once, at startup.
- Help text defaults must match the code's defaults.

## Arguments

- `getopts` with short options. Fleet scripts share these letters, so they behave the same everywhere:

| Flag | Meaning |
|---|---|
| `-r DIR` | sites root |
| `-s SITE` | one site only: a folder name under the root, or a path |
| `-m N` | max depth for finding `wp-config.php` |
| `-f` | apply changes (the script is a dry run without it) |
| `-y` | skip the confirmation (only with `-f`) |
| `-q` | quiet |
| `-h` | help |
| `-V` | version |

- Task-specific options use other letters.
- Positional arguments are for required inputs only (a URL file, a date range). Validate each one: count, format (dates with `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` plus `date -d`), and that files exist and are readable.
- Reject unknown options and unexpected positional arguments with usage and exit 1. Numeric options are checked with `^[0-9]+$`.
- Running with no arguments does the safe default (a dry run or a report). It never prints usage and quits when every argument has a default.

## Preflight

Check every external command before doing any work, with one `require_cmd` helper: `wp` (through `$WP_CLI`), and `jq`, `zip`, `unzip`, `curl`, `git`, or `mail` only if the script uses them. Each message says what is missing and how to get it.

## Output

- Logging helpers (`log`, `ok`, `warn`, `die`) write to **stderr**, so stdout stays clean for data a user might pipe (a list of URLs, CSV).
- Colours only when stdout is a terminal and `NO_COLOR` is unset. Use `$'\033[...]'` strings, so `printf '%s'` works without `echo -e`. Never `echo` a colour variable without `-e`.
- No emoji in log lines. A cron mail or a log file should read cleanly.
- Every fleet script ends with a summary: a table of site and status, then one totals line. In a dry run it says so plainly and names the flag that applies the change.
- Scripts that produce data (lists, audits) offer `--format`-style output only if asked. The default is a readable table.

## Exit Codes

- `0`: everything succeeded (or there was nothing to do).
- `1`: usage, preflight, or setup error. Nothing was processed.
- `2`: the run finished, but one or more sites failed or were skipped for an error.

## Bash Hygiene

- Quote every expansion (`"$var"`, `"${arr[@]}"`). The one exception is an ID list passed to `wp ... delete $ids`, with a `# shellcheck disable=SC2086` comment saying why.
- `local` for function variables. Declare and assign on separate lines when the assignment is a command substitution whose status matters (`local out; out=$(...)`).
- Counters use `x=$((x + 1))`, never `((x++))`, which returns status 1 when `x` is 0 and kills the script under `set -e`.
- Never keep state you need later inside a `( ... )` subshell or a `cmd | while read` loop. Both run in a child shell, and their variables vanish. Loop with `while ... done < <(cmd)` or `mapfile -t arr < <(cmd)`.
- `continue` and `break` only directly inside a loop, never inside a subshell within one.
- Check `$?` only on the line right after the command, or better, use `if cmd; then`. Any command in between (`rm`, `echo`) replaces it.
- A numeric test on command output checks the value first: `[[ "$n" =~ ^[0-9]+$ ]] || n=0`.
- `sed` with `+`, `?`, `|`, or `{}` needs `-E`. Without it, `+` is a literal character.
- Temporary files and folders come from `mktemp` / `mktemp -d` and are removed in the EXIT trap. Never use predictable `/tmp/name_$site` paths.
- `find ... -print0` with `while IFS= read -r -d ''` whenever paths may contain spaces.
- Every script passes `bash -n` and `shellcheck` with no warnings. Any `# shellcheck disable=` names the rule and gives the reason.
