# Skill specification reference

Facts for judging a target skill's frontmatter, layout, and runtime behavior. Sources:
Claude Code skills docs (https://code.claude.com/docs/en/skills) and the Agent Skills open spec
(https://agentskills.io/specification). Where they differ, both are given. Verified against
both pages on 2026-11-12, except the items marked *unverified* (which carry their own date); a
report's "Spec facts" line cites 2026-11-12. Claude Code changes quickly: facts tagged *(version-sensitive)* below
are the likeliest to drift. This skill does not fetch the docs: when a target is wrong on one of
them, cite this file with its date, and tell the user to confirm against the live docs.

## Contents

1. Frontmatter fields
2. Constraints and limits
3. Body substitutions
4. Dynamic context injection (`!` commands)
5. `allowed-tools` and `disallowed-tools`
6. Locations, precedence, namespacing
7. Size and progressive disclosure
8. Validators

## 1. Frontmatter fields

Every field is optional. `description` is strongly recommended: without it, Claude cannot decide
when to load the skill.

| Field | Type | Meaning | Default |
|---|---|---|---|
| `name` | string | Slash-command name | Directory name |
| `description` | string | What the skill does and when to use it; drives auto-loading | First non-empty body line |
| `when_to_use` | string | Extra trigger text appended to the description in the listing *(version-sensitive; some plugin guidance treats it as legacy - prefer putting triggers in `description`)* | none |
| `argument-hint` | string | Autocomplete hint, e.g. `[issue-number]` | none |
| `arguments` | string or list | Named positional args, used as `$name` | none |
| `disable-model-invocation` | bool | `true` = only the user can invoke it (via `/name`) | `false` |
| `user-invocable` | bool | `false` = hidden from the `/` menu; Claude-only | `true` |
| `allowed-tools` | string or list | Tools pre-approved for the invoking turn | none |
| `disallowed-tools` | string or list | Tools removed while the skill is active *(version-sensitive)* | none |
| `model` | string | Model for the skill, or `inherit` | Session model |
| `effort` | string | `low`, `medium`, `high`, `xhigh`, `max` *(version-sensitive)* | Session effort |
| `context` | string | `fork` = run in a forked subagent | none (inline) |
| `agent` | string | Subagent type when `context: fork` | `general-purpose` |
| `background` | bool | With `context: fork` only; `false` waits for the result *(version-sensitive)* | `true` |
| `hooks` | object | Hooks registered on invoke, active for the session | none |
| `paths` | string or list | Globs that limit auto-activation to matching files | none |
| `shell` | string | `bash` or `powershell`, for `!` command blocks *(version-sensitive)* | `bash` |
| `metadata` | map | Free-form; Claude Code ignores it | none |
| `license`, `compatibility` | string | Spec fields; accepted, not acted on | none |

- `version` appears in many plugin skills but neither doc page lists it. It is ignored: harmless,
  but not a real control.
- Unknown fields are ignored without error, so a typo (`allowed_tools`, `descripton`) fails
  silently. Flag likely typos.
- With malformed YAML, the body loads with empty metadata, so `/name` still works but
  auto-triggering is lost. Treat this as a high-impact finding.
- Contradiction: `disable-model-invocation: true` plus `user-invocable: false` leaves nothing that
  can invoke the skill.
- `agent` and `background` do nothing without `context: fork`.

## 2. Constraints and limits

**name**

- Spec: 1-64 characters, lowercase `a-z`, `0-9`, and hyphens. No leading, trailing, or
  consecutive hyphens. Must match the parent directory name.
- Claude Code: states no length or regex rule, but refuses names that contain zero-width or
  control characters, private-use or unassigned characters, bidi controls, non-plain blanks
  (NBSP, double spaces, leading or trailing spaces), or `<` and `>`.
- Reserved: `anthropic-skills`, `anthropic-skills:*`, and a folder named `synced`.

**description**

- Spec: 1-1024 characters, non-empty.
- Claude Code listing: description plus `when_to_use` is truncated at 1,536 characters
  (`skillListingMaxDescChars`). Trigger phrases past the cut are never seen.
- The whole skill listing gets about 1% of the context window. On overflow, the descriptions of
  the least-invoked skills drop first; names always stay. Settings that affect this:
  `skillListingBudgetFraction`, `SLASH_COMMAND_TOOL_CHAR_BUDGET`, and `skillOverrides`
  (`name-only`). A long description therefore costs the user's whole skill ecosystem, not just
  this skill.
- `<` and `>` in description or `when_to_use` render as `&lt;` `&gt;`. Use `[brackets]`.

**compatibility** (spec): 1-500 characters if present.

## 3. Body substitutions

| Token | Expands to |
|---|---|
| `$ARGUMENTS` | All arguments, as typed |
| `$ARGUMENTS[N]`, `$N` | Argument at 0-based index N (shell-style quoting) |
| `$name` | Named argument from the `arguments` list |
| `${CLAUDE_SKILL_DIR}` | Directory containing `SKILL.md`: use it for bundled script paths |
| `${CLAUDE_PROJECT_DIR}` | Project root |
| `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}` | Session ID, effort level |
| `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` | Plugin skills only |

- If arguments are given but no placeholder is used, Claude Code appends `ARGUMENTS: <value>`.
- An unmatched `$2` stays literal. An unmatched named argument becomes empty.
- Escape a literal dollar sign as `\$`. Expanded values are not re-expanded.
- Substitution applies to the `SKILL.md` body when the skill loads *(version-sensitive)*.
  Reference files read later with the Read tool are not preprocessed: `${CLAUDE_SKILL_DIR}` and
  `$ARGUMENTS` inside them stay literal, so the model has to resolve them.
- `$0`-`$9` inside commands in `SKILL.md` (shell `$1`, awk `$0`) are replaced with skill
  arguments. Escape them as `\$1` (lint `BODY011`).
- Review point: a script path written relative to the working directory
  (`python scripts/x.py`) breaks whenever the working directory is not the skill folder.
  `${CLAUDE_SKILL_DIR}/scripts/x.py` is the robust form.

## 4. Dynamic context injection (`!` commands)

- Syntax: `` !`command` `` inline, at the start of a line or after whitespace. A fenced block
  opened with ```` ```! ```` runs multi-line commands.
- The command runs **before** the skill content reaches Claude, and its output replaces the
  placeholder. Output is not re-scanned for placeholders.
- It runs in the session's working directory with a 2-minute timeout. A failure aborts the whole
  invocation. Non-zero exit counts as failure, except exit 1 from search/compare commands; use
  `|| true` when non-zero is expected.
- Permissions are checked against the permission rules with **no prompt**. Outside auto mode,
  anything not allowed aborts. `allowed-tools` can pre-approve the command.
- Admins can disable it with `"disableSkillShellExecution": true`. This does not affect bundled
  and managed skills.
- Security weight: this is code that runs merely because the skill was invoked, before any model
  judgment. Every `!` line deserves a finding that states what it runs and what it can reach.
- Plugin skills can reference plugin-level files as `${CLAUDE_PLUGIN_ROOT}/...` (shared scripts,
  hook scripts, sibling skills' references). A plugin's `hooks/hooks.json`, hooks declared in
  `plugin.json`, and `.mcp.json` servers run whenever the plugin is enabled. Vetting one skill of a
  plugin therefore means vetting those files too.
- The `hooks` frontmatter field is the same class of risk: its commands are registered when the
  skill is invoked and stay active for the session. List each command as a finding.

## 5. `allowed-tools` and `disallowed-tools`

- Format: a space- or comma-separated string, or a YAML list.
- Bash patterns: the Claude Code docs use the space form (`Bash(git add *)`,
  `Bash(python3 *)`, `Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)`). The spec's examples use
  the colon form (`Bash(git:*)`). Both appear in the wild.
- **`allowed-tools` pre-approves; it does not restrict.** Every tool stays callable, and
  unlisted tools fall back to the normal permission settings. Deny and ask rules still win. The
  grant lasts for the invoking turn and clears on the next user message *(unverified against the
  live docs as of 2026-11-13; if the grant outlasts the turn, the menu order costs nothing; if it
  is narrower, every script run prompts and the analysis still works)*.
- To actually restrict tools, use `disallowed-tools`.
- `${CLAUDE_SKILL_DIR}` is substituted inside `allowed-tools` patterns too (docs example above;
  *unverified against the live docs as of 2026-11-13; if it is not, the two script runs prompt
  instead of running pre-approved*),
  so a skill can pre-approve exactly its own scripts. Matching is on the command text: if the
  body's command quotes the path differently from the pattern, the user simply gets a prompt.
- Review points:
  - A bare `Bash` or `Bash(*)` pre-approves any shell command for that turn.
  - An interpreter wildcard (`Bash(python3 *)`, `Bash(node:*)`, `Bash(bash *)`, `Bash(uv run *)`,
    `Bash(npx *)`) is just as broad: `python3 -c '...'` or a script inside an untrusted target
    runs without a prompt. This matters most for skills that read untrusted content.
  - A directory wildcard (`Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/*)`) can be escaped with
    `../`. Least privilege is one entry per script, path quoted:
    `Bash(python3 -I -B "${CLAUDE_SKILL_DIR}/scripts/x.py" *)`.
  - Code-capable commands with free arguments are as broad as interpreters: `git -c core.pager=...`,
    `npm run` (runs the target's `package.json` scripts), `find -exec`, `env`, `xargs`, `make`,
    `curl -o`.
  - Quoting must match: if the pattern quotes the script path, the body's commands must quote it
    the same way, or every run prompts. Quote paths so install folders with spaces work.
  - Pre-approved scripts become no-prompt tools for whatever arguments the model passes. Scripts
    that read or write files should validate their arguments themselves.
  - Pre-approving `Write`/`Edit` lets an injected instruction write anywhere (shell rc files,
    `.claude/settings.json`) without a prompt. Skills that only save one report rarely need it.
  - An author who wrote `allowed-tools: Read` expecting a read-only sandbox is mistaken. Flag
    this misunderstanding.
  - Pre-approving both a network tool and Bash widens the exfiltration surface.

## 6. Locations, precedence, namespacing

| Scope | Path |
|---|---|
| Enterprise | managed settings dir `.claude/skills/<name>/SKILL.md` |
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Project | `.claude/skills/<name>/SKILL.md` (from the start dir up to the repo root) |
| Nested | `<subdir>/.claude/skills/<name>/SKILL.md`; invoked as `/subdir:name` |
| Additional dir | `.claude/skills/` inside an `--add-dir` directory |
| Plugin | `<plugin>/skills/<name>/SKILL.md`; invoked as `/plugin-name:skill-name` |
| claude.ai sync | `~/.claude/skills/synced/` |

- Precedence for the same name: enterprise > personal > project.
- A skill beats a same-named `.claude/commands/` file.
- Plugin skills are namespaced, so they never collide by name, though they can still collide
  by description.

## 7. Size and progressive disclosure

- Three loading levels:
  1. `name` and `description` are always in context (~100 tokens).
  2. The `SKILL.md` body loads on trigger.
  3. Bundled files load only when read. Scripts can run without being read.
- Size thresholds. This table is the single source for size judgments in this skill: the
  rubric, failure-mode catalog, and `lint_skill.py` (`BODY001-003`) all use it.

  | Measure | Target | Warn | Error | Source |
  |---|---|---|---|---|
  | Body words | <= 2,000 | > 3,000 | > 3,750 (~5,000 tokens) | plugin-dev guidance; spec "< 5,000 tokens" |
  | `SKILL.md` lines | - | > 500 | - | Claude Code docs and spec |
  | `description` chars | ~200-600 | > 600 (info) | > 1,024 | spec max; listing budget |
  | description + `when_to_use` | - | > 1,536 (warn: truncated) | - | Claude Code listing |
- Keep file references one level deep from `SKILL.md`. A reference reachable only through
  another reference is often never read.
- Folder conventions: `scripts/` is executed, not loaded. `references/` is read on demand.
  `assets/` holds templates and data used in output. `examples/` holds working samples.
- After compaction, re-attached skills keep their first 5,000 tokens each, within a 25,000-token
  combined budget. Instructions placed late in a long `SKILL.md` can be lost after compaction.
  Put critical rules early.

## 8. Validators

- `skills-ref validate ./my-skill` (Agent Skills reference tool).
- `claude plugin validate <dir>` finds frontmatter it cannot parse *(version-sensitive; the version
  that added it is unverified)*.
- This skill's own `scripts/lint_skill.py` covers the rules above that can be checked statically.
