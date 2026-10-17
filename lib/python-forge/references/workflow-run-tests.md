# Run Python Tests

Run pytest with a coverage report, then explain failures and coverage gaps.

## Options

Recognize these options in the request and pass them to pytest.

| Request | pytest flag |
|---------|-------------|
| Test path (`tests/unit/test_users.py`) | positional path |
| Name pattern ("tests matching create") | `-k "create"` |
| Stop on first failure | `-x` |
| Show local variables in tracebacks | `-l` |
| Parallel run | `-n auto` (needs `pytest-xdist`) |
| Last failed only | `--lf` |
| No coverage | omit `--cov` flags |

## Steps

1. Pick the runner: `uv run` when `uv.lock` exists, otherwise the active environment.
2. Run:
   ```bash
   uv run pytest -v --cov --cov-report=term-missing [options]
   # without uv:
   pytest -v --cov --cov-report=term-missing [options]
   ```
   If `pytest-cov` is missing, run without `--cov` flags and suggest `uv add --dev pytest-cov`.
3. Report pass/fail/skip counts, per-file coverage, and missing line ranges.
4. Flag files under 80% coverage and name the untested functions.
5. On failure:
   1. Read the failure message and traceback.
   2. Identify the root cause in the code under test or in the test.
   3. Propose a fix.
   4. Implement the fix if asked, then rerun only the failed tests with `--lf`.

For a deeper coverage breakdown (0% files, source files without test files), run `scripts/analyze-coverage.sh`.

## Example Output

```text
tests/test_users.py::test_create_user PASSED
tests/test_users.py::test_get_user PASSED
tests/test_users.py::test_delete_user PASSED

---------- coverage: platform linux, python 3.12 ----------
Name                    Stmts   Miss  Cover   Missing
-----------------------------------------------------
src/mypackage/users.py     45      5    89%   23-25, 42-43
src/mypackage/utils.py     12      0   100%
-----------------------------------------------------
TOTAL                      57      5    91%

3 passed in 0.45s
```

Branch coverage appears when `--cov-branch` is set or `branch = true` is configured under `[tool.coverage.run]`.
