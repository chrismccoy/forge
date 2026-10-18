# Workflow: Generate Next.js Proxy or Middleware

Create request interception for Next.js 16 (`proxy.ts`) or Next.js 15 and earlier (`middleware.ts`): auth gating, i18n redirects, rate limiting, and security headers with a nonce-based CSP, each with a matcher. Use it when the user asks for "middleware for auth", "i18n routing", "rate limiting", "security headers", or "add proxy.ts".

## Contents

- [Instructions](#instructions)
- [Proxy vs Middleware](#proxy-vs-middleware)
- [Example Output](#example-output)
  - [Authentication gating](#authentication-gating)
  - [Auth.js wrapper](#authjs-wrapper)
  - [Database check (exception pattern)](#database-check-exception-pattern)
  - [Internationalization](#internationalization)
  - [Rate limiting](#rate-limiting)
  - [Security headers with a nonce CSP](#security-headers-with-a-nonce-csp)
  - [Combining concerns](#combining-concerns)
- [Checklist](#checklist)
- [Related](#related)

## Instructions

1. **Inspect the project first**
   - Read the Next.js version in `package.json`. 16 uses `proxy.ts`; 15 and earlier use `middleware.ts`.
   - Check whether routes live in `app/` or `src/app/`. The proxy file goes in the project root, or in `src/` when the app lives in `src/app/`.
   - Read path aliases in `tsconfig.json`.
   - Look for an existing `proxy.ts` or `middleware.ts`. A project has exactly one; extend it instead of adding a second file.
   - Find existing helpers: auth (`@/auth` with Auth.js v5, or another library), DB client (`@/lib/db`), and any rate-limit store (Upstash Redis env vars).
   - Note the hosting target (Vercel, self-hosted behind a reverse proxy, Docker). It decides how to read the client IP.

2. **Analyze the request**
   - Identify the concern: auth gating, i18n, rate limiting, security headers, redirects, or rewrites.
   - List the paths it applies to, and the paths it must skip (`_next/static`, `_next/image`, `favicon.ico`, public files, `api` where relevant).
   - Decide how API paths respond: JSON `401`/`403`/`429`, never a redirect to an HTML login page.

3. **Implement**
   - Next.js 16: `proxy.ts` exporting `proxy(request)`. It runs on Node.js; a `runtime` config is not allowed.
   - Next.js 15 and earlier: `middleware.ts` exporting `middleware(request)`. It runs on Edge by default; 15.5 can opt into Node.js with `export const config = { runtime: 'nodejs' }`.
   - Export `config.matcher` narrowed to the paths that need the logic. Matcher values must be static literals.
   - Keep the work small: no heavy DB queries, no long-running calls. The proxy runs on every matched request, including prefetches.
   - The proxy is not authorization. Every Server Action, Route Handler, and protected page re-checks the session and ownership.
   - Strip client-supplied copies of any header the proxy sets for downstream code (`x-user-id`, `x-nonce`).

4. **Report**
   - The created or modified file path (Server; state the runtime).
   - The matcher and the paths it skips.
   - Required env vars and packages.
   - The server-side checks that must still exist in pages, actions, and handlers.

Optional shortcut: scaffold `proxy.ts` with the bundled generator, then edit it. It refuses to overwrite an existing file unless `--force` is passed (only with the user's consent).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/generate-nextjs-component.py middleware --path .
```

Pass `--legacy-middleware` to write `middleware.ts` for Next.js 15 and earlier.

## Proxy vs Middleware

| Next.js version | File | Export | Runtime |
|-----------------|------|--------|---------|
| 16+ (default) | `proxy.ts` | `export function proxy` | Node.js (DB and Node APIs available; `runtime` config not allowed) |
| 16, Edge required | `middleware.ts` (deprecated) | `export function middleware` | Edge |
| 15.5 | `middleware.ts` | `export function middleware` | Edge by default; Node.js via `config.runtime = 'nodejs'` |
| ≤15.4 | `middleware.ts` | `export function middleware` | Edge |

Migrate an existing file with `npx @next/codemod@canary middleware-to-proxy .`. The examples below use `proxy.ts`; on 15 and earlier, rename the file and the function to `middleware`. Matcher syntax, redirects, rewrites, and cookies are in [nextjs-middleware.md](../nextjs-middleware.md).

## Example Output

### Authentication gating

Use `getToken` when the proxy must stay free of the full Auth.js config. `getToken` needs `secret`, and `secureCookie` must match whether the session cookie carries the `__Secure-` prefix. Behind a reverse proxy that terminates TLS, set it explicitly.

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

const publicPaths = ['/', '/login', '/register', '/forgot-password', '/api/auth'];
const adminPaths = ['/admin', '/api/admin'];

// Exact match or sub-path only ('/' must not match everything, '/admin' must not match '/administrator')
const matches = (pathname: string, path: string) =>
  pathname === path || pathname.startsWith(`${path}/`);

export async function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;

  if (publicPaths.some((path) => matches(pathname, path))) {
    return NextResponse.next();
  }

  const token = await getToken({
    req: request,
    secret: process.env.AUTH_SECRET,
    // Auth.js prefixes the cookie with __Secure- on HTTPS; this must match
    secureCookie: request.nextUrl.protocol === 'https:',
  });

  // API callers get JSON, not a 307 to the login HTML
  const isApi = matches(pathname, '/api');

  if (!token) {
    if (isApi) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('callbackUrl', pathname + search); // same-origin path only
    return NextResponse.redirect(loginUrl);
  }

  // UX-level role gate; the admin pages and handlers re-check the role from the DB
  if (adminPaths.some((path) => matches(pathname, path)) && token.role !== 'admin') {
    if (isApi) return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    return NextResponse.redirect(new URL('/unauthorized', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

When the login page reads `callbackUrl`, accept only same-origin paths (starts with `/`, not `//`) to avoid an open redirect.

### Auth.js wrapper

With Auth.js v5 configured in `@/auth`, wrap the proxy with `auth`. It reads and refreshes the session cookie and exposes it as `request.auth`.

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse } from 'next/server';
import { auth } from '@/auth';

export const proxy = auth((request) => {
  const { pathname, search } = request.nextUrl;
  if (!request.auth) {
    if (pathname.startsWith('/api/')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('callbackUrl', pathname + search);
    return NextResponse.redirect(loginUrl);
  }
  return NextResponse.next();
});

export const config = {
  matcher: ['/dashboard/:path*', '/account/:path*', '/api/private/:path*'],
};
```

On Next.js 15 export it as `middleware` instead. For a pure redirect, `export { auth as proxy } from '@/auth'` plus the `authorized` callback in the Auth.js config also works.

### Database check (exception pattern)

A DB lookup in the proxy runs on every matched request. Prefer `auth()` checks in layouts, pages, and Route Handlers. Use this only when a revoked or deactivated user must be blocked before anything renders, and keep the matcher narrowed to the protected prefixes. It needs the Node.js runtime (`proxy.ts` on 16, or `runtime: 'nodejs'` on 15.5).

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';
import { verify } from 'jsonwebtoken';
import { db } from '@/lib/db';

const matches = (pathname: string, path: string) =>
  pathname === path || pathname.startsWith(`${path}/`);

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Strip client-supplied copies so they cannot be spoofed downstream
  const requestHeaders = new Headers(request.headers);
  requestHeaders.delete('x-user-id');
  requestHeaders.delete('x-user-role');

  const isApi = matches(pathname, '/api');
  const deny = (status: 401 | 403) =>
    isApi
      ? NextResponse.json({ error: status === 401 ? 'Unauthorized' : 'Forbidden' }, { status })
      : NextResponse.redirect(new URL(status === 401 ? '/login' : '/unauthorized', request.url));

  const token = request.cookies.get('auth-token')?.value;
  if (!token) return deny(401);

  try {
    // Pin the algorithm; never let the token header choose it
    const decoded = verify(token, process.env.JWT_SECRET!, { algorithms: ['HS256'] }) as {
      userId: string;
    };

    const user = await db.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, role: true, isActive: true },
    });
    if (!user || !user.isActive) return deny(401);

    if ((matches(pathname, '/admin') || matches(pathname, '/api/admin')) && user.role !== 'admin') {
      return deny(403);
    }

    // Pass user context as REQUEST headers (readable via headers(); not sent to the browser).
    // Routes outside the matcher never get these, so read them only under the matched prefixes.
    requestHeaders.set('x-user-id', user.id);
    requestHeaders.set('x-user-role', user.role);
    return NextResponse.next({ request: { headers: requestHeaders } });
  } catch {
    return deny(401);
  }
}

// Only the protected prefixes: every other route skips the DB round-trip
export const config = {
  matcher: ['/admin/:path*', '/dashboard/:path*', '/api/admin/:path*'],
};
```

### Internationalization

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';

const locales = ['en', 'es', 'fr', 'de'] as const;
type Locale = (typeof locales)[number];
const defaultLocale: Locale = 'en';

const isLocale = (value: string | undefined): value is Locale =>
  value !== undefined && (locales as readonly string[]).includes(value);

function getLocale(request: NextRequest): Locale {
  const cookieLocale = request.cookies.get('NEXT_LOCALE')?.value;
  if (isLocale(cookieLocale)) return cookieLocale;

  const preferred = request.headers
    .get('accept-language')
    ?.split(',')
    .map((part) => part.split(';')[0].trim().split('-')[0].toLowerCase())
    .find(isLocale);

  return preferred ?? defaultLocale;
}

export function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;

  const hasLocale = locales.some(
    (locale) => pathname === `/${locale}` || pathname.startsWith(`/${locale}/`)
  );
  if (hasLocale) return NextResponse.next();

  const locale = getLocale(request);
  return NextResponse.redirect(new URL(`/${locale}${pathname}${search}`, request.url));
}

export const config = {
  // Skip api, Next.js internals, and any path with a dot (public files such as
  // /robots.txt and /logo.png), or they get redirected to /en/robots.txt
  matcher: ['/((?!api|_next|.*\\..*).*)'],
};
```

Pages then live under `app/[lang]/`. Validate `lang` in the layout and call `notFound()` for unknown values; see [nextjs-routing.md](../nextjs-routing.md#dynamic-segments).

### Rate limiting

In-memory counters do not work here: each serverless or Edge instance has its own memory, and a `Map` grows without bound. Use a shared store such as Upstash Redis (`npm install @upstash/ratelimit @upstash/redis`, env `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`).

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';
import { ipAddress } from '@vercel/functions';

const redis = Redis.fromEnv();

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(100, '1 m'), // 100 requests per minute per IP
  prefix: 'ratelimit:api',
});

// Separate, stricter bucket for requests with no identifiable IP. Sharing one
// 'unknown' key with the main limiter would let one client throttle everyone.
const unknownIpRatelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
  prefix: 'ratelimit:api:no-ip',
});

function getClientIp(request: NextRequest): string | undefined {
  // On Vercel: the platform-provided IP
  const platformIp = ipAddress(request);
  if (platformIp) return platformIp;
  // Elsewhere x-forwarded-for is client-spoofable. Trust its first entry only when
  // a reverse proxy you control overwrites it, and opt in with TRUST_PROXY=1.
  if (process.env.TRUST_PROXY === '1') {
    return request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || undefined;
  }
  return undefined; // falls into the stricter no-IP bucket
}

export async function proxy(request: NextRequest) {
  const ip = getClientIp(request);
  const { success, limit, remaining, reset } = ip
    ? await ratelimit.limit(ip)
    : await unknownIpRatelimit.limit('no-ip');

  if (!success) {
    return NextResponse.json(
      { error: 'Too many requests' },
      {
        status: 429,
        headers: {
          'Retry-After': String(Math.max(0, Math.ceil((reset - Date.now()) / 1000))),
          'X-RateLimit-Limit': String(limit),
          'X-RateLimit-Remaining': String(remaining),
        },
      }
    );
  }

  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```

For per-user limits on authenticated endpoints (for example, expensive AI calls), rate-limit inside the Route Handler or Server Action keyed by `session.user.id`, where the session is verified.

### Security headers with a nonce CSP

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';

export function proxy(request: NextRequest) {
  // Fresh, unpredictable nonce per request
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const isDev = process.env.NODE_ENV === 'development';

  const csp = [
    "default-src 'self'",
    // React needs 'unsafe-eval' in development only
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${isDev ? " 'unsafe-eval'" : ''}`,
    `style-src 'self' 'nonce-${nonce}'`,
    "img-src 'self' blob: data:",
    "font-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    'upgrade-insecure-requests',
  ].join('; ');

  // Next.js reads the nonce from the request CSP header and applies it to its own
  // scripts. Set x-nonce on the request (overwriting any client value) for your own tags.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('Content-Security-Policy', csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });

  response.headers.set('Content-Security-Policy', csp);
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');

  return response;
}

export const config = {
  matcher: [
    {
      source: '/((?!api|_next/static|_next/image|favicon.ico).*)',
      // Skip prefetches; they do not need a nonce
      missing: [
        { type: 'header', key: 'next-router-prefetch' },
        { type: 'header', key: 'purpose', value: 'prefetch' },
      ],
    },
  ],
};
```

Read the nonce in a Server Component for third-party scripts:

```tsx
// app/layout.tsx — Server Component
import { headers } from 'next/headers';
import Script from 'next/script';

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const nonce = (await headers()).get('x-nonce') ?? undefined;
  return (
    <html lang="en">
      <body>
        {children}
        <Script src="https://www.googletagmanager.com/gtag/js" strategy="afterInteractive" nonce={nonce} />
      </body>
    </html>
  );
}
```

Nonces require dynamic rendering: no static, ISR, or cached pages under this matcher. For a static site, set a CSP without nonces in `next.config` `headers()` instead. Inline `style` attributes from some UI libraries fail under a nonce-only `style-src`; test before shipping.

### Combining concerns

A project has one proxy file. Write each concern as a function that returns a response to short-circuit, or `undefined` to continue, and widen the matcher to the union of their paths.

```tsx
// proxy.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';
import { rateLimit } from '@/lib/proxy/rate-limit';
import { authGate } from '@/lib/proxy/auth-gate';
import { securityHeaders } from '@/lib/proxy/security-headers';

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (pathname.startsWith('/api/')) {
    const limited = await rateLimit(request); // NextResponse (429) | undefined
    if (limited) return limited;
  }

  const denied = await authGate(request); // NextResponse (401/redirect) | undefined
  if (denied) return denied;

  return pathname.startsWith('/api/') ? NextResponse.next() : securityHeaders(request);
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

Run cheap checks first (rate limit before any token or DB work), and make sure each helper skips paths it does not own.

## Checklist

- [ ] Project inspected: version, `app/` vs `src/app/`, aliases, existing proxy or middleware file, auth helper, hosting target
- [ ] `proxy.ts` with `export function proxy` on 16; `middleware.ts` with `export function middleware` on 15 and earlier
- [ ] File placed in the project root, or `src/` when the app lives in `src/app/`
- [ ] Matcher narrowed to the paths that need it; static assets and public files skipped
- [ ] Path checks use exact match or `path/` prefix, never a bare `startsWith(path)`
- [ ] API paths answer with JSON `401`/`403`/`429`, not redirects
- [ ] `callbackUrl` limited to same-origin paths
- [ ] Headers set for downstream code are stripped from the incoming request first
- [ ] Rate limiting uses a shared store; client IP from the platform, or `x-forwarded-for` only with `TRUST_PROXY=1`
- [ ] CSP nonce generated per request; pages under it render dynamically
- [ ] No heavy DB or network work, unless it is the narrowed exception pattern
- [ ] Every protected page, Server Action, and Route Handler still checks the session and ownership
- [ ] File path, runtime, matcher, env vars, and packages reported

## Related

- [nextjs-middleware.md](../nextjs-middleware.md): matchers, redirects, rewrites, cookies, geolocation, bot detection
- [nextjs-middleware.md](../nextjs-middleware.md#authentication-gating): why the proxy is not authorization
- [nextjs-route-handler.md](nextjs-route-handler.md): server-side auth, ownership, and idempotency in handlers
- [nextjs-caching.md](../nextjs-caching.md#per-user-and-safety-data): never cache session or role data
