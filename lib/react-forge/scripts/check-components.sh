#!/bin/bash
# React Component Structure Analyzer
# Analyzes your React components for patterns and potential improvements
#
# Usage: ./check-components.sh [project-path]
#
# Read-only: this script never modifies the project.
#
# This script checks:
# - Component organization
# - Client vs Server Components ('use client' / 'use server' directives)
# - Props patterns
# - Component size and complexity

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

# grep -r over SRC_DIR: src_grep [grep-options...]  (pass the pattern as -e PAT).
# Runs from inside SRC_DIR so --exclude-dir never matches the scan root
# itself. Never fails (no matches is not an error).
src_grep() {
    (cd "$SRC_DIR" && grep -r "${GREP_EXCLUDES[@]}" "$@" . 2>/dev/null) || true
}

# count_lines PATTERN [--include=...]: number of matching lines (ERE)
count_lines() {
    src_grep -E "${@:2}" -e "$1" | wc -l | tr -d ' '
}

# has_match PATTERN [--include=...]: true if any file matches (ERE)
has_match() {
    [ -n "$(src_grep -lE "${@:2}" -e "$1")" ]
}

# find under a directory, pruning excluded dirs. Extra args are the
# expression, e.g. src_find "$dir" \( -name '*.tsx' \) -type f -print
src_find() {
    local root="$1"
    shift
    find "$root" -mindepth 1 -type d \( "${FIND_PRUNE[@]}" \) -prune -o "$@" 2>/dev/null || true
}

