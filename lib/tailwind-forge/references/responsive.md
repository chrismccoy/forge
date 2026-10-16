# Responsive Design

**Contents:** Mobile-First Rules · Breakpoints · Container Queries · Fluid Type and Spacing · Layout Patterns · Input and Device Media · Touch Targets · Safe Areas · Responsive Images and Media · Mobile Navigation · Mobile Performance · Mobile Testing

## Mobile-First Rules

Unprefixed utilities apply at every width. A breakpoint prefix applies at that width **and above**. `sm:` never means "on small screens".

```html
<!-- Correct: base style is the mobile style, prefixes add changes upward -->
<div class="text-center sm:text-left">...</div>
<div class="flex flex-col md:flex-row">...</div>
```

The real desktop-first mistake is reading a prefix as "this size only" or writing the desktop style unprefixed and then trying to shrink it:

```html
<!-- Wrong: intends "small text on phones", but gives large text on phones
     and small text from 640px up -->
<p class="text-lg sm:text-sm">...</p>

<!-- Wrong: intends "stack on mobile", but stacks on everything 640px and wider -->
<div class="flex-row sm:flex-col">...</div>

<!-- Right -->
<p class="text-sm lg:text-lg">...</p>
<div class="flex flex-col sm:flex-row">...</div>
```

Class order inside the attribute is irrelevant. `lg:text-lg text-sm` and `text-sm lg:text-lg` produce the same result, because Tailwind sorts the generated CSS by variant.

Rules:

- Write the narrowest layout first with no prefix. Add a prefix only where the layout actually changes.
- Do not repeat a value at a larger breakpoint (`text-sm md:text-sm` changes nothing).
- Let content decide breakpoints: resize until the layout breaks, then add a breakpoint there.
- Use container queries for reusable components and viewport breakpoints for page-level layout (see Container Queries).
- Include `<meta name="viewport" content="width=device-width, initial-scale=1">`. Add `viewport-fit=cover` only when handling safe areas.

## Breakpoints

| Prefix | Min width | CSS | Typical target |
|--------|-----------|-----|----------------|
| (none) | 0 | — | Phones (base) |
| `sm:` | 40rem (640px) | `@media (width >= 40rem)` | Large phones |
| `md:` | 48rem (768px) | `@media (width >= 48rem)` | Tablets (portrait) |
| `lg:` | 64rem (1024px) | `@media (width >= 64rem)` | Tablets (landscape), laptops |
| `xl:` | 80rem (1280px) | `@media (width >= 80rem)` | Desktops |
| `2xl:` | 96rem (1536px) | `@media (width >= 96rem)` | Large desktops |

### Ranges and max-width

Every breakpoint has a built-in `max-*` variant (`max-sm:` = `width < 40rem`, up to `max-2xl:`). Do not redefine them.

```html
<!-- Below md only -->
<div class="max-md:hidden">Hidden under 768px</div>

<!-- Only between md and lg -->
<div class="hidden md:max-lg:block">Tablet only</div>

<!-- One-off arbitrary breakpoints -->
<div class="max-[600px]:text-sm min-[320px]:text-center">...</div>
```

### Custom breakpoints

Define breakpoints in `rem`. Mixing `px` and `rem` breaks variant sort order.

```css
@import "tailwindcss";

@theme {
  --breakpoint-xs: 30rem;   /* 480px */
  --breakpoint-3xl: 120rem; /* 1920px */
}
```

```html
<div class="grid xs:grid-cols-2 3xl:grid-cols-6">...</div>
```

Remove a default with `--breakpoint-2xl: initial;`, or replace the whole set:

```css
@theme {
  --breakpoint-*: initial;
  --breakpoint-tablet: 40rem;
  --breakpoint-laptop: 64rem;
  --breakpoint-desktop: 80rem;
}
```

`theme(--breakpoint-md)` remains valid inside a plain CSS `@media` rule when a breakpoint is needed outside a class.

## Container Queries

Container queries are built into v4. No plugin is needed. Mark a parent with `@container`; children use `@sm:`, `@md:`, etc. They are mobile-first like breakpoints.

