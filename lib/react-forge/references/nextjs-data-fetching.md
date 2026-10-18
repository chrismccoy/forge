# Next.js Data Fetching

Reading data in Next.js 15 and 16 with the App Router: Server Component fetching, parallel and sequential requests, React `cache()`, Suspense streaming, promises passed to Client Components, client-side libraries, Route Handlers, and `generateStaticParams`. Load it when a page or component needs data, a page loads in a waterfall, or the app needs an HTTP endpoint under `app/`.

## Contents

- [Quick Reference](#quick-reference)
- [Server Component Fetching](#server-component-fetching)
- [Parallel and Sequential Fetching](#parallel-and-sequential-fetching)
- [Deduplicating with React cache](#deduplicating-with-react-cache)
- [Streaming with Suspense](#streaming-with-suspense)
- [Passing Promises to Client Components](#passing-promises-to-client-components)
- [Client-Side Fetching](#client-side-fetching)
- [Prefetching with TanStack Query](#prefetching-with-tanstack-query)
- [Environment Variables](#environment-variables)
- [Route Handlers](#route-handlers)
- [Static Params](#static-params)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Quick Reference

| Need | Use |
|------|-----|
| Data for a page or layout | `async` Server Component that awaits `fetch` or a DB call |
| Independent requests | Start them together, then `await Promise.all([...])` |
| Same query in `generateMetadata` and the page | Wrap the loader in React `cache()` |
| Show the shell before slow data | `loading.tsx` for the segment, `<Suspense>` around slow parts |
| Client Component needs server data | Pass the value, or pass an unawaited promise and read it with `use()` |
| Polling, infinite scroll, client-owned cache | TanStack Query or SWR in a Client Component |
| Form post from the app's own UI | Server Action (see [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms)) |
| Endpoint for webhooks, mobile apps, third parties | Route Handler in `app/**/route.ts` |
| Prerender dynamic segments at build time | `generateStaticParams` plus `dynamicParams` |
| Cache, tag, or revalidate the result | See [nextjs-caching.md](nextjs-caching.md) |

Version notes:

- **15.0**: `params`, `searchParams`, `cookies()`, `headers()`, and `draftMode()` are async. `fetch` and `GET` Route Handlers are not cached by default.
- **16.0**: synchronous access to those request APIs is removed. Await them everywhere. See [nextjs-routing.md](nextjs-routing.md#async-params-and-searchparams).

## Server Component Fetching

Server Components are `async` functions. Await data directly in the component; there is no `useEffect` and no client bundle cost.

```tsx
// app/posts/page.tsx — Server Component
import Link from 'next/link';

interface Post {
  id: string;
  slug: string;
  title: string;
}

async function getPosts(): Promise<Post[]> {
  const res = await fetch('https://api.example.com/posts');
  if (!res.ok) throw new Error(`Failed to fetch posts: ${res.status}`);
  return res.json();
}

export default async function PostsPage() {
  const posts = await getPosts();

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>
          <Link href={`/posts/${post.slug}`}>{post.title}</Link>
        </li>
      ))}
    </ul>
  );
}
```

Query the database directly instead of calling the app's own Route Handler. A server-to-self HTTP hop adds latency and fails at build time when no server is running.

```tsx
// lib/posts.ts — server-only data access
import 'server-only';
import { db } from '@/lib/db';

export async function getRecentPosts() {
  return db.posts.findMany({
    where: { published: true },
    orderBy: { createdAt: 'desc' },
    take: 10,
    select: { id: true, slug: true, title: true },
  });
}
```

- Import `server-only` in data-access modules. A Client Component that imports one fails the build instead of shipping DB code or secrets.
- Use `select` to return only the fields the UI needs. Everything a Server Component passes to a Client Component is serialized into the page payload.
- Scope per-user queries with the session user ID. Never trust a user ID from `searchParams` or props that came from the URL.
- Server Components cannot set cookies. Set them in a Server Action, a Route Handler, or the proxy.

## Parallel and Sequential Fetching

Each `await` in sequence waits for the previous one. When requests do not depend on each other, start them together.

```tsx
// app/dashboard/page.tsx — Server Component
import { getUser, getPosts, getAnalytics } from '@/lib/dashboard';

export default async function DashboardPage() {
  // Parallel: all three start now; total time is the slowest one
  const [user, posts, analytics] = await Promise.all([
    getUser(),
    getPosts(),
    getAnalytics(),
  ]);

  return (
    <>
      <UserCard user={user} />
      <PostsList posts={posts} />
      <AnalyticsChart data={analytics} />
    </>
  );
}
```

Use `Promise.allSettled` when one failure should not blank the whole page, and render a fallback for the rejected entries.

Fetch sequentially only when a request needs the result of an earlier one:

```tsx
// app/users/[id]/page.tsx — Server Component
import { notFound } from 'next/navigation';
import { getUser, getTeamPosts } from '@/lib/users';

export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const user = await getUser(id);
  if (!user) notFound();

  // Depends on user.teamId, so it must wait
  const posts = await getTeamPosts(user.teamId);

  return (
    <>
      <h1>{user.name}</h1>
      <PostsList posts={posts} />
    </>
  );
}
```

To keep the first part of the page visible while the dependent request runs, move the dependent part into its own async component inside `<Suspense>` (see [Streaming with Suspense](#streaming-with-suspense)).

### Preload pattern

When a component deep in the tree needs data that only it awaits, start the request early from a parent so it runs in parallel with the parent's own work. Pair the loader with React `cache()` so the early call and the later call share one result.

```tsx
// lib/items.ts
import 'server-only';
import { cache } from 'react';
import { db } from '@/lib/db';

export const getItem = cache(async (id: string) => {
  return db.items.findUnique({ where: { id } });
});

export function preloadItem(id: string): void {
  void getItem(id); // start now, do not await
}
```

```tsx
// app/items/[id]/page.tsx — Server Component
import { getItem, preloadItem } from '@/lib/items';
import { checkAvailability } from '@/lib/inventory';

export default async function ItemPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  preloadItem(id); // starts the item query

  const available = await checkAvailability(id); // runs while the item query is in flight
  return available ? <ItemDetails id={id} /> : <SoldOut />;
}

async function ItemDetails({ id }: { id: string }) {
  const item = await getItem(id); // reuses the preloaded promise
  return <h1>{item?.name}</h1>;
}
```

## Deduplicating with React cache

React `cache()` memoizes a function for the duration of one server request. Use it for any loader called from more than one place in a render: `generateMetadata` and the page, a layout and a page, or sibling components.

```tsx
// lib/posts.ts
import 'server-only';
import { cache } from 'react';
import { db } from '@/lib/db';

export const getPost = cache(async (slug: string) => {
  return db.posts.findFirst({ where: { slug, published: true } });
});
```

- `cache()` is per request. It never shares data between users or requests, so it is safe for per-user data.
- Arguments are compared with `Object.is`. Pass primitives, not freshly created objects, or every call misses.
- `fetch` GET requests with the same URL and options are already memoized during a render. `cache()` is for DB clients, SDKs, and other non-`fetch` work.
- `cache()` is not a persistent cache. For results that outlive a request, see [nextjs-caching.md](nextjs-caching.md#request-memoization-and-react-cache).

## Streaming with Suspense

Streaming sends the page shell immediately and fills in slow parts as their data resolves.

### loading.tsx

A `loading.tsx` file wraps the segment's `page.tsx` in a Suspense boundary. Navigation shows it instantly while the page's data loads.

```tsx
// app/dashboard/loading.tsx — Server Component
export default function Loading() {
  return (
    <div role="status" aria-label="Loading dashboard" className="animate-pulse space-y-4">
      <div className="h-8 w-1/3 rounded bg-gray-200" />
      <div className="h-40 rounded bg-gray-200" />
    </div>
  );
}
```

### Nested Suspense boundaries

For finer control, render the page without awaiting slow data, and put each slow part in its own async component wrapped in `<Suspense>`. Each boundary streams independently.

```tsx
// app/dashboard/page.tsx — Server Component
import { Suspense } from 'react';

export default function DashboardPage() {
  return (
    <>
      <h1>Dashboard</h1>

      <Suspense fallback={<StatsSkeleton />}>
        <Stats />
      </Suspense>

      <Suspense fallback={<FeedSkeleton />}>
        <Feed />
        {/* Comments stream after Feed resolves, without blocking it */}
        <Suspense fallback={<CommentsSkeleton />}>
          <RecentComments />
        </Suspense>
      </Suspense>
    </>
  );
}

async function Stats() {
  const stats = await getStats(); // slow
  return <StatsGrid stats={stats} />;
}
```

- Place boundaries around independent regions, not around every element. Too many boundaries cause layout shift as fallbacks pop in.
- Give fallbacks the same dimensions as the content to avoid shift.
- A `<Suspense>` boundary must sit above the component that suspends. Awaiting inside the page itself suspends the whole page, so only `loading.tsx` can catch it.
- Add `key` to a `<Suspense>` boundary when it should show its fallback again on a `searchParams` change: `<Suspense key={query} fallback={...}>`.

## Passing Promises to Client Components

A Server Component can start a request and pass the unawaited promise to a Client Component. The Client Component reads it with `use()` and suspends until it resolves. The server shell renders without waiting, and the data still comes from the server.

```tsx
// app/posts/[slug]/page.tsx — Server Component
import { Suspense } from 'react';
import { getPost, getComments } from '@/lib/posts';
import { Comments } from './comments';

export default async function PostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);
  const commentsPromise = getComments(slug); // not awaited

  return (
    <article>
      <h1>{post?.title}</h1>
      <Suspense fallback={<p>Loading comments…</p>}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}
```

```tsx
// app/posts/[slug]/comments.tsx
'use client'; // reads a promise with use() and handles clicks

import { use, useState } from 'react';

interface Comment {
  id: string;
  author: string;
  body: string;
}

export function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  const [expanded, setExpanded] = useState(false);
  const visible = expanded ? comments : comments.slice(0, 3);

  return (
    <section aria-label="Comments">
      <ul>
        {visible.map((c) => (
          <li key={c.id}>
            <strong>{c.author}</strong>: {c.body}
          </li>
        ))}
      </ul>
      {comments.length > 3 && (
        <button type="button" onClick={() => setExpanded((v) => !v)}>
          {expanded ? 'Show fewer' : `Show all ${comments.length}`}
        </button>
      )}
    </section>
  );
}
```

- The resolved value must be serializable: plain objects, arrays, strings, numbers, `Date`, `Map`, `Set`. No class instances or functions.
- A rejected promise throws to the nearest error boundary (`error.tsx` or a client error boundary).
- Do not create the promise inside a Client Component render; a new promise on every render suspends forever. Create it on the server or cache it.
- More on `use()`: [fundamentals.md](fundamentals.md#the-use-hook) and [hooks-performance-and-react-19.md](hooks-performance-and-react-19.md).

## Client-Side Fetching

Fetch on the client only when the data is client-owned: polling, infinite scroll, search-as-you-type, or state that changes many times without a navigation. Prefer server fetching for initial page data.

- **TanStack Query**: full cache, mutations, optimistic updates, infinite queries. Setup and patterns are in [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md#tanstack-query-react-query). In Next.js, create the `QueryClient` inside a `'use client'` provider with `useState(() => new QueryClient())`, never at module scope, so requests do not share a cache on the server.
- **SWR**: smaller API for read-mostly data with revalidate-on-focus.

Seed the client cache from the server to skip the first loading state:

```tsx
// app/notifications/page.tsx — Server Component
import { auth } from '@/auth';
import { redirect } from 'next/navigation';
import { getNotifications } from '@/lib/notifications';
import { NotificationList } from './notification-list';

export default async function NotificationsPage() {
  const session = await auth();
  if (!session?.user) redirect('/login');

  const initial = await getNotifications(session.user.id);
  return <NotificationList initial={initial} />;
}
```

```tsx
// app/notifications/notification-list.tsx
'use client'; // polls with SWR

import useSWR from 'swr';
import type { Notification } from '@/lib/types';

async function fetcher(url: string): Promise<Notification[]> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
}

export function NotificationList({ initial }: { initial: Notification[] }) {
  const { data, error } = useSWR('/api/notifications', fetcher, {
    fallbackData: initial,
    refreshInterval: 30_000,
  });

  if (error) return <p role="alert">Could not refresh notifications.</p>;
  return (
    <ul>
      {data.map((n) => (
        <li key={n.id}>{n.message}</li>
      ))}
    </ul>
  );
}
```

The `/api/notifications` Route Handler must authenticate the caller and return only that user's rows. A client fetch is a public HTTP request.

For mutations from the client, prefer a Server Action. When calling a Route Handler instead (third-party clients, retries over flaky networks), send an `Idempotency-Key` header for payments and job submissions. See [workflows/nextjs-route-handler.md](workflows/nextjs-route-handler.md).

## Prefetching with TanStack Query

When a Client Component owns the data through TanStack Query (polling, infinite lists, optimistic mutations), prefetch the first page on the server and hydrate it. The client starts with data and no loading state.

```tsx
// app/projects/page.tsx — Server Component
import { dehydrate, HydrationBoundary, QueryClient } from '@tanstack/react-query';
import { redirect } from 'next/navigation';
import { auth } from '@/auth';
import { listProjects } from '@/lib/projects';
import { ProjectList } from './project-list';

export default async function ProjectsPage() {
  const session = await auth();
  if (!session?.user) redirect('/login');

  const queryClient = new QueryClient(); // new per request, never module scope
  await queryClient.prefetchQuery({
    queryKey: ['projects'],
    queryFn: () => listProjects(session.user.id),
  });

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ProjectList />
    </HydrationBoundary>
  );
}
```

```tsx
// app/projects/project-list.tsx
'use client';

import { useQuery } from '@tanstack/react-query';
import type { Project } from '@/lib/types';

async function fetchProjects(): Promise<Project[]> {
  const res = await fetch('/api/projects');
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
}

export function ProjectList() {
  const { data, error } = useQuery({ queryKey: ['projects'], queryFn: fetchProjects });
  if (error) return <p role="alert">Could not refresh projects.</p>;
  return <ul>{data?.map((p) => <li key={p.id}>{p.name}</li>)}</ul>;
}
```

- Use the same `queryKey` on server and client, and return the same shape from both query functions.
- Set a non-zero `staleTime` (for example `60_000`) on the client `QueryClient`. With the default `0`, the client refetches immediately after hydration.
- Prefetch with `prefetchQuery`, which never throws. Missing data then shows the client's error state; call `notFound()` yourself when the resource must exist.
- For dependent client queries, gate the second query with `enabled: Boolean(firstResult?.id)`.
- Dehydrated data is serialized into the HTML. Prefetch only what this user may see.

## Environment Variables

| Variable | Available in | When it is read |
|----------|--------------|-----------------|
| `DATABASE_URL`, `AUTH_SECRET` (no prefix) | Server only | At runtime |
| `NEXT_PUBLIC_API_URL` | Server and browser | Inlined into the bundle at build time |

- Unprefixed variables are `undefined` in the browser, including in Client Component code. Read them in Server Components, Server Actions, Route Handlers, or `server-only` modules.
- Never give a secret the `NEXT_PUBLIC_` prefix. Its value ships to every visitor.
- `NEXT_PUBLIC_` values are frozen at build time. Changing them needs a rebuild; for per-deployment values, read an unprefixed variable on the server and pass it down as a prop.
- Validate both sets once at startup. Schemas and the literal-access rule for public values: [zod.md](zod.md#environment-variables).

## Route Handlers

A `route.ts` (or `route.js`) under `app/` exports functions named after HTTP methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`. Unsupported methods return `405`. A `route.ts` cannot share a folder with a `page.tsx`. File placement and the `params` basics are in [nextjs-routing.md](nextjs-routing.md#route-handlers); this section covers the full request and response handling.

### Signature

```tsx
// app/api/projects/[id]/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';
import { auth } from '@/auth';
import { db } from '@/lib/db';

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: NextRequest, { params }: RouteContext) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { id } = await params; // async since 15
  const fields = request.nextUrl.searchParams.get('fields'); // query string

  // Scope the read to the owner; 404 hides whether the row exists
  const project = await db.projects.findFirst({
    where: { id, ownerId: session.user.id },
    select: fields === 'summary' ? { id: true, name: true } : undefined,
  });
  if (!project) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json(project);
}
```

- `NextRequest` extends the Web `Request` with `nextUrl` (parsed URL with `searchParams`) and `cookies`. A plain `Request` works when those are not needed.
- `NextResponse.json(body, init)` sets `Content-Type`. `new NextResponse(null, { status: 204 })` returns an empty body.
- `cookies()` and `headers()` from `next/headers` also work in Route Handlers. Await them.
- Route Handlers run on the Node.js runtime by default.

### Reading and validating the body

Parse every body with a Zod schema and pass only the parsed fields to the database. Zod 4 strips unknown keys from `z.object()` by default, which whitelists fields.

```tsx
// app/api/projects/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/lib/db';

const CreateProjectSchema = z.object({
  name: z.string().trim().min(1).max(100),
  description: z.string().max(2000).optional(),
  contactEmail: z.email().optional(), // Zod 4 top-level format
});

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body: unknown = await request.json().catch(() => undefined);
  if (body === undefined) {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const parsed = CreateProjectSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: z.flattenError(parsed.error).fieldErrors },
      { status: 400 }
    );
  }

  // Owner comes from the session, never from the body
  const project = await db.projects.create({
    data: { ...parsed.data, ownerId: session.user.id },
  });

  return NextResponse.json(project, { status: 201 });
}
```

Read form posts and uploads with `request.formData()`:

```tsx
const form = await request.formData();
const file = form.get('file');
if (!(file instanceof File) || file.size === 0) {
  return NextResponse.json({ error: 'No file provided' }, { status: 400 });
}
```

- Read the body once. Pick `request.json()`, `request.formData()`, `request.text()` (needed for webhook signatures), or `request.arrayBuffer()`.
- App Router ignores the Pages Router `export const config = { api: { bodyParser: false } }`. Remove it and read the raw body with `request.text()` or `request.arrayBuffer()`.
- Enforce size limits yourself: check `file.size` and reject with `413`. Hosting platforms also cap request bodies (Vercel Functions at 4.5 MB).
- Coerce and bound query parameters: `z.coerce.number().int().min(1).max(100).default(20)`.

### Status codes

| Status | When |
|--------|------|
| `200` | Read or update succeeded |
| `201` | Resource created (return it, or its URL in `Location`) |
| `204` | Delete succeeded, no body |
| `400` | Malformed JSON or failed validation |
| `401` | No valid session |
| `403` | Signed in but not allowed (use `404` when the resource's existence is private) |
| `404` | Resource not found or not visible to this user |
| `409` | Conflict, such as a unique constraint or an idempotency key reused with a different body |
| `413` | Body or file too large |
| `415` | Unsupported content type |
| `429` | Rate limited (set `Retry-After`) |
| `500` | Unexpected failure. Log the error; return a generic message without stack traces |

### Streaming responses

Return a `ReadableStream` for Server-Sent Events or incremental output. Stop producing when the client disconnects.

```tsx
// app/api/progress/route.ts — Server
import type { NextRequest } from 'next/server';

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder();
  const { signal } = request; // aborts when the client disconnects

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i <= 100 && !signal.aborted; i += 10) {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ progress: i })}\n\n`));
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      if (!signal.aborted) controller.close();
    },
  });

  // No 'Connection' header: it is hop-by-hop and invalid over HTTP/2
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
    },
  });
}
```

Authenticate streaming endpoints the same way as any other handler before opening the stream.

### CORS

Same-origin calls from the app itself need no CORS headers. For cross-origin callers, allow an explicit list of origins and answer the preflight `OPTIONS` request.

```tsx
// app/api/public/stats/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';

const ALLOWED_ORIGINS = new Set(['https://partner.example.com', 'https://app.example.com']);

function corsHeaders(origin: string | null): HeadersInit {
  if (!origin || !ALLOWED_ORIGINS.has(origin)) return {};
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '600',
    Vary: 'Origin',
  };
}

export function OPTIONS(request: NextRequest) {
  return new NextResponse(null, { status: 204, headers: corsHeaders(request.headers.get('origin')) });
}

export async function GET(request: NextRequest) {
  const stats = await getPublicStats();
  return NextResponse.json(stats, { headers: corsHeaders(request.headers.get('origin')) });
}
```

- Never reflect an arbitrary `Origin` together with `Access-Control-Allow-Credentials: true`. That lets any site make authenticated requests as the app's users.
- CORS is a browser rule, not access control. Authenticate the request regardless.

### Route Handler or Server Action

| Use a Server Action | Use a Route Handler |
|---------------------|---------------------|
| Form posts and mutations from the app's own React UI | Webhooks from Stripe, GitHub, and other providers |
| Progressive enhancement with `<form action>` | Mobile apps, CLIs, third-party clients |
| Typed call from a Client Component | Custom status codes, headers, streaming, CORS |

Server Action patterns: [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms) and [fundamentals.md](fundamentals.md#server-actions). Full Route Handler templates with ownership checks, idempotency keys, uploads, and webhooks: [workflows/nextjs-route-handler.md](workflows/nextjs-route-handler.md).

## Static Params

`generateStaticParams` prerenders dynamic segments at build time; its full usage, nested segments, and `dynamicParams` are in [nextjs-routing.md](nextjs-routing.md#generatestaticparams). For data fetching, keep these rules:

- Load the param list straight from the database (not the app's own Route Handler, which is not running during the build), and select only the key fields: `select: { slug: true }`.
- Return only public, published rows. Prerendered pages are served to everyone.
- Share the page loader with `generateMetadata` through React `cache()` so each prerendered page runs one query.
- Reading `searchParams`, `cookies()`, or `headers()` in the page makes it render per request, which defeats prerendering.
- For a large catalog, return the most visited slugs and let the rest render on first request.
- `dynamicParams = false` (404 for unlisted values) is not allowed with `cacheComponents: true`; call `notFound()` instead. See [nextjs-caching.md](nextjs-caching.md#segment-config-and-cache-components). ISR and revalidation intervals are covered in [nextjs-caching.md](nextjs-caching.md#static-generation-and-isr).

## Error Handling

Throw from a Server Component to reach the nearest `error.tsx`. Call `notFound()` for missing rows so the segment's `not-found.tsx` renders with a `404` status.

```tsx
// app/posts/error.tsx
'use client'; // error boundaries must be Client Components

export default function PostsError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div role="alert">
      <h2>Could not load posts</h2>
      {/* In production, error.message is replaced; log error.digest to correlate with server logs */}
      <button type="button" onClick={() => reset()}>
        Try again
      </button>
    </div>
  );
}
```

- Check `res.ok` after every `fetch`. A `404` or `500` response does not reject the promise.
- Catch locally only when something useful can be rendered in place (a "comments unavailable" note). Otherwise let the error reach `error.tsx`.
- Do not catch `redirect()` or `notFound()`. They work by throwing; wrapping them in `try/catch` swallows them.
- File conventions for `loading.tsx`, `error.tsx`, and `not-found.tsx`: [nextjs-routing.md](nextjs-routing.md#loading-error-and-not-found).

## Best Practices

| Practice | Why |
|----------|-----|
| Fetch in Server Components, close to where data is used | No client bundle cost, no request waterfall from the browser |
| Start independent requests together | Total time equals the slowest request, not the sum |
| Wrap shared loaders in React `cache()` | One query per request across metadata, layouts, and pages |
| Put `<Suspense>` around slow, independent regions | The shell paints immediately |
| Mark data modules with `import 'server-only'` | Secrets and DB code never reach the client |
| Pass the smallest serializable shape to Client Components | Smaller payload, no leaked fields |
| Authenticate and scope every Route Handler | Each one is a public HTTP endpoint |
| Validate bodies and query strings with Zod | URL and body input is untrusted |
| Prefer Server Actions for the app's own forms | Less code, progressive enhancement |
| Decide caching deliberately | See [nextjs-caching.md](nextjs-caching.md) |
