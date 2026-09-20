# Utilities

[← Back to the README](../README.md)

## `prompt-snippet`

Write one complete, production-quality standalone script in any of 19 languages, from three questions asked one at a time: language, task, and whether to show it in the chat or save it to a file.

```
/snippet
```

A script that merely works and a script you can leave running are different artifacts. This tool writes the second kind by default. Every script ships with a header comment giving file name, purpose, usage, exit codes, dependencies and any assumptions; logic split into functions or modules behind one entry point; validated arguments and a `--help`; errors on stderr and meaningful exit codes; cleanup on exit and on interrupt; secrets read from the environment rather than hardcoded; validation and a `--dry-run` before anything destructive; streamed reads so a huge input cannot exhaust memory; and atomic replace-by-rename so an interrupted run cannot leave a half-written file. State, config and logs land in XDG locations on Linux and macOS and `%APPDATA%`/`%LOCALAPPDATA%` on Windows, with an ISO 8601 UTC timestamp on every log line.

Nineteen languages have their own conventions section - bash, clojure, csharp, elixir, erlang, go, haskell, java, javascript, lua, perl, php, powershell, python, ruby, rust, swift, typescript, zsh - covering how the file starts, how options are parsed, how errors are reported, which tools run other programs, and which formatter to match. Only the one section that applies is read, and where it differs from the general rules, it wins.

## 📋 Technical Overview

One slash command and a two-file procedure bundle. `lib/prompt-snippet/SKILL.md` carries the one-question-at-a-time intake, the general structure, reliability, state and style rules, and the two delivery formats. `lib/prompt-snippet/references/languages.md` holds the 19 language sections plus an "Any other language" fallback; exactly one section is loaded per run. Intake takes an answer from anywhere in the conversation, so an argument that already names the language and the task leaves only the output question.

## ✨ Features

- 🗣️ Three questions, one per reply - no code block, no preamble, no list of the other fields
- 🌐 19 language sections plus a general fallback; only the matching section is read
- 📄 Header comment with file name, purpose, usage, exit codes, dependencies and up to 5 `Assumptions:`
- 🛡️ stderr for errors, non-zero exit on failure, cleanup on exit and interrupt
- 🔐 No hardcoded secrets, no `eval` of input, no shell commands built from input strings
- 🧯 Validation and a `--dry-run` before anything destructive
- 💧 Streamed reads for large inputs; atomic replace-by-rename for file writes
- 📁 XDG config/state/log locations on Linux and macOS, `%APPDATA%`/`%LOCALAPPDATA%` on Windows
- 📤 Two delivery modes: one bare code block in the chat, or a saved file plus a four-line summary
- 🚫 No TODOs, stubs, placeholder functions, or `...` sections

## 🔄 How it works

1. **Ask for the language.** One short question, naming a few examples. Skipped if already known.
2. **Ask what the script should do.** Skipped if already known.
3. **Ask where it goes.** Chat is the default; a file name counts as an answer. Then generation starts in that same reply.
4. **Load one language section** from the references file and apply its conventions over the general rules.
5. **Write the complete script** - structure, reliability and safety, state and logging if the task needs them, style.
6. **Deliver it.** One fenced code block and nothing else, or the saved file plus `Saved:` / `Run:` / `Exit codes:` / `Dependencies:`.

## 🚀 How to use it

