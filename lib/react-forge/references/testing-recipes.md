# React Testing Recipes

Complete, copy-paste test files for common React scenarios. Setup, query priority, async and mocking principles, gotchas, and Server Component testing are in [testing.md](testing.md); media components are in [testing-media.md](testing-media.md).

## Contents

- [Test Setup](#test-setup)
- [Component Testing Patterns](#component-testing-patterns)
- [Async Testing Patterns](#async-testing-patterns)
- [Testing Custom Hooks](#testing-custom-hooks)
- [Mocking Patterns](#mocking-patterns)
- [Integration Testing](#integration-testing)
- [Accessibility Testing](#accessibility-testing)

## Test Setup

The Vitest and Jest configuration and the shared `src/test/setup.ts` (jest-dom, cleanup, mock reset and restore, and `matchMedia`/`IntersectionObserver`/`ResizeObserver` mocks) are in [testing.md](testing.md#testing-tools). The recipes below assume that setup, in particular `vi.restoreAllMocks()` after each test, which restores any `vi.spyOn(globalThis, 'fetch')` spy.

### Custom Render with Providers

Components that read context, routes, server-state caches, or themes need those providers in every test. Put them in one shared `render` that re-exports Testing Library, so test files import from `@/test/utils` instead of `@testing-library/react`:

- Create a fresh `QueryClient` (or store) per rendered tree, held in `useState` so it stays stable across re-renders; a shared client leaks cache state between tests.
- Turn off retries (`retry: false`) so error-state tests fail fast instead of retrying until they time out.
- Accept options such as `initialEntries` for the in-memory router.
- Add app-specific providers (for example, a `ThemeProvider`) inside `AllProviders`.

```tsx
// src/test/utils.tsx
import { useState, type ReactElement, type ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
// React Router v6: import from 'react-router-dom'
import { MemoryRouter } from 'react-router';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  });
}

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  // Starting URL(s) for the in-memory router
  initialEntries?: string[];
}

function customRender(
  ui: ReactElement,
  { initialEntries = ['/'], ...options }: CustomRenderOptions = {}
) {
  function AllProviders({ children }: { children: ReactNode }) {
    // One client per rendered test tree; useState keeps it stable across re-renders
    const [queryClient] = useState(createTestQueryClient);

    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={initialEntries}>
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    );
  }

  return render(ui, { wrapper: AllProviders, ...options });
}

// Re-export everything
export * from '@testing-library/react';
export { customRender as render };
```

## Component Testing Patterns

### Basic Component Test

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const defaultProps = {
    name: 'John Doe',
    email: 'john@example.com',
    role: 'Developer',
  };

  it('renders user information', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
    expect(screen.getByText('Developer')).toBeInTheDocument();
  });

  it('renders avatar when provided', () => {
    render(<UserCard {...defaultProps} avatar="/avatar.jpg" />);

    const avatar = screen.getByRole('img', { name: /john doe/i });
    expect(avatar).toHaveAttribute('src', '/avatar.jpg');
  });

  it('shows placeholder when no avatar', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByTestId('avatar-placeholder')).toBeInTheDocument();
  });
});
```

### Testing Props and Disabled State

```tsx
// Button.tsx
interface ButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  disabled?: boolean;
}

export function Button({ onClick, children, disabled = false }: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled}>
      {children}
    </button>
  );
}
```

```tsx
// Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button onClick={() => {}}>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick}>Click me</Button>);
    await user.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button onClick={() => {}} disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('does not call onClick when disabled', async () => {
    const handleClick = vi.fn();
    const user = userEvent.setup();

    render(<Button onClick={handleClick} disabled>Click me</Button>);
    await user.click(screen.getByRole('button'));

    expect(handleClick).not.toHaveBeenCalled();
  });
});
```

### Testing User Interactions

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { Counter } from './Counter';

describe('Counter', () => {
  it('increments count when plus button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter initialCount={0} />);

    expect(screen.getByText('Count: 0')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('decrements count when minus button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter initialCount={5} />);

    await user.click(screen.getByRole('button', { name: /decrement/i }));

    expect(screen.getByText('Count: 4')).toBeInTheDocument();
  });

  it('calls onChange when count changes', async () => {
    const user = userEvent.setup();
    const handleChange = vi.fn();
    render(<Counter initialCount={0} onChange={handleChange} />);

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(handleChange).toHaveBeenCalledWith(1);
  });
});
```

