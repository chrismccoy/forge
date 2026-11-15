# Report sections - detailed guidance

What each section must contain, how deep to go, and what good looks like, plus which sections
each mode writes. Cite `path:line` for every claim about the target (`SKILL.md:<first>-<last>` for
frontmatter findings that have no line), and label uncited claims Verified, Inferred, or
`(unverified)` per `workflow.md` section 4 (beginner mode: no labels). Never hedge. Size sections to the target: a prose-only
skill has a short File Map; a script-heavy skill has a short Techniques section and a long File
Map.

## Contents

0. Modes, lengths, and conventions (Sections per mode, Compat mode, Work per mode, Length bands,
   Conventions, Beginner mode)
1. Executive Summary
2. Skill Purpose & Trigger Conditions
3. Frontmatter & Metadata Analysis
4. Skill Body Structure
5. Script / Reference File Map
6. Instruction & Wording Analysis
7. Techniques & Patterns Used
8. Invocation & Execution Flow
9. Output & Format Specification
10. Security & Permissions Review
11. Evaluation / Testing / Behavior
12. Failure Modes & Robustness
13. Dependencies, Compatibility & Pipeline
14. Potential Interview / Review Questions
15. Optimization / Improvements
16. Appendix

---

## 0. Modes, lengths, and conventions

### Sections per mode

Every mode keeps the section numbers below, so a section means the same thing in every report.
`build_appendix.py --mode <mode>` checks that exactly these headings appear, in order.

| Mode | File | Title line | Sections | Appendix |
|---|---|---|---|---|
| `full` | `SKILL-SUMMARY*.md` | `# Skill Summary: <name>` | 1-16 | yes |
| `security` | `SKILL-SECURITY*.md` | `# Skill Security Review: <name>` | 1, 3, 5, 10, 12, 15, 16 | yes |
| `explain` | `SKILL-EXPLAINED*.md` | `# Skill Explained: <name>` | 1, 2, 4, 5, 6, 7, 8, 9, 13, 16 | yes |
| `interview` | `SKILL-INTERVIEW*.md` | `# Skill Interview Prep: <name>` | 1, 2, 4, 5, 6, 7, 8, 9, 13, 14, 16 | yes |
| `improve` | `SKILL-IMPROVE*.md` | `# Skill Improvement Review: <name>` | 1, 2, 3, 4, 6, 11, 12, 15, 16 | yes |
| `compat` | `SKILL-COMPAT*.md` | `# Skill Compatibility: <name>` | 1, 13 | no |
| `beginner` | `SKILL-BEGINNER*.md` | `# What this skill does: <name>` | the 8 beginner headings below | no |
| `quick` | none (chat) | - | 10-line verdict | no |

Mode emphasis:

- **security** - section 1 is, in order: the `Verdict:` line (exact wording under "Scores"
  below), the one-row Safety table, then one or two paragraphs; it scores only Safety &
  permissions; section 10 is the centerpiece. In section 5, keep the table, the Dependency map,
  and Missing and orphan files; rename Per-file notes to "What each file can do", one or two lines per
  file (run code, reach the network, write files, hold secrets). Item 6's Tools and Network
  findings (shell, file write, network, a browser connector, a download-then-shell handoff,
  including needs found only by reading) go in the section 10 risk table, by the row and severity
  table in section 10 (it applies in every mode). Inert references (no code, no commands) may share
  one "What each file can do" line. Section 3 notes only security-relevant frontmatter
  (allowed-tools, hooks, disable-model-invocation, disallowed-tools; an absent one reads `absent` in
  Value and `-` in Valid?): in security mode, this overrides section 3's
  "one row per field present", so name, description, and argument-hint get no row. Delete
  the template's Total row. "What each file can do" replaces the six-point narrative; browser-side
  script risks go in section 10.
- **explain** - no scorecard; section 1 states purpose, shape, and the one-sentence workflow.
  Write for someone learning how the skill works.
- **interview** - as explain, plus section 14 with the question counts in the minimums table below.
- **improve** - full scorecard; section 15 is the centerpiece, with replacement text.
- **compat** - section 13's table and suggested `compatibility:` line, with a short section 1. The
  rules are in "Compat mode" below.
- **quick** - in chat: what it does (1 line), where it runs (surfaces row), top 3 risks with
  `path:line`, score, and the single most important fix.

### Compat mode

1. **Section 1** is one paragraph plus a bullet per blocker or confirmed high hit. A blocker is a
   defect that breaks a surface or a mode; a lint warn (BODY010, REF003) is a blocker only when it
   does, else it goes in the discussion between section 13's table and "Declared vs detected". A
   high hit found false gets one sentence, no bullet; a true high hit with limited reach gets a
   bullet that states the limit. "A bullet per blocker" means defects and confirmed high hits, not
   the surface marks themselves.
