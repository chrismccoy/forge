#!/bin/bash
# Analyze Python dependencies and check for issues.
# Inspects config and lockfiles, runs pip-audit and an outdated-package listing if available.
# Changes no project files; in uv projects, `uv run --frozen` may create or sync .venv.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Dependency Analysis ==="
echo ""

# Check for pyproject.toml
if [ -f "pyproject.toml" ]; then
    echo -e "${GREEN}Found pyproject.toml${NC}"

    # Extract project info
    PROJECT_NAME=$(grep -E "^name = " pyproject.toml | head -1 | sed 's/name = "\(.*\)"/\1/')
    PROJECT_VERSION=$(grep -E "^version = " pyproject.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
    PYTHON_REQ=$(grep -E "^requires-python" pyproject.toml | sed 's/requires-python = "\(.*\)"/\1/')

    echo "  Project: $PROJECT_NAME"
    echo "  Version: $PROJECT_VERSION"
    echo "  Python: $PYTHON_REQ"
    echo ""
elif [ -f "setup.py" ]; then
    echo -e "${YELLOW}Found setup.py (consider migrating to pyproject.toml)${NC}"
    echo ""
elif [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}Found requirements.txt (consider migrating to pyproject.toml)${NC}"
    echo ""
else
    echo -e "${RED}No Python project configuration found${NC}"
    exit 1
fi

# Check package manager
echo "=== Package Manager ==="
echo ""

if [ -f "uv.lock" ]; then
    echo -e "${GREEN}Using uv (recommended)${NC}"

    # Count dependencies
    DEP_COUNT=$(grep -c "^\[\[package\]\]" uv.lock 2>/dev/null || true)
    echo "  Total packages: $DEP_COUNT"
elif [ -f "poetry.lock" ]; then
    echo -e "${BLUE}Using Poetry${NC}"

    DEP_COUNT=$(grep -c "^\[\[package\]\]" poetry.lock 2>/dev/null || true)
    echo "  Total packages: $DEP_COUNT"
elif [ -f "Pipfile.lock" ]; then
    echo -e "${BLUE}Using Pipenv${NC}"
elif [ -f "requirements.txt" ]; then
    echo "Using pip with requirements.txt"
    DEP_COUNT=$(grep -v "^#" requirements.txt | grep -v "^$" | wc -l)
    echo "  Direct dependencies: $DEP_COUNT"
fi

echo ""

# Check for security vulnerabilities (if pip-audit is available)
echo "=== Security Check ==="
echo ""

# Only use uv when the project is uv-managed; --frozen keeps uv.lock untouched.
if [ -f "uv.lock" ] && command -v uv &> /dev/null; then
    if uv run --frozen pip-audit --version &> /dev/null; then
        echo "Running pip-audit..."
        if uv run --frozen pip-audit 2>&1; then
            echo -e "${GREEN}No known vulnerabilities found${NC}"
        else
            echo -e "${RED}Vulnerabilities detected! See above for details.${NC}"
        fi
    else
        echo -e "${YELLOW}pip-audit not installed. Install with: uv add --dev pip-audit${NC}"
    fi
elif command -v pip-audit &> /dev/null; then
    echo "Running pip-audit..."
    if pip-audit 2>&1; then
        echo -e "${GREEN}No known vulnerabilities found${NC}"
    else
        echo -e "${RED}Vulnerabilities detected! See above for details.${NC}"
    fi
else
    echo -e "${YELLOW}pip-audit not available. Install with: pip install pip-audit${NC}"
fi

echo ""

# Check for outdated packages
echo "=== Outdated Packages ==="
echo ""

if [ -f "uv.lock" ] && command -v uv &> /dev/null; then
    echo "Checking for outdated packages..."
    uv pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
elif [ -f ".venv/bin/pip" ]; then
    .venv/bin/pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
else
    pip list --outdated 2>/dev/null || echo "Could not check outdated packages"
fi

echo ""

# Analyze imports
echo "=== Import Analysis ==="
echo ""

if [ -d "src" ]; then
    SRC_DIR="src"
elif [ -d "app" ]; then
    SRC_DIR="app"
else
    SRC_DIR="."
fi

# Count third-party imports (excludes stdlib, relative imports, and local packages)
echo "Third-party packages used in code (import count):"
python3 -I - "$SRC_DIR" <<'PY'
import ast, sys
from collections import Counter
from pathlib import Path

src = Path(sys.argv[1])
skip = {".venv", "venv", ".git", "build", "dist", "node_modules", ".tox", "__pycache__"}
files = [p for p in src.rglob("*.py") if not skip & set(p.parts)]
local = {p.name for p in src.iterdir() if p.is_dir()} | {p.stem for p in src.glob("*.py")}
counts = Counter()
for p in files:
    try:
        tree = ast.parse(p.read_text(encoding="utf-8", errors="replace"))
    except SyntaxError:
        continue
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names = [a.name for a in node.names]
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            names = [node.module]
        else:
            continue
        for name in names:
            top = name.split(".")[0]
            if top not in sys.stdlib_module_names and top not in local and top != "__future__":
                counts[top] += 1
if counts:
    for name, n in counts.most_common(20):
        print(f"  {n:4d} {name}")
else:
    print("  No third-party imports found")
PY

echo ""
echo "Done!"
