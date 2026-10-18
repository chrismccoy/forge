# Performance Rules Checklist

An impact-ranked checklist of performance rules for React 19 and Next.js 15.5/16. Load it when reviewing code for speed, planning an optimization pass, or writing data-fetching and bundle-sensitive code.

**Measure first.** Profile the slow interaction or page (React DevTools Profiler, Web Vitals, a bundle analyzer, server timing logs) before applying any rule here. Work down the list from the top: one removed network waterfall usually beats every re-render fix combined. Re-measure after each change and revert what does not help. For the profiling workflow itself, see [performance.md](performance.md#measuring-performance).

## Contents

- [How to Use This List](#how-to-use-this-list)
- [1. Eliminate Waterfalls (Critical)](#1-eliminate-waterfalls-critical)
- [2. Reduce Bundle Size (Critical)](#2-reduce-bundle-size-critical)
- [3. Server-Side Work (High)](#3-server-side-work-high)
- [4. Client Data Fetching (Medium-High)](#4-client-data-fetching-medium-high)
- [5. Re-renders (Medium)](#5-re-renders-medium)
- [6. Rendering (Medium)](#6-rendering-medium)
- [7. JavaScript Micro-Optimizations (Low)](#7-javascript-micro-optimizations-low)
- [Review Checklist](#review-checklist)

## How to Use This List

| Rank | Category | Typical win | Where it bites |
|------|----------|-------------|----------------|
| 1 | Waterfalls | Seconds; each serial `await` adds a full round trip | Server Components, loaders, Route Handlers, Server Actions |
| 2 | Bundle size | Hundreds of ms of TTI/LCP, faster dev boot | Client Components, icon and UI libraries, editors, charts |
| 3 | Server-side work | Lower TTFB, smaller HTML/RSC payload | RSC props, repeated DB calls, logging in the response path |
| 4 | Client data fetching | Fewer duplicate requests | `useEffect` + `fetch` |
| 5 | Re-renders | Smoother typing, scrolling, INP | State placement, subscriptions, global listeners, effects |
| 6 | Rendering | Faster paint for long or hidden content | Long lists, tabs, theme flashes |
| 7 | JS micro-optimizations | Matters only in hot loops over large data | Lookups, sorting, regex |

Each rule below states what to do, why, and its impact. Skip a rule when the profile does not point at it.

## 1. Eliminate Waterfalls (Critical)

### Run independent work in parallel

**What:** Start independent async calls together with `Promise.all` (or `Promise.allSettled` when partial failure is acceptable).
**Why:** Three sequential awaits cost three round trips; parallel calls cost the slowest one.
**Impact:** Critical.

```ts
// Bad: three round trips
const user = await getUser(id);
const orders = await getOrders(id);
const prefs = await getPrefs(id);

// Good: one round trip
const [user, orders, prefs] = await Promise.all([getUser(id), getOrders(id), getPrefs(id)]);
```

Full Server Component examples: [nextjs-data-fetching.md](nextjs-data-fetching.md) (Parallel and Sequential Fetching).

### Start promises early, await late

**What:** When only part of the work depends on an earlier result, kick off the independent promises first and await them where they are needed.
**Why:** `Promise.all` alone still waits for the dependency before starting the dependent call, while unrelated work sits idle.
**Impact:** Critical in Route Handlers and Server Actions.

```ts
// app/api/dashboard/route.ts
export async function GET() {
  const sessionPromise = getSession();   // starts now
  const configPromise = getAppConfig();  // starts now, does not need the session
  configPromise.catch(() => {});          // the 401 path never awaits it; avoid an unhandled rejection

  const session = await sessionPromise;
  if (!session) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  // getStats needs the user id; config is already in flight
  const [config, stats] = await Promise.all([configPromise, getStats(session.userId)]);
  return Response.json({ config, stats });
}
```

Authorization still runs before any user data leaves the handler. A started-but-unused promise is fine as long as it cannot reject unhandled; attach `.catch` or await it on every path.

When a call needs one earlier result but the rest do not, chain it onto that promise instead of awaiting first. Each call then starts as soon as its own input is ready:

```ts
const userPromise = getUser(id);
const profilePromise = userPromise.then((user) => getProfile(user.profileId));
const [user, config, profile] = await Promise.all([userPromise, getConfig(), profilePromise]);
```

For larger dependency graphs, a helper such as `better-all` resolves named tasks in dependency order. Plain chaining covers most cases without a dependency.

### Defer `await` into the branch that uses it

**What:** Check cheap conditions (flags, early returns, not-found) before awaiting expensive data that only one branch needs.
**Why:** An `await` at the top blocks every path, including those that return early.
**Impact:** High when the early-return path is common.

```ts
// Bad: always waits for permissions, even for a missing resource
const perms = await getPermissions(userId);
const doc = await getDoc(docId);
if (!doc) return { error: 'Not found' };

// Good: only fetch permissions once the doc exists
const doc = await getDoc(docId);
if (!doc) return { error: 'Not found' };
const perms = await getPermissions(userId);
```

Do not reorder an authorization check after a write or after returning data. Deferring applies to reads that gate nothing.

### Split the tree so siblings fetch in parallel

**What:** Move each `await` into the async Server Component that needs the data instead of awaiting at the page level.
**Why:** A parent that awaits before returning JSX blocks all children's fetches; sibling async components start together.
**Impact:** Critical for pages with several data sources.

```tsx
// Bad: Sidebar's fetch starts only after the header data arrives
export default async function Page() {
  const header = await getHeader();
  return (<><Header data={header} /><Sidebar /></>);
}

// Good: both components fetch at the same time
export default function Page() {
  return (<><Header /><Sidebar /></>);
}
async function Header() { const data = await getHeader(); return <header>{data.title}</header>; }
async function Sidebar() { const items = await getNav(); return <nav>{/* items */}</nav>; }
```

### Stream with Suspense boundaries

**What:** Wrap slow async components in `<Suspense fallback={...}>` so the shell renders and the slow part streams in.
**Why:** Without a boundary, the whole route waits for its slowest query.
**Impact:** High for TTFB and first paint.

Keep above-the-fold, SEO-critical, or layout-defining data outside the boundary, and give the fallback the same dimensions as the content to avoid layout shift. To share one request between several client children, create the promise in the Server Component and pass it down to `use()`. Patterns: [nextjs-data-fetching.md](nextjs-data-fetching.md) (Streaming with Suspense, Passing Promises to Client Components).

## 2. Reduce Bundle Size (Critical)

### Avoid barrel imports of large libraries

**What:** Import from a package's per-module path, or let the framework rewrite barrel imports.
**Why:** An `index` that re-exports thousands of modules makes the bundler and the dev server process all of them, slowing builds, HMR, and cold starts. Tree-shaking does not help when the package is external or has side effects.
**Impact:** Critical for icon sets and component libraries.

Next.js config: [nextjs-performance.md](nextjs-performance.md#reduce-client-javascript).

`optimizePackageImports` is still under `experimental` in Next.js 16. Common libraries (`lucide-react`, `date-fns`, `lodash-es`, `@mui/material`, `@mui/icons-material`, `react-icons/*`, `recharts`, `rxjs`, and others) are optimized by default; check the Next.js docs list before adding them. Outside Next.js, import per-module paths (`import Button from '@mui/material/Button'`) and avoid internal barrel files in application code for large folders.

### Load heavy components on demand

**What:** Split editors, charts, maps, and rich-text widgets out of the initial chunk with `React.lazy` or `next/dynamic`.
**Why:** Code that is not needed for the first paint delays hydration and interaction.
**Impact:** Critical for TTI and LCP.

```tsx
'use client';
import dynamic from 'next/dynamic';

// ssr: false is only allowed inside a Client Component
const CodeEditor = dynamic(() => import('./code-editor').then((m) => m.CodeEditor), {
  ssr: false,
  loading: () => <p role="status">Loading editor…</p>,
});
```

`React.lazy` patterns and route-level splitting: [performance.md](performance.md#code-splitting).

### Load modules only when a feature is used

**What:** Import large data or modules inside the event or effect that activates the feature.
**Why:** A feature most users never open should not cost every user its download.
**Impact:** High.

```tsx
'use client';
async function exportPdf(report: Report) {
  const { renderPdf } = await import('@/lib/pdf'); // fetched on first click only
  await renderPdf(report);
}
```

### Defer non-critical third parties

**What:** Load analytics, chat widgets, and session replay after hydration.
**Why:** They compete with application code for the main thread during startup but are not needed for the first interaction.
**Impact:** Medium.

```tsx
// app/layout.tsx (Server Component)
import Script from 'next/script';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Script src="https://analytics.example.com/script.js" strategy="lazyOnload" />
      </body>
    </html>
  );
}
```

For a React component from an analytics package, wrap it in a small `'use client'` file that uses `next/dynamic` with `ssr: false`, and render that wrapper from the layout.

### Preload on intent

**What:** Start the chunk download on `pointerenter` or `focus` of the control that opens it.
**Why:** Hover-to-click time (often 100–300 ms) hides most of the download.
**Impact:** Medium for perceived latency.

Reuse the same loader for `lazy()` and the preload so the bundler caches one module. Example: [performance.md](performance.md#preloading-a-route-chunk-on-hover). Bind preloading to `onFocus` as well as hover so keyboard users benefit.

## 3. Server-Side Work (High)

### Deduplicate per request with React `cache()`

**What:** Wrap server data loaders (current user, a record by id) in `cache()` so repeated calls in one render share a result.
**Why:** Layouts, pages, `generateMetadata`, and nested components often ask for the same data.
**Impact:** Medium to high.

`cache()` lives for one server request only and works in Server Components. Pass arguments by primitive value; object arguments compare by reference and miss. Details: [nextjs-data-fetching.md](nextjs-data-fetching.md) (Deduplicating with React cache) and [nextjs-caching.md](nextjs-caching.md#request-memoization-and-react-cache).

### Cache across requests, carefully

**What:** For data read by many requests within seconds (feature flags, catalog lookups), use the framework cache (`'use cache'` with `cacheLife`/`cacheTag` in Next.js 16 with `cacheComponents: true`; `unstable_cache` on 15) or a bounded in-memory LRU.
**Why:** `cache()` resets on every request; a short cross-request cache avoids repeated identical queries.
**Impact:** High for read-heavy endpoints.

```ts
// lib/flags.ts
import 'server-only';
import { LRUCache } from 'lru-cache';

const flagCache = new LRUCache<string, FeatureFlags>({ max: 500, ttl: 30_000 });

export async function getFlags(tenantId: string): Promise<FeatureFlags> {
  const hit = flagCache.get(tenantId);
  if (hit) return hit;
  const flags = await db.flags.findForTenant(tenantId);
  flagCache.set(tenantId, flags);
  return flags;
}
```

Rules for cross-request caches:

- Never cache per-user or permission data under a key that another user can hit. Include the user or tenant id in the key, or do not cache it.
- Never use a cached value to decide authorization, billing, or plan limits. Re-read the source of truth.
- An in-memory LRU is per process. In serverless or multi-instance deployments, each instance has its own copy; use a shared store (Redis) or the framework's remote cache handler when consistency matters.
- Invalidate on write, or keep the TTL short enough that stale data is acceptable.

See [nextjs-caching.md](nextjs-caching.md#per-user-and-safety-data).

### Minimize what crosses the Server/Client boundary

**What:** Pass Client Components only the fields they render.
**Why:** Every prop passed from a Server Component to a Client Component is serialized into the HTML and the RSC payload. Passing a full database row also risks leaking private fields.
**Impact:** High for page weight; also a security issue.

```tsx
// Bad: serializes the entire user record (including email, hashes, flags)
return <ProfileCard user={user} />;

// Good: serialize only what the client renders
return <ProfileCard name={user.name} avatarUrl={user.avatarUrl} />;
```

Map rows to explicit DTOs in a `server-only` data layer so new columns are not exposed by default.

### Pass a value once, derive copies on the client

**What:** Pass a list to a Client Component once, and sort, filter, or slice it there. Do not pass both the original and a derived copy as separate props.
**Why:** The RSC payload reuses a value only when the same reference appears twice. `items.toSorted()`, `items.filter()`, and `[...items]` create new arrays, so the data is serialized again.
**Impact:** Low; higher for large arrays of primitives, which are copied in full. Arrays of objects repeat only the array structure.

```tsx
// Bad: the list is serialized twice
<ProductList items={products} featured={products.filter((p) => p.featured)} />

// Good: serialize once; derive in the Client Component
<ProductList items={products} />
```

Derive on the server instead when the derivation is expensive, or when the client needs only the derived subset; then pass only that subset.

### Move non-critical work out of the response with `after()`

**What:** Schedule logging, analytics, audit writes, and cache warming with `after()` from `next/server`.
**Why:** The response does not wait for work the user does not need to see.
**Impact:** Medium for TTFB.

```ts
// app/api/orders/route.ts
import { after } from 'next/server';

export async function POST(request: Request) {
  const order = await createOrder(request); // auth + Zod validation inside
  const userAgent = request.headers.get('user-agent') ?? 'unknown';

  after(async () => {
    await trackEvent('order_created', { orderId: order.id, userAgent });
  });

  return Response.json(order, { status: 201 });
}
```

Notes: `after` is stable since Next.js 15.1. It works in Server Components, Server Functions, Route Handlers, and `proxy.ts`. It runs even when the response errors, redirects, or calls `notFound()`. In Server Components, read `cookies()`/`headers()` before calling `after` and pass the values in; calling them inside the callback throws. The callback is bounded by the route's max duration, and static export does not support it. Do not move work the user must see succeed (payment capture, the write itself) into `after`.

## 4. Client Data Fetching (Medium-High)

### Deduplicate requests with a server-state library

**What:** Fetch client-side data through TanStack Query or SWR instead of `useEffect` + `fetch`.
**Why:** Every mounted component with its own effect sends its own request, with no caching, race handling, or revalidation.
**Impact:** Medium-high.

```tsx
// Bad: each instance fetches; no cancellation or cache
useEffect(() => { fetch('/api/users').then((r) => r.json()).then(setUsers); }, []);

// Good: one request shared by every component using this key
const { data: users } = useQuery({ queryKey: ['users'], queryFn: fetchUsers });
```

Setup and mutations: [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md) and [state-management.md](state-management.md) (SWR). In Server Component frameworks, prefer fetching on the server first.

## 5. Re-renders (Medium)

React Compiler handles most memoization automatically. Without it, reach for structure first (colocate state, pass `children`) and add `memo`/`useMemo`/`useCallback` only at a measured hotspot or a stable-prop boundary. Never memoize by default. See [performance.md](performance.md#memoization) and [hooks-performance-and-react-19.md](hooks-performance-and-react-19.md).

### Derive state during render

**What:** Compute values from props and state in the render body instead of syncing them with `useEffect` + `setState`.
**Why:** The effect version renders twice and can show a stale frame.
**Impact:** Medium.

```tsx
// Bad
const [fullName, setFullName] = useState('');
useEffect(() => setFullName(`${first} ${last}`), [first, last]);

// Good
const fullName = `${first} ${last}`;
```

### Subscribe to the derived value, not the raw stream

**What:** Subscribe to a boolean or bucketed value (e.g. `useMediaQuery('(max-width: 767px)')`) instead of a continuous one (window width, scroll position) when only the threshold matters.
**Why:** A component reading `window.innerWidth` re-renders on every pixel; one reading a media query re-renders only when it flips.
**Impact:** Medium.

Store selectors follow the same rule: select `state.cart.items.length > 0`, not `state.cart`.

### Share and mark global event listeners

**What:** Register one listener per event type for all subscribers, and pass `{ passive: true }` to `touchstart`, `touchmove`, and `wheel` handlers that never call `preventDefault()`.
**Why:** N component instances each adding a `window` listener do N times the work per event. Non-passive touch and wheel listeners make the browser wait for the handler before scrolling. `scroll` itself cannot be cancelled, so the flag is harmless there but changes nothing.
**Impact:** Low to medium.

The hooks in [hooks-custom-library.md](hooks-custom-library.md) (media query, window size, scroll position, key press) are SSR-safe, but each mounted instance adds its own listener. That is fine for a handful of components. When many instances listen to the same event, share one `window` listener through a module-level subscriber set and read it with `useSyncExternalStore`:

```ts
// lib/scroll-store.ts
const subscribers = new Set<() => void>();
const onScroll = () => subscribers.forEach((notify) => notify());

export function subscribe(notify: () => void) {
  if (subscribers.size === 0) window.addEventListener('scroll', onScroll, { passive: true });
  subscribers.add(notify);
  return () => {
    subscribers.delete(notify);
    if (subscribers.size === 0) window.removeEventListener('scroll', onScroll);
  };
}
export const getSnapshot = () => window.scrollY;
export const getServerSnapshot = () => 0;

// in a component: useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot)
```

A keyboard-shortcut registry follows the same shape: one `keydown` listener dispatching to a `Map` of shortcut handlers. Omit `{ passive: true }` only for a handler that calls `preventDefault()`, such as custom swipe or pinch-zoom handling.

### Use functional `setState`

**What:** Write `setItems((prev) => [...prev, item])` when the next value depends on the previous one.
**Why:** It avoids stale closures and lets callbacks drop the state dependency.
**Impact:** Medium; mainly correctness.

### Initialize expensive state lazily

**What:** Pass a function to `useState` for expensive initial values: `useState(() => buildIndex(items))`.
**Why:** `useState(buildIndex(items))` runs `buildIndex` on every render and throws the result away.
**Impact:** Medium when the initializer is costly.

Do not read `localStorage` or `window` in a `useState` initializer in server-rendered components; that causes a hydration mismatch. Use `useSyncExternalStore` instead.

### Mark non-urgent updates as transitions

**What:** Wrap updates that trigger heavy re-renders (filtering a large list, switching tabs) in `startTransition`, or render a lagging copy with `useDeferredValue`.
**Why:** Urgent input (typing, clicking) stays responsive while React renders the expensive update in the background.
**Impact:** Medium for INP.

Keep controlled input values outside the transition. Details: [performance.md](performance.md#concurrent-features).

For async work, prefer `useTransition`'s `isPending` over a hand-managed `isLoading` state, which is easy to leave stuck on an early return or an error:

```tsx
const [isPending, startTransition] = useTransition();

function search(query: string) {
  startTransition(async () => {
    const data = await fetchResults(query);
    // State updates after an await need their own startTransition
    startTransition(() => setResults(data));
  });
}
```

Async transitions are not cancelled when a new one starts and can finish out of order. Ignore stale results (compare a request id or use an `AbortController`), or use a data library that handles this. An error thrown inside the transition goes to the nearest error boundary, so catch errors the UI should handle inline.

### Read volatile values where they are used

**What:** Read values that only an event handler needs (URL search params, storage) inside the handler instead of subscribing at render time.
**Why:** A `useSearchParams()` subscription re-renders the component on every query change even if render never uses it.
**Impact:** Low to medium.

```tsx
'use client';
function ShareButton({ postId }: { postId: string }) {
  function share() {
    const ref = new URLSearchParams(window.location.search).get('ref');
    void sharePost(postId, { ref });
  }
  return <button type="button" onClick={share}>Share</button>;
}
```

### Keep high-frequency values in refs

**What:** Store values that change at pointer, scroll, or animation-frame rate, and that render does not display, in `useRef`. Apply visual updates by writing to the DOM node through a ref.
**Why:** `setState` on every `pointermove` or `scroll` event re-renders the component dozens of times per second.
**Impact:** Medium for INP and animation smoothness.

```tsx
'use client';
import { useRef } from 'react';

function Spotlight() {
  const glowRef = useRef<HTMLDivElement>(null);

  function handlePointerMove(e: React.PointerEvent) {
    // No state update: write the style directly, relative to the container
    const box = e.currentTarget.getBoundingClientRect();
    glowRef.current?.style.setProperty(
      'transform',
      `translate(${e.clientX - box.left}px, ${e.clientY - box.top}px)`
    );
  }

  return (
    <div onPointerMove={handlePointerMove} className="relative h-96">
      <div ref={glowRef} className="pointer-events-none absolute size-32 rounded-full bg-white/10" />
    </div>
  );
}
```

Never read `ref.current` during render. Move a value into state only when render must show it, and throttle it (for example once per `requestAnimationFrame`).

### Initialize the app once, not per mount

**What:** Run app-wide setup (analytics init, SDK configuration, a one-time storage migration) in the client entry module or behind a module-level guard, not in a component's `useEffect(() => {}, [])`.
**Why:** Effects re-run whenever the component remounts, and React Strict Mode runs them twice in development.
**Impact:** Low; mainly correctness.

```tsx
'use client';
import { useEffect } from 'react';

let didInit = false;

export function AppInit() {
  useEffect(() => {
    if (didInit) return;
    didInit = true;
    initAnalytics();
    migrateStoredPrefs();
  }, []);
  return null;
}
```

Keep this client-only. On the server, module state is shared across all requests, so a server-side "once" flag leaks between users.

### Narrow effect dependencies

**What:** Depend on primitives (`user.id`) or a derived boolean (`isMobile`), not whole objects or continuous values.
**Why:** An effect keyed on `user` re-runs whenever any field or the object identity changes.
**Impact:** Low.

For an effect that must call the latest callback without resubscribing, use `useEffectEvent` (stable in React 19.2) and keep the Effect Event out of the dependency array.

### Memoize only measured hotspots

**What:** Without React Compiler, wrap a component in `memo` only when the Profiler shows it re-rendering with unchanged props and those renders are expensive; stabilize the props it receives.
**Why:** `memo` adds comparison cost, and new object or function props on every render defeat it.
**Impact:** Medium at a real hotspot; negative elsewhere.

A useful structural trick: move expensive work into a child component placed after an early return (`if (loading) return <Skeleton />`) so the work does not run at all while loading.

Watch default values for non-primitive props on a memoized component. `function Row({ onSelect = () => {}, tags = [] })` creates a new function and array on every render where the prop is omitted, so `memo` sees changed props every time. Hoist the defaults:

```tsx
const NOOP = () => {};
const NO_TAGS: string[] = [];

const Row = memo(function Row({ onSelect = NOOP, tags = NO_TAGS }: RowProps) {
  /* ... */
});
```

React Compiler handles this automatically.

## 6. Rendering (Medium)

### Keep hidden UI alive with `<Activity>`

**What:** Wrap tabs, drawers, or panels that toggle often in `<Activity mode={visible ? 'visible' : 'hidden'}>`.
**Why:** Hidden children keep their state and DOM (hidden with `display: none`), so switching back is instant and form input survives. A hidden boundary can also pre-render content the user is likely to open next.
**Impact:** Medium.

```tsx
import { Activity } from 'react';

function Tabs({ active }: { active: 'feed' | 'settings' }) {
  return (
    <>
      <Activity mode={active === 'feed' ? 'visible' : 'hidden'}><Feed /></Activity>
      <Activity mode={active === 'settings' ? 'visible' : 'hidden'}><Settings /></Activity>
    </>
  );
}
```

`<Activity>` is stable in React 19.2+. When hidden, React cleans up the children's Effects and re-creates them when shown; children still re-render at low priority. DOM side effects persist: pause `<video>`, `<audio>`, and `<iframe>` work in a cleanup (`useLayoutEffect`). Hidden pre-rendering fetches only data read through Suspense (such as `use(promise)`), not data fetched in Effects. On React 19.0/19.1, fall back to conditional rendering or CSS hiding.

### Skip off-screen layout with `content-visibility`

**What:** Apply `content-visibility: auto` with `contain-intrinsic-size` to repeated items in long, non-virtualized lists.
**Why:** The browser skips layout and paint for off-screen items, cutting initial render time for long feeds.
**Impact:** High for long lists that cannot be virtualized; no JS needed.

```css
.feed-item {
  content-visibility: auto;
  contain-intrinsic-size: auto 120px; /* estimated height; 'auto' remembers the real one */
}
```

For thousands of rows, virtualize instead: [performance-virtualization.md](performance-virtualization.md). Note that `content-visibility` items still exist in the DOM, so in-page find and screen readers work.

### Hoist static JSX and constants

**What:** Move JSX, objects, and arrays that never depend on props or state to module scope.
**Why:** They are not recreated each render, and a stable reference does not break memoized children.
**Impact:** Low. React Compiler hoists these automatically.

```tsx
const EMPTY_ICON = <svg aria-hidden="true" viewBox="0 0 24 24">{/* large static path */}</svg>;
const DEFAULT_FILTERS: Filters = { status: 'all', sort: 'newest' };
```

### Avoid hydration flicker for client-only preferences

**What:** For values only the browser knows (theme, sidebar collapsed), set them on `<html>` with a tiny inline script before hydration, or store them in a cookie the server can read.
**Why:** Reading storage in an effect paints the server default first and then flips; reading it during render causes a hydration mismatch.
**Impact:** Medium for perceived quality.

Patterns and the narrow use of `suppressHydrationWarning`: [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches).

### Render conditions explicitly

**What:** Use a boolean condition or a ternary when the left side of `&&` can be `0` or `NaN`.
**Why:** `{count && <Badge />}` renders `0` when `count` is zero.
**Impact:** Low; correctness.

```tsx
{count > 0 ? <Badge count={count} /> : null}
```

### Animate a wrapper, not the SVG

**What:** Apply CSS `transform`/`opacity` animations to a wrapping element rather than the `<svg>` itself, and strip excess path precision with SVGO.
**Why:** Some browsers do not GPU-accelerate transforms on SVG elements; overly precise path data bloats markup.
**Impact:** Low.

Optimize icons once at build time: `npx svgo --multipass --precision=1 icons/*.svg` (this overwrites the files in place; commit first, or pass `-o dist/icons`). The right precision depends on the `viewBox` size: one decimal is plenty for a `0 0 24 24` icon, while a small `viewBox` scaled up may need two or three. Compare the result visually.

## 7. JavaScript Micro-Optimizations (Low)

Apply these only inside a measured hot path (a loop over thousands of items, a function called during every render of a large list).

| Rule | Instead of | Do | Why |
|------|-----------|----|-----|
| Set/Map lookups | `ids.includes(x)` inside a loop | `const idSet = new Set(ids); idSet.has(x)` | O(1) per lookup instead of O(n) |
| Index by key | `users.find((u) => u.id === o.userId)` per order | `const byId = new Map(users.map((u) => [u.id, u]))` | Builds once, then O(1) |
| Immutable sort | `props.items.sort(...)` | `items.toSorted(...)` (or `[...items].sort(...)`) | `sort` mutates props/state; `toSorted` needs Node 20+ / modern browsers |
| Min/max | Sorting to take the first element | One pass loop | O(n) instead of O(n log n). Avoid `Math.min(...arr)` on large arrays: spreading passes every element as an argument, which can throw a `RangeError` (engine limits are often around 10⁵) |
| Early exit | Looping on after the answer is known | `return` on first match; compare lengths before deep comparison | Skips wasted work |
| Hoist RegExp | `new RegExp(...)` in render or a loop | Module-level literal; derive a dynamic one once per input (`useMemo` keyed on the input without React Compiler) | Avoids recompiling; beware shared `lastIndex` on `/g` regexes. Escape user input first: `RegExp.escape(q)` where supported, else `q.replace(/[.*+?^${}()\|[\]\\]/g, '\\$&')` |
| Combine passes | Several `.filter()` calls over the same array | One `for...of` that pushes into several buckets | One iteration |
| Avoid layout thrashing | Alternating layout reads (`offsetWidth`, `getBoundingClientRect()`, `getComputedStyle()`) with style writes in a loop | Do all reads first, then all writes; or toggle a class | Each read after a write forces a synchronous reflow. Consecutive writes alone are batched by the browser |
| Cache pure results | Calling an expensive pure function with repeated inputs | Module-level `Map` cache, bounded | Never cache user-specific values at module scope on the server |
| Cache storage reads | Calling `localStorage.getItem` or parsing `document.cookie` repeatedly in a hot path | Read once into a module `Map`, update it on write, clear it on the `storage` and `visibilitychange` events | Storage and cookie access is synchronous and comparatively slow. Client only |
| Hoist property reads | Reading `obj.a.b.c` on every iteration of a hot loop | `const c = obj.a.b.c` before the loop | Smallest win here; JIT compilers often do it already |

## Review Checklist

Work through the categories in order and stop where the profile stops pointing.

- [ ] Profile captured; the bottleneck is named (network, bundle, server time, render, or JS).
- [ ] No sequential `await` of independent requests; dependent requests start as early as possible; `await` sits in the branch that uses it.
- [ ] Slow sections sit behind `<Suspense>` with size-matched fallbacks.
- [ ] Large libraries imported per module or optimized; heavy widgets loaded on demand and preloaded on hover or focus.
- [ ] Third-party scripts load after hydration.
- [ ] Server loaders deduplicated with `cache()`; any cross-request cache is keyed safely and never used for authorization.
- [ ] Client Components receive only the fields they render.
- [ ] Logging and analytics run in `after()`, not in the response path.
- [ ] Client fetching goes through TanStack Query or SWR, not ad-hoc effects.
- [ ] No derived state stored via effects; state is colocated.
- [ ] Pointer, scroll, and animation values live in refs, not state; global listeners are shared and passive where possible.
- [ ] No non-primitive default props on memoized components; app-wide init runs once, not per mount.
- [ ] `memo`/`useMemo`/`useCallback` exist only at measured hotspots (or React Compiler is on).
- [ ] Heavy updates run in transitions or behind `useDeferredValue`; often-toggled panels use `<Activity>`.
- [ ] Long lists virtualized or use `content-visibility`.
- [ ] No `&&` conditions whose left side can be `0` or `NaN`.
- [ ] No hydration flicker for theme or other client-only preferences.
- [ ] Re-measured after each change; changes without a measured gain reverted.
