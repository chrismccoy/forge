# Redux Toolkit

Redux Toolkit 2.x with react-redux 9.x and React 19: store setup, slices, typed hooks, async thunks, RTK Query, Next.js App Router, selectors, testing, and migrating legacy Redux. Load it when a project already uses Redux or the team is choosing it for large, shared client state.

## Contents

- [When to Choose Redux](#when-to-choose-redux)
- [Store Setup and Typed Hooks](#store-setup-and-typed-hooks)
- [Slices](#slices)
- [Async Thunks](#async-thunks)
- [Selectors](#selectors)
- [RTK Query](#rtk-query)
- [Next.js App Router](#nextjs-app-router)
- [Testing](#testing)
- [Migrating Legacy Redux](#migrating-legacy-redux)
- [Rules](#rules)

## When to Choose Redux

| Need | Choose |
|------|--------|
| Remote data (lists, details, mutations) without much client logic | TanStack Query or SWR; or RTK Query if Redux is already present |
| A few shared client values (theme, sidebar, modal) | Zustand, Jotai, or Context |
| Large client state with many writers, complex transitions, undo, time-travel debugging, strict conventions across a big team | Redux Toolkit |
| An existing Redux codebase | Keep Redux; move it to RTK incrementally |

Store only global, mutable client state in Redux. Keep form state in the form, URL state in the URL, and server data in a cache (RTK Query or TanStack Query), not in a hand-written slice. Comparison of all options: [state-management.md](state-management.md); Zustand: [state-zustand.md](state-zustand.md); Jotai and TanStack Query: [state-jotai-and-tanstack-query.md](state-jotai-and-tanstack-query.md).

Install:

```bash
npm install @reduxjs/toolkit react-redux
```

react-redux 9 requires React 18+ and ships its own types; do not install `@types/react-redux`.

## Store Setup and Typed Hooks

Create the store through a factory. The factory lets tests and server-rendered apps create a fresh store per test or per request.

```ts
// src/store/store.ts
import { combineSlices, configureStore } from '@reduxjs/toolkit';
import { cartSlice } from './cartSlice';
import { uiSlice } from './uiSlice';
import { api } from './api';

export const rootReducer = combineSlices(cartSlice, uiSlice, api);
export type RootState = ReturnType<typeof rootReducer>;

export function makeStore(preloadedState?: Partial<RootState>) {
  return configureStore({
    reducer: rootReducer,
    preloadedState,
    middleware: (getDefault) => getDefault().concat(api.middleware),
  });
}

export type AppStore = ReturnType<typeof makeStore>;
export type AppDispatch = AppStore['dispatch'];
```

`combineSlices` mounts each slice (and the RTK Query API) under its `reducerPath`. A plain `{ cart: cartReducer }` object also works. In RTK 2, `middleware` must be a callback; the object form was removed.

Define typed hooks once and use them everywhere instead of the raw hooks:

```ts
// src/store/hooks.ts
import { useDispatch, useSelector, useStore } from 'react-redux';
import type { AppDispatch, AppStore, RootState } from './store';

export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<RootState>();
export const useAppStore = useStore.withTypes<AppStore>();
```

For a client-only SPA, create the store once at module level in the entry file and wrap the app in `<Provider store={store}>`. For server rendering, see [Next.js App Router](#nextjs-app-router).

## Slices

`createSlice` generates action creators and a reducer. Write "mutating" code inside reducers; Immer turns it into immutable updates.

```ts
// src/store/cartSlice.ts
import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

export interface CartItem {
  productId: string;
  quantity: number;
  unitPrice: number;
}

interface CartState {
  items: CartItem[];
}

const initialState: CartState = { items: [] };

export const cartSlice = createSlice({
  name: 'cart',
  initialState,
  reducers: {
    itemAdded(state, action: PayloadAction<CartItem>) {
      const existing = state.items.find((i) => i.productId === action.payload.productId);
      if (existing) existing.quantity += action.payload.quantity;
      else state.items.push(action.payload);
    },
    itemRemoved(state, action: PayloadAction<string>) {
      state.items = state.items.filter((i) => i.productId !== action.payload);
    },
    cleared: () => initialState,
  },
  selectors: {
    selectCartItems: (cart) => cart.items,
    selectCartCount: (cart) => cart.items.reduce((n, i) => n + i.quantity, 0),
  },
});

export const { itemAdded, itemRemoved, cleared } = cartSlice.actions;
export const { selectCartItems, selectCartCount } = cartSlice.selectors;
```

Name actions as past-tense events (`itemAdded`), not setters. Keep reducers pure: no fetches, random IDs, or dates; generate those in a `prepare` callback or the caller.

Respond to actions defined elsewhere (another slice's actions, thunks, `isAnyOf(...)` matchers) with the builder callback form of `extraReducers`, as in [Async Thunks](#async-thunks). RTK 2 removed the object form.

## Async Thunks

Prefer RTK Query for data fetching. Use thunks for multi-step workflows that are not a single request (checkout flows, coordinating several slices).

### Standalone `createAsyncThunk`

```ts
// src/store/checkoutSlice.ts
import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';
import type { RootState } from './store';

interface Receipt { orderId: string; total: number }
type Status = 'idle' | 'pending' | 'succeeded' | 'failed';
interface CheckoutState { status: Status; receipt: Receipt | null; error: string | null }

export const placeOrder = createAsyncThunk<
  Receipt,
  { idempotencyKey: string },
  { state: RootState; rejectValue: string }
>('checkout/placeOrder', async ({ idempotencyKey }, { getState, rejectWithValue, signal }) => {
  const items = getState().cart.items;
  const res = await fetch('/api/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Idempotency-Key': idempotencyKey },
    body: JSON.stringify({ items }),
    signal,
  });
  if (!res.ok) return rejectWithValue(`Order failed (${res.status})`);
  return (await res.json()) as Receipt;
});

const initialState: CheckoutState = { status: 'idle', receipt: null, error: null };

export const checkoutSlice = createSlice({
  name: 'checkout',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(placeOrder.pending, (state) => { state.status = 'pending'; state.error = null; })
      .addCase(placeOrder.fulfilled, (state, action) => { state.status = 'succeeded'; state.receipt = action.payload; })
      .addCase(placeOrder.rejected, (state, action) => { state.status = 'failed'; state.error = action.payload ?? 'Unknown error'; });
  },
});
```

Generate the idempotency key once per checkout attempt on the client (`crypto.randomUUID()`) and reuse it on retry. The server validates it as described in the skill's Safety Rules.

In a component, `await dispatch(placeOrder({ idempotencyKey })).unwrap()` throws on rejection, which suits `try/catch` around a submit.

### Thunks inside `reducers` with `create.asyncThunk`

The callback form of `reducers` can define thunks inline. The default `createSlice` throws if `create.asyncThunk` is used; build a slice creator that includes it:

```ts
// src/store/createAppSlice.ts
import { asyncThunkCreator, buildCreateSlice } from '@reduxjs/toolkit';

export const createAppSlice = buildCreateSlice({
  creators: { asyncThunk: asyncThunkCreator },
});
```

```ts
// src/store/profileSlice.ts
import { createAppSlice } from './createAppSlice';

interface Profile { id: string; displayName: string }

export const profileSlice = createAppSlice({
  name: 'profile',
  initialState: { data: null as Profile | null, loading: false, error: null as string | null },
  reducers: (create) => ({
    fetchProfile: create.asyncThunk(
      async (id: string, { signal }) => {
        const res = await fetch(`/api/profiles/${encodeURIComponent(id)}`, { signal });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return (await res.json()) as Profile;
      },
      {
        pending: (state) => { state.loading = true; state.error = null; },
        fulfilled: (state, action) => { state.data = action.payload; },
        rejected: (state, action) => { state.error = action.error.message ?? 'Failed'; },
        settled: (state) => { state.loading = false; },
      },
    ),
  }),
});

export const { fetchProfile } = profileSlice.actions;
```

`settled` runs after `fulfilled` or `rejected`, like `finally`.

## Selectors

Select the smallest value a component needs. `useSelector` re-renders when the selected value changes by reference, so a selector that builds a new array or object on every call re-renders every time.

```ts
import { createSelector } from '@reduxjs/toolkit';
import type { RootState } from './store';

const selectItems = (state: RootState) => state.cart.items;

export const selectCartTotal = createSelector([selectItems], (items) =>
  items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0),
);

// Parameterized: create one memoized selector per component instance if args vary
export const selectItemById = createSelector(
  [selectItems, (_state: RootState, productId: string) => productId],
  (items, productId) => items.find((i) => i.productId === productId),
);
```

```tsx
'use client';
import { useAppSelector } from '@/store/hooks';
import { selectCartCount } from '@/store/cartSlice';

export function CartBadge() {
  const count = useAppSelector(selectCartCount); // a number: re-renders only when it changes
  return <span aria-label={`${count} items in cart`}>{count}</span>;
}
```

Store normalized data (by id) for large collections with `createEntityAdapter`, which provides `selectAll`, `selectById`, and CRUD reducers.

## RTK Query

RTK Query caches server data, deduplicates requests, tracks loading state, and refetches on invalidation.

```ts
// src/store/api.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export interface Post { id: string; title: string; body: string }

export const api = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({ baseUrl: '/api', credentials: 'same-origin' }),
  tagTypes: ['Post'],
  endpoints: (build) => ({
    getPosts: build.query<Post[], void>({
      query: () => 'posts',
      providesTags: (result) =>
        result
          ? [...result.map(({ id }) => ({ type: 'Post' as const, id })), { type: 'Post', id: 'LIST' }]
          : [{ type: 'Post', id: 'LIST' }],
    }),
    getPost: build.query<Post, string>({
      query: (id) => `posts/${encodeURIComponent(id)}`,
      providesTags: (_result, _error, id) => [{ type: 'Post', id }],
    }),
    addPost: build.mutation<Post, Pick<Post, 'title' | 'body'>>({
      query: (body) => ({ url: 'posts', method: 'POST', body }),
      invalidatesTags: [{ type: 'Post', id: 'LIST' }],
    }),
    updatePost: build.mutation<Post, Pick<Post, 'id'> & Partial<Post>>({
      query: ({ id, ...patch }) => ({ url: `posts/${encodeURIComponent(id)}`, method: 'PATCH', body: patch }),
      invalidatesTags: (_result, _error, { id }) => [{ type: 'Post', id }],
    }),
  }),
});

export const { useGetPostsQuery, useGetPostQuery, useAddPostMutation, useUpdatePostMutation } = api;
```

Authentication goes in an httpOnly cookie sent by the browser (`credentials`); do not read a token from `localStorage` in `prepareHeaders`.

Skip a query until its argument exists with `skipToken`, which keeps the argument type narrow:

```tsx
'use client';
import { skipToken } from '@reduxjs/toolkit/query/react';
import { useGetPostQuery } from '@/store/api';

export function PostPreview({ postId }: { postId: string | null }) {
  const { data, isLoading, isError, refetch } = useGetPostQuery(postId ?? skipToken);

  if (!postId) return <p>Select a post.</p>;
  if (isError) return <p role="alert">Could not load the post. <button type="button" onClick={() => void refetch()}>Retry</button></p>;
  if (isLoading || !data) return <p role="status">Loading…</p>;
  return <article><h2>{data.title}</h2><p>{data.body}</p></article>;
}
```

`isLoading` is true only for the first load; `isFetching` is also true during background refetches. Show a spinner for `isLoading` and keep the old data on screen during `isFetching` (see [ui-states.md](ui-states.md)).

For an optimistic edit, patch the cache in `onQueryStarted` with `api.util.updateQueryData` and call `patch.undo()` if `queryFulfilled` rejects.

Call `setupListeners(store.dispatch)` from `@reduxjs/toolkit/query` once in a client-only entry to enable `refetchOnFocus` or `refetchOnReconnect`.

## Next.js App Router

A module-level store on the server is shared by every request and leaks one user's state to another. Create one store per request inside a Client Component provider.

```tsx
// app/StoreProvider.tsx
'use client';
import { useState, type ReactNode } from 'react';
import { Provider } from 'react-redux';
import { makeStore, type AppStore, type RootState } from '@/store/store';

export function StoreProvider({
  preloadedState,
  children,
}: {
  preloadedState?: Partial<RootState>;
  children: ReactNode;
}) {
  // Lazy initializer: one store per request on the server, one per tab in the browser
  const [store] = useState<AppStore>(() => makeStore(preloadedState));
  return <Provider store={store}>{children}</Provider>;
}
```

Render `<StoreProvider>` around `{children}` inside `<body>` in `app/layout.tsx`; the layout itself stays a Server Component.

A `useRef` guard (`if (!storeRef.current) storeRef.current = makeStore()`) works the same way.

Rules:

- Server Components never read or write the store. They cannot use hooks or context. Fetch on the server with `fetch` or the data layer and pass data down as props.
- Use RTK Query for client-side fetching only.
- A store in the root layout survives client navigation. To seed per-route data, dispatch once during render behind a `useRef` flag in a Client Component, not in `useEffect`, which runs after hydration and flickers.
- Pass only serializable, non-sensitive data as `preloadedState`; it is embedded in the HTML.
- Pages whose output depends on the user must not be cached for other users. See [nextjs-caching.md](nextjs-caching.md#per-user-and-safety-data).

## Testing

Test through the public API: dispatch actions to a reducer, and render components with a real store created per test.

```ts
// src/store/cartSlice.test.ts
import { describe, expect, it } from 'vitest';
import { cartSlice, itemAdded, itemRemoved } from './cartSlice';

describe('cartSlice', () => {
  it('merges quantities for the same product', () => {
    let state = cartSlice.reducer(undefined, itemAdded({ productId: 'p1', quantity: 1, unitPrice: 5 }));
    state = cartSlice.reducer(state, itemAdded({ productId: 'p1', quantity: 2, unitPrice: 5 }));
    expect(state.items).toEqual([{ productId: 'p1', quantity: 3, unitPrice: 5 }]);
  });
});
```

```tsx
// src/test/renderWithStore.tsx
import type { ReactElement, ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { makeStore, type AppStore, type RootState } from '@/store/store';

interface Options extends Omit<RenderOptions, 'wrapper'> {
  preloadedState?: Partial<RootState>;
  store?: AppStore;
}

export function renderWithStore(ui: ReactElement, { preloadedState, store = makeStore(preloadedState), ...options }: Options = {}) {
  function Wrapper({ children }: { children: ReactNode }) {
    return <Provider store={store}>{children}</Provider>;
  }
  return { store, user: userEvent.setup(), ...render(ui, { wrapper: Wrapper, ...options }) };
}
```

```tsx
// src/components/CartBadge.test.tsx
import { expect, it } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithStore } from '@/test/renderWithStore';
import { CartBadge } from './CartBadge';

it('shows the item count', () => {
  renderWithStore(<CartBadge />, {
    preloadedState: { cart: { items: [{ productId: 'p1', quantity: 2, unitPrice: 5 }] } },
  });
  expect(screen.getByLabelText('2 items in cart')).toBeInTheDocument();
});
```

Mock the network (MSW) rather than RTK Query or thunks. Never share a store between tests. General RTL setup: [testing.md](testing.md).

## Migrating Legacy Redux

Migrate one feature at a time; RTK stores accept hand-written reducers, so old and new code run together.

| Legacy | Redux Toolkit |
|--------|---------------|
| `createStore` + `applyMiddleware` + `compose` + DevTools setup | `configureStore` (thunk, DevTools, and dev checks included) |
| Action type constants + action creators + `switch` reducer | `createSlice` |
| Spread-heavy immutable updates | Immer "mutations" inside slice reducers |
| `redux-thunk` with manual loading flags | RTK Query, or `createAsyncThunk` |
| `reselect` | `createSelector` (re-exported by RTK) |
| `connect(mapState, mapDispatch)(Component)` | `useAppSelector` and `useAppDispatch` in function components |
| `TypedUseSelectorHook` wrappers | `useSelector.withTypes<RootState>()` |
| Normalizr or hand-rolled by-id maps | `createEntityAdapter` |

```ts
// Replaces a type constant, an action creator, and a switch case returning spread copies
const todosSlice = createSlice({
  name: 'todos',
  initialState: [] as Todo[],
  reducers: {
    todoAdded: {
      reducer: (state, action: PayloadAction<Todo>) => { state.push(action.payload); },
      prepare: (text: string) => ({ payload: { id: crypto.randomUUID(), text, done: false } }),
    },
  },
});
```

Order of work: swap `createStore` for `configureStore`; convert reducers to slices feature by feature; replace `connect` with hooks while converting class components (see [react-19-upgrade.md](react-19-upgrade.md#migrating-class-components-to-hooks)); move fetch logic to RTK Query last. Keep the existing action type strings when other code listens for them (`name: 'todos'` plus reducer key `added` yields `todos/added`).

## Rules

- Never store auth tokens or secrets in Redux, and never persist them with `redux-persist` or `localStorage`. Keep tokens in httpOnly cookies.
- Persist only non-sensitive preferences, and rehydrate after mount to avoid hydration mismatches (see [react-19-upgrade.md](react-19-upgrade.md#persisted-client-stores)).
- Keep state serializable: no class instances, Promises, `Date` objects, or DOM nodes. Store ISO strings and ids.
- Do not copy server data into hand-written slices; let RTK Query own it.
- Select primitives or memoized values; never return a new object from an unmemoized selector.
- One store per request on the server; one store per test.
