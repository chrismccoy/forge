# My Custom Made Skills

One Claude Code plugin - `forge` - holding 66 tools behind 77 slash commands.

Nothing here auto-triggers. Every tool is reached by typing its command, and each
command loads its own procedure file at that moment. No skill in this plugin can fire
on its own, compete with another installed skill, or sit in your context when you are
not using it.

Not sure which tool you want? Run `/forge` and pick a category, then a tool - or go straight
to a category with `/forge-wordpress`, `/forge-design`, `/forge-writing`, `/forge-devops`,
`/forge-cloud`, `/forge-security`, `/forge-cleanup`, `/forge-code`, `/forge-docs`, or
`/forge-utils`.

## Available commands

**WordPress**

- [`/wp-plugin`](docs/wordpress.md#wordpress-plugin). Builds a complete WordPress plugin from scratch, ready for the WordPress.org repository, with security, translations, and a clean uninstall all handled.
- [`/wp-build`](docs/wordpress.md#wp-builder-pro). Builds and implements custom WordPress code - themes, plugins, Gutenberg blocks, WooCommerce, and REST endpoints - with security and performance built in. Best when you're adding to or fixing a site you already have - a new feature, a slow page, a broken block.
- [`/wp-theme`](docs/wordpress.md#html-to-wordpress-theme). Converts static HTML/Tailwind files into installable WordPress themes.
- [`/wp-review`](docs/wordpress.md#wordpress-architect-review). Reviews a WordPress plugin or theme file by file, then returns ranked findings, a scorecard, and the top fixes to make.
- [`/wp-consult`](docs/wordpress.md#wordpress-consultant). A senior WordPress consulting audit covering architecture, performance, security, and scalability, ending with a 0-100 scorecard and summary.
- [`/wp-format`](docs/wordpress.md#wordpress-formatter). Formats a theme's template files to the WordPress coding standard - tabs, spacing, and array style - without changing how any page renders. It installs the tools, runs the fixer, and checks the result.
- [`/wp-menu-icons`](docs/wordpress.md#menu-icon-picker). Ports a searchable Font Awesome icon picker onto every Appearance > Menus item, integrated into a classic theme - click an icon instead of typing a class, with security gates and full rebranding.
- [`/wp-report-card`](docs/wordpress.md#wordpress-report-card). Scores a WordPress plugin or theme on ten areas out of 10, with an overall score and tier - just the scorecard table, no findings and no fixes.
- [`/wp-grade`](docs/wordpress.md#wordpress-grade). Grades one piece of WordPress code - a snippet or a single file - with a letter grade from A to F against a fixed rubric, what the code does, what it gets right, the real problems with the reason each one matters, the nitpicks kept separate, and a verdict on whether it is safe for a live site.
- [`/wp-performance`](docs/wordpress.md#wordpress-performance). Reads every file in a plugin or theme and reports what will break under traffic - unbounded queries, cache bypass, repeated queries inside loops, and cron that blocks itself. Starts fresh every run, so running it a second time is a real second opinion rather than a replay of the first.
- [`/wp-demo`](docs/wordpress.md#wp-demo-content). Builds a WP-CLI demo content importer for a classic theme: reads the theme's whole data model out of its code, writes `demo/demo-import.php`, fills an empty site with realistic posts, media, fields, menus and settings, tests it end to end on a throwaway SQLite site, and reports the theme's own bugs. The theme's files are never touched unless you agree to fixes.
- [`/wp-feature-readme`](docs/wordpress.md#wordpress-feature-readme). Writes a plain-English README for a WordPress theme or plugin: the name, a short description, and every user facing feature grouped into categories a site owner can read. Each feature is traced to real code, never taken from a readme or changelog, and the output carries no emojis, dashes, or hype words.

**Design & Frontend**

- [`/html-design-styles`](docs/design.md#html-design-styles). 53 named design styles with full color palettes, typography, and component patterns.
- [`/accessibility-audit`](docs/design.md#accessibility-audit). Checks a page, a folder, or a single component against the accessibility rules, tells you what is broken and why it matters, and can fix it for you. Command only, so it never fires on its own or clashes with another accessibility plugin.
- [`/design-system`](docs/design.md#design-system). Reverse-engineers the HTML and CSS of a page or folder into a reusable `DESIGN.md` - colors, typography, spacing, components, and the signature motifs that define the look - grounded in the real source, never invented.
- [`/tailwind-convert`](docs/design.md#tailwind-gut). Strips a page's custom CSS and rewrites it in Tailwind utilities, pixel-identical, detecting the Tailwind version first and promoting real design tokens into the theme config.
- [`/page-cloner`](docs/design.md#page-cloner). Copies a live URL into one self-contained working HTML file that looks and lays out like the original, built from the real rendered page and checked against it in a loop. Faithful copy, no redesign. Needs Claude in Chrome.
- [`/page-tailwindify`](docs/design.md#page-tailwindify). Rebuilds a live page's exact look in clean Tailwind, with the framework's generated class hashes replaced by real utility classes and every class traced to a real computed value. Needs Claude in Chrome.

**Writing & Content**

- [`/tech-blog-article`](docs/writing-and-content.md#tech-blog-article). Writes a technical blog post in the voice of a senior developer - a strong opening, clear code examples, and an honest look at the downsides.
- [`/tutorial-builder`](docs/writing-and-content.md#tutorial-builder). Turns code or a topic into a step-by-step, hands-on tutorial that teaches instead of describing, where every code block runs and shows its output, with a pre-publish checklist and a 1-5 speed score before you get it.
- [`/draft-contract`](docs/writing-and-content.md#contract-framework). Writes a clear, fair freelance or consulting contract from a few plain questions, covering the work, the payment, and who owns the finished result, with anything that depends on where you live flagged for you to check locally.
- [`/name-domains`](docs/writing-and-content.md#naming-strategist). Brainstorms 10 brandable, easy-to-say domain names for your SaaS, with a shortlist of the best three and a checklist to verify them.
- [`/language-tutor`](docs/writing-and-content.md#language-tutor). Translates and explains a phrase, or corrects and critiques your writing, with grammar notes, pronunciation tips, and better alternatives.

**DevOps & Data**

- [`/docker-compose-architect`](docs/devops-and-data.md#docker-compose-architect). Generates a secure, production docker-compose setup for your app - separate networks, persistent volumes, health checks, and secrets kept out of the file.
- [`/kubernetes-architect`](docs/devops-and-data.md#kubernetes-architect). Turns your app details into production-ready Kubernetes manifests, with health checks, resource limits, and security settings already included.
- [`/powershell-script-engine`](docs/devops-and-data.md#powershell-script-engine). Writes clean, production-ready PowerShell scripts with built-in help, logging, error handling, and safe handling of credentials and destructive actions.
- [`/jq`](docs/devops-and-data.md#jq). Builds copy-paste-ready jq one-liners to filter, reshape, and aggregate JSON from APIs and CLI tools, inspecting the JSON structure first and explaining each filter stage.

**Cloud & Architecture**

- [`/system-design`](docs/cloud-and-architecture.md#system-design). Designs a scalable system architecture from four answers - components and data flow, datastore and caching choices, sync versus async communication, and how it survives failure. Infrastructure only, no code.
- [`/terraform`](docs/cloud-and-architecture.md#terraform). Writes production Terraform split into `main.tf`, `variables.tf`, and `outputs.tf`, with least-privilege IAM, a pinned provider, and a state backend recommendation.
- [`/cicd-pipeline`](docs/cloud-and-architecture.md#cicd-pipeline). Builds an optimized pipeline file for GitHub Actions, GitLab CI, or Jenkins - dependency and Docker layer caching, test gates, and a checklist of every secret you need to set.
- [`/data-pipeline`](docs/cloud-and-architecture.md#data-pipeline). Designs an idempotent ETL or ELT pipeline - extraction strategy, Bronze/Silver/Gold layers, a conceptual DAG for your orchestrator, quality tests, and a backfill plan.
- [`/cloud-migration`](docs/cloud-and-architecture.md#cloud-migration). Plans a data-center exit on the 6 R's, with a landing zone built before any workload moves, a wave-by-wave roadmap, and risk and cost tables.
- [`/sre-audit`](docs/cloud-and-architecture.md#sre-audit). Designs the observability you are missing - SLIs and SLOs with error budgets, tracing spans that close your blind spots, burn-rate alerts instead of noisy thresholds, and a logging schema.
- [`/finops`](docs/cloud-and-architecture.md#finops). Cuts a cloud bill - immediate quick wins, structural architecture shifts, which commitments to actually buy, and the tagging and alarms to keep it from creeping back.
- [`/incident-report`](docs/cloud-and-architecture.md#incident-report). Turns incident notes into a blameless RCA - impact, timeline, a 5 Whys chain that ends at a systemic flaw, and action items that fix systems rather than asking people to be careful.

**Security**

- [`/threat-model`](docs/security.md#threat-model). Runs a STRIDE threat model over your system - trust boundaries, all six categories, every threat severity-rated with a mapped mitigation. Defensive only.
- [`/devsecops`](docs/security.md#devsecops). Audits a pipeline, IaC files, or cloud IAM for security flaws - blast radius, the compliance control each one violates, scanning gates to catch it next time, and runtime guardrails.
- [`/pentest-report`](docs/security.md#pentest-report). Turns notes from an authorized assessment into a formal vulnerability report - CVSS score with vector string, technical cause, sanitized reproduction steps, and both a short-term and long-term fix.

**Code Cleanup**

- [`/unslop`](docs/code-cleanup.md#unslop). Strips the AI-sounding voice out of comments, docstrings, and names in your code without changing how the code runs. Works across 19+ languages.
- [`/strip-unicode`](docs/code-cleanup.md#strip-unicode). Flattens messy Unicode - curly quotes, long dashes, ellipses, bullets, invisible characters - down to plain 7-bit ASCII that works everywhere, either cleaning a file in place or handing back tidied text, with a table of everything it changed. It swaps characters only; it never rewrites your words.
- [`/strip-emoji`](docs/code-cleanup.md#readme-emoji). Cleans the feature list in a README - strips the leading emoji off each feature bullet, turns a short label dash into a colon, and removes the long dashes from those bullets. Every other byte of the file comes back exactly as it went in.
- [`/strip-comments`](docs/code-cleanup.md#strip-comments). Deletes every comment in a codebase except the header at the top of each file, and except the comment-shaped things that are actually doing work - shebangs, linter and type-checker directives, build pragmas, license notices. It shows you a diff and waits for approval before writing anything, then parse-checks and audits what it changed.

**Code**

- [`/blueprint`](docs/code.md#app-blueprint). Produces a full production app blueprint from your idea - folder layout, data models, API design, dependencies, tests, and CI/CD.
- [`/e2e-tests`](docs/code.md#e2e-playwright). Adds a Playwright end-to-end suite to an existing Node/Express app without touching how the current tests run. Builds a throwaway install rebuilt from the app's own schema each run, a stand-in server for any paid API so the suite never makes a real call, one spec per user journey that needs a real browser, and `TESTING.md`. A real bug keeps its assertion, gets marked `test.fail()`, and is reported rather than fixed.
- [`/explain-my-code`](docs/code.md#explain-my-code). Reads a whole repo and writes one self-contained onboarding document - architecture, folder map, app flow, design patterns, risks - in 13 fixed sections with Mermaid diagrams, so anyone new to the project can get up to speed just by reading it.
- [`/codebase-to-mermaid`](docs/code.md#codebase-to-mermaid). Reads a codebase you don't know and draws accurate Mermaid flow, sequence, or class diagrams, with every box tied to a real file and line.
- [`/readme-builder`](docs/code.md#readme-builder). Reads a whole project and writes one beginner friendly `README.md` for it, in a fixed order, in plain everyday English, with hype words and long dashes kept out.
- [`/changelog-generator`](docs/code.md#changelog-generator). Writes a changelog your users can read from a repo's whole git history by reading the real code changes, not the commit messages, then sorts every change and saves `CHANGELOG.md`.
- [`/refactor`](docs/code.md#refactoring-analyst). Reviews your codebase and returns a prioritized refactoring plan, with every issue tied to a real file and line and a roadmap to fix them.
- [`/explain-sql`](docs/code.md#sql-breakdown). Reviews one SQL query without running it - a validation check, a clause-by-clause breakdown, the business question it answers, a quality scorecard out of 40, efficiency and risk flags, and a plain-English summary for someone who has never seen SQL.
- [`/docblock-rewrite`](docs/code.md#docblock-rewrite). Rewrites bulky PHPDoc and JSDoc blocks into short, plain-English one-line comments, backing up the originals first.
- [`/code-teacher`](docs/code.md#code-teacher). Turns a script into a teaching version of itself - a header block covering purpose, the tricky parts, the algorithm, usage, and requirements, then line-by-line comments explaining not just what each piece does but why it was written that way, the lessons worth taking away, and a check that the original code came back unchanged. Only comments are added.
- [`/fullstack-readme`](docs/code.md#fullstack-feature-readme). Writes a plain-English README for a web application, frontend, backend, or both: the name, a short description, and every user facing feature grouped into categories a non-technical user can read. Each feature is traced to real code, never taken from a readme, docs, or tests, and the output carries no emojis, dashes, hype words, or setup steps.

**Docs & Diagrams**

- [`/mermaid-to-ascii`](docs/docs-and-diagrams.md#mermaid-to-ascii). Turns a Mermaid diagram file into clean text-art you can paste into a comment, a README, or a terminal, saved next to the original as a `.txt`.
- [`/mermaid-sequence`](docs/docs-and-diagrams.md#mermaid-generator). Turns a plain bullet-point list of steps into one valid Mermaid sequence diagram, getting the arrow directions right and refusing cleanly when a step is missing its sender.
- [`/explain-prompt`](docs/docs-and-diagrams.md#prompt-dummy). Explains any AI prompt in plain, everyday English for a total beginner - what it is, what you get back, how it works, and how to use it - in eight fixed sections. It describes the prompt, it never runs it.
- [`/analyze-prompt`](docs/docs-and-diagrams.md#prompt-summary). A rigorous, review-ready breakdown of any AI prompt - anatomy, techniques, output contract, failure modes, and concrete improvements - with the full prompt quoted verbatim in an appendix.
- [`/rank-prompt`](docs/docs-and-diagrams.md#prompt-ranker). Audits a prompt's architecture and scores it - a tier and a score on one anchored scale, strengths and risks each tied to real language in the prompt, a row per analysis dimension, and the single change that would move it up the most. It reviews the prompt; it never obeys it.
- [`/prompt-rank-table`](docs/docs-and-diagrams.md#prompt-rank-table). The same eight-dimension prompt audit as `/rank-prompt`, reduced to three sections - a tier and score, one table row per dimension with the evidence quoted from the prompt itself, and a one-line verdict. Built for a fast read, or for putting several prompts side by side.
- [`/prompt-stencil`](docs/docs-and-diagrams.md#prompt-stencil). Turns one image prompt that already works into a reusable template - the wording that makes the look is locked, at most three things become swappable, and you get a copy-ready template plus filled examples proving the swap works.

**Utilities**

- [`/snippet`](docs/utilities.md#prompt-snippet). Asks three questions - language, task, where to put it - then writes one complete standalone script in any of 19 languages, with help text, exit codes, cleanup on interrupt, a dry run before anything destructive, streamed reads, atomic file replacement, and no secrets in the file.
- [`/session-stats`](docs/utilities.md#session-stats). Turns a Claude Code session into a single dark-theme HTML report - prompts, tool calls, edits, cost, and files changed. Runs fully offline.
- [`/token-audit`](docs/utilities.md#token-auditor). Grades how efficiently you used the model from four token counts. Input efficiency, cache strategy, and output discipline each get a letter from a fixed band table, weighted into one overall grade, with the single highest-impact fix named. The same numbers always produce the same letters, so it works as a benchmark tracked over time.
- [`/vgademo`](docs/utilities.md#vgademo). Generates a retro 1990s-style assembly graphics demo (MS-DOS, boot sector, or BIOS) after a few multiple-choice questions.
- [`/fix-formula`](docs/utilities.md#excel-formula-troubleshooter). Fixes broken Excel or Google Sheets formulas - names the real cause, returns a corrected formula, and explains it in plain English.
- [`/crash-report`](docs/utilities.md#crash-report). Explains a macOS crash report in plain English - what happened, the core issue, why it happened, why it crashed that way, and a fix for the developer and one for the user. Every claim has to name the field, thread, or line in the report that backs it up.

## Quick start

In any Claude Code session, run:

```
/plugin marketplace add chrismccoy/forge
/plugin install forge@forge
```

That is the whole install. One plugin, 77 commands, nothing running in the background.

Then either browse the whole catalog:

```
/forge
```

which asks for a category, then a tool, then runs it. Or jump straight to one category:

```
/forge-wordpress    # 12 WordPress tools
/forge-design       # 6 design and frontend tools
/forge-writing      # 5 writing and content tools
/forge-devops       # 4 DevOps and data tools
/forge-cloud        # 8 cloud and architecture tools
/forge-security     # 3 security tools
/forge-cleanup      # 4 code-cleanup tools
/forge-code         # 11 code tools
/forge-docs         # 7 docs and diagram tools
/forge-utils        # 6 utilities
```

Or call any tool directly:

```
# WordPress
/wp-plugin                      # scaffold a whole plugin from scratch
/wp-build                       # targeted work on an existing project
/wp-theme                       # static HTML -> installable theme
/wp-review                      # security, performance, architecture review
/wp-consult                     # 10-section consulting audit
/wp-format                      # apply WordPress Coding Standards formatting
/wp-menu-icons                  # searchable icon picker for menu items
/wp-report-card                 # scorecard-only review, /10 table plus tier
/wp-grade                       # letter grade A-F on one snippet or file
/wp-performance                 # cold full-file performance review
/wp-demo                        # WP-CLI demo content importer, built and tested
/wp-feature-readme              # plain-English feature README for a theme or plugin

# Design & Frontend
/html-design-styles             # 53 named design styles with full specs
/accessibility-audit            # WCAG audit and fixes
/design-system                  # reverse-engineer a page into a reusable DESIGN.md
/tailwind-convert               # rip out custom CSS, rewrite in Tailwind utilities
/page-cloner                    # copy a live URL into one self-contained HTML file
/page-tailwindify               # rebuild a live page's exact look in clean Tailwind

# Writing & Content
/tech-blog-article              # front-page-quality technical article
/tutorial-builder               # hands-on, step-by-step tutorial
/draft-contract                 # plain-English service agreement
/name-domains                   # 10 brandable SaaS domain candidates
/language-tutor                 # translate, or correct and critique writing

# DevOps & Data
/docker-compose-architect       # production docker-compose stack
/kubernetes-architect           # production Kubernetes manifests
/powershell-script-engine       # PSScriptAnalyzer-clean PowerShell script
/jq                             # one explained, copy-paste-ready jq command

# Cloud & Architecture
/system-design                  # scalable architecture blueprint, no code
/terraform                      # production HCL: main.tf, variables.tf, outputs.tf
/cicd-pipeline                  # optimized pipeline YAML + secrets checklist
/data-pipeline                  # idempotent ETL/ELT design with quality tests
/cloud-migration                # 6 R's plan, landing zone, wave roadmap
/sre-audit                      # SLOs, tracing, burn-rate alerts, log schema
/finops                         # cut the cloud bill without breaking availability
/incident-report                # blameless RCA from incident notes

# Security
/threat-model                   # STRIDE model with severity-rated threats
/devsecops                      # harden a pipeline, IaC, or cloud IAM config
/pentest-report                 # formal vulnerability report, sanitized PoC

# Code Cleanup
/unslop                         # strip AI voice without changing behavior
/strip-unicode                  # flatten messy Unicode to 7-bit ASCII
/strip-emoji                    # clean the emoji and long dashes out of a feature list
/strip-comments                 # delete comments, keep headers and pragmas

# Code
/blueprint                      # 11-section production app blueprint
/e2e-tests                      # Playwright end-to-end suite for a Node/Express app
/explain-my-code                # 13-section onboarding doc for a whole repo
/codebase-to-mermaid            # validated Mermaid diagrams with file:line cites
/readme-builder                 # beginner-friendly README.md
/changelog-generator            # changelog built from real diffs, not commit messages
/refactor                       # prioritized refactoring plan, file:line cited
/explain-sql                    # validate and break down one SQL query
/docblock-rewrite               # PHPDoc/JSDoc -> one-line plain-English comments
/code-teacher                   # annotate a script with teaching comments
/fullstack-readme               # plain-English feature README for a web app

# Docs & Diagrams
/mermaid-to-ascii               # Mermaid file -> monospace ASCII .txt
/mermaid-sequence               # bullet-point steps -> one Mermaid sequence diagram
/explain-prompt                 # any AI prompt in plain, beginner English
/analyze-prompt                 # review-ready prompt anatomy breakdown
/rank-prompt                    # tier and score a prompt's architecture
/prompt-rank-table              # the same audit as a tier, a table, one verdict
/prompt-stencil                 # cut a working image prompt into a reusable template

# Utilities
/snippet                        # a complete standalone script in 19 languages
/session-stats                  # this session's stats as standalone HTML
/token-audit                    # grade token efficiency from four counts
/vgademo                        # sizecoded 1990s assembly demo
/fix-formula                    # debug a broken Excel or Sheets formula
/crash-report                   # diagnose a macOS .ips or .crash report
```

Full descriptions of what each one does are below.

## Browsing the catalog

Eleven of the 77 commands are pickers. They do no work themselves - they show you what is
available, then hand off to the tool you choose.

### `/forge` - everything

Asks for a category, then a tool, then runs it. `AskUserQuestion` allows at most four
options per question, so the ten categories arrive over four screens, the first three
ending in `More...`:

```
Which category?      Which category?          Which category?     Which category?
  WordPress            DevOps & Data            Code Cleanup        Utilities
  Design & Frontend    Cloud & Architecture     Code                Back to page 1
  Writing & Content    Security                 Docs & Diagrams
  More...              More...                  More...
```

Pick a category and the second question lists that category's tools with a one-line
description each.

### `/forge-<category>` - one category, no category step

| Command | Tools | Screens |
|---------|-------|---------|
| `/forge-wordpress` | 12 | 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 |
| `/forge-design` | 6 | 3 + `More...`, then 3 |
| `/forge-writing` | 5 | 3 + `More...`, then 2 |
| `/forge-devops` | 4 | one |
| `/forge-cloud` | 8 | 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-security` | 3 | one |
| `/forge-cleanup` | 4 | one |
| `/forge-code` | 11 | 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-docs` | 7 | 3 + `More...`, then 3 + `More...`, then 1 |
| `/forge-utils` | 6 | 3 + `More...`, then 3 |



A picker screen looks like this - `/forge-wordpress`, page 1 of 4:

```
Which tool?
  Build a plugin from scratch    Full WordPress.org-ready scaffold: OOP classes,
                                 blocks, REST, i18n, uninstall.php.
  Targeted WordPress code        Add a feature, settings page, block, or endpoint
                                 to an existing project.
  HTML to WordPress theme        Convert static HTML into an installable theme
                                 with Tailwind and WCAG AA.
  More...                        The remaining WordPress tools.
```

Every screen also carries the built-in "Other" free-text field. Typing a tool name there
is treated the same as passing it as an argument.

### Skipping the picker

Pass a tool name and the picker never appears. Anything after the name becomes that
tool's own argument:

```
/forge jq                          → runs /jq, no questions from the picker
/forge-wordpress wp-format ~/themes/mytheme
                                  → runs /wp-format against that path
```

Both pickers accept a tool's `lib/` folder name as well as its command name, so
`/forge naming-strategist` finds `/name-domains` and `/forge wordpress-plugin` finds
`/wp-plugin`. Old names keep working inside the pickers even though the slash commands
themselves were renamed.

### Category commands only run their own tools

Name a tool a category picker does not own and it refuses rather than running it:

```
/forge-wordpress unslop
→ unslop is a Code Cleanup tool. Run /forge-cleanup, or /unslop directly.
```

Each category command carries a lookup table of every tool it does not own, along with
the owning picker, so the redirect always names the right destination. `/forge` has no such limit -
it owns the whole catalog.

### What happens when a picker starts a tool

Choosing a tool makes the picker read that tool's command file and follow it, which in
turn reads the tool's procedure from `lib/`. The picker announces the switch in one line
(`Running /wp-format.`) so you know which tool took over. Nothing is loaded until that
moment - see below.

## How it is put together

```
.claude-plugin/
  marketplace.json     one plugin entry
  plugin.json          the forge plugin manifest
commands/              77 command files - 66 tools, 11 pickers
lib/<tool>/
  SKILL.md             the tool's procedure, read only when its command runs
  references/          deep detail, loaded on demand by the procedure
  scripts/             deterministic runners
  assets/              output templates
```

`lib/` is deliberately not named `skills/`. Claude Code auto-discovers skills from a
`skills/` directory and keeps their descriptions loaded in every session. Putting the
procedure files under `lib/` takes them out of discovery entirely, so they exist only
as files that commands read on demand. No metadata in your context, no competing
triggers, no surprise activations.

Every command also carries `disable-model-invocation: true` in its frontmatter, which
removes it from the SlashCommand tool. So Claude cannot decide on its own to run
`/unslop` on your code or `/refactor` on your repo. These 77 commands fire when you
type them, and at no other time.

`/forge` starts a tool by reading the target command's file directly rather than calling
it as a slash command, so browsing still works with model invocation switched off.

---

## Command reference

Every tool's full write-up - what it does, how it works, how to use it - lives in `docs/`, one file per group. The [Available commands](#available-commands) list above links straight to each tool.

| Group | Tools | Reference |
|---|---|---|
| WordPress | 12 | [docs/wordpress.md](docs/wordpress.md) |
| Design & Frontend | 6 | [docs/design.md](docs/design.md) |
| Writing & Content | 5 | [docs/writing-and-content.md](docs/writing-and-content.md) |
| DevOps & Data | 4 | [docs/devops-and-data.md](docs/devops-and-data.md) |
| Cloud & Architecture | 8 | [docs/cloud-and-architecture.md](docs/cloud-and-architecture.md) |
| Security | 3 | [docs/security.md](docs/security.md) |
| Code Cleanup | 4 | [docs/code-cleanup.md](docs/code-cleanup.md) |
| Code | 11 | [docs/code.md](docs/code.md) |
| Docs & Diagrams | 7 | [docs/docs-and-diagrams.md](docs/docs-and-diagrams.md) |
| Utilities | 6 | [docs/utilities.md](docs/utilities.md) |


## Repo layout

```
.
├── .claude-plugin/
│   ├── marketplace.json      ← marketplace manifest (one entry: forge)
│   └── plugin.json           ← the forge plugin manifest
├── commands/                 ← 77 slash commands: 11 pickers + 66 tools
├── lib/                      ← 66 procedure folders (SKILL.md + bundled
│                                references/scripts/assets). NOT a skills/ dir,
│                                so nothing auto-loads; each is read only when
│                                its command runs.
├── docs/                     ← full write-up for each command group (linked above)
├── forge-screens/            ← ASCII screen maps + generated PNGs of every menu
├── FORGE_MAP.txt             ← the whole catalog on one screen
├── SUMMARY.md                ← the 66 tools compared by how much each does
└── README.md                 ← this file
```

Every tool is built the same way: `commands/<name>.md` (the slash command, carrying a
"Load first" banner) points at `lib/<procedure>/SKILL.md` (the actual procedure). Some
command names differ from their procedure folder - `SUMMARY.md` has the full map.
