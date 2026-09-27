#!/usr/bin/env bash
# Build a throwaway test site for the audit and prepare it: a copy of the theme, the audit must-use plugins,
# SAVEQUERIES, and axe-core in the web root. Prints the site folder (<tmp>) on the last line.
#
# The theme is copied for real, like a normal install: a symlinked theme breaks code that includes files or builds
# URLs from __DIR__, because PHP resolves __DIR__ to the symlink's target. Only media folders and files over 5 MB are
# symlinked, to save space. The copy leaves out .git, node_modules, audit (this prompt's output), tool folders, and
# anything in AUDIT_EXCLUDE_DIRS. Build a new site, or copy again, after the theme's files change.
#
# Usage: new-site.sh <work> <theme-dir> [local|<php-minor>] [<wordpress-version>]
#
# Environment:
#   AUDIT_MEDIA_DIRS   theme sub-folders holding only media, linked as one folder (space-separated relative paths).
#                      Detected automatically with media-dirs.sh when unset; set it to "none" to link nothing.
#                      Media files over 1 MB outside those folders are linked too.
#   AUDIT_EXCLUDE_DIRS theme sub-folders the theme doesn't ship (from .distignore or export-ignore), left out of the copy
#   AUDIT_PARENT_DIR   for a child theme: the parent theme's folder, installed and activated first
#   PHP_CLI_SERVER_WORKERS defaults to 4 so loopback requests don't hang the server
#
# Stops with exit code 9 when less than 1 GB is free on the disk holding <work>.
#
# Output: stdout is only the site folder, on the last line; progress and the PHP/WordPress versions go to stderr.
# Any other failure exits non-zero (set -e) with nothing on stdout; a site that was already built is torn down
# first (with site-down.sh), so failed runs don't leave sites behind. Setup details are in
# <work>/sites/setup-<php>-<HHMMSS>.log. Needs rsync, and php-static.sh, setup-test-site.sh, media-dirs.sh, and
# mu/*.php next to this script.

set -euo pipefail

# Free space required on the disk holding <work>, in KB (1 GB).
readonly MIN_FREE_KB=1048576
# Exit code for "not enough disk space"; callers stop the audit on it.
readonly EXIT_NO_SPACE=9
# Theme files over this size are symlinked instead of copied.
readonly LINK_ANY_OVER='+5M'
# Media files over this size are symlinked instead of copied.
readonly LINK_MEDIA_OVER='+1M'
# find -iregex (posix-extended) for the media extensions media-dirs.sh uses.
readonly MEDIA_FILE_REGEX='.*\.(jpe?g|png|gif|webp|avif|bmp|ico|tiff?|psd|mp4|webm|mov|m4v|ogv|avi|mp3|ogg|oga|wav|m4a|flac|woff2?|ttf|otf|eot)'
# Theme sub-folders never copied into the site (repository, dependencies, audit output, agent state).
readonly COPY_EXCLUDES=(--exclude=/.git --exclude=/node_modules --exclude=/audit --exclude=/.remember --exclude=/.claude)

work="${1:?usage: new-site.sh <work> <theme-dir> [local|<php-minor>] [<wordpress-version>]}"
theme="$(cd "${2:?theme dir}" && pwd -P)"
php_version="${3:-local}"
wp_version="${4:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
slug="$(basename "$theme")"
tmp=""

