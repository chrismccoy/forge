---
description: Render a Claude Code session's stats (KPI cards + per-tool usage table + token-bucket table) as a self-contained dark-theme HTML page. Offline pipeline - parses the .jsonl transcript and computes cost from token usage; no external tools required. Stats only, no observations.
allowed-tools: Read, Bash, Glob
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/session-stats/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `session-stats` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /session-stats - Session Stats as Dark HTML

Produce a stats-only, self-contained HTML page (KPI cards + per-tool usage table + token-bucket
table) for a Claude Code session, using the bundled offline pipeline.

## Usage

```
/session-stats [session.jsonl path]
```

User input: `$ARGUMENTS`

## Resolve the target transcript

1. **If `$ARGUMENTS` is a path to an existing `.jsonl` file**, use it as `SESSION_JSONL`.
2. **If `$ARGUMENTS` is empty**, use the current session transcript. Derive the project slug from
   the working directory and pick the newest match:
   `ls -t "$HOME/.claude/projects/<project-slug>"/*.jsonl | head -1`
3. Reject a path that does not exist. Require a `.jsonl` file, not a directory.

## Run the pipeline

```bash
ROOT="${CLAUDE_PLUGIN_ROOT}/lib/session-stats"
python "$ROOT/scripts/scan_jsonl.py" --in "<SESSION_JSONL>" \
  | python "$ROOT/scripts/build_stats_html.py" --out session-stats.html
```

- `scan_jsonl.py` computes metrics and a cost estimate (token `usage` × per-model pricing, current
  Opus 4.8 catalog rates). Override rates per MTok with env vars: `IN_RATE`, `OUT_RATE`, `CW_RATE`,
  `CR_RATE`. promptCount excludes slash-command and system turns.
- `build_stats_html.py` injects the stats into the fixed dark template and writes a standalone HTML
  file (no `<script>`, no external assets). Default output `session-stats.html`; change `--out` to retarget.
- When a scan holds multiple sessions, select one with `build_stats_html.py --session <id-or-slug-prefix>`.

## Report

State the output path and confirm the page is self-contained. Stats only - no observations or
recommendations. Every number traces to the transcript; absent fields render as `N/A`. Offer to
open it or change the destination.
