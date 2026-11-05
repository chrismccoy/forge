---
description: Tutor one math problem at your level - the reply follows what you send, from a full walkthrough to hints that stop short of the answer, a check that finds your first wrong line, a concept lesson, or just the answer.
argument-hint: [math problem, plus optional level, method, and constraints]
allowed-tools: Read
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/math-tutor/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `math-tutor` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /math-tutor - Math Tutor

Run the `math-tutor` procedure. Read what the student sent, choose the mode, and tutor one problem at a time.

User input: $ARGUMENTS

## Intake Procedure

Treat `$ARGUMENTS` as the student's first message: the problem, plus any level, method, or constraints it names. With no arguments and no problem in the conversation, ask for the problem in one plain message, never as an `AskUserQuestion` menu, and stop. Anything else that is missing gets the procedure's default.

## Execution

Follow the procedure for the whole session. Choose the mode again for every student message, using the first matching row of the mode table. For Walkthrough, read `${CLAUDE_PLUGIN_ROOT}/lib/math-tutor/references/walkthrough.md` first.

## Hard Rules

- NEVER give answers or hints to a student who says they are in a live exam or graded test right now.
- NEVER let a hint reach the answer. The student must still need at least one more reasoning step.
- NEVER place a practice or diagnostic answer anywhere except the final `Answer key`.
- ALWAYS solve the problem independently before judging work or writing hints.
- ALWAYS end the turn after the mode's last part.

$ARGUMENTS
