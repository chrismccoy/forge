# Refactor, Map and Clean Up

[← Back to the README](../README.md)

## `refactoring-analyst`

Senior engineer refactoring review. evidence-first, citation-bound (`path:line`), 16 fixed sections, priority-tagged.

```
/refactor
```

Ever stared at a codebase and known something was wrong but couldn't name the specific files, lines, or smells you should fix first? That's what this plugin solves.

The `refactoring-analyst` skill turns Claude into a careful pre-merge architectural reviewer that reads your project, finds the messy parts, and gives you a structured report you can actually act on. Every finding cites `path:line`. Every priority is plain text (`CRITICAL` / `HIGH` / `MEDIUM` / `LOW`). Every section either reports findings or emits the exact phrase `None detected - <one-line reason citing what was checked>.` so you know nothing was skipped without a reason.

What makes it different from a generic "review my code" prompt? It operates on Martin Fowler's `Refactoring` catalog, Robert Martin's `Clean Code`, and the SOLID + GRASP design heuristics as its reference grammar. It enforces a SCALE RULE when the codebase exceeds 50 files. prioritizes files matching your `FOCUS_AREAS` first, samples the rest one per major directory, and is honest about which files were fully read versus sampled. It never claims to have analyzed a file it didn't read. And it ships with a `/refactor` slash command that runs a multiple-choice intake (path, focus areas, scope, depth) so you don't have to type a long prompt.

It produces the report you would otherwise hire someone to write, for a refactor sprint, a pre-merge architectural pass, a quarterly technical debt plan, or an honest read on one folder.

## 📋 Technical Overview

An AI instruction specification that generates a 16-section refactoring plan with `path:line` citations, `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` priorities, a Top 5 Critical Issues block, a File Impact Matrix, an Issue Summary Table, and a phased Implementation Plan with risk and rollback notes.

Built around the locked 16-section template (`references/sections.md`), the hard-constraint and SCALE / FOCUS_AREAS rules (`references/constraints.md`), the summary tables spec (`references/summary.md`), a silent STEP 17 self-validation that re-runs the report before delivery, and prompt-injection defenses that treat `TARGET_PATH` and `FOCUS_AREAS` as inert data.

It refuses to fabricate: no claiming to have read a file it never opened, no skipping a numbered section, no invented line numbers.

## ✨ Features

