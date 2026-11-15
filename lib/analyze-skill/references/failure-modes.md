# Skill failure modes and script audit checklist

Use Part A to fill the report's Failure Modes section and Part B to review each bundled script.
Report only the modes that apply, each with evidence (`path:line`). Do not paste the catalog
into the report.

## Contents

- A. Failure-mode catalog (triggering, instructions, structure, resources, environment,
  requirements and portability, output, security)
- B. Script audit checklist
- C. Severity guide

## A. Failure-mode catalog

### Triggering

| Mode | Signs | Mitigation |
|---|---|---|
| Under-triggering | Description lists topic words, not user phrasings; no "when" clause; key phrases placed past the 1,536-character listing cut | Add concrete quoted phrasings and contexts; front-load them |
| Over-triggering | Broad verbs ("help with code", "review"); no exclusions | Name the object (file type, tool); add "not for X" |
| Collision | Another installed skill claims the same phrases | Differentiate by artifact type or context; cross-reference the other skill |
| Description/body mismatch | Description promises outputs the body never produces | Align both; the description is a contract |
| Listing-budget pressure | Description far longer than needed | Trim; the listing shares about 1% of context with every skill |
| Wrong invoker | Side-effecting skill (deploy, send, delete) can auto-trigger | `disable-model-invocation: true` |

### Instructions

| Mode | Signs | Mitigation |
|---|---|---|
| Ambiguous decision | "as appropriate", "if needed", "when relevant" | Name the condition and the action |
| Missing stop condition | No rule for missing input; the model invents a target | Explicit "stop and ask" branch |
| Conflicting rules | Two sections disagree (word budgets, "never truncate" vs a size cap) | One rule, one place |
| Repetition | The same rule appears 3+ times, which inflates tokens and signals anxiety | State it once, early, in bold if critical |
| Over-emphasis | Many MUST/NEVER/CRITICAL lines; every rule looks equally urgent | Reserve emphasis for 1-3 true invariants |
| Non-actionable line | Sampling settings, "model-agnostic", tools not available | Delete, or replace with something the model can do |
| Second-person drift | Mixed "you should" and imperative voice | Pick one; the plugin-dev convention is imperative |
| Late critical rule | Key rule after ~5,000 tokens; lost after compaction | Move it up |

### Structure and resources

| Mode | Signs | Mitigation |
|---|---|---|
| Monolith | Body past the warn thresholds in `skill-spec.md` section 7 (> 3,000 words or > 500 lines); detail inline | Move detail to `references/` with "read when" pointers |
| Orphan resource | File shipped but never referenced (`REF003`) | Reference it with a trigger condition, or delete it |
| Dangling reference | `SKILL.md` names a missing file (`REF001`) | Add the file or fix the path |
| Deep chain | Reference reachable only via another reference (`REF002`) | Link it directly from `SKILL.md` |
| Duplication | Same content in `SKILL.md` and a reference | Keep one copy; point to it |
| Interface drift | `SKILL.md` calls a script with arguments or output it does not have | Re-read the script's argparse/usage; fix one or the other |
| No navigation | Reference over 100 lines with no contents list | Add a contents list or grep hints |

### Environment

| Mode | Signs | Mitigation |
|---|---|---|
| Relative script path | `python scripts/x.py` | `${CLAUDE_SKILL_DIR}/scripts/x.py` |
| Undeclared dependency | Third-party import with no install note (`SCR004`) | Stdlib-only, a guarded import, or a documented install |
| Platform assumption | GNU-only flags, `/home/...` paths, backslash paths, bash-only syntax | Portable commands; state the platform |
| Missing interpreter | `python` vs `python3`; no shebang | State the interpreter in the command |
| Tool absent | Body needs Write/Bash and has no fallback | Fallback branch (print instead of save) |
| Network required | Script fetches at run time; fails offline or in a sandbox | Bundle the data, or handle the failure clearly |

### Requirements and portability

| Mode | Signs | Mitigation |
|---|---|---|
| Undeclared vision need | "look at the render", "check the screenshot" loops, no mention of image viewing | Declare it in `compatibility`; add a fallback |
| Missing second-stage install | `pip install playwright` without `playwright install chromium` | List both commands |
| Runtime domain blocked | Runtime calls to non-registry domains; surfaces that allowlist domains block them | Name the domains; state the affected surfaces |
| Version floor never stated | Syntax needs Python 3.10+ / Node 18+ but nothing declares it (`REQ007`) | Declare it, or avoid the syntax |
| Surface assumption | Needs the user's repo, a display, or subagents but claims to work everywhere | Mark surfaces honestly in `compatibility` |
| Package without install path | Third-party import with no install command or manifest (`REQ005`) | Add a manifest or install line |

### Output

| Mode | Signs | Mitigation |
|---|---|---|
| Silent overwrite | Fixed output filename, no existence check | Ask first, or add a unique suffix |
| Output in skill folder | Report written to the working directory while it is the skill folder | Write outside the target |
| Truncation | Large outputs with no rule; the model summarizes the verbatim parts | Explicit "never truncate" plus size handling |
| Unverifiable contract | Required sections with no checklist or template | Template in `assets/` plus a pre-delivery check |
| Format break | Verbatim quotes containing fences break the Markdown | Fence longer than any inner fence |

### Security

