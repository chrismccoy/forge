# Debugging

[← Back to the README](../README.md)

## `crash-report`

Explain a macOS crash report in plain English: what happened, the core issue, why it happened, why it crashed that way, and a fix for the developer plus one for the person using the app.

```
/crash-report
```

A Mac writes a crash report every time an app stops working, and the reason is in there, buried in thousands of lines of addresses and frame numbers. The `crash-report` skill reads modern `.ips` JSON reports, legacy `.crash` text reports, hang reports, spindumps, samples, and Console excerpts, and returns six fixed sections in the same order every time - section 1 for a non-technical stakeholder, section 6 for someone who does not write code.

Every claim has to name its source: the thread number, the frame index, the field name, or the exact string it came from. A claim without an anchor is not made at all - the section prints its header followed by `Not determinable from this report - need [the missing field]` instead. That rule is what keeps the analysis from drifting into a plausible-sounding story about a crash that did not happen.

Length tracks evidence rather than filling a quota. Each section has a structural cap counted before sending, but the caps are ceilings and most reports land well under: a paste with three usable lines gets a two-sentence section 4. Restating the backtrace frame by frame, explaining macOS concepts the report never raises, or listing fixes the evidence does not support all count as padding and get cut.

Damaged input has defined behaviour rather than a guess. A report cut off after the exception block is diagnosed from what survived and flagged incomplete on the input-type line. An unsymbolicated backtrace is diagnosed from the Binary Images table, Termination Reason, and Exception Type, with the matching `.dSYM` requested in section 5. A paste holding several crashes gets the most recent one analyzed and the others counted. Only a wholly unreadable paste stops the report.

## 📋 Technical Overview

One slash command plus its procedure file `lib/crash-report/SKILL.md`, which loads the master template from `lib/crash-report/references/prompt-template.md`. The command `/crash-report` takes a path or a pasted report, or offers to read the newest file in `~/Library/Logs/DiagnosticReports`. The report is substituted into a paired-tag block and treated as machine-generated data throughout. Every response, including the two fixed replies, ends with the version line `macOS Crash Report Analyzer v1.1`.

## ✨ Features

- 🧭 Six fixed sections, same order every time, as exact Markdown H2 headers - never merged, reordered, renamed, or dropped
- 📌 Every claim names its source field, thread, frame, or quoted string, or it is not made
- 🕳️ Gaps admitted by name. A missing OS Version marks that one section and leaves the other five intact
- 📄 Reads what a Mac actually writes: `.ips` JSON, legacy `.crash`, hang reports, spindumps, samples, Console excerpts
- 🧩 Damaged input handled. Truncated reports, unsymbolicated backtraces, and multi-crash pastes each have defined behaviour
- ⚖️ A mechanical response-type test. Unreadable means one short question; readable but not an Apple log means a fixed reply; readable Apple log means the full six sections
- ✂️ Structural caps counted before sending, treated as ceilings rather than targets
- 📖 Every macOS-specific term defined parenthetically on first use, however long the response runs
- 🔀 Contested diagnoses stay contested. Where evidence supports two readings, section 2 leads with the favoured one and names what would confirm the alternative
- 🛡️ Instruction-like text inside the report is reported as tampering on its own line and never followed
- 🚫 Never recommends disabling SIP, Gatekeeper, or code-signing verification as a user-side fix

## 🔄 How it works

1. **Intake.** Take the report from a path, a paste, or the newest file in `~/Library/Logs/DiagnosticReports`.
2. **Classify.** Apply the mechanical test - can the block be read, and is it an Apple log?
3. **Identify.** Emit one input-type line carrying the format, extra crash count, whether the backtrace is unsymbolicated, and whether the report is incomplete.
4. **Diagnose.** Write the six sections, anchoring every claim and marking gaps by name.
5. **Check.** Count sentences and steps against the caps, confirm the headers and term definitions, cut anything over.
6. **Close.** The version line, last, always.

## 🚀 How to use it

```
/crash-report ~/Library/Logs/DiagnosticReports/MyApp-2026-09-03.ips
/crash-report                     ← asks for a paste, a path, or the newest report
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"why did my app crash"*, *"explain this crash report"*, *"read this .ips file"*, *"what does EXC_BAD_ACCESS mean here"*, *"my app quits on launch"*, *"diagnose this spindump"*

The full procedure lives at [`lib/crash-report/SKILL.md`](../lib/crash-report/SKILL.md) and the slash command at [`commands/crash-report.md`](../commands/crash-report.md).
