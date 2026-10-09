# Toolkit Summary - Tool Analysis

A quick guide to what's in the `forge` plugin and how its 83 tools compare. Each tool is sorted into one of three groups by **how much it does** - not by how good it is. A "quick win" tool can be just as useful as a "full toolkit" one; it just does a smaller, more focused job.

**At a glance:** 1 quick win · 48 guided helpers · 34 full toolkits.

## Small Utils

Small, focused, one-and-done. You give it something, it hands one clear answer straight back.

| Tool | How you start it | What it does for you |
|--------|------------------|----------------------|
| `excel-formula-troubleshooter` | `/fix-formula` | Paste a broken Excel or Google Sheets formula and get the fixed version, with an explanation of what went wrong |

## Guided helpers

These ask you a few questions (or take a short description), then produce a complete, well-organized result in one go. Great when you know roughly what you want and want an expert to shape it.

| Tool | How you start it | What it does for you |
|--------|------------------|----------------------|
| `jq` | `/jq` | Builds a ready-to-paste command for pulling data out of JSON, and explains each step |
| `sql-breakdown` | `/explain-sql` | Reviews one SQL query without running it - what each clause does, the business question it answers, a score out of 40, and what could give you wrong numbers |
| `regex-tutor` | `/explain-regex` | Explains one regular expression in plain English across 11 sections - every piece, real examples that match and don't, the traps, whether a long input can freeze it, and safer alternatives - with every example checked against real regex engines |
| `html-design-styles` | `/html-design-styles` | Restyles a web page in one of 53 named looks (bento, brutalist, glassmorphism, and more) |
| `vgademo` | `/vgademo` | Walks you through a few choices, then writes a tiny retro 1990s-style graphics demo |
| `tech-blog-article` | `/tech-blog-article` | Writes a polished technical blog post with a strong opening, clear examples, and honest trade-offs |
| `language-tutor` | `/language-tutor` | Translates and explains a phrase, or corrects your writing with grammar and pronunciation tips |
| `github-bio` | `/github-bio` | Asks six questions one at a time, then writes five GitHub profile bios in five styles, each checked by a script to fit GitHub's 160-character limit |
| `book-summary` | `/book-summary` | Asks about the book, language, spoilers, and an optional social post in one message, checks it really knows the book, then writes a sectioned summary that paraphrases instead of inventing quotes |
| `claudepuppy` | `/claudepuppy` | Takes a blog draft and a dog flavor (light, medium, or strong), asking for whichever is missing, then rewrites the post in The Claude Puppy dog-trainer voice with every fact and code block kept exact and any added sentence listed |
| `contract-framework` | `/draft-contract` | Writes a clear, fair freelance or consulting contract covering the work, the payment, and who owns the finished result, with anything legal flagged to check locally |
| `readme-builder` | `/readme-builder` | Reads a whole project and writes one beginner friendly README in a fixed order, plain English, with hype words and long dashes kept out |
| `tutorial-builder` | `/tutorial-builder` | Turns code or a topic into a step-by-step, hands-on tutorial that teaches, every code block runnable with its output shown, gated by a checklist and a yes/no quality gate |
| `naming-strategist` | `/name-domains` | Brainstorms 10 brandable domain names, picks the best 3, and gives you a checklist to verify them |
| `refactoring-analyst` | `/refactor` | Reviews your code and returns a prioritized clean-up plan, every issue tied to a real file and line |
| `kubernetes-architect` | `/kubernetes-architect` | Turns your app details into ready-to-use Kubernetes setup files |
| `docker-compose-architect` | `/docker-compose-architect` | Builds a secure Docker setup for your app - networks, storage, health checks, secrets kept safe |
| `wordpress-consultant` | `/wp-consult` | A senior WordPress audit across architecture, performance, security, and scaling, with a 0-100 scorecard |
| `accessibility-audit` | `/accessibility-audit` | Checks a page, folder, or pasted component for accessibility problems, explains why each one matters, fixes them if you ask, and tells you which keys to test |
| `system-design` | `/system-design` | Designs how a system should be built to handle real load - components, data flow, database choice, and what breaks first |
| `terraform` | `/terraform` | Writes ready-to-apply Terraform split into three files, with tight permissions and somewhere safe to keep the state |
| `cicd-pipeline` | `/cicd-pipeline` | Builds a build-and-deploy pipeline that caches properly, plus a checklist of every secret you need to add |
| `data-pipeline` | `/data-pipeline` | Designs a data pipeline you can safely re-run - where the data comes from, how it's shaped, and what to do when it breaks |
| `cloud-migration` | `/cloud-migration` | Plans a move out of your data center: what to lift, what to rebuild, the foundation to build first, and the risks |
| `sre-audit` | `/sre-audit` | Works out what to measure and when to wake someone up - reliability targets, tracing, alerts that aren't noise, and logging |
| `finops` | `/finops` | Finds where the cloud bill is leaking, what to fix now, what to restructure, and which discounts are actually worth buying |
| `incident-report` | `/incident-report` | Turns your notes about an outage into a write-up that blames the system, not a person, and lists what to fix |
| `threat-model` | `/threat-model` | Walks your system through all six kinds of attack, rates how bad each risk is, and pairs every one with a fix |
| `devsecops` | `/devsecops` | Audits a pipeline, infrastructure file, or cloud permission set for security holes, and shows how to catch them next time |
| `pentest-report` | `/pentest-report` | Turns notes from a security test you were authorized to run into a formal report with a score and a fix |
| `design-system` | `/design-system` | Reverse-engineers a page's HTML and CSS into a reusable DESIGN.md - colors, type, spacing, components, and the signature motifs that define the look, all pulled from the real source |
| `tailwind-gut` | `/tailwind-convert` | Strips a page's custom CSS and rewrites it in Tailwind utilities, pixel-identical, with a short report of what moved to config and what had to stay as CSS |
| `mermaid-generator` | `/mermaid-sequence` | Turns a bullet-point list of process steps into one valid Mermaid sequence diagram |
| `prompt-dummy` | `/explain-prompt` | Explains any AI prompt in plain beginner English across eight fixed sections |
| `prompt-summary` | `/analyze-prompt` | Breaks an AI prompt down for review - anatomy, techniques, failure modes, and concrete improvements |
| `prompt-ranker` | `/rank-prompt` | Scores a prompt's architecture on one anchored scale, with every strength and risk tied to real language in it, and names the one change worth making first |
| `prompt-rank-table` | `/prompt-rank-table` | The same audit shrunk to three sections - a tier and score, one table row per dimension with the evidence quoted, and a one-line verdict |
| `prompt-stencil` | `/prompt-stencil` | Turns an image prompt that already works into a reusable template - the look stays locked, up to three things become swappable, with filled examples proving the swap |
| `prompt-bloat` | `/prompt-bloat` | Cleans up an overengineered prompt or skill file - branding, invented citations, self-scores, and unused settings come out, every rule stays, and you get a list of each cut, a check that nothing was lost, and an offer to save the result |
| `prompt-audit` | `/prompt-audit` | Scores a prompt out of 100 (115 for agents) across nine dimensions, every deduction quoting the passage behind it, then ranks the fixes, writes three drop-in replacements, and projects the score once they are in |
| `readme-emoji` | `/strip-emoji` | Cleans a README's feature list - leading emoji off each bullet, a short label dash becomes a colon, long dashes gone, every other byte returned untouched |
| `crash-report` | `/crash-report` | Explains a macOS crash report in plain English across six sections, every claim pointing at the field, thread, or line that backs it up |
| `wordpress-grade` | `/wp-grade` | Grades one piece of WordPress code A to F against a fixed rubric, with strengths, real problems, nitpicks kept separate, and a ship-or-not verdict |
| `wordpress-feature-readme` | `/wp-feature-readme` | Reads a WordPress theme or plugin and writes a plain-English README: the name, a short description, and every feature a site owner would notice, grouped into categories and traced to real code |
| `fullstack-feature-readme` | `/fullstack-readme` | Reads a web app's screens, server, or both and writes a plain-English README: the name, a short description, and every feature a user would notice, grouped into categories and traced to real code |
| `code-teacher` | `/code-teacher` | Hands a script back as a teaching version of itself - a header block, comments explaining what and why, and the lessons worth taking away. Only comments are added |
| `code-explainer` | `/explain-code` | Explains one snippet, file, or function at your level - as a full tutorial, a quick summary, interview prep, or line by line - with risks marked confirmed or possible and an offer to save it as Markdown |
| `token-auditor` | `/token-audit` | Grades how efficiently you used the model from four token counts - input, cache and output each get a letter, weighted into one overall grade, with the single fix worth making first |

