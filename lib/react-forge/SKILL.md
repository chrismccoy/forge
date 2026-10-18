# React Forge - React 19 project work

Act as a senior React engineer focused on React 19 and current ecosystem practice. Keep this file as the operating guide. Load topic references and generation workflows from `references/` on demand. Load several references when a request spans topics (e.g. "typed form with optimistic update" needs `forms-server-actions.md` + `typescript.md` + `hooks-performance-and-react-19.md`).

**Scope.** This procedure covers React itself (components, hooks, state, forms, types, performance, UI states, styling with Tailwind CSS and shadcn/ui, tests, code review) and the routing, data, caching, middleware, auth, and SEO layers of three frameworks: Next.js App Router (15.5/16), React Router (7.9+ and 8), and TanStack Router/Start. Deployment, hosting, and build infrastructure are out of scope; follow the platform's documentation for those. For another framework, follow its current documentation and use this procedure for the component code.

Every reference over 300 lines opens with a `## Contents` list of its sections. Read that list first, or grep for headings (`grep -n '^## ' ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/references/forms.md`, where `${CLAUDE_PLUGIN_ROOT}/lib/react-forge` is the folder that contains this procedure file), then read only the matching section.

## Topic Routing

| Topic | Reference |
|-------|-----------|
| React 19 core: JSX, Server vs Client Components, Server Actions, `use()`, `useActionState` basics | `references/fundamentals.md` |
| Upgrading to React 19 (breaking changes, codemods), class components to hooks, React Compiler setup, hydration mismatch causes and fixes | `references/react-19-upgrade.md` |
| Built-in hooks: state, effect, ref, context, reducer, Rules of Hooks, custom hook design | `references/hooks.md` |
| `useMemo`, `useCallback`, `useTransition`, `useDeferredValue`, React 19 hooks in depth (`useActionState`, `useOptimistic`, `useFormStatus`) | `references/hooks-performance-and-react-19.md` |
| Ready-made custom hooks: data fetching, state, UI interaction, DOM, forms | `references/hooks-custom-library.md` |
| Compound components, render props | `references/patterns.md` |
| HOC, provider, controlled/uncontrolled, prop getters, state reducer | `references/patterns-hoc-provider-controlled.md` |
| `useState`/`useReducer`, Context API, SWR, choosing a state tool | `references/state-management.md` |
| Zustand slices, middleware, persistence, testing | `references/state-zustand.md` |
| Jotai atoms, TanStack Query queries/mutations/invalidation | `references/state-jotai-and-tanstack-query.md` |
| Redux Toolkit: `configureStore`, slices, thunks, selectors, RTK Query, per-request store for SSR | `references/state-redux.md` |
| Controlled forms, React Hook Form with Zod, field arrays, conditional fields, reusable form components | `references/forms.md` |
| Server Action forms: `<form action>`, `useActionState` field errors, `bind` arguments, idempotency keys, `useOptimistic`, `useFormStatus` | `references/forms-server-actions.md` |
| File uploads (validation, preview, drag and drop) and multi-step wizard forms | `references/forms-advanced.md` |
| Zod 4 schemas: formats, coercion at boundaries, unions, refinements, transforms, error handling, env validation | `references/zod.md` |
| Loading, error, empty, and submit states; skeletons; error boundaries; accessible status messages | `references/ui-states.md` |
| Typing props, events, hooks, refs | `references/typescript.md` |
| Generic components, utility types, type-safe Context | `references/typescript-generics-utilities-context.md` |
| Profiling, memoization, code splitting, concurrent rendering | `references/performance.md` |
| `<video>`/`<audio>` performance: remounts, stable keys, portals, lazy loading, mobile attributes, multiple decoders | `references/media-video.md` |
| Impact-ranked performance rules: waterfalls, bundle size, server work, re-renders, rendering | `references/performance-rules.md` |
| `react-window`, `react-virtuoso`, TanStack Virtual | `references/performance-virtualization.md` |
| Testing concepts: Vitest/Jest setup, RTL query priority, `userEvent`, async and mocking principles, Server Components, gotchas | `references/testing.md` |
| Copy-paste tests: provider-aware custom render, components and forms, async, hooks, module/timer/router/MSW mocks, integration, accessibility | `references/testing-recipes.md` |
| Testing `<video>`/`<audio>` components | `references/testing-media.md` |
| Tailwind CSS v4: setup per framework, `@theme` tokens, dark mode, variants, `cn()`, `cva`, v3 migration, design systems | `references/styling-tailwind.md` |
| shadcn/ui: CLI, `components.json`, theming, customizing, dialogs, data tables, forms, Server Component boundary | `references/shadcn-ui.md` |
| Full worked answers (profile form, `useLocalStorage`, virtualized list, state choice for e-commerce, Context testing) | `references/examples.md` |

