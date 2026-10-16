# Dark Mode

**Contents:** Choosing a Strategy · Media Strategy (Default) · Class Strategy · Data-Attribute Strategy · Toggle Without FOUC · Next.js with next-themes · Token Swapping with CSS Variables · color-scheme · Testing

Add `dark:` variants only when the project actually supports dark mode.

## Choosing a Strategy

| Strategy | Config | User can override OS? | Use when |
|----------|--------|-----------------------|----------|
| Media (default) | none | No | Follow OS only, no toggle |
| Class | `@custom-variant dark (&:where(.dark, .dark *));` | Yes | Manual toggle, most apps |
| Data attribute | `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));` | Yes | Multiple themes, or a framework that sets `data-theme` |

Pick one per project. Every example below applies one strategy only.

## Media Strategy (Default)

`dark:` maps to `@media (prefers-color-scheme: dark)`. No configuration.

```css
@import "tailwindcss";
```

```html
<div class="bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">
  <p class="text-gray-600 dark:text-gray-400">Secondary text</p>
</div>
```

## Class Strategy

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));
```

```html
<html class="dark">
  <body class="bg-white text-gray-900 dark:bg-gray-900 dark:text-gray-100">...</body>
</html>
```

`:where()` keeps specificity at zero, so `dark:` utilities do not outrank other utilities unexpectedly. Once this variant is defined, `dark:` no longer responds to the OS setting by itself; the script in Toggle Without FOUC applies the OS preference when the user has not chosen.

## Data-Attribute Strategy

```css
@import "tailwindcss";

@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));
```

```html
<html data-theme="dark">...</html>
```

Use the same toggle script as the class strategy, setting `document.documentElement.dataset.theme` instead of toggling a class.

## Toggle Without FOUC

The theme must be applied **before first paint**. Put a small blocking script inline in `<head>`, before stylesheets render. A script at the end of `<body>` or in a deferred bundle runs after paint and flashes the wrong theme.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script>
    (function () {
      try {
        var stored = localStorage.getItem('theme'); // 'light' | 'dark' | null (system)
        var dark = stored === 'dark' ||
          (stored === null && window.matchMedia('(prefers-color-scheme: dark)').matches);
        document.documentElement.classList.toggle('dark', dark);
      } catch (e) {}
    })();
  </script>
  <link rel="stylesheet" href="/app.css">
</head>
<body>
  <button type="button" id="theme-toggle" aria-pressed="false"
          class="inline-flex min-h-11 min-w-11 items-center justify-center">
    <span class="sr-only">Dark mode</span>
    <svg class="size-5" aria-hidden="true">...</svg>
  </button>
</body>
</html>
```

Toggle logic (can load normally, after paint), with light / dark / system support:

```js
const root = document.documentElement;
const media = window.matchMedia('(prefers-color-scheme: dark)');
const button = document.getElementById('theme-toggle');

function apply() {
  const stored = localStorage.getItem('theme');
  const dark = stored === 'dark' || (stored === null && media.matches);
  root.classList.toggle('dark', dark);
  button.setAttribute('aria-pressed', String(dark));
}

// 'light' | 'dark' | 'system'
function setTheme(theme) {
  if (theme === 'system') localStorage.removeItem('theme');
  else localStorage.setItem('theme', theme);
  apply();
}

button.addEventListener('click', () => {
  setTheme(root.classList.contains('dark') ? 'light' : 'dark');
});

// Follow OS changes only while the user has not chosen
media.addEventListener('change', () => {
  if (localStorage.getItem('theme') === null) apply();
});

apply();
```

For a three-way control, render a `<select>` or radio group (Light / Dark / System) that calls `setTheme`. Keyboard access and a visible focus style are required; see `accessibility.md`.

## Next.js with next-themes

`next-themes` injects the blocking head script itself.

```bash
npm install next-themes
```

```tsx
// app/providers.tsx
'use client';

import { ThemeProvider } from 'next-themes';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </ThemeProvider>
  );
}
```

```tsx
// app/layout.tsx
import { Providers } from './providers';
import './globals.css';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

```tsx
// components/theme-toggle.tsx
'use client';

