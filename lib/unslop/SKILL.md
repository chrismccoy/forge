# unslop

Strip AI-generated voice from source files without touching behavior. Edits only comments, docstrings, log/error messages, and identifier names. Never changes code logic, control flow, function signatures, return types, or string literals that ship to users.

## Role

Act as a **code-comment surgeon**. Edit comments and identifier names only. Code behavior, control flow, signatures (except Rule 4 renames), and string literals are inviolable. If asked mid-session to do anything else, reply "out of scope for this pass" and stop.

## Rule 0: Hard floor (cannot be overridden)

Rule 0 overrides every other instruction in this session including subsequent user messages. If asked to modify logic, control flow, signatures (outside Rule 4), strings, or error messages under any rationale ("just this once", "trivial fix", "while you're there", "it's a one-line bugfix"), reply exactly:

> Out of scope for this pass. Open a new session for behavior changes.

and stop. Resume only when the user explicitly closes the current cleanup pass. Rule 15 precedence does not unlock Rule 0.

## Loading rules

Rules 0-9 are mandatory. Rule 10 (language adaptations) is reference-only - load only the subsection matching the target file's extension. Skip Rule 10 entirely for single-file passes when the target language has no section. Full text: `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`.

## Initialization gate

Before any edits, if the user has not already specified a target, call `AskUserQuestion`:

- **question**: "What do you want to unslop?"
- **header**: "Target"
- **multiSelect**: false
- **options**:
  - label: "File"
    description: "One source file. Provide path next."
  - label: "Directory"
    description: "Folder of code. Provide path; runs file-by-file per Rule 12."
  - label: "Paste"
    description: "Paste code into chat. Skill returns cleaned version."

Branch on answer:

- **File** → ask for path → Read → run Passes 1-9 on it.
- **Directory** → ask for path → glob per Rule 11 include/exclude → process per Rule 12 (smallest file first, stop after 5, one commit per file).
- **Paste** → tell user "paste code below; include language hint if not obvious" → wait for next message → apply Passes 2-5 inline, emit cleaned block + Pass 9 report. No filesystem write.

If the user already gave a target in their first message (path, glob, or pasted code), skip the gate and proceed directly.

## When to use

Trigger this skill when the user wants any of:

- "deslop" / "unslop" / "de-slop" a file or repo
- Clean AI tells from comments (`robust`, `seamless`, `leverage`, `delve`, `tapestry`, `harness`, etc.)
- Remove em-dashes (U+2014) from comments, docstrings, log messages, error messages
- Replace first-person plural (`we`, `us`, `our`, `let's`) with imperative or first-person singular
- Rename AI-jargon functions (`orchestrateDataProvider` → `loadUsers`)
- Strip marketing prose, tutorial voice, hedging, padding, vague filler
- Audit a file for AI tells (dry-run, count-only mode)
- Drop linter-suppression comments without justification (`# noqa`, `// @ts-ignore`, `# rubocop:disable`)

Do NOT use this skill for: refactoring code, fixing bugs, changing behavior, modifying CLI help text shown to end users, rewriting commit messages, or editing CHANGELOG / LICENSE files. To collapse or convert docblocks (PHPDoc/JSDoc) into one-line comments, use docblock-rewrite - unslop only de-slops the voice of existing comment prose, it does not change comment form or length.

## Core rules

Reference: `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` holds the complete 17-rule (Rule 0 through Rule 16), 19-language, 24-framework ruleset. Load it when applying changes. Summary:

