## Meta-framework rules (Next.js, Remix / React Router, Nuxt, SvelteKit, Astro)

These frameworks route by file path, export functions with reserved names, and split code between the server and the browser. A doc comment must say **where the code runs** and **which URL it serves**.

### Shared

- **File header for a route file:** the URL pattern the file serves, worked out from its path, whether it renders on the server, the client or both, and what it loads or mutates. Path rules:
  - Next.js: `[id]` → `:id`, `[...slug]` catch-all, `[[...slug]]` optional catch-all, `(group)` folders and `@slot` parallel routes are not in the URL, `(.)` / `(..)` intercepting routes say which route they intercept, `_folder` is private (not a route).
  - Remix / React Router 7: flat-route names (`notes.$id.tsx` → `/notes/:id`, `_index` is the index route, a leading `_` is a pathless layout, a trailing `_` opts out of nesting, `($lang)` is optional, `[.]` escapes a literal dot: `jokes[.]rss.tsx` → `/jokes.rss`; `.server` / `.client` module suffixes limit where a module runs), or the `routes.ts` config when there is one. When `routes.ts` delegates to a convention package (`@react-router/fs-routes` `flatRoutes()`, `remix-flat-routes`, `react-router-auto-routes`), apply that package's folder rules (a route folder's `route.tsx` or index file is the route; colocated helpers are not) and its `ignoredRouteFiles` patterns: an ignored file (`*.server.*`, `*.test.*`) is a module, not a route, and its header must not claim a URL.
  - SvelteKit: `[id]`, `[[optional]]`, `[...rest]`, `(group)` folders not in the URL, `[id=matcher]` with the matcher in `src/params/`.
  - Nuxt: `pages/[id].vue`, `[[optional]].vue`, `[...slug].vue`; `server/api/` paths start with `/api`.
- **Reserved exports** are documented with the role the framework gives them, not just what the code does: Next.js `generateMetadata`, `generateStaticParams`, `metadata`, `revalidate`, `dynamic`, `runtime`, route handlers `GET` / `POST` …; Remix / React Router `loader`, `action`, `meta`, `links`, `headers`, `handle` (route data read by `useMatches()`, such as breadcrumbs or a `getSitemapEntries` hook), `ErrorBoundary`; SvelteKit `load`, `actions`, `prerender`, `ssr`, `csr`, `entries`, `handle`, `handleError`; Nuxt `definePageMeta`, server `defineEventHandler`.
- **Directives:** `'use client'`, `'use server'`, `'use cache'` stay exactly where they are. The file header may sit above them. Say in the header what the directive means for the file (a client component boundary, server actions callable from the client).
- **Server actions and form actions** are public endpoints: document the inputs they accept, the auth they check, what they mutate, what they revalidate or redirect to, and the errors they return.
- **Caching:** document cache tags, `revalidatePath` / `revalidateTag` calls, `fetch` cache options, and ISR intervals with the reason for each.
- **Middleware** (Next `middleware.ts`, renamed `proxy.ts` in Next 16; SvelteKit `hooks.server.ts`, `hooks.client.ts` and `hooks.ts` `reroute`; Nuxt `server/middleware` and `defineNuxtRouteMiddleware`): the matcher or paths it runs on, what it reads (cookies, headers, geo), and what it rewrites, redirects or blocks.
- **Server-only modules** (`server-only` imports, `*.server.ts`, `$lib/server`, `server/`): say that they must never be imported from client code, and why (secrets, DB access).

### Next.js

- `app/` router: `page`, `layout`, `template`, `loading`, `error`, `not-found`, `default` (parallel-route fallback) and `route` files each get a header that names their role in the segment. Also `generateViewport`, and `instrumentation.ts` (`register`, `onRequestError`). `params` and `searchParams` (Promises in Next 15+) are documented as props.
- `pages/` router: `getServerSideProps`, `getStaticProps`, `getStaticPaths`, `pages/api/*` handlers (method checks, status codes).
- `next.config.*`: document each non-default option and why it is set. Keep the `@type {import('next').NextConfig}` line exactly (it is a kept type tag).

### Remix / React Router

- `loader` / `action` (server) and `clientLoader` / `clientAction` (browser), `shouldRevalidate`, `HydrateFallback`: the request data they read, the response or `json` / `data` they return (follow the shapes list), thrown `Response`s and redirects. `useLoaderData` / `useActionData` consumers reference the loader's shape.

### Nuxt

- `server/api/*` and `server/routes/*` handlers: method from the file suffix (`notes.get.ts`), path from the file path, inputs read with `getQuery` / `readBody` / `getRouterParam`, and errors from `createError`.
- `composables/`, `plugins/` (client or server suffix), `middleware/` (route middleware: global or named), `server/plugins/`, `server/utils/`, `nuxt.config.*` options.
- `useFetch` / `useAsyncData`: the key, the route called (route map), and when it refetches. `runtimeConfig` keys map to `NUXT_*` / `NUXT_PUBLIC_*` variables: list them in the env map.

### SvelteKit

- `+page.svelte` / `+layout.svelte` / `+error.svelte` get a component header naming the route. `*.remote.ts` remote functions (`query`, `command`, `form`) are public endpoints, like server actions.
- `+page.ts` / `+page.server.ts` / `+layout*.ts` `load` functions: where they run, what they return (the `data` prop shape), dependencies (`depends`, `invalidate`). `+server.ts` handlers per method. Form `actions` by name.

### Astro

- **In scope:** `.astro` components, but only their frontmatter (the TypeScript between the `---` fences at the top) and their plain `<script>` tags (TypeScript, bundled by Astro). A script with any attribute other than `src` (`is:inline`, `type="module"`, `define:vars`) is sent to the page as written, so it is markup: never comment inside it. The template markup, `{…}` expressions included, is compared byte for byte: never add `<!-- -->` or `{/* */}` comments there.
- **File header:** a `/** … */` block at the top of the frontmatter: what the component or page renders, its route (for files under `src/pages/`), and the layout it uses. A component without frontmatter needs none (coverage checks the header only in the frontmatter); describe it from its parent.
- **Props:** document `interface Props` and each member (they are the component's attributes), and say which come from `Astro.props` defaults.
- **Pages and endpoints:** a page under `src/pages/` documents its URL (file-system route, `[slug]` / `[...rest]` params) and `getStaticPaths()` (what it enumerates, and the `props` it passes). An endpoint (`src/pages/**/*.ts` exporting `GET`, `POST` …) is a route: method, path, inputs and response.
- **Content and config:** `src/content.config.ts` (or `src/content/config.ts`) collections and their zod schemas form shared shapes; `astro.config.mjs` integrations and `import.meta.env` / `astro:env` reads follow the env map.
- **Islands:** `client:load`, `client:idle`, `client:visible` directives are markup: leave them, and say in the island component's own header when it hydrates.
