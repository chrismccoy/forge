# Custom Hooks Library

Production-ready custom hooks for common React patterns.

This file is the canonical source for these hooks. Other references (`hooks.md`, `examples.md`, `workflows/hook.md`) show excerpts or point here; when they differ, follow this file.

## Contents

- [Data Fetching Hooks](#data-fetching-hooks)
- [State Management Hooks](#state-management-hooks)
- [UI Interaction Hooks](#ui-interaction-hooks)
- [DOM Hooks](#dom-hooks)
- [Form Hooks](#form-hooks)

## Data Fetching Hooks

For server data in real applications, prefer a data-fetching library such as TanStack Query or SWR: they handle caching, deduplication, retries, and revalidation that a hand-written hook does not. Use `useFetch` for small apps or as a reference for correct effect-based fetching.

### useFetch - Generic Fetch Hook

```tsx
import { useCallback, useEffect, useRef, useState } from 'react';

interface UseFetchOptions<T> {
  onSuccess?: (data: T) => void;
  onError?: (error: Error) => void;
}

interface UseFetchResult<T> {
  data: T | null;
  error: Error | null;
  loading: boolean;
  refetch: () => void;
}

/**
 * Fetch JSON from `url`. Pass `null` to skip fetching.
 * Aborts the in-flight request when `url` changes or the component unmounts.
 */
export function useFetch<T>(
  url: string | null,
  options: UseFetchOptions<T> = {}
): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(url !== null);
  const [reloadToken, setReloadToken] = useState(0);

  // Keep the latest callbacks without making them effect dependencies,
  // so inline callbacks do not trigger a refetch on every render.
  // On React 19.2+, useEffectEvent replaces this ref pattern (see hooks.md).
  const callbacksRef = useRef(options);
  useEffect(() => {
    callbacksRef.current = options;
  });

  useEffect(() => {
    if (url === null) {
      setLoading(false);
      return;
    }

    const controller = new AbortController();

    // Reset state for the new key so stale data/errors are not shown
    setData(null);
    setError(null);
    setLoading(true);

    fetch(url, { signal: controller.signal })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json() as Promise<T>;
      })
      .then((result) => {
        if (controller.signal.aborted) return;
        setData(result);
        setLoading(false);
        callbacksRef.current.onSuccess?.(result);
      })
      .catch((err: unknown) => {
        // Ignore aborts caused by a URL change or unmount
        if (controller.signal.aborted) return;
        if (err instanceof Error && err.name === 'AbortError') return;
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setLoading(false);
        callbacksRef.current.onError?.(error);
      });

    return () => controller.abort();
  }, [url, reloadToken]);

  // Stable identity: callers may list refetch in effect dependencies
  const refetch = useCallback(() => setReloadToken((n) => n + 1), []);

  return { data, error, loading, refetch };
}
```

**Usage:**
```tsx
function UserProfile({ userId }: { userId: string }) {
  const { data: user, loading, error, refetch } = useFetch<User>(
    `/api/users/${userId}`,
    {
      onSuccess: (user) => console.log('Loaded:', user.name),
      onError: (err) => console.error('Failed:', err.message),
    }
  );

  if (loading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} onRetry={refetch} />;
  if (!user) return null;

  return <UserCard user={user} />;
}
```

### useAsync - Generic Async Operation Hook

```tsx
import { useCallback, useEffect, useRef, useState } from 'react';

type AsyncFunction<T, Args extends unknown[]> = (...args: Args) => Promise<T>;

interface UseAsyncResult<T, Args extends unknown[]> {
  data: T | null;
  error: Error | null;
  loading: boolean;
  execute: (...args: Args) => Promise<T | null>;
  reset: () => void;
}

export function useAsync<T, Args extends unknown[] = []>(
  asyncFunction: AsyncFunction<T, Args>
): UseAsyncResult<T, Args> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(false);

  // Only the most recent call may update state, so a slow earlier
  // response cannot overwrite the result of a newer call.
  const callIdRef = useRef(0);

  // Keep the latest function so an inline asyncFunction does not change execute
  const fnRef = useRef(asyncFunction);
  useEffect(() => {
    fnRef.current = asyncFunction;
  });

  // execute and reset are memoized because callers often put them in
  // effect dependencies
  const execute = useCallback(
    async (...args: Args): Promise<T | null> => {
      const callId = ++callIdRef.current;
      setLoading(true);
      setError(null);

      try {
        const result = await fnRef.current(...args);
        if (callId !== callIdRef.current) return null; // superseded
        setData(result);
        setLoading(false);
        return result;
      } catch (err) {
        if (callId !== callIdRef.current) return null; // superseded
        const error = err instanceof Error ? err : new Error('Unknown error');
        setError(error);
        setLoading(false);
        return null;
      }
    },
    []
  );

  const reset = useCallback(() => {
    callIdRef.current++; // ignore any call still in flight
    setData(null);
    setError(null);
    setLoading(false);
  }, []);

  return { data, error, loading, execute, reset };
}
```

**Usage:**
```tsx
function CreatePostForm({ onCreated }: { onCreated: (id: string) => void }) {
  const { execute, loading, error } = useAsync(async (formData: FormData) => {
    const response = await fetch('/api/posts', {
      method: 'POST',
      body: formData,
    });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json() as Promise<{ id: string }>;
  });

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const result = await execute(new FormData(e.currentTarget));
    if (result) {
      onCreated(result.id); // e.g. navigate with the app's router
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {error && <Alert variant="error">{error.message}</Alert>}
      <label>
        Title
        <input name="title" required />
      </label>
      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

## State Management Hooks

### useLocalStorage - Persistent State

SSR-safe persistent state built on `useSyncExternalStore`. The server snapshot (and the first client render during hydration) uses `initialValue`, so server and client markup match; React then re-renders with the stored value. Changes sync across hooks in the same tab (custom event) and across tabs (`storage` event).

```tsx
import { useCallback, useMemo, useState, useSyncExternalStore } from 'react';

const LOCAL_STORAGE_EVENT = 'local-storage';

function subscribe(onChange: () => void) {
  window.addEventListener('storage', onChange); // other tabs
  window.addEventListener(LOCAL_STORAGE_EVENT, onChange); // this tab
  return () => {
    window.removeEventListener('storage', onChange);
    window.removeEventListener(LOCAL_STORAGE_EVENT, onChange);
  };
}

function readRaw(key: string): string | null {
  try {
    return window.localStorage.getItem(key);
  } catch {
    return null; // storage unavailable (privacy mode, blocked)
  }
}

function parse<T>(raw: string | null, fallback: T): T {
  if (raw === null) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

export function useLocalStorage<T>(
  key: string,
  initialValue: T
): [T, (value: T | ((prev: T) => T)) => void, () => void] {
  // Like useState, only the first initialValue is used, so passing an
  // inline object or array does not cause extra work.
  const [fallback] = useState(initialValue);

  // The snapshot is the raw string: strings compare by value, so
  // useSyncExternalStore does not see a "new" snapshot on every read
  // (returning a freshly parsed object here would loop forever).
  const raw = useSyncExternalStore(
    subscribe,
    () => readRaw(key),
    () => null // server snapshot: no storage, fall back to initialValue
  );

  // Memoized so an object value keeps its identity between renders and is
  // safe in consumers' dependency arrays; setValue/removeValue likewise
  const value = useMemo(() => parse(raw, fallback), [raw, fallback]);

  const setValue = useCallback(
    (next: T | ((prev: T) => T)) => {
      try {
        // Read the latest stored value, not a value captured by a closure
        const prev = parse(readRaw(key), fallback);
        const newValue =
          typeof next === 'function' ? (next as (prev: T) => T)(prev) : next;
        window.localStorage.setItem(key, JSON.stringify(newValue));
        window.dispatchEvent(new Event(LOCAL_STORAGE_EVENT));
      } catch (error) {
        console.warn(`Error setting localStorage key "${key}":`, error);
      }
    },
    [key, fallback]
  );

  const removeValue = useCallback(() => {
    try {
      window.localStorage.removeItem(key);
      window.dispatchEvent(new Event(LOCAL_STORAGE_EVENT));
    } catch (error) {
      console.warn(`Error removing localStorage key "${key}":`, error);
    }
  }, [key]);

  return [value, setValue, removeValue];
}
```

**Usage:**
```tsx
function Settings() {
  const [theme, setTheme, removeTheme] = useLocalStorage<'light' | 'dark'>('theme', 'light');

  return (
    <div>
      <select value={theme} onChange={(e) => setTheme(e.target.value as 'light' | 'dark')}>
        <option value="light">Light</option>
        <option value="dark">Dark</option>
      </select>
      <button onClick={() => setTheme((prev) => (prev === 'light' ? 'dark' : 'light'))}>
        Toggle
      </button>
      <button onClick={removeTheme}>Reset to default</button>
    </div>
  );
}
```

Notes:
- localStorage is the single source of truth. If a write fails (quota exceeded, storage blocked), the value does not change.
- Values must be JSON-serializable. Never store auth tokens or other secrets in localStorage.
- Content that depends on the stored value renders with `initialValue` on the server and during hydration, then updates on the client.

### usePrevious - Track Previous Value

Store the previous value in state and update it during render when the value changes (the React docs pattern for storing information from previous renders). Reading `ref.current` during render is not allowed: it breaks under concurrent rendering and the React Compiler.

```tsx
import { useState } from 'react';

/**
 * Returns the value from before the most recent change of `value`
 * (`undefined` until it first changes). Re-renders that leave `value`
 * unchanged keep the same previous value.
 */
export function usePrevious<T>(value: T): T | undefined {
  const [current, setCurrent] = useState(value);
  const [previous, setPrevious] = useState<T | undefined>(undefined);

  if (!Object.is(value, current)) {
    // Setting state during render: React discards this render's output
    // and re-renders immediately, before updating the DOM.
    setPrevious(current);
    setCurrent(value);
  }

  return previous;
}
```

**Usage:**
```tsx
function PriceDisplay({ price }: { price: number }) {
  const previousPrice = usePrevious(price);
  const priceChange = previousPrice !== undefined ? price - previousPrice : 0;

  return (
    <div>
      <span>${price.toFixed(2)}</span>
      {priceChange !== 0 && (
        <span className={priceChange > 0 ? 'text-green-500' : 'text-red-500'}>
          {priceChange > 0 ? '+' : ''}{priceChange.toFixed(2)}
        </span>
      )}
    </div>
  );
}
```

### useToggle - Boolean State with Named Actions

```tsx
import { useState } from 'react';

// Plain functions are enough here. Memoize them only if a consumer passes them
// to a memo() child or lists them in effect dependencies.
export function useToggle(initialValue = false) {
  const [value, setValue] = useState(initialValue);

  const toggle = () => setValue((v) => !v);
  const setTrue = () => setValue(true);
  const setFalse = () => setValue(false);

  return { value, toggle, setTrue, setFalse, setValue };
}
```

## UI Interaction Hooks

### useDebounce - Debounced Value

```tsx
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(timer);
    };
  }, [value, delay]);

  return debouncedValue;
}
```

### useThrottle - Throttled Value

Updates at most once per `interval`. A change outside the window applies immediately; a change inside the window is scheduled for the time remaining, so the latest (trailing) value always lands. Unlike `useDebounce`, continuous changes still produce regular updates.

```tsx
import { useState, useEffect, useRef } from 'react';

export function useThrottle<T>(value: T, interval = 500): T {
  const [throttledValue, setThrottledValue] = useState<T>(value);
  // 0 means "never updated", so the first change outside a window applies at once
  const lastExecuted = useRef(0);

  useEffect(() => {
    const elapsed = Date.now() - lastExecuted.current;

    if (elapsed >= interval) {
      lastExecuted.current = Date.now();
      setThrottledValue(value);
      return;
    }

    // Inside the window: schedule the trailing value for the remaining time.
    // A newer value replaces this timer but keeps the same deadline.
    const timer = setTimeout(() => {
      lastExecuted.current = Date.now();
      setThrottledValue(value);
    }, interval - elapsed);

    return () => clearTimeout(timer);
  }, [value, interval]);

  return throttledValue;
}
```

### useClickOutside - Detect Outside Clicks

```tsx
import { useEffect, useRef, RefObject } from 'react';

export function useClickOutside<T extends HTMLElement>(
  handler: () => void
): RefObject<T | null> {
  const ref = useRef<T>(null);

  // Keep the latest handler so an inline callback does not resubscribe
  const handlerRef = useRef(handler);
  useEffect(() => {
    handlerRef.current = handler;
  });

  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      const target = event.target as Node;
      if (!ref.current || ref.current.contains(target)) {
        return;
      }
      handlerRef.current();
    };

    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);

    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, []);

  return ref;
}
```

**Usage:**
```tsx
function Dropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useClickOutside<HTMLDivElement>(() => setIsOpen(false));

  return (
    <div ref={dropdownRef}>
      <button onClick={() => setIsOpen(!isOpen)}>Menu</button>
      {isOpen && (
        <ul className="dropdown-menu">
          <li>Option 1</li>
          <li>Option 2</li>
        </ul>
      )}
    </div>
  );
}
```

### useMediaQuery - Responsive Design

```tsx
import { useCallback, useSyncExternalStore } from 'react';

