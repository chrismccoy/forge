# Styling with Tailwind CSS

Tailwind CSS 4.3 setup, CSS-first design tokens, theming, dark mode, variants, class composition, and accessible styling for React 19 apps. Load it when adding Tailwind to a project, defining a theme or design system, building variant-driven components, or migrating from Tailwind v3.

## Contents

- [Quick Reference](#quick-reference)
- [Setup](#setup)
- [CSS-First Configuration](#css-first-configuration)
- [Design Tokens with @theme](#design-tokens-with-theme)
- [Semantic Tokens and Theming](#semantic-tokens-and-theming)
- [Dark Mode](#dark-mode)
- [Responsive Design and Container Queries](#responsive-design-and-container-queries)
- [State Variants](#state-variants)
- [Composing Classes](#composing-classes)
- [Variants with class-variance-authority](#variants-with-class-variance-authority)
- [Dynamic Class Names](#dynamic-class-names)
- [Accessibility](#accessibility)
- [Design System](#design-system)
- [Migrating from v3](#migrating-from-v3)
- [Best Practices](#best-practices)

## Quick Reference

| Task | v4 approach |
|------|-------------|
| Import Tailwind | `@import "tailwindcss";` in one CSS entry file |
| Vite-based build | `@tailwindcss/vite` plugin |
| Next.js / other PostCSS | `@tailwindcss/postcss` plugin |
| Add tokens | `@theme { --color-brand-500: oklch(...); }` |
| Token that references a variable | `@theme inline { --color-background: var(--background); }` |
| Custom utility | `@utility name { ... }` |
| Custom variant | `@custom-variant name (selector);` |
| Class-based dark mode | `@custom-variant dark (&:where(.dark, .dark *));` |
| Scan extra paths | `@source "../node_modules/@acme/ui";` |
| Safelist classes | `@source inline("bg-red-{100..900..100}");` |
| CSS variable in a class | `bg-(--brand-color)` |
| Important | `flex!` (suffix) |
| Upgrade from v3 | `npx @tailwindcss/upgrade` (Node 20+) |

Packages: `tailwindcss` and the matching `@tailwindcss/vite` or `@tailwindcss/postcss` (keep them on the same version), plus `clsx`, `tailwind-merge` 3.x, and `class-variance-authority` for component code.

## Setup

v4 needs no `tailwind.config.js` and no `content` array. Sources are detected automatically from the project, ignoring `.gitignore`d files and binaries. Browser floor: Safari 16.4, Chrome 111, Firefox 128; stay on v3.4 when older browsers must be supported.

### Vite, React Router, and TanStack Start

All three build with Vite, so they share the Vite plugin.

```bash
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts: add tailwindcss() to the existing plugin list
import tailwindcss from '@tailwindcss/vite';

// Vite SPA:         plugins: [react(), tailwindcss()]
// React Router:     plugins: [tailwindcss(), reactRouter(), tsconfigPaths()]
// TanStack Start:   plugins: [tailwindcss(), tanstackStart(), tsConfigPaths()]
```

Create one CSS entry with `@import "tailwindcss";` and load it once:

| Framework | CSS file | Loaded from |
|-----------|----------|-------------|
| Vite SPA | `src/index.css` | `import './index.css'` in `src/main.tsx` |
| React Router | `app/app.css` | Side-effect import in `app/root.tsx` ([react-router.md](react-router.md)) |
| TanStack Start | `src/styles.css` | `?url` import linked from the root route `head` ([tanstack-router.md](tanstack-router.md)) |

```tsx
// src/routes/__root.tsx (TanStack Start): link the stylesheet so SSR HTML includes it
import { createRootRoute } from '@tanstack/react-router';
import appCss from '../styles.css?url';

export const Route = createRootRoute({
  head: () => ({ links: [{ rel: 'stylesheet', href: appCss }] }),
  component: RootComponent,
});
```

### Next.js

Next.js builds CSS through PostCSS, so use the PostCSS plugin.

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

```js
// postcss.config.mjs
export default { plugins: { '@tailwindcss/postcss': {} } };
```

Put `@import "tailwindcss";` in `app/globals.css` and import it from `app/layout.tsx`.

## CSS-First Configuration

Everything that lived in `tailwind.config.js` now lives in CSS directives.

| Directive | Purpose |
|-----------|---------|
| `@import "tailwindcss";` | Load preflight, theme, and utilities |
| `@theme { ... }` | Define design tokens that generate utilities |
| `@utility name { ... }` | Register a custom utility that works with variants |
| `@custom-variant name (...)` | Register or override a variant |
| `@variant dark { ... }` | Apply a variant inside hand-written CSS |
| `@source "path";` | Scan a path that automatic detection misses |
| `@source not "path";` | Exclude a path from scanning |
| `@plugin "pkg";` | Load a JavaScript plugin |
| `@config "path";` | Load a legacy JS config during migration |
| `@reference "path";` | Make theme and utilities available to `@apply` in a separate stylesheet without emitting them |

```css
@import "tailwindcss";
@source "../node_modules/@acme/ui";

@utility content-auto {
  content-visibility: auto;
}

/* Functional utility: tab-2, tab-4 read --tab-size-* tokens */
@utility tab-* {
  tab-size: --value(--tab-size-*);
}
```

Use `@layer base` for element defaults and `@layer components` for class-based components that utilities must be able to override. Do not use `@layer utilities` for custom utilities; use `@utility`.

## Design Tokens with @theme

Variables inside `@theme` are tokens: each namespace generates utilities and is also emitted as a plain CSS variable readable with `var()`.

| Namespace | Generates |
|-----------|-----------|
| `--color-*` | `bg-*`, `text-*`, `border-*`, `fill-*`, ... |
| `--font-*` | `font-sans`, `font-display` |
| `--text-*` | `text-sm`, `text-display` |
| `--font-weight-*`, `--tracking-*`, `--leading-*` | Weight, letter spacing, line height |
| `--spacing` / `--spacing-*` | Padding, margin, gap, width, height, inset |
| `--breakpoint-*` | `sm:`, `md:`, custom responsive variants |
| `--container-*` | `@sm:` container variants and `max-w-*` sizes |
| `--radius-*` | `rounded-*` |
| `--shadow-*`, `--inset-shadow-*`, `--drop-shadow-*` | Shadows |
| `--ease-*`, `--animate-*` | Timing functions and animations |

```css
@import "tailwindcss";

@theme {
  /* Brand scale in OKLCH for perceptually even steps */
  --color-brand-500: oklch(0.58 0.19 250);
  --color-brand-900: oklch(0.27 0.08 250);

  --font-display: "Cal Sans", ui-sans-serif, system-ui, sans-serif;

  --text-display: 3.5rem;
  --text-display--line-height: 1.1;

  /* Base unit: p-4 = calc(var(--spacing) * 4) */
  --spacing: 0.25rem;

  --breakpoint-xs: 30rem;
  --breakpoint-3xl: 120rem;

  --radius-card: 0.75rem;

  --animate-fade-in: fade-in 150ms ease-out;
  @keyframes fade-in { from { opacity: 0; } }
}
```

Reset a namespace to remove defaults, then define only what the system allows:

```css
@theme {
  --color-*: initial;
  --color-white: #fff;
  --color-brand-500: oklch(0.58 0.19 250);
}
```

Use `rem` for breakpoints so variants sort correctly. Use `@theme static` only when every token must be emitted even if unused (for example, tokens read from JavaScript); by default only used tokens are output.

For fonts loaded by a framework, reference the loader's variable with `@theme inline` so the utility uses the value directly:

```css
/* next/font exposes --font-inter on <html> */
@theme inline {
  --font-sans: var(--font-inter);
}
```

## Semantic Tokens and Theming

Components should use role names (`bg-background`, `text-muted-foreground`, `border-border`) rather than palette steps (`bg-gray-100`). Define the raw values as plain CSS variables per theme, then map them into `@theme inline` so the utility reads the variable at runtime and switches when the theme changes.

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --border: oklch(0.922 0 0);
  /* ...muted, accent, destructive, ring, etc. follow the same pattern */
  --radius: 0.625rem;
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --border: oklch(1 0 0 / 10%);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-border: var(--border);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
}

@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground; }
}
```

- Pair every surface token with a `-foreground` token and check the pair's contrast in both themes.
- Opacity modifiers work on variable-backed colors: `bg-primary/90`, `ring-ring/50`.
- Add brand themes the same way as dark: a `[data-theme="ocean"]` block overriding the same variables, plus a `@custom-variant` when theme-specific utilities are needed.
- Do not put `var()` references in plain `@theme`; use `@theme inline`, or the variable resolves where it is defined instead of where it is used.

## Dark Mode

By default `dark:` follows `prefers-color-scheme`, which needs no JavaScript and never flashes. Override the variant when users can choose a theme:

```css
/* Class on <html> */
@custom-variant dark (&:where(.dark, .dark *));

/* Or a data attribute */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

Apply the stored choice before first paint with a blocking inline script in `<head>`; a `useEffect` runs after paint and causes a flash of the wrong theme.

```tsx
// Root document component (React Router root Layout, TanStack Start shell, etc.)
const themeScript = `
  document.documentElement.classList.toggle(
    'dark',
    localStorage.theme === 'dark' ||
      (!('theme' in localStorage) && matchMedia('(prefers-color-scheme: dark)').matches)
  );
`;

export function Document({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

To change themes, set or remove `localStorage.theme` (`"light"`, `"dark"`, or absent for system) and toggle the same class.

The server cannot know the client's theme, so the script changes `<html>` before hydration. `suppressHydrationWarning` on `<html>` silences that one attribute mismatch only; it does not reach children. Never render theme-dependent markup (an icon chosen from `localStorage`) during the first render; read the theme after mount or render both icons and toggle them with `dark:hidden` / `hidden dark:block`. See [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches) for the full caveat.

In a Vite SPA, put the same script in `index.html`. In Next.js, use `next-themes` (shown in [shadcn-ui.md](shadcn-ui.md#dark-mode)). Alternatively store the preference in a cookie and render the class on the server, which removes the script and the mismatch.

Set `color-scheme: dark` inside `.dark` (and `light` in `:root`) so native controls and scrollbars match.

## Responsive Design and Container Queries

Breakpoint variants are mobile-first `min-width` queries. Write the base style for small screens, then layer up.

```tsx
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4" />
<aside className="hidden md:max-xl:block" /> {/* only from md up to xl */}
```

Use container queries for components that appear in containers of different widths (cards in a sidebar vs. main column). They are built in; no plugin.

```tsx
<article className="@container rounded-lg border">
  <div className="flex flex-col gap-3 p-4 @md:flex-row @md:items-center">
    <img src={product.image} alt="" className="aspect-square w-full @md:w-32" />
    <h3 className="truncate font-semibold @lg:text-lg">{product.name}</h3>
  </div>
</article>
```

| Syntax | Meaning |
|--------|---------|
| `@container` | Mark an inline-size container |
| `@md:` / `@max-md:` | Container at least / below `md` (28rem) |
| `@sm:@max-md:` | Container size range |
| `@container/main` + `@lg/main:` | Query a named, non-nearest container |
| `@min-[475px]:` | Arbitrary container size |
| `w-[50cqw]` | Container query units |

## State Variants

| Variant | Example | Notes |
|---------|---------|-------|
| `hover:` | `hover:bg-muted` | Only on devices that support hover |
| `focus-visible:` | `focus-visible:ring-2` | Keyboard focus; prefer over `focus:` |
| `active:`, `disabled:` | `disabled:opacity-50` | |
| `aria-*` | `aria-expanded:rotate-180`, `aria-invalid:border-destructive` | Style from the real ARIA state |
| `aria-[...]` | `aria-[sort=ascending]:text-primary` | Arbitrary ARIA value |
| `data-*` | `data-active:font-semibold`, `data-[state=open]:bg-muted` | Boolean or value match |
| `group-*` | `group-hover:underline`, `group-data-[state=open]:rotate-180` | Parent marked `group` |
| `group-*/name` | `group-hover/item:visible` | Named group `group/item` |
| `peer-*` | `peer-invalid:visible`, `peer-checked:bg-primary` | Earlier sibling marked `peer` |
| `has-*` | `has-[input:checked]:border-primary` | Parent styled by descendants |
| `not-*` | `not-last:border-b` | Negate a variant |
| `in-*` | `in-data-[state=open]:opacity-100` | Like `group-*` without a `group` class |
| `starting:` | `starting:opacity-0` | `@starting-style` for enter transitions |
| `*:` | `*:rounded-md` | Direct children |

Style from state the markup already expresses. When a component sets `aria-expanded` or `data-state`, use those variants instead of mirroring the state into extra class logic.

```tsx
<button
  type="button"
  aria-expanded={open}
  aria-controls={panelId}
  onClick={() => setOpen(!open)}
  className="group flex w-full items-center justify-between rounded-md px-3 py-2 hover:bg-muted focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
>
  {title}
  <ChevronDown aria-hidden className="size-4 transition-transform motion-reduce:transition-none group-aria-expanded:rotate-180" />
</button>
```

Enter transitions for elements that appear (popovers, dialogs) use `starting:` with `transition-discrete` so `display` can animate:

```tsx
<div popover="auto" id="menu" className="opacity-100 transition-[opacity,display] transition-discrete starting:open:opacity-0" />
```

## Composing Classes

Use one `cn()` helper everywhere a component accepts `className`. `clsx` handles conditionals; `tailwind-merge` resolves conflicts so the caller's `px-6` beats the component's `px-4`.

```ts
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
type CardProps = React.ComponentProps<'div'> & { interactive?: boolean };

export function Card({ className, interactive = false, ...props }: CardProps) {
  return (
    <div
      data-slot="card"
      className={cn(
        'rounded-lg border bg-background p-4',
        interactive && 'transition-shadow hover:shadow-md',
        className,
      )}
      {...props}
    />
  );
}
```

`ref` is a regular prop in React 19: it is part of `React.ComponentProps<'div'>` and reaches the element through `...props`. Do not wrap components in `forwardRef`.

tailwind-merge 3.x supports v4 class names. It only knows the default scales, so register custom tokens that share a prefix with other utilities. Without this, `text-display` is treated as a color and `cn('text-display', 'text-red-500')` drops the size.

```ts
import { extendTailwindMerge } from 'tailwind-merge';

// Use this instead of the default twMerge inside cn()
const twMerge = extendTailwindMerge({
  extend: { theme: { text: ['display'], radius: ['card'] } },
});
```

## Variants with class-variance-authority

Use `cva` when a component has named variants. It keeps variant logic declarative and typed.

```tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const badgeVariants = cva(
  'inline-flex items-center gap-1 rounded-md border px-2 py-0.5 text-xs font-medium',
  {
    variants: {
      variant: {
        neutral: 'border-transparent bg-muted text-foreground',
        primary: 'border-transparent bg-primary text-primary-foreground',
        danger: 'border-transparent bg-destructive text-white',
        outline: 'text-foreground',
      },
      size: { sm: 'px-1.5', md: '' },
    },
    compoundVariants: [{ variant: 'outline', size: 'sm', class: 'border-dashed' }],
    defaultVariants: { variant: 'neutral', size: 'md' },
  },
);

type BadgeProps = React.ComponentProps<'span'> & VariantProps<typeof badgeVariants>;

export function Badge({ className, variant, size, ...props }: BadgeProps) {
  return (
    <span
      data-slot="badge"
      data-variant={variant ?? 'neutral'}
      className={cn(badgeVariants({ variant, size }), className)}
      {...props}
    />
  );
}

export { badgeVariants };
```

Export the `cva` function so other components (a link styled as a badge) can reuse the classes. Keep variants about appearance; behavior differences belong in separate components or props.

## Dynamic Class Names

Tailwind scans source files as plain text. It cannot evaluate template strings, so interpolated class names are never generated.

```tsx
// Wrong: bg-red-500 and bg-green-500 never appear in source
<span className={`bg-${color}-500`} />

// Right: complete class names in a typed map
type Status = 'success' | 'warning' | 'error';
const statusClasses = {
  success: 'bg-green-100 text-green-800',
  warning: 'bg-amber-100 text-amber-900',
  error: 'bg-red-100 text-red-800',
} as const satisfies Record<Status, string>;

<span className={statusClasses[status]} />
```

For truly runtime values (user-picked colors, computed positions), use a CSS variable and a static utility that reads it:

```tsx
<div
  className="bg-(--swatch) size-8 rounded-full"
  style={{ '--swatch': user.color } as React.CSSProperties}
/>
```

If classes come from a CMS or database, safelist them with `@source inline("{hover:,}bg-red-{100..900..100}")`; there is no `safelist` option in v4.

## Accessibility

- Give every interactive element a visible keyboard focus style. Use `focus-visible:` so mouse clicks do not show rings: `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring`, or a ring: `focus-visible:ring-[3px] focus-visible:ring-ring/50`.
- Never remove focus styles without a replacement. In v4, `outline-hidden` hides the outline but keeps it in forced-colors mode; `outline-none` removes it entirely.
- Gate decorative motion: `motion-safe:animate-fade-in`, `motion-reduce:transition-none`, `motion-reduce:animate-none`. Keep essential feedback (a spinner) but slow or simplify it.
- Check contrast for every `-foreground` pair in both themes (4.5:1 for body text, 3:1 for large text and UI boundaries). `text-muted-foreground` on `bg-muted` is the pair that most often fails.
- Use `contrast-more:` and `forced-colors:` to strengthen borders and focus indicators for users who ask for them.
- Hide text visually but keep it for screen readers with `sr-only`; use `aria-hidden` on decorative icons.
- Do not convey state by color alone; pair color with text or an icon.
- Keep touch targets at least 24px (`min-h-6 min-w-6`), ideally 44px for primary actions (`min-h-11`).

See [fundamentals.md](fundamentals.md) for accessible markup in components.

## Design System

A Tailwind design system is three layers. Keep each in its own place.

| Layer | Where | Example |
|-------|-------|---------|
| Primitive tokens | `@theme` | `--color-brand-500`, `--spacing`, `--radius` |
| Semantic tokens | `:root` / `.dark` + `@theme inline` | `--primary`, `--muted-foreground` |
| Component primitives | `components/ui/*` with `cva` | `Button`, `Badge`, `Card`, `Input` |

- Product code uses semantic tokens and component primitives only. Palette utilities (`bg-blue-600`) in feature code are a smell; reset unused namespaces (`--color-*: initial`) to enforce this at build time.
- Component primitives accept `className` and merge it last with `cn()`, accept `ref` as a regular prop, and spread remaining props onto the root element.
- Add a `data-slot` attribute to each primitive's root so parents can target it (`*:data-[slot=icon]:size-4`) without coupling to class names.
- Wrap rather than fork: build a product-specific component on top of a primitive, constraining its variants, instead of editing the primitive for one use case.

```tsx
type ToolbarButtonProps = Omit<React.ComponentProps<typeof Button>, 'variant' | 'size'> & { danger?: boolean };

export function ToolbarButton({ danger = false, ...props }: ToolbarButtonProps) {
  return <Button variant={danger ? 'destructive' : 'ghost'} size="sm" {...props} />;
}
```

Document variants next to the component: list each `cva` variant with intended use, show every variant in a story or a single gallery route, and add a visual or interaction test per variant (see [testing.md](testing.md)). Treat token names as public API; renaming one is a breaking change for every consumer.

## Migrating from v3

Run `npx @tailwindcss/upgrade` (Node 20+) on a clean branch and review the diff.

| v3 | v4 |
|----|----|
| `@tailwind base; @tailwind components; @tailwind utilities;` | `@import "tailwindcss";` |
| `tailwind.config.js` `theme.extend` | `@theme { ... }` in CSS |
| `content: [...]` | Automatic detection; `@source` for extras |
| `safelist` | `@source inline(...)` |
| `darkMode: 'class'` | `@custom-variant dark (&:where(.dark, .dark *));` |
| `tailwindcss` PostCSS plugin, `autoprefixer` | `@tailwindcss/postcss` (prefixing built in) or `@tailwindcss/vite` |
| `@layer utilities { .x {} }` | `@utility x { }` |
| `@tailwindcss/container-queries` | Built in |
| `bg-[--brand]` | `bg-(--brand)` |
| `!flex` | `flex!` |
| `first:*:pt-0` (right to left) | `*:first:pt-0` (left to right) |
| `shadow-sm` / `shadow` | `shadow-xs` / `shadow-sm` (same for `blur`, `rounded`, `drop-shadow`) |
| `outline-none` | `outline-hidden` |
| `ring` (3px, blue) | `ring-3` and an explicit color; `ring` is 1px `currentColor` |
| `border` defaults to gray-200 | Defaults to `currentColor`; set `border-border` or a color |
| `theme('colors.red.500')`, `resolveConfig()` | `var(--color-red-500)`; `getComputedStyle` at runtime |
| Sass/Less with Tailwind | Not supported; plain CSS plus `@reference` |
| `hsl(var(--primary))` tokens | Full color in the variable, `@theme inline` mapping |
| `tailwindcss-animate` | `tw-animate-css` (`@import "tw-animate-css";`) |

Behavior changes to check visually: buttons use `cursor: default`, placeholders use 50% of the text color, `hover:` only applies on hover-capable devices, and `space-y-*` uses a new selector (prefer `flex flex-col gap-*`). Keep a JS config temporarily with `@config "../tailwind.config.js";` if a plugin has no v4 equivalent; `corePlugins` and `separator` are gone.

## Best Practices

- Keep one CSS entry file with `@import "tailwindcss";`, tokens, and base styles; do not import Tailwind in multiple files.
- Write complete class names; map props to classes instead of interpolating.
- Route every `className` merge through `cn()` and register custom token names with `extendTailwindMerge`.
- Prefer container queries for reusable components; reserve breakpoints for page layout.
- Use `focus-visible:` rings on every interactive element and gate motion with `motion-safe:` / `motion-reduce:`.
- Set the theme class before paint with an inline script or server-rendered class, never in an effect.
- Extract a component, not an `@apply` class, when a class list repeats; reserve `@apply` for third-party markup that cannot be changed.
