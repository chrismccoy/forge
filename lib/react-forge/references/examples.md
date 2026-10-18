# Worked Examples

Reference answers that show the expected depth and shape of a response.

## Contents

- [User is building a new feature and needs guidance on component architecture](#user-is-building-a-new-feature-and-needs-guidance-on-component-architecture)
- [User needs help with custom hooks](#user-needs-help-with-custom-hooks)
- [User has performance issues](#user-has-performance-issues)
- [User asks about state management choices](#user-asks-about-state-management-choices)
- [User needs help testing a component](#user-needs-help-testing-a-component)

## User is building a new feature and needs guidance on component architecture

**Request:** How should I structure a user profile page with editable fields?

I'll help you design a well-structured user profile page. Let me create a component architecture that follows React 19 best practices.

For an editable profile page, I recommend this structure. It uses Server Components and Server Actions, so it needs a framework that supports them (e.g. Next.js, React Router).

```tsx
// components/profile/ProfilePage.tsx (Server Component)
import { getSession } from '@/lib/auth';
import { getUser } from '@/lib/data';
import { ProfileForm } from './ProfileForm';

export async function ProfilePage() {
  const session = await getSession();
  if (!session) return <p>Please sign in.</p>;

  const user = await getUser(session.user.id);
  return (
    <main className="max-w-2xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Profile Settings</h1>
      <ProfileForm initialData={user} />
    </main>
  );
}
```

```tsx
// components/profile/ProfileForm.tsx (Client Component)
'use client';

import { useActionState } from 'react';
import { updateProfile, type ProfileState } from './actions';

interface ProfileFormProps {
  initialData: { name: string; email: string; bio: string };
}

const initialState: ProfileState = { error: null, success: false };

export function ProfileForm({ initialData }: ProfileFormProps) {
  const [state, formAction, isPending] = useActionState(updateProfile, initialState);

  return (
    <form action={formAction} className="space-y-4">
      {state.error && <div className="text-red-600">{state.error}</div>}
      {state.success && <div className="text-green-600">Profile updated!</div>}

      <div>
        <label htmlFor="name" className="block font-medium">Name</label>
        <input
          id="name"
          name="name"
          defaultValue={initialData.name}
          className="w-full border rounded px-3 py-2"
        />
      </div>

      <div>
        <label htmlFor="bio" className="block font-medium">Bio</label>
        <textarea
          id="bio"
          name="bio"
          defaultValue={initialData.bio}
          rows={4}
          className="w-full border rounded px-3 py-2"
        />
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
      >
        {isPending ? 'Saving...' : 'Save Changes'}
      </button>
    </form>
  );
}
```

```tsx
// components/profile/actions.ts
'use server';

import { z } from 'zod';
import { db } from '@/lib/db';
import { getSession } from '@/lib/auth';

const profileSchema = z.object({
  name: z.string().trim().min(2, { error: 'Name must be at least 2 characters' }).max(100),
  bio: z.string().trim().max(500, { error: 'Bio must be 500 characters or fewer' }),
});

export type ProfileState = { error: string | null; success: boolean };

export async function updateProfile(
  prevState: ProfileState,
  formData: FormData
): Promise<ProfileState> {
  const session = await getSession();
  if (!session) {
    return { error: 'You must be signed in', success: false };
  }

  const parsed = profileSchema.safeParse({
    name: formData.get('name'),
    bio: formData.get('bio') ?? '',
  });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? 'Invalid input', success: false };
  }

  // Scope the write to the signed-in user; never trust an id from the form
  await db.users.update({
    where: { id: session.user.id },
    data: parsed.data,
  });

  // framework-specific cache invalidation (e.g. Next.js revalidatePath; see the framework docs)
  return { error: null, success: true };
}
```

This architecture:
- **Server Component** for the page shell and data fetching
- **Client Component** only for the interactive form
- **Server Action** that authenticates, validates with Zod, and scopes the write to the session user
- **Progressive enhancement** - works without JavaScript

## User needs help with custom hooks

**Request:** Create a useLocalStorage hook that syncs state with localStorage

Use the canonical implementation in `hooks-custom-library.md` → `useLocalStorage`. Its shape:

```tsx
// hooks/useLocalStorage.ts (excerpt; full version in hooks-custom-library.md)
export function useLocalStorage<T>(key: string, initialValue: T) {
  const [fallback] = useState(initialValue);
  const raw = useSyncExternalStore(
    subscribe,             // 'storage' (other tabs) + same-tab 'local-storage' event
    () => readRaw(key),    // raw string snapshot: stable, avoids render loops
    () => null             // server snapshot -> initialValue, no hydration mismatch
  );
  const value = useMemo(() => parse(raw, fallback), [raw, fallback]); // stable identity for consumers' deps
  // setValue reads the latest stored value, writes it, and dispatches 'local-storage'
  // removeValue removes the key and dispatches 'local-storage'
  return [value, setValue, removeValue] as const;
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
      <button onClick={removeTheme}>Reset to default</button>
    </div>
  );
}
```

Key features:
- **Type-safe** with generics
- **SSR-safe** - `useSyncExternalStore` renders `initialValue` on the server and during hydration, then the stored value on the client
- **Sync** - updates every hook using the same key in this tab (custom event) and in other tabs (`storage` event)
- **Functional updates** - `setValue(prev => ...)` applies to the latest stored value
- **Remove function** - clears the stored value and falls back to `initialValue`
- **Not for secrets** - never store auth tokens in localStorage

## User has performance issues

**Request:** My list component is slow when rendering 1000+ items. How do I fix it?

For large lists, you need virtualization - only rendering visible items. Let me show you the solution using react-window.

**Install the library (react-window 2.x ships its own TypeScript types; do not install `@types/react-window`):**
```bash
npm install react-window
```

**Virtualized list implementation (react-window 2.x API):**
```tsx
'use client';

import { List, type RowComponentProps } from 'react-window';

interface Item {
  id: string;
  name: string;
  status: 'active' | 'inactive';
}

interface RowProps {
  items: Item[];
  onItemClick: (item: Item) => void;
}

// Receives index, style, and ariaAttributes from List, plus everything in rowProps
function Row({ index, style, ariaAttributes, items, onItemClick }: RowComponentProps<RowProps>) {
  const item = items[index];

  return (
    <div
      {...ariaAttributes}
      style={style}
      className="flex items-center px-4 border-b hover:bg-gray-50 cursor-pointer"
      onClick={() => onItemClick(item)}
    >
      <span className="flex-1">{item.name}</span>
      <span className={`px-2 py-1 rounded text-sm ${
        item.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100'
      }`}>
        {item.status}
      </span>
    </div>
  );
}

export function VirtualizedList({ items, onItemClick }: RowProps) {
  return (
    <List
      rowComponent={Row}
      rowCount={items.length}
      rowHeight={50}
      rowProps={{ items, onItemClick }}
      style={{ height: 600 }}
    />
  );
}
```

**For variable heights**, pass a function to `rowHeight`, or use `useDynamicRowHeight` for measured content. The full variable-height and dynamic-height code is in [performance-virtualization.md](performance-virtualization.md#list---variable-and-dynamic-heights).

**Measure, do not guess:** record the list before and after virtualization with the React Profiler (React DevTools) and the browser Performance panel, using the real data size. Gains depend on row complexity and device.

Additional optimizations:
1. **Keep row components cheap**; add `memo()` only if profiling shows row re-renders are the cost
2. **Pass data through `rowProps`** rather than closing over it, so List can re-render rows when it changes
3. **Use `rowKey`** (react-window 2.3+, signature `(index, rowProps) => Key`, wrapped in `useCallback` so the list receives a stable prop) for sortable or filterable lists so rows keep stable keys
4. **Consider react-virtuoso** for auto-sizing without measuring

## User asks about state management choices

**Request:** Should I use Redux, Zustand, or Context for my e-commerce app?

For an e-commerce app, I recommend a **hybrid approach** using different tools for different state types. Let me break this down:

**State Categories in E-commerce:**

| State Type | Examples | Recommended Solution |
|------------|----------|---------------------|
| Server state | Products, orders, user data | TanStack Query |
| UI state | Modals, sidebars, filters | Zustand |
| Form state | Checkout form, search | React Hook Form |
| Auth state | User session (not tokens) | httpOnly cookies + server session; Zustand only for non-sensitive user info |
| Cart state | Items, quantities | Zustand (persisted) |

**My recommendation: Zustand + TanStack Query**

Here's why NOT Redux for most apps:
- Significant boilerplate
- Steep learning curve
- Overkill for most e-commerce needs

Keep auth tokens in httpOnly, Secure, SameSite cookies set by the server. Never persist tokens in localStorage or a persisted Zustand store: any XSS can read them. Only non-sensitive data, such as the cart below, belongs in persisted client state.

**Example cart store with Zustand:**
```tsx
// stores/cart.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartStore {
  items: CartItem[];
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  total: () => number;
}

export const useCart = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],

      addItem: (item) => set((state) => {
        const existing = state.items.find((i) => i.id === item.id);
        if (existing) {
          return {
            items: state.items.map((i) =>
              i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
            ),
          };
        }
        return { items: [...state.items, { ...item, quantity: 1 }] };
      }),

      removeItem: (id) => set((state) => ({
        items: state.items.filter((i) => i.id !== id),
      })),

      updateQuantity: (id, quantity) => set((state) => ({
        items: quantity <= 0
          ? state.items.filter((i) => i.id !== id)
          : state.items.map((i) => (i.id === id ? { ...i, quantity } : i)),
      })),

      clearCart: () => set({ items: [] }),

      total: () => get().items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    }),
    {
      name: 'cart-storage',
      // Read localStorage after hydration, not during the first render
      skipHydration: true,
    }
  )
);
```

With server rendering, the server has no `localStorage`, so it renders an empty cart while the browser may hold saved items. Rehydrating during the first client render would make the markup differ from the server's. `skipHydration: true` keeps the initial state until `rehydrate()` is called after mount:

```tsx
// components/CartHydrator.tsx
'use client';

import { useEffect } from 'react';
import { useCart } from '@/stores/cart';

// Render once near the root of the app
export function CartHydrator() {
  useEffect(() => {
    useCart.persist.rehydrate();
  }, []);
  return null;
}
```

Alternatively, gate UI that depends on saved data on `useCart.persist.hasHydrated()`. See [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches) for hydration mismatches in general.

**Server state with TanStack Query:**
```tsx
// hooks/useProducts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useCart } from '@/stores/cart';
import type { OrderData, Product } from '@/types';

export function useProducts(category?: string) {
  return useQuery({
    queryKey: ['products', category],
    queryFn: async ({ signal }): Promise<Product[]> => {
      // Only send params that are set; avoids `?category=undefined`
      const params = new URLSearchParams();
      if (category) params.set('category', category);
      const query = params.toString();

      const res = await fetch(`/api/products${query ? `?${query}` : ''}`, { signal });
      if (!res.ok) throw new Error(`Failed to load products: ${res.status}`);
      return res.json();
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useCreateOrder() {
  const queryClient = useQueryClient();
  const clearCart = useCart((s) => s.clearCart);

  return useMutation({
    mutationFn: async (orderData: OrderData) => {
      const res = await fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData),
      });
      // Throwing routes 4xx/5xx to onError, so the cart is only cleared on success
      if (!res.ok) throw new Error(`Order failed: ${res.status}`);
      return res.json();
    },
    onSuccess: () => {
      clearCart();
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}
```

**When TO use Redux:**
- Very large teams needing strict patterns
- Complex state with many reducers
- Need Redux DevTools time-travel debugging
- Existing Redux codebase

**Summary:**
- **Zustand**: Simple, minimal boilerplate, great DX
- **TanStack Query**: Perfect for server state, caching, synchronization
- **Redux**: Only if you have specific needs for it

## User needs help testing a component

**Request:** How do I test a component that uses useContext?

Testing components with Context requires wrapping them in the appropriate provider. Here's a comprehensive guide:

These examples use the `AuthContext` and `AuthProvider` from `hooks.md` → `useContext` (exported from `@/contexts/AuthContext`). That provider starts with `user` set to `null`, so tests that need a signed-in user pass an explicit context value instead of relying on a default.

**1. Create a test utility for rendering with providers:**
```tsx
// test/utils.tsx
import { useState, type ReactElement, type ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { vi } from 'vitest';
import { ThemeProvider } from '@/contexts/ThemeContext';
import { AuthContext, type AuthContextType } from '@/contexts/AuthContext';

export const testUser = { id: '1', name: 'Ada Lovelace', email: 'ada@example.com' };

// Build a complete context value; isAuthenticated always follows user
export function makeAuthValue(
  overrides: Partial<AuthContextType> = {}
): AuthContextType {
  const user = 'user' in overrides ? overrides.user ?? null : testUser;
  return {
    login: vi.fn().mockResolvedValue(undefined),
    logout: vi.fn().mockResolvedValue(undefined),
    ...overrides,
    user,
    isAuthenticated: user !== null,
  };
}

interface ProviderOptions extends Omit<RenderOptions, 'wrapper'> {
  auth?: AuthContextType;
}

export function renderWithProviders(
  ui: ReactElement,
  { auth = makeAuthValue(), ...options }: ProviderOptions = {}
) {
  function AllProviders({ children }: { children: ReactNode }) {
    // One client per test render; useState keeps it stable across re-renders
    const [queryClient] = useState(
      () => new QueryClient({ defaultOptions: { queries: { retry: false } } })
    );

    return (
      <QueryClientProvider client={queryClient}>
        <AuthContext.Provider value={auth}>
          <ThemeProvider>{children}</ThemeProvider>
        </AuthContext.Provider>
      </QueryClientProvider>
    );
  }

  return render(ui, { wrapper: AllProviders, ...options });
}

export * from '@testing-library/react';
export { renderWithProviders as render };
```

**2. Test a component using Context:**
```tsx
// components/UserGreeting.test.tsx
import { render, screen, makeAuthValue, testUser } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { UserGreeting } from './UserGreeting';

describe('UserGreeting', () => {
  it('shows greeting for logged-in user', () => {
    render(<UserGreeting />, { auth: makeAuthValue({ user: testUser }) });

    expect(screen.getByText(/welcome, ada lovelace/i)).toBeInTheDocument();
  });

  it('shows login prompt when not authenticated', () => {
    render(<UserGreeting />, { auth: makeAuthValue({ user: null }) });

    expect(screen.getByText(/please log in/i)).toBeInTheDocument();
  });
});
```

**3. Test a component that modifies context:**
```tsx
// components/ThemeToggle.test.tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { ThemeToggle } from './ThemeToggle';
import { ThemeContext } from '@/contexts/ThemeContext';

describe('ThemeToggle', () => {
  it('calls toggleTheme when clicked', async () => {
    const user = userEvent.setup();
    const toggleTheme = vi.fn();

    render(
      <ThemeContext.Provider value={{ theme: 'light', toggleTheme }}>
        <ThemeToggle />
      </ThemeContext.Provider>
    );

    await user.click(screen.getByRole('button', { name: /toggle theme/i }));

    expect(toggleTheme).toHaveBeenCalledTimes(1);
  });

  it('displays current theme', () => {
    render(
      <ThemeContext.Provider value={{ theme: 'dark', toggleTheme: vi.fn() }}>
        <ThemeToggle />
      </ThemeContext.Provider>
    );

    expect(screen.getByText(/current: dark/i)).toBeInTheDocument();
  });
});
```

**4. Testing custom hooks that use Context:**
```tsx
// hooks/useAuth.test.tsx
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect, vi, afterEach } from 'vitest';
import { useAuth, AuthProvider } from '@/contexts/AuthContext';
import { testUser } from '@/test/utils';

afterEach(() => {
  vi.restoreAllMocks();
});

describe('useAuth', () => {
  it('starts signed out', () => {
    const { result } = renderHook(() => useAuth(), { wrapper: AuthProvider });

    expect(result.current.user).toBeNull();
    expect(result.current.isAuthenticated).toBe(false);
  });

  it('logs in and out', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      // POST /api/login returns the profile
      .mockResolvedValueOnce(
        new Response(JSON.stringify(testUser), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        })
      )
      // POST /api/logout clears the session cookie
      .mockResolvedValueOnce(new Response(null, { status: 204 }));
    const { result } = renderHook(() => useAuth(), { wrapper: AuthProvider });

    await act(async () => {
      await result.current.login('ada@example.com', 'secret');
    });
    expect(result.current.user).toEqual(testUser);
    expect(result.current.isAuthenticated).toBe(true);

    await act(async () => {
      await result.current.logout();
    });
    expect(fetchMock).toHaveBeenLastCalledWith('/api/logout', { method: 'POST' });
    expect(result.current.user).toBeNull();
    expect(result.current.isAuthenticated).toBe(false);
  });
});
```

**Key testing patterns:**
| Scenario | Approach |
|----------|----------|
| Component uses context | Wrap in provider via test utils |
| Control the context value | Pass a complete value (`makeAuthValue`) for each test |
| Override one provider | Wrap in that provider directly in the test |
| Test context changes | Mock the context methods with `vi.fn()` |
| Test hook using context | Use `renderHook` with wrapper |
