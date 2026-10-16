# Tailwind CSS Plugins

**Contents:** Official Plugins · Built In, No Plugin Needed · Creating Custom Plugins (v4) · Community Plugins · Best Practices

## Official Plugins

### @tailwindcss/typography

Typographic defaults for content not controlled by the template (Markdown, CMS output).

#### Installation

```bash
npm install -D @tailwindcss/typography
```

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

#### Basic Usage

```html
<article class="prose">
  <h1>Article Title</h1>
  <p>Rendered Markdown gets consistent styles.</p>
</article>
```

#### Size Modifiers

| Class | Body font size |
|-------|----------------|
| `prose-sm` | 0.875rem (14px) |
| `prose-base` (default) | 1rem (16px) |
| `prose-lg` | 1.125rem (18px) |
| `prose-xl` | 1.25rem (20px) |
| `prose-2xl` | 1.5rem (24px) |

```html
<article class="prose md:prose-lg">...</article>
```

#### Gray Scales

`prose-gray` (default), `prose-slate`, `prose-zinc`, `prose-neutral`, `prose-stone`. Match the project's neutral palette.

#### Dark Mode

Only if the project uses dark mode:

```html
<article class="prose dark:prose-invert">...</article>
```

#### Element Modifiers

Override specific elements with `prose-{element}:{utility}`. Available: `headings`, `lead`, `h1`-`h4`, `p`, `a`, `blockquote`, `figure`, `figcaption`, `strong`, `em`, `kbd`, `code`, `pre`, `ol`, `ul`, `li`, `dl`, `dt`, `dd`, `table`, `thead`, `tr`, `th`, `td`, `img`, `picture`, `video`, `hr`.

```html
<article class="prose prose-a:text-brand-600 prose-headings:font-display prose-img:rounded-md">
  Content
</article>
```

#### Max Width Control

```html
<article class="prose max-w-none">Full-width content</article>
```

#### Escaping Prose Styles

```html
<article class="prose">
  <p>Styled paragraph</p>

  <div class="not-prose">
    <!-- This subtree is excluded from prose styles -->
  </div>
</article>
```

`not-prose` is never prefixed, even when the project uses a utility prefix.

#### Custom Class Name

```css
@plugin "@tailwindcss/typography" {
  className: wysiwyg;
}
```

```html
<article class="wysiwyg">Content</article>
```

### @tailwindcss/forms

Resets form controls to an easily styled baseline.

#### Installation

```bash
npm install -D @tailwindcss/forms
```

```css
@import "tailwindcss";
@plugin "@tailwindcss/forms";
```

By default the plugin restyles text-like inputs (`text`, `email`, `url`, `password`, `number`, `date`, `datetime-local`, `month`, `search`, `tel`, `time`, `week`), `checkbox`, `radio`, `select`, `select[multiple]`, and `textarea`.

#### Basic Usage

```html
<input type="email" class="rounded-md border-gray-300 focus:border-brand-500 focus:ring-brand-500">

<select class="rounded-md border-gray-300">
  <option>Option 1</option>
  <option>Option 2</option>
</select>

<input type="checkbox" class="rounded-sm text-brand-600 focus:ring-brand-500">

<textarea class="rounded-md border-gray-300" rows="4"></textarea>
```

#### Strategy Option

`strategy: "base"` generates only global element styles. `strategy: "class"` generates only opt-in classes, which avoids clashing with existing form styles:

```css
@plugin "@tailwindcss/forms" {
  strategy: "class";
}
```

```html
<input type="text" class="form-input rounded-md">
<select class="form-select rounded-md"></select>
<textarea class="form-textarea rounded-md"></textarea>
<input type="checkbox" class="form-checkbox rounded-sm">
<input type="radio" class="form-radio">
```

| Class | Element |
|-------|---------|
| `form-input` | Text-like inputs |
| `form-textarea` | `textarea` |
| `form-select` | `select` |
| `form-multiselect` | `select[multiple]` |
| `form-checkbox` | Checkboxes |
| `form-radio` | Radio buttons |

