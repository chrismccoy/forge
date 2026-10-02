# TYPESCRIPT facts
Covers: Next.js (App Router), Prisma, Auth.js (next-auth), NestJS, React Native (Expo), Node.js/TypeScript runtime
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Next.js caching and rendering

### TS-01 Caching and prerendering differ by major
- Trap: "fetch and GET handlers are cached" (14 only), or "uncached in 15, so a page's Prisma query runs per request."
- Reality: 14: fetch cached (force-cache), GET handlers static, Router Cache keeps dynamic pages 30s; 15+ drops all three, but a route using no request-time API (`cookies`, `headers`, `searchParams`, `connection()`) is still prerendered at `next build`, so its queries run once. 16: `cacheComponents` (`'use cache'`) is opt-in and removes `dynamic`/`revalidate`/`fetchCache`.
- Detect: no Next.js major in the caching plan; dashboards in Server Components with no revalidation.
- Fix: Pin the major; opt in to caching explicitly; `await connection()` before per-request queries, or `revalidate`.
- Source: Upgrading to version 15 - https://nextjs.org/docs/app/guides/upgrading/version-15 ; connection - https://nextjs.org/docs/app/api-reference/functions/connection

### TS-02 NEXT_PUBLIC_ values are frozen at build
- Trap: One image promoted across environments with different `NEXT_PUBLIC_*` values, or a secret with that prefix.
- Reality: `NEXT_PUBLIC_` values are inlined into the browser bundle at `next build`; others stay server-only.
- Detect: "build once, deploy everywhere"; `NEXT_PUBLIC_*KEY`/`SECRET`.
- Fix: Build per environment or serve runtime config from the server.
- Source: Environment Variables - https://nextjs.org/docs/app/guides/environment-variables

### TS-03 Next.js 15/16 breaking APIs
- Trap: Sync `cookies()`, `headers()`, `params`; Edge `middleware.ts`.
- Reality: 15 made them async; 16 removes sync access, renames `middleware` to `proxy` (Node.js runtime only), needs Node 20.9+, builds with Turbopack (a custom `webpack` config fails `next build`) and removes `next lint`.
- Detect: `const { id } = params`; `cookies().get`.
- Fix: `await` request APIs; name the major; use `proxy.ts` on 16.
- Source: Upgrading to version 16 - https://nextjs.org/docs/app/guides/upgrading/version-16

### TS-04 page/layout/route files allow only specific exports
- Trap: Helpers exported from `page.tsx`; `page.tsx` and `route.ts` in one folder.
- Reality: `next build` fails on page/layout exports other than `default`, `metadata`, `generateMetadata`, `viewport`, `generateStaticParams` and segment config (routes: HTTP methods plus config). `route.js` cannot share a segment with `page.js`. `'use server'` files export only async functions.
- Detect: helper exports in a page; `app/x/{page.tsx,route.ts}`.
- Fix: Shared code in `lib/`; APIs under `app/api/`.
- Source: Route Handlers - https://nextjs.org/docs/app/getting-started/route-handlers ; next-types-plugin - https://github.com/vercel/next.js/blob/canary/packages/next/src/build/webpack/plugins/next-types-plugin/index.ts

## Next.js auth and Server Actions

### TS-05 Layouts and proxy are not a security boundary
- Trap: "The /admin layout checks the session"; "middleware protects all routes".
- Reality: Layouts do not re-render on navigation or stop child segments rendering. Proxy is for optimistic cookie checks only. Server Actions accept direct POSTs even if no UI uses them.
- Detect: auth only in `layout.tsx` or `middleware.ts`/`proxy.ts`; actions without a session check.
- Fix: Check auth and ownership in a server-only data layer and in every Server Action and Route Handler.
- Source: Data Security - https://nextjs.org/docs/app/guides/data-security ; Authentication - https://nextjs.org/docs/app/guides/authentication

### TS-06 Server Action limits
- Trap: Uploads, bulk imports or parallel reads through Server Actions.
- Reality: Body limit 1 MB by default (`serverActions.bodySizeLimit`); actions run one at a time per client.
- Detect: uploads, imports, `Promise.all` over actions.
- Fix: Upload direct to storage; read via Server Components or Route Handlers.
- Source: serverActions - https://nextjs.org/docs/app/api-reference/config/next-config-js/serverActions ; Server Actions - https://nextjs.org/docs/app/guides/server-actions