```html
<div class="@container">
  <article class="flex flex-col gap-4 @md:flex-row @md:items-center">
    <img class="aspect-video w-full object-cover @md:w-48" src="..." alt="..." />
    <div class="min-w-0 flex-1">
      <h3 class="text-base font-semibold @lg:text-xl">Title</h3>
      <p class="line-clamp-2 text-sm @lg:line-clamp-3">Description</p>
    </div>
  </article>
</div>
```

| Syntax | Meaning |
|--------|---------|
| `@md:flex-row` | container width ≥ 28rem |
| `@max-md:flex-col` | container width < 28rem |
| `@sm:@max-md:flex-col` | between 24rem and 28rem |
| `@min-[475px]:flex-row` | arbitrary container size |
| `@container/sidebar` + `@md/sidebar:` | query a named container |
| `@container-size` (v4.3+) | size container (enables `cqb`/`cqh` units); on older versions use `[container-type:size]` |
| `w-[50cqw]` | container query units as arbitrary values |

Default sizes: `@3xs` 16rem, `@2xs` 18rem, `@xs` 20rem, `@sm` 24rem, `@md` 28rem, `@lg` 32rem, `@xl` 36rem, `@2xl` 42rem, `@3xl` 48rem, `@4xl` 56rem, `@5xl` 64rem, `@6xl` 72rem, `@7xl` 80rem. Add more with `@theme { --container-8xl: 96rem; }`.

Named containers, for nested contexts:

```html
<div class="flex">
  <aside class="@container/sidebar w-64">
    <nav class="flex flex-col gap-2 @lg/sidebar:flex-row">...</nav>
  </aside>
  <main class="@container/main flex-1">
    <div class="grid grid-cols-1 gap-6 @md/main:grid-cols-2 @xl/main:grid-cols-3">...</div>
  </main>
</div>
```

| Container queries | Viewport breakpoints |
|-------------------|----------------------|
| Reusable cards, widgets | Page shell, header, nav |
| Components placed in sidebars, modals, grids | Hero and full-width sections |
| CMS/embedded content | Show/hide of whole regions |

## Fluid Type and Spacing

Define fluid tokens in `@theme` so utilities generate automatically: `--text-fluid-*` produces `text-fluid-*`; `--spacing-fluid-*` produces `p-fluid-*`, `m-fluid-*`, `gap-fluid-*`, etc. Always combine `rem` with `vw` in `clamp()` so text still scales with browser zoom and user font size (WCAG 1.4.4).

```css
@import "tailwindcss";

@theme {
  --text-fluid-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
  --text-fluid-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --text-fluid-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
  --text-fluid-xl: clamp(1.25rem, 1rem + 1.25vw, 1.5rem);
  --text-fluid-2xl: clamp(1.5rem, 1.1rem + 2vw, 2rem);
  --text-fluid-3xl: clamp(1.875rem, 1.2rem + 3.375vw, 2.5rem);
  --text-fluid-4xl: clamp(2.25rem, 1rem + 6.25vw, 3.5rem);

  --spacing-fluid-sm: clamp(0.5rem, 0.4rem + 0.5vw, 1rem);
  --spacing-fluid-md: clamp(1rem, 0.75rem + 1.25vw, 2rem);
  --spacing-fluid-lg: clamp(1.5rem, 1rem + 2.5vw, 3rem);
  --spacing-fluid-xl: clamp(2rem, 1.25rem + 3.75vw, 4rem);
  --spacing-fluid-section: clamp(4rem, 2rem + 10vw, 8rem);
}
```

```html
<section class="px-fluid-md py-fluid-section">
  <h2 class="mb-fluid-lg text-fluid-3xl font-bold text-balance">Section title</h2>
  <p class="max-w-prose text-fluid-base leading-relaxed">Body text that scales smoothly.</p>
  <div class="grid grid-cols-1 gap-fluid-md md:grid-cols-2 lg:grid-cols-3">...</div>
</section>
```

Use fluid tokens or stepped breakpoints for a given element, not both. Stepped alternative:

