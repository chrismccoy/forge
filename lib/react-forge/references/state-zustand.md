# Zustand Patterns Guide

Advanced patterns and best practices for Zustand state management.

## Contents

- [Core Concepts](#core-concepts)
- [Selectors and Performance](#selectors-and-performance)
- [Middleware Patterns](#middleware-patterns)
- [Store Organization Patterns](#store-organization-patterns)
- [Async Actions](#async-actions)
- [Subscriptions and Side Effects](#subscriptions-and-side-effects)
- [Computed Values](#computed-values)
- [Store Outside React](#store-outside-react)
- [Testing Patterns](#testing-patterns)

## Core Concepts

### Basic Store Setup

```tsx
import { create } from 'zustand';

interface BearStore {
  bears: number;
  increase: () => void;
  decrease: () => void;
  reset: () => void;
}

const useBearStore = create<BearStore>((set) => ({
  bears: 0,
  increase: () => set((state) => ({ bears: state.bears + 1 })),
  decrease: () => set((state) => ({ bears: Math.max(0, state.bears - 1) })),
  reset: () => set({ bears: 0 }),
}));

// Usage
function BearCounter() {
  const bears = useBearStore((state) => state.bears);
  const increase = useBearStore((state) => state.increase);

  return (
    <div>
      <span>{bears} bears</span>
      <button onClick={increase}>Add bear</button>
    </div>
  );
}
```

### Using get() for Current State

```tsx
const useStore = create<Store>((set, get) => ({
  items: [],
  selectedId: null,

  // Use get() to access current state in actions
  getSelectedItem: () => {
    const { items, selectedId } = get();
    return items.find((item) => item.id === selectedId) ?? null;
  },

  // Use get() for conditional logic
  addItem: (item) => {
    const { items } = get();
    if (items.length >= 100) {
      console.warn('Item limit reached');
      return;
    }
    set({ items: [...items, item] });
  },
}));
```

## Selectors and Performance

### Selecting Primitive Values

```tsx
// GOOD - Only re-renders when count changes
const count = useStore((state) => state.count);

// BAD - Re-renders on ANY state change
const { count, items, users } = useStore();
```

### Selecting Derived Data

In Zustand v5, the hook created by `create` takes only a selector: there is no equality-function second argument, and `useStore(selector, shallow)` is not supported. A selector that returns a new array or object on every call (`filter`, `map`, `{ a, b }`) makes the hook see a "changed" value each time and can cause an infinite render loop.

```tsx
import { useShallow } from 'zustand/react/shallow';

// GOOD - select a primitive derived value
const expensiveCount = useStore(
  (state) => state.items.filter((item) => item.price > 100).length
);

// GOOD - select the stable source array, derive during render
const items = useStore((state) => state.items);
const expensiveItems = items.filter((item) => item.price > 100);

// GOOD - selector returns a new array/object: wrap it in useShallow
// (see "Using useShallow for Object Selection" below)
const expensiveIds = useStore(
  useShallow((state) => state.items.filter((i) => i.price > 100).map((i) => i.id))
);
```

For a custom equality function, create the store with `createWithEqualityFn` from `zustand/traditional` (requires the `use-sync-external-store` peer dependency), which restores the `(selector, equalityFn)` signature.

### Creating Reusable Selectors

```tsx
// selectors.ts
export const selectUser = (state: StoreState) => state.user;
export const selectIsAuthenticated = (state: StoreState) => state.user !== null;
export const selectCartTotal = (state: StoreState) =>
  state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

// Component
function Cart() {
  const total = useStore(selectCartTotal);
  return <span>Total: ${total}</span>;
}
```

### Using useShallow for Object Selection

```tsx
import { useShallow } from 'zustand/react/shallow';

// Prevents re-renders when unrelated state changes
function UserProfile() {
  const { name, email, avatar } = useStore(
    useShallow((state) => ({
      name: state.user.name,
      email: state.user.email,
      avatar: state.user.avatar,
    }))
  );

  return (
    <div>
      <img src={avatar} alt={name} />
      <h1>{name}</h1>
      <p>{email}</p>
    </div>
  );
}
```

## Middleware Patterns

### Persist Middleware - Local Storage

```tsx
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface CartStore {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  clearCart: () => void;
}

const useCartStore = create<CartStore>()(
  persist(
    (set) => ({
      items: [],
      addItem: (item) =>
        set((state) => ({
          items: [...state.items, item],
        })),
      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'cart-storage', // localStorage key
      storage: createJSONStorage(() => localStorage),
      // Only persist certain fields
      partialize: (state) => ({ items: state.items }),
    }
  )
);
```

#### Persisted State and Server Rendering

The server has no `localStorage`, so it renders the initial state while the browser may hold saved data. If the store rehydrates during the first client render, the markup differs from the server's and React reports a hydration mismatch. Defer rehydration until after mount:

```tsx
import { useEffect } from 'react';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useCartStore = create<CartStore>()(
  persist(
    (set) => ({
      items: [],
      addItem: (item) => set((state) => ({ items: [...state.items, item] })),
      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'cart-storage',
      skipHydration: true, // do not read storage until rehydrate() is called
    }
  )
);

// Render once near the app root (a Client Component)
function StoreHydrator() {
  useEffect(() => {
    useCartStore.persist.rehydrate();
  }, []);
  return null;
}
```

Alternatively, keep automatic hydration and gate UI that depends on saved data on `useCartStore.persist.hasHydrated()` (subscribe with `persist.onFinishHydration` to re-render when it flips). See [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches) for hydration mismatches in general.

### Persist with SessionStorage

```tsx
const useSessionStore = create<Store>()(
  persist(
    (set) => ({
      // ...
    }),
    {
      name: 'session-data',
      storage: createJSONStorage(() => sessionStorage),
    }
  )
);
```

### Persist with Async Storage (React Native)

```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';

const useStore = create<Store>()(
  persist(
    (set) => ({
      // ...
    }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

### DevTools Middleware

```tsx
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

const useStore = create<Store>()(
  devtools(
    (set) => ({
      count: 0,
      increment: () =>
        set(
          (state) => ({ count: state.count + 1 }),
          false, // replace state?
          'increment' // action name for devtools
        ),
    }),
    { name: 'MyStore' } // Store name in devtools
  )
);
```

### Combining Middlewares

```tsx
import { create } from 'zustand';
import { devtools, persist, subscribeWithSelector } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

// Order matters! devtools should be outer, persist inner
const useStore = create<Store>()(
  devtools(
    subscribeWithSelector(
      persist(
        immer((set) => ({
          // Store definition
        })),
        { name: 'storage-key' }
      )
    ),
    { name: 'StoreName' }
  )
);
```

### Immer Middleware - Mutable Updates

```tsx
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface TodoStore {
  todos: Todo[];
  addTodo: (text: string) => void;
  toggleTodo: (id: string) => void;
  updateTodo: (id: string, text: string) => void;
}

const useTodoStore = create<TodoStore>()(
  immer((set) => ({
    todos: [],

    addTodo: (text) =>
      set((state) => {
        // Mutate directly - Immer handles immutability
        state.todos.push({
          id: crypto.randomUUID(),
          text,
          completed: false,
        });
      }),

    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.completed = !todo.completed;
        }
      }),

    updateTodo: (id, text) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.text = text;
        }
      }),
  }))
);
```

## Store Organization Patterns

### Slice Pattern - Split Large Stores

```tsx
// slices/userSlice.ts
import type { StateCreator } from 'zustand';

export interface UserSlice {
  user: User | null;
  setUser: (user: User | null) => void;
  /** Clears client state only; call after the server logout request succeeds */
  clearUser: () => void;
}

export const createUserSlice: StateCreator<
  UserSlice & CartSlice, // Full store type
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
});

// slices/cartSlice.ts
export interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  clearCart: () => void;
}

