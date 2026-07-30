---
description: Set up WordPress Coding Standards formatting for a theme and apply the auto-fixable formatting, without changing how any page renders
argument-hint: [path to theme]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-formatter/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `wordpress-formatter` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Run the WordPress formatting workflow using the `wordpress-formatter` procedure.

First confirm the target is a WordPress theme (a `style.css` theme header, or
template files like `index.php` / `functions.php`). If it is not, say so and
stop - do not scaffold tooling into a non-theme repo.

Then ask the five intake questions from the procedure file (scope, ruleset strictness,
Yoda reorders, theme name, files to exclude) and wait for the answers. If the
user says "just do it," use the defaults: templates-and-partials scope,
WordPress-Core ruleset, Yoda reported but not applied.

Install PHP_CodeSniffer and the WordPress Coding Standards as Composer dev
dependencies (skip if already present), write the scoped `phpcs.xml.dist`, run
`phpcbf` twice, and check every touched file with `php -l`. Report remaining
issues using the procedure file's triage table - leave the behavior-risky sniffs
reported but unapplied. Finish with the procedure file's report template.

If a path was provided in the slash command arguments, format that path.
Otherwise use the current working directory.

If `composer.json` is missing, ask whether to run `composer init` or abort - do
not create one silently. If `composer require` fails, stop and report the exact
error and failing command.

Target path (if provided): $ARGUMENTS