### Testing Forms

```tsx
import { render, screen, waitFor } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { ContactForm } from './ContactForm';

describe('ContactForm', () => {
  it('submits form with entered data', async () => {
    const user = userEvent.setup();
    const handleSubmit = vi.fn();
    render(<ContactForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.type(screen.getByLabelText(/message/i), 'Hello world');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(handleSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
      message: 'Hello world',
    });
  });

  it('shows validation errors for empty fields', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByText(/name is required/i)).toBeInTheDocument();
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  });

  it('shows error for invalid email', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.type(screen.getByLabelText(/email/i), 'invalid-email');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
  });

  it('disables submit button while submitting', async () => {
    const user = userEvent.setup();
    const handleSubmit = vi.fn(() => new Promise((r) => setTimeout(r, 100)));
    render(<ContactForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByRole('button', { name: /submitting/i })).toBeDisabled();

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /submit/i })).toBeEnabled();
    });
  });
});
```

### Testing Async Form Submission and Errors

A controlled form whose `onSubmit` returns a promise. The third test holds the promise open with a captured `resolve` to assert the in-flight (disabled) state deterministically, without a timer:

```tsx
// LoginForm.tsx
interface LoginFormProps {
  onSubmit: (data: { email: string; password: string }) => Promise<void>;
}

export function LoginForm({ onSubmit }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      await onSubmit({ email, password });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </div>
      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
      </div>
      {error && <p role="alert">{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}
```

```tsx
// LoginForm.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  it('submits form with email and password', async () => {
    const handleSubmit = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();

    render(<LoginForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');
    await user.click(screen.getByRole('button', { name: /login/i }));

    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
    });
  });

  it('displays error message on failed submission', async () => {
    const handleSubmit = vi.fn().mockRejectedValue(new Error('Invalid credentials'));
    const user = userEvent.setup();

    render(<LoginForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'wrong');
    await user.click(screen.getByRole('button', { name: /login/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Invalid credentials');
    });
  });

  it('disables submit button while submitting', async () => {
    let resolveSubmit: () => void;
    const handleSubmit = vi.fn().mockImplementation(
      () => new Promise((resolve) => { resolveSubmit = resolve; })
    );
    const user = userEvent.setup();

    render(<LoginForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password');
    await user.click(screen.getByRole('button', { name: /login/i }));

    expect(screen.getByRole('button')).toBeDisabled();
    expect(screen.getByRole('button')).toHaveTextContent('Logging in...');

    resolveSubmit!();

    await waitFor(() => {
      expect(screen.getByRole('button')).not.toBeDisabled();
    });
  });
});
```

### Testing with Select and Radio

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { FilterForm } from './FilterForm';

describe('FilterForm', () => {
  it('selects option from dropdown', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    await user.selectOptions(screen.getByLabelText(/category/i), 'electronics');

    expect(screen.getByRole('option', { name: /electronics/i })).toBeSelected();
  });

  it('selects radio option', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    await user.click(screen.getByLabelText(/high to low/i));

    expect(screen.getByLabelText(/high to low/i)).toBeChecked();
  });

  it('toggles checkbox', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    const checkbox = screen.getByLabelText(/in stock only/i);

    expect(checkbox).not.toBeChecked();

    await user.click(checkbox);
    expect(checkbox).toBeChecked();

    await user.click(checkbox);
    expect(checkbox).not.toBeChecked();
  });
});
```

### Testing Components with Context

Wrap the component in its real provider so the test exercises the same context value the app uses. For many providers, use the shared custom `render` above instead of a per-file helper.

```tsx
// ThemeContext.tsx
import { createContext, useContext, useState, type ReactNode } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
}

export const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');
  const toggleTheme = () => setTheme((t) => (t === 'light' ? 'dark' : 'light'));

  return (
    // React 19: render the context directly (React 18: <ThemeContext.Provider>)
    <ThemeContext value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used within ThemeProvider');
  return context;
}
```

```tsx
// ThemedButton.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { ThemeProvider } from './ThemeContext';
import { ThemedButton } from './ThemedButton';

