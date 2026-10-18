# Next.js Performance and SEO

Core Web Vitals, `next/image`, `next/font`, `next/script`, SEO metadata files, bundle analysis, and Server Component performance for Next.js 15.5 and 16. Load it when a Next.js app scores poorly in Lighthouse or field data, when adding images, fonts, third-party scripts, or Open Graph images, or when the client bundle grows.

## Contents

- [Quick Reference](#quick-reference)
- [Measuring](#measuring)
- [Images](#images)
- [Fonts](#fonts)
- [Third-Party Scripts](#third-party-scripts)
- [Metadata and SEO](#metadata-and-seo)
- [Bundle Size](#bundle-size)
- [Server Component Performance](#server-component-performance)
- [Checklist](#checklist)

## Quick Reference

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Slow LCP | Hero image lazy-loaded or discovered late, slow TTFB | Load the LCP image eagerly at high priority, cache or stream the page |
| High CLS | Images without dimensions, web fonts swapping, late banners | `width`/`height` or `fill` in a sized parent, `next/font`, reserved space |
| High INP | Long tasks from hydration or third-party scripts | Less client JS, `lazyOnload` scripts, `useTransition` for heavy updates |
| Large client bundle | Heavy libraries in Client Components | Move work to the server, `next/dynamic`, `optimizePackageImports` |
| Slow TTFB | Uncached data on every request, sequential awaits | `'use cache'`, parallel fetches, Suspense streaming |

Related: caching and Partial Prerendering in [nextjs-caching.md](nextjs-caching.md), streaming and parallel fetching in [nextjs-data-fetching.md](nextjs-data-fetching.md), React-level profiling and memoization in [performance.md](performance.md).

## Measuring

### Core Web Vitals

Google assesses each metric at the 75th percentile of real page loads.

| Metric | Measures | Good | Poor |
|--------|----------|------|------|
| LCP (Largest Contentful Paint) | Load speed of the main content | ≤ 2.5 s | > 4 s |
| INP (Interaction to Next Paint) | Responsiveness across all interactions | ≤ 200 ms | > 500 ms |
| CLS (Cumulative Layout Shift) | Visual stability | ≤ 0.1 | > 0.25 |

INP replaced FID (First Input Delay) as a Core Web Vital in March 2024. Do not optimize for or report FID. TTFB and FCP are diagnostic: they explain a bad LCP but are not Core Web Vitals.

### Field vs lab data

- **Field data** (real users): Chrome UX Report, the field panel in PageSpeed Insights, Search Console, or a custom `useReportWebVitals` pipeline. The pass/fail assessment uses field data.
- **Lab data** (one simulated load): Lighthouse in Chrome DevTools, PageSpeed Insights, Lighthouse CI. Use it to reproduce and verify fixes. Lab runs cannot measure INP; use Total Blocking Time as the proxy.
- Measure a production build (`next build && next start`), never `next dev`.
- Next.js 16 removed the `size` and `First Load JS` columns from `next build` output. Use Lighthouse, field data, or the [bundle analyzer](#bundle-size).

### Reporting from the App Router

`useReportWebVitals` from `next/web-vitals` reports TTFB, FCP, LCP, CLS, and INP. Put it in its own Client Component, render that once in the root layout's `<body>`, and keep the callback at module scope so a changing reference does not cause duplicate reports.

```tsx
// app/_components/web-vitals.tsx
'use client';

import { useReportWebVitals } from 'next/web-vitals';

type ReportCallback = Parameters<typeof useReportWebVitals>[0];

const report: ReportCallback = (metric) => {
  const body = JSON.stringify({
    name: metric.name, // 'LCP' | 'INP' | 'CLS' | 'FCP' | 'TTFB'
    value: metric.value,
    rating: metric.rating, // 'good' | 'needs-improvement' | 'poor'
    id: metric.id,
    path: window.location.pathname,
  });
  // sendBeacon survives page unload; fall back to a keepalive fetch
  if (!navigator.sendBeacon?.('/api/vitals', body)) {
    fetch('/api/vitals', { method: 'POST', body, keepalive: true });
  }
};

export function WebVitals() {
  useReportWebVitals(report);
  return null;
}
```

Aggregate by `name` and `path` and track the 75th percentile, not the mean. For component render cost, use the React DevTools Profiler (see [performance.md](performance.md#react-devtools-profiler)).

## Images

`next/image` resizes, converts to WebP (or AVIF if enabled), lazy-loads by default, and generates `srcset`. It prevents CLS only when the browser knows the size up front.

### Sizing to avoid CLS

```tsx
import Image from 'next/image';
import hero from './hero.jpg'; // static import: width, height, and blurDataURL are inferred

// 1. Static import: dimensions and blur placeholder come for free
<Image src={hero} alt="Mountain at sunrise" placeholder="blur" />

// 2. Remote or string src: pass intrinsic width and height (sets the aspect ratio)
<Image src={product.imageUrl} alt={product.name} width={800} height={600} />

// 3. Unknown size: fill a positioned parent that has its own dimensions
<div className="relative aspect-video">
  <Image src={post.cover} alt="" fill sizes="(max-width: 768px) 100vw, 50vw" className="object-cover" />
</div>
```

Set `sizes` on every `fill` image and every image made responsive with CSS. Without it the browser assumes `100vw` and downloads an image far wider than needed. With `sizes`, Next.js emits a full width-based `srcset`; a fixed-width image without it gets only `1x`/`2x` candidates. Example for a 3/2/1-column grid: `sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"`.

### The LCP image

Images are `loading="lazy"` by default, which delays a hero image. Mark only the image that is the LCP element:

```tsx
// Next.js 16: in most cases use loading="eager" or fetchPriority="high"
<Image src={hero} alt="..." fetchPriority="high" loading="eager" sizes="100vw" />

// Next.js 16: preload adds <link rel="preload"> to <head>, for images discovered late
<Image src={hero} alt="..." preload sizes="100vw" />

// Next.js 15.x: priority (deprecated in 16 in favor of preload)
<Image src={hero} alt="..." priority sizes="100vw" />
```

- Do not combine `preload` with `loading` or `fetchPriority`, and do not use `preload` when different images are the LCP element at different viewports.
- Never mark more than one or two images. Each high-priority image competes for bandwidth with the real LCP element.

### Configuration

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      new URL('https://cdn.example.com/uploads/**'),
      { protocol: 'https', hostname: '**.cloudinary.com', pathname: '/my-account/**', search: '' },
    ],
    formats: ['image/avif', 'image/webp'], // default is ['image/webp']
    qualities: [60, 75, 90], // 16 default: [75]
    localPatterns: [{ pathname: '/assets/**', search: '?v=1' }],
    minimumCacheTTL: 2678400, // 31 days; 16 default is 14400 (4 hours)
  },
};

export default nextConfig;
```

- Keep `remotePatterns` tight (protocol, hostname, pathname). Omitted fields act as `**`. `images.domains` is deprecated.
- AVIF is about 20% smaller than WebP but slower to encode on first request, and each format is cached separately.

Next.js 16 changed these image defaults (breaking):

| Setting | Before | 16 |
|---------|--------|----|
| `qualities` | Any quality allowed | `[75]`. Other `quality` props are coerced to the closest allowed value |
| `minimumCacheTTL` | 60 s | 14400 s (4 hours) |
| `imageSizes` | Included `16` | `16` removed |
| `maximumRedirects` | Unlimited | 3 |
| Local `src` with a query string | Allowed | Requires a matching `localPatterns[].search` |
| Local IP upstreams | Allowed | Blocked unless `dangerouslyAllowLocalIP: true` (private networks only) |

`next/legacy/image` is deprecated in 16; migrate to `next/image`.

### Placeholders

- `placeholder="blur"` works automatically for static imports. For remote images, pass a tiny (10 px or less) base64 `blurDataURL` generated at upload time.
- `placeholder="data:image/..."` accepts any data URL, such as a solid color or shimmer SVG.
- A placeholder improves perceived speed. It does not fix CLS; dimensions do.

## Fonts

`next/font` downloads fonts at build time and self-hosts them with the app's static assets, so the browser makes no request to Google. It generates a size-adjusted fallback font (`adjustFontFallback`, on by default) so the swap to the web font causes almost no layout shift.

```ts
// app/fonts.ts: define each font once and import it where needed
import { Inter, Roboto_Mono } from 'next/font/google';
import localFont from 'next/font/local';

export const inter = Inter({
  subsets: ['latin'], // preloaded subsets; omitting this while preload is true warns
  display: 'swap', // default
  variable: '--font-inter',
});

// Variable font: no weight needed. Non-variable fonts require weight, e.g. ['400', '700']
export const mono = Roboto_Mono({ subsets: ['latin'], variable: '--font-roboto-mono' });

export const brand = localFont({
  src: [
    { path: './fonts/Brand-Regular.woff2', weight: '400', style: 'normal' },
    { path: './fonts/Brand-Bold.woff2', weight: '700', style: 'normal' },
  ],
  variable: '--font-brand',
  fallback: ['system-ui', 'arial'],
});
```

Apply the variables on `<html>`: ``className={`${inter.variable} ${mono.variable} ${brand.variable}`}``, then map them in CSS:

```css
/* app/globals.css: Tailwind CSS v4 */
@import 'tailwindcss';

@theme inline {
  --font-sans: var(--font-inter);
  --font-mono: var(--font-roboto-mono); /* never reuse a theme name: var(--font-mono) would be circular */
  --font-display: var(--font-brand);
}
```

- Prefer variable fonts: one file covers every weight. Request extra axes (`axes: ['slnt']`) only when used.
- Call each loader once in a shared module. Every call creates a separate hosted instance.
- A font is preloaded only on routes whose page or layout uses it; one used in the root layout preloads everywhere. Set `preload: false` for rarely used fonts.
- Use `display: 'optional'` for non-critical display fonts to skip the swap on slow connections.
- Limit families and weights. Each is another download on the critical path.
- Import multi-word Google fonts with underscores: `Roboto_Mono`, `Source_Sans_3`.

## Third-Party Scripts

`next/script` controls when external JavaScript loads. Third-party scripts are a common cause of poor INP.

| Strategy | When it loads | Use for |
|----------|---------------|---------|
| `beforeInteractive` | Injected into `<head>` from the server, before Next.js code | Bot detection, consent managers. Root layout only |
| `afterInteractive` (default) | After some hydration | Tag managers, analytics |
| `lazyOnload` | Browser idle time, after all resources | Chat widgets, social embeds |
| `worker` | In a web worker | Experimental, Pages Router only. Does not work in the App Router |

```tsx
// app/layout.tsx
import Script from 'next/script';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Script src="https://consent.example.com/cmp.js" strategy="beforeInteractive" />
        <Script src="https://chat.example.com/widget.js" strategy="lazyOnload" />
      </body>
    </html>
  );
}
```

- `onLoad`, `onReady`, and `onError` work only in Client Components. `onLoad` and `onError` cannot be combined with `beforeInteractive`.
- Use `onReady` (not `onLoad`) for SDKs that must re-initialize on every mount, such as a map after client navigation.
- Give inline scripts an `id` so Next.js can deduplicate them.
- Load a script in the page or layout that needs it, not the root layout, so other routes do not pay for it.

### @next/third-parties

`@next/third-parties` (experimental) wraps common Google embeds with performance defaults: scripts load after hydration and embeds lazy-load.

Import from `@next/third-parties/google`: `<GoogleTagManager gtmId="GTM-..." />` (place it in the root layout for all routes), `GoogleAnalytics` (`gaId`), `GoogleMapsEmbed`, `YouTubeEmbed` (built on `lite-youtube-embed`), and the client helpers `sendGTMEvent` and `sendGAEvent`. If GTM is already present, configure Analytics inside GTM instead of adding both.

## Metadata and SEO

The `metadata` export, `generateMetadata`, and `title.template` are covered in [nextjs-routing.md](nextjs-routing.md#metadata). This section covers what affects search and sharing.

### metadataBase, canonical URLs, and indexing

```tsx
// app/layout.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'https://example.com'),
  title: { default: 'Acme', template: '%s | Acme' },
  description: 'Tools for teams that ship.',
  alternates: { canonical: '/' },
  openGraph: { type: 'website', siteName: 'Acme', locale: 'en_US' },
  twitter: { card: 'summary_large_image' },
};
```

```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug); // wrapped in React cache() so the page reuses the result
  if (!post) return { title: 'Not found', robots: { index: false } };
  return {
    title: post.title,
    description: post.excerpt,
    alternates: { canonical: `/blog/${slug}` },
    openGraph: { type: 'article', publishedTime: post.publishedAt },
  };
}
```

- Set `metadataBase` once in the root layout; relative OG image and canonical URLs resolve against it.
- Give every indexable page a unique title, description, and canonical URL. Set `robots: { index: false }` on search results, drafts, and empty states.
- Keep `generateMetadata` fast and share its data with the page through React `cache()` or a `'use cache'` function.

### Open Graph images

Add `opengraph-image.tsx` (or a static `opengraph-image.png` plus `opengraph-image.alt.txt`) to a segment; `twitter-image` works the same way. Generated images are prerendered and cached unless they use request-time APIs or uncached data. In 16, `params` (and `id` from `generateImageMetadata`) are Promises.

```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from 'next/og';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

export const alt = 'Acme blog post';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

// Read static assets once at module scope
const interBold = await readFile(join(process.cwd(), 'assets/Inter-Bold.ttf'));

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);

  return new ImageResponse(
    (
      // Layout supports flexbox, not grid
      <div style={{ display: 'flex', width: '100%', height: '100%', alignItems: 'center', padding: 80, background: '#0b0b0f', color: 'white', fontSize: 64, fontFamily: 'Inter' }}>
        {post?.title ?? 'Acme'}
      </div>
    ),
    { ...size, fonts: [{ name: 'Inter', data: interBold, weight: 700, style: 'normal' }] },
  );
}
```

Static OG images must stay under 8 MB (Twitter images under 5 MB) or the build fails.

### sitemap.ts and robots.ts

Both are special Route Handlers, cached by default unless they use request-time APIs.

```ts
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = 'https://example.com';
  const posts = await getPublishedPosts();
  return [
    { url: base, lastModified: new Date(), changeFrequency: 'weekly', priority: 1 },
    ...posts.map((p) => ({ url: `${base}/blog/${p.slug}`, lastModified: p.updatedAt })),
  ];
}
```

`app/robots.ts` returns `MetadataRoute.Robots`: `{ rules: { userAgent: '*', allow: '/', disallow: ['/api/', '/admin/'] }, sitemap: 'https://example.com/sitemap.xml' }`.

Above 50,000 URLs, split with `generateSitemaps()`; in 16 the `sitemap` function receives `id` as `Promise<string>`. Sitemap entries also accept `images`, `videos`, and `alternates.languages`.

### JSON-LD

Render structured data with a plain `<script>` (not `next/script`; it is data, not code) in the page or layout. Escape `<` so user content cannot close the tag. Type it with `schema-dts` and validate with Google's Rich Results Test.

```tsx
import type { Product, WithContext } from 'schema-dts';

const jsonLd: WithContext<Product> = {
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: product.name,
  image: product.imageUrl,
  description: product.summary,
};

<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, '\\u003c') }}
/>
```

## Bundle Size

### Analyze

Next.js 16 builds with Turbopack by default.

```bash
npx next analyze           # Turbopack analyzer (16.1+): treemap, import chains, client and server
npx next analyze --output  # write to .next/diagnostics/analyze for before/after diffs
```

For Webpack builds (`next build --webpack`, or Next.js 15) use `@next/bundle-analyzer`:

```ts
// next.config.ts
import type { NextConfig } from 'next';
import bundleAnalyzer from '@next/bundle-analyzer';

