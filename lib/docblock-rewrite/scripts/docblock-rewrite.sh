#!/usr/bin/env bash
#
# docblock rewrite converts PHPDoc / JSDoc blocks to one line // comments
# in plain English. Walks a directory or single file, calls Claude Haiku
# per symbol, validates output, replaces in place (with .bak by default).
#
# Usage:
#   ./docblock-rewrite.sh <path> [flags]
#
#   <path> may be a directory (walked recursively) or a single file.
#
# Auth: uses local `claude` CLI (Claude Code subscription) no API key needed.
#
# Flags:
#   --dry-run            Show diffs, do not modify files
#   --concurrency N      Files in flight at once (default 3 for CC quota)
#   --model NAME         Claude model id (default claude-haiku-4-5-20251001)
#   --no-backup          Skip .bak files
#   --include-vendor     Do not skip vendor/node_modules/etc.
#   --strict             Exit non-zero if any block was skipped
#   -h, --help           Show this help
#
# Requires: bash 4+, jq, perl, claude (Claude Code CLI on PATH)

set -euo pipefail

DIR=""
DRY_RUN=0
CONCURRENCY=3
MODEL="claude-haiku-4-5-20251001"
BACKUP=1
INCLUDE_VENDOR=0
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)        DRY_RUN=1; shift ;;
    --concurrency)    CONCURRENCY="$2"; shift 2 ;;
    --model)          MODEL="$2"; shift 2 ;;
    --no-backup)      BACKUP=0; shift ;;
    --include-vendor) INCLUDE_VENDOR=1; shift ;;
    --strict)         STRICT=1; shift ;;
    -h|--help)        sed -n '3,21p' "$0"; exit 0 ;;
    -*)               echo "unknown flag: $1" >&2; exit 1 ;;
    *)                DIR="$1"; shift ;;
  esac
done

[[ -n "$DIR" ]] || { echo "usage: $0 <path> [flags]" >&2; exit 1; }
if [[ -d "$DIR" ]]; then
  IS_FILE=0
elif [[ -f "$DIR" ]]; then
  IS_FILE=1
else
  echo "not a file or directory: $DIR" >&2; exit 1
fi

