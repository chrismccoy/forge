# Workflow: Review React Code

Review React and framework code against this skill's rules, and report confirmed findings by severity with a fix and a reference for each.

## Contents

- [Instructions](#instructions)
- [1. Inspect the Project](#1-inspect-the-project)
- [2. Review Checklist](#2-review-checklist)
  - [Correctness](#correctness)
  - [React 19 APIs](#react-19-apis)
  - [Server and Client Boundary](#server-and-client-boundary)
  - [Security](#security)
  - [Accessibility](#accessibility)
  - [Performance](#performance)
  - [State Placement](#state-placement)
  - [Forms](#forms)
  - [TypeScript](#typescript)
  - [Testing Gaps](#testing-gaps)
  - [Next.js](#nextjs)
  - [React Router](#react-router)
  - [TanStack Router and Start](#tanstack-router-and-start)
- [3. Severity Scale](#3-severity-scale)
- [4. Verify Before Reporting](#4-verify-before-reporting)
- [5. Output Format](#5-output-format)
- [Related](#related)

## Instructions

1. Inspect the project and fix the review scope (section 1).
2. Walk the checklist (section 2) for the files in scope. Skip categories that do not apply, such as framework sections for a Vite SPA.
3. Rate each candidate finding with the severity scale (section 3).
4. Confirm every finding in the code before reporting it (section 4).
5. Report in the output format (section 5).
6. Do not edit code during a review. Offer to apply the fixes, and apply them only when the user asks.

Judge code by the rules in `SKILL.md` (Guidelines, Safety Rules for Mutating Endpoints, Anti-patterns) and the topic references. Every suggested fix must agree with them. Respect the installed versions: do not suggest React 19 APIs to a React 18 project or Next.js 16 APIs to a 15 project, except as an upgrade note.

## 1. Inspect the Project

**Scope.** Prefer the change under review over the whole app:

```bash
git diff --stat main...HEAD        # branch or PR
git diff --name-only HEAD          # uncommitted work
```

Use the base branch the project actually uses. If there is no git history or the user names files, review those files. For a whole-app review, start with entry points, routes, mutating endpoints, and shared providers, and say what was sampled. Read enough surrounding code (callers, the schema, the auth helper) to judge each changed line.

**Versions and tooling.** Read `package.json` and config files for:

- `react` and `react-dom` major (18 or 19), and whether React Compiler (`babel-plugin-react-compiler`) is enabled
- Framework and major: `next` (15 or 16, and `cacheComponents` in `next.config.*`), `react-router` (7.9+ or 8), `@tanstack/react-router` or `@tanstack/react-start`
- `zod` major (3 or 4), form library, state libraries
- Test runner (Vitest or Jest), Testing Library, MSW
- ESLint config: is `eslint-plugin-react-hooks` on, and are rules disabled or downgraded
- `tsconfig.json`: `strict`, `noUncheckedIndexedAccess`

**Automated signals (optional).** Run the bundled scripts from the project root. Treat their output as leads to check by hand, not as findings: they match patterns and produce false positives.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/check-components.sh .
bash ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/check-hooks.sh .
bash ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/check-testing.sh .
python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/nextjs-analyzer.py   # Next.js only; add --check-version for the installed version
```

If the project has lint, type-check, or test scripts, run them when the user allows it, and report failures in files under review.

## 2. Review Checklist

Each item names what to look for and where the fix lives. Paths are relative to `references/`.

### Correctness

- **Rules of Hooks.** Hooks called conditionally, in loops, after an early `return`, or in plain functions that are not components or `use*` hooks. Fix: [hooks.md](../hooks.md#rules-of-hooks).
- **Effect dependencies.** Missing values in a dependency array, or `// eslint-disable-next-line react-hooks/exhaustive-deps` with no written reason. Objects or functions created during render used as dependencies, so the effect runs every render. Fix: [hooks.md](../hooks.md#useeffect).
- **Derived state in effects.** `useEffect` that sets state computed from props or other state. Compute it during render instead. Fix: [hooks.md](../hooks.md#useeffect).
- **Race conditions.** Fetching in `useEffect` without an `AbortController` or ignore flag, so a slow earlier response overwrites a later one. Prefer a server-state library or a Server Component. Fix: [hooks.md](../hooks.md#useeffect), [state-jotai-and-tanstack-query.md](../state-jotai-and-tanstack-query.md#tanstack-query-react-query).
- **Missing cleanup.** Subscriptions, timers, listeners, observers, or object URLs created in an effect and never released.
- **Stale closures.** Intervals, listeners, or async callbacks that read state captured at creation time. Use a functional update (`setCount((c) => c + 1)`) or a ref that tracks the latest value.
- **Keys.** Array index as `key` in lists that filter, sort, insert, or reorder; keys built from `Math.random()` or that change on unrelated state. Fix: [fundamentals.md](../fundamentals.md#3-key-prop-usage).
- **Mutation.** Sorting or pushing into props or state in place (`items.sort(...)`), so React misses the change.
- **Error and loading states.** Async UI with no error boundary or error state, and no empty state.

```tsx
// Finding: race condition. A slow response for an old id can land last.
useEffect(() => {
  fetch(`/api/users/${id}`).then((r) => r.json()).then(setUser);
}, [id]);
```

### React 19 APIs

Apply only on React 19.

- **`forwardRef` in new code.** In React 19 pass `ref` as a regular prop. Treat existing `forwardRef` as a Nit unless the change touches it. Fix: [typescript.md](../typescript.md#extending-html-element-props), [react-19-upgrade.md](../react-19-upgrade.md#new-apis-to-adopt-after-upgrading).
- **`useActionState` signature.** The action must be `(prevState, formData)` and return the full state shape on every path, including errors. An action that takes only `formData`, or returns `undefined` on success, is a bug. Fix: [hooks-performance-and-react-19.md](../hooks-performance-and-react-19.md#useactionstate).
- **`useOptimistic`.** The setter called outside a transition or form action. Fix: [hooks-performance-and-react-19.md](../hooks-performance-and-react-19.md#useoptimistic).
- **`useFormStatus`.** Called in the same component that renders the `<form>`; it only reads a parent form. Fix: [hooks-performance-and-react-19.md](../hooks-performance-and-react-19.md#useformstatus).
- **`use()` with a promise created during render** in a Client Component. This creates a new promise each render and suspends forever. The promise must come from a Server Component or a cached loader. Fix: [fundamentals.md](../fundamentals.md#the-use-hook).
- **Removed APIs.** `ReactDOM.render`, string refs, `propTypes` or `defaultProps` on function components, legacy context. Fix: [react-19-upgrade.md](../react-19-upgrade.md#breaking-changes).

### Server and Client Boundary

Apply where the framework supports Server Components.

- **`'use client'` too high.** A whole page or layout marked client when only a button or input needs it. Move the directive to the smallest interactive leaf. Fix: [fundamentals.md](../fundamentals.md#composing-server-and-client-components).
- **Server code reachable from the client.** A Client Component importing a module that uses the database, secrets, or `fs`. Data-access modules should `import 'server-only'` (Next.js) or be named `*.server.ts` (React Router, TanStack Start). Fix: [nextjs-data-fetching.md](../nextjs-data-fetching.md#server-component-fetching).
- **Over-sharing props.** A Server Component passing a full database record (password hash, internal flags, other users' data) to a Client Component. Pass only the fields the client renders.
- **Non-serializable props** (functions other than Server Actions, class instances) passed across the boundary.
- **Inline Server Actions in a `'use client'` file.** Actions must live in a `'use server'` module. Fix: [fundamentals.md](../fundamentals.md#server-actions).
- **Hydration mismatches.** `window`, `localStorage`, `Date.now()`, `Math.random()`, or locale formatting read during render of server-rendered code; `typeof window` branches in render; invalid HTML nesting; persisted stores rehydrating on first render; `suppressHydrationWarning` used to hide a real mismatch. Fix: [react-19-upgrade.md](../react-19-upgrade.md#hydration-mismatches), [hooks-custom-library.md](../hooks-custom-library.md#uselocalstorage---persistent-state).

### Security

Check every mutating endpoint against the Safety Rules in `SKILL.md`: Server Actions, Route Handlers, React Router actions and loaders, TanStack server functions, and API routes. Each is a public endpoint that can be called directly, whatever the UI does.

- **Authorization inside the handler.** The handler must re-check the session and ownership itself (`where: { id, ownerId: session.user.id }`). A proxy, middleware, layout check, or route guard alone is a Critical finding when the endpoint reads or writes user data. Fix: [workflows/nextjs-route-handler.md](nextjs-route-handler.md#item-read-update-delete-with-ownership), [nextjs-middleware.md](../nextjs-middleware.md#authentication-gating).
- **Input validation and whitelisting.** Every body, `FormData`, `params`, and `searchParams` value parsed with a Zod schema, and only parsed fields passed to the database. Flag spreading a raw body into a create or update (mass assignment), `Object.fromEntries(formData)` written directly, and unchecked casts of input. Check that schemas use the installed Zod major's API (Zod 4: `z.email()`, `{ error: ... }`). Fix: [nextjs-data-fetching.md](../nextjs-data-fetching.md#reading-and-validating-the-body), [forms.md](../forms.md#with-zod-validation).
- **Idempotency.** Retried mutations with side effects (payments, job submission) must take a client-supplied `Idempotency-Key`, validate it, and store it under a UNIQUE constraint scoped to the user before writing. Flag a server-generated fallback key. Fix: [workflows/nextjs-route-handler.md](nextjs-route-handler.md#retried-mutation-with-an-idempotency-key).
- **Webhooks.** Signature verified as an HMAC over the raw body with `crypto.timingSafeEqual`, stale timestamps rejected, deduplication on the provider's event ID under a UNIQUE constraint, event types dispatched with `satisfies Record<Union, Handler>`. Flag parsing JSON before verifying, `===` on signatures, and sending a shared secret to a caller-supplied URL. Fix: [workflows/nextjs-route-handler.md](nextjs-route-handler.md#signed-webhook-with-hmac), [workflows/nextjs-route-handler.md](nextjs-route-handler.md#stripe-webhook-with-exhaustive-dispatch).
- **Fail closed.** When the handler cannot get a definite answer (unknown ID, provider error, partial data), it must deny or grant nothing. Flag fallbacks to a cached field such as `user.plan`. Fix: [nextjs-caching.md](../nextjs-caching.md#per-user-and-safety-data).
- **XSS.** `dangerouslySetInnerHTML` with user or CMS content that is not sanitized with a maintained sanitizer (for example DOMPurify); `href` or `src` built from user input without rejecting `javascript:` URLs; user data interpolated into inline `<script>` JSON without escaping `<`.
- **Secrets in client bundles.** API keys, database URLs, or signing secrets in files that reach the browser. Any `NEXT_PUBLIC_` (Next.js) or `VITE_` (Vite) variable is public; flag secrets under those prefixes.
- **Tokens in client storage.** Auth tokens in `localStorage`, `sessionStorage`, or a persisted store. Keep them in httpOnly, Secure, SameSite cookies. Fix: [state-zustand.md](../state-zustand.md#domain-specific-stores).
- **Open redirects.** A `redirect`, `next`, or `callbackUrl` parameter used without checking it is a same-origin relative path. Fix: [tanstack-router.md](../tanstack-router.md#authenticated-routes).
- **Leaky errors.** Stack traces, SQL errors, or internal IDs returned to the client from an action or handler.

```ts
// Finding (Critical): no auth check, and the raw body reaches the database.
export async function updateProfile(data: Record<string, unknown>) {
  'use server';
  await db.user.update({ where: { id: data.id as string }, data });
}
```

### Accessibility

- **Clickable non-controls.** `<div onClick>` or `<span onClick>` instead of `<button>`; `<a>` without `href` used as a button; links used for actions.
- **Unlabelled controls.** Inputs without a `<label>`, `aria-label`, or `aria-labelledby`; icon-only buttons without an accessible name; placeholder used as the only label.
- **Form errors.** Errors not tied to the field with `aria-describedby` and `aria-invalid`, or not announced (`role="alert"` or a live region).
- **Images.** Missing `alt`; decorative images without `alt=""`.
- **Dialogs and menus.** No focus move on open, no focus trap, focus not restored on close, Escape does not close. Prefer the native `<dialog>` element or a tested primitive library.
- **Keyboard.** Custom widgets (tabs, listboxes, comboboxes) without arrow-key support or visible focus; positive `tabIndex`.
- **Redundant or wrong ARIA.** `role="button"` on a `<button>`, ARIA roles that contradict the element, `aria-hidden` on focusable content.
- **Dynamic content.** Loading and async results not announced; toasts without `role="status"` or `role="alert"`.
- **Headings and landmarks.** Skipped heading levels, no `<main>`, several unlabelled `<nav>` elements.

Fix and tests: [testing.md](../testing.md#accessibility-testing), [testing-recipes.md](../testing-recipes.md#accessibility-testing), [forms.md](../forms.md#custom-form-components).

### Performance

Report performance only as red flags, not as a demand to memoize. The rule is measure first: do not ask for `memo`, `useMemo`, or `useCallback` without a measured hotspot or a stable-prop boundary, and not at all when React Compiler is enabled. Do not flag inline callbacks or object literals on their own. When a real hotspot needs work, point to the optimize workflow instead of prescribing memoization in the review.

Red flags worth reporting:

- A frequently-changing value (input text, mouse position, timer) in a Context shared by much of the tree. Fix: [state-management.md](../state-management.md#optimizing-context-performance).
- State held far above the component that uses it, so typing re-renders a large page. Fix: [performance.md](../performance.md#state-colocation).
- Hundreds or thousands of rows rendered at once. Fix: [performance-virtualization.md](../performance-virtualization.md).
- Heavy libraries (editors, charts, maps) imported eagerly on a route that rarely uses them. Fix: [performance.md](../performance.md#code-splitting).
- Request waterfalls: sequential `await` calls that do not depend on each other. Fix: [nextjs-data-fetching.md](../nextjs-data-fetching.md#parallel-and-sequential-fetching).
- `memo` wrapping a component whose parent passes new objects or functions every render (the memo does nothing), or `useMemo` around trivial work. Report as Nit.
- `<video>` elements remounted by unstable keys, or playback driven through state instead of refs. Fix: [media-video.md](../media-video.md).

Fix workflow: [workflows/optimize.md](optimize.md).

### State Placement

- Server data copied into `useState` or a client store and kept in sync by hand. Use a server-state library (TanStack Query, SWR) or framework loaders. Fix: [state-management.md](../state-management.md#1-choose-the-right-tool).
- Redundant state that can be derived from props or other state.
- A global store or Context for state used by one component. Keep state local and colocated.
- Persisted stores that cause hydration mismatches, or that persist secrets. Fix: [state-zustand.md](../state-zustand.md#persisted-state-and-server-rendering).
- Zustand selectors that return a new object every call without `useShallow`. Fix: [state-zustand.md](../state-zustand.md#using-useshallow-for-object-selection).
- Mutations that do not invalidate or update the queries they affect, leaving stale UI. Fix: [state-jotai-and-tanstack-query.md](../state-jotai-and-tanstack-query.md#mutations-with-optimistic-updates).

### Forms

- Client validation only, with no server-side validation of the same data. Fix: [forms-server-actions.md](../forms-server-actions.md#server-actions-with-forms).
- Server validation errors not shown to the user.
- Submit not disabled while pending, allowing duplicate submissions.
- Controlled and uncontrolled patterns mixed on one input (`value` without `onChange`, or switching from `undefined` to a string).
- Hand-rolled `loading`/`error` state around a Server Action where `useActionState` fits (React 19).
- React Hook Form schemas and resolver mismatched with the installed Zod major. Fix: [forms.md](../forms.md#with-zod-validation).
- Object URLs from file previews never revoked. Fix: [forms-advanced.md](../forms-advanced.md#file-upload-forms).

### TypeScript

- **`any`** in props, hook returns, API responses, or catch clauses. Use precise types, or `unknown` and narrow. Fix: [typescript.md](../typescript.md#best-practices).
- **Non-null assertions (`!`)** on values that can be null at runtime: `useRef` targets, `find()` results, `document.getElementById`, env vars.
- **Unsafe casts.** `as SomeType` on `request.json()`, `FormData`, URL params, or `JSON.parse` output instead of a schema parse; `as unknown as T` double casts.
- **Loose unions.** Status strings typed as `string` where a discriminated union would catch missing cases. Fix: [typescript-generics-utilities-context.md](../typescript-generics-utilities-context.md#discriminated-unions).
- **Event and ref types.** `any` event handlers, or `useRef()` with no argument on React 19 types. Fix: [typescript.md](../typescript.md#event-handlers), [react-19-upgrade.md](../react-19-upgrade.md#typescript-changes).
- Suppressions (`@ts-ignore`, `@ts-expect-error`) without a reason.

### Testing Gaps

Report missing tests for changed behavior, not a coverage percentage.

- New or changed components and hooks with no tests, or tests that miss the empty, loading, and error states.
- Mutating endpoints with no test for the unauthorized and invalid-input paths.
- Tests that assert internal state, call component methods, or use `container.querySelector` where a role query works. Fix: [testing.md](../testing.md#2-avoid-implementation-details).
- `fireEvent` where `userEvent` fits; `waitFor` wrapping a `getBy` query that `findBy` replaces. Fix: [testing.md](../testing.md#testing-async-components).
- `async` Server Components rendered as JSX in tests. Fix: [testing.md](../testing.md#testing-server-components).
- Network mocked by stubbing `fetch` per test where the project already uses MSW. Fix: [testing-recipes.md](../testing-recipes.md#mocking-api-with-msw).

Fix workflow: [workflows/test.md](test.md).

### Next.js

- **Caching correctness.** Without Cache Components, remember `fetch` is uncached by default since 15; tags alone do not opt in. With `cacheComponents: true`, flag segment config exports (`dynamic`, `revalidate`, `fetchCache`, `dynamicParams`, `runtime`), which are build errors. Fix: [nextjs-caching.md](../nextjs-caching.md#fetch-defaults), [nextjs-caching.md](../nextjs-caching.md#segment-config-and-cache-components).
- **`'use cache'` safety.** A `'use cache'` function that calls `auth()`, `cookies()`, or `headers()`, or returns per-user data without the user ID as an argument. Any cached authorization or entitlement state (session, role, plan, feature gates) is Critical. Fix: [nextjs-caching.md](../nextjs-caching.md#per-user-and-safety-data).
- **Invalidation after mutation.** A Server Action that writes but does not call `updateTag`, `revalidateTag`, or `revalidatePath`; single-argument `revalidateTag(tag)` on 16 (deprecated). Fix: [nextjs-caching.md](../nextjs-caching.md#revalidation).
- **Proxy is not authorization.** Auth checks only in `proxy.ts` or `middleware.ts`, with pages, Route Handlers, or Server Actions trusting that they ran. Also flag `proxy.ts` on 15 (silently ignored), `middleware.ts` on 16 unless the Edge runtime is required (deprecated there), and matchers that skip protected paths. Fix: [nextjs-middleware.md](../nextjs-middleware.md#authentication-gating), [nextjs-middleware.md](../nextjs-middleware.md#matcher-configuration).
- **Async `params` and `searchParams`.** Synchronous access, or types like `{ params: { id: string } }` on 15/16. `searchParams` used without validation. Fix: [nextjs-routing.md](../nextjs-routing.md#async-params-and-searchparams). Check with `python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/migrate-to-nextjs16.py --check`.
- **Prerendered private data.** Drafts or private records returned from `generateStaticParams`. Fix: [nextjs-routing.md](../nextjs-routing.md#generatestaticparams).
- **Route states.** Dynamic segments with no `loading.tsx`, `error.tsx` (must be a Client Component), or `notFound()` path. Fix: [nextjs-routing.md](../nextjs-routing.md#loading-error-and-not-found).
- **Metadata.** `metadata` or `generateMetadata` exported from a Client Component; dynamic pages with a fixed title. Fix: [nextjs-routing.md](../nextjs-routing.md#metadata).
- **Images and fonts.** Raw `<img>` for large or above-the-fold images where `next/image` fits; `next/image` without `width`/`height` or `fill`, causing layout shift; the LCP image not loaded eagerly (`loading="eager"`, `fetchPriority="high"`, or `preload` on Next.js 16; `priority` on 15); fonts loaded from a `<link>` to a font CDN instead of `next/font`; third-party scripts outside `next/script`. Fix: [nextjs-performance.md](../nextjs-performance.md#images), [fonts](../nextjs-performance.md#fonts), [scripts](../nextjs-performance.md#third-party-scripts).
- **Route Handlers.** Missing status codes, unvalidated bodies, permissive CORS on authenticated routes. Fix: [workflows/nextjs-route-handler.md](nextjs-route-handler.md#checklist).

### React Router

- **Loaders and actions authorize themselves.** Every `loader` and `action` that touches user data checks the session and ownership, even when middleware or a parent route already did. Fix: [react-router.md](../react-router.md#auth-gating).
- **Action validation.** `request.formData()` parsed with Zod before use; validation errors returned with `data(..., { status: 400 })`. Fix: [react-router.md](../react-router.md#action-with-form-and-zod-validation).
- **Per-user data cached publicly.** `Cache-Control: public` or `s-maxage` on a loader or `headers` export that depends on the session. Authenticated routes need `private, no-store`, and `Vary: Cookie` behind a shared cache. Also check that a parent's headers are not lost because only the deepest route's `headers` is sent. Fix: [react-router.md](../react-router.md#http-caching-with-headers).
- **Server modules.** Database and secret code outside `*.server.ts` files. Fix: [react-router.md](../react-router.md#route-module-exports).
- **Thrown data.** Internal details in `throw data(...)`, which is sent to the browser as-is. Fix: [react-router.md](../react-router.md#errors).
- **Revalidation.** `shouldRevalidate` returning `false` in a way that leaves stale data after an action. Fix: [react-router.md](../react-router.md#shouldrevalidate).

### TanStack Router and Start

- **Server functions are public endpoints.** Each `createServerFn` that touches private data must authenticate (middleware or an in-handler check), validate input with `.validator()`, and scope reads and writes to the user. Fix: [tanstack-router.md](../tanstack-router.md#server-functions).
- **`beforeLoad` is UX only.** A route guard in `beforeLoad` redirects signed-out users, but it does not protect the server functions or server routes the page calls. Fix: [tanstack-router.md](../tanstack-router.md#authenticated-routes).
- **CSRF.** A custom `src/start.ts` without `createCsrfMiddleware()` registered. Fix: [tanstack-router.md](../tanstack-router.md#start-middleware).
- **Search params.** Search params read without `validateSearch`. Fix: [tanstack-router.md](../tanstack-router.md#typed-search-params).
- **Login state changes.** No `router.invalidate()` and no removal of the previous account's cached queries after login or logout. Fix: [tanstack-router.md](../tanstack-router.md#authenticated-routes).
- **Server code leaks.** Server-only helpers imported outside handlers, or `verbatimModuleSyntax` enabled. Fix: [tanstack-router.md](../tanstack-router.md#server-functions).

## 3. Severity Scale

| Severity | Definition | Examples |
|----------|------------|----------|
| **Critical** | Security hole, data loss or corruption, or a crash in a normal path. Must be fixed before the change ships. | Missing authorization in a mutating endpoint, mass assignment, per-user data in a shared cache, unverified webhook, secret in the client bundle, render crash on empty data |
| **Major** | Wrong behavior users will hit, or a broken contract with this skill's rules, with no direct security impact. Fix before the change ships. | Race condition, missing effect cleanup that leaks, wrong `useActionState` signature, hydration mismatch, missing invalidation after a write, unlabelled form controls, index keys on a reorderable list |
| **Minor** | Maintainability, robustness, or accessibility gaps that do not break the main path. Fix soon. | `any` in props, missing error or empty state, missing tests for changed behavior, a measured performance red flag |
| **Nit** | Style or small clarity improvements. Optional. | Naming, ineffective `memo`, redundant ARIA on a native control, `forwardRef` in untouched React 19 code |

Rate by impact in this codebase, not by category: an `any` on a value that flows into a database write can be Critical. When in doubt between two levels, choose the lower one and say why.

## 4. Verify Before Reporting

Report only findings confirmed in the code. For each candidate:

1. Open the file and the exact line. Read the surrounding function and its callers.
2. Check whether the issue is handled elsewhere: an auth helper the handler calls, a schema parsed in a wrapper, a parent error boundary, a cleanup in a custom hook.
3. Check the version: an API that is wrong on Next.js 16 may be correct on 15.
4. Confirm the fix applies to this codebase and agrees with the references.

Drop anything that cannot be confirmed. Script output, naming, and "this usually means" are not evidence. Prefer a few confirmed findings over a long list of possibilities. If something looks risky but needs missing context (for example, the auth middleware lives in another repository), list it under "Not reviewed" or as an open question, not as a finding.

## 5. Output Format

```markdown
## Review: <scope, e.g. "branch feature/billing (12 files)">

### Critical
- `app/api/invoices/[id]/route.ts:24` — DELETE removes the invoice by ID without checking the owner — any signed-in user can delete any invoice — Add `ownerId: session.user.id` to the `where` clause and return 404 when no row matches (`workflows/nextjs-route-handler.md` → Item: read, update, delete with ownership).

### Major
- `components/SearchResults.tsx:31` — fetch in `useEffect` has no abort or ignore flag — fast typing shows results for an earlier query — Use TanStack Query keyed on the query, or abort in the cleanup (`hooks.md` → useEffect).

### Minor
- ...

### Nit
- ...

### Summary
<2-4 sentences: overall state, the most important fix, any pattern that repeats.>

### Not reviewed
<Files, areas, or checks skipped and why: generated files, out-of-scope packages, tests not run, behavior that needs runtime verification.>
```

Rules for the report:

- One finding per line: `path:line — problem — why it matters — fix (reference)`. Group repeats of the same issue into one finding listing every location.
- Omit empty severity sections.
- Show a short code fix only when the one-line fix is ambiguous.
- If there are no findings, say so, and still list what was not reviewed.
- End by offering to apply the fixes, starting with Critical. Do not change files until the user agrees.

## Related

- [workflows/optimize.md](optimize.md): measured performance fixes
- [workflows/test.md](test.md): writing the missing tests
- [workflows/nextjs-route-handler.md](nextjs-route-handler.md#checklist): endpoint checklist
- [workflows/nextjs-page.md](nextjs-page.md#checklist): page checklist
- [react-19-upgrade.md](../react-19-upgrade.md): breaking changes, React Compiler, hydration
