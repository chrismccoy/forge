#!/usr/bin/env bash
# Run PHPStan on a theme without exhausting the machine's memory: the whole theme is in scanDirectories (so every
# symbol is known), but the theme's own files are analysed about 8 at a time, each run in one process with a 1 GB
# limit, under a 2 GB cap when systemd allows it. PHPStan's defaults (several 2 GB workers, or one process on the
# whole theme) crashed a 6 GB machine.
#
# Usage: phpstan-batches.sh <tools> <theme-dir> <php-minor> <out-dir> [level]
#   <tools> must hold a Composer install of phpstan/phpstan, szepeviktor/phpstan-wordpress, and
#   phpstan/extension-installer. If <out-dir>/bootstrap.php exists (the theme's constants), it is loaded.
#   AUDIT_EXCLUDE_DIRS (space-separated) leaves folders the theme doesn't ship out of the analysis. vendor/ is scanned
#   for symbols (so bundled libraries' functions aren't reported as missing) but not analysed.
# Writes <out-dir>/batch-NNN.json per batch and <out-dir>/summary.txt with every error, one per line, then deletes
# PHPStan's cache (about 60 MB per run).
#
# Output (stdout), one line:
#   phpstan-batches: <n> files, <n> batches, <n> failed, <n> errors (PHP <minor>, level <level>)
# summary.txt lines are "<path>:<line>: <message>", "GENERAL: <message>", or "BATCH <n> FAILED (see <err>): <files>";
# the errors count excludes the BATCH lines. Exit 0 once batches ran, even when some failed; 1 when PHPStan isn't
# installed, <theme-dir> doesn't exist, or <php-minor> isn't <major>.<minor>. Needs php and python3.

set -uo pipefail

# Files analysed per PHPStan process.
readonly BATCH_SIZE=8
# Memory limit per PHPStan process.
readonly PHP_MEMORY_LIMIT=1G
# Memory cap for each PHPStan run when systemd-run is available.
readonly SYSTEMD_MEMORY_MAX=2G
# Accepted <php-minor> values, e.g. 8.1.
readonly PHP_MINOR_PATTERN='^[0-9]+\.[0-9]+$'

tools="${1:?usage: phpstan-batches.sh <tools> <theme-dir> <php-minor> <out-dir> [level]}"
theme_arg="${2:?theme dir}"
minor="${3:?php minor, e.g. 8.1}"
out="${4:?out dir}"
level="${5:-5}"
theme="$(cd "$theme_arg" 2>/dev/null && pwd -P)"
[[ -n "$theme" ]] || { printf 'phpstan-batches: theme dir not found: %s\n' "$theme_arg" >&2; exit 1; }
[[ "$minor" =~ $PHP_MINOR_PATTERN ]] || { printf 'phpstan-batches: php minor must look like 8.1, got %s\n' "$minor" >&2; exit 1; }
phpstan="$tools/vendor/bin/phpstan"
[[ -x "$phpstan" ]] || { printf 'phpstan-batches: %s not found; install it with Composer into %s\n' "$phpstan" "$tools" >&2; exit 1; }

exclude_dirs=()
read -r -d '' -a exclude_dirs <<< "${AUDIT_EXCLUDE_DIRS:-}" || true

# php_version_id <major.minor>: PHPStan's phpVersion, e.g. 8.1 -> 80100.
php_version_id() {
	printf '%d%02d00' "${1%%.*}" "${1#*.}"
}

write_config() {
	local excludes="" bootstrap="" dir
	for dir in "${exclude_dirs[@]}"; do
		excludes="$excludes            - $theme/$dir/*
"
	done
	[[ -f "$out/bootstrap.php" ]] && bootstrap="    bootstrapFiles:
        - $out/bootstrap.php"

	cat > "$out/phpstan.neon" <<NEON
parameters:
    level: $level
    phpVersion: $(php_version_id "$minor")
    tmpDir: $out/tmp
    parallel:
        maximumNumberOfProcesses: 1
    scanDirectories:
        - $theme
    excludePaths:
        analyse:
            - $theme/vendor/*
        analyseAndScan:
            - $theme/node_modules/*
            - $theme/audit/*
$excludes
$bootstrap
NEON
}

# summarize_batch <json>: append the batch's errors to summary.txt; returns 1 when the JSON is missing or invalid.
# PHP startup warnings (a standalone build can't load PHPStan's optional native extension) can land on stdout
# before the report, so the report is read from its first line that starts with "{".
summarize_batch() {
	python3 - "$1" >> "$out/summary.txt" <<'PY'
import json, re, sys
try:
    with open(sys.argv[1], errors='replace') as handle:
        text = handle.read()
    start = re.search(r'^\{', text, re.M)
    data, _ = json.JSONDecoder().raw_decode(text[start.start():] if start else text)
except (OSError, ValueError):
    sys.exit(1)
if not isinstance(data, dict):
    sys.exit(1)
for path, info in data.get('files', {}).items():
    for m in info.get('messages', []):
        print('%s:%s: %s' % (path, m.get('line'), m.get('message')))
for m in data.get('errors', []):
    print('GENERAL: %s' % m)
PY
}

mkdir -p "$out/tmp"
write_config

cap=()
if systemd-run --user --scope -q -p MemoryMax="$SYSTEMD_MEMORY_MAX" true >/dev/null 2>&1; then
	cap=(systemd-run --user --scope -q -p MemoryMax="$SYSTEMD_MEMORY_MAX")
fi

skip=()
for dir in "${exclude_dirs[@]}"; do
	skip+=(-not -path "$theme/$dir/*")
done
mapfile -t files < <(find "$theme" -name '*.php' -not -path "$theme/vendor/*" -not -path "$theme/node_modules/*" \
	-not -path "$theme/audit/*" -not -path "$theme/.git/*" "${skip[@]}" | sort)
: > "$out/summary.txt"
batch=0
failed=0
for ((i = 0; i < ${#files[@]}; i += BATCH_SIZE)); do
	batch=$((batch + 1))
	json="$out/$(printf 'batch-%03d.json' "$batch")"
	"${cap[@]}" php "$phpstan" analyse --configuration="$out/phpstan.neon" --memory-limit="$PHP_MEMORY_LIMIT" --no-progress \
		--error-format=json -- "${files[@]:i:BATCH_SIZE}" > "$json" 2> "$json.err"
	if ! summarize_batch "$json"; then
		failed=$((failed + 1))
		printf 'BATCH %s FAILED (see %s.err): %s\n' "$batch" "$json" "${files[*]:i:BATCH_SIZE}" >> "$out/summary.txt"
	fi
done
rm -rf "$out/tmp"
errors="$(grep -vc '^BATCH' "$out/summary.txt")"
printf 'phpstan-batches: %s files, %s batches, %s failed, %s errors (PHP %s, level %s)\n' \
	"${#files[@]}" "$batch" "$failed" "${errors:-0}" "$minor" "$level"
