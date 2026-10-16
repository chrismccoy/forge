# React + Tailwind Patterns

**Contents:** Server and Client Components · Refs as Props (React 19) · Styling State with data-* and aria-* · Dynamic Class Names · Hooks · Layout Components

React-only topics. The canonical `Button`, `Card`, `Input`, and `cn()` helper are in `components.md`; framework installation is in `frameworks.md`; theme switching (including `next-themes`) is in `dark-mode.md`.

## Server and Client Components

Tailwind generates CSS at build time from class strings, so utilities work identically in Server and Client Components. The client boundary is about interactivity, not styling.

- Keep components that only render markup as Server Components.
- Add `'use client'` only to the smallest component that needs state, effects, or event handlers.
- Pass `className` and `children` through client components so server-rendered content and styling stay on the server side.
- Prefer CSS variants (`hover:`, `open:`, `peer-checked:`, `group-aria-expanded:`) over client state when the browser already tracks the state.

```tsx
// app/faq/page.tsx (Server Component)
import { Disclosure } from './disclosure';

export default function FaqPage() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900">FAQ</h1>
      <Disclosure title="Do you ship internationally?" className="mt-6">
        <p className="text-gray-700">Yes, to most countries.</p>
      </Disclosure>
    </main>
  );
}
```

```tsx
// app/faq/disclosure.tsx
'use client';

import { useId, useState } from 'react';
import { cn } from '@/lib/utils';

export function Disclosure({ title, className, children }: {
  title: string;
  className?: string;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const panelId = useId();

  return (
    <div className={cn('border-b border-gray-200', className)}>
      <button
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen(!open)}
        className="group flex w-full items-center justify-between py-3 text-left font-medium focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500"
      >
        {title}
        <ChevronDownIcon aria-hidden="true" className="size-4 transition-transform group-aria-expanded:rotate-180 motion-reduce:transition-none" />
      </button>
      <div id={panelId} hidden={!open} className="pb-4">
        {children}
      </div>
    </div>
  );
}
```

For a disclosure with no other logic, native `<details>`/`<summary>` with the `open:` variant needs no client component at all.

## Refs as Props (React 19)

React 19 passes `ref` as a normal prop to function components. Do not wrap new components in `forwardRef`, and drop `displayName` boilerplate.

```tsx
import { useRef, type ComponentProps } from 'react';
import { cn } from '@/lib/utils';

export function Textarea({ className, ...props }: ComponentProps<'textarea'>) {
  return (
    <textarea
      className={cn(
        'block w-full rounded-md border border-gray-300 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500',
        className
      )}
      {...props}
    />
  );
}
```

```tsx
// Usage: ref flows through ...props
function CommentBox() {
  const ref = useRef<HTMLTextAreaElement>(null);
  return <Textarea ref={ref} rows={4} onFocus={() => ref.current?.select()} />;
}
```

`ComponentProps<'textarea'>` includes `ref` in React 19. Projects still on React 18 need `forwardRef`.

## Styling State with data-* and aria-*

Expose component state as attributes and style it with built-in variants. This avoids branching class strings in JavaScript, keeps the accessible state and the visual state in sync, and lets parents react via `group-*`/`peer-*`.

```tsx
'use client';

import { useState } from 'react';

export function Switch({ label }: { label: string }) {
  const [on, setOn] = useState(false);

  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      onClick={() => setOn(!on)}
      className="group inline-flex h-6 w-11 items-center rounded-full bg-gray-300 p-0.5 aria-checked:bg-brand-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500"
    >
      <span className="sr-only">{label}</span>
      <span aria-hidden="true" className="size-5 rounded-full bg-white transition-transform group-aria-checked:translate-x-5 motion-reduce:transition-none" />
    </button>
  );
}
```

| State source | Attribute | Variant |
| --- | --- | --- |
| Expanded/collapsed | `aria-expanded` | `aria-expanded:`, `group-aria-expanded:` |
| Selected tab | `aria-selected` | `aria-selected:` |
| Toggle | `aria-pressed`, `aria-checked` | `aria-pressed:`, `aria-checked:` |
| Loading | `aria-busy` | `aria-busy:`, `group-aria-busy:` |
| Custom UI state | `data-state="open"` | `data-[state=open]:` |
| Boolean flag | `data-active` | `data-active:` |

Use `aria-*` when an ARIA attribute already describes the state; use `data-*` for purely visual state.

## Dynamic Class Names

Tailwind detects classes by scanning source text, so it never sees classes built at runtime.

```tsx
// Wrong: bg-red-500 / bg-green-500 never appear in source
<span className={`bg-${color}-500`} />

// Right: map props to complete class names
const tone = {
  danger: 'bg-red-100 text-red-800',
  success: 'bg-green-100 text-green-800',
} as const;

<span className={tone[status]} />
```

For truly runtime values (user-chosen colors, measured sizes), set a CSS variable inline and consume it with the `(--var)` shorthand:

```tsx
<div style={{ '--progress': `${pct}%` } as React.CSSProperties} className="h-2 w-(--progress) rounded-full bg-brand-500" />
```

## Hooks

Reach for a hook only when JavaScript must know the state (rendering different trees, not just different styles). For styling alone, use responsive and media variants (`md:`, `motion-reduce:`, `forced-colors:`).

```ts
// hooks/use-media-query.ts
import { useSyncExternalStore } from 'react';

export function useMediaQuery(query: string, serverDefault = false) {
  return useSyncExternalStore(
    (onChange) => {
      const mql = window.matchMedia(query);
      mql.addEventListener('change', onChange);
      return () => mql.removeEventListener('change', onChange);
    },
    () => window.matchMedia(query).matches,
    () => serverDefault
  );
}
```

```tsx
// Match Tailwind's md breakpoint (48rem by default, or the project's --breakpoint-md)
const isDesktop = useMediaQuery('(min-width: 48rem)');
const reduceMotion = useMediaQuery('(prefers-reduced-motion: reduce)');
```

`serverDefault` is the value rendered on the server; the client re-renders with the real value after hydration.

## Layout Components

```tsx
// components/layout/container.tsx
import type { ComponentProps } from 'react';
import { cn } from '@/lib/utils';

const widths = {
  sm: 'max-w-2xl',
  md: 'max-w-3xl',
  lg: 'max-w-5xl',
  xl: 'max-w-7xl',
  full: 'max-w-full',
} as const;

export function Container({
  size = 'lg',
  className,
  ...props
}: ComponentProps<'div'> & { size?: keyof typeof widths }) {
  return <div className={cn('mx-auto w-full px-4 sm:px-6 lg:px-8', widths[size], className)} {...props} />;
}
```

v4 removed `max-w-screen-*`. Use the container scale (`max-w-3xs` to `max-w-7xl`) or, to match a breakpoint exactly, `max-w-(--breakpoint-md)`.
