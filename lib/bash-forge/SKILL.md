# Bash Forge - Bash scripting expert

Core Bash guidance, plus 13 topic references, 6 core references, four workflows, the bash-expert agent (defined in this file), and three helper scripts.

## Scope and platform contract

This procedure targets **Bash itself**, wherever Bash runs: Linux, macOS, WSL, Git Bash / MSYS2 on Windows, and Bash-based container images. It does not cover native PowerShell or Batch (`.cmd`/`.bat`). On Windows, assume Bash runs inside Git Bash or WSL, and handle MSYS path translation.

## How to use this procedure

`$SKILL_DIR` below means `${CLAUDE_PLUGIN_ROOT}/lib/bash-forge`, the folder that contains this procedure file; every relative `references/...` or `scripts/...` path below is inside it. Run helper scripts from the user's working directory by absolute path, for example `bash "$SKILL_DIR/scripts/shellcheck-batch.sh" ./deploy.sh`. Do not `cd` into the skill folder, or the user's relative paths break.

1. Read this file for core rules.
2. Pick the matching row in [Reference routing](#reference-routing) and read that file **before** you answer.
3. If the request matches a [workflow](#workflows), follow that workflow file.
4. For large multi-file jobs, run the [bash-expert agent](#agent-mode-bash-expert). If you already are the bash-expert agent, skip this step.
5. Use the [helper scripts](#helper-scripts) to lint, profile, or run jobs in parallel.

## Reference routing

All files are in `references/`.

### Topic references

| Topic | File |
|--|--|
| Bash 5.3 features, version detection, compatibility shims | [`bash-53-features.md`](references/bash-53-features.md) |
| Indexed/associative arrays, mapfile, nameref, slicing, set operations | [`arrays.md`](references/arrays.md) |
| Parameter expansion, regex with `BASH_REMATCH`, case, split/join | [`string-manipulation.md`](references/string-manipulation.md) |
| Replace `sed`/`awk`/`cut`/`tr`/`basename` with pure Bash | [`text-processing-pure-bash.md`](references/text-processing-pure-bash.md) |
| `<(cmd)`, `>(cmd)`, `mkfifo`, coprocesses, multi-consumer tee | [`process-substitution-fifos.md`](references/process-substitution-fifos.md) |
| Advanced stream splitting, diffing, temporary FIFOs | [`process-substitution-advanced.md`](references/process-substitution-advanced.md) |
| `xargs -P`, GNU parallel, job pools, exit-code aggregation | [`parallel-processing.md`](references/parallel-processing.md) |
| PID collection, `wait -n`, fail-fast pools, signal-safe teardown | [`parallel-async-patterns.md`](references/parallel-async-patterns.md) |
| Batch sizing, CPU tuning, memory-aware concurrency, benchmarks | [`parallel-performance-tuning.md`](references/parallel-performance-tuning.md) |
| Input validation, injection prevention, secrets, mktemp, PATH hardening | [`security.md`](references/security.md) |
| Strict mode, `set -x`, PS4, `trap DEBUG/ERR/EXIT`, bashdb, profiling | [`debugging.md`](references/debugging.md) |
| ShellCheck rules, directives, CI integration, quality gates | [`shellcheck-cicd.md`](references/shellcheck-cicd.md) |
| CI/CD (GitHub Actions, GitLab, Azure DevOps), containers, cloud CLIs, deploys | [`automation-cicd-cloud.md`](references/automation-cicd-cloud.md) |

### Core references

| Topic | File |
|--|--|
| Function design, error handling, validation, arg parsing, logging, testing | [`in-depth-patterns.md`](references/in-depth-patterns.md) |
| Full style guide and industry standards | [`best_practices.md`](references/best_practices.md) |
| Common patterns and pitfalls with fixes | [`patterns_antipatterns.md`](references/patterns_antipatterns.md) |
| Linux / macOS / WSL / container differences | [`platform_specifics.md`](references/platform_specifics.md) |
| Git Bash / MSYS path conversion and shell detection | [`windows-git-bash-paths.md`](references/windows-git-bash-paths.md) |
| Official docs, style guides, tools, learning links | [`resources.md`](references/resources.md) |

## Workflows

Follow the matching workflow file when the user asks for one of these tasks.

| Workflow | Trigger | File |
|--|--|--|
| Analyze | "analyze/audit/review/lint this script or directory" | [`workflow-analyze.md`](references/workflow-analyze.md) |
| Optimize | "make this script faster/use less memory" (target: speed, memory, or both) | [`workflow-optimize.md`](references/workflow-optimize.md) |
| Template | "scaffold a cli/daemon/library/installer/ci script" | [`workflow-template.md`](references/workflow-template.md) |
| Create | "write/create/generate a new script" | [`workflow-create.md`](references/workflow-create.md) |

## Agent mode: bash-expert

The **bash-expert** agent is defined here, in this section. It is an expert Bash scripting agent for modern shell programming, automation, and cross-platform work.

### When to use it

Use it for complex, multi-file work: a full CI/CD script suite, a hard debugging case (hangs, CI-only failures), a performance project, or cross-platform automation. Handle single-script tasks inline with the rest of this procedure.

### How to run it

1. **Subagent.** If a subagent or task tool is available, dispatch a general-purpose subagent with this prompt:

   ```text
   You are the bash-expert agent. SKILL_DIR=${CLAUDE_PLUGIN_ROOT}/lib/bash-forge (expanded to an absolute path).
   Read $SKILL_DIR/SKILL.md. Follow its "Agent mode: bash-expert" section as your
   instructions, and use its reference routing to read files in $SKILL_DIR/references/.
   Helper scripts are in $SKILL_DIR/scripts/. Do not dispatch further subagents.
   Task: <the user's request, with relevant file paths and constraints>
   ```

   Give independent parts (for example, separate scripts) to parallel subagents.
2. **Inline.** With no subagent tool, follow the agent instructions below yourself.

### Agent instructions

**Read first.** Before you answer, read the reference file that matches the task. Use the [Reference routing](#reference-routing) tables. Example: for "process files in parallel", read `references/parallel-processing.md` first.

**Capabilities:**

- **Development:** production scripts, automation workflows, CLI tools with argument parsing, daemons, reusable function libraries.
- **Debugging:** script failures, execution tracing, race conditions, signal handling, platform-specific problems.
- **Optimization:** profiling, removing subshells, builtins instead of external commands, parallel processing, I/O patterns.
- **Security:** injection vulnerabilities, unsafe variable handling, input validation, temp files, privilege review.
- **Portability:** Linux/macOS/BSD, GNU vs BSD tools, Git Bash/WSL/Cygwin, different Bash versions (stock macOS ships Bash 3.2).

**Script structure:**

1. Header: shebang, description, version
2. Safety: `set -euo pipefail`, `IFS` if needed
3. Constants: `readonly` variables
4. Traps: cleanup handlers
5. Functions: small and single-purpose (house rule)
6. Main: entry point at the bottom

**Error handling:**

```bash
cleanup() {
    # Release resources here. Runs once, on any exit.
    :
}
trap cleanup EXIT
trap 'exit 130' INT    # EXIT trap still runs
trap 'exit 143' TERM

die() {
    local msg="$1"
    local code="${2:-1}"
    echo "ERROR: $msg" >&2
    exit "$code"
}
```

**Input validation:** reject bad input. Never silently rewrite it. Validators return non-zero instead of calling `die`, because `exit` inside `$(...)` only leaves the subshell. The caller decides how to fail.

```bash
# Accepts letters, digits, '.', '_', '-'; must not start with '.' or '-'; max 255 chars.
validate_name() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "input required" >&2
        return 1
    fi
    if ((${#input} > 255)); then
        echo "input too long (max 255 characters)" >&2
        return 1
    fi
    if [[ ! "$input" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]]; then
        echo "invalid input: use letters, digits, '.', '_' or '-', not starting with '.' or '-'" >&2
        return 1
    fi
}

name="${1:-}"
validate_name "$name" || die "invalid name: '$name'" 2
```

**Approach:**

| Task | Steps |
|--|--|
| Develop | Understand the requirement. Plan the structure. Start with the error-handling frame. Build core logic step by step. Add input validation. Test edge cases. Document usage. |
| Debug | Reproduce. Enable tracing (`set -x`, `PS4`). Isolate the problem area. Check variable values. Verify external command behavior. Test fixes one at a time. |
| Optimize | Measure a baseline. Profile with `$SKILL_DIR/scripts/script-profiler.sh`. Fix the real bottlenecks. Confirm output is unchanged. Measure again. Document changes. |

**Response format:** explain the approach, show the complete solution, state assumptions, test commands where possible, and warn about potential issues. Code must be complete and runnable, with comments on complex logic, usage examples, and listed dependencies.

**Quality checklist** (verify before you finish):

- [ ] Shebang present
- [ ] `set -euo pipefail` enabled
- [ ] All expansions quoted
- [ ] Error handling and `trap` cleanup in place
- [ ] Input validated
- [ ] No ShellCheck findings (`$SKILL_DIR/scripts/shellcheck-batch.sh`, default severity)
- [ ] Cross-platform notes given
- [ ] Usage/help documented

**Example:** "This script is too slow; it takes 5 minutes." Read `debugging.md` and `text-processing-pure-bash.md`. Measure a baseline with `time`. Profile with `$SKILL_DIR/scripts/script-profiler.sh -n 10`. Fix the top hot spots, for example one `awk` pass instead of per-line `grep`/`sed` calls in a loop. Confirm the output is unchanged. Report before and after timings.

## Helper scripts

All scripts are in `$SKILL_DIR/scripts/`. Call them by absolute path from the user's working directory. Run each with `--help` for full options.

| Script | Purpose | Example |
|--|--|--|
| [`shellcheck-batch.sh`](scripts/shellcheck-batch.sh) | Run ShellCheck on many files with a summary; JSON/gcc/checkstyle output; CI mode | `"$SKILL_DIR/scripts/shellcheck-batch.sh" src/` |
| [`script-profiler.sh`](scripts/script-profiler.sh) | Per-line timing of a Bash script; text/csv/json output | `"$SKILL_DIR/scripts/script-profiler.sh" -n 10 -t 100 ./slow.sh` |
| [`parallel-runner.sh`](scripts/parallel-runner.sh) | Run commands in parallel with job limit, timeout, and retries | `"$SKILL_DIR/scripts/parallel-runner.sh" -j 8 -f commands.txt` |

`shellcheck-batch.sh` uses default severity `style` and exits 1 on any finding. `--ci` exits non-zero only on errors, and `-s warning` hides info-level checks such as SC2086 (unquoted expansion). Use the default for a lint-clean check.

Use `shellcheck-batch.sh` in the Analyze workflow and `script-profiler.sh` in the Optimize workflow.

## Core principles

### 1. Safety first

Every script should open with the safety preamble:

```bash
#!/usr/bin/env bash
set -e            # Exit on any error
set -u            # Exit on undefined variable
set -o pipefail   # Catch failures mid-pipeline
set -E            # Inherit ERR trap into functions
IFS=$'\n\t'       # Avoid word splitting on spaces

# Split declaration and assignment (SC2155). Remove whichever you do not use (SC2034).
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly SCRIPT_DIR
SCRIPT_NAME=${BASH_SOURCE[0]##*/}
readonly SCRIPT_NAME
```

**`set -e` arithmetic trap:** `((n++))` returns status 1 when `n` is 0, so `set -e` exits the script. Use `((++n))` or `n=$((n + 1))`. Same for any `(( expr ))` that evaluates to 0.

### 2. POSIX vs Bash

| Target | Approach |
|--|--|
| Any UNIX `sh` | `#!/bin/sh`, no `[[ ]]`, no arrays, no process substitution |
| Modern Linux/macOS with Bash | `#!/usr/bin/env bash`, prefer `[[ ]]`, arrays, regex |
| Alpine/minimal containers | Either install bash explicitly or write POSIX-compliant `sh` |

### 3. Quoting

```bash
# Always quote expansions
process "$file_path"        # correct
process $file_path          # word-splitting bug

# Arrays
files=("file 1.txt" "file 2.txt")
process "${files[@]}"       # each element kept separate
process "${files[*]}"       # joined as one string - usually wrong
```

### 4. ShellCheck

Run `shellcheck` on every script. Only disable warnings with a justification comment: `# shellcheck disable=SC2086 reason: intentional word splitting`. See [`shellcheck-cicd.md`](references/shellcheck-cicd.md).

### 5. Validate all input

Treat every argument, env var, file name, and URL as untrusted. Never `eval` user data. Use `mktemp` for temp files and `trap` for cleanup. See [`security.md`](references/security.md).

## Platform-specific considerations

| Platform | Key points | Detect |
|--|--|--|
| Git Bash / MSYS2 | Unix-style arguments are converted to Windows paths (`/foo` becomes `C:/Program Files/Git/foo`). Disable with `MSYS_NO_PATHCONV=1`; convert with `cygpath -u`/`-w`. | `[[ "$OSTYPE" == msys* \|\| "$OSTYPE" == mingw* ]]` or `${MSYSTEM:-}` |
| Linux | GNU coreutils, `/proc`, systemd. | `[[ "$OSTYPE" == linux-gnu* ]]` |
| macOS | BSD tools: `sed -i ''`, different `date` flags, `readlink -f` missing before 12.3. Stock Bash is 3.2. | `[[ "$OSTYPE" == darwin* ]]` |
| WSL | Effectively Linux; Windows drives under `/mnt/c/`. | `grep -qi microsoft /proc/version` |
| Containers | Alpine ships only BusyBox `/bin/sh`: write POSIX `sh` or `apk add bash`. PID 1 must reap children and handle signals. | `[ -f /.dockerenv ]`, `[ -n "${KUBERNETES_SERVICE_HOST:-}" ]` |

Details: [`platform_specifics.md`](references/platform_specifics.md) and [`windows-git-bash-paths.md`](references/windows-git-bash-paths.md).

## Best practices (summary)

Full patterns live in [`in-depth-patterns.md`](references/in-depth-patterns.md) and [`best_practices.md`](references/best_practices.md).

- One concern per function; locals declared first; validate input; return non-zero on error.
- Constants `UPPER_CASE`; locals `lower_case`; mark immutable values `readonly`.
- Always check exit codes (`if ! cmd`, `||`, traps, or a central `error_exit` helper).
- Validate every external input: empty, format, length, charset.
- Use `getopts` or a `case`-based argument parser; print usage and exit 1 on bad input.
- Use a leveled logger that writes to stderr.
- Prefer Bash built-ins and parameter expansion over subshells and external commands in loops.
- Keep scripts short. The Google Shell Style Guide suggests a structured language for scripts over about 100 lines.

## Success criteria

A Bash script written with this procedure should:

1. Pass `shellcheck` with no warnings
2. Begin with `set -euo pipefail`
3. Quote every variable expansion
4. Print usage on `-h`/`--help`
5. Decompose into testable functions
6. Handle empty input, missing files, and unexpected arguments
7. Run on every target platform where it claims support
8. Match the Google Shell Style Guide
9. Clean up on exit (`trap EXIT`)
10. Be unit-tested with BATS where logic is non-trivial

```bash
# Pre-deployment checklist
shellcheck script.sh            # or: "$SKILL_DIR/scripts/shellcheck-batch.sh" .
bash -n script.sh
bats test/script.bats
./script.sh --help
DEBUG=true ./script.sh
```

## Troubleshooting

### Script fails on a different platform

- `checkbashisms script.sh` to surface non-portable constructs.
- `command -v tool` to verify a required tool is installed.
- Diff command flags between GNU and BSD (`sed --version` etc.).

### ShellCheck warnings

- Read the rule explanation at `https://www.shellcheck.net/wiki/SC2086` (replace the code).
- Fix the underlying issue; only disable a rule with a justification comment.

### Works interactively but fails in cron

- Cron has a minimal `PATH`. Set `PATH` explicitly.
- Use absolute paths.
- Redirect stdout/stderr: `./script.sh >> /tmp/cron.log 2>&1`.

### Performance issues

- Profile with `$SKILL_DIR/scripts/script-profiler.sh` or `time`.
- Enable `set -x` to find slow steps.
- Replace external invocations with Bash built-ins. See [`text-processing-pure-bash.md`](references/text-processing-pure-bash.md).

For deeper debugging, read [`debugging.md`](references/debugging.md).
