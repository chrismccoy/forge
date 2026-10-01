---
description: Refactor bash and Python scripts that another program or agent runs, without changing their output, exit codes, or files - proven by side-by-side runs, with every behavior-changing bug fix held for approval.
argument-hint: [script paths, a folder, or a glob]
allowed-tools: AskUserQuestion, Read, Write, Edit, Grep, Glob, Bash(bash ${CLAUDE_PLUGIN_ROOT}/lib/script-refactor/scripts/compare-runs.sh *)
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/script-refactor/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `script-refactor` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /script-refactor - Behavior-Safe Script Refactor

Run the `script-refactor` procedure. Clean up bash and Python scripts whose output, exit codes, or files are read by another program, pipeline, or AI agent, while keeping every one of those details exactly the same.

This command writes to disk only after the user approves the refactor. Fixes that would change how a script behaves are listed as numbered proposals and applied only when the user names their numbers.

User input: $ARGUMENTS

## Intake Procedure

If `$ARGUMENTS` names existing files, a folder, or a glob, take the bash and Python scripts from it and go straight to the procedure's intake step. Do not ask anything the procedure can infer or default.

If `$ARGUMENTS` is empty, ask one question with `AskUserQuestion`:

1. **SCRIPTS** - which scripts to refactor. Offer: `All scripts in ./scripts`, `One script (give path)`, `Changed scripts only (git diff)`, plus "Other".

Ask nothing else up front. The procedure asks once more only when a script's language cannot be worked out.

## Execution

Follow the procedure's seven steps in order: intake, find the callers, read the rules, refactor copies in a temporary workspace, compare old and new with `bash ${CLAUDE_PLUGIN_ROOT}/lib/script-refactor/scripts/compare-runs.sh`, report and wait, then apply only what was approved.

## Hard Rules

- NEVER edit an original script before the user approves the refactor.
- NEVER apply a fix that changes stdout, stderr, exit codes, or side effects without the user naming its number.
- NEVER report a script as unchanged without `compare-runs.sh` cases showing `result: same`.
- NEVER run a script against real servers, real data, paths outside the temporary workspace, or with `sudo`.
- NEVER add `set -e`, `set -u`, or `pipefail` to a script that lacks them.
- NEVER commit. Leave every change uncommitted.
- ALWAYS refuse out-of-scope requests with: `Out of scope: this engine refactors bash and Python scripts only.` For a read-only refactoring plan of a whole codebase use `/refactor`; to write a new script from scratch use `/snippet`; to add teaching comments without changing code use `/code-teacher`.

$ARGUMENTS