// Custom render function with providers
function renderWithTheme(ui: React.ReactElement) {
  return render(<ThemeProvider>{ui}</ThemeProvider>);
}

describe('ThemedButton', () => {
  it('uses light theme by default', () => {
    renderWithTheme(<ThemedButton>Click me</ThemedButton>);
    expect(screen.getByRole('button')).toHaveClass('light');
  });

  it('toggles theme on click', async () => {
    const user = userEvent.setup();
    renderWithTheme(<ThemedButton>Toggle</ThemedButton>);

    const button = screen.getByRole('button');
    expect(button).toHaveClass('light');

    await user.click(button);
    expect(button).toHaveClass('dark');

    await user.click(button);
    expect(button).toHaveClass('light');
  });
});
```

## Async Testing Patterns

### Testing Loading States

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect, vi } from 'vitest';
import { UserList } from './UserList';

// Each test spies on fetch; vi.restoreAllMocks() in the setup file restores it.
describe('UserList', () => {
  it('shows loading state initially', () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(() => new Promise(() => {})); // Never resolves
    render(<UserList />);

    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('displays users after loading', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce({
      ok: true,
      json: async () => [
        { id: '1', name: 'John' },
        { id: '2', name: 'Jane' },
      ],
    } as Response);

    render(<UserList />);

    expect(await screen.findByText('John')).toBeInTheDocument();
    expect(screen.getByText('Jane')).toBeInTheDocument();
  });

  it('shows error message on failure', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValueOnce(new Error('Network error'));

    render(<UserList />);

    expect(await screen.findByText(/error loading users/i)).toBeInTheDocument();
  });
});
```

### Testing with waitFor

```tsx
import { render, screen, waitFor, waitForElementToBeRemoved } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { AsyncSearch } from './AsyncSearch';

describe('AsyncSearch', () => {
  it('shows results after typing', async () => {
    const user = userEvent.setup();
    render(<AsyncSearch />);

    await user.type(screen.getByRole('searchbox'), 'react');

    // Wait for loading to appear and disappear
    await waitFor(() => {
      expect(screen.getByText(/searching/i)).toBeInTheDocument();
    });

    await waitForElementToBeRemoved(() => screen.queryByText(/searching/i));

    expect(screen.getByText(/results for "react"/i)).toBeInTheDocument();
  });

  it('debounces search input', async () => {
    const user = userEvent.setup();
    const searchFn = vi.fn();
    render(<AsyncSearch onSearch={searchFn} />);

    // Type quickly
    await user.type(screen.getByRole('searchbox'), 'react');

    // Should only call once after debounce
    await waitFor(() => {
      expect(searchFn).toHaveBeenCalledTimes(1);
      expect(searchFn).toHaveBeenCalledWith('react');
    });
  });
});
```

### Testing with findBy Queries

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { Dashboard } from './Dashboard';