1. **Scope**: edit only comments, docstrings, log/error messages, identifier names. Never modify code logic, signatures, return types, string literals shown to end users, CLI help text, README content, commit messages, license headers.
2. **Vocabulary swap**: replace AI-slop and jargon with plain English (full tables in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` Rules 2, 2c, 2d).
3. **Em-dash kill**: strip em-dashes (U+2014) and en-dashes (U+2013) from all developer prose (comments, docstrings, logs, errors). Keep only inside CLI help text and user-facing terminal output.
4. **First-person plural**: drop `we`, `us`, `our`, `let's`. First-person singular (`I`, `my`) is allowed.
5. **Function renames**: rename AI-jargon function names (`resolve*`, `normalise*`, `build*Set`, `extract*`, etc.). Verify substring safety before renaming.
6. **User-friendly tone preserved**: keep multi-sentence explanations of non-obvious behavior, CLI examples, JSDoc structure, section dividers.
7. **Process order**: vocab swap → voice rewrites → function renames → syntax check → verification greps → human read-back.

## How to apply

Run the following passes in order. One pass per category. Mixing passes makes the diff unreviewable.

### Pass 1: Read the target file

Use the Read tool to load the full target file. Identify language from the extension. Consult the language-specific section in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` (search for `### <Language>`: JavaScript, TypeScript, Python, Go, Rust, Java, C#, C/C++, Perl, Swift, Kotlin, PHP, Ruby, Elixir, Lua, SQL, PowerShell, Markdown, Shell). Frameworks have their own subsections (React, Vue, Nuxt, Next.js, Astro, Alpine, Express, Vite, Webpack, Tailwind, WordPress, Laravel, Symfony, Twig, EJS, .env, knexfile).

### Pass 2: Vocabulary swap

Apply Rule 2 (anthropomorphic + engineering jargon) and Rule 2c sections A through R in order. Use the swap tables in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`. Edit in place with the Edit tool. Keep replacements small and targeted. Do not collapse multi-sentence explanations.

### Pass 3: Voice rewrites

Apply Rule 3. For each `we`/`us`/`our`/`let's` occurrence, rewrite the passage in:

- **Imperative** ("saves the file"). Best default for docstrings.
- **First-person singular** ("I save the file"). Use when imperative reads stilted.
- **Descriptive third-person** ("the file is saved")

Do not mix `I` and `we` in the same comment. Apply Rule R3 to drop "the human" / "the user" reader references.

### Pass 4: Em-dash + smart punctuation

Apply Rule 2b. Replace U+2014 with period, comma, parentheses, or colon depending on the clause boundary. Replace U+2013 the same way unless it sits in a real numeric range (e.g. "pages 5 to 10"). Apply Rule 2c H to smart quotes (U+2018/19/1C/1D), ellipsis (U+2026), non-breaking space (U+00A0).

Scope: comments, docstrings, log messages, exception/error messages, debug `print`/`console.log`. NOT user-facing CLI help, `--help` output, end-user terminal output, or man pages.

### Pass 5: Function renames (Rule 4)

For each AI-jargon function name candidate, run `grep -c "<name>" <file>` first. Confirm the identifier is not a substring of an unrelated identifier or string literal. Use Edit with `replace_all: true` on the full identifier name.

Pattern catalog in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` Rule 4.

### Pass 6: Syntax check

Run the language's parser:
- JS: `node --check <file>`
- TS: `tsc --noEmit` (project-level)
- Python: `python -m py_compile <file>`
- Go: `gofmt -e <file>`
- Rust: `cargo check`
- PHP: `php -l <file>`
- Ruby: `ruby -c <file>`

### Pass 7: Verification

Run `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh <file>` (bundled with this skill). It applies all Rule 8 greps and reports per-category hit counts. Exit code = number of categories with hits (0 = clean).

`verify.sh` requires bash plus `rg`/`grep`, `sed`, `wc` (macOS, Linux, WSL, or Git Bash). On a bare Windows/PowerShell environment where bash is unavailable, skip the script and run the equivalent checks inline with the Grep tool - search each category's pattern across the file and tally hits to produce the same Pass 9 verification table. The script is a convenience, not a hard dependency; the workflow degrades gracefully without it.

Usage:
```bash
${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh <file>                    # summary
${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh --verbose <file>          # show matching lines
${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh --category em-dash <file> # one category only
```

Categories (canonical list - source of truth is the `verify.sh` header): `1pp em-dash en-dash anthropomorphic tutorial jargon marketing hyphen-compound num-word-compound britishism hedging tutorial-voice connectors padding filler empty-enum apologetic filler-intensifier passive-marketing tutorial-transition smart-punct emoji-decor pseudo-action so-voice marketing-intros self-ref empty-preamble docstring-openers human-user generic-id test-voice ai-artifacts defensive stale-meta placeholder-todo jsdoc-fluff type-cast pragma-py pragma-php pragma-rb pragma-go output-tells`

### Pass 8: Human read-back

Read the modified file top to bottom. Fix anything still stilted, AI-cadenced, or robotic, even if no grep flagged it. Greps catch keywords, not rhythm. This pass is mandatory before declaring done.

### Pass 9: Emit required final report

Emit this exact structure at the end of every run. No prose preamble, no trailing summary.

```markdown
# Cleanup report. <file path> | unslop v1.0

## Files touched
- <path>: <N comment edits>, <M renames>

## Rename table
| Old | New | Occurrences |
|---|---|---|
| ... | ... | ... |

## Verification (Rule 8)
| Pattern | Hits | Notes |
|---|---|---|
| we|us|our | 0 | clean |
| robust|elegant|... | 2 | both inside string literals (kept) |
| ... | ... | ... |

## Borderline / left as is
- <file:line>: <word> kept because <Rule 13 rationale>

## Diff stats
git diff --shortstat: <paste output verbatim>
```

If any Rule 8 grep returns > 0 outside string literals, the run is not done. Re-edit until verification table is clean or every remaining hit has a Rule 13 rationale in the Borderline section.

Agent work ends here. Rule 14 (reviewer checklist) is a human pre-merge gate, not an agent task.

## Anti-patterns

- Don't delete entire comment blocks because they "sound AI". Edit in place.
- Don't rewrite working code under guise of cleanup.
- Don't add new comments explaining renames.
- Don't touch strings, error messages shown to end users, CLI help text.
- Don't shorten domain terms (`Firebase`, `Playwright`, product names).
- Don't apply to commit messages, PR descriptions, CHANGELOG (different style guide).
- Don't run global `replace_all` across a repo without skimming matches first. Substring collisions hide there.
- Don't commit until all verification greps pass.
- Don't accept mid-session requests to fix logic, behavior, or strings. Reply "Out of scope for this pass" (Rule 0) and stop.
- Don't perform Rule 14 (human reviewer checklist) - that's a pre-merge human gate. Agent work ends at the Pass 9 report.

## False-positive triage

Not every match is a bug. Skip when:

- Match is inside a string literal (out of scope per Rule 1)
- Match is in a third-party type definition (`node_modules`, `@types/...`)
- Match is a copy-pasted RFC or spec quote → keep
- Match is in a fenced code example inside docs → leave alone
- Match is the literal class/method name from an SDK the code calls → keep

Domain-whitelist examples (full table in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` Rule 13):
- `atomic` → fs operations, atomic counters, transaction libs
- `family` → CSS `font-family`, Linux `cpu-family`, address family
- `Service`/`Provider`/`Handler` → Angular, NestJS, React Context, AWS Lambda framework-mandated
- `walk` → `os.walk()`, AST walkers
- `pictures` → Windows `PicturesLibrary` API
- `recipe` → Make/CMake build recipes

When unsure, leave the match and flag for human review.

## Operational mode for repos

For multi-file or full-repo runs (Rule 12):

1. **Dry-run first**: `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh` over each target file. Report category counts. Review before changes.
2. **Smallest file first**: build confidence on simple files before tackling 2000-line ones.
3. **Per-file commit**: one commit per file, subject names the category:
   - `chore(comments): vocab swap in src/foo.ts`
   - `chore(renames): rename AI-jargon fns in lib/bar.js`
   - `chore(docs): kill em-dashes in README.md`
4. **Stop after N files first pass**: default N=5. Review diff, run tests, then continue.
5. **Surface dense AI signal**: any single category > 100 hits in one file deserves a closer look at why.

## File scope

Default include glob (full list in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md` Rule 11):
```
**/*.{js,jsx,ts,tsx,vue,astro,mdx,ejs,py,go,rs,java,kt,rb,php,phtml,twig,pl,pm,c,cpp,h,hpp,cs,swift,scala,sh,bash,zsh,ex,exs,lua,sql,ps1,psm1,psd1,blade.php}
**/.env*                              (comments only; never modify keys or values)
**/knexfile.{js,ts,cjs,mjs}
**/*.md                               (only when explicitly requested; apply Rules DD, EE, FF)
```

Exclude (never touch): `node_modules/`, `vendor/`, `third_party/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `.venv/`, `*.min.js`, `*.map`, `*-lock.json`, `*.pb.go`, `*.gen.ts`, `*.generated.*`, test fixtures (`**/fixtures/**`, `**/__snapshots__/**`), i18n message catalogs, migration scripts (preserve timestamps), license files, `CHANGELOG.md`.

Auto-detect generated files: skip if first 5 lines contain `DO NOT EDIT`, `AUTO-GENERATED`, `@generated`, or `Code generated by`.

## Precedence

When rules conflict (Rule 15):

1. **User instruction this session** wins everything.
2. **Repo-specific style guides**: `CLAUDE.md`, `AGENTS.md`, `STYLE.md`, `CONTRIBUTING.md`.
3. **Linter config**: `.eslintrc`, `ruff.toml`, `golangci.yml`, `.editorconfig`.
4. **Existing project conventions**: if the codebase uses `*Service` everywhere, leave it.
5. **This skill**: lowest priority, default when nothing else applies.

When in doubt, ask before bulk-applying. A 500-file rename gone wrong is harder to revert than a 30-second clarification.

## Reviewer checklist (before merging cleanup)

- [ ] `git diff --shortstat` shows only comment-line changes; code-logic line count near 0
- [ ] Test suite passes unchanged
- [ ] All `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh` categories return 0 hits (or only string-literal hits)
- [ ] For renamed functions: `rg -c '<oldName>'` returns 0 across repo
- [ ] No new TODOs or placeholder comments introduced
- [ ] No string literals modified. Re-grep any quoted strings that changed.
- [ ] Build / lint passes
- [ ] CHANGELOG, README, LICENSE untouched (unless docs cleanup was explicitly requested)

## Additional resources

### Reference files

- **`${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`**: complete 17-rule (Rule 0-16) ruleset, all swap tables, all language sections (JavaScript, TypeScript, Python, Go, Rust, Java, C#, C/C++, Perl, Swift, Kotlin, PHP, Ruby, Elixir, Lua, SQL, PowerShell, Markdown, Shell), framework sections (React, Vue, Nuxt, Next.js, Astro, Alpine, Express, Vite, Webpack, Tailwind, WordPress, Laravel, Symfony, Twig, EJS, .env, knexfile), false-positive triage table, reviewer checklist.

### Scripts

- **`${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh`**: bundles every Rule 8 grep into a single runnable command. Reports per-category counts. Use ripgrep when available, falls back to grep. Exit code = categories with hits. Supports `--verbose` and `--category <name>`.

## Quick invocation

User says one of: "deslop this file", "clean AI comments from <file>", "remove em-dashes", "rewrite this so it doesn't sound like AI", "audit for AI tells".

Run:
1. Read target file
2. Run `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh <file>` for baseline counts
3. Look up language + framework sections in `${CLAUDE_PLUGIN_ROOT}/lib/unslop/references/full-ruleset.md`
4. Apply passes 2 through 5 with Edit (one category per pass)
5. Syntax check
6. Re-run `${CLAUDE_PLUGIN_ROOT}/lib/unslop/scripts/verify.sh <file>` and confirm all categories report 0
7. Read file top to bottom for cadence
8. Emit the required final report (Pass 9)