```
/snippet                                      ← asks all three questions
/snippet python, watch a folder and resize new images   ← only the output question is left
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write me a bash script that..."*, *"I need a Python CLI for..."*, *"generate a Go utility that..."*, *"script this in zsh"*, *"save it as wordcount.py"*

The full procedure lives at [`lib/prompt-snippet/SKILL.md`](../lib/prompt-snippet/SKILL.md), the per-language conventions at [`lib/prompt-snippet/references/languages.md`](../lib/prompt-snippet/references/languages.md), and the slash command at [`commands/snippet.md`](../commands/snippet.md).

## `session-stats`

Render a Claude Code session's quantitative stats as a single self-contained, dark-theme HTML page. Stats only: KPI cards, a full metrics table, and a files-modified table. No prompts, observations, tone analysis, or recommendations.

```
/session-stats
```

Session transcripts are rich but unreadable as raw `.jsonl`, and the one number people actually want, what a session cost, is not stored anywhere in them. This plugin turns a transcript into a clean visual of the numbers. A two-stage offline pipeline parses the transcript and renders the page with no external dependency. `scan_jsonl.py` walks the `.jsonl`, counts prompts (excluding slash-command and system turns), tool calls, edits, files touched, errors, compactions, and subagents, derives duration and median turn time from timestamps, and computes a cost estimate from each assistant message's token `usage` times per-model pricing (the transcript stores token counts, not dollars). `build_stats_html.py` injects the result into a fixed dark template and writes a standalone `.html` file with no `<script>` tags and no external assets.

Pricing follows the current Claude API catalog (Opus 4.8 = $5/$25 per MTok in/out, cache write $6.25, cache read $0.50). Override any rate per MTok with the `IN_RATE`, `OUT_RATE`, `CW_RATE`, `CR_RATE` environment variables. Every number traces to the transcript; absent fields render as `N/A`, never a guess.

## 📋 Technical Overview

One slash command, its procedure file, two scripts, and a template asset. The procedure file `lib/session-stats/SKILL.md` carries the trigger phrases, the two-step workflow, and the stats-only constraint. `scripts/scan_jsonl.py` produces a metrics JSON object; `scripts/build_stats_html.py` consumes it and the fixed `assets/template.html` to emit the document. The slash command `/session-stats` resolves the current session transcript (or an explicit `.jsonl` path) and runs the pipeline.

## ✨ Features

- 🎯 KPI cards: prompts, tool calls, edits, duration, cost, API errors, compactions, subagents
- 📊 Full metrics table plus a files-modified table (path and write count)
- 💰 Cost computed from token `usage` times per-model pricing; current Opus 4.8 catalog rates; `IN_RATE`/`OUT_RATE`/`CW_RATE`/`CR_RATE` overrides
- 🧮 promptCount excludes slash-command and system turns; cost groups assistant messages by model and sums input/output/cache-write/cache-read tokens times rates / 1e6
- 🌑 Fixed dark template; restyle via the `:root` CSS variables only
- 📦 Self-contained output: one `<!DOCTYPE html>` file, no `<script>`, no external assets, no fonts
- 🔌 Offline two-stage pipeline; pure Python stdlib; no external dependency
- 🚫 Stats only. No observations, narrative retros, or recommendations
- 🧾 Every number traces to the transcript; missing fields render as `N/A`

## 🔄 How it works

1. **Resolve the transcript.** The slash command uses an explicit `.jsonl` path, or finds the newest transcript for the current project under `~/.claude/projects/<slug>/`.
2. **Scan.** `scan_jsonl.py --in <session.jsonl>` emits a metrics JSON object, computing cost from token usage times per-model pricing.
3. **Render.** `build_stats_html.py --out session-stats.html` injects the metrics into the dark template and writes a standalone document. Pipe the two stages, or run them separately.
4. **Report.** State the output path; the page opens in any browser.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/session-stats                       ← current session → session-stats.html
/session-stats path/to/session.jsonl ← a specific transcript
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"render my session stats as HTML"*, *"make an HTML stats card of my session"*, *"session stats html"*, *"export session metrics to a dark HTML page"*, *"session stats dashboard"*

The full procedure lives at [`lib/session-stats/SKILL.md`](../lib/session-stats/SKILL.md), the slash command at [`commands/session-stats.md`](../commands/session-stats.md), and the scripts and template under [`lib/session-stats/scripts/`](../lib/session-stats/scripts/) and [`lib/session-stats/assets/template.html`](../lib/session-stats/assets/template.html).

## `token-auditor`

Grade LLM token usage from four raw counts: input efficiency, cache strategy, output discipline, and a weighted overall letter, with one highest-impact fix. A repeatable benchmark - the same four numbers always produce the same letters.

```
/token-audit
```

A session's token counts are easy to read and hard to judge. 40,000 input tokens is good or terrible depending entirely on what the cache did, and no dashboard says which. This tool fixes the judgement in a band table so the answer cannot drift between runs. Three metrics are computed at full precision, rounded once, and banded: input efficiency (`input / (input + cache_read) × 100`, lower is better), cache strategy (`cache_read / cache_create`, higher is better), and output discipline (`output / TOTAL × 100`, lower is better). Each gets a letter from a fixed table; the letters, not the raw metrics, are then weighted - cache strategy 50%, input efficiency 30%, output discipline 20%, scoring A=4 through F=0 - into one overall grade.

Six stages run in order and each gates the next: PARSE, VALIDATE, CALCULATE, GRADE, VERIFY, RENDER. Only the four values, the total, the five rounded metrics and the four letters cross a stage boundary, so a grade is defensible from the numbers alone rather than from how the run felt. Ten edge-case rows are evaluated under a precedence rule: the first six HALT on first match, the last four continue and all matching rows apply, because one run can hit several undefined denominators at once.

## 📋 Technical Overview

One slash command and a two-file procedure bundle. `lib/token-auditor/SKILL.md` carries the intake block format, the six-stage workflow, the edge-case precedence table, and the output contract. `lib/token-auditor/references/rules.md` holds the formulas, letter values, bands, worked examples, and five named rules - `RULE precision`, `RULE residual`, `RULE conditionals`, `RULE verify-retry`, `RULE repair` - which win over any other section that disagrees with them. The command accepts a pasted `---BEGIN TOKENS---` block or collects the six fields one at a time, assembling them into that same block so both paths run identical validation.

## ✨ Features

- 🎯 Three banded metrics plus a weighted overall letter, A through F, from a fixed table
- 🧮 Grades are weighted, never raw metrics - grade first, then weight A=4 through F=0
- 📐 `RULE precision`: full precision, rounded once, half away from zero, never banker's rounding
- 🧾 `RULE residual`: four independently rounded shares do not sum to 100.0, so the residual lands on the largest of rows 1, 3 and 4 - never on the output row, whose share is itself a banded metric
- 🚦 Ten edge-case rows under a precedence rule: rows 1-6 HALT on first match, rows 7-10 all apply
- ⭐ Row 9 fallback scale marks its letter with `*` and says so, since a marked B is not comparable to an unmarked one
- 🔁 `RULE verify-retry`: a disagreeing letter re-runs CALCULATE and GRADE once, then HALTs rather than guessing
- 🚫 Never estimates a value that was not supplied - a missing required number is a HALT
- 📊 Working shown for every ratio and for the weighted score; raw values stated once outside the table

## 🔄 How it works

1. **Parse.** Read the `---BEGIN TOKENS---` block, ignoring anything outside the delimiters, blank lines, and `#` comments. Identical repeated keys collapse; conflicting ones HALT.
2. **Validate.** Walk the ten edge-case rows under `RULE precedence`.
3. **Calculate.** Apply the formulas at full precision - shares, input efficiency, cache ratio, cache share, output discipline, io ratio.
4. **Grade.** Band each rounded value, then compute the weighted score from the letter values.
5. **Verify.** Recheck the arithmetic and each letter against its band row; re-run stages 3 and 4 once on disagreement, then HALT.
6. **Render.** Emit the output contract verbatim: metrics table, three ratios with working, four grades, one recommendation.

