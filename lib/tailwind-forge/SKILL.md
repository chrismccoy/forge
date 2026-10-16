# Tailwind Forge - Tailwind CSS v4 project work

Single entry point for Tailwind CSS work. `<skill-dir>` is `${CLAUDE_PLUGIN_ROOT}/lib/tailwind-forge`, the folder that contains this procedure file; every relative `references/...` or `scripts/...` path below is inside it. Load only the reference files that match the task.

If the project does not use Tailwind (no `tailwindcss` dependency, no `@import "tailwindcss"` or `@tailwind` directive), say so in one line and ask whether to set it up (`references/workflow-setup.md`) or stop.

## Workflow

0. If the request names no task (bare invocation, or "help with Tailwind"), run the two-question intake in `references/workflow-intake.md`. Skip it when the task is already clear.
1. Read the project first. Find the CSS entry file (the file with `@import "tailwindcss"`), existing `@theme` tokens, and existing components. Match the project's radius, palette, spacing, and component patterns.
2. Identify the version from `tailwindcss` in `package.json`, including the minor version. `@tailwind` directives mean v3; `@import "tailwindcss";` means v4 (which can still load a JS config through `@config`). Never mix v3 and v4 syntax. For a v3 project not migrating, or a feature tagged v4.1+ or newer, see `references/v4-fundamentals.md` (v3 to v4 Reference).
3. Open the matching reference file. Use its **Contents** line to jump to the relevant section.
4. Write the smallest set of utilities that meets the requirement. Add `dark:`, responsive, hover, and animation variants only where state or layout really changes.
5. Verify. Confirm dynamic classes appear as complete strings in source, and check dark mode and breakpoints if the project uses them.

## Routing Table

| Task | Reference file |
|------|----------------|
| Install, CSS-first config, `@theme`, `@utility`, `@custom-variant`, layers, v3 to v4 table, minor-version features | `references/v4-fundamentals.md` |
| Theme namespaces, overriding defaults, `@theme inline` / `static` | `references/v4-theme-advanced.md` |
| Custom utilities: naming, `--value()`, `--modifier()` | `references/v4-custom-utilities.md` |
| Breakpoints, container queries, fluid sizing, pointer media, touch targets, safe areas, images | `references/responsive.md` |
| Dark mode strategies, FOUC-free toggle, next-themes, token swapping | `references/dark-mode.md` |
| Grid, Flexbox, subgrid, sticky, z-index, scroll snap, print | `references/layouts.md` |
| `cn()`, Button, Card, Input, CVA, `data-*` state, group/peer, Headless UI, Radix | `references/components.md` |
| Design tokens, multi-theme, shadcn/ui theming, monorepo tokens | `references/design-systems.md` |
| Animations, transitions, enter/leave, scroll-driven, view transitions, reduced motion | `references/animations.md` |
| WCAG 2.2: focus, forced colors, contrast, forms, ARIA widgets, target size | `references/accessibility.md` |
| Typography and forms plugins, JS plugin API, community plugins | `references/plugins.md` |
| Content detection, safelisting, output size, runtime performance | `references/performance.md` |
| Framework setup (Vite, Next.js, Vue, Nuxt, SvelteKit, Astro, React Router), `@reference` | `references/frameworks.md` |
| React: server/client components, refs as props, state styling | `references/frameworks-react.md` |
| Classes not applying, `@source`, v3 to v4 errors, cascade layers, v4 behavior changes, error messages | `references/debugging.md` |

For tasks that span topics, load more than one file. For example, an accessible dark-mode toggle needs `references/dark-mode.md` and `references/accessibility.md`.

### Step-by-Step Workflows

For end-to-end requests, follow the matching workflow file (questions, starter code, checklist, expected output).

| Request | Workflow file |
|---------|---------------|
| "Set up Tailwind in my project", install and configure for a framework | `references/workflow-setup.md` |
| "Create a button / card / input / modal component" | `references/workflow-component.md` |
| "Make this layout responsive", grids, nav, hero, sidebar, show/hide | `references/workflow-responsive.md` |
| "Styles aren't applying", build errors, broken dark mode or plugins | `references/workflow-debug.md` |

Workflow starter code is generic. Adapt it to the project's tokens and apply the Anti-Patterns below.

## v4 Essentials

### Entry Point and Install

```css
/* app.css */
@import "tailwindcss";
```

- Vite: `tailwindcss @tailwindcss/vite`. PostCSS: `@tailwindcss/postcss` (`tailwindcss` is no longer a PostCSS plugin). CLI: `npx @tailwindcss/cli -i app.css -o out.css`.
- Content detection is automatic. Add `@source "../path";` only for files outside the scan, such as a monorepo package.

### CSS-First Configuration

