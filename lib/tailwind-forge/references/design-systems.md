# Tailwind CSS Advanced Design Systems

**Contents:** Building Design Tokens with @theme · Dark Mode Design Tokens · Multi-Theme Systems · Component Token System · Responsive Design Tokens · Brand Color Generation · Monorepo Design System · shadcn/ui Projects · Best Practices

## Building Design Tokens with @theme

### Complete Design Token System

Every namespaced variable generates utilities automatically (`--color-surface` → `bg-surface`, `text-surface`, `border-surface`). See v4-theme-advanced.md for the namespace list.

```css
@import "tailwindcss";

@theme {
  /* ===== COLOR ===== */
  --color-*: initial;

  --color-white: oklch(1 0 0);
  --color-black: oklch(0 0 0);

  /* Surfaces */
  --color-surface: oklch(1 0 0);
  --color-surface-raised: oklch(0.98 0.002 250);
  --color-surface-sunken: oklch(0.95 0.004 250);
  --color-surface-inverse: oklch(0.15 0.02 250);

  /* Foreground (text/icons): text-fg, text-fg-muted */
  --color-fg: oklch(0.15 0.02 250);
  --color-fg-muted: oklch(0.4 0.02 250);
  --color-fg-subtle: oklch(0.55 0.015 250);
  --color-fg-inverse: oklch(0.98 0 0);
  --color-fg-disabled: oklch(0.7 0.01 250);

  /* Borders: border-line, border-line-strong */
  --color-line: oklch(0.85 0.01 250);
  --color-line-subtle: oklch(0.92 0.005 250);
  --color-line-strong: oklch(0.7 0.02 250);

  /* Brand scale */
  --color-brand-50: oklch(0.97 0.02 250);
  --color-brand-100: oklch(0.93 0.04 250);
  --color-brand-200: oklch(0.87 0.08 250);
  --color-brand-300: oklch(0.78 0.12 250);
  --color-brand-400: oklch(0.68 0.16 250);
  --color-brand-500: oklch(0.58 0.2 250);
  --color-brand-600: oklch(0.5 0.2 250);
  --color-brand-700: oklch(0.42 0.18 250);
  --color-brand-800: oklch(0.35 0.15 250);
  --color-brand-900: oklch(0.28 0.12 250);
  --color-brand-950: oklch(0.2 0.08 250);

  /* Status */
  --color-success: oklch(0.6 0.18 145);
  --color-success-subtle: oklch(0.95 0.04 145);
  --color-warning: oklch(0.75 0.18 85);
  --color-warning-subtle: oklch(0.95 0.06 85);
  --color-error: oklch(0.55 0.22 25);
  --color-error-subtle: oklch(0.95 0.04 25);
  --color-info: oklch(0.6 0.18 250);
  --color-info-subtle: oklch(0.95 0.04 250);

  /* ===== TYPOGRAPHY ===== */
  /* Keep the names sans and mono: preflight reads --default-font-family
     (→ --font-sans) and --default-mono-font-family (→ --font-mono) */
  --font-*: initial;

  --font-display: "Cal Sans", "Inter", system-ui, sans-serif;
  --font-sans: "Inter", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", "Fira Code", monospace;

  /* Type scale (Major Third - 1.25) */
  --text-xs: 0.64rem;
  --text-sm: 0.8rem;
  --text-base: 1rem;
  --text-lg: 1.25rem;
  --text-xl: 1.563rem;
  --text-2xl: 1.953rem;
  --text-3xl: 2.441rem;
  --text-4xl: 3.052rem;

  --leading-tight: 1.15;
  --leading-snug: 1.3;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  --tracking-tight: -0.025em;
  --tracking-normal: 0;
  --tracking-wide: 0.025em;

  /* ===== SPACING ===== */
  /* One multiplier drives p-*, m-*, gap-*, w-*, h-*: p-4 = 1rem */
  --spacing: 0.25rem;

  /* ===== SHADOWS ===== */
  --shadow-*: initial;

  --shadow-xs: 0 1px 2px 0 oklch(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 oklch(0 0 0 / 0.1), 0 1px 2px -1px oklch(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px oklch(0 0 0 / 0.1), 0 2px 4px -2px oklch(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px oklch(0 0 0 / 0.1), 0 4px 6px -4px oklch(0 0 0 / 0.1);

  /* Colored shadows - only when requested */
  --shadow-brand: 0 4px 14px 0 oklch(0.58 0.2 250 / 0.3);

  /* ===== RADIUS ===== */
  /* rounded-none and rounded-full are built in; no tokens needed */
  --radius-*: initial;

  --radius-xs: 0.125rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;

  /* ===== MOTION ===== */
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
  --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);

  /* ===== BREAKPOINTS ===== */
  /* Defaults (sm-2xl) are kept; add extras in rem only */
  --breakpoint-xs: 30rem;
  --breakpoint-3xl: 120rem;
}
```

