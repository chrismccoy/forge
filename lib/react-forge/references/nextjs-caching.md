# Next.js Caching and Revalidation

Caching in Next.js 15 and 16: `fetch` defaults, Cache Components with `'use cache'`, `cacheLife`, `cacheTag`, tag and path revalidation, Request Memoization, the Router Cache, ISR, and debugging. Load it when data is stale, a page is unexpectedly static or dynamic, or a mutation does not show up after it runs.

## Contents

- [Quick Reference](#quick-reference)
- [Caching Layers](#caching-layers)
- [fetch Defaults](#fetch-defaults)
- [Cache Components and use cache](#cache-components-and-use-cache)
- [cacheLife and cacheTag](#cachelife-and-cachetag)
- [Revalidation](#revalidation)
- [Request Memoization and React cache](#request-memoization-and-react-cache)
- [Router Cache](#router-cache)
- [Static Generation and ISR](#static-generation-and-isr)
- [Segment Config and Cache Components](#segment-config-and-cache-components)
- [Per-User and Safety Data](#per-user-and-safety-data)
- [Debugging](#debugging)
- [Best Practices](#best-practices)

## Quick Reference

| Need | Next.js 15 (no Cache Components) | Next.js 16 with `cacheComponents: true` |
|------|----------------------------------|------------------------------------------|
| Cache a fetch | `fetch(url, { cache: 'force-cache' })` | Call it inside a `'use cache'` function |
| Cache a DB query | `unstable_cache(fn, keys, opts)` | `'use cache'` function |
| Time-based refresh | `{ next: { revalidate: 60 } }` or `export const revalidate = 60` | `cacheLife('minutes')` or `cacheLife({ revalidate: 60 })` |
| Tag for invalidation | `{ next: { tags: ['posts'] } }` | `cacheTag('posts')` |
| Always fresh | `{ cache: 'no-store' }` or `dynamic = 'force-dynamic'` | Default: uncached data renders at request time |
| Read-your-writes after a mutation | `revalidateTag('posts')` (15) | `updateTag('posts')` in a Server Action |
| Background refresh | `revalidateTag('posts')` | `revalidateTag('posts', 'max')` |
| Refresh a URL | `revalidatePath('/posts')` | `revalidatePath('/posts')` |
| Refresh the client view | `router.refresh()` | `router.refresh()` |

Version flags:

- **15.0**: `fetch` and `GET` Route Handlers are no longer cached by default. Client Router Cache no longer reuses dynamic pages (`staleTimes.dynamic` is `0`).
- **16.0**: `cacheComponents: true` enables `'use cache'`, `cacheLife`, and `cacheTag` as stable APIs. It replaces `experimental.dynamicIO`, `experimental.useCache`, and `experimental.ppr`. `updateTag` is added. Single-argument `revalidateTag(tag)` is deprecated.

## Caching Layers

| Layer | Stores | Where | Lifetime | Invalidate with |
|-------|--------|-------|----------|-----------------|
| Request Memoization | Function return values | Server, one request | One render pass | Automatic |
| Data Cache / `'use cache'` | Fetch responses and cached function results | Server | Until revalidated or expired | `updateTag`, `revalidateTag`, `revalidatePath`, `cacheLife` |
| Full Route Cache | Prerendered HTML and RSC payload | Server | Until revalidated or redeployed | Same as above |
| Router Cache | RSC payloads of visited and prefetched routes | Browser memory | Session, per `staleTimes` | `router.refresh()`, or any revalidation in a Server Action |

A route is prerendered (static) when everything it reads is cached or known at build time. Reading `cookies()`, `headers()`, `searchParams`, `connection()`, or uncached data makes it render at request time.

## fetch Defaults

Since Next.js 15, `fetch` in Server Components and Route Handlers is not cached. In 13 and 14 it was cached indefinitely by default.

```tsx
// Not cached: runs on every request (15+)
const live = await fetch('https://api.example.com/stats');

// Cached until revalidated
const config = await fetch('https://api.example.com/config', { cache: 'force-cache' });

// Cached, stale after one hour
const products = await fetch('https://api.example.com/products', { next: { revalidate: 3600 } });

// Cached and tagged. Tags alone do not opt in to caching.
const posts = await fetch('https://api.example.com/posts', {
  cache: 'force-cache',
  next: { tags: ['posts'] },
});

// Explicitly uncached, for example inside a segment that forces caching
const balance = await fetch('https://api.example.com/balance', { cache: 'no-store' });
```

With Cache Components enabled, the `fetch` options still work, but prefer wrapping the fetch in a `'use cache'` function so fetch and non-fetch data use one model.

Fetch independent data in parallel with `Promise.all`, and wrap slow parts in `<Suspense>` so the rest of the page streams first.

## Cache Components and use cache

Enable Cache Components in `next.config.ts` (Next.js 16):

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheComponents: true,
};

export default nextConfig;
```

With it on, nothing is cached unless marked as cached, and request-time data must sit inside a `<Suspense>` boundary. The static shell prerenders. Cached parts are included in it. Dynamic parts stream in at request time (Partial Prerendering).

Put `'use cache'` at the top of a function, a component, or a file.

```tsx
// lib/posts.ts: function scope
import { cacheLife, cacheTag } from 'next/cache';

export async function getPublishedPosts() {
  'use cache';
  cacheLife('hours');
  cacheTag('posts');
  return db.posts.findMany({ where: { published: true }, orderBy: { createdAt: 'desc' } });
}

export async function getPost(slug: string) {
  'use cache';
  cacheLife('days');
  cacheTag('posts', `post-${slug}`); // arguments are part of the cache key
  return db.posts.findFirst({ where: { slug, published: true } });
}
```

```tsx
// components/category-list.tsx: component scope (props become part of the key)
import { cacheLife, cacheTag } from 'next/cache';

export async function CategoryList({ category }: { category: string }) {
  'use cache';
  cacheLife('days');
  cacheTag(`category-${category}`);
  const items = await db.products.findMany({ where: { category } });
  return (
    <ul>
      {items.map((p) => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

```tsx
// app/dashboard/page.tsx: cached shell plus request-time part
import { Suspense } from 'react';
import { cookies } from 'next/headers';

export default function DashboardPage() {
  return (
    <>
      <CategoryList category="featured" />
      <Suspense fallback={<p>Loading your settings…</p>}>
        <UserSettings />
      </Suspense>
    </>
  );
}

async function UserSettings() {
  const theme = (await cookies()).get('theme')?.value ?? 'light';
  return <p>Theme: {theme}</p>;
}
```

Rules:

- Cached functions and components must be `async`. Arguments and return values must be serializable. Non-serializable values such as `children` or functions can pass through as long as the cached scope does not inspect them.
- A file-level `'use cache'` caches every export, so the module may only export async functions.
- Do not call `cookies()`, `headers()`, or read `searchParams` inside a cached scope. Read them outside and pass the needed values in as arguments.
- `'use cache'` defaults to an in-memory LRU per server instance. `'use cache: remote'` uses a shared handler configured with `cacheHandlers` in `next.config.ts` (for example Redis), so all instances share entries.
- `'use cache: private'` (16, with Cache Components) may read `cookies()`, `headers()`, and `searchParams`. It is not stored in a server cache across requests: results are reused within one request and kept in browser memory for the `cacheLife` `stale` time. Use it for personalization, never for authorization decisions.
- Cache Components is not supported on the Edge runtime.

## cacheLife and cacheTag

`cacheLife` sets three timings:

| Field | Meaning |
|-------|---------|
| `stale` | How long the client may use the entry without checking the server |
| `revalidate` | After this, the next request serves the cached entry and refreshes it in the background |
| `expire` | After this with no traffic, the next request waits for fresh data |

Built-in profiles: `'default'`, `'seconds'`, `'minutes'`, `'hours'`, `'days'`, `'weeks'`, `'max'`. Use an inline object for one-off values, or define named profiles in config.

```tsx
cacheLife({ stale: 60, revalidate: 300, expire: 3600 });
```

```ts
// next.config.ts
const nextConfig: NextConfig = {
  cacheComponents: true,
  cacheLife: {
    catalog: { stale: 300, revalidate: 900, expire: 86400 },
  },
};
```

`cacheTag` attaches one or more string tags to the cached entry. Tag broadly (`'posts'`) and narrowly (`post-${id}`) so either level can be invalidated. Tags can be set conditionally after the data is known, for example `cacheTag(`author-${post.authorId}`)`.

## Revalidation

| API | Behavior | Where |
|-----|----------|-------|
| `updateTag(tag)` | Expires the tag now. The next read in the same request waits for fresh data (read-your-writes) | Server Actions only (16) |
| `revalidateTag(tag, 'max')` | Marks the tag stale. Next visit serves stale content and refreshes in the background | Server Actions, Route Handlers (16 signature) |
| `revalidateTag(tag, { expire: 0 })` | Expires immediately outside a Server Action, for example from a webhook | Route Handlers (16) |
| `revalidateTag(tag)` | Deprecated in 16. On 15 it expires the tag | 15 |
| `revalidatePath(path)` | Invalidates everything rendered for a URL. Pass `'layout'` as the second argument to include nested routes | Server Actions, Route Handlers |
| `refresh()` from `next/cache` | Refreshes the client router after an action that changed uncached data | Server Actions only (16) |
| `router.refresh()` | Re-fetches the current route's Server Components without losing client state | Client |

A Server Action that mutates data must authorize, validate, write, then invalidate:

```tsx
// app/posts/actions.ts
'use server';

import { revalidatePath, updateTag } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { auth } from '@/auth';

const PostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(50_000),
});

export async function updatePost(id: string, formData: FormData) {
  const session = await auth();
  if (!session?.user) throw new Error('Unauthorized');

  // Every exported action is a public endpoint: check ownership, never trust the id alone
  const post = await db.posts.findUnique({ where: { id }, select: { authorId: true, slug: true } });
  if (!post || post.authorId !== session.user.id) throw new Error('Forbidden');

  const parsed = PostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });
  if (!parsed.success) return { errors: z.flattenError(parsed.error).fieldErrors };

  await db.posts.update({ where: { id }, data: parsed.data });

  updateTag('posts');
  updateTag(`post-${post.slug}`);
  revalidatePath('/dashboard/posts');
  redirect(`/posts/${post.slug}`);
}
```

For wiring this action to a form with `useActionState`, see [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms).

### Revalidation webhook

When a CMS or another service changes data, expose an authenticated Route Handler:

```tsx
// app/api/revalidate/route.ts
import { createHash, timingSafeEqual } from 'node:crypto';
import { revalidatePath, revalidateTag } from 'next/cache';
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';

const BodySchema = z
  .object({
    tag: z.string().regex(/^[A-Za-z0-9:_-]{1,128}$/).optional(),
    // Same-app path only: one leading '/', no '..', no scheme or query
    path: z.string().max(512).regex(/^\/(?!\/)(?!.*\.\.)[A-Za-z0-9/_\-.[\]]*$/).optional(),
  })
  .refine((b) => b.tag || b.path, 'tag or path required');

function isValidSecret(provided: string | null): boolean {
  const expected = process.env.REVALIDATION_SECRET;
  if (!provided || !expected) return false;
  // Hash both so the lengths match, then compare in constant time
  const a = createHash('sha256').update(provided).digest();
  const b = createHash('sha256').update(expected).digest();
  return timingSafeEqual(a, b);
}

export async function POST(request: NextRequest) {
  if (!isValidSecret(request.headers.get('x-revalidate-secret'))) {
    return NextResponse.json({ error: 'Invalid secret' }, { status: 401 });
  }

  const parsed = BodySchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return NextResponse.json({ error: 'Invalid body' }, { status: 400 });

  const { tag, path } = parsed.data;
  if (tag) revalidateTag(tag, 'max'); // updateTag is not available in Route Handlers
  if (path) revalidatePath(path);

  return NextResponse.json({ revalidated: true });
}
```

If the provider signs its payloads, verify the HMAC over the raw body with `timingSafeEqual` and reject stale timestamps instead of using a shared header secret.

## Request Memoization and React cache

Within one server render, identical `GET` `fetch` calls (same URL and options) run once, so a layout and a page can both call `getUser(id)` without a second request. This does not apply to `POST` requests or to non-fetch code.

For database queries and SDK calls, wrap the function with React `cache()`. The result is shared for the rest of the request and discarded afterwards.

```tsx
// lib/data.ts
import { cache } from 'react';
import 'server-only';

export const getUser = cache(async (id: string) => {
  return db.users.findUnique({ where: { id } });
});
```

- `cache()` is per request, so it is safe for per-user data. It is not a persistent cache.
- `'use cache'` is persistent and shared across requests and users. Combine them when both are needed: a `cache()` wrapper for deduplication around a `'use cache'` function for persistence.
- Call `cache()` at module scope. Creating it inside a component gives each render a new, empty cache.

## Router Cache

The browser keeps RSC payloads of visited and prefetched routes in memory so back/forward and repeat navigations are instant.

- `<Link>` prefetches routes as they enter the viewport in production. Pass `prefetch={false}` for links that are rarely used or expensive.
- Since 15, dynamic pages are not reused from the Router Cache (`staleTimes.dynamic` is `0`). Static pages are reused for 5 minutes. Tune with `experimental.staleTimes` in `next.config.ts`. With Cache Components, the `stale` value from `cacheLife` controls this instead.
- Calling `updateTag`, `revalidateTag`, `revalidatePath`, `cookies().set`, or `cookies().delete` in a Server Action clears the Router Cache, so the UI updates after the action.
- From a Client Component, call `router.refresh()` to re-fetch the current route without losing client state.

```tsx
// components/refresh-button.tsx
'use client';

import { useRouter } from 'next/navigation';
import { useTransition } from 'react';

export function RefreshButton() {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  return (
    <button disabled={isPending} onClick={() => startTransition(() => router.refresh())}>
      {isPending ? 'Refreshing…' : 'Refresh'}
    </button>
  );
}
```

## Static Generation and ISR

Incremental Static Regeneration serves a prerendered page and regenerates it in the background after a time or on demand.

```tsx
// app/blog/[slug]/page.tsx: Next.js 16 with Cache Components
import { notFound } from 'next/navigation';
import { getPost } from '@/lib/posts'; // 'use cache' + cacheLife('days') + cacheTag(`post-${slug}`)

export async function generateStaticParams() {
  const posts = await db.posts.findMany({ where: { published: true }, take: 100, select: { slug: true } });
  return posts.map((p) => ({ slug: p.slug }));
}

export default async function PostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) notFound();
  return <article>{post.title}</article>;
}
```

```tsx
// app/blog/[slug]/page.tsx: Next.js 15 without Cache Components
export const revalidate = 3600; // regenerate at most once an hour
export const dynamicParams = true; // render unknown slugs on demand (default)

export async function generateStaticParams() {
  const posts = await db.posts.findMany({ where: { published: true }, take: 100, select: { slug: true } });
  return posts.map((p) => ({ slug: p.slug }));
}
```

ISR needs a running server (`next start` or a platform that supports it). It does not work with `output: 'export'`. For the routing side of `generateStaticParams`, see [nextjs-routing.md](nextjs-routing.md#generatestaticparams).

Route Handlers: a `GET` handler is not cached by default since 15. For CDN caching of public responses, set the header yourself:

```tsx
// app/api/catalog/route.ts
import { NextResponse } from 'next/server';
import { getCatalog } from '@/lib/catalog'; // a 'use cache' function

export async function GET() {
  const data = await getCatalog();
  return NextResponse.json(data, {
    headers: { 'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400' },
  });
}
```

`'use cache'` cannot go on the `GET` export itself. Call a cached helper from it.

## Segment Config and Cache Components

Without Cache Components, these exports from a `page`, `layout`, or `route` control caching:

```tsx
export const dynamic = 'force-dynamic'; // or 'force-static', 'error', 'auto'
export const revalidate = 60; // seconds; false = cache indefinitely; 0 = always dynamic
export const fetchCache = 'force-no-store';
export const dynamicParams = false; // 404 for params not in generateStaticParams
export const runtime = 'nodejs'; // or 'edge'
```

With `cacheComponents: true`, exporting `dynamic`, `revalidate`, `fetchCache`, `dynamicParams`, or `runtime` is a build error. Replace them:

| Old export | Replacement with Cache Components |
|------------|-----------------------------------|
| `dynamic = 'force-dynamic'`, `revalidate = 0` | Remove. Uncached data already renders at request time. Wrap it in `<Suspense>` |
| `dynamic = 'force-static'`, `revalidate = N`, `fetchCache = 'force-cache'` | `'use cache'` with `cacheLife(...)` on the page, component, or data function |
| `fetchCache = 'force-no-store'` | Remove. Fetches outside `'use cache'` are not cached |
| `dynamicParams = false` | Call `notFound()` when the param does not resolve to data |
| `runtime = 'edge'` | Remove. Cache Components requires the Node.js runtime |

Migrate one route at a time: turn on `cacheComponents`, run `next build`, and fix each reported segment.

## Per-User and Safety Data

Shared caches outlive the request and are served to other users. A wrong key here leaks data across accounts or keeps revoked access alive.

- Never cache per-user data under a shared key. If a `'use cache'` function returns user data, the user ID must be an argument, and the entry must never be rendered for anyone else. Prefer not caching it, or React `cache()` for per-request deduplication.
- Never cache authorization or entitlement state (session validity, role, plan, feature flags that gate paid features, ban status). Read it fresh in every Server Action, Route Handler, and protected page.
- When a check cannot produce a definite answer (unknown ID, upstream error, partial result), take the zero-entitlement branch. Never fall back to a cached field such as `user.plan`.
- Do not wrap a function that calls `auth()`, `cookies()`, or `headers()` in `'use cache'`. Call them outside and pass in only the non-sensitive values the cached part needs.
- Prerendered pages are public. Do not put drafts or private content in `generateStaticParams`.

```tsx
// Wrong: entitlement cached and shared
async function getPlan(userId: string) {
  'use cache';
  cacheLife('hours');
  return db.subscriptions.findUnique({ where: { userId } });
}

// Right: read fresh, fail closed
async function getPlan(userId: string): Promise<'free' | 'pro'> {
  const sub = await db.subscriptions.findUnique({ where: { userId } }).catch(() => null);
  return sub?.status === 'active' && sub.plan === 'pro' ? 'pro' : 'free';
}
```

## Debugging

Log fetches and cache status in the dev terminal:

```ts
// next.config.ts
const nextConfig: NextConfig = {
  logging: { fetches: { fullUrl: true } },
};
```

Run `next build` and read the route table. Each route is marked static, partially prerendered, or dynamic. A page expected to be static usually reads `cookies()`, `headers()`, `searchParams`, or uncached data somewhere in its tree.

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Data never updates | Cached without a tag or path revalidation | Add `cacheTag` and call `updateTag`/`revalidateTag` after writes |
| Mutation not visible to the user who made it | `revalidateTag(tag, 'max')` serves stale first | Use `updateTag` in the Server Action |
| Data refetched on every request (15+) | `fetch` is uncached by default | Add `cache: 'force-cache'` or `'use cache'` |
| Build error about uncached or runtime data accessed outside `<Suspense>` | Cache Components with request-time data | Wrap that component in `<Suspense>` or cache the data |
| Build error on `export const dynamic` | Segment config with Cache Components | See [Segment Config and Cache Components](#segment-config-and-cache-components) |
| Error using `cookies()` inside `'use cache'` | Request data in cached scope | Read outside and pass values in |
| Another user's data appears | Per-user data under a shared cache key | Remove the cache. See [Per-User and Safety Data](#per-user-and-safety-data) |
| Works in dev, stale in production | Dev does not cache the same way | Test caching with `next build && next start` |
| Stale page after back navigation | Router Cache | `router.refresh()` or invalidate in the Server Action |

## Best Practices

| Practice | Why |
|----------|-----|
| Opt in to caching deliberately | Nothing is cached by default since 15 |
| Cache expensive public data with `'use cache'` and tags | One model for fetch and non-fetch data |
| Pair every cache tag with an invalidation | Show the `cacheTag` and its `updateTag`/`revalidateTag` together |
| Use `updateTag` for the user's own writes | Read-your-writes without a stale flash |
| Use React `cache()` for per-request deduplication | Safe for per-user data |
| Never cache per-user or entitlement state under a shared key | Prevents data leaks and stale access |
| Authorize and Zod-validate before every write | Every Server Action is a public endpoint |
| Wrap request-time data in `<Suspense>` | Keeps the static shell fast |
| Verify with `next build` | The route table shows what is static |
