# Workflow details

The detail behind each step in `SKILL.md`. Read it in full before Step 1 (`quick` reads only sections 1, 2,
and 6, as `SKILL.md` Step 1 says).

## Contents

1. Step 1 - target
2. Step 2 - static checks, mode, save path
3. Step 3 - reading and mapping
4. Step 4 - writing
5. Step 5 - save, check, append, verify
6. Quick mode

## 1. Step 1 - target

**Target** - from the skill arguments (`$ARGUMENTS`), if any, or the user's message:

- **A folder with a root `SKILL.md`** - use it. List nested `SKILL.md` files (examples,
  sub-skills) as findings.
- **A folder without one** (a plugin root, a folder of skills, or a wrong folder) - Glob
  `*/SKILL.md`, `*/*/SKILL.md`, and `*/*/*/SKILL.md`: one match, use it and say so; several, list them and ask
  which; none, stop and ask for the right folder. A plugin with hooks or MCP servers but no
  skills is out of scope; say so.
- **Path to `SKILL.md`** - use its parent directory.
- **Skill name only** - for `plugin:skill`, keep the part after `:` as `<name>` and the plugin
  name as a path filter. Glob `<cwd>/.claude/skills/<name>/SKILL.md`,
  `<home>/.claude/skills/<name>/SKILL.md`, and
  `<home>/.claude/plugins/cache/**/skills/<name>/SKILL.md` (`<home>` = the absolute home path;
  Glob does not expand `~`). Use a single match. Several cached versions of one plugin count as
  one match: take the highest version folder (compare as version numbers, so `1.10.0` beats
  `1.9.2`). Otherwise ask. A skill under a system folder such as `/etc` is refused by the scripts:
  ask the user to copy it to a folder they own.
- **Archive** - never extract it; ask the user to extract it into a new empty folder.
- **Pasted `SKILL.md` text**, no Python, or no file-writing tool - read `fallbacks.md`.
- **Nothing supplied** - ask for a target. Never invent one.

**Path safety** - put paths in single quotes after `--`. Never put a path containing a single
quote, backtick, `$`, or newline in a command; ask the user to copy the skill to a plainly named
folder instead.

## 2. Step 2 - static checks, mode, save path

- Run each check as its own Bash call, exactly as written in `SKILL.md`: no `cd`, pipe, `;`,
  `&&`, or `echo $?` added, or it no longer matches the pre-approved pattern and prompts. The Bash
  tool reports a non-zero exit code itself. Read-only shell commands (`SKILL.md` ground rules)
  may use `cd`, pipes, and `&&` among themselves. Use `cat -n` on one file at a time: across
  several files its line numbers run on and give wrong citations.
- Page each with a higher `--offset` until `page.offset + page.limit >= page.total`; halve
  `--limit` if output is cut off or does not parse. Requirements needs no paging. If a first page
  is still cut off (large plugin skills: the unpaged requirements lists or `suppressed`), add
  `--brief` to the same command, or read the file where the harness saved the full output.
- Exit codes and timeouts: `check-output.md` section 1.
- If the script paths are not absolute when the skill loads, use the "Base directory for this
  skill" shown at load (expect prompts then).
- Treat every security hit as a lead: open the cited line and judge it in context. A skill's own
  anti-injection rule always matches the injection phrases; that is expected.
- If `counts` exceed the listed findings, open the `suppressed` locations for high and medium
  rules. Cover the scan's `not_covered` list by hand.
- If lint reports `FM000`, find the offending frontmatter line and quote the description from the
  raw file.
