#!/usr/bin/env bash
# Fetch one URL from the test site, save the body, and print one summary line:
#   <status> <label> errors=<n> critical=<0|1> bytes=<n> <url>
# errors counts PHP warning, notice, deprecation, and fatal lines in the HTML; critical is 1 when WordPress printed
# "There has been a critical error" (a fatal can keep a 200 or 404 status, so never rely on the status alone).
#
# Usage: fetch.sh <tmp> <out-dir> <label> <path-or-url> [extra curl arguments...]
# Pass -b <tmp>/jar for a logged-in request.
#
# Caveats:
#   - Exits 0 with the summary line whenever a request was attempted; a connection failure shows as status 000
#     with bytes=0. Exits 1 with one stderr line and no stdout when <path-or-url> is a path and <tmp>/env.sh
#     doesn't define WP_TEST_URL.
#   - The body is saved as <out-dir>/<label>.html, so <label> must be a plain file name.

set -uo pipefail

# PHP error lines as PHP prints them in HTML (display_errors wraps the level in <b>).
readonly PHP_ERROR_PATTERN='(Warning|Notice|Deprecated|Fatal error)(</b>)?: .* on line'
# WordPress's fatal-error handler page; shown even when the status stays 200 or 404.
readonly CRITICAL_ERROR_TEXT='There has been a critical error'
# Sent by default so WordPress serves what a browser gets (the classic editor only loads TinyMCE for browser user
# agents); pass your own -A after the other arguments to override it.
readonly BROWSER_USER_AGENT='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36'
# Seconds before curl gives up on one request.
readonly FETCH_TIMEOUT=60
# curl's %{http_code} when no response arrived; also used when curl printed nothing.
readonly NO_RESPONSE_STATUS='000'

tmp="${1:?usage: fetch.sh <tmp> <out-dir> <label> <path-or-url> [curl args]}"
out_dir="${2:?out dir}"
label="${3:?label}"
target="${4:?path or url}"
shift 4

# resolve_url <path-or-url>: absolute URLs pass through; paths are joined to the test site's base URL.
resolve_url() {
	local target="$1"
	case "$target" in
		http*) printf '%s' "$target" ;;
		*)
			[[ -n "${WP_TEST_URL:-}" ]] || { printf 'fetch: WP_TEST_URL not set by %s/env.sh\n' "$tmp" >&2; return 1; }
			printf '%s%s' "$WP_TEST_URL" "$target"
			;;
	esac
}

# count_php_errors <file>: number of PHP error lines in the file, 0 when it's missing or unreadable.
count_php_errors() {
	local count
	count="$(grep -cE "$PHP_ERROR_PATTERN" "$1" 2>/dev/null)"
	printf '%s' "${count:-0}"
}

# has_critical_error <file>: prints 1 when WordPress's critical-error page is in the file, else 0.
has_critical_error() {
	if grep -qF "$CRITICAL_ERROR_TEXT" "$1" 2>/dev/null; then
		printf '1'
	else
		printf '0'
	fi
}

# byte_count <file>: size in bytes, 0 when the file is missing (curl writes nothing when it can't connect).
byte_count() {
	local bytes=0
	[[ -f "$1" ]] && bytes="$(wc -c < "$1")"
	printf '%s' "${bytes//[[:space:]]/}"
}

# shellcheck source=/dev/null
[[ -f "$tmp/env.sh" ]] && source "$tmp/env.sh"
url="$(resolve_url "$target")" || exit 1
mkdir -p "$out_dir"
out="$out_dir/$label.html"

status="$(curl -s -o "$out" -w '%{http_code}' --max-time "$FETCH_TIMEOUT" -A "$BROWSER_USER_AGENT" "$@" "$url")"
[[ "$status" =~ ^[0-9]{3}$ ]] || status="$NO_RESPONSE_STATUS"

printf '%s %s errors=%s critical=%s bytes=%s %s\n' \
	"$status" "$label" "$(count_php_errors "$out")" "$(has_critical_error "$out")" "$(byte_count "$out")" "$url"