## Full toolkits

The biggest tools. They run multi-step workflows, generate whole sets of files, or include built-in scripts and checklists. Best for bigger jobs where you want production-ready results, not just a draft.

| Tool | How you start it | What it does for you |
| `app-blueprint` | `/blueprint` | Turns an app idea - yours, or a random pick from 2,600 examples - into a full plan: folders, data, APIs, libraries, tests, deployment, security, and risks. Then a fresh reviewer checks it against fact sheets for your stack, a throwaway skeleton proves it builds, and short experiments test what's still risky |
|--------|------------------|----------------------|
| `wp-builder-pro` | `/wp-build` | Builds and fixes custom WordPress code - themes, plugins, blocks, WooCommerce, and more |
| `wordpress-plugin` | `/wp-plugin` | Generates a complete, ready-to-submit WordPress plugin from scratch, security and cleanup included |
| `wordpress-architect-review` | `/wp-review` | Reviews a WordPress plugin or theme file by file, with a scorecard and the top fixes to make |
| `wordpress-report-card` | `/wp-report-card` | Scores a plugin or theme on ten areas out of 10, with an overall score and tier - just the scorecard, no findings and no fixes |
| `wordpress-performance` | `/wp-performance` | Reads every file in a plugin or theme and reports what will break under traffic, starting fresh each run so a second pass is a real second opinion |
| `wordpress-formatter` | `/wp-format` | Formats a theme's template files to the WordPress standard - tabs, spacing, arrays - without changing how any page renders, and checks its own work |
| `menu-icon-picker` | `/wp-menu-icons` | Ports a searchable Font Awesome icon picker onto every menu item into a classic theme, rebranded to the theme's prefix, with security gates and static verification |
| `powershell-script-engine` | `/powershell-script-engine` | Writes clean, production-ready PowerShell scripts with logging, error handling, and safe credential use |
| `html-to-wordpress-theme` | `/wp-theme` | Converts your static HTML into an installable WordPress theme, checking its own work as it goes |
| `unslop` | `/unslop` | Strips the AI-sounding voice out of your comments and names without changing how the code runs |
| `strip-comments` | `/strip-comments` | Deletes every comment except the header at the top of each file, keeping the shebangs, pragmas, and licence notices that only look like comments, and showing you a diff to approve before it writes |
| `strip-unicode` | `/strip-unicode` | Flattens messy Unicode - curly quotes, long dashes, invisible characters - down to plain ASCII, cleaning a file in place or handing back tidied text, with a table of what changed |
| `docblock-rewrite` | `/docblock-rewrite` | Rewrites bulky code comments into short one-liners anyone can read, backing up the originals first |
| `codebase-to-mermaid` | `/codebase-to-mermaid` | Reads a codebase you don't know and draws accurate diagrams, every box tied to a real file and line |
| `mermaid-to-ascii` | `/mermaid-to-ascii` | Redraws a Mermaid diagram file as plain text-art and saves it next to the original, ready to paste into a comment, README, or terminal |
| `explain-my-code` | `/explain-my-code` | Reads a whole codebase and writes one onboarding document - architecture, flow, patterns, and risks, with diagrams |
| `changelog-generator` | `/changelog-generator` | Writes a changelog from a repo's whole history by reading the real code changes, not the commit messages, then sorts each change and saves the file |
| `session-stats` | `/session-stats` | Turns a Claude Code session into a single shareable stats page - prompts, edits, cost, and files changed |
| `page-cloner` | `/page-cloner` | Copies a live web page into one self-contained working HTML file that matches the original, built from the real rendered page and checked against it in a loop, no redesign (needs Claude in Chrome) |
| `wp-demo-content` | `/wp-demo` | Reads a theme's whole data model, then writes and tests a one-file importer that fills an empty site with realistic demo content - posts, photos, video, comments, menus and every setting the theme reads - and hands back a list of the theme's own bugs |
| `wordpress-wp-cli` | `/wp-cli` | Writes bash scripts that run one WP-CLI task across every WordPress site on a server - cleanup, updates, users, media, backups, settings - dry run by default with a typed confirmation, one site's failure never stopping the rest, and a summary table at the end. Also reviews and fixes scripts you already have, and tests every script against a stub before handing it over |
| `wordpress-block-theme` | `/wp-block-theme` | Builds a complete full-site-editing block theme from a short brief - theme.json version 3, templates, parts, patterns, style variations, local fonts - and reviews it until it ships, or reviews an existing block theme by file and line with a ship verdict |
| `wordpress-classic-to-block` | `/wp-classic-to-block` | Moves a classic PHP theme to a block theme - first a plan that sorts every file and view by how much work it needs, lists every stored value the theme reads, and gives an hour estimate and a verdict, then the converted theme with custom post types, metaboxes, and shortcodes moved into a companion plugin, every meta key, option, and URL kept |
| `wordpress-theme-bug-audit` | `/wp-bug-audit` | Reads every file in a theme, runs about 160 numbered bug checks, tests everything on throwaway sites across your customers' PHP versions, and writes a verified bug list and coverage report - changing nothing unless you ask for fixes |
| `wordpress-theme-mockup` | `/wp-mockup` | Builds a clickable static HTML mockup of a classic WordPress theme in one of 53 named design styles - every template as a linked page with a shared header, sidebar, and footer - ready for `/wp-theme` to turn into a real theme |
| `wordpress-doc-pass` | `/wp-doc-pass` | Documents a whole plugin without changing its code - full PHPDoc and JSDoc on every file, function, and hook in the plugin's own coding standard, written by parallel agents, with a checker that proves only comments changed and a ranked list of the bugs it found along the way |
| `wordpress-modernize` | `/wp-modernize` | Moves a whole plugin from the WordPress Coding Standards to PSR-12, a PSR-4 `src/` tree, and strict PHP 8.1 types in eight tested and tagged phases - outward-facing names unchanged, stored names kept working through aliases, and an upgrade test from the old version to prove it |
| `wordpress-plugin-submission` | `/wp-submission` | Decides whether a built plugin is ready for WordPress.org review - maps code, readme, and Plugin Check output to the current official guidelines, catches trialware and undisclosed services, and returns one verdict with the smallest fix list and a factual reply to the review team, never promising approval |
| `page-tailwindify` | `/page-tailwindify` | Rebuilds a live page's exact look in clean Tailwind, the framework's generated class hashes swapped for real utilities and every class traced to a real computed value (needs Claude in Chrome) |
| `prompt-snippet` | `/snippet` | Asks three questions, then writes a complete standalone script in any of 19 languages - help text, exit codes, cleanup on interrupt, a dry run before anything destructive, and no secrets in the file |
| `e2e-playwright` | `/e2e-tests` | Adds a browser test suite to a Node app: a throwaway database rebuilt each run, a stand-in for any paid API so no real one is called, one test per user journey, and a report of every bug and every change it made |
| `script-refactor` | `/script-refactor` | Cleans up the bash and Python scripts another program or AI agent runs without changing their output, exit codes, or files, runs old and new side by side to prove it, and holds every behavior-changing bug fix for your approval |
| `blueprint-forge` | `/blueprint-forge` | Reads a whole codebase and writes a 14-section blueprint detailed enough to rebuild the app without the original code - every route, model, export, and environment variable, secrets never copied, checked by a bundled script - or rebuilds a working app from one, plan first and each step verified, with an optional check that lists anything the rebuild lost |