export const createCartSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  CartSlice
> = (set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  clearCart: () => set({ items: [] }),
});

// store.ts
import { create } from 'zustand';

type StoreState = UserSlice & CartSlice;

const useStore = create<StoreState>()((...args) => ({
  ...createUserSlice(...args),
  ...createCartSlice(...args),
}));
```

### Domain-Specific Stores

Security: do not keep auth tokens in a store, and never in `localStorage` or `sessionStorage`, where any XSS can read them. The server sets an httpOnly, Secure, SameSite session cookie, so client code never handles the token. The store holds only the non-sensitive user profile, and logging out goes through the server, because only the server can clear an httpOnly cookie.

```tsx
// stores/authStore.ts
import { create } from 'zustand';

interface AuthStore {
  user: User | null;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => Promise<void>;
  /** Clears client state when the server reports the session is gone (401) */
  clearSession: () => void;
}

export const useAuthStore = create<AuthStore>()((set) => ({
  user: null,
  login: async (credentials) => {
    // The response sets the httpOnly session cookie; the body is the profile
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
    });
    if (!res.ok) throw new Error('Login failed');
    set({ user: (await res.json()) as User });
  },
  logout: async () => {
    const res = await fetch('/api/logout', { method: 'POST' });
    if (!res.ok) throw new Error('Logout failed');
    set({ user: null });
  },
  clearSession: () => set({ user: null }),
}));