/**
 * Subscribe to a CSS media query. `serverFallback` is used on the server
 * and during hydration, so markup matches; the real value follows on the client.
 */
export function useMediaQuery(query: string, serverFallback = false): boolean {
  // useSyncExternalStore resubscribes whenever subscribe changes identity
  const subscribe = useCallback(
    (onChange: () => void) => {
      const mediaQuery = window.matchMedia(query);
      mediaQuery.addEventListener('change', onChange);
      return () => mediaQuery.removeEventListener('change', onChange);
    },
    [query]
  );

  return useSyncExternalStore(
    subscribe,
    () => window.matchMedia(query).matches,
    () => serverFallback
  );
}

// Convenience hooks
export function useIsMobile() {
  return useMediaQuery('(max-width: 768px)');
}

export function useIsDesktop() {
  return useMediaQuery('(min-width: 1024px)');
}

export function usePrefersDarkMode() {
  return useMediaQuery('(prefers-color-scheme: dark)');
}
```

### useKeyPress - Keyboard Shortcuts

```tsx
import { useEffect, useRef } from 'react';

interface UseKeyPressOptions {
  /** Cmd on macOS, Ctrl elsewhere: matches when either key is held */
  mod?: boolean;
  ctrl?: boolean;
  alt?: boolean;
  shift?: boolean;
  meta?: boolean;
  preventDefault?: boolean;
  /** Also fire while focus is in an input, textarea, select, or contentEditable element */
  allowInInputs?: boolean;
}

