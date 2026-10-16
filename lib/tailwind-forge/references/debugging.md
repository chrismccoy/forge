# Tailwind CSS Debugging

**Contents:** Classes Not Applying · Dynamic Class Names · Content Detection and @source · PostCSS and Vite Setup (v3 to v4) · Cascade Layers and Specificity · v4 Behavior Changes · Dark Variant Issues · Plugin Issues · Framework @reference Errors · HMR and Cache · IntelliSense · Inspecting Generated CSS · Error Messages · Checklist

## Classes Not Applying

Inspect the element in browser DevTools and classify the failure:

| DevTools shows | Cause | Section |
|----------------|-------|---------|
| Class on element, no matching rule in CSS | Class was never generated | Dynamic Class Names, Content Detection and @source |
| No Tailwind rules at all | Build not running or CSS not imported | PostCSS and Vite Setup (v3 to v4) |
| Rule present but crossed out | Another rule wins | Cascade Layers and Specificity |
| Rule present and active, looks different than v3 | Changed default | v4 Behavior Changes |

Confirm Tailwind is running with a temporary element:

```html
<div class="fixed top-0 right-0 z-50 bg-red-500 p-4 text-white">Tailwind running</div>
```

Breakpoint variants (`sm:`, `md:`, `lg:`) are viewport-based min-width queries. A narrow parent does not stop `md:` from matching; a wide parent does not make it match. To respond to a parent's width, use container queries (`@container` on the parent, `@md:` on the child). Breakpoint values and container query syntax: see responsive.md.

## Dynamic Class Names

Tailwind scans source files as plain text. It cannot evaluate interpolation, so constructed class names are never generated.

```tsx
// Not generated
<div className={`bg-${color}-500`} />

// Generated: every full class name appears in source
const bg = { primary: "bg-blue-500", danger: "bg-red-500" } as const;
<div className={bg[color]} />
```

When values come from a CMS or database and cannot appear in source, safelist them with `@source inline()` (v4.1+):

```css
@import "tailwindcss";
@source inline("{hover:,}bg-red-{50,{100..900..100},950}");
```

For arbitrary runtime values (user-chosen colors, computed sizes), set a CSS variable inline and reference it: `style={{ "--accent": color }}` with `bg-(--accent)`.

## Content Detection and @source

v4 scans the project automatically, relative to the current working directory. It skips files in `.gitignore`, `node_modules`, binary files, CSS files, and lock files.

Register extra paths relative to the stylesheet:

```css
@import "tailwindcss";
@source "../node_modules/@acme/ui";
@source not "../src/legacy";
```

`@source not` requires v4.1+.

Monorepos: the build often runs from the repo root, or shared packages live outside the app directory. Set the base path and register shared packages explicitly:

```css
@import "tailwindcss" source("../src");
@source "../../../packages/ui/src";
```

Full manual control:

```css
@import "tailwindcss" source(none);
@source "../admin";
@source "../shared";
```

Block classes that appear in source but must never be generated (for example, from test fixtures): `@source not inline("container");` (v4.1+).

## PostCSS and Vite Setup (v3 to v4)

The PostCSS plugin moved out of the `tailwindcss` package. `autoprefixer` and `postcss-import` are no longer needed.

```js
// postcss.config.mjs
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

With Vite, use the dedicated plugin instead of PostCSS:

```js
// vite.config.ts
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()],
});
```

Entry stylesheet replaces the three v3 directives:

```css
@import "tailwindcss";
```

Setup failures to check:

- `@tailwind base; @tailwind components; @tailwind utilities;` still present: replace with `@import "tailwindcss";`.
- Both the Vite plugin and the PostCSS plugin configured: keep one.
- Entry CSS not imported by the app entry point (`main.tsx`, root layout).
- `tailwind.config.js` still expected: v4 ignores it unless loaded with `@config "../tailwind.config.js";`. Move tokens to `@theme`.
- Entry file is `.scss`/`.less`: v4 is not designed to run with Sass, Less, or Stylus. Use plain `.css`.

## Cascade Layers and Specificity

v4 outputs native cascade layers in this order: `theme`, `base`, `components`, `utilities`. Later layers beat earlier layers regardless of selector specificity. Any unlayered CSS beats all layered CSS, regardless of source order or specificity.

Consequence: a plain rule such as `.card { padding: 2rem; }` overrides `p-4` on the same element, even when the rule appears before `@import "tailwindcss"`.

Place custom CSS in the correct layer so utilities can still override it:

```css
@import "tailwindcss";

