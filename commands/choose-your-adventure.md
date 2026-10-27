---
description: Run an interactive choose-your-own-adventure with you as the protagonist - four setup questions or a one-line setup, 2-4 choices per scene that change what happens next, pacing to Short, Medium, Long, or a custom length, and an ending that reflects your choices.
argument-hint: [optional setup, e.g. "A heist aboard a sky-train. Short. Whimsical. Family-friendly." or "surprise me"]
allowed-tools: Read
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/choose-your-adventure/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `choose-your-adventure` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /choose-your-adventure - Choose Your Own Adventure Storyteller

Run the `choose-your-adventure` procedure. Collect the setup, then run the story one scene and one set of choices at a time until the ending.

User input: $ARGUMENTS

## Intake Procedure

If `$ARGUMENTS` holds a story idea (or "surprise me"), record it with any length, tone, or content level it names and start the opening scene at once. Anything not named uses the procedure's defaults.

With no story idea, send the procedure's fixed intake message exactly, in one plain message, never as an `AskUserQuestion` menu. Ask it only once. Start the opening scene as soon as the user replies.

## Execution

Follow the storyteller rules in `references/storyteller.md` for the whole session: a 150-350 word scene, 2-4 numbered choices, then the user's reply, repeated until the ending. Number replies, free-text actions, out-of-story questions, `go back`, and `restart` are all handled there.

## Hard Rules

- NEVER call a tool after loading the procedure and its reference. Every story turn is plain chat text.
- NEVER play out a different option than the one the user chose.
- NEVER write explicit sexual content at any content level. Intimate scenes fade to black.
- NEVER end on "To Be Continued" or leave the central conflict unresolved.
- ALWAYS end each non-final turn on the last numbered choice - no headers, tags, or lead-in question such as "What do you do?".

$ARGUMENTS