2. **FM000** (frontmatter dropped) is a section 1 bullet, with the description quoted from the raw
   file: the value's first 200 characters, not counting `description: `, and the part around the
   break (find the `: ` or ` #` on the line FM000 names), in a code span; the full text is in the
   Appendix. It changes no surface mark (the skill still runs when invoked by name).
3. **Grep.** The word list is in the "Work per mode" table below. Match each word at a word start,
   case-sensitive (`\bexec`; words of three letters or fewer, such as `git` and `npx`, as whole words: `\bgit\b`), so `execSync`, `spawnSync`, and `https`
   are found but `digit` and `requires` are not. With no Grep tool, run shell `grep -n` on the named
   script and reference files the inventory lists, as `SKILL.md` allows. Open every hit in scripts
   (its line, with a few lines of context when needed), except regex method calls such as `.exec(`,
   the word inside a regex literal, and any comment (`import(...)` in JSDoc, `// import later`). In
   references, open hits inside code blocks and inside inline code spans whose text begins with a
   command name (a program you could type at a shell prompt: `npm ci`, not `tokio::spawn`), at most
   the first 20 per file plus every hit in a code block that runs a command. The homoglyph check
   covers `SKILL.md`, the scripts, and the references this mode Greps.
4. **Surface marks.** A defect that breaks one surface marks that surface ⚠️ with the defect as the
   blocker, in every mode (BODY011's `$0` substitution: Claude Code ⚠️, and Cowork ⚠️ unverified
   since it loads skills the same way); it also gets a section 1 bullet. A rare-branch BODY011
   marks no surface; it is a bullet only. A branch is rare when typical inputs never reach it: an
   error fallback, or a size threshold most targets stay under (a "projects over 5,000 files" branch
   is rare). A confirmed high security hit changes no surface mark either; it is a section 1 bullet
   with its reach. A packaging defect that breaks every surface (a missing lockfile) goes in
   Packages and section 1, and the surfaces are still marked by capability.
5. **Section 13 rows.** The Packages row shows the command that works today (the broken shipped one
   is a blocker), while the suggested line describes the skill once the listed fixes land. Package
   versions (`0.3.1`, `^7.26.0`) are not version claims and do not trip the version check (it looks
   for a floor such as `16+`); version floors come from the requirements output. When a fetch has no
   stated domain (a toolchain that downloads itself), name the tool and write "domain not stated"
   in the Network row. The API blocker names any fallback the skill states. In the Pipeline row,
   compat judges close siblings from their names only (it skips the siblings check): mark them
   Inferred.

### Work per mode (Step 3 items and references)

