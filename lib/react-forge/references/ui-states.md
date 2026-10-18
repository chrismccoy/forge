# UI States: Loading, Error, Empty, and Pending

Patterns for the loading, error, empty, and submitting states of React 19 components, with accessible markup. Load it when building any component that shows async data or triggers a mutation, or when reviewing one for missing states.

## Contents

- [Principles](#principles)
- [State Order](#state-order)
- [Loading](#loading)
- [Errors](#errors)
- [Empty States](#empty-states)
- [Buttons and Form Submission](#buttons-and-form-submission)
- [Optimistic Updates](#optimistic-updates)
- [Accessibility](#accessibility)
- [Checklist](#checklist)

## Principles

1. Show a loading indicator only when there is nothing to show yet. Keep existing data on screen during refetches.
2. Never swallow an error. Every failure the user caused or waits on gets a visible message and, where possible, a retry.
3. Every collection has an empty state that says what to do next.
4. Every trigger of an async action shows that it is pending and cannot fire twice.
5. Partial data beats no data: render what loaded and isolate what failed.

## State Order

Check states in this order. Getting the order wrong is the usual cause of spinners flashing over cached data and of empty states shown during the first load.

```tsx
'use client';
import { useQuery } from '@tanstack/react-query';

export function ProjectList() {
  const { data, error, isPending, isFetching, refetch } = useQuery({
    queryKey: ['projects'],
    queryFn: fetchProjects,
  });

  if (isPending) return <ProjectListSkeleton />;                      // nothing yet
  if (data === undefined) return <ErrorState onRetry={() => void refetch()} />; // failed, nothing cached
  if (data.length === 0) return <EmptyProjects />;                     // loaded, but empty

  return (
    <section aria-busy={isFetching}>
      {error ? <InlineWarning message="Showing saved results. Refresh failed." onRetry={() => void refetch()} /> : null}
      <ul>{data.map((p) => <li key={p.id}>{p.name}</li>)}</ul>
    </section>
  );
}
```

```tsx
// Wrong: replaces the list with a spinner on every background refetch
if (isFetching) return <Spinner />;
```

In TanStack Query 5, `isPending` means "no data yet" and `isFetching` covers any request, including background ones. RTK Query uses `isLoading` and `isFetching` the same way; SWR uses `isLoading` and `isValidating`.

## Loading

### Skeleton or spinner

| Use a skeleton when | Use a spinner when |
|---------------------|--------------------|
| The content's shape is known (list, card, table) | The shape is unknown or tiny |
| It is the first load of a page or section | An action is running inside a button or dialog |
| Layout shift must be avoided | The wait is a single inline operation |

Size skeletons to match the real content so nothing jumps when data arrives. Mark skeletons `aria-hidden="true"` and announce loading once through a status region (see [Accessibility](#accessibility)).

### Avoid flashes for fast responses

A spinner that appears for 80 ms reads as a glitch. Delay it, and once shown, keep it long enough to be seen.

```tsx
'use client';
import { useEffect, useState } from 'react';

export function DelayedSpinner({ delayMs = 300, label = 'Loading' }: { delayMs?: number; label?: string }) {
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const id = setTimeout(() => setVisible(true), delayMs);
    return () => clearTimeout(id);
  }, [delayMs]);

  // The status container stays mounted so the announcement fires when text appears
  return <div role="status">{visible ? (<><span className="spinner" aria-hidden="true" /><span className="sr-only">{label}…</span></>) : null}</div>;
}
```

Use it as a Suspense fallback or for an `isPending` state.

### Suspense boundaries

Put a `<Suspense>` boundary around each independently loading region, not one around the whole page. In the Next.js App Router, `loading.tsx` is a route-level boundary; nested boundaries stream smaller parts. See [nextjs-data-fetching.md](nextjs-data-fetching.md) (Streaming with Suspense).

### Keep the old UI during updates with transitions

When a navigation or filter change would suspend an already visible boundary, React would normally swap the content for the fallback. Wrap the update in a transition and React keeps showing the previous UI while the new one prepares. Dim it to show it is stale.

```tsx
'use client';
import { Suspense, useState, useTransition } from 'react';

type Tab = 'overview' | 'activity';

export function ProjectTabs() {
  const [tab, setTab] = useState<Tab>('overview');
  const [isPending, startTransition] = useTransition();

  function select(next: Tab) {
    startTransition(() => setTab(next));
  }

  return (
    <>
      <div role="tablist" aria-label="Project sections">
        {(['overview', 'activity'] as const).map((t) => (
          <button key={t} role="tab" aria-selected={tab === t} onClick={() => select(t)}>
            {t}
          </button>
        ))}
      </div>
      <div role="tabpanel" aria-busy={isPending} style={{ opacity: isPending ? 0.6 : 1 }}>
        <Suspense fallback={<PanelSkeleton />}>
          {tab === 'overview' ? <Overview /> : <ActivityFeed />}
        </Suspense>
      </div>
    </>
  );
}
```

The fallback still shows on the first load of the boundary; transitions only prevent hiding content that is already visible. For a lagging copy of a fast-changing value (search input), use `useDeferredValue` instead (see [hooks-performance-and-react-19.md](hooks-performance-and-react-19.md)).

## Errors

### Hierarchy

Pick the smallest surface that matches the scope of the failure.

| Level | Use for | Component |
|-------|---------|-----------|
| Inline, at the field | Validation errors for one input | Text linked with `aria-describedby`, `aria-invalid` on the input |
| Inline, at the section | One widget failed, rest of the page works | Message plus retry inside the section |
| Toast or banner | A background or one-off action failed and can be retried | Live-region notification with an action |
| Error boundary | A render-time error in a subtree | Fallback with retry around that subtree |
| Full page | The route cannot render at all (not found, forbidden, outage) | `error.tsx` / `not-found.tsx` in Next.js, route `ErrorBoundary` in React Router |

Field-level validation with React Hook Form and Zod lives in [forms.md](forms.md). Route-level files: [nextjs-routing.md](nextjs-routing.md) and [react-router.md](react-router.md).

### Always surface errors

```ts
// Wrong: the user sees nothing
try {
  await saveDraft(draft);
} catch (err) {
  console.error(err);
}

// Right: log for developers, tell the user, offer a way forward
try {
  await saveDraft(draft);
  toast.success('Draft saved');
} catch (err) {
  reportError(err);
  toast.error('Could not save the draft.', { action: { label: 'Retry', onClick: () => void retrySave() } });
}
```

Show messages in plain language. Never render raw server error text, stack traces, or SQL errors; map them to a safe message on the server.

### Error state with retry

```tsx
interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
}

export function ErrorState({ title = 'Something went wrong', message = 'Please try again.', onRetry }: ErrorStateProps) {
  return (
    <div role="alert" className="error-state">
      <h2>{title}</h2><p>{message}</p>
      {onRetry ? <button type="button" onClick={onRetry}>Try again</button> : null}
    </div>
  );
}
```

### Error boundaries with reset

Function components cannot catch render errors themselves. Use `react-error-boundary` (or a small class, see [fundamentals.md](fundamentals.md)) and reset it when the user retries or the inputs change.

```tsx
'use client';
import { ErrorBoundary, type FallbackProps } from 'react-error-boundary';
import { useQueryErrorResetBoundary } from '@tanstack/react-query';

function SectionFallback({ resetErrorBoundary }: FallbackProps) {
  return <ErrorState title="This section failed to load" onRetry={resetErrorBoundary} />;
}

export function ResilientSection({ children }: { children: React.ReactNode }) {
  const { reset } = useQueryErrorResetBoundary(); // lets suspense queries refetch after reset
  return (
    <ErrorBoundary FallbackComponent={SectionFallback} onReset={reset}>
      {children}
    </ErrorBoundary>
  );
}
```

Error boundaries do not catch errors in event handlers or async code after render; handle those where they happen and set error state or show a toast.

## Empty States

Every list, table, and search result has an empty state. Make it specific to why it is empty and offer the next step.

```tsx
// EmptyState renders a heading, an optional description, and an optional action
// No data yet: invite the first action
<EmptyState title="No projects yet" description="Projects group your tasks." action={<CreateProjectButton />} />

// Search returned nothing: help them recover
<EmptyState
  title={`No results for “${query}”`}
  description="Check the spelling or try fewer filters."
  action={<button type="button" onClick={clearFilters}>Clear filters</button>}
/>
```

Distinguish "nothing exists", "nothing matches", and "you do not have access". Show the empty state only after loading finishes without error.

## Buttons and Form Submission

### Pending state with `useFormStatus`

`useFormStatus` reads the status of the parent `<form>` whose `action` is running. Call it in a component rendered inside the form.

```tsx
'use client';
import { useFormStatus } from 'react-dom';

export function SubmitButton({ children, pendingLabel }: { children: React.ReactNode; pendingLabel: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} aria-disabled={pending}>
      {pending ? pendingLabel : children}
    </button>
  );
}
```

### Form with `useActionState`

```tsx
'use client';
import { useActionState, useEffect, useRef } from 'react';
import { createProject, type CreateProjectState } from './actions'; // 'use server' module
import { SubmitButton } from './SubmitButton';

const initialState: CreateProjectState = { status: 'idle', fieldErrors: {}, message: null };

export function CreateProjectForm() {
  const [state, formAction] = useActionState(createProject, initialState); // action: (prevState, formData)
  const errorRef = useRef<HTMLParagraphElement>(null);

  useEffect(() => {
    if (state.status === 'error') errorRef.current?.focus();
  }, [state]);

  return (
    <form action={formAction} noValidate>
      <label htmlFor="name">Project name</label>
      <input
        id="name"
        name="name"
        required
        aria-invalid={Boolean(state.fieldErrors.name)}
        aria-describedby={state.fieldErrors.name ? 'name-error' : undefined}
      />
      {state.fieldErrors.name ? <p id="name-error">{state.fieldErrors.name}</p> : null}

      {state.status === 'error' && state.message ? (
        <p ref={errorRef} tabIndex={-1} role="alert">{state.message}</p>
      ) : null}
      {state.status === 'success' ? <p role="status">Project created.</p> : null}

      <SubmitButton pendingLabel="Creating…">Create project</SubmitButton>
    </form>
  );
}
```

The Server Action validates `formData` with a Zod 4 schema, re-checks the session, and always returns the full `CreateProjectState` shape. See [forms.md](forms.md) and the Safety Rules in the skill's main guide.

### Preventing double submits

- Disable the trigger while pending. For a `<form action>`, `useFormStatus` covers it; for a click handler, track `isPending` from `useTransition` or the mutation hook.
- Disabling is a UI guard, not a guarantee. For payments and other non-repeatable writes, send an idempotency key and enforce it on the server.
- Keep the button's width stable when its label changes, so the layout does not jump.
- Do not disable a submit button just because the form is invalid; users cannot discover why. Let them submit and show field errors.

## Optimistic Updates

For instant feedback on likes, toggles, and list additions, show the expected result immediately with `useOptimistic` and let React revert it if the action fails. Call the optimistic setter inside a form action or `startTransition`, and surface the failure with a toast or inline message, since the revert alone is easy to miss. Full patterns: [hooks-performance-and-react-19.md](hooks-performance-and-react-19.md) (`useOptimistic`). For TanStack Query cache-level optimistic updates, see [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md).

## Accessibility

| Situation | Markup |
|-----------|--------|
| A region is loading or refreshing | `aria-busy="true"` on the region; remove it when done |
| Announce "Loading…" or "Saved" | A `role="status"` element (polite live region) that exists before the text changes |
| Announce an error | `role="alert"` (assertive) for errors the user must act on now |
| Spinner icon | `aria-hidden="true"` on the graphic, visible or `sr-only` text for its meaning |
| Skeleton | `aria-hidden="true"`; announce loading once in a status region, not per skeleton row |
| Invalid field | `aria-invalid="true"` and `aria-describedby` pointing at the message |
| Pending button | `disabled` (or `aria-disabled` plus a guarded handler when it must stay focusable) and a changed label |

Focus management:

- After a failed submit, move focus to the error summary or the first invalid field, so keyboard and screen-reader users land on the problem.
- After a successful action that removes the focused element (deleting a row, closing a dialog), move focus to a logical neighbor or the dialog trigger.
- Do not steal focus for background refresh errors; announce them politely instead.

Live regions only announce changes to content that was already in the DOM. Render the `role="status"` container from the start and change its text, rather than mounting it with the message.

Test each state with Testing Library: `findByRole('status')`, `findByRole('alert')`, and `toHaveFocus()` assertions. See [testing-recipes.md](testing-recipes.md).

## Checklist

**States**
- [ ] Loading shown only with no data yet; spinners delayed; skeletons match content size.
- [ ] Transitions keep visible content during navigation and filter changes.
- [ ] Every error surfaced at the right level, with a retry; boundaries wrap independent sections and can reset.
- [ ] Every collection has a contextual empty state with a next action.

**Actions**
- [ ] Triggers disabled and relabeled while pending; non-repeatable writes carry an idempotency key.
- [ ] Every action gives visible feedback; optimistic updates revert and tell the user on failure.

**Accessibility**
- [ ] `aria-busy` on refreshing regions; `role="status"` and `role="alert"` used correctly.
- [ ] Focus moves to errors after a failed submit.
- [ ] Tests cover loading, error, empty, and success states.
