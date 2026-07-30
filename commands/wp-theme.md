---
description: Convert HTML files into a production-quality, installable WordPress theme
argument-hint: [theme name]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/html-to-wordpress-theme/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `html-to-wordpress-theme` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

I want to convert static HTML files into a production-quality, installable WordPress theme using the `html-to-wordpress-theme` procedure. Apply the full phased workflow with mandatory approval gates: Initialization → Phase 1A (critical analysis) → Phase 1B (extended analysis) → chunked implementation → Phase 3 self-audit.

If a theme name was provided in the slash command arguments, use it. Otherwise ask for it at the Initialization Gate.

Theme name (if provided): $ARGUMENTS

Begin with the Initialization Gate from the procedure file. Confirm the theme name and naming conventions, then present the **Source HTML → WordPress Template Mapping** table so the user knows which named files (`index.html`, `single.html`, `page.html`, `archive.html`, `category.html`, `tag.html`, `search.html`, `404.html`, `comments.html`, plus any custom page templates like `landing.html`) drive which WordPress templates. Collect whatever they have in one shot.

Then run the proactive questions block in full - specifically don't skip the **Optional WordPress features** prompt (Customizer settings, transient caching, reading time, related posts, Schema.org JSON-LD, social share, author bio, last-updated date, AJAX comments/pagination, custom shortcodes, plugin integrations). The user opts into these explicitly; everything they don't mention defaults to "no" and is omitted from the theme. Each opted-in feature gets a row in ⑨ Decision Log, an entry in ⑪ File Manifest, and a self-audit row in Phase 3.

Then proceed to Phase 1A.