### TS-07 Self-hosted Next.js on several instances
- Trap: ECS/K8s replicas treated like Vercel.
- Reality: Self-hosted, the ISR/data cache is on each instance's disk; each build makes a new Server Actions encryption key.
- Detect: several containers; `revalidateTag` with no shared cache.
- Fix: Shared `cacheHandler`, fixed `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`, one build on every instance.
- Source: Self-Hosting - https://nextjs.org/docs/app/guides/self-hosting

### TS-08 Auth.js v5 status and session/provider rules
- Trap: "next-auth v5 is stable"; `NEXTAUTH_*` vars; Credentials with database sessions; magic links, no adapter.
- Reality: v5 is still `next-auth@beta` (`latest` is 4.24.x). Auth.js is now part of Better Auth, which it recommends for new projects. v5 reads `AUTH_*` vars (only `AUTH_SECRET` required). Credentials works only with JWT sessions. Email/magic-link needs an adapter and its verification-token table.
- Detect: `next-auth@5` as stable; Credentials with `strategy: 'database'`; Email, no adapter.
- Fix: Pin the beta knowingly or use Better Auth; JWT with Credentials; adapter for email.
- Source: Migrating to v5 - https://authjs.dev/getting-started/migrating-to-v5 ; Credentials - https://authjs.dev/reference/core/providers/credentials

## Prisma

### TS-09 Prisma 7 layout; npm now installs 8 RC
- Trap: v6 setup (`url`/`directUrl` in schema, auto-generate and seed).
- Reality: v7 needs a driver adapter, generator `output`, URLs in `prisma.config.ts` and Node 20.19+; it neither loads `.env` nor auto-runs `generate`/seed. `npm install prisma` now gives the v8 RC, which lacks `migrate dev`, `generate` and isolation levels.
- Detect: unpinned `prisma`; schema `url = env(...)` on v7.
- Fix: Pin `prisma@7` and `@prisma/client@7`; follow the v7 layout.
- Source: Upgrade to v7 - https://www.prisma.io/docs/guides/upgrade-prisma-orm/v7 ; Release status - https://www.prisma.io/docs/orm/release-status

### TS-10 1:1 relation needs @unique on the FK
- Trap: `userId Int` with `@relation` described as one-to-one.
- Reality: Without a unique FK it is 1:n; Prisma requires `@unique` for 1:1.
- Detect: "one profile per user", no `@unique`.
- Fix: `userId Int @unique`.
- Source: One-to-one relations - https://www.prisma.io/docs/orm/v7/prisma-schema/data-model/relations/one-to-one-relations

### TS-11 $transaction does not prevent races
- Trap: `$transaction` makes read-then-update safe; long work inside it.
- Reality: Isolation is the DB default (PostgreSQL READ COMMITTED): two transactions can read one balance and both write (DATA-01). Interactive defaults: `maxWait` 2 s, `timeout` 5 s.
- Detect: find-then-update of stock, seats or balances; API calls inside `$transaction`.
- Fix: Atomic `increment`/`decrement`, conditional `updateMany`, `SELECT ... FOR UPDATE`, or Serializable with P2034 retries. Keep transactions short.
- Source: Transactions - https://www.prisma.io/docs/orm/v7/prisma-client/queries/transactions

### TS-12 Pools, PgBouncer and migrations
- Trap: Default pools per serverless instance; `migrate dev`/`db push` at deploy or via a pooler.
- Reality: Each instance has its own pool (v6 `connection_limit` CPUs×2+1; v7 `pg` adapter `max` 10). PgBouncer needs transaction mode (`pgbouncer=true` only below 1.21); Migrate cannot use it. `migrate dev` needs a shadow DB and may reset data; never use it in production.
- Detect: Vercel/Lambda, no pooler; one URL for app and migrations; `migrate dev` in CI, Dockerfile or start command.
- Fix: Pooled URL for the app, direct URL for Migrate; pool × instances < `max_connections`; `migrate deploy` as a release step.
- Source: Connection pool - https://www.prisma.io/docs/orm/v7/prisma-client/setup-and-configuration/databases-connections/connection-pool ; PgBouncer - https://www.prisma.io/docs/orm/v7/prisma-client/setup-and-configuration/databases-connections/pgbouncer ; Development and production - https://www.prisma.io/docs/orm/v7/prisma-migrate/workflows/development-and-production

