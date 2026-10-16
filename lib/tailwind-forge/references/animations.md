# Tailwind CSS Animations and Transitions

**Contents:** Built-in Animations · Transitions · Transforms · Custom Animations · Enter and Leave Transitions · Scroll-Driven Animations · View Transitions · Staggered Animations · Reduced Motion · Performance

Animate only what communicates state (loading, opening, feedback). Do not add hover lifts, scale effects, or entrance animations to static content by default.

Token names such as `bg-primary` and `bg-surface` are placeholders; replace them with the project's `@theme` tokens.

## Built-in Animations

| Class | Use |
|-------|-----|
| `animate-spin` | Loading spinners |
| `animate-ping` | Notification badge pulse |
| `animate-pulse` | Skeleton placeholders |
| `animate-bounce` | Scroll-down hint, typing dots |
| `animate-none` | Remove an animation |

Spinner:

```html
<svg class="size-5 animate-spin motion-reduce:animate-none" viewBox="0 0 24 24" fill="none" aria-hidden="true">
  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
</svg>
```

Notification ping:

```html
<span class="relative flex size-3">
  <span class="absolute inline-flex size-full animate-ping rounded-full bg-primary opacity-75"></span>
  <span class="relative inline-flex size-3 rounded-full bg-primary"></span>
</span>
```

Skeleton:

```html
<div class="animate-pulse space-y-3" aria-hidden="true">
  <div class="h-4 w-3/4 rounded-sm bg-muted"></div>
  <div class="h-4 w-1/2 rounded-sm bg-muted"></div>
  <div class="h-4 w-5/6 rounded-sm bg-muted"></div>
</div>
```

## Transitions

| Class | Properties transitioned |
|-------|-------------------------|
| `transition` | Colors, opacity, shadow, transform, filters, `display`, `content-visibility`, `overlay` |
| `transition-colors` | Color, background, border, outline, text-decoration, fill, stroke, gradient stops |
| `transition-opacity` | `opacity` |
| `transition-shadow` | `box-shadow` |
| `transition-transform` | `transform`, `translate`, `scale`, `rotate` |
| `transition-[height,opacity]` | Arbitrary list |
| `transition-all` | Everything (avoid) |
| `transition-none` | Nothing |

All `transition-*` utilities default to 150ms and `cubic-bezier(0.4, 0, 0.2, 1)`.

| Duration | Value |
|----------|-------|
| `duration-75` … `duration-1000` | Any number of ms: `duration-150`, `duration-200`, `duration-300` |
| `duration-[1.5s]` | Arbitrary |
| `duration-initial` | Reset |

| Easing | Value |
|--------|-------|
| `ease-linear` | `linear` |
| `ease-in` | `cubic-bezier(0.4, 0, 1, 1)` |
| `ease-out` | `cubic-bezier(0, 0, 0.2, 1)` |
| `ease-in-out` | `cubic-bezier(0.4, 0, 0.2, 1)` |
| `ease-[cubic-bezier(…)]` / `ease-<token>` | Arbitrary or custom `--ease-*` token |

| Delay | Value |
|-------|-------|
| `delay-75` … `delay-1000` | Any number of ms: `delay-100`, `delay-300` |
| `delay-[2s]` | Arbitrary |

Example:

```html
<button class="rounded-md bg-primary px-4 py-2 text-white transition-colors hover:bg-primary/90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary">
  Save
</button>
```

Keep UI feedback between 100ms and 300ms. Use `ease-out` for elements entering, `ease-in` for elements leaving.

## Transforms

In v4, transform utilities work without a `transform` class.

| Utility | Example |
|---------|---------|
| Scale | `scale-95`, `scale-x-110`, `active:scale-95` |
| Rotate | `rotate-45`, `-rotate-90`, `rotate-180` |
| Translate | `translate-x-2`, `-translate-y-1`, `translate-y-full` |
| Skew | `skew-x-3`, `skew-y-3` |
| Origin | `origin-center`, `origin-top-left`, `origin-top` |

Disclosure chevron that rotates when expanded (works with mouse and keyboard because it follows `aria-expanded`):

```html
<button type="button" aria-expanded="false" aria-controls="faq-1" class="group flex items-center gap-2">
  Shipping
  <svg class="size-4 transition-transform group-aria-expanded:rotate-180" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
    <path d="M5.5 7.5 10 12l4.5-4.5" />
  </svg>
</button>
```

Menu icon to X, driven by `aria-expanded` (toggle the attribute in JS):

```html
<button type="button" aria-expanded="false" aria-label="Menu" class="group flex size-10 flex-col items-center justify-center gap-1.5">
  <span class="block h-0.5 w-6 bg-current transition-transform group-aria-expanded:translate-y-2 group-aria-expanded:rotate-45"></span>
  <span class="block h-0.5 w-6 bg-current transition-opacity group-aria-expanded:opacity-0"></span>
  <span class="block h-0.5 w-6 bg-current transition-transform group-aria-expanded:-translate-y-2 group-aria-expanded:-rotate-45"></span>
</button>
```

The `open:` variant matches only `<details>`, `<dialog>`, and popovers; it never matches a `<button>`.

## Custom Animations

Define `--animate-*` tokens with their `@keyframes` inside `@theme`. Keyframes defined inside `@theme` are emitted only when the animation is used.

```css
@import "tailwindcss";

@theme {
  --animate-fade-in: fade-in 0.2s ease-out;
  --animate-slide-up: slide-up 0.3s ease-out;
  --animate-shake: shake 0.4s ease-in-out;

  --ease-out-expo: cubic-bezier(0.19, 1, 0.22, 1);

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  @keyframes slide-up {
    from { opacity: 0; transform: translateY(0.5rem); }
    to { opacity: 1; transform: translateY(0); }
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-0.25rem); }
    75% { transform: translateX(0.25rem); }
  }
}
```

