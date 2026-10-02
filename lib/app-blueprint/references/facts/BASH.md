# BASH facts
Covers: bash (GNU bash 5.x, macOS bash 3.2), cron, systemd timers, flock, curl, ssh, rsync
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Error handling

### SH-01 `set -e` is ignored in many contexts
- Trap: "The script runs with `set -e`, so any failing command aborts the run."
- Reality: bash does not exit on a failure in a `while`/`until` condition, an `if`/`elif` test, a `&&`/`||` list (except after the final operator), a non-last pipeline stage, or a `!`-negated command. A function called in such a context (`if myfunc; then`) runs its whole body with `-e` ignored.
- Detect: `set -e` as the whole error strategy; `if do_backup; then`, `step || log failed`.
- Fix: Check exit codes explicitly where it matters (`cmd || die`); do not rely on `-e` inside functions called as conditions.
- Source: GNU bash manual, The Set Builtin - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html

### SH-02 A pipeline's status is its last command
- Trap: `pg_dump db | zstd > db.zst` or `curl ... | jq ...` fails the job when the first command fails.
- Reality: Without `pipefail` a pipeline's status is the last command's, so a failed `pg_dump` or `curl` before a successful `zstd`/`jq` counts as success and `set -e` does not fire.
- Detect: backup, export or API pipelines with `|` and no `set -o pipefail`.
- Fix: `set -o pipefail`; inspect `PIPESTATUS` when the failing stage matters.
- Source: GNU bash manual, Pipelines - https://www.gnu.org/software/bash/manual/html_node/Pipelines.html

### SH-03 Command substitution loses the failure
- Trap: Under `set -e`, `local out=$(cmd)` stops the script when `cmd` fails.
- Reality: Command substitution subshells do not inherit `-e` unless `shopt -s inherit_errexit` (bash 4.4+) or posix mode. `local`/`declare`/`export` return their own status (0 unless the name is invalid or readonly), which masks the substituted command's failure.
- Detect: `local var=$(...)`, `export X=$(...)`, multi-command `$( ... )` blocks.
- Fix: Declare and assign separately (`local out; out=$(cmd) || die`), and set `shopt -s inherit_errexit` on bash 4.4+.
- Source: GNU bash manual, The Shopt Builtin - https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html

## Scheduling

### SH-04 cron is not your login shell
- Trap: A script that works in a terminal works unchanged from cron.
- Reality: cron runs the line with `/bin/sh`, sets only SHELL, LOGNAME, HOME and a default PATH, and reads no profile or `.bashrc`. Crontab variable lines are not expanded (`PATH=$HOME/bin:$PATH` fails). Output is mailed to the owner or MAILTO.
- Detect: bare names of tools in `/usr/local/bin` or `~/bin`, reliance on exported variables, bash syntax in the crontab line, no log redirection.
- Fix: Set PATH in the script, call a script with a bash shebang, and redirect output to a log.
- Source: crontab(5) - https://man7.org/linux/man-pages/man5/crontab.5.html

### SH-05 crontab lines have their own syntax traps
- Trap: `0 2 * * * backup.sh > log-$(date +%F)` works, and `0 3 1-7 * 1` means "first Monday of the month".
- Reality: An unescaped `%` in the command becomes a newline and the rest is sent as stdin, so the first line runs truncated. When both day-of-month and day-of-week are restricted, cron runs when either matches: the second line fires on days 1-7 and every Monday.
- Detect: `date +%...` or `printf` formats in a crontab line; "first/last <weekday> of the month" in one line.
- Fix: Escape `\%` or move logic into the script. Restrict one day field and test the other in the command, or use systemd `OnCalendar=Mon *-*-01..07` (weekday and date are ANDed).
- Source: crontab(5) - https://man7.org/linux/man-pages/man5/crontab.5.html ; systemd.time(7) - https://man7.org/linux/man-pages/man7/systemd.time.7.html

### SH-06 cron starts overlapping runs
- Trap: A long job every 15 minutes "just won't overlap" or is guarded by a PID file.
- Reality: cron starts each run regardless of earlier ones. `flock -n` fails at once if the lock is held (exit 1, or `-E` code), and the lock dies with the process, unlike PID files. A systemd timer does not start a second instance while the service is still active.
- Detect: frequent cron jobs (rsync, backups, API syncs) with no lock or a hand-rolled PID file.
- Fix: `flock -n /run/lock/job.lock /path/job.sh` (or `exec 9>lockfile; flock -n 9 || exit`), or use a systemd timer.
- Source: flock(1) - https://man7.org/linux/man-pages/man1/flock.1.html ; systemd.timer(5) - https://man7.org/linux/man-pages/man5/systemd.timer.5.html

