# Tailwind CSS v4 Fundamentals

**Contents:** Overview · Installation · CSS-First Configuration · Custom Utilities · Custom Variants · Loading Plugins · Using Prefixes · CSS Variables in Code · Core Utility Categories · Arbitrary Values · Important Modifier · Layers · Best Practices · v3 to v4 Reference · Common Migration Issues

## Overview

Tailwind CSS v4.0 (January 2025) is a ground-up rewrite with a new high-performance engine (Oxide) and CSS-first configuration.

| Feature | v3 | v4 |
|---------|----|----|
| Configuration | `tailwind.config.js` | CSS-first (`@theme`) |
| Color format | hex/rgb | OKLCH |
| Plugins | `plugins: []` in JS config | `@plugin` directive |
| Custom utilities | JS config / `@layer utilities` | `@utility` directive |
| Custom variants | `addVariant()` | `@custom-variant` directive |
| `@import` handling | postcss-import | Built-in |
| Vendor prefixing | autoprefixer | Built-in |
| CSS nesting | postcss-nested | Built-in |
| Content detection | `content` config | Automatic (`@source` for extra paths) |
| Container queries | Plugin | Built-in (see responsive.md) |

## Installation

### Vite Projects (Recommended)

```bash
npm install -D tailwindcss @tailwindcss/vite
```

```javascript
// vite.config.js
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [tailwindcss()]
})
```

### PostCSS Projects

```bash
npm install -D tailwindcss @tailwindcss/postcss
```

```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {}
  }
}
```

### CLI

```bash
npm install -D tailwindcss @tailwindcss/cli
npx @tailwindcss/cli -i app.css -o out.css --watch
```

### CSS Entry Point

```css
/* app.css - the only required CSS file */
@import "tailwindcss";
```

## CSS-First Configuration

`@theme` replaces `tailwind.config.js`. Each theme variable creates both a CSS variable and the matching utilities.

```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 180);

  --font-display: "Satoshi", sans-serif;
  --font-sans: "Inter", sans-serif; /* page default via preflight */

  /* Extra breakpoints - always rem, never px */
  --breakpoint-xs: 30rem;
  --breakpoint-3xl: 120rem;
}
```

This generates `bg-primary`, `text-secondary`, `font-display`, `font-sans` (also the preflight default font), `xs:*`, `3xl:*`, and the CSS variables `--color-primary` etc.

Spacing is a single multiplier (`--spacing: 0.25rem`), so `p-4`, `p-13`, and `w-17` all work without listing each step.

The full namespace table, resetting defaults (`--*: initial`), `@theme inline`, `@theme static`, and shared theme files are in v4-theme-advanced.md.

## Custom Utilities

`@utility` registers a class that works with every variant (`hover:`, `md:`, `dark:`). Names are plain identifiers, optionally ending in `-*`. Nest pseudo-elements instead of putting them in the name.

```css
@utility content-auto {
  content-visibility: auto;
}

/* Functional: measure-60 (60ch), measure-prose (theme), measure-[40rem] */
@utility measure-* {
  max-inline-size: --value(--measure-*, [length]);
  max-inline-size: calc(--value(integer) * 1ch);
}
```

```html
<div class="content-auto">
  <p class="measure-60">Body copy capped at 60 characters per line</p>
</div>
```

Never reuse a core utility name (`text-balance`, `line-clamp-*`, `snap-*`, `aspect-*`, `indent-*`, `text-shadow-*` (v4.1+), `tab-*` (v4.3+) already exist). Canonical `content-auto` and `scrollbar-hide` definitions and the full `--value()` / `--modifier()` reference are in v4-custom-utilities.md.

## Custom Variants

Use built-in variants first. Only add `@custom-variant` for states Tailwind does not cover.

| Need | Built-in |
|------|----------|
| `data-state="open"` | `data-[state=open]:` |
| `data-disabled` present | `data-disabled:` |
| `aria-expanded="true"` | `aria-expanded:` |
| Direct children | `*:` |
| All descendants | `**:` |
| Not first child | `not-first:` |
| Parent hover/focus | `group-hover:`, `group-focus-visible:` |
| Sibling checked | `peer-checked:` |