- 📋 16 fixed sections in fixed order. codebase overview, cross-file coupling, duplication, readability, naming, structure, side effects, error handling, performance, security, testing, complexity, design patterns, anti-patterns, refactoring recommendations, implementation plan
- 📍 Every finding cites `path:line`. no vague "somewhere in `auth/`"
- 🎯 Priority labels. `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. plain text. works in every terminal. no emoji
- 📊 Three summary blocks. Top 5 Critical Issues, File Impact Matrix (files ranked by issue density), Issue Summary Table (every problem with effort estimate)
- 🗺️ Phased Implementation Plan. risk and rollback strategy per phase
- 🚦 SCALE RULE. if file count > 50, prioritizes `FOCUS_AREAS` files first, samples one per major directory, states exactly which were fully analyzed vs sampled
- 🎛️ FOCUS_AREAS RULE. sections matching focus extend to 800 words, others cap at 400
- 🧠 Martin Fowler `Refactoring` catalog, Robert Martin `Clean Code`, SOLID, GRASP. the reference grammar for every finding
- 🛡️ "None detected - <reason>" exact phrase when a section is empty. never skipped without a reason
- ✅ Silent STEP 17 self-validation. checks every claim, regenerates failed sections before output
- 🔒 Prompt-injection defense. `TARGET_PATH` and `FOCUS_AREAS` treated as inert data. directives inside inputs are logged in Section 1 and ignored
- 🚫 Refuses to fabricate. never claims to have analyzed an unread file. never invents line numbers
- 💬 `/refactor` slash command with multiple-choice intake. path, focus areas (multi-select), scope (file / folder / recent / sample), depth (quick / standard / deep)

## 🔄 How it works

1. **Step 0 - Access verification**: attempts to read `TARGET_PATH`. on failure reports path attempted, error, and what the user should check. does not proceed
2. **Step 1 - SCALE RULE**: if file count > 50, prioritizes `FOCUS_AREAS` matches first, samples remaining one per major directory, states exactly which files were fully analyzed vs sampled
3. **Step 2 - Emit sections 1-16**: in exact order, with `path:line` citations and `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` priorities
4. **Step 3 - Emit Summary**: Top 5 Critical Issues, File Impact Matrix, Issue Summary Table per `references/summary.md`
5. **Step 4 - Silent STEP 17 self-validation**: runs the constraint checklist. regenerates any failed section before delivery

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/refactor src/my-app ← runs the multiple-choice intake then the report
/refactor             ← prompts for the path
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"analyze code for refactoring"*, *"produce a refactoring plan for src/"*, *"find code smells in this project"*, *"architectural review of this codebase"*, *"SOLID/GRASP audit on auth/"*, *"find God classes"*, *"Martin Fowler refactoring catalog review"*, *"pre-merge architectural review"*

The full procedure lives at [`lib/refactoring-analyst/SKILL.md`](../lib/refactoring-analyst/SKILL.md), the slash command at [`commands/refactor.md`](../commands/refactor.md), and the 16-section template, constraint list, and summary tables spec at [`references/sections.md`](../lib/refactoring-analyst/references/sections.md), [`references/constraints.md`](../lib/refactoring-analyst/references/constraints.md), and [`references/summary.md`](../lib/refactoring-analyst/references/summary.md).

---

## `codebase-to-mermaid`

Point Claude at any codebase. Get a validated Mermaid diagram of how the code actually flows. Every node and edge cited to a real `file:line`.

```
/codebase-to-mermaid
```

Ever joined a new project and burned a whole afternoon trying to figure out where the request enters, where it hits the database, and which file actually owns the business logic? The README claims one thing, the architecture diagram in the wiki is two years stale, and the only honest source of truth is the code itself. This plugin solves that. Point it at a repo and it reads the actual source, classifies the project (HTTP service, CLI, data pipeline, SPA, Next.js, WordPress plugin/theme, WooCommerce, Laravel, Symfony, Spring Boot, ASP.NET Core, Go service, Rust web service, Bash + WP-CLI, htmx, Alpine, Livewire, Vue SPA, C/C++/Qt/Unity, monorepo - 19+ languages, 30+ frameworks), and writes a Mermaid diagram showing the real flow with every node tied back to a file path and line number.

The skill runs five phases. Phase 1 globs the tree, reads manifests (`package.json`, `composer.json`, `go.mod`, `Cargo.toml`, `pom.xml`, `pyproject.toml`, `Gemfile`), and greps framework signals. Phase 2 picks the archetype from a 30+-row classification table. Phase 3 drafts the diagram with kebab-case node ids, verb-phrase edge labels (`POST /login`, `emits user.created`, `awaits row`), and subgraphs grouped by package boundary. Phase 4 self-validates: every node has a `file:line` citation, every edge is something you can `Grep` for, Mermaid syntax check, 40-node cap enforced. Phase 5 writes raw Mermaid source to `flow.mmd` (or `flow-request-lifecycle.mmd` + `flow-service-topology.mmd` for paired archetypes) and prints a Markdown report to chat with diagram, legend, and notes.

Hard refusal on invented modules, decorative edges, paraphrasing the README instead of reading the code, and on out-of-scope asks (code review, refactor proposals, bug hunts, security/performance audits - those are different skills).

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/codebase-to-mermaid/SKILL.md` carries the five-phase procedure (Discover → Classify → Draft → Validate → Emit) and constraints. The bulky framework grep cheat sheet, archetype-to-diagram table, and 24 worked few-shot examples live in `references/` and load only when the model needs them - keeps base context light. The slash command `/codebase-to-mermaid` accepts an absolute or relative path, or shows a two-option picker (current working directory vs custom path) when invoked bare.

## ✨ Features

