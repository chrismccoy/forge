# Forge Commands

## wp-plugin

Builds a new WordPress plugin from scratch. It asks seven intake questions covering the plugin name, features, target users, admin screens, front end output, and third party integrations. The result is a full plugin folder with a main file, OOP classes, security checks, translation support, readme.txt, and uninstall.php. Use wp-build instead when you are changing a plugin that already exists.

## wp-build

Adds targeted code to a new or existing WordPress project. You pick what to build, such as a theme feature, plugin settings page, block, WooCommerce extension, REST endpoint, performance fix, or security fix. It then asks whether the project is new or existing, what the feature should do, and which WordPress and PHP versions to target. The defaults are WordPress 6.4 and PHP 8.1 when you leave the versions blank.

## wp-theme

Converts static HTML files into an installable WordPress theme. It maps each HTML file, such as index.html, single.html, and archive.html, to the matching WordPress template. The work runs in phases with an approval step before each one, followed by a self audit at the end. Optional features like related posts, reading time, and Schema.org markup are only added when you ask for them.

## wp-review

Runs a senior architect review of a plugin or theme. It reads every PHP, JS, CSS, and config file, then reports issues by category with the file and line, the quoted code, the impact, and the fix. The report also includes strengths, a scorecard, and the top five fixes in priority order. If the overall score is below 6 out of 10, it adds a refactor roadmap.

## wp-consult

Runs a consulting style audit of a WordPress site. It asks seven questions about the site type, the current problem, the technology stack, traffic, goals, performance needs, and support needs. It then works through a 10 section framework and ends with a report and a score from 0 to 100. Use it when you need advice on a whole site rather than a review of one codebase.

## wp-format

Sets up WordPress Coding Standards for a theme and applies the formatting fixes that can be done automatically. It installs PHP_CodeSniffer and WPCS as Composer dev dependencies and writes a phpcs.xml.dist file. It then runs phpcbf twice and checks every changed file with php -l. Only formatting changes, so no page renders any differently afterwards.

## wp-menu-icons

Adds a searchable Font Awesome icon picker to each item under Appearance > Menus in a classic theme. Instead of typing an icon class by hand, the site owner clicks an icon in a modal. The picker code is copied into the theme itself and renamed to use the theme's own prefix. It is not installed as a separate plugin.

## wp-report-card

Gives a plugin or theme a score and nothing else. It reads every file, scores ten areas from 1 to 10, and prints an overall score with its tier. There are no findings, fixes, or summary in the output. Use wp-review when you need to know what is wrong and how to fix it.

## wp-grade

Grades a single snippet or a single file of WordPress code. You paste the code or give a file path. The output has six fixed sections: what the code does, a letter grade from A to F, strengths, real weaknesses, minor nitpicks, and a verdict on whether it is safe for a live site. It is meant for quick checks on small pieces of code, not whole projects.

## wp-performance

Reviews a plugin or theme for performance problems. It reads every file in full and looks for unbounded queries, cache bypasses, queries inside loops, and expensive cron jobs and asset loading. Each finding has a severity, a file and line, the impact, and a fix. Every run starts fresh, so running it a second time can catch things the first run missed.

## wp-demo

Builds a demo content importer for a classic theme. It reads the theme's code to learn every post type, field, and option the theme uses, then writes a single WP-CLI script at demo/demo-import.php. The script is tested on a throwaway SQLite site so your real sites are never touched. Any bugs it finds in the theme are written to demo/BUGS.md and only fixed if you say yes.

## wp-feature-readme

Writes a plain English README.md for a theme or plugin. The file has three parts: the name, a short description, and a feature list grouped into categories. It is written for site owners who are not technical. Every feature in the list is traced back to a real file in the code.

## wp-cli

Writes or reviews bash scripts that run a WP-CLI task on every WordPress site on a server, or on just one. Typical tasks include spam cleanup, media audits, updates, checksum checks, and backups. Every script runs as a dry run until you pass -f, and it asks you to type yes before making changes. Scripts are tested against a fake wp command and fake sites, and you run them on real sites yourself.

## wp-block-theme

Builds a new block theme from a short brief, or reviews an existing one. A build includes theme.json version 3, templates, template parts, patterns, style variations, and local fonts. A review lists each problem with the file and line, a severity, and a bad and good code example. Every review ends with one of three verdicts: SHIP, FIX WARNINGS, or DO NOT SHIP.

