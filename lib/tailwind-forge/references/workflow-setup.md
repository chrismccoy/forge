# Tailwind CSS Setup

**Contents:** 1. Determine Project Type · 2. Install Dependencies · 3. Configure the Build Tool · 4. Create the CSS Entry Point · 5. Add Plugins (Optional) · 6. Import the CSS · 7. Recommend Developer Tools · 8. Verify Setup · Framework Notes · Output

Steps for configuring Tailwind CSS v4 in a new or existing project. Per-framework details are in `frameworks.md`.

## 1. Determine Project Type

Infer from the project before asking:

- **Build tool / framework**: `vite.config.*`, `next.config.*`, `nuxt.config.ts`, `svelte.config.js`, `astro.config.mjs`, `react-router.config.ts`, or none (CLI).
- **Package manager**: lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`).
- **Existing Tailwind**: `@tailwind` directives or a `tailwindcss@3` dependency mean a v3 project; migrate with `npx @tailwindcss/upgrade` instead of a fresh setup. A `tailwind.config.js` alone does not mean v3: a v4 project can still load it through `@config`.

Ask only for what cannot be detected.

## 2. Install Dependencies

Vite-based projects (React, Vue, Nuxt, SvelteKit, Astro, React Router):

```bash
npm install tailwindcss @tailwindcss/vite
```

Next.js and other PostCSS projects:

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

No bundler (Tailwind CLI):

```bash
npm install tailwindcss @tailwindcss/cli
```

## 3. Configure the Build Tool

Vite:

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss()],
});
```

PostCSS:

```js
// postcss.config.mjs
const config = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};

export default config;
```

CLI:

```bash
npx @tailwindcss/cli -i ./src/input.css -o ./src/output.css --watch
```

No `tailwind.config.js` and no `autoprefixer` are needed in v4.

## 4. Create the CSS Entry Point

```css
/* src/index.css, app/globals.css, or src/input.css */
@import "tailwindcss";

@theme {
  --color-brand-500: oklch(0.6 0.2 250);
  --font-sans: "Inter", system-ui, sans-serif;
}
```

Add tokens only for values the project actually uses. Content detection is automatic; add `@source "../packages/ui/src";` only for files outside the project root (for example a monorepo package).

For dark mode, see `dark-mode.md`; add it only when the project needs it.

## 5. Add Plugins (Optional)

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography"; /* prose styles for Markdown/CMS content */
@plugin "@tailwindcss/forms";      /* form element resets */
```

Container queries are built into v4 (`@container`, `@md:`); no plugin is needed.

## 6. Import the CSS

Import the entry file once at the app root: `main.tsx`/`main.ts` for Vite apps, `app/layout.tsx` for Next.js, `app/root.tsx` for React Router, `src/routes/+layout.svelte` for SvelteKit, a layout component for Astro, or the `css` array in `nuxt.config.ts`. For the CLI, link the generated `output.css` in HTML.

## 7. Recommend Developer Tools

Recommend the Tailwind CSS IntelliSense editor extension (`bradlc.vscode-tailwindcss`). Offer `prettier-plugin-tailwindcss` for automatic class sorting. Do not install unrequested tooling; if the user accepts, run:

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

```json
// .prettierrc
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

## 8. Verify Setup

Start the dev server and render:

```html
<h1 class="text-3xl font-bold underline">Hello world!</h1>
```

If the styles do not apply, check that the CSS file is imported, the plugin is registered, and the file containing the classes is not excluded by `.gitignore` (ignored files are not scanned).

## Framework Notes

- **Next.js**: CSS in `app/globals.css`, imported in `app/layout.tsx`.
- **Vue / Svelte / Astro scoped styles**: add `@reference "<path to main css>";` before using `@apply` (see `frameworks.md`).
- **Nuxt**: register `tailwindcss()` under `vite.plugins` in `nuxt.config.ts` and list the CSS file in `css`.
- **SvelteKit**: `npx sv add tailwindcss` performs the whole setup.
- **Astro**: use `@tailwindcss/vite` in `astro.config.mjs`, not `@astrojs/tailwind`.

## Output

Provide:

1. Install commands for the detected setup and package manager
2. Build tool configuration
3. CSS entry point with only the needed `@theme` tokens
4. Where to import the CSS
5. Verification step