## 🚀 How to use it

```
/token-audit                                  ← asks for each field in turn
/token-audit ---BEGIN TOKENS--- ...           ← parses a pasted block, no questions
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"grade my token usage"*, *"how efficient was this session"*, *"audit my cache hit ratio"*, *"token efficiency report card"*, *"am I using prompt caching well"*

The full procedure lives at [`lib/token-auditor/SKILL.md`](../lib/token-auditor/SKILL.md), the formulas and named rules at [`lib/token-auditor/references/rules.md`](../lib/token-auditor/references/rules.md), and the slash command at [`commands/token-audit.md`](../commands/token-audit.md).

## `vgademo`

Generates retro 1990s style sizecoded assembly demos for MS-DOS, BIOS, and boot sector targets.

```
/vgademo
```

Remember the 256 byte intros and 4KB demos that shipped at Assembly, Revision, and The Party in the early 1990s? The kind of artful little programs the demoscene made famous. plasma fields, fire effects, tunnels, rotozoomers - all in the byte budget of a tweet? That's what this skill builds.

The `vgademo` skill adopts a veteran demoscene engineer persona and writes ultra compact 16 bit real mode assembly that runs on real (or emulated) DOS era hardware. It targets NASM, FASM, TASM, or MASM. emits `.COM` files, boot sectors, or raw binaries. and respects strict size budgets with byte level estimates before any code ships.

What makes it different from a generic "write me asm" prompt? It enforces demoscene rules. register reuse, implicit operands, fused operations (`STOSB`, `STOSW`, `LODSB`), bit shifts over multiplies, no `PUSH`/`POP` for preservation, no functions or macros beyond the minimum. And it refuses cleanly with a single line code (`REFUSE: size`, `REFUSE: platform`, `REFUSE: contradiction`) when your inputs don't add up, instead of producing broken bytes.

It ships a 256 byte intro, a boot sector that fits in 510 bytes, or a worked example of how the demoscene squeezes plasma out of a handful of opcodes.

## 📋 Technical Overview

An AI instruction specification that generates byte budget constrained 16 bit real mode x86 assembly in the style of early 1990s demoscene productions.

Built around a strict scope lock (refuses anything outside MS-DOS / BIOS / boot sector / .COM targets, refuses modern instructions, refuses size overruns), a mandatory output format (Byte Budget → Code → Core Trick → Tradeoffs), and a byte calibration table for accurate size estimation before emit.

It behaves like a real sizecoder: show the technique, name the opcode, move on. No marketing register, no buzzwords, no tutorials. Includes prompt injection defenses that treat `{{placeholder}}` content as inert data.

## ✨ Features

- 🎨 14 placeholder variables driving every demo: visual effect, size budget, target platform, video mode, CPU mode, assembler, binary format, entry point, performance priority, loop style, allowed tricks, memory model, dependencies, and comments toggle
- 🎯 4-round multiple-choice intake via `AskUserQuestion`. each question auto-includes an "Other" option for custom values (custom visual effects like starfield, metaballs, voxel landscape pass through verbatim)
- 📏 Strict size budgets enforced with a per-opcode byte calibration table. 256b intros, 512b boot sectors, 1KB / 4KB. 15% safety margin built in
- 🧮 Byte estimate emitted before the code block. no surprise overruns
- 💾 Multi-target. MS-DOS `.COM`, raw boot sector (with `0AA55h` signature), raw binary, BIOS-only mode
- 🖼️ Multi-mode rendering. Mode 13h (320x200x256 VGA), text mode (`B800h`, 80x25), VGA planar / Mode X
- 🔧 Four assembler syntaxes. NASM, FASM, TASM, MASM
- 🪄 Demoscene tricks. self-modifying code, undocumented opcodes, FPU, lookup tables, approximate trig, intentional overflow
- 🔁 Loop styles. single loop (`LOOP` instruction), unrolled, self-modifying
- 🎵 Optional PC speaker or AdLib-style sound when the byte budget allows
- 📋 Mandatory output format. Byte Budget → Code → Core Trick (mechanism + key instructions + register reuse map) → Tradeoffs (size won by / cycles cost / sacrificed)
- 🛡️ Single-line refusal codes. `REFUSE: scope|size|contradiction|platform|placeholder|injection`. no elaboration, no side-channel leaks
- 🔒 Scope lock refuses tutorials, history lessons, modern code (SSE/AVX/x86_64), and any request that breaches the declared `CPU_MODE`
- ⚡ Demoscene rules enforced. register reuse, implicit operands (AX/SI/DI), fused operations, bit-shifts for mul/div, no PUSH/POP for preservation, no functions or macros beyond minimum
- 📚 Two worked reference examples bundled. 256b XOR-plasma `.COM` (Mode 13h) and 512b text-mode color-bars boot sector (BIOS only)
- ⚠️ Negative anti-pattern example included. shows what to refuse cleanly instead of "fixing and emitting"
- 🎚️ Suggested low-temperature runtime (`temperature=0.3`, `top_p=0.9`). sizecoding needs low variance for stable byte counts
- 🚫 Hacker-engineer voice. no marketing register, no corporate jargon, no consultancy-speak
- 🔐 Prompt-injection defense. instructions embedded inside `{{...}}` placeholders are treated as inert data, refusal output is uniform to prevent side-channel inference

## 🔄 How it works

1. **Intake**: the `/vgademo` slash command runs four `AskUserQuestion` rounds collecting 14 placeholders:
 - **Round 1 - Visual & Platform**: effect (plasma / fire / tunnel / rotozoomer / Other), size (256b / 512b / 1KB / 4KB), platform (MS-DOS .COM / boot sector / BIOS), video mode (Mode 13h / text mode / VGA planar)
 - **Round 2 - Toolchain**: CPU mode (16-bit real / 32-bit protected), assembler (NASM / FASM / TASM / MASM), binary format (.COM / boot sector / raw), entry point (`org 100h` / `org 7C00h` / `org 0`)
 - **Round 3 - Optimization**: performance priority (smallest / fastest / balanced), loop style (single / unrolled / SMC), allowed tricks (multi-select. SMC / undoc / FPU / LUT), memory model
 - **Round 4 - Final**: dependencies (BIOS only / no DOS / direct HW), comments (yes / no)
2. **Validation**: checks for contradictions before emit. size-vs-effect, BIOS-only-vs-DOS-mode, 16-bit-vs-32-bit-tricks. emits `REFUSE: <reason>` on any conflict
3. **Pre-emit checklist** (silent): byte estimate ≤ 0.85 × size limit, zero forbidden instructions, register reuse covers every named register, mechanism matches the named trick
4. **Emit**: mandatory four-section output. Byte Budget, Code (single asm block), Core Trick (≤200 words), Tradeoffs (≤120 words)

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/vgademo ← walks through all four intake rounds
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a 256 byte plasma intro in NASM for MS-DOS"*, *"make a fire effect demo in Mode 13h"*, *"build a 512 byte boot sector with color bars"*, *"sizecoded tunnel effect for .COM file"*, *"VGA assembly rotozoomer under 1KB"*, *"demoscene intro for the 8086"*

The full procedure lives at [`lib/vgademo/SKILL.md`](../lib/vgademo/SKILL.md), the slash command at [`commands/vgademo.md`](../commands/vgademo.md), and the worked reference examples (256b XOR plasma and 512b boot sector) plus the anti pattern at [`references/examples.md`](../lib/vgademo/references/examples.md).

## `excel-formula-troubleshooter`

Debug, fix, and optimize broken Excel and Google Sheets formulas.

```
/fix-formula
```

A broken formula is rarely broken where it looks broken. `=VLOOKUP(A2,Sheet2!A:B,3,0)` throws `#REF!` not because the syntax is wrong but because the column index counts inside the range, and `A:B` only has two columns. The `excel-formula-troubleshooter` skill traces the formula like a spreadsheet engine does. function by function, parentheses balance, argument count and order, range references, data types (text vs number, dates as serials), circular references. then names the exact root cause, returns a copy-paste-ready corrected formula, explains the fix in plain bullets, and where it helps, suggests a modern alternative (`XLOOKUP` over `VLOOKUP`, `IFERROR` to mask error values).