## wp-classic-to-block

Moves a classic PHP theme to a block theme. Assess mode is read only and produces an inventory of the theme, a list of risks, an hour estimate, and a recommendation to convert, go hybrid, or rebuild. Migrate mode writes the new block theme and moves business logic such as custom post types, shortcodes, and REST routes into a companion plugin. Every meta key, option, and URL stays the same so existing content keeps working.

## wp-bug-audit

Audits a theme for bugs. It reads every file, runs about 160 numbered checks, and tests the theme on throwaway SQLite sites across the PHP and WordPress versions your customers use. The verified bug list and a coverage report are saved in the theme's audit/ folder. Nothing in the theme changes unless you ask for fixes afterwards.

## wp-mockup

Builds a clickable static HTML mockup of a classic theme in one of 53 named design styles, such as bento, swiss, or retro terminal. It creates one page per template, including index, single, page, archive, search, and 404, all sharing a header, sidebar, and footer. The pages use Tailwind CSS v3 and WordPress class names. The output is ready to hand to wp-theme to turn into a real theme.

## wp-doc-pass

Adds documentation to every part of a plugin or theme without changing any code. It writes PHPDoc and JSDoc blocks for every file, class, function, hook, and template, plus inline comments that explain why the code does what it does. It follows the project's existing coding standard, whether that is WPCS, PSR-12, or an older style. A bundled checker compares the code before and after to prove that only comments changed.

## wp-modernize

Moves a plugin from WordPress Coding Standards to PSR-12, organizes classes into a PSR-4 src/ folder, and adds strict PHP 8.1 types. The work runs in eight phases, and each phase is tested, committed, and tagged in git. Nothing visible from outside the plugin changes, including option keys, hook names, REST routes, and HTML output. An upgrade test confirms that an existing install still works and uninstalls cleanly.

## wp-submission

Checks whether a plugin is ready to submit to the WordPress.org Plugin Directory. It maps the plugin against the current directory guidelines, sorts through Plugin Check output, looks for trialware and undisclosed external services, and checks readme.txt. It returns one verdict: DO NOT SUBMIT, INSUFFICIENT EVIDENCE, READY AFTER FIXES, or READY TO SUBMIT. It also lists the smallest fixes needed and can draft a reply to a reviewer email.

## wp-demo-video

Records an MP4 demo video of a plugin's admin screens. It reads the plugin source to find its admin pages, settings, and controls, then checks those screens on the live site. You approve a storyboard before anything is recorded. The recording is done with Playwright, with a visible cursor and an option to save one clip per scene.

## wp-security

Reviews a plugin or theme for security holes. A bundled scanner runs 65 checks to find likely problems, and each one is confirmed by reading the code before it is reported. It traces every value that comes from a request, such as form fields, URL parameters, and REST arguments, to the place where it is used. The report lists each finding as CRITICAL, WARNING, or INFO, with the file and line, a CWE number, and the vulnerable code next to the fixed version.

## wp-theme-review

Reviews a WordPress theme against current theme standards. It works on block, classic, hybrid, and child themes. A bundled scanner finds likely problems in theme.json, templates, patterns, and theme PHP, and each one is confirmed by reading the code before it is reported. It catches things like theme.json presets that WordPress silently ignores, PHP left in block template files, deprecated functions, and unescaped request data. The report lists each finding as CRITICAL, WARNING, or INFO, with the file and line and the broken code next to the fixed version. An optional WordPress.org mode applies the theme directory rules.


## wp-block-review

Reviews the code of WordPress blocks. It works on any block plugin: a single block, a library of dozens, a plugin that ships only compiled files, or older blocks registered in PHP. A bundled scanner first works out what kind of project it is, then finds likely problems in block.json, the editor and save code, deprecations, the PHP that renders blocks, the Interactivity API, registration, and the build output. Each one is confirmed by reading the code before it is reported. It catches things like saved block markup that changes with the editor's language and breaks the block for other users, deprecations that no longer match old content, render code that lets a Contributor inject script, and built files the block points at but that were never built. The report lists each finding as CRITICAL, WARNING, or INFO, with the file and line and a BAD/GOOD fix.

## wp-security-review

