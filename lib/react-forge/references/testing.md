# React Testing

## Contents

- [Core Workflow](#core-workflow)
- [Key Gotchas](#key-gotchas)
- [Quick Reference](#quick-reference)
- [Testing Tools](#testing-tools)
- [Component Testing](#component-testing)
- [Testing Async Components](#testing-async-components)
- [Testing Hooks](#testing-hooks)
- [Testing with Context](#testing-with-context)
- [Mocking](#mocking)
- [Integration Testing](#integration-testing)
- [Accessibility Testing](#accessibility-testing)
- [Testing Server Components](#testing-server-components)
- [Best Practices](#best-practices)
- [Media Components](#media-components)
- [Additional References](#additional-references)

## Core Workflow

1. Set up the runner and jsdom environment first, then centralize `@testing-library/jest-dom`, cleanup, and browser API mocks in test setup.
2. Write tests from the user perspective using role, label, text, placeholder, and display-value queries before falling back to test IDs.
3. Use `userEvent.setup()` for interactions and `waitFor` or findBy queries for async state changes.
4. Mock at module or network boundaries, not internal component state, and reset mocks between tests.
5. Create provider-aware render utilities for context, routers, query clients, themes, and other app-wide wrappers (see [Custom Render with Providers](testing-recipes.md#custom-render-with-providers)).
6. For media components, mock jsdom gaps such as `HTMLMediaElement.play`, `pause`, `load`, metadata properties, and IntersectionObserver (see [testing-media.md](testing-media.md)).

## Key Gotchas

- Avoid asserting implementation details such as component state; assert visible behavior and accessibility state.
- `fireEvent` is lower-level than `userEvent`; prefer `userEvent` unless directly firing browser/media events is necessary.
- Async assertions should wait for UI changes, not arbitrary timers.
- jsdom does not implement real media playback, layout, or browser codecs; mock those APIs deliberately.
- Provider state can leak between tests unless render utilities create fresh clients and cleanup runs after each test.

## Quick Reference

| Tool | Purpose | Install |
|------|---------|---------|
| Vitest or Jest | Test runner (use whichever the project already has) | `npm i -D vitest` |
| @testing-library/react | Component testing | `npm i -D @testing-library/react` |
| @testing-library/user-event | User simulation | `npm i -D @testing-library/user-event` |
| jest-axe | Accessibility testing | `npm i -D jest-axe` |

| Query | When to Use |
|-------|-------------|
| `getByRole` | Best - accessible elements |
| `getByLabelText` | Form inputs |
| `getByText` | Static text |
| `getByTestId` | Last resort |

| Pattern | Example |
|---------|---------|
| Setup user | `const user = userEvent.setup()` |
| Click | `await user.click(button)` |
| Type | `await user.type(input, 'text')` |
| Wait for async | `await waitFor(() => expect(...))` |

Use the project's existing test runner (Vitest or Jest) and package manager. Examples below use Vitest (`vi`); with Jest, replace `vi` with `jest` and import from `@jest/globals` or use globals.

## Testing Tools

### Setup with Vitest

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    include: ['**/*.test.{ts,tsx}'],
    css: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

afterEach(() => {
  cleanup();
  vi.clearAllMocks(); // reset call history on every mock
  vi.restoreAllMocks(); // undo vi.spyOn, including spies on globalThis.fetch
});

// jsdom does not implement matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver and ResizeObserver.
// Components call these with `new`, so the mock implementation must be a
// `function` (or class), not an arrow function; Vitest 3+/4 rejects `new` on
// arrow implementations. The same pattern works with jest.fn.
globalThis.IntersectionObserver = vi.fn(function () {
  return {
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
    takeRecords: vi.fn(() => []),
  };
}) as unknown as typeof IntersectionObserver;

globalThis.ResizeObserver = vi.fn(function () {
  return {
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn(),
  };
}) as unknown as typeof ResizeObserver;
```

Mock `fetch` with `vi.spyOn(globalThis, 'fetch')` inside each test rather than assigning `global.fetch = vi.fn()`. `vi.restoreAllMocks()` in the setup file then puts the real `fetch` back after every test; a direct assignment is never undone and leaks into later tests. `vi.spyOn` needs an existing global `fetch`: Vitest on Node 18+ has one, but `jest-environment-jsdom` does not, so under Jest define a `fetch` stub in the setup file first or mock at the network layer with MSW.

### Setup with Jest

```bash
npm install -D jest @testing-library/react @testing-library/jest-dom @testing-library/user-event jest-environment-jsdom
```

```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  transform: {
    '^.+\\.(ts|tsx)$': ['ts-jest', { tsconfig: 'tsconfig.json' }],
  },
};
```

## Component Testing

Render the component, find elements the way a user would, interact through `userEvent`, and assert on visible output, accessible state, and callback calls:

```tsx
const user = userEvent.setup();
render(<Button onClick={handleClick} disabled>Click me</Button>);
await user.click(screen.getByRole('button'));
expect(handleClick).not.toHaveBeenCalled();
```

- Cover the default render, each meaningful prop variation, every interaction, and empty, error, and loading states.
- Assert disabled, checked, selected, and focus state with jest-dom matchers (`toBeDisabled`, `toBeChecked`, `toHaveFocus`) instead of reading props or class names.
- Pass props through a shared `defaultProps` object and override one value per test.

Recipes: [testing-recipes.md](testing-recipes.md#component-testing-patterns) (basic render, props and disabled state, interactions, forms with validation and async submission, select and radio inputs).

## Testing Async Components

- Prefer `await screen.findBy*` for an element that appears later; it combines `waitFor` and `getBy`.
- Use `waitFor` only for assertions that are not element lookups (a mock call, a changed attribute), and keep a single assertion inside it.
- Use `waitForElementToBeRemoved` for a loading indicator that must disappear.
- Use `queryBy*` to assert absence; `getBy*` throws when nothing matches.
- To assert a loading state, mock the request with a promise that never resolves. To assert an in-flight state and then its end, capture the promise's `resolve` and call it after the first assertion.
- Wait for UI changes, never arbitrary sleeps; with fake timers, advance the clock inside `act`.

Recipes: [testing-recipes.md](testing-recipes.md#async-testing-patterns) (loading, success, and error states; `waitFor`; `findBy` timeouts; mocking an API module).

## Testing Hooks

Test a custom hook through `renderHook`, wrap state updates in `act`, and use `waitFor` for async results. Pass a `wrapper` when the hook reads context:

```tsx
import { renderHook, act } from '@testing-library/react';
import { it, expect } from 'vitest';
import { useCounter } from './useCounter';

it('increments counter', () => {
  const { result } = renderHook(() => useCounter());

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});
```

Full recipes (a `useCounter` suite, a `useFetch` suite with success, error, and URL-change cases, and hooks that need a context provider) are in [testing-recipes.md](testing-recipes.md#testing-custom-hooks).

## Testing with Context

Render a component that reads context inside its real provider rather than mocking the context, so tests exercise the same value and updates the app uses. For one provider, wrap the element directly (`render(<ThemeProvider>{ui}</ThemeProvider>)`); for several (query client, router, theme, auth), use a shared provider-aware custom `render` that creates fresh clients per test. Both are in [testing-recipes.md](testing-recipes.md): [Custom Render with Providers](testing-recipes.md#custom-render-with-providers) and [Testing Components with Context](testing-recipes.md#testing-components-with-context).

## Mocking

- Mock at module or network boundaries (`vi.mock('./api')`, `vi.spyOn(globalThis, 'fetch')`, or MSW), never internal component state.
- Prefer MSW when the project already uses it; it exercises the real `fetch` code path.
- Spy on `fetch` per test instead of assigning `global.fetch`; `vi.restoreAllMocks()` in the setup file restores it (see [Setup with Vitest](#setup-with-vitest)).
- `vi.mock` calls are hoisted above imports. To replace only some exports, spread `await importOriginal()` into the factory.
- Replace a heavy child component (chart, map, editor) with a lightweight stand-in only when the test targets the parent.
- Render routed components inside `MemoryRouter` with `initialEntries` instead of mocking the router. Mock the router module only for framework routers whose hooks cannot run outside the framework (for example, Next.js `next/navigation`).
- With fake timers, pass `advanceTimers` to `userEvent.setup()` so typing does not hang, and restore real timers in `afterEach`:

```tsx
vi.useFakeTimers();
const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
```

Recipes: [testing-recipes.md](testing-recipes.md#mocking-patterns) (whole and partial module mocks, child components, routing, external libraries, timers and debounced input, MSW).

## Integration Testing

Integration tests render a feature root with its real children and state, then drive a complete flow (add, complete, filter, delete) through the UI. Mock only the network boundary. Recipe: [Testing Data Flow](testing-recipes.md#testing-data-flow).

## Accessibility Testing

Run `jest-axe` against the rendered `container` (`expect(await axe(container)).toHaveNoViolations()` after `expect.extend(toHaveNoViolations)`) for each significant component, and complement it with behavior tests: labels found by `getByLabelText`, required fields, error messages linked through `aria-describedby`, focus traps, and keyboard handling with `user.tab()` and `user.keyboard('{Escape}')`. Automated checks catch only part of WCAG; keep manual checks in review. Recipes: [testing-recipes.md](testing-recipes.md#accessibility-testing).

## Testing Server Components

React Testing Library renders on the client with React DOM, so it cannot render an `async` Server Component (`render(<UserProfile userId="1" />)` fails). Choose one of these approaches, in this order:

1. **Split data from markup.** Test the data function (`getUser`) as a plain async function, and move the markup into a synchronous component that takes the data as props. That component renders with RTL like any other.
2. **Await the component as a function.** For a leaf Server Component with mocked data, call it and render the returned element. This works only when the returned tree has no nested `async` components and the code does not call framework request APIs such as `cookies()` or `headers()` (mock those modules if it does).
3. **Test the full tree end to end.** For pages that combine several Server Components, Suspense streaming, or Server Actions, use Playwright (or the framework's recommended e2e setup) against a running app.

```tsx
// components/UserProfile.test.tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { getUser } from '@/lib/users';
import { UserProfile } from './UserProfile';

vi.mock('@/lib/users', () => ({ getUser: vi.fn() }));

describe('UserProfile (Server Component)', () => {
  it('renders the user', async () => {
    vi.mocked(getUser).mockResolvedValue({
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      joinedAt: '2024-01-01',
    });

    render(await UserProfile({ userId: '1' }));

    expect(screen.getByRole('heading', { name: 'John Doe' })).toBeInTheDocument();
  });

  it('shows a not-found message', async () => {
    vi.mocked(getUser).mockResolvedValue(null);

    render(await UserProfile({ userId: 'missing' }));

    expect(screen.getByRole('status')).toHaveTextContent('User not found.');
  });
});
```

Client Components inside a Server Component tree test normally with RTL. Server Actions are async functions: call them directly with a `FormData` and a mocked session to test auth, validation, and the returned state.

## Best Practices

### 1. Query Priority

```tsx
// Best - accessible queries
screen.getByRole('button', { name: /submit/i });
screen.getByLabelText(/email/i);
screen.getByPlaceholderText(/search/i);
screen.getByText(/welcome/i);
screen.getByDisplayValue(/john/i);

// Fallback - test IDs (last resort)
screen.getByTestId('custom-element');
```

Order of preference:

1. **Accessible queries:** `getByRole` (most semantic; filter with `name`), `getByLabelText` (form fields), `getByPlaceholderText`, `getByText` (non-interactive content), `getByDisplayValue` (current input value).
2. **Semantic queries:** `getByAltText` (images), `getByTitle` (title attribute).
3. **Test IDs:** `getByTestId`, only when no semantic option exists (for example, `<video>`, which has no implicit role).

### 2. Avoid Implementation Details

```tsx
// Bad - testing implementation
expect(component.state.isOpen).toBe(true);

// Good - testing behavior
expect(screen.getByRole('dialog')).toBeVisible();
```

### 3. Test User Behavior

```tsx
// Bad - testing clicks
fireEvent.click(button);

// Good - simulating real user
const user = userEvent.setup();
await user.click(button);
```

### 4. Use Test Utilities

Centralize providers in a shared custom `render` that re-exports Testing Library and creates fresh clients per test. The full utility and its rationale are in [Custom Render with Providers](testing-recipes.md#custom-render-with-providers).

## Media Components

Testing video and audio components (mocking `play()`/`pause()` in jsdom, media events, IntersectionObserver for lazy-loaded media) is in [testing-media.md](testing-media.md).

## Additional References

- [testing-recipes.md](testing-recipes.md) - Complete copy-paste test files: provider-aware custom render, components, forms, async, hooks, mocking, MSW, integration, and accessibility
- [testing-media.md](testing-media.md) - Testing video and audio components: HTMLMediaElement mocks, playback state, media events, IntersectionObserver for lazy media
