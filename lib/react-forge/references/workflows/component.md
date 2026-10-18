# Workflow: Generate React Component

Create a new React component following best practices for React 19.

## Instructions

Create a React component based on the provided name and specifications:

1. **Analyze Requirements**
   - Parse component name from the request
   - Identify required props and their types
   - Determine if it should be a Server or Client Component:
     - If the user asks for a Client or Server Component explicitly, follow that request
     - Otherwise decide from its needs (see "When to Use 'use client'" below), in a framework that supports Server Components
   - Check for existing patterns in the codebase

2. **Component Structure**
   - Use function component syntax
   - Add proper TypeScript interface for props
   - Include 'use client' directive only if needed (useState, useEffect, event handlers)
   - Follow project naming conventions

3. **Implementation Checklist**
   - [ ] Proper prop types with TypeScript
   - [ ] Destructured props with defaults where appropriate
   - [ ] Proper accessibility attributes (aria-*, role, etc.)
   - [ ] Error boundaries if needed
   - [ ] Loading/error states if applicable
   - [ ] Proper key usage for lists

4. **File Location**
   - Check project structure for component directories
   - Place in appropriate folder (components/, features/, etc.)
   - Use consistent file naming (PascalCase.tsx)

## Example Output

In a framework that supports Server Components (for example the Next.js App Router), components are Server Components unless they need interactivity. This one fetches its own data on the server and ships no JavaScript to the browser:

```tsx
// components/UserProfile.tsx — Server Component (no 'use client')
import { getUser } from '@/lib/users';

interface UserProfileProps {
  userId: string;
}

export async function UserProfile({ userId }: UserProfileProps) {
  const user = await getUser(userId);

  if (!user) {
    return <p role="status">User not found.</p>;
  }

  return (
    <section aria-labelledby={`user-${user.id}-name`}>
      <h2 id={`user-${user.id}-name`}>{user.name}</h2>
      <p>{user.email}</p>
      <p>Joined {new Date(user.joinedAt).toLocaleDateString()}</p>
    </section>
  );
}
```

In a client-only app (for example a Vite SPA), every component is a Client Component and no directive is needed; fetch data with a client library such as TanStack Query instead of `async` components.

When the component needs an event handler, state, or browser APIs, make it a Client Component:

```tsx
// components/UserCard.tsx
'use client'; // has an event handler

interface UserCardProps {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  onEdit?: (id: string) => void;
}

export function UserCard({ id, name, email, avatar, onEdit }: UserCardProps) {
  return (
    <article className="user-card">
      {avatar && <img src={avatar} alt={`${name}'s avatar`} />}
      <h3>{name}</h3>
      <p>{email}</p>
      {onEdit && (
        <button type="button" onClick={() => onEdit(id)} aria-label={`Edit ${name}`}>
          Edit
        </button>
      )}
    </article>
  );
}
```

`onEdit` works only when the parent is also a Client Component: props crossing from a Server Component to a Client Component must be serializable, and a plain function is not. From a Server Component parent, pass a Server Action instead (name the prop `...Action`, such as `editAction`) or keep the interaction inside the Client Component:

```tsx
// app/users/actions.ts
'use server';

import { redirect } from 'next/navigation';
import { z } from 'zod';
import { requireUser } from '@/lib/authz';

export async function editUser(id: string): Promise<void> {
  await requireUser(); // a Server Action is a public endpoint: authenticate and validate
  redirect(`/users/${z.string().regex(/^[A-Za-z0-9_-]{1,64}$/).parse(id)}/edit`);
}
```

```tsx
// components/UserCardAction.tsx
'use client';

interface UserCardActionProps {
  name: string;
  editAction: () => Promise<void>; // a Server Action, serializable across the boundary
}

export function UserCardAction({ name, editAction }: UserCardActionProps) {
  return (
    <form action={editAction}>
      <h3>{name}</h3>
      <button type="submit" aria-label={`Edit ${name}`}>
        Edit
      </button>
    </form>
  );
}
```

```tsx
// In a Server Component parent: bind the id on the server
<UserCardAction name={user.name} editAction={editUser.bind(null, user.id)} />
```

See [fundamentals.md](../fundamentals.md#composing-server-and-client-components) for what may cross the server-client boundary.

## Client Component Example

```tsx
// components/Counter.tsx
'use client';

import { useState } from 'react';

interface CounterProps {
  initialCount?: number;
  step?: number;
  onChange?: (count: number) => void;
}

export function Counter({ initialCount = 0, step = 1, onChange }: CounterProps) {
  const [count, setCount] = useState(initialCount);

  const handleIncrement = () => {
    const newCount = count + step;
    setCount(newCount);
    onChange?.(newCount);
  };

  return (
    <div className="counter">
      <span aria-live="polite">{count}</span>
      <button type="button" onClick={handleIncrement} aria-label={`Increment count by ${step}`}>
        +{step}
      </button>
    </div>
  );
}
```

## When to Use 'use client'

Only add 'use client' when the component:
- Uses hooks like useState, useEffect, useRef
- Has event handlers (onClick, onChange, etc.)
- Uses browser-only APIs (window, document, localStorage)
- Needs to be interactive

Server Components (no 'use client') when:
- Only displaying data
- Fetching data directly
- No interactivity needed
- Rendering static content
