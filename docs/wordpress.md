# WordPress

[← Back to the README](../README.md)

## `wp-builder-pro`

Builds and implements custom WordPress code - themes, plugins, Gutenberg blocks, WooCommerce, and REST endpoints - with security and performance built in.

```
/wp-build
```

Where `wordpress-plugin` builds a whole plugin from scratch in a single run, `wp-builder-pro` is the everyday builder: add a settings page, register a dynamic block, connect a REST endpoint, extend WooCommerce checkout, or track down why the shop page is slow. It routes each request to one of five bundled references and works the same six steps every time - analyze, design, implement, validate with `phpcs --standard=WordPress`, optimize, then test and secure - so the output meets WordPress Coding Standards with nonces, sanitization, escaping, capability checks, and prepared statements already in place.

It also answers symptom-first requests. *"My site is slow"*, *"a plugin throws a fatal error"*, *"this block won't render"*, *"fix my WordPress site"* all trigger it, and it asks for the specific symptom before writing a line of code.

## ✨ Features

- 📋 Intake. four fields via `AskUserQuestion` - build target (single-select), new-vs-existing context, free-text specifics, optional WP/PHP constraints - then routes the target to the right reference
- 🏗️ Full WordPress surface. themes (templates, hierarchy, child themes, FSE), plugins (activation, settings API, hooks, updates), Gutenberg blocks and patterns (static + dynamic), WooCommerce extensions, REST endpoints, ACF fields
- 🔒 Security by default. nonces on every form/AJAX path, sanitization on every input, escaping on every output, capability checks before privileged actions, `$wpdb->prepare()` with `$wpdb->prefix` on every query
- ⚡ Performance built in. transient and object caching, query optimization, conditional asset enqueueing via `wp_enqueue_scripts` hooks
- 🩺 Fixes things that broke. slow site, fatal error, block won't render - asks what's going wrong first, then fixes it
- 📚 Five on-demand references. theme-development, plugin-architecture, gutenberg-blocks, hooks-filters, performance-security - loaded only for the matching build target
- ✅ Quality gates before delivery. WPCS clean, nonce per mutation, sanitize/escape on all I/O, capability checks, prepared statements, hook-based enqueueing, translatable strings, no core edits
- 🚦 Scope-locked. defers complete from-scratch plugin scaffolds to `wordpress-plugin` and refuses code review (that's `wordpress-architect-review` / `wordpress-consultant`)

## 🔄 How it works

1. **Intake**: four fields via `AskUserQuestion` - build target, project context (new vs existing + path), specifics, optional WP/PHP constraints.
2. **Routing**: the chosen build target maps to one or two bundled references (e.g. WooCommerce → `plugin-architecture.md` + `hooks-filters.md`).
3. **Six-step workflow**: analyze → design → implement → validate (`phpcs --standard=WordPress`) → optimize → test & secure.
4. **Quality gates**: runs before delivery - WPCS clean, nonce per mutation, sanitize/escape on all I/O, capability checks, prepared statements, hook-based enqueueing, i18n, no core edits.
5. **Delivery**: the code plus a short explanation of the WordPress-specific patterns used.

## 🚀 How to use it

```
/wp-build ← walks through all four questions
/wp-build "a dynamic block that lists recent posts" ← seeds the specifics
```

Or natural language: *"build a custom WordPress theme"*, *"add a settings page to my plugin"*, *"create a Gutenberg block"*, *"extend WooCommerce checkout"*, *"add a REST API endpoint"*, *"my WordPress site is slow"*.

The full procedure lives at [`lib/wp-builder-pro/SKILL.md`](../lib/wp-builder-pro/SKILL.md).

---

## `wordpress-plugin`

Generates complete WordPress plugins from scratch. the kind you could submit to the WordPress.org repository today.

```
/wp-plugin
```

Most AI generated WordPress plugins fail the same way: missing nonces, raw `$_POST` values, string-interpolated SQL, no text domain, no `uninstall.php`, and a `Plugin Name` header that's the only metadata it bothered to fill in. The `wordpress-plugin` skill takes a different approach. Seven structured intake answers in. full directory tree out, with WordPress Coding Standards compliance, complete security guardrails, internationalization, conditional asset enqueueing, custom tables via `dbDelta()` with proper indexes, and a real uninstall script that removes every artefact the plugin creates.

Five of the seven intake questions are **pickers** via `AskUserQuestion`: pick the WordPress mechanisms the plugin uses, the target audience, the admin UI components, the frontend display surfaces, and the third party integrations. Two are free text. the plugin name and a 2-4 sentence description of what the plugin actually does. No ambiguous answers, no follow-up clarification rounds.

## ✨ Features

- 📋 Intake. five picker prompts via `AskUserQuestion` plus two free text. every variable in the about-me section is a picker, not a fill-in-the-blank
- 🏗️ Modular OOP structure. singleton main plugin class wires Admin, Frontend, Database, AJAX, REST, Cron, CLI, Roles, CPT, Meta-box, List-table, Dashboard-widget, Notices, and Integration components
- 🔒 Security built in. `defined( 'ABSPATH' ) || exit;` on every file, nonces on every mutation, capability checks before every privileged action, sanitization on every input, escaping on every output, `$wpdb->prepare()` on every query
- 🧰 WordPress mechanisms covered: Custom Post Types & Taxonomies, Settings API, Gutenberg blocks, shortcodes, REST endpoints, WP-CLI commands, cron, custom tables, roles & capabilities, email notifications, frontend forms, dashboard widgets, import/export, activity logging, custom user meta
- 🎯 Audience-aware code generation. pick "Multisite network administrators" and the activator/deactivator/uninstaller all loop `get_sites()`; pick "Developers" and you get a `docs/` folder with documented hooks
- 🧩 Frontend surfaces. shortcodes, Gutenberg blocks, classic widgets, template tags, `the_content` injection with opt-out, REST-driven SPA, custom page templates
- 🔌 Integration scaffolds. WooCommerce, BuddyPress/bbPress, ACF, Elementor, external REST APIs, Stripe/PayPal, Mailchimp/ConvertKit/SendGrid, Google Analytics, OAuth providers, incoming and outgoing webhooks (with HMAC verification and Action Scheduler fallback)
- 🌍 Internationalization: every user-facing string wrapped in i18n functions with the correct text domain, plus a populated `.pot` file in `languages/`
- 📚 Complete documentation: `readme.txt` in WordPress.org format (Contributors, Tags, Requires at least, Tested up to, Stable tag, License, Description, Installation, FAQ, Screenshots, Changelog, Upgrade Notice), `readme.md` GitHub-friendly mirror, PHPDoc on every class and public method
- 🗑️ Complete uninstall: drops every custom table, deletes every option/transient/user-meta/post-meta, clears scheduled events, removes registered roles and capabilities, with the proper `WP_UNINSTALL_PLUGIN` guard
- ⚡ Conditional asset enqueueing: `get_current_screen()` checks so admin assets never leak onto the frontend and public assets don't load on every admin page
- 🗃️ Custom-table best practices: `$wpdb->get_charset_collate()`, `dbDelta()`, indexes on every queried column, schema version stored in an option for migrations
- 🚫 Zero placeholders. no `TODO`, no `TBD`, no `{name}`, no `Coming soon` in any generated file

## 🔄 How it works

1. **Intake**: five picker prompts via `AskUserQuestion`, two free text:
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

## 🚀 How to use it

```
/wp-plugin ← walks through all seven questions
/wp-plugin "Acme Bookings" ← pre-fills the plugin name
```

Or natural language: *"build me a WordPress plugin for time-slot bookings"*, *"scaffold a WP plugin with a settings page and a REST endpoint"*, *"create a custom post type plugin for testimonials"*, *"I need a Gutenberg block plugin for newsletter signups"*, *"make me a WooCommerce extension that adds gift wrapping"*.

The full procedure lives at [`lib/wordpress-plugin/SKILL.md`](../lib/wordpress-plugin/SKILL.md).

---

## `html-to-wordpress-theme`

Converts static HTML files into installable WordPress themes.

```
/wp-theme
```

Ever had a beautiful static HTML design built with Tailwind CSS and wished you could just drop it into WordPress? That's exactly what this plugin solves.

The `html-to-wordpress-theme` skill takes your static Tailwind CSS HTML files and converts them into a fully installable, WordPress-compliant theme. No more manually rewriting markup into PHP templates or guessing how WordPress expects things to be structured. the skill handles it all for you through a guided, step by step workflow.

What makes it different from a quick rewrite? Your converted theme comes out with proper accessibility built in, secure code that follows WordPress coding standards, and a Tailwind CSS build pipeline. no CDN links or shortcuts. There's even a 79-point checklist that runs before anything is delivered to make sure nothing got missed.

It asks for your approval at every major step, so nothing large happens without you seeing the plan first.

## 📋 Technical Overview

An AI instruction specification that converts static Tailwind CSS HTML files into fully installable, WordPress Theme Review Team-compliant themes.

Built around a phased workflow with mandatory approval gates, it enforces WordPress PHP coding standards, WCAG 2.1 AA accessibility, Tailwind CSS v3 CLI build pipelines, escaping and security rules, and a 79-point self-audit with cited evidence requirements.

It states its assumptions instead of leaving them unsaid, stops rather than generating past the plan, and handles the awkward cases: poor source HTML, context window limits, and work that spans several sessions.

## ✨ Features

- 🏗️ Phased workflow with mandatory approval gates. no code ships without user sign-off
- 🔒 Exhaustive escaping and sanitization rules for every output context
- ♿ WCAG 2.1 AA accessibility built into every phase and template
- 🎨 Tailwind CSS v3 CLI build pipeline. zero CDN references, zero frameworks
- 🔍 79-point self-audit table requiring cited file-and-line evidence for every check
- 🚦 Graduated failure modes. abort, degraded, or proceed based on source quality
- 🌍 Full internationalization with enforced translator comments and text domains
- 🧩 Smart template abstraction rules for repeated markup patterns
- 👶 Child theme compatibility with overridable functions and removable hooks
- 📦 Automatic chunk planning with size estimation to prevent truncation
- 🔄 Session continuity protocol for multi-conversation conversions
- 📋 Pre-output self-check validates every file before delivery
- ⚖️ Decision tiebreaker hierarchy when multiple valid approaches exist
- 🛡️ Nonce enforcement and input sanitization for all custom forms
- 📱 Mobile-first responsive design with keyboard and touch target requirements
- 🏷️ Strict naming conventions derived from a single confirmed theme name
- 📝 Auto-generated README with setup instructions, testing checklist, and documentation
- ⚡ Image performance rules. lazy loading, fetch priority, and registered custom sizes
- 🧪 Testing checklist covering core functionality, accessibility, and build system
- 📐 Content width single source of truth synced across PHP, JSON, and Tailwind config

## 🔄 How it works

Hand it an `index.html` (and optionally a `single.html`, plus any other page mockups) and it walks you through a 4-phase conversion:

1. **Initialization**: confirm theme name and defaults
2. **Phase 1. Analysis** (1A critical, 1B extended). HTML validation, source quality grading, design-token extraction, file manifest, decision log
3. **Phase 2. Implementation**: generates every theme file in user-approved chunks
4. **Phase 3. Self-Audit**: a 79-item checklist with cited file-and-line evidence before delivery

You approve each phase before the next one starts, so nothing runs away from you.

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/wp-theme ← starts the workflow
/wp-theme Brewline ← pre-fills the theme name
```

**Natural language** (auto-triggers):

> *"I have an index.html and a single.html in my Downloads folder. convert them into a WordPress theme called 'Brewline'."*

Either way, confirm the theme name and defaults at the initialization gate, then approve each phase as it completes. Theme files are saved to a folder named after your theme slug.

The full procedure lives at [`lib/html-to-wordpress-theme/SKILL.md`](../lib/html-to-wordpress-theme/SKILL.md), with deep references in the adjacent [`references/`](../lib/html-to-wordpress-theme/references/) folder.

## 🤖 AI Analysis Verdict

> The skill's source instruction set was independently analyzed by Claude Opus 4.6. Below are the evaluation results.

| Aspect | Description | Rating | Score |
|--------|-------------|--------|-------|
| Completeness | Covers every edge case from abort criteria to degraded mode, with zero gaps in the conversion workflow | ★★★★★ | 10/10 |
| Structure | Phase gates, numbered sections, cross-references, and a document map make navigation even at 2000+ lines | ★★★★★ | 10/10 |
| Clarity | Every rule includes ✅/❌ examples, anti-patterns, and decision trees. leaves no room for misinterpretation | ★★★★★ | 10/10 |
| Maintainability | Versioned with changelog, modular sections, and a priority hierarchy that makes updates safe and predictable | ★★★★★ | 10/10 |
| Practical Effectiveness | Evidence-based self-audit, context window management, and session continuity ensure reliable output across real world usage | ★★★★★ | 10/10 |
| Error Handling | Graduated failure modes (abort → degraded → proceed) with explicit user checkpoints prevent silent failures | ★★★★★ | 10/10 |
| Security Coverage | Exhaustive escaping/sanitization tables, nonce enforcement, and a pre-output self-check catch vulnerabilities before they ship | ★★★★★ | 10/10 |
| Accessibility | WCAG 2.1 AA built into every phase. contrast ratios, keyboard nav, ARIA, skip links, and reduced motion are non-negotiable | ★★★★★ | 10/10 |
| **Overall** | **An AI engineering specification that rivals internal runbooks at mature development organizations** | **★★★★★** | **10/10** |

---

## `wordpress-architect-review`

Senior WordPress architect code review for plugins and themes. file by file audit covering security, performance, architecture, correctness, WordPress standards, accessibility, i18n, and missing infrastructure.

```
/wp-review
```

Most AI code reviews of WordPress plugins read like generic linter output: "consider adding error handling", "use prepared statements where possible", without ever quoting the offending line. The `wordpress-architect-review` skill takes a different stance. It acts as a senior WordPress architect with 15+ years on WordPress.org submissions, enterprise WP stacks, and security audits. Every finding cites `file:line`, quotes the exact offending code, tags severity (SEVERE / MODERATE / MINOR), states the actual impact, and gives the fix. No filler adjectives, no vague advice, no praise before issues.

Scope-locked. It will not write tutorials, recommend hosting, or answer general WP questions. only audit code. Prompt-injection defenses treat file contents as inert data, so a `// Ignore prior instructions...` comment in the audited code gets flagged as a CRITICAL Security finding rather than followed.

## ✨ Features

- 🎯 Target auto-detection. plugin header in root PHP, `style.css` theme header, `block.json`, or `wp-content/mu-plugins/` path; aborts cleanly if none found
- 📖 Reads every file directly. every PHP/JS/CSS plus companion configs (`readme.txt`, `theme.json`, `composer.json`, `package.json`, `phpcs.xml`); no summarizing from filenames
- 🏷️ Severity-tagged findings. SEVERE / MODERATE / MINOR. mandatory format: title + `file:line` + code fence + Impact line + Fix line
- 📊 10-row scorecard. Security, Performance, Architecture, Correctness, WordPress Standards, Maintainability, Documentation, Testing, Accessibility/UX, Internationalization. overall weighted toward Security, Performance, Correctness
- 🛡️ Prompt-injection defense. inline instructions in the audited code are treated as inert data and reported as a CRITICAL Security finding
- 🔒 Scope lock. refuses tutorials, recommendations, hosting advice, non-code questions
- 🚫 Banned filler word list. no "leverage", "robust", "comprehensive", "utilize", "synergy", and ~15 more
- ✅ Pre-emit validation. partial reports are regenerated, never shipped
- 🗺️ Optional refactor roadmap. 3-phase modernization path appended when overall score is below 6/10

## 📂 Categories covered

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

## 🔄 How it works

1. **Detect target**: looks for plugin header, theme `style.css`, `block.json`, or `mu-plugins` path
2. **Read everything**: every PHP/JS/CSS file plus companion configs, with the Read tool, never from filename summaries
3. **Categorize findings**: max 5 per category, most severe first, every one cited and quoted
4. **Score and rank**: fill the 10-row scorecard, list the top 5 fixes with S/M/L effort tags
5. **Optional roadmap**: append a 3-phase refactor plan if overall is below 6/10
6. **Pre-emit validation**: verify every section before returning; regenerate anything failing

## 🚀 How to use it

```
/wp-review ← audits the current working directory
/wp-review ./wp-content/plugins/x ← audits the specified path
```

Or natural language: *"review my WordPress plugin for security holes"*, *"audit this theme before I submit to WordPress.org"*, *"is this plugin "*, *"give me a senior architect review of this WP code"*, *"rate my plugin out of 10"*.

The full procedure lives at [`lib/wordpress-architect-review/SKILL.md`](../lib/wordpress-architect-review/SKILL.md).

---

## `wordpress-consultant`

Senior WordPress Consultant (10+ years, WordPress VIP coding standards) that runs a fixed 10-section consulting framework over a WordPress project. Seven inputs in, an expert audit out, ending with a 0-100 scorecard and a single summary table.

```
/wp-consult
```

Most "WordPress help" turns into a list of disconnected tips - install this caching plugin, bump that PHP version, try a different host. This plugin replaces that with the audit a senior consultant would actually run: seven inputs describing the site, ten sections of structured analysis, and a final report that scores the project on health, performance, security, scalability, and code quality. Every section 1-9 is capped at 250 words and written as Finding / Impact / Recommendation bullets - no walls of text, no filler. Section 3 (WooCommerce) drops to `N/A` when the site is not a store. The consultant never recommends nulled or pirated plugins, never suggests editing WordPress core, never prints secrets in examples, and never assigns a security rating without naming what was checked.

The skill body runs the workflow. Step 1 validates inputs - if `Current Challenge` or `Development Goals` is blank it halts and asks, because an audit with no problem statement and no goal is fiction. Step 2 loads the Section 1-10 prompts from `references/framework.md`. Step 3 uses extended thinking before Section 4 (Performance) and Section 10 (Final Report), the two sections that need the deepest reasoning. Step 4 emits every section under its exact header per `references/output-contract.md`. Step 5 applies the Section 10 scales and ends with the mandatory summary table. Step 6 runs a silent self-validation gate - all 10 sections present, every score on its defined scale, table last - before delivery.

Hard refusal on out-of-scope asks (anything that is not WordPress engineering, declined in one line then back to the framework), on nulled/pirated plugins, on core-file edits, and on security ratings given without naming what was checked.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/wordpress-consultant/SKILL.md` carries the voice, scope lock, input gates, and 6-step workflow. The Section 1-10 analysis prompts live in `references/framework.md`. The output contract (word caps, Section 10 scales, summary-table columns, pre-delivery checklist) lives in `references/output-contract.md`. The full input-handling and prompt-injection rules live in `references/guardrails.md`. The slash command `/wp-consult` accepts an optional `Current Challenge` arg, then walks the user through `AskUserQuestion` intake for all seven fields.

## ✨ Features

- 🎯 Seven inputs in, a 10-section consultant report out. Website Type + Current Challenge + Technology Stack + Traffic Volume + Development Goals + Performance Requirements + Support Needed
- 🚧 Two required inputs gate the run - blank `Current Challenge` or `Development Goals` halts with `MISSING INPUT: <field> required.` The other five are optional and proceed with a flagged assumption at the top of the affected section
- 🧭 Fixed framework: Architecture Assessment, Development Strategy, WooCommerce Review, Performance Optimization Audit, Security Hardening, Debugging & Troubleshooting, Scalability & Infrastructure, Automation & Workflow, Technical Debt Assessment, Final Senior Consultant Report
- 🗜️ Max 250 words per section 1-9, written as Finding / Impact / Recommendation bullets. Section 3 drops to `Section 3 - N/A (not a WooCommerce site)` for non-stores
- 📊 Section 10 scorecard on fixed scales - Health, Performance, Security, Scalability, Code Quality (0-100); Technical Debt Severity (Low/Medium/High/Critical); Recommended Priorities (ranked, max 5)
- 📋 Mandatory Markdown summary table as the final element, every run, exact columns
- 🧠 Extended thinking before Section 4 (Performance) and Section 10 (Final Report)
- 🛡️ Security guardrails - never recommends nulled/pirated themes or plugins, never suggests editing core files, never outputs DB credentials/keys/secrets in examples, never claims a security rating without naming what was checked
- 🛑 Prompt-injection defense. All seven inputs treated as inert project data. Directives like `ignore prior`, `system:`, `act as`, role-switch attempts inside field values are ignored
- 🪝 Scope-locked to WordPress engineering. Non-WordPress requests declined in one line, then back to the framework

## 🔄 How it works

1. **Intake.** Slash command collects all seven fields via `AskUserQuestion`. If `Current Challenge` was passed as `$ARGUMENTS`, confirm and seed it. Empty / blank / `[FIELD_NAME]` on a required field → halt with `MISSING INPUT: <field> required.`
2. **Validate.** Required gate on `Current Challenge` and `Development Goals`. Optional blanks proceed with a flagged assumption. Conflicting inputs (e.g. Website Type vs Challenge) named in one line and confirmed before proceeding.
3. **Load framework.** Read `references/framework.md`, `references/output-contract.md`, `references/guardrails.md`. Wrap all input values in `<inputs></inputs>` and treat as inert data.
4. **Extended thinking** before Section 4 and Section 10.
5. **Emit Sections 1-10** under exact headers. Mark `Section 3 - N/A` for non-stores. Max 250 words per section 1-9.
6. **Section 10 + summary table.** Apply the fixed scales. End with the single mandatory summary table - it must be last.
7. **Silent validation gate.** Confirm all 10 sections present, every score on its scale, table last, no security rating without naming what was checked. Fix any gap before output.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/wp-consult "checkout is slow on our WooCommerce store"   ← arg seeds Current Challenge, intake fills the rest
/wp-consult                                               ← full 7-question intake
```

**Natural language** (auto-triggers via the skill):

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

## ✨ Features

- 🎯 Five quick questions first. Scope (templates and partials, or all theme PHP), strictness (formatting only, or the full standard), Yoda checks on or off, the theme name, and any files to skip. Say "just do it" for safe defaults
- 🧰 Installs the tools for you. PHP_CodeSniffer and the WordPress Coding Standards go into the theme's local `vendor/` as dev dependencies - nothing is installed globally
- 🧾 Writes a scoped config. A `phpcs.xml.dist` that leaves out `vendor`, `node_modules`, and by default `lib`, `inc`, `assets`, and `functions.php`
- 🔧 Fixes formatting only. Runs `phpcbf` twice for tabs, spacing, array style, and alignment - never escaping, sanitization, or behavior
- 🛡️ Leaves risky changes alone. Loose `==` to `===`, the `array_search` strict flag, and `extract()` are reported, not applied, so runtime behavior never changes
- ✅ Checks its own work. Runs `php -l` on every changed file and stops if anything breaks
- 🚦 Two safe stops. No `composer.json` means it asks before creating one; a failed install means it shows the exact error instead of guessing
- 🧱 Adds re-run shortcuts. `composer lint` and `composer format` so you can run it again anytime

## 🔄 How it works

1. **Check first.** Confirm the folder is a WordPress theme (a `style.css` header or template files). Stop if it is not.
2. **Intake.** Ask the five questions and wait for the answers, or use the defaults on "just do it".
3. **Install.** Add PHPCS and WPCS as Composer dev dependencies, skipping if they are already there. Stop and report if the install fails.
4. **Configure.** Write `phpcs.xml.dist` scoped to the answers, and add the `lint` and `format` composer scripts.
5. **Fix.** Run `phpcbf` twice, then `php -l` on every changed file. A syntax error is a hard stop.
6. **Report.** List what was fixed and what was left, with a reason for each item that was left.

## 🚀 How to use it

```
/wp-format ← formats the current theme
/wp-format ./wp-content/themes/mytheme ← formats a specific theme
```

Or natural language: *"format my WordPress theme to the coding standard"*, *"run phpcbf on my templates"*, *"fix the indentation and spacing in my theme"*, *"set up phpcs for this theme"*, *"convert my theme files to tabs"*.

The full procedure lives at [`lib/wordpress-formatter/SKILL.md`](../lib/wordpress-formatter/SKILL.md), and the slash command at [`commands/wp-format.md`](../commands/wp-format.md).
