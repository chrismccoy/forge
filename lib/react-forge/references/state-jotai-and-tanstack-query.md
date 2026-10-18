# React State Management: Jotai and TanStack Query

Detailed patterns for Jotai atom-based state management and TanStack Query (React Query) server-state management: atoms, derived atoms, async atoms, query clients, mutations, invalidation, optimistic updates, and cache tuning. `state-management.md` keeps built-in state, Context API, Zustand, SWR, and best-practice selection guidance.

## Contents

- [Jotai](#jotai)
- [TanStack Query (React Query)](#tanstack-query-react-query)

## Jotai

### Basic Jotai Atoms

```tsx
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai';
import { atomWithStorage } from 'jotai/utils';

// Primitive atoms
const countAtom = atom(0);
const textAtom = atom('');

// Derived atom (computed value)
const doubleCountAtom = atom((get) => get(countAtom) * 2);

// Writable derived atom
const uppercaseTextAtom = atom(
  (get) => get(textAtom).toUpperCase(),
  (get, set, newValue: string) => set(textAtom, newValue.toLowerCase())
);

// Async atom (Jotai passes an AbortSignal that aborts when the atom re-evaluates)
const userAtom = atom(async (_get, { signal }) => {
  const response = await fetch('/api/user', { signal });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return (await response.json()) as User;
});

// Persisted atom (localStorage: never store tokens or other secrets this way)
const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light');

// Usage
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const doubleCount = useAtomValue(doubleCountAtom);

  return (
    <div>
      <p>Count: {count}</p>
      <p>Double: {doubleCount}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
    </div>
  );
}
```

### Jotai with Async Actions

```tsx
import { useAtom } from 'jotai';
import { atomWithQuery, atomWithMutation } from 'jotai-tanstack-query';

interface Post {
  id: string;
  title: string;
  content: string;
}

// Query atom
const postsAtom = atomWithQuery(() => ({
  queryKey: ['posts'],
  queryFn: async ({ signal }): Promise<Post[]> => {
    const res = await fetch('/api/posts', { signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  },
}));

// Mutation atom
const createPostAtom = atomWithMutation(() => ({
  mutationFn: async (newPost: { title: string; content: string }) => {
    const res = await fetch('/api/posts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(newPost),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return (await res.json()) as Post;
  },
}));

function Posts() {
  const [{ data: posts, isLoading }] = useAtom(postsAtom);
  const [{ mutate: createPost, isPending }] = useAtom(createPostAtom);

  if (isLoading || !posts) return <p>Loading...</p>;

  return (
    <div>
      {posts.map((post) => (
        <article key={post.id}>{post.title}</article>
      ))}
      <button
        type="button"
        disabled={isPending}
        onClick={() => createPost({ title: 'New', content: 'Content' })}
      >
        {isPending ? 'Creating...' : 'Add Post'}
      </button>
    </div>
  );
}
```

## TanStack Query (React Query)

### Basic Queries

A module-scope `QueryClient` is fine for a client-only app. With server rendering, a module-scope client is shared by every request, so cached data can leak between users. Create one client per request instead, inside the provider component:

```tsx
'use client';

import { useState, type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

export function QueryProvider({ children }: { children: ReactNode }) {
  // Created once per mounted provider: per request on the server, once in the browser
  const [queryClient] = useState(() => new QueryClient());
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
```

The client-only setup:

```tsx
import { useQuery, useMutation, useQueryClient, QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Query client setup
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 30, // 30 minutes
      retry: 3,
      refetchOnWindowFocus: true,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Posts />
    </QueryClientProvider>
  );
}

// Fetching data
function Posts() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['posts'],
    // TanStack Query passes an AbortSignal and handles races, dedupe, and caching
    queryFn: async ({ signal }): Promise<Post[]> => {
      const res = await fetch('/api/posts', { signal });
      if (!res.ok) throw new Error('Failed to fetch');
      return res.json();
    },
  });

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!data) return null;

  return (
    <div>
      {data.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
      <button type="button" onClick={() => refetch()}>Refresh</button>
    </div>
  );
}
```

### Mutations with Optimistic Updates

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';

function useCreatePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (newPost: CreatePostInput) => {
      const res = await fetch('/api/posts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newPost),
      });
      if (!res.ok) throw new Error('Failed to create post');
      return res.json();
    },
    onMutate: async (newPost) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['posts'] });

      // Snapshot previous value
      const previousPosts = queryClient.getQueryData<Post[]>(['posts']);

      // Optimistically update (old is undefined if the list was never fetched)
      queryClient.setQueryData<Post[]>(['posts'], (old = []) => [
        { ...newPost, id: `temp-${crypto.randomUUID()}` },
        ...old,
      ]);

      return { previousPosts };
    },
    onError: (err, newPost, context) => {
      // Rollback on error
      queryClient.setQueryData(['posts'], context?.previousPosts);
    },
    onSettled: () => {
      // Refetch after mutation
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });
}

function CreatePostForm() {
  const createPost = useCreatePost();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    createPost.mutate({
      title: formData.get('title') as string,
      content: formData.get('content') as string,
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="post-title">Title</label>
      <input id="post-title" name="title" required />
      <label htmlFor="post-content">Content</label>
      <textarea id="post-content" name="content" required />
      {createPost.isError && <p role="alert">{createPost.error.message}</p>}
      <button type="submit" disabled={createPost.isPending}>
        {createPost.isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

### Infinite Queries

```tsx
import { Fragment } from 'react';
import { useInfiniteQuery } from '@tanstack/react-query';

interface PostsPage {
  posts: Post[];
  nextCursor: number | null;
}

function InfinitePosts() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: ['posts', 'infinite'],
    queryFn: async ({ pageParam, signal }): Promise<PostsPage> => {
      const res = await fetch(`/api/posts?cursor=${pageParam}&limit=10`, { signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    },
    // Return undefined (not null) to signal there is no next page
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    initialPageParam: 0,
  });

  if (isLoading) return <Spinner />;

  return (
    <div>
      {data?.pages.map((page, i) => (
        <Fragment key={i}>
          {page.posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </Fragment>
      ))}

      <button
        type="button"
        onClick={() => fetchNextPage()}
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage
          ? 'Loading more...'
          : hasNextPage
          ? 'Load More'
          : 'No more posts'}
      </button>
    </div>
  );
}
```