# words <text>: print each whitespace-separated word on its own line, without glob expansion.
words() {
	local list=()
	read -r -d '' -a list <<< "$1" || true
	[[ ${#list[@]} -eq 0 ]] || printf '%s\n' "${list[@]}"
}

# teardown_on_failure: EXIT trap; removes a half-built site so a failed run leaves nothing behind.
teardown_on_failure() {
	local status=$?
	if [[ "$status" -ne 0 && -n "$tmp" && -d "$tmp" ]]; then
		bash "$here/site-down.sh" "$tmp" >/dev/null 2>&1 || true
		printf 'new-site: failed (exit %s); removed %s\n' "$status" "$tmp" >&2
	fi
	exit "$status"
}
trap teardown_on_failure EXIT

# free_kb <path>: KB available on the disk holding <path>, or 0 when df gives no number.
free_kb() {
	local avail
	avail="$(df --output=avail -k "$1" 2>/dev/null | tail -1)"
	avail="${avail//[[:space:]]/}"
	[[ "$avail" =~ ^[0-9]+$ ]] || avail=0
	printf '%s' "$avail"
}

if [[ -z "${AUDIT_MEDIA_DIRS+x}" ]]; then
	AUDIT_MEDIA_DIRS="$(bash "$here/media-dirs.sh" "$theme")"
	printf 'new-site: media folders linked, not copied: %s\n' "${AUDIT_MEDIA_DIRS:-none}" >&2
fi
[[ "${AUDIT_MEDIA_DIRS:-}" == none ]] && AUDIT_MEDIA_DIRS=""
export AUDIT_MEDIA_DIRS
mapfile -t media_dirs < <(words "${AUDIT_MEDIA_DIRS:-}")
mapfile -t exclude_dirs < <(words "${AUDIT_EXCLUDE_DIRS:-}")

mkdir -p "$work"
if [[ "$(free_kb "$work")" -lt "$MIN_FREE_KB" ]]; then
	printf 'new-site: less than 1 GB free on the disk holding %s; stop and report\n' "$work" >&2
	exit "$EXIT_NO_SPACE"
fi

if [[ "$php_version" != local ]]; then
	php_dir="$(bash "$here/php-static.sh" "$php_version" "$work/tools")"
	export PATH="$php_dir:$PATH" PHP_INI_SCAN_DIR="$php_dir/ini"
fi
export PHP_CLI_SERVER_WORKERS="${PHP_CLI_SERVER_WORKERS:-4}"

mkdir -p "$work/sites"
setup_theme="$theme"
[[ -n "${AUDIT_PARENT_DIR:-}" ]] && setup_theme="$(cd "$AUDIT_PARENT_DIR" && pwd -P)"
log="$work/sites/setup-$php_version-$(date +%H%M%S).log"
tmp="$(bash "$here/setup-test-site.sh" "$setup_theme" 0 "$work/sites" 2>"$log" | tail -1)"
[[ -f "$tmp/env.sh" ]] || { printf 'new-site: setup failed; see %s\n' "$log" >&2; tmp=""; exit 1; }
# shellcheck source=/dev/null
source "$tmp/env.sh"

# site_copy <src> <dest>: copy a theme into the site, symlinking media folders and large files instead of copying.
site_copy() {
	local src="$1" dest="$2" dir file linked
	local excludes=("${COPY_EXCLUDES[@]}")
	for dir in "${exclude_dirs[@]}" "${media_dirs[@]}"; do
		excludes+=("--exclude=/$dir")
	done
	local skip=()
	for dir in "${exclude_dirs[@]}"; do
		skip+=(-not -path "$src/$dir/*")
	done
	linked="$(mktemp)"
	find "$src" -type f \( -size "$LINK_ANY_OVER" -o \( -size "$LINK_MEDIA_OVER" -regextype posix-extended \
		-iregex "$MEDIA_FILE_REGEX" \) \) \
		-not -path "$src/.git/*" -not -path "$src/node_modules/*" -not -path "$src/audit/*" "${skip[@]}" \
		-printf '/%P\n' > "$linked"
	rm -f "$dest"
	mkdir -p "$dest"
	rsync -a --exclude-from="$linked" "${excludes[@]}" "$src/" "$dest/"
	for dir in "${media_dirs[@]}"; do
		[[ -d "$src/$dir" ]] || continue
		mkdir -p "$(dirname "$dest/$dir")"
		ln -s "$src/$dir" "$dest/$dir"
	done
	while IFS= read -r file; do
		file="${file#/}"
		[[ -e "$dest/$file" ]] && continue
		mkdir -p "$(dirname "$dest/$file")"
		ln -s "$src/$file" "$dest/$file"
	done < "$linked"
	rm -f "$linked"
}

themes="$tmp/wordpress/wp-content/themes"
if [[ -n "${AUDIT_PARENT_DIR:-}" ]]; then
	site_copy "$setup_theme" "$themes/$(basename "$setup_theme")"
	site_copy "$theme" "$themes/$slug"
	wp theme activate "$slug" >/dev/null
else
	site_copy "$theme" "$themes/$slug"
fi

mkdir -p "$tmp/wordpress/wp-content/mu-plugins"
cp "$here"/mu/*.php "$tmp/wordpress/wp-content/mu-plugins/"
wp config set SAVEQUERIES true --raw >/dev/null
axe="$work/tools/node_modules/axe-core/axe.min.js"
if [[ -f "$axe" ]]; then
	cp "$axe" "$tmp/wordpress/axe.min.js"
fi

if [[ -n "$wp_version" ]]; then
	wp core update --version="$wp_version" --force >/dev/null
	wp core update-db >/dev/null
	wp user update admin --user_pass=admin >/dev/null
fi

{
	printf 'export PHP_CLI_SERVER_WORKERS=%s\n' "$PHP_CLI_SERVER_WORKERS"
	if [[ "$php_version" != local ]]; then
		# shellcheck disable=SC2016  # $PATH stays literal: env.sh expands it when sourced.
		printf 'export PATH="%s:$PATH" PHP_INI_SCAN_DIR="%s/ini"\n' "$php_dir" "$php_dir"
	fi
} >> "$tmp/env.sh"

printf 'php %s, wordpress %s\n' "$(php -r 'echo PHP_VERSION;')" "$(wp core version)" >&2
printf '%s\n' "$tmp"
