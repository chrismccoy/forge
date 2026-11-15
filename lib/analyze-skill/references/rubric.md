# Skill scorecard rubric

## Contents

1. Scoring rules and tie-breaks
2. Dimensions (Triggering, Frontmatter validity, Structure & disclosure, Instruction clarity,
   Resources & scripts, Safety & permissions, Output contract, Testability & robustness)
3. Reading the total

Use the dimension names in the scorecard exactly as listed in item 2 (the check matches them).

Score each dimension 0-3, with a one-line reason citing evidence. Put the table in the Executive
Summary. The maximum is 24, or 21 when Resources & scripts is N/A (see "Reading the total").

| Score | Meaning |
|---|---|
| 3 | Strong: no meaningful issues |
| 2 | Adequate: minor issues |
| 1 | Weak: issues likely to affect real runs |
| 0 | Broken or absent |

One issue, one dimension: score each defect under the single dimension it belongs to most (a
broken YAML description lowers Frontmatter, not also Triggering; broad `allowed-tools` lowers
Safety, not Frontmatter), and mention it elsewhere without re-scoring it. Two cosmetic issues in
one dimension still score 2; a 1 needs an issue likely to affect real runs. Tie-breaks score the
defect where its fix lands:

- Description wording or length, FM011, FM028: Triggering. One such issue alone scores 2.
- YAML that does not parse: Frontmatter (0). Triggering is scored on the description text, with a
  note that it is ignored until fixed.
- `$0`-`$9` substituted inside a command (BODY011): Instruction clarity, 1 when the command
  breaks in normal use (including only when an argument is given), else 2.
- A needed step with no shipped tool, or a missing lockfile that blocks setup: Resources &
  scripts, 1.
- Pre-approved `Write` or `Edit` (unscoped) on a skill that reads untrusted input: Safety 2; with
  a shell or interpreter wildcard as well, 1.
- A skill that runs the project's own tests, builds, or installs by design: Safety judges whether
  it confirms first and limits the blast radius, not that it runs them.
- A needed step whose only route is a documented manual workaround: Resources & scripts 1 when it
  blocks a mode or the model must write the code itself (this is "no shipped tool"), 2 when the
  main path still works.
- A multi-turn intake with no single-turn fallback: Testability & robustness, 2. A fallback means
  the skill can finish without asking: it skips the intake when the first message already holds
  every answer, or it states defaults it uses when no reply comes. Defaults applied only after
  asking are not a fallback. (This is the Testability meaning. A surface mark is stricter:
  `compatibility.md` keeps the API ⚠️ unless the skill states defaults for no reply.)
- The same rule worded the same way (more than one sentence) in `SKILL.md` and a reference:
  Structure, 2. A README that restates
  `SKILL.md` for humans is not duplication.
- A collision marked `(unverified)` (sibling description cut at 1,000 characters, or an installed
  skill that could not be checked): score it as mild overlap and say so.
- An undefined workspace or output folder (with or without a stated default): Output contract 2
  when what it writes cannot collide with a file it did not create (a unique or timestamped name);
  1 when an existing same-name file the skill did not create would be overwritten. A single file
  the user names counts as untrusted input only when it comes from someone else (a downloaded
  file), not when the user wrote it.
- A misaligned example or template file (its content contradicts what `SKILL.md` or the scripts
  produce, or it is drawn wrongly, such as a box off by a column): Resources & scripts 2 (1 when the skill copies it into
  its output; "match the template exactly" counts as copying).
- A skill whose shell-capable agents read untrusted repos or pages: Safety 1 unless the agents are
  confined by all three of: no network, a scratch copy, confirmation before writes; then 2. This
  rule wins over the "runs project tests by design" tie-break. "Untrusted" means content the user
  did not write: downloaded repos, web pages, third-party files; the user's own codebase is
  trusted. A skill meant for any repo the user points it at ("audit this repo") reads untrusted
  input, since nothing limits it to the user's own code.
- A workspace defined loosely but with a stated fallback (`<scratchpad>` or a temp folder): Output
  contract can score 3. An overwrite counts as "can overwrite" when any normal input reaches it.
- A BODY011 command only on a rare branch (a fallback for huge projects): Instruction clarity 2.
- A shipped tool whose output channel is blocked (a browser allows one download per session):
  Resources & scripts 1, as "no shipped tool" for that output.
- Two skills that share a verb but take different inputs (a URL vs a file): mild overlap, not a
  collision; say which input routes where.
- A skill that edits user files in place on purpose: Safety can still score 3 when it confirms
  first, keeps a backup or works in a copy, and lists every changed file. When that skill also runs
  shell-capable agents over any repo the user points it at, the untrusted-input rule above wins;
  for it, "confirmation before writes" means one confirmation of the planned edit set before the
  first write.
- A chat-only output is "checked" when the skill states a self-check step against the format
  (a script is not required).
- A defect in a rule's scope (a rule applied to one section that should cover all): Instruction
  clarity, 1 when normal use breaks the rule in the output, else 2.

A paraphrase of one rule across files (not the same wording) is not duplication; it costs Structure
only when the copies disagree; two or more sentences repeated near word for word count as the same
wording. Without a defined workspace, a possible overwrite of a file the skill
did not create in the current folder scores Output contract 1; of its own earlier output, 2.

