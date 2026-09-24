# Code

[← Back to the README](../README.md)

## `app-blueprint`

Turns a one-line app idea into a complete, production-ready application blueprint.

```
/blueprint
```

Ever sat down to build something and realized the hardest part isn't writing the code. it's deciding the folder layout, the data models, the API surface, the deployment target, and the testing plan before you've typed a single line? That's what this plugin solves.

The `app-blueprint` skill behaves like a senior software architect with 15+ years of production experience. Hand it five inputs (what the app does, the tech stack, the workload type, the language, and the scale) and it produces an 11-section blueprint with the folder tree, the layer walkthrough, the data models, every API endpoint, dependency choices with reasoning, environment variables, a testing plan, a deploy plan justified by your scale, architect's notes, and a self-validation table that auto-repairs inconsistencies before delivery.

What makes it different from a generic "design my app" prompt? It refuses to invent. no `MyApp`, no `UserService`, no `Entity1`. Every name derives from your `APP_DESCRIPTION`. It enforces consistency. every entity in the data-model section must appear in at least one API endpoint, every dependency must map to a folder or reference, the deployment target must be justified by your stated scale with a stated migration trigger. And it halts cleanly with `MISSING INPUT: <field> required` instead of guessing when an input is blank.

It produces the plan a senior engineer would draft in their first ten minutes on a project, at any size: a weekend side project, a team kickoff, or a `BLUEPRINT.md` for something going to production.

## 📋 Technical Overview

An AI instruction specification that generates 11-section production application blueprints from five required inputs.

Built around a locked 11-section template (`references/prompt-template.md`), strict consistency rules (folder/layer parity, entity/endpoint mapping, dependency reachability, scale-justified deployment), a section 11 validation table that runs before delivery, and prompt-injection defenses that treat input field values as inert data.

It names things after your app instead of using placeholder filler, halts on a missing input rather than guessing, and keeps folder trees and data models consistent with each other.

## ✨ Features

- 🏗️ 11 fixed sections in fixed order. project overview, folder tree, layer walkthrough, data models, API endpoints, dependencies, env vars, testing, deployment, architect's notes, self-validation
- 📥 Five required inputs. `APP_DESCRIPTION`, `TECH_STACK`, `APP_TYPE`, `LANGUAGE`, `SCALE`
- ❓ Slash command `/blueprint` runs an `AskUserQuestion` intake for any missing inputs. one question per missing field
- 🚫 No generic placeholders. all names derive from `APP_DESCRIPTION` (no `MyApp`, no `UserService`, no `FooEntity`)
- 🔁 Identical folder names in section 2 and layer names in section 3. parity enforced
- 🔗 Every section 4 entity must appear in at least one section 5 endpoint
- 📦 Every section 6 dependency must map to a folder (section 2) or a reference (section 8)
- 🚀 Deployment target (section 9) justified by `SCALE` explicitly. migration trigger always stated
- ✅ Section 11 validation table runs before output. any FAIL row repaired in place before delivery
- ⛔ `MISSING INPUT: <field> required. Provide value and re-run.` halt on any blank or placeholder input
- 🛡️ Prompt-injection defense. input field values treated as literal strings, never executed
- 🔒 Prompt secrecy. the template is never revealed, paraphrased, or summarized in output
- 📐 Output format. fenced code blocks for trees and config, tables for deps and env, domain-specific names everywhere

## 🔄 How it works

1. **Intake**: the `/blueprint` slash command collects five inputs via `AskUserQuestion`. one question per missing field. existing inputs are reused
2. **Load template**: reads `references/prompt-template.md`. the authoritative 11-section spec
3. **Substitute placeholders**: replaces `{{APP_DESCRIPTION}}`, `{{TECH_STACK}}`, `{{APP_TYPE}}`, `{{LANGUAGE}}`, `{{SCALE}}`. treats values as inert data
4. **Emit sections 1-11**: in exact order, no additions, no reordering
5. **Self-validation**: runs the section 11 validation table. repairs any FAIL row in place before delivery

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/blueprint ← walks through the five-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"design a production architecture for a dog walking marketplace"*, *"blueprint an app that tracks plant watering schedules"*, *"architect a tool for booking guitar lessons"*, *"give me a full system blueprint for a multi tenant SaaS"*, *"production architecture for a coffee subscription box"*