@layer base {
  h1 { font-size: var(--text-2xl); }
}

@layer components {
  .card { padding: --spacing(8); border-radius: var(--radius-md); }
}
```

`<div class="card p-4">` now gets `p-4`, because `utilities` comes after `components`. Leave CSS unlayered only when it must beat utilities (third-party overrides).

When a utility must win over unlayered or third-party CSS, use the important modifier as a suffix (last resort):

```html
<div class="mt-0! hover:bg-red-500!">
```

Two conflicting utilities on one element (`p-2 p-4`) resolve by Tailwind's internal order, not class attribute order. Remove the unwanted one, or use `tailwind-merge` when composing classes from props.

## v4 Behavior Changes

Rules that generate correctly but look different from v3:

| Change | v4 behavior | Fix |
|--------|-------------|-----|
| `hover:` | Applies only inside `@media (hover: hover)`; tapping on touch devices does not trigger it | Do not rely on hover for touch. To restore: `@custom-variant hover (&:hover);` |
| Variant stacking | Applies left to right | Reverse order-sensitive stacks: v3 `first:*:pt-0` becomes `*:first:pt-0` |
| `space-x-*` / `space-y-*` | Selector is now `> :not(:last-child)` (v3 used `> :not([hidden]) ~ :not([hidden])`), so margins land on different children | Prefer `flex`/`grid` with `gap-*` |
| Border and divide color | `currentColor` instead of `gray-200` | Add a color (`border border-gray-200`) or the base rule below |
| `ring` | 1px `currentColor` instead of 3px blue | Use `ring-3 ring-blue-500` |
| Button cursor | `cursor: default` | Add `cursor-pointer`, or the base rule below |
| Placeholder | Current text color at 50% opacity instead of `gray-400` | Add `placeholder:text-gray-400`, or the base rule below |
| `outline-none` | Sets `outline-style: none` | Use `outline-hidden` (v3's `outline-none`) and keep a visible `focus-visible:` style |
| Important | `!` goes at the end: `flex!` | Prefix form is deprecated |

Base rules that restore v3 defaults (add only when migrating a v3 project):

```css
@layer base {
  *,
  ::after,
  ::before,
  ::backdrop,
  ::file-selector-button {
    border-color: var(--color-gray-200, currentColor);
  }

  button:not(:disabled),
  [role="button"]:not(:disabled) {
    cursor: pointer;
  }

  input::placeholder,
  textarea::placeholder {
    color: var(--color-gray-400);
  }
}
```

## Dark Variant Issues

By default, `dark:` follows `prefers-color-scheme`. No configuration is needed for that behavior.

For a manual toggle, override the variant and put the class on `<html>`:

```css
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

```html
<html class="dark">
```

Checks:

- `dark:` ignores the toggle: the `@custom-variant` override is missing, or the `.dark` class is on an element that does not contain the target.
- `dark:` applies while the toggle is off: no override exists, so the OS setting controls it.
- Data-attribute toggles need a matching selector: `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));`.
- Flash of light theme on load: set the class in an inline `<head>` script before first paint.

## Plugin Issues

Load v4 plugins in CSS, not a JS config:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
```

Typography:

- `prose` has no effect: the `@plugin` line is missing or the package is not installed.
- Element styles override utilities inside `prose`: use element modifiers (`prose-a:text-blue-600 prose-h1:text-4xl`).
- Embedded components inherit prose styles: wrap them in `not-prose`.

Forms:

- Styles leak onto every input: switch to opt-in classes.

```css
@plugin "@tailwindcss/forms" {
  strategy: "class";
}
```

```html
<input type="text" class="form-input" />
```

- `@tailwindcss/container-queries` is unnecessary in v4; container queries are built in. Remove the plugin.
- Third-party plugins written for v3 may fail to load. Check the plugin for a v4 release.

## Framework @reference Errors

Vue/Svelte/Astro `<style>` blocks and CSS modules are processed separately from the main stylesheet, so they have no theme. `@apply` with a theme utility fails with "Cannot apply unknown utility class".

```vue
<style scoped>
  @reference "../app.css";

  button {
    @apply bg-blue-500;
  }