command -v jq >/dev/null || {
  echo "needs jq install with:"          >&2
  echo "  macOS:  brew install jq"         >&2
  echo "  Ubuntu: sudo apt install jq"     >&2
  echo "  Fedora: sudo dnf install jq"     >&2
  exit 1
}
command -v perl >/dev/null || {
  echo "needs perl install with:"        >&2
  echo "  macOS:  preinstalled (try /usr/bin/perl)" >&2
  echo "  Ubuntu: sudo apt install perl"   >&2
  echo "  Fedora: sudo dnf install perl"   >&2
  exit 1
}
command -v claude >/dev/null || {
  echo "needs claude (Claude Code CLI) install with:" >&2
  echo "  npm install -g @anthropic-ai/claude-code" >&2
  echo "  or see https://docs.claude.com/claude-code/setup" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACT_PL="$SCRIPT_DIR/extract-docblocks.pl"
APPLY_PL="$SCRIPT_DIR/apply-plan.pl"
[[ -f "$EXTRACT_PL" ]] || { echo "missing $EXTRACT_PL" >&2; exit 1; }
[[ -f "$APPLY_PL"   ]] || { echo "missing $APPLY_PL"   >&2; exit 1; }

# prompt

PROMPT_FILE="${PROMPT_FILE:-$SCRIPT_DIR/system-prompt.txt}"
[[ -f "$PROMPT_FILE" ]] || { echo "missing prompt file: $PROMPT_FILE" >&2; exit 1; }
PROMPT_HEADER=$(cat "$PROMPT_FILE")

# find files

if [[ "$IS_FILE" -eq 1 ]]; then
  FILES=( "$DIR" )
else
  PRUNE=()
  if [[ "$INCLUDE_VENDOR" -eq 0 ]]; then
    for d in vendor node_modules dist build coverage __tests__ .git .svn .hg .next .nuxt out tmp; do
      PRUNE+=( -path "*/$d" -o )
    done
    unset 'PRUNE[${#PRUNE[@]}-1]'
  fi

  mapfile -t FILES < <(
    if [[ "${#PRUNE[@]}" -gt 0 ]]; then
      find "$DIR" \( "${PRUNE[@]}" \) -prune -o \
        -type f \( -name '*.php' -o -name '*.js' -o -name '*.ts' \
                -o -name '*.jsx' -o -name '*.tsx' -o -name '*.mjs' -o -name '*.cjs' \) \
        ! -name '*.min.js' ! -name '*.generated.*' -print
    else
      find "$DIR" -type f \( -name '*.php' -o -name '*.js' -o -name '*.ts' \
                -o -name '*.jsx' -o -name '*.tsx' -o -name '*.mjs' -o -name '*.cjs' \) \
        ! -name '*.min.js' ! -name '*.generated.*' -print
    fi
  )
fi

echo "scanning ${#FILES[@]} file(s) under $DIR"

# per file

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

export MODEL DRY_RUN BACKUP WORK_DIR EXTRACT_PL APPLY_PL
export PROMPT_HEADER

process_file() {
  local file="$1"
  local pairs_json
  pairs_json=$(perl "$EXTRACT_PL" "$file")

  local pair_count
  pair_count=$(echo "$pairs_json" | jq 'length')
  if [[ "$pair_count" -eq 0 ]]; then
    echo "  skip (no docblocks): $file"
    return 0
  fi

  echo "  $file - $pair_count docblock(s)"

  local safe
  safe=$(echo "$file" | tr / _ | tr -c 'A-Za-z0-9._-' _)
  local plan="$WORK_DIR/$safe.plan"
  local skip_log="$WORK_DIR/$safe.skip"
  local rw_log="$WORK_DIR/$safe.rw"
  : > "$plan"
  : > "$skip_log"
  : > "$rw_log"

  local i=0
  while [[ "$i" -lt "$pair_count" ]]; do
    local block sym
    block=$(echo "$pairs_json" | jq -r ".[$i].block" | base64 -d)
    sym=$(  echo "$pairs_json" | jq -r ".[$i].symbol" | base64 -d)
    local start len
    start=$(echo "$pairs_json" | jq -r ".[$i].start")
    len=$(  echo "$pairs_json" | jq -r ".[$i].len")

    local user_msg
    user_msg=$(printf '%s\n\nORIGINAL_DOCBLOCK:\n%s\nSYMBOL:\n%s\nOUTPUT:\n' \
      "$PROMPT_HEADER" "$block" "$sym")

    echo "    [$((i+1))/$pair_count] $sym" >&2
    local raw rc
    raw=$(NO_COLOR=1 TERM=dumb timeout 60 claude --model "$MODEL" --print "$user_msg" 2>&1)
    rc=$?
    if [[ "$rc" -ne 0 ]]; then
      echo "    claude rc=$rc: ${raw:0:200}" >&2
      printf '%s\t%s\tclaude_error\trc=%s\n' "$file" "$sym" "$rc" >> "$skip_log"
      i=$((i+1)); continue
    fi
    local out
    # strip ANSI CSI + OSC sequences and keep first line; trim trailing whitespace
    out=$(printf '%s' "$raw" \
      | perl -pe 's/\e\[[\d;?]*[A-Za-z]//g; s/\e\][^\a\e]*(?:\a|\e\\)//g; s/\e[\x40-\x5f]//g; tr/\x00-\x08\x0b\x0c\x0e-\x1f\x7f//d' \
      | head -n1 \
      | sed 's/[[:space:]]*$//')

    local reason
    if ! reason=$(validate_output "$out"); then
      echo "    invalid output for [$sym]: $out ($reason)" >&2
      printf '%s\t%s\tvalidation\t%s\n' "$file" "$sym" "$reason" >> "$skip_log"
      i=$((i+1)); continue
    fi

    printf '%s\t%s\t%s\n' "$start" "$len" "$(printf '%s' "$out" | base64 | tr -d '\n')" >> "$plan"
    printf '%s\t%s\n' "$file" "$sym" >> "$rw_log"
    i=$((i+1))
  done

  apply_plan "$file" "$plan"
}

validate_output() {
  local out="$1"
  if [[ -z "$out" ]]; then echo "empty"; return 1; fi
  if [[ "$out" == *$'\n'* ]]; then echo "multiline"; return 1; fi
  if [[ ! "$out" =~ ^//\  ]]; then echo "missing // prefix"; return 1; fi
  if (( ${#out} > 100 )); then echo ">100 chars (${#out})"; return 1; fi
  local banned
  banned=$(echo "$out" | grep -ioE '\b(instantiate|invoke|callback|promise|iterate|async|boolean|array|object|parameter|argument|mutate|hash|payload|instance|factory|singleton|polyfill|regex)\b' | head -1)
  if [[ -n "$banned" ]]; then echo "banned word: $banned"; return 1; fi
  return 0
}

apply_plan() {
  local file="$1" plan="$2"
  local lines
  lines=$(wc -l < "$plan" | tr -d ' ')
  if [[ "$lines" -eq 0 ]]; then
    echo "    nothing to apply"
    return 0
  fi
  perl "$APPLY_PL" "$file" "$plan" "$DRY_RUN" "$BACKUP"
}

export -f process_file apply_plan validate_output

# run

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "no candidate files found"
  exit 0
fi

if [[ "$CONCURRENCY" -le 1 ]]; then
  for f in "${FILES[@]}"; do process_file "$f"; done
else
  printf '%s\n' "${FILES[@]}" \
    | xargs -P "$CONCURRENCY" -I{} bash -c 'process_file "$@"' _ {}
fi

# summary report

shopt -s nullglob
RW_FILES=( "$WORK_DIR"/*.rw )
SKIP_FILES=( "$WORK_DIR"/*.skip )
shopt -u nullglob

TOTAL_FILES=${#FILES[@]}
REWRITTEN=0
SKIPPED=0
[[ "${#RW_FILES[@]}"   -gt 0 ]] && REWRITTEN=$(cat "${RW_FILES[@]}"   | wc -l | tr -d ' ')
[[ "${#SKIP_FILES[@]}" -gt 0 ]] && SKIPPED=$(  cat "${SKIP_FILES[@]}" | wc -l | tr -d ' ')

echo
echo "----"
echo "files scanned:    $TOTAL_FILES"
echo "blocks rewritten: $REWRITTEN"
echo "blocks skipped:   $SKIPPED"

if [[ "$SKIPPED" -gt 0 ]]; then
  echo
  echo "skipped blocks (left as original):"
  cat "${SKIP_FILES[@]}" | while IFS=$'\t' read -r f s r d; do
    printf '  %s\n    [%s] %s — %s\n' "$f" "$r" "$s" "$d"
  done
fi

echo "done."

if [[ "$STRICT" -eq 1 && "$SKIPPED" -gt 0 ]]; then
  exit 2
fi
