# Tailwind CSS Component Creation

**Contents:** 1. Inspect the Project · 2. Define the Minimal API · 3. Write the Component · 4. Accessibility Checklist · 5. Dark Mode (Only If the Project Uses It) · Output

Steps for building a new component. Full canonical examples (`Button`, `Card`, `Input`, polymorphic `Text`, headless integrations) and the single `cn()` helper are in `components.md`.

## 1. Inspect the Project

Infer before asking. Check:

- **Existing components**: Does the component (or a near match) already exist in `components/`, `ui/`, or a library like shadcn/ui, Headless UI, or Radix? Extend it instead of rebuilding.
- **Tokens**: Read the main CSS file's `@theme` block for colors, radius, spacing, and fonts. Use those utilities (`bg-brand-500`, `rounded-md`) rather than defaults or `[#hex]` values.
- **Conventions**: Match the radius, border, and shadow levels, the class-merging helper (`cn()` or none), the file naming, and the prop style used by sibling components.
- **Framework and React version**: React 19 takes `ref` as a prop; React 18 needs `forwardRef`. Vue, Svelte, or plain HTML change the starter accordingly.
- **Dark mode**: Look for `@custom-variant dark`, existing `dark:` classes, or a theme provider.

Ask the user only about what cannot be inferred, such as which variants are needed or the intended behavior.

## 2. Define the Minimal API

- Implement only the variants and sizes the user asked for or the design shows.
- Accept `className` and spread remaining native props so callers can extend the element.
- Do not declare props that are not implemented (for example `asChild` without a Slot implementation).
- Use a variant library (`class-variance-authority`) only for shared components with several variant axes; one-offs get inline classes.

## 3. Write the Component

Start from the closest canonical example in `components.md`. Minimal starter when nothing similar exists (replace the palette, radius, and spacing with project tokens):

```tsx
// components/ui/card.tsx
import type { ComponentProps } from 'react';
import { cn } from '@/lib/utils';

type CardProps = ComponentProps<'section'> & {
  title?: string;
  footer?: React.ReactNode;
};

export function Card({ title, footer, className, children, ...props }: CardProps) {
  return (
    <section className={cn('rounded-lg border border-gray-200 bg-white', className)} {...props}>
      {title && (
        <h3 className="border-b border-gray-200 px-6 py-4 text-lg font-semibold text-gray-900">{title}</h3>
      )}
      <div className="p-6">{children}</div>
      {footer && <div className="border-t border-gray-200 px-6 py-4">{footer}</div>}
    </section>
  );
}
```

Rules while writing:

- Use semantic elements (`button`, `a`, `section`, `label`) before adding ARIA.
- Visible focus: `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-<token>`. Never `outline-none` alone.
- Pair every hover-only effect with a focus or keyboard equivalent.
- Add transitions, shadows, and hover effects only when the design calls for them; prefer `transition-colors` over `transition-all`.
- Use complete class names; never build them with string interpolation.

## 4. Accessibility Checklist

- [ ] Semantic HTML element for the role
- [ ] Visible `focus-visible` indicator using an outline (survives forced-colors mode)
- [ ] Accessible name on icon-only controls (`aria-label` or `sr-only` text)
- [ ] Keyboard operable; state exposed via `aria-expanded`, `aria-pressed`, `aria-selected`, or `aria-invalid`
- [ ] Text contrast at least 4.5:1 (3:1 for large text and UI boundaries)
- [ ] Target size at least 24×24 CSS px (`min-h-6 min-w-6`); 44×44 (`min-h-11 min-w-11`) for primary touch targets
- [ ] Motion wrapped with `motion-reduce:` fallbacks

Details in `accessibility.md`.

## 5. Dark Mode (Only If the Project Uses It)

Add `dark:` variants only if the project already uses dark mode (`@custom-variant dark` in the CSS, existing `dark:` classes, or semantic tokens that switch per theme). If the project uses semantic tokens (`bg-surface`, `text-fg`), use those and add no `dark:` classes at all. See `dark-mode.md`.

## Output

Provide:

1. Component code with TypeScript types, matching project tokens and conventions
2. Only the variants and sizes the user asked for
3. `dark:` variants only if the project uses dark mode
4. Accessibility features from the checklist
5. A short usage example
