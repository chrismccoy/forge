# React + TypeScript: Generics, Utilities, Context

Full code for generic component patterns, type utilities (`PropsWithChildren`, `ComponentProps`, etc.), and type-safe React Context. `typescript.md` keeps props / event handlers / hooks; this reference has the advanced material.

## Contents

- [Generic Components](#generic-components)
- [Type Utilities](#type-utilities)
- [Type-Safe Context](#type-safe-context)

## Generic Components

### Generic List

```tsx
import type { ReactNode } from 'react';

interface ListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => ReactNode;
  keyExtractor: (item: T) => string | number;
  emptyMessage?: string;
}

function List<T>({
  items,
  renderItem,
  keyExtractor,
  emptyMessage = 'No items',
}: ListProps<T>) {
  if (items.length === 0) {
    return <p>{emptyMessage}</p>;
  }

  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>{renderItem(item, index)}</li>
      ))}
    </ul>
  );
}

// Usage
interface Product {
  id: string;
  name: string;
  price: number;
}

function ProductList({ products }: { products: Product[] }) {
  return (
    <List
      items={products}
      keyExtractor={(product) => product.id}
      renderItem={(product) => (
        <div>
          <span>{product.name}</span>
          <span>${product.price}</span>
        </div>
      )}
    />
  );
}
```

### Generic Select

```tsx
import { useId, useState } from 'react';

interface SelectOption<T> {
  value: T;
  label: string;
}

interface SelectProps<T> {
  label: string;
  options: SelectOption<T>[];
  value: T | null;
  onChange: (value: T) => void;
  placeholder?: string;
  getOptionValue?: (option: SelectOption<T>) => string;
}

function Select<T>({
  label,
  options,
  value,
  onChange,
  placeholder = 'Select...',
  getOptionValue = (opt) => String(opt.value),
}: SelectProps<T>) {
  const id = useId();
  const selectedOption = options.find((opt) => opt.value === value);

  return (
    <>
      <label htmlFor={id}>{label}</label>
      <select
        id={id}
        value={selectedOption ? getOptionValue(selectedOption) : ''}
        onChange={(e) => {
          const option = options.find(
            (opt) => getOptionValue(opt) === e.target.value
          );
          if (option) {
            onChange(option.value);
          }
        }}
      >
        <option value="" disabled>
          {placeholder}
        </option>
        {options.map((option) => (
          <option key={getOptionValue(option)} value={getOptionValue(option)}>
            {option.label}
          </option>
        ))}
      </select>
    </>
  );
}

// Usage
type Status = 'draft' | 'published' | 'archived';

function StatusSelect() {
  const [status, setStatus] = useState<Status | null>(null);

  const options: SelectOption<Status>[] = [
    { value: 'draft', label: 'Draft' },
    { value: 'published', label: 'Published' },
    { value: 'archived', label: 'Archived' },
  ];

  return <Select label="Status" options={options} value={status} onChange={setStatus} />;
}
```

### Generic Table

`T extends object` (not `Record<string, unknown>`) so that plain interfaces such as `interface User` are accepted: interfaces have no implicit index signature and fail a `Record<string, unknown>` constraint.

```tsx
import type { ReactNode } from 'react';

interface Column<T> {
  key: keyof T & string;
  header: string;
  render?: (item: T) => ReactNode;
  width?: string | number;
}

interface TableProps<T> {
  data: T[];
  columns: Column<T>[];
  keyExtractor: (item: T) => string | number;
  onRowClick?: (item: T) => void;
}

function Table<T extends object>({
  data,
  columns,
  keyExtractor,
  onRowClick,
}: TableProps<T>) {
  const getCellValue = (item: T, column: Column<T>): ReactNode => {
    if (column.render) {
      return column.render(item);
    }
    const value = item[column.key];
    // Objects (e.g. Date) are not valid React children; give them a render function
    return value == null ? '' : String(value);
  };

  return (
    <table>
      <thead>
        <tr>
          {columns.map((column) => (
            <th key={String(column.key)} style={{ width: column.width }}>
              {column.header}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((item) => (
          <tr
            key={keyExtractor(item)}
            onClick={() => onRowClick?.(item)}
            style={{ cursor: onRowClick ? 'pointer' : 'default' }}
          >
            {columns.map((column) => (
              <td key={String(column.key)}>{getCellValue(item, column)}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// Usage
interface User {
  id: string;
  name: string;
  email: string;
  status: 'active' | 'inactive';
  createdAt: Date;
}

function UsersTable({ users }: { users: User[] }) {
  const columns: Column<User>[] = [
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    {
      key: 'status',
      header: 'Status',
      render: (user) => (
        <span className={`badge badge-${user.status}`}>{user.status}</span>
      ),
    },
    {
      key: 'createdAt',
      header: 'Created',
      render: (user) => user.createdAt.toLocaleDateString(),
    },
  ];

  return (
    <Table
      data={users}
      columns={columns}
      keyExtractor={(user) => user.id}
      onRowClick={(user) => console.log('Clicked:', user)}
    />
  );
}
```

## Type Utilities

### Common Utility Types

```tsx
// Partial - all properties optional
interface User {
  id: string;
  name: string;
  email: string;
}

type PartialUser = Partial<User>;
// { id?: string; name?: string; email?: string }

// Required - all properties required
interface Config {
  host?: string;
  port?: number;
}

type RequiredConfig = Required<Config>;
// { host: string; port: number }

// Pick - select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;
// { id: string; name: string }

// Omit - exclude specific properties
type CreateUserInput = Omit<User, 'id'>;
// { name: string; email: string }

// Record - object with specific key/value types
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;
// { [key: string]: 'admin' | 'user' | 'guest' }

// Extract - extract types from union
type Status = 'idle' | 'loading' | 'success' | 'error';
type LoadingStates = Extract<Status, 'loading' | 'idle'>;
// 'loading' | 'idle'

// Exclude - exclude types from union
type ErrorStates = Exclude<Status, 'success'>;
// 'idle' | 'loading' | 'error'
```

### Component Props Utilities

```tsx
import { ComponentProps, ComponentPropsWithRef, ComponentPropsWithoutRef } from 'react';

// Get props of a component
type ButtonProps = ComponentProps<'button'>;
type DivProps = ComponentProps<'div'>;

// Get props of a custom component
function MyButton({
  variant,
  className,
  ...props
}: ComponentProps<'button'> & { variant: 'primary' | 'secondary' }) {
  // Destructure custom props so they are not spread onto the DOM element
  return <button className={`btn btn-${variant} ${className ?? ''}`} {...props} />;
}
type MyButtonProps = ComponentProps<typeof MyButton>;

// Props with ref
type InputPropsWithRef = ComponentPropsWithRef<'input'>;

// Props without ref
type InputPropsNoRef = ComponentPropsWithoutRef<'input'>;
```

### Discriminated Unions

```tsx
// API response states
type ApiResponse<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function useApiData<T>(url: string): ApiResponse<T> {
  // Implementation...
  return { status: 'idle' };
}

// Usage with type narrowing
function DataDisplay() {
  const response = useApiData<User[]>('/api/users');

  switch (response.status) {
    case 'idle':
      return <p>Ready to fetch</p>;
    case 'loading':
      return <p>Loading...</p>;
    case 'success':
      // TypeScript knows response.data exists here
      return <UserList users={response.data} />;
    case 'error':
      // TypeScript knows response.error exists here
      return <p>Error: {response.error.message}</p>;
  }
}
```

### Exhaustive Checks

Make the compiler fail when a new variant is added but not handled. Assign the narrowed value to `never` in the `default` branch.

```tsx
function assertNever(value: never): never {
  throw new Error(`Unhandled variant: ${JSON.stringify(value)}`);
}

type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'rect'; width: number; height: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'rect':
      return shape.width * shape.height;
    default:
      return assertNever(shape); // adding { kind: 'triangle' } makes this a compile error
  }
}
```

Use `satisfies` to check a lookup object against a type without widening its keys or values:

```tsx
const statusLabel = {
  idle: 'Ready',
  loading: 'Loading…',
  success: 'Done',
  error: 'Failed',
} satisfies Record<ApiResponse<unknown>['status'], string>; // a missing or extra key is an error
```

### Inference and Conditional Types

```tsx
// Infer return type (illustration; use the built-in ReturnType<T> in real code)
type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never;

function fetchUser(id: string) {
  return { id, name: 'John', email: 'john@example.com' };
}

type FetchUserReturn = ReturnTypeOf<typeof fetchUser>;
// { id: string; name: string; email: string }

// Extract a promise value with infer (illustration only)
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

// In real code use the built-in Awaited<T>, which also unwraps nested promises and thenables
async function getUsers() {
  return [{ id: '1', name: 'John' }];
}

type UsersData = Awaited<ReturnType<typeof getUsers>>;
// { id: string; name: string }[]

// Props inference from component
type PropsOf<T> = T extends React.ComponentType<infer P> ? P : never;
```

## Type-Safe Context

```tsx
import { createContext, useContext, useState, type ReactNode } from 'react';

// Create type-safe context factory
function createSafeContext<T>(displayName: string) {
  const Context = createContext<T | undefined>(undefined);
  Context.displayName = displayName;

  function useContextSafe() {
    const context = useContext(Context);
    if (context === undefined) {
      throw new Error(`use${displayName} must be used within ${displayName}Provider`);
    }
    return context;
  }

  return [Context.Provider, useContextSafe] as const;
}

// Usage
interface AuthContextValue {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const [AuthProvider, useAuth] = createSafeContext<AuthContextValue>('Auth');

// Provider component
function AuthContextProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (email: string, password: string) => {
    // The server sets an httpOnly session cookie; the client keeps only the profile
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) throw new Error('Login failed');
    setUser((await res.json()) as User);
  };

  const logout = async () => {
    // Only the server can clear the httpOnly session cookie
    const res = await fetch('/api/logout', { method: 'POST' });
    if (!res.ok) throw new Error('Logout failed');
    setUser(null);
  };

  return (
    <AuthProvider value={{ user, login, logout }}>
      {children}
    </AuthProvider>
  );
}

// Consumer component - fully type-safe
function Profile() {
  const { user, logout } = useAuth();
  const [logoutError, setLogoutError] = useState<string | null>(null);
  // TypeScript knows user can be null
  if (!user) return <p>Please log in</p>;

  const handleLogout = async () => {
    setLogoutError(null);
    try {
      await logout();
    } catch {
      setLogoutError('Could not log out. Please try again.');
    }
  };

  return (
    <div>
      <p>Welcome, {user.name}</p>
      <button type="button" onClick={handleLogout}>Logout</button>
      {logoutError && <p role="alert">{logoutError}</p>}
    </div>
  );
}
```
