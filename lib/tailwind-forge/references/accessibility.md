# Tailwind CSS Accessibility Patterns (WCAG 2.2)

**Contents:** WCAG 2.2 Overview · Focus Management · Forced Colors Mode · Screen Reader Utilities · Color Contrast · Motion and Animation · Form Accessibility · Interactive Components · Touch Targets · Text Accessibility · Semantic HTML with Tailwind · Testing Accessibility · Best Practices Summary

## WCAG 2.2 Overview

WCAG 2.2 is the current W3C recommendation. Tailwind-relevant criteria added in 2.2:

- **2.4.11 Focus Not Obscured (Minimum), AA**: a focused element must not be entirely hidden by author-created content such as sticky headers, cookie banners, or chat widgets. (2.4.12 Enhanced, AAA, requires no part of it to be hidden.)
- **2.4.13 Focus Appearance, AAA**: the focus indicator must be at least as large as a 2 CSS px perimeter of the element and have 3:1 contrast between focused and unfocused states.
- **2.5.8 Target Size (Minimum), AA**: pointer targets at least 24×24 CSS px, or spaced so that a 24 px circle centered on each does not overlap another target.
- **3.3.7 Redundant Entry, A**: do not make users re-enter information already provided in the same process.
- **3.2.6 Consistent Help, A**: help mechanisms appear in the same relative order across pages.

## Focus Management

### Focus Indicators

