# Next.js App Router Routing

File conventions, dynamic segments, async `params`, route groups, parallel and intercepting routes, navigation, and metadata for Next.js 15 and 16. Load it when creating or restructuring routes under `app/`, or when fixing async `params`/`searchParams` errors.

## Contents

- [Quick Reference](#quick-reference)
- [File Conventions](#file-conventions)
- [Layouts and Templates](#layouts-and-templates)
- [Loading, Error, and Not Found](#loading-error-and-not-found)
- [Dynamic Segments](#dynamic-segments)
- [Async params and searchParams](#async-params-and-searchparams)
- [generateStaticParams](#generatestaticparams)
- [Route Groups and Private Folders](#route-groups-and-private-folders)
- [Parallel Routes](#parallel-routes)
- [Intercepting Routes](#intercepting-routes)
- [Navigation](#navigation)
- [Metadata](#metadata)
- [Route Handlers](#route-handlers)
- [Best Practices](#best-practices)

## Quick Reference

| File | Purpose | Boundary |
|------|---------|----------|
| `page.tsx` | Route UI. A folder is only a public route if it has one | Server (default) |
| `layout.tsx` | Shared UI that persists across navigations | Server (default) |
| `template.tsx` | Like a layout, but re-mounts on every navigation | Server (default) |
| `loading.tsx` | Suspense fallback for the segment | Server (default) |
| `error.tsx` | Error boundary for the segment | Must be `'use client'` |
| `global-error.tsx` | Error boundary for the root layout | Must be `'use client'` |
| `not-found.tsx` | UI for `notFound()` and unmatched URLs | Server (default) |
| `default.tsx` | Fallback for a parallel route slot | Server (default) |
| `route.ts` | HTTP handler (cannot share a folder with `page.tsx`) | Server |

| Pattern | Folder | `params` for a sample URL |
|---------|--------|---------------------------|
| Dynamic | `[slug]` | `/blog/hello` → `{ slug: 'hello' }` |
| Catch-all | `[...slug]` | `/docs/a/b` → `{ slug: ['a', 'b'] }` |
| Optional catch-all | `[[...slug]]` | `/shop` → `{ slug: undefined }` |
| Route group | `(name)` | No URL segment |
| Private folder | `_name` | Not routable |
| Parallel route | `@slot` | No URL segment, passed to the layout as a prop |
| Intercepting route | `(.)x`, `(..)x`, `(..)(..)x`, `(...)x` | Renders `x` inside the current layout |

The Server vs Client Component boundary (`'use client'`, serializable props, composition) is covered in [fundamentals.md](fundamentals.md#server-vs-client-components). Every file in this reference is a Server Component unless it says `'use client'`.

## File Conventions

```text
app/
├── layout.tsx              # Root layout (required, renders <html> and <body>)
├── page.tsx                # /
├── loading.tsx, error.tsx, not-found.tsx, global-error.tsx
├── (marketing)/about/page.tsx   # /about (route group adds no segment)
├── _components/            # Private folder: not a route
├── dashboard/
│   ├── layout.tsx          # Receives {children}, {analytics}
│   ├── page.tsx            # /dashboard
│   ├── @analytics/page.tsx + default.tsx
│   └── settings/page.tsx   # /dashboard/settings
├── blog/[slug]/page.tsx    # /blog/:slug
├── docs/[...slug]/page.tsx # /docs/*
├── shop/[[...slug]]/page.tsx # /shop and /shop/*
└── api/posts/route.ts      # Route Handler
```

The segment files nest in a fixed order: `layout` wraps `template`, which wraps `error`, which wraps `loading`, which wraps `not-found`, which wraps `page`. An `error.tsx` therefore does not catch errors thrown by the `layout.tsx` in the same folder. Put the boundary one level up, or use `global-error.tsx` for the root layout.

## Layouts and Templates

The root layout is required and must render `<html>` and `<body>`.

```tsx
// app/layout.tsx
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: { template: '%s | My App', default: 'My App' },
  description: 'My application',
  metadataBase: new URL('https://example.com'),
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header>{/* Navigation */}</header>
        <main>{children}</main>
      </body>
    </html>
  );
}
```

```tsx
// app/dashboard/layout.tsx
import { Sidebar } from './_components/sidebar';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="dashboard">
      <Sidebar />
      <div className="content">{children}</div>
    </div>
  );
}
```

Layouts keep their state and do not re-render on navigation between child pages. Layouts do not receive `searchParams`. Read them in the page, or with `useSearchParams` in a Client Component.

Use `template.tsx` only when a wrapper must re-mount on every navigation: resetting form state, re-running an enter animation, or re-logging a page view in an effect.

```tsx
// app/dashboard/template.tsx
export default function DashboardTemplate({ children }: { children: React.ReactNode }) {
  return <div className="fade-in">{children}</div>;
}
```

## Loading, Error, and Not Found

`loading.tsx` wraps the segment's `page` in a `<Suspense>` boundary and shows instantly on navigation.

```tsx
// app/posts/loading.tsx
export default function PostsLoading() {
  return <div className="skeleton" aria-busy="true" />;
}
```

For finer streaming, wrap slow components in their own `<Suspense>` inside the page. See [fundamentals.md](fundamentals.md#suspense-and-error-boundaries).

```tsx
// app/dashboard/error.tsx
'use client';

import { useEffect } from 'react';

export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error); // send to your error reporter
  }, [error]);

  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

In production, server errors reach `error.tsx` with a generic `message` and a `digest` that matches the server log. Do not render raw messages that may contain internal details.

`app/global-error.tsx` replaces the root layout when it fails, so it must render its own `<html>` and `<body>` and be a Client Component.


```tsx
// app/not-found.tsx
import Link from 'next/link';

export default function NotFound() {
  return (
    <div>
      <h2>Page not found</h2>
      <Link href="/">Return home</Link>
    </div>
  );
}
```

Call `notFound()` from `next/navigation` in a page, layout, or `generateMetadata` to render the nearest `not-found.tsx`. It throws, so code after it does not run, and TypeScript narrows the value afterwards.

## Dynamic Segments

```tsx
// app/shop/[category]/[product]/page.tsx
type Props = { params: Promise<{ category: string; product: string }> };

export default async function ProductPage({ params }: Props) {
  const { category, product } = await params;
  const item = await getProduct(category, product);
  return <h1>{item.name}</h1>;
}
```

```tsx
// app/docs/[...slug]/page.tsx: /docs/api/auth → ['api', 'auth']
type Props = { params: Promise<{ slug: string[] }> };

export default async function DocsPage({ params }: Props) {
  const { slug } = await params;
  const doc = await getDoc(slug.join('/'));
  return <article>{doc.title}</article>;
}
```

```tsx
// app/shop/[[...slug]]/page.tsx: also matches /shop with slug undefined
type Props = { params: Promise<{ slug?: string[] }> };

export default async function ShopPage({ params }: Props) {
  const { slug } = await params;
  if (!slug) return <AllProducts />;
  if (slug.length === 1) return <Category category={slug[0]} />;
  return <ProductDetail category={slug[0]} product={slug[1]} />;
}
```

Treat every segment value as untrusted input. Validate it (for example with a Zod schema or a lookup that returns `null`) and call `notFound()` when it does not resolve.

## Async params and searchParams

Since Next.js 15, `params` and `searchParams` are Promises. Next.js 15 still allowed synchronous access with a warning. Next.js 16 removes it. `cookies()`, `headers()`, and `draftMode()` from `next/headers` are async on the same schedule.

| Where | How to read |
|-------|-------------|
| Server `page`, `layout`, `generateMetadata`, `route.ts` | `const { id } = await params` |
| Client Component page | `const { id } = use(params)` with `use` from `react` |
| Any Client Component below the page | `useParams()`, `useSearchParams()` from `next/navigation` |
| `generateStaticParams` | Its own `params` argument is a plain object (synchronous) |

```tsx
// app/search/page.tsx
type Props = {
  searchParams: Promise<{ q?: string; page?: string; sort?: string }>;
};

export default async function SearchPage({ searchParams }: Props) {
  const { q = '', page = '1', sort = 'relevance' } = await searchParams;
  const pageNumber = Math.max(1, Number(page) || 1);
  const results = await search({ query: q, page: pageNumber, sort });
  return <SearchResults query={q} results={results} />;
}
```

```tsx
// app/posts/[id]/edit/page.tsx
'use client';

import { use } from 'react';

export default function EditPost({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <PostEditor id={id} />;
}
```

Next.js 15.5+ generates global `PageProps<'/blog/[slug]'>` and `LayoutProps<'/dashboard'>` helpers during `next dev`/`next build`/`next typegen`. Use them instead of hand-written prop types when the project already does.

Upgrade sync usage with `npx @next/codemod@canary next-async-request-api .`. See [react-19-upgrade.md](react-19-upgrade.md) for the React side of the upgrade.

## generateStaticParams

`generateStaticParams` returns the segment values to prerender at build time. Its return values are plain objects whose keys match the segment names.

```tsx
// app/blog/[slug]/page.tsx
import { notFound } from 'next/navigation';

export async function generateStaticParams() {
  const posts = await db.posts.findMany({ where: { published: true }, select: { slug: true } });
  return posts.map((post) => ({ slug: post.slug }));
}

export default async function PostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) notFound();
  return <article>{post.title}</article>;
}
```

For nested dynamic segments, a child `generateStaticParams` receives the parent's values as a synchronous `params` argument.

```tsx
// app/products/[category]/[product]/page.tsx
export async function generateStaticParams({ params }: { params: { category: string } }) {
  const products = await getProductsInCategory(params.category);
  return products.map((p) => ({ product: p.slug }));
}
```

- Return a subset (for example the top 100 items) to keep builds fast. Other values render on first request and are then cached, unless the route opts out.
- Without Cache Components, `export const dynamicParams = false` makes unknown values 404. With `cacheComponents: true` that export is an error, so call `notFound()` for unknown values instead. See [nextjs-caching.md](nextjs-caching.md#segment-config-and-cache-components).
- Only published, public content belongs here. Never prerender drafts or per-user pages.

## Route Groups and Private Folders

A folder named `(name)` groups routes and lets them share a layout without adding a URL segment.

```text
app/
├── (marketing)/
│   ├── layout.tsx          # Marketing header and footer
│   ├── about/page.tsx      # /about
│   └── pricing/page.tsx    # /pricing
├── (shop)/
│   ├── layout.tsx          # Shop chrome with cart
│   └── cart/page.tsx       # /cart
└── (auth)/
    ├── layout.tsx          # Centered, minimal
    └── login/page.tsx      # /login
```

- Two groups must not resolve to the same URL (for example `(a)/about` and `(b)/about`). That is a build error.
- To get multiple root layouts, remove `app/layout.tsx` and give each group its own `layout.tsx` that renders `<html>` and `<body>`. Navigating between root layouts triggers a full page load.

A folder whose name starts with `_` is private. Nothing inside it becomes a route, so use it to colocate components and helpers.

```text
app/
├── _lib/format.ts
└── dashboard/
    ├── _components/chart.tsx
    └── page.tsx
```

Colocating non-route files works without the underscore too (only `page` and `route` files are public), but the prefix makes intent clear and avoids collisions with future conventions.

## Parallel Routes

A folder named `@slot` defines a named slot. The parent layout receives each slot as a prop next to `children`. Each slot can have its own `loading.tsx` and `error.tsx`, so it streams and fails independently.

```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode;
  analytics: React.ReactNode;
  team: React.ReactNode;
}) {
  return (
    <div className="grid">
      <main>{children}</main>
      <aside>
        {analytics}
        {team}
      </aside>
    </div>
  );
}
```

### default.tsx

On soft navigation, a slot with no match for the new URL keeps its previous content. On a hard load or refresh, Next.js renders the slot's `default.tsx`, or a 404 if there is none.

```tsx
// app/dashboard/@analytics/default.tsx
export default function AnalyticsDefault() {
  return null;
}
```

Next.js 16 fails the build when a slot has no `default.tsx`. Add one to every slot (and to the folder's implicit `children` slot when sub-pages exist only in other slots), returning `null` or calling `notFound()`.

### Conditional slots

```tsx
// app/dashboard/layout.tsx
import { auth } from '@/auth';

export default async function Layout({
  children,
  admin,
  user,
}: {
  children: React.ReactNode;
  admin: React.ReactNode;
  user: React.ReactNode;
}) {
  const session = await auth();
  return (
    <>
      {children}
      {session?.user?.role === 'admin' ? admin : user}
    </>
  );
}
```

Choosing which slot to render is presentation only. The data loaders and Server Actions behind the `admin` slot must still check the role themselves.

## Intercepting Routes

An intercepting route renders another route inside the current layout during soft navigation, while a direct visit or refresh renders the full page. The classic use is a modal.

| Prefix | Matches |
|--------|---------|
| `(.)` | Same level |
| `(..)` | One route segment up |
| `(..)(..)` | Two route segments up |
| `(...)` | From the `app` root |

The prefixes count route segments, not file-system folders, so `@slot` and `(group)` folders are ignored.

```text
app/
├── layout.tsx               # Renders {children} and {modal}
├── feed/page.tsx            # Links to /photo/[id]
├── photo/[id]/page.tsx      # Full page on direct visit or refresh
└── @modal/
    ├── default.tsx          # Returns null
    └── (.)photo/[id]/page.tsx  # Modal on soft navigation from /feed
```

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
  modal,
}: {
  children: React.ReactNode;
  modal: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {children}
        {modal}
      </body>
    </html>
  );
}
```

```tsx
// app/@modal/(.)photo/[id]/page.tsx
import { notFound } from 'next/navigation';
import { Modal } from '@/components/modal';

export default async function PhotoModal({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const photo = await getPhoto(id);
  if (!photo) notFound();
  return (
    <Modal>
      <img src={photo.url} alt={photo.title} />
    </Modal>
  );
}
```

```tsx
// components/modal.tsx
'use client';

import { useRouter } from 'next/navigation';

export function Modal({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  return (
    <div className="overlay" onClick={() => router.back()}>
      <div role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
        <button onClick={() => router.back()} aria-label="Close">×</button>
        {children}
      </div>
    </div>
  );
}
```

To close the modal when the user navigates elsewhere with a `<Link>`, add `app/@modal/[...catchAll]/page.tsx` that returns `null`. Use a native `<dialog>` or an accessible dialog library for focus trapping and Escape handling.

## Navigation

| Need | API | Where |
|------|-----|-------|
| Declarative link | `<Link href="/x">` from `next/link` | Server or Client |
| Push, replace, back, refresh, prefetch | `useRouter()` from `next/navigation` | Client |
| Current path | `usePathname()` | Client |
| Query string | `useSearchParams()` | Client |
| Dynamic segment values | `useParams()` | Client |
| Redirect (307, or 303 after a Server Action) | `redirect('/x')` | Server Component, Server Action, Route Handler |
| Permanent redirect (308) | `permanentRedirect('/x')` | Same as `redirect` |
| 404 | `notFound()` | Server Component, `generateMetadata` |

Import `useRouter` from `next/navigation`, never from `next/router` (Pages Router only).

```tsx
import Link from 'next/link';

export function Nav() {
  return (
    <nav>
      <Link href="/">Home</Link>
      <Link href="/blog" prefetch={false}>Blog</Link>
      <Link href="/dashboard" replace>Dashboard</Link>
      <Link href={{ pathname: '/search', query: { q: 'react' } }}>Search</Link>
    </nav>
  );
}
```

### Updating the query string

```tsx
// components/sort-select.tsx
'use client';

import { usePathname, useRouter, useSearchParams } from 'next/navigation';

export function SortSelect() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function setSort(value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.set('sort', value);
    params.delete('page');
    router.replace(`${pathname}?${params.toString()}`, { scroll: false });
  }

  return (
    <select defaultValue={searchParams.get('sort') ?? 'relevance'} onChange={(e) => setSort(e.target.value)}>
      <option value="relevance">Relevance</option>
      <option value="date">Date</option>
    </select>
  );
}
```

A Client Component that calls `useSearchParams()` on a statically rendered route must sit inside a `<Suspense>` boundary, or the build fails with "Missing Suspense boundary with useSearchParams". Wrap it in the parent page.

### redirect and notFound

```tsx
// app/account/page.tsx
import { redirect } from 'next/navigation';
import { auth } from '@/auth';

export default async function AccountPage() {
  const session = await auth();
  if (!session?.user) redirect('/login?callbackUrl=/account');
  return <Account userId={session.user.id} />;
}
```

`redirect`, `permanentRedirect`, and `notFound` work by throwing. Call them outside `try`/`catch`, or rethrow in the `catch`, otherwise the catch block swallows the navigation. In a Server Action, call `redirect` after the mutation and cache invalidation.

## Metadata

Export a static `metadata` object or an async `generateMetadata` function from a `page.tsx` or `layout.tsx` (Server Components only). Child segments merge over their parents. `title.template` in a layout formats child titles.

```tsx
// app/about/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About', // "About | My App" via the root template
  description: 'Who we are',
  openGraph: { images: ['/og-about.png'] },
};
```

```tsx
// app/products/[id]/page.tsx
import type { Metadata, ResolvingMetadata } from 'next';
import { cache } from 'react';
import { notFound } from 'next/navigation';

type Props = { params: Promise<{ id: string }> };

// One query per request, shared by generateMetadata and the page
const getProduct = cache(async (id: string) => db.products.findUnique({ where: { id } }));

export async function generateMetadata({ params }: Props, parent: ResolvingMetadata): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);
  if (!product) return { title: 'Not found' };

  const previousImages = (await parent).openGraph?.images ?? [];
  return {
    title: product.name,
    description: product.summary,
    openGraph: { images: [product.imageUrl, ...previousImages] },
  };
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await getProduct(id);
  if (!product) notFound();
  return <h1>{product.name}</h1>;
}
```

File-based metadata also works per segment: `opengraph-image.tsx`, `icon.tsx`, `apple-icon.png`, and at the root `sitemap.ts` and `robots.ts`. Set `metadataBase` in the root layout so relative image URLs resolve to absolute ones.

### viewport

`themeColor`, `colorScheme`, and viewport settings go in a separate `viewport` export (or `generateViewport`), not in `metadata`.

```tsx
// app/layout.tsx
import type { Viewport } from 'next';

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
};
```

Next.js already emits `width=device-width, initial-scale=1`. Do not set `maximumScale: 1` or `userScalable: false`: blocking zoom fails WCAG 1.4.4.

### Sitemaps, robots, and structured data

`sitemap.ts`, `robots.ts`, Open Graph images, canonical URLs, and JSON-LD are covered in [nextjs-performance.md](nextjs-performance.md#metadata-and-seo).

## Route Handlers

A `route.ts` under `app/` exports functions named after HTTP methods. It cannot share a folder with a `page.tsx`, and `params` arrives as a Promise on the second argument (`{ params }: { params: Promise<{ id: string }> }`). For request and response handling, auth, validation, and caching, see [nextjs-data-fetching.md](nextjs-data-fetching.md#route-handlers). For choosing between a Route Handler and a Server Action, see [nextjs-data-fetching.md](nextjs-data-fetching.md#route-handler-or-server-action).

## Best Practices

| Practice | Why |
|----------|-----|
| Keep pages and layouts as Server Components | Push `'use client'` down to interactive leaves |
| Await `params` and `searchParams` | Required in 16, warned in 15 |
| Add `loading.tsx` and `error.tsx` per major segment | Instant feedback and contained failures |
| Add `default.tsx` to every parallel slot | Avoids 404s on refresh; required to build in 16 |
| Validate segment values and call `notFound()` | URL input is untrusted |
| Share data between `generateMetadata` and the page with React `cache()` | One query per request |
| Use route groups for layout variants | No URL changes |
| Keep `redirect`/`notFound` outside `try`/`catch` | They throw to work |
| Authorize in the page, action, or handler | Layout and proxy checks alone are not authorization |
