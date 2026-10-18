# React 19 Fundamentals

Components, Server and Client Components, Server Actions, `use()`, props and state, Suspense, and error boundaries in React 19.

## Contents

- [Quick Reference](#quick-reference)
- [Overview](#overview)
- [JSX and Components](#jsx-and-components)
- [Server vs Client Components](#server-vs-client-components)
- [Server Actions](#server-actions)
- [The use() Hook](#the-use-hook)
- [Props and State](#props-and-state)
- [Suspense and Error Boundaries](#suspense-and-error-boundaries)
- [Fragments and Portals](#fragments-and-portals)
- [Best Practices](#best-practices)

## Quick Reference

| Feature | Pattern | Example |
|---------|---------|---------|
| Server Component | Default (no directive) | `async function Page() {}` |
| Client Component | `'use client'` directive | `'use client'; function Counter() {}` |
| Server Action | `'use server'` directive (framework-supported) | `async function submit(prevState, formData) {}` |
| use() hook | Read promises/context | `const data = use(promise)` |

| Concept | Syntax |
|---------|--------|
| Conditional render | `{condition && <Component />}` |
| List render | `{items.map(item => <Item key={item.id} />)}` |
| Props destructure | `function Card({ title, children }) {}` |
| State update | `setItems(prev => [...prev, newItem])` |

## Overview

React 19 (released December 2024) adds Actions and async transitions, new hooks (`useActionState`, `useOptimistic`, `useFormStatus`, `use`), `ref` as a regular prop, and stable Server Components and Server Actions for frameworks that support them (e.g. Next.js, React Router). The React Compiler is a separate build-time tool (a Babel plugin) that works with React 17+ and is not part of the React 19 release itself.

## JSX and Components

### Function Components

```tsx
// Basic component
function Greeting({ name }: { name: string }) {
  return <h1>Hello, {name}!</h1>;
}

// With children
function Card({ children, title }: { children: React.ReactNode; title: string }) {
  return (
    <div className="card">
      <h2>{title}</h2>
      {children}
    </div>
  );
}

// Arrow function component
const Button: React.FC<{ onClick: () => void; children: React.ReactNode }> = ({
  onClick,
  children,
}) => (
  <button onClick={onClick}>{children}</button>
);
```

### JSX Expressions

```tsx
function ProductCard({ product }: { product: Product }) {
  return (
    <div className="product">
      {/* Conditional rendering */}
      {product.onSale && <span className="badge">Sale!</span>}

      {/* Ternary */}
      {product.inStock ? (
        <button>Add to Cart</button>
      ) : (
        <span>Out of Stock</span>
      )}

      {/* Logical AND (short-circuit) */}
      {product.reviews.length > 0 && (
        <Reviews reviews={product.reviews} />
      )}

      {/* Mapping arrays */}
      <ul>
        {product.features.map((feature) => (
          <li key={feature.id}>{feature.name}</li>
        ))}
      </ul>

      {/* Nullish coalescing */}
      <span>{product.discount ?? 0}% off</span>
    </div>
  );
}
```

## Server vs Client Components

### Server Components (Default)

Server Components run only in a framework that supports them (e.g. Next.js, React Router). In those frameworks, components are Server Components unless marked `'use client'`.

```tsx
// components/PostsPage.tsx - Server Component by default
import { db } from '@/lib/db';

async function PostsPage() {
  // Direct database access - runs on server only
  const posts = await db.posts.findMany({
    orderBy: { createdAt: 'desc' },
  });

  return (
    <div>
      <h1>Posts</h1>
      {posts.map((post) => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  );
}

export default PostsPage;
```

### Client Components

```tsx
// components/Counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
    </div>
  );
}
```

### Composing Server and Client Components

```tsx
// Server Component
import { db } from '@/lib/db';
import { LikeButton } from './LikeButton'; // Client Component

async function Post({ id }: { id: string }) {
  const post = await db.posts.findUnique({ where: { id } });
  if (!post) return <p>Post not found</p>;

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
      {/* Client component for interactivity */}
      <LikeButton postId={id} initialLikes={post.likes} />
    </article>
  );
}
```

```tsx
// LikeButton.tsx - Client Component
'use client';

import { useState, useTransition } from 'react';
import { likePost } from './actions';

export function LikeButton({ postId, initialLikes }: { postId: string; initialLikes: number }) {
  const [likes, setLikes] = useState(initialLikes);
  const [isPending, startTransition] = useTransition();

  const handleLike = () => {
    startTransition(async () => {
      const newLikes = await likePost(postId);
      // Updates after an await need their own startTransition
      startTransition(() => {
        setLikes(newLikes);
      });
    });
  };

  return (
    <button onClick={handleLike} disabled={isPending}>
      {isPending ? 'Liking...' : `Like (${likes})`}
    </button>
  );
}
```

## Server Actions

Server Actions run in a framework that supports them (e.g. Next.js, React Router). Treat every action as a public endpoint: authenticate, validate input, and scope writes to the current user.

### Defining Server Actions

```tsx
// actions.ts
'use server';

import { z } from 'zod';
import { db } from '@/lib/db';
import { getSession } from '@/lib/auth';

const postSchema = z.object({
  title: z.string().min(1, { error: 'Title is required' }).max(200),
  content: z.string().min(1, { error: 'Content is required' }),
});

export type CreatePostState = {
  error?: string;
  fieldErrors?: Partial<Record<'title' | 'content', string[]>>;
  success?: boolean;
};

// useActionState calls the action as action(prevState, formData)
export async function createPost(
  prevState: CreatePostState,
  formData: FormData
): Promise<CreatePostState> {
  const session = await getSession();
  if (!session) {
    return { error: 'You must be signed in' };
  }

  const parsed = postSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });
  if (!parsed.success) {
    return {
      error: 'Please fix the errors below',
      fieldErrors: z.flattenError(parsed.error).fieldErrors,
    };
  }

  await db.posts.create({
    data: { ...parsed.data, authorId: session.user.id },
  });

  // framework-specific cache invalidation (e.g. Next.js revalidatePath; see the framework docs)
  return { success: true };
}

export async function likePost(postId: string): Promise<number> {
  const session = await getSession();
  if (!session) {
    throw new Error('Unauthorized');
  }

  const id = z.string().min(1).parse(postId);

  // Record one like per user, then return the new count
  await db.likes.upsert({
    where: { postId_userId: { postId: id, userId: session.user.id } },
    create: { postId: id, userId: session.user.id },
    update: {},
  });

  return db.likes.count({ where: { postId: id } });
}
```

### Using Server Actions in Forms

An action passed directly to `<form action>` receives only `formData`. Because `createPost` above uses the `useActionState` signature, wire it through `useActionState` (next section). A plain form action looks like this:

```tsx
// actions.ts ('use server'): export async function savePost(formData: FormData): Promise<void>
import { savePost } from './actions';

function CreatePostForm() {
  return (
    <form action={savePost}>
      <input type="text" name="title" placeholder="Title" required />
      <textarea name="content" placeholder="Content" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

### Using useActionState

```tsx
'use client';

import { useActionState } from 'react';
import { createPost, type CreatePostState } from './actions';

const initialState: CreatePostState = {};

function CreatePostForm() {
  const [state, formAction, isPending] = useActionState(createPost, initialState);

  return (
    <form action={formAction}>
      <input type="text" name="title" placeholder="Title" required />
      {state.fieldErrors?.title && <p className="error">{state.fieldErrors.title[0]}</p>}

      <textarea name="content" placeholder="Content" required />
      {state.fieldErrors?.content && <p className="error">{state.fieldErrors.content[0]}</p>}

      {state.error && <p className="error">{state.error}</p>}
      {state.success && <p className="success">Post created!</p>}

      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

## The use() Hook

### Reading Promises

Do not create the promise during render of a Client Component: every render creates a new promise, so `use()` suspends again and loops. Create it in a Server Component (or a framework loader), or cache it outside render, and pass it down as a prop.

```tsx
// Post.tsx - Server Component (framework-supported)
import { Suspense } from 'react';
import { db } from '@/lib/db';
import { Comments } from './Comments';

export async function Post({ postId }: { postId: string }) {
  // Start the query on the server, do not await it here
  const commentsPromise = db.comments.findMany({ where: { postId } });

  return (
    <article>
      <h1>Post Title</h1>
      <Suspense fallback={<p>Loading comments...</p>}>
        <Comments commentsPromise={commentsPromise} />
      </Suspense>
    </article>
  );
}
```

```tsx
// Comments.tsx - Client Component
'use client';

import { use } from 'react';

export function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);

  return (
    <ul>
      {comments.map((comment) => (
        <li key={comment.id}>{comment.text}</li>
      ))}
    </ul>
  );
}
```

Without Server Components, create the promise outside render (an event handler, a route loader, or a cache keyed by `postId`) or use a data library with Suspense support such as TanStack Query (`useSuspenseQuery`).

### Reading Context Conditionally

```tsx
import { use } from 'react';
import { ThemeContext } from './ThemeContext'; // canonical shape: state-management.md

function ThemedButton({ showTheme }: { showTheme: boolean }) {
  // use() can be called conditionally (unlike useContext)
  if (showTheme) {
    const themeContext = use(ThemeContext);
    const isDark = themeContext?.theme === 'dark';
    return <button className={isDark ? 'button-dark' : 'button-light'}>Themed</button>;
  }

  return <button>Default</button>;
}
```

## Props and State

### Props Patterns

```tsx
// Destructuring props
function UserCard({ user, onEdit, className = '' }: UserCardProps) {
  return (
    <div className={`user-card ${className}`}>
      <h3>{user.name}</h3>
      <button onClick={() => onEdit(user.id)}>Edit</button>
    </div>
  );
}

// Spreading props
function Button({ children, ...props }: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return <button {...props}>{children}</button>;
}

// Default props with TypeScript
interface CardProps {
  title: string;
  elevated?: boolean;
  padding?: 'sm' | 'md' | 'lg';
}

function Card({ title, elevated = false, padding = 'md' }: CardProps) {
  return (
    <div
      className={`card ${elevated ? 'elevated' : ''} padding-${padding}`}
    >
      <h2>{title}</h2>
    </div>
  );
}
```

### State Updates

```tsx
'use client';

import { useState } from 'react';

function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // Functional update for derived state
  const addTodo = (text: string) => {
    setTodos((prev) => [
      ...prev,
      { id: Date.now(), text, completed: false },
    ]);
  };

  // Toggle item
  const toggleTodo = (id: number) => {
    setTodos((prev) =>
      prev.map((todo) =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  };

  // Remove item
  const removeTodo = (id: number) => {
    setTodos((prev) => prev.filter((todo) => todo.id !== id));
  };

  return (
    <ul>
      {todos.map((todo) => (
        <li key={todo.id}>
          <input
            type="checkbox"
            checked={todo.completed}
            onChange={() => toggleTodo(todo.id)}
          />
          <span>{todo.text}</span>
          <button onClick={() => removeTodo(todo.id)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

## Suspense and Error Boundaries

### Suspense for Loading States

```tsx
import { Suspense } from 'react';

function App() {
  return (
    <div>
      <h1>My App</h1>

      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>

      <Suspense fallback={<SidebarSkeleton />}>
        <Sidebar />
      </Suspense>

      <Suspense fallback={<ContentSkeleton />}>
        <MainContent />
      </Suspense>
    </div>
  );
}
```

### Error Boundaries

```tsx
'use client';

import { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }

    return this.props.children;
  }
}

// Usage
function App() {
  return (
    <ErrorBoundary fallback={<ErrorPage />}>
      <MainContent />
    </ErrorBoundary>
  );
}
```

### Error Boundary Hook (react-error-boundary library)

React has no built-in hook for error boundaries. The third-party `react-error-boundary` package provides an `ErrorBoundary` component and a `useErrorBoundary` hook for errors thrown outside rendering (event handlers, async code):

```tsx
'use client';

import { useErrorBoundary } from 'react-error-boundary';

function DataLoader() {
  const { showBoundary } = useErrorBoundary();

  const loadData = async () => {
    try {
      const data = await fetchData();
      return data;
    } catch (error) {
      showBoundary(error);
    }
  };

  // ...
}
```

## Fragments and Portals

### Fragments

```tsx
// Short syntax
function List() {
  return (
    <>
      <li>Item 1</li>
      <li>Item 2</li>
    </>
  );
}

// With key (for mapping)
import { Fragment } from 'react';

function DefinitionList({ items }: { items: { term: string; definition: string }[] }) {
  return (
    <dl>
      {items.map((item) => (
        <Fragment key={item.term}>
          <dt>{item.term}</dt>
          <dd>{item.definition}</dd>
        </Fragment>
      ))}
    </dl>
  );
}
```

### Portals

For a modal, prefer the native `<dialog>` element opened with `showModal()`. The browser renders it in the top layer (no portal needed), makes the rest of the page inert, moves focus into the dialog, closes it on Escape, and returns focus to the previously focused element when it closes.

```tsx
'use client';

import { useEffect, useId, useRef, type ReactNode } from 'react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}

function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleId = useId();

  // Sync the prop with the native open state; runs only on the client
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (isOpen && !dialog.open) dialog.showModal();
    if (!isOpen && dialog.open) dialog.close();
  }, [isOpen]);

  return (
    // onClose fires for Escape and for dialog.close(), keeping parent state in sync
    <dialog ref={dialogRef} aria-labelledby={titleId} onClose={onClose}>
      <h2 id={titleId}>{title}</h2>
      {children}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  );
}
```

Use `createPortal` for overlays that must escape a parent's `overflow` or stacking context but are not modal, such as toasts or tooltips. Render nothing until mounted, because `document` does not exist on the server:

```tsx
'use client';

import { createPortal } from 'react-dom';
import { useEffect, useState, type ReactNode } from 'react';

function Toast({ children }: { children: ReactNode }) {
  // Render nothing until mounted so server and client markup match
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  return createPortal(
    <div role="status" className="toast">
      {children}
    </div>,
    document.body
  );
}
```

A custom modal built with a portal instead of `<dialog>` must add everything the browser would otherwise provide: `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing at the title, moving focus into the dialog on open and restoring it on close, trapping Tab inside, closing on Escape, and making the background `inert`.

## Best Practices

### 1. Component Organization

```text
src/
  components/
    ui/              # Reusable UI components
      Button.tsx
      Card.tsx
    features/        # Feature-specific components
      auth/
        LoginForm.tsx
        SignupForm.tsx
    layout/          # Layout components
      Header.tsx
      Footer.tsx
  hooks/             # Custom hooks
    useAuth.ts
    useLocalStorage.ts
  lib/               # Utilities and helpers
    utils.ts
    api.ts
  types/             # TypeScript types
    index.ts
```

### 2. Naming Conventions

- Components: PascalCase (`UserProfile.tsx`)
- Hooks: camelCase with `use` prefix (`useAuth.ts`)
- Utilities: camelCase (`formatDate.ts`)
- Types: PascalCase (`User`, `ApiResponse`)
- Props types: component name plus `Props` (`UserProfileProps`)
- Booleans: `is`, `has`, `can`, `should` prefixes (`isLoading`, `hasError`)
- Event handlers: `handle` inside the component (`handleSubmit`), `on` for the prop (`onSubmit`)
- Interfaces: no `I` prefix (`PaymentGateway`, not `IPaymentGateway`)
- Module-level constants: `UPPER_SNAKE_CASE` (`MAX_UPLOAD_BYTES`)

Pick one file-name style per project, PascalCase or kebab-case, and keep it consistent. Next.js route files (`page.tsx`, `layout.tsx`) keep their fixed lowercase names.

### 3. Key Prop Usage

```tsx
// Good - stable unique identifier
{items.map((item) => (
  <Item key={item.id} data={item} />
))}

// Avoid - index as key (unless list is static)
{items.map((item, index) => (
  <Item key={index} data={item} /> // Can cause issues with reordering
))}
```

### 4. Memoize Only When Measured

Inline objects and functions are fine by default. Do not wrap them in `useMemo`/`useCallback` preemptively.

```tsx
// Default - inline props are fine
<Component style={{ color: 'red' }} onClick={() => handleClick(id)} />

// Only when profiling shows a hotspot, or the child is wrapped in memo()
// and its props must stay referentially stable:
const handleClickStable = useCallback(() => handleClick(id), [id]);
<MemoizedChild onClick={handleClickStable} />
```

Hoist true constants (such as a static style object) to module scope instead of memoizing them. With React Compiler enabled, manual memoization is mostly unnecessary.

### 5. Feature Folders and Boundaries

As the app grows, group code by feature instead of by file type, and keep shared primitives separate.

```text
src/
  components/ui/        # Shared primitives (Button, Input, Dialog)
  features/
    orders/
      components/       # OrderList.tsx, OrderDetail.tsx
      hooks/            # useOrders.ts
      api.ts            # Data access for this feature
      schemas.ts        # Zod schemas shared by client and server
      types.ts
    auth/
  lib/                  # Cross-feature utilities
```

- A feature may import from `components/ui` and `lib`, not from another feature's internals. Move shared code up instead.
- Co-locate tests next to the code (`OrderList.test.tsx`).
- Import modules directly. Large `index.ts` barrel files slow dev builds and can defeat tree-shaking; if one exists, keep it to the feature's public API.
- In Next.js, keep routes thin in `app/` and import feature code from `src/features`. Mark server-side data-access modules with `import 'server-only'`.
