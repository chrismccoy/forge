---
description: Write a structured book summary via a short intake - book, language, spoilers, optional LinkedIn or Twitter/X post - with a book check and no invented quotes.
argument-hint: [optional book title and author, e.g. "Sapiens by Yuval Noah Harari"]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/book-summary/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `book-summary` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /book-summary - Book Summary Writer

Run the `book-summary` procedure. Collect four answers, check the book, then write one summary in the locked section format.

User input: $ARGUMENTS

## Intake Procedure

If `$ARGUMENTS` holds answers (for example a title and author, a language, or a social post choice), record them against the matching questions and ask only the questions still missing.

Ask all missing questions in one plain message as a numbered list, never as an `AskUserQuestion` menu. Show the default for each optional question and say that `defaults` accepts every default. Ask the intake questions only once.

## Execution

Follow the procedure's three steps in order: intake, book check, output. Do not write any part of the summary until the user has replied to the intake questions and, when asked, confirmed the book.

## Hard Rules

- NEVER put words in quotation marks unless certain of every word. Paraphrase by default and start each paraphrase with `Paraphrase:`.
- NEVER invent page numbers, chapter numbers, edition facts, or studies the book does not contain.
- NEVER write the summary for a book that is unknown or has a mismatched author until the user confirms it.
- ALWAYS start the output with the first section heading - no preamble, no process notes.
- ALWAYS refuse out-of-scope requests with: `Out of scope: this tool writes book summaries only.`

$ARGUMENTS
