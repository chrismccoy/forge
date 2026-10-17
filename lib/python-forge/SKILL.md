# Python Forge - modern Python development

Production-grade guidance for modern Python development: language features, concurrency, typing, packaging, web APIs, testing, CI/CD, edge and serverless deployment, computer vision, and media processing. Includes a project-init workflow, a test workflow, and four project analysis scripts.

## Operating Rules

1. Load the matching topic reference from the routing table BEFORE answering. Load more than one when the task spans topics.
2. Load a deep-dive reference when the task needs code beyond the primary file. For the OpenCV, FFmpeg, and video-pipeline rows the primary file is an index: load the first matching deep-dive for any code task.
3. Type-annotate all code. Prefer built-in generics (`list[str]`) and `X | None`.
4. Use async for I/O-bound work. Never block the event loop.
5. Target Python 3.11+ minimum. Use dataclasses and Pydantic v2.
6. Validate input, use parameterized queries, hash passwords with bcrypt.
7. Include tests for new functions and classes. Aim for 80%+ coverage.
8. Keep the user's existing framework and tooling unless a clear reason exists to change.

## Response Format

1. Clarify requirements only when the request is ambiguous.
2. Provide complete, working code with type hints.
3. Add docstrings for public APIs.
4. Explain decisions and trade-offs briefly.
5. Include tests when creating new functions or classes.

For large or independent Python work, delegate to a subagent. Give it `references/expert-persona.md` (role briefing and worked examples) plus the relevant topic references as context.

## Topic Routing

All paths are relative to `${CLAUDE_PLUGIN_ROOT}/lib/python-forge`, the folder that contains this procedure file.

| Topic / trigger | Primary reference | Deep-dive references |
|-----------------|-------------------|----------------------|
| Python 3.13+: free-threading, JIT, pattern matching, walrus, f-strings, type params, exception groups, dataclasses, enums | `references/python-fundamentals-313.md` | - |
| asyncio: gather, TaskGroup, semaphores, timeouts, queues, async generators, uvloop | `references/python-asyncio.md` | `references/async-patterns-library.md` |
| Type hints: generics, Protocol, TypedDict, Literal, TypeGuard/TypeIs, ParamSpec, mypy/pyright | `references/python-type-hints.md` | `references/advanced-typing-patterns.md` |
| Packaging: uv, pyproject.toml, uv.lock, src layout, Ruff, pre-commit, PyPI | `references/python-package-management.md` | - |
| FastAPI: structure, Pydantic schemas, DI, async SQLAlchemy, JWT, Docker, Gunicorn | `references/python-fastapi.md` | `references/dependency-injection-patterns.md` |
| Testing: pytest, fixtures, parametrize, pytest-mock, pytest-asyncio, coverage, Hypothesis | `references/python-testing.md` | `references/pytest-fixtures-cookbook.md` |
| GitHub Actions: setup-uv, caching, matrix, reusable workflows, trusted publishing | `references/python-github-actions.md` | - |
| Cloudflare: Python Workers (Pyodide), Containers, bindings, cold starts | `references/python-cloudflare.md` | - |
| Modal.com: functions, classes, GPU, web endpoints, cron, Volumes, `.map()` | `references/python-modal.md` | `references/parallel-volumes-testing.md` |
| Gotchas: mutable defaults, late binding, `is` vs `==`, LEGB, float precision, circular imports | `references/python-gotchas.md` | - |
| OpenCV: BGR/RGB, `img[y, x]`, imread `None`, VideoCapture, filters, contours, features, DNN, CUDA | `references/python-opencv.md` | `references/opencv-critical-gotchas.md`, `references/opencv-core-operations.md`, `references/opencv-advanced-patterns.md` |
| FFmpeg: ffmpeg-python, PyAV, subprocess, codecs, NVENC/QSV/VAAPI, HLS/DASH, thumbnails | `references/python-ffmpeg.md` | `references/ffmpeg-complete-recipes.md`, `references/ffmpeg-advanced-patterns.md` |
| Video pipelines: FFmpeg + OpenCV + Modal, HWC/CHW, chunked GPU processing, HLS output | `references/python-video-pipeline.md` | `references/video-pipeline-complete-patterns.md`, `references/modal-video-patterns.md` |

To find a section inside a large reference, grep its headings first, for example `grep -n '^##' references/ffmpeg-complete-recipes.md`.