import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return <span className="inline-block size-11" aria-hidden="true" />;

  const dark = resolvedTheme === 'dark';
  return (
    <button
      type="button"
      aria-pressed={dark}
      onClick={() => setTheme(dark ? 'light' : 'dark')}
      className="inline-flex min-h-11 min-w-11 items-center justify-center"
    >
      <span className="sr-only">Dark mode</span>
      {/* icon */}
    </button>
  );
}
```

`globals.css` needs the class strategy variant (`@custom-variant dark (&:where(.dark, .dark *));`). Use `attribute="data-theme"` with the data-attribute variant instead if preferred. The `mounted` guard avoids a hydration mismatch, since the server cannot know the theme.

## Token Swapping with CSS Variables

Define semantic color tokens once in `@theme`, then override the variables for dark mode. Components use `bg-surface text-fg` with no `dark:` variants at all.

Override the variables under **the same mechanism the project's strategy uses**. With the class strategy, override under `.dark` only. Do not also add a `@media (prefers-color-scheme: dark)` override: OS-dark users would then be unable to choose light mode, because the media query wins regardless of the toggle.

Class strategy:

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-surface: oklch(1 0 0);
  --color-surface-muted: oklch(0.97 0 0);
  --color-fg: oklch(0.2 0 0);
  --color-fg-muted: oklch(0.45 0 0);
  --color-border: oklch(0.9 0 0);
}

@layer base {
  .dark {
    --color-surface: oklch(0.18 0 0);
    --color-surface-muted: oklch(0.23 0 0);
    --color-fg: oklch(0.95 0 0);
    --color-fg-muted: oklch(0.72 0 0);
    --color-border: oklch(0.32 0 0);
  }
}
```

Media strategy (no toggle; replaces the `.dark` block above and omits the `@custom-variant`):

```css
@layer base {
  @media (prefers-color-scheme: dark) {
    :root {
      --color-surface: oklch(0.18 0 0);
      --color-fg: oklch(0.95 0 0);
    }
  }
}
```

```html
<div class="border border-border bg-surface text-fg">
  <p class="text-fg-muted">Semantic tokens, no dark: variants</p>
</div>
```

These tokens hold literal values in plain `@theme`, so utilities reference `var(--color-surface)` and the `.dark` override applies. If the tokens instead live in `@theme inline` as aliases (`--color-surface: var(--surface)`), override the raw variable (`--surface`) under `.dark`; overriding an inline `--color-*` variable under a selector does not affect utilities. Prefer token utilities (`bg-surface`) over `bg-[var(--color-surface)]`.

Typography plugin: `prose dark:prose-invert`.

Contrast must pass in both themes: 4.5:1 for body text, 3:1 for large text and UI component boundaries (WCAG 2.2). Do not use pure black backgrounds with pure white text; soften both.

## color-scheme

Set `color-scheme` so native UI (scrollbars, form controls, date pickers, default canvas) matches the theme.

```html
<!-- Class or data-attribute strategy -->
<html class="scheme-light dark:scheme-dark">
```

```css
/* Media strategy */
:root { color-scheme: light dark; }
```

`scheme-light-dark` is the utility equivalent of `color-scheme: light dark`. Also set `<meta name="theme-color">` per scheme for mobile browser chrome when relevant:

```html
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#111111" media="(prefers-color-scheme: dark)">
```

## Testing

- [ ] Reload in dark mode with throttled CPU: no light flash (head script runs before paint)
- [ ] Toggle persists across reloads and pages
- [ ] With no stored choice, OS changes are followed; after an explicit choice, they are not
- [ ] OS set to dark, user chooses light: page is fully light (no leftover media-query overrides)
- [ ] Native controls and scrollbars match (`color-scheme`)
- [ ] Contrast checked in both themes, including focus rings, borders, and disabled states
- [ ] Toggle reachable by keyboard and announces its state (`aria-pressed` or labelled radio group)
- [ ] Emulate in DevTools: Rendering panel, "Emulate CSS prefers-color-scheme"
- [ ] `bash <skill-dir>/scripts/check-dark-mode.sh` for coverage
