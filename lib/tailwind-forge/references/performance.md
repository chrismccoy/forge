# Tailwind CSS Performance

**Contents:** How v4 Generates CSS · Content Detection · Dynamic Class Names and Safelisting · Theme Size and Output · Multiple CSS Entry Points · Minification and Compression · Measuring Output Size · Runtime Performance · Checklist

## How v4 Generates CSS

Tailwind v4 scans source files for class-name candidates and generates CSS only for the utilities it finds. There is no separate purge step and nothing to enable.

Consequences:

- Output size tracks the number of distinct utilities used, not the size of the theme.
- Removing palette colors, spacing values, or breakpoints from `@theme` does not meaningfully shrink output. Unused theme variables are not emitted (unless `@theme static` is used). Trim the theme to constrain the design system, not to save bytes.
- Large output almost always means many distinct utilities (or arbitrary values) in source, overly broad safelists, or files being scanned that should not be.

## Content Detection

Detection is automatic. Tailwind scans the project and skips files in `.gitignore`, `node_modules`, binary files, CSS files, and lock files.

```css
@import "tailwindcss";
```

Register extra paths (relative to the stylesheet), for example a UI library inside `node_modules`:

```css
@import "tailwindcss";
@source "../node_modules/@acmecorp/ui-lib";
```

Exclude paths that produce false candidates (legacy code, fixtures, generated docs) with `@source not` (v4.1+):

```css
@import "tailwindcss";
@source not "../src/components/legacy";
```

Set the base directory for detection explicitly:

```css
@import "tailwindcss" source("../src");
```

Disable automatic detection and list every source by hand:

```css
@import "tailwindcss" source(none);
@source "../admin";
@source "../shared";
```

## Dynamic Class Names and Safelisting

Tailwind reads source files as plain text. It cannot see class names assembled at runtime.

```jsx
// Not detected: the full class never appears in source
<p className={`text-${color}-600`} />
```

Map values to complete class names instead:

```jsx
const textColor = {
  info: "text-blue-600",
  danger: "text-red-600",
  success: "text-green-600",
};

<p className={textColor[status]} />
```

For values that are truly runtime (user-chosen colors), set a CSS variable and use the variable shorthand:

```jsx
<div style={{ "--accent": userColor }} className="bg-(--accent)" />
```

When classes come from a CMS or database and cannot appear in source, safelist them with `@source inline()` (v4.1+). The input is brace-expanded:

```css
@import "tailwindcss";
@source inline("underline");
@source inline("{hover:,focus:,}underline");
@source inline("{hover:,}bg-red-{50,{100..900..100},950}");
```

`{hover:,}` generates both the base class and the `hover:` variant. Every expansion adds CSS, so keep safelists narrow.

Block classes that are detected but unwanted (false positives from content strings) with `@source not inline()` (v4.1+):

```css
@source not inline("container");
```

## Theme Size and Output

Resetting a namespace (`--color-*: initial;`) and redefining a small set is a design-constraint decision: it stops off-palette utilities from existing. It is not a bundle optimization.

```css
@theme {
  --color-*: initial;
  --color-surface: oklch(0.99 0 0);
  --color-ink: oklch(0.2 0 0);
  --color-primary: oklch(0.55 0.2 250);
}
```

Breakpoints use `rem` so variant ordering stays correct:

```css
@theme {
  --breakpoint-*: initial;
  --breakpoint-sm: 40rem;
  --breakpoint-lg: 64rem;
}
```

Spacing uses a single multiplier (`--spacing: 0.25rem`); there is no need to list individual spacing steps.

### `@theme static` and `@theme inline`

- Default `@theme`: only theme variables used by generated utilities are emitted to `:root`.
- `@theme static`: emits every theme variable even when unused. Output gets larger. Use it when JavaScript or third-party CSS reads the variables at runtime.
- `@theme inline`: utilities get the token's value inlined instead of `var(--token)`. Required when the value is `var(--x)`, so the reference resolves at the right scope. Theme switching then works by overriding `--x` under `.dark` or `[data-theme]`, not the inline `--color-*` variable. See v4-theme-advanced.md.

```css
@theme static {
  --color-primary: oklch(0.55 0.2 250);
}

@theme inline {
  --font-sans: var(--font-inter);
}
```

Neither option is a speed optimization; choose based on how the variables are consumed.