function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;
  return (
    target.isContentEditable ||
    target instanceof HTMLInputElement ||
    target instanceof HTMLTextAreaElement ||
    target instanceof HTMLSelectElement
  );
}

export function useKeyPress(
  key: string,
  callback: (event: KeyboardEvent) => void,
  options: UseKeyPressOptions = {}
): void {
  const {
    mod = false,
    ctrl = false,
    alt = false,
    shift = false,
    meta = false,
    preventDefault = true,
    allowInInputs = false,
  } = options;

  // Keep the latest callback so an inline function does not resubscribe
  const callbackRef = useRef(callback);
  useEffect(() => {
    callbackRef.current = callback;
  });

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Do not hijack typing: plain shortcuts are ignored in editable fields
      if (!allowInInputs && isEditableTarget(event.target)) return;
      if (event.key.toLowerCase() !== key.toLowerCase()) return;

      // Each modifier must match exactly, so plain `k` does not fire on Cmd+K
      const wantCtrl = ctrl || (mod && !event.metaKey);
      const wantMeta = meta || (mod && event.metaKey);
      const modifiersMatch =
        (!mod || event.metaKey || event.ctrlKey) &&
        event.ctrlKey === wantCtrl &&
        event.metaKey === wantMeta &&
        event.altKey === alt &&
        event.shiftKey === shift;

      if (!modifiersMatch) return;

      if (preventDefault) {
        event.preventDefault();
      }
      callbackRef.current(event);
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [key, mod, ctrl, alt, shift, meta, preventDefault, allowInInputs]);
}
```

Shortcuts such as `?` already require Shift on most layouts; pass `shift: true` for them. To let a shortcut work while typing (for example Escape or Cmd/Ctrl+Enter in a text box), pass `allowInInputs: true`.

**Usage:**
```tsx
function SearchModal() {
  const [isOpen, setIsOpen] = useState(false);

  // Cmd/Ctrl + K to open, even from a text field
  useKeyPress('k', () => setIsOpen(true), { mod: true, allowInInputs: true });

  // Escape to close, including while the search input has focus
  useKeyPress('Escape', () => setIsOpen(false), { allowInInputs: true });

  return isOpen ? <Modal>...</Modal> : null;
}
```

## DOM Hooks

### useIntersectionObserver - Lazy Loading & Infinite Scroll

Return a callback ref and keep the element in state, so observation starts whenever the node attaches, including a node that mounts after the first render.

```tsx
import { useEffect, useState } from 'react';

