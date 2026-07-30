---
description: Troubleshoot a broken Excel/Google Sheets formula - collects the formula and the problem, then debugs and fixes it.
argument-hint: [broken formula] | [what's going wrong]
allowed-tools: Read, AskUserQuestion
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/excel-formula-troubleshooter/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `excel-formula-troubleshooter` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Intake for the **excel-formula-troubleshooter** procedure.

Raw arguments: `$ARGUMENTS`

## Collect inputs

Two inputs are required:
- `broken_formula` - the formula that isn't working
- `issue` - what's going wrong (error code, wrong result, expected behavior)

Parse `$ARGUMENTS`:
- If it contains a `|`, treat the part before `|` as `broken_formula` and the part after as `issue`.
- If it contains `<broken_formula>` / `<issue>` tags, use those.
- Otherwise, if only a formula is present, treat the whole thing as `broken_formula` and ask the user for the `issue`.
- If `$ARGUMENTS` is empty, ask the user to provide both the broken formula and the issue. Use AskUserQuestion only if a multiple-choice clarification helps; otherwise just ask in plain text.

Do not guess the issue. If it is missing, ask.

## Run

Once both inputs are known, apply the `excel-formula-troubleshooter` procedure with them wrapped as:

```
<broken_formula>
{the formula}
</broken_formula>

<issue>
{what's going wrong}
</issue>
```

Follow the procedure file's output format exactly.
