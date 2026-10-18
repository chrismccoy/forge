# React Forms: Server Actions

Load this when wiring `<form action>` to Server Actions in a supporting framework: `useActionState`, bound arguments, idempotent submissions, `useOptimistic`, and `useFormStatus`.

**Prerequisites:** general form patterns, accessibility wiring, and Key Gotchas live in [forms.md](forms.md); `FormData` parsing with Zod is in [zod.md](zod.md#coercion-at-boundaries).

## Contents

- [Server Actions with Forms](#server-actions-with-forms)
  - [Basic Server Action Form](#basic-server-action-form)
  - [Passing Extra Arguments with bind](#passing-extra-arguments-with-bind)
  - [Idempotent Server Actions](#idempotent-server-actions)
  - [Optimistic Updates with useOptimistic](#optimistic-updates-with-useoptimistic)
  - [Form with useFormStatus](#form-with-useformstatus)

## Server Actions with Forms

Server Actions are a React 19 feature available in a framework that supports them. Treat every action as a public endpoint: authenticate, validate input, and scope writes to the session user.

### Basic Server Action Form

When an action is used with `useActionState`, React calls it as `action(prevState, formData)`. The signature must accept the previous state first, and every return path must produce the same state shape.

```tsx
// actions.ts
'use server';

import { z } from 'zod';
import { auth } from './auth'; // your session helper
import { db } from './db'; // your data layer

const PostSchema = z.object({
  title: z.string().trim().min(3, 'Title must be at least 3 characters').max(200),
  content: z.string().trim().min(1, 'Content is required').max(10_000),
});

export type CreatePostState = {
  status: 'idle' | 'success' | 'error';
  message: string | null;
  fieldErrors: { title?: string[]; content?: string[] };
};

export async function createPost(
  prevState: CreatePostState,
  formData: FormData
): Promise<CreatePostState> {
  const session = await auth();
  if (!session?.user) {
    return { status: 'error', message: 'You must be signed in.', fieldErrors: {} };
  }

  const parsed = PostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });
  if (!parsed.success) {
    return {
      status: 'error',
      message: 'Fix the errors below.',
      fieldErrors: z.flattenError(parsed.error).fieldErrors,
    };
  }

  await db.posts.create({
    data: { ...parsed.data, authorId: session.user.id },
  });

  // framework-specific cache invalidation (e.g. Next.js revalidatePath; see the framework docs)
  return { status: 'success', message: 'Post created!', fieldErrors: {} };
}
```

```tsx
// CreatePostForm.tsx
'use client';

import { useActionState } from 'react';
import { createPost, type CreatePostState } from './actions';

const initialState: CreatePostState = { status: 'idle', message: null, fieldErrors: {} };

function CreatePostForm() {
  const [state, formAction, isPending] = useActionState(createPost, initialState);
  const { fieldErrors } = state;

  return (
    <form action={formAction}>
      {state.message && (
        <div role={state.status === 'error' ? 'alert' : 'status'}>{state.message}</div>
      )}

      <div>
        <label htmlFor="title">Title</label>
        <input
          id="title"
          name="title"
          required
          aria-invalid={!!fieldErrors.title}
          aria-describedby={fieldErrors.title ? 'title-error' : undefined}
        />
        {fieldErrors.title && <span id="title-error">{fieldErrors.title[0]}</span>}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea
          id="content"
          name="content"
          required
          aria-invalid={!!fieldErrors.content}
          aria-describedby={fieldErrors.content ? 'content-error' : undefined}
        />
        {fieldErrors.content && <span id="content-error">{fieldErrors.content[0]}</span>}
      </div>

      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

### Passing Extra Arguments with bind

To send a value that is not a form field (a record id from the route), bind it to the action. Bound arguments come first, then `formData` (or `prevState, formData` under `useActionState`).

```tsx
// actions.ts
'use server';

import { z } from 'zod';
import { auth } from './auth';
import { db } from './db';

const RenameSchema = z.object({ name: z.string().trim().min(1, 'Name is required').max(100) });

export async function renameProject(projectId: string, formData: FormData): Promise<void> {
  const session = await auth();
  if (!session?.user) throw new Error('Unauthorized');

  const id = z.uuid().parse(projectId); // bound values are client-visible and can be tampered with
  const { name } = RenameSchema.parse({ name: formData.get('name') });

  // Scope the write to the owner: a mismatched id updates nothing
  const { count } = await db.projects.updateMany({
    where: { id, ownerId: session.user.id },
    data: { name },
  });
  if (count === 0) throw new Error('Not found');
}
```

```tsx
// app/projects/[id]/settings/page.tsx
import { renameProject } from './actions';

export default async function ProjectSettings({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const renameThisProject = renameProject.bind(null, id);

  return (
    <form action={renameThisProject}>
      <label htmlFor="name">Project name</label>
      <input id="name" name="name" required maxLength={100} />
      <button type="submit">Rename</button>
    </form>
  );
}
```

`bind` works in Server and Client Components and keeps progressive enhancement. A hidden input also works, but its value is just as untrusted: re-validate and re-authorize either way. For parsing `FormData` fields (checkboxes, numbers, multi-value fields, files), see [zod.md](zod.md#coercion-at-boundaries).

### Idempotent Server Actions

A double click, a flaky network, or a resubmitted page can run an action twice. Server Actions cannot set custom headers such as `Idempotency-Key`, so the key travels as a bound argument (or a hidden input). Generate it once per form intent, when the form is rendered, never inside the action: a key created per call dedupes nothing.

```prisma
model Order {
  id             String @id @default(cuid())
  userId         String
  idempotencyKey String
  productId      String
  quantity       Int

  @@unique([userId, idempotencyKey])
}
```

```tsx
// actions.ts
'use server';

import { Prisma } from '@prisma/client';
import { redirect } from 'next/navigation';
import { z } from 'zod';
import { auth } from './auth';
import { db } from './db';

const KeySchema = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
const OrderSchema = z.object({
  productId: z.string().min(1).max(64),
  quantity: z.coerce.number().int().min(1).max(100),
});

export type OrderState = { error: string | null };

export async function placeOrder(
  key: string, // bound argument: client-visible, so validate it like any input
  prevState: OrderState,
  formData: FormData
): Promise<OrderState> {
  const session = await auth();
  if (!session?.user) return { error: 'You must be signed in.' };

  const idempotencyKey = KeySchema.safeParse(key);
  const parsed = OrderSchema.safeParse(Object.fromEntries(formData));
  if (!idempotencyKey.success || !parsed.success) return { error: 'Invalid order.' };

  const userId = session.user.id;
  let orderId: string;
  try {
    // The key is stored with the write, under UNIQUE (userId, idempotencyKey)
    const order = await db.order.create({
      data: { ...parsed.data, userId, idempotencyKey: idempotencyKey.data },
    });
    orderId = order.id;
  } catch (error) {
    const isDuplicate =
      error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002';
    if (!isDuplicate) throw error;
    // Repeat submission: return the original result instead of writing again
    const existing = await db.order.findUniqueOrThrow({
      where: { userId_idempotencyKey: { userId, idempotencyKey: idempotencyKey.data } },
    });
    orderId = existing.id;
  }
  redirect(`/orders/${orderId}`); // outside try: redirect() throws by design
}
```

```tsx
// app/checkout/page.tsx: Server Component, dynamic because it reads the session
import { redirect } from 'next/navigation';
import { auth } from './auth';
import { CheckoutForm } from './CheckoutForm';

export default async function CheckoutPage() {
  if (!(await auth())?.user) redirect('/login');
  return <CheckoutForm idempotencyKey={crypto.randomUUID()} />; // new key per page render
}
```

```tsx
// app/checkout/CheckoutForm.tsx
'use client';

import { useActionState } from 'react';
import { placeOrder, type OrderState } from './actions';

const initialState: OrderState = { error: null };

export function CheckoutForm({ idempotencyKey }: { idempotencyKey: string }) {
  // React calls the bound action as (prevState, formData)
  const [state, formAction, isPending] = useActionState(
    placeOrder.bind(null, idempotencyKey),
    initialState
  );

  return (
    <form action={formAction}>
      {state.error && <p role="alert">{state.error}</p>}
      {/* inputs named productId and quantity */}
      <button type="submit" disabled={isPending}>Place order</button>
    </form>
  );
}
```

Generate the key in a dynamically rendered page, as above, or in the client after mount; a prerendered page would hand every visitor the same key. Scoping the constraint to `userId` stops one user from replaying another user's result. After a successful write, the next intent needs a fresh key: the redirect does this by rendering a new page.

### Optimistic Updates with useOptimistic

`addComment` is a Server Action with the same guards as `createPost` (authenticate, validate with Zod, scope the write to the session user). It is called directly here, not through `useActionState`, so it takes only `formData`.

```tsx
'use client';

import { useOptimistic, useTransition } from 'react';
import { addComment } from './actions';

interface Comment {
  id: string;
  text: string;
  author: string;
  pending?: boolean;
}

function CommentSection({ initialComments }: { initialComments: Comment[] }) {
  const [isPending, startTransition] = useTransition();
  const [optimisticComments, addOptimisticComment] = useOptimistic(
    initialComments,
    (state, newComment: Comment) => [...state, { ...newComment, pending: true }]
  );

  function handleSubmit(formData: FormData) {
    const text = String(formData.get('text') ?? '');

    startTransition(async () => {
      // Shown immediately; reverts automatically when the transition ends
      addOptimisticComment({ id: crypto.randomUUID(), text, author: 'You' });
      await addComment(formData);
    });
  }

  return (
    <div>
      <ul>
        {optimisticComments.map((comment) => (
          <li key={comment.id} style={{ opacity: comment.pending ? 0.5 : 1 }}>
            <strong>{comment.author}</strong>: {comment.text}
            {comment.pending && <span> (posting...)</span>}
          </li>
        ))}
      </ul>

      <form action={handleSubmit}>
        <label htmlFor="comment-text">Add a comment</label>
        <input id="comment-text" name="text" required />
        <button type="submit" disabled={isPending}>
          {isPending ? 'Posting...' : 'Post'}
        </button>
      </form>
    </div>
  );
}
```

The optimistic comment is discarded when the transition ends, so the saved comment must reach `initialComments` by then or it disappears from the list. After `addComment` resolves, update the source list in one of these ways:

- Revalidate or refetch the data that renders `CommentSection` (framework revalidation, such as Next.js `revalidatePath`, inside the Server Action), so the parent passes the new list.
- Have `addComment` return the saved comment, keep the list in state (`const [comments, setComments] = useState(initialComments)`, passed to `useOptimistic`), and append the result inside the same transition: `startTransition(() => setComments((prev) => [...prev, saved]))`.

### Form with useFormStatus

`useFormStatus` reads the status of the parent `<form>`, so it must be called from a component rendered inside that form.

```tsx
'use client';

import { useFormStatus } from 'react-dom';
import { submitContactForm } from './actions';

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

function ContactForm() {
  return (
    <form action={submitContactForm}>
      <label htmlFor="contact-name">Name</label>
      <input id="contact-name" name="name" autoComplete="name" required />

      <label htmlFor="contact-email">Email</label>
      <input id="contact-email" name="email" type="email" autoComplete="email" required />

      <label htmlFor="contact-message">Message</label>
      <textarea id="contact-message" name="message" required />

      <SubmitButton />
    </form>
  );
}
```
