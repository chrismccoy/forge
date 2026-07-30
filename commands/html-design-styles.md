---
description: Apply a named design style (bento, brutalist, vaporwave, kawaii, glassmorphism…) to a page or component
argument-hint: [style] [optional project description]
disable-model-invocation: true
---

> **Load first.** Read `${CLAUDE_PLUGIN_ROOT}/lib/html-design-styles/SKILL.md` in full before
> anything else - intake, tool calls, or output. That file is the authoritative
> procedure for this command; every mention of "the `html-design-styles` procedure" below
> refers to it. It is not auto-loaded, so this read is mandatory.

I want to apply a named design style to a frontend interface using the `html-design-styles` procedure. The catalog has 53 styles, each with a complete spec (color palette, typography stack, component patterns, signature visual mechanics).

User input: $ARGUMENTS

If the input names a recognized style from the catalog, identify the style and proceed to the Initialization Gate (defined in the `html-design-styles` procedure) to confirm project context (full page vs. component, what's being built, any existing markup to restyle). If no style was named, present the catalog picker. If the input is ambiguous - a category word like "brutalist"/"dark"/"retro" that matches multiple catalog entries, or anything generic like "modern"/"clean"/"minimal" - present a sub-picker of the matching styles.

**Picker UX preference:** when asking the user to choose among multiple styles (whether top-level catalog or category sub-picker), **prefer the `AskUserQuestion` tool over plain-text questions**. It gives the user keyboard-navigable selection with one-line descriptions per option instead of forcing them to retype a style name. Pass each candidate style as a suggested option (label = display name, description = one-liner from the catalog table) with a free-text fallback. Fall back to plain text only if `AskUserQuestion` isn't available.

Once style and project context are confirmed, load `${CLAUDE_PLUGIN_ROOT}/lib/html-design-styles/references/common.md` (cross-cutting patterns) and `${CLAUDE_PLUGIN_ROOT}/lib/html-design-styles/references/styles/<slug>.md` (the chosen style's complete spec), then generate a single self-contained HTML file applying the style faithfully - exact color values, font stacks, and shadow recipes, no "similar" substitutions.
