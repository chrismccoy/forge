#!/usr/bin/env bash
# Tear a test site down completely: run its teardown, then stop any `php -S` process still serving its folder
# (teardown only stops the server it last started, and a server started twice leaves the first one running).
#
# Usage: site-down.sh <tmp>
#
# Output (stdout), one line: "site-down: <tmp> removed" or "site-down: <tmp> is already gone" (both exit 0).
# Exit 2 with a stderr line when <tmp> isn't a wp-test-* folder once symlinks and .. are resolved (nothing is
# touched); exit 1 with a stderr line when the folder is still there afterwards. Anything bin/teardown prints is
# discarded.

set -uo pipefail

# Only folders made by setup-test-site.sh (mktemp wp-test-XXXXXX) are ever deleted.
readonly SITE_DIR_GLOB='wp-test-*'
# Seconds between asking servers to stop and killing them.
readonly STOP_GRACE_SECONDS=1

tmp="${1:?usage: site-down.sh <tmp>}"
[[ -d "$tmp" ]] || { printf 'site-down: %s is already gone\n' "$tmp"; exit 0; }
# The folder as given (the server's command line uses it) and its real path (what is checked and deleted), so
# "<site>/../<other>" or a symlink can never point the rm at anything but a test site.
given="${tmp%/}"
tmp="$(cd "$tmp" && pwd -P)" || { printf 'site-down: cannot resolve %s\n' "$given" >&2; exit 2; }
# shellcheck disable=SC2053  # Glob match intended.
[[ "$(basename "$tmp")" == $SITE_DIR_GLOB ]] || { printf 'site-down: %s is not a test site folder\n' "$given" >&2; exit 2; }

# regex_escape <text>: the text with ERE metacharacters escaped, for pgrep -f.
regex_escape() {
	# shellcheck disable=SC2001,SC2016  # A bracket class is clearer in sed than in ${//}; $ is literal.
	sed 's/[][\.|$(){}?+*^]/\\&/g' <<< "$1"
}

# server_pids <site>: pids of `php -S 127.0.0.1:<port> -t <site>/wordpress` processes, one per line.
server_pids() {
	pgrep -f -- "-S 127\.0\.0\.1:[0-9]+ -t $(regex_escape "${1%/}")/wordpress" || true
}

# all_server_pids: server pids for the folder as given and as its real path, one per line, no duplicates.
all_server_pids() {
	{ server_pids "$given"; server_pids "$tmp"; } | sort -u
}

"$tmp/bin/teardown" >/dev/null 2>&1 || true

mapfile -t pids < <(all_server_pids)
if [[ ${#pids[@]} -gt 0 ]]; then
	kill "${pids[@]}" 2>/dev/null || true
	sleep "$STOP_GRACE_SECONDS"
	mapfile -t pids < <(all_server_pids)
	[[ ${#pids[@]} -gt 0 ]] && kill -9 "${pids[@]}" 2>/dev/null
fi
[[ -d "$tmp" ]] && rm -rf -- "$tmp"
[[ -d "$tmp" ]] && { printf 'site-down: could not remove %s\n' "$tmp" >&2; exit 1; }
printf 'site-down: %s removed\n' "$given"
