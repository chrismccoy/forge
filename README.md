# My Custom Made Skills

One Claude Code plugin - `forge` - holding 57 tools behind 67 slash commands.

Nothing here auto-triggers. Every tool is reached by typing its command, and each
command loads its own procedure file at that moment. No skill in this plugin can fire
on its own, compete with another installed skill, or sit in your context when you are
not using it.

Not sure which tool you want? Run `/forge` and pick a category, then a tool - or go straight
to a category with `/forge-wordpress`, `/forge-design`, `/forge-writing`, `/forge-devops`,
`/forge-cloud`, `/forge-security`, `/forge-cleanup`, `/forge-docs`, or `/forge-utils`.

## Available commands

**WordPress**

- [`/wp-build`](docs/wordpress.md#wp-builder-pro). Builds and implements custom WordPress code - themes, plugins, Gutenberg blocks, WooCommerce, and REST endpoints - with security and performance built in. Best when you're adding to or fixing a site you already have - a new feature, a slow page, a broken block.
- [`/wp-plugin`](docs/wordpress.md#wordpress-plugin). Builds a complete WordPress plugin from scratch, ready for the WordPress.org repository, with security, translations, and a clean uninstall all handled.
- [`/wp-theme`](docs/wordpress.md#html-to-wordpress-theme). Converts static HTML/Tailwind files into installable WordPress themes.
- [`/wp-review`](docs/wordpress.md#wordpress-architect-review). Reviews a WordPress plugin or theme file by file, then returns ranked findings, a scorecard, and the top fixes to make.
- [`/wp-consult`](docs/wordpress.md#wordpress-consultant). A senior WordPress consulting audit covering architecture, performance, security, and scalability, ending with a 0-100 scorecard and summary.
- [`/wp-format`](docs/wordpress.md#wordpress-formatter). Formats a theme's template files to the WordPress coding standard - tabs, spacing, and array style - without changing how any page renders. It installs the tools, runs the fixer, and checks the result.
- [`/wp-menu-icons`](docs/wordpress.md#menu-icon-picker). Ports a searchable Font Awesome icon picker onto every Appearance > Menus item, integrated into a classic theme - click an icon instead of typing a class, with security gates and full rebranding.
- [`/wp-report-card`](docs/wordpress.md#wordpress-report-card). Scores a WordPress plugin or theme on ten areas out of 10, with an overall score and tier - just the scorecard table, no findings and no fixes.
- [`/wp-performance`](docs/wordpress.md#wordpress-performance). Reads every file in a plugin or theme and reports what will break under traffic - unbounded queries, cache bypass, repeated queries inside loops, and cron that blocks itself. Starts fresh every run, so running it a second time is a real second opinion rather than a replay of the first.

**Plan and Design**

- [`/blueprint`](docs/plan-and-design.md#app-blueprint). Produces a full production app blueprint from your idea - folder layout, data models, API design, dependencies, tests, and CI/CD.
- [`/html-design-styles`](docs/plan-and-design.md#html-design-styles). 53 named design styles with full color palettes, typography, and component patterns.
- [`/accessibility-audit`](docs/plan-and-design.md#accessibility-audit). Checks a page, a folder, or a single component against the accessibility rules, tells you what is broken and why it matters, and can fix it for you. Command only, so it never fires on its own or clashes with another accessibility plugin.
- [`/design-system`](docs/plan-and-design.md#design-system). Reverse-engineers the HTML and CSS of a page or folder into a reusable `DESIGN.md` - colors, typography, spacing, components, and the signature motifs that define the look - grounded in the real source, never invented.
- [`/tailwind-convert`](docs/plan-and-design.md#tailwind-gut). Strips a page's custom CSS and rewrites it in Tailwind utilities, pixel-identical, detecting the Tailwind version first and promoting real design tokens into the theme config.
- [`/page-cloner`](docs/plan-and-design.md#page-cloner). Copies a live URL into one self-contained working HTML file that looks and lays out like the original, built from the real rendered page and checked against it in a loop. Faithful copy, no redesign. Needs Claude in Chrome.
- [`/page-tailwindify`](docs/plan-and-design.md#page-tailwindify). Rebuilds a live page's exact look in clean Tailwind, with the framework's generated class hashes replaced by real utility classes and every class traced to a real computed value. Needs Claude in Chrome.

**Refactor, Map and Clean Up**

- [`/refactor`](docs/refactor-map-and-clean-up.md#refactoring-analyst). Reviews your codebase and returns a prioritized refactoring plan, with every issue tied to a real file and line and a roadmap to fix them.
- [`/codebase-to-mermaid`](docs/refactor-map-and-clean-up.md#codebase-to-mermaid). Reads a codebase you don't know and draws accurate Mermaid flow, sequence, or class diagrams, with every box tied to a real file and line.
- [`/mermaid-to-ascii`](docs/refactor-map-and-clean-up.md#mermaid-to-ascii). Turns a Mermaid diagram file into clean text-art you can paste into a comment, a README, or a terminal, saved next to the original as a `.txt`.
- [`/mermaid-sequence`](docs/refactor-map-and-clean-up.md#mermaid-generator). Turns a plain bullet-point list of steps into one valid Mermaid sequence diagram, getting the arrow directions right and refusing cleanly when a step is missing its sender.
- [`/explain-my-code`](docs/refactor-map-and-clean-up.md#explain-my-code). Reads a whole repo and writes one self-contained onboarding document - architecture, folder map, app flow, design patterns, risks - in 13 fixed sections with Mermaid diagrams, so anyone new to the project can get up to speed just by reading it.
- [`/docblock-rewrite`](docs/refactor-map-and-clean-up.md#docblock-rewrite). Rewrites bulky PHPDoc and JSDoc blocks into short, plain-English one-line comments, backing up the originals first.
- [`/unslop`](docs/refactor-map-and-clean-up.md#unslop). Strips the AI-sounding voice out of comments, docstrings, and names in your code without changing how the code runs. Works across 19+ languages.
- [`/strip-unicode`](docs/refactor-map-and-clean-up.md#strip-unicode). Flattens messy Unicode - curly quotes, long dashes, ellipses, bullets, invisible characters - down to plain 7-bit ASCII that works everywhere, either cleaning a file in place or handing back tidied text, with a table of everything it changed. It swaps characters only; it never rewrites your words.
- [`/changelog-generator`](docs/refactor-map-and-clean-up.md#changelog-generator). Writes a changelog your users can read from a repo's whole git history by reading the real code changes, not the commit messages, then sorts every change and saves `CHANGELOG.md`.
- [`/strip-comments`](docs/refactor-map-and-clean-up.md#strip-comments). Deletes every comment in a codebase except the header at the top of each file, and except the comment-shaped things that are actually doing work - shebangs, linter and type-checker directives, build pragmas, license notices. It shows you a diff and waits for approval before writing anything, then parse-checks and audits what it changed.
- [`/strip-emoji`](docs/refactor-map-and-clean-up.md#readme-emoji). Cleans the feature list in a README - strips the leading emoji off each feature bullet, turns a short label dash into a colon, and removes the long dashes from those bullets. Every other byte of the file comes back exactly as it went in.

**Servers and Scripting**

- [`/docker-compose-architect`](docs/servers-and-scripting.md#docker-compose-architect). Generates a secure, production docker-compose setup for your app - separate networks, persistent volumes, health checks, and secrets kept out of the file.
- [`/kubernetes-architect`](docs/servers-and-scripting.md#kubernetes-architect). Turns your app details into production-ready Kubernetes manifests, with health checks, resource limits, and security settings already included.
- [`/powershell-script-engine`](docs/servers-and-scripting.md#powershell-script-engine). Writes clean, production-ready PowerShell scripts with built-in help, logging, error handling, and safe handling of credentials and destructive actions.
- [`/jq`](docs/servers-and-scripting.md#jq). Builds copy-paste-ready jq one-liners to filter, reshape, and aggregate JSON from APIs and CLI tools, inspecting the JSON structure first and explaining each filter stage.

**Cloud and architecture**

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

**Domain Names**

- [`/name-domains`](docs/domain-names.md#naming-strategist). Brainstorms 10 brandable, easy-to-say domain names for your SaaS, with a shortlist of the best three and a checklist to verify them.

**Creative**

- [`/vgademo`](docs/creative.md#vgademo). Generates a retro 1990s-style assembly graphics demo (MS-DOS, boot sector, or BIOS) after a few multiple-choice questions.

**Data**

- [`/fix-formula`](docs/data.md#excel-formula-troubleshooter). Fixes broken Excel or Google Sheets formulas - names the real cause, returns a corrected formula, and explains it in plain English.
- [`/explain-sql`](docs/data.md#sql-breakdown). Reviews one SQL query without running it - a validation check, a clause-by-clause breakdown, the business question it answers, a quality scorecard out of 40, efficiency and risk flags, and a plain-English summary for someone who has never seen SQL.

**Writing and language**

- [`/tech-blog-article`](docs/writing-and-language.md#tech-blog-article). Writes a technical blog post in the voice of a senior developer - a strong opening, clear code examples, and an honest look at the downsides.
- [`/language-tutor`](docs/writing-and-language.md#language-tutor). Translates and explains a phrase, or corrects and critiques your writing, with grammar notes, pronunciation tips, and better alternatives.
- [`/draft-contract`](docs/writing-and-language.md#contract-framework). Writes a clear, fair freelance or consulting contract from a few plain questions, covering the work, the payment, and who owns the finished result, with anything that depends on where you live flagged for you to check locally.
- [`/readme-builder`](docs/writing-and-language.md#readme-builder). Reads a whole project and writes one beginner friendly `README.md` for it, in a fixed order, in plain everyday English, with hype words and long dashes kept out.
- [`/tutorial-builder`](docs/writing-and-language.md#tutorial-builder). Turns code or a topic into a step-by-step, hands-on tutorial that teaches instead of describing, where every code block runs and shows its output, with a pre-publish checklist and a 1-5 speed score before you get it.
- [`/explain-prompt`](docs/writing-and-language.md#prompt-dummy). Explains any AI prompt in plain, everyday English for a total beginner - what it is, what you get back, how it works, and how to use it - in eight fixed sections. It describes the prompt, it never runs it.
- [`/analyze-prompt`](docs/writing-and-language.md#prompt-summary). A rigorous, review-ready breakdown of any AI prompt - anatomy, techniques, output contract, failure modes, and concrete improvements - with the full prompt quoted verbatim in an appendix.
- [`/rank-prompt`](docs/writing-and-language.md#prompt-ranker). Audits a prompt's architecture and scores it - a tier and a score on one anchored scale, strengths and risks each tied to real language in the prompt, a row per analysis dimension, and the single change that would move it up the most. It reviews the prompt; it never obeys it.
- [`/prompt-stencil`](docs/writing-and-language.md#prompt-stencil). Turns one image prompt that already works into a reusable template - the wording that makes the look is locked, at most three things become swappable, and you get a copy-ready template plus filled examples proving the swap works.

**Debugging**

- [`/crash-report`](docs/debugging.md#crash-report). Explains a macOS crash report in plain English - what happened, the core issue, why it happened, why it crashed that way, and a fix for the developer and one for the user. Every claim has to name the field, thread, or line in the report that backs it up.

**Session tools**

- [`/session-stats`](docs/session-tools.md#session-stats). Turns a Claude Code session into a single dark-theme HTML report - prompts, tool calls, edits, cost, and files changed. Runs fully offline.

## Quick start

In any Claude Code session, run:

```
/plugin marketplace add chrismccoy/forge
/plugin install forge@forge
```

That is the whole install. One plugin, 67 commands, nothing running in the background.

Then either browse the whole catalog:

```
/forge
```

which asks for a category, then a tool, then runs it. Or jump straight to one category:

```
/forge-wordpress    # 9 WordPress tools
/forge-design       # 6 design and frontend tools
/forge-writing      # 5 writing and content tools
/forge-devops       # 5 DevOps and data tools
/forge-cloud        # 8 cloud and architecture tools
/forge-security     # 3 security tools
/forge-cleanup      # 6 code-cleanup tools
/forge-docs         # 10 docs and diagram tools
/forge-utils        # 5 utilities
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
/wp-performance                 # cold full-file performance review

# Design and frontend
/html-design-styles             # 53 named design styles with full specs
/accessibility-audit            # WCAG audit and fixes

# Writing and content
/tech-blog-article              # front-page-quality technical article
/tutorial-builder               # hands-on, step-by-step tutorial
/draft-contract                 # plain-English service agreement
/name-domains                   # 10 brandable SaaS domain candidates
/language-tutor                 # translate, or correct and critique writing

# DevOps and data
/docker-compose-architect       # production docker-compose stack
/kubernetes-architect           # production Kubernetes manifests
/powershell-script-engine       # PSScriptAnalyzer-clean PowerShell script
/jq                             # one explained, copy-paste-ready jq command
/explain-sql                    # validate and break down one SQL query

# Cloud and architecture
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

# Code cleanup
/unslop                         # strip AI voice without changing behavior
/strip-unicode                  # flatten messy Unicode to 7-bit ASCII
/strip-comments                 # delete comments, keep headers and pragmas
/strip-emoji                    # clean the emoji and long dashes out of a feature list
/docblock-rewrite               # PHPDoc/JSDoc -> one-line plain-English comments
/refactor                       # cited refactoring plan, read-only

# Docs and diagrams
/explain-my-code                # 13-section onboarding doc for a whole repo
/codebase-to-mermaid            # validated Mermaid diagrams with file:line cites
/mermaid-to-ascii               # Mermaid file -> monospace ASCII .txt
/readme-builder                 # beginner-friendly README.md
/changelog-generator            # changelog built from real diffs, not commit messages
/explain-prompt                 # any AI prompt in plain, beginner English
/analyze-prompt                 # review-ready prompt anatomy breakdown
/rank-prompt                    # tier and score a prompt's architecture
/prompt-stencil                 # cut a working image prompt into a reusable template

# Utilities
/blueprint                      # 11-section production app blueprint
/session-stats                  # this session's stats as standalone HTML
/vgademo                        # sizecoded 1990s assembly demo
/fix-formula                    # debug a broken Excel or Sheets formula
/crash-report                   # diagnose a macOS .ips or .crash report
```

Full descriptions of what each one does are below.

## Browsing the catalog

Ten of the 67 commands are pickers. They do no work themselves - they show you what is
available, then hand off to the tool you choose.

### `/forge` - everything

Asks for a category, then a tool, then runs it. `AskUserQuestion` allows at most four
options per question, so the nine categories arrive over three screens, the first two
ending in `More...`:

```
Which category?          Which category?          Which category?
  WordPress                DevOps & Data            Code Cleanup
  Design & Frontend        Cloud & Architecture     Docs & Diagrams
  Writing & Content        Security                 Utilities
  More...                  More...                  Back to page 1
```

Pick a category and the second question lists that category's tools with a one-line
description each.

### `/forge-<category>` - one category, no category step

| Command | Tools | Screens |
|---------|-------|---------|
| `/forge-wordpress` | 9 | 3 + `More...`, then 3 + `More...`, then 3 |
| `/forge-design` | 6 | 3 + `More...`, then 3 |
| `/forge-writing` | 5 | 3 + `More...`, then 2 |
| `/forge-devops` | 5 | 3 + `More...`, then 2 |
| `/forge-cloud` | 8 | 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-security` | 3 | one |
| `/forge-cleanup` | 6 | 3 + `More...`, then 3 |
| `/forge-docs` | 10 | 3 + `More...`, three times, then 1 |
| `/forge-utils` | 5 | 3 + `More...`, then 2 |

A picker screen looks like this - `/forge-wordpress`, page 1 of 2:

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
commands/              67 command files - 57 tools, 10 pickers
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
`/unslop` on your code or `/refactor` on your repo. These 67 commands fire when you
type them, and at no other time.

`/forge` starts a tool by reading the target command's file directly rather than calling
it as a slash command, so browsing still works with model invocation switched off.

---

## Command reference

Every tool's full write-up - what it does, how it works, how to use it - lives in `docs/`, one file per group. The [Available commands](#available-commands) list above links straight to each tool.

| Group | Tools | Reference |
|---|---|---|
| WordPress | 9 | [docs/wordpress.md](docs/wordpress.md) |
| Plan and Design | 7 | [docs/plan-and-design.md](docs/plan-and-design.md) |
| Refactor, Map and Clean Up | 11 | [docs/refactor-map-and-clean-up.md](docs/refactor-map-and-clean-up.md) |
| Servers and Scripting | 4 | [docs/servers-and-scripting.md](docs/servers-and-scripting.md) |
| Cloud and Architecture | 8 | [docs/cloud-and-architecture.md](docs/cloud-and-architecture.md) |
| Security | 3 | [docs/security.md](docs/security.md) |
| Domain Names | 1 | [docs/domain-names.md](docs/domain-names.md) |
| Creative | 1 | [docs/creative.md](docs/creative.md) |
| Data | 2 | [docs/data.md](docs/data.md) |
| Writing and language | 9 | [docs/writing-and-language.md](docs/writing-and-language.md) |
| Debugging | 1 | [docs/debugging.md](docs/debugging.md) |
| Session tools | 1 | [docs/session-tools.md](docs/session-tools.md) |

## Repo layout

```
.
├── .claude-plugin/
│   ├── marketplace.json      ← marketplace manifest (one entry: forge)
│   └── plugin.json           ← the forge plugin manifest
├── commands/                 ← 67 slash commands: 10 pickers + 57 tools
├── lib/                      ← 57 procedure folders (SKILL.md + bundled
│                                references/scripts/assets). NOT a skills/ dir,
│                                so nothing auto-loads; each is read only when
│                                its command runs.
├── docs/                     ← full write-up for each command group (linked above)
├── forge-screens/            ← ASCII screen maps + generated PNGs of every menu
├── FORGE_MAP.txt             ← the whole catalog on one screen
├── SUMMARY.md                ← the 57 tools compared by how much each does
└── README.md                 ← this file
```

Every tool is built the same way: `commands/<name>.md` (the slash command, carrying a
"Load first" banner) points at `lib/<procedure>/SKILL.md` (the actual procedure). Some
command names differ from their procedure folder - `SUMMARY.md` has the full map.
