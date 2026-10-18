# React 19 Upgrade, React Compiler, and Hydration

Migrate an app to React 19, turn on the React Compiler, and find and fix hydration mismatches.

## Contents

- [Upgrade Checklist](#upgrade-checklist)
- [Install and Codemods](#install-and-codemods)
- [Breaking Changes](#breaking-changes)
- [TypeScript Changes](#typescript-changes)
- [New APIs to Adopt After Upgrading](#new-apis-to-adopt-after-upgrading)
- [Migrating Class Components to Hooks](#migrating-class-components-to-hooks)
- [React Compiler](#react-compiler)
- [Hydration Mismatches](#hydration-mismatches)
- [Reading the Hydration Error](#reading-the-hydration-error)

## Upgrade Checklist

1. Upgrade to React 18.3 first. It is React 18.2 plus warnings for every API that React 19 removes. Fix all warnings before moving on.
2. Confirm the project uses the new JSX transform (`"jsx": "react-jsx"` in `tsconfig.json`, or the automatic runtime in Babel/esbuild/SWC). React 19 requires it.
3. Install React 19 and its types (see [Install and Codemods](#install-and-codemods)).
4. Run the React codemod recipe, then the TypeScript codemod preset.
5. Fix what the codemods miss: `defaultProps` on function components, legacy context, `findDOMNode`, `react-test-renderer/shallow`.
6. Upgrade libraries that pin `react@^18` in `peerDependencies` (routers, UI kits, testing libraries). Check each changelog for a React 19 release.
7. Run type-check, lint, unit tests, and an end-to-end smoke test. Check the browser console for hydration errors on server-rendered pages.
8. Adopt new APIs and the React Compiler in separate follow-up changes, not in the upgrade commit.

## Install and Codemods

Pin exact versions so every environment resolves the same React build:

```bash
npm install --save-exact react@^19.0.0 react-dom@^19.0.0
npm install --save-exact --save-dev @types/react@^19.0.0 @types/react-dom@^19.0.0
```

Run the migration recipe. It bundles `replace-reactdom-render`, `replace-string-ref`, `replace-act-import`, `replace-use-form-state`, and `prop-types-typescript`:

```bash
npx codemod@latest react/19/migration-recipe
```

The recipe does not touch types. Run the TypeScript preset separately:

```bash
npx types-react-codemod@latest preset-19 ./src
```

Commit after each codemod so each diff can be reviewed on its own.

## Breaking Changes

### `ReactDOM.render` and `ReactDOM.hydrate`

Both are removed. Use the root APIs from `react-dom/client`.

```tsx
// Before
ReactDOM.render(<App />, container);
ReactDOM.hydrate(<App />, container);

// After
import { createRoot, hydrateRoot } from 'react-dom/client';
createRoot(container).render(<App />);
hydrateRoot(container, <App />); // for server-rendered HTML
```

### `unmountComponentAtNode`

Removed. Keep the root and call `unmount()` on it.

```tsx
// Before
ReactDOM.unmountComponentAtNode(container);

// After: keep the root returned by createRoot
root.unmount();
```

`ReactDOM.findDOMNode` is also removed. Attach a ref to the DOM element instead.

### `propTypes` and `defaultProps` on Function Components

React no longer checks `propTypes` (they are silently ignored), and `defaultProps` is ignored on function components. Use TypeScript for prop types and default parameters for defaults. Class components still support `defaultProps`.

```tsx
// Before
function Heading({ text }: { text?: string }) { return <h1>{text}</h1>; }
Heading.defaultProps = { text: 'Hello, world!' };

// After
function Heading({ text = 'Hello, world!' }: { text?: string }) { return <h1>{text}</h1>; }
```

### String Refs

Removed. Replace `ref="input"` and `this.refs.input` with a ref callback or `createRef` (codemod: `react/19/replace-string-ref`).

```tsx
// Before
render() { return <input ref="input" />; } // read via this.refs.input

// After
input: HTMLInputElement | null = null;
render() { return <input ref={(el) => { this.input = el; }} />; }
```

### Legacy Context

`contextTypes`, `childContextTypes`, and `getChildContext` are removed. Use `createContext` with `static contextType` in classes or `useContext`/`use` in function components.

```tsx
// Before
static contextTypes = { theme: PropTypes.string };

// After
const ThemeContext = createContext('light');
// in the class:
static contextType = ThemeContext;
declare context: React.ContextType<typeof ThemeContext>;
```

### Test Utilities

`act` moved from `react-dom/test-utils` to `react`. The other `test-utils` functions now throw. `react-test-renderer/shallow` is removed.

```ts
// Before
import { act } from 'react-dom/test-utils';
import ShallowRenderer from 'react-test-renderer/shallow';

// After
import { act } from 'react';
import ShallowRenderer from 'react-shallow-renderer'; // npm i -D react-shallow-renderer
```

Prefer moving shallow-render tests to React Testing Library (see `testing.md`).

### Errors in Render Are Not Re-Thrown

React 19 no longer re-throws errors caught during render. Uncaught errors go to `window.reportError`, and errors caught by an Error Boundary go to `console.error`. If monitoring relied on the re-throw, wire it up through the root options:

```tsx
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root')!, {
  onUncaughtError: (error, errorInfo) =>
    reportToMonitoring(error, { componentStack: errorInfo.componentStack }),
  // Errors an Error Boundary handled
  onCaughtError: (error) => reportToMonitoring(error, { handled: true }),
  // Errors React recovered from on its own, e.g. a hydration mismatch
  onRecoverableError: (error) => reportToMonitoring(error, { recoverable: true }),
});
root.render(<App />);
```

`hydrateRoot` accepts the same options as its third argument.

Other removals: module pattern factories (components that return an object with `render`) and `React.createFactory`. Replace both with plain function components and JSX.

## TypeScript Changes

### `useRef` Requires an Argument

```ts
// Before
const timer = useRef<number>();

// After
const timer = useRef<number | undefined>(undefined);
const input = useRef<HTMLInputElement>(null); // RefObject<HTMLInputElement | null>
```

All refs are mutable now, and `MutableRefObject` is deprecated in favour of `RefObject`.

### Ref Callbacks Can Return a Cleanup

A ref callback may return a cleanup function that React calls when the element detaches. Because of this, an arrow function that implicitly returns a value is now a type error. Use a block body.

```tsx
// Before: implicit return, now a type error
<div ref={(node) => (instance = node)} />

// After
<div ref={(node) => { instance = node; }} />

// New: cleanup instead of a second call with null
<div ref={(node) => { const ro = new ResizeObserver(onResize); ro.observe(node!); return () => ro.disconnect(); }} />
```

### `ReactElement` Props Default to `unknown`

`ReactElement['props']` is `unknown` instead of `any`. Pass a type argument where code reads element props: `ReactElement<{ id: string }>`. For codebases with heavy unsound `element.props` access, `npx types-react-codemod@latest react-element-default-any-props ./src` restores `any`.

### `JSX` Namespace Moved to `React.JSX`

The global `JSX` namespace is gone. Use `React.JSX.Element` and friends, and wrap augmentations in a module declaration that matches the `jsx` compiler option (`react/jsx-runtime` for `"react-jsx"`, `react/jsx-dev-runtime` for `"react-jsxdev"`, `react` for `"react"` or `"preserve"`).

```ts
// global.d.ts
declare module 'react' {
  namespace JSX {
    interface IntrinsicElements {
      'my-element': { myElementProps: string };
    }
  }
}
```

### `useReducer` Typing

Do not pass the reducer type as a type argument (`useReducer<React.Reducer<State, Action>>(reducer)`). Type the reducer's parameters and call `useReducer(reducer, initialState)`.

## New APIs to Adopt After Upgrading

Adopt these one at a time after the upgrade lands. Details live in `fundamentals.md` and `hooks-performance-and-react-19.md`.

- **`ref` as a prop**: function components receive `ref` like any other prop. Drop `forwardRef` in new code; the old API still works.
- **`<Context>` as a provider**: render `<ThemeContext value={theme}>` instead of `<ThemeContext.Provider value={theme}>`.
- **`use`**: read a promise (with Suspense) or a context, including inside conditionals. See `fundamentals.md` → The use() Hook.
- **Actions**: async functions in `startTransition`, `<form action={fn}>`, `useActionState`, `useOptimistic`, and `useFormStatus`. See `hooks-performance-and-react-19.md` → React 19 Hooks and `forms.md`.
- **Document metadata**: render `<title>`, `<meta>`, and `<link>` inside any component; React hoists them to `<head>`.
- **Stylesheets**: `<link rel="stylesheet" href="..." precedence="default" />` is deduplicated, ordered by `precedence`, and blocks commit until loaded.
- **Async scripts**: `<script async src="..." />` can sit next to the component that needs it; React loads it once.

## Migrating Class Components to Hooks

Class components still work in React 19, so convert them only when the component is already being changed or needs hooks-based libraries. Convert leaf components first, keep each conversion in its own commit, and keep the tests green between steps.

### Lifecycle to Hooks Mapping

| Class | Function component |
|-------|--------------------|
| `constructor` / `this.state = {...}` | `useState` per independent value, or `useReducer` for related values |
| `componentDidMount` | `useEffect(() => { ... }, [])` |
| `componentDidUpdate(prevProps)` checking `prevProps.id !== this.props.id` | `useEffect(() => { ... }, [id])` |
| `componentWillUnmount` | The cleanup function returned from the same `useEffect` |
| Mount + update + unmount for one subscription | One `useEffect` with setup and cleanup, keyed on its inputs |
| `getDerivedStateFromProps` | Compute during render; to reset state on a prop change, pass a `key` |
| `shouldComponentUpdate` / `PureComponent` | `memo` only at a measured hotspot (or React Compiler) |
| `getSnapshotBeforeUpdate` | No hook equivalent; read layout in `useLayoutEffect`, or keep the class |
| `componentDidCatch` / `getDerivedStateFromError` | No hook equivalent; keep a class error boundary |
| `UNSAFE_componentWillMount` / `WillReceiveProps` / `WillUpdate` | Render-time logic, a `key` reset, or an effect |
| `this.forceUpdate()` | Usually a sign of state stored outside React; use `useSyncExternalStore` |
| Instance fields (`this.timer`) | `useRef` |
| `static contextType` / `<Context.Consumer>` | `useContext(Ctx)` or `use(Ctx)` |

Effects run after paint and, in Strict Mode development, mount, unmount, and mount again. Every effect that subscribes, starts a timer, or fetches needs a cleanup.

### State and `setState` Differences

- `this.setState({ a })` shallow-merges into the state object. A `useState` setter replaces the value. Split unrelated fields into separate `useState` calls, or spread when keeping an object: `setForm((prev) => ({ ...prev, email }))`.
- `setState(updater, callback)` has no hook equivalent for the callback. Run follow-up work in the event handler after computing the next value, or in an effect that depends on the state.
- Use the functional form (`setCount((c) => c + 1)`) whenever the next value depends on the previous one; closures in function components capture the render's values.
- Methods bound in the constructor (`this.handleClick = this.handleClick.bind(this)`) become plain functions in the component body.

```tsx
// Before
class Search extends React.Component<{ initialQuery: string }, { query: string; page: number }> {
  state = { query: this.props.initialQuery, page: 1 };
  handleChange = (e: React.ChangeEvent<HTMLInputElement>) => this.setState({ query: e.target.value, page: 1 });
  nextPage = () => this.setState((s) => ({ page: s.page + 1 }));
  render() { /* ... */ }
}

// After
function Search({ initialQuery }: { initialQuery: string }) {
  const [query, setQuery] = useState(initialQuery);
  const [page, setPage] = useState(1);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value);
    setPage(1); // both updates batch into one render
  }
  const nextPage = () => setPage((p) => p + 1);
  /* ... */
}
```

### Data Fetching in Lifecycles

A `componentDidMount` + `componentDidUpdate` fetch pair becomes one effect keyed on the input, with a cleanup that ignores stale responses. Better, move it to a server-state library or a Server Component (see `state-jotai-and-tanstack-query.md`).

```tsx
function UserPanel({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setUser(null);
    setError(null);
    fetch(`/api/users/${encodeURIComponent(userId)}`, { signal: controller.signal })
      .then((r) => (r.ok ? (r.json() as Promise<User>) : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then(setUser)
      .catch((err: unknown) => {
        if (!controller.signal.aborted) setError(err as Error);
      });
    return () => controller.abort(); // replaces componentWillUnmount and stale-update guards
  }, [userId]);

  if (error) return <p role="alert">Could not load the user.</p>;
  if (!user) return <p role="status">Loading…</p>;
  return <h2>{user.name}</h2>;
}
```

### Refs

- `React.createRef()` in the constructor becomes `useRef<HTMLInputElement>(null)`.
- Mutable instance fields that should not trigger a render (timer ids, previous values) become `useRef` values.
- Imperative methods a parent called on the class instance (`this.inputRef.current.focus()` from outside) become `useImperativeHandle(ref, () => ({ focus }))`, with `ref` received as a regular prop in React 19. Do not add `forwardRef`.

### Context

Replace `static contextType = ThemeContext` and `<ThemeContext.Consumer>` render props with `const theme = useContext(ThemeContext)` (or `use(ThemeContext)`, which may be called conditionally). Legacy `contextTypes` must be removed first; see [Legacy Context](#legacy-context).

### Error Boundaries Stay Classes

There is no hook for catching render errors. Keep one small class boundary (see `fundamentals.md`) or use the `react-error-boundary` package, which wraps the class and adds `resetKeys` and `onReset`. Convert everything else around it.

### HOCs and Render Props to Hooks

A higher-order component or render-prop component that only supplies data or behavior becomes a custom hook. The consumer calls the hook directly, and the wrapper layers disappear from the tree.

```tsx
// Before: HOC injects `online` and `connect(...)` injects `user`
export default connect(mapState)(withOnlineStatus(Profile));

// After
function Profile() {
  const online = useOnlineStatus(); // custom hook using useSyncExternalStore
  const user = useAppSelector(selectCurrentUser);
  /* ... */
}
```

Keep a HOC when it wraps rendering for many components that cannot change (third-party components, route guards in older routers). See `patterns-hoc-provider-controlled.md` for when HOCs still fit and `hooks-custom-library.md` before writing a new hook.

### Codemods

No codemod reliably converts stateful classes; convert those by hand. Two transforms from `react-codemod` help around the edges:

```bash
# Render-only classes (no state, no lifecycles) to function components
npx react-codemod pure-component ./src

# Prefix deprecated lifecycles with UNSAFE_ so they are easy to find
npx react-codemod rename-unsafe-lifecycles ./src
```

Review every diff, then run type-check, lint (`eslint-plugin-react-hooks`), and tests. After converting, check the [React Compiler](#react-compiler) section: compiled function components rarely need manual `memo` added during migration.

## React Compiler

The React Compiler is a build-time Babel plugin that memoizes components and hooks automatically. It inserts the equivalent of `useMemo`, `useCallback`, and `React.memo` where they help, including in places manual memoization cannot reach (such as after an early return).

### Requirements

- React 19: works with no extra configuration.
- React 17 or 18: set `target: '17'` or `target: '18'` (strings, no patch version) and install `react-compiler-runtime` as a regular dependency, not a dev dependency.
- Code that follows the Rules of React. The compiler skips any component or hook it cannot prove safe; it does not break it.

```bash
npm install -D babel-plugin-react-compiler@latest
# React 17/18 only:
npm install react-compiler-runtime@latest
```

### Install: Plain Babel

The compiler must run first in the Babel plugin list, because it needs the original source.

```js
// babel.config.js
module.exports = {
  plugins: [
    ['babel-plugin-react-compiler', {
      // target: '18', // only when not on React 19
    }],
    // ...other plugins after it
  ],
};
```

### Install: Vite

`@vitejs/plugin-react` 6+ removed its inline `babel` option. Add `@rolldown/plugin-babel` and use the preset that `@vitejs/plugin-react` exports:

```bash
npm install -D @rolldown/plugin-babel
```

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react, { reactCompilerPreset } from '@vitejs/plugin-react';
import babel from '@rolldown/plugin-babel';

export default defineConfig({
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] }),
  ],
});
```

On `@vitejs/plugin-react` 5 and earlier, pass the plugin through the inline option instead: `react({ babel: { plugins: ['babel-plugin-react-compiler'] } })`.

### Install: Next.js

Install `babel-plugin-react-compiler`, then set `reactCompiler: true` in `next.config.ts` (top-level since Next.js 16; `experimental.reactCompiler` before that). It also accepts an object such as `{ compilationMode: 'annotation' }`. See the Next.js docs.

### ESLint Rules

The compiler's lint rules now ship in `eslint-plugin-react-hooks` (v6+); the separate `eslint-plugin-react-compiler` is no longer needed. The `recommended` config includes them (`purity`, `refs`, `immutability`, `set-state-in-render`, `set-state-in-effect`, `static-components`, and others).

```bash
npm install -D eslint-plugin-react-hooks@latest
```

```ts
// eslint.config.ts (flat config, ESLint 9+)
import reactHooks from 'eslint-plugin-react-hooks';
import { defineConfig } from 'eslint/config';

export default defineConfig([
  reactHooks.configs.flat.recommended,
  // reactHooks.configs.flat['recommended-latest'] for experimental rules
]);
```

On ESLint 8 legacy config, use `"extends": ["plugin:react-hooks/recommended"]`. Install the lint rules even without the compiler: every reported violation is a component the compiler will skip.

### Incremental Adoption

For a large codebase, start in annotation mode. Only functions marked `"use memo"` are compiled.

```js
// babel.config.js
module.exports = {
  plugins: [['babel-plugin-react-compiler', { compilationMode: 'annotation' }]],
};
```

```tsx
function TodoList({ todos }: { todos: Todo[] }) {
  'use memo'; // also add to custom hooks you want compiled
  // ...
}
```

Alternatively, compile one directory at a time: move the plugin into a Babel `overrides` entry with `test: ['./src/features/**/*.{js,jsx,ts,tsx}']` and add globs as each area passes its tests.

Once the default mode (`infer`) is on, opt a single problem function out with `"use no memo"` while fixing it, then remove the directive:

```tsx
function LegacyChart(props: ChartProps) {
  'use no memo'; // TODO: mutates props.series, see #1234
  // ...
}
```

Directives must be the first statement in the function body, or the first statement in the file (before imports) to apply to the whole module.

### Verify It Is Working

- Open React DevTools in development. Compiled components show a **Memo ✨** badge next to their name.
- Inspect the build output: compiled modules import `c` from `react/compiler-runtime` (or `react-compiler-runtime` on React 17/18) and contain `Symbol.for("react.memo_cache_sentinel")`.
- Profile a known slow interaction before and after with the React DevTools Profiler (see `performance.md`).

### Existing `useMemo`, `useCallback`, and `React.memo`

Leave them in place. The compiler works alongside them, and removing one can change when an effect fires if the memoized value is in its dependency array. Remove manual memoization only in code covered by tests, one component at a time. In new code, skip manual memoization unless the code needs an exact, stable identity for an effect dependency or a third-party API.

### Code the Compiler Skips

The compiler bails out of a component or hook (leaving it as plain, uncompiled code) when it detects a Rules of React violation, such as:

- Mutating props, state, or values already used in JSX.
- Reading or writing `ref.current` during render.
- Side effects or non-idempotent calls during render (`Math.random()`, `Date.now()`, writing to module variables).
- Calling hooks conditionally or from regular functions.
- Defining components inside other components.
- Unsupported syntax, or libraries whose return values change identity without React knowing (reported as `incompatible-library`).

The lint rules above flag the same cases. Fix them to get the component compiled.

## Hydration Mismatches

Hydration attaches React to server-rendered HTML. The first client render must produce exactly the same markup as the server. When it does not, React 19 throws away the server HTML for the nearest Suspense boundary (or the whole root) and re-renders on the client. Treat every mismatch as a bug: at best it costs a second render, at worst event handlers attach to the wrong elements.

### Browser-Only Values During Render

`window`, `localStorage`, `matchMedia`, `navigator`, and `document` do not exist on the server. Reading them in render or in a `useState` initializer gives the client a different first render.

```tsx
// Bad: server renders "light", client's first render may render "dark"
function ThemeLabel() {
  const [theme] = useState(() => localStorage.getItem('theme') ?? 'light');
  const isWide = window.matchMedia('(min-width: 768px)').matches;
  return <span>{theme} {isWide ? 'desktop' : 'mobile'}</span>;
}
```

Use `useSyncExternalStore` with a `getServerSnapshot`. React uses the server snapshot during hydration and then re-renders with the real value.

```tsx
// Good
import { useSyncExternalStore } from 'react';

function subscribe(onChange: () => void) {
  const mql = window.matchMedia('(min-width: 768px)');
  mql.addEventListener('change', onChange);
  return () => mql.removeEventListener('change', onChange);
}

function useIsWide() {
  return useSyncExternalStore(
    subscribe,
    () => window.matchMedia('(min-width: 768px)').matches, // client
    () => false, // server and hydration
  );
}
```

`hooks-custom-library.md` has complete SSR-safe versions: `useLocalStorage`, `useMediaQuery`, and `useWindowSize`. Use them instead of writing new ones.

### Server/Client Branches in Render

`typeof window !== 'undefined'` is `false` on the server and `true` during hydration, so the two renders differ by design.

```tsx
// Bad
if (typeof window === 'undefined') return null;

// Good: two-pass render; the first client render matches the server
function Banner() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return null;
  return <p>Welcome back, {getCachedUserName()}</p>;
}
```

A two-pass render costs an extra render after hydration, so keep it to small leaf components. On React 19.3+, a component that must only render in the browser can call `use(browser())` (from `react-dom`) inside a `<Suspense>` boundary instead: the server sends the fallback and the client renders the content.

### Time, Randomness, and Locale

`Date.now()`, `new Date()`, `Math.random()`, and locale-dependent formatting return different values on the server and in the browser. `toLocaleString()` without arguments uses the machine's locale and time zone, which rarely match between a server and a user.

```tsx
// Bad
function Posted({ createdAt }: { createdAt: string }) {
  return <time>{new Date(createdAt).toLocaleString()}</time>;
}
```

Format with an explicit locale and time zone, compute "now" once on the server and pass it as a prop, or render the user-local value after mount:

```tsx
// Good 1: explicit locale and time zone, so both sides format identically
const formatter = new Intl.DateTimeFormat('en-GB', {
  dateStyle: 'medium',
  timeStyle: 'short',
  timeZone: 'UTC',
});

function Posted({ createdAt }: { createdAt: string }) {
  return <time dateTime={createdAt}>{formatter.format(new Date(createdAt))}</time>;
}

// Good 2: render the user-local value after mount
function LocalTime({ iso }: { iso: string }) {
  const [text, setText] = useState<string | null>(null);
  useEffect(() => setText(new Date(iso).toLocaleString()), [iso]);
  return <time dateTime={iso}>{text ?? iso}</time>;
}
```

### Generated IDs

Random or counter-based ids differ between server and client. Use `useId`, which is stable across both.

```tsx
// Bad
const id = `field-${Math.random().toString(36).slice(2)}`;

// Good
const id = useId(); // <label htmlFor={id}> ... <input id={id} />
```

### Invalid HTML Nesting

The browser's HTML parser repairs invalid nesting in the server HTML, so the DOM no longer matches what React expects. Common cases:

```tsx
// Bad
<p><div>Block inside paragraph</div></p>       // parser closes <p> early
<a href="/a"><a href="/b">Nested link</a></a>  // nested <a> is split
<table><tr><td>Cell</td></tr></table>          // parser inserts <tbody>

// Good
<div><div>Block inside block</div></div>
<a href="/a">Link</a> <a href="/b">Other link</a>
<table><tbody><tr><td>Cell</td></tr></tbody></table>
```

Watch for components that render a `<div>` (cards, markdown renderers, UI-kit `Text` components) placed inside a `<p>`. React logs an `In HTML, <div> cannot be a descendant of <p>` error in development that names both components.

### Browser Extensions and Third-Party Scripts

Extensions (password managers, translators, Grammarly, dark-mode tools) add attributes or nodes to the DOM before React hydrates. React 19 skips unexpected tags in `<head>` and `<body>`, but attribute changes on elements inside the app still mismatch. Reproduce in a private window with extensions disabled before debugging app code. If an extension consistently changes attributes on `<html>` or `<body>`, `suppressHydrationWarning` on that element is acceptable.

### `suppressHydrationWarning`

Use it only when a single element's text or attribute is unavoidably different, such as a timestamp or a theme class set by an inline script before hydration. It works one level deep, and React does not patch the mismatched text, so the server value stays on screen until the next render.

```tsx
// Acceptable: one element, unavoidable difference
<time dateTime={iso} suppressHydrationWarning>
  {new Date(iso).toLocaleTimeString()}
</time>

// Acceptable: an inline script sets a theme class on <html> before React loads
<html lang="en" suppressHydrationWarning>
```

Do not put it on a wrapper to hide mismatches in children; it does not reach them.

### Persisted Client Stores

Stores that read `localStorage` on creation render stored values on the client and defaults on the server.

**Zustand `persist`** rehydrates synchronously from `localStorage` when the store is created, so the first client render can differ from the server. Set `skipHydration: true` and rehydrate after mount:

```tsx
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { useEffect } from 'react';

export const useCartStore = create<{ items: string[] }>()(
  persist(() => ({ items: [] }), { name: 'cart', skipHydration: true }),
);

// Render once near the root
export function CartHydrator() {
  useEffect(() => {
    void useCartStore.persist.rehydrate();
  }, []);
  return null;
}
```

Use `useCartStore.persist.hasHydrated()` and `useCartStore.persist.onFinishHydration(cb)` to show a placeholder until stored data arrives. See `state-zustand.md` for persistence options.

**Jotai `atomWithStorage`** defaults to `getOnInit: false`: the atom starts at `initialValue` on both server and client and switches to the stored value after mount, so the user sees the default briefly. Do not set `getOnInit: true` in server-rendered apps, because the first client render then reads storage and mismatches. The Jotai docs recommend rendering markup that depends on the stored value (such as a `className`) only on the client.

```tsx
import { atomWithStorage } from 'jotai/utils';

// Hydration-safe default: initial value first, stored value after mount
export const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light');
```

## Reading the Hydration Error

React 19 logs one error per mismatch with a diff, instead of several vague warnings:

```text
Uncaught Error: Hydration failed because the server rendered HTML didn't match the client.
As a result this tree will be regenerated on the client. This can happen if an SSR-ed
Client Component used:
- A server/client branch `if (typeof window !== 'undefined')`.
- Variable input such as `Date.now()` or `Math.random()` which changes each time it's called.
- Date formatting in a user's locale which doesn't match the server.
- External changing data without sending a snapshot of it along with the HTML.
- Invalid HTML tag nesting.

It can also happen if the client has a browser extension installed which messes with
the HTML before React loaded.
https://react.dev/link/hydration-mismatch
  <App>
    <Header>
      <span>
+       Client
-       Server
```

Read it like this:

- The indented tree is the component path to the mismatch. The innermost component name is where to look.
- Lines starting with `+` are what the client rendered; lines starting with `-` are what the server HTML contained.
- An attribute diff (for example `+ className="dark"` / `- className="light"`) points to a browser-only value or a persisted store.
- A diff where the server side contains an element the client does not usually means invalid nesting or an extension.

To debug: view the page source (the raw server HTML, not DevTools Elements), find the node from the diff, and compare it with what the component renders on the client. Report production mismatches with `onRecoverableError` on `hydrateRoot` (see [Errors in Render Are Not Re-Thrown](#errors-in-render-are-not-re-thrown)), since production builds log a minified message without the diff.
