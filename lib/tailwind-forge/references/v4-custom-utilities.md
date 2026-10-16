# Custom Utilities Deep Dive

**Contents:** Naming Rules · Static Utilities · Functional Utilities · Modifiers · Variants Inside Utilities · Utilities vs Components · Debugging Custom Utilities

## Naming Rules

- A utility name is a plain identifier, optionally ending in `-*` for functional utilities.
- No `::pseudo`, `:hover`, or `@` in the name. Nest selectors inside the body instead.
- Never redefine a core utility name. `columns-*`, `z-*`, `inset-*`, `blur-*`, `tracking-*`, `aspect-*`, `line-clamp-*`, `snap-*`, `opacity-*`, `indent-*`, `tab-*` (v4.3+), `text-balance`, `text-shadow-*` (v4.1+), and `grid-cols-subgrid` already exist. Redefining them changes behavior for every existing use and overrides Tailwind's theme-aware versions.
- Check https://tailwindcss.com/docs before adding a utility; most common needs are already covered.

## Static Utilities

```css
@utility content-auto {
  content-visibility: auto;
  contain-intrinsic-size: auto 500px; /* placeholder height; prevents scrollbar jumps */
}

@utility scrollbar-hide {
  scrollbar-width: none;
  &::-webkit-scrollbar {
    display: none;
  }
}
```

```html
<section class="content-auto">...</section>
<div class="overflow-x-auto scrollbar-hide">...</div>
```

Every custom utility works with all variants: `md:scrollbar-hide`, `hover:content-auto`.

## Functional Utilities

A name ending in `-*` accepts a value. `--value()` resolves it. Declarations that fail to resolve are omitted, so several forms can be stacked.

### Bare Values

`--value(type)` validates the part after the dash. Bare types: `number`, `integer`, `ratio`, `percentage`.

```css
/* Line length in ch: measure-60 → max-inline-size: 60ch */
@utility measure-* {
  max-inline-size: calc(--value(integer) * 1ch);
}
```

Matches `measure-45`, `measure-60`, `measure-75`.

### Theme Values

`--value(--namespace-*)` looks up a theme key:

```css
@theme {
  --measure-prose: 65ch;
}

@utility measure-* {
  max-inline-size: --value(--measure-*);
}
```

Matches `measure-prose`.

### Arbitrary Values

`--value([type])` accepts bracketed values of that type. Arbitrary types: `absolute-size`, `angle`, `bg-size`, `color`, `family-name`, `generic-name`, `image`, `integer`, `length`, `line-width`, `number`, `percentage`, `position`, `ratio`, `relative-size`, `url`, `vector`, `*`.

```css
@utility scroll-pad-* {
  scroll-padding-top: --value([length]);
}
```

Matches `scroll-pad-[4.5rem]`.

### Literal Values

Quoted strings match exact words:

```css
@utility measure-* {
  max-inline-size: --value("none", "fit-content");
}
```

### Combining Forms

One utility can accept theme, bare, and arbitrary values:

```css
@theme {
  --measure-prose: 65ch;
}

@utility measure-* {
  max-inline-size: --value([length]);
  max-inline-size: calc(--value(integer) * 1ch);
  max-inline-size: --value(--measure-*);
}
```

Matches `measure-[40rem]`, `measure-60`, and `measure-prose`.

Pick names core does not own: core already has `indent-*` (`text-indent`) and, on v4.3+, `tab-*` (`tab-size`). On versions with core `tab-*`, use it instead of a custom tab utility.

## Modifiers

`--modifier()` works like `--value()` but reads the part after `/`. Declarations that depend on a missing modifier are dropped.

```css
@utility glow-* {
  --glow-size: --value([length]);
  --glow-color: --modifier(--color-*, [color]);
  text-shadow: 0 0 var(--glow-size) var(--glow-color, currentColor);
}
```

```html
<span class="glow-[4px]">currentColor glow</span>
<span class="glow-[4px]/blue-500">theme color glow</span>
<span class="glow-[4px]/[oklch(0.7_0.2_250)]">arbitrary color glow</span>
```

Only when requested: glows are decorative.

## Variants Inside Utilities

Use `@variant` inside the utility body to adjust it for a state. Writing a separate `.dark .glass` rule is not part of the utility and does not compose with variants.

```css
@utility glass {
  background: oklch(1 0 0 / 0.6);
  backdrop-filter: blur(12px);

  @variant dark {
    background: oklch(0 0 0 / 0.4);
  }
}
```

Only when requested: glass effects are decorative. Show `@variant dark` only if the project uses dark mode.

## Utilities vs Components

Keep `@utility` single-purpose. Multi-property patterns belong in a component (template partial) or `@layer components`:

```css
/* Avoid: a component disguised as a utility */
@utility card {
  display: flex;
  flex-direction: column;
  padding: 1rem;
  background: white;
  border-radius: 0.5rem;
}

/* Prefer */
@layer components {
  .card {
    @apply flex flex-col p-4 bg-white rounded-lg;
  }
}
```

Also avoid functional utilities that set unrelated properties together.

## Debugging Custom Utilities

```bash
grep "scrollbar-hide" dist/output.css
```

If the utility is missing:

1. Check the name has no `::`, `:`, or `@`, and does not collide with a core utility.
2. Confirm the `@utility` block is in the same CSS entry as `@import "tailwindcss"`, or in a file it imports.
3. Confirm the class appears in a scanned source file (add `@source` for paths outside automatic detection).
4. For functional utilities, check the value matches a `--value()` form. `measure-60` needs `--value(integer)`; `measure-[40rem]` needs `--value([length])`.