```html
<div class="animate-fade-in">...</div>
<p class="animate-shake text-danger" role="alert">Invalid code</p>
<div class="transition-transform ease-out-expo">...</div>
```

One-off animation without a token: `animate-[fade-in_0.2s_ease-out]` (the keyframes must still exist).

## Enter and Leave Transitions

### CSS only: `starting:` (`@starting-style`)

The `starting:` variant sets the initial style when an element is first rendered or goes from `display: none` to visible, so a plain transition animates the entrance. Combine with `transition-discrete` to also animate `display` on exit.

```html
<button popovertarget="menu">Options</button>
<div
  popover
  id="menu"
  class="opacity-0 transition-discrete transition-[opacity,display,overlay] duration-150 open:opacity-100 starting:open:opacity-0"
>
  ...
</div>
```

Same pattern for `<dialog>`:

```html
<dialog class="scale-95 opacity-0 transition-discrete transition-[opacity,scale,display,overlay] duration-200 open:scale-100 open:opacity-100 starting:open:scale-95 starting:open:opacity-0">
  ...
</dialog>
```

`@starting-style` support varies; check caniuse.com. Browsers without it show the element without animating, which is an acceptable fallback.

### Headless UI v2 (React)

Pass `transition` and describe the closed state with `data-closed:`. See the Headless UI v2 Dialog example in components.md.

### `tw-animate-css`

Classes such as `animate-in fade-in-0 zoom-in-95` and `animate-out fade-out-0` (used by shadcn/ui) come from the `tw-animate-css` package, the v4 replacement for `tailwindcss-animate`. They are not built into Tailwind.

```css
@import "tailwindcss";
@import "tw-animate-css";
```

## Scroll-Driven Animations

Tailwind has no dedicated utilities; use arbitrary properties. Support varies; check caniuse.com, treat the effect as progressive enhancement, and keep content visible without it.

Reading progress bar:

```css
@theme {
  --animate-grow-x: grow-x linear both;

  @keyframes grow-x {
    from { transform: scaleX(0); }
    to { transform: scaleX(1); }
  }
}
```

```html
<div class="fixed inset-x-0 top-0 h-1 origin-left bg-primary motion-safe:animate-grow-x motion-safe:[animation-timeline:scroll()]"></div>
```

Reveal as an element enters the viewport:

```html
<section class="motion-safe:animate-fade-in motion-safe:[animation-timeline:view()] motion-safe:[animation-range:entry_0%_cover_30%]">
  ...
</section>
```

## View Transitions

The View Transitions API animates between DOM states. Support varies; check caniuse.com and provide a non-animated fallback (the feature check below applies the update instantly).

```js
function update(render) {
  if (!document.startViewTransition) return render();
  document.startViewTransition(render);
}
```

Name an element so it morphs between states:

```html
<img src="/cover.jpg" alt="" class="[view-transition-name:hero]" />
```

Each `view-transition-name` must be unique on the page at the time of the transition.

## Staggered Animations

Set the delay per item with a CSS variable:

```tsx
{items.map((item, i) => (
  <li
    key={item.id}
    style={{ "--i": i } as React.CSSProperties}
    className="motion-safe:animate-slide-up [animation-delay:calc(var(--i)*50ms)] [animation-fill-mode:both]"
  >
    {item.label}
  </li>
))}
```

`[animation-fill-mode:both]` keeps items hidden until their delay elapses. For a fixed set, use literal delays:

```html
<div class="flex gap-1" aria-label="Loading" role="status">
  <span class="size-2 animate-bounce rounded-full bg-current [animation-delay:-0.3s]"></span>
  <span class="size-2 animate-bounce rounded-full bg-current [animation-delay:-0.15s]"></span>
  <span class="size-2 animate-bounce rounded-full bg-current"></span>
</div>
```

## Reduced Motion

- `motion-safe:` applies only when the user has not requested reduced motion. Prefer it for decorative or movement-heavy effects; it avoids undoing styles.
- `motion-reduce:` applies when reduced motion is requested. Use it to stop or replace an animation; for loading indicators use `motion-reduce:animate-none` so the cue stays visible.

```html
<div class="motion-safe:animate-slide-up">...</div>
<svg class="animate-spin motion-reduce:animate-none">...</svg> <!-- stops spinning, keeps the loading cue -->
```

Global safety net for animations that cannot be edited individually:

```css
@layer base {
  @media (prefers-reduced-motion: reduce) {
    *,
    ::before,
    ::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
}
```

Reduced motion means less movement, not no feedback: opacity and color changes are generally fine.

## Performance

- Animate `transform` and `opacity`. Avoid animating `width`, `height`, `top`/`left`, `margin`, or `padding`, which trigger layout each frame. To animate height, prefer `grid-rows-[0fr]` → `grid-rows-[1fr]` with `transition-[grid-template-rows]`.
- Use a specific `transition-*` utility, not `transition-all`.
- Use `will-change-transform` only on elements that animate continuously or imminently; remove it otherwise.
- Isolate heavy animated regions with `[contain:layout_paint]` when siblings would otherwise re-layout.
- Keep interaction feedback short (100–300ms); longer durations feel sluggish.

### Decorative hover effects (only when requested)

```html
<a href="/post" class="block rounded-lg border border-border p-6 transition-[translate,box-shadow] motion-safe:hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary">
  ...
</a>
```