</style>
```

`@reference` imports theme and utilities for lookup without emitting CSS. Use `@reference "tailwindcss";` when the project has no custom theme. Simpler alternative that skips Tailwind processing: `background-color: var(--color-blue-500);`.

`@apply` of a class defined in plain CSS also fails in v4. Define it with `@utility` instead:

```css
@utility btn {
  padding: --spacing(2) --spacing(4);
  border-radius: var(--radius-md);
}
```

## HMR and Cache

New classes not appearing during development:

1. Save the CSS entry file to force a rebuild.
2. Restart the dev server (required after adding `@source`, `@plugin`, or changing `postcss.config.mjs`/`vite.config.ts`).
3. Clear framework caches, then restart:

```bash
rm -rf node_modules/.vite   # Vite
rm -rf .next                # Next.js
rm -rf .svelte-kit          # SvelteKit
```

4. Hard-reload the browser to bypass cached CSS.

## IntelliSense

Install the extension `bradlc.vscode-tailwindcss`. No completions in a v4 project usually means the extension cannot find the CSS entry point.

```json
{
  "tailwindCSS.experimental.configFile": "src/app.css",
  "tailwindCSS.classFunctions": ["cn", "clsx", "cva"],
  "files.associations": { "*.css": "tailwindcss" }
}
```

- `experimental.configFile`: path to the CSS file containing `@import "tailwindcss"`.
- `classFunctions`: enables completions inside class-composition helpers.
- `files.associations`: stops the built-in CSS validator from flagging `@theme`, `@utility`, and `@custom-variant`.

Reload the extension after changes: Command Palette, "Tailwind CSS: Restart IntelliSense" or "Developer: Reload Window".

## Inspecting Generated CSS

Compile the stylesheet once and search it:

```bash
npx @tailwindcss/cli -i src/app.css -o /tmp/out.css
grep -n "bg-blue-500" /tmp/out.css
```

- Class missing from output: content detection or dynamic class name issue.
- Class present in output but not in the browser: the app loads a different or stale CSS file.

Theme variables: v4 emits only variables that are used. Spacing is one multiplier, `--spacing: 0.25rem`, not per-step variables. A missing `--color-*` in `:root` means nothing used it; use `@theme static` when JavaScript reads the variables.

## Error Messages

| Message | Cause | Fix |
|---------|-------|-----|
| "It looks like you're trying to use `tailwindcss` directly as a PostCSS plugin" | v3 PostCSS config | Install `@tailwindcss/postcss` and replace `tailwindcss: {}` |
| "Cannot find module '@tailwindcss/postcss'" / "'@tailwindcss/vite'" | Package not installed | `npm install -D tailwindcss @tailwindcss/postcss` (or `@tailwindcss/vite`) |
| "Unknown at rule @theme" / "@custom-variant" | Editor CSS linter, or v3 build tooling | Set `files.associations`; upgrade to v4 packages |
| "Cannot apply unknown utility class" | `@apply` in a separately processed file, an undefined token, or a plain CSS class | Add `@reference`; define the token in `@theme`; convert the class to `@utility` |
| `@tailwind` directives produce nothing | v3 entry syntax | Replace with `@import "tailwindcss";` |
| Sass errors on `@import "tailwindcss"` | Entry file is `.scss` | Rename to `.css`; drop Sass |

## Checklist

- [ ] `@import "tailwindcss";` in a `.css` entry imported by the app
- [ ] One of `@tailwindcss/vite` or `@tailwindcss/postcss` configured, not both
- [ ] Every class name appears complete in source
- [ ] Files outside the project root registered with `@source`
- [ ] Custom CSS placed in `@layer base` or `@layer components`
- [ ] v4 default changes accounted for (border color, ring, hover, space-*, cursor, placeholder)
- [ ] `@custom-variant dark` present if dark mode uses a class toggle
- [ ] Plugins loaded with `@plugin`
- [ ] `@reference` in component `<style>` blocks and CSS modules that use `@apply`
- [ ] Dev server restarted and caches cleared
