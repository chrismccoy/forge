# Compatibility reference

How to turn the `requirements` check into report section 13's compatibility table. Read before
writing section 13. Every line is derived from
evidence, never guessed.

## Contents

1. Confidence labels
2. The eight axes
3. Surface matrix
4. Section 13 table format
5. Writing rules

## 1. Confidence labels

Label every requirement, and every claim in the report that is not a direct quote:

| Label | Meaning | How to write it |
|---|---|---|
| **Verified** | Traced to a file and line in the skill, or to a current official doc | State it plainly; cite `path:line` |
| **Inferred** | Follows from a signal but is not stated (a `match` statement implies Python 3.10+) | Name the trigger: `Python 3.10+ (match in scripts/x.py:41)` |
| **Unverified** | Plausible but unsupported | Add `(unverified)`, or leave it out |

- Never write a version floor from memory. `Node 18+` or `Python 3.11+` needs a declaration in
  the skill (`engines`, `requires-python`, a pinned install, a shebang) or a syntax signal from
  the `requirements` check.
- Prefer a capability to a version: "needs the Claude in Chrome connector" beats "needs Claude
  Code 1.2+". Product facts drift: take them from this file, label them Inferred, and tell the
  user to verify a load-bearing one (`workflow.md` section 4, web policy).

## 2. The eight axes

Every requirement belongs to exactly one axis. The `requirements` check feeds Runtime, Packages,
Tools, Network, and Companions. Surfaces is derived from Tools with the matrix below; Model and
Degradation come from reading `SKILL.md`.

| Axis | Source in the check | Write it as | Common mistakes |
|---|---|---|---|
| **Surfaces** | Derived from Tools via the matrix below | `Claude Code ✅ · Cowork ✅ · claude.ai ⚠️ no display · Chrome ❌ no shell · API ⚠️ needs Bash wired` | Leaving a surface out (silence reads as yes); a ❌ with no blocker named |
| **Runtime** | `runtime`: shebangs, `engines`, `requires-python`, `.nvmrc`, syntax floors; also `binaries` (external programs; leave out POSIX core tools every Bash surface has: `sed`, `grep`, `sort`, `find`, `awk`, `df`, `comm`, `touch`, `chmod`, `cp`, `mv`, `mkdir`, `cat`, `wc`, `cmp`, `diff`, `xargs`, `patch`; list `rsync`, `git`, `jq`, and anything not in POSIX). A program used only when the project has it (`cargo` in a Rust repo) is "optional, used when present" | `Python 3.10+ (match in scripts/x.py:41)` | Copying a floor from another project; calling `npx` in prose a Node runtime need |
| **Packages** | `packages`: third-party imports, manifests, install commands | One paste-ready command per package, its second-stage step on the same line: `pip install pyyaml`. If the shipped command is broken, write the working one (labelled Inferred: untested) and cite the broken one as a finding | Listing stdlib modules; missing second-stage installs (`playwright install chromium`); guarded imports stated as required |
| **Tools** | `tools`: what the instructions rely on, from `SKILL.md` and `allowed-tools` | `Bash · file write · image viewing (render check)` | Missing vision in "look at the render" loops (the most common undeclared need); an optional tool stated as required |
| **Network** | `network`: domains used by commands or network calls, split install vs runtime | `pypi.org at install; overpass-api.de at runtime - blocked where domains are allowlisted` | "Needs internet" with no domain; docs links counted as needs (the check counts those separately) |
| **Model** | Judgment, not detected | `Any model. Long multi-file loop - a stronger model reduces retries` | "Requires Opus" with no reason; naming model versions from memory; vision put here instead of Tools |
| **Companions** | `companions`: installed or sibling skills named in instructions or routing lines | `Feeds seo-schema · Routes styling questions to frontend-design` | Listing every skill in the folder; calling a companion a requirement when the skill runs alone |
| **Degrades to** | Reading `SKILL.md` fallbacks | `Without Python: checks done by hand; appendix best-effort` | Claiming graceful degradation the skill does not implement. If it simply fails, say so |

Also report the declared `compatibility` frontmatter field (if any) against what was detected;
`REQ002` flags omissions.

- A package manager used only to install (`npm` for `npm ci`, `pip`) goes in the Packages row
  with its install command, even though the requirements output lists it under `binaries`; the
  runtime it belongs to (Node, Python) goes in Runtime.
- When the skill names a service but no domain (`npm ci`, `pip install -r`), the check lists the
  default registry as Inferred (`registry.npmjs.org`, `pypi.org`); keep that label. For an install
  command the check missed, name the tool's default registry the same way, labelled Inferred
  (by reading), citing the install line.
- When reading finds a need the check missed (a fetch from page context, a CDN script tag), add
  it labelled "Verified (by reading)" and cite the line.