## A few extra notes

**Thirty-eight tools have a command name that's different from the tool name:**

All twenty WordPress tools share a short `wp-` command so they group together when you type `/wp`:

- `wordpress-plugin` → type `/wp-plugin`
- `wp-builder-pro` → type `/wp-build`
- `html-to-wordpress-theme` → type `/wp-theme`
- `wordpress-architect-review` → type `/wp-review`
- `wordpress-consultant` → type `/wp-consult`
- `wordpress-formatter` → type `/wp-format`
- `menu-icon-picker` → type `/wp-menu-icons`
- `wordpress-report-card` → type `/wp-report-card`
- `wordpress-grade` → type `/wp-grade`
- `wordpress-performance` → type `/wp-performance`
- `wp-demo-content` → type `/wp-demo`
- `wordpress-feature-readme` → type `/wp-feature-readme`
- `wordpress-wp-cli` → type `/wp-cli`
- `wordpress-block-theme` → type `/wp-block-theme`
- `wordpress-classic-to-block` → type `/wp-classic-to-block`
- `wordpress-theme-bug-audit` → type `/wp-bug-audit`
- `wordpress-theme-mockup` → type `/wp-mockup`
- `wordpress-doc-pass` → type `/wp-doc-pass`
- `wordpress-modernize` → type `/wp-modernize`
- `wordpress-plugin-submission` → type `/wp-submission`