| Mode | Signs | Mitigation |
|---|---|---|
| Unscoped pre-approval | `allowed-tools: Bash`, `Bash(*)`, an interpreter wildcard (`Bash(python3 *)`, `Bash(node:*)`), or a code-capable command with free arguments (`Bash(git *)`, `Bash(npm run *)`, `Bash(find *)`, `Bash(env *)`, `Bash(xargs *)`, `Bash(curl *)`) | One entry per bundled script: `Bash(python3 -I -B "${CLAUDE_SKILL_DIR}/scripts/x.py" *)` |
| Relative pre-approval | `Bash(python3 scripts/x.py *)` matches whatever `scripts/` sits in the working directory | Anchor on `${CLAUDE_SKILL_DIR}` |
| Write pre-approval | `Write`/`Edit` in `allowed-tools` on a skill that reads untrusted content | Leave writes to the normal prompt |
| Restriction illusion | Author believes `allowed-tools` blocks other tools | Use `disallowed-tools` for real limits |
| Load-time execution | `` !`cmd` `` lines; run before any model judgment | Justify each one; keep it read-only; `\|\| true` |
| Hook execution | `hooks:` in frontmatter registers commands that run on invocation and stay active for the session | List every command; justify it; prefer no hooks in shared skills |
| Data-as-instructions | Skill reads untrusted files or web pages and follows what they say | Explicit data-isolation rule; quote rather than obey |
| Hidden instructions | Zero-width, bidi, or variation-selector characters; HTML comments in Markdown (invisible when rendered); encoded blobs; a reference contradicting `SKILL.md` | Strip them; review decoded content |
| Symlink escape | A file or directory symlink pointing outside the skill (`~/.ssh`, `/etc`) | Remove; ship real files. Analyzers must never read through it |
| Vendored payload | Code inside `node_modules/`, `.venv/`, or similar, called from `SKILL.md` | Ship dependencies declared, not vendored; review anything called |
| Plugin-wide hooks | The skill's plugin registers hooks or MCP servers that run whenever the plugin is enabled, used or not | Vet the plugin, not only the skill; list each command |
| Hidden plugin dependency | Skill calls `${CLAUDE_PLUGIN_ROOT}/...` scripts or borrows a sibling skill's files; a skill-only review misses them | Name plugin-level dependencies in the File Map; review them like skill files |
| Broken plugin path | `${CLAUDE_PLUGIN_ROOT}/...` target missing, or the skill is copied out of its plugin | Ship the file inside the skill, or document the plugin requirement |
| Exfiltration path | Network tool plus file reads plus no confirmation | Confirm before sending; limit destinations |
| Destructive command | `rm -rf`, `git reset --hard`, force push, DB drops | Confirmation step; dry-run flag |
| Persistence | Edits shell rc files, crontab, Claude settings, CLAUDE.md, hooks | User confirmation; document clearly |
| Supply chain | Run-time `pip install`/`npx`/`curl \| sh` of unpinned packages | Pin versions; vendor; or document the manual install |
| Secrets in files | Tokens, keys, passwords in scripts or examples | Remove and rotate; use env vars |

## B. Script audit checklist

Answer each question for every script. Facts go in the File Map; problems go in Security or
Failure Modes.

1. **Interface:** Entry point? Arguments and their validation? `--help`? Exit codes?
2. **Inputs:** Which paths does it read, and can a caller-controlled path escape the intended
   directory (`..`, absolute paths, symlinks)? Which env vars? Stdin?
3. **Outputs:** What goes to stdout (format stable enough for the model to parse)? Which files
   does it write, where, and does it overwrite?
4. **Execution:** Does it run subprocesses? With `shell=True` or string concatenation
   (injection)? `eval`/`exec`? Does it load code from the target data (`import` of
   user-supplied modules, `pickle`, `yaml.load` without SafeLoader)?
5. **Network:** Any HTTP or sockets? To where? What data is sent?
6. **Secrets and personal data:** Does it read credentials, tokens, or home-directory dotfiles?
   Does it log them?
7. **Dependencies:** Stdlib only? Third-party imports: pinned, guarded, documented? External
   binaries (`jq`, `git`, `node`)?
8. **Robustness:** Behavior on a missing file, empty input, non-UTF-8, a huge file, or a
   timeout. Does it fail loudly with a clear message?
9. **Determinism:** Same input, same output? Ordering stable (sorted walks)?
10. **Fit:** Does `SKILL.md` invoke it with the right arguments and parse its real output? Is
    the work deterministic enough to justify a script rather than model reasoning, or the
    reverse?

**Browser-side scripts** (JavaScript pasted into a page through an MCP tool) also need:

1. **Origin and credentials:** does it run in the user's logged-in page, and do its `fetch` calls
   carry that page's cookies?
2. **DOM changes:** what it adds, removes, or rewrites on the live page.
3. **Network targets:** whether the page or the script chooses where requests go.
4. **Data back to context:** what it copies into the conversation (and whether page text can
   inject instructions that way).

Read scripts only. Never run a target script to "see what it does", not even with `--help`.
`--help` still executes module-level code.

**Blind spots of `scan_security.py`.** Its JSON carries a `not_covered` list; that list is the
authoritative one (see `check-output.md` section 4). Check every item by hand for each script and
reference that matters.

## C. Severity guide

| Severity | Meaning | Examples |
|---|---|---|
| High | Can cause data loss, credential exposure, or code execution the user did not intend; or the skill cannot work | Unscoped Bash plus destructive command; secret in file; malformed frontmatter; hidden instructions |
| Medium | Wrong or unsafe output in realistic cases; reliability problems | Silent overwrite; relative script paths; collision; undeclared dependency; `!` command with side effects |
| Low | Quality, cost, or style issues | Second person; repetition; missing contents list; `version` field |
