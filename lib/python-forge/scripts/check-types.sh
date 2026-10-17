#!/bin/bash
# Check Python type hints with mypy or pyright.
# Runs the type checker, then reports annotation coverage and typing style.
# Exit code is the type checker's result (0 = clean).

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Python Type Checking ==="
echo ""

# Determine runner: only use uv when the project is uv-managed.
# --frozen keeps uv from rewriting uv.lock.
if [ -f "uv.lock" ] && command -v uv &> /dev/null; then
    RUN_CMD="uv run --frozen"
    echo "Using uv (uv.lock found)"
elif [ -f ".venv/bin/activate" ]; then
    RUN_CMD=""
    source .venv/bin/activate
    echo "Using virtual environment"
else
    RUN_CMD=""
    echo "Using current Python environment"
fi

# Find source directory
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

echo "Checking directory: $SRC_DIR"
echo ""

# Interpreter: uv/.venv provide "python"; otherwise prefer python3
if [ -n "$RUN_CMD" ] || command -v python &> /dev/null; then
    PY="python"
else
    PY="python3"
fi

STATUS=0

# Try mypy first
if $RUN_CMD $PY -c "import mypy" 2>/dev/null; then
    echo "Running mypy..."
    echo ""
    $RUN_CMD $PY -m mypy "$SRC_DIR" --ignore-missing-imports 2>&1 || STATUS=$?

# Try pyright as fallback (project dependency first, then PATH)
elif [ -n "$RUN_CMD" ] && $RUN_CMD pyright --version &> /dev/null; then
    echo "Running pyright..."
    echo ""
    $RUN_CMD pyright "$SRC_DIR" 2>&1 || STATUS=$?
elif command -v pyright &> /dev/null; then
    echo "Running pyright..."
    echo ""
    pyright "$SRC_DIR" 2>&1 || STATUS=$?
else
    echo -e "${YELLOW}Neither mypy nor pyright found.${NC}"
    echo ""
    echo "Install with:"
    echo "  uv add --dev mypy"
    echo "  # or"
    echo "  pip install mypy"
    STATUS=1
fi

echo ""
if [ "$STATUS" -eq 0 ]; then
    echo -e "${GREEN}No type errors found!${NC}"
else
    echo -e "${RED}Type errors detected (or no checker available). See above for details.${NC}"
fi

# Annotation coverage via ast (handles multi-line signatures)
echo ""
echo "=== Type Coverage Summary ==="
echo ""

python3 -I - "$SRC_DIR" <<'PY'
import ast, sys
from pathlib import Path

SKIP = {".venv", "venv", ".git", "build", "dist", "node_modules", ".tox", "__pycache__"}
total = returns = params_total = params_typed = 0
for p in Path(sys.argv[1]).rglob("*.py"):
    if SKIP & set(p.parts):
        continue
    try:
        tree = ast.parse(p.read_text(encoding="utf-8", errors="replace"))
    except SyntaxError:
        continue
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            total += 1
            returns += node.returns is not None
            args = node.args.posonlyargs + node.args.args + node.args.kwonlyargs
            args = [a for a in args if a.arg not in ("self", "cls")]
            params_total += len(args)
            params_typed += sum(a.annotation is not None for a in args)
if total:
    print(f"Functions with return type hints: {returns} / {total} ({returns * 100 // total}%)")
    if params_total:
        print(f"Annotated parameters: {params_typed} / {params_total} ({params_typed * 100 // params_total}%)")
else:
    print("No functions found to analyze")
PY

# Check for common typing issues
echo ""
echo "=== Typing Best Practices Check ==="
echo ""

# Lines importing typing aliases that have built-in generic replacements
OLD_TYPING=$(grep -rE "from typing import.*\b(List|Dict|Set|Tuple)\b" "$SRC_DIR" --include="*.py" "${EXCLUDES[@]}" 2>/dev/null | wc -l)
if [ "$OLD_TYPING" -gt 0 ]; then
    echo -e "${YELLOW}Found $OLD_TYPING import line(s) using deprecated typing.List/Dict/Set/Tuple${NC}"
    echo "  Consider using built-in generics: list[str], dict[str, int], set[int], tuple[int, ...]"
else
    echo -e "${GREEN}Using modern type syntax (no deprecated typing imports)${NC}"
fi

# Check for Optional usage vs union
OPTIONAL_COUNT=$(grep -r "Optional\[" "$SRC_DIR" --include="*.py" "${EXCLUDES[@]}" 2>/dev/null | wc -l)
if [ "$OPTIONAL_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $OPTIONAL_COUNT line(s) with Optional[X]${NC}"
    echo "  Consider using X | None syntax (Python 3.10+)"
else
    echo -e "${GREEN}Using modern union syntax (X | None)${NC}"
fi

echo ""
echo "Done!"
exit "$STATUS"