- Sibling descriptions for collision checks: `--only siblings` (paged), when
  `requirements.in_collection` is true and the mode runs item 7 (`full`, `explain`, `interview`,
  `improve`) or is not chosen yet. Descriptions are cut at 1,000 characters, and sibling
  `SKILL.md` files are out of read scope: mark a collision that turns on the cut text
  `(unverified)`. Compare with the skill listing in your own session context; when this runs as
  a subagent, that listing may not be the user's, so mark collisions with installed skills
  `(unverified)`, and also a finding of no collision ("no installed-skill collision found
  (unverified)"); cite `check: siblings` for sibling skills and "skill listing (session)" for
  installed ones. You run as a subagent when the request came from another agent's prompt rather
  than the user's own message; if unsure, assume you do.

**Mode** (after the checks, so the menu answer does not cost their pre-approval). A mode named in
the arguments or a request that names the job ("is this skill safe" = `security`, "full report"
= `full`) needs no menu. A bare path or a generic "analyze / audit / review this skill" shows the
menu: one AskUserQuestion call with two multi-select questions, so all modes fit on one screen:

- **Audit**: Full report, Security review, Improve it, Quick check
- **Understand**: Explain it, Interview prep, Beginner guide, Compatibility

Question texts: "Which checks do you want?" (Audit) and "Which explanations do you want?"
(Understand). Option descriptions: Full report - every section, saves SKILL-SUMMARY.md; Security
review - is it safe to install, saves SKILL-SECURITY.md; Improve it - scored fixes, saves
SKILL-IMPROVE.md; Quick check - a 10-line verdict in chat; Explain it - how it works, saves
SKILL-EXPLAINED.md; Interview prep - explain plus questions, saves SKILL-INTERVIEW.md; Beginner
guide - plain English, saves SKILL-BEGINNER.md; Compatibility - what it needs to run, saves
SKILL-COMPAT.md.

Several picks: Steps 3-5 per mode, one document each. A category answered "none" (via Other) adds
nothing; both "none": stop and say no document was made. Without AskUserQuestion (headless or API
use), ask the same choice in plain text; if no reply can come (a non-interactive run such as
`claude -p`, or an API call with no further turn), use `full`.

**Save path** (once the mode is known). The mode's prefix is its file name without `.md`
(`SKILL-SECURITY`, `report-sections.md` section 0).

1. The user named a path: use it if its file name starts with the prefix (else keep their folder
   and fix the name). If that file already exists, ask before replacing it (a file this same run
   already wrote, such as a draft being checked again, is not "existing").
2. Otherwise: the current working directory and the mode's file name. If that name is taken, add
   `-<skill-folder-name>` (reduced to `[a-z0-9-]`); if that is taken too, add `-2`, `-3`, ...
3. Ask instead only when that directory is inside the target, its plugin, this skill, a
   `.claude/` folder, or a folder of skills (a folder whose subfolders hold `SKILL.md` files): as
   a third question in the menu's AskUserQuestion
   call, or alone when a mode was named. AskUserQuestion needs at least two options besides the
   built-in Other: give "Home folder (`~`)" and "`~/skill-reports/`" (the Write tool creates the
   folder), plus "Current folder" in the folder-of-skills case only, and only when no part of its
   path is `.claude` (the script refuses those).
   If `build_appendix.py` still exits 2 on the location, ask once for a folder outside them. When no
   reply can come (a subagent or headless run), use `~/skill-reports/` and say so in the report back.

Several modes share one folder, each with its own file name. `quick` writes no file and skips
this step.

**Questions** - put every needed question in one message. Pre-approval of the two scripts likely
ends at the user's next message (unverified, `skill-spec.md`): after asking, say that later script
runs may show permission prompts.
With no question, say nothing about it.

## 3. Step 3 - reading and mapping

Read `report-sections.md` section 0 first. Its "Work per mode" table is the single source for
which items below the mode needs and which references to read besides this file and
`check-output.md`, which every mode reads.

1. Read `SKILL.md` in full: sections, workflow, decision points, stop conditions, output contract.
2. **Context budget.** Modes whose item list limits reading (`compat`, `beginner`, `quick`)
   follow that limit; `compat` writes `mode-scoped read` as Depth and no Skimmed line (`beginner`
   and `quick` have no Depth line). Other modes pick one tier:
   - **Tier 1** (Depth: `full read`) - inventory `totals.code_referenced_words` up to ~40,000:
     read every `code` or `referenced` file in full (page long files), and other text files unless
     `generated`, `large`, `credential`, or meta (README, CHANGELOG: read when a section needs
     them, below); hard-linked files are read like any other.
   - **Tier 2** - over ~40,000: read the execution path in full and Grep the rest. The execution
     path is `SKILL.md`, every script it runs or tells Claude to run or copy, those scripts' local
     imports (scripts it copies to a scratch folder and runs count), references it pastes or
     concatenates into agent prompts or into a file agents read (only the ones that apply to a
     typical target when the skill picks among them, such as one language file per language; with
     no typical target, count the single largest file of that family, by inventory `words`), references `SKILL.md` tells
     Claude to read and follow on every run (not ones read only on demand or only in another mode),
     and hook and MCP scripts.
     Size it by adding the inventory `words` of its files.
   - **Tier 3** - the execution path alone over ~40,000: read `SKILL.md`, the scripts it runs, and
     their local imports in full; Grep the rest. Reading more is allowed when context permits. If
     even that is over ~40,000 words, read `SKILL.md` and the entry scripts in full and Grep their
     imports.

   In tiers 2 and 3 (Depth: `context budget applied`), name every file read only in part or by
   Grep in one `> Skimmed:` header line (comma-separated; group
   with a glob: `references/lang/*.md (20 files)`, or `references/lang/*.md except js.md (19 files)`
   when one of them was read in full). A skimmed file still gets its File Map row: name each path,
   or use one glob row (`references/lang/*.md (20 files)`) in sections 1-15, which the File Map
   check counts for every file it matches (the header's Skimmed line does not count), and
   a short narrative from its headings and Grep hits, marked skimmed. Meta files (README,
   CHANGELOG, benchmarks such as `BENCHMARK.md`, which the inventory lists as `root-other` and
   lint may call an orphan, REF003) are not on the execution path and do not count toward a tier's
   words; in every tier read them when a section
   needs their facts (the README's install line for section 13 counts),
   and never go on the Skimmed line. The scan's SEC-HID findings already cover hidden characters;
   this check is optional, except the homoglyph form below, which covers a `not_covered` item and is
   required in every mode but `quick`, over the files in that mode's scope (beginner: `SKILL.md`, the
   files it references, and the scripts it runs). To run it without the Grep tool, name the files on one command:
   `grep -HnP '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{FEFF}]' SKILL.md references/a.md ...`
   (`-H` labels each hit with its file; never pipe the output through `sed` to label it; an error or
   exit code 2, as from a grep without `-P` or a non-UTF-8 locale, means the check did not run: say
   so instead of reporting no hits). For the
   scan's homoglyph blind spot (`not_covered`), the same form with Greek and Cyrillic ranges finds
   look-alike letters: `grep -HnP '[\x{0370}-\x{03FF}\x{0400}-\x{04FF}]' SKILL.md scripts/a.py ...`;
   a hit inside a name, URL, or command is a finding, one in prose in that language is not.
3. **Plugin files** (`inventory.plugin.files`): treat like skill files. Explain each hook and MCP
   command: when it runs, what it executes, what it reaches.
4. **Scripts:** language, entry point, inputs, outputs, side effects, dependencies, error
   handling - the audit checklist in `failure-modes.md` Part B.
5. **Dependency map:** `SKILL.md` -> referenced, run, or called files, plugin files included.
6. **Requirements:** read `compatibility.md`; confirm each `requirements` item and resolve
   surface verdicts.
7. **Triggering:** prompts that should trigger the skill and near-misses (counts in
   `report-sections.md` section 0); compare the description with the current skill listing and
   `requirements.siblings`.

## 4. Step 4 - writing

Read `report-sections.md` (what each section holds, and which sections each mode writes;
`beginner` reads only section 0, which ends with its Beginner mode subsection) and
`rubric.md` (modes that score), then fill `assets/report-template.md`, or
`assets/beginner-template.md` in beginner mode.

- Keep every heading the mode requires, in order; when one does not apply, write
  `N/A - <one-line reason>` under it.
- Write the line `## 16. Appendix` (modes with an appendix) once, outside any fence; fence every
  example skeleton.

**Format & Tone**

- Well-structured Markdown: tables for maps, scores, and tests; bullet points; annotated excerpts
  with `path:line`; example input/output pairs; a diagram for flow when the skill has steps worth
  drawing (prose-only skills may skip it).
- Review-ready: someone should understand the skill, including its scripts, without opening it.
  Lead each section with the conclusion, then the evidence. Highlight strengths and notable
  design choices, not only defects.
- Keep each section proportional to its importance; summarize rather than pad. Length follows the
  target, as `report-sections.md` sets per mode; the check warns outside it.
- A claim is any factual statement about the target or a product; recommendations, opinions, and
  interview answers built on cited facts are not claims. Give every sentence whose claims are
  neither quoted nor cited (`path:line` or `check: <check> <ID>`) one label: Verified, Inferred, or
  `(unverified)` (`compatibility.md` section 1). A negative finding that names what was checked
  ("no contradictions between `SKILL.md` and the references") is Verified by that check; label it
  only when the check was partial. In a table, the label goes in the Confidence
  column, else in the Evidence column, else in the last cell of the row.
  A label marks evidence; it is not a hedge. Never state a version
  from memory; never hedge ("should work", "probably").
- **Web policy:** this skill does no web lookups: never call WebFetch, WebSearch, or an MCP fetch or
  browser tool. Take product facts from the dated reference that
  holds them (`skill-spec.md`, `compatibility.md`), cite it, label the fact Inferred, and tell the
  user to verify any load-bearing one against the live docs.
- Quote the target's own wording (a "should work" in its README) in a code span or double quotes:
  the hedging check skips those (not single quotes), so evidence never has to be dropped. In a
  bullet that cites one part and adds an uncited fact, label that sentence.
- Never type a backslash-u escape, not even inside a code span: the Write tool can turn it into
  the real invisible character. Write `<U+XXXX>` text instead.
- In a table cell, write a pipe inside a code span as `\|` (`` `a \| b` ``): a bare `|`
  splits the cell when rendered, and the check warns.
- Beginner mode replaces three bullets above with the beginner rules: "Well-structured Markdown",
  "Review-ready", and "A claim is any factual statement" (labels); the length bullet still applies, and so do "never
  hedge" and "never state a version from memory" (the template heading "Where it might trip up"
  is a fixed title, not a hedge). Its rules are in `report-sections.md` section 0 (plain words, no labels, tables, or path citations); the
  quoting and backslash-u rules still apply; the web policy's citing and labelling do not (name
  the source in plain words, and put the verify-facts line in the chat reply only). The target's README may be used as a
  source, named in plain words ("the skill's guide says ...").