interface UseIntersectionObserverOptions {
  /** Pass a constant (not an inline array), or the observer restarts every render */
  threshold?: number | number[];
  root?: Element | null;
  rootMargin?: string;
  freezeOnceVisible?: boolean;
}

export function useIntersectionObserver<T extends Element>(
  options: UseIntersectionObserverOptions = {}
): [(node: T | null) => void, boolean] {
  const {
    threshold = 0,
    root = null,
    rootMargin = '0px',
    freezeOnceVisible = false,
  } = options;

  const [element, setElement] = useState<T | null>(null);
  const [isVisible, setIsVisible] = useState(false);
  const frozen = freezeOnceVisible && isVisible;

  useEffect(() => {
    if (!element || frozen) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsVisible(entry.isIntersecting);
      },
      { threshold, root, rootMargin }
    );

    observer.observe(element);

    return () => {
      observer.disconnect();
    };
  }, [element, threshold, root, rootMargin, frozen]);

  // setElement is stable, so React does not detach and reattach it
  return [setElement, isVisible];
}
```

**Usage:**
```tsx
function LazyImage({ src, alt }: { src: string; alt: string }) {
  const [ref, isVisible] = useIntersectionObserver<HTMLDivElement>({
    freezeOnceVisible: true,
    rootMargin: '100px',
  });

  return (
    <div ref={ref}>
      {isVisible ? (
        <img src={src} alt={alt} />
      ) : (
        <div className="placeholder" />
      )}
    </div>
  );
}
```

### useScrollPosition - Track Scroll

```tsx
import { useState, useEffect } from 'react';