| Mode | Step 3 items (`workflow.md` section 3) | Read besides SKILL.md and this file | Report back |
|---|---|---|---|
| `full` | 1-7 | every file in this skill's own `references/` (`fallbacks.md` only on a fallback path), `report-template.md` | path, score, top 3 improvements |
| `security` | 1-5 (6: Tools and Network findings only, written into section 10) | skill-spec, failure-modes, compatibility, rubric (the Safety dimension and every tie-break that scores Safety), `report-template.md` | path, verdict, top 3 fixes |
| `explain` | 1-3, 4 (facts only: inputs, outputs, side effects, dependencies; no severity judgments), 5-7 | skill-spec, compatibility, failure-modes (Part B), `report-template.md` | path, one-line summary, the 3 key files |
| `interview` | 1-3, 4 (facts only, as `explain`), 5-7 | skill-spec, compatibility, failure-modes, `report-template.md` | path, question count, the 3 hardest questions |
| `improve` | 1, 2, 3, 4, 6, 7 | skill-spec, failure-modes, rubric, compatibility, `report-template.md` | path, score, top 3 improvements |
| `compat` (section 1 here overrides section 1's general guidance: one paragraph, no scorecard) | 1, 2 (limit: `SKILL.md` in full; scripts and references Grepped for `import`, `require`, `subprocess`, `child_process`, `exec`, `spawn`, `fetch`, `curl`, `http`, `install`, `npx`, `rsync`, `git`), 3, 4 (facts only, for scripts: imports, calls, network), 6 | compatibility, skill-spec, failure-modes (Part B), `report-template.md` | path, surfaces row, suggested `compatibility:` line |
| `beginner` | 1, 2 (here: files in scope: `SKILL.md`, the files it references, and the scripts it runs; README is optional, and may be named in plain words as a source), 3 (what hooks and MCP servers do, in plain words); skip item 4's checklist and the rubric | `beginner-template.md`, `skill-spec.md` sections 5 (what pre-approval means) and 6 (install folders) | path, top 3 weak spots from section 7 |
| `quick` | 1, plus the security, lint, and requirements output | rubric (dimensions the output can show; others `n/a (quick)`), compatibility (surfaces row) | the verdict itself |

Security hits must be confirmed at their lines in every mode that reports them all (`full`,
`security`, `improve`; `quick` confirms the hits it names plus every high); `compat`, `explain`, `interview`, and `beginner` confirm and
mention only the high hits that matter to their reader (`compat` puts them in section 1;
`beginner` also explains a medium hit that answers its "does it act without asking?" question,
confirmed at its line like the high ones).
`improve` puts its confirmed hits in sections 12 and 15. Sibling collision checks (and the
`--only siblings` run) belong to modes that run item 7. "Report back" above is the whole
chat reply after the path; it replaces any generic headline. The "Runs on" header line (every
mode but `beginner`) comes from the requirements `tools` row and the `compatibility.md` matrix,
even in modes that skip item 6.

Scores: `full` and `improve` use the 8-dimension scorecard; `quick` gives a rubric score in chat. `security` scores Safety & permissions
only and maps it to a verdict, written exactly as `Verdict: <wording>.`: 3 = "Safe to install as
is"; 2 = "Safe after the listed low and medium fixes"; 1 = "Not safe until the high-severity
issues are fixed"; 0 = "Do not install". The check ties the wording to the Safety score. Do not apply the rubric's
percentage bands to a one-row score: show a one-row table plus a `Verdict:` line. In `security`
mode, section 1 leads with the verdict, and sections 12 and 15 cover security and permission
issues only. Other modes have no scorecard (`quick` states its score in chat).

### Length bands

Prose words only: tables (required content), code fences, and the header block before section 1
do not count. Size classes count inventory files plus plugin files: small 1-3, medium 4-15,
large 16+. Under the band, look for missing required content (counts, per-file notes); never
pad. `build_appendix.py` prints the count and band as `INFO` and warns outside the band;
the warning is advisory - one pass to cut padding and repetition, then continue.

| Mode | Small target (1-3 files) | Medium (4-15) | Large (16+) |
|---|---|---|---|
| `full` | 1,200-2,600 | 1,800-4,000 | 2,500-5,000 |
| `security` | 400-1,300 | 550-1,700 | 800-2,400 |
| `explain` | 700-1,600 | 1,100-2,400 | 1,600-3,600 |
| `interview` | 1,000-2,200 | 1,500-3,000 | 2,000-4,200 |
| `improve` | 600-1,400 | 900-2,000 | 1,300-2,800 |
| `compat` | 150-800 | 200-900 | 250-1,000 |
| `beginner` | 350-1,300 | 350-1,300 | 350-1,400 |

Minimums scale with the target, so a small skill is not padded:

| Item | Small | Medium | Large |
|---|---|---|---|
| Trigger tests (section 2: should-trigger + near-miss prompts; the "Should trigger?" cell is Yes, No, or Ambiguous, and Ambiguous counts as a near-miss) | 3 + 3 | 4 + 4 | 5 + 5 |
| Review questions (section 14, `full`) | 5-8, answers 1-3 sentences | 8-12, answers 1-3 sentences | 10-15, answers 2-4 sentences |
| Review questions (`interview` mode) | 10-14 | 12-18 | 15-20 |
| Failure modes (section 12) | the categories that apply | the categories that apply, each checked against `failure-modes.md` A | consider every category in `failure-modes.md` A; report those that apply |

Where a section below names a count, these minimums win.

### Conventions

- A heading that does not apply: keep it and write `N/A - <one-line reason>`.
- Prose-only skills (no scripts or other code; references and assets allowed): section 5 is the
  table, with each reference's purpose and when `SKILL.md` loads it in its row, a one-line
  dependency map (`SKILL.md -> references/a.md (Step 2), references/b.md (Step 4)`) written under the
  template's `### Dependency map` heading in place of the tree, and the Missing and orphan files line; delete the Per-file notes subheading (this
  overrides the per-file narratives below; a reference's contents-list and read-when notes go in
  its table row). In section 11, keep the `**Script tests:**` label with its one line, `None (prose-only
  skill).` (the
  template's table becomes that line). Section 8 may skip the
  diagram. For a skill with no code, the Runtime, Packages, and Network rows of section 13 read
  "None (no code)". Section 4's heading outline is a table (heading, line range, words) in every
  skill, prose-only or script-backed.
- A browser-side script pasted into a page answers narrative items 1-5 plus the browser-script
  questions in `failure-modes.md` Part B (item 6 becomes how `SKILL.md` hands it over).
- In beginner mode a short fenced sample in section 3 ("What you get back") is allowed (this overrides
  the no-diagrams rule below) when the
  skill's output is itself text art or code, even when that output is a diagram.
- Near-identical files (for example 20 language references with the same shape) may share one
  File Map row that names every path; the File Map check matches each path in the text.
- A table inside a section that does not apply (for example script tests for a prose-only
  skill): delete the table and write one line under its label (`**Script tests:** None (prose-only
  skill).`).
- One issue, one rubric dimension: score each defect under the dimension it belongs to most
  (see `rubric.md`), and mention it elsewhere without re-scoring it.
- Header lines (the template shows them), each on its own line, in this order: Target (with
  Files and Analyzed on the same line), Report mode, Depth (`full read | context budget applied |
  mode-scoped read | pasted text only`), Plugin, Runs on (the surfaces row in short form with
  marks and blockers; the check warns when it is missing), Spec facts, then optional Save path
  and Skimmed. Beginner mode keeps only Target, Analyzed, Report mode, and optional Save path,
  each on its own line, in that order (`beginner-template.md`), and reads only section 0 of this file
  (its last part is the Beginner mode subsection; Step 4's "read report-sections.md" means section 0).
  Beginner may put a file name or a symbol the reader will see (`login.mmd`, `--->`) in a code
  span, and leaves out a medium hit that is only the target's own anti-injection rule.
- Severity cells use the scan's level; when reading shows a different level, write yours and say
  why in the same row (high, medium, or low; no ranges). Percentages round half up (62.5% -> 63%) for display; the rubric band uses the unrounded value (18/21 = 85.71% is Solid, not 86%).
  The "per compatibility.md (dated)" note goes in the Evidence cell of each hard ❌ (once per row
  when one row holds several); with no ❌, it is optional. A product or third-party fact that a
  dated reference holds is cited and labelled Inferred; one found in no dated reference is labelled
  `(unverified)` alone (never "Inferred, unverified"). Evaluative sentences ("well calibrated") need no
  label; a sentence that mixes a fact and a judgement labels the fact. A "None (no code)" row is
  Verified (the inventory shows no code files). Score cells are a bare
  digit (`2`) or `N/A`; the Total row reads `**<score>/<max> (<pct>%)**` and names the rubric
  band ("Solid", "Works sometimes", ...). Section 14 questions are a numbered list (`1. **...**`)
  or `Q:` lines; the check counts either.
- In a header's Runs on line, separate surfaces with ` · `.
- A check item labelled inferred that reading confirmed becomes "Verified (by reading)". Surface marks in
  section 13 are the ✅ ⚠️ ❌ emoji; the header's Runs on line may use the words works,
  partial, and blocked.
- A missing lockfile (or another packaging defect with one obvious fix): in every mode, describe
  the skill as if the fix ships, and list the defect as a blocker. The one exception is section 13's
  Packages row, which shows the command that works today (`npm install`, labelled Inferred: untested)
  so the reader can run it now.
- A description whose frontmatter does not parse: the Predicted column may be Ambiguous when the
  body's first line (Claude Code's fallback) partly matches the prompt.
- A section with nothing of concern still keeps its table: one row saying what was checked and
  that nothing was found, with `-` in a Severity cell and in any other cell that does not apply
  (Scenario, Mitigation). A section with only low rows lists them and
  has no "nothing found" row. In section 12 (no Severity column), list a
  checked category that does not apply only when no category applies, as one row with "does not
  apply" in its Mitigation cell.
- Cite frontmatter by its line range or the key's line (`SKILL.md:3`); the check output's
  `SKILL.md:frontmatter` source means the same block.
- Title: `# <mode title>: <skill-name>`; backticks around the name are optional.
- Quote the target's description inside a code span or code block, so placeholders such as
  `<book>` survive rendering.

### Beginner mode

A short, friendly document a total beginner can read in a
few minutes. Use exactly these headings, in order, with `## N. ` numbering
(`assets/beginner-template.md`):

1. **In one line** - one plain sentence: what this skill is, from the reader's side.
2. **What it does** - one or two short paragraphs: what it is for, who would use it, what they
   get back.
3. **What you get back** - what the result looks like (chat answer, saved file and its name,
   changed project), with a small sample adapted from the skill's own example or template (the
   target is never run).
