# React Hooks Complete Guide

State, effect, context, and ref hooks, custom-hook summaries, and the Rules of Hooks.

## Contents

- [Quick Reference](#quick-reference)
- [State Hooks](#state-hooks)
- [Effect Hooks](#effect-hooks)
- [Context Hook](#context-hook)
- [Ref Hooks](#ref-hooks)
- [Performance Hooks and React 19 Hooks](#performance-hooks-and-react-19-hooks)
- [Custom Hooks](#custom-hooks)
- [Avoiding Unnecessary Effects](#avoiding-unnecessary-effects)
- [Rules of Hooks](#rules-of-hooks)
- [Additional References](#additional-references)

## Quick Reference

| Hook | Purpose | Example |
|------|---------|---------|
| `useState` | Local state | `const [count, setCount] = useState(0)` |
| `useReducer` | Complex state | `const [state, dispatch] = useReducer(reducer, init)` |
| `useEffect` | Side effects | `useEffect(() => { ... }, [deps])` |
| `useRef` | Mutable ref / DOM | `const ref = useRef<HTMLInputElement>(null)` |
| `useContext` | Consume context | `const value = useContext(MyContext)` |
| `useMemo` | Memoize value | `const computed = useMemo(() => calc(), [deps])` |
| `useCallback` | Stable function | `const fn = useCallback(() => {}, [deps])` |

| Concurrent Hook (React 18+) | Purpose |
|-----------------------------|---------|
| `useTransition` | Non-blocking updates (React 19 adds async transitions) |
| `useDeferredValue` | Defer expensive renders (React 19 adds an initial value) |

| React 19 Hook | Purpose |
|---------------|---------|
| `useActionState` | Action state (forms, Server Actions) |
| `useOptimistic` | Optimistic UI updates |
| `useFormStatus` | Form pending state (from `react-dom`) |
| `use` | Read promises/context during render |

## State Hooks

### useState

```tsx
import { useState } from 'react';

// Basic usage
const [count, setCount] = useState(0);

// With initial function (lazy initialization)
const [state, setState] = useState(() => {
  const initialValue = expensiveComputation();
  return initialValue;
});

// Object state
const [user, setUser] = useState<User | null>(null);

// Updating object state (always create new reference)
setUser((prev) => prev ? { ...prev, name: 'New Name' } : null);

// Array state
const [items, setItems] = useState<Item[]>([]);

// Add item
setItems((prev) => [...prev, newItem]);

// Remove item
setItems((prev) => prev.filter((item) => item.id !== id));

// Update item
setItems((prev) =>
  prev.map((item) => (item.id === id ? { ...item, ...updates } : item))
);
```

### useReducer

```tsx
import { useReducer } from 'react';

// Define state and action types
interface State {
  count: number;
  error: string | null;
  loading: boolean;
}

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset'; payload: number }
  | { type: 'setError'; payload: string };

// Reducer function
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + 1 };
    case 'decrement':
      return { ...state, count: state.count - 1 };
    case 'reset':
      return { ...state, count: action.payload };
    case 'setError':
      return { ...state, error: action.payload };
    default:
      return state;
  }
}

// Usage
function Counter() {
  const [state, dispatch] = useReducer(reducer, {
    count: 0,
    error: null,
    loading: false,
  });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'reset', payload: 0 })}>
        Reset
      </button>
    </div>
  );
}
```

### useReducer with Immer

```tsx
import { useReducer } from 'react';
import { produce } from 'immer';

interface Todo {
  id: number;
  text: string;
  completed: boolean;
}

type Action =
  | { type: 'add'; text: string }
  | { type: 'toggle'; id: number }
  | { type: 'delete'; id: number };

function todosReducer(state: Todo[], action: Action): Todo[] {
  return produce(state, (draft) => {
    switch (action.type) {
      case 'add':
        draft.push({
          id: Date.now(),
          text: action.text,
          completed: false,
        });
        break;
      case 'toggle': {
        const todo = draft.find((t) => t.id === action.id);
        if (todo) todo.completed = !todo.completed;
        break;
      }
      case 'delete': {
        const index = draft.findIndex((t) => t.id === action.id);
        if (index !== -1) draft.splice(index, 1);
        break;
      }
    }
  });
}
```

## Effect Hooks

### useEffect

```tsx
import { useEffect, useState } from 'react';

function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();

    async function fetchUser() {
      // Reset state for the new userId so the previous user is not shown
      setUser(null);
      setError(null);
      setLoading(true);
      try {
        const response = await fetch(`/api/users/${userId}`, {
          signal: controller.signal,
        });
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data: User = await response.json();
        setUser(data);
        setLoading(false);
      } catch (err) {
        // Ignore aborts caused by a userId change or unmount
        if (controller.signal.aborted) return;
        setError(err instanceof Error ? err : new Error('Unknown error'));
        setLoading(false);
      }
    }

    fetchUser();

    // Cleanup: abort the in-flight request
    return () => controller.abort();
  }, [userId]); // Re-run when userId changes

  if (loading) return <p>Loading...</p>;
  if (error) return <p role="alert">Failed to load user: {error.message}</p>;
  if (!user) return <p>User not found</p>;
  return <div>{user.name}</div>;
}
```

### useLayoutEffect

```tsx
import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';

function Tooltip({ text, children }: { text: string; children: ReactNode }) {
  const [tooltipHeight, setTooltipHeight] = useState(0);
  const tooltipRef = useRef<HTMLDivElement>(null);

  // Runs synchronously after DOM mutations but before paint
  useLayoutEffect(() => {
    if (tooltipRef.current) {
      setTooltipHeight(tooltipRef.current.getBoundingClientRect().height);
    }
  }, [text]);

  return (
    <div className="tooltip-container">
      {children}
      <div
        ref={tooltipRef}
        className="tooltip"
        style={{ top: -tooltipHeight - 10 }}
      >
        {text}
      </div>
    </div>
  );
}
```

### useInsertionEffect (for CSS-in-JS libraries)

```tsx
import { useInsertionEffect } from 'react';

// For CSS-in-JS library authors
function useCSS(rule: string) {
  useInsertionEffect(() => {
    const style = document.createElement('style');
    style.textContent = rule;
    document.head.appendChild(style);
    return () => {
      document.head.removeChild(style);
    };
  }, [rule]);
}
```

## Context Hook

### useContext

```tsx
import { createContext, useContext, useState, type ReactNode } from 'react';

export interface User {
  id: string;
  name: string;
  email: string;
}

// Exported so tests and other modules can type context values
export interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
}

// Exported so tests can render consumers with an explicit value
export const AuthContext = createContext<AuthContextType | null>(null);

// Provider component
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (email: string, password: string) => {
    // The server sets an httpOnly session cookie; the client keeps only the user profile
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    if (!response.ok) throw new Error('Login failed');
    const userData: User = await response.json();
    setUser(userData);
  };

  const logout = async () => {
    // Only the server can clear the httpOnly session cookie
    const response = await fetch('/api/logout', { method: 'POST' });
    if (!response.ok) throw new Error('Logout failed');
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        login,
        logout,
        isAuthenticated: !!user,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// Custom hook for using context
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

// Usage
function LoginButton() {
  const { isAuthenticated, logout, user } = useAuth();
  const [logoutError, setLogoutError] = useState<string | null>(null);

  const handleLogout = async () => {
    setLogoutError(null);
    try {
      await logout();
    } catch {
      setLogoutError('Could not log out. Please try again.');
    }
  };

  if (isAuthenticated) {
    return (
      <div>
        <span>Welcome, {user?.name}</span>
        <button onClick={handleLogout}>Logout</button>
        {logoutError && <p role="alert">{logoutError}</p>}
      </div>
    );
  }

  return <a href="/login">Login</a>;
}
```

## Ref Hooks

### useRef

```tsx
import { useRef, useEffect, useState } from 'react';

// DOM reference
function TextInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  return <input ref={inputRef} type="text" />;
}

// Mutable value (doesn't trigger re-render)
function Timer() {
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const [count, setCount] = useState(0);

  const startTimer = () => {
    if (intervalRef.current) return;
    intervalRef.current = setInterval(() => {
      setCount((c) => c + 1);
    }, 1000);
  };

  const stopTimer = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  };

  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={startTimer}>Start</button>
      <button onClick={stopTimer}>Stop</button>
    </div>
  );
}
```

### useImperativeHandle

In React 19, `ref` is a regular prop for function components, so `forwardRef` is not needed.

```tsx
import { useImperativeHandle, useRef, Ref } from 'react';

interface VideoPlayerHandle {
  play: () => void;
  pause: () => void;
  seek: (time: number) => void;
}

function VideoPlayer({ src, ref }: { src: string; ref?: Ref<VideoPlayerHandle> }) {
  const videoRef = useRef<HTMLVideoElement>(null);

  useImperativeHandle(ref, () => ({
    play() {
      videoRef.current?.play();
    },
    pause() {
      videoRef.current?.pause();
    },
    seek(time: number) {
      if (videoRef.current) {
        videoRef.current.currentTime = time;
      }
    },
  }));

  return <video ref={videoRef} src={src} />;
}

// Usage
function App() {
  const playerRef = useRef<VideoPlayerHandle>(null);

  return (
    <div>
      <VideoPlayer ref={playerRef} src="/video.mp4" />
      <button onClick={() => playerRef.current?.play()}>Play</button>
      <button onClick={() => playerRef.current?.pause()}>Pause</button>
      <button onClick={() => playerRef.current?.seek(30)}>Skip to 30s</button>
    </div>
  );
}
```

React 18 fallback only: wrap the component in `forwardRef<VideoPlayerHandle, { src: string }>((props, ref) => ...)`.

### Ref Callbacks with Cleanup

In React 19 a ref callback may return a cleanup function. React calls it when the element detaches, so per-element setup no longer needs a separate effect.

```tsx
function AutoSizeBox({ onResize, children }: { onResize: (rect: DOMRectReadOnly) => void; children: ReactNode }) {
  return (
    <div
      ref={(node) => {
        if (!node) return;
        const observer = new ResizeObserver(([entry]) => onResize(entry.contentRect));
        observer.observe(node);
        return () => observer.disconnect();
      }}
    >
      {children}
    </div>
  );
}
```

- Use a block body. An arrow that implicitly returns an assignment (`ref={(n) => (x = n)}`) is a type error in React 19.
- An inline callback is a new function on every render, so React runs cleanup and setup again each render. That is fine for cheap work. For expensive setup, hoist the callback or wrap it in `useCallback` with the real dependencies.

## Performance Hooks and React 19 Hooks

Detailed coverage of `useMemo`, `useCallback`, the concurrent hooks `useTransition` and `useDeferredValue` (React 18+), and React 19 hooks such as `useActionState`, `useOptimistic`, `useFormStatus`, and `use` lives in `hooks-performance-and-react-19.md`. Load that reference when optimizing renders, handling transitions/deferred values, or wiring React 19 forms and async resources.

## Custom Hooks

Full, canonical implementations live in `hooks-custom-library.md`. Use these summaries to pick a hook, then copy it from there.

### useLocalStorage

See `hooks-custom-library.md` → `useLocalStorage`. It uses `useSyncExternalStore` so the server render and hydration use `initialValue` (no hydration mismatch), syncs across hooks and tabs, and supports functional updates against the latest stored value.

```tsx
const [theme, setTheme] = useLocalStorage<'light' | 'dark'>('theme', 'light');
<button onClick={() => setTheme((t) => (t === 'light' ? 'dark' : 'light'))}>Toggle</button>
```

Do not read `localStorage` in a `useState` initializer in server-rendered apps: the server and client render different markup and hydration fails.

### useDebounce

See `hooks-custom-library.md` → `useDebounce`. The core is a timeout that is cleared on every change:

```tsx
function SearchInput() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);

  // Fetch with debouncedQuery (see useFetch or TanStack Query)
  return (
    <input
      type="search"
      aria-label="Search"
      value={query}
      onChange={(e) => setQuery(e.target.value)}
    />
  );
}
```

### useFetch

See `hooks-custom-library.md` → `useFetch`. Prefer TanStack Query or SWR for server data. A hand-written fetch effect must:

- abort the previous request with an `AbortController` (or an ignore flag) in the cleanup,
- ignore `AbortError`,
- check `res.ok` and treat other statuses as errors,
- reset `loading`/`error` (and stale data) when the URL changes.

### useMediaQuery

See `hooks-custom-library.md` → `useMediaQuery` (built on `useSyncExternalStore`, with a server fallback value).

```tsx
function App() {
  const isMobile = useMediaQuery('(max-width: 768px)');
  return isMobile ? <MobileNav /> : <DesktopNav />;
}
```

### useDebugValue

Label a custom hook's state in React DevTools. Pass a formatter when formatting is costly; it runs only when DevTools inspects the hook.

```tsx
import { useDebugValue, useSyncExternalStore } from 'react';

function useOnlineStatus() {
  const isOnline = useSyncExternalStore(subscribe, () => navigator.onLine, () => true);
  useDebugValue(isOnline, (online) => (online ? 'Online' : 'Offline'));
  return isOnline;
}
```

## Avoiding Unnecessary Effects

Effects synchronize with systems outside React (network, DOM APIs, timers, subscriptions). Most other uses add an extra render and a chance for bugs.

| Instead of an effect that... | Do this |
|------------------------------|---------|
| Sets state derived from props or other state | Compute it during render |
| Resets all state when a prop changes | Pass that prop as `key` to the component |
| Runs logic after a user action | Run it in the event handler |
| Notifies a parent of a state change | Call the parent's callback in the same handler that sets state |
| Fetches data in a framework | Fetch on the server, or use TanStack Query or SWR |

```tsx
// Avoid: extra render, and visibleTodos lags one render behind
const [visibleTodos, setVisibleTodos] = useState<Todo[]>([]);
useEffect(() => {
  setVisibleTodos(todos.filter((t) => !t.completed));
}, [todos]);

// Do: derive during render
const visibleTodos = todos.filter((t) => !t.completed);

// Reset a whole subtree's state when the user changes, instead of an effect that clears fields
<ProfileEditor key={userId} userId={userId} />
```

### Stale Closures

A callback created in one render sees that render's values. Timers and subscriptions set up once keep reading the first render's state.

```tsx
// Bug: count is always the initial value inside the interval
useEffect(() => {
  const id = setInterval(() => setCount(count + 1), 1000);
  return () => clearInterval(id);
}, []);

// Fix: functional update, no dependency on count
useEffect(() => {
  const id = setInterval(() => setCount((c) => c + 1), 1000);
  return () => clearInterval(id);
}, []);
```

List every reactive value the effect reads in the dependency array and keep `react-hooks/exhaustive-deps` on. An effect that sets state it also depends on (`setData(process(data))` with `[data]`) loops forever: derive the value during render instead.

### useEffectEvent (React 19.2+)

When an effect must read the latest value of something without re-running when it changes, move that read into an Effect Event.

```tsx
import { useEffect, useEffectEvent } from 'react';

function ChatRoom({ roomId, theme }: { roomId: string; theme: 'light' | 'dark' }) {
  const onConnected = useEffectEvent(() => {
    showToast(`Connected to ${roomId}`, theme); // always reads the latest theme
  });

  useEffect(() => {
    const connection = createConnection(roomId);
    connection.on('connected', () => onConnected());
    connection.connect();
    return () => connection.disconnect();
  }, [roomId]); // theme changes do not reconnect

  return null;
}
```

Call Effect Events only from inside effects, never during render or from event handlers, and do not list them as dependencies.

## Rules of Hooks

1. **Only call hooks at the top level** - Don't call in loops, conditions, or nested functions
2. **Only call hooks from React functions** - Call from components or custom hooks
3. **Start custom hook names with "use"** - Convention that enables linting

```tsx
// Bad - conditional hook call
function Bad({ condition }) {
  if (condition) {
    const [state, setState] = useState(0); // Error!
  }
}

// Good - call hook unconditionally
function Good({ condition }) {
  const [state, setState] = useState(0);
  if (condition) {
    // Use state here
  }
}
```

## Additional References

For production-ready custom hook implementations, see:

- `hooks-custom-library.md` - Complete library of reusable custom hooks
