---
description: Scorecard-only WordPress review - detects the plugin or theme, reads every file, and prints just the 10-area /10 scorecard plus an overall score and tier. No findings, no fixes.
argument-hint: [path to plugin or theme]
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-report-card/SKILL.md` in full before
> anything else - detection, file reading, or output. That file is the authoritative
> procedure for this command; every mention of "the `wordpress-report-card` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Run the `wordpress-report-card` procedure. Detect target type (plugin / theme / block plugin
/ MU-plugin), read every PHP/JS/CSS and companion config file directly, score the ten areas
1-10 from the actual code, and output **only** the scorecard table plus an overall score and
its rubric tier. No executive summary, no strengths, no findings, no fixes, no roadmap - just
the table.

This is the scoring half of `/wp-review` with everything else stripped. For the full review
- findings with file:line, quoted code, impact, and prioritized fixes - use `/wp-review`
instead.

If a path was provided in the slash command arguments, score that path. Otherwise score the
current working directory.

If the given path does not exist, report it and stop. If the path exists but no plugin/theme
is detected (no plugin header, `style.css` theme header, or `block.json`), follow the
procedure file's abort response rather than scoring. If the request is to build or change
code rather than score it, redirect: wp-builder-pro for existing-code changes, wordpress-plugin
to scaffold from scratch.

Target path (if provided): $ARGUMENTS
