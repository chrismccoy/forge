## Bug check only

A read-only pass: no file in the project changes, not even a comment. It reuses the discovery, the maps and the groups from `SKILL.md`, because the maps (routes, env, shapes) let an agent see bugs that cross files. It skips everything that exists only to write or prove comments. Follow the steps below in place of `SKILL.md` steps 1 to 5. Where a step says "as in step N", it means that step of `SKILL.md`, with only the parts named here.

### 1. Discover

Do these items of `SKILL.md` step 1 as written: **Languages and stack**, **Checker**, **Files**, the route, event and env maps and the shared shapes (with a facts library when the user points to one), **Tests** (find the commands; run nothing yet), and **Show the plan**. Read `references/discovery.md` for them, but skip what it says about dialects, `@since`, frozen comments and the self-test.

Skip the rest of step 1. These items only matter when comments are written: the git-state question, dialects, checked types and schema tags, the question about tools that publish comments, the `@since` policy, the line limit, and the self-test.

- **Git state:** in git, record `git -C <project> status --porcelain` for the report. Do not ask about uncommitted changes, since nothing will be written.
- **No working checker** (`npm ci` cannot reach the registry and the user gives no cache): this does not block a bug check. Build `files.txt` with `find` over the extensions in the language table, apply the same exclusions, skip the parse check below, and say so in the report. The final check below does not need the checker.
- **Parse check:** run `node <scratchpad>/checker/verify.mjs <project> <project> --files-from <scratchpad>/files.txt > <scratchpad>/parse.txt` once. It exits non-zero when a file has an `original parse error`; that is expected. Keep those files in `files.txt`, because agents can still read them, and list them in the report: a file that does not parse is often a bug itself. Ignore any other failure line in that run (the checker is used here only to list and parse files) and remove nothing.
- **Groups:** as in step 1, but up to about 1,500 lines each (reading is faster than writing). Waves hold at most 7 agents. Under about 1,500 lines in total, work in the main session.
- **The plan:** languages and stack, file and line counts per package, out-of-scope, `SKIPPED:` and `SKIPPED DIR:` entries, files that do not parse, test commands, and the groups and waves.

### 2. Safety net

- **Back up** the in-scope files: `rsync -a --files-from=<scratchpad>/files.txt <project>/ <scratchpad>/orig/`.
- **Changed-paths snapshot:** `touch <scratchpad>/start-marker`, and in git also `git -C <project> status --porcelain=v1 -uall > <scratchpad>/status-before.txt`.
- **Facts:** write `<scratchpad>/facts.md` with the absolute paths `<scratchpad>` and `<project>` stand for, the languages and stack per package, the scope, the path of each map, the test commands with what they need, and these rules: read only; never open `.env*`, credentials or key files (`.env.example` may be read); never run anything in `<project>`.
- **No baselines.** Nothing is edited, so there is nothing to compare.
- **Running code to confirm a finding** is allowed, never in `<project>`. Set up a work copy and dependencies as step 2 says (**One work copy**, including the free-space check, and **Dependencies**, including asking before an install), and follow its **Tests** rules: a timeout, the background when slow, no snapshot-update flags, never a script that sends email, charges money or calls production services, and private service instances. An agent that runs code makes its own copy inside its agent folder, so agents never share one.

### 3. Agents

For each group, build `<scratchpad>/agent-<n>/` with `files.txt` (its exact file list, with no blank or `#` lines) and `rules.md`. No `frozen.txt` slice is needed. Build `rules.md` from the group's whole language files, in the table's order (for JS / TS: `lang/js.md`, the style files, then the area files). Their **Bug report additions** and framework sections are what the agents need. A first line tells the agent to ignore the comment-writing rules. Replace `<files>` with the group's language files:

```sh
A=<scratchpad>/agent-<n>
{ echo "Read-only bug check. Ignore every instruction below to write, change or verify comments; use these files only for what they say about the code, its frameworks and its bugs."; echo
  for f in <files>; do cat "<skill-dir>/references/$f"; echo; done
  cat <scratchpad>/facts.md; echo
  for m in shapes routes events env; do
    echo "## Map: $m (rows for this group)"; grep -F -f "$A/files.txt" "<scratchpad>/maps/$m.md"; echo
  done
} > "$A/rules.md"
```

`grep -F` matches substrings, so a group may get a few extra map rows (`src/a.ts` also matches `src/a.tsx`); that is harmless.

Launch one general-purpose agent per group, all groups of a wave in a single message. Give each agent the path to its folder and tell it:

- Read `rules.md` in full first. Read other project files read-only when needed: callers, views, tests, and the full maps in `<scratchpad>/maps/`.
- Read only: never edit, create or delete any file in the project. Keep helper scripts and any copy of the project inside the agent folder.
- Never open `.env*`, credentials or key files (`.env.example` may be read).
- Open the code behind every finding before listing it.
- Write `report.md` in the agent folder with each bug as `file:line`, a one-line problem, a one-line fix, and a severity:
  - **Serious:** security, data loss, a crash or 500 on normal input, wrong results in a main path.
  - **Medium:** edge cases, wrong error codes, unlikely races, misleading public docs.
  - **Minor:** smells and small doc errors.
- If the Write tool refuses `report.md`, return the full report in the reply instead. Otherwise reply with one line: files read, and bug counts per severity.

When an agent returns its report in the reply, save it to its `report.md` before reading the next one.

### 4. Final check

Both checks must come back empty:

- **Byte compare:** `while IFS= read -r f; do cmp -s "<scratchpad>/orig/$f" "<project>/$f" || echo "CHANGED: $f"; done < <scratchpad>/files.txt`. This is stricter than verify, because comments must not change either.
- **Changed paths:** `(cd <project> && find . -path ./.git -prune -o -type f -newer <scratchpad>/start-marker -print | sed 's|^\./||') | LC_ALL=C sort > <scratchpad>/changed.txt`. The file must be empty. In git, `git -C <project> status --porcelain=v1 -uall` must equal `status-before.txt`.

If either check is not empty, list each path in the report and say the run was not read-only. Restore the paths as `SKILL.md` step 4, item 8 says.

### 5. Report

- The languages and stack per package, and the git state at the start.
- The final check: byte compare, changed paths and git status, or which of them could not run and why.
- The scope: files read by area, out-of-scope files, `SKIPPED:` and `SKIPPED DIR:` entries, and the files that do not parse.
- The code that was run to confirm findings, if any, with its results.
- The bug list, de-duplicated across agents (read the reports by count first, then one at a time). Rank it by severity, then as **Report ranking** in `references/discovery.md` says. Confirm every Serious entry against the code yourself before listing it. Downgrade or drop one the code does not support, and say so.

Fix nothing. Ask which bugs to fix. For any fix, follow the last paragraph of `SKILL.md` step 5.