And eighteen others are shortened or renamed:

- `excel-formula-troubleshooter` → type `/fix-formula`
- `naming-strategist` → type `/name-domains`
- `contract-framework` → type `/draft-contract`
- `app-blueprint` → type `/blueprint`
- `refactoring-analyst` → type `/refactor`
- `tailwind-gut` → type `/tailwind-convert`
- `mermaid-generator` → type `/mermaid-sequence`
- `prompt-dummy` → type `/explain-prompt`
- `prompt-summary` → type `/analyze-prompt`
- `prompt-ranker` → type `/rank-prompt`
- `readme-emoji` → type `/strip-emoji`
- `sql-breakdown` → type `/explain-sql`
- `e2e-playwright` → type `/e2e-tests`
- `prompt-snippet` → type `/snippet`
- `token-auditor` → type `/token-audit`
- `fullstack-feature-readme` → type `/fullstack-readme`
- `regex-tutor` → type `/explain-regex`
- `code-explainer` → type `/explain-code`

The other 45 use their own name as the command. Every tool has exactly one command.

**Eleven of the 94 commands are pickers, not tools:**

`/forge` walks you through every category, then the tools in it. `/forge-wordpress`,
`/forge-design`, `/forge-writing`, `/forge-devops`, `/forge-cloud`, `/forge-security`,
`/forge-cleanup`, `/forge-code`, `/forge-docs`, and `/forge-utils` skip the category step
and go straight to one of the ten categories - 20, 6, 8, 4, 8, 3, 4, 15, 9 and 6 tools
respectively. Lists longer than four
are paged behind a `More...` option, since that is the picker's limit. Passing a tool name
skips the questions entirely - `/forge-wordpress wp-format ~/themes/mytheme` runs that tool
against that path. A category command will not run a tool from another category; it names
the right command and stops. Every tool's write-up lives in the `docs/` file for its category, one file per category. Full walkthrough in the README under "Browsing the catalog".

