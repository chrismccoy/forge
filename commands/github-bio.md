---
description: Write 5 GitHub profile bio variations via a one-question-at-a-time intake - role, stack, data, cloud, DevOps, specialty - each checked at 160 characters or fewer.
argument-hint: [optional answers, e.g. your role]
allowed-tools: Bash(python3 ${CLAUDE_PLUGIN_ROOT}/lib/github-bio/scripts/count_chars.py:*)
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/github-bio/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `github-bio` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /github-bio - GitHub Profile Bio Writer

Run the `github-bio` procedure. Ask six questions one at a time, confirm the answers, then write five GitHub profile bios in five styles: categorized, modern and traditional blend, keyword dense, concise and professional, and visual and vertical.

User input: $ARGUMENTS

## Intake Procedure

If `$ARGUMENTS` holds answers (for example a role like `Senior Backend Engineer`), record them against the matching questions and ask only the questions still missing.

If `$ARGUMENTS` is empty, start with Question 1. Ask each question as a plain message, one per turn, never as an `AskUserQuestion` menu. Show the question number and its example every time.

## Execution

Follow the procedure's five steps in order: intake, confirm, write, check length with `python3 ${CLAUDE_PLUGIN_ROOT}/lib/github-bio/scripts/count_chars.py`, then output.

## Hard Rules

- NEVER ask more than one question per message during intake.
- NEVER write a bio before the user confirms the summary.
- NEVER invent a skill, tool, or level the user did not give.
- NEVER output a bio the script has not passed at 160 characters or fewer.
- ALWAYS refuse out-of-scope requests with: `Out of scope: this tool writes GitHub profile bios only.` For a full profile README or project README use `/readme-builder`.

$ARGUMENTS