// stores/uiStore.ts
export const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: false,
  theme: 'light',
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  setTheme: (theme) => set({ theme }),
}));

// stores/cartStore.ts
export const useCartStore = create<CartStore>((set) => ({
  // Cart specific logic
}));
```

## Async Actions

### Basic Async Pattern

```tsx
interface DataStore {
  data: Item[] | null;
  loading: boolean;
  error: Error | null;
  fetchData: () => Promise<void>;
}

const useDataStore = create<DataStore>((set) => ({
  data: null,
  loading: false,
  error: null,

  fetchData: async () => {
    set({ loading: true, error: null });

    try {
      const response = await fetch('/api/data');
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data: Item[] = await response.json();
      set({ data, loading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error : new Error('Unknown error'),
        loading: false,
      });
    }
  },
}));
```

### Async with Abort Controller

```tsx
interface SearchStore {
  query: string;
  results: SearchResult[];
  loading: boolean;
  setQuery: (query: string) => void;
  search: () => Promise<void>;
}

const useSearchStore = create<SearchStore>((set, get) => {
  let abortController: AbortController | null = null;

  return {
    query: '',
    results: [],
    loading: false,

    setQuery: (query) => set({ query }),

    search: async () => {
      // Cancel previous request
      abortController?.abort();
      abortController = new AbortController();

      const { query } = get();
      if (!query.trim()) {
        set({ results: [] });
        return;
      }

      set({ loading: true });

      try {
        const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`, {
          signal: abortController.signal,
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const results: SearchResult[] = await response.json();
        set({ results, loading: false });
      } catch (error) {
        // A newer search aborted this one and owns the loading state
        if (error instanceof DOMException && error.name === 'AbortError') return;
        set({ loading: false });
      }
    },
  };
});
```

## Subscriptions and Side Effects

### Subscribe to State Changes

```tsx
import { subscribeWithSelector } from 'zustand/middleware';

const useStore = create<Store>()(
  subscribeWithSelector((set) => ({
    count: 0,
    increment: () => set((s) => ({ count: s.count + 1 })),
  }))
);

// Subscribe to specific state changes
const unsubscribe = useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log(`Count changed from ${prevCount} to ${count}`);
  }
);

// With options
useStore.subscribe(
  (state) => state.count,
  (count) => {
    console.log('Count is now:', count);
  },
  {
    equalityFn: (a, b) => a === b, // Custom equality
    fireImmediately: true, // Fire on subscribe
  }
);
```

### React Integration with useEffect

```tsx
function Analytics() {
  const count = useStore((s) => s.count);

  useEffect(() => {
    // Track analytics when count changes
    analytics.track('count_changed', { count });
  }, [count]);

  return null;
}
```

## Computed Values

### Using get() for Computed Properties

```tsx
interface CartStore {
  items: CartItem[];
  getTotal: () => number;
  getItemCount: () => number;
}

const useCartStore = create<CartStore>((set, get) => ({
  items: [],

  getTotal: () => {
    const { items } = get();
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  },

  getItemCount: () => {
    const { items } = get();
    return items.reduce((sum, item) => sum + item.quantity, 0);
  },
}));

// Usage
function CartSummary() {
  const getTotal = useCartStore((s) => s.getTotal);
  const getItemCount = useCartStore((s) => s.getItemCount);

  // Note: These are functions, call them to get values
  return (
    <div>
      <span>{getItemCount()} items</span>
      <span>${getTotal()}</span>
    </div>
  );
}
```

### Selector-Based Computed Values

```tsx
// More efficient - computed at selection time
function CartSummary() {
  const total = useCartStore((s) =>
    s.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

  return <span>${total}</span>;
}
```

## Store Outside React

### Accessing Store Outside Components

```tsx
// Access state directly
const currentState = useStore.getState();
console.log(currentState.count);

// Call actions directly
useStore.getState().increment();

// Set state directly
useStore.setState({ count: 100 });

// Subscribe outside React
const unsubscribe = useStore.subscribe(console.log);
```

### Use in API Interceptors

The session lives in an httpOnly cookie (see the security note under Domain-Specific Stores), so requests send credentials instead of an `Authorization` header. A 401 means the server already ended the session, so clearing client state is enough.

```tsx
// api/client.ts
import axios from 'axios';
import { useAuthStore } from '@/stores/authStore';

// withCredentials matters only for cross-origin APIs; same-origin requests send cookies anyway
const client = axios.create({ baseURL: '/api', withCredentials: true });

client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().clearSession();
    }
    return Promise.reject(error);
  }
);
```

## Testing Patterns

### Testing Store Actions

```tsx
import { beforeEach, describe, expect, it } from 'vitest';
import { useCartStore } from './cartStore';

describe('cartStore', () => {
  beforeEach(() => {
    // Reset store before each test
    useCartStore.setState({ items: [] });
  });

  it('adds item to cart', () => {
    const item = { id: '1', name: 'Product', price: 10, quantity: 1 };

    useCartStore.getState().addItem(item);

    expect(useCartStore.getState().items).toHaveLength(1);
    expect(useCartStore.getState().items[0]).toEqual(item);
  });

  it('calculates total correctly', () => {
    useCartStore.setState({
      items: [
        { id: '1', name: 'A', price: 10, quantity: 2 },
        { id: '2', name: 'B', price: 5, quantity: 3 },
      ],
    });

    expect(useCartStore.getState().getTotal()).toBe(35);
  });
});
```

### Testing Components with Store

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, expect, it } from 'vitest';
import { useCartStore } from './cartStore';
import { Cart } from './Cart';

beforeEach(() => {
  useCartStore.setState({ items: [] });
});

it('displays cart items', () => {
  useCartStore.setState({
    items: [{ id: '1', name: 'Test Product', price: 10, quantity: 1 }],
  });

  render(<Cart />);

  expect(screen.getByText('Test Product')).toBeInTheDocument();
});

it('removes item when delete is clicked', async () => {
  const user = userEvent.setup();
  useCartStore.setState({
    items: [{ id: '1', name: 'Test Product', price: 10, quantity: 1 }],
  });

  render(<Cart />);
  await user.click(screen.getByRole('button', { name: /remove/i }));

  expect(useCartStore.getState().items).toHaveLength(0);
});
```
