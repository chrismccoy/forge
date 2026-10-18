# Workflow: Generate React Component Tests

Create comprehensive tests for a React component using React Testing Library.

## Instructions

Generate tests for the specified React component:

1. **Analyze Component**
   - Read the component file specified in the request
   - Identify all props and their types
   - Find all interactive elements (buttons, inputs, links)
   - Identify conditional rendering logic
   - Check for async operations or side effects
   - Detect the project's test runner (Vitest or Jest) from `package.json` and existing config, and follow its conventions. The examples below use Vitest's `vi`; with Jest use `jest` instead

2. **Test Categories to Cover**
   - Rendering tests (component renders without errors)
   - Props tests (handles different prop values correctly)
   - Interaction tests (clicks, typing, form submission)
   - Accessibility tests (roles, labels, keyboard navigation)
   - Edge cases (empty states, error states, loading states)

3. **Implementation Checklist**
   - [ ] Import component and testing utilities
   - [ ] Set up necessary providers/mocks
   - [ ] Test default render
   - [ ] Test all prop variations
   - [ ] Test user interactions
   - [ ] Test accessibility
   - [ ] Test error handling

4. **File Location**
   - Place test file next to component: `Component.test.tsx`
   - Or in __tests__ folder: `__tests__/Component.test.tsx`
   - Follow the existing layout if the project already has tests

5. **Run**
   - Run the tests with the project's own test script (for example, its `test` script in `package.json`), not a hard-coded runner command

## Example Output

```tsx
// components/UserCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const defaultProps = {
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  };

  it('renders user name and email', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
  });

  it('renders avatar when provided', () => {
    render(<UserCard {...defaultProps} avatar="/avatar.jpg" />);

    const avatar = screen.getByRole('img', { name: /john doe's avatar/i });
    expect(avatar).toHaveAttribute('src', '/avatar.jpg');
  });

  it('does not render avatar when not provided', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', async () => {
    const user = userEvent.setup();
    const handleEdit = vi.fn();

    render(<UserCard {...defaultProps} onEdit={handleEdit} />);

    await user.click(screen.getByRole('button', { name: /edit john doe/i }));

    expect(handleEdit).toHaveBeenCalledWith('1');
  });

  it('does not render edit button when onEdit is not provided', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});
```

## Testing Patterns

### Testing with Providers
Create a fresh `QueryClient` for each render so cache state never leaks between tests, and turn off retries so error-state tests fail fast instead of retrying until they time out:

```tsx
import { render } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './ThemeProvider';

function renderWithProviders(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        {ui}
      </ThemeProvider>
    </QueryClientProvider>
  );
}
```

For a shared utility that also sets up a router, see [Custom Render with Providers](../testing-recipes.md#custom-render-with-providers).

### Testing Async Components
```tsx
it('loads and displays data', async () => {
  render(<UserList />);

  expect(screen.getByText('Loading...')).toBeInTheDocument();

  // findBy* waits for the element to appear
  expect(await screen.findByText('John Doe')).toBeInTheDocument();
});
```

### Testing Server Components
React Testing Library cannot render an `async` Server Component as JSX. Test its data function separately, render the awaited result for a leaf component (`render(await UserProfile({ userId: '1' }))` with the data module mocked), or use an e2e test for full pages. See `../testing.md#testing-server-components`.

### Testing Forms
```tsx
it('submits form with entered data', async () => {
  const user = userEvent.setup();
  const handleSubmit = vi.fn();

  render(<ContactForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText('Name'), 'John');
  await user.type(screen.getByLabelText('Email'), 'john@example.com');
  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(handleSubmit).toHaveBeenCalledWith({
    name: 'John',
    email: 'john@example.com',
  });
});
```

### Testing Custom Hooks
```tsx
import { renderHook, act } from '@testing-library/react';

it('increments counter', () => {
  const { result } = renderHook(() => useCounter());

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});
```

## Query Priority (Best Practices)

Query by role, then label, placeholder, text, and display value; fall back to alt text and title, and use `getByTestId` only when no semantic option exists. Full order and examples: [testing.md](../testing.md#1-query-priority).

## Mocking Best Practices

Mock at module or network boundaries: `vi.mock('./api')` for data modules, `vi.spyOn(globalThis, 'fetch')` per test (restored by `vi.restoreAllMocks()`), or MSW if the project uses it. Render routed components inside the project's router (for example, `MemoryRouter` with `initialEntries`) instead of mocking it; mock only framework routers such as Next.js `next/navigation`, following the project's existing test setup. Principles: [testing.md](../testing.md#mocking). Copy-paste recipes: [testing-recipes.md](../testing-recipes.md#mocking-patterns), including [routing](../testing-recipes.md#routing-render-in-a-memoryrouter) and [MSW](../testing-recipes.md#mocking-api-with-msw).