### Plugins

Each `@plugin` adds utilities only when they are used, but remove plugins the project does not use to keep the build simple. Container queries are built into v4 (`@container`, `@md:`); no plugin is needed.

## Multiple CSS Entry Points

Each stylesheet that contains `@import "tailwindcss"` is a full build: preflight, theme variables, and its own utilities. If two such stylesheets load on the same page, preflight and overlapping utilities are shipped twice and cascade order between them becomes unpredictable.

Trade-off:

- **One entry point** (default): one file, no duplication, simplest. Utilities from every route are included.
- **Separate entry points per app** (for example marketing site and admin served on different pages): fine when a page never loads both. Each file contains only the utilities found in its sources; use `source(none)` plus `@source` to scope them.

```css
/* admin.css */
@import "tailwindcss" source(none);
@source "../admin";
@source "../shared";
```

For component-scoped styles (Vue/Svelte `<style>` blocks, CSS modules) that need `@apply` or theme variables, use `@reference` instead of importing Tailwind again. It makes the theme available without emitting any CSS:

```vue
<style>
  @reference "../../app.css";

  h1 {
    @apply text-2xl font-bold;
  }
</style>
```

Bundler code-splitting (`manualChunks`, lazy-loaded CSS) only splits CSS files that already exist. It does not split Tailwind's generated utilities per route; a lazily loaded file that imports `tailwindcss` again duplicates preflight.

## Minification and Compression

- **Vite** (`@tailwindcss/vite`): production builds (`vite build`) are minified with no extra config.
- **CLI**: pass `--minify`.

```bash
npx @tailwindcss/cli -i ./src/app.css -o ./dist/app.css --minify
```

No separate CSS minifier (cssnano) or PurgeCSS step is needed.

Serve CSS with gzip or Brotli compression from the server or CDN. Tailwind output compresses very well because class patterns repeat.

## Measuring Output Size

Measure the built file, compressed as users receive it:

```bash
npm run build
ls -lh dist/assets/*.css
gzip -c dist/assets/*.css | wc -c
brotli -c dist/assets/*.css | wc -c
```

Typical production apps land in the tens of kilobytes uncompressed and well under that compressed. If output is unexpectedly large:

1. Count selectors to see what dominates:

   ```bash
   grep -o '\.[a-zA-Z0-9_\\:-]*' dist/assets/*.css | sort | uniq -c | sort -rn | head -20
   ```

2. Check for broad `@source inline()` expansions.
3. Check for scanned directories that should be excluded with `@source not` (v4.1+) (generated files, fixtures, vendored HTML).
4. Check for heavy use of one-off arbitrary values (`w-[317px]`) that could be tokens.

## Runtime Performance

### Transition specific properties

```html
<!-- Transitions every animatable property; avoid -->
<button class="transition-all">Save</button>

<!-- Transitions only what changes -->
<button class="bg-primary hover:bg-primary/90 transition-colors">Save</button>
```

### Animate `transform` and `opacity`

They can run on the compositor. Animating `top`/`left`, `width`/`height`, or `margin` triggers layout on every frame.

```html
<div class="translate-x-0 data-[open=true]:translate-x-64 transition-transform">...</div>
```

### `will-change` sparingly

Apply `will-change-transform` only to elements that animate continuously or are about to animate. Applied broadly, it wastes memory by promoting many layers.

```html
<div class="will-change-transform animate-spin">...</div>
```

### `content-visibility` for long off-screen content

Skips rendering work for sections outside the viewport. Use the `content-auto` utility (canonical definition with its intrinsic size estimate in v4-custom-utilities.md); override the size estimate per section when it differs.

```html
<section class="content-auto [contain-intrinsic-size:auto_40rem]">
  ...
</section>
```

## Checklist

- [ ] No dynamically concatenated class names
- [ ] Safelists (`@source inline()`) limited to classes that cannot appear in source
- [ ] Irrelevant directories excluded with `@source not`
- [ ] Only one stylesheet with `@import "tailwindcss"` loads per page; scoped styles use `@reference`
- [ ] Production build minified; server sends gzip/Brotli
- [ ] Compressed CSS size measured, not guessed
- [ ] Specific `transition-*` utilities, not `transition-all`
- [ ] Animations use `transform`/`opacity`; `will-change` only where needed
