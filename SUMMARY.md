# Toolkit Summary - Tool Analysis

A quick guide to what's in the `forge` plugin and how its 50 tools compare. Each tool is sorted into one of three groups by **how much it does** - not by how good it is. A "quick win" tool can be just as useful as a "full toolkit" one; it just does a smaller, more focused job.

**At a glance:** 1 quick win · 31 guided helpers · 16 full toolkits.

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
| `html-design-styles` | `/html-design-styles` | Restyles a web page in one of 53 named looks (bento, brutalist, glassmorphism, and more) |
| `vgademo` | `/vgademo` | Walks you through a few choices, then writes a tiny retro 1990s-style graphics demo |
| `tech-blog-article` | `/tech-blog-article` | Writes a polished technical blog post with a strong opening, clear examples, and honest trade-offs |
| `language-tutor` | `/language-tutor` | Translates and explains a phrase, or corrects your writing with grammar and pronunciation tips |
| `contract-framework` | `/draft-contract` | Writes a clear, fair freelance or consulting contract covering the work, the payment, and who owns the finished result, with anything legal flagged to check locally |
| `readme-builder` | `/readme-builder` | Reads a whole project and writes one beginner friendly README in a fixed order, plain English, with hype words and long dashes kept out |
| `tutorial-builder` | `/tutorial-builder` | Turns code or a topic into a step-by-step, hands-on tutorial that teaches, every code block runnable with its output shown, gated by a checklist and a 1-5 score |
| `naming-strategist` | `/name-domains` | Brainstorms 10 brandable domain names, picks the best 3, and gives you a checklist to verify them |
| `refactoring-analyst` | `/refactor` | Reviews your code and returns a prioritized clean-up plan, every issue tied to a real file and line |
| `kubernetes-architect` | `/kubernetes-architect` | Turns your app details into ready-to-use Kubernetes setup files |
| `docker-compose-architect` | `/docker-compose-architect` | Builds a secure Docker setup for your app - networks, storage, health checks, secrets kept safe |
| `app-blueprint` | `/blueprint` | Turns a one-line app idea into a full plan: folders, data, APIs, libraries, tests, and deployment |
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

## Full toolkits

The biggest tools. They run multi-step workflows, generate whole sets of files, or include built-in scripts and checklists. Best for bigger jobs where you want production-ready results, not just a draft.

| Tool | How you start it | What it does for you |
|--------|------------------|----------------------|
| `wp-builder-pro` | `/wp-build` | Builds and fixes custom WordPress code - themes, plugins, blocks, WooCommerce, and more |
| `wordpress-plugin` | `/wp-plugin` | Generates a complete, ready-to-submit WordPress plugin from scratch, security and cleanup included |
| `wordpress-architect-review` | `/wp-review` | Reviews a WordPress plugin or theme file by file, with a scorecard and the top fixes to make |
| `wordpress-report-card` | `/wp-report-card` | Prints just the review scorecard - ten areas out of 10 plus an overall score and tier, no findings and no fixes |
| `wordpress-formatter` | `/wp-format` | Formats a theme's template files to the WordPress standard - tabs, spacing, arrays - without changing how any page renders, and checks its own work |
| `menu-icon-picker` | `/wp-menu-icons` | Ports a searchable Font Awesome icon picker onto every menu item into a classic theme, rebranded to the theme's prefix, with security gates and static verification |
| `powershell-script-engine` | `/powershell-script-engine` | Writes clean, production-ready PowerShell scripts with logging, error handling, and safe credential use |
| `html-to-wordpress-theme` | `/wp-theme` | Converts your static HTML into an installable WordPress theme, checking its own work as it goes |
| `unslop` | `/unslop` | Strips the AI-sounding voice out of your comments and names without changing how the code runs |
| `strip-unicode` | `/strip-unicode` | Flattens messy Unicode - curly quotes, long dashes, invisible characters - down to plain ASCII, cleaning a file in place or handing back tidied text, with a table of what changed |
| `docblock-rewrite` | `/docblock-rewrite` | Rewrites bulky code comments into short one-liners anyone can read, backing up the originals first |
| `codebase-to-mermaid` | `/codebase-to-mermaid` | Reads a codebase you don't know and draws accurate diagrams, every box tied to a real file and line |
| `mermaid-to-ascii` | `/mermaid-to-ascii` | Redraws a Mermaid diagram file as plain text-art and saves it next to the original, ready to paste into a comment, README, or terminal |
| `explain-my-code` | `/explain-my-code` | Reads a whole codebase and writes one onboarding document - architecture, flow, patterns, and risks, with diagrams |
| `changelog-generator` | `/changelog-generator` | Writes a changelog from a repo's whole history by reading the real code changes, not the commit messages, then sorts each change and saves the file |
| `session-stats` | `/session-stats` | Turns a Claude Code session into a single shareable stats page - prompts, edits, cost, and files changed |
| `page-cloner` | `/page-cloner` | Copies a live web page into one self-contained working HTML file that matches the original, built from the real rendered page and checked against it in a loop, no redesign (needs Claude in Chrome) |
| `page-tailwindify` | `/page-tailwindify` | Rebuilds a live page's exact look in clean Tailwind, the framework's generated class hashes swapped for real utilities and every class traced to a real computed value (needs Claude in Chrome) |