Definitions: a **collision** is another installed or sibling skill whose description claims the
same request; **mild overlap** is a shared word or phrase where the artifact type or context
still separates the two. The same quoted phrase in both descriptions is mild overlap only when
the rest of each description names what separates them; otherwise it is a collision. In Output
contract, a silent overwrite scores 1 only when it can destroy user data (any file the skill did
not create, such as a same-name file next to the source, or unsaved work; the harness rule that
Claude Read a file before Write does not change this, since the skill can Read and then Write); an overwrite of the
skill's own previous output is a gap (2). In Safety, pre-approved arbitrary code (an interpreter wildcard, a browser MCP plus
shell) on a skill that reads untrusted content scores 1; 0 needs shipped code or instructions
that cause harm without being tricked. A skill that correctly needs no references can score 3 on
Structure.

## Dimensions

### 1. Triggering

- **3** - Third person. States what the skill does and when to use it. Has concrete quoted user
  phrasings, disambiguating context (a "not for" clause when a near neighbour exists: an installed
  or sibling skill whose description shares a quoted phrase or the main verb and object), and no
  collisions. Within limits.
- **2** - Clear, but few phrasings or a mild overlap.
- **1** - Topic words only, a second-person or vague description, or collision likely.
- **0** - Missing, or so generic it never or always triggers.

### 2. Frontmatter validity

- **3** - Parses. Every field is valid and purposeful. The name matches the directory.
- **2** - One cosmetic issue: an undocumented `version`, or a missing `argument-hint`.
- **1** - Unknown or typo fields, contradictory settings, or a misunderstood `allowed-tools`.
- **0** - Malformed YAML, or no frontmatter.

### 3. Structure & disclosure

- **3** - Body within the target in `skill-spec.md` section 7 (<= 2,000 words and <= 500 lines).
  Detail lives in references, each with a "read when" pointer, one level deep. No orphans or
  duplication.
- **2** - Between target and warn thresholds, or one orphan or duplicate.
- **1** - Monolithic, over the warn threshold (even with references), or references unused or
  dangling.
- **0** - Unusable layout: no body, or broken references to core content.

### 4. Instruction clarity

- **3** - Imperative and consistent. Numbered workflow. Explicit branches and stop conditions.
  No ambiguity or non-actionable lines.
- **2** - Minor ambiguity or voice drift.
- **1** - Key decisions left to guesswork, conflicting rules, or heavy repetition within one file
  (the same rule copied between `SKILL.md` and a reference is Structure duplication instead).
- **0** - Cannot be followed.

### 5. Resources & scripts

Covers every bundled file: scripts, references, assets, examples (a misaligned example template
counts here). N/A only when the skill ships nothing but `SKILL.md` and meta files. Browser-side
scripts the model pastes into a page through an MCP tool are judged on correctness and on how
`SKILL.md` hands them over, not on `${CLAUDE_SKILL_DIR}` paths. When N/A, total out of 21.

- **3** - Scripts are correct, documented, dependency-light, and invoked with
  `${CLAUDE_SKILL_DIR}`. Their interfaces match `SKILL.md`.
- **2** - Minor gaps: no `--help`, a relative path, an unpinned dependency.
- **1** - Interface drift, undeclared dependencies, or fragile parsing.
- **0** - Bundled files broken or missing (a referenced script or reference that does not exist).

### 6. Safety & permissions

`security` mode scores only this row and maps it to a verdict (`report-sections.md` section 0).

- **3** - Least-privilege `allowed-tools`. No unconfirmed destructive or network actions.
  Untrusted data isolated. No secrets or hidden content.
- **2** - Slightly broad pre-approval, or a side effect that is documented but unconfirmed.
- **1** - Unscoped Bash, `!` commands with side effects, plugin hooks or MCP servers with broad
  reach and no justification, or an injection-prone design.
- **0** - Secrets, hidden instructions, destructive commands without confirmation, or remote
  code execution.

### 7. Output contract

For skills whose deliverable is not a saved file (code edits, a chat answer), judge whether the
deliverable is specified, bounded, and checked in the same way.

- **3** - Deliverable, location, and format are specified. A template plus a script or checklist enforces
  them. Overwrite and fallback are handled (for a chat-only deliverable: the format is specified
  and checked, and no overwrite applies).
- **2** - Specified, but not enforced; or one gap.
- **1** - Vague deliverable, or silent overwrite.
- **0** - No defined output.

### 8. Testability & robustness

- **3** - Edge and adversarial inputs handled. Evals or tests shipped, or easy to write.
  Behavior is deterministic where it matters. Requirements are declared (a `compatibility`
  field or equivalent) and degradation is stated.
- **2** - Main edge cases handled; no tests, or requirements left undeclared.
- **1** - Common edge cases (missing input, tool absent) unhandled.
- **0** - Fails on ordinary input.

## Reading the total

Write the total as `score/max` and judge it as a percentage, so prose-only skills (max 21) and
script-backed skills (max 24) use the same bands:

| Percentage | /24 | /21 | Verdict |
|---|---|---|---|
| >= 87% | 21-24 | 19-21 | Production-ready |
| 66-86% | 16-20 | 14-18 | Solid; fix the listed items |
| 41-65% | 10-15 | 9-13 | Works sometimes; needs revision before sharing |
| < 41% | 0-9 | 0-8 | Rework |

One 0 in Safety caps the verdict at "needs revision", whatever the total.