### Durations and Z-Index Layers

`--duration-*` and `--z-*` are not theme namespaces, so tokens for them inside `@theme` generate nothing. Use built-in bare values (`duration-150`, `z-40`), or define plain variables and reference them with the arbitrary shorthand:

```css
:root {
  --duration-fast: 150ms;
  --duration-base: 200ms;

  --z-dropdown: 100;
  --z-sticky: 200;
  --z-modal: 500;
  --z-toast: 800;
}
```

```html
<header class="sticky top-0 z-(--z-sticky)">...</header>
<div class="fixed inset-0 z-(--z-modal)">...</div>
<button class="transition-colors duration-(--duration-fast)">Save</button>
```

## Dark Mode Design Tokens

Use one strategy: define tokens once in `@theme`, override the variables for dark mode, and use the generated utilities. Components need no `dark:` classes. Only if the project uses dark mode.

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-surface: oklch(1 0 0);
  --color-surface-raised: oklch(0.98 0 0);
  --color-fg: oklch(0.15 0 0);
  --color-fg-muted: oklch(0.45 0 0);
  --color-line: oklch(0.9 0 0);
}

@layer base {
  .dark {
    --color-surface: oklch(0.12 0.02 260);
    --color-surface-raised: oklch(0.18 0.02 260);
    --color-fg: oklch(0.95 0 0);
    --color-fg-muted: oklch(0.65 0 0);
    --color-line: oklch(0.28 0.02 260);
  }
}
```

For OS-preference-only dark mode, drop the `@custom-variant` line and put the overrides in `@media (prefers-color-scheme: dark) { :root { ... } }` instead of `.dark`. Do not ship both.

```html
<div class="bg-surface text-fg">
  <p class="text-fg-muted">Muted text</p>
  <div class="border border-line bg-surface-raised">Bordered</div>
</div>
```

Do not write `bg-[var(--color-surface)]` or hand-written `@utility bg-surface` rules; `@theme` already generates `bg-surface`.

## Multi-Theme Systems

### Theme Switching with Data Attributes

Override the same variables per theme. Utilities such as `bg-primary` follow the active theme without extra variants.

```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 200);
  --color-accent: oklch(0.75 0.18 30);
}

@layer base {
  [data-theme="ocean"] {
    --color-primary: oklch(0.55 0.2 220);
    --color-secondary: oklch(0.65 0.15 200);
    --color-accent: oklch(0.7 0.18 180);
  }

  [data-theme="forest"] {
    --color-primary: oklch(0.5 0.18 145);
    --color-secondary: oklch(0.6 0.12 120);
    --color-accent: oklch(0.75 0.15 85);
  }
}
```

```html
<html data-theme="ocean">
  <body>
    <button class="bg-primary text-white">Uses the ocean primary</button>
  </body>
</html>
```

### JavaScript Theme Switcher

```javascript
function setTheme(theme) {
  if (theme === 'default') {
    document.documentElement.removeAttribute('data-theme');
  } else {
    document.documentElement.setAttribute('data-theme', theme);
  }
  try { localStorage.setItem('theme', theme); } catch {}
}

function initTheme() {
  let saved = 'default';
  try { saved = localStorage.getItem('theme') || 'default'; } catch {}
  setTheme(saved);
}