Output is locked to four sections so every answer reads the same: ❌ The Issue, ✅ Corrected Formula, 🛠️ How the Fix Works, 🚀 Better Alternative (omitted when none applies). Function names come back UPPERCASE, ready to paste. Scope is locked to spreadsheet-formula troubleshooting. it does not answer general spreadsheet or data questions outside a broken formula.

## ✨ Features

- 🔎 Silent pre-answer trace. function-by-function, parentheses balance, argument count/order, range references, data types, circular references. the reasoning never clutters the output
- 🎯 Exact root cause. mismatched parentheses, wrong syntax, text-vs-number mismatch, circular reference, incorrect range, wrong column index. not "consider checking your ranges"
- 📋 Copy-paste-ready corrected formula with UPPERCASE function names
- 🧾 Beginner-friendly bulleted explanation of why the fix works
- 🚀 Optional modern alternative. `XLOOKUP` over `VLOOKUP`, `INDEX/MATCH`, `IFERROR` to mask `#N/A`. omitted cleanly when nothing better applies
- 📦 Locked 4-section output format. identical layout on every answer
- 🚪 Asks for the issue instead of guessing when only a formula is supplied
- 🔒 Scope lock. spreadsheet-formula troubleshooting only

## 🔄 How it works

1. **Intake**: the `/fix-formula` slash command parses the broken formula and the issue. pipe-separated (`formula | issue`), tag-wrapped (`<broken_formula>` / `<issue>`), or interactive prompt when either is missing
2. **Silent trace**: walks the formula function-by-function, checking parentheses, arguments, ranges, data types, and circular references. reasoning is not shown
3. **Diagnose**: names the single exact root cause
4. **Emit**: the locked four-section answer. The Issue, Corrected Formula, How the Fix Works, optional Better Alternative

## 🚀 How to use it

**Slash command** (explicit):

```
/fix-formula =VLOOKUP(A2,Sheet2!A:B,3,0) | returns #REF!   ← formula | issue
/fix-formula =VLOOKUP(A2,Sheet2!A:B,3,0)                   ← asks for the issue
/fix-formula                                               ← full intake (formula + issue)
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"fix my Excel formula"*, *"why does my formula return #REF!"*, *"debug this spreadsheet formula"*, *"troubleshoot a Google Sheets formula"*, *"my VLOOKUP isn't working"*, *"correct this formula"*

The full procedure lives at [`lib/excel-formula-troubleshooter/SKILL.md`](../lib/excel-formula-troubleshooter/SKILL.md), and the slash command at [`commands/fix-formula.md`](../commands/fix-formula.md).

---

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