## NestJS

### TS-13 Providers are singletons; REQUEST scope spreads
- Trap: Per-request state in service fields, or request-scoped providers everywhere.
- Reality: Default scope is a singleton shared across requests. REQUEST scope bubbles up to every dependent and costs performance; gateways, Passport strategies and cron jobs cannot use it.
- Detect: `this.currentUser =` in a service; `Scope.REQUEST` on core services.
- Fix: Stateless singletons; request context via AsyncLocalStorage or durable providers.
- Source: Injection scopes - https://docs.nestjs.com/fundamentals/injection-scopes

### TS-14 Request lifecycle order
- Trap: A guard reads the validated DTO; `useGlobalGuards` guards with injected services.
- Reality: Order: middleware, guards, interceptors, pipes, handler. Guards see the unvalidated body. `useGlobalGuards()` guards cannot inject dependencies.
- Detect: authorization using pipe output; `useGlobalGuards(new X(service))`.
- Fix: Authorize from the request/user in guards; register global guards via `APP_GUARD`.
- Source: Request lifecycle - https://docs.nestjs.com/faq/request-lifecycle ; Guards - https://docs.nestjs.com/guards

### TS-15 Webhook raw body in NestJS
- Trap: Verifying HMAC signatures over `JSON.stringify(req.body)`.
- Reality: Re-serialized JSON is not byte-identical (SVC-04). Nest keeps raw bytes as `req.rawBody` only with `NestFactory.create(App, { rawBody: true })`.
- Detect: signature checks with no `rawBody` option.
- Fix: Enable `rawBody` and verify against it.
- Source: Raw body - https://docs.nestjs.com/faq/raw-body

### TS-16 NestJS 12 ships ESM-only packages
- Trap: Nest 12 as a drop-in on Node 18 or plain Lambda.
- Reality: CommonJS apps need `require(esm)` (Node 20.19+/22.12+); Lambda disables it unless `NODE_OPTIONS=--experimental-require-module`. Jest loads v12 only on Node 24.9+.
- Detect: Nest 12 with old Node, Lambda or Jest.
- Fix: Pin the Nest major; match Node, Lambda flag and test runner.
- Source: Migration guide - https://docs.nestjs.com/migration-guide

## Node.js and TypeScript runtime

### TS-17 Running .ts directly on Node
- Trap: "Node runs TypeScript, so no build step" for NestJS or code with enums and path aliases.
- Reality: Node 22.18+ strips erasable types only: enums, runtime namespaces, parameter properties and decorators fail; `tsconfig` `paths` are ignored; imports need extensions; `.ts` in `node_modules` is refused.
- Detect: `node src/main.ts` with decorators, `enum`, `@/` imports.
- Fix: Keep a `tsc`/SWC build, or use `erasableSyntaxOnly` and explicit extensions.
- Source: Modules: TypeScript - https://nodejs.org/api/typescript.html

## React Native

### TS-18 Background tasks are not a scheduler
- Trap: "Sync every 5 minutes in the background", even after the app is closed.
- Reality: Android WorkManager's minimum interval is 15 min; iOS picks the time (often overnight). A killed app (iOS swipe-away) runs no tasks.
- Detect: exact intervals or background sync SLAs.
- Fix: Best effort only; server push or foreground sync for deadlines.
- Source: BackgroundTask - https://docs.expo.dev/versions/latest/sdk/background-task/

### TS-19 Native changes: OTA limits, New Architecture only
- Trap: Features or native modules shipped over the air; legacy-architecture libraries or `newArchEnabled=false`.
- Reality: EAS Update replaces JS, styling and images only; native changes need a new binary and `runtimeVersion`. Apple guideline 2.5.2 bars downloaded code changing features. New Architecture is default since RN 0.76 and cannot be disabled from 0.82.
- Detect: "ship features via OTA"; OTA after adding a native library.
- Fix: OTA for fixes only; store review for native or feature changes; vet native libraries first.
- Source: EAS Update - https://docs.expo.dev/eas-update/introduction/ ; App Review Guidelines - https://developer.apple.com/app-store/review/guidelines/ ; React Native 0.82 - https://reactnative.dev/blog/2025/10/08/react-native-0.82