initTheme();
```

Run `initTheme()` in a blocking script in `<head>` to avoid a flash of the default theme.

## Component Token System

Component tokens are not theme namespaces, so define them as plain variables. Derive spacing from `--spacing` (there is no `--spacing-4` in v4).

```css
:root {
  --button-padding-x: calc(var(--spacing) * 4);
  --button-padding-y: calc(var(--spacing) * 2);
  --button-radius: var(--radius-md);

  --input-padding-x: calc(var(--spacing) * 3);
  --input-padding-y: calc(var(--spacing) * 2);
  --input-radius: var(--radius-md);

  --card-padding: calc(var(--spacing) * 6);
  --card-radius: var(--radius-lg);
}
```

```css
@layer components {
  .btn {
    padding: var(--button-padding-y) var(--button-padding-x);
    border-radius: var(--button-radius);
    font-weight: 500;
    transition: background-color 150ms ease, color 150ms ease;
  }

  .input {
    padding: var(--input-padding-y) var(--input-padding-x);
    border-radius: var(--input-radius);
    border: 1px solid var(--color-line);
  }

  .input:focus-visible {
    outline: 2px solid var(--color-brand-500);
    outline-offset: 2px;
  }

  .card {
    padding: var(--card-padding);
    border-radius: var(--card-radius);
    border: 1px solid var(--color-line);
  }
}
```

Keep the focus outline visible. Never set `outline: none` without a replacement indicator.

## Responsive Design Tokens

Fluid sizes are ordinary theme tokens in the `--text-*` and `--spacing-*` namespaces. Tailwind generates the utilities; no `@utility` rules are needed. The full scale and when to use it are in responsive.md.

```css
@theme {
  --text-fluid-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --text-fluid-xl: clamp(1.5rem, 1.2rem + 1.5vw, 2rem);
  --text-fluid-3xl: clamp(2.5rem, 1.8rem + 3vw, 4rem);

  --spacing-fluid-sm: clamp(0.5rem, 0.4rem + 0.5vw, 1rem);
  --spacing-fluid-md: clamp(1rem, 0.8rem + 1vw, 2rem);
  --spacing-fluid-lg: clamp(2rem, 1.5rem + 2vw, 4rem);
}
```

```html
<section class="py-fluid-lg px-fluid-md">
  <h2 class="text-fluid-3xl">Heading</h2>
  <div class="grid gap-fluid-sm">...</div>
</section>
```

Always combine `vw` with `rem` in `clamp()` so text still scales with browser zoom.

## Brand Color Generation

### Generating Color Scales from Brand Color

The scale references other variables, so it goes in `@theme inline`; utilities get the `oklch(... var(--brand-hue))` value inlined. Changing `--brand-hue` at runtime (from JavaScript, or under `[data-theme]`) re-tints the whole scale. Overriding `--color-brand-500` itself under a selector does not affect utilities.

```css
:root {
  --brand-hue: 250;
  --brand-chroma: 0.2;
}

@theme inline {
  --color-brand-50: oklch(0.97 calc(var(--brand-chroma) * 0.1) var(--brand-hue));
  --color-brand-100: oklch(0.93 calc(var(--brand-chroma) * 0.2) var(--brand-hue));
  --color-brand-200: oklch(0.87 calc(var(--brand-chroma) * 0.4) var(--brand-hue));
  --color-brand-300: oklch(0.78 calc(var(--brand-chroma) * 0.6) var(--brand-hue));
  --color-brand-400: oklch(0.68 calc(var(--brand-chroma) * 0.8) var(--brand-hue));
  --color-brand-500: oklch(0.58 var(--brand-chroma) var(--brand-hue));
  --color-brand-600: oklch(0.5 var(--brand-chroma) var(--brand-hue));
  --color-brand-700: oklch(0.42 calc(var(--brand-chroma) * 0.9) var(--brand-hue));
  --color-brand-800: oklch(0.35 calc(var(--brand-chroma) * 0.75) var(--brand-hue));
  --color-brand-900: oklch(0.28 calc(var(--brand-chroma) * 0.6) var(--brand-hue));
  --color-brand-950: oklch(0.2 calc(var(--brand-chroma) * 0.4) var(--brand-hue));
}
```

## Monorepo Design System

### Shared Design Tokens Package

```text
packages/
  design-tokens/
    tokens.css
    package.json
  ui-components/
    src/
    package.json
