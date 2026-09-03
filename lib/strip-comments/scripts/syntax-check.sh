#!/usr/bin/env bash
# syntax-check.sh - parse-check files with each language's own parser.
#
# Usage:
#   syntax-check.sh file1 file2 ...
#   git diff --name-only | syntax-check.sh
#
# Exit 0 only if every checkable file parsed. Files whose checker is not
# installed are reported as SKIP and do not fail the run - but they are NOT
# evidence of correctness, so report them explicitly.

set -uo pipefail

FAIL=0
CHECKED=0
SKIPPED=0

have() { command -v "$1" >/dev/null 2>&1; }

# keep py_compile bytecode out of the working tree
PYCACHE="$(mktemp -d 2>/dev/null || echo /tmp/strip-comments-pycache.$$)"
trap 'rm -rf "$PYCACHE"' EXIT

report() { printf '%-6s %s%s\n' "$1" "$2" "${3:+  ($3)}"; }

check_one() {
  local f="$1" out rc
  [ -f "$f" ] || { report SKIP "$f" "missing"; SKIPPED=$((SKIPPED+1)); return; }

  case "$f" in
    *.js|*.mjs|*.cjs|*.jsx)
      have node || { report SKIP "$f" "node not installed"; SKIPPED=$((SKIPPED+1)); return; }
      case "$f" in
        *.jsx) report SKIP "$f" "jsx: use tsc/babel, node --check cannot parse"; SKIPPED=$((SKIPPED+1)); return;;
      esac
      out=$(node --check "$f" 2>&1); rc=$? ;;
    *.ts|*.tsx|*.mts|*.cts)
      if have tsc; then out=$(tsc --noEmit --allowJs false --skipLibCheck "$f" 2>&1); rc=$?
      elif have npx; then out=$(npx --no-install tsc --noEmit --skipLibCheck "$f" 2>&1); rc=$?
      else report SKIP "$f" "tsc not installed"; SKIPPED=$((SKIPPED+1)); return; fi ;;
    *.py|*.pyi)
      have python3 || { report SKIP "$f" "python3 not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(PYTHONPYCACHEPREFIX="$PYCACHE" python3 -m py_compile "$f" 2>&1); rc=$? ;;
    *.php)
      have php || { report SKIP "$f" "php not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(php -l "$f" 2>&1); rc=$? ;;
    *.rb)
      have ruby || { report SKIP "$f" "ruby not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(ruby -c "$f" 2>&1); rc=$? ;;
    *.sh|*.bash|*.zsh)
      out=$(bash -n "$f" 2>&1); rc=$? ;;
    *.go)
      have gofmt || { report SKIP "$f" "gofmt not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(gofmt -e "$f" 2>&1 >/dev/null); rc=$? ;;
    *.lua)
      have luac || { report SKIP "$f" "luac not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(luac -p "$f" 2>&1); rc=$? ;;
    *.pl|*.pm)
      have perl || { report SKIP "$f" "perl not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(perl -c "$f" 2>&1); rc=$? ;;
    *.json)
      have python3 || { report SKIP "$f" "python3 not installed"; SKIPPED=$((SKIPPED+1)); return; }
      out=$(python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>&1); rc=$? ;;
    *.rs)
      report SKIP "$f" "run 'cargo check' at crate level"; SKIPPED=$((SKIPPED+1)); return ;;
    *.java|*.kt|*.kts|*.cs|*.swift|*.scala|*.dart|*.ex|*.exs)
      report SKIP "$f" "run the project build for this language"; SKIPPED=$((SKIPPED+1)); return ;;
    *.vue|*.svelte|*.astro|*.html|*.htm|*.ejs|*.hbs|*.handlebars)
      report SKIP "$f" "template: check via project build / manual diff review"; SKIPPED=$((SKIPPED+1)); return ;;
    *.css|*.scss|*.sass|*.less|*.sql)
      report SKIP "$f" "no standalone parser wired up"; SKIPPED=$((SKIPPED+1)); return ;;
    *)
      report SKIP "$f" "unknown extension"; SKIPPED=$((SKIPPED+1)); return ;;
  esac

  CHECKED=$((CHECKED+1))
  if [ "$rc" -eq 0 ]; then
    report OK "$f"
  else
    FAIL=$((FAIL+1))
    report FAIL "$f"
    printf '%s\n' "$out" | sed 's/^/         /'
  fi
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do check_one "$f"; done
else
  while IFS= read -r f; do [ -n "$f" ] && check_one "$f"; done
fi

printf '\n%d checked, %d failed, %d skipped\n' "$CHECKED" "$FAIL" "$SKIPPED"
[ "$FAIL" -eq 0 ]
