# Advanced @theme Patterns

**Contents:** Theme Variable Namespaces · Overriding and Resetting Defaults · @theme inline · @theme static · Sharing Themes Across Projects · Semantic Color Tokens · Runtime Theme Switching · Responsive Theme Values · Typography Scale · Prefix Isolation · Brand Variants · Motion Tokens

## Theme Variable Namespaces

Only variables in these namespaces generate utilities or variants. Any other variable inside `@theme` is just a CSS variable.

| Namespace | Generates |
|-----------|-----------|
| `--color-*` | Color utilities: `bg-*`, `text-*`, `border-*`, `fill-*`, `text-shadow-*` colors (v4.1+), etc. |
| `--font-*` | Font family: `font-sans` |
| `--text-*` | Font size: `text-xl` |
| `--font-weight-*` | Font weight: `font-bold` |
| `--tracking-*` | Letter spacing: `tracking-wide` |
| `--leading-*` | Line height: `leading-tight` |
| `--tab-size-*` | Not a core namespace. Core `tab-*` (v4.3+) reads no theme key: it takes positive integers (`tab-4`), `tab-[<value>]`, or `tab-(<custom-property>)`. For named values, pass a variable (`tab-(--tab-code)`); do not redefine `tab-*` |
| `--breakpoint-*` | Responsive variants: `sm:*` |
| `--container-*` | Container query variants `@sm:*` and sizes like `max-w-md` |
| `--spacing-*` | Spacing and sizing: `px-4`, `max-h-16` |
| `--radius-*` | Border radius: `rounded-sm` |
| `--shadow-*` | Box shadow: `shadow-md` |
| `--inset-shadow-*` | Inset shadow: `inset-shadow-xs` |
| `--drop-shadow-*` | Drop shadow filter: `drop-shadow-md` |
| `--text-shadow-*` | Text shadow (v4.1+): `text-shadow-sm` |
| `--blur-*` | Blur filter: `blur-md` |
| `--perspective-*` | Perspective: `perspective-near` |
| `--aspect-*` | Aspect ratio: `aspect-video` |
| `--ease-*` | Timing function: `ease-out` |
| `--animate-*` | Animation: `animate-spin` |

There is no `--duration-*` or `--z-*` namespace. `duration-*` and `z-*` take bare numbers (`duration-150`, `z-40`) or arbitrary values (`z-(--z-modal)`).

## Overriding and Resetting Defaults

Override one value by redefining it. Add a value by defining a new key:

```css
@theme {
  --breakpoint-sm: 36rem;          /* override default */
  --color-midnight: oklch(0.2 0.05 270); /* add bg-midnight etc. */
}
```

Remove a whole default namespace with `initial`, then define only the values the project uses:

```css
@theme {
  --color-*: initial;
  --color-white: #fff;
  --color-midnight: oklch(0.2 0.05 270);
}
```

`bg-red-500` and the other defaults in that namespace no longer exist.

Disable the entire default theme:

```css
@theme {
  --*: initial;

  --spacing: 0.25rem;
  --font-sans: Inter, sans-serif; /* keep the name: preflight reads it via --default-font-family */
  --color-primary: oklch(0.72 0.11 221.19);
}
```

## @theme inline

When a theme variable references another variable, use `inline`. Utilities then use the resolved value instead of `var(--color-primary)`, which avoids resolution surprises when the referenced variable is defined on a different element.

```css
@theme inline {
  --font-sans: var(--font-inter);
  --color-primary: var(--color-blue-500);
}
```

How each mode resolves, and how theme switching works with it:

- Plain `@theme`: utilities reference the theme variable (`background-color: var(--color-surface)`). Overriding `--color-surface` under `.dark` or `[data-theme]` updates utilities.
- `@theme inline`: utilities get the token's value inlined (`background-color: var(--surface)`). Required when the value is `var(--x)`; otherwise the reference resolves at the wrong scope. Switch themes by overriding the raw variable (`--surface`) under `.dark` or `[data-theme]`. Overriding the inline `--color-*` variable itself under a selector does not affect utilities.
- Runtime changes to raw variables referenced by inline tokens (for example `--brand-hue` set from JavaScript) do work.

```css
:root { --surface: oklch(0.99 0 0); }
.dark { --surface: oklch(0.15 0.01 260); }   /* override the raw variable */

@theme inline {
  --color-surface: var(--surface);
}
```

## @theme static

By default, only theme variables that are used end up in the CSS output. `static` emits every variable. Use it when JavaScript or inline styles read variables that no class references; it increases output size.