```html
<h1 class="text-3xl font-bold leading-tight sm:text-4xl lg:text-5xl">Heading</h1>
<p class="text-base leading-relaxed md:text-lg">Body</p>
```

Keep body text readable with `max-w-prose` (65ch).

## Layout Patterns

Grid that steps with breakpoints, or auto-fits without any:

```html
<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 md:gap-6">...</div>

<div class="grid grid-cols-[repeat(auto-fit,minmax(min(100%,17.5rem),1fr))] gap-6">...</div>
```

Stack to row, with the action pushed right on wider screens:

```html
<div class="flex flex-col gap-4 sm:flex-row sm:items-center">
  <div class="min-w-0 flex-1">
    <h3 class="font-semibold">Title</h3>
    <p class="text-sm">Description</p>
  </div>
  <button class="min-h-11 px-4">Action</button>
</div>
```

Sidebar layout:

```html
<div class="grid min-h-dvh grid-cols-1 lg:grid-cols-[16rem_1fr]">
  <aside class="hidden border-r lg:block">Sidebar</aside>
  <main class="p-4 lg:p-8">Content</main>
</div>
```

Page shell with header, optional sidebars, and footer:

```html
<div class="grid min-h-dvh grid-rows-[auto_1fr_auto]">
  <header class="sticky top-0 z-50 border-b bg-white">...</header>
  <div class="grid grid-cols-1 md:grid-cols-[15rem_1fr] lg:grid-cols-[15rem_1fr_17.5rem]">
    <nav class="hidden border-r p-4 md:block">Left nav</nav>
    <main class="p-4 md:p-6 lg:p-8">Main</main>
    <aside class="hidden border-l p-4 lg:block">Right sidebar</aside>
  </div>
  <footer class="py-8">Footer</footer>
</div>
```

Table that becomes stacked rows on mobile:

```html
<table class="w-full">
  <thead class="max-md:sr-only">
    <tr><th class="p-3 text-left">Name</th><th class="p-3 text-left">Email</th></tr>
  </thead>
  <tbody>
    <tr class="border-b max-md:flex max-md:flex-col max-md:py-3">
      <td class="p-3"><span class="font-medium md:hidden">Name: </span>Jane Doe</td>
      <td class="p-3"><span class="font-medium md:hidden">Email: </span>jane@example.com</td>
    </tr>
  </tbody>
</table>
```

Alternatively wrap a wide table in `<div class="overflow-x-auto">` to keep table semantics.

Show/hide: `hidden md:block` (from md up), `md:hidden` (below md). Hidden content is still downloaded; do not render heavy duplicates for each breakpoint. More layouts: `layouts.md`.

Use `min-h-dvh` instead of `h-screen`/`min-h-screen` for full-height mobile layouts so the browser toolbar does not cut off content.

## Input and Device Media

| Variant | CSS |
|---------|-----|
| `hover:` | `@media (hover: hover) { &:hover }` (hover styles do not stick on touch) |
| `pointer-fine:` (v4.1+) | `@media (pointer: fine)` (mouse, trackpad) |
| `pointer-coarse:` (v4.1+) | `@media (pointer: coarse)` (touch) |
| `pointer-none:` (v4.1+) | `@media (pointer: none)` |
| `any-pointer-fine:` / `any-pointer-coarse:` / `any-pointer-none:` (v4.1+) | `@media (any-pointer: ...)` (any connected input) |
| `portrait:` / `landscape:` | `@media (orientation: ...)` |
| `print:` | `@media print` |
| `motion-reduce:` / `motion-safe:` | `prefers-reduced-motion` |
| `contrast-more:` | `prefers-contrast: more` |
| `forced-colors:` | `@media (forced-colors: active)` |
| `noscript:` (v4.1+) | `@media (scripting: none)` |

There is no built-in `any-hover` variant. Add one only if needed: `@custom-variant any-hover (@media (any-hover: hover));`.

