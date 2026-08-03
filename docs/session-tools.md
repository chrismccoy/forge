# Session tools

[← Back to the README](../README.md)

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