```css
@theme static {
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 180);
}
```

## Sharing Themes Across Projects

Put theme variables in their own file and import it. Works for monorepo packages and published npm packages.

```css
/* packages/brand/theme.css */
@theme {
  --color-brand-500: oklch(0.58 0.2 250);
  --font-display: "Satoshi", sans-serif;
}
```

```css
/* packages/admin/app.css */
@import "tailwindcss";
@import "../brand/theme.css";
```

## Semantic Color Tokens

Layer raw palette → semantic → component tokens. Aliases reference other variables, so they go in `@theme inline`. To retheme, override the referenced palette variables (`--color-blue-500`), not the aliases:

```css
@theme {
  --color-blue-500: oklch(0.55 0.2 250);
  --color-blue-600: oklch(0.48 0.2 250);
  --color-slate-100: oklch(0.95 0.01 260);
  --color-slate-900: oklch(0.15 0.01 260);
}

@theme inline {
  --color-primary: var(--color-blue-500);
  --color-primary-hover: var(--color-blue-600);
  --color-background: var(--color-slate-100);
  --color-foreground: var(--color-slate-900);
}
```

```html
<button class="bg-primary hover:bg-primary-hover text-white">Save</button>
```

## Runtime Theme Switching

Define tokens with literal values in `@theme`, then override the variables under a selector. Utilities reference the variable, so they update automatically. Only if the project uses dark mode:

```css
@theme {
  --color-surface: oklch(0.99 0 0);
  --color-on-surface: oklch(0.15 0 0);
  --color-border: oklch(0.9 0 0);
}

@custom-variant dark (&:where(.dark, .dark *));

.dark {
  --color-surface: oklch(0.15 0.01 260);
  --color-on-surface: oklch(0.95 0 0);
  --color-border: oklch(0.25 0.01 260);
}
```

```html
<div class="bg-surface text-on-surface border border-border">No dark: classes needed</div>
```

## Responsive Theme Values

Override theme variables inside media queries. `theme()` is valid inside media query conditions:

```css
@theme {
  --spacing-gutter: 1rem;
  --text-hero: 2rem;
}

@media (width >= theme(--breakpoint-md)) {
  :root {
    --spacing-gutter: 2rem;
    --text-hero: 3rem;
  }
}
```

`px-gutter` and `text-hero` change at `md` without responsive classes. For `clamp()`-based fluid values see responsive.md.

## Typography Scale

Pair each size with a line height using the `--text-*--line-height` sub-key (also `--letter-spacing`, `--font-weight`):

```css
@theme {
  --text-sm: 0.875rem;
  --text-sm--line-height: 1.25rem;

  --text-base: 1rem;
  --text-base--line-height: 1.5rem;

  --text-lg: 1.25rem;
  --text-lg--line-height: 1.75rem;

  --text-display: 3rem;
  --text-display--line-height: 1.1;
  --text-display--letter-spacing: -0.02em;
}
```

## Prefix Isolation

Prefix utilities and variables to avoid conflicts when embedding in another site:

```css
@import "tailwindcss" prefix(app);

@theme {
  --color-brand: oklch(0.6 0.2 250);
}
```

```html
<div class="app:flex app:bg-brand app:p-4">Content</div>
```

## Brand Variants

Override palette variables per brand with an attribute selector. Keep the base tokens non-inline so utilities follow the override:

```css
@theme {
  --color-primary-50: oklch(0.97 0.02 250);
  --color-primary-500: oklch(0.55 0.2 250);
  --color-primary-900: oklch(0.2 0.1 250);
}

@layer base {
  :root[data-brand="acme"] {
    --color-primary-50: oklch(0.97 0.03 150);
    --color-primary-500: oklch(0.55 0.2 150);
    --color-primary-900: oklch(0.2 0.12 150);
  }
}
```

## Motion Tokens

`--ease-*` and `--animate-*` are theme namespaces. Put `@keyframes` inside `@theme` so they are emitted with the animation:

```css
@theme {
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);

  --animate-fade-in: fade-in 200ms cubic-bezier(0, 0, 0.2, 1);

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
}
```

```html
<div class="animate-fade-in motion-reduce:animate-none">Loaded</div>
<button class="transition-colors duration-150 ease-snappy">Save</button>
```

Durations are not theme tokens. Use bare values (`duration-150`), or plain variables with the arbitrary shorthand when a named scale is required:

```css
:root {
  --duration-fast: 150ms;
  --duration-slow: 300ms;
}
```

```html
<div class="transition-opacity duration-(--duration-fast)">...</div>
```