Reviews WordPress plugins, themes, and custom code for security holes. It first asks one round of questions: what to review, how deep to go, who can reach the site, and whether you want patches. It skips them when your request already says. A scan finds likely problem lines, and each one is traced back to see whether a visitor or a low-level user can really reach it, including data they saved earlier that comes back out later. A finding is rated CRITICAL only after the attack is written out step by step: where it starts, who can do it, which check is missing, and what it breaks. Each finding has the file and line, a CWE number, and a BAD/GOOD fix.

## wp-plugin-review

Reviews how a WordPress plugin is built: its headers, activation and uninstall code, hooks, settings, REST routes, cron jobs, database tables, translations, and prefixes. It first works out whether the plugin is for WordPress.org, a private site, an mu-plugin, or a drop-in, because that changes what counts as a problem. A scanner finds likely problems, then it reads every PHP file, not just the ones with hits. Each finding is CRITICAL, WARNING, or INFO, with the file and line and a BAD/GOOD fix that uses the plugin's own prefix. The report ends with whether the plugin is ready for WordPress.org. Security problems get one line each and a pointer to wp-security-review.

## html-design-styles

Applies one of 53 named design styles to a page or component, such as bento, brutalist, vaporwave, kawaii, or glassmorphism. If you do not name a style, it shows a picker, and if your style name matches several entries, it asks you to choose one. Each style has a full spec covering colors, fonts, component patterns, and visual effects. The output is a single self-contained HTML file that uses the exact values from the spec.

## accessibility-audit

Finds, reports, and fixes WCAG accessibility problems in source files, a live page, or a pasted component. You choose a mode first: report only, fix, review one component, or get guidance. It asks for the scope and the WCAG standard to check against, and in fix mode it asks how much it is allowed to change. It prefers semantic HTML and only adds ARIA where HTML cannot solve the problem.

## design-system

Reads the HTML and CSS of an existing site and writes a DESIGN.md file that describes its visual design. The file covers colors, typography, components, and the visual details that make the site recognizable. Everything in the file comes from the actual source code, not guesses. You can point it at a folder, a single HTML file, or pasted HTML.

## tailwind-convert

Takes one HTML file with a block of custom CSS and rewrites it using Tailwind utility classes. The goal is a page that looks exactly the same as before. Only styles that cannot be written as utilities are left as custom CSS. It finishes with a report of what was converted and what was kept.

## page-cloner

Copies a live web page into one self-contained HTML file that works on its own. It keeps the same layout, styles, and content with no redesign. The clone is built from the page's real rendered markup and CSS. It then compares the clone to the original and repeats until they match.

## page-tailwindify

Rebuilds a live web page in clean Tailwind CSS while keeping the exact same look. Generated class names like css-1a2b3c or sc-bdfBwQ are replaced with readable utility classes. The design stays the same and only the styling system changes. Every class is based on a real computed value from the page.

## tailwind-forge

Works on Tailwind CSS inside an existing project: setup, moving from v3 to v4, design tokens, components, responsive layout, dark mode, shadcn/ui themes, and fixing styles that do not apply. It reads the project's own colors, spacing, and components first and matches them. It does not add dark mode, gradients, or extra variants nobody asked for. Run with no task, it looks at the project and asks two multiple-choice questions. Four bundled scripts check class usage, dark mode, accessibility, and CSS size.

## react-forge

Works on React code inside an existing project: components, hooks, state, forms, TypeScript, tests, speed, upgrades to React 19, and code review. It also covers pages, data loading, caching, login, and middleware in Next.js, React Router, and TanStack. It checks the project's React and framework versions and its existing components first, and matches them. Every endpoint that changes data gets a login check, input validation, and protection against double submits. Run with no task, it looks at the project and asks one multiple-choice question. Seven bundled scripts check components, hooks, tests, and bundle size, and help with Next.js pages and upgrades.

## tech-blog-article

Writes a full technical blog article. It asks five questions: the topic, the reader's experience level, the angle, the main programming language, and the word count. The article follows a fixed structure. Use it when you need a finished draft rather than an outline.

## tutorial-builder

Writes a step by step, hands-on tutorial from a topic or from existing code. Only the topic is required. If you skip the audience, format, constraints, or where it will be published, it uses defaults and lists those assumptions at the top. The tutorial follows a fixed structure so readers can work through it from start to finish.

