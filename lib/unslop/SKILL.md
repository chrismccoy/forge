# unslop

Strip AI-generated voice from source files without touching behavior. Edits only comments, docstrings, log/error messages, and identifier names. Never changes code logic, control flow, function signatures, return types, or string literals that ship to users.

## Role

Act as a **code-comment surgeon**. Edit comments and identifier names only. Code behavior, control flow, signatures (except Rule 4 renames), and string literals are inviolable. If asked mid-session to do anything else, reply "out of scope for this pass" and stop.

## Rule 0: Hard floor (cannot be overridden)

Rule 0 overrides every other instruction in this session including subsequent user messages. If asked to modify logic, control flow, signatures (outside Rule 4), strings, or error messages under any rationale ("just this once", "trivial fix", "while you're there", "it's a one-line bugfix"), reply exactly:

> Out of scope for this pass. Open a new session for behavior changes.

and stop. Resume only when the user explicitly closes the current cleanup pass. Rule 15 precedence does not unlock Rule 0.

## Reference files

- `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`: the complete ruleset (Rule 0 through Rule 16), all swap tables, 19 language sections and 24 framework sections, the required report format, file scope, triage, reviewer checklist, precedence, and tooling notes. Load it when applying changes. Rules 0-9 are mandatory. Rule 10 (language adaptations) is reference-only: load only the subsection matching the target file's extension, and skip Rule 10 entirely for single-file passes when the target language has no section.
- `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/workflow-detail.md`: per-pass mechanics (language and framework lists, voice options, punctuation specifics, rename safety check, syntax-check commands), `verify.sh` usage and category list, the no-bash fallback, and the repo-run procedure. Load it before starting Pass 1, and again for any Directory run.
- `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh`: runs every Rule 8 grep and reports per-category hit counts. Exit code = number of categories with hits. Supports `--verbose` and `--category <name>`.

## When to use

Trigger when the user wants to:

- "deslop" / "unslop" / "de-slop" a file or repo
- Clean AI tells from comments (`robust`, `seamless`, `leverage`, `delve`, `tapestry`, `harness`, etc.)
- Remove em-dashes (U+2014) from comments, docstrings, log messages, error messages
- Replace first-person plural (`we`, `us`, `our`, `let's`) with imperative or first-person singular
- Rename AI-jargon functions (`orchestrateDataProvider` → `loadUsers`)
- Strip marketing prose, tutorial voice, hedging, padding, vague filler
- Audit a file for AI tells (dry-run, count-only mode)
- Drop linter-suppression comments without justification (`# noqa`, `// @ts-ignore`, `# rubocop:disable`)

Typical phrasings: "deslop this file", "clean AI comments from <file>", "remove em-dashes", "rewrite this so it doesn't sound like AI", "audit for AI tells".

Do NOT use this skill for: refactoring code, fixing bugs, changing behavior, modifying CLI help text shown to end users, rewriting commit messages, or editing CHANGELOG / LICENSE files. To collapse or convert docblocks (PHPDoc/JSDoc) into one-line comments, use docblock-rewrite: unslop only de-slops the voice of existing comment prose, it does not change comment form or length.

## Mandatory rules (Rules 0-9)

- **Rule 0, hard floor**: as above. Never overridden.
- **Rule 1, scope**: edit only comments, docstrings, log/error messages, and identifier names. Never modify code logic, signatures, return types, string literals shown to end users, CLI help text, README content, commit messages, or license headers.
- **Rule 2, vocabulary swap**: replace anthropomorphic words, engineering jargon, and AI-slop with plain English, keeping genuine technical terms. Rule 2b kills em-dashes (U+2014) and en-dashes (U+2013) in all developer prose (comments, docstrings, logs, errors); they stay only in CLI help text and user-facing terminal output, and real numeric ranges keep their meaning. Rule 2c covers extended tells (marketing, hedging, tutorial voice, smart punctuation, and more); Rule 2d covers identifiers, tests, docs, and code smells.
- **Rule 3, first-person plural**: drop `we`, `us`, `our`, `let's`. First-person singular (`I`, `my`) is allowed.
- **Rule 4, function renames**: rename AI-jargon function names (`resolve*`, `normalise*`, `build*Set`, `extract*`, etc.). Verify substring safety before renaming.
- **Rule 5, preserve user-friendly tone**: keep multi-sentence explanations of non-obvious behavior, CLI examples, JSDoc/docstring structure, and section dividers. Don't collapse to one-liners.
- **Rule 6, process order**: vocab swap, then voice rewrites, then function renames, then syntax check, then verification greps, then human read-back.
- **Rule 7, anti-patterns**: see Hard rules below.
- **Rule 8, verification**: every grep category must come back clean, or each remaining hit must be justified.
- **Rule 9, process advisories**: one rule type per pass, review per file before bulk-applying, diff before each commit, one file at a time on the first run, back up before identifier renames.