```css
/* Selector-based dark mode (replaces the default prefers-color-scheme strategy) */
@custom-variant dark (&:where(.dark, .dark *));

/* Combined state - hover and keyboard focus */
@custom-variant hocus (&:hover, &:focus-visible);
```

```html
<button class="hocus:bg-blue-600">Hover or focus</button>
<div data-state="open" class="hidden data-[state=open]:block">Panel</div>
<ul class="*:border-b *:border-gray-200">
  <li class="not-first:pt-2">Item 1</li>
  <li class="not-first:pt-2">Item 2</li>
</ul>
```

## Loading Plugins

```css
@import "tailwindcss";

@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";

/* Local JS plugin - last resort, prefer @utility / @custom-variant */
@plugin "./my-plugin.js";
```

Plugin options use a block:

```css
@plugin "@tailwindcss/forms" {
  strategy: "class";
}
```

See plugins.md for details.

## Using Prefixes

```css
@import "tailwindcss" prefix(tw);

@theme {
  /* Define without prefix */
  --font-display: "Satoshi", sans-serif;
}
```

```html
<div class="tw:flex tw:bg-red-500 tw:hover:bg-red-600">Content</div>
```

The prefix comes first, before variants. Generated variables are prefixed too:

```css
:root {
  --tw-font-display: "Satoshi", sans-serif;
}
```

## CSS Variables in Code

Use `var()` instead of `theme()`:

```css
/* v3 (deprecated) */
.old-way {
  background-color: theme(colors.red.500);
}

/* v4 */
.new-way {
  background-color: var(--color-red-500);
}
```

Exception: CSS variables do not work in media query conditions, so `theme()` with the variable name is still correct there.

```css
@media (width >= theme(--breakpoint-xl)) {
  /* ... */
}
```

## Core Utility Categories

```html
<!-- Layout -->
<div class="flex flex-col md:flex-row items-center justify-between gap-4">
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

<!-- Spacing -->
<div class="px-6 py-2 mx-auto my-8 gap-x-6 gap-y-2">

<!-- Typography -->
<p class="text-sm md:text-base font-medium leading-relaxed text-gray-600">

<!-- Colors -->
<div class="bg-white text-blue-600 border border-gray-200">

<!-- Sizing -->
<div class="w-full md:w-1/2 min-h-[500px] max-w-xl">
```

## Arbitrary Values

```html
<!-- Any CSS value -->
<div class="top-[117px] left-[calc(50%-4rem)]">

<!-- CSS variable shorthand (v4) -->
<div class="bg-(--my-color)">

<!-- Underscores become spaces -->
<div class="grid-cols-[1fr_500px_2fr]">
```

Prefer a token utility (`bg-surface`) over an arbitrary value when the token exists.

## Important Modifier

The `!` goes at the end of the class, after any variants:

```html
<div class="mt-0!">
<div class="hover:bg-red-500!">
```

The v3 prefix form (`!mt-0`) is deprecated.

## Layers

```css
@layer base {
  h1 {
    @apply text-2xl font-bold;
  }
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-medium;
  }
}

/* Utilities: use @utility, not @layer utilities */
```

## Best Practices

### 1. Use OKLCH Colors

```css
@theme {
  /* oklch(lightness 0-1, chroma 0-0.4, hue 0-360) */
  --color-primary-50: oklch(0.97 0.02 250);
  --color-primary-100: oklch(0.93 0.04 250);
  --color-primary-500: oklch(0.55 0.2 250);
  --color-primary-600: oklch(0.48 0.2 250);
  --color-primary-900: oklch(0.27 0.12 250);

  --color-success: oklch(0.6 0.15 145);
  --color-warning: oklch(0.75 0.15 65);
  --color-error: oklch(0.55 0.2 25);
}
```

### 2. Fluid Typography and Spacing

Define fluid sizes as `--text-*` / `--spacing-*` theme tokens with `clamp()`. The canonical scale and usage live in responsive.md; token naming is in design-systems.md.

### 3. Organize Theme by Category

```css
@theme {
  /* === Colors === */
  --color-primary: oklch(0.6 0.2 250);
  --color-error: oklch(0.55 0.2 25);

  /* === Typography === */
  --font-sans: "Inter Variable", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  /* === Radius === */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;

  /* === Easing === */
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
}
```

### 4. Keep @utility Definitions Single-Purpose