interface ScrollPosition {
  x: number;
  y: number;
}

export function useScrollPosition(): ScrollPosition {
  const [position, setPosition] = useState<ScrollPosition>({ x: 0, y: 0 });

  useEffect(() => {
    const handleScroll = () => {
      setPosition({
        x: window.scrollX,
        y: window.scrollY,
      });
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // Initial position

    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return position;
}
```

### useWindowSize - Track Window Dimensions

SSR-safe: the server snapshot (and the first client render during hydration) uses `serverSize`, then React re-renders with the real size.

```tsx
import { useSyncExternalStore } from 'react';

interface WindowSize {
  width: number;
  height: number;
}

function subscribe(onChange: () => void) {
  window.addEventListener('resize', onChange);
  return () => window.removeEventListener('resize', onChange);
}

export function useWindowSize(
  serverSize: WindowSize = { width: 0, height: 0 }
): WindowSize {
  // One store per dimension: each snapshot is a number, which compares by
  // value. Returning a new { width, height } object from getSnapshot would
  // make every read look like a change and loop forever.
  const width = useSyncExternalStore(
    subscribe,
    () => window.innerWidth,
    () => serverSize.width
  );
  const height = useSyncExternalStore(
    subscribe,
    () => window.innerHeight,
    () => serverSize.height
  );

  return { width, height };
}
```

## Form Hooks

### useForm - Simple Form State

```tsx
import { useState, ChangeEvent, FocusEvent, FormEvent } from 'react';

interface UseFormOptions<T> {
  initialValues: T;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
  /** Throw (or reject) to report a failure; the message is exposed as `submitError` */
  onSubmit: (values: T) => void | Promise<void>;
}

// Handlers are plain functions: they read `values`, which changes on every
// keystroke, so memoizing them would not keep them stable anyway.
export function useForm<T extends Record<string, unknown>>({
  initialValues,
  validate,
  onSubmit,
}: UseFormOptions<T>) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value, type } = e.target;
    const newValue = type === 'checkbox'
      ? (e.target as HTMLInputElement).checked
      : value;
    const nextValues = { ...values, [name]: newValue };

    setValues(nextValues);

    if (touched[name as keyof T] && validate) {
      const validationErrors = validate(nextValues);
      setErrors((prev) => ({ ...prev, [name]: validationErrors[name as keyof T] }));
    }
  };

  const handleBlur = (
    e: FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name } = e.target;
    setTouched((prev) => ({ ...prev, [name]: true }));

    if (validate) {
      const validationErrors = validate(values);
      setErrors((prev) => ({ ...prev, [name]: validationErrors[name as keyof T] }));
    }
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSubmitError(null);

    // Mark every field touched so all errors show, not only visited fields
    const allTouched = Object.fromEntries(
      Object.keys(values).map((key) => [key, true])
    ) as Partial<Record<keyof T, boolean>>;
    setTouched(allTouched);

    if (validate) {
      const validationErrors = validate(values);
      setErrors(validationErrors);

      if (Object.values(validationErrors).some(Boolean)) {
        return;
      }
    }

    setIsSubmitting(true);
    try {
      await onSubmit(values);
    } catch (error) {
      setSubmitError(
        error instanceof Error ? error.message : 'Something went wrong. Please try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const reset = () => {
    setValues(initialValues);
    setErrors({});
    setTouched({});
    setSubmitError(null);
  };

  return {
    values,
    errors,
    touched,
    isSubmitting,
    submitError,
    handleChange,
    handleBlur,
    handleSubmit,
    reset,
    setValues,
    setErrors,
  };
}
```

**Usage:**
```tsx
function ContactForm() {
  const id = useId();
  const {
    values,
    errors,
    touched,
    isSubmitting,
    submitError,
    handleChange,
    handleBlur,
    handleSubmit,
  } = useForm({
    initialValues: { name: '', email: '', message: '' },
    validate: (values) => {
      const errors: Record<string, string> = {};
      if (!values.name) errors.name = 'Name is required';
      if (!values.email) {
        errors.email = 'Email is required';
      } else if (!/\S+@\S+\.\S+/.test(values.email)) {
        errors.email = 'Invalid email';
      }
      return errors;
    },
    onSubmit: async (values) => {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      });
      if (!response.ok) {
        throw new Error(`Could not send your message (status ${response.status}).`);
      }
    },
  });

  const nameError = touched.name ? errors.name : undefined;
  const emailError = touched.email ? errors.email : undefined;

  return (
    <form onSubmit={handleSubmit} noValidate>
      <label htmlFor={`${id}-name`}>Name</label>
      <input
        id={`${id}-name`}
        name="name"
        value={values.name}
        onChange={handleChange}
        onBlur={handleBlur}
        aria-invalid={nameError ? true : undefined}
        aria-describedby={nameError ? `${id}-name-error` : undefined}
      />
      {nameError && <span id={`${id}-name-error`} role="alert">{nameError}</span>}

      <label htmlFor={`${id}-email`}>Email</label>
      <input
        id={`${id}-email`}
        name="email"
        type="email"
        value={values.email}
        onChange={handleChange}
        onBlur={handleBlur}
        aria-invalid={emailError ? true : undefined}
        aria-describedby={emailError ? `${id}-email-error` : undefined}
      />
      {emailError && <span id={`${id}-email-error`} role="alert">{emailError}</span>}

      <label htmlFor={`${id}-message`}>Message</label>
      <textarea
        id={`${id}-message`}
        name="message"
        value={values.message}
        onChange={handleChange}
        onBlur={handleBlur}
      />

      {submitError && <p role="alert">{submitError}</p>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
```
