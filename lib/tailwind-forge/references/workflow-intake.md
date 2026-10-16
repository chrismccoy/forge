# Tailwind CSS Intake Workflow

**Contents:** When to Run · Detect Before Asking · Question 1 · Question 2 · Routing · Something Else · Fallback Without a Question Tool

Ask two multiple-choice questions to find the task, then route to the matching workflow, reference, or script.

## When to Run

Run the intake only when the request does not name a task:

- The skill is invoked with no arguments (`/tailwind-forge`).
- The request is vague: "help with Tailwind", "clean up my styles", "look at my CSS".

Skip it when the request already names a task ("make this responsive", "classes not applying"). Go straight to the routing table in SKILL.md.

## Detect Before Asking

Check these first so the options fit the project. This takes a few file reads, not a full audit.

| Check | How | Effect on options |
|-------|-----|-------------------|
| Tailwind installed | `tailwindcss` in `package.json` | Not installed: offer "Fresh install"; drop "Migration" and "Audit" |
| Major and minor version | `tailwindcss` version, `@tailwind` vs `@import "tailwindcss"` | v4: drop "Migration". v3: put "Migration" first |
| Dark mode | `dark:` classes, `@custom-variant dark`, or color overrides under `.dark` / `[data-theme]` | None: drop "Dark mode coverage" from the audit; keep "Dark mode" as a build option |
| shadcn/ui | `components.json` or a `components/ui/` folder | Absent: drop "shadcn theming" |
| Build output | `dist/`, `build/`, `.next/`, `.output/` | Absent: label "CSS size" as "needs a build first" |

Mention the detected version in the first question, for example "Tailwind v4.1 detected."

## Question 1

Header: `Task`. Question: "What do you want to do?" Show up to four options. The question tool adds an "Other" free-text option automatically; it is the "Something else" path. Do not add a separate "Other" or "Something else" option, because the tool limits each question to four options.

| Option | Description |
|--------|-------------|
| Set up or upgrade | Install Tailwind, migrate v3 to v4, or add a plugin |
| Build or style something | Component, responsive layout, dark mode, or shadcn theming |
| Fix something | Classes not applying, build errors, or styles wrong after an upgrade |
| Audit the project | Accessibility, dark mode coverage, class usage, or CSS size |

## Question 2

Ask the follow-up that matches the first answer. Remove options that detection ruled out. Skip question 2 when only one option is left; for example, "Set up or upgrade" in a v3 project with Tailwind installed means migration.

| Question 1 answer | Question 2 options |
|-------------------|--------------------|
| Set up or upgrade | Fresh install · Migrate v3 to v4 · Add a plugin |
| Build or style something | Component · Responsive layout · Dark mode · shadcn theming |
| Fix something | Classes not applying · Build or setup error · Looks wrong after upgrade |
| Audit the project | Accessibility · Dark mode coverage · Class usage · CSS size (multi-select) |

Allow multi-select only for the audit, since several scripts can run in one pass. "Other" stays available on question 2 as well, for a task inside the chosen area that the options miss.

After question 2, ask for the target in plain text if it is still unknown: which component, page, or error message.

## Routing

| Answer | Go to |
|--------|-------|
| Fresh install | workflow-setup.md |
| Migrate v3 to v4 | v4-fundamentals.md (v3 to v4 Reference), then debugging.md (v4 Behavior Changes) |
| Add a plugin | plugins.md (Official Plugins) |
| Component | workflow-component.md |
| Responsive layout | workflow-responsive.md |
| Dark mode | dark-mode.md (Choosing a Strategy) |
| shadcn theming | design-systems.md (shadcn/ui Projects) |
| Classes not applying, Build or setup error | workflow-debug.md |
| Looks wrong after upgrade | debugging.md (v4 Behavior Changes) |
| Accessibility | `scripts/check-accessibility.sh`, then accessibility.md for fixes |
| Dark mode coverage | `scripts/check-dark-mode.sh` |
| Class usage | `scripts/check-classes.sh` |
| CSS size | `scripts/analyze-bundle.sh` (after a build), then performance.md |
| Other (either question) | Something Else, below |

For an audit, run the selected scripts from the project root and summarize the findings in a short list ordered by severity. Do not fix anything until the user picks what to fix.

## Something Else

When the user answers "Other", treat the free text as the request:

1. Match it against the SKILL.md routing table and the workflow table. If a reference covers it, route there and continue as usual.
2. If it spans several topics, load each matching reference.
3. If no reference covers it (for example Tailwind in email templates, a CMS theme, a component library not listed, or a newly released feature), say so in one line. Then:
   - Check current Tailwind docs (docs MCP server or WebFetch on tailwindcss.com) before writing version-specific code.
   - Still apply the SKILL.md Workflow steps 1, 2, 4, and 5 and the Anti-Patterns.
   - Use the closest reference for shared rules, for example components.md for a new component type or frameworks.md for an unlisted framework.
4. If the request is not about Tailwind at all (plain CSS, CSS-in-JS, a different framework), say the skill does not cover it and continue without it.

## Fallback Without a Question Tool

When no multiple-choice question tool is available, show the same choices as a numbered list in one message and ask for a number or a description:

```text
Tailwind v4.1 detected. What do you want to do?
1. Set up or upgrade (install, migrate, add a plugin)
2. Build or style something (component, responsive layout, dark mode, shadcn theming)
3. Fix something (classes not applying, build errors, wrong after upgrade)
4. Audit the project (accessibility, dark mode coverage, class usage, CSS size)
5. Something else (describe it)
```

Ask question 2 the same way after the answer, ending with "Something else (describe it)". Treat a number for "Something else", or any free-text reply, as described in Something Else.
