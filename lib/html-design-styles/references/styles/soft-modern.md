# Soft Modern Style

Clean white design with soft blurred orb backgrounds, generous rounding, and accessible color palette. Trustworthy and friendly. Use when asked for "soft modern style".

## Typography

Default Tailwind font stack (system-ui). Headlines `font-extrabold tracking-tight`. Labels `font-semibold`. Body `text-slate-600 leading-relaxed`.

## Colors

```
Background:   #ffffff
Text:         #0f172a (slate-900)
Muted:        #64748b (slate-500)
Primary:      #2563EB (blue-600)
Accent:       #EC4899 (pink-500)
Border:       #e2e8f0 (slate-200)
Shadow:       0 10px 30px rgba(2,6,23,0.10)
```

## Background Orbs

Place large blurred circles for depth. No hard shapes:

```html
<div class="absolute -left-24 -top-24 size-80 rounded-full bg-blue-500/15 blur-3xl"></div>
<div class="absolute -right-24 top-24 size-80 rounded-full bg-pink-500/15 blur-3xl"></div>
```

## Cards

`rounded-2xl border border-slate-200 bg-white shadow-sm hover:shadow-md transition-shadow`. No hard borders or offset shadows. Subtle hover elevation only.

## Buttons

```css
.btn-primary { background: #EC4899; color: #fff; rounded-xl; padding: 12px 24px; font-weight: 600; shadow-soft; }
.btn-primary:hover { filter: brightness(1.1); }
.btn-secondary { border: 1px solid #e2e8f0; background: #fff; color: #0f172a; rounded-2xl; }
/* Always include focus-visible ring: focus-visible:ring-2 focus-visible:ring-[brand] focus-visible:ring-offset-2 */
```

## Header

`sticky top-0 border-b border-slate-200/70 bg-white/80 backdrop-blur`. Logo with rounded-xl icon. Plain text nav links. Pink rounded-xl CTA. Mobile: `<details>/<summary>` for menu, `rounded-2xl border border-slate-200 shadow-soft` dropdown.

## Small Trust Chips (below hero)

`rounded-2xl border border-slate-200 bg-white p-4 shadow-sm` - 3-column grid with bold heading + muted subtext.

## Feature List Items

`flex gap-3` with small `rounded-full` check circle in blue or pink, semibold text.

## Accessibility

- Skip link: `sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4`
- All interactive elements: `focus-visible:outline-none focus-visible:ring-2`
- `aria-label` on icon buttons and logo links
- `role="menu"` on mobile dropdown

## Implementation

- No custom fonts needed - system font stack reads as clean and trusted
- Use `prefers-reduced-motion` media query: `* { scroll-behavior: auto !important; transition: none !important; animation: none !important; }`
- Max-width: `max-w-6xl` (1152px)
- Section padding: `py-14 md:py-20`
