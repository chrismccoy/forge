# React Hooks: Performance Hooks and React 19 Hooks

Detailed coverage of `useMemo`, `useCallback`, the concurrent hooks `useTransition` and `useDeferredValue` (React 18+), and React 19 hooks such as `useActionState`, `useOptimistic`, and `useFormStatus`. `use()` is covered in [`fundamentals.md`](fundamentals.md#the-use-hook). `hooks.md` keeps state, effect, context, ref, custom-hook, and Rules of Hooks essentials.

## Contents

- [Performance Hooks](#performance-hooks)
- [Concurrent Hooks (React 18+)](#concurrent-hooks-react-18)
- [React 19 Hooks](#react-19-hooks)

## Performance Hooks

Do not memoize by default. Reach for `useMemo`, `useCallback`, and `memo` only when the React Profiler shows a measured hotspot, or when a value crosses a stable-prop boundary (a `memo` child, or an effect/hook dependency that must not change every render). With React Compiler enabled, manual memoization is mostly unnecessary.

### useMemo

```tsx
import { useMemo, useState } from 'react';

function ProductList({ products, filter }: Props) {
  // Memoize only if profiling shows this filter is expensive
  const filteredProducts = useMemo(() => {
    console.log('Filtering products...');
    return products.filter((product) => {
      if (filter.category && product.category !== filter.category) {
        return false;
      }
      if (filter.minPrice && product.price < filter.minPrice) {
        return false;
      }
      if (filter.maxPrice && product.price > filter.maxPrice) {
        return false;
      }
      return true;
    });
  }, [products, filter]);

  // Cheap derived data: compute directly, no useMemo needed
  const stats = {
    total: filteredProducts.length,
    avgPrice:
      filteredProducts.length > 0
        ? filteredProducts.reduce((sum, p) => sum + p.price, 0) /
          filteredProducts.length
        : 0,
  };

  return (
    <div>
      <p>
        Showing {stats.total} products (avg: ${stats.avgPrice.toFixed(2)})
      </p>
      {filteredProducts.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

### useCallback

`useCallback` only pays off when the function is passed to a `memo` child (as here) or used as an effect dependency. Without such a boundary it adds cost and no benefit.

```tsx
import { useCallback, useState, memo } from 'react';

// Memoized child component (justified when the list is large and profiling shows re-render cost)
const TodoItem = memo(function TodoItem({
  todo,
  onToggle,
  onDelete,
}: {
  todo: Todo;
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
}) {
  console.log('Rendering todo:', todo.id);
  return (
    <li>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={() => onToggle(todo.id)}
      />
      <span>{todo.text}</span>
      <button onClick={() => onDelete(todo.id)}>Delete</button>
    </li>
  );
});

function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // Stable callback reference
  const handleToggle = useCallback((id: number) => {
    setTodos((prev) =>
      prev.map((todo) =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  }, []);

  const handleDelete = useCallback((id: number) => {
    setTodos((prev) => prev.filter((todo) => todo.id !== id));
  }, []);

  return (
    <ul>
      {todos.map((todo) => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={handleToggle}
          onDelete={handleDelete}
        />
      ))}
    </ul>
  );
}
```

## Concurrent Hooks (React 18+)

`useTransition` and `useDeferredValue` were introduced in React 18. React 19 adds async functions in transitions (Actions) and an `initialValue` argument for `useDeferredValue`.

### useTransition

```tsx
import { useState, useTransition } from 'react';

function TabContainer() {
  const [tab, setTab] = useState('about');
  const [isPending, startTransition] = useTransition();

  function selectTab(nextTab: string) {
    // Mark state update as non-urgent
    startTransition(() => {
      setTab(nextTab);
    });
  }

  return (
    <div>
      <nav>
        {['about', 'posts', 'contact'].map((t) => (
          <button
            key={t}
            onClick={() => selectTab(t)}
            className={tab === t ? 'active' : ''}
          >
            {t}
          </button>
        ))}
      </nav>

      <div className={isPending ? 'pending' : ''}>
        {tab === 'about' && <AboutTab />}
        {tab === 'posts' && <PostsTab />}
        {tab === 'contact' && <ContactTab />}
      </div>
    </div>
  );
}
```

### useDeferredValue

```tsx
import { useState, useDeferredValue, memo } from 'react';

const SlowList = memo(function SlowList({ text }: { text: string }) {
  // Expensive rendering
  const items = [];
  for (let i = 0; i < 20000; i++) {
    items.push(<li key={i}>{text}</li>);
  }
  return <ul>{items}</ul>;
});

function App() {
  const [text, setText] = useState('');
  const deferredText = useDeferredValue(text);

  return (
    <div>
      <input
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Type here..."
      />
      {/* Input stays responsive while list updates are deferred */}
      <SlowList text={deferredText} />
    </div>
  );
}
```

`useDeferredValue` only helps when the slow child can skip the urgent render: wrap it in `memo` (or rely on React Compiler), otherwise it re-renders with the new `text` anyway. This is one of the few places `memo` is needed by default.

### Choosing useTransition or useDeferredValue

| | `useTransition` | `useDeferredValue` |
|---|---|---|
| Use when | The component owns the state update | The component receives the value (prop, hook result) |
| What gets wrapped | The `setState` call (or an async action) | The value |
| Pending signal | `isPending` | Compare `value !== deferredValue` to dim stale UI |
| Typical case | Tab switches, filters, navigation | Search results driven by an input |

Keep text inputs out of transitions: the input's own state must update urgently or typing lags.

## React 19 Hooks

### useActionState

`const [state, formAction, isPending] = useActionState(action, initialState, permalink?)`

- React calls `action(prevState, formData)`, so the action's first parameter is the previous state, and every return path must produce the same state shape.
- Pass `formAction` to `<form action>` or `<button formAction>`. Calling it outside a form requires `startTransition`.
- `isPending` is true while the action runs. Use it to disable the submit button.
- After a successful `<form action>` submission, React resets uncontrolled fields. Return submitted values in `state` when the fields must keep them on error.

For a complete Server Action wired through `useActionState`, see [fundamentals.md](fundamentals.md#using-useactionstate). For field errors and bound arguments, see [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms); for idempotent submits, see [forms-server-actions.md](forms-server-actions.md#idempotent-server-actions).

### useOptimistic

The optimistic setter must be called inside a transition or a form action. Calling it from a plain async event handler logs a warning and the optimistic value is discarded immediately.

```tsx
'use client';

import { useOptimistic, useState, useTransition } from 'react';
import { likePost } from './actions'; // Server Action or any async function

function LikeButton({ postId, initialLikes }: { postId: string; initialLikes: number }) {
  const [likes, setLikes] = useState(initialLikes);
  const [isPending, startTransition] = useTransition();
  const [optimisticLikes, addOptimisticLike] = useOptimistic(
    likes,
    (current, delta: number) => current + delta
  );

  function handleLike() {
    startTransition(async () => {
      addOptimisticLike(1); // Shown until the transition settles
      const newLikes = await likePost(postId);
      // Updates after an await are not part of the transition automatically:
      // wrap them in startTransition again
      startTransition(() => {
        setLikes(newLikes); // Real value replaces the optimistic one
      });
    });
  }

  return (
    <button onClick={handleLike} disabled={isPending}>
      Like ({optimisticLikes})
    </button>
  );
}
```

If `likePost` throws, the optimistic value reverts automatically when the transition ends; surface the error with an error boundary or local state.

### useFormStatus

```tsx
'use client';

import { useFormStatus } from 'react-dom';

function SubmitButton() {
  // Must be rendered inside a <form>; reads that form's status
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

// submitAction: any form action, e.g. a Server Action imported from './actions'
function Form({ submitAction }: { submitAction: (formData: FormData) => Promise<void> }) {
  return (
    <form action={submitAction}>
      <input type="text" name="name" />
      <SubmitButton />
    </form>
  );
}
```