## draft-contract

Drafts a plain English service agreement framework in eight sections. It asks about your business, the client, the service, payment terms, protections you want, and the tone. This is help with drafting, not legal advice. Items that depend on local law are flagged so you can finalize them with a lawyer.

## name-domains

Suggests 10 brandable domain names for a SaaS product. It asks about the market, the audience, what you are selling, the brand tone, and which domain extensions matter most. Each name is scored and shown in the same fixed format. Use it at the naming stage before you buy a domain.

## language-tutor

Helps with a foreign language in two ways. In translate mode it translates a phrase and explains how it works. In analyze mode it corrects your own writing and explains each mistake. It asks for your native language and how much detail you want so the explanation fits your level.

## github-bio

Writes five GitHub profile bios in five different styles. It asks six questions one at a time about your role, your stack, data tools, cloud, DevOps, and your specialty. You confirm the answers before anything is written. A script checks that every bio is 160 characters or fewer.

## book-summary

Writes a structured summary of a book. It asks which book, what language to write in, whether spoilers are allowed, and whether you want a LinkedIn or X post as well. It confirms the book before writing so it does not summarize the wrong one. It never makes up quotes and marks paraphrased lines clearly.

## claudepuppy

Rewrites a blog draft in the voice of The Claude Puppy, a patient dog trainer who writes about working with Claude. You pick the dog flavor before it starts. Every fact, number, link, code block, and command from the original draft stays exactly the same. Only the voice of the writing changes.

## seo-duel

Compares two rewrites of the same blog post for SEO. It scores both drafts on 10 criteria with evidence, and judges them twice in opposite order to remove any bias toward the first one read. The report names a winner or a plan to merge the two. It also gives the top five fixes, a title tag, and a meta description.

## human

Rewrites any text as a personal, first-person blog post. It invents a persona that fits the topic and writes in a casual voice with short paragraphs, keeping every fact and number from the source. Grave topics such as grief or health get a sincere voice with no jokes. Instructions written inside the source are rewritten as text, never followed.

## docker-compose-architect

Designs a docker-compose stack for production use. It asks about your tech stack, database, network setup, and any constraints. The output includes networks, health checks, secrets passed as environment references, and a .env template. Use it when you need a compose file that is ready to run on a server.

## kubernetes-architect

Designs Kubernetes manifests for a production workload. It asks about the app, resource limits, how it should be exposed, and the target environment. The output covers the Deployment, autoscaling, Service and Ingress, health probes, resource limits, and security contexts. It never invents defaults, so every value comes from your answers.

## powershell-script-engine

Writes a PowerShell script that passes PSScriptAnalyzer. It asks for the task, requirements, target systems, whether it runs remotely, and how to handle destructive actions. The script includes help text, logging, input validation, and notes on security. The output follows a fixed four section layout.

## jq

Builds one jq command you can copy and paste. It asks where the JSON comes from, what you want to get out of it, and how the output should look. If you give it real JSON or a file, it checks the actual structure before writing the filter. Each stage of the filter is explained in one line.

## git-forge

Handles any Git or Git-hosting task, from a first commit to a history rewrite. It covers branches, merges and conflicts, rebases, lost work, rejected pushes, pull requests on GitHub, GitLab, Azure DevOps, and Bitbucket, GitHub Actions, and secret scanning. Before anything that could delete work, it checks the repository, says exactly what is at risk, makes a backup, gives the undo command, and waits for your yes. It asks once whether to commit for you, only stage, or only explain.

## bash-forge

Writes, reviews, fixes, and speeds up Bash scripts for Linux, macOS, WSL, Git Bash on Windows, and containers. It reads the matching guide before it answers, for topics like arrays, text handling, running jobs in parallel, security, ShellCheck, debugging, and CI/CD. Every script it writes stops on errors, quotes its variables, checks its input, and cleans up after itself. It has fixed steps for reviewing a script, making one faster, starting from a template, and writing a new one. Three bundled scripts run ShellCheck over many files, time a script line by line, and run commands in parallel.

## system-design

Designs the architecture for a system that needs to scale. It asks what the system does, the expected scale, the cloud provider, and key constraints. The result covers components, data flow, the choice of datastore, and how the system handles failure. It produces a design only and writes no code.

## terraform