4. **How it works, step by step** - numbered plain steps; say when a step keeps things safe or
   accurate.
5. **The rules it follows** - must always, must never, and limits; one plain sentence each.
6. **What it is good at** - real strengths, specific, no hype.
7. **Where it might trip up** - weak spots, plus "is it safe?" in plain words: does it run
   programs on the computer, change or delete files, use the internet, or act without asking.
   Fair, not scary.
8. **How to use it** - install it, what to type to start it, what to hand over, what to check.

Rules (the check enforces the ones marked *):

- Write for someone who has never seen a skill or a prompt. Short sentences. No jargon; if a
  technical word is unavoidable, explain it right after. Do not assume the reader can code.
- No hype or filler: "seamless", "robust", "powerful", "cutting-edge", "leverage", "unlock",
  "supercharge", "effortless", "game-changing", "elegant", "delightful", "at its core", "the
  heart of", "designed to", "empowers you to", "simply", "easily", "blazing-fast", "world-class".*
- No long dashes (en or em)* and no curly quotes*. Write "step by step" and "plain English" as
  spaced words, not hyphenated.
- If the skill is very small, keep every heading and keep thin sections to a line or two.
- Nothing after section 8 (no extra headings*), and no notes about your own process. Refer to
  sources in plain words ("the skill's main file says...") rather than `path:line`*; no
  confidence labels*, tables*, or diagrams. A folder or command the reader must type (`~/.claude/skills/`)
  may sit in a code span; that is not a citation.