# Print files whose directive prologue (leading string-literal statements,
# skipping blank lines and comments) contains the given directive, in
# either quote style.
# Usage: files_with_directive "use client"
files_with_directive() {
    # shellcheck disable=SC2016 # awk program, not shell expansions
    src_find "$SRC_DIR" \( -name '*.tsx' -o -name '*.jsx' -o -name '*.ts' -o -name '*.js' \) -type f -print0 |
        xargs -0 -r awk -v want="$1" '
            FNR == 1 { incomment = 0 }
            {
                line = $0
                if (incomment) {
                    p = index(line, "*/")
                    if (!p) next
                    line = substr(line, p + 2)
                    incomment = 0
                }
                sub(/^[ \t\r]+/, "", line); sub(/[ \t\r]+$/, "", line)
                while (line ~ /^\/\*/) {
                    p = index(line, "*/")
                    if (!p) { incomment = 1; next }
                    line = substr(line, p + 2)
                    sub(/^[ \t\r]+/, "", line)
                }
                if (line == "" || line ~ /^\/\//) next
                if (match(line, /^"[^"]*"|^\047[^\047]*\047/)) {
                    d = substr(line, 2, RLENGTH - 2)
                    rest = substr(line, RLENGTH + 1)
                    sub(/^[ \t]*;?[ \t]*/, "", rest)
                    # Allow trailing comments: "use client"; // note  or  /* note */
                    while (rest ~ /^\/\*/) {
                        p = index(substr(rest, 3), "*/")
                        if (!p) { incomment = 1; rest = ""; break }
                        rest = substr(rest, p + 4)
                        sub(/^[ \t]+/, "", rest)
                    }
                    if (rest == "" || rest ~ /^\/\//) {
                        if (d == want) { print FILENAME; nextfile }
                        next    # another directive, e.g. "use strict"
                    }
                }
                nextfile        # first real statement: prologue is over
            }' 2>/dev/null || true
}

echo "=== React Component Analysis ==="
echo "Scanning:  $SRC_DIR"
echo "Excluding: ${EXCLUDE_DIRS[*]}"
echo ""

# Count components
echo "=== Component Summary ==="
echo ""

FUNC_COMPONENTS=$(count_lines "export.*function [A-Z]" --include="*.tsx" --include="*.jsx")
ARROW_COMPONENTS=$(count_lines "export const [A-Z].*=.*=>" --include="*.tsx" --include="*.jsx")

echo "Function components:       $FUNC_COMPONENTS"
echo "Arrow function components: $ARROW_COMPONENTS"
echo ""

CLIENT_COMPONENTS=$(files_with_directive "use client" | wc -l | tr -d ' ')
echo "Client Components ('use client'):     $CLIENT_COMPONENTS files"

SERVER_ACTIONS=$(files_with_directive "use server" | wc -l | tr -d ' ')
echo "Server Action modules ('use server'): $SERVER_ACTIONS files"
echo "  (module-level directives only; inline 'use server' functions are not counted)"
echo ""

# Component directories
echo "=== Component Organization ==="
echo ""

COMPONENT_DIRS=("components" "ui" "features" "pages" "app" "layouts" "views")
for dir in "${COMPONENT_DIRS[@]}"; do
    if [ -d "$SRC_DIR/$dir" ]; then
        count=$(src_find "$SRC_DIR/$dir" \( -name "*.tsx" -o -name "*.jsx" \) -type f -print | wc -l | tr -d ' ')
        echo "✓ $dir/: $count files"
    fi
done
echo ""

# Performance-related patterns
echo "=== Performance Patterns ==="
echo ""

# memo( or React.memo( -- not useMemo( or other identifiers containing memo
MEMO_USAGE=$(count_lines '(^|[^A-Za-z0-9_.])(React\.)?memo\(' --include="*.tsx" --include="*.jsx")
echo "React.memo usage: $MEMO_USAGE"

FORWARD_REF=$(count_lines '(^|[^A-Za-z0-9_])forwardRef' --include="*.tsx" --include="*.jsx")
echo "forwardRef usage: $FORWARD_REF (React 19: ref is a regular prop; forwardRef is only needed on React 18)"

LAZY_COMPONENTS=$(count_lines '(^|[^A-Za-z0-9_])lazy\(' --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js")
echo "lazy() calls:     $LAZY_COMPONENTS"
echo ""

# Check for large components
echo "=== Component Complexity Check ==="
echo ""
echo "Large components (>200 lines):"

LARGE_FOUND=0
while IFS= read -r -d '' file; do
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt 200 ]; then
        echo "  ⚠️  $file: $lines lines"
        LARGE_FOUND=$((LARGE_FOUND + 1))
    fi
done < <(src_find "$SRC_DIR" \( -name "*.tsx" -o -name "*.jsx" \) -type f -print0)

if [ "$LARGE_FOUND" -eq 0 ]; then
    echo "  None found"
else
    echo ""
    echo "Consider splitting components >200 lines into smaller pieces"
fi
echo ""

# Props patterns
echo "=== Props Patterns ==="
echo ""

INTERFACE_PROPS=$(count_lines '(^|[^A-Za-z0-9_])interface [A-Za-z0-9_]*Props' --include="*.tsx")
echo "TypeScript interface props: $INTERFACE_PROPS"

TYPE_PROPS=$(count_lines '(^|[^A-Za-z0-9_])type [A-Za-z0-9_]*Props' --include="*.tsx")
echo "TypeScript type props:      $TYPE_PROPS"

# PropTypes (legacy)
PROPTYPES=$(count_lines "PropTypes" --include="*.tsx" --include="*.jsx" --include="*.js")
if [ "$PROPTYPES" -gt 0 ]; then
    echo "⚠️  PropTypes (legacy):       $PROPTYPES"
    echo "   React 19 ignores propTypes; consider migrating to TypeScript"
fi
echo ""

# Check for common patterns
echo "=== Common Patterns Detected ==="
echo ""

PATTERNS_FOUND=0

if has_match '\.Provider|\.Consumer|createContext' --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js"; then
    echo "✓ Context/Provider pattern detected"
    PATTERNS_FOUND=1
fi

if has_match 'render=\{' --include="*.tsx" --include="*.jsx"; then
    echo "✓ Render props pattern detected"
    PATTERNS_FOUND=1
fi

if has_match '(^|[^A-Za-z0-9_])children\(' --include="*.tsx" --include="*.jsx"; then
    echo "✓ Children as function pattern detected"
    PATTERNS_FOUND=1
fi

if [ "$PATTERNS_FOUND" -eq 0 ]; then
    echo "  None detected"
fi
echo ""

# Recommendations
echo "=== Recommendations ==="
echo ""
echo "1. Use TypeScript interfaces for all component props"
echo "2. Split large components (>200 lines) into smaller pieces"
echo "3. Profile first (React DevTools Profiler). Memoize only measured hotspots;"
echo "   with React Compiler enabled, manual memo is mostly unnecessary"
echo "4. Lazy load heavy route-level components if your framework doesn't already split per route"
echo "5. Organize by feature rather than type for larger apps"
echo "6. Use 'use client' only when needed (hooks, events, browser APIs)"
echo ""