```css
@import "tailwindcss";

@theme {
  --color-brand-500: oklch(0.62 0.19 255);
  --font-display: "Inter", sans-serif;
  --breakpoint-3xl: 120rem;
  --animate-fade-in: fade-in 0.3s ease-out;

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
}

@utility content-auto {
  content-visibility: auto;
}

/* Only for class-based dark mode; the media strategy needs no variant */
@custom-variant dark (&:where(.dark, .dark *));

@plugin "@tailwindcss/typography";
```

- Each `@theme` variable namespace creates utilities: `--color-*` gives `bg-*`, `text-*`, and similar; `--breakpoint-*` gives variants; `--animate-*` gives `animate-*`.
- Every theme value is a native CSS variable. Use `var(--color-brand-500)` in CSS and JS instead of `theme()`. Exception: `theme(--breakpoint-xl)` is still valid inside `@media`, where variables are not allowed.
- Tokens whose value is `var(--x)` go in `@theme inline { ... }`, so utilities inline the value. Switch themes by overriding the raw `--x` under `.dark` or `[data-theme]`. Never override an inline theme variable (`--color-*`) under a selector; utilities ignore it. To override `--color-*` directly, define it in plain `@theme`. shadcn/ui uses this pattern (see `references/design-systems.md`).
- Use `@reference "../app.css";` at the top of Vue, Svelte, or CSS-module `<style>` blocks that use `@apply`.

### v3 to v4 Traps

These change output silently, with no error:

| v3 | v4 |
|----|----|
| `@tailwind base; ...` | `@import "tailwindcss";` |
| `shadow`, `rounded`, `blur` | One step down: `shadow-sm`, `rounded-sm`, `blur-sm` (old `-sm` becomes `-xs`) |
| `ring` (3px, blue) | `ring-3` (`ring` is now 1px `currentColor`) |
| Border default `gray-200` | `currentColor`; set a color explicitly |
| `!font-bold` | `font-bold!` |
| `outline-none` | `outline-hidden` (`outline-none` now removes focus in forced-colors mode) |

Full table and `npx @tailwindcss/upgrade`: `references/v4-fundamentals.md` (v3 to v4 Reference).

## Key Gotchas

- Tailwind scans source as plain text. A class built at runtime, such as `` `bg-${color}-500` ``, is never generated. Map values to complete class strings in an object instead.
- `@apply` inside framework `<style>` blocks fails without `@reference`.
- `prose` from the typography plugin overrides child utilities. Use `not-prose` on embedded components.
- Fixed bottom bars need `pb-[env(safe-area-inset-bottom)]` on notched devices, which requires `viewport-fit=cover` in the viewport meta tag.
- Pair `hover:` with `focus-visible:`. Hover-only interactions fail on touch and keyboard.

## Anti-Patterns to Avoid

Generated Tailwind tends to fall into these traps. Check every response against them.

1. **Ignoring existing context (the most common mistake).** Read existing components and tokens before writing new ones. Match the project's `rounded-*`, palette, spacing scale, and component patterns. Do not rebuild a component that already exists.
2. **Over-decoration.** Do not add gradients, large shadows, hover animations, and transitions by default. Most real UIs are flat. Do not round everything to `rounded-xl` or `rounded-2xl`. Do not animate static elements. Do not add gradient-text hero sections unless asked.
3. **Class bloat.** Do not add `dark:` variants when the project has no dark mode. Do not add responsive variants that change nothing, such as `text-sm md:text-sm`. Do not add hover, disabled, or loading states unless the element needs them.
4. **Over-engineering.** Do not build CVA or `clsx` variant systems for one-off components. Do not add wrappers, helper functions, or extension points that were not requested.
5. **Token violations.** Do not hard-code `[#hex]` values when a design token exists. Use the `@theme` utility or `var(--color-...)`.

## Response Standards

- Prefer composition of utilities over new abstractions.
- Justify any animation or shadow that gets added.
- State v3 versus v4 syntax differences when migrating.
- Cite the Tailwind v4 docs for non-obvious behavior. When a docs MCP server (such as context7) or WebFetch is available, check current docs before answering version-specific questions.

## Analysis Scripts

Run from the target project root as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rule matches, for example `bash ${CLAUDE_PLUGIN_ROOT}/lib/tailwind-forge/scripts/check-classes.sh`. No arguments. The `check-*` scripts scan `src/`, `app/`, `components/`, `pages/`, and `lib/` (or the root) and skip `node_modules` and build output. `analyze-bundle.sh` reads build output instead; run it after a build.

- `scripts/check-classes.sh`: class usage patterns, dynamic class risks
- `scripts/check-dark-mode.sh`: dark mode coverage
- `scripts/check-accessibility.sh`: focus, `outline-none`, and other a11y patterns
- `scripts/analyze-bundle.sh`: CSS bundle size and optimization opportunities