Writes Terraform code for one cloud provider: AWS, GCP, or Azure. It asks for the provider, the resources you need, compliance requirements, and where to store state. The code is split into main.tf, variables.tf, and outputs.tf. IAM permissions are kept to the minimum needed and a state backend is included.

## cicd-pipeline

Designs a CI/CD pipeline for your repository. It asks about the tech stack, how you test, where you deploy, and which CI platform you use. The output is pipeline YAML written for that platform, with caching for dependencies and build layers. It also includes a checklist for handling secrets.

## data-pipeline

Designs an ETL or ELT data pipeline that can be rerun safely without creating duplicates. It asks for the data source, the destination warehouse, how data should be transformed, and the orchestration tool. The design covers how to extract data, the layers of the warehouse, the job graph, data quality tests, and backfills. It never fills in defaults, so all four answers are required.

## cloud-migration

Plans a move from on-premises servers to the cloud. It asks what runs today, the goal of the move, the target cloud, and compliance needs. Each workload is sorted using the six R's of migration, such as rehost, replatform, or retire. The plan includes a landing zone, a roadmap in waves, and tables for risk and total cost.

## sre-audit

Designs monitoring and reliability practices for a system. It asks about the system's shape, the most important user journeys, where you currently have no visibility, and your telemetry tools. The output defines SLIs, SLOs, and error budgets, along with tracing spans, burn rate alerts, and a logging format. Use it when you need to decide what to measure and when to alert.

## finops

Finds ways to lower a cloud bill. It asks for the cloud provider, the current architecture, the monthly spend, and where you think money is being wasted. The plan starts with quick wins, then covers larger architecture changes and when to buy committed use discounts. It also covers tagging and billing alarms so costs stay visible.

## incident-report

Turns your incident notes into a blameless root cause analysis. It asks what happened, what triggered it, the impact, and how it was resolved. The report includes a timeline, a 5 Whys analysis, and action items that fix the underlying cause. It is only for incidents that are already resolved.

## threat-model

Builds a STRIDE threat model for a system you are responsible for. It asks for a description of the system, the tech stack, how sensitive the data is, and any compliance rules. The output maps trust boundaries and covers all six STRIDE categories. Each threat has a severity and a matching mitigation.

## devsecops

Audits CI/CD pipelines, infrastructure code, or cloud settings for security risks. It asks which area to review, the stack, the configuration, and which compliance framework applies. The report shows how much damage a weakness could cause and maps findings to the framework. It also recommends scanning steps for the pipeline and guardrails for running systems.

## pentest-report

Turns notes from an authorized security test into a formal vulnerability report. It asks for the target, the finding, how it was found, and the business impact. The report includes a CVSS score, technical background, a safe proof of concept, and steps to fix the issue. It is a reporting tool only and does not help with exploitation.

## unslop

Removes the AI-generated tone from comments, docstrings, log messages, and variable names in source files. Code logic, control flow, function signatures, and text shown to users are never changed. You can point it at a file, a folder, or pasted code. If asked to change behavior during the pass, it refuses and tells you to start a new session.

## strip-unicode

Converts text to plain 7-bit ASCII. Curly quotes become straight quotes, long dashes become hyphens, invisible characters are removed, and other characters are replaced with their closest ASCII match. Line breaks, indentation, and wording stay the same. It can clean a file in place or return cleaned text from a paste, with a report of what changed.

## strip-emoji

Cleans up the feature list in a README file. It removes emoji from the start of each feature bullet, changes the first short label dash to a colon, and deletes en and em dashes. Number and letter ranges are kept as plain hyphens. Every line outside the feature bullets is returned exactly as it was.

## strip-comments

Removes every comment from a codebase except the header comment at the top of each file. Comments that are really directives, pragmas, or license notices are also kept. It shows a preview of every change before it writes anything. Nothing is saved until you approve the preview.

## blueprint

Plans a new app from five inputs and writes a 12 section blueprint. A fresh reviewer then checks the plan against fact sheets for the chosen stack. After that it builds a minimal working skeleton of the app. It finishes with short, time-limited experiments to test the riskiest parts of the plan.

## e2e-tests

Adds a Playwright end to end test suite to an existing Node and Express app. Tests run against a throwaway install with seeded data and a fake version of any outside service, so real API keys and data are never touched. Each user journey gets its own spec file. It ends with a report of every bug found and any app changes it had to make.

