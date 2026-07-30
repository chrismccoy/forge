---
description: Strip AI-generated voice from source files without changing behavior - picker for file, directory, or paste
argument-hint: [optional path or pasted code]
allowed-tools: AskUserQuestion, Read, Edit, Write, Bash, Grep, Glob
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/unslop/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `unslop` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Run the `unslop` procedure on whatever the user provides.

User input: $ARGUMENTS

## Routing

1. **If $ARGUMENTS is a path to an existing file**, treat as **File** mode and run Passes 1-9 from the procedure file on it. Skip the picker.

2. **If $ARGUMENTS is a path to an existing directory**, treat as **Directory** mode. Glob per Rule 11 include/exclude in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`, then process file-by-file per Rule 12 (smallest first, one commit per file, stop after 5, await review). Skip the picker.

3. **If $ARGUMENTS contains pasted code** (multi-line block, fenced or unfenced, no valid path), treat as **Paste** mode. Detect language from syntax / fence hint. Apply Passes 2-5 inline. Return cleaned block + Pass 9 report. No filesystem write.

4. **If $ARGUMENTS is empty or ambiguous**, call `AskUserQuestion`:

   - question: "What do you want to unslop?"
   - header: "Target"
   - multiSelect: false
   - options:
     - label: "File", description: "One source file. Provide path next."
     - label: "Directory", description: "Folder of code. Provide path; runs file-by-file per Rule 12."
     - label: "Paste", description: "Paste code into chat. Returns the cleaned version."

   On answer:
   - **File** → ask path → File mode
   - **Directory** → ask path → Directory mode
   - **Paste** → reply "Paste code below; include language hint if not obvious" → wait for next message → Paste mode

## Procedure

After the target is resolved, follow the full procedure in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/SKILL.md`:

- Passes 1-8 in order (read → vocab swap → voice rewrites → em-dash strip → renames → syntax check → verify.sh → human read-back)
- Emit the mandatory Pass 9 final report

## Rule 0 enforcement

If the user mid-session asks for behavior changes, logic fixes, signature edits (outside Rule 4), or string-literal edits - under any rationale - reply exactly:

> Out of scope for this pass. Open a new session for behavior changes.

and stop. Rule 0 cannot be overridden.

## Scope refusal

Refuse and stop if the request is: refactoring, bug fixes, feature changes, CLI help text edits, README/CHANGELOG/LICENSE edits, or commit-message rewrites. These are different style guides.