**How each one gets what it needs from you:**

- **Asks multiple-choice questions** (just pick from a menu): 59 tools - the easiest way to start
- **Asks a few questions directly:** 4 - `html-to-wordpress-theme`, `github-bio`, `book-summary`, `claudepuppy`
- **Just works from what you point it at** (a file path, URL, paste, or your current session; asks one plain question only when you pass nothing): 20 - `changelog-generator`, `docblock-rewrite`, `mermaid-to-ascii`, `session-stats`, `wordpress-architect-review`, `wordpress-performance`, `wordpress-plugin-submission`, `design-system`, `tailwind-gut`, `mermaid-generator`, `prompt-dummy`, `prompt-summary`, `readme-emoji`, `page-cloner`, `page-tailwindify`, `wordpress-grade`, `script-refactor`, `blueprint-forge`, `prompt-bloat`, `prompt-audit`

**Every tool runs only when you type its command:**

None of these start on their own. Nothing here is registered as a skill, so a tool can't fire just because you typed a certain phrase, clash with another plugin that answers the same kind of request, or take up space in Claude's memory while you work on something else. Run `/forge` to browse the whole catalog, `/forge-wordpress` / `/forge-design` / `/forge-writing` / `/forge-devops` / `/forge-cloud` / `/forge-security` / `/forge-cleanup` / `/forge-code` / `/forge-docs` / `/forge-utils` to browse one category, or type the tool's own command directly.

Accessibility is a good example. Those tools are common, so if you have another one installed, two of them might both jump on "make this accessible" and you can't tell which one answered. Typing `/accessibility-audit` settles it, and the same is true for every one of the 83 tools here.