```html
<!-- Larger hit area on touch devices, compact for mouse -->
<button class="px-3 py-1.5 pointer-coarse:px-4 pointer-coarse:py-3">Save</button>

<!-- Row actions: always visible on touch, revealed on hover/focus for mouse -->
<li class="group flex items-center justify-between">
  <span>Item</span>
  <div class="pointer-fine:opacity-0 pointer-fine:group-hover:opacity-100 pointer-fine:group-focus-within:opacity-100">
    <button class="min-h-11 min-w-11" aria-label="Delete item">...</button>
  </div>
</li>

<!-- Orientation -->
<div class="flex portrait:flex-col landscape:flex-row">...</div>

<!-- Print -->
<nav class="print:hidden">...</nav>
```

`prefers-reduced-data` has near-zero browser support. If needed anyway: `@custom-variant reduced-data (@media (prefers-reduced-data: reduce));` and treat it as progressive enhancement only.

## Touch Targets

- WCAG 2.2 AA (2.5.8): at least 24×24 CSS px, or enough spacing that a 24px circle around each target does not overlap another.
- Recommended for touch: 44×44 px (`min-h-11 min-w-11`). Primary mobile actions: 48px (`min-h-12`).

```html
<!-- Icon button, 44px -->
<button class="inline-flex min-h-11 min-w-11 items-center justify-center" aria-label="Close">
  <svg class="size-5" aria-hidden="true">...</svg>
</button>

<!-- Minimum AA, 24px (dense UIs only) -->
<button class="inline-flex min-h-6 min-w-6 items-center justify-center" aria-label="Remove tag">
  <svg class="size-4" aria-hidden="true">...</svg>
</button>

<!-- Small visible link with an extended hit area -->
<a href="/terms" class="relative text-sm">
  Terms
  <span class="absolute -inset-3" aria-hidden="true"></span>
</a>

<!-- Spacing between adjacent targets -->
<div class="flex flex-wrap gap-3">
  <button class="min-h-11 px-4">Cancel</button>
  <button class="min-h-11 px-4">Confirm</button>
</div>
```

Stacked links: make the whole row the target with `block min-h-11 px-4 py-3`.

## Safe Areas

Use arbitrary values with `env()` everywhere. This file does not define custom safe-area utilities. Requires `viewport-fit=cover` in the viewport meta:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

```html
<header class="sticky top-0 pt-[env(safe-area-inset-top)]">
  <div class="flex h-14 items-center px-4">...</div>
</header>

<nav class="fixed inset-x-0 bottom-0 pb-[env(safe-area-inset-bottom)]">
  <ul class="flex justify-around">...</ul>
</nav>

<!-- Combine with base padding -->
<footer class="pb-[max(--spacing(4),env(safe-area-inset-bottom))]">...</footer>

<!-- Landscape notch -->
<div class="pr-[env(safe-area-inset-right)] pl-[env(safe-area-inset-left)]">...</div>
```

## Responsive Images and Media

Reserve space with `aspect-*` (prevents layout shift), lazy-load below the fold, and give `srcset` + `sizes` so the browser picks the right file.

```html
<img
  src="image-800.jpg"
  srcset="image-400.jpg 400w, image-800.jpg 800w, image-1200.jpg 1200w, image-1600.jpg 1600w"
  sizes="(width >= 80rem) 1200px, (width >= 48rem) 80vw, 100vw"
  alt="Description"
  width="1600" height="900"
  loading="lazy" decoding="async"
  class="aspect-video h-auto w-full object-cover"
/>

<!-- Art direction -->
<picture>
  <source media="(width >= 64rem)" srcset="wide.jpg" />
  <source media="(width >= 40rem)" srcset="medium.jpg" />
  <img src="narrow.jpg" alt="Description" class="h-auto w-full" loading="lazy" />
</picture>

<!-- Aspect ratio that changes with breakpoints -->
<div class="aspect-square overflow-hidden sm:aspect-video lg:aspect-4/3">
  <img src="..." alt="..." class="size-full object-cover" loading="lazy" />
</div>
```

Do not lazy-load the LCP/hero image; give it `fetchpriority="high"` instead.