---

## 1. Executive Summary

2-3 paragraphs, then the scorecard.

- Paragraph 1: what the skill does, who invokes it, and the deliverable it produces.
- Paragraph 2: shape. Is it prose-only, script-backed, or hybrid? How many files? What is the
  workflow in one sentence?
- Paragraph 3: verdict. The two biggest strengths and the two biggest risks or gaps.
- Then the scorecard table from `rubric.md` (8 dimensions, 0-3 each, a one-line reason per
  row) and the Total row as `**<score>/<max> (<pct>%)**` with the band name and the first fixes,
  e.g. `**17/24 (71%)**` | Solid; fix triggering and script paths first.

## 2. Skill Purpose & Trigger Conditions

- Quote the `description` (plus `when_to_use`) verbatim and give its character count against
  the 1,024 (spec) and 1,536 (listing) limits.
- Break it into *what it does* and *when to use it*, and list every trigger phrase.
- Judge it on these points:
  - Third person?
  - Concrete user phrasings, or only topic words?
  - Does it name file types, tools, or contexts that disambiguate it?
  - Does it say what the skill is *not* for?
- Trigger test table: prompts that should trigger and near-misses that should not (counts by
  target size in section 0), each with a predicted outcome and the reason. If the frontmatter
  does not parse, the Predicted column is as shipped (Claude Code falls back to the body's first
  line, `skill-spec.md`); put the intended outcome in the Why column.

  The "Should trigger?" and Predicted cells are Yes, No, or Ambiguous; only "Should trigger?" is
  counted.

  | Prompt | Should trigger? | Predicted | Why |
  |---|---|---|---|

- Collisions: name other skills in the current listing whose descriptions overlap, and say
  which one would likely win.
- Invoker: the user via `/name`, Claude automatically, or both (from the
  `disable-model-invocation` and `user-invocable` fields). Note any orchestrating agent or
  command that calls it.
- Done: what a correct run must produce, in one or two sentences.

## 3. Frontmatter & Metadata Analysis