apps/
  web/
```

**packages/design-tokens/tokens.css:**
```css
@theme {
  --color-brand-500: oklch(0.58 0.2 250);
  --font-display: "Cal Sans", system-ui, sans-serif;
}
```

**packages/design-tokens/package.json:**
```json
{
  "name": "@mycompany/design-tokens",
  "version": "1.0.0",
  "exports": {
    ".": "./tokens.css"
  }
}
```

**apps/web/app.css:**
```css
@import "tailwindcss";
@import "@mycompany/design-tokens";

/* Scan shared component source for class names */
@source "../../packages/ui-components/src";
```

## shadcn/ui Projects

shadcn/ui on Tailwind v4 keeps raw variables in `:root` and `.dark` (oklch values), outside any `@layer`, and maps them to utilities with `@theme inline`:

```css
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  /* card, popover, secondary, muted, accent, destructive, border, input, ring, chart-1..5, sidebar-* */
}

.dark {
  color-scheme: dark;
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --radius-sm: calc(var(--radius) * 0.6);
  --radius-md: calc(var(--radius) * 0.8);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) * 1.4);
}
```

Newer CLI versions also add `@import "shadcn/tailwind.css";`. Keep whatever imports the project already has.

`&:is(.dark *)` does not match `<html>` itself, so `dark:scheme-dark` on `<html>` never applies; set `color-scheme: dark` inside the `.dark {}` block.

- Retheme by editing the raw variables (`--primary`, `--background`, `--radius`) in `:root` and `.dark`. Do not override the `--color-*` aliases; they are inlined, so overrides under `.dark` have no effect.
- Each surface pairs with a `-foreground` token. Use the generated utilities: `bg-background text-foreground`, `bg-primary text-primary-foreground`. Do not write `bg-[var(--primary)]`.
- Add a new color by defining `--warning` and `--warning-foreground` in `:root` and `.dark`, then mapping `--color-warning: var(--warning);` and `--color-warning-foreground: var(--warning-foreground);` in `@theme inline`.
- Add components with `npx shadcn@latest add <name>` (for example `button`, `dialog`). Check `components/ui` first; the component may already exist.
- Components are copied into the project (`components/ui`). Edit them there instead of wrapping them in new components.
- Re-running `add --overwrite` replaces local edits. Commit before overwriting, then reapply customizations.

## Best Practices

### 1. Use Semantic Naming

Name tokens by role (`--color-surface-raised`, `--color-fg-muted`, `--color-line`), not by raw value (`--color-gray-900`). Choose names that read well as utilities: `text-fg-muted` beats `text-text-muted`.

### 2. Document Token Purpose

```css
@theme {
  /*
   * Surfaces
   * surface: page background
   * raised: cards and elevated elements
   * sunken: inset areas like inputs
   */
  --color-surface: oklch(1 0 0);
  --color-surface-raised: oklch(0.98 0 0);
  --color-surface-sunken: oklch(0.96 0 0);
}
```

### 3. Create Token Aliases with @theme inline

```css
@theme {
  --color-blue-500: oklch(0.58 0.2 250);
}

@theme inline {
  --color-primary: var(--color-blue-500);
  --color-link: var(--color-blue-500);
  --color-focus: var(--color-blue-500);
}
```

Aliases are inlined, so overriding `--color-primary` under `.dark` or `[data-theme]` does not affect utilities. To switch them per theme, override the referenced variable (`--color-blue-500`) under the selector, or define the token with a literal value in plain `@theme` and override that.

### 4. Version the Design System

Keep tokens in version control and record breaking renames in the changelog (for example, `--color-gray-*` → `--color-neutral-*`).
