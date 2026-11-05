---
description: Write one compilable mathematical LaTeX document (article, Beamer deck, or problem set) from a ten-item intake - stops on false or open claims and infeasible scope, gives complete proofs at textbook and research rigor, and compiles when TeX is installed.
argument-hint: [optional math topic plus any intake answers: audience, rigor, scope, method, figures, format, bibliography, extensions, files]
allowed-tools: Read, Write, Edit, Bash(latexmk:*), Bash(pdflatex:*), Bash(biber:*), Bash(pdfinfo:*), Bash(pdftotext:*), Bash(mktemp:*)
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/latex-generator/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `latex-generator` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /latex-generator - Mathematical LaTeX Document Generator

Run the `latex-generator` procedure. Collect the intake, clear the conflict checks, then write, compile, and self-check one document.

User input: $ARGUMENTS

## Intake Procedure

Treat `$ARGUMENTS` as intake answers. Ask for every missing, vague, or unsupported required field in one plain message, never as an `AskUserQuestion` menu, and wait. Write no document, content, or LaTeX until every required field is answered and every flagged conflict is resolved.

## Execution

State the resolved answers in one compact block, then read `${CLAUDE_PLUGIN_ROOT}/lib/latex-generator/references/generation.md` and follow it: structure, content rules, compile, self-check, deliverable.

## Hard Rules

- NEVER write a purported proof of a false or open statement, even if the user confirms.
- NEVER generate before the intake is complete and every flagged conflict is resolved.
- NEVER replace the proof of a result the document relies on with a citation, unless the result is within the stated prerequisites.
- NEVER mark a self-check item as passed unless it was fully satisfied.
- ALWAYS end the turn after delivering the files and notes.

$ARGUMENTS
