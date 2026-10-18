#!/bin/bash
# React Testing Coverage Analyzer
# Analyzes test coverage and testing patterns in your React project
#
# Usage: ./check-testing.sh [project-path]
#
# Read-only: this script never modifies the project or runs its tests.
#
# This script checks:
# - Test file organization
# - Testing library usage
# - Component test coverage (by file count)
# - Testing patterns

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
PKG="$PROJECT_PATH/package.json"

# Directories never scanned (dependencies, build output, caches, VCS)
EXCLUDE_DIRS=(node_modules .next dist build coverage .git out .turbo)
GREP_EXCLUDES=()
FIND_PRUNE=()
for d in "${EXCLUDE_DIRS[@]}"; do
    GREP_EXCLUDES+=("--exclude-dir=$d")
    FIND_PRUNE+=(-name "$d" -o)
done
unset 'FIND_PRUNE[${#FIND_PRUNE[@]}-1]' # drop trailing -o

# Test files: *.test.* and *.spec.* for js/jsx/ts/tsx
TEST_EXTS=(js jsx ts tsx)
TEST_INCLUDES=()
TEST_FIND=()
for kind in test spec; do
    for ext in "${TEST_EXTS[@]}"; do
        TEST_INCLUDES+=("--include=*.$kind.$ext")
        TEST_FIND+=(-name "*.$kind.$ext" -o)
    done
done
unset 'TEST_FIND[${#TEST_FIND[@]}-1]' # drop trailing -o

# grep -r over SRC_DIR: src_grep [grep-options...]  (pass the pattern as -e PAT).
# Runs from inside SRC_DIR so --exclude-dir never matches the scan root
# itself. Never fails (no matches is not an error).
src_grep() {
    (cd "$SRC_DIR" && grep -r "${GREP_EXCLUDES[@]}" "$@" . 2>/dev/null) || true
}

# count_in_tests PATTERN: number of occurrences (ERE) in test files
count_in_tests() {
    src_grep -oE "${TEST_INCLUDES[@]}" -e "$1" | wc -l | tr -d ' '
}

# find under SRC_DIR, pruning excluded dirs
src_find() {
    find "$SRC_DIR" -mindepth 1 -type d \( "${FIND_PRUNE[@]}" \) -prune -o "$@" 2>/dev/null || true
}

# pkg_has_key NAME: package.json declares "NAME": (dependency or config key)
pkg_has_key() {
    [ -f "$PKG" ] && grep -qE "\"$1\"[[:space:]]*:" "$PKG" 2>/dev/null
}

echo "=== React Testing Analysis ==="
echo "Scanning:  $SRC_DIR"
echo "Excluding: ${EXCLUDE_DIRS[*]}"
echo ""

# Package manager (from lockfile)
if [ -f "$PROJECT_PATH/pnpm-lock.yaml" ]; then
    PM="pnpm"; PM_ADD_DEV="pnpm add -D"; PM_EXEC="pnpm exec"
elif [ -f "$PROJECT_PATH/yarn.lock" ]; then
    PM="yarn"; PM_ADD_DEV="yarn add -D"; PM_EXEC="yarn"
elif [ -f "$PROJECT_PATH/bun.lock" ] || [ -f "$PROJECT_PATH/bun.lockb" ]; then
    PM="bun"; PM_ADD_DEV="bun add -d"; PM_EXEC="bunx"
else
    PM="npm"; PM_ADD_DEV="npm install -D"; PM_EXEC="npx"
fi

echo "=== Testing Framework Detection ==="
echo ""
echo "Package manager: $PM"

if pkg_has_key "vitest"; then
    echo "✓ Vitest detected"
    FRAMEWORK="vitest"
elif pkg_has_key "jest"; then
    echo "✓ Jest detected"
    FRAMEWORK="jest"
else
    echo "⚠️  No test runner detected (no \"vitest\" or \"jest\" key in package.json)"
    echo "   Recommended: Vitest. Install: $PM_ADD_DEV vitest jsdom"
    FRAMEWORK="none"
fi

if pkg_has_key "@testing-library/react"; then
    echo "✓ React Testing Library detected"
else
    echo "⚠️  React Testing Library not found"
    echo "   Install: $PM_ADD_DEV @testing-library/react @testing-library/dom @testing-library/jest-dom"
fi

if pkg_has_key "@testing-library/user-event"; then
    echo "✓ @testing-library/user-event detected"
else
    echo "⚠️  @testing-library/user-event not found"
    echo "   Install: $PM_ADD_DEV @testing-library/user-event"
fi

echo ""

echo "=== Test File Summary ==="
echo ""

TEST_FILES=$(src_find -type f \( "${TEST_FIND[@]}" \) -print | wc -l | tr -d ' ')
COMPONENT_FILES=$(src_find -type f \( -name "*.tsx" -o -name "*.jsx" \) \
    ! -name "*.test.*" ! -name "*.spec.*" ! -name "*.stories.*" -print | wc -l | tr -d ' ')