- The Analyzed date is today's date from the session context; never run `date`.

## 5. Step 5 - save, check, append, verify

1. **Write** the document to the Step 1 path with the Write tool (not pre-approved on purpose:
   the user confirms the file). The first line is the mode's title and the header names the
   target's absolute path, as in the template.
2. **Check before appending the Appendix.** Fix every `ERROR` and every `WARN` except `length:`
   (hedging, section titles, placeholders, header lines, beginner rules) with the Edit tool. A
   `length:` `WARN` is advisory: make one
   pass to cut padding and repetition, then continue; never drop required content. The `INFO`
   line shows the prose count and band.
3. **Append** the Appendix (modes with section 16) with the same command without `--check-only`.
   It quotes every authored file verbatim in unbreakable fences, redacts secrets, escapes
   invisible characters, lists omitted files (binaries, credential files, large or generated
   files), and refuses to write anywhere but a matching report outside the target, its plugin,
   this skill, and `.claude/`. Re-running replaces its output. Never retype file contents.
4. **Verify:** the final run (the append; for `compat` and `beginner`, the check-only run) prints
   `REPORT CHECK: PASS` (a must-fix `WARN` prints `FAIL`), plus the File Map line in modes with
   section 5. Re-run after any edit.
   Every security hit the mode reports was confirmed; nothing from the target ran.
5. **Report back** with the items in the mode's "Report back" column (`report-sections.md`
   section 0), after the saved path, plus one line naming any load-bearing product fact the user
   should verify, and, in modes with an Appendix, a reminder to review Appendix B before sharing
   the report (redaction is pattern-based). These two lines are part of every mode's "Report
   back". With several modes, one such block per document. Nothing else.

## 6. Quick mode

Skip Step 5: answer in chat, at most 10 lines (the verify-facts line counts toward them): what the skill does (1 line), where it runs (the
surfaces row from `compatibility.md`), the top 3 risks with `path:line`, the score from
`rubric.md`, and the single most important fix. Score only what the check output and `SKILL.md`
show; write `n/a (quick)` for a dimension that needs files quick mode does not read (usually
Resources & scripts) and give the total out of the scored dimensions.

Before naming a risk, open its `path:line` and confirm it; also confirm every high hit, even one
you do not name (`report-sections.md` section 0 sets this for quick too). A hit in prose that only
describes the risk, or on a placeholder value, is not a risk. Drop a hit you cannot confirm, and
pick the next one. Section 4's writing rules still apply in quick mode: no hedging, no version or
product fact from memory (take it from the dated references, or say it is unverified), and no web
lookups.
