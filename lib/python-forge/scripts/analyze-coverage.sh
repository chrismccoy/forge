#!/bin/bash
# Analyze Python test coverage and identify untested code.
# Runs the project's test suite and writes .coverage and htmlcov/.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Test Coverage Analysis ==="
echo ""

# Determine source directory
if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

# Directories never analyzed (matters for flat layouts where SRC_DIR=".")
EXCLUDES=(--exclude-dir=.venv --exclude-dir=venv --exclude-dir=.git --exclude-dir=build \
    --exclude-dir=dist --exclude-dir=node_modules --exclude-dir=.tox --exclude-dir=__pycache__)
PRUNE=( \( -name .venv -o -name venv -o -name .git -o -name build -o -name dist \
    -o -name node_modules -o -name .tox -o -name __pycache__ -o -name tests \) -prune -o )

# Determine runner: only use uv when the project is uv-managed.
# --frozen keeps uv from rewriting uv.lock.
if [ -f "uv.lock" ] && command -v uv &> /dev/null; then
    RUN_CMD="uv run --frozen"
elif [ -f ".venv/bin/activate" ]; then
    RUN_CMD=""
    source .venv/bin/activate
else
    RUN_CMD=""
fi

# Interpreter: uv/.venv provide "python"; otherwise prefer python3
if [ -n "$RUN_CMD" ] || command -v python &> /dev/null; then
    PY="python"
else
    PY="python3"
fi

if ! $RUN_CMD $PY -c "import pytest" 2>/dev/null; then
    echo -e "${RED}pytest not installed${NC}"
    echo "Install with: uv add --dev pytest pytest-cov"
    exit 1
fi

# Check if pytest-cov is available
if ! $RUN_CMD $PY -c "import pytest_cov" 2>/dev/null; then
    echo -e "${YELLOW}pytest-cov not installed${NC}"
    echo "Install with: uv add --dev pytest-cov"
    echo ""
    echo "Running tests without coverage..."
    $RUN_CMD $PY -m pytest -v || true
    exit 0
fi

# Run tests with coverage
echo "Running tests with coverage..."
echo ""

$RUN_CMD $PY -m pytest --cov="$SRC_DIR" --cov-report=term-missing --cov-report=html -v 2>&1 || true

echo ""
echo "=== Coverage Summary ==="
echo ""

# Parse coverage data if available
if [ -f ".coverage" ]; then
    # Show files with low coverage
    echo "Files with low coverage (<80%):"
    echo ""

    $RUN_CMD $PY -m coverage report --fail-under=0 2>/dev/null | \
        grep -E "^[a-zA-Z_/.].*[0-9]+%" | grep -v "^TOTAL" | \
        while IFS= read -r line; do
            coverage=$(echo "$line" | grep -oE "[0-9]+%" | tail -1 | tr -d '%')
            if [ -n "$coverage" ] && [ "$coverage" -lt 80 ]; then
                echo -e "${YELLOW}$line${NC}"
            fi
        done || echo "Could not parse coverage data"

    echo ""

    # Show totally uncovered files
    echo "Completely uncovered files (0%):"
    UNCOVERED=$($RUN_CMD $PY -m coverage report --fail-under=0 2>/dev/null | \
        grep -E "^[a-zA-Z_/.].*[[:space:]]0%([[:space:]]|$)" | grep -v "^TOTAL" || true)
    if [ -n "$UNCOVERED" ]; then
        echo -e "${RED}$UNCOVERED${NC}"
    else
        echo "None found"
    fi
fi

echo ""

# Check test to code ratio
echo "=== Test Analysis ==="
echo ""

TEST_FILES=$(find tests -name "test_*.py" 2>/dev/null | wc -l)
TEST_FUNCS=$(grep -rE "^\s*(async )?def test_" tests --include="*.py" "${EXCLUDES[@]}" 2>/dev/null | wc -l)
SRC_FILES=$(find "$SRC_DIR" "${PRUNE[@]}" -name "*.py" ! -name "__init__.py" ! -name "conftest.py" -print 2>/dev/null | wc -l)
SRC_FUNCS=$(grep -rE "^\s*(async )?def " "$SRC_DIR" --include="*.py" "${EXCLUDES[@]}" --exclude-dir=tests 2>/dev/null | grep -v "def __" | wc -l)

echo "Test files: $TEST_FILES"
echo "Test functions: $TEST_FUNCS"
echo "Source files: $SRC_FILES"
echo "Source functions: $SRC_FUNCS"

if [ "$SRC_FUNCS" -gt 0 ]; then
    RATIO=$(awk -v t="$TEST_FUNCS" -v s="$SRC_FUNCS" 'BEGIN { printf "%.2f", t / s }')
    echo "Test to function ratio: $RATIO"
fi

echo ""

# Check for missing test files
echo "=== Missing Tests ==="
echo ""

echo "Source files without a matching test_<name>.py anywhere under tests/:"
MISSING=0
while IFS= read -r -d '' src_file; do
    base_name=$(basename "$src_file" .py)
    if [ -z "$(find tests -name "test_${base_name}.py" -print -quit 2>/dev/null)" ]; then
        echo -e "${YELLOW}  Missing: test_${base_name}.py (for $src_file)${NC}"
        MISSING=$((MISSING + 1))
    fi
done < <(find "$SRC_DIR" "${PRUNE[@]}" -name "*.py" ! -name "__init__.py" ! -name "__main__.py" \
    ! -name "conftest.py" ! -name "test_*.py" -print0 2>/dev/null)
if [ "$MISSING" -eq 0 ]; then
    echo -e "${GREEN}  None${NC}"
fi

echo ""

# HTML report location
if [ -d "htmlcov" ]; then
    echo -e "${GREEN}HTML coverage report generated: htmlcov/index.html${NC}"
fi

echo ""
echo "Done!"