Use outlines for focus. In v4, `outline-none` sets `outline-style: none`, which removes the indicator even in forced-colors mode. `outline-hidden` (the v4 name for v3's `outline-none`) hides it visually but keeps it in forced-colors mode.

```html
<!-- Keyboard-only focus indicator -->
<button class="rounded-md px-4 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500">
  Button
</button>

<!-- Focus-within for a composite control: the input hides its own outline, the wrapper shows one -->
<div class="flex rounded-md border border-gray-300 focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-500">
  <input type="search" aria-label="Search" class="flex-1 px-3 py-2 outline-hidden" />
  <button class="px-3">Go</button>
</div>
```

A shared utility keeps the indicator consistent:

```css
@utility focus-ring {
  &:focus-visible {
    outline: 2px solid var(--color-brand-500);
    outline-offset: 2px;
  }
}

@utility focus-ring-inset {
  &:focus-visible {
    outline: 2px solid var(--color-brand-500);
    outline-offset: -2px;
  }
}
```

### Focus Not Obscured (2.4.11)

Sticky headers and footers can cover elements scrolled into view by keyboard focus. Reserve scroll padding equal to their height:

```html
<html class="scroll-pt-20">
  <body>
    <header class="sticky top-0 z-40 h-20 bg-white">...</header>
  </body>
</html>
```

`scroll-pt-*` on the scroll container affects both focus scrolling and anchor jumps. Use `scroll-mt-*` on individual targets when only specific sections need an offset.

### Skip Links

```html
<a
  href="#main-content"
  class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:rounded-md focus:bg-white focus:px-4 focus:py-2 focus:outline-2 focus:outline-brand-500"
>
  Skip to main content
</a>

<header>Navigation...</header>
<main id="main-content" tabindex="-1">Main content</main>
```

### Modal Dialogs

Prefer the native `<dialog>` element opened with `showModal()`: it traps focus, closes on Escape, makes the rest of the page inert, and exposes `::backdrop`.

```html
<dialog id="confirm" aria-labelledby="confirm-title" class="m-auto w-full max-w-md rounded-lg p-6 backdrop:bg-black/50">
  <h2 id="confirm-title" class="text-lg font-semibold">Delete project?</h2>
  <p class="mt-2 text-gray-700">This cannot be undone.</p>
  <form method="dialog" class="mt-6 flex justify-end gap-3">
    <button class="focus-ring rounded-md px-4 py-2">Cancel</button>
    <button value="confirm" class="focus-ring rounded-md bg-red-600 px-4 py-2 text-white">Delete</button>
  </form>
</dialog>
```

## Forced Colors Mode

Windows High Contrast and similar modes replace author colors with a system palette. In forced-colors mode:

- `box-shadow` is removed, so `ring-*` focus indicators and shadow-only borders disappear. Outlines and borders remain.
- Background colors are overridden, so state conveyed only by background (selected tab, toggle on) can vanish.

Use the `forced-colors:` variant to patch those cases:

```html
<!-- Card separated only by a shadow: add a border in forced colors -->
<div class="rounded-lg bg-white shadow-sm forced-colors:border">...</div>

<!-- Selected state shown by background: add a visible outline -->
<button role="tab" aria-selected="true" class="px-4 py-2 aria-selected:bg-brand-100 forced-colors:aria-selected:outline-2">
  Profile
</button>

<!-- Custom-styled checkbox: restore the native control -->
<input type="checkbox" class="appearance-none size-4 rounded-sm border checked:bg-brand-500 forced-colors:appearance-auto" />
```

## Screen Reader Utilities

```html
<!-- Hidden visually, available to screen readers -->
<span class="sr-only">Additional context for screen readers</span>

<!-- Icon button with accessible name -->
<button type="button" class="focus-ring rounded-md p-2">
  <svg aria-hidden="true" class="size-5">...</svg>
  <span class="sr-only">Close menu</span>
</button>

<!-- Visually hidden label -->
<label>
  <span class="sr-only">Search</span>
  <input type="search" placeholder="Search..." />
</label>
```

### Announcing Dynamic Content

```html
<!-- Polite live region (keep it in the DOM; change its text) -->
<div role="status" aria-live="polite" aria-atomic="true" class="sr-only">
  3 items added to cart
</div>

<!-- Assertive message for errors -->
<div role="alert" class="rounded-md bg-red-50 p-4 text-red-800">
  Error: Please correct the form
</div>
```

## Color Contrast

WCAG AA requires 4.5:1 for normal text and 3:1 for large text (24 px, or 18.66 px bold) and for UI component boundaries and focus indicators.

Measured contrast of v4 default grays on white:

| Class | Value | Ratio on white | Result |
| --- | --- | --- | --- |
| `text-gray-400` | `oklch(70.7% 0.022 261.325)` | about 2.6:1 | Fails AA for all text |
| `text-gray-500` | `oklch(55.1% 0.027 264.364)` | about 4.8:1 | Passes AA for normal text, narrowly (about 4.6:1 on `bg-gray-50`, about 4.4:1 and failing on `bg-gray-100`) |
| `text-gray-600` | `oklch(44.6% 0.03 256.802)` | about 7.6:1 | Passes AA and AAA |

```html
<p class="text-gray-700">Body text, comfortably above 4.5:1</p>
<p class="text-sm text-gray-600">Secondary text</p>
<p class="text-gray-400">Placeholder-level contrast: decorative or disabled text only</p>
```

Check the project's own tokens rather than assuming default palette ratios. When the project uses dark mode, verify each pair in both themes; a `dark:` shade is not automatically equivalent.

### Focus Indicator Contrast

Define a focus color token and use its generated utilities:

```css
@theme {
  --color-focus: oklch(0.55 0.25 250);
}
```

```html
<button class="focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus">
  High contrast focus
</button>
```

The offset leaves a gap of page background between control and outline, so the outline only needs 3:1 against the page background.

## Motion and Animation

### Reduced Motion

```html
<!-- Remove animation entirely -->
<div class="animate-spin motion-reduce:animate-none">...</div>

<!-- Keep color feedback, drop movement -->
<a href="#" class="transition-colors hover:text-brand-600 motion-reduce:transition-none">Link</a>

<!-- Opt in to motion only when allowed -->
<div class="motion-safe:animate-bounce">...</div>
```

### Entrance Animations

`animate-in`, `fade-in`, and `slide-in-from-*` come from `tw-animate-css` (`@import "tw-animate-css";`), the replacement for `tailwindcss-animate`. Add a reduced-motion fallback where they are applied:

```html
<div class="animate-in fade-in slide-in-from-bottom-4 duration-300 motion-reduce:animate-none">
  Panel content
</div>
```

### Pausing Animation

Anything that moves for more than 5 seconds needs a way to pause it (2.2.2). There is no built-in `animate-pause` utility; use an arbitrary property and give keyboard users the same control:

```html
<div tabindex="0" class="animate-marquee hover:[animation-play-state:paused] focus:[animation-play-state:paused] motion-reduce:animate-none">
  Scrolling announcements
</div>
```

`animate-marquee` stands for a project-defined `--animate-marquee` theme token. Prefer an explicit pause button for content users need to read.

## Form Accessibility

### Accessible Form Fields

```html
<div class="space-y-4">
  <div>
    <label for="email" class="block text-sm font-medium text-gray-700">
      Email address <span class="text-red-700" aria-hidden="true">*</span>
    </label>
    <input
      type="email"
      id="email"
      name="email"
      required
      aria-describedby="email-hint"
      class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500"
    />
    <p id="email-hint" class="mt-1 text-sm text-gray-600">We'll never share your email.</p>
  </div>

  <div class="flex items-start gap-3">
    <input type="checkbox" id="terms" name="terms" class="mt-1 size-4 rounded-sm border-gray-300 accent-brand-500" />
    <label for="terms" class="text-sm text-gray-700">
      I agree to the <a href="/terms" class="text-brand-600 underline">terms and conditions</a>
    </label>
  </div>

  <fieldset>
    <legend class="text-sm font-medium text-gray-700">Notification preference</legend>
    <div class="mt-2 space-y-2">
      <label class="flex items-center gap-3">
        <input type="radio" name="notification" value="email" class="size-4" /> Email
      </label>
      <label class="flex items-center gap-3">
        <input type="radio" name="notification" value="sms" class="size-4" /> SMS
      </label>
    </div>
  </fieldset>
</div>
```

The native `required` attribute already exposes the required state; `aria-required` is redundant on native inputs.

### Error States

Set `aria-invalid="true"` on the field and style from it with the `aria-[invalid=true]:` variant, so visual and accessible state cannot drift apart.

```html
<div>
  <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
  <input
    type="password"
    id="password"
    aria-invalid="true"
    aria-describedby="password-error"
    class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 aria-[invalid=true]:border-red-600 focus-visible:outline-2 focus-visible:outline-brand-500 aria-[invalid=true]:focus-visible:outline-red-600"
  />
  <p id="password-error" class="mt-1 text-sm text-red-700">
    <span class="sr-only">Error:</span> Password must be at least 8 characters
  </p>
</div>
```

Do not rely on red alone; the error text carries the meaning. Move focus to the first invalid field (or an error summary) on submit.

## Interactive Components

### Loading Button

`aria-busy` is set on the button, so children react through `group-aria-busy:` (the `aria-busy:` variant only matches the element that has the attribute).

```html
<button
  type="submit"
  aria-busy="true"
  aria-disabled="true"
  class="group relative rounded-md bg-brand-500 px-4 py-2 text-white aria-busy:cursor-wait aria-disabled:opacity-60 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500"
>
  <span class="group-aria-busy:invisible">Submit</span>
  <span class="invisible absolute inset-0 flex items-center justify-center group-aria-busy:visible">
    <svg class="size-5 animate-spin motion-reduce:animate-none" aria-hidden="true">...</svg>
    <span class="sr-only">Submitting</span>
  </span>
</button>
```

`aria-disabled` keeps the button focusable; block the action in the click handler.

### Toggle Button

```html
<button
  type="button"
  aria-pressed="false"
  class="focus-ring rounded-md border border-gray-300 px-4 py-2 aria-pressed:border-brand-500 aria-pressed:bg-brand-500 aria-pressed:text-white"
>
  Bold
</button>
```

The visible text is the accessible name; `aria-pressed` conveys the state.

### Disclosure Menu

The trigger is the `peer`, and the menu shows when the trigger's `aria-expanded` is `true`. JavaScript toggles `aria-expanded`, closes on Escape, and returns focus to the trigger. For simple navigation menus, plain links in a list (no `role="menu"`) are usually the better pattern.

```html
<div class="relative">
  <button
    id="options-button"
    type="button"
    aria-haspopup="true"
    aria-expanded="false"
    aria-controls="options-menu"
    class="peer focus-ring flex items-center gap-2 rounded-md border border-gray-300 px-4 py-2"
  >
    Options
    <svg aria-hidden="true" class="size-4">...</svg>
  </button>

  <ul
    id="options-menu"
    role="menu"
    aria-labelledby="options-button"
    class="absolute top-full mt-1 hidden w-48 rounded-md border border-gray-200 bg-white py-1 shadow-md peer-aria-expanded:block"
  >
    <li role="none">
      <a href="#" role="menuitem" tabindex="-1" class="block px-4 py-2 outline-hidden hover:bg-gray-100 focus:bg-gray-100">Edit</a>
    </li>
    <li role="none">
      <a href="#" role="menuitem" tabindex="-1" class="block px-4 py-2 outline-hidden hover:bg-gray-100 focus:bg-gray-100">Delete</a>
    </li>
  </ul>
</div>
```

The menu items use `outline-hidden` because the background change is the visible focus indicator; the outline still appears in forced-colors mode.

### Tabs

```html
<div>
  <div role="tablist" aria-label="Account settings" class="flex border-b border-gray-200">
    <button
      role="tab"
      id="tab-1"
      aria-selected="true"
      aria-controls="panel-1"
      class="focus-ring-inset border-b-2 border-transparent px-4 py-2 text-gray-600 hover:text-gray-900 aria-selected:border-brand-500 aria-selected:text-brand-600"
    >
      Profile
    </button>
    <button
      role="tab"
      id="tab-2"
      aria-selected="false"
      aria-controls="panel-2"
      tabindex="-1"
      class="focus-ring-inset border-b-2 border-transparent px-4 py-2 text-gray-600 hover:text-gray-900 aria-selected:border-brand-500 aria-selected:text-brand-600"
    >
      Settings
    </button>
  </div>

  <div role="tabpanel" id="panel-1" aria-labelledby="tab-1" tabindex="0" class="focus-ring-inset p-4">
    Profile content
  </div>
  <div role="tabpanel" id="panel-2" aria-labelledby="tab-2" tabindex="0" hidden class="focus-ring-inset p-4">
    Settings content
  </div>
</div>
```

The selected tab is marked by a border, which survives forced-colors mode. Arrow keys move between tabs (roving `tabindex`), handled in JavaScript.

## Touch Targets

| Level | Requirement | Tailwind |
| --- | --- | --- |
| AA (2.5.8) | 24×24 CSS px minimum, or adequate spacing | `min-h-6 min-w-6` |
| AAA (2.5.5) / recommended for touch | 44×44 CSS px | `min-h-11 min-w-11` |

Platform guidance: Apple 44×44 pt, Material 48×48 dp. Use `min-h-11 min-w-11` as the default for primary touch controls.

```html
<!-- 44×44 icon button -->
<button type="button" class="focus-ring inline-flex min-h-11 min-w-11 items-center justify-center rounded-md">
  <svg class="size-6" aria-hidden="true">...</svg>
  <span class="sr-only">Close</span>
</button>

<!-- Extend the hit area of a small visible element without changing layout -->
<a href="#" class="relative text-sm">
  Small link
  <span class="absolute -inset-3" aria-hidden="true"></span>
</a>

<!-- Whole card clickable through a stretched link -->
<article class="relative rounded-lg border border-gray-200 p-4 focus-within:outline-2 focus-within:outline-brand-500">
  <h3><a href="/details" class="outline-hidden after:absolute after:inset-0">Card title</a></h3>
  <p>Description text</p>
</article>
```

### Spacing

Targets smaller than 24×24 pass 2.5.8 only if a 24 px circle centered on each one does not intersect another target or its circle. In practice, keep small targets at least 24 px apart center-to-center, or make them 24 px.

```html
<div class="flex flex-wrap gap-2">
  <button class="min-h-11 rounded-md border px-4">Cancel</button>
  <button class="min-h-11 rounded-md bg-brand-500 px-4 text-white">Confirm</button>
</div>
```

Exceptions: inline links in a sentence, user-agent controls, an equivalent larger target on the same page, or when the size is essential.

## Text Accessibility

### Readable Text

```html
<article class="max-w-prose space-y-6">
  <p class="leading-relaxed">Body text with comfortable line height and 45–75 characters per line.</p>
</article>
```

### Text Resizing

Tailwind's type scale is in `rem`, so it follows the user's default font size setting.

```html
<p class="text-sm">Scales with the user's browser font size setting</p>

<!-- Pixel sizes ignore the user's default font size (browser zoom still scales them) -->
<p class="text-[14px]">Avoid</p>
```

Avoid fixed heights on text containers (`h-12` on a block of text); use `min-h-*` or padding so content can grow at 200% text size (1.4.4) and with increased text spacing (1.4.12).

## Semantic HTML with Tailwind

### Landmark Regions

```html
<body class="flex min-h-dvh flex-col">
  <header class="sticky top-0 z-40 border-b bg-white">
    <nav aria-label="Main">...</nav>
  </header>

  <div class="flex flex-1">
    <main id="main-content" class="flex-1">
      <h1>Page title</h1>
      <section aria-labelledby="section-1">
        <h2 id="section-1">Section title</h2>
      </section>
    </main>
    <aside aria-label="Related content" class="hidden lg:block">Sidebar</aside>
  </div>

  <footer class="bg-gray-800 text-white">
    <nav aria-label="Footer">...</nav>
  </footer>
</body>
```

`<aside>` sits beside `<main>`, not inside it, so it is exposed as a separate complementary landmark.

### Heading Hierarchy

Choose heading levels by document structure, then style them with utilities. Visual size and heading level are independent: `<h2 class="text-sm font-semibold uppercase">` is valid.

## Testing Accessibility

1. **Keyboard**: Tab through every control; confirm focus is visible and never hidden behind sticky UI.
2. **Contrast**: check text and focus indicators with DevTools or a contrast checker.
3. **Zoom and text size**: 200% zoom, and a larger browser default font size.
4. **Reduced motion**: enable the OS setting or emulate `prefers-reduced-motion` in DevTools.
5. **Forced colors**: emulate `forced-colors: active` in Chrome DevTools Rendering panel.
6. **Screen reader**: VoiceOver or NVDA pass on key flows.

```tsx
// jest-axe
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('component is accessible', async () => {
  const { container } = render(<Component />);
  expect(await axe(container)).toHaveNoViolations();
});
```

## Best Practices Summary

| Pattern | Implementation | WCAG |
| --- | --- | --- |
| Focus visible | `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-<token>` | 2.4.7 (AA) |
| Focus not obscured | `scroll-pt-*` matching sticky header height | 2.4.11 (AA) |
| Forced colors | Outlines over rings; `forced-colors:` fixes | 1.4.11 (AA) |
| Screen reader text | `sr-only` | 1.3.1 (A) |
| Skip link | `sr-only focus:not-sr-only focus:absolute` | 2.4.1 (A) |
| Reduced motion | `motion-reduce:animate-none motion-reduce:transition-none` | 2.3.3 (AAA) |
| Pause motion | Pause control or `[animation-play-state:paused]` on hover and focus | 2.2.2 (A) |
| Target size | `min-h-6 min-w-6` minimum; `min-h-11 min-w-11` recommended | 2.5.8 (AA) / 2.5.5 (AAA) |
| Text contrast | 4.5:1 normal, 3:1 large | 1.4.3 (AA) |
| Form errors | `aria-invalid="true"` + `aria-describedby` error text | 3.3.1 (A) |
