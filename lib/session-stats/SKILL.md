# session-stats

## Purpose

Render the quantitative metrics of a Claude Code session as one self-contained, dark-theme HTML
page. The output is **stats only**: KPI cards for headline numbers (duration, prompts, tool calls,
files written/edited, output tokens, est. cost), a per-tool usage table with share bars, and a
token-bucket table (input, output, cache created, cache read). No prompts, observations, tone
analysis, or recommendations.

Two bundled scripts form an offline pipeline with no third-party Python packages (standard library only; requires Python 3). `scan_jsonl.py` parses a
session `.jsonl` transcript and computes every metric, including a cost estimate derived from each
assistant message's token `usage` times per-model pricing. `build_stats_html.py` injects the result
into a fixed dark template and writes a standalone document.

## When to Use

Use this skill to produce a shareable visual of session *numbers* - duration, prompts, tool calls,
files written/edited, output tokens, est. cost, per-tool usage breakdown, and token buckets - styled
in the dark template, written to a standalone `.html` file that opens in any browser with no external
assets, scripts, or fonts.

Do not use this skill for full session summaries, narrative retros, or recommendations - this skill
emits stats only.

## Process

1. **Get the scan JSON.** `${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/scan_jsonl.py` parses a Claude Code `.jsonl` transcript and emits
   the metrics JSON, computing cost from token `usage` times per-model pricing (the transcript stores
   token counts, not dollars, so cost is always computed here). Find the current session file, then
   scan it:

   ```bash
   # Locate the current session transcript (POSIX: macOS / Linux / WSL / Git Bash)
   ls -t "$HOME/.claude/projects/<project-slug>"/*.jsonl | head -1
   # Scan it
   python "${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/scan_jsonl.py" --in <session.jsonl> > /tmp/scan.json
   ```

   On Windows/PowerShell, resolve the newest transcript natively:

   ```powershell
   Get-ChildItem "$env:USERPROFILE\.claude\projects\<project-slug>\*.jsonl" |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
   ```

   Or just use the Glob tool (`**/.claude/projects/<project-slug>/*.jsonl`, newest first) to stay
   shell-agnostic. Invoke the scripts with `python` (the usual command on Windows); if that is not
   found, try `py -3` - note `python3` is often absent on Windows.

   Pricing follows the current Claude API catalog via a per-model table (Opus, Sonnet, Haiku, Fable),
   defaulting to Opus 4.8 = $5/$25 per MTok in/out, cache write $6.25, cache read $0.50. A model with
   no table entry renders cost as `N/A` rather than $0. Override rates without editing the script via
   env vars (per MTok): `IN_RATE`, `OUT_RATE`, `CW_RATE`, `CR_RATE`. promptCount excludes slash-command
   and system turns.

2. **Render the HTML.** Run the builder, or pipe the two stages directly:

   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/build_stats_html.py" --in /tmp/scan.json --out session-stats.html
   ```

   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/scan_jsonl.py" --in <session.jsonl> \
     | python "${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/build_stats_html.py" --out session-stats.html
   ```

   When a scan holds multiple sessions, select one by id/slug prefix:

   ```bash
   python "${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/build_stats_html.py" --in /tmp/scan.json --session 657aa92f --out session-stats.html
   ```

3. **Report.** State the output path and confirm the page is self-contained (no `<script>`, no
   external assets). Offer to open it or change the destination. Render values come only from the
   transcript - never invent metrics; missing fields render as `N/A`.

### Bundled files

- **`${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/scan_jsonl.py`** - Parses a Claude Code `.jsonl` transcript into the metrics JSON,
  computing cost from token `usage` times per-model pricing. Pure stdlib, no third-party packages.
  Supports `IN_RATE`/`OUT_RATE`/`CW_RATE`/`CR_RATE` env overrides. Cost groups assistant messages by
  model and sums input/output/cache-write/cache-read tokens times their rates, divided by one million;
  an unpriced model makes the whole cost render `N/A`, never $0. Also emits a per-tool call breakdown
  (`toolBreakdown`, sorted by count) and summed token buckets (`tokens`: input/output/cacheCreated/cacheRead)
  that feed the usage and token tables. The `API errors` metric is a heuristic (substring match on
  assistant text), so treat it as approximate.
- **`${CLAUDE_PLUGIN_ROOT}/lib/session-stats/scripts/build_stats_html.py`** - Converts the metrics JSON into the stats HTML. Handles session
  selection (`--session` prefix match), duration/cost/int formatting, HTML-escaping, and template
  injection. `--template <path>` overrides the bundled `${CLAUDE_PLUGIN_ROOT}/lib/session-stats/assets/template.html`. Pure stdlib. Exit
  codes: `0` ok, `1` no session / bad JSON, `2` template missing.
- **`${CLAUDE_PLUGIN_ROOT}/lib/session-stats/assets/template.html`** - The fixed dark-theme shell, an inline static-CSS port of the design (no
  Tailwind, no `<script>`, no external assets). The script replaces the single `<!-- CONTENT -->` marker
  with the rendered stats body. To restyle, edit the CSS variables in `:root` (e.g. `--accent`, `--ember`,
  `--ink`, `--coal`); `build_content()` in `build_stats_html.py` emits the matching `.kpi` / `table.t` /
  `.bar` classes, so keep those class names in sync if structural rules change.

## Validation

- [ ] Output is one complete `<!DOCTYPE html>` document with no external references and no `<script>` tags.
- [ ] Stats only: no narrative sections, observations, or recommendations.
- [ ] Every number traces to the transcript; absent metrics show `N/A`, never a guess.
- [ ] The page is self-contained and opens in any browser with no external assets, scripts, or fonts.