- 🗺️ Reads the whole project. Globs the tree, reads manifests, greps framework signals - no skimming the README and guessing
- 🔍 Auto-classifies the archetype across 19+ languages (JS, TS, PHP, Python, Go, Rust, Java, Kotlin, C#, C, C++, Ruby, Swift, Bash, Vue, Svelte, Razor) and 30+ framework families (React, Vue, Next.js, Nuxt, Astro, Remix, SvelteKit, Express, Fastify, NestJS, Hono, Koa, Laravel, Symfony, Livewire, Slim, Drupal, Magento, WordPress core / plugin / theme / Gutenberg / WooCommerce, WP-CLI, Spring Boot, Quarkus, Micronaut, Vert.x, ASP.NET Core, Blazor, MAUI, Unity, Qt, Drogon, Crow, axum, actix, rocket, leptos, yew, htmx, Alpine, chi, gin, echo, fiber, cobra, clap, FastAPI, Flask, Django, Rails, Airflow, Prefect, Dagster, Kafka, RabbitMQ)
- 📐 Picks the right diagram kind: `flowchart TD` for branching control flow, `flowchart LR` for pipelines and service maps, `sequenceDiagram` per route, `classDiagram` for ORM models
- 🏷️ Every node carries a `file:line` citation in the legend. Unverifiable node = deleted node
- 🚫 No invented modules, no decorative edges. If you cannot `Grep` for the call, the edge is deleted
- ✂️ Caps each diagram at 40 nodes. Bigger projects get an overview plus per-archetype zooms instead of one unreadable wall
- ⚠️ Flags destructive steps (`wp db reset`, `wp search-replace`, `rm -rf`, `aws s3 rm --recursive`) with a distinct node style
- 🤝 Pairs archetypes that travel together. WordPress plugin + WooCommerce, Laravel + Livewire, Go/chi + htmx + Alpine, Next.js + Prisma + tRPC - emits one diagram per layer plus a round-trip `sequenceDiagram`
- 📝 Writes raw Mermaid to `flow.mmd` (or `flow-<archetype>.mmd` per diagram) with no fences and no commentary, so it pipes straight into `mmdc -i flow.mmd -o flow.svg`
- 🖨️ Prints a Markdown report to chat: rendered diagram + legend (`node-id → relative/path.ext:line - one-line role`) + notes (external systems, async boundaries, anything skipped)
- 🚦 Scope-locked. Refuses code review, refactor proposals, bug hunts, security/performance audits, README rewrites, "explain this function". Diagram + legend + notes only

## 🔄 How it works

1. **Discover.** `Glob` the tree for layout and manifest files. Read manifests for entry points and declared deps. `Grep` framework signals from the cheat sheet in `references/framework-signals.md`. Build an internal `{module → file → exported_symbols → callers}` inventory capped at the top ~50 modules by inbound edges.
2. **Classify.** Pick the archetype from `references/archetype-table.md`. If two archetypes both fit, emit two diagrams. WordPress plugins/themes, Laravel/Symfony apps, and hypermedia stacks (htmx/Alpine/Livewire on top of a backend) almost always warrant at least two.
3. **Draft.** Write Mermaid with stable kebab-case node ids, human-readable labels, verb-phrase edge labels from real call sites, subgraphs by package boundary.
4. **Validate.** Self-check: every node id appears in the legend with a real `file:line`; every edge corresponds to a real call/import/route/hook/message you can `Grep` for; Mermaid syntax parses (balanced brackets, no reserved-word collisions, no orphan nodes, no labels with unwrapped special chars); diagram fits the 40-node cap or is split.
5. **Emit.** `Write` the raw Mermaid source to `flow.mmd` (or per-archetype `.mmd` files) into the target directory. Print the Markdown report to chat.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/codebase-to-mermaid /path/to/repo         ← map this repo
/codebase-to-mermaid ../sibling-project    ← relative paths work too
/codebase-to-mermaid                        ← picker: current dir vs custom path
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"map this codebase"*, *"draw a diagram of this repo"*, *"generate a flow diagram"*, *"make a mermaid diagram"*, *"visualize this project"*, *"show how this code flows"*, *"diagram the architecture"*, *"sequence diagram of this endpoint"*, *"class diagram of these models"*, *"onboarding diagram"*, *"produce a flow.mmd"*

After the run, render the saved `.mmd` file two ways:

```bash
# CLI (mermaid-cli)
npx -p @mermaid-js/mermaid-cli mmdc -i flow.mmd -o flow.svg
```

Or paste the contents of `flow.mmd` into <https://mermaid.live>.

The full procedure lives at [`lib/codebase-to-mermaid/SKILL.md`](../lib/codebase-to-mermaid/SKILL.md), the slash command at [`commands/codebase-to-mermaid.md`](../commands/codebase-to-mermaid.md), and the on-demand reference files at [`lib/codebase-to-mermaid/references/framework-signals.md`](../lib/codebase-to-mermaid/references/framework-signals.md), [`lib/codebase-to-mermaid/references/archetype-table.md`](../lib/codebase-to-mermaid/references/archetype-table.md), [`lib/codebase-to-mermaid/references/examples.md`](../lib/codebase-to-mermaid/references/examples.md).

---

## `mermaid-to-ascii`

Hand it a Mermaid diagram file. Get back the same diagram drawn in plain text-art, saved right next to the original as a `.txt`.

```
/mermaid-to-ascii
```

Mermaid is great until you need the picture somewhere that can't render it: a code comment, a plain-text README, a chat message, a terminal, an email. This plugin takes a `.mmd` file and redraws it as tidy monospace text-art you can paste anywhere. It reads the file, works out what kind of diagram it is, lines everything up with fixed spacing, and writes the result to a `.txt` with the same name. Your original file is never touched.

It handles all the common Mermaid types: sequence diagrams become vertical lifelines with arrows crossing between them, flowcharts become connected boxes that follow the top-down or left-right direction you set, class diagrams become bordered boxes with their fields listed inside, state diagrams and ER diagrams get boxed nodes with labeled links, and gantt charts become rows of bars along a time axis. Every name, label, message, condition, and grouping block from the source is kept exactly as written, nothing dropped or renamed.

It asks one thing before it starts: which file to convert. If you named the file in your request it uses that; if you didn't, it asks and waits rather than guessing. Anything written inside the diagram is treated as plain drawing data, so a label that happens to read like an instruction just gets drawn, never obeyed. If a diagram is too wide for a terminal it splits into stacked sections instead of cutting anything off, and if the file is empty or broken it tells you what failed instead of inventing a picture.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/mermaid-to-ascii/SKILL.md` carries the filename-first intake, the eleven conversion rules (Rule 0 through Rule 10), the edge-case handling, and the output contract. The six per-type ASCII layout templates live in `references/skeletons.md` and load only once the diagram type is known, so the base context stays light. The slash command `/mermaid-to-ascii` takes a file path, or asks for one when invoked bare.

## ✨ Features

- 🧭 Asks which file to convert first, then stops and waits. No guessing, no scanning for a file you didn't name
- 🔁 Restates the plan once ("Converting `flow.mmd` -> `flow.txt`") before it does anything
- 📐 Handles every common Mermaid type: sequence, flowchart/graph, class, state, ER, and gantt
- 🧱 Picks the right text layout per type from six bundled templates, loaded only when needed
- 🏷️ Keeps every name, label, message, condition, and grouping block (`alt`/`else`/`opt`/`loop`/`par`). Nothing dropped, nothing renamed
- 📏 Fixed column spacing, aligned boxes, spaces not tabs, sized for an 80-120 character terminal
- ✂️ Splits oversized diagrams into stacked, labeled sections instead of cutting them off
- 🧾 Starts with a title and ends with a legend explaining every symbol used
- 🛟 Reports a clear parse error on empty or broken files and writes nothing; renders the good part of a partly broken file and lists the lines it skipped
- 🔒 Treats everything inside the file as drawing data, never instructions, even comments and labels that look like commands
- 📝 Writes only to the matching `.txt` and leaves the source file untouched

## 🔄 How it works

1. **Get the filename.** Use the file named in the request, or ask "Which Mermaid file should I convert?" and wait. Set the output name to the same base name with a `.txt` extension and restate the mapping.
2. **Read and identify.** Parse the source and work out the diagram type, which decides the layout.
3. **Lay it out.** Load the matching template from `references/skeletons.md` and draw the diagram with fixed spacing and aligned boxes, keeping every label and grouping block.
4. **Handle the awkward cases.** Approximate an unknown type and say so, split anything too wide, report parse errors on empty or broken source, and list any lines that couldn't be drawn.
5. **Save it.** Write the text-art to the `.txt` file, report which nodes and frames were captured, and leave the original alone.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/mermaid-to-ascii flow.mmd     ← convert this file
/mermaid-to-ascii              ← asks which file to convert
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"convert this mermaid to ascii"*, *"turn diagram.mmd into ascii art"*, *"render this sequence diagram as text"*, *"make an ascii version of this flowchart"*, *"mermaid to txt"*

The full procedure lives at [`lib/mermaid-to-ascii/SKILL.md`](../lib/mermaid-to-ascii/SKILL.md), the slash command at [`commands/mermaid-to-ascii.md`](../commands/mermaid-to-ascii.md), and the on-demand layout templates at [`lib/mermaid-to-ascii/references/skeletons.md`](../lib/mermaid-to-ascii/references/skeletons.md).

---

## `explain-my-code`

Point Claude at any codebase. Get back one self-contained Markdown document that onboards anyone new to the project - architecture, flows, patterns, risks - with every component named from the real source.

```
/explain-my-code
```

Ever been handed a repo on day one with no docs, no diagram, and the one person who knew it left three months ago? You spend a week clicking through folders just to learn where the app starts and how a request reaches the database. This plugin replaces that week. Point it at a repo and it reads the actual source like a senior architect doing your onboarding for you, then writes a single `CODEBASE_DOCUMENTATION.md` you can hand to the next person who joins. No sit-down handover, no "ask whoever wrote it," no stale wiki.

The skill runs five phases. Phase 1 scopes the target (finds the repo root, reads manifests first - `package.json`, `go.mod`, `pom.xml`, `Cargo.toml`, `*.csproj`, Dockerfile, CI configs). Phase 2 identifies the foundations (tech stack, languages, frameworks, and whether it's a monolith, microservices, or modular). Phase 3 traverses folder-by-folder and module-by-module, inferring design patterns and tracing the data and dependency flow. Phase 4 writes all 13 sections with real file, class, and function names and embedded Mermaid diagrams. Phase 5 verifies before delivery - every section present and non-shallow, every cited symbol actually in the repo, every Mermaid block valid - then saves the file and tells you the path.

Hard refusal on shallow summaries, skipped sections, invented symbols, and silent guessing (undocumented behavior is inferred out loud, with the assumption stated). Scope-locked to documentation - it won't do line-by-line review, refactor plans, or diagram-only output (those are different skills).

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/explain-my-code/SKILL.md` carries the five-phase procedure (Scope → Identify → Traverse → Write → Verify), the 13-section output contract, and the preserved source constraints. The slash command `/explain-my-code` accepts an absolute or relative path, or shows a two-option picker (current working directory vs custom path) when invoked bare.

## ✨ Features

- 📖 Reads the whole project. Globs the tree, reads manifests first, then walks folder-by-folder - no skimming and guessing
- 🧭 Works out the structure: tech stack, languages, frameworks, and monolith vs microservices vs modular
- 🔁 Traces how it actually runs: entry points, startup sequence, request lifecycle, auth flow, and data flow from input → processing → storage
- 🏷️ Names real things. Every component, class, and function in the doc is a real, `Grep`-verifiable symbol - no `MyApp`, no `FooService`
- 📊 Embeds Mermaid `graph TD` for architecture and `sequenceDiagram` for flows, right inside the document
- 📑 Always 13 sections, always in order. An inapplicable section keeps its heading and says `Not applicable - <reason>` rather than vanishing
- 🧱 Skips the noise. `node_modules`, `vendor`, `dist`, `build` excluded from traversal and noted as skipped
- 🧩 Big repo? Analyzes in chunks - manifests and entry points first, then module by module - and is honest about anything sampled rather than read in full
- 📝 Writes one `CODEBASE_DOCUMENTATION.md` to the repo root and reports the path
- 🚦 Scope-locked. Refuses code review, bug hunts, refactor plans, and diagram-only output

## 🔄 How it works

1. **Scope.** Find the repo root (default: current working directory). `Glob` the layout and read manifest/config files first. Stop and ask if there's no code at the target.
2. **Identify.** Determine languages, frameworks, and infra split; classify the architecture; locate entry points and config loading.
3. **Traverse.** Walk folder/service/module by module. Infer design patterns (MVC, Clean, Hexagonal, Factory, Observer) and record where and why each is used. Trace business logic, dependency flow, and data flow.
4. **Write.** Produce all 13 sections with real symbol names and embedded Mermaid. Where behavior is undocumented, infer it and state the assumption explicitly.
5. **Verify.** Confirm every section is present and substantive, every cited symbol exists, every Mermaid block parses. `Write` the document and report its path.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/explain-my-code /path/to/repo         ← document this repo
/explain-my-code ../sibling-project    ← relative paths work too
/explain-my-code                        ← picker: current dir vs custom path
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"document this codebase"*, *"explain my code"*, *"generate architecture docs"*, *"write an onboarding doc"*, *"analyze this repo"*, *"help a new dev understand this whole codebase"*, *"write up how this project works"*, *"map out this code into a doc"*

The full procedure lives at [`lib/explain-my-code/SKILL.md`](../lib/explain-my-code/SKILL.md) and the slash command at [`commands/explain-my-code.md`](../commands/explain-my-code.md).

---

## `code-teacher`

Turns a script into a teaching version of itself. You hand it code, it hands back the same code with the explanation attached - a header block saying what the program does and where the tricky parts are, plus line-by-line comments explaining not only what each piece does but why it was written that way. Nothing in the code itself changes. Only comments are added.

```
/code-teacher
```

Useful for teachers preparing course material, for writing up a project so a teammate can pick it up later, or for understanding a script somebody handed you. Where `explain-my-code` reads a whole repository and writes a separate onboarding document, `code-teacher` works on one unit - a function, a class, a file - and the annotated code *is* the output.

It plans before it writes. The first thing that comes back is a short Plan naming the non-obvious problems the code solves, the parts most likely to trip a student, and the one or two design choices a competent developer could plausibly have made differently, each with the alternative and why it was likely rejected. The teaching points at the end draw on that plan rather than restating the code.

Inference is marked. Anything you told it about - a bug you hit, a tool that behaved unexpectedly, an ordering that mattered - is written as fact. Anything it worked out on its own carries an `INFERRED:` prefix and has to point at the specific line that supports it. A claim that cannot be anchored to a line is dropped rather than guessed at, so the annotations never invent history you never described.

Then it checks itself. Before returning, it re-reads the annotated version against your original and confirms in the Verification section that every original line of executable code is still present, unchanged, and in the same order, that nothing was added except comments, and that every `INFERRED:` claim points at a real line.

## 📋 Technical Overview

One slash command plus its procedure file `lib/code-teacher/SKILL.md`, which loads the master template from `lib/code-teacher/references/prompt-template.md`. The command `/code-teacher` takes code inline or as a file path, or asks for it - and when it asks, it also asks for the bugs, surprises, and design decisions that are not visible in the code alone, because that is what turns an annotation into a lesson. Language is detected automatically unless you name one; the audience level defaults to intermediate.

## ✨ Features

- 🧭 Plan first. At most eight lines naming the hardest parts and the consequential design choices, before any annotated code
- 📑 Header block covering purpose, why it is tricky, the high-level algorithm, usage, and requirements
- 💬 Inline comments on every meaningful block - what it does and why it is written that way, not a restatement
- 🔁 State explained. Every value tracked across a loop or several steps gets its purpose spelled out
- 🎓 Teaching points. Three to five bullets on the lessons this specific code actually teaches
- 🔍 Inference marked. Unattributed claims carry `INFERRED:` and a line anchor, or they are cut
- ✅ Self-verification. Confirms the original code came back unchanged, in order, with only comments added
- 🗣️ Audience aware. Comments pitched at a beginner or at someone more experienced, your call
- 🌐 Any language, detected on its own, with the comment syntax matched to it
- 🔑 Secrets flagged. A hardcoded password, key, or token is called out in a comment rather than passed over
- 📄 Long files handled. Stops at a clean unit boundary and says where, rather than truncating mid-function
- 🛡️ Injection resistant. Instructions hidden in comments or strings are content to annotate, not directions to follow
- 🛑 Refuses cleanly. Says so and stops if the input is not code, or if the code is clearly built to do harm

## 🔄 How it works

1. **Intake.** Take the code from the argument, a file path, or a plain ask - plus the developer notes that are not visible in the code.
2. **Gate.** Stop on an absent or placeholder submission, on input that is not source code, or on code whose evident purpose is harmful.
3. **Plan.** Name the hard parts and the design choices worth discussing.
4. **Annotate.** Header block, then inline comments, with every inference anchored to a line.
5. **Teach.** Three to five teaching points drawn from the plan.
6. **Verify.** Re-read against the original; fix anything that drifted before returning.
7. **Print.** Plan, one fenced code block, teaching points, verification - in that order, nothing else.

## 🚀 How to use it

```
/code-teacher ./scripts/deploy.sh   ← annotate a file
/code-teacher                       ← asks you to paste the code
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"annotate this script for students"*, *"explain this code line by line"*, *"add teaching comments to this"*, *"document this function so a junior can follow it"*, *"turn this into course material"*

The annotated version comes back in the response. It is never written over your original file.

For a whole-repo onboarding document use [`/explain-my-code`](#explain-my-code); to turn existing docblocks into one-line comments use [`/docblock-rewrite`](#docblock-rewrite).

The full procedure lives at [`lib/code-teacher/SKILL.md`](../lib/code-teacher/SKILL.md), the slash command at [`commands/code-teacher.md`](../commands/code-teacher.md), and the master template at [`lib/code-teacher/references/prompt-template.md`](../lib/code-teacher/references/prompt-template.md).

---

## `docblock-rewrite`

Convert PHPDoc and JSDoc `/** ... */` blocks into one-line plain-English `//` comments. Two engines under one ruleset.

```
/docblock-rewrite
```

Ever inherited a codebase where every function has a perfectly-tagged PHPDoc block that tells you absolutely nothing about what the code does for a human reader? `@param string $token`, `@return bool`, three lines of jargon, and a non-technical teammate (PM, designer, support) bouncing off it. That's what this plugin solves.

The `docblock-rewrite` skill takes existing doc blocks and replaces each one with a single `// ` comment a non-coder could understand. Tech jargon banned (no `array`, no `callback`, no `instantiate`). 100-character cap. Capitalized, present-tense verb for functions, noun phrase for classes / files / constants. Tags stripped - `@param`, `@return`, `@throws`, `@since`, `@author`, `@version`, all of it. Doc blocks marked `@internal`, `@deprecated`, or `@ignore` are left alone.

Two engines apply the same rules: an **interactive** Read / Edit walk the model runs directly for small jobs (1-20 files) when you want to tune the prompt or check edge cases by eye, and a **bundled bash + perl + claude --print runner** for bulk jobs (20+ files, repeat runs, CI / unattended). The script walks the directory, parses doc blocks with perl, calls Claude Haiku once per symbol, validates every response against the banned-word list and 100-char cap, and applies replacements right-to-left so byte offsets stay valid. Bad outputs leave the original block intact for human review. `.bak` files saved next to every modified file unless `--no-backup`.

It turns wall of tags doc blocks into comments that read like a sentence, whichever the reason: shipping to non technical merchants, onboarding a teammate who keeps asking what each function does, or clearing a decade old PHPDoc graveyard before handing the repo off.

## 📋 Technical Overview

One slash command, its procedure file, and a bundled three-file runner (bash + 2× perl) that share one set of rewrite rules. The procedure file `lib/docblock-rewrite/SKILL.md` carries the full rule set and decides which engine to use based on file count. The slash command `/docblock-rewrite` invokes the runner via `${CLAUDE_PLUGIN_ROOT}/lib/docblock-rewrite/scripts/docblock-rewrite.sh`. Both engines emit the same `// <summary>.` format.

## ✨ Features

- 🧹 Strips PHPDoc / JSDoc blocks down to one plain-English `//` line
- 🚫 Banned-word list (`instantiate`, `invoke`, `callback`, `promise`, `iterate`, `async`, `boolean`, `array`, `object`, `parameter`, `argument`, `mutate`, `hash`, `payload`, `instance`, `factory`, `singleton`, `polyfill`, `regex`) - validation rejects any output that contains them
- 📏 100-character total cap including the leading `// `
- 🏷️ Honors `@internal`, `@deprecated`, `@ignore` opt-out tags - leaves those blocks alone
- 📄 File-level detection via `@file` / `@package` / `@module` or a post-block `declare` / `namespace` / `use` / `import` / `export` line
- 🗂️ Walks `.php`, `.js`, `.ts`, `.jsx`, `.tsx`, `.mjs`, `.cjs` - skips `vendor`, `node_modules`, `dist`, `build`, `coverage`, `__tests__`, `.git`, `.next`, `.nuxt`, `out`, `tmp`, `*.min.js`, `*.min.css` by default
- 🛟 `.bak` backup written next to every modified file unless `--no-backup`
- 🔍 `--dry-run` prints unified diffs without writing
- 🚦 Validation gates per response: one-line, `// ` prefix, length cap, banned-word regex - failures leave the original block intact
- ⚙️ Concurrency-tunable (`--concurrency N`, default 3) parallel `claude --print` calls via `xargs -P`
- 🪓 Right-to-left byte-splice in `apply-plan.pl` keeps offsets valid across multi-block files
- 🤖 Same prompt rules in both the inline skill engine and the scripted engine

## 🔄 How it works

**Inline engine (skill, small jobs):**

1. Model uses Grep / Glob to find candidate files
2. For each file: `cp file file.bak`, Read the file, identify every `/** ... */` block and its following declaration, rewrite each one with Edit, self-check against the rule set before applying
3. Report file count, blocks rewritten, blocks skipped, blocks needing review

**Scripted engine (bulk):**

1. `find` walks the path with the skip list
2. `extract-docblocks.pl` slurps each file, emits JSON pairs of `(doc block, next non-blank line)`
3. Bash loops the pairs, builds a prompt with the rule set + few-shot examples + the docblock + the symbol, pipes through `claude --model … --print`
4. Output gets `head -n1` + trim, runs through `validate_output` (one line, `// ` prefix, length cap, banned-word grep)
5. Validated outputs go into a per-file plan file as `start <TAB> len <TAB> base64(new)`
6. `apply-plan.pl` applies plan entries right-to-left so earlier byte offsets stay valid, renames original to `.bak`, writes new contents

## 🚀 How to use it

Two ways to invoke:

**Slash command** (scripted bulk run):

```
/docblock-rewrite . --dry-run     ← dry run on current dir
/docblock-rewrite src/            ← real run with .bak backups
/docblock-rewrite src/ --no-backup --concurrency 8
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"rewrite docblocks in src/"*, *"convert my PHPDoc to plain English"*, *"strip jargon from comments in formatting.php"*, *"make these JSDoc blocks readable to a non-coder"*, *"turn my doc blocks into friendly one-liners"*

The skill picks the engine based on file count - small jobs run inline, big jobs hand off to the script.

The full procedure lives at [`lib/docblock-rewrite/SKILL.md`](../lib/docblock-rewrite/SKILL.md), the slash command at [`commands/docblock-rewrite.md`](../commands/docblock-rewrite.md), and the bundled runner at [`lib/docblock-rewrite/scripts/docblock-rewrite.sh`](../lib/docblock-rewrite/scripts/docblock-rewrite.sh), [`lib/docblock-rewrite/scripts/extract-docblocks.pl`](../lib/docblock-rewrite/scripts/extract-docblocks.pl), [`lib/docblock-rewrite/scripts/apply-plan.pl`](../lib/docblock-rewrite/scripts/apply-plan.pl).

## Requirements (script only)

`bash` 4+, `jq`, `perl` with `MIME::Base64`, `claude` CLI on `PATH` (Claude Code subscription auth, no API key required).

---

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

## `changelog-generator`

Point Claude at a git repo. Get back a changelog your users can read, built from the actual code changes across the whole history - first commit to `HEAD` - not from the commit messages.

```
/changelog-generator
```

Ever tried to write release notes from `git log` and found half the commits say "fixes", "tweaks", or "and more"? Commit messages leave things out and get the label wrong. A "fix" turns out to undo a break from an hour earlier. A one-line "cleanup" hides three real features. A commit tagged "security" only renamed a variable. If you write the changelog from the messages, you ship a changelog that is partly fiction.

This plugin reads the code instead. It walks the full history, splits it into eras by date and tags, and reads the real diffs with `git show` and `git diff`. The diff is the truth of what shipped, so the changelog says what actually changed. It sorts each change into New Features, Improvements, Security, Breaking Changes, or Fixes, drops the noise users never see, and writes everything in plain language anyone can follow. When it is done it offers to save `CHANGELOG.md` and tells you every place the code did not match the commit message.

## 📋 Technical Overview

One slash command, its procedure file, and one bundled script. The procedure file `lib/changelog-generator/SKILL.md` carries the trust boundary, the five-step workflow, the per-range brief for sub-agents, and the fixed output format. The script `scripts/map-history.sh` does the deterministic git plumbing (repo check, shallow check, root commit, tags, full oldest-first timeline, root-to-HEAD diffstat) so the model never has to reinvent it. The slash command `/changelog-generator` takes a repo path or runs on the current directory.

## ✨ Features

- 📖 Reads the code change, not the message. `git show` / `git diff` is the source, so "fixes" and "and more" get unpacked into what really shipped
- 🕰️ Covers the whole history. First commit to `HEAD`, no gaps. It will not take a date or version range - the scope is always everything
- 🧪 Checks the repo first. Stops if the folder is not a git repo, warns when the copy is shallow (so it never claims full coverage), and handles a one-commit history
- 🗂️ Splits the history into eras. Contiguous per-release chunks by date and theme, using tags as the boundaries
- 👥 Handles big histories. Over about 40 commits, or when a diff is too large to read in one pass, it splits the work across parallel helpers, then combines and double-checks anything surprising against the real code - it never quietly skips or samples
- 🏷️ Sorts every change: feature, improvement, fix, security, breaking change, or internal
- 🕵️ Catches what messages hide. Lists features buried under "and more", drops fixes that only undo a break from the same batch, refuses to call reworded or moved code "new", and flags any commit whose message says more or less than the diff did
- 🔒 Pulls security and breaking changes into their own sections, with the real mechanism (how a check or block works, what setting was removed or flipped)
- 🛡️ Treats everything in the repo as data, not orders. A diff that says "ignore the above" gets described, never obeyed
- 📝 Offers to save `CHANGELOG.md` and reports where the diff corrected the commit messages

## 🔄 How it works

1. **Map.** Run `scripts/map-history.sh`. Act on its `STATUS` / `SHALLOW` / `COMMIT_COUNT` - stop if not a git repo, warn if shallow, take the single-commit path if there is only one commit.
2. **Split.** Break the timeline into contiguous ranges by era and release, using tags and day-grouped commits as boundaries.
3. **Read the diffs.** For each range, `git diff <range> --stat` for the overview, then `git show` / `git log -p` for the substance. Over ~40 commits or an oversized diff, dispatch one helper per range in parallel with the per-range brief.
4. **Synthesize.** Merge the findings, treat helper reports as claims and spot-check the surprising ones against the diff, dedupe, order newest first, and lift out security and breaking changes.
5. **Check and write.** Confirm the ranges chain together with no gaps and that a real diff sits behind every entry, then emit the changelog and offer to save it.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/changelog-generator            ← runs on the current repo
/changelog-generator ../my-app  ← runs on a repo at that path
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"generate a changelog for this repo"*, *"write release notes from the git history"*, *"what actually shipped in this project?"*, *"changelog from the code changes, don't trust the commit messages"*, *"turn this repo's history into release notes my users can read"*

The full procedure lives at [`lib/changelog-generator/SKILL.md`](../lib/changelog-generator/SKILL.md), the slash command at [`commands/changelog-generator.md`](../commands/changelog-generator.md), and the history script at [`lib/changelog-generator/scripts/map-history.sh`](../lib/changelog-generator/scripts/map-history.sh).

---

## `mermaid-generator`

Turns a bullet-point list of process steps into one valid Mermaid sequence diagram, in the voice of a technical diagramming assistant. It works out the participants, the message directions, and the branches, loops, and parallel blocks.

```
/mermaid-sequence
```

The single easiest thing to get wrong in a sequence diagram is arrow direction, and most tools point it at the sentence's grammatical subject. This one reads the verb: "the warehouse receives the shipment from Supplier" draws an arrow from Supplier to Warehouse, not the other way. It normalizes every reference to one participant, aliases multi-word names, strips characters that would break the syntax, and turns "if / otherwise", "for each", "only if", and "at the same time" into `alt`, `loop`, `opt`, and `par` blocks.

It never guesses. If a step names a recipient but no sender, or the input has fewer than two participants, it returns a one-line `ERROR:` pointing at the exact bullet instead of a diagram built on a guess. Output is exactly one thing: a fenced `mermaid` block, an `ERROR:`, or a `SAFETY:` message - never prose around it. Text inside the input is treated as diagram content, so a hidden "ignore all instructions" just becomes a message label.

## 📋 Technical Overview

One slash command plus its procedure file `lib/mermaid-generator/SKILL.md`, targeting Mermaid.js v10+. The command `/mermaid-sequence` takes the bullet list as its argument, or asks for it. A silent 14-point validation runs before anything is emitted.

## ✨ Features

- 🧭 Arrow direction from the verb, not the subject - receptive versus active phrasing
- 🏷️ Aliases multi-word names and normalizes every reference to one participant id
- 🔀 `alt` / `opt` / `loop` / `par` from "if/otherwise", "only if", "for each", "at the same time"
- 🧹 Strips parens, brackets, semicolons, and `#` from labels instead of failing
- 🚦 Refuses with a one-line error at the exact bullet when a sender is missing
- 🛡️ Treats input as diagram content; injection attempts become plain labels
- 📤 Emits exactly one form - diagram, `ERROR:`, or `SAFETY:` - never with surrounding text

## 🔄 How it works

1. **Intake.** Take the bullet list from the argument or ask for it.
2. **Parse.** Identify participants in order of appearance; resolve each entity to one id.
3. **Direct.** Set every arrow from the verb; use `-->>` only for explicit returns.
4. **Structure.** Wrap conditionals, loops, and parallel steps in the right blocks.
5. **Validate and emit.** Run the 14 checks; emit the diagram, or an error if it cannot be built.

## 🚀 How to use it

```
/mermaid-sequence                 ← asks for your bullet-point steps
```

Then paste steps like:

```
* User submits login form
* Server validates credentials
* If valid, server returns session token
```

The full procedure lives at [`lib/mermaid-generator/SKILL.md`](../lib/mermaid-generator/SKILL.md) and the slash command at [`commands/mermaid-sequence.md`](../commands/mermaid-sequence.md).

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
