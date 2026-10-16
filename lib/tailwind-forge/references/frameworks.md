# Tailwind CSS Framework Setup

**Contents:** React with Vite · Next.js · Vue 3 · Nuxt · SvelteKit · Astro · React Router v7 · Scoped Styles and @reference · Shared Tooling

Per-framework installation for Tailwind v4, matching tailwindcss.com/docs/installation. Component examples live in `components.md`; React-specific patterns in `frameworks-react.md`; dark mode (including `next-themes`) in `dark-mode.md`.

Every setup ends with one CSS entry file:

```css
@import "tailwindcss";
```

## React with Vite

```bash
npm create vite@latest my-app -- --template react-ts
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

Put `@import "tailwindcss";` in `src/index.css` and import it once in `src/main.tsx` (`import './index.css';`).

## Next.js

`create-next-app` offers Tailwind during setup. For an existing project:

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

```js
// postcss.config.mjs
const config = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};

export default config;
```

```css
/* app/globals.css */
@import "tailwindcss";
```

```tsx
// app/layout.tsx
import './globals.css';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

Tailwind is build-time CSS, so utilities work the same in Server and Client Components. Remove any `tailwind.config.js` and `autoprefixer` left from v3; v4 handles vendor prefixes itself.

## Vue 3

```bash
npm create vue@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [vue(), tailwindcss()],
});
```

Put `@import "tailwindcss";` in `src/assets/main.css` and import it in `src/main.ts`.

## Nuxt

```bash
npm create nuxt@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```ts
// nuxt.config.ts
import tailwindcss from '@tailwindcss/vite';

export default defineNuxtConfig({
  css: ['~/assets/css/main.css'],
  vite: {
    plugins: [tailwindcss()],
  },
});
```

```css
/* app/assets/css/main.css */
@import "tailwindcss";
```

## SvelteKit

```bash
npx sv create my-app
cd my-app
npx sv add tailwindcss
```

`npx sv add tailwindcss` performs the steps below. Manual setup:

```bash
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()],
});
```

```svelte
<!-- src/routes/+layout.svelte (Svelte 5) -->
<script>
  import '../app.css';
  let { children } = $props();
</script>

{@render children()}
```

`src/app.css` contains `@import "tailwindcss";`. Svelte 5 uses `$props()` instead of `export let` and `{@render children()}` instead of `<slot />`.

## Astro

Use the Vite plugin. `@astrojs/tailwind` targets Tailwind v3 and is not used with v4.

```bash
npm create astro@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },
});
```

```astro
---
// src/layouts/Layout.astro
import '../styles/global.css';
---
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>My Site</title>
  </head>
  <body>
    <slot />
  </body>
</html>
```

`src/styles/global.css` contains `@import "tailwindcss";`.

## React Router v7

React Router v7 framework mode is the successor to Remix. It is Vite-based, so it uses `@tailwindcss/vite`.

```bash
npx create-react-router@latest my-app
cd my-app
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { reactRouter } from '@react-router/dev/vite';
import { defineConfig } from 'vite';
import tsconfigPaths from 'vite-tsconfig-paths';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [tailwindcss(), reactRouter(), tsconfigPaths()],
});
```

```tsx
// app/root.tsx
import { Links, Meta, Outlet, Scripts, ScrollRestoration } from 'react-router';
import './app.css';

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

export default function App() {
  return <Outlet />;
}
```

`app/app.css` contains `@import "tailwindcss";`. Existing Remix v2 Vite projects use the same plugin; add `tailwindcss()` next to `remix()`.

## Scoped Styles and @reference

Vue `<style scoped>`, Svelte `<style>`, Astro `<style>`, and CSS modules are processed separately from the main stylesheet. To use `@apply`, `theme()`, or custom utilities there, reference the main stylesheet. `@reference` imports definitions without emitting CSS.

```vue
<template>
  <h1>Hello world!</h1>
</template>

<style scoped>
@reference "../assets/main.css";

h1 {
  @apply text-2xl font-bold text-brand-600;
}
</style>
```

Use `@reference "tailwindcss";` when the project has no custom theme. Alternatively, skip `@apply` and read theme variables directly:

```css
h1 {
  font-size: var(--text-2xl);
  font-weight: var(--font-weight-bold);
  color: var(--color-blue-600);
}
```

By default only used theme variables are generated in the output CSS. If a variable is missing at runtime (for example, one read only from JavaScript), declare it in `@theme static { ... }`, which always emits every variable in that block.

## Shared Tooling

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

```json
// .prettierrc
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

Install the Tailwind CSS IntelliSense editor extension (`bradlc.vscode-tailwindcss`) for completion and linting.

For conditional class merging, use the single `cn()` helper defined in `components.md`.