echo "Test files:      $TEST_FILES"
echo "Component files: $COMPONENT_FILES (.tsx/.jsx, excluding tests and stories)"

if [ "$COMPONENT_FILES" -gt 0 ]; then
    COVERAGE_PCT=$((TEST_FILES * 100 / COMPONENT_FILES))
    echo "Test ratio:      ~${COVERAGE_PCT}% (test files per component file; not line coverage)"
fi
echo ""

echo "=== Test Organization ==="
echo ""

COLOCATED=$(src_find -type f \( "${TEST_FIND[@]}" \) -print | grep -c -v '/__tests__/' || true)
echo "Co-located tests: $COLOCATED"

TESTS_DIR=$(src_find -type d -name "__tests__" -print | wc -l | tr -d ' ')
echo "__tests__ dirs:   $TESTS_DIR"

echo ""

echo "=== Testing Patterns Used ==="
echo ""

RENDER_COUNT=$(count_in_tests '(^|[^A-Za-z0-9_.])render\(')
echo "render() calls:           $RENDER_COUNT"

SCREEN_COUNT=$(count_in_tests '(^|[^A-Za-z0-9_])screen\.')
echo "screen.* queries:         $SCREEN_COUNT"

USER_EVENT=$(count_in_tests '(^|[^A-Za-z0-9_])user(Event)?\.(click|type|keyboard|hover|tab|selectOptions|clear|upload|pointer)\(')
echo "userEvent interactions:   $USER_EVENT"

WAIT_FOR=$(count_in_tests '(^|[^A-Za-z0-9_])waitFor(ElementToBeRemoved)?\(')
echo "waitFor calls:            $WAIT_FOR"

RENDER_HOOK=$(count_in_tests '(^|[^A-Za-z0-9_])renderHook\(')
echo "renderHook calls:         $RENDER_HOOK"

echo ""

echo "=== Query Types (Best Practices) ==="
echo ""

echo "Accessibility queries (preferred):"
BY_ROLE=$(count_in_tests '(get|query|find)(All)?ByRole')
echo "  ByRole:         $BY_ROLE"

BY_LABEL=$(count_in_tests '(get|query|find)(All)?ByLabelText')
echo "  ByLabelText:    $BY_LABEL"

BY_TEXT=$(count_in_tests '(get|query|find)(All)?ByText')
echo "  ByText:         $BY_TEXT"

echo ""
echo "Test IDs (last resort):"
BY_TESTID=$(count_in_tests '(get|query|find)(All)?ByTestId')
echo "  ByTestId:       $BY_TESTID"

if [ "$BY_TESTID" -gt "$BY_ROLE" ]; then
    echo ""
    echo "⚠️  Consider using more accessibility queries (ByRole, ByLabelText)"
fi

echo ""

echo "=== Components Without Tests ==="
echo ""

# has_test BASE_PATH: a .test/.spec file with any js/jsx/ts/tsx extension exists
has_test() {
    local base="$1" kind ext
    for kind in test spec; do
        for ext in "${TEST_EXTS[@]}"; do
            [ -f "$base.$kind.$ext" ] && return 0
        done
    done
    return 1
}

UNTESTED=0
while IFS= read -r -d '' component; do
    case "$component" in
        */__tests__/*) continue ;;
    esac
    base="${component%.*}"
    name=$(basename "$base")
    dir=$(dirname "$component")
    if ! has_test "$base" && ! has_test "$dir/__tests__/$name"; then
        UNTESTED=$((UNTESTED + 1))
        if [ "$UNTESTED" -le 10 ]; then
            echo "  No test: $component"
        fi
    fi
done < <(src_find -type f \( -name "*.tsx" -o -name "*.jsx" \) \
    ! -name "*.test.*" ! -name "*.spec.*" ! -name "*.stories.*" -print0)

if [ "$COMPONENT_FILES" -eq 0 ]; then
    echo "  No component files found"
elif [ "$UNTESTED" -eq 0 ]; then
    echo "  None (every component file has a matching test or spec file)"
elif [ "$UNTESTED" -gt 10 ]; then
    echo "  ... ($UNTESTED total, showing first 10)"
fi
echo ""

case "$FRAMEWORK" in
    vitest) COVERAGE_CMD="$PM_EXEC vitest run --coverage" ;;
    jest)   COVERAGE_CMD="$PM_EXEC jest --coverage" ;;
    *)      COVERAGE_CMD="$PM_EXEC vitest run --coverage   (after installing Vitest)" ;;
esac

echo "=== Recommendations ==="
echo ""
echo "1. Prefer ByRole > ByLabelText > ByText > ByTestId"
echo "2. Use userEvent.setup() for user interactions"
echo "3. Test behavior, not implementation details"
echo "4. Add custom render with providers for context"
echo "5. Use findBy* / waitFor for async UI"
echo "6. Co-locate tests with components (Component.test.tsx)"
echo "7. Run tests with coverage: $COVERAGE_CMD"
echo ""