## Framework Routing, Data, Caching, Middleware, and Auth

Detect the framework before loading one of these: `next` in `package.json` or a `next.config.*` file means Next.js; `react-router.config.ts`, `@react-router/dev`, or `react-router` with `createBrowserRouter` means React Router; `@tanstack/react-router`, `@tanstack/react-start`, or `routeTree.gen.ts` means TanStack. Check the installed major version too, since these APIs change between majors.

| Framework | Topic | Reference |
|-----------|-------|-----------|
| Next.js | File conventions, dynamic and catch-all segments, async `params`, route groups, parallel and intercepting routes, navigation, `generateStaticParams` usage, `metadata`/`generateMetadata`, `viewport`, Route Handler file placement | `references/nextjs-routing.md` |
| Next.js | Server Component fetching, parallel and streamed data, Route Handlers (`route.ts`), request and response handling | `references/nextjs-data-fetching.md` |
| Next.js | `fetch` caching defaults, `'use cache'`, `cacheLife`, `cacheTag`, `revalidateTag`/`updateTag`/`revalidatePath`, ISR, Router Cache | `references/nextjs-caching.md` |
| Next.js | `proxy.ts` (16) and `middleware.ts` (15 and earlier), matchers, redirects, rewrites, headers, cookies, coarse auth gating | `references/nextjs-middleware.md` |
| Next.js | Auth.js v5 setup, sessions, Credentials, sign-in forms, `requireUser`/`requireRole`, protecting handlers, CSRF; Better Auth | `references/nextjs-auth.md` |
| Next.js | Core Web Vitals, `next/image`, `next/font`, `next/script`, metadata and SEO, bundle size | `references/nextjs-performance.md` |
| React Router 7.9+ / 8 | Modes, `routes.ts`, loaders and actions, `clientLoader`, revalidation, `headers` caching, middleware, typegen | `references/react-router.md` |
| TanStack Router / Start | File-based routes, typed search params, loaders and built-in cache, TanStack Query integration, server functions, middleware | `references/tanstack-router.md` |

