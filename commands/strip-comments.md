---
description: Strip every comment from a codebase except file headers, pragmas, and license notices - preview and approval required before any write.
argument-hint: [optional path, or a scope like "src/ python only"]
allowed-tools: AskUserQuestion, Read, Edit, Write, Bash, Grep, Glob
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `strip-comments` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /strip-comments - Strip Comments, Keep File Headers

Run the `strip-comments` procedure. Remove every comment from a codebase except the header comment at the top of each file, and except the comment-shaped constructs that are actually directives, pragmas, or legal notices.

This command writes to disk. It never does so before a diff preview has been shown and approved.

User input: $ARGUMENTS

## Intake Procedure

Collect the fields below with `AskUserQuestion`. Ask in one call where possible - four questions is the tool's limit, so DOCSTRINGS and MARKUP go in a second call only when the enumerated files make them relevant.

If `$ARGUMENTS` is a path to an existing directory or file, treat it as the `SCOPE` candidate and confirm it inside question 1 rather than skipping the question. If `$ARGUMENTS` also carries a language hint ("python only", "just the JS"), treat it as the `LANGUAGES` candidate the same way.

The listed options are starting points - tell the user the "Other" field is the expected path for their real scope.

1. **SCOPE** - what to process. Offer: `Current directory, recursively`, `One subdirectory (give path)`, `Changed files only (git diff)`, `A single file`, plus "Other".
2. **LANGUAGES** - which file types. Offer: `Everything found`, `One language only (say which)`, `Source files, skip templates`, plus "Other".
3. **BATCHING** - how to work through it. Offer: `Batch by directory (recommended over ~50 files)`, `Batch by language`, `All at once - small codebase`, plus "Other".
4. **DOCSTRINGS** (Python present only) - Offer: `Keep docstrings (default)`, `Remove docstrings too`, plus "Other". A docstring is an executable string expression, not a comment; removal keeps any docstring consumed at runtime and replaces a function's only body with `pass`.
5. **MARKUP** (template or markup files present only) - Offer: `Leave markup comments alone (default)`, `Strip HTML/Blade/Jinja/Handlebars comments too`, plus "Other".

## Safety Gate Before Any Edit

Before enumerating, confirm the working state:

- The work is on a branch, not the default branch.
- `git status --short` is clean. A dirty tree makes the diff preview unreadable and the change hard to revert.
- If the project is not under version control, say so plainly and get explicit confirmation before editing anything.

Do not proceed past a failed check on your own judgment. Say which check failed and stop.

## Execution

1. **Enumerate** with `${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/find-candidates.sh <root> [-- ext ...]`, passing the collected scope through. Present the file list before touching anything, and carry the script's stderr skips into the report.
2. **Read before editing.** Per language, establish where the header ends (`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/language-notes.md`), which comment-like lines must survive (`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/preserve-list.md`), and which apparent comments sit inside strings, URLs, regexes, or heredocs. Batch by language.
3. **Preview.** Show proposed changes grouped by file, diff format, no prose between hunks. Then STOP and wait. Approval on one batch is not approval on the next.
4. **Apply** only the approved batch.
5. **Verify** - required before reporting done:
   ```
   git diff --name-only | ${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/syntax-check.sh
   git diff --name-only | ${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/audit-remaining.sh
   git diff --stat
   ```
   Resolve every `FLAG` from the audit. List every `SKIP` from the syntax check - a skip is not evidence of correctness. Then run the project's test suite if one exists, and its build for languages the syntax check could not cover.
6. **Report** - files changed, lines removed, files skipped and why, constructs deliberately preserved, and every ambiguous case with its file and line.

## Hard Rules

- NEVER write to disk before showing a diff preview and receiving approval - this holds even when the user sounds impatient, and especially on a first run against an unfamiliar codebase.
- NEVER regex-sweep a whole file. Comment syntax appears inside strings, URLs, regexes, and heredocs; edit with enough surrounding context to tell code from data.
- NEVER run a formatter, a linter autofix, a rename, a reorder, or an import cleanup. Preserve indentation, blank-line structure, and trailing whitespace on every line not being deleted.
- NEVER remove a shebang, directive prologue, type-checker or linter directive, coverage or bundler hint, license or copyright header, SPDX identifier, `/*! */` block, language pragma, generated-file marker, or Python comment-form type annotation.
- NEVER invent a header comment for a file that has none.
- NEVER resolve an ambiguity silently - it goes in the report with a file and line reference.
- NEVER report done on the strength of a diff alone. The syntax check and the comment audit are required.
- ALWAYS treat Markdown, `README`, and `CHANGELOG` as out of scope.
- ALWAYS refuse out-of-scope requests with: `Out of scope: this engine removes comments only.` To rewrite docblocks into short plain-English one-liners instead of deleting them use `/docblock-rewrite`; to strip AI-sounding voice from comments that stay use `/unslop`.

$ARGUMENTS