A table with one row per field present (when the YAML does not parse, one row per field the raw
text shows, each marked "dropped: YAML broken", with the broken description quoted as "Compat mode" item 2 in section 0
says: the value's first 200 characters and the part around the break). In `security` mode, also give `allowed-tools`,
`disable-model-invocation`, `hooks`, and `disallowed-tools` a row when absent ("absent": what that means for safety). An
`allowed-tools` entry no file uses (lint `FM032`) is noted in its row and costs no Frontmatter
point (one issue, one dimension: a risky one is scored under Safety only):

| Field | Value | Effect | Valid? | Notes |
|---|---|---|---|---|

A field that is valid but draws a lint warning reads `Yes (warn: FM011)` in the Valid? cell.

- Use `skill-spec.md` for meanings and limits.
- Call out unknown or typo fields (silently ignored), `version` (not a documented field),
  contradictory combinations, and `allowed-tools` misunderstood as a restriction.
- List notable absences: no `argument-hint` while the body uses `$ARGUMENTS`, or no
  `disable-model-invocation` on a skill with side effects that should only run on request
  (deploy, send, delete).

## 4. Skill Body Structure

- Outline the body: each heading, its line range, and its word count.
- Describe the ordering logic. Do intake and guardrails come before the work? Is the output
  contract near the end, where the model reaches it right before writing?
- Find critical rules placed late. After compaction only the first 5,000 tokens survive, so
  late rules can be lost.
- Look for structure problems: steps without numbers, decision branches buried in prose, two
  sections that contradict each other, and the same rule restated in several places (note
  where).

## 5. Script / Reference File Map

Include plugin-level files from `inventory.plugin.files` in the same table, as `<plugin>/path`,
with the `reason` they were included. Give hook scripts and scripts called through
`${CLAUDE_PLUGIN_ROOT}` the same per-file narrative as bundled scripts.

**Table: one row for every file in the inventory** (or one row per group of near-identical files,
naming every path - see section 0), including orphans and binaries:

| File | Role in skill | Language/type | Invoked by / invokes | Inputs | Outputs & side effects | Risk notes |
|---|---|---|---|---|---|---|

- *Role*: entry instructions, executed script, on-demand reference, output template, example,
  or meta (README, LICENSE).
- *Invoked by*: the `SKILL.md` line that runs or reads it, or "never referenced".
- *Inputs*: CLI args, env vars, stdin, files read, network.
- *Outputs*: stdout shape, files written (where?), network calls, exit codes.

**Per-file narrative** for each non-trivial script (references and assets use the shorter list
after it):

1. Purpose in one sentence.
2. Step-by-step behavior: what it parses, computes, and emits.
3. Dependencies: stdlib or third-party, external binaries, and whether the install steps are
   documented.
4. Side effects: file writes (inside or outside the skill folder?), network, shell, and
   credentials.
5. Error handling: does it fail loudly or silently? Are exit codes meaningful? Does it print
   usage?
6. How `SKILL.md` invokes it: the exact command, the path form (`${CLAUDE_SKILL_DIR}` or
   relative), and whether the instructions match the script's real interface (argument names,
   output format). For a browser-side script pasted into a page, say how `SKILL.md` hands it over
   and answer the browser-script questions in `failure-modes.md` Part B instead.

For references and assets: what each one covers, whether `SKILL.md` says *when* to read it,
whether it duplicates `SKILL.md`, and whether a file of more than 100 lines or 20 KB has a contents list.

**Dependency map**, as an ASCII tree or a Mermaid graph:

```
SKILL.md
├── runs  scripts/build.py ──imports── scripts/util.py
├── reads references/api.md
└── fills assets/template.md
(orphan) scripts/old_build.sh
```

Finish with **Missing** (referenced, absent) and **Orphans** (present, never referenced; meta
files such as README, LICENSE, CHANGELOG, and benchmarks are not orphans), each with the
consequence.

## 6. Instruction & Wording Analysis

Go section by section through the `SKILL.md` prose:

- **Directive strength:** MUST, NEVER, and all-caps. Is emphasis used sparingly enough to mean
  something? Over-emphasis makes a model rigid or anxious.
- **Voice:** imperative ("Run X") vs second person ("You should run X"). Note the convention and
  how consistently it is applied. A single deliberate role line ("Act as ...") is fine.
- **Ambiguity:** words like "appropriate", "as needed", "if relevant" that hide a decision the
  model must guess. Give the line and a concrete rewrite.
- **Variables:** `$ARGUMENTS`, `$N`, `${CLAUDE_SKILL_DIR}`, `{{x}}`, `<x>`. For each, give what
  is injected at runtime and what happens when it is empty.
- **Non-actionable lines:** sampling settings (temperature), "model-agnostic" claims,
  instructions that need tools the skill does not mention, and references to files that do not
  exist.
- **Delimiters and quoting:** how the skill separates data from instructions.

Annotate excerpts like this:

> `SKILL.md:42` "If the user seems unsure, ask." - *"seems unsure" is undefined; name the signals
> (no path given, multiple candidates).*

## 7. Techniques & Patterns Used

For each pattern present: name it, give a one-sentence explanation for a newcomer, cite where it
appears, and say why it fits or does not. Common patterns:

- progressive disclosure
- script delegation (deterministic work moved out of the model)
- data isolation / anti-injection framing
- tool-permission pre-approval
- conditional branching and stop conditions
- structured-output contract or template
- self-verification checklist
- role prompting
- few-shot examples
- forked context (`context: fork`)
- dynamic context injection (`!`)
- argument substitution

Also name patterns that are absent but would help.

## 8. Invocation & Execution Flow

A numbered walkthrough from trigger to deliverable, then a diagram (Mermaid `flowchart TD`, or
ASCII). Show:

- the trigger path: auto-match or `/name args`
- the load: `!` commands run first, then substitutions, then the body
- each file read or script run, in order
- each decision branch and stop point
- the final output and where it goes

Note which steps cost context tokens (reading files) and which do not (running scripts).

## 9. Output & Format Specification

- The deliverable: file (name, location, overwrite behavior), chat output, code changes, or an
  external action.