## Critical Gotchas (Always Apply)

- Mutable default arguments: use `None`, then create the object inside the function.
- `asyncio.gather` hides sibling failures. Prefer `asyncio.TaskGroup` on 3.11+.
- OpenCV loads BGR. Convert with `cv2.cvtColor(img, cv2.COLOR_BGR2RGB)` before Matplotlib or PIL.
- NumPy image indexing is `img[row, col]` (`img[y, x]`). OpenCV drawing uses `(x, y)`.
- `cv2.imread` returns `None` on failure and raises no error. Check the result.
- FFmpeg video filters drop audio unless the audio stream goes to `ffmpeg.output(...)` explicitly.
- Use `overwrite_output()` (ffmpeg-python) or `-y` (CLI) to avoid blocking prompts.
- Drain subprocess stdout and stderr to avoid pipe deadlocks.

## Workflow: Initialize a Project

Use when asked to create, scaffold, or initialize a Python project. Recognize project type in the request: FastAPI app, CLI tool, library, or minimal setup. Options, steps, and the `pyproject.toml` template: `references/workflow-project-init.md`.

1. Ask for the project name and description if missing.
2. Run `uv init --package <name>` (`uv init --lib <name>` for a library). This creates the src layout and `.gitignore`, and runs `git init` unless already inside a git repository.
3. Write the description into `pyproject.toml`.
4. Add project-type dependencies (FastAPI, Typer, and so on) as listed in the workflow reference.
5. Add dev tools to `[dependency-groups] dev`: `uv add --dev pytest pytest-cov ruff mypy`.
6. Merge the Ruff, mypy (strict), and pytest configuration from the template. Create a smoke test in `tests/`.
7. Run `uv sync`, then verify: `uv run pytest`, `uv run ruff check .`, `uv run mypy src`.

## Workflow: Run Tests

Use when asked to run tests or check coverage. Map requested options (test path, name pattern, stop on first failure, parallel, no coverage) to pytest flags as listed in `references/workflow-run-tests.md`.

1. Run `uv run pytest -v --cov --cov-report=term-missing [flags]` when `uv.lock` exists; otherwise drop the `uv run` prefix.
2. Report pass/fail counts, per-file coverage, and missing lines. Flag files under 80%.
3. On failure, find the root cause, propose a fix, and implement it if asked. Rerun with `--lf`.

## Analysis Scripts

Run each script from the target project root. Each script takes no arguments and analyzes `src/`, `app/`, or `.` (first found). Scripts that run project tools use `uv run --frozen` only when `uv.lock` exists, otherwise `.venv` or the current environment (`python3` when no `python` exists). `.venv`, `venv`, `.git`, `build`, `dist`, `node_modules`, and `.tox` are always skipped.

Side effects: `check-async.sh` only parses source. `check-types.sh` and `check-deps.sh` run mypy/pyright, pip-audit, and an outdated-package listing without changing project files, though `uv run --frozen` may create or sync `.venv`. `analyze-coverage.sh` runs the full test suite (with the suite's own side effects) and writes `.coverage` and `htmlcov/`.

| Script | Purpose |
|--------|---------|
| `scripts/check-types.sh` | Run mypy (fallback: pyright from the project, then PATH), report return and parameter annotation coverage, flag `typing.List`-style imports and `Optional[X]`. Exits with the checker's status |
| `scripts/check-async.sh` | Count async/sync functions, find blocking calls inside `async def`, possibly un-awaited coroutine calls, and fire-and-forget `create_task`; count asyncio patterns |
| `scripts/analyze-coverage.sh` | Run pytest with coverage, list files under 80% and at 0%, list source files without a matching `tests/test_<name>.py` |
| `scripts/check-deps.sh` | Read project metadata, detect package manager, run pip-audit, list outdated packages, count third-party imports |

Invoke with `bash ${CLAUDE_PLUGIN_ROOT}/lib/python-forge/scripts/<name>.sh`, as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rule matches. Read the script output before suggesting fixes.

## Additional Resources

- `references/expert-persona.md` - subagent briefing and worked examples (uv setup, concurrent HTTP, Pydantic schemas, mutable defaults, FastAPI async tests)
- `references/workflow-project-init.md` - project-type options, steps, `pyproject.toml` template
- `references/workflow-run-tests.md` - option-to-flag mapping, steps, sample output
- Topic and deep-dive references: see the routing table above.
