# React Router Routing, Data Loading, and Middleware

Covers React Router 7.9+ and 8.x (8.4 is current as of this writing), with a focus on framework mode. Load this file when a project depends on `react-router`, `@react-router/dev`, or `react-router-dom`, or when adding routes, loaders, actions, caching, or middleware.

## Contents

- [Modes and How to Detect Them](#modes-and-how-to-detect-them)
- [Routing in Framework Mode](#routing-in-framework-mode)
- [Navigation](#navigation)
- [Data Loading](#data-loading)
- [Mutations and Actions](#mutations-and-actions)
- [Caching and Revalidation](#caching-and-revalidation)
- [Middleware and Context](#middleware-and-context)
- [Pre-rendering and SPA Mode](#pre-rendering-and-spa-mode)
- [Testing Routes](#testing-routes)

## Modes and How to Detect Them

React Router has three modes. Each one adds features on top of the previous one.

| Mode | Entry point | What it adds |
|------|-------------|--------------|
| Declarative | `<BrowserRouter>` + `<Routes>` | URL matching, `<Link>`, `useNavigate`, `useLocation` |
| Data | `createBrowserRouter` + `<RouterProvider>` | `loader`, `action`, `useFetcher`, `useNavigation`, pending UI, middleware |
| Framework | Vite plugin + `app/routes.ts` | Route modules, generated types, `href()`, SSR/SPA/pre-rendering, code splitting, server middleware |

Before writing code, find out which mode the project uses:

| Signal | Mode |
|--------|------|
| `react-router.config.ts`, `@react-router/dev` in `devDependencies`, `reactRouter()` in `vite.config.ts`, `app/routes.ts` | Framework |
| `createBrowserRouter(...)` passed to `<RouterProvider>` | Data |
| `<BrowserRouter>` wrapping `<Routes>` and `<Route>` elements | Declarative |
| `remix.config.js` or `@remix-run/*` packages | Remix v2 (the predecessor of framework mode); upgrade before using these APIs |

Check the major version in `package.json`:

- **v6** imports from `react-router-dom`. v7 still re-exports everything through `react-router-dom` for compatibility.
- **v7 and v8** import from `react-router`, except `RouterProvider` and `HydratedRouter`, which come from `react-router/dom`.
- **v8** removes the `react-router-dom` package. It requires React 19.2.7+, Node 22.22+, and Vite 7+, and ships ESM only. All `future.v8_*` flags are gone and their behavior is the default.

```tsx
// Data mode entry
import { createBrowserRouter } from 'react-router';
import { RouterProvider } from 'react-router/dom';

const router = createBrowserRouter([
  {
    path: '/',
    Component: Root,
    ErrorBoundary: RootErrorBoundary,
    children: [
      { index: true, Component: Home },
      { path: 'projects/:projectId', Component: Project, loader: projectLoader },
      { path: 'settings', lazy: () => import('./routes/settings') },
    ],
  },
]);

createRoot(document.getElementById('root')!).render(<RouterProvider router={router} />);
```

```ts
// Framework mode: vite.config.ts uses plugins: [reactRouter()] from '@react-router/dev/vite'
// react-router.config.ts
import type { Config } from '@react-router/dev/config';

export default { ssr: true } satisfies Config;
```

## Routing in Framework Mode

### Route config in `app/routes.ts`

```ts
import { type RouteConfig, route, index, layout, prefix } from '@react-router/dev/routes';

export default [
  index('./routes/home.tsx'),
  route('about', './routes/about.tsx'),

  // Pathless layout: wraps children without adding a URL segment
  layout('./routes/auth/layout.tsx', [
    route('login', './routes/auth/login.tsx'),
    route('register', './routes/auth/register.tsx'),
  ]),

  // Nested: /dashboard and /dashboard/settings render inside dashboard.tsx's <Outlet />
  route('dashboard', './routes/dashboard.tsx', [
    index('./routes/dashboard-home.tsx'),
    route('settings', './routes/dashboard-settings.tsx'),
  ]),

  // prefix adds a URL segment without a layout module
  ...prefix('projects', [
    index('./routes/projects/index.tsx'),
    route(':projectId', './routes/projects/project.tsx'),
  ]),

  route(':lang?/docs', './routes/docs.tsx'), // optional segment
  route('files/*', './routes/files.tsx'),    // splat: params['*']
  route('*', './routes/not-found.tsx'),      // catch-all
] satisfies RouteConfig;
```

- `:name` is a dynamic segment (`params.name`). A trailing `?` makes a dynamic or static segment optional (`users/:id/edit?`).
- A trailing `*` is a splat. Read the rest of the path from `params['*']`.
- Pass `{ id: '...' }` as the third argument when the same module file is used by two routes.
- In the catch-all route, throw `data('Not found', { status: 404 })` from its loader so the response is not a `200`.

### File-system routes

Install `@react-router/fs-routes` to define routes by file name. It can be combined with config routes:

```ts
import { type RouteConfig, route } from '@react-router/dev/routes';
import { flatRoutes } from '@react-router/fs-routes';

export default [
  route('/healthz', './healthz.tsx'),
  ...(await flatRoutes({ ignoredRouteFiles: ['**/*.test.tsx'] })),
] satisfies RouteConfig;
```

| File in `app/routes/` | URL |
|-----------------------|-----|
| `_index.tsx` | `/` |
| `concerts.trending.tsx` | `/concerts/trending` (nested in `concerts.tsx` if it exists) |
| `concerts.$city.tsx` | `/concerts/:city` |
| `($lang).categories.tsx` | `/categories` and `/:lang/categories` |
| `files.$.tsx` | `/files/*` |
| `_auth.login.tsx` | `/login`, rendered inside the pathless layout `_auth.tsx` |
| `concerts_.mine.tsx` | `/concerts/mine`, not nested in `concerts.tsx` |
| `sitemap[.]xml.tsx` | `/sitemap.xml` |
| `projects/route.tsx` | Folder route; other files in the folder are not routes |

### Route module exports

A parent route component renders the matched child wherever it places `<Outlet />` (imported from `react-router`).

| Export | Runs on | Purpose |
|--------|---------|---------|
| `default` | Server + client | Route component; receives `loaderData`, `actionData`, `params`, `matches` |
| `loader` / `clientLoader` | Server / browser | Read data for the route |
| `action` / `clientAction` | Server / browser | Handle non-GET submissions |
| `middleware` / `clientMiddleware` | Server / browser | Wrap loaders, actions, and requests |
| `ErrorBoundary` | Server + client | Render thrown errors and error responses |
| `HydrateFallback` | Server + client | Render while `clientLoader` runs during hydration |
| `headers` | Server | Set HTTP response headers |
| `meta`, `links` | Server + client | Document `<title>`, `<meta>`, and `<link>` tags |
| `shouldRevalidate` | Browser | Opt out of reloading this route's loader |
| `handle` | Server + client | Arbitrary data read through `useMatches()` |

Name server-only modules (database clients, secrets) `*.server.ts` so the build fails if browser code imports them.

### Generated types

The Vite plugin generates types for every route. Import them from `./+types/<route-file-name>`:

```tsx
// app/routes/projects/project.tsx
import { data } from 'react-router';
import type { Route } from './+types/project';
import { getProject } from '~/models/project.server';

export async function loader({ params }: Route.LoaderArgs) {
  //                           ^? { projectId: string }
  const project = await getProject(params.projectId);
  if (!project) throw data('Project not found', { status: 404 });
  return { project };
}

export function meta({ loaderData }: Route.MetaArgs) {
  return [{ title: loaderData?.project.name ?? 'Project' }];
}

export default function Project({ loaderData }: Route.ComponentProps) {
  return <h1>{loaderData.project.name}</h1>;
}
```

- `Route` also provides `ClientLoaderArgs`, `ActionArgs`, `ClientActionArgs`, `ErrorBoundaryProps`, `HydrateFallbackProps`, `HeadersArgs`, `MiddlewareFunction`, and `ClientMiddlewareFunction`.
- In `tsconfig.json`, add `".react-router/types/**/*"` to `include` and set `"rootDirs": [".", "./.react-router/types"]`. Add `.react-router/` to `.gitignore`.
- `react-router dev` regenerates types on every edit. In CI, run `react-router typegen && tsc`.
- Build URLs with `href('/projects/:projectId', { projectId })` so a wrong path or missing param fails type-check.
- In v8, `meta` reads `loaderData`. The old `data` field is removed.

## Navigation

```tsx
import { Link, NavLink, useNavigate, href } from 'react-router';

function Nav({ projectId }: { projectId: string }) {
  const navigate = useNavigate();
  return (
    <nav>
      <Link to={href('/projects/:projectId', { projectId })} prefetch="intent">Project</Link>
      <NavLink to="/inbox" className={({ isActive, isPending }) => (isActive ? 'active' : isPending ? 'pending' : undefined)}>
        Inbox
      </NavLink>
      <button type="button" onClick={() => navigate(-1)}>Back</button>
    </nav>
  );
}
```

- Use `<Link>` for anything the user clicks to go somewhere. Keep `useNavigate` for navigation after a timer or effect.
- `prefetch="intent"` (framework mode) loads the next route's code and data on hover or focus. `"viewport"` and `"render"` prefetch earlier.
- In loaders, actions, and middleware, `throw redirect('/login')` instead of navigating.

### Search params

```tsx
import { useSearchParams } from 'react-router';

function SortSelect() {
  const [searchParams, setSearchParams] = useSearchParams();
  return (
    <select
      value={searchParams.get('sort') ?? 'newest'}
      onChange={(e) =>
        setSearchParams((prev) => { prev.set('sort', e.target.value); return prev; }, { replace: true, preventScrollReset: true })
      }
    >
      <option value="newest">Newest</option>
      <option value="price">Price</option>
    </select>
  );
}
```

Changing search params is a navigation, so loaders run again and read `new URL(request.url).searchParams`. For search boxes, use `<Form method="get">`: it writes the inputs into the URL with no extra state.

### Pending UI

```tsx
import { Outlet, useNavigation } from 'react-router';

export default function Layout() {
  const navigation = useNavigation(); // state: 'idle' | 'loading' | 'submitting'
  const busy = navigation.state !== 'idle';
  return (
    <main aria-busy={busy} className={busy ? 'opacity-60' : undefined}>
      <Outlet />
    </main>
  );
}
```

`useNavigation` tracks page navigations only. Read fetcher progress from `fetcher.state`, or `useFetchers()` for all fetchers.

## Data Loading

### `loader` and `clientLoader`

- `loader` runs on the server for the document request and for client navigations (the browser fetches a `.data` URL). It is stripped from the client bundle.
- `clientLoader` runs only in the browser. Without a server `loader`, export `HydrateFallback` so the server has something to render.
- Combine both: `loader` serves the first render, and `clientLoader` can call `serverLoader()` on later navigations.

```tsx
import type { Route } from './+types/weather';

export async function clientLoader({ params }: Route.ClientLoaderArgs) {
  const res = await fetch(`/api/weather/${params.city}`);
  if (!res.ok) throw new Response('Weather unavailable', { status: res.status });
  return (await res.json()) as { tempC: number };
}

export function HydrateFallback() {
  return <p>Loading weather...</p>;
}

export default function Weather({ loaderData }: Route.ComponentProps) {
  return <p>{loaderData.tempC} °C</p>;
}
```

Loader data is serialized with the same rules as React Server Component props: plain objects, arrays, `Date`, `Map`, `Set`, and promises survive; class instances and functions do not.

In framework mode, read data from the `loaderData` prop: it is typed from the route's own loader. Use `useLoaderData<typeof loader>()` in data mode or in a child component, and `useRouteLoaderData('routes/dashboard')` (the route id) to read a parent's data instead of refetching.

### Streaming with promises

Await critical data. Return slow data as an unawaited promise inside the returned object (a loader cannot return a bare promise):

```tsx
import { Suspense } from 'react';
import { Await } from 'react-router';
import type { Route } from './+types/product';

export async function loader({ params }: Route.LoaderArgs) {
  const reviews = getReviews(params.productId); // not awaited
  const product = await getProduct(params.productId);
  return { product, reviews };
}

export default function Product({ loaderData }: Route.ComponentProps) {
  return (
    <>
      <h1>{loaderData.product.name}</h1>
      <Suspense fallback={<p>Loading reviews...</p>}>
        <Await resolve={loaderData.reviews} errorElement={<p>Could not load reviews.</p>}>
          {(reviews) => <ReviewList reviews={reviews} />}
        </Await>
      </Suspense>
    </>
  );
}
```

- With React 19, pass the promise to a child component and unwrap it with `use(promise)` inside `<Suspense>` instead of `<Await>`.
- Pending streamed promises are rejected after 4950 ms. Export `streamTimeout` from `entry.server.tsx` to change it.
- A streamed promise that rejects before the other loaders settle is an unhandled rejection in Node. Attach `.catch()` to it or register a `process.on('unhandledRejection', ...)` handler in the server entry.

### Errors

Throw `data(message, { status })` for expected failures such as not found or forbidden. Everything else bubbles to the closest `ErrorBoundary`:

```tsx
import { isRouteErrorResponse } from 'react-router';
import type { Route } from './+types/project';

export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  if (isRouteErrorResponse(error)) {
    return <h1>{error.status} {typeof error.data === 'string' ? error.data : error.statusText}</h1>;
  }
  return <h1>Something went wrong</h1>;
}
```

- Always export an `ErrorBoundary` from `app/root.tsx`.
- In production, server `Error` messages and stacks are sanitized before they reach the browser. Data in `throw data(...)` is sent as-is, so keep internal details out of it.
- In data mode, boundaries receive no props; read the error with `useRouteError()`.

## Mutations and Actions

### `action` with `<Form>` and Zod validation

Every exported `action` is a public HTTP endpoint: anyone can POST any body to the route URL. Inside each action, check the session, validate the input, and scope every write to the current user.

```ts
// app/sessions.server.ts
import { createCookieSessionStorage, redirect } from 'react-router';

export const sessionStorage = createCookieSessionStorage<{ userId: string }>({
  cookie: {
    name: '__session',
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    secrets: [process.env.SESSION_SECRET!],
  },
});

export async function requireUserId(request: Request): Promise<string> {
  const session = await sessionStorage.getSession(request.headers.get('Cookie'));
  const userId = session.get('userId');
  if (!userId) throw redirect('/login');
  return userId;
}
```

```tsx
// app/routes/projects/edit.tsx
import { Form, data, redirect, useNavigation } from 'react-router';
import { z } from 'zod';
import type { Route } from './+types/edit';
import { requireUserId } from '~/sessions.server';
import { db } from '~/db.server';

const ProjectSchema = z.object({
  name: z.string().trim().min(1, 'Name is required').max(100),
});

export async function action({ request, params }: Route.ActionArgs) {
  const userId = await requireUserId(request);

  const result = ProjectSchema.safeParse(Object.fromEntries(await request.formData()));
  if (!result.success) {
    return data({ errors: z.flattenError(result.error).fieldErrors }, { status: 400 });
  }

  // Scope the write to the owner; never trust an id from the URL or form alone
  const { count } = await db.project.updateMany({
    where: { id: params.projectId, ownerId: userId },
    data: result.data,
  });
  if (count === 0) throw data('Not found', { status: 404 });

  return redirect(`/projects/${params.projectId}`);
}

export default function EditProject({ actionData }: Route.ComponentProps) {
  const saving = useNavigation().state === 'submitting';
  const nameError = actionData?.errors.name?.[0];
  return (
    <Form method="post">
      <input name="name" aria-invalid={!!nameError} aria-describedby="name-error" />
      {nameError && <p id="name-error" role="alert">{nameError}</p>}
      <button type="submit" disabled={saving}>{saving ? 'Saving...' : 'Save'}</button>
    </Form>
  );
}
```

- Return `4xx` for validation errors. Loaders are not revalidated after a `4xx`/`5xx` action response by default.
- Redirect after a successful POST so a refresh does not resubmit.
- `<Form>` without `action` posts to its own route and creates a history entry. Use a `name="intent"` button value when one action handles several operations.
- See [forms.md](forms.md) for field-level UX, and [react-19-upgrade.md](react-19-upgrade.md) for `useActionState` outside the router.

### `useFetcher` for mutations without navigation

Use a fetcher for likes, toggles, and inline edits that should not change the URL or add history:

```tsx
import { useFetcher } from 'react-router';

function FavoriteButton({ projectId, favorite }: { projectId: string; favorite: boolean }) {
  const fetcher = useFetcher();
  // Optimistic: show the pending value while the submission is in flight
  const optimistic = fetcher.formData ? fetcher.formData.get('favorite') === 'true' : favorite;

  return (
    <fetcher.Form method="post" action={`/projects/${projectId}/favorite`}>
      <input type="hidden" name="favorite" value={String(!optimistic)} />
      <button type="submit" aria-pressed={optimistic}>{optimistic ? '★' : '☆'}</button>
    </fetcher.Form>
  );
}
```

- `fetcher.submit(values, { method: 'post', action })` submits imperatively; `fetcher.load(path)` calls a loader without navigating.
- A route module with a `loader` or `action` and no default export is a resource route. Use it as a fetcher target or a JSON/file endpoint.
- `clientAction` runs in the browser and takes priority over `action`; call `serverAction()` to forward the submission. Use it to update a client cache, never as a security check.

## Caching and Revalidation

### Automatic revalidation

After a successful action (`2xx`/`3xx`), React Router reloads the loaders of every route on the page. Call `useRevalidator().revalidate()` to reload on demand.

- **Framework mode with SSR**: loaders revalidate on every navigation and every successful submission.
- **SPA mode and data mode**: loaders revalidate after successful submissions. On GET navigations they reload only when their params or the search params change, or when the URL is unchanged (treated as a refresh).

### `shouldRevalidate`

```ts
import type { ShouldRevalidateFunctionArgs } from 'react-router';

export function shouldRevalidate({ currentUrl, nextUrl, formAction, defaultShouldRevalidate }: ShouldRevalidateFunctionArgs) {
  // Search-param-only navigations do not affect this layout's data
  if (!formAction && currentUrl.pathname === nextUrl.pathname) return false;
  if (formAction?.endsWith('/analytics')) return false;
  return defaultShouldRevalidate;
}
```

- Fall back to `defaultShouldRevalidate`. An unconditional `return false` also skips param changes and explicit `revalidate()` calls.
- Each matched route decides on its own: a child returning `false` does not stop the root loader.
- For one call site, pass `defaultShouldRevalidate={false}` to `<Form>`, `<Link>`, or `<fetcher.Form>`, or as an option to `fetcher.submit`, `useSubmit`, `useNavigate`, or `setSearchParams`. A route's `shouldRevalidate` still has the final say.

### HTTP caching with `headers`

Headers set on loader data are not sent automatically. Forward them from the `headers` export:

```tsx
import { data } from 'react-router';
import type { Route } from './+types/blog-post';

export async function loader({ params }: Route.LoaderArgs) {
  const post = await getPublishedPost(params.slug);
  if (!post) throw data('Not found', { status: 404 });
  return data({ post }, { headers: { 'Cache-Control': 'public, max-age=300, s-maxage=3600' } });
}

export function headers({ loaderHeaders, parentHeaders }: Route.HeadersArgs) {
  const out = new Headers(parentHeaders);
  const cacheControl = loaderHeaders.get('Cache-Control');
  if (cacheControl) out.set('Cache-Control', cacheControl);
  return out;
}
```

- When several matched routes export `headers`, only the deepest route's result is sent. Combine `parentHeaders` yourself, or set headers only in leaf routes.
- `Set-Cookie` from parent loaders, actions, and `headers` is kept automatically.
- `headers` also receives `actionHeaders` and `errorHeaders`.
- To set a header on every response, set it on the `Response` in root server middleware after `next()`, or in `entry.server.tsx`.

**Never** send `Cache-Control: public` or `s-maxage` on a response that depends on the session or contains per-user data: a CDN will serve one user's page to another. For authenticated routes, use `private, no-store`, and add `Vary: Cookie` if a shared cache sits in front.

### Client cache with `clientLoader`

Keep server rendering and cache in the browser, so going back and forth skips the network:

```tsx
import type { Route } from './+types/catalog';

type CatalogData = { products: Product[] };
const cache = new Map<string, { at: number; value: CatalogData }>(); // browser only
const TTL_MS = 60_000;

export async function loader({ request }: Route.LoaderArgs): Promise<CatalogData> {
  return { products: await getCatalog(new URL(request.url).searchParams) };
}

export async function clientLoader({ request, serverLoader }: Route.ClientLoaderArgs) {
  const key = new URL(request.url).search;
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.value;

  const value = await serverLoader();
  cache.set(key, { at: Date.now(), value });
  return value;
}
// Run during hydration so the server's data primes the cache. It returns what the
// server rendered, so no HydrateFallback is needed and nothing mismatches.
clientLoader.hydrate = true as const;

export async function clientAction({ serverAction }: Route.ClientActionArgs) {
  const result = await serverAction();
  cache.clear(); // invalidate after the write completes
  return result;
}
```

Key the cache by everything the data depends on. If the data is per-user, clear the cache on logout.

### Pairing with TanStack Query

Prefetch in the loader and let components read the query cache, which adds background refetching and shared mutations. In SPA or data mode, use one browser `QueryClient`:

```tsx
import { queryOptions, useSuspenseQuery } from '@tanstack/react-query';
import { queryClient } from '~/query-client';
import type { Route } from './+types/project';

const projectQuery = (id: string) =>
  queryOptions({
    queryKey: ['project', id],
    queryFn: () => fetch(`/api/projects/${id}`).then((r) => r.json() as Promise<Project>),
    staleTime: 30_000,
  });

export async function clientLoader({ params }: Route.ClientLoaderArgs) {
  // Cached data when present, otherwise fetch. Before TanStack Query 5.102: queryClient.ensureQueryData(...)
  await queryClient.query({ ...projectQuery(params.projectId), staleTime: 'static' });
  return { projectId: params.projectId };
}

export default function ProjectPage({ loaderData }: Route.ComponentProps) {
  const { data: project } = useSuspenseQuery(projectQuery(loaderData.projectId));
  return <h1>{project.name}</h1>;
}
```

- With SSR, never share a `QueryClient` between requests. Create one per request on the server, prefetch, and return `dehydrate(queryClient)` in loader data for a `<HydrationBoundary>`.
- Put the user or tenant in query keys for per-user data, and call `queryClient.clear()` on logout.
- Router revalidation does not touch the query cache. Call `queryClient.invalidateQueries(...)` after a mutation (for example in a `clientAction`).
- See [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md) for query keys and optimistic updates.

## Middleware and Context

Middleware is stable since 7.9. In v7, turn it on with `future: { v8_middleware: true }` in `react-router.config.ts` (framework mode) or in `createBrowserRouter` options (data mode). In v8 it is always on and the flag no longer exists.

Middleware runs parent to child before the handlers, then child to parent after them:

```text
root start → parent start → child start → loaders/action run → child end → parent end → root end
```

- **`middleware`** (server) runs on every document request. On client navigations it runs only when the browser makes a `.data` request, which needs a matched route with a server `loader` or `action`.
- **`clientMiddleware`** runs on every client navigation and fetcher call.
- Call `next()` at most once. On the server, `next()` returns the `Response`, which the middleware must return. If the middleware does not call `next()`, React Router calls it after the middleware function returns.
- `next()` does not throw: errors below it become a `Response` rendered by an `ErrorBoundary`. Throwing `redirect()` from middleware is allowed.

### Typed context

```ts
// app/context.ts
import { createContext } from 'react-router';

export type SessionUser = { id: string; email: string; role: 'admin' | 'member' };
export const userContext = createContext<SessionUser | null>(null);
export const requestIdContext = createContext<string>();
```

`context.set(userContext, user)` and `context.get(userContext)` are typed. `context.get` throws if a context with no default value was never set. In v8, `context` is always a `RouterContextProvider`; a custom server's `getLoadContext` must return `new RouterContextProvider()` with values set on it, not a plain object.

### Auth gating

```ts
// app/middleware/auth.server.ts
import { redirect, type MiddlewareFunction } from 'react-router';
import { userContext } from '~/context';
import { getUserFromSession } from '~/sessions.server';

export const requireUser: MiddlewareFunction<Response> = async ({ request, context }) => {
  const user = await getUserFromSession(request);
  if (!user) {
    const url = new URL(request.url);
    throw redirect(`/login?redirectTo=${encodeURIComponent(url.pathname + url.search)}`);
  }
  context.set(userContext, user);
};
```

```tsx
// app/routes/dashboard.tsx — layout for every /dashboard/* route
import { userContext } from '~/context';
import { requireUser } from '~/middleware/auth.server';
import type { Route } from './+types/dashboard';

export const middleware: Route.MiddlewareFunction[] = [requireUser];

export async function loader({ context }: Route.LoaderArgs) {
  const user = context.get(userContext)!;
  return { email: user.email };
}
```

After login, accept `redirectTo` only if it starts with a single `/`, so the app never redirects to another origin.

Middleware is not authorization on its own:

- It establishes who the user is. Each loader and action that touches user data must still check what the user may do: scope queries by `user.id`, check ownership and role, and return `404`/`403` otherwise.
- Middleware on a layout does not cover routes outside that layout, such as resource routes elsewhere in the tree.
- Server middleware does not run on client navigations where no matched route has a server loader or action. Data that a `clientLoader` fetches must be protected by the API that serves it.

### Logging, timing, and response headers

```ts
// app/root.tsx
import { requestIdContext } from '~/context';
import type { Route } from './+types/root';

const logRequests: Route.MiddlewareFunction = async ({ request, context }, next) => {
  const requestId = crypto.randomUUID();
  context.set(requestIdContext, requestId);
  const start = performance.now();

  const response = await next();

  console.log(`[${requestId}] ${request.method} ${new URL(request.url).pathname} ${response.status} ${Math.round(performance.now() - start)}ms`);
  response.headers.set('X-Request-Id', requestId);
  return response;
};

const timeNavigations: Route.ClientMiddlewareFunction = async ({ request }, next) => {
  const start = performance.now();
  await next();
  console.debug(`${new URL(request.url).pathname}: ${Math.round(performance.now() - start)}ms`);
};

export const middleware: Route.MiddlewareFunction[] = [logRequests];
export const clientMiddleware: Route.ClientMiddlewareFunction[] = [timeNavigations];
```

### Data mode

Add `middleware: [...]` to route objects, and seed context per navigation with the `getContext` option of `createBrowserRouter`, which returns a `RouterContextProvider`. All data-mode middleware runs in the browser, so treat it as UX (redirect early), never as protection: the API behind the loaders must authorize every request.

## Pre-rendering and SPA Mode

```ts
// react-router.config.ts
import type { Config } from '@react-router/dev/config';

export default {
  ssr: true,
  async prerender({ getStaticPaths }) {
    const slugs = await getPublishedSlugs();
    return [...getStaticPaths(), ...slugs.map((slug) => `/blog/${slug}`)];
  },
} satisfies Config;
```

- `prerender: true` renders all static paths at build time; list dynamic paths yourself. Each path produces `[url].html` and a `[url].data` file for client navigations.
- Pre-rendered loaders run once at build time with no session. Never pre-render per-user content.
- `ssr: false` without `prerender` is SPA mode: only the root route is rendered at build time, and only `root` may export a `loader`. Use `clientLoader` elsewhere.
- `ssr: false` with `prerender` allows loaders on pre-rendered paths. Other URLs fall back to `index.html` (or `__spa-fallback.html` when `/` is pre-rendered); configure the host to serve that file for unknown paths.
- With `ssr: false`, `action` and `headers` exports fail the build, and server `middleware` never runs. Use `clientAction` and `clientMiddleware`, and set cache headers in the host config.

## Testing Routes

Use `createRoutesStub` from `react-router` to render components that use router APIs (`useLoaderData`, `useActionData`, `useFetcher`, `<Form>`, `<Link>`) with stubbed loaders and actions:

```tsx
import { createRoutesStub } from 'react-router';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from './LoginForm';

test('shows validation errors from the action', async () => {
  const Stub = createRoutesStub([
    { path: '/login', Component: LoginForm, action: () => ({ errors: { email: ['Email is required'] } }) },
  ]);

  render(<Stub initialEntries={['/login']} />);
  await userEvent.click(screen.getByRole('button', { name: /log in/i }));

  expect(await screen.findByText('Email is required')).toBeInTheDocument();
});
```

- Use `createRoutesStub` for reusable components. Route modules typed with `Route.ComponentProps` produce type errors in a stub because `matches` differs from the real route tree; test whole routes end to end against a running app.
- Test loaders and actions as plain functions: build a `Request`, call `loader({ request, params, context })`, and assert on the result or the thrown `Response`. Pass a `RouterContextProvider` as `context` when they read middleware context.

See [testing.md](testing.md) for setup and [testing-recipes.md](testing-recipes.md) for more patterns.