- The contract: required sections, schema, length, and template.
- Enforcement: is there a template, a verification checklist, or a validating script?
- Gaps: unspecified file location, silent overwrite, output written inside the skill folder, or
  no fallback when the tool is unavailable.
- Show a short example of the expected output: a skeleton, or 10-20 representative lines. Inside
  such examples, never write the exact line `## 16. Appendix`; `build_appendix.py` requires that
  line exactly once.

## 10. Security & Permissions Review

**Row and severity table.** These row and severity rules apply to section 10 in every mode. Read the
first row that fits:

| Finding | Row? | Severity |
|---|---|---|
| Scanner hit, confirmed | one row per rule per line ("SEC-TOOL-1 x2: `Write`, `Edit`"); one row per severity when the hits on a line differ; one row for several files only when it lists every `path:line` | the scanner's; reading may raise it, or lower it one level when the hit is negligible or limited in reach (a restore of files that were clean before), with the reason in the row |
| Scanner hit judged false (an install line only shown, never run; an install hint inside an error message or docstring, unless `SKILL.md` tells Claude to follow it) | no row; it goes in the false-positive list, with no row | - |
| SEC-PKG-1 install line the skill runs (any install line in the target's own `SKILL.md`, such as Requirements or Setup, counts as run, since Claude reads that file as instructions) | keeps its low row (one per line, like any scanner hit); a rule with both kinds lists the false ones in the false-positive list | low |
| Item 6 need (shell, file write, network, browser connector, download-then-shell handoff) already covered by a scanner row (SEC-TOOL-1/2, SEC-PATH-3, SEC-NET-5, ...) | no second row: keep that row and its severity | the scanner's |
| Item 6 need with no scanner row | one row | medium |
| Risk a scanner row already implies (injection that leads to the code SEC-TOOL-2 pre-approves) | folded into that row | the row's |
| Other risk found only by reading | one row | high when it can run code on the user's machine, reach secrets, or destroy data the skill did not create, without the user's confirmation; else medium |
| Install-time domain, asking the user, image viewing | no row (they widen nothing at run time) | - |

What the table's words mean:

- Code confined to a browser page is medium. Code a skill runs in a browser it launches on the
  user's machine (headless Chromium) is browser-page code too, unless it can read local files or
  reach beyond the page; a `file://` page cannot read other local files by default, unless the
  skill passes flags that allow file access.
- "Reach secrets" means read or send a credential, token, or key the user holds; writing a page's
  own form tokens to a local file the user asked for is medium.
- A restore limited to files that were clean before is medium.
- With no `allowed-tools`, Claude Code's normal permission prompt is the user's confirmation.
- An overwrite that can destroy data the skill did not create goes here and in section 12; any
  other output defect goes in section 12 only.

When the skill sits in a plugin, cover the plugin's hook commands and MCP servers here
(`SEC-HOOK-2`, `SEC-MCP-1`): what each runs, on which events, and what it can reach. They run
whenever the plugin is enabled, so installing the skill means accepting them.

Combine the confirmed `scan_security.py` hits with a manual review against the script audit
checklist in `failure-modes.md`.

| Risk | Evidence | Severity | Scenario | Mitigation |
|---|---|---|---|---|

Cover these points:

- **`allowed-tools`:** what is pre-approved and whether it is least-privilege. Is the author
  treating it as a restriction?
- **Execution surface:** scripts, `!` commands, hooks.
- **Data flow:** what leaves the machine, and what untrusted input (user files, web content) the
  skill reads and then acts on.
- **Hidden content:** zero-width or bidi characters, encoded blobs, and instructions in
  references that contradict `SKILL.md`.
- **Secrets and personal data:** hardcoded credentials, user-specific paths, telemetry.

List the scanner hits judged to be false positives, with a one-line reason each, so a reviewer
can see they were checked. Under "Blind spots checked by hand", give one line per `not_covered` item
that applies to this skill (what was checked and the result), and one line naming the items that do
not apply (a prose-only skill has no code to trace). An output defect (a silent overwrite) goes in
section 12, not in this risk table, unless it can destroy data the skill did not create. A hit that is real but negligible is not a false positive: give it a
risk-table row with Severity low and the reason it is negligible. If nothing of concern exists, say so plainly and name what was
checked.

## 11. Evaluation / Testing / Behavior

Three parts (for a prose-only skill, the script-tests table becomes one line; the eval-set
paragraph stays).

**Triggering** - reuse the section 2 prompts, or reference that table.

**Functional cases:**

| Input | Expected output | Notes |
|---|---|---|
| Typical well-formed input | ... | Happy path |
| Missing / empty argument | ... | Edge |
| Malformed input (wrong file type, huge file) | ... | Edge |
| Input containing injected instructions | Logged, not obeyed | Adversarial |
| Required tool or dependency unavailable | ... | Environment |

**Script tests** (script-backed skills only): what to run against each script, with which
fixture, and what output to expect. **Every skill:** say whether the skill ships tests or evals, and what an
eval set would need: trigger cases, output assertions, and a with/without-skill baseline.

## 12. Failure Modes & Robustness

Use the catalog in `failure-modes.md`. For each failure mode that applies:

- **Mode** - a short name
- **Where** - `path:line`, or "design"
- **Likelihood / impact** - L/M/H for each, written `L / H` (likelihood first)
- **Symptom** - what the user would see
- **Mitigation** - a concrete change

In `full` mode on medium and large targets, consider at least: triggering (under and over),
instruction drift, path and environment assumptions, dependency failure, partial-failure
handling, and context bloat; report the ones that apply. `security` mode covers security and
permission failures only.

## 13. Dependencies, Compatibility & Pipeline

Three parts, in this order:

1. **Compatibility table** - the eight-axis table in `compatibility.md` section 4, built from the
   `requirements` check and confirmed line by line: Surfaces, Runtime, Packages, Tools, Network,
   Model, Companions, Degrades to. Every row carries a confidence label and evidence. The
   Surfaces row marks all five surfaces, with the blocker named for each ⚠️ or ❌.
   `build_appendix.py` validates this table.
2. **Declared vs detected** - quote the skill's `compatibility` field (or say there is none),
   list what it omits (`REQ001`, `REQ002`), then give a suggested one-line `compatibility:`
   value in a `yaml` block (at most 500 characters, no `: ` inside).
3. **Pipeline** - where the skill sits in a larger system:
   - commands, agents, or hooks that call it
   - skills it feeds or consumes (the Companions row, expanded)
   - for a plugin skill: the plugin, its other skills, agents, and commands
     (`inventory.plugin.components`), and any this skill calls or borrows files from
   - files it expects from earlier steps, and what consumes its output

   For a standalone skill, write `Standalone: invoked directly by the user or the model.` A skill in
   a collection is standalone when no sibling calls it and it calls none; still list close siblings
   (their overlap goes in section 2).

Section 13 is never N/A: every skill has at least a Surfaces and a Tools row.

## 14. Potential Interview / Review Questions

Questions across four groups (counts by target size and mode in section 0):

- **conceptual** (why a skill rather than a command, an agent, or CLAUDE.md)
- **design** (why delegate this step to a script, why this ordering)
- **skill-specific** (what happens if a referenced script is missing)
- **trade-offs** (token cost vs reliability, strictness vs flexibility, one skill vs several)

Give each question an answer grounded in the files (length by target size in section 0).

## 15. Optimization / Improvements

A ranked table, highest impact first:

| # | Change | Where | Why / expected impact | Effort |
|---|---|---|---|---|

- Make each change concrete enough to apply: show the replacement text or code when it is
  short.
- In `full` and `improve` modes, cover triggering, structure and length, scripts, security and
  least privilege, output robustness, and testability. In `security` mode, security and
  permission fixes only.
- Say what to change first.
- If the skill is already strong, say so and list only real improvements. Do not pad. If none
  apply, write `N/A - skill is already well-optimized.` (section 15 only: this overrides the
  "keep the table with one nothing-found row" convention).

## 16. Appendix

Write only the heading line `## 16. Appendix`. `scripts/build_appendix.py` fills it (Step 5), so
file contents are never retyped by the model. It produces:

1. **A. Automated checks** - the merged check output, headings demoted to fit under section 16.
2. **B. File contents** - an untrusted-data banner, then each authored text file under a
   `#### path` heading, `SKILL.md` first, in a fence one backtick longer than any fence inside the
   file, with a language tag. Then "Plugin files used by this skill", each as
   `#### <plugin>/path` with the reason it was included. Secrets (including whole private-key
   bodies) are redacted and invisible or control characters shown as `<U+XXXX>`; a note above
   the file lists each change.
3. **C. Omitted files** - each with a reason: credential-type files (`.env*`, `*.pem`, `*.key`,
   `credentials*`, `id_*`, `.netrc`, ...), binaries, symlinks (with targets),
   special and unreadable files, generated files (lockfiles, minified bundles, source maps) even in
   `scripts/`, any file over 500 KB, non-code unreferenced files over 100 KB, files past the 5 MB
   total Appendix cap, and vendored directories. A coverage line follows: `quoted + omitted = N of N`.
4. **D. Sources** - the documentation the analysis relies on.

The script also prints a File Map check: any inventory path not named in sections 1-15 is listed
on a `WARNING:` line. It does not fail the check, but Done requires every file accounted for: add
those paths to the File Map and re-run.
