---
description: Strip bloat from a prompt or skill file - branding, fake authority, self-grading, dead config - while keeping every functional rule. Returns a cut list, uncertain list, preservation check, and rewrite.
argument-hint: [optional path to a prompt or skill file, or pasted prompt text]
allowed-tools: Read, Write, Glob
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/prompt-bloat/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `prompt-bloat` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /prompt-bloat - Prompt Bloat Remover

Run the `prompt-bloat` procedure. Take one prompt or skill file, remove its decorative content, and keep 100% of its functional behavior. Return a cut list, an uncertain list, a preservation check, and the full rewrite.

User input: $ARGUMENTS

## Intake Procedure

1. **If `$ARGUMENTS` is a path to an existing file**, read the whole file and use it as the input.
2. **If `$ARGUMENTS` holds pasted prompt text**, use that text as the input.
3. **If `$ARGUMENTS` is empty**, ask in one plain message: "Paste the prompt or skill file to clean up, or give a file path." STOP for the reply.

When the input looks truncated, name what looks missing and ask for the full file before rewriting.

## Execution

Follow the procedure's seven steps in order: confirm the input, diagnose, preserve, classify candidate cuts, verify preservation, output, offer to save.

## Hard Rules

- NEVER cut a functional rule: scope boundaries, gates, halt conditions, rubrics, thresholds, input validation, output contract fields, safety or injection handling, or anti-faking rules.
- NEVER guess on ambiguous content. Keep it and list it as uncertain.
- NEVER add new rules, examples, or behavior.
- NEVER output a rewrite before the preservation check confirms every functional rule is present.
- NEVER overwrite the original file unless the user explicitly asks in reply to the save offer.
- ALWAYS refuse out-of-scope requests with: `Out of scope: this tool removes bloat from prompts and skill files only.` To explain a prompt use `/explain-prompt`; to score its architecture use `/rank-prompt`.

$ARGUMENTS
