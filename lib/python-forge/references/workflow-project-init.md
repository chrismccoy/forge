# Initialize a Python Project

Create a production-ready Python project with src layout, uv, Ruff, mypy, and pytest.

## Options

Recognize these options in the request. Default: packaged application, full tooling.

| Option | Meaning | Effect |
|--------|---------|--------|
| Project name | Directory and distribution name | Ask if not given |
| Description | One-line summary | Ask if not given; write to `[project] description` |
| `--fastapi` / "FastAPI app" | Web API | Add `fastapi`, `uvicorn[standard]`, `pydantic-settings`; create `src/<pkg>/main.py` with an app factory. Follow `python-fastapi.md` |
| `--cli` / "CLI tool" | Command-line app | Add `typer`; create `src/<pkg>/cli.py`; add `[project.scripts] <name> = "<pkg>.cli:app"` |
| `--lib` / "library" | Reusable library | Use `uv init --lib` (it already creates `src/<pkg>/py.typed`); no entry point |
| `--minimal` / "minimal" | Smallest setup | Skip mypy and pytest-cov; keep Ruff and pytest |

## Steps

1. Ask for the project name and description if missing.
2. Create the project with src layout. `uv init` also runs `git init` and writes `.gitignore`, unless the target directory is already inside a Git repository (or `--vcs none` is passed):
   ```bash
   uv init --package <name>     # application or CLI: src/<pkg>/__init__.py with main(), script <name> = "<pkg>:main"
   uv init --lib <name>         # library: src/<pkg>/__init__.py + py.typed
   ```
3. Set `description` in `pyproject.toml`.
4. Add the project-type dependencies from the Options table.
5. Add dev tools to `[dependency-groups] dev`:
   ```bash
   uv add --dev pytest pytest-cov ruff mypy   # --minimal: uv add --dev pytest ruff
   ```
6. Merge the tool configuration from the template below into `pyproject.toml`.
7. Create `tests/conftest.py` and `tests/test_main.py` with one smoke test.
8. Run `uv sync`.
9. Verify:
   ```bash
   uv run pytest
   uv run ruff check .
   uv run mypy src          # skip for --minimal
   ```

## Resulting Layout

```text
<name>/
├── src/
│   └── <package>/
│       ├── __init__.py      # uv init --package: holds main() (entry point "<package>:main")
│       ├── main.py          # --fastapi only: app factory (added by hand)
│       ├── cli.py           # --cli only: Typer app (added by hand)
│       └── py.typed         # --lib only (uv init --lib)
├── tests/
│   ├── conftest.py
│   └── test_main.py
├── pyproject.toml
├── uv.lock
├── README.md
├── .python-version
└── .gitignore
```

## pyproject.toml Template

`uv init` writes `[project]` and `[build-system]` (the `uv_build` backend by default; pass `--build-backend hatch` or another backend only when needed), and `uv add --dev` writes `[dependency-groups]`. Keep the `[build-system]` table that `uv init` writes and add the `[tool.*]` sections below.

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My Python project"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=5.0.0",
    "ruff>=0.6.0",
    "mypy>=1.11.0",
]

[tool.ruff]
target-version = "py311"
line-length = 88
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP"]

[tool.mypy]
python_version = "3.11"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["-ra", "-q", "--cov=src"]   # drop --cov for --minimal
```

Use `[project.optional-dependencies]` only for extras that end users install (for example `pip install my-project[postgres]`), never for dev tools.

## Next Steps

```bash
uv add <package>          # runtime dependency
uv add --dev <package>    # dev tool
uv run pytest             # tests
uv run ruff format .      # format
```
