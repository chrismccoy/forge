# Improvements

Apply these where they pay off, always inside the contract (`contract.md`) and away from the traps in
`hazards.md`. Scale the effort to the script: a 15-line script needs a header and a few guards, not five new
functions. When a script is already solid, say so and change little.

## General

- Move repeated or single-purpose logic into small named functions: `local` variables in bash, typed parameters
  and return values in Python. Add no new global state.
- Guard operations that can fail quietly or return empty or malformed data: network calls, file reads,
  subprocesses, missing environment variables. Handle the failure within the contract.
- Replace magic values and inline regexes with named constants near the top, each with a one-line comment.
- Add a short header comment (bash) or module docstring (Python) if one is missing. Cover purpose, usage, the
  stdout format, exit codes, and non-obvious caveats (for example "the HTTP status alone is not reliable; also
  check the body for X").
- Improve naming, quoting, and type hints. Never rename anything that is part of the CLI or the output.

## Bash

- Check command results before trusting them: capture curl's `%{http_code}` and check its shape, check `$?`, or
  use `if ! cmd; then`.

## Python

- Use `subprocess.run(..., check=False)` with explicit return code handling.
- Add type hints to function signatures, in a form the minimum runtime supports (`typing.List` or
  `from __future__ import annotations` below 3.9).
- Catch specific exceptions around file and network calls.

## Batches

When there is more than one script, compare them on output style, argument parsing, error message style, exit
code meanings, and how they detect failure. Propose one shared convention. When bash and Python scripts are used
by the same caller, also compare their summary line format and exit codes. Change a script to match only when
that keeps its contract; otherwise report the difference and leave it.
