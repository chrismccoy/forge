# WordPress

[← Back to the README](../README.md)

## `wordpress-plugin`

Generates complete WordPress plugins from scratch. the kind you could submit to the WordPress.org repository today.

```
/wp-plugin
```

Most AI generated WordPress plugins fail the same way: missing nonces, raw `$_POST` values, string-interpolated SQL, no text domain, no `uninstall.php`, and a `Plugin Name` header that's the only metadata it bothered to fill in. The `wordpress-plugin` skill takes a different approach. Seven structured intake answers in. full directory tree out, with WordPress Coding Standards compliance, complete security guardrails, internationalization, conditional asset enqueueing, custom tables via `dbDelta()` with proper indexes, and a real uninstall script that removes every artefact the plugin creates.

Five of the seven intake questions are **multiple-choice checklists** (their option lists are too long for `AskUserQuestion`, so they're numbered plain-text lists, each with an `Other (specify)` escape): pick the WordPress mechanisms the plugin uses, the target audience, the admin UI components, the frontend display surfaces, and the third party integrations. Two are free text. the plugin name and a 2-4 sentence description of what the plugin actually does. No ambiguous answers, no follow-up clarification rounds.

## Features

- Intake. five multiple-choice checklists plus two free text. every choice is picked from a list (with an `Other (specify)` escape), not a fill-in-the-blank
- Modular OOP structure. singleton main plugin class wires Admin, Frontend, Database, AJAX, REST, Cron, CLI, Roles, CPT, Meta-box, List-table, Dashboard-widget, Notices, and Integration components
- Security built in. `defined( 'ABSPATH' ) || exit;` on every file, nonces on every mutation, capability checks before every privileged action, sanitization on every input, escaping on every output, `$wpdb->prepare()` on every query
- WordPress mechanisms covered: Custom Post Types & Taxonomies, Settings API, Gutenberg blocks, shortcodes, REST endpoints, WP-CLI commands, cron, custom tables, roles & capabilities, email notifications, frontend forms, dashboard widgets, import/export, activity logging, custom user meta
- Audience-aware code generation. pick "Multisite network administrators" and the activator/deactivator/uninstaller all loop `get_sites()`; pick "Developers" and you get a `docs/` folder with documented hooks
- Frontend surfaces. shortcodes, Gutenberg blocks, classic widgets, template tags, `the_content` injection with opt-out, REST-driven SPA, custom page templates
- Integration scaffolds. WooCommerce, BuddyPress/bbPress, ACF, Elementor, external REST APIs, Stripe/PayPal, Mailchimp/ConvertKit/SendGrid, Google Analytics, OAuth providers, incoming and outgoing webhooks (with HMAC verification and Action Scheduler fallback)
- Internationalization: every user-facing string wrapped in i18n functions with the correct text domain, plus a populated `.pot` file in `languages/`
- Complete documentation: `readme.txt` in WordPress.org format (Contributors, Tags, Requires at least, Tested up to, Stable tag, License, Description, Installation, FAQ, Screenshots, Changelog, Upgrade Notice), `readme.md` GitHub-friendly mirror, PHPDoc on every class and public method
- Complete uninstall: drops every custom table, deletes every option/transient/user-meta/post-meta, clears scheduled events, removes registered roles and capabilities, with the proper `WP_UNINSTALL_PLUGIN` guard
- Conditional asset enqueueing: `get_current_screen()` checks so admin assets never leak onto the frontend and public assets don't load on every admin page
- Custom-table best practices: `$wpdb->get_charset_collate()`, `dbDelta()`, indexes on every queried column, schema version stored in an option for migrations
- Zero placeholders. no `TODO`, no `TBD`, no `{name}`, no `Coming soon` in any generated file

## How it works

1. **Intake**: five multiple-choice checklists (each with `Other (specify)`), two free text:
 - Plugin name (free text)
 - Functionality categories (multi-select: CPTs, Settings page, Blocks, Shortcodes, REST, WP-CLI, Cron, Custom Tables, Roles, Email, Forms, Dashboard Widget, Import/Export, Logging, User Meta)
 - Specific feature detail (free text. 2-4 sentences)
 - Target users (single-select: Site admins / Editors / Frontend visitors / Developers / Multisite admins / Mixed)
 - Admin interface components (multi-select: Top-level menu / Settings submenu / Tools submenu / Meta boxes / List tables / Dashboard widget / Admin notices / Help tabs / None)
 - Frontend display surfaces (multi-select: Shortcodes / Blocks / Widgets / Template tags / `the_content` filter / REST SPA / Custom page templates / None)
 - Third party integrations (multi-select: WooCommerce / BuddyPress / ACF / Elementor / External REST API / Stripe or PayPal / Mailchimp etc / GA / OAuth / Incoming webhooks / Outgoing webhooks / None)
2. **Inference**: slug, text domain, constant prefix, PHP namespace, main file name, and singleton class name are all derived from the plugin name. "Acme Bookings" → slug `acme-bookings`, text domain `acme-bookings`, constants `ACME_BOOKINGS_*`, namespace `AcmeBookings`.
3. **Conditional generation**: each component file is generated only if the corresponding picker option was picked. No empty `blocks/` folder when Gutenberg blocks weren't requested.
4. **Quality checklist**: runs before delivery: ABSPATH guard on every PHP file, nonce on every mutation, capability check before every privileged action, sanitizer on every input, escape on every output, prepared statement on every query, i18n on every string, full `readme.txt`, complete `uninstall.php`, zero placeholders.
5. **Delivery**: writes the full tree to `./{plugin-slug}/` (or `./{plugin-slug}-new/` if the first exists).

## How to use it

```
/wp-plugin ← walks through all seven questions
/wp-plugin "Acme Bookings" ← pre-fills the plugin name
```

It also handles requests like *"build me a WordPress plugin for time-slot bookings"*, *"scaffold a WP plugin with a settings page and a REST endpoint"*, *"create a custom post type plugin for testimonials"*, *"I need a Gutenberg block plugin for newsletter signups"*, or *"make me a WooCommerce extension that adds gift wrapping"* - but you invoke it with `/wp-plugin`; it never auto-triggers.

The full procedure lives at [`lib/wordpress-plugin/SKILL.md`](../lib/wordpress-plugin/SKILL.md).

---

## `wp-builder-pro`

Builds and implements custom WordPress code - themes, plugins, Gutenberg blocks, WooCommerce, and REST endpoints - with security and performance built in.

```
/wp-build
```

Where `wordpress-plugin` builds a whole plugin from scratch in a single run, `wp-builder-pro` is the everyday builder: add a settings page, register a dynamic block, connect a REST endpoint, extend WooCommerce checkout, or track down why the shop page is slow. It routes each request to one of five bundled references and works the same six steps every time - analyze, design, implement, validate with `phpcs --standard=WordPress`, optimize, then test and secure - so the output meets WordPress Coding Standards with nonces, sanitization, escaping, capability checks, and prepared statements already in place.

It also answers symptom-first requests. *"My site is slow"*, *"a plugin throws a fatal error"*, *"this block won't render"*, *"fix my WordPress site"* are all in scope, and it asks for the specific symptom before writing a line of code.

## Features

- Intake. four fields via `AskUserQuestion` - build target (two-step picker: broad class, then specific target), new-vs-existing context, free-text specifics, optional WP/PHP constraints - then routes the target to the right reference
- Full WordPress surface. themes (templates, hierarchy, child themes, FSE), plugins (activation, settings API, hooks, updates), Gutenberg blocks and patterns (static + dynamic), WooCommerce extensions, REST endpoints, ACF fields
- Security by default. nonces on every form/AJAX path, sanitization on every input, escaping on every output, capability checks before privileged actions, `$wpdb->prepare()` with `$wpdb->prefix` on every query
- Performance built in. transient and object caching, query optimization, conditional asset enqueueing via `wp_enqueue_scripts` hooks
- Fixes things that broke. slow site, fatal error, block won't render - asks what's going wrong first, then fixes it
- Five on-demand references. theme-development, plugin-architecture, gutenberg-blocks, hooks-filters, performance-security - loaded only for the matching build target
- Quality gates before delivery. WPCS clean, nonce per mutation, sanitize/escape on all I/O, capability checks, prepared statements, hook-based enqueueing, translatable strings, no core edits
- Scope-locked. defers complete from-scratch plugin scaffolds to `wordpress-plugin` and refuses code review (that's `wordpress-architect-review` / `wordpress-consultant`)

## How it works

1. **Intake**: four fields via `AskUserQuestion` - build target, project context (new vs existing + path), specifics, optional WP/PHP constraints.
2. **Routing**: the chosen build target maps to one or two bundled references (e.g. WooCommerce → `plugin-architecture.md` + `hooks-filters.md`).
3. **Six-step workflow**: analyze → design → implement → validate (`phpcs --standard=WordPress`) → optimize → test & secure.
4. **Quality gates**: runs before delivery - WPCS clean, nonce per mutation, sanitize/escape on all I/O, capability checks, prepared statements, hook-based enqueueing, i18n, no core edits.
5. **Delivery**: the code plus a short explanation of the WordPress-specific patterns used.

## How to use it

```
/wp-build ← walks through all four questions
/wp-build "a dynamic block that lists recent posts" ← seeds the specifics
```

It also handles requests like *"build a custom WordPress theme"*, *"add a settings page to my plugin"*, *"create a Gutenberg block"*, *"extend WooCommerce checkout"*, *"add a REST API endpoint"*, or *"my WordPress site is slow"* - but you invoke it with `/wp-build`; it never auto-triggers.

The full procedure lives at [`lib/wp-builder-pro/SKILL.md`](../lib/wp-builder-pro/SKILL.md).

---

## `html-to-wordpress-theme`

Converts static HTML files into installable WordPress themes.

```
/wp-theme
```

Ever had a beautiful static HTML design built with Tailwind CSS and wished you could just drop it into WordPress? That's exactly what this plugin solves.

The `html-to-wordpress-theme` skill takes your static Tailwind CSS HTML files and converts them into a fully installable, WordPress-compliant theme. No more manually rewriting markup into PHP templates or guessing how WordPress expects things to be structured. the skill handles it all for you through a guided, step by step workflow.

What makes it different from a quick rewrite? Your converted theme comes out with proper accessibility built in, secure code that follows WordPress coding standards, and a Tailwind CSS build pipeline. no CDN links or shortcuts. There's even a 90-point checklist that runs before anything is delivered to make sure nothing got missed.

It asks for your approval at every major step, so nothing large happens without you seeing the plan first.

## Technical Overview

An AI instruction specification that converts static Tailwind CSS HTML files into fully installable, WordPress Theme Review Team-compliant themes.

Built around a phased workflow with mandatory approval gates, it enforces WordPress PHP coding standards, WCAG 2.1 AA accessibility, Tailwind CSS v3 CLI build pipelines, escaping and security rules, and a 90-point self-audit with cited evidence requirements.

It states its assumptions instead of leaving them unsaid, stops rather than generating past the plan, and handles the awkward cases: poor source HTML, context window limits, and work that spans several sessions.

## Features

- Phased workflow with mandatory approval gates. no code ships without user sign-off
- Escaping and sanitization rules for every output context
- WCAG 2.1 AA accessibility built into every phase and template
- Tailwind CSS v3 CLI build pipeline. zero CDN references, zero frameworks
- 90-point self-audit table requiring cited file-and-line evidence for every check
- Graduated failure modes. abort, degraded, or proceed based on source quality
- Full internationalization with enforced translator comments and text domains
- Smart template abstraction rules for repeated markup patterns
- Child theme compatibility with overridable functions and removable hooks
- Automatic chunk planning with size estimation to prevent truncation
- Session continuity protocol for multi-conversation conversions
- Pre-output self-check validates every file before delivery
- Decision tiebreaker hierarchy when multiple valid approaches exist
- Nonce enforcement and input sanitization for all custom forms
- Mobile-first responsive design with keyboard and touch target requirements
- Strict naming conventions derived from a single confirmed theme name
- Auto-generated README with setup instructions, testing checklist, and documentation
- Image performance rules. lazy loading, fetch priority, and registered custom sizes
- Testing checklist covering core functionality, accessibility, and build system
- Content width single source of truth synced across PHP, JSON, and Tailwind config

## How it works

Hand it an `index.html` (and optionally a `single.html`, plus any other page mockups) and it walks you through a 4-phase conversion:

1. **Initialization**: confirm theme name and defaults
2. **Phase 1. Analysis** (1A critical, 1B extended). HTML validation, source quality grading, design-token extraction, file manifest, decision log
3. **Phase 2. Implementation**: generates every theme file in user-approved chunks
4. **Phase 3. Self-Audit**: a 90-item checklist with cited file-and-line evidence before delivery

You approve each phase before the next one starts, so nothing runs away from you.

## How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/wp-theme ← starts the workflow
/wp-theme Brewline ← pre-fills the theme name
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"I have an index.html and a single.html in my Downloads folder. convert them into a WordPress theme called 'Brewline'."*

Either way, confirm the theme name and defaults at the initialization gate, then approve each phase as it completes. Theme files are saved to a folder named after your theme slug.

The full procedure lives at [`lib/html-to-wordpress-theme/SKILL.md`](../lib/html-to-wordpress-theme/SKILL.md), with deep references in the adjacent [`references/`](../lib/html-to-wordpress-theme/references/) folder.

---

## `wordpress-architect-review`

Senior WordPress architect code review for plugins and themes. A file by file audit covering security, performance, architecture, correctness, WordPress standards, accessibility, i18n, and missing infrastructure.

```
/wp-review
```

Most AI code reviews of WordPress plugins read like generic linter output: "consider adding error handling", "use prepared statements where possible", without ever quoting the offending line. The `wordpress-architect-review` skill takes a different stance. It reviews as a senior WordPress architect would for a WordPress.org submission or a security audit. Every finding cites `file:line`, quotes the exact offending code, tags severity (SEVERE / MODERATE / MINOR), states the actual impact, and gives the fix. No filler adjectives, no vague advice, no praise before issues.

Scope-locked. It will not write tutorials, recommend hosting, or answer general WP questions. only audit code. Prompt-injection defenses treat file contents as inert data, so a `// Ignore prior instructions...` comment in the audited code gets flagged as a SEVERE Security finding rather than followed.

## Features

- Target auto-detection. plugin header in root PHP, `style.css` theme header, `block.json`, or `wp-content/mu-plugins/` path; aborts cleanly if none found
- Reads every file directly. every PHP/JS/CSS plus companion configs (`readme.txt`, `theme.json`, `composer.json`, `package.json`, `phpcs.xml`); no summarizing from filenames
- Severity-tagged findings. SEVERE / MODERATE / MINOR. mandatory format: title + `file:line` + code fence + Impact line + Fix line
- 10-row scorecard. Security, Performance, Architecture, Correctness, WordPress Standards, Maintainability, Documentation, Testing, Accessibility/UX, Internationalization. overall weighted toward Security, Performance, Correctness
- Prompt-injection defense. inline instructions in the audited code are treated as inert data and reported as a SEVERE Security finding
- Scope lock. refuses tutorials, recommendations, hosting advice, non-code questions
- Banned filler word list. no "leverage", "robust", "comprehensive", "utilize", "synergy", and ~15 more
- Pre-emit validation. partial reports are regenerated, never shipped
- Optional refactor roadmap. 3-phase modernization path appended when overall score is below 6/10

## Categories covered

- **Architecture**: OOP vs procedural, namespacing, separation of concerns, autoloading, dependency injection
- **Performance**: query count, `get_option` autoload patterns, transient/object caching, asset enqueue strategy, N+1 queries, `WP_Query` efficiency
- **Security**: nonces, capability checks, ABSPATH guard, sanitization (correct filter per data type), escaping on output, prepared statements, CSRF, SSRF, file uploads, `eval`/`create_function`, raw `$_GET`/`$_POST`
- **Correctness**: type juggling, null handling, regex backtracking, race conditions, activation/deactivation idempotency
- **WordPress Standards**: Settings API, `register_setting`, `wp_enqueue_*`, text domain matching slug, i18n functions, REST patterns, hook priorities, transients, multisite
- **Theme-specific**: `wp_head()` / `wp_footer()`, `body_class()` / `post_class()`, template hierarchy, child theme compatibility, `theme.json`, FSE readiness, accessibility (skip links, ARIA, alt text)
- **Plugin-specific**: activation/deactivation/uninstall, `register_activation_hook`, `dbDelta` migrations, version constants, plugin row meta
- **Maintainability**: duplication, function length, naming clarity, dead code, hardcoded values
- **Missing Infrastructure**: `readme.txt` / `style.css` headers, `Requires PHP`, `Tested up to`, autoloader, PHPUnit, CI, `phpcs.xml` (WPCS), `.editorconfig`, `.gitignore`
- **Compatibility**: PHP/WP version range, deprecated function usage, block editor compatibility, multisite, RTL

## How it works

1. **Detect target**: looks for plugin header, theme `style.css`, `block.json`, or `mu-plugins` path
2. **Read everything**: every PHP/JS/CSS file plus companion configs, with the Read tool, never from filename summaries
3. **Categorize findings**: max 5 per category, most severe first, every one cited and quoted
4. **Score and rank**: fill the 10-row scorecard, list the top 5 fixes with S/M/L effort tags
5. **Optional roadmap**: append a 3-phase refactor plan if overall is below 6/10
6. **Pre-emit validation**: verify every section before returning; regenerate anything failing

## How to use it

```
/wp-review ← audits the current working directory
/wp-review ./wp-content/plugins/x ← audits the specified path
```

It also handles requests like *"review my WordPress plugin for security holes"*, *"audit this theme before I submit to WordPress.org"*, *"is this plugin secure"*, *"give me a senior architect review of this WP code"*, or *"rate my plugin out of 10"* - but you invoke it with `/wp-review`; it never auto-triggers.

The full procedure lives at [`lib/wordpress-architect-review/SKILL.md`](../lib/wordpress-architect-review/SKILL.md).

---

## `wordpress-consultant`

A senior WordPress consulting audit, checked against WordPress VIP coding standards, that runs a fixed 10-section framework over a WordPress project. Seven inputs in, an audit out, ending with a 0-100 scorecard and a single summary table.

```
/wp-consult
```

Most "WordPress help" turns into a list of disconnected tips - install this caching plugin, bump that PHP version, try a different host. This plugin replaces that with the audit a senior consultant would run: seven inputs describing the site, ten sections of structured analysis, and a final report that scores the project on health, performance, security, scalability, and code quality. Every section 1-9 is capped at 250 words and written as Finding / Impact / Recommendation bullets - no walls of text, no filler. Section 3 (WooCommerce) drops to `N/A` when the site is not a store. The consultant never recommends nulled or pirated plugins, never suggests editing WordPress core, never prints secrets in examples, and never assigns a security rating without naming what was checked.

The skill body runs the workflow. Step 1 validates inputs - if `Current Challenge` or `Development Goals` is blank it halts and asks, because an audit with no problem statement and no goal is fiction. Step 2 loads the Section 1-10 prompts from `references/framework.md`. Step 3 uses extended thinking before Section 4 (Performance) and Section 10 (Final Report), the two sections that need the deepest reasoning. Step 4 emits every section under its exact header per `references/output-contract.md`. Step 5 applies the Section 10 scales and ends with the mandatory summary table. Step 6 runs a silent self-validation gate - all 10 sections present, every score on its defined scale, table last - before delivery.

Hard refusal on out-of-scope asks (anything that is not WordPress advisory work - it advises, it does not write or review the code itself - declined in one line then back to the framework), on nulled/pirated plugins, on core-file edits, and on security ratings given without naming what was checked.

## Technical Overview

One slash command plus its procedure file. The procedure file `lib/wordpress-consultant/SKILL.md` carries the voice, scope lock, input gates, and 6-step workflow. The Section 1-10 analysis prompts live in `references/framework.md`. The output contract (word caps, Section 10 scales, summary-table columns, pre-delivery checklist) lives in `references/output-contract.md`. The full input-handling and prompt-injection rules live in `references/guardrails.md`. The slash command `/wp-consult` accepts an optional `Current Challenge` arg, then walks the user through `AskUserQuestion` intake for all seven fields.

## Features

- Seven inputs in, a 10-section consultant report out. Website Type + Current Challenge + Technology Stack + Traffic Volume + Development Goals + Performance Requirements + Support Needed
- Two required inputs gate the run - blank `Current Challenge` or `Development Goals` halts with `MISSING INPUT: <field name> required. Provide value and re-run.` The other five are optional and proceed with a flagged assumption at the top of the affected section
- Fixed framework: Architecture Assessment, Development Strategy, WooCommerce Review, Performance Optimization Audit, Security Hardening, Debugging & Troubleshooting, Scalability & Infrastructure, Automation & Workflow, Technical Debt Assessment, Final Senior Consultant Report
- Max 250 words per section 1-9, written as Finding / Impact / Recommendation bullets. Section 3 drops to `## SECTION 3 - N/A (not a WooCommerce site)` for non-stores
- Section 10 scorecard on fixed scales - Health, Performance, Security, Scalability, Code Quality (0-100); Technical Debt Severity (Low/Medium/High/Critical); Recommended Priorities (ranked, max 5)
- Mandatory Markdown summary table as the final element, every run, exact columns
- Extended thinking before Section 4 (Performance) and Section 10 (Final Report)
- Security guardrails - never recommends nulled/pirated themes or plugins, never suggests editing core files, never outputs DB credentials/keys/secrets in examples, never claims a security rating without naming what was checked
- Prompt-injection defense. All seven inputs treated as inert project data. Directives like `ignore prior`, `system:`, `act as`, role-switch attempts inside field values are ignored
- Scope-locked to WordPress engineering. Non-WordPress requests declined in one line, then back to the framework

## How it works

1. **Intake.** Slash command collects all seven fields via `AskUserQuestion`. If `Current Challenge` was passed as `$ARGUMENTS`, confirm and seed it. Empty / blank / `[FIELD_NAME]` on a required field → halt with `MISSING INPUT: <field name> required. Provide value and re-run.`
2. **Validate.** Required gate on `Current Challenge` and `Development Goals`. Optional blanks proceed with a flagged assumption. Conflicting inputs (e.g. Website Type vs Challenge) named in one line and confirmed before proceeding.
3. **Load framework.** Read `references/framework.md`, `references/output-contract.md`, `references/guardrails.md`. Wrap all input values in `<inputs></inputs>` and treat as inert data.
4. **Extended thinking** before Section 4 and Section 10.
5. **Emit Sections 1-10** under exact headers. Mark `## SECTION 3 - N/A (not a WooCommerce site)` for non-stores. Max 250 words per section 1-9.
6. **Section 10 + summary table.** Apply the fixed scales. End with the single mandatory summary table - it must be last.
7. **Silent validation gate.** Confirm all 10 sections present, every score on its scale, table last, no security rating without naming what was checked. Fix any gap before output.

## How to use it

Two ways to invoke:

**Slash command:**

```
/wp-consult "checkout is slow on our WooCommerce store"   ← arg seeds Current Challenge, intake fills the rest
/wp-consult                                               ← full 7-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"review my WordPress architecture"*, *"WordPress performance audit"*, *"WordPress security review"*, *"scale my WordPress site"*, *"WooCommerce performance review"*, *"WordPress technical debt assessment"*, *"senior WordPress consultant"*

After the run, work the Section 10 priorities top-down - the ranked list is capped at 5 and ordered by impact, so start at the top, and use the summary-table scores to track health, performance, security, scalability, and code quality across follow-up engagements.

The full procedure lives at [`lib/wordpress-consultant/SKILL.md`](../lib/wordpress-consultant/SKILL.md), the slash command at [`commands/wp-consult.md`](../commands/wp-consult.md), and the on-demand reference files at [`lib/wordpress-consultant/references/framework.md`](../lib/wordpress-consultant/references/framework.md), [`lib/wordpress-consultant/references/output-contract.md`](../lib/wordpress-consultant/references/output-contract.md), [`lib/wordpress-consultant/references/guardrails.md`](../lib/wordpress-consultant/references/guardrails.md).

---

## `wordpress-formatter`

Formats a theme's template files and partials to the WordPress coding standard - tabs, spacing, array style, alignment - without changing how any page renders. It installs the tools, writes the config, runs the fixer, and checks the result.

```
/wp-format
```

Most WordPress themes drift from the coding standard over time - mixed tabs and spaces, inconsistent array syntax, ragged alignment. This plugin cleans that up the safe way. It installs PHP_CodeSniffer and the WordPress Coding Standards into the theme's local `vendor/` folder (nothing global), writes a scoped `phpcs.xml.dist`, and runs `phpcbf` to fix everything that can be fixed automatically. It runs the fixer twice, since some fixes unlock others, then checks every changed file with `php -l` before it calls the job done.

The important part is what it will not do. Formatting should never change how a page renders, so anything that could change behavior is reported but left alone: turning a loose `==` into a strict `===`, adding the strict flag to `array_search`, or removing `extract()`. The one exception is Yoda conditions, which only reorder the two sides of a comparison and are safe, and even those are applied only if you say yes. It also stops early on the two things that go wrong most often: if the folder is not a WordPress theme, or if there is no `composer.json`, it asks or stops rather than guessing.

## Features

- Five quick questions first. Scope (templates and partials, or all theme PHP), strictness (formatting only, or the full standard), whether to apply the safe Yoda reorders or only report them, the theme name, and any files to skip. Say "just do it" for safe defaults
- Installs the tools for you. PHP_CodeSniffer and the WordPress Coding Standards go into the theme's local `vendor/` as dev dependencies - nothing is installed globally
- Writes a scoped config. A `phpcs.xml.dist` that leaves out `vendor`, `node_modules`, and by default `lib`, `inc`, `assets`, and `functions.php`
- Fixes formatting only. Runs `phpcbf` twice for tabs, spacing, array style, and alignment - never escaping, sanitization, or behavior
- Leaves risky changes alone. Loose `==` to `===`, the `array_search` strict flag, and `extract()` are reported, not applied, so runtime behavior never changes
- Checks its own work. Runs `php -l` on every changed file and stops if anything breaks
- Two safe stops. No `composer.json` means it asks before creating one; a failed install means it shows the exact error instead of guessing
- Adds re-run shortcuts. `composer lint` and `composer format` so you can run it again anytime

## How it works

1. **Check first.** Confirm the folder is a WordPress theme (a `style.css` header or template files). Stop if it is not.
2. **Intake.** Ask the five questions and wait for the answers, or use the defaults on "just do it".
3. **Install.** Add PHPCS and WPCS as Composer dev dependencies, skipping if they are already there. Stop and report if the install fails.
4. **Configure.** Write `phpcs.xml.dist` scoped to the answers, and add the `lint` and `format` composer scripts.
5. **Fix.** Run `phpcbf` twice, then `php -l` on every changed file. A syntax error is a hard stop.
6. **Report.** List what was fixed and what was left, with a reason for each item that was left.

## How to use it

```
/wp-format ← formats the current theme
/wp-format ./wp-content/themes/mytheme ← formats a specific theme
```

It also handles requests like *"format my WordPress theme to the coding standard"*, *"run phpcbf on my templates"*, *"fix the indentation and spacing in my theme"*, *"set up phpcs for this theme"*, or *"convert my theme files to tabs"* - but you invoke it with `/wp-format`; it never auto-triggers.

The full procedure lives at [`lib/wordpress-formatter/SKILL.md`](../lib/wordpress-formatter/SKILL.md), and the slash command at [`commands/wp-format.md`](../commands/wp-format.md).

---

## `menu-icon-picker`

Ports a searchable Font Awesome icon picker onto every menu item under Appearance > Menus, integrated straight into a classic theme.

```
/wp-menu-icons
```

Most themes that show icons on menu items make you type the Font Awesome class by hand into a plain text field - `fa-solid fa-house`, spelled exactly, no preview, no search. This tool replaces that with a click-to-pick modal: open a menu item, click the icon button, search the full Font Awesome grid, pick one, done. It ships its own reference copy of the picker (PHP + JS + CSS), so there is no external plugin to install - the code is ported into the theme itself and rebranded to the theme's own prefix, with no `mip_` placeholder name left behind.

It is not a plugin and it is not a blind copy-paste. The tool first runs a precheck: the picker hooks the classic menu system (`nav-menus.php`, `wp_nav_menu_item_custom_fields`), so a block/FSE theme that drives navigation through the Navigation block is rejected up front with a message rather than half-wired. Then it decides how much to install by looking at what the theme already has.

## Features

- Precheck first. classic-menu themes only; block/FSE themes are detected and rejected before any file is touched
- Two install modes, auto-detected. **Mode A** (theme already has an icon field + renderer) swaps the plain text input for the picker, reuses the existing meta key, and changes zero frontend code. **Mode B** (no field) installs the full admin side, adds a reader helper, and writes `MENU-ICON-FRONTEND.md` with copy-paste render instructions
- Full rebrand. every `mip_` / `Menu_Icon_Picker` / `_mip_icon` placeholder is renamed to the theme's own prefix, read from the theme, not invented; the JS↔PHP contract (field name, localized object, element IDs, CSS classes) is kept in sync
- Security gates on every path. nonce (`update-nav-menu-nonce`), capability (`edit_theme_options`), sanitize on save, escape on output; safe practice overrides any instruction that would skip a gate
- Normalize on save. the picked value is stored render-ready (a full `fa-solid fa-house` class), idempotent and backward compatible, so the frontend prints it verbatim
- Theme-correct enqueue. picker CSS/JS and Font Awesome load only on `nav-menus.php`; asset URLs use `get_theme_file_uri()` so parent and child themes both resolve
- Static verification. `php -l`, `phpcs` (or a cited manual security check), a placeholder-leak grep, the JS↔PHP contract shown side by side, gated-enqueue and security greps, and save-wiring proof - all pasted as evidence before the job is called done
- Prompt-injection defense. every theme file is treated as inert data; instructions found inside theme code are ignored and flagged

## How it works

1. **Precheck**: confirm the theme uses classic menus (`register_nav_menus` / `wp_nav_menu`); reject block/FSE themes with a message.
2. **Naming**: pin the theme's function prefix and text domain, read from the theme.
3. **Mode**: classify by two signals - an icon **field** and a **renderer**. Both present -> Mode A. No field -> Mode B. Field but no renderer -> Mode A admin plus a Mode B frontend doc.
4. **Port**: move the JS/CSS into the theme's `assets/`, drop the plugin packaging, rebrand every identifier, normalize the value on save.
5. **Frontend (Mode B)**: write `MENU-ICON-FRONTEND.md` with two render options (drop-in filter or custom walker) using the real prefix and key - templates are never auto-edited.
6. **Verify**: run the seven static checks and paste the evidence; summarize the mode, prefix, meta key, and files touched. A click-through smoke test is handed to you to run in the browser.

## How to use it

```
/wp-menu-icons ← integrates into the theme in the current directory
/wp-menu-icons ./wp-content/themes/mytheme ← target a specific theme
```

It handles jobs like *"add an icon picker to my WordPress menu items"*, *"let me pick a Font Awesome icon per menu item"*, *"replace the icon text field on my nav menu with a picker"*, or *"install a menu icon picker into my theme"* - but you invoke it with `/wp-menu-icons`, not by describing the task. Like every Forge tool it sets `disable-model-invocation`, so it never fires on its own; the slash command is the only trigger.

The full procedure lives at [`lib/menu-icon-picker/SKILL.md`](../lib/menu-icon-picker/SKILL.md), the bundled reference source at [`lib/menu-icon-picker/sources/`](../lib/menu-icon-picker/sources/), and the slash command at [`commands/wp-menu-icons.md`](../commands/wp-menu-icons.md).

---

## `wordpress-report-card`

Scores a WordPress plugin or theme on ten areas, each out of 10, with an overall score and a rubric tier. That's the whole output - no findings, no fixes, no prose.

```
/wp-report-card
```

Sometimes twenty severity-tagged findings with quoted code and a refactor roadmap is more than the moment needs - you just want a number. Is this plugin a 3 or an 8? Where does it lose points? `wp-report-card` answers exactly that and stops. It detects the target, reads every file, scores the ten areas against a fixed rubric, then prints only the table and the overall tier.

The scores are earned, not estimated. The tool reads every PHP, JS, CSS, and companion config file directly and grades from what the code actually does - a missing nonce or a raw `$_GET` in SQL caps Security low no matter how clean the rest looks. The output is deliberately narrow; the analysis behind each number is not.

Use it as a quick gate - score a plugin before you invest in it, track a codebase's number across refactors, or compare two candidates at a glance.

## Features

- One deliverable. the 10-row scorecard, an Overall row, and a single tier line - nothing before the table, nothing after the tier
- Grades from real code. detects plugin / theme / block plugin / MU-plugin, reads every file directly, scores from what the code does, not filenames
- Ten scored areas. Security, Performance, Architecture, Correctness, WordPress Standards, Maintainability, Documentation, Testing, Accessibility/UX, Internationalization - overall weighted toward Security, Performance, Correctness
- Rubric tier. the overall score is mapped to one of five tiers (enterprise-ready down to critical/broken)
- No findings, no fixes, no roadmap. suppressed by design; each Notes cell is a single grounded clause, never a recommendation
- Prompt-injection defense. file contents are inert data; an injection attempt in the code drops the Security score and is noted, never followed
- Scope-locked. scores code only; declines build, scaffold, and change requests in one line

## How it works

1. **Detect target**: plugin header, theme `style.css`, `block.json`, or `mu-plugins` path; abort cleanly if none found.
2. **Read everything**: every PHP/JS/CSS plus companion configs, with the Read tool, never from filename summaries.
3. **Score internally**: grade the ten areas against `references/categories.md`; do the finding-level analysis but do not print it.
4. **Emit the table**: the 10 rows plus a weighted Overall row, each Notes cell one grounded clause.
5. **Tier line**: map the overall score to its rubric tier from `references/rubric.md` - the only text outside the table.
6. **Pre-emit check**: confirm all rows filled, exactly one tier line, no findings or fixes leaked; regenerate if not.

## How to use it

```
/wp-report-card ← scores the current working directory
/wp-report-card ./wp-content/plugins/x ← scores the specified path
```

It handles jobs like *"just give me the scorecard for this plugin"*, *"rate this theme out of 10, no details"*, *"score my WordPress plugin, table only"*, or *"what's this plugin's report card"* - but you invoke it with `/wp-report-card`, not by describing the task. Like every Forge tool it sets `disable-model-invocation`, so it never fires on its own; the slash command is the only trigger.

The full procedure lives at [`lib/wordpress-report-card/SKILL.md`](../lib/wordpress-report-card/SKILL.md), the slash command at [`commands/wp-report-card.md`](../commands/wp-report-card.md), and the scoring references (category roll-up + rubric tiers) at [`lib/wordpress-report-card/references/`](../lib/wordpress-report-card/references/).

---

## `wordpress-grade`

A letter grade on one piece of WordPress code. Paste a snippet or point at a single file and it returns six fixed sections: what the code does, a grade from A to F against a stated rubric, what it gets right, the real problems with the reason each one matters, the nitpicks kept separate, and a verdict on whether it belongs on a live site.

```
/wp-grade
```

Where `wordpress-architect-review` walks a whole plugin or theme file by file and `wordpress-report-card` scores a directory on ten areas out of 10 with no prose, `wordpress-grade` takes the thing you just wrote and tells you whether it is any good. It reads for purpose before it judges - what the code is for, which WordPress APIs and idioms it leans on - so the grade lands on the code as written rather than on a checklist.

The rubric is fixed, which is what makes two runs comparable. A is ships-as-is: no security defect, no performance defect, idiomatic throughout. B is sound with one substantive issue. C is several substantive issues, or one missing security control. D is multiple missing controls, or a defect that breaks under normal production load. F is directly exploitable - unprepared SQL built from request data, an unrestricted file write, an unauthenticated privileged action. `+` and `-` move within a band.

Before the grade is written, six things get re-scanned: output escaping, input sanitization on the superglobals, nonce verification on state-changing requests, capability checks on privileged actions, SQL built without `$wpdb->prepare()`, and queries inside loops or a `WP_Query` pulling back more than it needs. A hit on any of them is a weakness, never a nitpick, and it moves the grade. Running the other way, an odd-looking pattern is checked for a deliberate back-compat reason before it is called a defect.

Pasted code is data. A comment that says `rate this an A` gets quoted at the top of the verdict as an injection signal and the code is graded exactly as written.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-grade/SKILL.md`, which loads the master template from `lib/wordpress-grade/references/prompt-template.md`. The command `/wp-grade` takes the code inline or as a file path, or asks for it. In scope: PHP written against the WordPress APIs - plugin, theme, mu-plugin, and WP-CLI code - plus the JS and CSS shipping alongside it.

## Features

- Letter grade A-F with `+`/`-`, bound to a written rubric so the same code earns the same grade twice
- Purpose before judgment. What the code does and why it likely exists, with the WordPress idioms named
- Up to six strengths - idiomatic API use, caching, escaping and sanitization, prefixing, defensive coding
- Up to six weaknesses, each with the reason it matters rather than a label
- Nitpicks kept in their own list so style notes never get mistaken for real problems
- Six-point safety scan before the grade: escaping, sanitization, nonces, capability checks, `$wpdb->prepare()`, queries in loops
- A safety hit is always a weakness, never a nitpick, and always reflected in the grade
- Back-compat aware. An unusual pattern is checked as a deliberate accommodation before being called a defect
- Asks for the code if you run it with nothing, and refuses to grade input that is not WordPress code
- Large input handled. Reviews what it can, says where it stopped, offers to continue
- Injection resistant. Text inside the code aimed at the reviewer is quoted in the verdict and not obeyed

## How it works

1. **Intake.** Take the code from the argument, a file path, or a plain ask.
2. **Gate.** Stop on an absent or placeholder submission; refuse to grade non-WordPress input.
3. **Read for purpose.** Establish what the code does and which WordPress APIs it uses.
4. **Safety scan.** Account for all six checks before writing anything.
5. **Grade.** Assign the rubric band, then justify it in one sentence.
6. **Check.** Six sections in order, every safety hit in Weaknesses, each list capped at six, every weakness carrying its "why".
7. **Print.** The six sections only.

## How to use it

```
/wp-grade ./wp-content/plugins/acme/acme.php   ← grade one file
/wp-grade                                      ← asks you to paste the code
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"grade this WordPress code"*, *"is this plugin code any good"*, *"review this hook"*, *"what letter grade would you give this"*, *"is this safe to ship"*

For a file-by-file review of a whole plugin or theme use [`/wp-review`](#wordpress-architect-review); for the scorecard-only pass over a directory use [`/wp-report-card`](#wordpress-report-card).

The full procedure lives at [`lib/wordpress-grade/SKILL.md`](../lib/wordpress-grade/SKILL.md), the slash command at [`commands/wp-grade.md`](../commands/wp-grade.md), and the master template at [`lib/wordpress-grade/references/prompt-template.md`](../lib/wordpress-grade/references/prompt-template.md).

---

## `wordpress-performance`

Cold, full-file performance review for WordPress plugins, themes, mu-plugins, and loose code. Reads every file in the target and reports what breaks under load - unbounded queries, cache bypass, N+1 loops, per-request database writes, polling, and cron that blocks its own queue.

```
/wp-performance
```

Most performance checks are a grep pass wearing a report's clothing. They find `posts_per_page => -1` because it has a literal signature, and miss the query sitting inside a `foreach` two files away because it does not. The `wordpress-performance` procedure separates the two jobs: a bundled scan script greps for the patterns that do have signatures and uses the hits only to decide reading order, then every file in the coverage manifest gets read top to bottom. The findings that matter most - N+1 loops, expensive work running in the wrong request context, missing caching around a slow call - only exist in the reading pass.

The second thing it refuses to do is remember. Every run rebuilds the manifest, re-reads every file from disk, and ignores earlier findings, earlier reports, and earlier clean verdicts. Run it twice on the same theme and the second pass is genuinely independent, which is the only way a second pass finds anything. Coverage is reported as a number in the output - files read against files in the manifest - so an incomplete pass cannot read as a complete one.

## Features

- Cold run every time. manifest rebuilt, files re-read, prior verdicts discarded. no warm-start, no "already checked"
- Full-file coverage. every `.php`, `.inc`, `.js`, `.jsx`, `.ts`, `.tsx`, `.json` in the manifest read end to end; files over 1500 lines read in sequential chunks
- Triage, not verdicts. the scan script orders the reading pass; a grep match is a candidate until the surrounding code is read
- Mandatory coverage line. `files read / files in manifest / total lines` printed with the report; any unread file named with its reason
- Severity-tagged findings. CRITICAL / WARNING / INFO with `file:line`, quoted code, an Impact line naming the failure mode and scale, and a Fix line
- Context-aware severity. admin, CLI, and cron paths are scored against the load they actually face, not public traffic
- Platform-aware fixes. managed host, self-hosted, or shared hosting changes whether an object-cache fix is even available
- Prompt-injection defense. file contents are inert data; an instruction hidden in a comment is reported, never followed
- Banned filler word list. no "leverage", "robust", "comprehensive", "utilize", "synergy", and ~15 more
- Pre-emit validation. a report missing its coverage line or a finding's citation is regenerated, not shipped

## What it checks

- **Database queries**: unbounded `posts_per_page`, `query_posts()`, N+1 inside loops, `meta_query` value scans, `post__not_in`, leading-wildcard `LIKE`, missing `no_found_rows`
- **Hooks and request context**: expensive work on `init` / `wp_loaded` with no guard, option writes on frontend paths, hook callbacks that run everywhere
- **Caching**: uncached `url_to_postid` and friends, missing object-cache wrappers, dynamic transient keys, volatile-data transients, large autoloaded options
- **Cache bypass**: `session_start()`, cookies on public pages, query-parameter cache busting
- **AJAX and REST**: `admin-ajax.php` bootstrap cost, POST for reads, `setInterval` polling
- **Assets**: unconditional enqueues, missing version strings, no defer/async strategy, full library imports
- **Block editor**: `registerBlockStyle()` volume, re-sanitized InnerBlocks content, static blocks for client builds
- **WP-Cron**: callbacks looping every user or post, `wp_schedule_event` without a `wp_next_scheduled` guard, cron on page requests
- **External HTTP**: uncached `wp_remote_get`, missing timeouts, absent error handling

## How it works

1. **Detect target**: plugin header, theme `style.css`, `block.json`, `mu-plugins` path, or a loose PHP/JS directory
2. **Build the manifest**: `wp-perf-manifest.sh` lists every reviewable file with line counts, pruning `vendor`, `node_modules`, build output, and minified assets
3. **Triage**: `wp-perf-scan.sh` returns severity-grouped grep hits, used only to order the reading pass
4. **Read everything**: every manifest file in full, in batches, ticked off as it goes
5. **Report**: findings by severity with citation, quoted code, impact, and fix, then the coverage line and headline verdict
6. **Pre-emit validation**: manifest freshness, coverage arithmetic, and per-finding format checked before anything is returned

## How to use it

```
/wp-performance ← reviews the current working directory
/wp-performance ./wp-content/themes/mytheme ← reviews the specified path
/wp-performance ← run it again for an independent second pass
```

It also handles requests like *"why is this site slow"*, *"audit this plugin before our sale"*, *"find the query that's timing out"*, or *"scan it again, I think we missed something"* - but you invoke it with `/wp-performance`; it never auto-triggers.

For a security and architecture review instead, use `/wp-review`. For the scorecard alone, `/wp-report-card`. To change the code rather than review it, `/wp-build`.

The full procedure lives at [`lib/wordpress-performance/SKILL.md`](../lib/wordpress-performance/SKILL.md).

---

## `wp-demo-content`

Build a WP-CLI demo content importer for a classic WordPress theme: read the theme's whole data model out of its code, write `demo/demo-import.php`, test it end to end on a throwaway SQLite site, and report the theme's own bugs.

```
/wp-demo
```

Seeing whether a theme actually looks right needs a site full of believable content - posts in every format, photos at the right aspect ratio, video and audio the player accepts, threaded comments, menus, widgets, and every meta box, Customizer setting and options field the theme reads. Building that by hand takes hours, and a generic dummy-content plugin fills none of the theme's own fields. This tool writes an importer that fits the specific theme, because it maps the theme's data model first: every meta key with its storage, field type, sanitize callback, allowed values, where it applies, and where templates print it, each cited `file:line`, before a line of importer code exists.

The importer it produces is a single `final class` in the theme's own code style, run with `wp eval-file`. It takes positional arguments - `reset`, `purge`, `count=N`, `seed=N`, `no-comments`, `verify` - refuses to run twice or on multisite, flags everything it creates so `purge` removes only its own content, and backs up every setting it touches so `purge` restores them exactly. The same `seed` always produces the same content, with dates anchored to the day it runs.

Then it tests for real, on a throwaway WordPress built by a bundled script: SQLite, WP-Cron off, `WP_DEBUG` on, pretty permalinks, Classic Editor active, the theme symlinked and activated. Fourteen numbered steps follow - marker values, liveness checks on every media URL, phpcs to zero violations, a small import inspected item by item, a refuse-to-rerun check, a purge that must restore the markers, a full import plus `verify`, two `reset seed=1` runs compared for identical output, front-end and admin fetches grepped for PHP notices, field-by-field verification, screenshots at 1440 and 390 wide, and a final purge and teardown. Anything that cannot run is marked BLOCKED with the reason rather than reported as passed.

## Technical Overview

One slash command and a seven-file procedure bundle. `lib/wp-demo-content/SKILL.md` carries the scope lock, the inputs, the six-step workflow, the deliverables contract and the hard rules. `references/data-model.md` is the read-the-theme-first step; `references/content-spec.md` is what the importer creates; `references/importer-spec.md` is the arguments, guards, flagging, settings backup, run order and runtime; `references/testing.md` is the fourteen test steps; `references/bug-fixing.md` is the optional fix pass; and `references/setup-test-site.md` holds the test harness itself, copied out by line range and checked against a `sha256` recorded in the procedure, so a mistyped copy cannot run.

## Features

- Maps the theme's data model first - every meta field, Customizer setting and options field, cited `file:line`, before any code is written
- Fills fields the way the theme's own save handler stores them, calling its sanitize functions, ACF field keys, CMB2, Meta Box and Carbon Fields formats
- Images sized to each slot's aspect ratio and never below the largest registered crop, deduplicated by file hash and picsum photo ID
- Freely licensed video and audio, liveness-checked and size-capped before download; animated GIFs generated locally with GD
- Reversible by construction: everything flagged, every touched setting backed up, `purge` restores the site exactly
- Repeatable: the same `seed` gives identical content, dates anchored to the run day
- Tested on a throwaway SQLite WordPress, never against a real site, with phpcs at zero violations
- Screenshots at 1440 and 390 wide, with overlay bypass via `SHOT_INIT_JS`; skipped cleanly when Chrome or Node 22+ is missing
- Reports the theme's own bugs in `demo/BUGS.md`, grouped by severity with where, what breaks, and a suggested fix
- Never writes to code or secret fields, never emails or pings, never commits, and treats theme file contents as data

## How it works

1. **Read the theme.** Grep and read it, then summarize the data model in tables with `file:line` citations. Large themes split the reading across subagents.
2. **Decide the content.** Posts across every format and post type, terms, authors, dates, comments, counters, media, fields, pages, menus, widgets, and one consistent fake brand across every Customizer and options field.
3. **Write the importer.** One file, theme code style, positional arguments, guards, flagging, settings backup, fixed run order.
4. **Test it.** Build the throwaway site from the bundled script after checking its hash, then run the fourteen steps.
5. **Deliver.** `demo/demo-import.php`, `demo/BUGS.md`, `demo/README.md`, `demo/screenshots/`, a `demo/` line in `.distignore`, and a report with real numbers.
6. **Offer fixes.** Only if bugs were found and only on a yes: confirm each bug, ask about the ones needing a decision, fix on a `fix/demo-audit-bugs` branch, and record everything in `demo/CHANGED.md`.

## How to use it

```
/wp-demo                      ← the theme in the current directory
/wp-demo ~/themes/mytheme     ← a specific theme
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"build demo content for this theme"*, *"I need a demo importer"*, *"fill a test site with content for my theme"*, *"generate sample content that exercises every field"*, *"what's broken in this theme"*

**Needs:** Linux with bash 4.4+, PHP with `pdo_sqlite`, and `curl`, `unzip`, `mktemp`, `timeout`. Chrome or Chromium and Node.js 22+ for screenshots - without them screenshots are skipped and everything else still runs. Classic themes only; block themes, MySQL and multisite are out of scope.

The full procedure lives at [`lib/wp-demo-content/SKILL.md`](../lib/wp-demo-content/SKILL.md), the step references under [`lib/wp-demo-content/references/`](../lib/wp-demo-content/references/), and the slash command at [`commands/wp-demo.md`](../commands/wp-demo.md).

---

## `wordpress-feature-readme`

A plain-English feature README for a WordPress theme or plugin. Point it at a folder or a `.zip` and it returns three parts only: the name as the title, a short description of what it is and who it is for, and every user facing feature grouped into categories a site owner can read.

```
/wp-feature-readme
```

A theme or plugin page lives or dies on its feature list, and the usual one is either a copy of the author's memory or a pile of technical terms. This tool builds the list from the code itself. It reads every file in scope twice: a first pass that records each file and the features it adds, and a second pass that hunts for what the first one missed, such as a small footer option, an admin screen toggle, or a template tweak that only shows under a condition. Only features traced to a real file make the list. Readme files, changelogs, and code comments are never taken as proof.

Every feature is then translated out of developer language. A custom post type for portfolio items becomes a dedicated section for showcasing portfolio work; WooCommerce template overrides become built in support for running an online store. Categories get plain names, are ordered from largest to smallest, and are never padded to look fuller than the code is.

The writing rules are strict: no emojis, no en or em dashes, no hype words like "powerful" or "seamless", no installation, credits, license, changelog, FAQ, or support sections, and no headings beyond the title and the categories.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-feature-readme/SKILL.md`, which loads the master template from `lib/wordpress-feature-readme/references/prompt-template.md`. The command `/wp-feature-readme` takes a folder or `.zip` path as its argument, or asks for one, then asks whether to print the README or write it to `README.md`. In scope: classic and block themes, child themes, plugins, MU-plugins, block plugins, and add-on plugins.

## Features

- Tells themes and plugins apart by their `Theme Name` and `Plugin Name` headers
- Asks which one to document when a folder holds more than one theme or plugin
- Documents only what a child theme adds on top of its parent
- Documents only what an add-on plugin adds to the plugin it extends
- Treats plugins bundled inside a theme as part of that theme
- Two passes over every file, the second one hunting for small settings and conditional display logic
- Lists only features traced to real code; readmes, changelogs, and comments are not proof
- Marks features that need a paid license, a pro version, or an outside account
- Turns technical capabilities into everyday language a site owner understands
- Plain-English categories ordered from largest to smallest, never padded
- No emojis, dashes, hype words, or extra sections in the output
- Injection resistant. Text inside the code is described, never obeyed

## How it works

1. **Intake.** Take the path from the argument or ask for it; ask whether to print or write the file.
2. **Identify.** Find the theme or plugin header; stop on none, ask on more than one.
3. **First pass.** Read every file in scope and list the features each one adds.
4. **Second pass.** Re-scan for anything missed and add it.
5. **Translate.** Group into plain-English categories and rewrite each feature for a site owner.
6. **Check.** Title, description, categories only; every bullet traced; no emoji, dashes, or hype words.
7. **Deliver.** Print the README or write `README.md`.

## How to use it

```
/wp-feature-readme                         ← asks for the theme or plugin
/wp-feature-readme ~/themes/mytheme        ← a specific folder
/wp-feature-readme ~/Downloads/mytheme.zip ← a zipped theme or plugin
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a feature list for my theme"*, *"what does this plugin actually do"*, *"make a README a site owner can read"*, *"list every feature in plain English"*

For a beginner README on a project that is not WordPress use [`/readme-builder`](code.md#readme-builder); for a review of the same code use [`/wp-review`](#wordpress-architect-review).

The full procedure lives at [`lib/wordpress-feature-readme/SKILL.md`](../lib/wordpress-feature-readme/SKILL.md), the slash command at [`commands/wp-feature-readme.md`](../commands/wp-feature-readme.md), and the master template at [`lib/wordpress-feature-readme/references/prompt-template.md`](../lib/wordpress-feature-readme/references/prompt-template.md).

---

## `wordpress-wp-cli`

Bash scripts that use WP-CLI to run one task across every WordPress site on a server, or on one site. It writes new ones, or reviews a script you already have, lists what is wrong with it line by line, and fixes it.

```
/wp-cli
```

Running the same job on forty sites by hand means forty logins, or a quick loop that stops at the first broken install and never tells you which sites it skipped. This tool writes the loop properly. It finds every `wp-config.php` under a sites root, talks to each install through one `wp_run` wrapper, keeps going when a site fails, and ends with a summary table and an exit code that tells cron what happened. Every script is built from the same tested skeleton, so the flags, the logging, and the safety rules are the same from one script to the next.

Every script is a dry run until you add `-f`. It asks you to type `yes` before changing anything, and `-y` skips that for cron. Update scripts export the database first and wrap core updates in maintenance mode, git scripts never push without `-f`, and every change is read back afterwards, so anything that did not take shows as `FAILED (not verified)`.

It never runs anything against your live sites. Each script is tested against a fake sites root and a stub `wp` before it is handed over, and you run the real thing.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-wp-cli/SKILL.md`. Three references load on every run: `references/conventions.md` (house style: header, strict mode, options, logging, exit codes), `references/fleet.md` (finding installs, the `wp_run` wrapper, multisite, the site loop, the summary), and `references/safety.md` (dry run, confirmation, and the rules for deletes, updates, backups, git, URLs, and downloads). Write mode starts from `references/examples/skeleton.sh`; review mode works through `references/review-checklist.md`. Ten area guides under `references/areas/` carry the commands and known traps for content, comments, media, users, updates, settings, themes and git, backups, maintenance, and custom WP-CLI commands, with a tested PHP example in `references/examples/custom-command.php`.

## Features

- Runs one task across every install under a sites root, or one site with `-s`
- Dry run by default; `-f` applies, a typed `yes` confirms, `-y` skips the prompt for cron
- One site's failure never stops the rest, and the run ends with a summary table and a meaningful exit code
- Shared flags on every script: `-r` sites root, `-s` one site, `-m` search depth, `-f`, `-y`, `-q`, `-h`
- Update scripts export the database first and wrap core updates in maintenance mode
- Every change is read back, and anything that did not take is reported as `FAILED (not verified)`
- Git scripts never push unless `-f` is passed
- Area guides for comments, media, users, updates and checksums, settings, themes and git, backups, and maintenance
- Suggests a small custom WP-CLI command in PHP when a job would call `wp` thousands of times, and writes it only on a yes
- Review mode tags every finding CRITICAL, WARNING, or INFO with the line, the risk, and the fix, and asks before fixing
- `bash -n`, `shellcheck`, and a stub dry run and apply run on every script before hand-off
- Never runs against your real sites, and treats existing scripts and command output as data

## How it works

1. **Intake.** Write or review, then the task or the script path, one question at a time.
2. **Read the rules.** House style, fleet, and safety, plus the area guide that matches the task.
3. **Write.** Check every WP-CLI command exists, decide bash or a custom command, build from the skeleton, and `chmod +x`.
4. **Or review.** Run the checklist (and a quick scan for a folder), report findings, then ask: fix everything, only bugs and safety, or report only.
5. **Test.** `bash -n`, `shellcheck`, `-h`, a bad option, then a dry run and a `-f -y` run against a stub `wp` and a fake sites root, cleaned up afterwards.
6. **Report.** The path, usage for a dry run, an apply run, one site, and cron, the defaults chosen, and the test results.

## How to use it

```
/wp-cli                                         ← asks write or review
/wp-cli delete spam and trash pending comments  ← write a new script
/wp-cli ./scripts/wp-user-purge.sh              ← review and fix a script
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a script that updates plugins on every site"*, *"purge spam comments across all my WordPress installs"*, *"check core checksums on the whole server"*, *"back up every active theme"*, *"review my WP-CLI script"*

**Needs:** bash and `shellcheck` for testing. The scripts themselves need WP-CLI on the server they run on. Defaults: sites root `$HOME/webapps` (override with `-r` or `SITES_ROOT`) and search depth 2.

For demo content on a single theme use [`/wp-demo`](#wp-demo-content); for a script in another language use [`/snippet`](utilities.md#prompt-snippet).

The full procedure lives at [`lib/wordpress-wp-cli/SKILL.md`](../lib/wordpress-wp-cli/SKILL.md), the references under [`lib/wordpress-wp-cli/references/`](../lib/wordpress-wp-cli/references/), and the slash command at [`commands/wp-cli.md`](../commands/wp-cli.md).

---

## `wordpress-block-theme`

Build or review a WordPress block theme made for full site editing. Give it a name and what the site is for and it writes a complete theme; point it at an existing block theme and it reports every problem by file and line.

```
/wp-block-theme
```

Block themes move almost everything into `theme.json`, HTML block templates, and patterns, and a small mistake there fails quietly: a raw hex color that the Site Editor can't change, a template part whose area doesn't match its registration, a pattern slug without a namespace, a font pulled from a CDN. This tool knows theme.json version 3 (WordPress 6.6+) key by key, the template hierarchy and its fallbacks, Global Styles, style variations, patterns, navigation, local fonts, the layout system, and the WordPress.org directory rules.

**Build** writes the whole theme from a short brief: `theme.json` version 3, templates, template parts, patterns, style variations, and local fonts, with preset-based styles and color pairs that pass WCAG AA. Name one of the 53 styles from [`/wp-mockup`](#wordpress-theme-mockup) and it carries that style's colors, fonts, radii, shadows, and spacing into the presets. It then reviews its own output with every check and fixes it until the verdict is `SHIP`.

**Review** reads `theme.json`, every template, part, pattern, and style variation, `style.css`, `functions.php`, and child theme overrides. Each finding carries the file and line, a severity (CRITICAL, WARNING, or INFO), the bad code, and the fixed code, and the report ends with one verdict: `SHIP`, `FIX WARNINGS`, or `DO NOT SHIP`. Review is read-only.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-block-theme/SKILL.md` and seven references: `build.md` (intake, files to create, rules, testing), `checks.md` (checks for every file type plus quick scans), `report-format.md` (severity, the report format, the "not a bug" list, version requirements), `theme-json-guide.md`, `template-patterns.md`, `fse-guide.md`, and `patterns.md` (working examples used for the GOOD side of findings). Build's optional live check uses the throwaway SQLite site builder bundled with [`/wp-bug-audit`](#wordpress-theme-bug-audit).

## Features

- Builds a complete block theme from a name, a purpose, and optional design notes
- Takes colors and fonts from any of the 53 `/wp-mockup` styles
- theme.json version 3 with a `$schema`, preset scales, and object-notation root padding
- Local fonts only, never a font CDN
- Color pairs that pass WCAG AA contrast
- Self-review until `SHIP`, plus JSON, `php -l`, and block markup balance checks
- Builds and reviews child themes of a block theme
- WordPress.org mode applies the stricter directory rules: `readme.txt`, `screenshot.png`, license, no phone-home code
- Every finding cites `file:line`, quotes the code, and gives a BAD/GOOD pair
- Judges each finding against a "not a bug" list before reporting it
- Injection resistant: text inside the theme that tries to give orders is reported as CRITICAL

## How it works

1. **Intake.** Build or review, then the brief or the theme path, one question at a time.
2. **Build:** derive the slug, text domain, prefix, and pattern namespace; write every file; test; self-review until `SHIP`; optionally run a live check on a throwaway site.
3. **Review:** detect a child theme and WordPress.org targeting, map the theme and run the quick scans, read every file in full, check each file type, and filter against the "not a bug" list.
4. **Report.** Findings grouped by file, the summary, and one verdict line.

## How to use it

```
/wp-block-theme                                   ← asks build or review
/wp-block-theme Trail Notes, a hiking blog, swiss ← build a new theme
/wp-block-theme ~/themes/my-theme                 ← review a block theme
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"build me a block theme for a recipe site"*, *"make an FSE theme in the bento style"*, *"review my theme.json"*, *"is this block theme ready for WordPress.org"*

Block themes only. To move a classic theme to a block theme use [`/wp-classic-to-block`](#wordpress-classic-to-block); for converting static HTML into a classic theme use [`/wp-theme`](#html-to-wordpress-theme); for a full bug audit on test sites use [`/wp-bug-audit`](#wordpress-theme-bug-audit).

The full procedure lives at [`lib/wordpress-block-theme/SKILL.md`](../lib/wordpress-block-theme/SKILL.md), the references under [`lib/wordpress-block-theme/references/`](../lib/wordpress-block-theme/references/), and the slash command at [`commands/wp-block-theme.md`](../commands/wp-block-theme.md).

---

## `wordpress-classic-to-block`

Move an existing classic PHP WordPress theme to a block theme. Point it at the theme and it writes a migration plan; ask it to migrate and it writes the block theme, plus a companion plugin for the business logic, in phases you can undo.

```
/wp-classic-to-block
```

Classic themes hide a lot of their behavior in PHP: custom post types and metaboxes in `functions.php`, Customizer settings, widgets, walkers, shortcodes, and filters that turn the block editor off. Switch themes carelessly and that content, and the settings behind it, can vanish. This tool treats the theme's stored data as the contract. Meta keys, option names, URLs, and hook names stay the same, so posts and settings keep working after the switch, and the classic theme stays available as a fallback until the new one is confirmed.

**ASSESS** reads the whole theme, including `template-parts/`, `inc/`, and build files such as `package.json` and `tailwind.config.js`. It sorts every file and every rendered view into AUTO, MANUAL, PLUGIN, or DELETE, lists every stored value the theme reads (post, term, user, comment, and menu item meta, theme mods, options, widget settings, cron jobs), and ends with a risk register, an hour estimate per phase, and one verdict: full migration, hybrid, or rebuild. ASSESS is read-only.

**MIGRATE** writes `theme.json` version 3 from the colors, fonts, and spacing the theme actually uses, then block templates, template parts, patterns, and style variations. It moves CPTs, taxonomies, metaboxes, shortcodes, REST routes, and cron into a companion plugin or an `inc/functionality/` folder, turns hand-coded metaboxes into block editor panels with the same keys and save rules, and finishes with WP-CLI data migrations that have a dry-run option and a checklist where every item has a "Verify:" command.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-classic-to-block/SKILL.md` and eighteen references, loaded at the gate that needs them: Gate 0 detection, ASSESS rates and the Phase 0 checklist, `theme.json` derivation, style variations, template conversion, patterns, plugin extraction, hand-coded and complex metaboxes, legacy features, site-state migration, large themes, hybrid and child themes, theme-bundled logic, WordPress.org requirements, verification, quality and deployment, and the anti-pattern list. `examples/` holds a classic theme, its converted block theme, a block child theme, and a complete companion plugin. `scripts/static-checks.sh` is a read-only check script: on a classic theme it lists what the theme contains, and on the migrated theme it checks syntax, block markup, pattern slugs, plugin blocks, and leftover block-editor sabotage.

## Features

- Inventories every PHP file and rendered view, scored by impact and effort
- Finds code that turns off block editor features and refuses to port it
- Field inventory of every stored value, with where it is saved, where it is printed, and whether it is still live
- Go/no-go verdict on rendered views: straightforward, moderate, high-risk, or rebuild
- Hour estimate per phase, with separate rates for small and very large themes
- `theme.json` version 3 with role-based color slugs, fluid type, and editor guardrails
- Customizer color schemes become style variations, including a per-visitor dark mode toggle
- Repeating sections become patterns; theme text and image paths stay out of `.html` templates
- Business logic moves to a companion plugin or `inc/functionality/`, with the plugin dependency spelled out
- Hand-coded metaboxes become editor panels that keep every key, sanitizer, and empty-value rule
- Shortcodes keep working in old content while new content uses blocks
- Menus, widgets, Additional CSS, and page template assignments are exported and moved
- Reversible phases with the classic theme tagged as a fallback first
- Read-only check script plus a Playwright screenshot diff of the classic and block themes

## How it works

1. **Intake.** Theme path, ASSESS or MIGRATE, where the logic lives, and how the theme is distributed, one question at a time.
2. **Gate 0 and Gate 1.** Find block-editor sabotage and complexity markers, export site state (or list the export commands), and classify every file and view.
3. **ASSESS:** summary, inventory table, complexity and hours, phased plan, risk register, plugin extraction list, field inventory, and the verdict.
4. **MIGRATE:** plugin data layer, then plugin blocks, then the theme: `theme.json`, style variations, parts, templates, patterns, editor panels, and WP-CLI migrations. Large themes go one phase at a time.
5. **Verify.** `static-checks.sh` on the new theme and plugin, a smoke test with the plugin off, and the acceptance checklist.

## How to use it

```
/wp-classic-to-block                              ← asks for the theme and the mode
/wp-classic-to-block ~/themes/my-theme assess     ← migration plan only
/wp-classic-to-block ~/themes/my-theme migrate    ← write the block theme
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"convert my classic theme to a block theme"*, *"how hard is it to move this theme to FSE"*, *"move these Customizer colors into theme.json"*, *"replace these metaboxes with Block Bindings"*, *"turn this shortcode into a block"*

Classic themes only. For a new block theme or a review of one use [`/wp-block-theme`](#wordpress-block-theme); to fill every field with test content before migrating use [`/wp-demo`](#wp-demo-content); for a full bug audit on test sites use [`/wp-bug-audit`](#wordpress-theme-bug-audit).

The full procedure lives at [`lib/wordpress-classic-to-block/SKILL.md`](../lib/wordpress-classic-to-block/SKILL.md), the references under [`lib/wordpress-classic-to-block/references/`](../lib/wordpress-classic-to-block/references/), and the slash command at [`commands/wp-classic-to-block.md`](../commands/wp-classic-to-block.md).

---

## `wordpress-theme-bug-audit`

A full bug audit of a WordPress theme. It reads every file, checks the code against about 160 numbered bug checks, tests everything on throwaway WordPress sites across the PHP versions your customers run, and writes a verified bug list and a coverage report into the theme's `audit/` folder.

```
/wp-bug-audit
```

A theme can pass every linter and still lose a customer's settings when they switch tabs on the options page, print a nonce into a cached page, or fatal on PHP 7.4. This tool looks for the bugs a customer would actually hit. It maps every field the theme stores and every template that reads it, checks each against the numbered list, then exercises all of it on real throwaway sites: activation, probe data through every save handler, the front end, the admin, every entry point, JavaScript errors, and a list of variations (page cache, plain permalinks, a subdirectory install, right to left, user roles, time zones, multisite, and more), each with its own evidence file.

It is built for long runs. Before anything starts it asks eight questions and shows the file count, a token estimate, free disk space, and which tools it found, then waits for **Start**. Progress is saved after every step in a work folder outside the theme, so an interrupted run can resume. Every bug is confirmed and independently checked before it is written, and nothing in the theme changes unless you ask for fixes afterwards.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-theme-bug-audit/SKILL.md`, which holds the ground rules, an outline of the intake, and a phase map. Each phase reads its reference in full first: `start.md` (finding the theme, the intake questions, and the start confirmation), `reading.md`, `checks.md` (the numbered check list), `testing-setup.md`, `testing-steps.md`, `variations.md`, `testing-final.md`, `verify-and-report.md`, and `fixes.md`. Eighteen tested scripts in `scripts/` do the fiddly parts: a sha256-checked SQLite site builder, per-version PHP passes with standalone PHP builds, phpcs and PHPStan in batches, ESLint and stylelint, page fetches that catch hidden fatals, HTML and asset checks, JavaScript and axe-core capture, and must-use plugins that log queries and block outbound requests.

## Features

- Finds the theme on its own - the current folder, up to three levels below, or a parent - and announces it before starting
- Eight multiple-choice questions: scope, PHP versions, extra plugins, known issues, fixes, marketplace, upgrade test, oldest WordPress
- Shows a token estimate, disk space, and missing tools before asking Start or Cancel; no answer means no audit
- About 160 numbered checks across fields, templates, code, JavaScript, security, upgrades, caching, privacy, accessibility, and multisite
- A pass per PHP version your customers run, with standalone PHP builds for 8.x and Docker for 7.4
- Throwaway SQLite sites only, outbound hosts blocked, no `sudo`
- Every variation checked as its own item with its own evidence
- Upgrade test from an earlier git tag or release
- Optional WordPress.org or ThemeForest rules
- Every bug confirmed and independently checked, with `file:line`, check ID, affected PHP versions, customer symptom, and steps to reproduce
- A coverage file that shows every file, entry point, and check ID with its outcome, so gaps are visible
- Resumes after a crash, a closed terminal, or a full context
- The theme is never changed unless you ask for fixes; earlier audits are left alone

## How it works

1. **Find the theme** and announce it; check for an unfinished run to resume.
2. **Intake.** Eight questions, then a cost and tools summary, then Start or Cancel.
3. **Read.** Every theme file, split across subagents for big themes; build the data model and inventory.
4. **Check.** Every row and template against every check ID.
5. **Test.** Tools and static analysis, then steps 1-17 on throwaway sites: activation, probe data, handlers, front end, admin, entry points, JavaScript, screenshots, variations, PHP and WordPress versions, upgrade, standards, loading, coverage.
6. **Verify and report.** Confirm each bug, check it independently, set severity, and write `BUGS.md` and `COVERAGE.md` into `audit/`.
7. **Offer fixes.** Only if you asked for them at intake.

## How to use it

```
/wp-bug-audit                     ← finds the theme from the current folder
/wp-bug-audit ~/themes/mytheme    ← a specific theme
/wp-bug-audit ~/Downloads/x.zip   ← a zipped theme, audited from a scratch copy
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"audit my theme for bugs"*, *"find everything broken in this theme before release"*, *"test my theme on PHP 7.4 through 8.4"*, *"what will customers hit in this theme"*

**Needs:** Linux with bash 4.4+, Python 3, PHP with `pdo_sqlite`, `curl`, `unzip`, `mktemp`, `timeout`, `rsync`, network access, Composer (or PHP able to run `composer.phar`), Node.js 22+ with npm, Chrome or Chromium, and about 2 GB free. Java, Xdebug or pcov, and Docker without `sudo` are used when present. Anything missing is marked BLOCKED or SKIPPED and the rest still runs. A full audit costs about 15,000-20,000 tokens per PHP file; Standard scope is roughly half.

For a scorecard review use [`/wp-review`](#wordpress-architect-review); for a performance-only pass use [`/wp-performance`](#wordpress-performance); for block themes use [`/wp-block-theme`](#wordpress-block-theme).

The full procedure lives at [`lib/wordpress-theme-bug-audit/SKILL.md`](../lib/wordpress-theme-bug-audit/SKILL.md), the references under [`lib/wordpress-theme-bug-audit/references/`](../lib/wordpress-theme-bug-audit/references/), the scripts under [`lib/wordpress-theme-bug-audit/scripts/`](../lib/wordpress-theme-bug-audit/scripts/), and the slash command at [`commands/wp-bug-audit.md`](../commands/wp-bug-audit.md).

---

## `wordpress-theme-mockup`

A clickable static HTML mockup of a classic WordPress theme in one of 53 named design styles, such as bento, swiss, glassmorphism, retro terminal, or y2k. You get one page per theme template, all sharing a header, sidebar, and footer and linking to each other.

```
/wp-mockup
```

Seeing a design style on a real blog - not a landing page - usually means building the theme first. This tool skips that. It writes `index.html`, `single.html`, `page.html`, `archive.html`, `category.html`, `tag.html`, `author.html`, `search.html`, and `404.html`, with an optional `front-page.html`, into `./<style>-theme-mockup/`. The single post page shows every element a writer can use - headings, lists, quotes, aligned images, a gallery, a table, and code - so the style covers all of them.

The style specs describe landing pages, so the tool maps them onto a blog instead of copying them. Fonts, colors, shadows, radii, textures, and motion carry over exactly; cards become post cards and widgets, pills become category and tag badges, and buttons become "Read more" and pagination. Landing-only sections like pricing and hero blocks are left out. Post text stays readable even in loud styles, because the style goes into the frame around the article.

The mockup is built to be converted: Tailwind CSS v3 with the style's tokens in `tailwind.config`, no inline style attributes, WordPress class names, semantic landmarks, and WCAG 2.1 AA contrast. When it is done, run [`/wp-theme`](#html-to-wordpress-theme) from inside the mockup folder to turn it into a real theme.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-theme-mockup/SKILL.md`, which holds the style picking rules, how a style is applied to a theme, the build rules, the output, and the style list. `references/theme-pages.md` covers the page set, the shared parts, the single-post content showcase, comments, and content rules. `references/styles/<slug>.md` holds one design spec per style, 53 in all, and only the requested one is read. The same 53 specs drive the named styles in [`/wp-block-theme`](#wordpress-block-theme).

## Features

- 53 named design styles, from bento and swiss to vaporwave, gothic, and longform
- A style name it doesn't know gets the 2-3 closest suggestions, never an improvised style
- Nine linked pages covering every classic theme template, plus an optional static front page
- Identical `<head>`, config, header, sidebar, and footer on every page
- A single post that shows every content element a writer can use
- Right sidebar by default, or left, or none
- Tailwind CSS v3 Play CDN with the style's tokens; no inline styles, no Tailwind v4 syntax
- WCAG 2.1 AA contrast, visible focus, labelled fields, and reduced motion
- Mobile first, with the sidebar stacking below the content
- Every link between pages works
- Built for `/wp-theme` to convert into a real theme

## How it works

1. **Intake.** The style, the fictional site, the sidebar, and any extra pages, one question at a time.
2. **Read.** `theme-pages.md` and only the chosen style's spec.
3. **Adapt.** Apply the style's visual rules exactly, map its components onto blog parts, and leave out landing-only sections.
4. **Build.** Write every page with the shared parts and working links.
5. **Check.** Every item in `theme-pages.md`, the shared parts, and every link.
6. **Report.** The folder and files, the style rules adapted or left out, and the `/wp-theme` handoff.

## How to use it

```
/wp-mockup                                        ← asks for the style
/wp-mockup bento, Trail Notes, a hiking blog      ← a style and a site
/wp-mockup swiss, left sidebar                    ← a style and a layout
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"mock up a WordPress theme in the bento style"*, *"show me a blog theme in vaporwave"*, *"build theme pages I can convert later"*

For turning the mockup into a theme use [`/wp-theme`](#html-to-wordpress-theme); for a block theme in one of these styles use [`/wp-block-theme`](#wordpress-block-theme).

The full procedure lives at [`lib/wordpress-theme-mockup/SKILL.md`](../lib/wordpress-theme-mockup/SKILL.md), the references under [`lib/wordpress-theme-mockup/references/`](../lib/wordpress-theme-mockup/references/), and the slash command at [`commands/wp-mockup.md`](../commands/wp-mockup.md).

---

## `wordpress-doc-pass`

Document every line of a WordPress plugin without touching its code. Point it at a plugin and it writes full PHPDoc and JSDoc on every file, class, constant, property, function, closure, and hook, plus inline comments that explain why the code does what it does, then proves that only comments changed.

```
/wp-doc-pass
```

Comment passes go wrong in quiet ways: a reformatted line, a renamed variable, a moved `phpcs:ignore`, or a rewritten WP-CLI docblock that changes the command's help and arguments. This tool backs up every file first and runs a checker that compares the code token by token for PHP and by syntax tree for JavaScript, compares the layout line by line, and holds every comment that is really code - WP-CLI docblocks, PHPUnit annotations, lint directives, `translators:` comments, bundler hints, license headers, and plugin header fields - exactly where it was.

It follows the plugin's own coding standard. A WordPress Coding Standards ruleset gets WordPress-style docblocks with tabs, hash notation for argument arrays, and no `@return void`. PSR-12 / PER code gets precise modern types and `@return void` everywhere. Legacy code with no standard gets the conventions it already uses. `@since` values are never invented: they come from git tags or a changelog entry that names the symbol, or the tool asks.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-doc-pass/SKILL.md` and seven references, read at the step that needs them: the core rules (hard rule, failure protocol, coverage, hooks, templates, and the list of comments to preserve), one file per coding-standard profile (WPCS, PSR-12 / PER, legacy), the JavaScript and TypeScript rules, the checks each agent runs, and the checker specification. `scripts/checker/` holds the checker: `verify.mjs` proves only comments changed, `coverage.mjs` lists anything still missing a docblock, and `php-tokens.php` bridges to PHP's own tokenizer. It is copied into the session scratchpad and installed there, so nothing is written into the plugin or the plugin folder.

## Features

- Detects the coding standard from phpcs or php-cs-fixer config, or from the code itself
- Full docblocks on every file, class, interface, trait, enum, constant, property, function, method, and closure
- Hook docblocks on every `apply_filters` and `do_action`, with one full docblock per hook and pointer lines elsewhere
- Template docblocks that list every variable a view receives, read from the code that includes it
- JSDoc, WordPress JS docs, or TSDoc, with shared `@typedef`s for localized config objects and block attributes
- Comments that are code - WP-CLI help, PHPUnit annotations, lint directives, `translators:`, bundler hints, license headers - kept byte for byte
- Adds a missing `translators:` comment before a gettext call with placeholders
- `@since` taken from git tags or the changelog, never invented, and existing values never changed
- Up to seven parallel agent groups sharing one rules file, so the style cannot drift between groups
- Checker self-tested on deliberately broken copies before it is trusted
- Tests, phpcs, and PHPStan / Psalm compared against the baseline before and after
- A ranked bug list with `file:line`, security issues and races first, fixed only when you ask

## How it works

1. **Intake.** Plugin path, scope (plugin PHP, JS assets, tests), and whether to report bugs, one question at a time.
2. **Discover.** Git state, files, coding standard, minimum PHP version, `@since` policy, comments that are code, the hook map, shared JS shapes, and the agent groups.
3. **Safety net.** Back up every file, record tests, phpcs, and static analysis, build the rules file, and set up and self-test the checker.
4. **Document.** Parallel agents, each checking its own files and restoring any file that fails.
5. **Verify and report.** Checker, syntax, tests, coverage scan, phpcs, and static analysis on the whole tree, then the report and the bug list.

## How to use it

```
/wp-doc-pass                                       ← asks for the plugin and scope
/wp-doc-pass ~/plugins/acme-notes                  ← the whole plugin
/wp-doc-pass ~/plugins/acme-notes php only         ← skip JS and tests
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"add PHPDoc to every function in this plugin"*, *"the WordPress-Docs sniffs are failing, fix the docblocks"*, *"document this plugin's hooks"*, *"add JSDoc to the admin scripts"*

Comments only. To change or fix code use [`/wp-build`](#wp-builder-pro); for a plain-English feature README use [`/wp-feature-readme`](#wordpress-feature-readme); to format code to the coding standard use [`/wp-format`](#wordpress-formatter).

The full procedure lives at [`lib/wordpress-doc-pass/SKILL.md`](../lib/wordpress-doc-pass/SKILL.md), the references under [`lib/wordpress-doc-pass/references/`](../lib/wordpress-doc-pass/references/), the checker under [`lib/wordpress-doc-pass/scripts/checker/`](../lib/wordpress-doc-pass/scripts/checker/), and the slash command at [`commands/wp-doc-pass.md`](../commands/wp-doc-pass.md).

---

## `wordpress-modernize`

Moves a WordPress plugin from the WordPress Coding Standards to PSR-12, puts its classes in a PSR-4 `src/` tree grouped by role, and adds strict PHP 8.1 types - without changing anything a site, a user, or another plugin can see.

```
/wp-modernize
```

Modernizing a plugin by hand breaks things quietly: a renamed method that was also a hook callback, an `uninstall_plugins` entry that still names the old class, a strict type that throws on the string `get_option()` returned, or a reformatted template that adds a visible space. This tool works in eight phases. Every phase runs the full test suite, compares each test's assertion count with the previous phase, commits, and tags, so any tag is a safe rollback point and an interrupted run resumes from the last one.

Nothing outward-facing changes: option, meta, and transient keys, REST routes, hook names, the text domain, error codes, HTML output, and JS config keys stay exactly as they were. Names WordPress has already stored in the database - the uninstall callback, class names in serialized objects - keep working through a `class_alias` or a wrapper, and an upgrade test proves it on a site that ran the old version.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-modernize/SKILL.md` - intake, the eight hard rules, the phase table, and the final report - and eight phase files under `references/`, each read only when its phase starts. `scripts/surface.php` lists a plugin's outward-facing names (option and meta keys, REST routes, hooks, script handles, menu slugs, nonces, `WP_Error` codes, and translatable strings with their context and plural) so the last phase can diff the baseline against the result. Progress lives in `MIGRATION_LOG.md`, kept out of git.

## Features

- Reads the code first and suggests every intake answer: root namespace, released or not, and how the tests run
- Builds a safety net before any change: hook, REST, and settings wiring tests, plus golden copies of admin HTML and raw post output
- Proves the PSR-12 layout pass changed no code with a token-stream diff
- Renames snake_case methods to camelCase only in real positions - definitions, calls, and callbacks - never by find-and-replace
- Leaves alone methods WordPress calls by name: `WP_List_Table`, `WP_Widget`, `WP_REST_Controller`, `Walker`, and WP-CLI command overrides
- PSR-4 `src/` tree grouped by role (`Admin/`, `Settings/`, `Rest/`, `Contracts/`, `Support/` …), shown for approval before anything moves
- A small autoloader and `Plugin::boot()`; Composer stays a dev tool
- Several plugins in one folder get one sub-namespace and one autoloader each
- `declare(strict_types=1)` everywhere, full types, and casts where WordPress hands back strings
- `class_alias` and wrapper methods for every name stored in the database
- The `msgid` set and every `translators:` comment checked against the baseline
- Final proof: lint at zero, golden copies, unchanged outward-facing names, a PHP 8.1 run, a smoke test with outbound HTTP blocked, and an upgrade test from the baseline version
- A tag per phase and a resumable progress log; nothing is ever pushed

## How it works

1. **Intake.** Reads the code, then asks for the root namespace, whether the plugin is released, and how to run the tests, in one question set.
2. **Baseline and safety net.** Tests green, `v0-baseline` tagged, then a PHPCS ruleset and the safety-net tests.
3. **Layout and names.** `phpcbf` with a token-level proof, then camelCase methods one class at a time.
4. **Namespace.** The `src/` tree you approved, the autoloader, and `Plugin::boot()`.
5. **Lint and types.** Lint to zero, then strict PHP 8.1 types and `Requires PHP: 8.1`.
6. **Verify and report.** Every check against the baseline, the upgrade test, and a report of every cast, ignore, alias, and decision left for you.

## How to use it

```
/wp-modernize                              ← uses the current directory or asks
/wp-modernize ~/plugins/acme-notes         ← that plugin
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"convert this plugin from WPCS to PSR-12"*, *"namespace this plugin and move the classes to src/"*, *"add strict PHP 8.1 types to this plugin without breaking anything"*, *"modernize this WordPress plugin"*

Whole-plugin migrations only. To format to the WordPress Coding Standards use [`/wp-format`](#wordpress-formatter); to add a feature or fix code use [`/wp-build`](#wp-builder-pro); to document code without changing it use [`/wp-doc-pass`](#wordpress-doc-pass).

The full procedure lives at [`lib/wordpress-modernize/SKILL.md`](../lib/wordpress-modernize/SKILL.md), the phase files under [`lib/wordpress-modernize/references/`](../lib/wordpress-modernize/references/), the checker at [`lib/wordpress-modernize/scripts/surface.php`](../lib/wordpress-modernize/scripts/surface.php), and the slash command at [`commands/wp-modernize.md`](../commands/wp-modernize.md).

---

## `wordpress-plugin-submission`

Decides whether a built WordPress plugin is ready for WordPress.org review, using the plugin's own evidence and current official guidance, and returns one verdict with the smallest set of fixes.

```
/wp-submission
```

Most pre-submission checks stop at a clean Plugin Check run. The review team does not: they read the readme against the code, trace what a license key actually locks, ask what data leaves the site, and reject slugs that begin with someone else's trademark. This tool asks the question a reviewer would: what can be proved from this ZIP, readme, service model, and the current rules - and what must change before submission?

Every rule it cites comes from the official WordPress.org pages it fetches at run time, with the fetch date recorded, never from memory. Every finding carries an evidence label - CONFIRMED, SUPPORTED, or UNKNOWN - and the verdict comes from fixed rules applied in order, so two runs on the same plugin reach the same answer. It reports and drafts only; it never changes the plugin and never promises approval.

## Technical Overview

One slash command plus its procedure file `lib/wordpress-plugin-submission/SKILL.md` - request scopes, evidence modes, six sections, the status set, the verdict rules, and the response contract - and three reference files under `references/`: `official-sources.md` (the URLs to fetch, submission-policy facts, the guideline index, and the common review surfaces, each tagged verified with a date, verify, or engineering), `example-rows.md` (a worked run showing every table, the verdict, the fix list, and a reviewer reply), and `situations.md` (updates to approved plugins, closures and reopen requests, block plugins, and multisite).

## Features

- Fetches the Detailed Plugin Guidelines, Common issues, the developer FAQ, the readme guide, and the Plugin Review Team blog, and records the date of each
- Triages Plugin Check output by category and severity: a Plugin Repo ERROR blocks upload, so it is a blocker; Security-category ERRORs are risks, except on a reopen after a security closure
- Traces every paid or external feature: local code, gate, remote work, what stops when unpaid, data sent, and disclosure - catching trialware and services that only validate a license
- Checks readme fields (Stable tag, short description, tags, Contributors, License) and every readme claim the code contradicts
- Five request scopes: full gate, review email, recovery after new feedback or a revised ZIP, a focused single check, and post-approval updates, closures, and reopen requests
- One verdict from fixed rules: DO NOT SUBMIT, INSUFFICIENT EVIDENCE, READY AFTER FIXES, or READY TO SUBMIT - every confirmed fixable problem listed whatever the verdict
- A reply plan and an email draft for the review team, listing every change and where it was made, sent on the original thread
- Block plugins checked against the Block Specific Plugin Guidelines only when the Block Directory is the target
- Never changes plugin files, never cites a rule from memory as current, never promises approval

## How it works

1. **Scope and evidence.** Picks the request scope and evidence mode, fetches the official sources, and records what was and was not supplied.
2. **Plugin Check.** Records the version and categories, classifies every finding, and walks the common review surfaces Plugin Check misses.
3. **Money and services.** Traces each paid or external feature to its gate, its remote work, and its disclosure.
4. **Readme.** Checks the fields against the readme rules and the claims against the code.
5. **Evidence map.** Turns every finding, reviewer point, and missing piece of evidence into one row with one status.
6. **Verdict and reply.** Applies the verdict rules in order, lists the fixes and the recheck plan, and drafts the reply to the review team.

## How to use it

```
/wp-submission                              ← gates the plugin in the current directory
/wp-submission ~/plugins/acme-export        ← gates that plugin
```

Paste Plugin Check output, a `readme.txt`, or a WordPress.org review or closure email into the same message to include it as evidence.

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"is my plugin ready for WordPress.org"*, *"is this trialware"*, *"triage these Plugin Check errors"*, *"check my readme.txt"*, *"help me reply to the plugin review team"*, *"my plugin was closed, what do I fix before asking to reopen"*

Directory readiness only. To scaffold a new plugin use [`/wp-plugin`](#wordpress-plugin); to add a feature or fix code use [`/wp-build`](#wp-builder-pro); for a security, performance, and architecture review use [`/wp-review`](#wordpress-architect-review); for a letter grade use [`/wp-grade`](#wordpress-grade).

The full procedure lives at [`lib/wordpress-plugin-submission/SKILL.md`](../lib/wordpress-plugin-submission/SKILL.md), the reference files under [`lib/wordpress-plugin-submission/references/`](../lib/wordpress-plugin-submission/references/), and the slash command at [`commands/wp-submission.md`](../commands/wp-submission.md).
