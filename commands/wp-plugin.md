---
description: Generate a complete, production-ready WordPress plugin from scratch with seven multiple-choice and free-text intake answers
argument-hint: [plugin name]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/wordpress-plugin/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `wordpress-plugin` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

Generate a complete, enterprise-grade WordPress plugin using the `wordpress-plugin` procedure. Run the seven-question intake per the procedure file's Intake section: two free-text (plugin name, feature detail) asked as plain prompts, and five multiple-choice (functionality, target users, admin interface, frontend display, third-party integrations). Each MC option list exceeds the `AskUserQuestion` 4-option cap, so present them as plain-text "select all that apply" checklists (target users is single-select), each with an `Other (specify)` escape. Then produce the full plugin directory with main file, modular OOP classes, security guards, i18n, readme.txt, and uninstall.php.

For an existing plugin (adding a feature, settings page, endpoint, or fix), this is the wrong command - defer to wp-builder-pro. This command scaffolds a brand-new plugin only.

If a plugin name was provided in the slash command arguments, pre-fill it for Q1. Otherwise ask for all seven inputs in order.

Plugin name (if provided): $ARGUMENTS