## A few extra notes

**Seventeen tools have a command name that's different from the tool name:**

All eight WordPress tools share a short `wp-` command so they group together when you type `/wp`:

- `wordpress-plugin` → type `/wp-plugin`
- `wp-builder-pro` → type `/wp-build`
- `html-to-wordpress-theme` → type `/wp-theme`
- `wordpress-architect-review` → type `/wp-review`
- `wordpress-consultant` → type `/wp-consult`
- `wordpress-formatter` → type `/wp-format`
- `menu-icon-picker` → type `/wp-menu-icons`
- `wordpress-report-card` → type `/wp-report-card`

And nine others are shortened or renamed:

- `excel-formula-troubleshooter` → type `/fix-formula`
- `naming-strategist` → type `/name-domains`
- `contract-framework` → type `/draft-contract`
- `app-blueprint` → type `/blueprint`
- `refactoring-analyst` → type `/refactor`
- `tailwind-gut` → type `/tailwind-convert`
- `mermaid-generator` → type `/mermaid-sequence`
- `prompt-dummy` → type `/explain-prompt`
- `prompt-summary` → type `/analyze-prompt`

The other 33 use their own name as the command. Every tool has exactly one command.

**Ten of the 60 commands are pickers, not tools:**

`/forge` walks you through every category, then the tools in it. `/forge-wordpress`,
`/forge-design`, `/forge-writing`, `/forge-devops`, `/forge-cloud`, `/forge-security`,
`/forge-cleanup`, `/forge-docs`, and `/forge-utils` skip the category step and go straight
to one group. Lists longer than four
are paged behind a `More...` option, since that is the picker's limit. Passing a tool name
skips the questions entirely - `/forge-wordpress wp-format ~/themes/mytheme` runs that tool
against that path. A category command will not run a tool from another category; it names
the right command and stops. Full walkthrough in the README under "Browsing the catalog".

**How each one gets what it needs from you:**

- **Asks multiple-choice questions** (just pick from a menu): 35 tools - the easiest way to start
- **Asks a few questions directly:** 1 - `html-to-wordpress-theme`
- **Just works from what you point it at** (a file path, URL, paste, or your current session; asks one plain question only when you pass nothing): 12 - `changelog-generator`, `docblock-rewrite`, `mermaid-to-ascii`, `session-stats`, `wordpress-architect-review`, `design-system`, `tailwind-gut`, `mermaid-generator`, `prompt-dummy`, `prompt-summary`, `page-cloner`, `page-tailwindify`

**Every tool runs only when you type its command:**

None of these start on their own. Nothing here is registered as a skill, so a tool can't fire just because you typed a certain phrase, clash with another plugin that answers the same kind of request, or take up space in Claude's memory while you work on something else. Run `/forge` to browse the whole catalog, `/forge-wordpress` / `/forge-design` / `/forge-writing` / `/forge-devops` / `/forge-cloud` / `/forge-security` / `/forge-cleanup` / `/forge-docs` / `/forge-utils` to browse one category, or type the tool's own command directly.

Accessibility is a good example. Those tools are common, so if you have another one installed, two of them might both jump on "make this accessible" and you can't tell which one answered. Typing `/accessibility-audit` settles it, and the same is true for every one of the 50 tools here.
