# React with TypeScript

Typing props, events, hooks, and context in React 19 with TypeScript.

## Contents

- [Quick Reference](#quick-reference)
- [Component Props](#component-props)
- [Event Handlers](#event-handlers)
- [Hooks with TypeScript](#hooks-with-typescript)
- [Generic Components, Type Utilities & Type-Safe Context](#generic-components-type-utilities--type-safe-context)
- [Typed Errors and Results](#typed-errors-and-results)
- [Best Practices](#best-practices)

## Quick Reference

| Type | Usage | Example |
|------|-------|---------|
| Props interface | Component props | `interface ButtonProps { variant: 'primary' }` |
| `ReactNode` | Children | `children: ReactNode` |
| `ChangeEvent` | Input change | `(e: ChangeEvent<HTMLInputElement>)` |
| `FormEvent` | Form submit | `(e: FormEvent<HTMLFormElement>)` |
| `MouseEvent` | Click | `(e: MouseEvent<HTMLButtonElement>)` |

| Pattern | Example |
|---------|---------|
| Extend HTML props | `extends ButtonHTMLAttributes<HTMLButtonElement>` |
| Generic component | `function List<T>({ items }: { items: T[] })` |
| `ref` as a prop (React 19) | `function Input({ ref, ...props }: ComponentProps<'input'>)` |
| Discriminated union | `{ status: 'success'; data: T } \| { status: 'error'; error: Error }` |

| Utility Type | Purpose |
|--------------|---------|
| `Partial<T>` | All props optional |
| `Pick<T, K>` | Select specific props |
| `Omit<T, K>` | Exclude specific props |
| `ComponentProps<'button'>` | Get element props |

## Component Props

### Basic Props Types

```tsx
// Inline props type
function Greeting({ name, age }: { name: string; age: number }) {
  return <p>Hello {name}, you are {age} years old</p>;
}

// Interface for props
interface UserCardProps {
  name: string;
  email: string;
  avatar?: string;  // Optional prop
  role: 'admin' | 'user' | 'guest';  // Union type
}

function UserCard({ name, email, avatar, role }: UserCardProps) {
  return (
    <div className="user-card">
      {avatar && <img src={avatar} alt={name} />}
      <h3>{name}</h3>
      <p>{email}</p>
      <span className={`badge-${role}`}>{role}</span>
    </div>
  );
}

// Type alias
type ButtonVariant = 'primary' | 'secondary' | 'danger';
type ButtonSize = 'sm' | 'md' | 'lg';

type ButtonProps = {
  variant?: ButtonVariant;
  size?: ButtonSize;
  children: React.ReactNode;
  onClick?: () => void;
};

function Button({ variant = 'primary', size = 'md', children, onClick }: ButtonProps) {
  return (
    <button className={`btn btn-${variant} btn-${size}`} onClick={onClick}>
      {children}
    </button>
  );
}
```

### Children Props

```tsx
import { ReactNode, PropsWithChildren } from 'react';

// Using ReactNode
interface CardProps {
  title: string;
  children: ReactNode;
}

function Card({ title, children }: CardProps) {
  return (
    <div className="card">
      <h2>{title}</h2>
      {children}
    </div>
  );
}

// Using PropsWithChildren
type ContainerProps = PropsWithChildren<{
  className?: string;
}>;

function Container({ className, children }: ContainerProps) {
  return <div className={className}>{children}</div>;
}

// Render prop children: type the callback with the real states (data is null while loading)
interface DataFetcherProps<T> {
  url: string;
  children: (data: T | null, loading: boolean) => ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const { data, loading } = useFetch<T>(url); // see "Custom Hooks" below
  return <>{children(data, loading)}</>;
}
```

### Extending HTML Element Props

In React 19, `ref` is a regular prop on function components. `ComponentProps<'button'>` already includes it, so destructure `ref` and pass it to the element. `forwardRef` is only needed as a React 18 fallback.

```tsx
import { useId, type ComponentProps } from 'react';

// Extend button props
type CustomButtonProps = ComponentProps<'button'> & {
  variant?: 'primary' | 'secondary';
  isLoading?: boolean;
};

function CustomButton({
  variant = 'primary',
  isLoading,
  children,
  className,
  disabled,
  ref,
  ...props
}: CustomButtonProps) {
  return (
    <button
      ref={ref}
      className={`btn btn-${variant} ${className ?? ''}`}
      disabled={disabled || isLoading}
      aria-busy={isLoading || undefined}
      {...props}
    >
      {isLoading ? 'Loading...' : children}
    </button>
  );
}

// Extend input props (omit the native `size` to replace it)
type TextInputProps = Omit<ComponentProps<'input'>, 'size'> & {
  label: string;
  error?: string;
  size?: 'sm' | 'md' | 'lg';
};

function TextInput({ label, error, size = 'md', className, id, ref, ...props }: TextInputProps) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const errorId = `${inputId}-error`;

  return (
    <div className="form-field">
      <label htmlFor={inputId}>{label}</label>
      <input
        ref={ref}
        id={inputId}
        className={`input input-${size} ${error ? 'input-error' : ''} ${className ?? ''}`}
        aria-invalid={!!error}
        aria-describedby={error ? errorId : undefined}
        {...props}
      />
      {error && (
        <span id={errorId} className="error-message">
          {error}
        </span>
      )}
    </div>
  );
}

// Usage: the ref reaches the <input>
// const inputRef = useRef<HTMLInputElement>(null);
// <TextInput label="Email" ref={inputRef} />
```

### Polymorphic Components

```tsx
import type { ComponentPropsWithoutRef, ElementType } from 'react';

type BoxProps<C extends ElementType> = {
  as?: C;
} & Omit<ComponentPropsWithoutRef<C>, 'as'>;

function Box<C extends ElementType = 'div'>({ as, ...props }: BoxProps<C>) {
  const Component = as ?? 'div';
  return <Component {...props} />;
}

// Usage: props are checked against the chosen element
function App() {
  return (
    <>
      <Box>Default div</Box>
      <Box as="section" className="section">Section element</Box>
      <Box as="a" href="/about">Link element</Box>
      <Box as="button" type="button" onClick={() => console.log('clicked')}>
        Button
      </Box>
    </>
  );
}
```

If an older TypeScript version reports an error on `<Component {...props} />`, widen the local variable with `const Component: ElementType = as ?? 'div';`. Callers keep full prop checking through `BoxProps<C>`. To accept `ref`, use `ComponentPropsWithRef<C>` instead.

## Event Handlers

### Common Event Types

```tsx
import {
  ChangeEvent,
  FormEvent,
  MouseEvent,
  KeyboardEvent,
  FocusEvent,
  DragEvent,
} from 'react';

function EventExamples() {
  // Input change
  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    console.log(e.target.value);
  };

  // Select change
  const handleSelectChange = (e: ChangeEvent<HTMLSelectElement>) => {
    console.log(e.target.value);
  };

  // Form submit
  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    console.log(Object.fromEntries(formData));
  };

  // Button click
  const handleClick = (e: MouseEvent<HTMLButtonElement>) => {
    console.log(e.clientX, e.clientY);
  };

  // Keyboard
  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      console.log('Enter pressed');
    }
  };

  // Focus
  const handleFocus = (e: FocusEvent<HTMLInputElement>) => {
    console.log('Focused:', e.target.name);
  };

  // Drag
  const handleDragStart = (e: DragEvent<HTMLDivElement>) => {
    e.dataTransfer.setData('text/plain', 'dragging');
  };

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="example-name">Name</label>
      <input
        id="example-name"
        name="name"
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onFocus={handleFocus}
      />
      <label htmlFor="example-option">Option</label>
      <select id="example-option" name="option" onChange={handleSelectChange}>
        <option value="1">Option 1</option>
      </select>
      <div draggable onDragStart={handleDragStart}>Drag me</div>
      <button type="submit" onClick={handleClick}>Submit</button>
    </form>
  );
}
```

### Event Handler Props

```tsx
import { useId, type ChangeEvent } from 'react';

interface FormFieldProps {
  label: string;
  onChange: (value: string) => void;
  onBlur?: () => void;
}

function FormField({ label, onChange, onBlur }: FormFieldProps) {
  const id = useId();
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };

  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input id={id} onChange={handleChange} onBlur={onBlur} />
    </>
  );
}

// Generic event handler
interface ListItemProps<T> {
  item: T;
  onSelect: (item: T) => void;
  onDelete?: (item: T) => void;
}

function ListItem<T extends { id: string; name: string }>({
  item,
  onSelect,
  onDelete,
}: ListItemProps<T>) {
  return (
    <li>
      <button type="button" onClick={() => onSelect(item)}>{item.name}</button>
      {onDelete && (
        <button type="button" onClick={() => onDelete(item)}>
          Delete
        </button>
      )}
    </li>
  );
}
```

## Hooks with TypeScript

### useState

```tsx
import { useState } from 'react';

// Inferred type
const [count, setCount] = useState(0);  // number

// Explicit type
const [user, setUser] = useState<User | null>(null);

// Union types
type Status = 'idle' | 'loading' | 'success' | 'error';
const [status, setStatus] = useState<Status>('idle');

// Complex state
interface FormState {
  name: string;
  email: string;
  errors: Record<string, string>;
}

const [form, setForm] = useState<FormState>({
  name: '',
  email: '',
  errors: {},
});

// Update partial state
setForm(prev => ({ ...prev, name: 'John' }));
```

### useReducer

```tsx
import { useReducer, Reducer } from 'react';

// State and action types
interface CounterState {
  count: number;
  step: number;
}

type CounterAction =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset' }
  | { type: 'setStep'; payload: number };

// Reducer function
const counterReducer: Reducer<CounterState, CounterAction> = (state, action) => {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + state.step };
    case 'decrement':
      return { ...state, count: state.count - state.step };
    case 'reset':
      return { ...state, count: 0 };
    case 'setStep':
      return { ...state, step: action.payload };
    default:
      return state;
  }
};

function Counter() {
  const [state, dispatch] = useReducer(counterReducer, { count: 0, step: 1 });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <button onClick={() => dispatch({ type: 'setStep', payload: 5 })}>Set Step to 5</button>
    </div>
  );
}
```

### useRef

```tsx
import { useRef, useEffect } from 'react';

function RefExamples() {
  // DOM element ref
  const inputRef = useRef<HTMLInputElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Mutable value ref
  const countRef = useRef<number>(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    // Focus input on mount
    inputRef.current?.focus();

    // Access canvas context
    const ctx = canvasRef.current?.getContext('2d');
    if (ctx) {
      ctx.fillRect(0, 0, 100, 100);
    }

    // Start timer
    timerRef.current = setInterval(() => {
      countRef.current += 1;
    }, 1000);

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  return (
    <div>
      <input ref={inputRef} />
      <canvas ref={canvasRef} />
    </div>
  );
}
```

### useContext

```tsx
import { createContext, useContext, useState, ReactNode } from 'react';

// Theme context
interface Theme {
  primary: string;
  secondary: string;
  mode: 'light' | 'dark';
}

interface ThemeContextType {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  toggleMode: () => void;
}

const ThemeContext = createContext<ThemeContextType | null>(null);

// Provider
function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>({
    primary: '#007bff',
    secondary: '#6c757d',
    mode: 'light',
  });

  const toggleMode = () => {
    setTheme((prev) => ({
      ...prev,
      mode: prev.mode === 'light' ? 'dark' : 'light',
    }));
  };

  return (
    <ThemeContext.Provider value={{ theme, setTheme, toggleMode }}>
      {children}
    </ThemeContext.Provider>
  );
}

// Hook with type safety
function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

// Usage
function ThemedButton() {
  const { theme, toggleMode } = useTheme();

  return (
    <button
      style={{ backgroundColor: theme.primary }}
      onClick={toggleMode}
    >
      Toggle {theme.mode === 'light' ? 'Dark' : 'Light'} Mode
    </button>
  );
}
```

### Custom Hooks

Type a generic data hook by putting the type parameter on the function and threading it through the result type. The caller supplies the type; the hook never casts beyond `response.json() as Promise<T>`. For production data fetching prefer TanStack Query or SWR, which handle caching, deduplication, and races out of the box.

```tsx
// Type shape only: the implementation (AbortController, res.ok check,
// state reset on URL change) is the canonical useFetch in
// hooks-custom-library.md. Copy it from there.
interface UseFetchResult<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

declare function useFetch<T>(
  url: string | null, // null skips fetching
  options?: { onSuccess?: (data: T) => void; onError?: (error: Error) => void }
): UseFetchResult<T>;

// Usage: T is inferred everywhere from the explicit type argument
interface User {
  id: number;
  name: string;
  email: string;
}

function UserProfile({ userId }: { userId: number }) {
  const { data: user, loading, error } = useFetch<User>(`/api/users/${userId}`);

  if (loading) return <div>Loading...</div>;
  if (error) return <div role="alert">Error: {error.message}</div>;
  if (!user) return <div>No user found</div>;

  return (
    <div>
      <h1>{user.name}</h1> {/* user: User */}
      <p>{user.email}</p>
    </div>
  );
}
```

## Generic Components, Type Utilities & Type-Safe Context

Full code for generic components (`List<T>`, `Select<T>`, `Table<T>`), utility types (`Partial`, `Pick`, `Omit`, `Record`, `Extract`, `Exclude`, `ComponentProps`, `ComponentPropsWithRef`, `ComponentPropsWithoutRef`), discriminated unions for API states, inference / conditional types (`infer`, `Awaited`, `PropsOf`), and the type-safe Context factory pattern (`createSafeContext`) lives in `typescript-generics-utilities-context.md`. Load that reference when building reusable typed components, working with React's prop-type utilities, or wiring a strongly-typed Context provider.

## Typed Errors and Results

Return expected failures as values and throw only for unexpected ones. Components and Server Actions can then branch on a typed result instead of guessing what a `catch` received.

```ts
// lib/result.ts
export type Result<T, E = AppError> =
  | { ok: true; data: T }
  | { ok: false; error: E };

export const ok = <T,>(data: T): Result<T, never> => ({ ok: true, data });
export const fail = <E,>(error: E): Result<never, E> => ({ ok: false, error });

// lib/errors.ts
export class AppError extends Error {
  constructor(
    message: string,
    readonly code: 'NOT_FOUND' | 'FORBIDDEN' | 'CONFLICT' | 'VALIDATION',
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = new.target.name;
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} ${id} was not found`, 'NOT_FOUND');
  }
}
```

```ts
async function getOrder(id: string, userId: string): Promise<Result<Order>> {
  try {
    const order = await db.orders.findFirst({ where: { id, ownerId: userId } });
    return order ? ok(order) : fail(new NotFoundError('Order', id));
  } catch (err: unknown) {
    // Keep the original error as the cause; never swallow it
    throw new Error('Failed to load order', { cause: err });
  }
}

const result = await getOrder(id, session.user.id);
if (!result.ok) {
  if (result.error.code === 'NOT_FOUND') notFound(); // Next.js; render a fallback elsewhere
  throw result.error;
}
result.data; // Order
```

- Type `catch` variables as `unknown` and narrow with `instanceof` before reading properties.
- Never leave a `catch` block empty. Log with context, rethrow, or convert to a typed result.
- Send the client a stable `code` and a safe message, never `err.message` from a database or third-party error.
- Error boundaries still catch thrown errors during render. Use results for flows expected to fail (not found, conflict, validation) and let real bugs throw.

## Best Practices

| Practice | Example |
|----------|---------|
| Use interface for component props | `interface ButtonProps { ... }` |
| Prefer type inference when obvious | `useState(0)` vs `useState<number>(0)` |
| Use generics for reusable components | `List<T>`, `Select<T>` |
| Discriminated unions for state | `{ status: 'success'; data: T }` |
| Accept `ref` as a regular prop (React 19) | `ComponentProps<'button'>` includes `ref` |
| Avoid `any`, use `unknown` if needed | `catch (err: unknown)` |
| Use `as const` for literal types | `['a', 'b'] as const` |
