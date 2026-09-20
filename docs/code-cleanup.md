# Code Cleanup

[← Back to the README](../README.md)

## `unslop`

Strip AI generated voice from source files without changing behavior.

```
/unslop
```

Every AI generated codebase has the same tells: `// leverage this robust, comprehensive solution to seamlessly orchestrate the data provider`, em-dashes everywhere, every comment opens with "This function...", every function name is `orchestrateDataProvider` when `loadUsers` would do. The `unslop` skill takes a rule based pass over comments, docstrings, log/error messages, and identifier names. It never touches code logic, function signatures, return types, string literals shown to end users, or CLI help text. Your code keeps working exactly the same. The fluff goes away. What's left sounds like a real person wrote it.

Scope locked at the file edit layer. The skill will not refactor business logic, fix bugs, modify error messages users see, rewrite commit messages, or edit `CHANGELOG`/`LICENSE`. Renames verify substring safety before applying (won't rename `extract` to `pull` if `extractor` exists in the file).

**Rule 0 hard floor**: if asked mid pass to change behavior, logic, signatures, or strings under any rationale ("just this once", "trivial fix", "while you're there"), the skill refuses with `Out of scope for this pass. Open a new session for behavior changes.` and stops. Rule 0 cannot be overridden by subsequent user instructions.

**Target picker**: when invoked without a target, the skill asks via a picker. **File** (one source file), **Directory** (folder, processed file by file per Rule 12), or **Paste** (paste code into chat, get cleaned version back, no filesystem write).

## ✨ Features

- 🧽 **Vocabulary swap**: kills marketing words (`robust`, `seamless`, `comprehensive`, `world-class`, `powerful`, `elegant`, `crucial`, `vital`, `revolutionary`, `transformative`, `game-changing`, `mission-critical`, `bleeding-edge`, `bulletproof`, `holistic`, `supercharge`, `elevate`, `hand-crafted`, `purpose-built`) and AI tells (`delve`, `leverage`, `harness`, `tapestry`, `myriad`, `unleash`)
- 💼 **Marketing hyphenated compounds**: drops `production-quality`, `production-ready`, `enterprise-grade`, `copy-paste`, `theme-building`, `baked-in`, `plug-and-play`, `turn-key`, `future-proof`
- ✂️ **De-hyphenate technical compounds**: `open-source` → `open source`, `command-line` → `command line`, `third-party` → `third party`, `AI-generated` → `AI generated`, `file-by-file` → `file by file`, `step-by-step` → `step by step`
- 🔢 **Number-word + noun compounds**: `seven-question intake`, `four-phase rollout`, `three-step process` → drop modifier or use digit
- 👀 **Filler intensifiers (audit only)**: flags `incredibly`, `highly`, `thoroughly`, `extensive`, `significantly`, `key` (adj), `fully`, `simply`, `very` for human review
- 🪞 **Empty enumeration intros (audit)**: flags `wide range of`, `a host of`, `a wealth of`, `an array of`, `a suite of`
- ➖ **Em-dash kill**: strips U+2014 / U+2013 from developer prose (comments, docstrings, logs, errors). Keeps them in CLI help text and user-facing terminal output. Leaves real number ranges alone (`pages 5-10`)
- 👥 **First-person plural**: drops `we`, `us`, `our`, `let's`. First-person singular (`I`, `my`) allowed
- 🏷️ **Function renames**: `orchestrateDataProvider` → `loadUsers`, `handleData` → `parseRequest`. Verifies substring safety before applying
- 🪢 **Padding cuts**: `in order to` → `to`, `due to the fact that` → `because`, `at this point in time` → `now`
- 🗯️ **Hedging removal**: `perhaps`, `essentially`, `fundamentally`, `at its core`, `arguably`
- 📚 **Tutorial voice**: drops `As you can see`, `Let's dive in`, `Imagine that`, `It's worth noting that`
- 🙏 **Apologetic openers**: drops `Please note`, `Keep in mind`, `Bear in mind`, `As a reminder`
- 📝 **Structure tics**: drops `This function...` / `This class...` openers, trailing wrap-up sentences that restate the docstring, decorative emojis/arrows/box-drawing in comments
- 🔁 **Restatement comments**: drops `i++; // increment i` and similar
- 🔇 **Linter-suppression markers**: flags unjustified `# noqa`, `// @ts-ignore`, `// @ts-expect-error`, `# rubocop:disable`, `//nolint`, `// eslint-disable-line`, `# pragma: no cover`, `@phpstan-ignore-line`, `@psalm-suppress`
- 📅 **Author/date stamps**: drops what `git blame` already tracks
- 🦺 **Defensive-check noise**: drops `// just in case`, `// defensive check`, `// shouldn't happen`
- 🎓 **Latin show-offs + AI Britishisms**: drops `whilst`, `amongst`, `ergo`, `vis-à-vis`
- 🧪 **Test name cleanup**: `should correctly do X` → `do X`

## 🌍 Languages covered

JavaScript, TypeScript, Python, Go, Rust, Java, C#, C/C++, Perl, Swift, Kotlin, PHP, Ruby, Elixir, Lua, SQL, PowerShell, Markdown, Shell scripts. Each language has its own ruleset section with tips for that language's comment/docstring/identifier conventions.

## 🛠️ Frameworks covered

React (+ Next.js Server Components, hooks, props), Vue (+ Nuxt composables, auto-imports), Astro (islands, content collections, view transitions), Alpine.js (`x-*` directives), Express (+ Koa, Fastify, Hono), Vite, Webpack, Rollup, esbuild, Tailwind (utility classes, `@apply`, config files), WordPress (plugins, themes, hooks, nonces, translation calls), Laravel (+ Blade, Livewire, Eloquent, migrations), Symfony (controllers, Doctrine, services, voters), Twig (Symfony/Drupal/standalone), EJS templates, `.env` files, `knexfile` database config.

## 🛡️ Safety rails

- Never changes code behavior, function signatures, return types, or string literals shown to end users
- Never touches CLI help text, README content, commit messages, license headers, CHANGELOG
- Function renames verify substring safety. won't rename `extract` to `pull` if `extractor` exists
- One pass per category. vocab swap → voice rewrites → function renames → syntax check → verification greps → human read-back. Mixing passes makes diffs unreviewable
- Falls back to "leave it and flag for human review" on ambiguous cases
- Ships with reviewer checklist and false-positive guide for when a flagged word is actually correct

## 🔄 How it works

1. **Initialization gate**: target picker fires (File / Directory / Paste) unless target already given
2. **Pass 1: read target**: full Read of the file, language detection from extension; loads relevant language + framework subsection from `references/full-ruleset.md`
3. **Pass 2: vocabulary swap**: Rule 2 (anthropomorphic + engineering jargon) and Rule 2c sections A-R in order
4. **Pass 3: voice rewrites**: first-person plural → imperative, kill tutorial voice, kill apologetic openers
5. **Pass 4: em-dash + smart punctuation**: strip U+2014/U+2013/smart quotes from developer prose
6. **Pass 5: function renames**: substring safety check, then rename across the file
7. **Pass 6: syntax check**: language-appropriate parse/lint
8. **Pass 7: verification greps**: `scripts/verify.sh` runs Rule 8 greps; all return empty when clean
9. **Pass 8: human read-back**: cadence + rhythm review (greps catch keywords, not voice)
10. **Pass 9: emit final report**: mandatory Markdown report (files touched, rename table, verification table, borderline kept, diff stats)

## 🚀 How to use it

Slash command:

```
/unslop # fires the File/Directory/Paste picker
/unslop src/auth.ts # skips picker, runs on the file
/unslop src/ # skips picker, runs on the directory
```

Requests it handles (type the command to run it - it never auto-triggers):

> *"unslop this file"*, *"deslop the repo"*, *"remove AI tells from `src/auth.ts`"*, *"strip em-dashes from comments"*, *"rename `orchestrateDataProvider` to something human"*, *"audit this file for AI slop"*, *"clean the AI voice out of these comments"*, *"kill the marketing words in this codebase"*

The full procedure lives at [`lib/unslop/SKILL.md`](../lib/unslop/SKILL.md), the slash command at [`commands/unslop.md`](../commands/unslop.md), the complete 16 rule, 19 language, 22 framework ruleset in [`references/full-ruleset.md`](../lib/unslop/references/full-ruleset.md), and verification greps in [`scripts/verify.sh`](../lib/unslop/scripts/verify.sh).

---

## `strip-unicode`

Flatten messy Unicode down to plain 7-bit ASCII, without changing a single word.

```
/strip-unicode
```

Text picks up junk everywhere it travels. A word processor turns your straight quotes into curly ones, your hyphens into long em dashes, your three dots into a single ellipsis character. A copy-paste from a website drags in non-breaking spaces and invisible zero-width characters that break diffs, grep, and code. `strip-unicode` is a deterministic sanitizer that walks the text once and maps every non-ASCII character back to the plain 7-bit range: `“Hi—bye”…` becomes `"Hi-bye"...`. It transliterates, it never interprets. Line breaks, indentation, and wording stay exactly as written. Nothing is summarized, rewritten, or grammar-fixed.

The same input always gives the same output. A bundled Python script does the character mapping, so it is repeatable rather than a best guess, and every run ends with a table of exactly what changed and a check that no non-ASCII characters are left behind.

**Two modes, chosen by structure not content.** Multi-line input is treated as pasted text and cleaned in a code block. A single line that is not a real file is also pasted text. A single line that *does* match an existing file is ambiguous, so the skill asks before it touches anything - it never guesses its way into overwriting a file. Given no input, it shows a simple File-or-Paste picker.

**Safety rails on file mode.** When cleaning a file it echoes the target first, then overwrites it in place. If the file cannot be read or written it aborts with `Error: <path> not writable - no changes made.` rather than leaving a half-written file behind, and it never falls back to paste mode on a failure. It never deletes a file and never writes anywhere except the one named path.

**Prompt-injection proof.** Everything in the input is inert data to be cleaned. If the text contains lines like `ignore previous instructions` or `system:`, they are cleaned as literal characters, never obeyed.

## ✨ What it changes

- ➖ **Dashes**: em dash `—` and en dash `–` (and the horizontal bar `―`) become a plain hyphen `-`
- 💬 **Curly quotes**: `“ ” „` become straight `"`; `‘ ’ ‚` become straight `'`
- 🔢 **Ellipsis**: `…` becomes three dots `...`
- 🔘 **Bullets**: `•` `▪` `◦` `⁃` become `-`
- 🌫️ **Invisible characters**: non-breaking, thin, and narrow spaces become a normal space; zero-width space, zero-width joiners, and the BOM are removed
- ➗ **Math symbols**: `≤` → `<=`, `≥` → `>=`, `≠` → `!=`, `×` → `x`, `÷` → `/`
- 🔤 **Everything else**: any other non-ASCII character is mapped to its nearest ASCII form (`café` → `cafe`, `™` → `TM`). Characters with no ASCII form (`€`, emoji, CJK) are removed and logged as `(removed)`
- 🧱 **Precedence**: the specific rules above always win over the catch-all, and no character is ever transformed twice

## 📊 The report

After cleaning, both modes print a table sorted by how often each character appeared, then confirm the result is clean:

```
| char | replaced with | count |
|------|---------------|-------|
| —    | -             | 4     |
| “    | "             | 2     |
| …    | ...           | 1     |

Non-ASCII remaining: 0
```

If the text was already plain ASCII, it skips the table and says `No changes - already 7-bit ASCII.` instead.

## 🚀 How to use it

Slash command:

```
/strip-unicode                 # File or Paste picker
/strip-unicode notes.md        # matches a file, so it asks File (1) or text (2) first
/strip-unicode “Hi—bye”…       # pasted text, cleaned in a code block
```

Requests it handles (type the command to run it - it never auto-triggers):

> *"strip the unicode from this"*, *"convert this to plain ASCII"*, *"remove the smart quotes"*, *"replace the em dashes"*, *"clean the zero-width characters out of this"*, *"normalize this text to ASCII"*

The full procedure lives at [`lib/strip-unicode/SKILL.md`](../lib/strip-unicode/SKILL.md), the slash command at [`commands/strip-unicode.md`](../commands/strip-unicode.md), and the deterministic transliteration script at [`scripts/strip_unicode.py`](../lib/strip-unicode/scripts/strip_unicode.py).

---

## `readme-emoji`

Clean the feature list in a Markdown README: strip the leading emoji off each feature bullet, turn a short label dash into a colon, and remove the en dashes and em dashes from those bullets entirely. Every other byte of the file comes back exactly as it went in.

```
/strip-emoji
```

Feature lists collect decoration. A rocket in front of every bullet, an em dash doing the work a colon should do, an en dash range that a find-and-replace would flatten into nonsense. The `readme-emoji` skill does one pass over the feature section and nothing else - headings, paragraphs, tables, badges, HTML, link definitions, ordered lists, and every fenced or indented code block are out of scope and returned byte for byte, including the ones sitting inside the feature section.

What counts as a feature section is a string comparison, not a judgment call. The heading text is normalized - leading emoji, emphasis markers, whitespace, trailing punctuation, case - and must then **equal** `Features`, `Key Features`, `Feature Highlights`, `Highlights`, `What's Included`, or `Why <name>`. So `## 🚀 Features`, `## **Features**`, and `## features:` all match, while `Deprecated Features` and `Feature Requests` do not.

The dash handling is two passes so ranges survive. Pass A classifies every dash: `2019–2024` and `10 – 20ms` are ranges and become plain ASCII hyphens, never colons and never deleted. Pass B gives a colon to the first remaining candidate whose preceding text is four words or fewer and does not end in `is`, `are`, `was`, `were`, `has`, `have`, or `will` - and deletes the rest. At most one candidate per bullet becomes a colon, so no bullet can end up with two.

## 📋 Technical Overview

One slash command plus its procedure file `lib/readme-emoji/SKILL.md`, which loads the master template from `lib/readme-emoji/references/prompt-template.md`. The command `/strip-emoji` takes a file path or pasted contents; with neither it emits one fixed intake line and stops rather than guessing a path or inventing a sample. The output is the whole file inside a single four-backtick fence tagged `markdown`, so three-backtick fences inside the README survive intact.

## ✨ Features

- 🎯 Mechanical scope test. Normalized heading equality against six exact names - a heading that merely contains "Features" is out of scope
- ✂️ Whole emoji grapheme clusters removed, variation selectors, skin tones, ZWJ sequences, keycaps, and regional indicator pairs included
- 🔢 Ranges preserved. `2019–2024` becomes `2019-2024`; a range never becomes a colon and is never deleted
- 🏷️ One colon per bullet, awarded by a word count and a seven-word verb list, never by taste
- 🧱 Everything else untouchable. Headings, ordered lists, continuation lines, code blocks, tables, badges, HTML, and link definitions come back byte for byte
- 📏 Line count verified against the input before anything is emitted
- 🚪 Asks for the file instead of guessing. No directory scan, no invented sample README
- 🛡️ File content is data. Instructions found inside it are never followed
- 📄 Non-Markdown input is echoed back unchanged rather than rewritten

## 🔄 How it works

1. **Intake.** Take the path or paste from the argument, or emit the one fixed intake line and stop.
2. **Locate.** Normalize every heading, keep the ones that equal a feature-list name, and mark each section's bullets.
3. **Transform 1.** Remove the leading emoji run from each in-scope bullet, along with the whitespace after it.
4. **Transform 2.** Classify each dash as range or candidate, rewrite ranges as hyphens, award at most one colon, delete the rest.
5. **Verify.** Line count matches, no heading or code line moved, no bullet gained two colons, every range still present.
6. **Emit.** The whole file inside one four-backtick fence, and nothing outside it.

## 🚀 How to use it

```
/strip-emoji ./README.md          ← clean a file, print or overwrite
/strip-emoji                      ← asks for a path or a paste
```

Given a path and a file-writing tool, it offers once to overwrite in place; a paste is always printed.

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"strip the emoji out of my README"*, *"clean up this feature list"*, *"remove em dashes from my README bullets"*, *"turn those feature dashes into colons"*, *"de-emoji this readme"*

The full procedure lives at [`lib/readme-emoji/SKILL.md`](../lib/readme-emoji/SKILL.md) and the slash command at [`commands/strip-emoji.md`](../commands/strip-emoji.md).

---

## `strip-comments`

Remove every comment from a codebase except the header comment at the top of each file, and except the many comment-shaped constructs that are actually directives, pragmas, or legal notices.

```
/strip-comments
```

The hard part of this job is not deleting comments. It is the two silent failure modes. Delete a load-bearing pragma - `//go:build`, `# type: ignore`, `/*#__PURE__*/`, a `webpackChunkName` hint - and the build quietly changes with no test to catch it. Delete something that only looked like a comment because it sat inside a URL, a string, a regex, or a heredoc, and the code breaks, sometimes only at runtime. The `strip-comments` skill defends against both with a preserve list and a mandatory preview.

Nothing is written before you have seen a diff and approved it. That holds on every batch - approval on one is not approval on the next - and it holds regardless of how the request is phrased. Before enumeration even starts, the skill checks that the work is on a branch, that the tree is clean, and that the project is under version control at all, saying which check failed rather than proceeding on its own judgment.

Three bundled scripts do the mechanical parts. `find-candidates.sh` enumerates eligible files, honouring `.gitignore` and excluding dependency directories, build output, lockfiles, minified bundles, and generated files. `syntax-check.sh` parse-checks every modified file with that language's own parser and reports `SKIP` where the checker is absent. `audit-remaining.sh` classifies each surviving comment-like line as `HEADER`, `KEEP`, or `FLAG`, and exits non-zero while any `FLAG` is unresolved - it over-reports on purpose.

Python docstrings are treated as what they are: executable string expressions, not comments. They are kept by default, and when removal is explicitly requested the skill still keeps any docstring consumed at runtime by `argparse`, `click`, FastAPI, or `doctest`, and replaces a docstring that is a function's only body with `pass` rather than producing a syntax error.

## 📋 Technical Overview

One slash command plus its procedure file `lib/strip-comments/SKILL.md`, with two reference files and four bundled scripts under the same folder. The command `/strip-comments` collects scope, languages, and batching, then asks about docstrings and markup comments only when those file types actually turn up. Comment removal only: no formatter, no linter autofix, no rename, no reorder, no import cleanup.

## ✨ Features

- 🛑 Preview and approval before any write, on every batch - never a first-run surprise on an unfamiliar codebase
- 🧷 Safety gate first. On a branch, clean tree, under version control, or it says which check failed and stops
- 📜 A full preserve catalogue. Shebangs, directive prologues, type-checker and linter directives, coverage and bundler hints, licence and copyright headers, SPDX identifiers, `/*! */` blocks, language pragmas, generated-file markers, Python comment-form type annotations
- 🔎 No regex sweeps. Comment syntax inside strings, URLs, regexes, and heredocs is read in context, not pattern-matched
- 🐍 Docstrings understood, not lumped in with comments - runtime-consumed ones survive even when removal is requested
- 🧪 Verification required. Parse-check plus a comment audit, with every `FLAG` resolved and every `SKIP` listed before anything is called done
- 📦 Batching by directory or language on anything over roughly 50 files, so a mistake stays cheap to isolate
- 🎨 Templates covered. `<script>` and `<style>` blocks inside `.vue`, `.svelte`, `.astro`, `.ejs`, `.hbs`, `.html`, and `.blade.php`
- 🚪 Markup comments opt-in. HTML, Blade, Handlebars, Jinja, and Markdown of any kind are out of scope unless asked for
- 🚩 Ambiguity flagged with a file and line, never resolved quietly

## 🔄 How it works

1. **Gate.** Branch, clean tree, version control. Stop and name the failure if any check fails.
2. **Enumerate.** `find-candidates.sh` builds the eligible file list; present it before touching anything.
3. **Read.** Per language, find where the header ends, which comment-like lines must survive, and which apparent comments are inside data.
4. **Preview.** Proposed changes grouped by file, diff only, then stop and wait.
5. **Apply.** The approved batch, preserving indentation, blank-line structure, and untouched trailing whitespace.
6. **Verify.** `syntax-check.sh`, then `audit-remaining.sh`, then the project's own tests and build.
7. **Report.** Files changed, lines removed, files skipped and why, constructs preserved, every ambiguous case located.

## 🚀 How to use it

```
/strip-comments src/              ← scope passed in, confirmed at intake
/strip-comments src/ python only  ← scope plus a language hint
/strip-comments                   ← full intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"strip the comments out of this codebase"*, *"remove all comments but keep the header"*, *"delete the commented-out code"*, *"clean up comments in src/"*, *"remove inline comments"*, *"clear out the stale TODOs"*

The full procedure lives at [`lib/strip-comments/SKILL.md`](../lib/strip-comments/SKILL.md) and the slash command at [`commands/strip-comments.md`](../commands/strip-comments.md). Its preserve catalogue is at [`lib/strip-comments/references/preserve-list.md`](../lib/strip-comments/references/preserve-list.md) and the per-language notes at [`lib/strip-comments/references/language-notes.md`](../lib/strip-comments/references/language-notes.md).
