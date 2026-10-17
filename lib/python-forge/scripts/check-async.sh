#!/bin/bash
# Analyze async patterns and detect common async/await issues.
# Read-only: parses source files with the stdlib ast module, runs no project code.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Python Async Pattern Analysis ==="
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

echo "Analyzing directory: $SRC_DIR"
echo ""

# AST-based checks: function counts, blocking calls inside async def,
# calls to project coroutines that are never awaited or scheduled.
python3 -I - "$SRC_DIR" <<'PY'
import ast, sys
from pathlib import Path

YELLOW, GREEN, BLUE, NC = "\033[1;33m", "\033[0;32m", "\033[0;34m", "\033[0m"
SKIP = {".venv", "venv", ".git", "node_modules", "build", "dist", ".tox", "__pycache__"}
BLOCKING = {
    "time.sleep": "use await asyncio.sleep()",
    "open": "use aiofiles or asyncio.to_thread()",
    "input": "blocks the event loop",
    "subprocess.run": "use asyncio.create_subprocess_exec()",
    "subprocess.call": "use asyncio.create_subprocess_exec()",
    "subprocess.check_output": "use asyncio.create_subprocess_exec()",
    "os.system": "use asyncio.create_subprocess_shell()",
}
BLOCKING_PREFIXES = {"requests.": "use httpx.AsyncClient or aiohttp",
                     "urllib.request.": "use httpx.AsyncClient or aiohttp"}

def own_nodes(fn):
    """Walk fn's body without descending into nested functions, lambdas, or classes."""
    stack = list(ast.iter_child_nodes(fn))
    while stack:
        node = stack.pop()
        yield node
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)):
            stack.extend(ast.iter_child_nodes(node))

# Parents that consume a coroutine/awaitable without a bare call statement
CONSUMERS = (ast.Await, ast.Return, ast.Call, ast.keyword, ast.List, ast.Tuple, ast.Set,
             ast.Dict, ast.Starred, ast.Yield, ast.YieldFrom, ast.AsyncFor, ast.withitem,
             ast.comprehension, ast.ListComp, ast.SetComp, ast.GeneratorExp, ast.DictComp,
             ast.Lambda)

def dotted(node):
    parts = []
    while isinstance(node, ast.Attribute):
        parts.append(node.attr)
        node = node.value
    if isinstance(node, ast.Name):
        parts.append(node.id)
        return ".".join(reversed(parts))
    return None

files = [p for p in Path(sys.argv[1]).rglob("*.py") if not SKIP & set(p.parts)]
trees = {}
for p in files:
    try:
        trees[p] = ast.parse(p.read_text(encoding="utf-8", errors="replace"))
    except SyntaxError:
        pass

async_names, n_async, n_sync = set(), 0, 0
for tree in trees.values():
    for node in ast.walk(tree):
        if isinstance(node, ast.AsyncFunctionDef):
            n_async += 1
            async_names.add(node.name)
        elif isinstance(node, ast.FunctionDef):
            n_sync += 1

print("=== Function Statistics ===")
print(f"Async functions: {n_async}")
print(f"Sync functions: {n_sync}")
print()
print("=== Potential Issues ===")
print()

blocking, unawaited = [], []
for path, tree in trees.items():
    parents = {}
    for node in ast.walk(tree):
        for child in ast.iter_child_nodes(node):
            parents[child] = node
    for fn in (n for n in ast.walk(tree) if isinstance(n, ast.AsyncFunctionDef)):
        for node in own_nodes(fn):
            if not isinstance(node, ast.Call):
                continue
            name = dotted(node.func) or ""
            hint = BLOCKING.get(name) or next(
                (h for pre, h in BLOCKING_PREFIXES.items() if name.startswith(pre)), None)
            if hint:
                blocking.append(f"{path}:{node.lineno}: {name}() in async {fn.name} - {hint}")
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        name = (dotted(node.func) or "").split(".")[-1]
        if name not in async_names:
            continue
        parent = parents.get(node)
        # Awaited, returned, iterated, or passed on (create_task, gather, ...) is fine.
        if isinstance(parent, CONSUMERS):
            continue
        unawaited.append(f"{path}:{node.lineno}: {name}() result is never awaited")

print("Blocking calls inside async functions:")
if blocking:
    for line in blocking[:20]:
        print(f"{YELLOW}  {line}{NC}")
else:
    print(f"{GREEN}  None found{NC}")
print()
print("Coroutine calls possibly never awaited (heuristic, matched by function name):")
if unawaited:
    for line in unawaited[:20]:
        print(f"{YELLOW}  {line}{NC}")
else:
    print(f"{GREEN}  None found{NC}")
print()
PY

# Check for create_task results that are discarded
echo "Checking for untracked tasks..."
UNTRACKED_TASKS=$(grep -rnE "^\s*asyncio\.create_task\(" "$SRC_DIR" --include="*.py" "${EXCLUDES[@]}" 2>/dev/null || true)

if [ -n "$UNTRACKED_TASKS" ]; then
    echo -e "${YELLOW}Potentially untracked tasks (fire-and-forget, may be garbage-collected):${NC}"
    echo "$UNTRACKED_TASKS"
else
    echo -e "${GREEN}No untracked tasks found${NC}"
fi
echo ""

# Pattern usage counts
echo "=== Async Patterns Used ==="
echo ""

count() { grep -rE "$1" "$SRC_DIR" --include="*.py" "${EXCLUDES[@]}" 2>/dev/null | wc -l; }

ASYNC_FUNCS=$(count "async def ")
GATHER_COUNT=$(count "asyncio\.gather")
TASKGROUP_COUNT=$(count "asyncio\.TaskGroup")
SEMAPHORE_COUNT=$(count "asyncio\.Semaphore")
TIMEOUT_COUNT=$(count "asyncio\.(timeout|wait_for)")
QUEUE_COUNT=$(count "asyncio\.Queue")

echo "asyncio.gather usage: $GATHER_COUNT"
echo "asyncio.TaskGroup usage: $TASKGROUP_COUNT"
echo "asyncio.Semaphore usage: $SEMAPHORE_COUNT"
echo "Timeout handling: $TIMEOUT_COUNT"
echo "asyncio.Queue usage: $QUEUE_COUNT"
echo ""

# Recommendations
echo "=== Recommendations ==="
echo ""

if [ "$ASYNC_FUNCS" -gt 0 ] && [ "$TASKGROUP_COUNT" -eq 0 ]; then
    echo -e "${BLUE}Consider using TaskGroup (Python 3.11+) for structured concurrency${NC}"
fi

if [ "$ASYNC_FUNCS" -gt 5 ] && [ "$SEMAPHORE_COUNT" -eq 0 ]; then
    echo -e "${BLUE}Consider using Semaphores for rate limiting concurrent operations${NC}"
fi

if [ "$TIMEOUT_COUNT" -eq 0 ] && [ "$ASYNC_FUNCS" -gt 0 ]; then
    echo -e "${YELLOW}No timeout handling found - consider adding asyncio.timeout()${NC}"
fi

REQUESTS_COUNT=$(count "^(import requests|from requests)")
if [ "$REQUESTS_COUNT" -gt 0 ] && [ "$ASYNC_FUNCS" -gt 0 ]; then
    echo -e "${YELLOW}Using sync 'requests' library with async code - consider httpx or aiohttp${NC}"
fi

echo ""
echo "Done!"
