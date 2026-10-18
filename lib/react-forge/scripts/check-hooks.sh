#!/bin/bash
# React Hooks Usage Analyzer
# Scans your React project for hooks usage patterns and potential issues
#
# Usage: ./check-hooks.sh [project-path]
#
# Read-only: this script never modifies the project.
#
# This script analyzes:
# - Hook usage patterns
# - Effects that may need a dependency review
# - Custom hooks organization
#
# It is a grep-based heuristic. For real rules-of-hooks and dependency
# checking, run eslint-plugin-react-hooks.

set -uo pipefail

PROJECT_PATH="${1:-.}"
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: '$PROJECT_PATH' is not a directory" >&2
    exit 1
fi

SRC_DIR="$PROJECT_PATH/src"
if [ ! -d "$SRC_DIR" ]; then
    SRC_DIR="$PROJECT_PATH"
fi

# Directories never scanned (dependencies, build output, caches, VCS)
EXCLUDE_DIRS=(node_modules .next dist build coverage .git out .turbo)
GREP_EXCLUDES=()
FIND_PRUNE=()
for d in "${EXCLUDE_DIRS[@]}"; do
    GREP_EXCLUDES+=("--exclude-dir=$d")
    FIND_PRUNE+=(-name "$d" -o)
done
unset 'FIND_PRUNE[${#FIND_PRUNE[@]}-1]' # drop trailing -o

SOURCE_INCLUDES=(--include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js")
TEST_EXCLUDES=(--exclude="*.test.*" --exclude="*.spec.*")

# grep -r over SRC_DIR: src_grep [grep-options...]  (pass the pattern as -e PAT).
# Runs from inside SRC_DIR so --exclude-dir never matches the scan root
# itself. Never fails (no matches is not an error).
src_grep() {
    (cd "$SRC_DIR" && grep -r "${GREP_EXCLUDES[@]}" "$@" . 2>/dev/null) || true
}

# Count calls to a hook (occurrences, not lines), outside test files.
# Matches `useX(` and `React.useX(`, but not `fooUseX(` or `obj.useX(`.
count_hook() {
    local hook="$1"
    src_grep -oE "${SOURCE_INCLUDES[@]}" "${TEST_EXCLUDES[@]}" \
        -e "(^|[^A-Za-z0-9_.]|React\.)${hook}\(" | wc -l | tr -d ' '
}

# print_list "none message" N: print the first N lines of stdin, or the
# message if stdin is empty.
print_list() {
    local none_msg="$1" max="$2" out total
    out=$(cat)
    if [ -z "$out" ]; then
        echo "  $none_msg"
        return
    fi
    total=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    printf '%s\n' "$out" | head -n "$max" | sed 's/^/  /'
    if [ "$total" -gt "$max" ]; then
        echo "  ... ($total total, showing first $max)"
    fi
}

echo "=== React Hooks Usage Analysis ==="
echo "Scanning:  $SRC_DIR"
echo "Excluding: ${EXCLUDE_DIRS[*]} (and *.test.* / *.spec.* files for counts)"
echo ""

echo "=== Hook Usage Summary ==="
echo ""

echo "Core Hooks:"
printf "  useState:         %s\n" "$(count_hook 'useState')"
printf "  useEffect:        %s\n" "$(count_hook 'useEffect')"
printf "  useContext:       %s\n" "$(count_hook 'useContext')"
printf "  useReducer:       %s\n" "$(count_hook 'useReducer')"
printf "  useRef:           %s\n" "$(count_hook 'useRef')"
echo ""

echo "Performance Hooks:"
printf "  useMemo:          %s\n" "$(count_hook 'useMemo')"
printf "  useCallback:      %s\n" "$(count_hook 'useCallback')"
echo ""

echo "React 18 Hooks:"
printf "  useTransition:    %s\n" "$(count_hook 'useTransition')"
printf "  useDeferredValue: %s\n" "$(count_hook 'useDeferredValue')"
printf "  useId:            %s\n" "$(count_hook 'useId')"
printf "  useSyncExtStore:  %s\n" "$(count_hook 'useSyncExternalStore')"
echo ""

echo "React 19 APIs:"
printf "  useActionState:   %s\n" "$(count_hook 'useActionState')"
printf "  useOptimistic:    %s\n" "$(count_hook 'useOptimistic')"
printf "  useFormStatus:    %s\n" "$(count_hook 'useFormStatus')"
printf "  use():            %s\n" "$(count_hook 'use')"
echo ""

echo "Other Hooks:"
printf "  useLayoutEffect:  %s\n" "$(count_hook 'useLayoutEffect')"
printf "  useImperativeHandle: %s\n" "$(count_hook 'useImperativeHandle')"
printf "  useDebugValue:    %s\n" "$(count_hook 'useDebugValue')"
echo ""

echo "=== Custom Hooks Found ==="
echo ""
src_grep -E "${SOURCE_INCLUDES[@]}" "${TEST_EXCLUDES[@]}" \
    -e 'export.*(function use[A-Z]|const use[A-Z][A-Za-z0-9_]*[[:space:]]*=)' |
    print_list "No custom hooks found" 20
echo ""

echo "=== Hooks Organization ==="
if [ -d "$SRC_DIR/hooks" ]; then
    echo "✓ hooks/ directory exists"
    echo "  Files:"
    (cd "$SRC_DIR/hooks" && find . -mindepth 1 -type d \( "${FIND_PRUNE[@]}" \) -prune -o \
        -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) -print 2>/dev/null) |
        sed 's|^\./||' | sort | print_list "(no hook source files)" 50
else
    echo "⚠️  No hooks/ directory found"
    echo "   Consider a hooks/ directory for shared custom hooks"
fi
echo ""

echo "=== Effects To Review (heuristics; single-line matches only) ==="
echo ""

echo "Effects with empty dependency arrays — review manually that they"
echo "really should run only on mount (they must not read changing props/state):"
src_grep -nE "${SOURCE_INCLUDES[@]}" "${TEST_EXCLUDES[@]}" -e 'useEffect\(.*\[\][[:space:]]*\)' |
    print_list "None found" 5
echo ""

echo "Effects without a dependency array (run after every render):"
src_grep -nE "${SOURCE_INCLUDES[@]}" "${TEST_EXCLUDES[@]}" -e 'useEffect\([^,]*\)' |
    { grep -v '\[' || true; } | print_list "None found" 5
echo ""

echo "Informational: useState with an object initial value (fine; update it"
echo "immutably with a new object, and split it if fields change independently):"
src_grep -nE "${SOURCE_INCLUDES[@]}" "${TEST_EXCLUDES[@]}" -e 'useState(<[^>]*>)?\(\{' |
    print_list "None found" 5
echo ""

echo "=== Recommendations ==="
echo ""
echo "1. Run eslint-plugin-react-hooks for real rules-of-hooks and dependency checks"
echo "2. Profile first (React DevTools Profiler). Memoize only measured hotspots;"
echo "   with React Compiler enabled, manual memo is mostly unnecessary"
echo "3. Prefer deriving values during render over syncing state in effects"
echo "4. React 19: consider useActionState / useOptimistic for form handling"
echo "5. Keep shared custom hooks in a hooks/ directory"
echo ""