```css
@utility safe-area-pb {
  padding-bottom: env(safe-area-inset-bottom);
}
```

Multi-property patterns (cards, buttons) belong in components or `@layer components`, not `@utility`.

### 5. Mobile-First Class Order

Write the unprefixed (mobile) class first, then larger breakpoints: `p-4 md:p-6 lg:p-8`. See responsive.md.

### 6. Accessible Interactive Elements

```html
<!-- 44px minimum target (WCAG 2.2 AAA / common guideline) -->
<button class="
  min-h-11 min-w-11 px-4 py-2.5
  bg-primary-600 hover:bg-primary-700 text-white
  rounded-md font-medium
  focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-500
  transition-colors motion-reduce:transition-none
">
  Button Text
</button>
```

Do not use `outline-none` to hide focus: in v4 it sets `outline-style: none`, which also hides focus in forced-colors mode. Use `outline-hidden` (the v3 `outline-none` behavior) only when a ring replaces the outline.

## v3 to v4 Reference

| v3 | v4 |
|----|----|
| `@tailwind base; @tailwind components; @tailwind utilities;` | `@import "tailwindcss";` |
| `tailwind.config.js` theme | `@theme { ... }` in CSS (JS config still loads through `@config`) |
| `darkMode: 'class'` | `@custom-variant dark (&:where(.dark, .dark *));` |
| `plugins: [require(...)]` | `@plugin "...";` |
| `shadow-sm`, `shadow` | `shadow-xs`, `shadow-sm` (scale moved down one step; same for `rounded-*` and `blur-*`) |
| `ring` (3px, blue) | `ring-3` (`ring` is now 1px, `currentColor`) |
| Border default `gray-200` | Border default `currentColor`; set a color explicitly |
| `bg-opacity-50` | `bg-black/50` |
| `!font-bold` | `font-bold!` |
| `outline-none` | `outline-hidden` (`outline-none` now sets `outline-style: none`) |
| `flex-shrink-*`, `flex-grow-*` | `shrink-*`, `grow-*` |
| `bg-gradient-to-r` | `bg-linear-to-r` |
| `@tailwindcss/container-queries` plugin | Built in: `@container`, `@md:`, `@max-md:` |
| `tailwindcss-animate` | `tw-animate-css` (`@import "tw-animate-css";`) |
| Variants stack right to left | Variants stack left to right |
| `hover:` on every device | `hover:` applies only on hover-capable devices |

For `space-*` selectors, placeholder color, button cursor, and the base-layer rules that restore v3 defaults, see debugging.md (v4 Behavior Changes).

Run `npx @tailwindcss/upgrade` to automate most of a v3 migration. Review the diff afterwards.

### Minor-Version Features

References tag newer features inline. Older installs do not generate them, and do not throw an error.

| Version | Features |
|---------|----------|
| v4.1+ | `text-shadow-*`, `pointer-*` / `any-pointer-*`, `noscript:`, `user-valid:` / `user-invalid:`, `@source inline()` / `@source not` |
| v4.2+ | `pbs-*` / `pbe-*` / `mbs-*` / `mbe-*` logical spacing |
| v4.3+ | `@container-size`, core `tab-*` |

Check the docs before using anything newer than the installed version.

### Working in a v3 Project

When the project is on v3 and the user has not asked to migrate, write v3 syntax: `tailwind.config.js` theme and plugins, `@tailwind` directives, `!` prefix, `bg-opacity-*`, the v3 `shadow`/`rounded`/`ring` scales. Read the table above in reverse. Offer `npx @tailwindcss/upgrade` once; do not push it.

## Common Migration Issues

### Border Color Default

v4 `border-*` and `divide-*` default to `currentColor` (v3 used gray-200). Set a color on each border (`border border-gray-200`). For the global v3 compatibility rule, see debugging.md (v4 Behavior Changes).

### Ring Default

v4 `ring` is 1px `currentColor` (v3 was 3px blue-500). Replace `ring` with `ring-3` and add an explicit color.

### Outline and Important Renames

`outline-none` → `outline-hidden`. `!mt-0` → `mt-0!`.

### Button Cursor

v4 buttons use `cursor: default`. Restore pointer if needed:

```css
@layer base {
  button:not(:disabled),
  [role="button"]:not(:disabled) {
    cursor: pointer;
  }
}
```