- A row that mixes evidence (a shebang plus an inferred floor) carries both labels and cites
  the shebang by its line: "Verified (`scripts/run.mjs:1`) / Inferred (16+)". The report check
  accepts a `file:line` citation, not the bare word "shebang".
- Facts about a third-party tool (npm needs a lockfile for `npm ci`) are labelled Inferred and
  name the tool; the target-side evidence (no lockfile ships) is Verified. A third-party fact you
  cannot tie to the tool's documented behavior is labelled `(unverified)` instead.
- This skill does no web lookups. Surface verdicts and other product facts come from the dated
  matrix below and are labelled Inferred; say "per compatibility.md (dated)" in the Evidence cell of any hard ❌.

## 3. Surface matrix

*(version-sensitive: capabilities differ by surface, plan, and configuration, and change over
time. Default mapping as of 2026-11. This skill does not fetch these docs: tell the user to
verify anything load-bearing - especially a hard ❌ - at code.claude.com/docs, docs.claude.com,
or support.claude.com.)*

| Surface | What it is |
|---|---|
| **Claude Code** | Terminal, IDE, or desktop agent: full shell, local files, MCP servers, subagents |
| **Cowork** | Agentic desktop workspace: shell and files, no display, file delivery to the user |
| **claude.ai** | Web and mobile chat with a Linux sandbox: Bash, Python, a per-task filesystem, allowlisted network, no display, no subagents |
| **Claude in Chrome** | Browser agent: page reading and interaction, no general shell |
| **API / Agent SDK** | Whatever tools the developer wires up; assume text only unless the skill says otherwise |

| Capability needed | Claude Code | Cowork | claude.ai | Chrome | API |
|---|---|---|---|---|---|
| Text in, text out | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bash / shell | ✅ | ✅ | ✅ sandboxed | ❌ | ⚠️ if wired |
| The user's own repo / local files | ✅ | ✅ | ❌ uploads only | ❌ | ⚠️ if wired |
| Files persisting across turns | ✅ | ✅ | ⚠️ resets between tasks | ❌ | ⚠️ |
| Arbitrary network | ✅ | ✅ | ❌ allowlisted domains | ⚠️ page-scoped | ⚠️ |
| Package install | ✅ | ✅ | ⚠️ registries only; pip may need `--break-system-packages` | ❌ | ⚠️ |
| Display / headed browser | ⚠️ local only | ❌ headless | ❌ | n/a | ❌ |
| Subagents / parallel tasks | ✅ | ✅ | ❌ serial | ❌ | ⚠️ |
| Image viewing (vision) | ✅ | ✅ | ✅ | ✅ | ⚠️ model-dependent |
| File delivered to the user | ✅ | ✅ | ✅ | ❌ | ⚠️ |
| A named MCP connector | ✅ if installed | ✅ if installed | ⚠️ connector-dependent | n/a | ⚠️ |
| `git` / `gh` on the user's repo | ✅ | ✅ | ❌ | ❌ | ⚠️ |
| Asking the user mid-task (AskUserQuestion, multi-turn intake) | ✅ | ✅ | ✅ | ⚠️ unverified (no question dialog) | ⚠️ single-turn calls cannot answer |
| A user-named local file (not a whole repo) | ✅ | ✅ | ⚠️ upload it first | ❌ | ⚠️ if wired |
| Browser and shell sharing files (download in a browser, then process) | ⚠️ needs the Chrome connector and local paths | ⚠️ verify | ❌ the sandbox has no browser | ❌ no shell | ⚠️ if the developer wires a browser and shell |
| Claude Code skill features (`allowed-tools`, hooks, `!` commands, `${CLAUDE_SKILL_DIR}`) | ✅ | ⚠️ verify | ⚠️ verify | ❌ | ⚠️ Agent SDK only |

Verdicts:

- **✅** - every required capability is present by default.
- **⚠️** - it runs but loses something or needs setup; name what.
- **❌** - a required capability is missing; name the capability, not the surface.

The **Chrome** column means running as the Claude in Chrome agent itself. A skill that drives
Chrome through the connector from Claude Code is a Claude Code skill: mark Claude Code by the
connector need (and the browser-and-shell row when it downloads a file and then moves it with shell
commands), and explain the Chrome ❌ in one line so it does not read as a contradiction.

A skill **needs the repo itself** when it edits files in place, runs the project's build, tests, or
git, or reads many project files by path; claude.ai is then ❌. A skill that only reads files the
user can upload is ⚠️ there.

`$ARGUMENTS`, `$0`-`$9`, and `argument-hint` count as Claude Code skill features, and a skill
needs that row only when it fails without them (asking for the input instead is a fallback). In a
Surfaces cell, never put `·` or `;` inside a blocker (they separate surfaces); a comma is fine. The
header form of the API cell for a skill that waits for replies is `partial (single-turn calls
cannot answer)`, or a shorter blocker with the same meaning; the check compares only the marks. "The user's own
repo" covers editing or running a project; "a user-named local file" covers reading one file; a
skill that does both takes the repo row. The header's Runs on blocker text may be shorter than
section 13's; only the marks must match.