Video and embeds: wrap in `aspect-video` (or `aspect-9/16` for vertical) and use `preload="metadata"` or `preload="none"` with a `poster`. `<iframe loading="lazy" class="aspect-video w-full">` works for embeds. For custom player controls, label every button (`aria-label="Play"`), keep controls visible on focus (`group-focus-within:opacity-100`, not hover only), and give scrubbers at least a 24px-tall hit area even when the visible track is thinner (`relative h-6` wrapper around an `h-1` track). Prefer native `controls` when no custom design is required.

## Mobile Navigation

Disclosure menu with an accessible toggle. JS toggles `aria-expanded` and the `hidden` attribute.

```html
<nav class="relative flex items-center justify-between p-4">
  <a href="/" class="font-semibold">Logo</a>

  <ul class="hidden items-center gap-6 md:flex">
    <li><a href="/products" class="py-2">Products</a></li>
    <li><a href="/about" class="py-2" aria-current="page">About</a></li>
  </ul>

  <button
    class="inline-flex min-h-11 min-w-11 items-center justify-center md:hidden"
    aria-expanded="false"
    aria-controls="mobile-menu"
    aria-label="Open menu"
  >
    <svg class="size-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
      <path stroke-linecap="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
    </svg>
  </button>

  <div id="mobile-menu" class="absolute inset-x-0 top-full border-t bg-white md:hidden" hidden>
    <ul class="py-2">
      <li><a href="/products" class="block min-h-11 px-4 py-3">Products</a></li>
      <li><a href="/about" class="block min-h-11 px-4 py-3" aria-current="page">About</a></li>
    </ul>
  </div>
</nav>
```

Bottom tab bar (app-style). `aria-current` has no built-in variant; use `aria-[current=page]:`.

```html
<nav class="fixed inset-x-0 bottom-0 z-50 border-t bg-white pb-[env(safe-area-inset-bottom)] md:hidden">
  <ul class="flex justify-around">
    <li>
      <a href="/" aria-current="page"
         class="flex min-h-14 min-w-14 flex-col items-center justify-center px-3 text-xs text-gray-600 aria-[current=page]:text-blue-700">
        <svg class="mb-1 size-6" aria-hidden="true">...</svg>
        Home
      </a>
    </li>
    <li>
      <a href="/search"
         class="flex min-h-14 min-w-14 flex-col items-center justify-center px-3 text-xs text-gray-600 aria-[current=page]:text-blue-700">
        <svg class="mb-1 size-6" aria-hidden="true">...</svg>
        Search
      </a>
    </li>
  </ul>
</nav>

<!-- Keep content clear of the fixed bar -->
<main class="pb-20 md:pb-0">...</main>
```

For off-canvas drawers, trap focus, close on Escape, and restore focus to the toggle; a headless library (Radix Dialog, Headless UI) handles this. See `accessibility.md`.

## Mobile Performance

- `loading="lazy"` and `decoding="async"` on below-fold images and iframes; explicit `width`/`height` or `aspect-*` on all media.
- Skip rendering off-screen sections with a `content-auto` utility (`content-visibility: auto`); see v4-custom-utilities.md for the canonical definition.

- Avoid shipping duplicate markup for mobile and desktop variants of the same region; restyle one tree with breakpoints where possible.
- Target LCP under 2.5s on a throttled mobile profile.

## Mobile Testing

Widths to check: 320, 375, 390–430, 768, 1024, 1280, 1440, 1920 px, plus the widths just below and above each breakpoint. Test in browser device mode, then on at least one real iOS and one Android device.

- [ ] No horizontal scroll at 320px
- [ ] Text readable without zoom; page usable at 200% zoom
- [ ] Touch targets ≥ 44px (≥ 24px absolute minimum) with spacing
- [ ] Hover-revealed content also reachable by focus and touch
- [ ] Images and embeds do not overflow; no layout shift on load
- [ ] Navigation, forms, modals, and tables usable on mobile
- [ ] Portrait and landscape both work
- [ ] Fixed headers/bars clear safe areas and do not cover focused elements
