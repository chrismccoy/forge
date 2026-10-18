# Next.js Authentication

Authentication and authorization in the Next.js App Router (15.5/16) with Auth.js v5 (`next-auth@5`), plus Better Auth as an alternative. Load it when adding sign-in, reading the session on the server, protecting pages, Server Actions, or Route Handlers, or adding roles.

## Contents

- [Quick Reference](#quick-reference)
- [Setup](#setup)
- [Split Config for the Proxy](#split-config-for-the-proxy)
- [Reading the Session](#reading-the-session)
- [Credentials Provider](#credentials-provider)
- [Sign-In and Sign-Out Forms](#sign-in-and-sign-out-forms)
- [Sessions: JWT or Database](#sessions-jwt-or-database)
- [Extending Session and JWT Types](#extending-session-and-jwt-types)
- [Authorization Helpers](#authorization-helpers)
- [Protecting Route Handlers](#protecting-route-handlers)
- [getToken Caveats](#gettoken-caveats)
- [CSRF and Server Actions](#csrf-and-server-actions)
- [Caching and Per-User Pages](#caching-and-per-user-pages)
- [Testing Auth](#testing-auth)
- [Better Auth as an Alternative](#better-auth-as-an-alternative)
- [Best Practices](#best-practices)

## Quick Reference

| Export from `@/auth` | Use |
|----------------------|-----|
| `auth` | `await auth()` in Server Components, Server Actions, Route Handlers; also wraps the proxy and handlers |
| `signIn` | `await signIn('github', { redirectTo })` in a Server Action |
| `signOut` | `await signOut({ redirectTo: '/' })` in a Server Action |
| `handlers` | `export const { GET, POST } = handlers` in the catch-all route |

| Where | How to read the session | Is it authorization? |
|-------|------------------------|----------------------|
| `proxy.ts` / `middleware.ts` | `req.auth` inside `auth((req) => ...)` | No. Optimistic redirect only |
| Server Component | `await auth()` | Yes, for what that component renders |
| Server Action | `await auth()` at the top of the action | Yes, required in every action |
| Route Handler | `await auth()` inside the handler | Yes, required in every handler |
| Client Component | `useSession()` under `SessionProvider` | No. UI only |

## Setup

```bash
npm install next-auth@beta
npx auth secret   # writes AUTH_SECRET to .env.local
```

```bash
# .env.local
AUTH_SECRET=...            # required; signs and encrypts the session cookie
AUTH_GITHUB_ID=...         # inferred by the GitHub provider
AUTH_GITHUB_SECRET=...
AUTH_GOOGLE_ID=...         # inferred by the Google provider
AUTH_GOOGLE_SECRET=...
# AUTH_TRUST_HOST=true when self-hosting behind a reverse proxy
```

Auth.js v5 reads `AUTH_<PROVIDER>_ID` and `AUTH_<PROVIDER>_SECRET` automatically, so `providers: [GitHub]` needs no options. Pass `clientId`/`clientSecret` only when the variable names differ.

Create `auth.ts` at the project root (or `src/`): it calls `NextAuth({ ...authConfig, ... })` and exports `{ handlers, auth, signIn, signOut }`. The full file, with an adapter and Credentials, is in [Credentials Provider](#credentials-provider); the shared `authConfig` is in [Split Config for the Proxy](#split-config-for-the-proxy).

```ts
// app/api/auth/[...nextauth]/route.ts
import { handlers } from '@/auth';

export const { GET, POST } = handlers;
```

The OAuth callback URL to register with the provider is `<origin>/api/auth/callback/<provider>`, for example `http://localhost:3000/api/auth/callback/github`.

## Split Config for the Proxy

Keep the request interceptor free of the database adapter, ORM client, and password hashing library. Put providers, pages, and callbacks that need no database in `auth.config.ts`, and add the adapter and Credentials provider in `auth.ts`. This is required for `middleware.ts` on the Edge runtime (15.5 and earlier) and still recommended for `proxy.ts` on 16 to keep the interceptor small.

```ts
// auth.config.ts (no adapter, no DB client, no bcrypt)
import type { NextAuthConfig } from 'next-auth';
import GitHub from 'next-auth/providers/github';
import Google from 'next-auth/providers/google';

const protectedPrefixes = ['/dashboard', '/account', '/admin'];

export default {
  providers: [GitHub, Google],
  pages: { signIn: '/login' },
  callbacks: {
    // Runs in the proxy: return false to redirect to pages.signIn
    authorized({ auth, request: { nextUrl } }) {
      const isProtected = protectedPrefixes.some(
        (p) => nextUrl.pathname === p || nextUrl.pathname.startsWith(`${p}/`),
      );
      return isProtected ? !!auth?.user : true;
    },
    jwt({ token, user }) {
      if (user) {
        token.id = user.id!;
        token.role = user.role ?? 'user';
      }
      return token;
    },
    session({ session, token }) {
      session.user.id = token.id;
      session.user.role = token.role;
      return session;
    },
  },
} satisfies NextAuthConfig;
```

```ts
// proxy.ts (Next.js 16)
import NextAuth from 'next-auth';
import authConfig from './auth.config';

export const { auth: proxy } = NextAuth(authConfig);

export const config = {
  matcher: ['/((?!api/auth|_next/static|_next/image|favicon.ico).*)'],
};
```

On 15.5 and earlier, name the file `middleware.ts` and export `middleware` instead (`export const { auth: middleware } = NextAuth(authConfig)`). When no split is needed, `export { auth as proxy } from '@/auth'` is enough.

For custom logic, wrap a function instead: `const { auth } = NextAuth(authConfig); export const proxy = auth((req) => { ... })`, where `req.auth` is the session or `null`. Matchers, redirects, `callbackUrl` handling, and why the proxy is not authorization are covered in [nextjs-middleware.md](nextjs-middleware.md#authentication-gating). Never put role checks only there: re-check in every page, action, and handler.

## Reading the Session

Read the session on the server with `auth()`. It reads request cookies, so any route that calls it renders dynamically.

```tsx
// app/dashboard/page.tsx
import { redirect } from 'next/navigation';
import { auth } from '@/auth';

export default async function DashboardPage() {
  const session = await auth();
  if (!session?.user) redirect('/login?callbackUrl=/dashboard');

  return <h1>Welcome, {session.user.name}</h1>;
}
```

```ts
// app/posts/actions.ts
'use server';

import { auth } from '@/auth';

export async function deletePost(postId: string) {
  const session = await auth();
  if (!session?.user) throw new Error('Unauthorized');
  // ownership check: see Authorization Helpers
}
```

Use the client API only where a Client Component must react to session changes (a menu that updates after sign-in in another tab, `update()` after a profile change). Pass the server session into `SessionProvider` to avoid an extra fetch and a loading flash.

```tsx
// app/providers.tsx
'use client';

import type { Session } from 'next-auth';
import { SessionProvider } from 'next-auth/react';

export function Providers({ session, children }: { session: Session | null; children: React.ReactNode }) {
  return <SessionProvider session={session}>{children}</SessionProvider>;
}
```

In a Client Component, `const { data: session, status, update } = useSession()` from `next-auth/react` gives the session, a `'loading' | 'authenticated' | 'unauthenticated'` status, and a function to refresh it.

Prefer passing `session.user.name` as a prop from a Server Component over adding `SessionProvider` to the whole tree. A client-side guard (`useSession` + redirect) hides UI but protects nothing.

## Credentials Provider

Validate credentials with Zod 4, hash passwords with `bcryptjs` or `argon2`, and return `null` for any failure so the response does not reveal whether the email exists. The Credentials provider only works with the JWT session strategy.

```ts
// lib/schemas/auth.ts
import { z } from 'zod';

export const SignInSchema = z.object({
  email: z.email().max(254),
  password: z.string().min(8).max(128),
});
```

```ts
// auth.ts
import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import bcrypt from 'bcryptjs';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@/lib/prisma';
import { SignInSchema } from '@/lib/schemas/auth';
import authConfig from './auth.config';

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  adapter: PrismaAdapter(prisma),
  session: { strategy: 'jwt' }, // required with Credentials; adapter alone defaults to 'database'
  providers: [
    ...authConfig.providers,
    Credentials({
      credentials: { email: {}, password: {} },
      async authorize(credentials) {
        const parsed = SignInSchema.safeParse(credentials);
        if (!parsed.success) return null;

        const user = await prisma.user.findUnique({
          where: { email: parsed.data.email.toLowerCase() },
          select: { id: true, email: true, name: true, role: true, passwordHash: true },
        });
        if (!user?.passwordHash) return null;

        const ok = await bcrypt.compare(parsed.data.password, user.passwordHash);
        if (!ok) return null;

        return { id: user.id, email: user.email, name: user.name, role: user.role };
      },
    }),
  ],
});
```

Registration is a separate Server Action: parse with Zod, `bcrypt.hash(password, 12)`, insert, and rely on a UNIQUE constraint on `email` instead of a check-then-create. Rate-limit both sign-in and registration by IP and email; Auth.js does not.

Returning `null` makes `signIn` throw `CredentialsSignin`. To send the client a specific code, throw a subclass from `authorize`: `class AccountLockedError extends CredentialsSignin { code = 'account_locked' }` (import `CredentialsSignin` from `next-auth`).

## Sign-In and Sign-Out Forms

Call `signIn` and `signOut` in Server Actions. On success they redirect by throwing `NEXT_REDIRECT`, so catch only `AuthError` and rethrow everything else.

```ts
// app/login/actions.ts
'use server';

import { AuthError } from 'next-auth';
import { signIn, signOut } from '@/auth';
import { SignInSchema } from '@/lib/schemas/auth';

export type LoginState = { error?: string; email?: string };

function safeRedirect(value: FormDataEntryValue | null): string {
  const path = typeof value === 'string' ? value : '';
  // Same-origin path only: reject "//evil.com" and "https://..."
  return path.startsWith('/') && !path.startsWith('//') ? path : '/dashboard';
}

export async function login(prevState: LoginState, formData: FormData): Promise<LoginState> {
  const parsed = SignInSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
  });
  const email = String(formData.get('email') ?? '');
  if (!parsed.success) return { error: 'Invalid email or password', email };

  try {
    await signIn('credentials', {
      ...parsed.data,
      redirectTo: safeRedirect(formData.get('callbackUrl')),
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return {
        error: error.type === 'CredentialsSignin' ? 'Invalid email or password' : 'Sign-in failed. Try again.',
        email,
      };
    }
    throw error; // NEXT_REDIRECT on success must propagate
  }
  return {};
}

export async function signInWithGitHub(formData: FormData) {
  await signIn('github', { redirectTo: safeRedirect(formData.get('callbackUrl')) });
}

export async function logout() {
  await signOut({ redirectTo: '/' });
}
```

```tsx
// app/login/login-form.tsx
'use client';

import { useActionState } from 'react';
import { login, signInWithGitHub, type LoginState } from './actions';

export function LoginForm({ callbackUrl }: { callbackUrl?: string }) {
  const [state, formAction, isPending] = useActionState<LoginState, FormData>(login, {});

  return (
    <>
      <form action={formAction} noValidate>
        <input type="hidden" name="callbackUrl" value={callbackUrl ?? ''} />
        <label htmlFor="email">Email</label>
        <input id="email" name="email" type="email" autoComplete="email" defaultValue={state.email} required />
        <label htmlFor="password">Password</label>
        <input id="password" name="password" type="password" autoComplete="current-password" required />
        {state.error && <p role="alert">{state.error}</p>}
        <button type="submit" disabled={isPending}>{isPending ? 'Signing in…' : 'Sign in'}</button>
      </form>
      <form action={signInWithGitHub}>
        <input type="hidden" name="callbackUrl" value={callbackUrl ?? ''} />
        <button type="submit">Sign in with GitHub</button>
      </form>
    </>
  );
}
```

Render `LoginForm` from `app/login/page.tsx`, passing `callbackUrl` from the awaited `searchParams`. Sign out with `<form action={logout}><button type="submit">Sign out</button></form>`, which works in Server and Client Components.

From a Client Component, import `signIn`/`signOut` from `next-auth/react` instead; they also accept `{ redirectTo }`. See [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms) for `useActionState` patterns and field errors.

## Sessions: JWT or Database

| | JWT (`strategy: 'jwt'`) | Database (`strategy: 'database'`) |
|-|-------------------------|-----------------------------------|
| Storage | Encrypted cookie | Session row via adapter; cookie holds an ID |
| Default when | No adapter | An adapter is configured |
| Readable in the proxy | Yes, without a DB | No, the proxy-side config has no adapter |
| Revocation | Not before expiry; check the DB for bans and role changes in sensitive handlers | Delete the row |
| Credentials provider | Supported | Not supported |

An adapter is still useful with JWT: it stores users and OAuth accounts. Install the one for the project's ORM (`@auth/prisma-adapter`, `@auth/drizzle-adapter`) and generate its schema from the adapter docs.

For database sessions (OAuth or email providers only), set `session: { strategy: 'database', maxAge, updateAge }` and note that the `session` callback then receives `user` (the adapter row) instead of `token`.

With database sessions, the proxy cannot verify the session. Gate there only on UX grounds, and do the real check with `auth()` on the server.

Keep the JWT small: IDs and a role hint, never provider access tokens. Anything placed on `session` reaches the browser through `useSession()` and `/api/auth/session`. Read provider tokens on the server from the adapter's `Account` table.

## Extending Session and JWT Types

```ts
// types/next-auth.d.ts
import type { DefaultSession } from 'next-auth';

export type Role = 'user' | 'editor' | 'admin';

declare module 'next-auth' {
  interface Session {
    user: { id: string; role: Role } & DefaultSession['user'];
  }
  interface User {
    role?: Role;
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string;
    role: Role;
  }
}
```

Make sure `tsconfig.json` includes the `types/` folder. With database sessions and a typed adapter, also augment `AdapterUser` in `@auth/core/adapters` if the adapter rejects the extra field.

## Authorization Helpers

Authentication says who the user is. Authorization says what they may do, and it runs in every Server Action, Route Handler, and protected page. Read the role fresh from the database, not from the token, for anything sensitive.

```ts
// lib/authz.ts
import 'server-only';
import { cache } from 'react';
import { auth } from '@/auth';
import { prisma } from '@/lib/prisma';
import type { Role } from '@/types/next-auth';

export class AuthzError extends Error {
  constructor(public status: 401 | 403) {
    super(status === 401 ? 'Unauthorized' : 'Forbidden');
  }
}

// Deduplicated per request, never shared across requests
export const getCurrentUser = cache(async () => {
  const session = await auth();
  if (!session?.user?.id) return null;
  const user = await prisma.user.findUnique({
    where: { id: session.user.id },
    select: { id: true, email: true, name: true, role: true, bannedAt: true },
  });
  return user && !user.bannedAt ? user : null; // unknown or banned: deny
});

export async function requireUser() {
  const user = await getCurrentUser();
  if (!user) throw new AuthzError(401);
  return user;
}

export async function requireRole(...roles: Role[]) {
  const user = await requireUser();
  if (!roles.includes(user.role as Role)) throw new AuthzError(403);
  return user;
}
```

Use them at the top of every action, then check ownership on the record itself:

```ts
// app/posts/actions.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/prisma';
import { requireUser } from '@/lib/authz';

const UpdatePostSchema = z.object({ id: z.uuid(), title: z.string().trim().min(1).max(200) });

export async function updatePost(formData: FormData) {
  const user = await requireUser();
  const { id, title } = UpdatePostSchema.parse({ id: formData.get('id'), title: formData.get('title') });

  // Ownership in the WHERE clause, not a separate read-then-write
  const result = await prisma.post.updateMany({ where: { id, authorId: user.id }, data: { title } });
  if (result.count === 0) throw new Error('Not found');

  revalidatePath(`/posts/${id}`);
}
```

In pages, convert the error into navigation: `const admin = await requireRole('admin').catch((e) => { if (e instanceof AuthzError) redirect(e.status === 401 ? '/login' : '/'); throw e; })`. `redirect()` throws, so never call it inside a `try` block whose `catch` swallows errors.

With `experimental.authInterrupts: true` in `next.config.ts`, call `unauthorized()` and `forbidden()` from `next/navigation` instead, and render `unauthorized.tsx` and `forbidden.tsx`. These are still experimental; do not wrap them in `try/catch`, since they work by throwing.

Hiding a button with a role check in a Server Component is UX only. The action behind it must call `requireRole` again.

## Protecting Route Handlers

Call `auth()` inside the handler and map failures to status codes. Never return a redirect to an API client.

```ts
// app/api/posts/route.ts
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '@/lib/prisma';
import { AuthzError, requireUser } from '@/lib/authz';

const CreatePostSchema = z.object({ title: z.string().trim().min(1).max(200), body: z.string().max(20_000) });

export async function POST(request: Request) {
  try {
    const user = await requireUser();
    const parsed = CreatePostSchema.safeParse(await request.json().catch(() => null));
    if (!parsed.success) return NextResponse.json({ error: z.flattenError(parsed.error) }, { status: 400 });

    const post = await prisma.post.create({ data: { ...parsed.data, authorId: user.id } });
    return NextResponse.json(post, { status: 201 });
  } catch (e) {
    if (e instanceof AuthzError) return NextResponse.json({ error: e.message }, { status: e.status });
    throw e;
  }
}
```

The wrapper form also works for handlers: `export const GET = auth(function GET(req) { ... })`, where `req.auth` is the session or `null`. Prefer the explicit `requireUser()` call so pages, actions, and handlers share one check.

Webhook routes have no session: authenticate them with a signature instead (see Safety Rules in `SKILL.md`).

## getToken Caveats

`getToken` from `next-auth/jwt` decodes the JWT cookie without the full Auth.js instance. Prefer `auth()` everywhere; reach for `getToken` only in a proxy that cannot import the Auth.js config.

- Pass `secret: process.env.AUTH_SECRET` explicitly instead of relying on environment defaults.
- Pass `secureCookie: request.nextUrl.protocol === 'https:'`. In production the cookie is `__Secure-authjs.session-token`; a mismatch returns `null` for every user.
- It returns the raw token, not the result of the `session` callback, and only works with the JWT strategy.
- A valid token can be stale: role changes and bans are not reflected until it is reissued.

See [nextjs-middleware.md](nextjs-middleware.md#authentication-gating) for a complete `getToken` proxy.

## CSRF and Server Actions

- Server Actions accept only POST, and Next.js compares the `Origin` header's host with the app's host (`x-forwarded-host` or `host`). A mismatch is rejected. A request with no `Origin` header is allowed with a warning, so do not treat this as the only defense for highly sensitive actions.
- Behind a reverse proxy that does not forward the public host, or when a trusted second domain posts to the app's actions, list it:

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    serverActions: { allowedOrigins: ['app.example.com', '*.example.com'] },
  },
};

export default nextConfig;
```

- Auth.js protects its own `/api/auth/*` POST endpoints with a double-submit CSRF token. The app's own Route Handlers get no automatic CSRF protection: keep the session cookie `SameSite=Lax` (the default), never mutate on GET, and require a JSON content type or a custom header for cookie-authenticated POST/PUT/DELETE handlers.

## Caching and Per-User Pages

- `auth()`, `cookies()`, and `headers()` make a route dynamic. Do not call them inside a `'use cache'` function, and do not cache their results under a shared key.
- Never put role, plan, ban status, or session validity in `unstable_cache`, `'use cache'`, or ISR output. Read them fresh per request.
- Use React `cache()` (as in `getCurrentUser`) only for per-request deduplication.
- After sign-in, sign-out, or a role change, the client Router Cache can still show the previous user's segments. `signIn`/`signOut` redirects refresh the tree; after other changes call `revalidatePath` or `router.refresh()`.

Full rules: [nextjs-caching.md](nextjs-caching.md#per-user-and-safety-data).

## Testing Auth

Mock `@/auth` so tests never load `next-auth` or touch a database, and drive behavior through the mocked `auth()`.

```ts
// app/posts/actions.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Session } from 'next-auth';

vi.mock('server-only', () => ({}));
vi.mock('@/auth', () => ({ auth: vi.fn(), signIn: vi.fn(), signOut: vi.fn() }));
vi.mock('next/cache', () => ({ revalidatePath: vi.fn() }));
vi.mock('@/lib/prisma', () => ({
  prisma: { user: { findUnique: vi.fn() }, post: { updateMany: vi.fn() } },
}));

import { auth } from '@/auth';
import { prisma } from '@/lib/prisma';
import { updatePost } from './actions';

// auth() is overloaded (wrapper and getter); cast to the getter signature
const mockAuth = vi.mocked(auth as unknown as () => Promise<Session | null>);
const postId = '6f1c0f7e-2a1b-4c3d-9e8f-0a1b2c3d4e5f';

const form = (data: Record<string, string>) => {
  const fd = new FormData();
  Object.entries(data).forEach(([k, v]) => fd.set(k, v));
  return fd;
};

describe('updatePost', () => {
  beforeEach(() => vi.clearAllMocks());

  it('rejects signed-out users', async () => {
    mockAuth.mockResolvedValue(null);
    await expect(updatePost(form({ id: postId, title: 'x' }))).rejects.toThrow('Unauthorized');
    expect(prisma.post.updateMany).not.toHaveBeenCalled();
  });

  it('scopes the update to the author', async () => {
    mockAuth.mockResolvedValue({ user: { id: 'u1', role: 'user' }, expires: '2099-01-01' } as Session);
    vi.mocked(prisma.user.findUnique).mockResolvedValue({ id: 'u1', role: 'user', bannedAt: null } as never);
    vi.mocked(prisma.post.updateMany).mockResolvedValue({ count: 1 });

    await updatePost(form({ id: postId, title: 'New' }));
    expect(prisma.post.updateMany).toHaveBeenCalledWith({
      where: { id: postId, authorId: 'u1' },
      data: { title: 'New' },
    });
  });
});
```

- Test each action's unauthenticated, wrong-role, wrong-owner, and invalid-input paths, not only the happy path.
- `redirect()` throws: mock `next/navigation` and assert the call. For `useSession` components, wrap them in `<SessionProvider session={mockSession}>` or mock `next-auth/react`.
- For end-to-end tests, sign in once in a Playwright setup project and reuse `storageState`, and test that a signed-out request to a protected action fails.

See [testing.md](testing.md#mocking) for general mocking setup.

## Better Auth as an Alternative

Better Auth is a TypeScript auth library that runs inside the Next.js app with its own database schema and plugins (two-factor, organizations, passkeys). Choose it when the app needs email/password, sessions in its own database, and those plugins without writing them on top of Auth.js. The authorization rules above apply unchanged.

```ts
// lib/auth.ts
import { betterAuth } from 'better-auth';
import { nextCookies } from 'better-auth/next-js';

export const auth = betterAuth({
  // database: your adapter (Drizzle, Prisma, Kysely, or a pg Pool)
  emailAndPassword: { enabled: true },
  socialProviders: {
    github: { clientId: process.env.GITHUB_CLIENT_ID!, clientSecret: process.env.GITHUB_CLIENT_SECRET! },
  },
  plugins: [nextCookies()], // keep last: applies Set-Cookie from Server Actions
});
```

Mount the handler at `app/api/auth/[...all]/route.ts` with `export const { GET, POST } = toNextJsHandler(auth)` (`toNextJsHandler` from `better-auth/next-js`). Read the session with `const session = await auth.api.getSession({ headers: await headers() })` (`headers` from `next/headers`) in Server Components, Server Actions, and Route Handlers.

- Use `createAuthClient` from `better-auth/react` for client calls.
- In the proxy, `getSessionCookie(request)` from `better-auth/cookies` only checks that a cookie exists. Use it for optimistic redirects only. For full validation call `auth.api.getSession` in `proxy.ts` on 16 (Node.js runtime); on 15.5 it needs `runtime: 'nodejs'` (stable since 15.5).
- Server Components cannot set cookies, so session cookie refreshes happen on the next Server Action or Route Handler call.

## Best Practices

| Do | Avoid |
|----|-------|
| `await auth()` or `requireUser()` at the top of every Server Action and Route Handler | Relying on the proxy matcher for authorization |
| Read role and ban status from the DB for sensitive operations | Trusting `token.role` for admin actions |
| Return `null` from `authorize` for any failure | Error messages that reveal whether an email exists |
| Catch `AuthError` and rethrow everything else around `signIn` | A bare `catch {}` that swallows `NEXT_REDIRECT` |
| Restrict `redirectTo` to same-origin paths | Passing a raw `callbackUrl` to `redirect()` |
| Keep the proxy config free of DB and hashing imports | Importing the adapter into `proxy.ts`/`middleware.ts` |
| Rate-limit sign-in and registration | Unlimited password attempts |