Without the plugin, `accent-*` (`accent-brand-600`) tints native checkboxes and radios.

## Built In, No Plugin Needed

- **Container queries:** `@tailwindcss/container-queries` is not needed in v4. Remove the install and `@plugin` line. Use `@container`, `@md:`, `@max-md:`, `@min-[400px]:`, and named containers (`@container/sidebar` with `@md/sidebar:`). See responsive.md.
- **Text shadow:** `text-shadow-*` is a core utility since v4.1. Remove text-shadow plugins.
- **Line clamp, aspect ratio:** core utilities (`line-clamp-*`, `aspect-*`). Remove `@tailwindcss/line-clamp` and `@tailwindcss/aspect-ratio`.

## Creating Custom Plugins (v4)

Order of preference:

1. `@utility` for a custom class (see v4-custom-utilities.md).
2. `@custom-variant` for a custom state.
3. A JavaScript plugin only when CSS cannot express it (generating many utilities from external data, publishing a reusable package).

### CSS-Only Utilities

Define custom classes with `@utility`; see v4-custom-utilities.md for canonical examples such as `content-auto` and `scrollbar-hide`.

### JavaScript Plugin (Last Resort)

v4 loads JS plugins with `@plugin`. Read theme values as CSS variables (`var(--spacing)`, `var(--color-*)`); the v3 `theme('spacing.2')` dot paths are legacy.

```javascript
// my-plugin.js
import plugin from 'tailwindcss/plugin'

export default plugin(function ({ addUtilities }) {
  addUtilities({
    '.pad-safe-y': {
      paddingTop: 'max(calc(var(--spacing) * 4), env(safe-area-inset-top))',
      paddingBottom: 'max(calc(var(--spacing) * 4), env(safe-area-inset-bottom))',
    },
  })
})
```

```css
@import "tailwindcss";
@plugin "./my-plugin.js";
```

The same result in CSS, which is preferred:

```css
@utility pad-safe-y {
  padding-top: max(calc(var(--spacing) * 4), env(safe-area-inset-top));
  padding-bottom: max(calc(var(--spacing) * 4), env(safe-area-inset-bottom));
}
```

### Custom Variants

Do not recreate built-in variants (`peer-checked:`, `group-focus-visible:`, `not-first:`, `not-last:`, `data-*:`, `aria-*:`). Add only genuinely new ones:

```css
@custom-variant hocus (&:hover, &:focus-visible);
```

## Community Plugins

| Package | Purpose |
|---------|---------|
| `tw-animate-css` | Enter/exit animation classes (`animate-in`, `fade-in`); replaces `tailwindcss-animate` |
| `tailwindcss-motion` | Motion/animation utilities |
| `tailwind-scrollbar` | Scrollbar styling |

Check each package's README for v4 support before installing.

### tw-animate-css

A CSS import, not a `@plugin`:

```bash
npm install -D tw-animate-css
```

```css
@import "tailwindcss";
@import "tw-animate-css";
```

```html
<div class="animate-in fade-in slide-in-from-bottom-4 duration-300 motion-reduce:animate-none">
  Dialog content
</div>
```

Use enter/exit animations for elements that actually appear or disappear (dialogs, popovers, toasts), not for static content.

## Best Practices

### 1. Load Only What Is Used

Remove `@plugin` lines for plugins no template uses.

### 2. Prefer CSS Over JavaScript

Reach for `@utility` and `@custom-variant` before writing a plugin. JS plugins add a build dependency and use a legacy API surface.

### 3. Verify v4 Compatibility When Upgrading

```bash
npm outdated | grep tailwind
npm update @tailwindcss/typography @tailwindcss/forms
```

v3-only community plugins (those relying on `theme()` dot paths, `:merge()`, or `tailwind.config.js`) need a v4 release or replacement.
