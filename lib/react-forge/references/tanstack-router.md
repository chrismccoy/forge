# TanStack Router and TanStack Start

Covers TanStack Router 1.170 and TanStack Start 1.169 (the first stable Start release, Vite 8); load it when a project depends on `@tanstack/react-router` or `@tanstack/react-start`, or when choosing a type-safe router or full-stack framework for a Vite app.

## Contents

- [Router or Start](#router-or-start)
- [File-Based Routing](#file-based-routing)
- [Navigation and Type Safety](#navigation-and-type-safety)
- [Data Loading and Caching](#data-loading-and-caching)
- [Authenticated Routes](#authenticated-routes)
- [TanStack Start](#tanstack-start)
- [Start Middleware](#start-middleware)
- [Testing Routes](#testing-routes)

## Router or Start

TanStack Router is a client-side router with typed params, typed search params, loaders, and a built-in stale-while-revalidate cache. TanStack Start is a full-stack framework built entirely on Router. It adds full-document SSR, streaming, server functions, server routes, and middleware.

Choose Router for an SPA served as static files that talks to an existing API. Choose Start when the app needs SSR or streaming HTML, typed RPC to server code (database, secrets), HTTP endpoints next to UI routes, or request middleware.

Detect which one a project uses before writing code:

| Signal | Meaning |
|--------|---------|
| `@tanstack/react-router` in `package.json` | Router (always present, also with Start) |
| `@tanstack/react-start` in `package.json` | Start |
| `src/routeTree.gen.ts` exists | File-based routing with the generator |
| `tanstackRouter()` from `@tanstack/router-plugin/vite` in `vite.config.ts` | Router-only, file-based |
| `tanstackStart()` from `@tanstack/react-start/plugin/vite` in `vite.config.ts` | Start (includes the router generator; do not add `tanstackRouter()` too) |
| `src/router.tsx` exports `getRouter()` | Start |
| `src/start.ts` with `createStart` | Start with global middleware |
| `createRoute({ getParentRoute })` calls, no generator | Code-based routing |

Router-only Vite setup. Place the router plugin before the React plugin:

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { tanstackRouter } from '@tanstack/router-plugin/vite';

export default defineConfig({
  plugins: [
    tanstackRouter({ target: 'react', autoCodeSplitting: true }),
    react(),
  ],
});
```

## File-Based Routing

The generator scans `src/routes` and writes `src/routeTree.gen.ts`. Never edit the generated file; rename or move route files instead and let the plugin regenerate it. Exclude it from linters and formatters.

| File | URL | Notes |
|------|-----|-------|
| `__root.tsx` | (wraps everything) | Must be named exactly this, at the root of `src/routes` |
| `index.tsx` | `/` | `index` matches the parent path exactly |
| `posts.tsx` | `/posts` | Layout for `posts.*` children; renders `<Outlet />` |
| `posts.index.tsx` | `/posts` | Index child of `posts` |
| `posts.$postId.tsx` | `/posts/:postId` | Dynamic segment, `params.postId` |
| `files.$.tsx` | `/files/*` | Splat, value in `params._splat` |
| `_auth.tsx` | (no segment) | Pathless layout: wraps children without adding to the URL |
| `_auth.dashboard.tsx` | `/dashboard` | Child of the `_auth` layout |
| `posts_.$postId.edit.tsx` | `/posts/:postId/edit` | `_` suffix: not nested under the `posts` layout |
| `(marketing)/pricing.tsx` | `/pricing` | Route group folder, not part of the URL |
| `-components/Card.tsx` | (ignored) | `-` prefix: excluded from the route tree, for colocated files |
| `blog/post/route.tsx` | `/blog/post` | `route` file is the route for its directory |
| `script[.]js.tsx` | `/script.js` | Brackets escape special characters |

Dots and directories are interchangeable: `posts.$postId.tsx` and `posts/$postId.tsx` produce the same route.

Define each route with `createFileRoute`. The path string is written and kept in sync by the generator:

```tsx
// src/routes/posts.$postId.tsx
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params }) => fetchPost(params.postId),
  component: PostPage,
});

function PostPage() {
  const post = Route.useLoaderData();
  const { postId } = Route.useParams();
  return <article><h1>{post.title}</h1><p>ID {postId}</p></article>;
}
```

Use `createRootRouteWithContext` when loaders need shared dependencies (auth state, a `QueryClient`). The context type is enforced when the router is created:

```tsx
// src/routes/__root.tsx
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router';
import type { QueryClient } from '@tanstack/react-query';
import type { AuthState } from '../auth';

interface RouterContext {
  auth: AuthState;
  queryClient: QueryClient;
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: () => <Outlet />,
  notFoundComponent: () => <p>Page not found</p>,
});
```

Use plain `createRootRoute({ component })` when no context is needed.

Create the router and register its type once (Router-only apps). Registration makes `Link`, `useNavigate`, and every hook check paths and params against the real route tree:

```tsx
// src/main.tsx
import { createRouter, RouterProvider } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

const router = createRouter({
  routeTree,
  context: { auth: undefined!, queryClient },
  defaultPreload: 'intent',
});

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

function App() {
  const auth = useAuth();
  return <RouterProvider router={router} context={{ auth }} />;
}
```

In Start, export `getRouter()` from `src/router.tsx` instead. The generated route tree registers it automatically.

Code-based routing builds the same tree by hand. Use it only when the generator cannot run:

```tsx
import { createRootRoute, createRoute, createRouter } from '@tanstack/react-router';

const rootRoute = createRootRoute({ component: Layout });
const postRoute = createRoute({ getParentRoute: () => rootRoute, path: 'posts/$postId', component: PostPage });
export const router = createRouter({ routeTree: rootRoute.addChildren([postRoute]) });
```

## Navigation and Type Safety

Use `<Link>` for anything a user clicks. It renders a real `href` (so cmd/ctrl-click works), preloads, and exposes active state. `to`, `params`, and `search` are all type-checked:

```tsx
import { Link } from '@tanstack/react-router';

<Link to="/posts/$postId" params={{ postId: post.id }}>{post.title}</Link>
<Link to="/posts" search={{ page: 2, sort: 'newest' }} activeProps={{ className: 'font-bold' }}>Posts</Link>

// Update one search param, keep the rest
<Link from={Route.fullPath} search={(prev) => ({ ...prev, page: prev.page + 1 })}>
  Next
</Link>
```

Active links also get `data-status="active"` for CSS styling.

Use `useNavigate` only for side-effect navigation, such as after a successful mutation:

```tsx
const navigate = useNavigate({ from: '/posts/$postId' });

async function onSave(values: PostInput) {
  const saved = await savePost(values);
  await navigate({ to: '/posts/$postId', params: { postId: saved.id }, replace: true });
}
```

Throw `redirect()` and `notFound()` from `beforeLoad` or `loader`. `redirect` accepts the same options as `navigate`:

```tsx
import { createFileRoute, notFound, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPost(params.postId);
    if (!post) throw notFound();
    if (post.movedTo) throw redirect({ to: '/posts/$postId', params: { postId: post.movedTo } });
    return post;
  },
  notFoundComponent: () => <p>Post not found</p>,
});
```

Read route state with the route-bound hooks (`Route.useParams()`, `Route.useSearch()`, `Route.useLoaderData()`, `Route.useRouteContext()`). In a component file that does not import `Route`, use `getRouteApi('/posts/$postId')` or pass `{ from: '/posts/$postId' }` to `useParams`/`useSearch`.

### Typed Search Params

Validate search params with `validateSearch`. With Zod 4 (or any Standard Schema library), pass the schema directly; no adapter is needed. Use `.catch()` so a malformed URL falls back to defaults instead of rendering the error component:

```tsx
import { createFileRoute } from '@tanstack/react-router';
import { z } from 'zod';

const productSearch = z.object({
  page: z.number().int().positive().catch(1),
  q: z.string().catch(''),
  sort: z.enum(['newest', 'oldest', 'price']).catch('newest'),
});

export const Route = createFileRoute('/products')({
  validateSearch: productSearch,
  component: Products,
});

function Products() {
  const { q } = Route.useSearch();
  const navigate = Route.useNavigate();
  const setQuery = (value: string) => navigate({ search: (prev) => ({ ...prev, q: value, page: 1 }) });
  return <input value={q} onChange={(e) => setQuery(e.target.value)} />;
}
```

On Zod 3, wrap the schema with `zodValidator(schema)` from `@tanstack/zod-adapter` and use its `fallback()` helper. Use `.default()` instead of `.catch()` when invalid input should surface through `errorComponent`.

Treat search params as URL state: filters, pagination, tabs, and sort order belong here instead of `useState` (see [state-management.md](state-management.md)).

### Outlets, Pending UI, and Preloading

- Render `<Outlet />` in every layout route (including pathless `_layout` routes) where children should appear.
- Show a global progress indicator with `useRouterState({ select: (s) => s.isLoading })`.
- A route's `pendingComponent` appears after `pendingMs` (default 1000 ms) and stays at least `pendingMinMs` (default 500 ms) to avoid flashing. Configure router-wide with `defaultPendingMs` / `defaultPendingMinMs` / `defaultPendingComponent`.
- Set `defaultPreload: 'intent'` on the router to preload a route's code and loader on hover or focus (after `defaultPreloadDelay`, 50 ms by default). Override per link with `preload` and `preloadDelay`. Other strategies: `'viewport'` and `'render'`.

## Data Loading and Caching

Each route runs in this order: `validateSearch` and param parsing (top-down), then `beforeLoad` (parent before child, serially), then all matched `loader`s in parallel. Throwing in a parent `beforeLoad` stops its children from loading.

```tsx
export const Route = createFileRoute('/posts')({
  validateSearch: z.object({ offset: z.number().catch(0), limit: z.number().catch(20) }),
  // Only these values form the cache key; changing them reloads regardless of staleTime
  loaderDeps: ({ search: { offset, limit } }) => ({ offset, limit }),
  loader: ({ deps: { offset, limit }, abortController }) =>
    fetchPosts({ offset, limit, signal: abortController.signal }),
  staleTime: 10_000,
  pendingComponent: () => <PostsSkeleton />,
  errorComponent: PostsError,
  component: PostsPage,
});
```

Return only the search values the loader actually uses from `loaderDeps`. Returning the whole `search` object creates a new cache entry for every unrelated param change.

### Built-In Cache

Router caches loader results per route and `loaderDeps` key with stale-while-revalidate semantics:

| Option | Default | Effect |
|--------|---------|--------|
| `staleTime` / `defaultStaleTime` | `0` | Data is stale immediately; revisiting reloads in the background |
| `defaultPreloadStaleTime` | 30 s | Preloaded data stays fresh this long, so the click reuses it |
| `gcTime` / `defaultGcTime` | 5 min | Unused entries become eligible for removal |
| `shouldReload` | — | `false` or a function; combine with `gcTime: 0` to load only on entry |

Set `staleTime: Infinity` for data that never changes during a session. After a mutation, call `router.invalidate()` to mark loader data stale and reload active routes; `await router.invalidate({ sync: true })` waits for the reload to finish.

### Error and Not-Found Components

`errorComponent` receives `{ error, reset }`, and `error` is `unknown`, so narrow it. For loader errors, retry with `router.invalidate()` rather than `reset()`, because invalidation reloads the loader and resets the boundary together:

```tsx
import { ErrorComponent, useRouter, type ErrorComponentProps } from '@tanstack/react-router';

function PostsError({ error }: ErrorComponentProps) {
  const router = useRouter();
  if (!(error instanceof ApiError)) return <ErrorComponent error={error} />;
  return <button onClick={() => router.invalidate()}>{error.message}. Retry</button>;
}
```

`notFoundComponent` renders for `throw notFound()` and unmatched URLs. With the default `notFoundMode: 'fuzzy'`, the nearest matching route that has a `notFoundComponent` handles it; set `notFoundMode: 'root'` to always use the root's.

### External Cache with TanStack Query

Use TanStack Query when data is shared across routes, needs background refetching, or is invalidated by mutations. The router coordinates when to load, and Query owns the data. Put the `QueryClient` in router context (`context: { queryClient }`) and set `defaultPreloadStaleTime: 0` on the router so every preload calls the loader and Query decides whether to fetch. Share one `queryOptions` object between the loader and the component:

```tsx
import { queryOptions, useSuspenseQuery } from '@tanstack/react-query';

const postQuery = (postId: string) =>
  queryOptions({ queryKey: ['post', postId], queryFn: () => fetchPost(postId) });

export const Route = createFileRoute('/posts/$postId')({
  loader: ({ context: { queryClient }, params }) =>
    // Returns cached data when present, otherwise fetches (TanStack Query 5.102+)
    queryClient.query({ ...postQuery(params.postId), staleTime: 'static' }),
  component: PostPage,
});

function PostPage() {
  const { postId } = Route.useParams();
  const { data: post } = useSuspenseQuery(postQuery(postId));
  return <h1>{post.title}</h1>;
}
```

`queryClient.query({ ...options, staleTime: 'static' })` replaces the deprecated `ensureQueryData` from TanStack Query 5.102. Pass `queryClient.query(options)` instead to respect the query's own `staleTime`. On versions before 5.102, use `queryClient.ensureQueryData(options)`. Include every search value the query depends on in both `loaderDeps` and the query key. See [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md) for query and mutation patterns.

When Query errors in a suspense route, call `useQueryErrorResetBoundary().reset()` in an effect inside `errorComponent`, then `router.invalidate()` on retry.

### Deferred Data

Await critical data and return slow data as an unawaited promise. The route renders as soon as awaited data resolves; `<Await>` suspends only its subtree:

```tsx
import { Await, createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const commentsPromise = fetchComments(params.postId); // not awaited
    const post = await fetchPost(params.postId);
    return { post, commentsPromise };
  },
  component: PostPage,
});

function PostPage() {
  const { post, commentsPromise } = Route.useLoaderData();
  return (
    <Await promise={commentsPromise} fallback={<p>Loading comments…</p>}>
      {(comments) => <CommentList post={post} comments={comments} />}
    </Await>
  );
}
```

On React 19, read the promise with `use()` inside a `<Suspense>` boundary instead of `<Await>`. A rejected promise throws to the nearest error boundary.

## Authenticated Routes

Pass auth state from React into router context, then guard a pathless layout with `beforeLoad`. Every child of `_authenticated` inherits the check:

```tsx
// src/routes/_authenticated.tsx
import { createFileRoute, isRedirect, Outlet, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/_authenticated')({
  beforeLoad: async ({ context, location }) => {
    try {
      const user = await context.auth.ensureUser(); // may throw on network failure
      if (!user) {
        throw redirect({ to: '/login', search: { redirect: location.href } });
      }
      return { user }; // added to context for child routes
    } catch (error) {
      if (isRedirect(error)) throw error;
      throw redirect({ to: '/login', search: { redirect: location.href } });
    }
  },
  component: () => <Outlet />,
});
```

Child routes read `context.user` in their own `beforeLoad` for role checks, for example `if (context.user.role !== 'admin') throw redirect({ to: '/' })` in `src/routes/_authenticated/admin.tsx`.

After login, send the user back with `router.history.push(search.redirect)` (validate that `redirect` is a same-origin relative path first to avoid an open redirect). After login or logout, call `router.invalidate()` so every `beforeLoad` reruns with the new state, and remove the previous account's cached queries.

Client-side guards are UX only. Anyone can call the API directly or edit the bundle. Every API endpoint, server function, and server route that returns or changes private data must authenticate the caller and check ownership on the server, regardless of what the route guard did.

## TanStack Start

Install Start, Router, and the Vite React plugin. Start requires Vite 8:

```bash
npm i @tanstack/react-start @tanstack/react-router react react-dom
npm i -D vite @vitejs/plugin-react typescript @types/react @types/react-dom @types/node
```

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import { tanstackStart } from '@tanstack/react-start/plugin/vite';
import viteReact from '@vitejs/plugin-react';

export default defineConfig({
  resolve: { tsconfigPaths: true },
  plugins: [
    tanstackStart(),
    viteReact(), // must come after tanstackStart()
  ],
});
```

Export a `getRouter` factory. Start creates a new router per SSR request, so create request-scoped state (such as a `QueryClient`) inside it, never at module scope, or one user's data can leak into another user's HTML:

```tsx
// src/router.tsx
import { createRouter } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

export function getRouter() {
  return createRouter({ routeTree, scrollRestoration: true, defaultPreload: 'intent' });
}
```

The root route renders the whole document with `<HeadContent />` and `<Scripts />`:

```tsx
// src/routes/__root.tsx
import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router';
import type { ReactNode } from 'react';

export const Route = createRootRoute({
  head: () => ({
    meta: [{ charSet: 'utf-8' }, { name: 'viewport', content: 'width=device-width, initial-scale=1' }],
  }),
  component: () => <RootDocument><Outlet /></RootDocument>,
});

function RootDocument({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head><HeadContent /></head>
      <body>{children}<Scripts /></body>
    </html>
  );
}
```

Route loaders are isomorphic: they run on the server for the first request and in the browser on client navigation. Put database access and secrets in server functions, not directly in loaders.

For TanStack Query in Start, add `@tanstack/react-router-ssr-query` and call `setupRouterSsrQueryIntegration({ router, queryClient })` inside `getRouter`; it provides `QueryClientProvider` and handles dehydration, hydration, and streaming.

### Server Functions

`createServerFn` defines server-only code that the client calls as a typed RPC. The build replaces the implementation with a `fetch` stub in the client bundle, so static imports from client files are safe. Avoid dynamic `import()` of server function modules.

Validate input with `.validator()`. It accepts a Zod 4 schema directly (Standard Schema) or a function. `.inputValidator()` from the release candidates was removed in 1.169:

```ts
// src/server/posts.functions.ts
import { createServerFn } from '@tanstack/react-start';
import { notFound } from '@tanstack/react-router';
import { z } from 'zod';
import { authMiddleware } from './auth-middleware';
import { db } from './db.server';

export const getPost = createServerFn({ method: 'GET' })
  .validator(z.object({ id: z.uuid() }))
  .handler(async ({ data }) => {
    const post = await db.post.findUnique({ where: { id: data.id, published: true } });
    if (!post) throw notFound();
    return post;
  });

const UpdatePost = z.object({ id: z.uuid(), title: z.string().min(1).max(200) });

export const updatePost = createServerFn({ method: 'POST' })
  .middleware([authMiddleware])
  .validator(UpdatePost)
  .handler(async ({ data, context }) => {
    // Scope the write to the caller: never trust an id alone
    const result = await db.post.updateMany({
      where: { id: data.id, authorId: context.session.userId },
      data: { title: data.title },
    });
    if (result.count === 0) throw new Error('Not found');
    return { ok: true };
  });
```

Organize by suffix: `*.functions.ts` exports `createServerFn` wrappers (importable anywhere), `*.server.ts` holds server-only helpers imported only inside handlers, and unsuffixed files hold client-safe schemas and types. Do not enable `verbatimModuleSyntax`; it can leak server code into client bundles.

Call server functions with a single `{ data }` argument, from loaders, event handlers, other server functions, or through `useServerFn` in components (which routes thrown `redirect`/`notFound` through the router):

```tsx
import { useServerFn } from '@tanstack/react-start';
import { useRouter } from '@tanstack/react-router';

export const Route = createFileRoute('/posts/$postId')({
  loader: ({ params }) => getPost({ data: { id: params.postId } }),
  component: PostPage,
});

function PostPage() {
  const post = Route.useLoaderData();
  const router = useRouter();
  const update = useServerFn(updatePost);

  async function rename(title: string) {
    await update({ data: { id: post.id, title } });
    await router.invalidate();
  }
  // ...
}
```

Treat every server function as a public HTTP endpoint. A route guard does not protect it, because it can be called directly. In each one that touches private data: authenticate (middleware or an in-handler check), validate input with `.validator()`, and scope reads and writes to the authenticated user. Start installs CSRF protection for server functions automatically only when the app has no `src/start.ts`; once that file exists, register `createCsrfMiddleware()` explicitly (see [Start Middleware](#start-middleware)).

### Request and Response Helpers

Import request and response helpers from `@tanstack/react-start/server` and call them inside handlers or middleware:

```ts
import { createServerFn } from '@tanstack/react-start';
import { setResponseHeaders } from '@tanstack/react-start/server';

export const getCatalog = createServerFn({ method: 'GET' }).handler(async () => {
  // Public, identical for every user: shared caches may store it
  setResponseHeaders(new Headers({ 'Cache-Control': 'public, max-age=300' }));
  return fetchCatalog();
});

export const getMyOrders = createServerFn({ method: 'GET' })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    // Personalized: never 'public'
    setResponseHeaders(new Headers({ 'Cache-Control': 'private, no-store' }));
    return db.order.findMany({ where: { userId: context.session.userId } });
  });
```

Other helpers: `getRequest()`, `getRequestHeader(name)`, `setResponseHeader(name, value)`, `setResponseStatus(code)`, `getCookie`, `setCookie`. Use `setCookie` (not `setResponseHeader('set-cookie', ...)`, which replaces all outgoing cookies) to add a cookie. Use `redirect()` to redirect, not a `Location` header. For page responses, set headers with the route's `headers` option, for example `headers: () => ({ 'Cache-Control': 'private, no-store' })` on any route that renders session data.

### Server Routes

Add a `server` property to `createFileRoute` to handle raw HTTP in the same `src/routes` tree. Use server routes for endpoints called from outside the app (webhooks, public APIs, file downloads); use server functions for calls from the app's own UI:

```ts
// src/routes/api/posts.$id.ts
import { createFileRoute } from '@tanstack/react-router';
import { z } from 'zod';

const Body = z.object({ title: z.string().min(1).max(200) });

export const Route = createFileRoute('/api/posts/$id')({
  server: {
    middleware: [apiAuthMiddleware], // request middleware that verifies a token and sets context.userId
    handlers: {
      PUT: async ({ request, params, context }) => {
        const parsed = Body.safeParse(await request.json().catch(() => undefined)); // malformed JSON -> 400, not 500
        if (!parsed.success) return Response.json(parsed.error.issues, { status: 400 });
        const result = await db.post.updateMany({
          where: { id: params.id, authorId: context.userId },
          data: parsed.data,
        });
        return result.count ? new Response(null, { status: 204 }) : new Response('Not found', { status: 404 });
      },
    },
  },
});
```

Handlers receive `{ request, params, context }` and return a `Response`. Use `handlers: ({ createHandlers }) => createHandlers({ GET: { middleware: [...], handler } })` to attach middleware to a single method. A file can define both `server` handlers and a `component`.

## Start Middleware

Create middleware with `createMiddleware` from `@tanstack/react-start`. There are two kinds:

| | Request middleware (default) | Function middleware (`{ type: 'function' }`) |
|---|---|---|
| Runs for | Every server request: SSR, server routes, server functions | Server functions only |
| Methods | `.middleware()`, `.server()` | `.middleware()`, `.validator()`, `.client()`, `.server()` |
| Can depend on | Request middleware | Both kinds |

Every `.server()` and `.client()` callback must call and return `next()`. Pass `{ context: {...} }` to `next` to add typed context for downstream middleware and the handler:

```ts
// src/server/auth-middleware.ts
import { createMiddleware } from '@tanstack/react-start';
import { getAppSession } from './session.server';

export const authMiddleware = createMiddleware({ type: 'function' }).server(async ({ next }) => {
  const session = await getAppSession(); // reads the cookie on the server
  if (!session.userId) throw new Error('Unauthorized');
  return next({ context: { session: { userId: session.userId } } });
});

export const adminMiddleware = createMiddleware({ type: 'function' })
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    const user = await db.user.findUnique({ where: { id: context.session.userId } });
    if (user?.role !== 'admin') throw new Error('Forbidden');
    return next({ context: { user } });
  });
```

A logging middleware that times every request:

```ts
import { createMiddleware } from '@tanstack/react-start';

export const loggingMiddleware = createMiddleware().server(async ({ next, request }) => {
  const start = performance.now();
  try { return await next(); }
  finally { console.info(`${request.method} ${request.url} ${Math.round(performance.now() - start)}ms`); }
});
```

Use `.client()` on function middleware to run code in the browser around the RPC, for example adding a header:

```ts
export const traceMiddleware = createMiddleware({ type: 'function' }).client(async ({ next }) => {
  return next({ headers: { 'X-Request-ID': crypto.randomUUID() } });
});
```

Client context is not sent to the server unless `sendContext` is passed to `next` in `.client()`. Anything sent that way is attacker-controlled: validate it, check the session principal may access it, and never derive identity from it.

Attach middleware to a server function with `.middleware([...])`, followed by `.validator()` and `.handler()`. Order is dependency-first: global middleware, then each listed middleware's dependencies, then the middleware itself, then the handler.

### Global Middleware

Register global middleware in `src/start.ts`. Adding this file disables the automatic CSRF protection for server functions, so include `createCsrfMiddleware` explicitly:

```ts
// src/start.ts
import { createCsrfMiddleware, createStart } from '@tanstack/react-start';
import { loggingMiddleware } from './server/logging-middleware';
import { traceMiddleware } from './server/trace-middleware';

const csrfMiddleware = createCsrfMiddleware({
  filter: (ctx) => ctx.handlerType === 'serverFn',
});

export const startInstance = createStart(() => ({
  requestMiddleware: [csrfMiddleware, loggingMiddleware], // every request
  functionMiddleware: [traceMiddleware], // every server function
}));
```

Middleware authenticates the caller; it does not authorize access to the specific rows a handler reads or writes. Inside each handler, re-check ownership against `context.session.userId` (a `where` clause on the owner, a membership lookup, or a permission check). A well-formed ID from validated input or `sendContext` is not an authorized ID.

## Testing Routes

Render routes in tests with a memory history so each test controls the starting URL without touching `window.location`:

```tsx
import { render, screen } from '@testing-library/react';
import { createMemoryHistory, createRootRoute, createRoute, createRouter, Outlet, RouterProvider } from '@tanstack/react-router';

test('renders a post from its loader', async () => {
  const rootRoute = createRootRoute({ component: () => <Outlet /> });
  const postRoute = createRoute({
    getParentRoute: () => rootRoute,
    path: '/posts/$postId',
    loader: ({ params }) => ({ title: `Post ${params.postId}` }),
    component: function Post() {
      const { title } = postRoute.useLoaderData();
      return <h1>{title}</h1>;
    },
  });

  const router = createRouter({
    routeTree: rootRoute.addChildren([postRoute]),
    history: createMemoryHistory({ initialEntries: ['/posts/42'] }),
  });
  render(<RouterProvider router={router} />);

  expect(await screen.findByRole('heading', { name: 'Post 42' })).toBeInTheDocument();
});
```

- Use `findBy*` queries: loaders and route matching are async.
- Pass a test `context` (fake auth, a fresh `QueryClient` with `retry: false`) to `createRouter` when routes use `createRootRouteWithContext`.
- Mock server functions at the module boundary (`vi.mock('~/server/posts.functions')`) in component tests; cover the real handlers, middleware, and ownership checks in server-side tests or end-to-end tests.

See [testing.md](testing.md) for setup and [testing-recipes.md](testing-recipes.md) for async and mocking recipes.
