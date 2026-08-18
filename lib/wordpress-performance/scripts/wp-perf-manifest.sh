#!/usr/bin/env bash
# Enumerate every reviewable file in a WordPress theme/plugin.
# Output is the coverage checklist for a full-read performance review.
# Usage: wp-perf-manifest.sh [target-dir] [--all]
#   --all  include minified/build output normally skipped

set -uo pipefail

TARGET="${1:-.}"
INCLUDE_BUILD=0
for arg in "$@"; do
  [ "$arg" = "--all" ] && INCLUDE_BUILD=1
done

if [ ! -d "$TARGET" ]; then
  echo "ERROR: not a directory: $TARGET" >&2
  exit 1
fi

PRUNE_DIRS=( node_modules vendor .git .svn dist build coverage )
EXTS=( php js jsx ts tsx json inc )

prune_expr=()
for d in "${PRUNE_DIRS[@]}"; do
  prune_expr+=( -name "$d" -o )
done
unset 'prune_expr[${#prune_expr[@]}-1]'

name_expr=()
for e in "${EXTS[@]}"; do
  name_expr+=( -name "*.$e" -o )
done
unset 'name_expr[${#name_expr[@]}-1]'

files=$(find "$TARGET" \( "${prune_expr[@]}" \) -prune -o -type f \( "${name_expr[@]}" \) -print | sort)

if [ "$INCLUDE_BUILD" -eq 0 ]; then
  files=$(printf '%s\n' "$files" | grep -v -E '\.min\.(js|css)$|-min\.(js|css)$|\.bundle\.js$|package-lock\.json$|composer\.lock$' || true)
fi

[ -z "$files" ] && { echo "No reviewable files found in $TARGET"; exit 0; }

total_files=0
total_lines=0
skipped_large=0

echo "LINES	FILE"
echo "-----	----"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  lines=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
  [ -z "$lines" ] && lines=0
  printf '%s\t%s\n' "$lines" "$f"
  total_files=$((total_files + 1))
  total_lines=$((total_lines + lines))
  [ "$lines" -gt 1500 ] && skipped_large=$((skipped_large + 1))
done <<< "$files"

echo
echo "MANIFEST TOTALS"
echo "  files to read: $total_files"
echo "  total lines:   $total_lines"
echo "  files >1500 lines (read in chunks): $skipped_large"
if [ "$INCLUDE_BUILD" -eq 0 ]; then
  echo "  excluded: node_modules, vendor, .git, dist, build, coverage, *.min.js/css, lock files"
  echo "  (re-run with --all to include build output)"
fi
echo
echo "COVERAGE RULE: every file listed above must be read in full before reporting."
