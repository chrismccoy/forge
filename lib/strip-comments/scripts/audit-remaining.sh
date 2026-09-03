#!/usr/bin/env bash
# audit-remaining.sh - list comment-like lines that survived a strip pass and
# classify each as HEADER, KEEP (matched the preserve list), or FLAG.
#
# Usage:
#   audit-remaining.sh file1 file2 ...
#   git diff --name-only | audit-remaining.sh
#
# Every FLAG line needs a human decision: it is either a comment that should
# have been removed, or a false positive (comment syntax inside a string, URL,
# or regex literal). This script deliberately over-reports rather than guessing.
#
# Exit 1 if any FLAG lines were found, 0 otherwise.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS="$HERE/preserve-patterns.txt"
[ -f "$PATTERNS" ] || { echo "audit-remaining: missing $PATTERNS" >&2; exit 2; }

# Lines that look like they contain a comment opener. Over-broad on purpose.
Q="'"
COMMENT_RE="(^|[[:space:]])(//|/\*|\*/|#|--|<!--|<%#|\"\"\"|${Q}${Q}${Q})|^[[:space:]]*\*[[:space:]]"
# A comment that starts the line (as opposed to trailing after code).
WHOLE_LINE_RE="^[[:space:]]*(//|/\*|\*|#|--|<!--|<%#|\"\"\"|${Q}${Q}${Q})"

FLAGS=0

audit_one() {
  local f="$1" in_prologue=1
  [ -f "$f" ] || return 0

  local lineno=0 line verdict
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))

    if ! printf '%s' "$line" | grep -Eq "$COMMENT_RE"; then
      # a non-blank, non-comment line ends the file prologue
      printf '%s' "$line" | grep -Eq '[^[:space:]]' && in_prologue=0
      continue
    fi

    # code followed by a comment ends the prologue and is never a header
    printf '%s' "$line" | grep -Eq "$WHOLE_LINE_RE" || in_prologue=0

    if printf '%s' "$line" | grep -Eqf "$PATTERNS"; then
      verdict=KEEP
    elif [ "$in_prologue" -eq 1 ]; then
      verdict=HEADER
    else
      verdict=FLAG
      FLAGS=$((FLAGS + 1))
    fi

    printf '%-6s %s:%d: %s\n' "$verdict" "$f" "$lineno" "$(printf '%s' "$line" | cut -c1-120)"
  done < "$f"
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do audit_one "$f"; done
else
  while IFS= read -r f; do [ -n "$f" ] && audit_one "$f"; done
fi

printf '\n%d line(s) flagged for review\n' "$FLAGS"
[ "$FLAGS" -eq 0 ]