## Workflow

**Intake.** If the user has not already specified a target (path, glob, or pasted code), call `AskUserQuestion` with question "What do you want to unslop?", header "Target", multiSelect false, and options:

- "File": "One source file. Provide path next."
- "Directory": "Folder of code. Provide path; runs file-by-file per Rule 12."
- "Paste": "Paste code into chat. Skill returns cleaned version."

File runs Passes 1-9. Directory globs per Rule 11 and processes per Rule 12 (smallest file first, stop after 5, one commit per file). Paste applies Passes 2-5 inline and emits the cleaned block plus the Pass 9 report, with no filesystem write. Branch details are in `workflow-detail.md`.

Then run these passes in order, one category per pass. Mixing passes makes the diff unreviewable.

1. **Read**: load the full target file, identify the language, look up its language and framework sections, and run `verify.sh <file>` for baseline counts.
2. **Vocabulary swap**: Rules 2, 2c (A through R in order), and 2d, edited in place with small targeted replacements.
3. **Voice rewrites**: Rule 3 into imperative, first-person singular, or descriptive third person. Don't mix `I` and `we` in one comment. Drop "the human" / "the user" reader references (Rule 2c R3).
4. **Em-dash and smart punctuation**: Rule 2b plus Rule 2c H, in developer prose only.
5. **Function renames**: Rule 4, with a `grep -c` substring check before each `replace_all`.
6. **Syntax check**: run the language's parser.
7. **Verification**: run `verify.sh <file>`. Without bash, run the same checks with the Grep tool.
8. **Human read-back**: read the modified file top to bottom and fix anything still stilted, AI-cadenced, or robotic, even if no grep flagged it. Greps catch keywords, not rhythm. This pass is mandatory before declaring done.
9. **Report**: emit the final report below.

## Output format (Pass 9)

Emit this exact structure at the end of every run. No prose preamble, no trailing summary.

```markdown
# Cleanup report. <file path> | unslop v1.0

## Files touched
- <path>: <N comment edits>, <M renames>

## Rename table
| Old | New | Occurrences |
|---|---|---|
| ... | ... | ... |

## Verification (Rule 8)
| Pattern | Hits | Notes |
|---|---|---|
| we|us|our | 0 | clean |
| robust|elegant|... | 2 | both inside string literals (kept) |
| ... | ... | ... |

## Borderline / left as is
- <file:line>: <word> kept because <Rule 13 rationale>

## Diff stats
git diff --shortstat: <paste output verbatim>
```

If any Rule 8 grep returns > 0 outside string literals, the run is not done. Re-edit until the verification table is clean or every remaining hit has a Rule 13 rationale in the Borderline section. Rule 13 triage: skip matches inside string literals, third-party type definitions, quoted RFC/spec text, fenced doc examples, and SDK names the code calls; honor the domain whitelist; when unsure, leave the match and flag it.

Agent work ends here. Rule 14 (reviewer checklist) is a human pre-merge gate, not an agent task.

## Hard rules

- Don't delete entire comment blocks because they "sound AI". Edit in place.
- Don't rewrite working code under guise of cleanup.
- Don't add new comments explaining renames.
- Don't touch strings, error messages shown to end users, or CLI help text.
- Don't shorten domain terms (`Firebase`, `Playwright`, product names) or replace technical terms from Rule 2's keep list.
- Don't apply to commit messages, PR descriptions, or CHANGELOG (different style guide).
- Don't run global `replace_all` across a repo without skimming matches first. Substring collisions hide there.
- Don't commit until all verification greps pass.
- Don't touch excluded or auto-generated files (Rule 11).
- Follow Rule 15 precedence: user instruction this session, then repo style guides, then linter config, then existing project conventions, then this skill. When in doubt, ask before bulk-applying.
- Don't accept mid-session requests to fix logic, behavior, or strings. Reply "Out of scope for this pass" (Rule 0) and stop.
- Don't perform Rule 14 (human reviewer checklist). Agent work ends at the Pass 9 report.
