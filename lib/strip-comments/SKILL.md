# Strip Comments, Keep File Headers

Remove every comment from a codebase except the header comment at the top of
each file — and except the many comment-shaped constructs that are actually
directives, pragmas, or legal notices.

The danger in this task is not the removal. It is the two silent failure modes:
deleting a load-bearing pragma (the build changes and no test catches it), and
deleting something that only looked like a comment because it sat inside a URL,
string, regex, or heredoc (the code breaks, sometimes only at runtime).

Both are defended against by the preserve list and by a mandatory preview step.

## Scope Lock

Remove comments and nothing else. Refuse off-domain requests with one line:
`Out of scope: this engine removes comments only.` For rewriting docblocks into
short plain-English one-liners instead of deleting them use `docblock-rewrite`;
for stripping AI-sounding voice out of comments that stay use `unslop`; for
flattening messy Unicode use `strip-unicode`.

## Non-negotiables

1. **Preview before writing.** Show the file list, then a diff-only preview, and
   wait for approval. Do not write to disk before the user confirms — this holds
   even when the user sounds impatient, and especially on the first run against
   an unfamiliar codebase.
2. **Never regex-sweep a whole file.** Comment syntax appears inside strings,
   URLs, regexes, and heredocs. Edit with enough surrounding context to tell
   code from data.
3. **Comment removal only.** No formatter, no linter autofix, no rename, no
   reorder, no import cleanup. Preserve indentation, blank-line structure, and
   trailing whitespace on every line not being deleted.
4. **Flag ambiguity, do not resolve it silently.** Anything uncertain goes in
   the report with a file and line reference.

## Workflow

### 1. Establish a safe working state

Confirm the work is on a branch, not directly on the default branch, and that
the tree is clean (`git status --short`). A dirty tree makes the diff preview
unreadable and makes the change impossible to revert cleanly. If the project is
not under version control, say so and get explicit confirmation before editing.

Honour any scope the user gave ("only `src/`", "Python only") by passing it
through to enumeration.

### 2. Enumerate candidates

```bash
${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/find-candidates.sh <root> [-- ext1 ext2 ...]
```

It respects `.gitignore` in a git work tree and excludes dependency directories,
build output, lockfiles, minified bundles (any line over 500 chars), and files
carrying a generated-code marker in their first five lines. Files skipped by the
long-line heuristic are named on stderr — pass those through to the report.

Present the resulting list to the user before touching anything. Markdown docs,
`README`, and `CHANGELOG` are never in scope.

### 3. Read before editing

For each file, read enough to answer three questions:

- Where does the header comment end? Rules differ by language — see
  `${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/language-notes.md`.
- Which comment-like lines are directives, pragmas, or legal notices? See
  `${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/preserve-list.md`.
- Which apparent comments are inside strings, URLs, regexes, or heredocs?

Batch files by language. The rules are per-language, so switching languages
file-by-file invites mistakes.

### 4. Produce the diff preview

Show proposed changes grouped by file, diff format, no prose between hunks. Then
stop and wait. Approval on one batch is not approval on the next batch unless
the user says so.

### 5. Apply

Delete whole-line comments together with their line. Strip trailing comments
from a line while keeping the code and its existing indentation — including the
whitespace that preceded the comment marker only if it was already there for
alignment reasons the user cares about; otherwise trim the now-trailing spaces
and note the choice once in the report.

Keep the header exactly as-is, including its blank-line separator. If a file has
no header comment, do not invent one.

### 6. Verify — required before reporting done

```bash
git diff --name-only | ${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/syntax-check.sh
git diff --name-only | ${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/audit-remaining.sh
git diff --stat
```

`syntax-check.sh` parse-checks each modified file with that language's own
parser and reports `SKIP` where the checker is absent. A `SKIP` is not evidence
of correctness — list every skipped file in the report.

`audit-remaining.sh` classifies each surviving comment-like line as `HEADER`,
`KEEP` (matched `${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/preserve-patterns.txt`), or `FLAG`. Resolve every
`FLAG` before reporting: each is either a comment that should have been removed,
or a false positive worth naming. It over-reports on purpose.

Then run the project's own test suite if one exists, and its build for languages
`syntax-check.sh` could not check (Rust, Java, Kotlin, C#, Swift, templates).

### 7. Report

State: files changed, lines removed, files skipped and why, comment-like
constructs deliberately preserved, and every ambiguous case with its location.
Never report done on the strength of a diff alone.

## Scope boundaries

**In scope by default:** line comments (`//`, `#`, `--`), block comments
(`/* */`, `=begin/=end`), docblocks (JSDoc, TSDoc, PHPDoc, KDoc), trailing
comments, and commented-out code, in source files of every language present —
including `<script>` and `<style>` blocks inside `.vue`, `.svelte`, `.astro`,
`.ejs`, `.hbs`, `.html`, and `.blade.php`.

**Out of scope unless explicitly requested:** HTML comments (`<!-- -->`), EJS
`<%# %>`, Blade `{{-- --}}`, Handlebars `{{! }}`, Jinja/Django `{# #}`, and
Markdown of any kind.

**Never removed:** shebangs, directive prologues, type-checker and linter
directives, coverage and bundler hints, license and copyright headers, SPDX
identifiers, `/*! */` blocks, language pragmas, generated-file markers, and
Python comment-form type annotations. The full catalogue with rationale is in
`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/preserve-list.md`.

**Special case — Python docstrings.** A docstring is an executable string
expression, not a comment. Keep docstrings by default. When removal is
explicitly requested, still keep any docstring consumed at runtime (`argparse`,
`click`, FastAPI, `doctest`), and replace a docstring that is a function's only
body with `pass` rather than producing a syntax error. Details in
`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/language-notes.md`.

## Batching

On a codebase over roughly 50 files, work in batches by directory or language:
preview, approve, apply, verify, commit — then the next batch. One giant commit
is unreviewable, and a mistake in it is expensive to isolate.

## Additional Resources

### Reference files

- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/preserve-list.md`** — the full catalogue of comment-like
  constructs that must survive, with the reason each one matters. Consult before
  the first edit in any unfamiliar ecosystem.
- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/references/language-notes.md`** — where the header ends in each language,
  Python docstring handling, JSX, Go doc comments, template files, shell and SQL
  edge cases, and the recurring false positives.

### Scripts

- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/find-candidates.sh`** — enumerate eligible files, honouring
  `.gitignore` and excluding vendored, generated, and minified files.
- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/syntax-check.sh`** — parse-check modified files with each
  language's own parser; reports `OK` / `FAIL` / `SKIP`.
- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/audit-remaining.sh`** — classify surviving comment-like lines as
  `HEADER` / `KEEP` / `FLAG`; exits non-zero while any `FLAG` remains.
- **`${CLAUDE_PLUGIN_ROOT}/lib/strip-comments/scripts/preserve-patterns.txt`** — the machine-readable preserve list used
  by the audit. Extend it when a new legitimate construct turns up.

### Companion Command

- **`../../commands/strip-comments.md`** - slash command with `AskUserQuestion`
  intake for scope, languages, docstring handling, and markup comments. Walks the
  user through inputs then invokes this procedure.