## explain-my-code

Reads a whole repository and writes one onboarding document called CODEBASE_DOCUMENTATION.md. The document has 13 sections and explains how the system is built and how its parts work together. It is written so a new developer can understand the project without meetings or outside help. It includes Mermaid diagrams for the architecture.

## codebase-to-mermaid

Reads a codebase from start to finish and draws Mermaid diagrams of how it actually works. Every box and arrow is tied to a real file and line number. It does not trust the README and does not add modules that do not exist. The diagrams are checked to make sure they render.

## readme-builder

Scans a repository and writes a README.md for beginners. Sections come in a fixed order, the tone is plain English, and marketing words are not allowed. You can have it print the README in the chat or write it to the project folder. Use wp-feature-readme or fullstack-readme instead when you only need a feature list.

## changelog-generator

Writes a changelog for users by reading the actual code changes in a repository. It does not rely on commit messages, which are often vague or wrong. It always covers the full history from the first commit to the latest one. It separates real features and fixes from minor wording changes.

## refactor

Analyzes code and recommends refactoring changes without editing anything. It asks which areas to focus on, the scope, and how deep to go. Every finding is backed by a file and line number. The analysis is based on well known refactoring patterns and design principles such as SOLID.

## explain-sql

Reviews one SQL query without running it. It first checks the query for errors, then explains it clause by clause. The report also covers what the query means for the business, a quality score, and risks such as slow patterns. It ends with a plain English summary of what the query does.

## docblock-rewrite

Replaces PHPDoc and JSDoc blocks with one line comments that a non-technical reader can follow. It runs as a script over a folder or a single file. Original files are backed up with a .bak extension, and each new comment is checked against a banned words list and a 100 character limit. Blocks marked @internal, @deprecated, or @ignore are left alone.

## code-teacher

Turns a function, class, or file into a teaching version of itself. It adds a header comment and line by line comments that explain what each part does and why it is written that way. It also lists the main points a student should learn from the code. A final check confirms that the code itself did not change.

## fullstack-readme

Writes a plain English README.md for a full stack web app. It reads the frontend, the backend, or both, and lists every feature a user can see. The file has three parts: the app name, a short description, and a feature list grouped into categories. Every feature is traced back to a real file in the code.

## explain-regex

Explains one regular expression in 11 sections. It breaks the pattern down piece by piece, shows matching and non-matching examples, lists common mistakes, and checks for catastrophic backtracking, which is known as ReDoS. Every example and claim is tested against real regex engines with a bundled script. You can read the result in the chat or save it to REGEX-EXPLAINED.md.

## script-refactor

Cleans up bash and Python scripts that are run by another program, pipeline, or AI agent. The output, exit codes, and files the scripts produce stay exactly the same. It proves this by running the old and new versions side by side. Any fix that would change behavior is listed separately and only applied if you approve it.

## blueprint-forge

Works in two modes that share the same 14 section format. Scan mode reads an existing codebase and writes a BLUEPRINT.md detailed enough to rebuild the app without the original code. Rebuild mode builds a working app from a blueprint, starting with a plan and checking each step. Secrets from the original code are never copied into the blueprint.

## explain-code

Explains a snippet, file, or function at your experience level: beginner, intermediate, or advanced. You also pick the style, such as a tutorial, a quick summary, interview prep, or a line by line walkthrough. It works out the programming language on its own. At the end it offers to save the explanation as a Markdown file.

## python-forge

Helps with modern Python work in your own project: setting up with uv, async code, type hints, FastAPI, tests with pytest, GitHub Actions, Cloudflare and Modal deploys, and video and image work with OpenCV and FFmpeg. It reads the matching guide before it answers, writes typed code with tests, and keeps the tools your project already uses. It can start a new project and check that it builds, or run your tests and find why one fails. Four bundled scripts check type hints, async code, test coverage, and dependencies.

## retrospec

Writes a Product Requirements Document for an app that already exists, by reading its code. It lists every page, or every group of API endpoints for a backend, and for each one describes the fields, what happens when a user clicks or submits, which APIs it calls, and which pages it links to. It writes in plain business language for product managers. Anything it cannot work out from the code is marked TBC instead of guessed, and APIs that only return made-up data are labelled Mock. Two bundled scripts find routes and endpoints to start from and set up the prd folder.

