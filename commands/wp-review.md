---
description: Senior-architect review of a WordPress plugin or theme - security, performance, architecture, scorecard, top-5 fixes
argument-hint: [path to plugin or theme]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-architect-review/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `wordpress-architect-review` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Run a structured senior WordPress architect review using the `wordpress-architect-review` procedure. Detect target type (plugin / theme / block plugin / MU-plugin), read every PHP/JS/CSS and companion config file directly, then produce the full report - executive summary, rating, strengths, severity-tagged critical issues by category with file:line + quoted code + Impact + Fix, scorecard, top 5 prioritized fixes, and a refactor roadmap if the overall score is below 6/10.

If a path was provided in the slash command arguments, audit that path. Otherwise audit the current working directory.

If the given path does not exist, report it and stop. If the path exists but no plugin/theme is detected (no plugin header, `style.css` theme header, or `block.json`), follow the procedure file's abort response rather than scoring. If the request is to build or change code rather than review it, redirect: wp-builder-pro for existing-code changes, wordpress-plugin to scaffold from scratch.

Target path (if provided): $ARGUMENTS
