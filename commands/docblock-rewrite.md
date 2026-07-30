---
description: Convert PHPDoc and JSDoc blocks into one-line plain-English // comments. Scripted bulk pass over a directory or single file. Backs up originals to .bak, validates output against banned-words list and 100-char cap, replaces in place. Honors @internal/@deprecated/@ignore opt-outs.
allowed-tools: Read, Bash
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/docblock-rewrite/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `docblock-rewrite` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

# /docblock-rewrite - Plain-English Comment Rewriter

Run the bundled bash + perl runner over a directory or single file. Each
`/** ... */` block is replaced with a one-line `//` comment a non-technical
reader can understand.

## Usage

```
/docblock-rewrite <path> [flags]
```

`<path>` may be a directory (walked recursively) **or** a single file.

### Flags

| Flag | Default | Effect |
|---|---|---|
| `--dry-run` | off | Print unified diffs, write nothing |
| `--concurrency N` | 3 | Files in flight at once |
| `--model NAME` | `claude-haiku-4-5-20251001` | Override model |
| `--no-backup` | off | Skip `.bak` files |
| `--include-vendor` | off | Do not skip vendor/node_modules/etc. |
| `--strict` | off | Exit non-zero (2) if any block was skipped |

### End-of-run report

After the run, the script prints a summary:

```
----
files scanned:    142
blocks rewritten: 984
blocks skipped:   7

skipped blocks (left as original):
  /path/to/file.php
    [validation] function foo() - banned word: callback
  /path/to/other.js
    [claude_error] async function bar() - rc=124
```

Surface this summary to the user so they can decide whether to re-run on the skipped blocks or accept them as-is.

With `--strict`, the script returns exit code 2 when any block is skipped - useful for CI gates.

## Execution

Run the script via Bash. Always invoke with `${CLAUDE_PLUGIN_ROOT}` so the
script and its sibling perl helpers resolve regardless of the user's
working directory.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/docblock-rewrite/scripts/docblock-rewrite.sh" $ARGUMENTS
```

If `$ARGUMENTS` is empty, default to a dry-run on the current directory so
the user sees the diff before any writes:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/docblock-rewrite/scripts/docblock-rewrite.sh" . --dry-run
```

## Requirements

The script will error early if any of these are missing on the user's
machine. Surface the error verbatim - do not paper over.

- `bash` 4+
- `jq`
- `perl` (with `MIME::Base64`)
- `claude` (Claude Code CLI on `PATH`)

On Windows this runs under WSL or Git Bash, not native PowerShell. If none is available, use the `docblock-rewrite` procedure's inline engine instead (Read/Edit, no extra tools).

## What it does

1. Discovers `.php`, `.js`, `.ts`, `.jsx`, `.tsx`, `.mjs`, `.cjs` files
   under the given path.
2. Skips `vendor`, `node_modules`, `dist`, `build`, `coverage`,
   `__tests__`, `.git`, `.svn`, `.hg`, `.next`, `.nuxt`, `out`, `tmp`, plus
   `*.min.js` and `*.generated.*`, unless `--include-vendor` is set.
3. Parses each file with `extract-docblocks.pl` - emits JSON pairs of
   doc block + following declaration line.
4. For each pair, invokes `claude --print` with the prompt rules baked
   into the script. First doc block in a file is treated as file-level
   when it carries `@file`/`@package`/`@module` or precedes a
   `declare`/`namespace`/`use`/`import`/`export` line.
5. Validates each response: one line, starts with `// `, ≤100 chars,
   no banned words. Failures leave the original block intact.
6. Applies replacements via `apply-plan.pl` right-to-left so offsets
   stay valid. Renames original to `.bak` before writing.

## When to use the inline engine instead

If the user wants to rewrite just one or two files interactively, or
wants to tune the prompt before scaling up, hand off to the
`docblock-rewrite` procedure file instead - it operates inline with the model's
own Read/Edit tools, no `claude --print` subprocesses. Use this command
for 20+ files or any unattended run.

## After running

If `--dry-run` was used, summarize the diff: file count, blocks
rewritten, blocks skipped, blocks needing review.

If a real run, mention the `.bak` files and how to roll back. This restores the
most recent run's originals (`*.bak`):

```bash
find <path> -name '*.bak' -exec sh -c 'mv "$1" "${1%.bak}"' _ {} \;
```

On repeat runs the script rotates older backups to `.bak.1`, `.bak.2`, … (highest
number = oldest/true original). To roll all the way back to the pre-first-run
state, restore the highest-numbered `.bak.N` for each file instead of `*.bak`.