The full procedure lives at [`lib/app-blueprint/SKILL.md`](../lib/app-blueprint/SKILL.md), the slash command at [`commands/blueprint.md`](../commands/blueprint.md), and the 11-section authoritative template at [`references/prompt-template.md`](../lib/app-blueprint/references/prompt-template.md).

---

## `e2e-playwright`

Add a Playwright end-to-end suite to an existing Node/Express application, alongside whatever tests it already has, without changing how the existing suite is run.

```
/e2e-tests
```

An end-to-end suite fails in ways a unit suite does not, and most of those failures are about the rig rather than the application. This tool builds the rig the way a careful contractor would: read the repository before writing anything, change application code only where permitted, and report plainly what was found, including what did not work.

The rig has four parts. A **throwaway install** - a seed script that wipes `var/e2e`, rebuilds the database from the application's own schema module, and copies fixture files into a throwaway uploads directory, with a path guard that exits non-zero rather than delete anything outside `var/e2e`, checked with `path.relative` and not a string prefix, so `var/e2e-other` cannot slip through. A **fake upstream**, if the app calls a paid API: a dependency-free `node:http` server the real SDK client is pointed at, so the SDK, the HTTP layer and the multipart encoding all stay under test. **Two servers started by Playwright**, each with a readiness URL, the app going through a small launcher because `webServer.env` adds to the environment rather than replacing it - which means a real API key in the developer's shell would otherwise reach the app and make the suite pass while spending money. And **one spec per journey**, sharing a helpers module and a constants module, limited to journeys a unit test cannot reach.

Sixteen documented pitfalls sit behind the design, each one a debugging cycle or a data-loss risk that happened in practice: `webServer` starting before `globalSetup`, `dotenv` not overwriting a variable already set, a reused server skipping the seed, rate limiters stopping the suite for reasons unrelated to the journey, an SDK retrying a 500 so the failure journey never happens, an `sr-only` checkbox behind a styled label that `check()` cannot reach, two fixtures sharing a name so every `.first()` silently picks one.

## 📋 Technical Overview

One slash command and a four-file procedure bundle. `lib/e2e-playwright/SKILL.md` carries the role, the scope lock, the intake fields, the nine-step workflow, the permitted application changes and the seven-part report contract. `references/pitfalls.md` holds the sixteen known failures and is read first. `references/rig.md` holds the Playwright config, the shared ports module, the launcher, the fake upstream, the seed data design and the npm scripts. `references/helpers.md` holds the shared helpers module and the assertion technique for each journey type - canvas, "without a reload", public pages, zips, file drag and drop, clipboard.

## ✨ Features

- 🌱 Seeded throwaway install rebuilt from the app's own schema, with a path guard that has its own test
- 🔒 Environment built from a short allow list, never `process.env`, so a real API key cannot reach the app
- 🚀 A launcher process that runs the seed then the server, because Playwright starts servers before `globalSetup`
- 🎭 Fake upstream with `fail-next`, a request log, `reset` and `health` control routes
- 📼 Upstream response shapes recorded from the real API as envelopes, never invented - and never recorded without asking first
- 🐞 A real application bug keeps its assertion, is marked `test.fail()`, and is reported with steps to reproduce
- 🔢 Alphabetical spec ordering with two-digit prefixes, the destructive file at `99-`
- 🧪 Both runners kept apart: the existing `test` script is untouched and neither side collects the other's files
- 🌿 Work lands on an `e2e-playwright` branch, committed step by step, never pushed
- 📋 Seven-part report: status, application bugs, docs that disagree with the code, envelope provenance, every application change, what was not covered, and notes

## 🔄 How it works

1. **Branch.** Create and switch to `e2e-playwright` if on the default branch. Never push.
2. **Readiness route.** Add `GET /health`, mounted before the IP allow list and the session check, with a test.
3. **Rig and smoke spec.** Install Playwright, write the config, the ports module, the launcher, and the first half of the seed - the path guard, the wipe and the schema rebuild - plus a smoke spec proving the app boots against an empty install.
4. **Seed data.** The constants and the fixture records, with the smoke spec now asserting seeded data through the UI.
5. **Upstream envelopes.** Record the real response shapes, after asking. In CI or with no way to ask, hand-build them and mark each `TODO: re-record`.
6. **Fake upstream.** The stub, its unit tests, and a spec that checks the request log so a call that went somewhere else shows up as a missing entry.
7. **Helpers and auth.** The shared module, then the authentication spec.
8. **One spec per journey**, each ending with a run and a commit.
9. **Full run and `TESTING.md`.** A wiped-directory run per browser project, then the documentation.