const withBundleAnalyzer = bundleAnalyzer({ enabled: process.env.ANALYZE === 'true' });
const nextConfig: NextConfig = {};

export default withBundleAnalyzer(nextConfig); // run: ANALYZE=true npx next build --webpack
```

### Reduce client JavaScript

1. **Move work to the server.** Libraries that only turn data into markup (syntax highlighting, Markdown, date formatting, static charts) belong in Server Components, where they never ship to the browser.
2. **Push `'use client'` to the leaves.** A `'use client'` file pulls every import into the client bundle. Keep pages and layouts on the server and mark only the interactive widget.
3. **Lazy-load below-the-fold or on-demand UI** with `next/dynamic`, or `await import('lib')` inside an event handler.
4. **Trim barrel imports** with `optimizePackageImports`.

```tsx
// app/dashboard/chart-panel.tsx
'use client';

import dynamic from 'next/dynamic';

// ssr: false is only allowed in a Client Component; it is an error in a Server Component
const RevenueChart = dynamic(() => import('./revenue-chart'), {
  ssr: false,
  loading: () => <div className="h-64 animate-pulse rounded bg-muted" />,
});

// Named export: resolve the module to the component
const Editor = dynamic(() => import('./editor').then((m) => m.Editor));

export function ChartPanel({ editing }: { editing: boolean }) {
  return editing ? <Editor /> : <RevenueChart />;
}
```

Server Components are code-split automatically; `next/dynamic` on a Server Component only lazy-loads its Client Component children. For `React.lazy` and route chunk preloading see [performance.md](performance.md#code-splitting).

```ts
// next.config.ts
const nextConfig: NextConfig = {
  experimental: {
    optimizePackageImports: ['@acme/icons', 'my-internal-ui'], // barrel-heavy packages not optimized by default
  },
};
```

`lucide-react`, `date-fns`, `lodash-es`, `@mui/material`, `@mui/icons-material`, `@heroicons/react/*`, `@headlessui/react`, `react-icons/*`, `recharts`, `rxjs`, `antd`, and others are already optimized; do not list them.

### Keep server code out of the client

```ts
// lib/db.ts
import 'server-only'; // build error if a Client Component imports this module

export async function getOrders(userId: string) {
  return db.orders.findMany({ where: { userId } });
}
```

Use `import 'client-only'` for the reverse (modules touching `window`). Add `serverExternalPackages: ['package-name']` in `next.config.ts` for server dependencies that must not be bundled, such as native modules.

## Server Component Performance

### Fetch on the server, in parallel

A Client Component that fetches in `useEffect` waits for the JS download, hydration, and then the request: a client waterfall. Fetch in Server Components instead and start independent requests together.

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';

export default async function Dashboard() {
  // Both requests start together: one round trip instead of two
  const [user, stats] = await Promise.all([getUser(), getStats()]);

  return (
    <>
      <Header user={user} stats={stats} />
      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity userId={user.id} />
      </Suspense>
    </>
  );
}
```

Parallel vs sequential fetching and the preload pattern are in [nextjs-data-fetching.md](nextjs-data-fetching.md#parallel-and-sequential-fetching); `loading.tsx` and nested boundaries in [nextjs-data-fetching.md](nextjs-data-fetching.md#streaming-with-suspense); starting a fetch on the server and reading it in a Client Component in [nextjs-data-fetching.md](nextjs-data-fetching.md#passing-promises-to-client-components).

### Pass minimal props across the boundary

Everything a Server Component passes to a Client Component is serialized into the RSC payload and the HTML. Pass only what the client needs.

```tsx
// Bad: ships the whole product record (long descriptions, internal fields) to the browser
<AddToCartButton product={product} />

// Good: only the fields the button uses
<AddToCartButton productId={product.id} price={product.price} inStock={product.stock > 0} />
```

- Render static content (descriptions, reviews, rich text) in Server Components and pass it to Client Components as `children` rather than as data.
- Never pass secrets or full database rows. Shape a DTO on the server.
- For large interactive lists, paginate on the server and virtualize on the client (see [performance-virtualization.md](performance-virtualization.md)).

### Partial Prerendering with Cache Components

In Next.js 16, Partial Prerendering is enabled through `cacheComponents: true`; the `experimental.ppr` flag and `experimental_ppr` segment export are removed. The static shell and `'use cache'` content are served immediately, and request-time parts stream into `<Suspense>` holes, so personalized pages still get a fast TTFB and LCP. Setup, `cacheLife`, `cacheTag`, and migration from segment config are in [nextjs-caching.md](nextjs-caching.md#cache-components-and-use-cache).

```tsx
// app/product/[id]/page.tsx (cacheComponents: true)
import { Suspense } from 'react';

export default async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return (
    <>
      <ProductDetails id={id} /> {/* uses 'use cache': part of the static shell */}
      <Suspense fallback={<PriceSkeleton />}>
        <PersonalizedPrice id={id} /> {/* reads cookies(): streams at request time */}
      </Suspense>
    </>
  );
}
```

Keep the LCP element (hero image, headline) in the static shell, never behind a Suspense boundary that waits on slow data.

Next.js 16 also ships stable React Compiler support (`reactCompiler: true` plus `babel-plugin-react-compiler`, off by default). It memoizes automatically, which can lower INP, at the cost of slower builds. Manual memoization is in [performance.md](performance.md#memoization).

## Checklist

**Measure**
- [ ] Field data (CrUX, Search Console, or `useReportWebVitals`) collected per route at p75
- [ ] Lighthouse run against a production build with the mobile profile
- [ ] LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1

**Images and fonts**
- [ ] Every `next/image` has `width`/`height`, a static import, or `fill` inside a sized parent
- [ ] `sizes` set on every `fill` or CSS-responsive image
- [ ] Only the LCP image is eager/high priority (`fetchPriority`/`preload` in 16, `priority` in 15)
- [ ] `remotePatterns` restricted by hostname and pathname; custom `quality` values listed in `images.qualities`
- [ ] All fonts through `next/font`, defined once, variable where available, `subsets` set, no fonts.googleapis.com links

**Scripts**
- [ ] Analytics `afterInteractive`, widgets `lazyOnload`, `beforeInteractive` only for consent or bot detection
- [ ] Third-party scripts scoped to the routes that need them

**SEO**
- [ ] `metadataBase` in the root layout; unique title, description, and canonical per page
- [ ] `opengraph-image` on shareable routes; `sitemap.ts` and `robots.ts` at the app root
- [ ] JSON-LD escaped with `.replace(/</g, '\\u003c')`; non-indexable pages set `robots: { index: false }`

**Bundle and server**
- [ ] Analyzed with `next analyze` (Turbopack) or `@next/bundle-analyzer` (Webpack)
- [ ] `'use client'` only on interactive leaves; data-to-markup libraries stay on the server
- [ ] Heavy on-demand UI behind `next/dynamic` or `import()`; server-only modules import `server-only`
- [ ] Independent fetches run in parallel; slow data behind `<Suspense>`; minimal props to Client Components
- [ ] Cacheable data uses `'use cache'` with `cacheComponents` (see [nextjs-caching.md](nextjs-caching.md))
