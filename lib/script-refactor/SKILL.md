# Script Refactor

Refactor bash and Python scripts that another program runs, without breaking that program.

A calling program depends on small details: one exact stdout line, an exit code, a file at a known path. Ordinary
cleanup changes those details silently (`echo` to `printf`, adding `set -e`, switching to `argparse`) and the
caller breaks with no error. This procedure treats every observable behavior as fixed, improves the code around it,
proves the result behaves the same by running both versions, and hands every real bug fix that would change
behavior to the user as a numbered proposal.

The reference files (`references/...`) and scripts (`scripts/...`) named below live in
`${CLAUDE_PLUGIN_ROOT}/lib/script-refactor/`.

## Scope Lock

Refactor bash and Python scripts only. Refuse anything else with one line: `Out of scope: this engine refactors
bash and Python scripts only.` A script in another language (JavaScript, PowerShell, PHP) gets that line too,
even inside an otherwise valid batch; handle the bash and Python files and name the skipped ones.

## Non-negotiables

1. **Never edit the original files before approval.** Work on copies in a temporary workspace until the user
   approves the refactor.
2. **Keep behavior identical.** The refactored script keeps every observable behavior, bugs included. See
   `references/contract.md`.
3. **Fixes that change behavior wait.** Propose them as numbered diffs; apply only the numbers the user names.
4. **Prove it by running.** Compare old and new with `compare-runs.sh` on safe inputs before reporting "unchanged".
5. **Never run a script against anything real.** No real servers, no real data, no paths outside the temporary
   workspace, no `sudo`. When a script can only be exercised against something real, say so and skip that case.
6. **Never commit.** Leave changes uncommitted for the user.

## Workflow

### 1. Intake

Take the scripts from the command's arguments (paths, a folder, or a glob) or from the request. Fill every
intake field using the table in `references/contract.md`: infer what can be inferred, default the rest, and ask
only about missing scripts or a language that cannot be worked out, in one message.

### 2. Find the callers

Before deciding what the caller relies on, search for it. Grep the repository for each script's file name in
docs, prompts, skills, commands, and other scripts (`*.md`, `*.sh`, `*.py`, `*.json`, `*.yml`). Read how each
caller uses the script: which stdout lines it reads, whether it checks the exit code, whether it reads stderr,
which files it expects. Record what was found and where; it fills "Caller relies on" and decides how freely error
messages may be reworded. With no callers found, use the conservative default (everything is relied on).

### 3. Read the rules

Read `references/contract.md`, `references/hazards.md`, and `references/improvements.md` in full before editing.

### 4. Set up a workspace and refactor

Create a temporary workspace (`mktemp -d`) with `old/` and `new/` subfolders, and copy each script into both.
Edit only the copies in `new/`. Apply the improvements that fit, scaled to the script's size. While reading the
code, collect every bug that cannot be fixed without changing behavior; each gets a concrete input, and the
result is traced or run (see "Evidence" in `references/hazards.md`).

### 5. Compare old and new

Run each pair through the comparison script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/script-refactor/scripts/compare-runs.sh [-C dir] [-p prep-command] <old-script> <new-script> [args...]
```

It runs both versions with the same arguments from the same directory and reports `stdout`, `stderr`, and `exit`
as `same` or `DIFF` with a diff, then `result: same` or `result: DIFF` (exit 0 or 1). Use `-C` to run inside a
fixture folder in the workspace, and `-p` to recreate fixtures that the script changes or deletes before each run.

Cover at least:
- no arguments and wrong arguments (usage and error paths);
- each normal path, using small fixture files built in the workspace;
- each failure path that can be triggered safely (missing file, unreachable `127.0.0.1` port, empty input);
- the input behind every bug found, to confirm the old behavior is kept.

Every case must show `result: same`. Investigate any `DIFF` and fix the refactor; never explain a difference
away. To demonstrate a proposed fix, compare the refactored script against a second copy with the fix applied.

### 6. Report and wait

Write the report in the format in `references/report-format.md`: intake, one section per script (diff, contract
check, comparison results, changes, skipped), behavior changes needing approval, and cross-script findings for
batches. End by asking two things: whether to write the refactor over the originals, and which numbered fixes to
apply. Stop and wait.

### 7. Apply what was approved

Copy the approved refactored scripts over the originals. Apply only the numbered fixes the user approved, then
rerun the comparison cases: each approved fix should cause exactly the differences it promised, and nothing
else should change. Update header comments and any docs or callers found in step 2 that describe the changed
behavior, and list those edits. Report the files changed. Do not commit.

## Additional Resources

### Reference Files

- **`references/contract.md`**: what counts as observable behavior, the approval rule, precedence, and the intake
  table.
- **`references/hazards.md`**: cleanups that silently change behavior in bash and Python, the separator check,
  and the evidence rule for bug claims.
- **`references/improvements.md`**: what to improve, how much, and how to compare scripts in a batch.
- **`references/report-format.md`**: the exact sections of the report.

### Scripts

- **`scripts/compare-runs.sh`**: runs an old and a new script with the same arguments and reports whether stdout,
  stderr, and exit code match. Always run it through `bash`.
