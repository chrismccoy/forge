# Next.js Proxy and Middleware

Request interception with `proxy.ts` (Next.js 16) and `middleware.ts` (Next.js 15 and earlier, or Edge on 16): matchers, redirects, rewrites, headers, cookies, coarse auth gating, geolocation, and bot detection. Load it when code must run before a route renders, or when migrating `middleware.ts` to `proxy.ts`.

## Contents

- [Quick Reference](#quick-reference)
- [proxy.ts on Next.js 16](#proxyts-on-nextjs-16)
- [middleware.ts on Next.js 15 and Edge](#middlewarets-on-nextjs-15-and-edge)
- [Matcher Configuration](#matcher-configuration)
- [Redirects](#redirects)
- [Rewrites](#rewrites)
- [Headers and CORS](#headers-and-cors)
- [Cookies](#cookies)
- [Authentication Gating](#authentication-gating)
- [Geolocation and IP](#geolocation-and-ip)
- [Bot Detection](#bot-detection)
- [Best Practices](#best-practices)

## Quick Reference

| Version | File | Export | Runtime |
|---------|------|--------|---------|
| Next.js 16+ | `proxy.ts` (project root, or `src/` next to `app/`) | `export function proxy` or default export | Node.js only |
| Next.js 16, Edge needed | `middleware.ts` (deprecated) | `export function middleware` | Edge |
| Next.js 15.5 | `middleware.ts` | `export function middleware` | Edge, or Node.js with `runtime: 'nodejs'` |
| Next.js ≤15.4 | `middleware.ts` | `export function middleware` | Edge |

| Response | Code | Effect |
|----------|------|--------|
| Continue | `NextResponse.next()` | Pass through to the route |
| Continue with request headers | `NextResponse.next({ request: { headers } })` | Route sees the modified headers |
| Redirect | `NextResponse.redirect(url)` | 307 by default. Browser URL changes |
| Rewrite | `NextResponse.rewrite(url)` | Serves another URL. Browser URL stays |
| Respond | `NextResponse.json(data, { status })` | Short-circuits the route |

| Request data | Access |
|--------------|--------|
| Path and query | `request.nextUrl.pathname`, `request.nextUrl.searchParams` |
| Cookies | `request.cookies.get('name')?.value` |
| Headers | `request.headers.get('name')` |
| Geo | `geolocation(request)` from `@vercel/functions`, or platform headers |
| IP | `ipAddress(request)` from `@vercel/functions`. `x-forwarded-for` only behind a trusted proxy |

`request.geo` and `request.ip` were removed in Next.js 15.

The proxy runs before every matched request, including prefetches. Keep it to redirects, rewrites, headers, and coarse gating. It is not authorization: re-check the session in every Server Action, Route Handler, and protected page.

## proxy.ts on Next.js 16

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';

export async function proxy(request: NextRequest) {
  const response = NextResponse.next();
  response.headers.set('x-request-path', request.nextUrl.pathname);
  return response;
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

- `proxy.ts` always runs on Node.js. The `runtime` config option is not allowed in it.
- Node APIs and database clients work, but every query adds latency to every matched request. Prefer a signed cookie or JWT check and keep matchers narrow.
- Export a single function, named `proxy` or as the default export.
- Pass data to the app through request headers, cookies, rewrites, or the URL. There is no shared memory with the route.
- Migrate with `npx @next/codemod@canary middleware-to-proxy .`. It renames the file and the function.
- Related config options were renamed too, for example `skipMiddlewareUrlNormalize` became `skipProxyUrlNormalize`.

All examples below use `proxy.ts`. On Next.js 15 or earlier, name the file `middleware.ts` and the function `middleware`.

## middleware.ts on Next.js 15 and Edge

```tsx
// middleware.ts
import { NextResponse, type NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();
  response.headers.set('x-request-path', request.nextUrl.pathname);
  return response;
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
  // runtime: 'nodejs', // 15.5+: opt into Node.js instead of Edge
};
```

On the Edge runtime there are no Node.js APIs, no TCP database drivers, and no native modules such as `bcrypt`. Auth libraries that need the database must use an Edge-safe config in middleware (for Auth.js, split the config so middleware imports only the JWT-based part), or opt into `runtime: 'nodejs'` on 15.5+.

Keep `middleware.ts` on Next.js 16 only when the Edge runtime is required. It is deprecated and will be removed.

## Matcher Configuration

Without a matcher, the proxy runs on every request, including static assets. Always set one.

```tsx
// One path
export const config = { matcher: '/about' };

// Several paths; :path* matches zero or more segments
export const config = { matcher: ['/dashboard/:path*', '/account/:path*'] };

// Everything except API routes, static files, and images
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)'],
};

// Object form: skip prefetches and match on conditions
export const config = {
  matcher: [
    {
      source: '/((?!api|_next/static|_next/image|favicon.ico).*)',
      missing: [
        { type: 'header', key: 'next-router-prefetch' },
        { type: 'header', key: 'purpose', value: 'prefetch' },
      ],
    },
  ],
};
```

- Matcher values must be constants. They are read at build time, so variables and template strings are not allowed.
- Inside the function, match paths as exact-or-subpath (`pathname === '/admin' || pathname.startsWith('/admin/')`). A bare `startsWith('/admin')` also matches `/admin-public`.

## Redirects

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';

const redirects: Record<string, string> = {
  '/old-page': '/new-page',
  '/blog/old-post': '/articles/new-post',
};

export function proxy(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  const destination = redirects[pathname];
  if (destination) {
    return NextResponse.redirect(new URL(destination, request.url), 308);
  }

  // Old query format to a path segment. Encode: the value is user input.
  if (pathname === '/search' && searchParams.has('query')) {
    const query = searchParams.get('query') ?? '';
    return NextResponse.redirect(new URL(`/search/${encodeURIComponent(query)}`, request.url));
  }

  return NextResponse.next();
}
```

- For a static list with no logic, prefer `redirects()` in `next.config.ts`. It runs before the proxy and needs no code.
- Never redirect to a URL taken from the query string (`?next=https://evil.com`) without checking that it is a same-origin path. Open redirects enable phishing.
- Do not hand-roll trailing-slash redirects. Next.js redirects `/about/` to `/about` by default. Set `trailingSlash: true` for the opposite.

## Rewrites

A rewrite serves a different URL while the browser keeps the original.

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';

const EXTERNAL_API_ORIGIN = 'https://api.example.com';

export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;

  // A/B test: allowlist the cookie value; it is client-controlled and becomes part of the path
  if (pathname === '/landing') {
    const bucket = request.cookies.get('bucket')?.value === 'b' ? 'b' : 'a';
    return NextResponse.rewrite(new URL(`/landing-${bucket}`, request.url));
  }

  // External API passthrough from a fixed origin
  if (pathname === '/api/external' || pathname.startsWith('/api/external/')) {
    const subPath = pathname.slice('/api/external'.length) || '/';
    // '//' or '\' could switch the host when resolved as a URL
    if (subPath.includes('//') || subPath.includes('\\')) {
      return NextResponse.json({ error: 'Bad request' }, { status: 400 });
    }
    const target = new URL(EXTERNAL_API_ORIGIN);
    target.pathname = subPath;
    target.search = search;

    // A rewrite forwards request headers. Never send the user's session to a third party.
    const headers = new Headers(request.headers);
    headers.delete('cookie');
    headers.delete('authorization');
    return NextResponse.rewrite(target, { request: { headers } });
  }

  return NextResponse.next();
}
```

Build external targets from a fixed origin, never with `new URL(userPath, origin)`. For a static mapping, prefer `rewrites()` in `next.config.ts`, which has the same header-forwarding caveat.

For locale routing, detect the locale from a cookie or `Accept-Language`, match it against an allowlist of supported locales, and redirect or rewrite to `/${locale}${pathname}`. Libraries such as `next-intl` ship a ready-made proxy.

## Headers and CORS

Set response headers on the `NextResponse`. To pass values to the route, set request headers, and overwrite any client-sent copy of the same name first.

```tsx
// proxy.ts: security headers
import { NextResponse, type NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  const requestHeaders = new Headers(request.headers);
  requestHeaders.delete('x-user-id'); // never trust a client-sent copy

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  return response;
}
```

For a Content Security Policy, generate a nonce per request in the proxy, set it in the `Content-Security-Policy` header and a request header, and avoid `'unsafe-inline'` and `'unsafe-eval'` in `script-src`. A nonce-based CSP forces dynamic rendering of every page.

```tsx
// proxy.ts: CORS for /api
import { NextResponse, type NextRequest } from 'next/server';

const allowedOrigins = new Set(['https://example.com', 'https://app.example.com']);

export function proxy(request: NextRequest) {
  const origin = request.headers.get('origin');
  const allowed = origin !== null && allowedOrigins.has(origin);

  if (request.method === 'OPTIONS') {
    const preflight = new NextResponse(null, { status: 204 });
    if (allowed) preflight.headers.set('Access-Control-Allow-Origin', origin);
    preflight.headers.set('Vary', 'Origin');
    preflight.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    preflight.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    preflight.headers.set('Access-Control-Max-Age', '86400');
    return preflight;
  }

  const response = NextResponse.next();
  if (allowed) response.headers.set('Access-Control-Allow-Origin', origin);
  response.headers.append('Vary', 'Origin'); // stop shared caches mixing origins
  return response;
}

export const config = { matcher: '/api/:path*' };
```

Never reflect an arbitrary `Origin`, and never combine `Access-Control-Allow-Origin: *` with credentials.

## Cookies

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  const response = NextResponse.next();

  if (!request.cookies.has('visitor_id')) {
    response.cookies.set('visitor_id', crypto.randomUUID(), {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365,
    });
  }

  const theme = request.cookies.get('theme')?.value === 'dark' ? 'dark' : 'light';
  response.headers.set('x-theme', theme);
  return response;
}
```

- Cookies set on the response reach the browser, but not the current render. To make a new cookie visible to the route in the same request, also set it on the request: `NextResponse.next({ request: { headers } })` with an updated `cookie` header.
- Every cookie value is client-controlled. Allowlist values before using them in paths, headers, or queries.
- Session cookies: `httpOnly`, `secure`, `sameSite: 'lax'` or stricter. Never write custom session crypto.

## Authentication Gating

Use Auth.js (NextAuth v5) or the project's auth library. The proxy only gives a fast redirect for signed-out users. It does not decide what a user may do.

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

const protectedPrefixes = ['/dashboard', '/account', '/admin'];

function isProtected(pathname: string) {
  return protectedPrefixes.some((p) => pathname === p || pathname.startsWith(`${p}/`));
}

export async function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  if (!isProtected(pathname)) return NextResponse.next();

  const token = await getToken({
    req: request,
    secret: process.env.AUTH_SECRET,
    secureCookie: request.nextUrl.protocol === 'https:',
  });

  if (!token) {
    const login = new URL('/login', request.url);
    login.searchParams.set('callbackUrl', pathname + search); // same-origin path only
    return NextResponse.redirect(login);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/account/:path*', '/admin/:path*'],
};
```

With Auth.js v5, alternatively re-export its wrapper: `export { auth as proxy } from '@/auth'` (or `as middleware` on 15), and use the `authorized` callback for the redirect logic.

Why this is not authorization:

- Server Actions are POST requests to the page that renders them, and Route Handlers can be called directly. A matcher gap, a renamed route, or a header trick can bypass the proxy.
- The token may be valid but stale: the user may have been demoted, banned, or downgraded since it was issued.

So in every Server Action, Route Handler, and protected page:

```tsx
// app/admin/actions.ts
'use server';

import { z } from 'zod';
import { auth } from '@/auth';

const BanSchema = z.object({ userId: z.uuid() });

export async function banUser(formData: FormData) {
  const session = await auth();
  if (!session?.user) throw new Error('Unauthorized');

  // Fresh role from the database, not from the cached token or the proxy
  const actor = await db.users.findUnique({ where: { id: session.user.id }, select: { role: true } });
  if (actor?.role !== 'admin') throw new Error('Forbidden');

  const { userId } = BanSchema.parse({ userId: formData.get('userId') });
  await db.users.update({ where: { id: userId }, data: { bannedAt: new Date() } });
}
```

Role checks in the proxy (redirecting non-admins away from `/admin`) are fine for UX, but repeat them on the server. Never cache session or role data under a shared key; see [nextjs-caching.md](nextjs-caching.md#per-user-and-safety-data).

## Geolocation and IP

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';
import { geolocation } from '@vercel/functions'; // Vercel; elsewhere read your platform's headers

const blockedCountries = new Set(['XX', 'YY']);

export function proxy(request: NextRequest) {
  const { country = 'US', city = 'Unknown' } = geolocation(request);

  if (blockedCountries.has(country)) {
    return NextResponse.redirect(new URL('/blocked', request.url));
  }

  const headers = new Headers(request.headers);
  headers.set('x-user-country', country); // overwrites any client-sent copy
  headers.set('x-user-city', encodeURIComponent(city));
  return NextResponse.next({ request: { headers } });
}
```

Read the values in a Server Component with `(await headers()).get('x-user-country')`.

- Geo and IP data come from the platform. Off Vercel, use the CDN's headers (for example Cloudflare's `cf-ipcountry`) and trust them only when the CDN strips client-sent copies.
- For rate limiting, use a shared store such as Upstash Redis with `@upstash/ratelimit`. In-memory counters are per instance and unbounded, so they fail on serverless.

## Bot Detection

```tsx
// proxy.ts
import { NextResponse, type NextRequest } from 'next/server';

const botPattern = /bot|spider|crawl|slurp|mediapartners/i;

export function proxy(request: NextRequest) {
  const userAgent = request.headers.get('user-agent') ?? '';
  const isBot = botPattern.test(userAgent);

  if (isBot && request.nextUrl.pathname.startsWith('/api/')) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const headers = new Headers(request.headers);
  headers.set('x-is-bot', isBot ? 'true' : 'false'); // overwrite any client-sent copy
  return NextResponse.next({ request: { headers } });
}
```

`User-Agent` is trivial to spoof. Use this for analytics or rendering choices, not as a security control. For real bot protection, use the platform's firewall or a service such as Vercel BotID or Cloudflare Bot Management.

## Best Practices

| Practice | Why |
|----------|-----|
| Use `proxy.ts` on Next.js 16 | `middleware.ts` is deprecated; keep it only for Edge or ≤15 |
| Always set a narrow `matcher` | The proxy runs on every matched request, including prefetches |
| Keep work fast and light | It adds latency to every request; no heavy DB work |
| Gate coarsely, authorize on the server | Re-check session and ownership in every Server Action and Route Handler |
| Zod-validate input where it is used | The proxy cannot validate action bodies |
| Match exact-or-subpath | `startsWith('/admin')` also matches `/admin-public` |
| Allowlist cookie, header, and query values | All are client-controlled |
| Overwrite client-sent copies of internal headers | Prevents spoofed `x-user-*` values |
| Strip `cookie` and `authorization` on external rewrites | Avoids leaking sessions to third parties |
| Prefer `next.config.ts` `redirects()`/`rewrites()` for static rules | No code on the request path |
| Always return a response | Use `NextResponse.next()` as the fallthrough |

For the routes the proxy protects, see [nextjs-routing.md](nextjs-routing.md). For Server Actions with forms, see [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms).