describe('Dashboard', () => {
  it('loads and displays data', async () => {
    render(<Dashboard />);

    // findBy* waits for element (combines waitFor + getBy)
    const greeting = await screen.findByText(/welcome, john/i);
    expect(greeting).toBeInTheDocument();

    // Multiple findBy calls
    const stats = await screen.findByTestId('stats-card');
    expect(stats).toBeInTheDocument();
  });

  it('handles findBy timeout', async () => {
    render(<Dashboard />);

    // Increase timeout for slow operations
    const element = await screen.findByText(/complex data/i, {}, { timeout: 5000 });
    expect(element).toBeInTheDocument();
  });
});
```

### Mocking an API Module for Async Components

Mock the data module with `vi.mock`, use a never-resolving promise to hold the loading state, and wait for the resolved or rejected UI:

```tsx
// UserProfile.tsx
export function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    // Reset when userId changes so stale data is not shown
    setLoading(true);
    setError(null);
    setUser(null);

    fetchUser(userId, { signal: controller.signal })
      .then((data) => {
        if (!controller.signal.aborted) setUser(data);
      })
      .catch((err) => {
        // Ignore aborts from unmount or a newer userId
        if (err.name === 'AbortError' || controller.signal.aborted) return;
        setError(err);
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!user) return <div>User not found</div>;

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

```tsx
// UserProfile.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UserProfile } from './UserProfile';
import * as api from './api';

vi.mock('./api');

describe('UserProfile', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('shows loading state initially', () => {
    vi.mocked(api.fetchUser).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    );

    render(<UserProfile userId="123" />);
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('displays user data when loaded', async () => {
    vi.mocked(api.fetchUser).mockResolvedValue({
      id: '123',
      name: 'John Doe',
      email: 'john@example.com',
    });

    render(<UserProfile userId="123" />);

    await waitFor(() => {
      expect(screen.getByRole('heading')).toHaveTextContent('John Doe');
    });
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
  });

  it('displays error when fetch fails', async () => {
    vi.mocked(api.fetchUser).mockRejectedValue(new Error('Network error'));

    render(<UserProfile userId="123" />);

    await waitFor(() => {
      expect(screen.getByText(/error: network error/i)).toBeInTheDocument();
    });
  });
});
```

## Testing Custom Hooks

### Basic Hook Testing

```tsx
// useCounter.ts
import { useState } from 'react';

export function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue);

  const increment = () => setCount((c) => c + 1);
  const decrement = () => setCount((c) => c - 1);
  const reset = () => setCount(initialValue);

  return { count, increment, decrement, reset };
}
```

```tsx
// useCounter.test.ts
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('defaults to 0', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);
  });

  it('returns initial count', () => {
    const { result } = renderHook(() => useCounter(5));

    expect(result.current.count).toBe(5);
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounter(0));

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('decrements count', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.decrement();
    });

    expect(result.current.count).toBe(4);
  });

  it('resets count', () => {
    const { result } = renderHook(() => useCounter(10));

    act(() => {
      result.current.increment();
      result.current.increment();
      result.current.reset();
    });

    expect(result.current.count).toBe(10);
  });
});
```

### Testing Async Hooks

The tests assume a `useFetch(url)` hook that returns `{ data, loading, error }`, sets `error` when the request rejects or the response is not ok, and refetches when `url` changes.

```tsx
// useFetch.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useFetch } from './useFetch';

function jsonResponse(body: unknown): Response {
  return { ok: true, status: 200, json: async () => body } as Response;
}

// vi.restoreAllMocks() in the setup file restores fetch after each test
describe('useFetch', () => {
  it('fetches data successfully', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(jsonResponse({ name: 'John' }));

    const { result } = renderHook(() => useFetch('/api/user'));

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toEqual({ name: 'John' });
    expect(result.current.error).toBeNull();
  });

  it('handles a network error', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValueOnce(new Error('Network error'));

    const { result } = renderHook(() => useFetch('/api/user'));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toBeNull();
    expect(result.current.error?.message).toBe('Network error');
  });

  it('handles a non-ok response', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce({ ok: false, status: 404 } as Response);

    const { result } = renderHook(() => useFetch('/api/user'));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toBeNull();
    expect(result.current.error).toBeInstanceOf(Error);
  });

  it('refetches when url changes', async () => {
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(jsonResponse({ id: 1 }))
      .mockResolvedValueOnce(jsonResponse({ id: 2 }));

    const { result, rerender } = renderHook(({ url }) => useFetch(url), {
      initialProps: { url: '/api/users/1' },
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({ id: 1 });
    });

    rerender({ url: '/api/users/2' });

    await waitFor(() => {
      expect(result.current.data).toEqual({ id: 2 });
    });

    expect(fetchSpy).toHaveBeenCalledTimes(2);
  });
});
```

### Testing Hooks with Context

```tsx
import type { ReactNode } from 'react';
import { renderHook } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useAuth } from './useAuth';
import { AuthProvider } from './AuthContext';

function wrapper({ children }: { children: ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

describe('useAuth', () => {
  it('provides the signed-out state from context', () => {
    // AuthProvider (hooks.md -> useContext) starts with no user
    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.user).toBeNull();
    expect(result.current.isAuthenticated).toBe(false);
  });

  it('throws when used outside provider', () => {
    // Suppress console.error for this test
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => {
      renderHook(() => useAuth());
    }).toThrow('useAuth must be used within an AuthProvider');

    consoleSpy.mockRestore();
  });
});
```

## Mocking Patterns

### Mocking Modules

```tsx
import { vi, describe, it, expect } from 'vitest';

// Mock entire module
vi.mock('@/lib/api', () => ({
  fetchUsers: vi.fn(),
  createUser: vi.fn(),
}));

// Import after mocking
import { fetchUsers, createUser } from '@/lib/api';

describe('UserService', () => {
  it('calls fetchUsers', async () => {
    (fetchUsers as any).mockResolvedValueOnce([{ id: 1, name: 'John' }]);

    const users = await fetchUsers();
    expect(users).toHaveLength(1);
  });
});
```

To replace only some exports, spread the original module:

```tsx
// Or mock specific exports
vi.mock('./api', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./api')>();
  return {
    ...actual,
    fetchUser: vi.fn(),
  };
});
```

### Mocking Child Components

Replace a heavy child (charts, maps, editors) with a lightweight stand-in when the test targets the parent:

```tsx
import { vi } from 'vitest';

// Mock a child component
vi.mock('./ExpensiveChart', () => ({
  ExpensiveChart: ({ data }: { data: number[] }) => (
    <div data-testid="mock-chart">Chart with {data.length} points</div>
  ),
}));
```

### Routing: Render in a MemoryRouter

Render routed components inside `MemoryRouter` with `initialEntries` instead of mocking the router, so `useParams`, `useNavigate`, and links behave as they do in the app:

```tsx
import { render, screen } from '@testing-library/react';
// React Router v6: import from 'react-router-dom'
import { MemoryRouter, Route, Routes } from 'react-router';
import { it, expect } from 'vitest';
import { UserPage } from './UserPage';

it('loads the user from the URL', async () => {
  render(
    <MemoryRouter initialEntries={['/users/123']}>
      <Routes>
        <Route path="/users/:id" element={<UserPage />} />
      </Routes>
    </MemoryRouter>
  );

  expect(await screen.findByRole('heading', { name: /user 123/i })).toBeInTheDocument();
});
```

For components that only need some router context, the custom `render` from `@/test/utils` accepts `initialEntries`. Mock the router module only when it is a framework router whose hooks cannot run outside the framework (for example, Next.js `next/navigation`).

### Mocking External Libraries

```tsx
import { vi } from 'vitest';

// Mock date-fns
vi.mock('date-fns', () => ({
  format: vi.fn((date) => '2024-01-01'),
  parseISO: vi.fn((str) => new Date(str)),
}));
```

### Mocking Timers

```tsx
import { render, screen, act } from '@/test/utils';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { CountdownTimer } from './CountdownTimer';

describe('CountdownTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('counts down every second', () => {
    render(<CountdownTimer seconds={5} />);

    expect(screen.getByText('5')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(1000);
    });
    expect(screen.getByText('4')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(2000);
    });
    expect(screen.getByText('2')).toBeInTheDocument();
  });

  it('calls onComplete when finished', () => {
    const handleComplete = vi.fn();
    render(<CountdownTimer seconds={3} onComplete={handleComplete} />);

    act(() => {
      vi.advanceTimersByTime(3000);
    });

    expect(handleComplete).toHaveBeenCalled();
  });
});
```

When `userEvent` types into a component that debounces with fake timers, pass `advanceTimers` to `userEvent.setup()` so its internal delays advance with the fake clock, and use the async timer API inside `act`:

```tsx
import { act, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import { DebouncedInput } from './DebouncedInput';

describe('Debounced Input', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('debounces input changes', async () => {
    const onChange = vi.fn();
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

    render(<DebouncedInput onChange={onChange} delay={300} />);

    await user.type(screen.getByRole('textbox'), 'hello');

    // Not called yet (within debounce window)
    expect(onChange).not.toHaveBeenCalled();

    // Advance time past debounce delay; act flushes the resulting state updates
    await act(async () => {
      await vi.advanceTimersByTimeAsync(300);
    });

    expect(onChange).toHaveBeenCalledWith('hello');
    expect(onChange).toHaveBeenCalledTimes(1);
  });
});
```

### Mocking API with MSW

```tsx
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'John' },
      { id: 2, name: 'Jane' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 3, ...body }, { status: 201 });
  }),

  http.delete('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ deleted: params.id });
  }),
];

// src/test/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// src/test/setup.ts
import { beforeAll, afterEach, afterAll } from 'vitest';
import { server } from './mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// In tests - override handlers
import { render, screen } from '@/test/utils';
import { it, expect } from 'vitest';
import { server } from '@/test/mocks/server';
import { http, HttpResponse } from 'msw';
import { UserList } from './UserList';

it('handles error response', async () => {
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 });
    })
  );

  render(<UserList />);
  expect(await screen.findByText(/error/i)).toBeInTheDocument();
});
```

## Integration Testing

Render the feature root without mocking its children and drive a whole flow through the UI, asserting on what the user sees after each step.

### Testing Data Flow

```tsx
// TodoApp.test.tsx
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { TodoApp } from './TodoApp';

describe('TodoApp Integration', () => {
  it('allows adding, completing, and deleting todos', async () => {
    const user = userEvent.setup();
    render(<TodoApp />);

    // Add a todo
    const input = screen.getByPlaceholderText(/add todo/i);
    await user.type(input, 'Buy groceries{Enter}');

    // Verify todo was added
    const todo = screen.getByText('Buy groceries');
    expect(todo).toBeInTheDocument();

    // Complete the todo
    const checkbox = screen.getByRole('checkbox');
    await user.click(checkbox);
    expect(checkbox).toBeChecked();

    // Delete the todo
    const deleteButton = screen.getByRole('button', { name: /delete/i });
    await user.click(deleteButton);
    expect(screen.queryByText('Buy groceries')).not.toBeInTheDocument();
  });

  it('filters todos correctly', async () => {
    const user = userEvent.setup();
    render(<TodoApp />);

    // Add todos
    const input = screen.getByPlaceholderText(/add todo/i);
    await user.type(input, 'Task 1{Enter}');
    await user.type(input, 'Task 2{Enter}');

    // Complete first task
    const checkboxes = screen.getAllByRole('checkbox');
    await user.click(checkboxes[0]);

    // Filter by active
    await user.click(screen.getByRole('button', { name: /active/i }));
    expect(screen.queryByText('Task 1')).not.toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();

    // Filter by completed
    await user.click(screen.getByRole('button', { name: /completed/i }));
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.queryByText('Task 2')).not.toBeInTheDocument();
  });
});
```

## Accessibility Testing

### Basic A11y Tests

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { axe, toHaveNoViolations } from 'jest-axe';
import { ContactForm } from './ContactForm';

expect.extend(toHaveNoViolations);

describe('ContactForm accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<ContactForm onSubmit={vi.fn()} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has proper form labels', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/message/i)).toBeInTheDocument();
  });

  it('has accessible button', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    const button = screen.getByRole('button', { name: /submit/i });
    expect(button).toBeInTheDocument();
    expect(button).toHaveAttribute('type', 'submit');
  });

  it('marks required fields', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/name/i)).toBeRequired();
    expect(screen.getByLabelText(/email/i)).toBeRequired();
  });

  it('associates error messages with inputs', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /submit/i }));

    const emailInput = screen.getByLabelText(/email/i);
    const errorId = emailInput.getAttribute('aria-describedby');

    expect(errorId).toBeTruthy();
    expect(document.getElementById(errorId!)).toHaveTextContent(/required/i);
  });
});
```

### Testing Keyboard Navigation

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { Modal } from './Modal';

describe('Modal keyboard navigation', () => {
  it('traps focus within modal', async () => {
    const user = userEvent.setup();
    render(
      <Modal isOpen onClose={vi.fn()}>
        <button>First</button>
        <button>Second</button>
        <button>Close</button>
      </Modal>
    );

    const firstButton = screen.getByRole('button', { name: /first/i });
    const closeButton = screen.getByRole('button', { name: /close/i });

    expect(firstButton).toHaveFocus();

    // Tab through all buttons
    await user.tab();
    expect(screen.getByRole('button', { name: /second/i })).toHaveFocus();

    await user.tab();
    expect(closeButton).toHaveFocus();

    // Tab should wrap to first
    await user.tab();
    expect(firstButton).toHaveFocus();
  });

  it('closes on Escape key', async () => {
    const user = userEvent.setup();
    const handleClose = vi.fn();
    render(
      <Modal isOpen onClose={handleClose}>
        Content
      </Modal>
    );

    await user.keyboard('{Escape}');

    expect(handleClose).toHaveBeenCalled();
  });
});
```