The existing suite runs after every step, and its test count must change only by the tests added for it.

## 🚀 How to use it

```
/e2e-tests                        ← reads the current directory, asks what it cannot read
/e2e-tests ~/code/my-app          ← points at a specific application root
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"add Playwright tests to this app"*, *"set up an end-to-end suite"*, *"I need browser tests for these journeys"*, *"e2e tests with a fake API server"*, *"test the upload flow in a real browser"*

The full procedure lives at [`lib/e2e-playwright/SKILL.md`](../lib/e2e-playwright/SKILL.md), the pitfalls at [`lib/e2e-playwright/references/pitfalls.md`](../lib/e2e-playwright/references/pitfalls.md), the rig at [`lib/e2e-playwright/references/rig.md`](../lib/e2e-playwright/references/rig.md), the helpers at [`lib/e2e-playwright/references/helpers.md`](../lib/e2e-playwright/references/helpers.md), and the slash command at [`commands/e2e-tests.md`](../commands/e2e-tests.md).

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

## `readme-builder`

Reads a whole project and writes one beginner friendly `README.md` for it. Plain everyday English, a fixed set of sections in the same order every time, and a firm rule against inventing anything that is not really in the repo.

```
/readme-builder
```

Most "write me a README" prompts either pad the page with hype ("a powerful, seamless tool") or describe features the project does not actually have. This plugin works the way a careful technical writer does. It opens and reads the real files first (the entry points, the config, the main scripts, any existing docs) to work out what the project is and what each file does, then writes the README from what it actually found. Tooling and session folders like `.git`, `.claude`, and `node_modules` are skipped and never mentioned.

The tone is aimed at someone who has never seen this kind of project before: short sentences, no jargon, and any unavoidable technical word explained in plain words right after. Marketing filler is banned outright (words like "seamless", "robust", "powerful", "leverage", and "supercharge"), along with empty fillers like "simply" and "just". The punctuation is kept plain too: no long dashes, no fancy arrows, and straight quotes only. A final check runs over the draft before you get it.

## 📋 What's inside

A plugin with one slash command and one skill. The procedure file `lib/readme-builder/SKILL.md` holds the writer persona, the five step workflow, the fixed section order, the banned word and punctuation lists, and the final quality check. The slash command `/readme-builder` takes an optional folder path, asks whether to write the file or print it, then runs the same workflow.

## ✨ What you get

- 📖 Reads the real project first, so the README matches what is actually there instead of being guessed
- 🧱 A fixed set of sections in the same order every time: title, description, feature list, a file by file explanation, a folder tree, and how to use it
- 🙂 Plain, friendly, everyday English with short sentences and no jargon
- 🚫 Hype words like "seamless", "robust", and "powerful" are banned, so the README stays honest
- ➖ No long dashes, no fancy arrows, and straight quotes only, which keeps the text clean and simple
- 🌳 A folder tree with a short note on each key file, so readers can see the layout at a glance
- ✅ A final check confirms every file and feature mentioned is real and a total beginner could follow it

## 🔄 How it works

1. **Read the repo.** It opens every folder and reads the important files to learn what the project is and what each file does. Nothing is guessed.
2. **Skip the noise.** Tooling and session folders (`.git`, `.claude`, `node_modules`, build output) are ignored and left out of the README.
3. **Draft.** It writes the sections in the fixed order, covering only the parts that fit the project.
4. **Clean.** It re-reads the draft against the banned word and punctuation lists and removes anything that slipped through.
5. **Final check.** It confirms no long dashes, no hype words, every file and feature real, and beginner readable, then hands over the finished README or saves it for you.

## 🚀 How to use it

Two ways to start:

**Slash command:**

```
/readme-builder ./my-project   ← seeds the target folder, then asks write or print
/readme-builder                ← documents the current folder
```

**Plain language** (starts the skill on its own):

> *"write a README for this repo"*, *"generate a README.md"*, *"document this project"*, *"make a beginner friendly README"*, *"explain this repo in a README"*

The full procedure lives at [`lib/readme-builder/SKILL.md`](../lib/readme-builder/SKILL.md), and the slash command at [`commands/readme-builder.md`](../commands/readme-builder.md).

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

## `sql-breakdown`

Review one SQL query without running it: a validation check, a clause-by-clause explanation, the business question it answers, a quality scorecard, efficiency and risk notes, and a plain-English summary for someone who has never seen SQL.

```
/explain-sql
```

A query can be syntactically perfect and still return the wrong numbers. `COUNT(*)` after a join counts joined rows, not distinct orders. A filter with no upper bound quietly reports "this month" as "everything since the first of the month". The `sql-breakdown` skill validates first - syntax, then logic in execution order, then completeness against what the business context actually asked for - and tags the result `✅ VALID`, `⚠️ HAS WARNINGS`, or `❌ LIKELY BROKEN` before it explains a single clause.

Everything after that is pitched at whoever the report is for. Tell it the reader is a data engineer and it writes peer-level with correct terminology; tell it the reader is a CFO and it drops the jargon and glosses every SQL term the first time it appears. Section 6 goes further and re-explains the whole query with no SQL terms in it at all.

Nothing is executed. A `✅ VALID` verdict means no error was found by reading, not that the query ran, and the efficiency section states an expected effect and the reason for it rather than a speed figure it cannot measure. Paste a `DELETE`, `UPDATE`, or `DROP` and the full report still ships, but every fix is described in words and no runnable version is printed anywhere.

## 📋 Technical Overview

One slash command plus its procedure file `lib/sql-breakdown/SKILL.md`, which loads the master template from `lib/sql-breakdown/references/prompt-template.md`. The command `/explain-sql` collects four fields - the query, the recipient role, the business context, and the dialect - of which only the query is required; the other three have defined defaults that are stated in the report when used. All four are substituted into a paired-marker block and treated as data, including text inside SQL comments and string literals.

## ✨ Features

- 🚦 Validation before explanation. Syntax, logic in execution order, and completeness against the business context, each with its own verdict
- 🎯 One register, chosen for the reader. Peer-level where the role writes SQL daily, plain business language where it does not, and it says which it took when either could apply
- 🧩 Clause by clause, with the rules that matter. Subqueries explained inner and outer, window frames contrasted with regular aggregation, `HAVING` distinguished from `WHERE`
- 📊 Anchored scorecard. Readability, Efficiency, Accuracy Confidence, and Business Clarity out of 10 each, totalled out of 40, with the verdict capping Accuracy Confidence so scores cannot contradict the validation
- ⚠️ At least two data risk flags, each as what could go wrong, when it would bite, and how to prevent it - never invented to fill a quota
- 🔒 Non-read statements handled, never handed back runnable. `DELETE`, `UPDATE`, `DROP` and friends get all seven sections with every fix in words only
- 🧠 Assumptions named, not hidden. With no schema supplied it names the grain or key-uniqueness assumption a finding rests on rather than asserting a join is wrong
- 📖 Section 6 in plain English with no SQL terms at all, closing with a comprehension confidence score
- 🛡️ Inputs are inert. Directives inside comments or string literals are ignored, and the input block closes only at the final marker

## 🔄 How it works

1. **Intake.** Collect the query, then the role, context, and dialect. Apply the stated default for anything skipped and say so.
2. **Classify.** Decide whether this is a read query or a non-read statement, and switch the per-section substitutions accordingly.
3. **Draft internally.** Settle the verdict, complexity rating, four scores, and risk flags as one set, holding competing readings side by side and committing to the one the inputs support.
4. **Check.** Confirm the verdict, rating, scores, and flags agree with each other and with the query as submitted, and that every finding points at real text.
5. **Print.** The seven sections, and nothing before the title that the rules did not require.

## 🚀 How to use it

```
/explain-sql SELECT ... FROM orders JOIN customers ...   ← query passed inline
/explain-sql ./reports/monthly_revenue.sql               ← query from a file
/explain-sql                                             ← full intake, four fields
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"explain this SQL query"*, *"what does this query actually do"*, *"review this query before I ship it"*, *"is this join going to double-count"*, *"explain this query for a non-technical stakeholder"*, *"score this query"*