### SH-07 Missed runs are not caught up by default
- Trap: A nightly job on a host that was powered off or rebooting "runs when it comes back".
- Reality: cron does not run jobs missed while the machine was down. systemd timers catch up only with `Persistent=true`, which defaults to false and only applies to `OnCalendar=` timers. A timer-started service gets a clean environment and a fixed PATH (`/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin`).
- Detect: daily or weekly jobs on hosts that may be down at the scheduled time; `.timer` units without `Persistent=`.
- Fix: For systemd, set `Persistent=true` (optionally `RandomizedDelaySec=`). For cron, make the job idempotent and check a last-run stamp.
- Source: systemd.timer(5) - https://man7.org/linux/man-pages/man5/systemd.timer.5.html ; systemd.exec(5) - https://man7.org/linux/man-pages/man5/systemd.exec.5.html

## Remote calls and transfers

### SH-08 curl succeeds on HTTP errors and never times out
- Trap: `curl -s "$API" > data.json && process` stops on a 404/500, and a hung server fails the job.
- Reality: Without `-f/--fail` curl exits 0 on HTTP 4xx/5xx. `--fail` returns 22 but is not fail-safe (401/407 can slip through); `--fail-with-body` (7.76+) keeps the body. There is no default overall timeout, and `--retry` defaults to 0 and only retries transient errors (timeouts, HTTP 408, 429, 500, 502, 503, 504).
- Detect: curl in scripts without `--fail`/`--fail-with-body`, without `--max-time`, or "retries on failure" with no `--retry`.
- Fix: `curl --fail-with-body --silent --show-error --max-time N --retry N`, and check `-w '%{http_code}'` where 401 matters.
- Source: curl(1) - https://curl.se/docs/manpage.html

### SH-09 ssh in a loop eats stdin and may prompt
- Trap: `while read host; do ssh "$host" uptime; done < hosts.txt` runs on every host, unattended.
- Reality: ssh reads stdin, so the first call consumes the rest of the list. `-n` redirects stdin from /dev/null. Without `BatchMode=yes` ssh can block on password or host-key prompts. ssh exits with the remote command's status, or 255 on its own errors.
- Detect: ssh inside `while read` loops; unattended ssh without BatchMode; every non-zero exit treated as a remote failure.
- Fix: `ssh -n -o BatchMode=yes -o StrictHostKeyChecking=accept-new` (or a managed known_hosts), and handle 255 separately.
- Source: ssh(1) - https://man7.org/linux/man-pages/man1/ssh.1.html ; ssh_config(5) - https://man7.org/linux/man-pages/man5/ssh_config.5.html

### SH-10 `rsync --delete` mirrors exactly what you point it at
- Trap: `rsync -a --delete src dest/` and `rsync -a --delete src/* dest/` are equivalent to `src/ dest/`.
- Reality: A trailing slash on the source copies its contents; without it rsync creates `dest/src`. `--delete` only acts on directories being synchronized, so shell-expanded `src/*` deletes nothing at the top level. An empty source (an unmounted mount point) is not an I/O error, so `--delete` empties the destination. Exit 24 means source files vanished mid-transfer.
- Detect: `--delete` with inconsistent slashes or wildcards, mounted sources with no mount check, exit 24 treated as fatal.
- Fix: Use `src/ dest/` consistently, check that the source is mounted and non-empty, add `--max-delete`, run `--dry-run` first, and decide whether 24 is acceptable.
- Source: rsync(1) - https://download.samba.org/pub/rsync/rsync.1

## Portability

### SH-11 macOS ships bash 3.2
- Trap: One script targets Linux servers and macOS laptops with `#!/bin/bash` and bash 4+ features.
- Reality: macOS `/bin/bash` is bash 3.2 (zsh is the default login shell since 10.15). Associative arrays (`declare -A`), `mapfile`, `${var,,}` and `globstar` need bash 4.0, `wait -n` needs 4.3, and `inherit_errexit` needs 4.4.
- Detect: "runs on macOS and Linux" with `declare -A`, `mapfile`, `readarray`, `${var,,}` or `wait -n`.
- Fix: Require a Homebrew bash via `#!/usr/bin/env bash` plus a version check (`BASH_VERSINFO`), or stay within bash 3.2 features.
- Source: Bash NEWS - https://cgit.git.savannah.gnu.org/cgit/bash.git/plain/NEWS ; Apple bash source (bash-3.2) - https://github.com/apple-oss-distributions/bash
