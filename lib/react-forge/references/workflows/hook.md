# Workflow: Generate React Custom Hook

Create a custom React hook following best practices.

## Instructions

Create a custom hook based on the provided name and description:

1. **Analyze Requirements**
   - Parse hook name from the request (must start with "use")
   - Identify the core functionality
   - Determine parameters and return types
   - Check for existing similar hooks in the codebase
   - Check `../hooks-custom-library.md` first: it holds the canonical versions of common hooks (`useFetch`, `useLocalStorage`, `useDebounce`, `useClickOutside`, `useMediaQuery`, and more). Copy from there instead of re-deriving them

2. **Hook Structure**
   - Name must start with "use"
   - Proper TypeScript generics if needed
   - Clear parameter and return type definitions
   - JSDoc comments for documentation

3. **Implementation Checklist**
   - [ ] Follows Rules of Hooks
   - [ ] Proper dependency arrays
   - [ ] Cleanup in useEffect if needed
   - [ ] No memoization by default: use `useCallback`/`useMemo` only for a measured hotspot or when callers need stable identities (`memo` children, effect dependencies); unnecessary with React Compiler
   - [ ] Handles edge cases
   - [ ] TypeScript types for all parameters and returns
   - [ ] SSR-safe: never read `window`/`document`/storage during render or in a `useState` initializer; use `useSyncExternalStore` with a `getServerSnapshot`, or read in an effect

4. **File Location**
   - Place in hooks/ directory
   - Use consistent naming (useHookName.ts)
   - Export from index if using barrel exports

## Example Output

```tsx
// hooks/useToggle.ts
import { useState } from 'react';

/**
 * Boolean state with named actions.
 * @param initialValue - Starting value (default: false)
 * @returns The current value, toggle, setTrue, setFalse, and setValue
 */
export function useToggle(initialValue = false) {
  const [value, setValue] = useState(initialValue);

  const toggle = () => setValue((v) => !v);
  const setTrue = () => setValue(true);
  const setFalse = () => setValue(false);

  return { value, toggle, setTrue, setFalse, setValue };
}
```

This matches the canonical version in [hooks-custom-library.md](../hooks-custom-library.md#usetoggle---boolean-state-with-named-actions). Reuse it instead of redefining it.

## Common Hook Patterns

### State + Actions Pattern
```tsx
function useCounter(initial = 0) {
  const [count, setCount] = useState(initial);

  const increment = () => setCount((c) => c + 1);
  const decrement = () => setCount((c) => c - 1);
  const reset = () => setCount(initial);

  return { count, increment, decrement, reset };
}
```

Plain functions are enough here. Wrap the actions in `useCallback` only when callers need stable identities (for example, they pass them to `memo` children or list them in effect dependencies) and the project does not use React Compiler; say so in a comment when wrapping them.

### Async Data Pattern

Prefer TanStack Query or SWR for server data. If a hand-written hook is required, copy the canonical `useFetch` from `../hooks-custom-library.md` (it aborts stale requests, ignores `AbortError`, checks `res.ok`, and resets state when the URL changes) instead of generating a new one:

```tsx
const { data: user, loading, error, refetch } = useFetch<User>(`/api/users/${userId}`);
```

### Subscription Pattern

Subscribe to external sources (media queries, window size, storage, browser APIs) with `useSyncExternalStore` and a `getServerSnapshot`, which keeps server-rendered markup in sync during hydration. `getSnapshot` must return a primitive or a cached value: a new object on every call causes an infinite loop. The canonical `useMediaQuery` and `useWindowSize` in `../hooks-custom-library.md` show the shape:

```tsx
const isMobile = useMediaQuery('(max-width: 768px)');
```

### Ref-Based Pattern

For hooks that return a ref and listen to the document (click outside, focus trap), keep the latest handler in a ref so an inline callback does not resubscribe. Copy the canonical `useClickOutside` from `../hooks-custom-library.md`:

```tsx
const menuRef = useClickOutside<HTMLDivElement>(() => setIsOpen(false));

return <div ref={menuRef}>{/* menu */}</div>;
```

When the observed element can mount after the first render (for example, `useIntersectionObserver`), return a callback ref and hold the element in state so the effect runs when the node attaches.

### Storage Pattern (SSR-Safe)

Use the canonical `useLocalStorage` from `../hooks-custom-library.md` verbatim. A generated storage hook must:

- read storage through `useSyncExternalStore`, with `getServerSnapshot` returning the initial value (never read storage in a `useState` initializer: it causes a hydration mismatch),
- return a cached snapshot from `getSnapshot` (the raw string, parsed separately) to avoid an infinite render loop,
- subscribe to the `storage` event (other tabs) and to a same-tab custom event that the setter dispatches,
- parse JSON inside `try/catch`,
- apply functional updates to the latest stored value, not a value captured in a closure.

## Rules of Hooks Reminder

1. **Only call hooks at the top level** - Never inside loops, conditions, or nested functions
2. **Only call hooks from React functions** - Function components or custom hooks
3. **Consistent order** - Hooks must be called in the same order every render