The full procedure lives at [`lib/sql-breakdown/SKILL.md`](../lib/sql-breakdown/SKILL.md), and the slash command at [`commands/explain-sql.md`](../commands/explain-sql.md).

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

## `fullstack-feature-readme`

A plain-English feature README for a web application. Point it at a folder or a `.zip` holding the screens, the server, or both, and it returns three parts only: the app's name as the title, a short description of what it is and who it is for, and every user facing feature grouped into categories a non-technical user can read.

```
/fullstack-readme
```

Most app READMEs either list the tech stack or list what the author remembers building. This tool builds the feature list from the code itself. It reads every file in scope twice: a first pass that records each file and the features it adds, and a second pass that hunts for what the first one missed, such as an empty state, a profile option, an admin only screen, or a page that looks different depending on someone's role or plan. Only features traced to a real file make the list. Readme files, docs, changelogs, code comments, and tests are never taken as proof.

Every feature is then translated out of developer language. Token based sign in with refresh rotation becomes keeping you signed in securely between visits; a payment webhook becomes updating your plan automatically when a payment goes through or fails, with a note that it needs a Stripe account. Features that need a paid plan or an outside account say so, and so do features switched off by default. Categories get plain names, are ordered from largest to smallest, and are never padded to look fuller than the code is.

The writing rules are strict: no emojis, no en or em dashes, no hype words like "powerful" or "seamless", no installation, setup, tech stack, credits, license, changelog, FAQ, or support sections, and no headings beyond the title and the categories.

