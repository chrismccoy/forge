#!/usr/bin/env bash
# The step 13 pass for one PHP version (and optionally an older WordPress): lint every theme file with that PHP,
# build a test site on it, replay the probe scripts, fetch the saved URL lists, run the loading check, collect every
# PHP error, and tear the site down.
#
# Usage: version-pass.sh <work> <theme-dir> <php-minor|local> [<wordpress-version>]
#
# Inputs it uses from <work>, all written by earlier steps:
#   probe/NN-*.php    replayed in order with `wp eval-file` (PHP 7.4 syntax), before the server starts
#   probe/NN-*.sh     run in order with `bash` after the server starts and `login` has run, with TMP set to the site
#                     folder (for AJAX calls, form posts, and the like; use $TMP/jar for logged-in requests)
#   AUDIT_EXCLUDE_DIRS and AUDIT_MEDIA_DIRS are honoured, as in new-site.sh
#   urls.tsv          <label><TAB><path> front-end pages, fetched logged out
#   admin-urls.tsv    <label><TAB><path> admin screens, fetched logged in
#   probe/loading.php the step 16 loading check, run with `wp eval-file` if present
# Output: <work>/php-<version>[-wp<wp>]-errors.txt, and the pages in <work>/pages/v<version>/. With `local` (for
# example inside a Docker container for PHP 7.x), <version> is the running PHP's major.minor, so passes on different
# containers never overwrite each other.
#
# Stdout is the log lines also written to the errors file: "== <name>: PHP <x.y.z>", "LINT ...", "php -l failures: <n>",
# "site ...", "PROBE FAILED ...", fetch.sh summary lines for pages with errors or a critical error (clean pages go to
# <pages>/fetch.log only), "-- <section>" headers, "BLOCKED: <reason>", and "== done; site torn down". The loading
# check, debug.log, and server.log excerpts go to the errors file only.
# Exit 3 when the PHP build is unavailable, 1 when the site can't be built or its server won't start (both after a
# BLOCKED line), else 0. URL lists may use CRLF line endings.

set -uo pipefail

# Exit code for "PHP build unavailable" (same as php-static.sh).
readonly EXIT_PHP_UNAVAILABLE=3
# How many lines of the loading check, debug.log, and server.log excerpts are kept.
readonly LOADING_LINES=20
readonly DEBUG_LOG_LINES=30
readonly SERVER_LOG_LINES=15
# PHP error lines in the built-in server's log.
readonly SERVER_LOG_ERROR_PATTERN='PHP (Fatal|Warning|Deprecated|Notice)'
# fetch.sh summary fields of a page with no PHP errors.
readonly CLEAN_FETCH_FIELDS='errors=0 critical=0'

work="${1:?usage: version-pass.sh <work> <theme-dir> <php-minor|local> [<wordpress-version>]}"
theme="$(cd "${2:?theme dir}" && pwd -P)"
version="${3:?php minor or local}"
wp_version="${4:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
label="$version"
if [[ "$version" == local ]]; then
	label="$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;' 2>/dev/null)" || label=local
fi
name="php-$label${wp_version:+-wp$wp_version}"
report="$work/$name-errors.txt"
pages="$work/pages/v$label${wp_version:+-wp$wp_version}"
mkdir -p "$pages"
: > "$report"

# log <text...>: print a line to stdout and append it to the errors file.
log() { printf '%s\n' "$*" | tee -a "$report"; }

# regex_escape <text>: the text with ERE metacharacters escaped.
regex_escape() {
	# shellcheck disable=SC2001,SC2016  # A bracket class is clearer in sed than in ${//}; $ is literal.
	sed 's/[][\.|$(){}?+*^]/\\&/g' <<< "$1"
}

# lint_theme <php>: php -l every theme file; logs each failure and the total.
lint_theme() {
	local php_bin="$1" file result failures=0 dirs=() dir skip=()
	read -r -d '' -a dirs <<< "${AUDIT_EXCLUDE_DIRS:-}" || true
	for dir in "${dirs[@]}"; do
		skip+=(-not -path "$theme/$dir/*")
	done
	while IFS= read -r -d '' file; do
		result="$("$php_bin" -l "$file" 2>&1)"
		[[ "$result" == *'No syntax errors'* ]] || { failures=$((failures + 1)); log "LINT $result"; }
	done < <(find "$theme" -name '*.php' -not -path "$theme/vendor/*" -not -path "$theme/node_modules/*" \
		-not -path "$theme/audit/*" -not -path "$theme/.git/*" "${skip[@]}" -print0)
	log "php -l failures: $failures"
}