A skill **needs** a row only when it fails or loses a feature without it: pre-approving a tool in
`allowed-tools` is not by itself a need for the Claude Code skill features row. **Browser and
shell sharing files** means a file made in the browser (a download) is then read or moved by
shell commands. Manifest-driven installs (`npm ci`, `pip install -r requirements.txt`) count as
one command per manifest.

A skill that waits for the user with no fallback is still ⚠️ on the API (single-turn calls cannot
answer), never ❌. Bash process substitution (`<(...)`) needs bash: it counts through the Bash /
shell row. In the header's word form, write a ⚠️ unverified cell as "partial (unverified: reason)" and a ❌
cell as "blocked (reason)".

A skill that asks in plain chat (no AskUserQuestion) still needs the "Asking the user
mid-task" row with the same Chrome blocker. A question asked only when an input is missing (no
path given) still counts: mark the row, and name the way around it ("give the path up front"). This holds
for a skill that skips its questions when the first message already answers them: the API cell
stays ⚠️ (name the way around: give every answer up front). It is ✅ only when the skill also
states defaults it uses when no reply comes. When two rows give one
surface different marks (a named MCP connector ✅ if installed, browser and shell sharing files
⚠️), the worse mark wins; when two rows give the same mark for different reasons, name both,
separated by a comma.

Combining rows: each surface takes the worst mark across the capabilities the skill needs, and
names the capability that set it. Runtime and package needs count through the Bash / shell,
Package install, and Arbitrary network rows (the Packages row gives one paste-ready command per
manifest, or per package when no manifest ships). A capability with a working fallback the skill
states (subagents, else serial; asking the user, else a stated default) costs at most ⚠️, never
❌: mark ⚠️ where the fallback loses something (slower, less parallel), ✅ where it works in full. A ⚠️ verify or ⚠️ unverified cell is written in section 13 as `⚠️ unverified (reason)` (Chrome:
`⚠️ unverified (no question dialog)`), and in the header's word form as `partial (unverified:
reason)`; a plain ⚠️ is `⚠️ reason` / `partial (reason)`. Use these forms only, unless the skill
states support.

Shortcuts: a skill that needs the user's repository or long-lived local files is a Claude Code /
Cowork skill - say so, and mark claude.ai ⚠️ (uploads) unless it needs the repo itself (❌). A
text-only skill gets ✅ everywhere, except that a skill that waits for the user's reply is ⚠️ on
Chrome and the API (the "Asking the user mid-task" row).

## 4. Section 13 table format

```markdown
| Axis | Requirement | Confidence | Evidence |
|---|---|---|---|
| **Surfaces** | Claude Code ✅ · Cowork ✅ · claude.ai ⚠️ no display · Chrome ❌ no shell · API ⚠️ needs Bash wired | Inferred | Tools row + surface matrix |
| **Runtime** | Python 3.10+ | Inferred | match in `scripts/render.py:41` |
| **Packages** | `pip install playwright` then `playwright install chromium` | Verified | `scripts/render.py:3` |
| **Tools** | Bash · file write · image viewing (render check) | Verified | `SKILL.md:52`, allowed-tools |
| **Network** | pypi.org at install; none at runtime | Verified | `SKILL.md:30` |
| **Model** | Any; long multi-step loop - a stronger model reduces retries | Inferred | `SKILL.md` Steps 2-6 |
| **Companions** | Feeds `report-publisher` | Verified | `SKILL.md:88` |
| **Degrades to** | Without image viewing, the render check is skipped; mechanical checks still run | Verified | `SKILL.md:61` |
```

Follow it with a suggested frontmatter line, one line, at most 500 characters, with no `: `
inside the value (use a dash instead):

```yaml
compatibility: Requires Bash and Python 3.10+ with playwright - image viewing for the render check - Claude Code and Cowork only
```

`build_appendix.py` checks the table: Surfaces row present with all five surfaces marked,
blockers named, every version claim cited or marked `(unverified)`, and the suggested line valid.

## 5. Writing rules

- Name the blocker, not just the verdict: "❌ claude.ai - no display for Chromium".
- One install command per package, or one per manifest when a manifest drives the install
  (`npm ci`), in the form a user would paste.
- Requirements are per skill: never inherit a sibling skill's dependencies because they share a
  folder. Plugin files count only when the skill uses them (the check already scopes this).
- Keep the table to the eight rows. Put discussion below it, not in it.
- No hedging ("should work", "probably"). State it, cite it, or mark it `(unverified)`.