## mermaid-to-ascii

Converts a Mermaid diagram file into an ASCII diagram that displays correctly in a terminal or plain text file. It supports sequence diagrams, flowcharts, class diagrams, state diagrams, ER diagrams, and Gantt charts. The result is saved as a .txt file with the same name as the source. Use it when you need a diagram in a place that cannot render Mermaid.

## mermaid-sequence

Turns a bullet list of process steps into one Mermaid sequence diagram. It works out who the participants are, what they send to each other, and the direction of each message. The output is a single valid diagram ready to paste into Markdown. Use it to document a flow such as a login or a checkout.

## explain-prompt

Explains an AI prompt in plain English for someone who has never written one. The output always has the same eight sections and describes what the prompt is and what it does. It only explains the prompt and never follows the instructions inside it. Use analyze-prompt when you need a deeper technical review.

## analyze-prompt

Writes a detailed technical analysis of an AI prompt that is ready for a team review. It covers the intent, structure, techniques used, the expected output, ways the prompt can fail, and suggested improvements. It only documents the prompt and never acts on the instructions inside it. Use it when reviewing a prompt before it goes into use.

## rank-prompt

Audits the architecture of a system prompt, agent instructions, or template. It gives the prompt a tier and a score, then lists strengths and risks with quoted evidence. It scores eight dimensions in a table. It ends with the single change that would raise the score the most.

## prompt-rank-table

Runs the same eight dimension audit as rank-prompt but returns only a table. The output is a tier and score, an eight row table with quoted evidence, and a one line verdict. There is no other text in the output. This makes it easy to compare several prompts side by side.

## prompt-stencil

Turns an image generation prompt that already works into a reusable template. It asks which part you want to change between uses, such as the subject or the setting. The template marks which wording must stay fixed and which parts are variables, and includes guards to stop results from drifting. It does not generate any images; the output is text only.

## prompt-bloat

Removes padding from a prompt or skill file while keeping every rule that affects behavior. Things like branding, fake claims of authority, self-grading, and unused settings are cut. Rules such as scope limits, thresholds, input checks, and safety handling are never removed. The output lists what was cut, what it was unsure about, a check that nothing important was lost, and the rewritten file.

## prompt-audit

Scores a prompt out of 100 across nine dimensions, or out of 115 for agent prompts. Every point taken off quotes the part of the prompt that caused it. The report also scans for AI-sounding language, ranks the fixes, and gives three exact replacements you can drop in. It ends with the score the prompt would get after the fixes.

## snippet

Writes one complete standalone script in any of 19 languages, including bash, Python, Go, and TypeScript. Every script has a help option, clear exit codes, cleanup on exit, and a dry run before any destructive step. Secrets are read from environment variables and files are replaced safely so a failed write cannot corrupt them. You choose whether to see the script in the chat or save it to a file.

## session-stats

Turns a Claude Code session into a single dark theme HTML page of statistics. The page shows cards for duration, prompts, tool calls, files changed, tokens, and estimated cost. It also has a table of tool usage and a table of token counts by type. It works offline by reading the session's .jsonl transcript and reports numbers only.

## token-audit

Grades your LLM token usage from four numbers. It shows the metrics, three ratios with the math, and letter grades for input efficiency, cache use, and output size. It combines these into one weighted overall grade. The same four numbers always give the same grades, and it ends with the one fix that would help the most.

## vgademo

Generates a small 1990s style demoscene program written in assembly. It walks you through 14 multiple choice questions covering the visual effect, size budget, platform, video mode, assembler, and memory model. You can type your own answer for any question, such as a starfield or a sine scroller. It then writes the complete program to fit the size you chose.

## fix-formula

Debugs and fixes a broken Excel or Google Sheets formula. You give it the formula and describe what is wrong, such as an error code or a wrong result. It explains the cause and returns a corrected formula. It only fixes existing formulas and does not build spreadsheets, write macros, or design charts.

## crash-report

Explains a macOS crash report in plain English. It reads .ips and .crash files, hang reports, spindumps, and Console.app output. The explanation has six sections: what happened, the main problem, why it happened, why it crashed that way, the fix for developers, and the fix for users. Every claim is tied to a specific field in the report.