# run_probes <ext> <runner...>: run <work>/probe/[0-9]*.<ext> in order, output to <pages>/<probe>.out.
run_probes() {
	local ext="$1" probe
	shift
	for probe in "$work"/probe/[0-9]*."$ext"; do
		[[ -e "$probe" ]] || continue
		"$@" "$probe" > "$pages/$(basename "$probe").out" 2>&1 || log "PROBE FAILED $(basename "$probe")"
	done
}

# fetch_list <tsv> [curl args...]: fetch every <label><TAB><path> row; clean pages go to fetch.log, others are logged.
fetch_list() {
	local list="$1" label path line
	shift
	[[ -f "$list" ]] || return 0
	while IFS=$'\t' read -r label path; do
		path="${path%$'\r'}"
		[[ -n "$label" ]] || continue
		line="$(bash "$here/fetch.sh" "$tmp" "$pages" "$label" "$path" "$@")"
		case "$line" in *"$CLEAN_FETCH_FIELDS"*) printf '%s\n' "$line" >> "$pages/fetch.log" ;; *) log "$line" ;; esac
	done < "$list"
}

# count_lines <file>: non-empty lines in the file, 0 when it's missing.
count_lines() {
	local count
	count="$(grep -c . "$1" 2>/dev/null)"
	printf '%s' "${count:-0}"
}

php_bin=php
if [[ "$version" != local ]]; then
	php_dir="$(bash "$here/php-static.sh" "$version" "$work/tools")" \
		|| { log "BLOCKED: no PHP $version build"; exit "$EXIT_PHP_UNAVAILABLE"; }
	php_bin="$php_dir/php"
	export PHP_INI_SCAN_DIR="$php_dir/ini"
fi
log "== $name: PHP $("$php_bin" -r 'echo PHP_VERSION;')"

lint_theme "$php_bin"

tmp="$(bash "$here/new-site.sh" "$work" "$theme" "$version" "$wp_version" 2>>"$report" | tail -1)"
[[ -n "$tmp" && -f "$tmp/env.sh" ]] || { log "BLOCKED: site setup failed"; exit 1; }
# shellcheck source=/dev/null
source "$tmp/env.sh"
log "site $tmp, WordPress $(wp core version)"

run_probes php wp eval-file

serve stop >/dev/null 2>&1
serve start || { log "BLOCKED: server didn't start"; bash "$here/site-down.sh" "$tmp"; exit 1; }
login || log "login failed"

run_probes sh env TMP="$tmp" bash

log "-- front end"
fetch_list "$work/urls.tsv"
log "-- admin"
fetch_list "$work/admin-urls.tsv" -b "$tmp/jar"

if [[ -f "$work/probe/loading.php" ]]; then
	log "-- loading check"
	wp eval-file "$work/probe/loading.php" 2>&1 | tail -"$LOADING_LINES" | tee -a "$report" >/dev/null
fi

real_theme="$(regex_escape "$theme")"
site_theme="$(regex_escape "$tmp/wordpress/wp-content/themes/$(basename "$theme")")"
theme_paths="($site_theme|$real_theme)/"
# Same pattern for sed s#...#...#, where a literal # in a path would end the pattern.
sed_theme_paths="${theme_paths//#/\\#}"
log "-- debug.log lines from the theme"
grep -E "$theme_paths" "$tmp/wordpress/wp-content/debug.log" 2>/dev/null | grep -v '/vendor/' \
	| sed -E 's/^\[[^]]*\] //' | sed -E "s#$sed_theme_paths#THEME/#g" | sort | uniq -c | sort -rn \
	| head -"$DEBUG_LOG_LINES" | tee -a "$report" >/dev/null
log "-- vendor notices: $(count_lines "$tmp/vendor-notices.log") requests with vendor deprecations"
log "-- server.log PHP errors"
grep -E "$SERVER_LOG_ERROR_PATTERN" "$tmp/server.log" 2>/dev/null | sed -E "s#$sed_theme_paths#THEME/#g" \
	| sort | uniq -c | sort -rn | head -"$SERVER_LOG_LINES" | tee -a "$report" >/dev/null

bash "$here/site-down.sh" "$tmp" >/dev/null
log "== done; site torn down"