## 📋 Technical Overview

One slash command plus its procedure file `lib/fullstack-feature-readme/SKILL.md`, which loads the master template from `lib/fullstack-feature-readme/references/prompt-template.md`. The command `/fullstack-readme` takes a folder or `.zip` path as its argument, or asks for one, then asks whether to print the README or write it to `README.md`. In scope: frontend-only apps, backend-only APIs, full stack apps, and monorepos whose web client, API, admin panel, workers, and mobile app serve one product.

## ✨ Features

- 🔍 Tells screens and server code apart from the app's manifests, routes, pages, and request handlers
- 🧩 Treats the web client, API, admin panel, workers, and shared packages of one product as one app
- 🧭 Asks which one to document when a folder holds more than one unrelated app
- 🛑 Stops with one sentence when the code is only a library, SDK, command line tool, or config repo
- 🧱 Documents only finished features in starter templates, never placeholder or example pages
- 🔁 Two passes over every file, the second one hunting for small settings, empty states, admin screens, and role or plan based logic
- 🧾 Lists only features traced to real code; readmes, docs, changelogs, comments, and tests are not proof
- 🔌 Counts endpoints other apps can call even when no screen uses them
- 💳 Marks features that need a paid plan or an outside account, and features switched off by default
- 🗣️ Turns technical capabilities into everyday language a non-technical user understands
- 🗂️ Plain-English categories ordered from largest to smallest, never padded
- 🚫 No emojis, dashes, hype words, setup steps, or extra sections in the output
- 🛡️ Injection resistant. Text inside the code is described, never obeyed

## 🔄 How it works

1. **Intake.** Take the path from the argument or ask for it; ask whether to print or write the file.
2. **Identify.** Find the manifests and decide frontend, backend, or full stack; stop on no app, ask on more than one.
3. **First pass.** Read every file in scope and list the features each one adds.
4. **Second pass.** Re-scan for anything missed and add it.
5. **Translate.** Group into plain-English categories and rewrite each feature for a non-technical user.
6. **Check.** Title, description, categories only; every bullet traced; no emoji, dashes, or hype words.
7. **Deliver.** Print the README or write `README.md`.

## 🚀 How to use it

```
/fullstack-readme                        ← asks for the app
/fullstack-readme ~/code/my-app          ← a specific folder
/fullstack-readme ~/Downloads/my-app.zip ← a zipped app
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a feature list for my web app"*, *"what does this app actually do"*, *"make a README a customer can read"*, *"list every feature in plain English"*

For a beginner README with setup steps and a file tour use [`/readme-builder`](#readme-builder); for a WordPress theme or plugin use [`/wp-feature-readme`](wordpress.md#wordpress-feature-readme); for full onboarding docs use [`/explain-my-code`](#explain-my-code).

The full procedure lives at [`lib/fullstack-feature-readme/SKILL.md`](../lib/fullstack-feature-readme/SKILL.md), the slash command at [`commands/fullstack-readme.md`](../commands/fullstack-readme.md), and the master template at [`lib/fullstack-feature-readme/references/prompt-template.md`](../lib/fullstack-feature-readme/references/prompt-template.md).

---
