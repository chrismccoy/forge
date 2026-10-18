# Workflow: Generate Next.js Page

Create a Next.js 15 or 16 App Router page with its `loading.tsx`, `error.tsx`, and (for dynamic segments) `not-found.tsx`, plus metadata and static params. Use it when the user asks to "create page `dashboard/settings`" or "add a `posts/[slug]` page".

## Contents

- [Instructions](#instructions)
- [Example Output](#example-output)
  - [Static page](#static-page)
  - [Dynamic page with metadata and static params](#dynamic-page-with-metadata-and-static-params)
  - [Loading state](#loading-state)
  - [Error boundary](#error-boundary)
  - [Not found](#not-found)
  - [Per-user page with validated searchParams](#per-user-page-with-validated-searchparams)
  - [Client Component receiving params](#client-component-receiving-params)
  - [Cached page (Next.js 16)](#cached-page-nextjs-16)
- [Checklist](#checklist)
- [Related](#related)

## Instructions

1. **Inspect the project first**
   - Read the Next.js version in `package.json`. On 15, `params` and `searchParams` are Promises and sync access only warns; on 16, sync access is removed.
   - Check whether routes live in `app/` or `src/app/`.
   - Read path aliases in `tsconfig.json` (`@/` or similar).
   - Find existing helpers: auth (`@/auth`, `auth()`), DB client (`@/lib/db`), data loaders in `lib/`, UI skeletons, and an existing `error.tsx` to match.
   - Check `next.config` for `cacheComponents: true`. If set, segment configs (`dynamic`, `revalidate`, `dynamicParams`) are build errors.
   - Match existing conventions over the templates below.

2. **Analyze the request**
   - Parse the URL path and dynamic segments: `[slug]`, `[...slug]`, `[[...slug]]`. See [nextjs-routing.md](../nextjs-routing.md#dynamic-segments).
   - Decide the data source and whether the page is public, per-user, or admin-only.
   - Decide static or dynamic: public content with known slugs gets `generateStaticParams`; pages that read the session, `cookies()`, `headers()`, or `searchParams` render per request.
   - Check that no `route.ts` exists in the same folder. A `page.tsx` and `route.ts` cannot share a segment.

3. **Create the files**
   - `page.tsx`: async Server Component. Type `params` and `searchParams` as Promises and `await` them.
   - `loading.tsx`: skeleton shaped like the page.
   - `error.tsx`: `'use client'` error boundary with a `reset` button.
   - `not-found.tsx`: for dynamic segments, rendered when the page calls `notFound()`.
   - `export const metadata` for static pages, or `generateMetadata` for dynamic ones. Share the loader between `generateMetadata` and the page with React `cache()`.
   - `generateStaticParams` for public dynamic pages with a known set of values.
   - Add `layout.tsx` only when several sibling pages share UI.

4. **Apply data and safety rules**
   - Fetch on the server; start independent requests together with `Promise.all`. See [nextjs-data-fetching.md](../nextjs-data-fetching.md#parallel-and-sequential-fetching).
   - Validate URL input (segments and `searchParams`) and call `notFound()` for unknown values.
   - Per-user pages: call `auth()` in the page (or its layout), `redirect('/login')` when signed out, and scope every query to `session.user.id`. A proxy check alone is not authorization.
   - Sanitize any stored HTML before `dangerouslySetInnerHTML`, or store Markdown.
   - Put interactivity in small `'use client'` leaf components; keep the page a Server Component.
   - Mutations from the page go through Server Actions. See [forms-server-actions.md](../forms-server-actions.md#server-actions-with-forms).
   - Caching (`'use cache'`, `cacheLife`, `cacheTag`, ISR) follows [nextjs-caching.md](../nextjs-caching.md).

5. **Report**
   - List every created file path and mark each as Server or Client.
   - Flag version-specific features (async `params`, `'use cache'`) with the minimum Next.js version.

Optional shortcut: scaffold the files with the bundled generator, then edit them. It refuses to overwrite existing files unless `--force` is passed (only with the user's consent).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/generate-nextjs-component.py page --path 'app/posts/[slug]' --with-loading --with-error
```

## Example Output

### Static page

```tsx
// app/about/page.tsx — Server Component
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About Us',
  description: 'Learn more about our company',
};

export default function AboutPage() {
  return (
    <main>
      <h1>About Us</h1>
      <p>Content here…</p>
    </main>
  );
}
```

### Dynamic page with metadata and static params

```tsx
// lib/posts.ts — server-only loaders
import 'server-only';
import { cache } from 'react';
import { db } from '@/lib/db';

// cache(): generateMetadata and the page share one query per request
export const getPost = cache(async (slug: string) => {
  return db.posts.findFirst({
    where: { slug, published: true },
    select: { title: true, excerpt: true, content: true, publishedAt: true },
  });
});

export async function getPublishedSlugs() {
  return db.posts.findMany({ where: { published: true }, select: { slug: true } });
}
```

```tsx
// app/posts/[slug]/page.tsx — Server Component
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import DOMPurify from 'isomorphic-dompurify';
import { getPost, getPublishedSlugs } from '@/lib/posts';

interface PageProps {
  params: Promise<{ slug: string }>;
  // No searchParams: reading it makes the page dynamic and defeats generateStaticParams
}

export async function generateStaticParams() {
  const posts = await getPublishedSlugs();
  return posts.map((post) => ({ slug: post.slug }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) return { title: 'Post not found' };

  return {
    title: post.title,
    description: post.excerpt ?? undefined,
    openGraph: { title: post.title, type: 'article' },
  };
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) notFound();

  return (
    <article>
      <h1>{post.title}</h1>
      <time dateTime={post.publishedAt.toISOString()}>
        {post.publishedAt.toLocaleDateString('en-US')}
      </time>
      {/* Stored HTML must be sanitized (XSS); or store Markdown and render it with react-markdown */}
      <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(post.content) }} />
    </article>
  );
}
```

### Loading state

```tsx
// app/posts/[slug]/loading.tsx — Server Component
export default function Loading() {
  return (
    <div role="status" aria-label="Loading post" className="animate-pulse">
      <div className="mb-4 h-8 w-3/4 rounded bg-gray-200" />
      <div className="mb-2 h-4 w-full rounded bg-gray-200" />
      <div className="h-4 w-5/6 rounded bg-gray-200" />
    </div>
  );
}
```

### Error boundary

```tsx
// app/posts/[slug]/error.tsx
'use client'; // error boundaries must be Client Components

import { useEffect } from 'react';

export default function PostError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Report to your error tracker; digest matches the server log entry
    console.error(error);
  }, [error]);

  return (
    <div role="alert">
      <h2>Something went wrong loading this post.</h2>
      <button type="button" onClick={() => reset()}>
        Try again
      </button>
    </div>
  );
}
```

### Not found

```tsx
// app/posts/[slug]/not-found.tsx — Server Component
import Link from 'next/link';

export default function PostNotFound() {
  return (
    <main>
      <h1>Post not found</h1>
      <p>The post may have been unpublished or the link is wrong.</p>
      <Link href="/posts">Back to all posts</Link>
    </main>
  );
}
```

### Per-user page with validated searchParams

```tsx
// app/dashboard/orders/page.tsx — Server Component (renders per request)
import type { Metadata } from 'next';
import { Suspense } from 'react';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/lib/db';

export const metadata: Metadata = { title: 'Your orders' };

const QuerySchema = z.object({
  status: z.enum(['open', 'shipped', 'cancelled']).optional(),
  page: z.coerce.number().int().min(1).max(1000).default(1),
});

interface PageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function OrdersPage({ searchParams }: PageProps) {
  const session = await auth();
  if (!session?.user) redirect('/login?callbackUrl=/dashboard/orders');

  // Invalid query values fall back to defaults instead of erroring
  const parsed = QuerySchema.safeParse(await searchParams);
  const { status, page } = parsed.success ? parsed.data : { status: undefined, page: 1 };

  return (
    <main>
      <h1>Your orders</h1>
      {/* key: show the fallback again when the filter changes */}
      <Suspense key={`${status}-${page}`} fallback={<p role="status">Loading orders…</p>}>
        <OrderList userId={session.user.id} status={status} page={page} />
      </Suspense>
    </main>
  );
}

async function OrderList({
  userId,
  status,
  page,
}: {
  userId: string;
  status?: 'open' | 'shipped' | 'cancelled';
  page: number;
}) {
  const orders = await db.orders.findMany({
    where: { userId, ...(status && { status }) }, // scoped to the signed-in user
    orderBy: { createdAt: 'desc' },
    skip: (page - 1) * 20,
    take: 20,
    select: { id: true, total: true, status: true, createdAt: true },
  });

  if (orders.length === 0) return <p>No orders yet.</p>;
  return (
    <ul>
      {orders.map((order) => (
        <li key={order.id}>
          #{order.id} · {order.status} · {order.total}
        </li>
      ))}
    </ul>
  );
}
```

### Client Component receiving params

A Client Component cannot be `async`. Read a `params` Promise with `use()`, or call `useParams()`.

```tsx
// app/posts/[slug]/share-button.tsx
'use client'; // uses the clipboard API and click handlers

import { use, useState } from 'react';

export function ShareButton({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = use(params);
  const [copied, setCopied] = useState(false);

  async function copy() {
    await navigator.clipboard.writeText(`${window.location.origin}/posts/${slug}`);
    setCopied(true);
  }

  return (
    <button type="button" onClick={copy}>
      {copied ? 'Link copied' : 'Copy link'}
    </button>
  );
}
```

### Cached page (Next.js 16)

With `cacheComponents: true` in `next.config.ts`, put `'use cache'` inside the component, not at the top of the file: a file-level `'use cache'` module may only export async functions, so `export const metadata` would break the build. Tag and invalidation rules are in [nextjs-caching.md](../nextjs-caching.md#cache-components-and-use-cache).

```tsx
// app/products/page.tsx — Server Component
import type { Metadata } from 'next';
import { cacheLife, cacheTag } from 'next/cache';
import { db } from '@/lib/db';
import { ProductGrid } from '@/components/product-grid';

export const metadata: Metadata = {
  title: 'Products',
  description: 'Browse our products',
};

export default async function ProductsPage() {
  'use cache';
  cacheLife('hours');
  cacheTag('products');

  const products = await db.products.findMany({ orderBy: { createdAt: 'desc' } });

  return (
    <main>
      <h1>Products</h1>
      <ProductGrid products={products} />
    </main>
  );
}
```

Never put `'use cache'` on per-user or permission data. See [nextjs-caching.md](../nextjs-caching.md#per-user-and-safety-data).

## Checklist

- [ ] Project inspected: version, `app/` vs `src/app/`, aliases, auth and DB helpers, `cacheComponents`
- [ ] `params` and `searchParams` typed as Promises and awaited (or read with `use()` in Client Components)
- [ ] `metadata` or `generateMetadata`, sharing the loader through React `cache()`
- [ ] `generateStaticParams` only for public, published data
- [ ] `loading.tsx`, `error.tsx` (`'use client'`), and `not-found.tsx` where a lookup can miss
- [ ] URL input validated; `notFound()` for unknown values
- [ ] Per-user pages call `auth()`, redirect when signed out, and scope queries to the session user
- [ ] Independent requests started in parallel; slow regions wrapped in `<Suspense>`
- [ ] Page stays a Server Component; `'use client'` only on interactive leaves
- [ ] Stored HTML sanitized before `dangerouslySetInnerHTML`
- [ ] Every created file reported with its Server or Client boundary

## Related

- [nextjs-routing.md](../nextjs-routing.md): file conventions, dynamic segments, metadata
- [nextjs-data-fetching.md](../nextjs-data-fetching.md): parallel fetching, Suspense streaming, `use()`
- [nextjs-caching.md](../nextjs-caching.md): `'use cache'`, revalidation, ISR
- [component.md](component.md): Server vs Client Component decisions
