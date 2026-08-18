---
description: Cold, full-file WordPress performance review - reads every file in the plugin or theme, then reports severity-tagged findings with file:line, impact, and fix. Re-runs from scratch every time, so a second pass finds what the first missed.
argument-hint: [path to plugin or theme]
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-performance/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `wordpress-performance` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /wp-performance - Cold Full-File Performance Review

Run the `wordpress-performance` procedure against a WordPress plugin, theme, mu-plugin, or loose code directory. Detect the target, build a coverage manifest, triage with the bundled scan script, read every manifest file in full, then report severity-tagged findings with `file:line`, quoted code, impact, and fix.

If a path was provided in the slash command arguments, review that path. Otherwise review the current working directory.

Target path (if provided): $ARGUMENTS

## This command never warm-starts

Every invocation is a cold run, no matter how many times it has already run in this session:

1. Re-run the manifest script - never reuse a file list from earlier in the conversation.
2. Re-read every file from disk, including files reviewed and cleared in a previous pass.
3. Ignore prior findings, prior reports, and prior clean verdicts while scanning.
4. Do not narrow scope by git state unless the user explicitly asks for a diff review.

That is the point of running it twice: a pass that inherits the first pass's assumptions cannot find what the first pass missed. Compare runs only after the fresh report is finished, and only if the user asks.

## Run the scripts

Always invoke with `${CLAUDE_PLUGIN_ROOT}` so the scripts resolve regardless of the working directory.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/wordpress-performance/scripts/wp-perf-manifest.sh" <target>
bash "${CLAUDE_PLUGIN_ROOT}/lib/wordpress-performance/scripts/wp-perf-scan.sh" <target>
```

The manifest is the coverage checklist for the run - every file it lists gets read in full, and files read must equal the manifest count. The scan script is triage that orders the reading pass; a grep match is a candidate, not a finding. Report both numbers in the output's scan line.

For a target over 200 files or 50k lines, state the size first, then proceed unless the user scopes it down. Never sample silently.

## Abort and redirect

If the given path does not exist, report it and stop. If it exists but holds no PHP or JS, follow the procedure file's abort response rather than reporting.

If the request is to fix the code rather than review it, redirect in one line: `/wp-build` changes existing WordPress code. For a full security and architecture review use `/wp-review`; for the scorecard alone use `/wp-report-card`. This command reviews performance, it does not rewrite.
