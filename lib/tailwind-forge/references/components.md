# Tailwind CSS Component Patterns

**Contents:** The cn() Helper · Button · Card · Input · Polymorphic Components · Data Attribute Variants · Group and Peer Patterns · Component Classes with @apply · Headless Library Integration · Loading and Entrance Animations · Shared Focus Utility

Canonical component examples for the skill. Other reference files point here instead of repeating them. Before using any example, replace the palette, radius, and spacing with the project's existing `@theme` tokens and component conventions. Examples use React 19 (`ref` is a regular prop, so no `forwardRef`).

## The cn() Helper

```bash
npm install clsx tailwind-merge
```

```ts
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

`clsx` handles conditionals; `tailwind-merge` resolves conflicts so a caller's `className="px-6"` overrides the component's `px-4`. Add it once the project has components that accept `className`; do not add it for a single static element.

## Button

A shared button with a small variant set. Use `class-variance-authority` only when the component is part of a shared library with several variant axes; for a one-off button, write the classes inline.

```bash
npm install class-variance-authority
```

```tsx
// components/ui/button.tsx
import { cva, type VariantProps } from 'class-variance-authority';
import type { ComponentProps } from 'react';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 rounded-md font-medium transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-brand-500 text-white hover:bg-brand-600',
        secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        ghost: 'text-gray-700 hover:bg-gray-100',
        destructive: 'bg-red-600 text-white hover:bg-red-700 focus-visible:outline-red-600',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-sm',
        icon: 'size-10',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
);

type ButtonProps = ComponentProps<'button'> & VariantProps<typeof buttonVariants>;

export function Button({ className, variant, size, type = 'button', ...props }: ButtonProps) {
  return (
    <button
      type={type}
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  );
}
```

```tsx
<Button>Save</Button>
<Button variant="ghost" size="icon" aria-label="Open menu"><MenuIcon aria-hidden="true" /></Button>
```

Keep only the variants the design actually uses. To render a link styled as a button, apply `buttonVariants()` to the `<a>` (or router `Link`) directly: `<a href="/docs" className={buttonVariants({ variant: 'secondary' })}>Docs</a>`.

## Card

```tsx
// components/ui/card.tsx
import type { ComponentProps } from 'react';
import { cn } from '@/lib/utils';

export function Card({ className, ...props }: ComponentProps<'div'>) {
  return <div className={cn('rounded-lg border border-gray-200 bg-white', className)} {...props} />;
}

export function CardHeader({ className, ...props }: ComponentProps<'div'>) {
  return <div className={cn('flex flex-col gap-1.5 p-6 pb-0', className)} {...props} />;
}

export function CardTitle({ className, ...props }: ComponentProps<'h3'>) {
  return <h3 className={cn('text-lg font-semibold text-gray-900', className)} {...props} />;
}

export function CardDescription({ className, ...props }: ComponentProps<'p'>) {
  return <p className={cn('text-sm text-gray-600', className)} {...props} />;
}

export function CardContent({ className, ...props }: ComponentProps<'div'>) {
  return <div className={cn('p-6', className)} {...props} />;
}

export function CardFooter({ className, ...props }: ComponentProps<'div'>) {
  return <div className={cn('flex items-center gap-2 p-6 pt-0', className)} {...props} />;
}
```

```tsx
<Card>
  <CardHeader>
    <CardTitle>Account settings</CardTitle>
    <CardDescription>Manage your account preferences.</CardDescription>
  </CardHeader>
  <CardContent>{/* form */}</CardContent>
  <CardFooter className="justify-end">
    <Button variant="ghost">Cancel</Button>
    <Button>Save changes</Button>
  </CardFooter>
</Card>
```

## Input

Label, hint, and error wired with `aria-describedby` and `aria-invalid`; the error styling keys off the ARIA attribute instead of a separate class branch.

```tsx
// components/ui/input.tsx
import { useId, type ComponentProps } from 'react';
import { cn } from '@/lib/utils';

type InputProps = ComponentProps<'input'> & {
  label: string;
  hint?: string;
  error?: string;
};

