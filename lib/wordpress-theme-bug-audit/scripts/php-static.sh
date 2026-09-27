#!/usr/bin/env bash
# Download a standalone PHP build (static-php.dev, PHP 8.0 and later) into <tools>/php/<minor>/, with an ini that
# raises the memory limit (the builds ship without php.ini and default to 128 MB, too little for WP-CLI).
#
# Usage: php-static.sh <minor-version> <tools-dir>     e.g. php-static.sh 8.1 ~/.cache/wp-theme-audit/x/tools
# Prints the folder to put first on PATH. Set PHP_INI_SCAN_DIR=<folder>/ini alongside it.
# The builds use musl libc: GLOB_BRACE is undefined, and some GD builds lack JPEG support.
#
# Output (stdout): the folder, one line, only on success. Exit 3 with a one-line stderr message when no usable
# build is available (no build for this version or machine, the download site can't be reached, or the build lacks
# a required extension); any partial download is removed, so the next run tries again instead of reusing a broken
# build. A folder that already holds an executable php is trusted and printed without re-checking.

set -euo pipefail

readonly BUILDS_URL="https://dl.static-php.dev/static-php-cli/common"
# Exit code meaning "PHP build unavailable"; callers mark the version BLOCKED.
readonly EXIT_UNAVAILABLE=3
# Seconds allowed for the build listing and for the download.
readonly LIST_TIMEOUT=30
readonly DOWNLOAD_TIMEOUT=300
# Accepted <minor-version> values, e.g. 8.1.
readonly PHP_MINOR_PATTERN='^[0-9]+\.[0-9]+$'
# Extensions WP-CLI, the SQLite test site, and the audit need.
readonly REQUIRED_EXTENSIONS=(pdo_sqlite curl gd zip mbstring openssl)
# memory_limit written to the build's ini.
readonly PHP_MEMORY_LIMIT=512M

minor="${1:?usage: php-static.sh <minor-version> <tools-dir>}"
tools="${2:?usage: php-static.sh <minor-version> <tools-dir>}"
arch="$(uname -m)"
dest="$tools/php/$minor"

# unavailable <message>: remove any partial build, report, and exit 3.
unavailable() {
	rm -rf -- "$dest"
	printf 'php-static: %s\n' "$1" >&2
	exit "$EXIT_UNAVAILABLE"
}

# latest_build_file: the newest php-<minor>.<patch>-cli-linux-<arch>.tar.gz in the build listing, or nothing.
latest_build_file() {
	local listing
	listing="$(curl -fsSL --max-time "$LIST_TIMEOUT" "$BUILDS_URL/")" \
		|| unavailable "could not list builds at $BUILDS_URL"
	grep -oE "php-${minor//./\\.}\.[0-9]+-cli-linux-${arch}\.tar\.gz" <<< "$listing" | sort -uV | tail -1 || true
}

# missing_extensions: the required extensions the build lacks, space-separated with a leading space.
missing_extensions() {
	local ext modules missing=""
	modules="$(PHP_INI_SCAN_DIR="$dest/ini" "$dest/php" -m 2>/dev/null || true)"
	for ext in "${REQUIRED_EXTENSIONS[@]}"; do
		grep -qix "$ext" <<< "$modules" || missing="$missing $ext"
	done
	printf '%s' "$missing"
}

if [[ -x "$dest/php" ]]; then
	printf '%s\n' "$dest"
	exit 0
fi

if [[ ! "$minor" =~ $PHP_MINOR_PATTERN ]]; then
	# Not unavailable(): <dest> is built from <minor>, so never rm -rf it before <minor> is known to be safe.
	printf 'php-static: no build of PHP %s for %s at %s\n' "$minor" "$arch" "$BUILDS_URL" >&2
	exit "$EXIT_UNAVAILABLE"
fi
file="$(latest_build_file)"
[[ -n "$file" ]] || unavailable "no build of PHP $minor for $arch at $BUILDS_URL"

mkdir -p "$dest/ini"
curl -fsSL --max-time "$DOWNLOAD_TIMEOUT" -o "$dest/php.tar.gz" "$BUILDS_URL/$file" \
	|| unavailable "download of $file failed"
tar -xzf "$dest/php.tar.gz" -C "$dest" || unavailable "could not unpack $file"
rm -f "$dest/php.tar.gz"
[[ -x "$dest/php" ]] || unavailable "archive had no php binary"
printf 'memory_limit=%s\n' "$PHP_MEMORY_LIMIT" > "$dest/ini/audit.ini"

missing="$(missing_extensions)"
[[ -z "$missing" ]] || unavailable "PHP $minor lacks:$missing"

printf '%s\n' "$dest"