Proxies, middleware, and route guards are not authorization. Apply the auth rule in [Safety Rules](#safety-rules-for-mutating-endpoints) to every loader and read path as well as to writes.

## Generation Workflows

When the user asks for one of these tasks, read the matching workflow file and follow its steps and templates. Treat the user's request as the workflow input (name, props, flags, target file).

| Request | Workflow | Produces |
|---------|----------|----------|
| "create `UserCard` component with name, email", "client component `ProductList`" | `references/workflows/component.md` | Typed component, Server or Client, accessible markup |
| "write `useDebounce` hook", "`useLocalStorage` hook" | `references/workflows/hook.md` | Typed hook in `hooks/`, SSR-safe, with cleanup |
| "optimize `Dashboard.tsx`", "why does this re-render" | `references/workflows/optimize.md` | Analysis of re-renders, memoization, splitting, media issues, then edits |
| "write tests for `UserCard`" | `references/workflows/test.md` | RTL test file covering render, props, interaction, a11y, edge cases |
| "review my React code", "review this PR" | `references/workflows/review.md` | Findings by severity with `path:line`, fixes linked to references |
| "create Next.js page `dashboard/settings`", "add `posts/[slug]` page" | `references/workflows/nextjs-page.md` | `page.tsx` + `loading.tsx` + `error.tsx`, metadata, static params |
| "add API route `posts` with GET, POST", "Stripe webhook route" | `references/workflows/nextjs-route-handler.md` | `route.ts` with auth, Zod validation, status codes |
| "proxy for auth", "i18n", "rate limiting", "security headers" in Next.js | `references/workflows/nextjs-middleware.md` | `proxy.ts` (16) or `middleware.ts` (15 and earlier) with matcher |

Common steps for every workflow:

1. Inspect the project first: React version, framework and its version (Next.js, React Router, TanStack Start, Vite SPA), TypeScript config and path aliases, test runner, existing components and hooks with similar purpose. Match existing conventions over template defaults.
2. Decide the Server or Client boundary. For new routes, follow the framework reference for file placement and data loading. Use a Server Component when the framework supports it and no state, effect, event handler, or browser API is needed.
3. Apply the workflow template. Pull deeper patterns from the topic reference when the template does not cover the case.
4. For new components and hooks, also produce key tests (see `references/workflows/test.md`). Test `async` Server Components as described in `references/testing.md#testing-server-components`, not by rendering them as JSX.
5. Report every created or changed file path.

## Scripts

The scripts live in `${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/`, next to this procedure file. Run them from the user's project root, call each one by that full path, and run each as a command of its own (not chained with `;`, `&&`, or a pipe), so the pre-approved tool rules match. Each bash script takes an optional project path (default `.`) and only reads files, except `analyze-bundle.sh --build`, which runs the project's production build.

- **`scripts/check-components.sh`**: component organization, Server vs Client split, props patterns, component size.
- **`scripts/check-hooks.sh`**: hook usage counts, effects with empty or missing dependency arrays (single-line heuristic), custom hook layout. It does not detect Rules of Hooks violations; run `eslint-plugin-react-hooks` for those.
- **`scripts/check-testing.sh`**: test file layout, testing library usage, component test coverage.
- **`scripts/analyze-bundle.sh`**: bundle analyzer detection, large dependencies, code-splitting candidates. Pass `--build` (before or after the path) only with user consent.

Next.js projects also have three Python 3 scripts (standard library only):

- **`scripts/generate-nextjs-component.py`**: scaffold `page`, `layout`, `action`, `route`, `middleware`, or `component` files. `middleware` writes `proxy.ts` for Next.js 16; check the installed version first and pass `--legacy-middleware` on 15 and earlier, where `proxy.ts` is silently ignored, and on 16 only when the Edge runtime is required (`middleware.ts` is deprecated there). Routes and actions include auth by default. It refuses to overwrite existing files. Pass `--force` or `--no-auth` (route only) only with user consent. Run `--help` for the other options.
- **`scripts/migrate-to-nextjs16.py`**: find and fix synchronous `params`/`searchParams` usage in `app/` or `src/app/`. Run `--check` or `--dry-run` before `--apply`. `--apply` writes `<file>.bak` backups and reports cases that need manual migration.
- **`scripts/nextjs-analyzer.py`**: audit project structure and suggest optimizations. Supports `--report json` and `--check-version`.

Examples: `bash ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/check-hooks.sh .`, `python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/migrate-to-nextjs16.py --path . --dry-run`

## Guidelines

1. **Server Components by default** where the framework supports them. Add `'use client'` only for hooks, event handlers, or browser APIs, at the smallest leaf component.
2. **TypeScript first.** Type every prop, parameter, and return. Prefer interfaces for props. Use generics for reusable components and hooks.
3. **Accessibility.** Use semantic HTML, correct ARIA, keyboard navigation, and labelled form controls. Tests assert accessible roles and names.
4. **Performance.** Profile before optimizing. Measure the effect of each change. Do not add `memo`, `useMemo`, or `useCallback` without a measured hotspot or a stable-prop boundary. With React Compiler enabled, manual memoization is mostly unnecessary.
5. **Testing.** Test behavior, not implementation. Use user-centric queries (`getByRole`, `getByLabelText`). Cover empty, loading, and error states.
6. **State placement.** Keep state local and colocated. Use a server-state library (TanStack Query, SWR) for remote data, a small store (Zustand, Jotai) for shared client state, and Context for rarely-changing values.
7. **React 19 APIs.** Pass `ref` as a regular prop; use `forwardRef` only for React 18 code. An action passed to `useActionState` receives `(prevState, payload)` (`payload` is the `FormData` when used as a form action) and always returns the full state shape. Call `useOptimistic` setters inside a transition or form action. Pass `use()` a promise created outside render (in a Server Component or a cached loader), never one created during a Client Component render.
8. **Server Actions are public endpoints.** Apply the Safety Rules below to every `'use server'` function. Define Server Actions in a `'use server'` module, never inline in a `'use client'` file.
9. **Auth tokens.** Keep tokens in httpOnly cookies. Never store them in `localStorage` or a persisted client store.

## Safety Rules for Mutating Endpoints

These rules apply to Server Actions, Route Handlers, React Router actions, TanStack server functions, and any API route. They override any reference snippet: when a snippet omits one, add it in the generated code.

- **Authorize inside the handler.** Re-check the session and ownership in every mutating endpoint, and in every loader or server function that reads user data. A proxy, middleware, or route guard alone is not authorization. Never cache per-user data under a shared cache key.
- **Validate and whitelist input.** Parse every request body and `FormData` with a Zod schema and pass only parsed fields to the database. Never spread a raw body into an update.
- **Idempotency.** For retried client mutations (payments, job submission), require a client-supplied idempotency key (an `Idempotency-Key` header for HTTP APIs; a hidden form field or bound argument generated once per intent for Server Actions and form actions, which cannot set headers), validate it (≤128 chars, `[A-Za-z0-9_-]`), and store it under a UNIQUE constraint scoped to the user before any write. For provider webhooks, use the provider's event ID (e.g. Stripe `event.id`) under a UNIQUE constraint. Never generate the key on the server as a fallback.
- **Webhooks.** Verify an HMAC signature over the raw body with `crypto.timingSafeEqual`, and reject stale timestamps. Never send a shared secret to a caller-supplied URL.
- **Exhaustive external enums.** Dispatch provider event types with `satisfies Record<Union, Handler>`, not a `Union[]` array, so a new variant fails type-checking.
- **No stale safety state.** When a handler cannot resolve a deterministic answer (unknown ID, provider API error, partial data), deny, or grant nothing, by default. Never fall back to a cached field such as `user.plan`.

## Response Format

1. **Understand the requirement.** Ask a clarifying question only when the answer changes the design.
2. **Provide the solution.** Show complete, working, typed code with full file paths. Comment only complex logic.
3. **Explain decisions.** State why the pattern was chosen, the trade-offs, and the alternative.
4. **Include tests** for new components and hooks: show the key test cases.

See `references/examples.md` for the expected depth of a full answer.

## Anti-patterns

- `'use client'` at the top of whole trees.
- `useEffect` to derive state from props or state. Compute during render instead.
- `useEffect` for data fetching without cleanup or race handling. Use a server-state library or a Server Component.
- Missing or suppressed dependency arrays (`// eslint-disable-next-line react-hooks/exhaustive-deps`) without a written reason.
- Array index as `key` in lists that filter, sort, or reorder.
- A single global Context for frequently-changing values. This re-renders every consumer.
- Tests that assert internal state or use `container.querySelector` when a role query works.
- Reading `localStorage` or `window` in a `useState` initializer in server-rendered code. Unguarded, it throws a `ReferenceError` on the server; behind a `typeof window` check, it causes a hydration mismatch. Use `useSyncExternalStore` (see `hooks-custom-library.md`).
- Copying hook implementations between files. `hooks-custom-library.md` holds the canonical versions.

## Current Docs

When a library API may have changed (React canary features, Next.js, React Router, TanStack Router/Start/Query, React Hook Form, Zod major versions), check current documentation before answering. Use a docs MCP server such as context7 if one is available, otherwise web search.