export function Input({ label, hint, error, id, className, ...props }: InputProps) {
  const autoId = useId();
  const inputId = id ?? autoId;
  const hintId = `${inputId}-hint`;
  const errorId = `${inputId}-error`;

  return (
    <div className="space-y-1">
      <label htmlFor={inputId} className="block text-sm font-medium text-gray-700">
        {label}
      </label>
      <input
        id={inputId}
        aria-invalid={error ? true : undefined}
        aria-describedby={[hint && hintId, error && errorId].filter(Boolean).join(' ') || undefined}
        className={cn(
          'block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder:text-gray-500',
          'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500',
          'aria-[invalid=true]:border-red-600 aria-[invalid=true]:focus-visible:outline-red-600',
          'disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        {...props}
      />
      {hint && <p id={hintId} className="text-sm text-gray-600">{hint}</p>}
      {error && <p id={errorId} className="text-sm text-red-700">{error}</p>}
    </div>
  );
}
```

## Polymorphic Components

An `as` prop lets one component render different elements while keeping element-specific props typed. With React 19, `ComponentProps<C>` already includes `ref`.

```tsx
// components/ui/text.tsx
import type { ComponentProps, ElementType } from 'react';
import { cn } from '@/lib/utils';

const sizes = { sm: 'text-sm', base: 'text-base', lg: 'text-lg', xl: 'text-xl' } as const;
const tones = { default: 'text-gray-900', muted: 'text-gray-600' } as const;

type TextProps<C extends ElementType> = {
  as?: C;
  size?: keyof typeof sizes;
  tone?: keyof typeof tones;
} & Omit<ComponentProps<C>, 'as'>;

export function Text<C extends ElementType = 'span'>({
  as,
  size = 'base',
  tone = 'default',
  className,
  ...props
}: TextProps<C>) {
  const Component = as ?? 'span';
  return <Component className={cn(sizes[size], tones[tone], className)} {...props} />;
}
```

```tsx
<Text as="p" tone="muted">Muted paragraph</Text>
<Text as="label" htmlFor="email" size="sm">Email</Text>
```

## Data Attribute Variants

v4 ships `data-*` variants. Use them directly; never redefine them with `@custom-variant`.

- `data-[state=open]:` matches `[data-state="open"]`
- `data-highlighted:` matches the presence of `[data-highlighted]`
- `group-data-[state=open]:` and `peer-data-[state=open]:` react to an ancestor or sibling

```tsx
function DropdownItem({ highlighted, disabled, children }: {
  highlighted?: boolean;
  disabled?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div
      role="menuitem"
      data-highlighted={highlighted || undefined}
      data-disabled={disabled || undefined}
      className="flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-hidden data-highlighted:bg-gray-100 data-disabled:pointer-events-none data-disabled:opacity-50"
    >
      {children}
    </div>
  );
}
```

`outline-hidden` is fine here because the highlighted background is the visible focus indicator, and `outline-hidden` still shows an outline in forced-colors mode.

Enter/exit animations keyed to `data-state` (the pattern Radix emits) use `tw-animate-css`:

```css
@import "tailwindcss";
@import "tw-animate-css"; /* npm install tw-animate-css; replaces tailwindcss-animate */
```

```html
<div
  data-state="open"
  data-side="bottom"
  class="rounded-md border border-gray-200 bg-white p-1 shadow-md data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[side=bottom]:slide-in-from-top-2 data-[side=top]:slide-in-from-bottom-2"
>
  ...
</div>
```

## Group and Peer Patterns

```html
<!-- Group: a hover/focus on the parent styles children. Pair hover with focus-visible. -->
<a href="/post" class="group block rounded-md p-4 hover:bg-gray-50 focus-visible:outline-2 focus-visible:outline-brand-500">
  <h3 class="font-semibold text-gray-900 group-hover:underline group-focus-visible:underline">Title</h3>
  <p class="text-gray-600">Description</p>
</a>

<!-- Named groups for nesting -->
<div class="group/card">
  <div class="group/header">
    <button class="group-hover/header:text-brand-600">Header action</button>
  </div>
  <div class="group-hover/card:bg-gray-50">Card content</div>
</div>

<!-- Peer: sibling state styles a later sibling -->
<div class="relative">
  <input id="email" type="email" placeholder=" " class="peer w-full rounded-md border border-gray-300 px-3 pt-5 pb-2" />
  <label for="email" class="absolute left-3 top-1 text-xs text-gray-600 peer-placeholder-shown:top-3.5 peer-placeholder-shown:text-base peer-focus:top-1 peer-focus:text-xs">
    Email address
  </label>
</div>

<!-- Peer for validation (shows after the user edits, via :user-invalid; user-invalid: is v4.1+) -->
<div>
  <input type="email" required class="peer rounded-md border border-gray-300 px-3 py-2 user-invalid:border-red-600" />
  <p class="hidden text-sm text-red-700 peer-user-invalid:block">Enter a valid email.</p>
</div>
```

`peer-*` only targets later siblings, so the peer element must come first in the DOM.

Decorative image overlays (gradient fade, zoom on hover, sliding captions) are only appropriate when the design explicitly calls for them.

## Component Classes with @apply

When markup cannot carry utilities (CMS output, third-party HTML), group them in `@layer components`. Variants work inside `@apply`.

```css
@layer components {
  .dialog-overlay {
    @apply fixed inset-0 bg-black/50;
  }

  .dialog-content {
    @apply fixed top-1/2 left-1/2 w-full max-w-lg -translate-1/2 rounded-lg bg-white p-6 shadow-lg;
  }

  .dialog-title {
    @apply text-lg font-semibold text-gray-900;
  }

  .dialog-close {
    @apply absolute top-4 right-4 rounded-sm text-gray-600 hover:text-gray-900;
    @apply focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500;
  }
}
```

In Vue/Svelte/CSS-module `<style>` blocks, add `@reference "../app.css";` (path to the main stylesheet) before using `@apply`.

## Headless Library Integration

### Headless UI v2 Dialog

v2 replaces `Transition`/`Transition.Child` and dot-notation components with named exports and a `transition` prop. Style the hidden state with `data-closed:`.

```tsx
import { Dialog, DialogBackdrop, DialogPanel, DialogTitle } from '@headlessui/react';

export function Modal({ open, onClose, title, children }: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <DialogBackdrop
        transition
        className="fixed inset-0 bg-black/30 duration-200 ease-out data-closed:opacity-0"
      />
      <div className="fixed inset-0 flex w-screen items-center justify-center p-4">
        <DialogPanel
          transition
          className="w-full max-w-md rounded-lg bg-white p-6 duration-200 ease-out data-closed:scale-95 data-closed:opacity-0 motion-reduce:transition-none"
        >
          <DialogTitle className="text-lg font-semibold text-gray-900">{title}</DialogTitle>
          <div className="mt-2">{children}</div>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
```

### Radix UI Dropdown Menu

Radix sets `data-state`, `data-side`, and `data-highlighted`; style them with built-in `data-*` variants. The animation classes need `tw-animate-css`.

```tsx
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';

export function OptionsMenu() {
  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger className="inline-flex items-center gap-2 rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium hover:bg-gray-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500">
        Options
        <ChevronDownIcon aria-hidden="true" className="size-4" />
      </DropdownMenu.Trigger>

      <DropdownMenu.Portal>
        <DropdownMenu.Content
          sideOffset={4}
          className="min-w-48 rounded-md border border-gray-200 bg-white p-1 shadow-md data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[side=bottom]:slide-in-from-top-2 data-[side=top]:slide-in-from-bottom-2"
        >
          <DropdownMenu.Item className="flex cursor-default select-none items-center rounded-sm px-2 py-2 text-sm outline-hidden data-highlighted:bg-gray-100">
            Profile
          </DropdownMenu.Item>
          <DropdownMenu.Separator className="my-1 h-px bg-gray-200" />
          <DropdownMenu.Item className="flex cursor-default select-none items-center rounded-sm px-2 py-2 text-sm text-red-700 outline-hidden data-highlighted:bg-red-50">
            Delete
          </DropdownMenu.Item>
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}
```

## Loading and Entrance Animations

### Skeleton

```tsx
import type { ComponentProps } from 'react';
import { cn } from '@/lib/utils';

export function Skeleton({ className, ...props }: ComponentProps<'div'>) {
  return (
    <div
      aria-hidden="true"
      className={cn('animate-pulse rounded-md bg-gray-200 motion-reduce:animate-none', className)}
      {...props}
    />
  );
}
```

```tsx
<div role="status" className="space-y-2">
  <span className="sr-only">Loading…</span>
  <Skeleton className="h-4 w-48" />
  <Skeleton className="h-3 w-full" />
  <Skeleton className="h-3 w-3/4" />
</div>
```

### Staggered List (only when requested)

Requires `tw-animate-css`.

```tsx
function StaggeredList({ items }: { items: { id: string; content: string }[] }) {
  return (
    <ul className="space-y-2">
      {items.map((item, index) => (
        <li
          key={item.id}
          className="animate-in fade-in-0 slide-in-from-left-4 motion-reduce:animate-none"
          style={{ animationDelay: `${index * 75}ms` }}
        >
          {item.content}
        </li>
      ))}
    </ul>
  );
}
```

## Shared Focus Utility

When many custom elements need the same focus indicator, define one shared `focus-ring` utility instead of repeating the classes. See the canonical `focus-ring` / `focus-ring-inset` definitions and outline guidance in accessibility.md (Focus Management).
