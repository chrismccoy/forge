# Cleanups that break the contract

These common changes look harmless but change behavior. Apply one only after showing that output and exit
behavior stay identical (`compare-runs.sh` is the proof). Otherwise skip it and list it under "Skipped".

## Bash

- **`set -e`, `set -u`, `set -o pipefail`:** they change exit codes and the points where the script stops. Do not
  add them. Add targeted checks on the specific commands that can fail instead. Leave them alone where the script
  already has them.
- **`echo` to `printf`:** use `printf '%s\n' "$x"`, never `printf "$x"` (the data becomes a format string). Watch
  for `echo -n`, `echo -e`, and backslashes in the data.
- **Quoting an unquoted expansion:** if the script relied on word splitting (for example `curl $FLAGS "$url"`),
  convert it to an array, or leave it and say why.
- **`[ ]` to `[[ ]]`:** bash only. Never in a `#!/bin/sh` script.

## Python

- **`sys.argv` to `argparse`:** argparse adds `-h`, exits 2 with its own usage text on bad input, and accepts
  shortened long options. Adopt it only if the old error output and exit codes can be matched (`add_help=False`,
  `allow_abbrev=False`, a custom `error()`). Otherwise keep `sys.argv` and add checks around it.
- **`os.system` to `subprocess.run`:** `os.system` returns a wait status, not a return code, and runs through a
  shell. Keep shell behavior where the command depends on it. Call `sys.stdout.flush()` before the subprocess so
  the output order stays the same.
- **`str` paths to `pathlib.Path`:** `str(Path(p))` drops trailing slashes and collapses `//`. Never print a Path
  where the raw string used to be printed.
- **`try`/`except` fallbacks:** a fallback must not turn a former crash (nonzero exit) into a quiet success (exit
  0 with default output). Keep failures failing unless a quirk says "always exit 0". Never use a bare `except:`.
  Never let a traceback reach stdout.

## Both

- Never print environment variable values or secrets in new error messages.
- **Separators inside fields:** for every space-separated stdout line, check each field for values that can hold a
  space, tab, or newline (paths, folder names, content types, error text). Report each one. Fixing it changes
  stdout, so it goes under "Behavior changes needing approval".

## Evidence for bug claims

For each bug reported, give one concrete input and the result traced for it, preferably confirmed by running it.
Never state an outcome that has not been traced through every command involved, including the tools' own
guards. Example of the mistake to avoid: claiming `rm -rf dir/..` deletes the parent folder, when GNU `rm`
refuses any path whose last part is `..`.
