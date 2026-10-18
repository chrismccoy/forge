# React State Management

## Contents

- [Quick Reference](#quick-reference)
- [Built-in State Management](#built-in-state-management)
- [Context API](#context-api)
- [Zustand](#zustand)
- [Jotai and TanStack Query](#jotai-and-tanstack-query)
- [SWR](#swr)
- [Best Practices](#best-practices)
- [Additional References](#additional-references)

## Quick Reference

| Library | Best For | Install |
|---------|----------|---------|
| Context | Rarely-changing values (theme, locale, current user) | Built-in |
| Zustand | Simple global state | `npm i zustand` |
| Jotai | Atomic/granular state | `npm i jotai` |
| Redux Toolkit | Large apps needing strict update flow and devtools, or existing Redux code | `npm i @reduxjs/toolkit react-redux` |
| TanStack Query | Server state/caching | `npm i @tanstack/react-query` |
| SWR | Data fetching | `npm i swr` |

| Scenario | Recommended |
|----------|-------------|
| Simple local state | `useState` |
| Complex local state | `useReducer` |
| Shared state, small tree or low update frequency | Context + useReducer |
| Shared state updated often or read by many components | Zustand or Jotai (or split contexts) |
| Large team, centralized store, existing Redux code | Redux Toolkit |
| Server state | TanStack Query or SWR |

## Built-in State Management

### Component State with useState

```tsx
'use client';

import { useState } from 'react';

function ShoppingCart() {
  const [items, setItems] = useState<CartItem[]>([]);
  const [isOpen, setIsOpen] = useState(false);

  const addItem = (product: Product) => {
    setItems((prev) => {
      const existing = prev.find((item) => item.id === product.id);
      if (existing) {
        return prev.map((item) =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const total = items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  return (
    <div>
      <button onClick={() => setIsOpen(!isOpen)}>
        Cart ({items.length}) - ${total.toFixed(2)}
      </button>
      {isOpen && <CartDropdown items={items} />}
    </div>
  );
}
```

### Complex State with useReducer

Context + `useReducer` works for a small tree or state that changes infrequently. Every consumer re-renders whenever the context value changes, so for shared state that updates often (a cart edited from many places, live counters) prefer Zustand or Jotai with selectors, or split state and dispatch into separate contexts.

```tsx
'use client';

import { useReducer, Dispatch, createContext, useContext } from 'react';

// Types
interface CartState {
  items: CartItem[];
  isLoading: boolean;
  error: string | null;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: Product }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string };

// Reducer
function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existing = state.items.find(
        (item) => item.id === action.payload.id
      );
      if (existing) {
        return {
          ...state,
          items: state.items.map((item) =>
            item.id === action.payload.id
              ? { ...item, quantity: item.quantity + 1 }
              : item
          ),
        };
      }
      return {
        ...state,
        items: [...state.items, { ...action.payload, quantity: 1 }],
      };
    }
    case 'REMOVE_ITEM':
      return {
        ...state,
        items: state.items.filter((item) => item.id !== action.payload),
      };
    case 'UPDATE_QUANTITY':
      return {
        ...state,
        items: state.items.map((item) =>
          item.id === action.payload.id
            ? { ...item, quantity: action.payload.quantity }
            : item
        ),
      };
    case 'CLEAR_CART':
      return { ...state, items: [] };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    default:
      return state;
  }
}

// Context
const CartContext = createContext<{
  state: CartState;
  dispatch: Dispatch<CartAction>;
} | null>(null);

// Provider
export function CartProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, {
    items: [],
    isLoading: false,
    error: null,
  });

  return (
    <CartContext.Provider value={{ state, dispatch }}>
      {children}
    </CartContext.Provider>
  );
}

// Hook
export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}
```

## Context API

### Creating and Using Context

This is the canonical theme context used across these references (tests in `examples.md` and `testing-recipes.md` render the provider with this shape). Keep the value minimal; consumers derive anything else, such as `isDark`.

```tsx
// contexts/ThemeContext.tsx
'use client';

import { createContext, useContext, useState, type ReactNode } from 'react';

export type Theme = 'light' | 'dark';

export interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
}

// Exported so tests can render consumers with an explicit value
export const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({
  children,
  initialTheme = 'light',
}: {
  children: ReactNode;
  initialTheme?: Theme;
}) {
  const [theme, setTheme] = useState<Theme>(initialTheme);
  const toggleTheme = () => setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}
```

```tsx
// components/ThemeToggle.tsx
'use client';

import { useTheme } from '@/contexts/ThemeContext';

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark'; // derived, not stored in context

  return (
    <button type="button" onClick={toggleTheme} aria-pressed={isDark}>
      Toggle theme (current: {theme})
    </button>
  );
}
```

To avoid a flash of the wrong theme with server rendering, pass the saved theme from a cookie as `initialTheme` instead of reading `localStorage` during render.

### Optimizing Context Performance

```tsx
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

interface UserActions {
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<User>) => Promise<void>;
}

// Split context to prevent unnecessary re-renders
const UserContext = createContext<User | null>(null);
const UserActionsContext = createContext<UserActions | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  // Memoization is deliberate here: a stable actions object is what keeps
  // UserActionsContext consumers from re-rendering when `user` changes.
  // The actions only call setUser (which is stable), so they need no deps.
  // (The React Compiler does this automatically.)
  const actions = useMemo<UserActions>(
    () => ({
      login: async (email, password) => {
        // The server sets an httpOnly session cookie; the client keeps only the profile
        const response = await fetch('/api/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password }),
        });
        if (!response.ok) throw new Error('Login failed');
        const userData: User = await response.json();
        setUser(userData);
      },

      logout: async () => {
        // Only the server can clear the httpOnly session cookie
        const response = await fetch('/api/logout', { method: 'POST' });
        if (!response.ok) throw new Error('Logout failed');
        setUser(null);
      },

      updateProfile: async (data) => {
        const response = await fetch('/api/profile', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        });
        if (!response.ok) throw new Error('Profile update failed');
        const updated: User = await response.json();
        setUser(updated);
      },
    }),
    []
  );

  return (
    <UserContext.Provider value={user}>
      <UserActionsContext.Provider value={actions}>
        {children}
      </UserActionsContext.Provider>
    </UserContext.Provider>
  );
}

// Separate hooks for data and actions
export function useUser() {
  return useContext(UserContext);
}

export function useUserActions() {
  const context = useContext(UserActionsContext);
  if (!context) {
    throw new Error('useUserActions must be used within UserProvider');
  }
  return context;
}
```

## Zustand

A minimal store. For selectors, middleware (`persist`, `devtools`, `immer`), async actions, store organization, and testing, see `state-zustand.md`.

```tsx
// stores/counter.ts
import { create } from 'zustand';

interface CounterStore {
  count: number;
  increment: () => void;
  reset: () => void;
}

export const useCounterStore = create<CounterStore>()((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  reset: () => set({ count: 0 }),
}));

// Select only what the component needs, so unrelated updates skip re-rendering
function Counter() {
  const count = useCounterStore((state) => state.count);
  const increment = useCounterStore((state) => state.increment);

  return (
    <button type="button" onClick={increment}>
      Count: {count}
    </button>
  );
}
```

**Persisted stores and server rendering:** with `persist`, the browser's saved state differs from what the server rendered, so rehydrating during the first client render causes a hydration mismatch. Create the store with `skipHydration: true` and call `useStore.persist.rehydrate()` in an effect after mount, or gate UI that depends on saved data on `useStore.persist.hasHydrated()`. See `state-zustand.md` → Middleware Patterns and [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches). Never persist auth tokens; keep them in httpOnly cookies.

## Jotai and TanStack Query

Detailed patterns for Jotai atom-based state and TanStack Query server-state management — atoms, derived atoms, async atoms, query clients, mutations, invalidation, optimistic updates, and cache tuning — live in `state-jotai-and-tanstack-query.md`. Load that reference when choosing atom composition or production-grade server-state caching.

## SWR

### Basic SWR Usage

```tsx
import useSWR, { SWRConfig } from 'swr';

const fetcher = async (url: string) => {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`); // SWR exposes this as `error`
  return res.json();
};

function App() {
  return (
    <SWRConfig
      value={{
        fetcher,
        refreshInterval: 0,
        revalidateOnFocus: true,
        dedupingInterval: 2000,
      }}
    >
      <Dashboard />
    </SWRConfig>
  );
}

function Dashboard() {
  const { data, error, isLoading, mutate } = useSWR('/api/dashboard');

  if (error) return <div>Failed to load</div>;
  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Total Users: {data.totalUsers}</p>
      <button onClick={() => mutate()}>Refresh</button>
    </div>
  );
}
```

### SWR Mutation

```tsx
import useSWRMutation from 'swr/mutation';

async function createUser(url: string, { arg }: { arg: CreateUserInput }) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(arg),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function CreateUserForm() {
  const { trigger, isMutating } = useSWRMutation('/api/users', createUser);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    await trigger({
      name: formData.get('name') as string,
      email: formData.get('email') as string,
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="new-user-name">Name</label>
      <input id="new-user-name" name="name" required />
      <label htmlFor="new-user-email">Email</label>
      <input id="new-user-email" name="email" type="email" required />
      <button type="submit" disabled={isMutating}>
        {isMutating ? 'Creating...' : 'Create'}
      </button>
    </form>
  );
}
```

### Data-Access Hooks

Wrap each endpoint in a named hook so components never build URLs or cache keys themselves. Name them by action and resource: `useGetOrders`, `useGetOrderById`, `useCreateOrder`.

```tsx
// features/orders/hooks/use-get-orders.ts
import useSWR from 'swr';
import type { Order, OrderFilters } from '../types';

export function useGetOrders(filters: OrderFilters) {
  const params = new URLSearchParams({ status: filters.status, page: String(filters.page) });
  return useSWR<Order[]>(`/api/orders?${params}`);
}

export function useGetOrderById(id: string | null) {
  // A null key skips the request (dependent or conditional fetch)
  return useSWR<Order>(id ? `/api/orders/${id}` : null);
}
```

### Paginated Data with useSWRInfinite

```tsx
import useSWRInfinite from 'swr/infinite';

type Page = { items: Order[]; nextCursor: string | null };

export function useOrderPages() {
  const { data, error, size, setSize, isLoading, isValidating } = useSWRInfinite<Page>(
    (index, previous) => {
      if (previous && !previous.nextCursor) return null; // reached the end
      return index === 0 ? '/api/orders' : `/api/orders?cursor=${encodeURIComponent(previous!.nextCursor!)}`;
    }
  );

  const orders = data?.flatMap((page) => page.items) ?? [];
  const hasMore = Boolean(data?.at(-1)?.nextCursor);
  const loadMore = () => setSize(size + 1);

  return { orders, error, isLoading, isLoadingMore: isValidating && size > (data?.length ?? 0), hasMore, loadMore };
}
```

Render the "Load more" control as a real `<button>` disabled while loading, and announce new results with a polite live region. For TanStack Query's equivalent, see [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md#infinite-queries).

## Best Practices

### 1. Choose the Right Tool

Pick by scenario using the table in [Quick Reference](#quick-reference). Start with `useState`, and move state to a shared store only when more than one part of the tree needs it.

### 2. Avoid Prop Drilling

```tsx
// Instead of passing props through many levels
<Parent user={user}>
  <Child user={user}>
    <GrandChild user={user} />
  </Child>
</Parent>

// Use context or state management
<UserProvider>
  <Parent>
    <Child>
      <GrandChild /> {/* Access user via useUser() */}
    </Child>
  </Parent>
</UserProvider>
```

### 3. Normalize Complex State

```tsx
// Instead of nested objects
const badState = {
  posts: [
    { id: 1, title: 'Post 1', author: { id: 1, name: 'Alice' } },
    { id: 2, title: 'Post 2', author: { id: 1, name: 'Alice' } },
  ],
};

// Use normalized structure
const goodState = {
  posts: {
    byId: {
      1: { id: 1, title: 'Post 1', authorId: 1 },
      2: { id: 2, title: 'Post 2', authorId: 1 },
    },
    allIds: [1, 2],
  },
  authors: {
    byId: { 1: { id: 1, name: 'Alice' } },
    allIds: [1],
  },
};
```

### 4. Keep Shareable UI State in the URL

Filters, sort order, pagination, the selected tab, and search text belong in the query string when a user would expect to bookmark, share, or go back to them. The URL then is the single source of truth: read it, and update it instead of mirroring it in `useState` or a store. Next.js: [nextjs-routing.md](nextjs-routing.md#updating-the-query-string).

## Additional References

For detailed patterns and advanced use cases, see:

- `state-zustand.md` - Advanced Zustand patterns including slices, middleware, and testing
- `state-jotai-and-tanstack-query.md` - Jotai atoms and TanStack Query queries, mutations, and providers
- `state-redux.md` - Redux Toolkit: `configureStore`, slices, thunks, selectors, RTK Query, per-request store for SSR
