# My Custom Made Skills

One Claude Code plugin - `forge` - holding 99 commands and 11 pickers.

Nothing here auto-triggers. Every tool is reached by typing its command, and each
command loads its own procedure file at that moment. No skill in this plugin can fire
on its own, compete with another installed skill, or sit in your context when you are
not using it.

Not sure which command you want? Run `/forge` and pick a category, then a command - or go straight
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
- [`/wp-cli`](docs/wordpress.md#wordpress-wp-cli). Writes bash scripts that run one WP-CLI task across every WordPress site on a server, or on one site: comment and spam cleanup, media audits, user purges, updates and checksums, settings changes, theme git audits, backups, and maintenance. Every script is a dry run until `-f`, asks for a typed `yes` before changing anything, keeps going when one site fails, and ends with a summary table and a real exit code. It also reviews an existing script, lists what is wrong line by line, and fixes it. Scripts are tested against a stub `wp`, never against your live sites.
- [`/wp-block-theme`](docs/wordpress.md#wordpress-block-theme). Builds a complete full-site-editing block theme from a short brief - theme.json version 3, templates, template parts, patterns, style variations, and local fonts - then reviews its own output until the verdict is ship. Or reviews an existing block theme and reports every problem by file and line, with a severity, the bad code and the fix, ending with a ship or don't-ship verdict. Review changes nothing; build never overwrites.
- [`/wp-classic-to-block`](docs/wordpress.md#wordpress-classic-to-block). Moves a classic PHP theme to a block theme. ASSESS writes a migration plan: every file and view sorted by how much work it needs, every stored value the theme reads, a risk register, an hour estimate, and a verdict - full migration, hybrid, or rebuild. MIGRATE writes `theme.json`, block templates, parts, and patterns, and moves custom post types, metaboxes, and shortcodes into a companion plugin, keeping every meta key, option, and URL so existing content keeps working.
- [`/wp-bug-audit`](docs/wordpress.md#wordpress-theme-bug-audit). Audits a WordPress theme for bugs: reads every file, checks the code against about 160 numbered bug checks, tests everything on throwaway WordPress sites across the PHP versions your customers run, and writes a verified bug list and a coverage report into the theme's `audit/` folder. It asks eight questions and confirms the cost before starting, can resume an interrupted run, and changes nothing in the theme unless you ask for fixes afterwards.
- [`/wp-mockup`](docs/wordpress.md#wordpress-theme-mockup). Builds a clickable static HTML mockup of a classic WordPress theme in one of 53 named design styles - bento, swiss, glassmorphism, retro terminal, y2k, and more. One page per theme template (blog index, single post, page, archives, search, 404), all sharing a header, sidebar, and footer and linking to each other. Built with Tailwind v3 and WordPress class names so `/wp-theme` can turn it into a real theme afterwards.
- [`/wp-doc-pass`](docs/wordpress.md#wordpress-doc-pass). Documents a WordPress plugin or theme (classic, block, or child) without changing its code: full PHPDoc and JSDoc on every file, class, constant, property, function, closure, and hook, plus inline comments that explain why, written in the project's own coding standard (WordPress, PSR-12, or legacy). Theme templates, template parts, page templates, and block patterns are covered too. A bundled checker compares every file token by token and line by line against a backup and keeps every comment that is really code - WP-CLI help, PHPUnit annotations, lint directives, `translators:` comments - exactly where it was. Tests, phpcs, and static analysis are compared before and after, and the bugs it finds are reported, never fixed unless you ask.
- [`/wp-modernize`](docs/wordpress.md#wordpress-modernize). Moves a WordPress plugin from the WordPress Coding Standards to PSR-12, puts its classes in a PSR-4 `src/` tree grouped by role, and adds strict PHP 8.1 types without changing anything outside the plugin can see. Eight phases, each tested against the previous one, committed, and tagged. Names WordPress stored in the database keep working through aliases, and an upgrade test on a site that ran the old version proves it.
- [`/wp-submission`](docs/wordpress.md#wordpress-plugin-submission). Decides whether a built plugin is ready for WordPress.org review. Maps the code, readme, and Plugin Check output to the current official guidelines it fetches, catches trialware, license-only services, undisclosed external calls, and readme mismatches, and returns one verdict - do not submit, insufficient evidence, ready after fixes, or ready to submit - with the smallest fix list and a factual reply to the review team. It also handles closures, reopen requests, and updates to approved plugins, and never promises approval.
- [`/wp-demo-video`](docs/wordpress.md#wp-plugin-demo-video). Records an MP4 demo video of a WordPress plugin's admin screens: reads the plugin's source to find its pages and controls, checks them on your live site, agrees a storyboard with you, and records with Playwright - a full video plus optional clips per scene, checked with contact sheets. Nothing that changes data runs without your approval, and your password never enters the chat.
- [`/wp-security`](docs/wordpress.md#wp-security). Reviews a WordPress plugin or theme for security holes. A bundled scanner runs 65 grep checks (and the WordPress phpcs security sniffs when installed) to find candidates, then every superglobal and REST request value is traced by hand from input to sink - SQL injection, XSS, CSRF and nonce gaps, missing capability checks, privilege escalation, unsafe uploads, path traversal, object injection, SSRF, and open redirects. Each confirmed finding comes back CRITICAL, WARNING, or INFO with the file and line, a CWE, and the vulnerable code next to the fixed version.
- [`/wp-theme-review`](docs/wordpress.md#wp-theme-review). Reviews a WordPress theme of any type - block, classic, hybrid, or child - against current theme standards. A bundled scanner finds candidates in theme.json, templates, patterns, and theme PHP: theme.json v3 preset collisions that silently drop theme values, a missing schema version, broken root padding, unbalanced block markup and PHP left in `.html` files, unescaped request data, deprecated functions, hardcoded `<title>` and asset tags, and missing headers. Each candidate is confirmed in the source and reported CRITICAL, WARNING, or INFO with the file and line and a BAD/GOOD fix pair. `--wporg` applies the WordPress.org theme directory rules.
- [`/wp-block-review`](docs/wordpress.md#wp-block-review). Reviews WordPress block (Gutenberg) code in any block plugin. A bundled scanner detects the project type - modern build, multi-block library, metadata collection, compiled-only, no-build, apiVersion 1, or PHP-registered - and finds candidates in block.json, edit and save, deprecations, render files and callbacks, the Interactivity API, registration, and build output. Each one is confirmed in the source before it is reported as CRITICAL, WARNING, or INFO with the file and line and a BAD/GOOD fix.
- [`/wp-security-review`](docs/wordpress.md#wp-security-review). Security review of a WordPress plugin, theme, specific files, a diff, or a pasted snippet. One round of questions settles the target, the depth (quick triage or full audit), who can reach the site (public, members, or admin-only, plus multisite and VIP), and whether you want patches, and it is skipped when your request already answers them. A grep scan finds candidate sinks, and each one is traced back through nonces, capability checks, sanitizing, allowlists, and stored data written by lower-privileged users. A finding is rated CRITICAL only after its exploit path is written out - entry point, who can reach it, the missing guard, and the impact - and every finding comes with the line, a CWE, and a BAD/GOOD fix.
- [`/wp-plugin-review`](docs/wordpress.md#wp-plugin-review). Reviews a WordPress plugin for architecture, lifecycle, API usage, and WordPress.org compliance. It sets the context first - WordPress.org, private, mu-plugin, or drop-in - because that changes what counts as a problem, runs a bundled scanner, then reads every PHP file, not just the ones with hits. Severity comes only from a fixed catalog, a "Not a Problem" list drops known false positives, and each finding has the line, CRITICAL, WARNING, or INFO, and a BAD/GOOD fix using the plugin's own prefix and text domain. The report ends with a WordPress.org readiness verdict, and security observations are listed in one line each for `/wp-security-review`.

**Design & Frontend**

- [`/html-design-styles`](docs/design.md#html-design-styles). 53 named design styles with full color palettes, typography, and component patterns.
- [`/accessibility-audit`](docs/design.md#accessibility-audit). Checks a page, a folder, or a single component against the accessibility rules, tells you what is broken and why it matters, and can fix it for you. Command only, so it never fires on its own or clashes with another accessibility plugin.
- [`/design-system`](docs/design.md#design-system). Reverse-engineers the HTML and CSS of a page or folder into a reusable `DESIGN.md` - colors, typography, spacing, components, and the signature motifs that define the look - grounded in the real source, never invented.
- [`/tailwind-convert`](docs/design.md#tailwind-gut). Strips a page's custom CSS and rewrites it in Tailwind utilities, pixel-identical, detecting the Tailwind version first and promoting real design tokens into the theme config.
- [`/page-cloner`](docs/design.md#page-cloner). Copies a live URL into one self-contained working HTML file that looks and lays out like the original, built from the real rendered page and checked against it in a loop. Faithful copy, no redesign. Needs Claude in Chrome.
- [`/page-tailwindify`](docs/design.md#page-tailwindify). Rebuilds a live page's exact look in clean Tailwind, with the framework's generated class hashes replaced by real utility classes and every class traced to a real computed value. Needs Claude in Chrome.
- [`/tailwind-forge`](docs/design.md#tailwind-forge). Works on Tailwind CSS in your own project - setup, v3 to v4 migration, `@theme` tokens and custom utilities, components, responsive layout, dark mode, shadcn/ui theming, animation, accessibility, and debugging - for v4, and in v3 syntax when a project has not migrated. It reads your CSS entry, tokens, and existing components first and matches them, skips unrequested `dark:` variants, gradients, and variant systems, and checks newer features against your installed minor version. With no task named it detects the project and asks two multiple-choice questions, and four bundled scripts audit class usage, dark mode, accessibility, and built CSS size.
- [`/react-forge`](docs/design.md#react-forge). React 19 (and 18) project work - components, hooks, Server Components and Server Actions, state management, forms with Zod 4, TypeScript, loading and error states, Tailwind CSS v4 and shadcn/ui, testing, performance, React 19 upgrades, and code review - plus routing, data loading, caching, middleware, auth, and SEO for Next.js 15.5/16, React Router 7.9+/8, and TanStack Router/Start. It reads your React and framework versions, TypeScript config, test runner, and existing components first and matches them, applies authorization, Zod validation, idempotency keys, and verified webhooks to every mutating endpoint, and ships eight generation workflows (component, hook, optimize, test, review, Next.js page, Route Handler, proxy) plus four read-only checker scripts and three Next.js scripts.

**Writing & Content**

- [`/tech-blog-article`](docs/writing-and-content.md#tech-blog-article). Writes a technical blog post in the voice of a senior developer - a strong opening, clear code examples, and an honest look at the downsides.
- [`/tutorial-builder`](docs/writing-and-content.md#tutorial-builder). Turns code or a topic into a step-by-step, hands-on tutorial that teaches instead of describing, where every code block runs and shows its output, with a pre-publish checklist and a yes/no quality gate before you get it.
- [`/draft-contract`](docs/writing-and-content.md#contract-framework). Writes a clear, fair freelance or consulting contract from a few plain questions, covering the work, the payment, and who owns the finished result, with anything that depends on where you live flagged for you to check locally.
- [`/name-domains`](docs/writing-and-content.md#naming-strategist). Brainstorms 10 brandable, easy-to-say domain names for your SaaS, with a shortlist of the best three and a checklist to verify them.
- [`/language-tutor`](docs/writing-and-content.md#language-tutor). Translates and explains a phrase, or corrects and critiques your writing, with grammar notes, pronunciation tips, and better alternatives.
- [`/github-bio`](docs/writing-and-content.md#github-bio). Writes five GitHub profile bios in five styles from six plain questions asked one at a time - your role, stack, databases, cloud, DevOps skills, and specialty. It confirms your answers first, uses only what you told it, and checks every bio with a script so each one fits GitHub's 160-character limit.
- [`/book-summary`](docs/writing-and-content.md#book-summary). Writes a clear, sectioned summary of any book - an overview, the main ideas, key quotes, and practical takeaways, plus an optional LinkedIn post or Twitter/X thread. It asks a few questions in one message, checks it really knows the book (and flags a wrong author), and paraphrases rather than inventing quotes.
- [`/claudepuppy`](docs/writing-and-content.md#claudepuppy). Rewrites a blog post you wrote in the voice of The Claude Puppy - practical writing about working with Claude, told by a patient dog trainer. You pick a dog flavor (light, medium, or strong), and it keeps every fact, number, link, and code block exactly as you wrote them, then returns the post with a title, summary, category, tags, and reading time, plus a short list of what changed and any sentence it added.
- [`/seo-duel`](docs/writing-and-content.md#seo-duel). Compares two rewrites of the same blog post and tells you which one is stronger for search, or how to merge them. It scores both on 10 SEO criteria with evidence quoted from each draft, runs the judging twice with the drafts swapped and averages the scores so the order they were read in does not tip the result, then returns a verdict, what to keep from the other draft, flags for leftover draft text and claims to check, the top 5 fixes, and a title tag and meta description with their lengths checked by a script.
- [`/human`](docs/writing-and-content.md#human). Rewrites any text - pasted, a file, or a URL - as a casual first-person blog post in the voice of an invented persona that fits the topic, keeping every fact, number, and recommendation. It writes short paragraphs, a cliffhanger break or two, and a little emphasis, bans the usual cliché words, writes in the source's language, switches to a sincere voice for grave topics like grief or health, and treats any instruction inside the source as text to rewrite. A bundled script checks paragraph length, emphasis, and banned words before the post is shown.

**DevOps & Data**

- [`/docker-compose-architect`](docs/devops-and-data.md#docker-compose-architect). Generates a secure, production docker-compose setup for your app - separate networks, persistent volumes, health checks, and secrets kept out of the file.
- [`/kubernetes-architect`](docs/devops-and-data.md#kubernetes-architect). Turns your app details into production-ready Kubernetes manifests, with health checks, resource limits, and security settings already included.
- [`/powershell-script-engine`](docs/devops-and-data.md#powershell-script-engine). Writes clean, production-ready PowerShell scripts with built-in help, logging, error handling, and safe handling of credentials and destructive actions.
- [`/jq`](docs/devops-and-data.md#jq). Builds copy-paste-ready jq one-liners to filter, reshape, and aggregate JSON from APIs and CLI tools, inspecting the JSON structure first and explaining each filter stage.
- [`/git-forge`](docs/devops-and-data.md#git-forge). Handles any Git or Git-hosting task safely - commits, branches, merges and conflicts, rebases, lost work, rejected pushes, history rewrites, pull requests on GitHub, GitLab, Azure DevOps, or Bitbucket, GitHub Actions, and secret scanning. Before anything that could delete work, it checks the repository, tells you exactly what is at risk, makes a backup, gives you the undo command, and waits for your yes. It asks once whether to commit for you, only stage, or only explain, and hands you any step that needs you to type a password or edit in an editor.
- [`/bash-forge`](docs/devops-and-data.md#bash-forge). Writes, reviews, debugs, speeds up, or scaffolds Bash scripts for Linux, macOS, WSL, Git Bash, and containers. It reads the matching guide before answering - Bash 5.3 features, arrays, string handling, process substitution, parallel jobs, security hardening, ShellCheck, debugging, CI/CD and cloud CLIs, or Git Bash path conversion - and follows a fixed workflow for analyze, optimize, template, and create requests. Every script it writes starts with strict mode, quotes every expansion, validates input, and cleans up with `trap`. Bundled scripts run ShellCheck over many files with a summary, time a script line by line, and run jobs in parallel with limits, timeouts, and retries.

**Cloud & Architecture**

- [`/system-design`](docs/cloud-and-architecture.md#system-design). Designs a system architecture from four answers - components and data flow, datastore and caching choices, sync versus async communication, and how it survives failure. Infrastructure only, no code.
- [`/terraform`](docs/cloud-and-architecture.md#terraform). Writes production Terraform split into `main.tf`, `variables.tf`, and `outputs.tf`, with least-privilege IAM, a pinned provider, and a state backend recommendation.
- [`/cicd-pipeline`](docs/cloud-and-architecture.md#cicd-pipeline). Builds a pipeline file for GitHub Actions, GitLab CI, or Jenkins - dependency and Docker layer caching, test gates, and a checklist of every secret you need to set.
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

- [`/blueprint`](docs/code.md#app-blueprint). Produces a 12-section production blueprint from your idea, or from a random pick of 2,600 ready-made examples if you don't have one yet - folder layout, data models, API design, dependencies, tests, CI/CD, security, and a risk register - then hardens it: a fresh reviewer checks it against fact sheets for your stack and repairs what the framework doesn't actually do, a throwaway skeleton proves it builds, and short spikes test whatever is still risky. Every stage keeps a numbered version of the plan.
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
- [`/explain-regex`](docs/code.md#regex-tutor). Explains one regular expression in plain English for beginners and experienced developers alike - a token-by-token breakdown, its structure and capture groups, examples that match and examples that fail, a step-by-step walkthrough, pitfalls, a catastrophic-backtracking (ReDoS) verdict, safer alternatives, and a jargon-free rewrite. Every example and alternative is checked against real regex engines, and the teardown prints in chat or saves to `REGEX-EXPLAINED.md`.
- [`/script-refactor`](docs/code.md#script-refactor). Cleans up bash and Python scripts that another program or AI agent runs, keeping their output, exit codes, and written files exactly the same. It checks what calls each script, runs the old and new versions side by side to prove nothing changed, and lists any bug fix that would change behavior as a numbered proposal you approve before it is applied.
- [`/blueprint-forge`](docs/code.md#blueprint-forge). Reads an existing codebase and writes one `BLUEPRINT.md` in 14 fixed sections - tech stack with every version's source, architecture, auth, a module map with every export's types, data models, every API route, features, UI, environment variables, tests, open questions, and step-by-step rebuild instructions - detailed enough to rebuild the app without the original code. Secrets are never copied, and a bundled checker confirms the format before you get it. Point it at a blueprint instead and it rebuilds the app: it proposes a plan, waits for your approval, then builds and verifies one step at a time. Afterwards it can scan the new app and compare it with the original blueprint, listing any endpoint, model, or environment variable the rebuild lost.
- [`/explain-code`](docs/code.md#code-explainer). Explains one snippet, file, line range, or named function the way an experienced engineer who teaches would, pitched at your level - Beginner, Intermediate, or Advanced - and shaped as a detailed tutorial, a quick summary of 300 words or fewer, interview preparation, or a line-by-line walkthrough. Every risk is marked confirmed or possible, every improvement shows before and after code, and the result can be saved as a Markdown document. It never edits the code.
- [`/python-forge`](docs/code.md#python-forge). Modern Python (3.11 to 3.13+) work in your own project: uv and `pyproject.toml`, asyncio, type hints and mypy, FastAPI and Pydantic, pytest and coverage, Ruff and pre-commit, GitHub Actions and PyPI, Cloudflare Python Workers, Modal, OpenCV, FFmpeg, and GPU video pipelines. It loads the matching guide before answering, writes typed code with tests, and keeps your existing framework and tools. A project-init workflow scaffolds a FastAPI app, CLI tool, library, or minimal project with uv and verifies it, a run-tests workflow reports coverage and finds the cause of failures, and four scripts check types, async code, coverage, and dependencies.
- [`/retrospec`](docs/code.md#retrospec). Reverse-engineers an existing frontend, backend, or fullstack codebase into a Product Requirements Document a product manager can read - a system README with the module overview, page inventory, and permission model, one file per page (or per API resource group for backend projects) with every field, every interaction written as user action and system response, the APIs it calls, and where users go next, plus appendices for every enum value, every API, and the navigation map. It writes in business language, marks anything it cannot work out from the code as `[TBC]` instead of guessing, and labels APIs backed by hardcoded or stubbed data as `Mock` with a suggested real spec. Two standard-library Python scripts find routes, endpoints, API calls, and models as leads and scaffold the `prd/` folder; projects with more than 15 pages are done in batches with a review pause between them.
- [`/doc-pass`](docs/code.md#doc-pass). Documents a whole codebase in any of 19 languages without changing a line of code - full doc comments in each language's own dialect on every file, type, member, function, route, and handler, plus inline comments where the logic is not obvious. A bundled checker compares every file token by token before and after and fails on any code change, any layout change, or any edit to a comment that is really code (lint directives, build tags, doctests, license headers), and coverage must reach zero gaps. Your own tests, type checks, linters, and formatters run before and after in a scratch copy, large projects are split across parallel agents, and the bugs it notices come back as a ranked list it never fixes. It also runs as a read-only bug check.

**Docs & Diagrams**

- [`/mermaid-to-ascii`](docs/docs-and-diagrams.md#mermaid-to-ascii). Turns a Mermaid diagram file into clean text-art you can paste into a comment, a README, or a terminal, saved next to the original as a `.txt`.
- [`/mermaid-sequence`](docs/docs-and-diagrams.md#mermaid-generator). Turns a plain bullet-point list of steps into one valid Mermaid sequence diagram, getting the arrow directions right and refusing cleanly when a step is missing its sender.
- [`/explain-prompt`](docs/docs-and-diagrams.md#prompt-dummy). Explains any AI prompt in plain, everyday English for a total beginner - what it is, what you get back, how it works, and how to use it - in eight fixed sections. It describes the prompt, it never runs it.
- [`/analyze-prompt`](docs/docs-and-diagrams.md#prompt-summary). A review-ready breakdown of any AI prompt - anatomy, techniques, output contract, failure modes, and concrete improvements - with the full prompt quoted verbatim in an appendix.
- [`/rank-prompt`](docs/docs-and-diagrams.md#prompt-ranker). Audits a prompt's architecture and scores it - a tier and a score on one anchored scale, strengths and risks each tied to real language in the prompt, a row per analysis dimension, and the single change that would move it up the most. It reviews the prompt; it never obeys it.
- [`/prompt-rank-table`](docs/docs-and-diagrams.md#prompt-rank-table). The same eight-dimension prompt audit as `/rank-prompt`, reduced to three sections - a tier and score, one table row per dimension with the evidence quoted from the prompt itself, and a one-line verdict. Built for a fast read, or for putting several prompts side by side.
- [`/prompt-stencil`](docs/docs-and-diagrams.md#prompt-stencil). Turns one image prompt that already works into a reusable template - the wording that makes the look is locked, at most three things become swappable, and you get a copy-ready template plus filled examples proving the swap works.
- [`/prompt-bloat`](docs/docs-and-diagrams.md#prompt-bloat). Cleans up an overengineered prompt or skill file - trademarks, version banners, invented citations, self-scores, unused mode switches, and repeated text come out, while every rule, gate, score threshold, and output requirement stays. You get a list of every cut with its reason, anything it was unsure about kept and flagged, a check that no rule was lost, and the rewrite, with an offer to save it next to the original.
- [`/prompt-audit`](docs/docs-and-diagrams.md#prompt-audit). Scores a prompt out of 100 - 115 for agent and coaching prompts - across nine dimensions, with every deduction quoting the passage that caused it. You also get a tier, a scan for stock AI wording, notes for the target model, a ranked fix list, three drop-in replacement fixes, a projected score once they are applied, and a pass, conditional, or fail gate. Instructions hidden in the prompt are logged, never followed.
- [`/readme-forge`](docs/docs-and-diagrams.md#readme-forge). Combines a folder of markdown files - one bio plus one file per project - into a single portfolio `README.md` with a header from the bio, a table of contents with working links, and one entry per project, in full or compact mode with optional categories. Links come only from your files, local and relative links are dropped, and a bundled script checks the result.

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

That is the whole install. One plugin, 99 commands and 11 pickers, nothing running in the background.

Then either browse the whole catalog:

```
/forge
```

which asks for a category, then a command, then runs it. Or jump straight to one category:

```
/forge-wordpress    # 26 WordPress commands
/forge-design       # 8 design and frontend commands
/forge-writing      # 10 writing and content commands
/forge-devops       # 6 DevOps and data commands
/forge-cloud        # 8 cloud and architecture commands
/forge-security     # 3 security commands
/forge-cleanup      # 4 code-cleanup commands
/forge-code         # 18 code commands
/forge-docs         # 10 docs and diagram commands
/forge-utils        # 6 utilities
```

Or call any command directly:

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
/wp-cli                         # write or review WP-CLI fleet scripts, dry run by default
/wp-block-theme                 # build or review a full-site-editing block theme
/wp-classic-to-block            # assess or migrate a classic theme to a block theme
/wp-bug-audit                   # full theme bug audit on throwaway test sites
/wp-mockup                      # static HTML theme mockup in one of 53 styles
/wp-doc-pass                    # document a plugin's or theme's code, proof that no code changed
/wp-modernize                   # WPCS to PSR-12, PSR-4 src/, strict PHP 8.1 types
/wp-submission                  # WordPress.org submission gate: verdict, fixes, reviewer reply
/wp-demo-video                  # MP4 demo video of a plugin's admin screens
/wp-security                    # security review: scanner, input-to-sink tracing, CWE-tagged fixes
/wp-theme-review                # theme standards review: block, classic, hybrid, child; --wporg mode
/wp-block-review                # block code review: block.json, edit/save, render, Interactivity API
/wp-security-review             # security review, CRITICAL only with a written exploit path
/wp-plugin-review               # plugin architecture, lifecycle, and WordPress.org review

# Design & Frontend
/html-design-styles             # 53 named design styles with full specs
/accessibility-audit            # WCAG audit and fixes
/design-system                  # reverse-engineer a page into a reusable DESIGN.md
/tailwind-convert               # rip out custom CSS, rewrite in Tailwind utilities
/page-cloner                    # copy a live URL into one self-contained HTML file
/page-tailwindify               # rebuild a live page's exact look in clean Tailwind
/tailwind-forge                 # Tailwind project work: tokens, components, dark mode, debugging
/react-forge                    # React project work: components, hooks, forms, tests, Next.js

# Writing & Content
/tech-blog-article              # technical article from five inputs
/tutorial-builder               # hands-on, step-by-step tutorial
/draft-contract                 # plain-English service agreement
/name-domains                   # 10 brandable SaaS domain candidates
/language-tutor                 # translate, or correct and critique writing
/github-bio                     # five GitHub profile bios, 160 characters each
/book-summary                   # sectioned book summary, quotes checked
/claudepuppy                    # blog draft in the Claude Puppy voice
/seo-duel                       # two blog drafts judged for SEO, winner or merge
/human                          # any text as a human-voice blog post

# DevOps & Data
/docker-compose-architect       # production docker-compose stack
/kubernetes-architect           # production Kubernetes manifests
/powershell-script-engine       # PSScriptAnalyzer-clean PowerShell script
/jq                             # one explained, copy-paste-ready jq command
/git-forge                      # any Git task, backup and a yes before destructive steps
/bash-forge                     # write, review, debug, or speed up Bash scripts

# Cloud & Architecture
/system-design                  # architecture blueprint, no code
/terraform                      # production HCL: main.tf, variables.tf, outputs.tf
/cicd-pipeline                  # pipeline YAML + secrets checklist
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
/blueprint                      # app blueprint, reviewed, scaffolded, spiked
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
/explain-regex                  # verified plain-English teardown of one regex
/script-refactor                # clean up agent-run scripts, output kept identical
/blueprint-forge                # codebase -> BLUEPRINT.md, or BLUEPRINT.md -> app
/explain-code                   # explain one snippet, file, or function at your level
/python-forge                   # modern Python: uv, asyncio, typing, FastAPI, pytest
/retrospec                      # codebase -> business-readable PRD in prd/
/doc-pass                       # comment-only doc pass, code proven unchanged

# Docs & Diagrams
/mermaid-to-ascii               # Mermaid file -> monospace ASCII .txt
/mermaid-sequence               # bullet-point steps -> one Mermaid sequence diagram
/explain-prompt                 # any AI prompt in plain, beginner English
/analyze-prompt                 # review-ready prompt anatomy breakdown
/rank-prompt                    # tier and score a prompt's architecture
/prompt-rank-table              # the same audit as a tier, a table, one verdict
/prompt-stencil                 # cut a working image prompt into a reusable template
/prompt-bloat                   # strip bloat from a prompt or skill file, rules kept
/prompt-audit                   # score a prompt /100 with cited deductions and fixes
/readme-forge                   # folder of project .md files -> one portfolio README

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

The 11 pickers do no work themselves - they show you what is available, then hand off
to the command you choose.

### `/forge` - everything

Asks for a category, then a command, then runs it. `AskUserQuestion` allows at most four
options per question, so the ten categories arrive over four screens, the first three
ending in `More...`:

```
Which category?      Which category?          Which category?     Which category?
  WordPress            DevOps & Data            Code Cleanup        Utilities
  Design & Frontend    Cloud & Architecture     Code                Back to page 1
  Writing & Content    Security                 Docs & Diagrams
  More...              More...                  More...
```

Pick a category and the second question lists that category's commands with a one-line
description each.

### `/forge-<category>` - one category, no category step

| Picker | Commands | Screens |
|---------|-------|---------|
| `/forge-wordpress` | 26 | 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-design` | 8 | 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-writing` | 10 | 3 + `More...`, then 3 + `More...`, then 4 |
| `/forge-devops` | 6 | 3 + `More...`, then 3 |
| `/forge-cloud` | 8 | 3 + `More...`, then 3 + `More...`, then 2 |
| `/forge-security` | 3 | one |
| `/forge-cleanup` | 4 | one |
| `/forge-code` | 18 | 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 3 |
| `/forge-docs` | 10 | 3 + `More...`, then 3 + `More...`, then 3 + `More...`, then 1 |
| `/forge-utils` | 6 | 3 + `More...`, then 3 |



A picker screen looks like this - `/forge-wordpress`, page 1 of 9:

```
Which command?
  Build a plugin from scratch    Full WordPress.org-ready scaffold: OOP classes,
                                 blocks, REST, i18n, uninstall.php.
  Targeted WordPress code        Add a feature, settings page, block, or endpoint
                                 to an existing project.
  HTML to WordPress theme        Convert static HTML into an installable theme
                                 with Tailwind and WCAG AA.
  More...                        The remaining WordPress commands.
```

Every screen also carries the built-in "Other" free-text field. Typing a command name there
is treated the same as passing it as an argument.

### Skipping the picker

Pass a command name and the picker never appears. Anything after the name becomes that
tool's own argument:

```
/forge jq                          → runs /jq, no questions from the picker
/forge-wordpress wp-format ~/themes/mytheme
                                  → runs /wp-format against that path
```

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
(`Running /wp-format.`) so you know which command took over. Nothing is loaded until that
moment - see below.

## How it is put together

```
.claude-plugin/
  marketplace.json     one plugin entry
  plugin.json          the forge plugin manifest
commands/              110 command files - 99 commands, 11 pickers
lib/<tool>/
  SKILL.md             the tool's procedure, read only when its command runs
  references/          deep detail, loaded on demand by the procedure
  scripts/             deterministic runners
  assets/              output templates
  examples/            worked before-and-after files the procedure reads
```

`lib/` is deliberately not named `skills/`. Claude Code auto-discovers skills from a
`skills/` directory and keeps their descriptions loaded in every session. Putting the
procedure files under `lib/` takes them out of discovery entirely, so they exist only
as files that commands read on demand. No metadata in your context, no competing
triggers, no surprise activations.

Every command also carries `disable-model-invocation: true` in its frontmatter, which
removes it from the SlashCommand tool. So Claude cannot decide on its own to run
`/unslop` on your code or `/refactor` on your repo. These commands and pickers fire when you
type them, and at no other time.

`/forge` starts a tool by reading the target command's file directly rather than calling
it as a slash command, so browsing still works with model invocation switched off.

---

## Command reference

Every tool's full write-up - what it does, how it works, how to use it - lives in `docs/`, one file per group. The [Available commands](#available-commands) list above links straight to each tool.

| Group | Commands | Reference |
|---|---|---|
| WordPress | 26 | [docs/wordpress.md](docs/wordpress.md) |
| Design & Frontend | 8 | [docs/design.md](docs/design.md) |
| Writing & Content | 10 | [docs/writing-and-content.md](docs/writing-and-content.md) |
| DevOps & Data | 6 | [docs/devops-and-data.md](docs/devops-and-data.md) |
| Cloud & Architecture | 8 | [docs/cloud-and-architecture.md](docs/cloud-and-architecture.md) |
| Security | 3 | [docs/security.md](docs/security.md) |
| Code Cleanup | 4 | [docs/code-cleanup.md](docs/code-cleanup.md) |
| Code | 18 | [docs/code.md](docs/code.md) |
| Docs & Diagrams | 10 | [docs/docs-and-diagrams.md](docs/docs-and-diagrams.md) |
| Utilities | 6 | [docs/utilities.md](docs/utilities.md) |


## Repo layout

```
.
├── .claude-plugin/
│   ├── marketplace.json      ← marketplace manifest (one entry: forge)
│   └── plugin.json           ← the forge plugin manifest
├── commands/                 ← 99 commands + 11 pickers
├── lib/                      ← 99 procedure folders (SKILL.md + bundled
│                                references/scripts/assets/examples). NOT a skills/ dir,
│                                so nothing auto-loads; each is read only when
│                                its command runs.
├── docs/                     ← full write-up for each command group (linked above)
├── forge-screens/            ← ASCII screen maps + generated PNGs of every menu
├── FORGE_MAP.txt             ← the whole catalog on one screen
├── SUMMARY.md                ← the 99 commands compared by how much each does
└── README.md                 ← this file
```

Every tool is built the same way: `commands/<name>.md` (the slash command, carrying a
"Load first" banner) points at `lib/<procedure>/SKILL.md` (the actual procedure). Some
command names differ from their procedure folder - `SUMMARY.md` has the full map.
