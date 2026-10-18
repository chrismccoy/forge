# Workflow: Generate Next.js Route Handler

Create a Next.js 15 or 16 App Router Route Handler (`app/**/route.ts`) with Zod validation, authentication, ownership checks, and correct status codes, including idempotent mutations and signed webhooks. Use it when the user asks to "add API route `posts` with GET,POST", "CRUD for `users/[id]`", or "add a Stripe webhook".

## Contents

- [Instructions](#instructions)
- [Example Output](#example-output)
  - [Collection: list and create](#collection-list-and-create)
  - [Item: read, update, delete with ownership](#item-read-update-delete-with-ownership)
  - [Retried mutation with an idempotency key](#retried-mutation-with-an-idempotency-key)
  - [File upload](#file-upload)
  - [Signed webhook with HMAC](#signed-webhook-with-hmac)
  - [Stripe webhook with exhaustive dispatch](#stripe-webhook-with-exhaustive-dispatch)
- [Checklist](#checklist)
- [Related](#related)

## Instructions

1. **Inspect the project first**
   - Read the Next.js version in `package.json`. The second handler argument's `params` is a Promise on 15 and 16; `await` it.
   - Check whether routes live in `app/` or `src/app/`.
   - Read path aliases in `tsconfig.json` (`@/` or similar).
   - Find existing helpers: auth (`@/auth` exporting `auth()`), DB client (`@/lib/db`), Zod version (these templates use Zod 4), error helpers, and existing `app/api/` handlers to match their response shape.
   - Check that no `page.tsx` exists in the target folder. A `route.ts` and `page.tsx` cannot share a segment.

2. **Analyze the request**
   - Parse the path, dynamic segments (`[id]`, `[slug]`), and HTTP methods.
   - Decide who may call each method: public, any signed-in user, the resource owner, or an admin.
   - Decide whether a Server Action fits better. Form posts from the app's own UI should be Server Actions ([forms-server-actions.md](../forms-server-actions.md#server-actions-with-forms)). Use a Route Handler for webhooks, mobile or third-party clients, streaming, custom headers, or CORS.
   - Identify retried mutations (payments, orders, job submission). These require a client-supplied idempotency key.
   - Identify webhooks. These require raw-body signature verification and the provider's event ID for idempotency.

3. **Implement each method**
   - Authenticate inside the handler with `auth()`. A proxy or middleware check is not authorization.
   - For item routes, load the resource and check ownership: `401` signed out, `404` missing or hidden, `403` visible but not allowed.
   - Parse JSON with `request.json().catch(() => undefined)` and return `400` on failure.
   - Validate bodies and query strings with Zod `safeParse`. Pass only parsed fields to the DB; never spread the raw body.
   - Take owner IDs, prices, and roles from the session or the database, never from the body.
   - Return the right status code (`200`, `201`, `204`, `400`, `401`, `403`, `404`, `409`, `413`, `415`, `429`, `500`). Log unexpected errors and return a generic message.
   - Do not add the Pages Router `export const config = { api: { bodyParser } }`. App Router ignores it. Read the raw body with `request.text()`.
   - `GET` handlers are not cached by default. Opt in only for public data; see [nextjs-caching.md](../nextjs-caching.md).

4. **Report**
   - List every created file path (all Route Handlers are Server).
   - List required env vars, DB constraints (UNIQUE indexes for idempotency), and packages.

Optional shortcut: scaffold the handler with the bundled generator, then edit it. It includes auth by default and refuses to overwrite existing files unless `--force` is passed (only with the user's consent).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/lib/react-forge/scripts/generate-nextjs-component.py route --path app/api/posts --methods GET,POST
```

Request parsing, streaming responses, and CORS are covered in [nextjs-data-fetching.md](../nextjs-data-fetching.md#route-handlers).

## Example Output

### Collection: list and create

```tsx
// app/api/posts/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/lib/db';

const CreatePostSchema = z.object({
  title: z.string().trim().min(1).max(200),
  content: z.string().min(1).max(50_000),
  published: z.boolean().optional(),
});

// Query params are strings: coerce and bound them (no NaN, 0, negatives, or limit=1e9)
const ListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(10),
});

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const query = ListQuerySchema.safeParse({
    page: searchParams.get('page') ?? undefined,
    limit: searchParams.get('limit') ?? undefined,
  });
  if (!query.success) {
    return NextResponse.json(
      { error: 'Invalid query', details: z.flattenError(query.error).fieldErrors },
      { status: 400 }
    );
  }
  const { page, limit } = query.data;

  try {
    // Published posts for everyone; signed-in users also see their own drafts
    const session = await auth();
    const where = session?.user
      ? { OR: [{ published: true }, { authorId: session.user.id }] }
      : { published: true };

    const [posts, total] = await Promise.all([
      db.posts.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: { id: true, title: true, published: true, createdAt: true },
      }),
      db.posts.count({ where }),
    ]);

    return NextResponse.json({
      data: posts,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error('GET /api/posts failed:', error);
    return NextResponse.json({ error: 'Failed to fetch posts' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body: unknown = await request.json().catch(() => undefined);
  if (body === undefined) {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const parsed = CreatePostSchema.safeParse(body); // strips unknown keys
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: z.flattenError(parsed.error).fieldErrors },
      { status: 400 }
    );
  }

  try {
    const post = await db.posts.create({
      data: { ...parsed.data, authorId: session.user.id }, // author from the session
    });
    return NextResponse.json(post, { status: 201 });
  } catch (error) {
    console.error('POST /api/posts failed:', error);
    return NextResponse.json({ error: 'Failed to create post' }, { status: 500 });
  }
}
```

### Item: read, update, delete with ownership

```tsx
// app/api/posts/[id]/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/lib/db';

type RouteContext = { params: Promise<{ id: string }> };

// Whitelist of updatable fields; never pass the raw body to the DB
const UpdatePostSchema = z
  .object({
    title: z.string().trim().min(1).max(200),
    content: z.string().min(1).max(50_000),
    published: z.boolean(),
  })
  .partial();

// Returns the post if the current user may modify it, else an error response
async function authorizeWrite(id: string) {
  const session = await auth();
  if (!session?.user) {
    return { error: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };
  }
  const post = await db.posts.findUnique({ where: { id }, select: { id: true, authorId: true } });
  if (!post) {
    return { error: NextResponse.json({ error: 'Post not found' }, { status: 404 }) };
  }
  if (post.authorId !== session.user.id && session.user.role !== 'admin') {
    return { error: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) };
  }
  return { post };
}

export async function GET(_request: NextRequest, { params }: RouteContext) {
  const { id } = await params;
  try {
    const post = await db.posts.findUnique({ where: { id } });

    // Drafts are visible only to their author (404, not 403: don't reveal they exist)
    const session = post && !post.published ? await auth() : null;
    if (!post || (!post.published && post.authorId !== session?.user?.id)) {
      return NextResponse.json({ error: 'Post not found' }, { status: 404 });
    }
    return NextResponse.json(post);
  } catch (error) {
    console.error(`GET /api/posts/${id} failed:`, error);
    return NextResponse.json({ error: 'Failed to fetch post' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const { id } = await params;
  const { error } = await authorizeWrite(id);
  if (error) return error;

  const body: unknown = await request.json().catch(() => undefined);
  if (body === undefined) {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const parsed = UpdatePostSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: z.flattenError(parsed.error).fieldErrors },
      { status: 400 }
    );
  }

  try {
    const post = await db.posts.update({ where: { id }, data: parsed.data });
    return NextResponse.json(post);
  } catch (err) {
    console.error(`PATCH /api/posts/${id} failed:`, err);
    return NextResponse.json({ error: 'Failed to update post' }, { status: 500 });
  }
}

export async function DELETE(_request: NextRequest, { params }: RouteContext) {
  const { id } = await params;
  const { error } = await authorizeWrite(id);
  if (error) return error;

  try {
    await db.posts.delete({ where: { id } });
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error(`DELETE /api/posts/${id} failed:`, err);
    return NextResponse.json({ error: 'Failed to delete post' }, { status: 500 });
  }
}
```

`session.user.role` is not part of Auth.js's default `Session` type. It type-checks only after the module augmentation in [nextjs-auth.md](../nextjs-auth.md#extending-session-and-jwt-types), and the `jwt` and `session` callbacks must copy the role onto the session. For sensitive checks, read the role fresh from the database with `requireRole` from [nextjs-auth.md](../nextjs-auth.md#authorization-helpers) instead.

After a mutation that changes cached pages, call `revalidatePath` or `revalidateTag(tag, 'max')` (Route Handlers cannot use `updateTag`). See [nextjs-caching.md](../nextjs-caching.md#revalidation).

### Retried mutation with an idempotency key

Clients retry payments, orders, and job submissions after timeouts. Require a client-supplied `Idempotency-Key`, persist it under a UNIQUE constraint scoped to the user, and replay the original result on a retry. A server-generated key gives no protection, so never fall back to one.

```prisma
// prisma/schema.prisma (excerpt)
model Order {
  id             String   @id @default(cuid())
  userId         String
  idempotencyKey String
  requestHash    String
  productId      String
  quantity       Int
  totalCents     Int
  createdAt      DateTime @default(now())

  @@unique([userId, idempotencyKey])
}
```

```tsx
// lib/db-errors.ts
import { Prisma } from '@prisma/client';

export function isUniqueViolation(error: unknown): boolean {
  return error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002';
}
```

```tsx
// app/api/orders/route.ts — Server
import { createHash } from 'node:crypto';
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { auth } from '@/auth';
import { db } from '@/lib/db';
import { isUniqueViolation } from '@/lib/db-errors';

const IdempotencyKeySchema = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);

const CreateOrderSchema = z.object({
  productId: z.string().min(1).max(64),
  quantity: z.number().int().min(1).max(100),
});

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const userId = session.user.id;

  // Validate the key before any DB write
  const key = IdempotencyKeySchema.safeParse(request.headers.get('idempotency-key'));
  if (!key.success) {
    return NextResponse.json({ error: 'Missing or invalid Idempotency-Key header' }, { status: 400 });
  }
  const idempotencyKey = key.data;

  const body: unknown = await request.json().catch(() => undefined);
  const parsed = CreateOrderSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Invalid order' }, { status: 400 });
  }
  const requestHash = createHash('sha256').update(JSON.stringify(parsed.data)).digest('hex');

  const replay = async () => {
    const existing = await db.order.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
    });
    if (!existing) return null;
    // Same key with a different body is a client bug, not a retry
    if (existing.requestHash !== requestHash) {
      return NextResponse.json({ error: 'Idempotency-Key reused with a different request' }, { status: 409 });
    }
    return NextResponse.json(existing, { status: 200 });
  };

  const previous = await replay();
  if (previous) return previous;

  // Price comes from the database, never from the client
  const product = await db.product.findUnique({
    where: { id: parsed.data.productId },
    select: { priceCents: true, active: true },
  });
  if (!product || !product.active) {
    return NextResponse.json({ error: 'Product not found' }, { status: 404 });
  }

  try {
    const order = await db.order.create({
      data: {
        userId,
        idempotencyKey,
        requestHash,
        productId: parsed.data.productId,
        quantity: parsed.data.quantity,
        totalCents: product.priceCents * parsed.data.quantity,
      },
    });
    return NextResponse.json(order, { status: 201 });
  } catch (error) {
    // A concurrent retry won the race: return its result
    if (isUniqueViolation(error)) {
      const raced = await replay();
      if (raced) return raced;
    }
    console.error('POST /api/orders failed:', error);
    return NextResponse.json({ error: 'Failed to create order' }, { status: 500 });
  }
}
```

The client generates the key once per user intent (for example `crypto.randomUUID()` when the checkout form mounts) and resends the same key on every retry.

### File upload

Do not write to `public/` or the local filesystem: runtime-added files in `public/` are not served, and the filesystem is read-only or ephemeral on Vercel and in containers. Store uploads in object storage.

```tsx
// app/api/upload/route.ts — Server
import { NextResponse, type NextRequest } from 'next/server';
import { put } from '@vercel/blob';
import { auth } from '@/auth';

const MAX_BYTES = 4 * 1024 * 1024; // Vercel Functions cap request bodies at 4.5 MB
const ALLOWED_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

export async function POST(request: NextRequest) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const formData = await request.formData(); // no bodyParser config in App Router
    const file = formData.get('file');

    if (!(file instanceof File) || file.size === 0) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }
    if (file.size > MAX_BYTES) {
      return NextResponse.json({ error: 'File too large' }, { status: 413 });
    }

    const ext = ALLOWED_TYPES[file.type]; // file.type is client-supplied: allowlist only
    if (!ext) {
      return NextResponse.json({ error: 'Unsupported file type' }, { status: 415 });
    }

    // Never use file.name in the path (path traversal, overwrites): generate it
    const pathname = `uploads/${session.user.id}/${crypto.randomUUID()}.${ext}`;
    const blob = await put(pathname, file, { access: 'public', contentType: file.type });

    return NextResponse.json({ url: blob.url }, { status: 201 });
  } catch (error) {
    console.error('POST /api/upload failed:', error);
    return NextResponse.json({ error: 'Upload failed' }, { status: 500 });
  }
}
```

For files larger than a few MB, skip the server hop: use Vercel Blob client uploads (`@vercel/blob/client`) or return an S3 presigned URL from an authenticated route. For stricter type checks, sniff magic bytes (for example with `file-type`) instead of trusting `file.type`.

### Signed webhook with HMAC

For providers without an SDK verifier, compute the HMAC over the raw body yourself, compare with `crypto.timingSafeEqual`, reject stale timestamps, and use the provider's event ID under a UNIQUE constraint so retries run once. Adjust the signed payload format and header names to the provider's documentation.

```tsx
// app/api/webhooks/acme/route.ts — Server (Node.js runtime)
import { createHmac, timingSafeEqual } from 'node:crypto';
import { NextResponse, type NextRequest } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db';
import { isUniqueViolation } from '@/lib/db-errors';

const TOLERANCE_SECONDS = 300;

const EventSchema = z.object({
  id: z.string().min(1).max(200),
  type: z.literal('invoice.paid'),
  data: z.object({ accountId: z.string().min(1), invoiceId: z.string().min(1) }),
});

function verifySignature(rawBody: string, timestamp: string | null, signature: string | null): boolean {
  if (!timestamp || !signature) return false;
  const ts = Number(timestamp);
  if (!Number.isInteger(ts) || Math.abs(Date.now() / 1000 - ts) > TOLERANCE_SECONDS) return false;

  const expected = createHmac('sha256', process.env.ACME_WEBHOOK_SECRET!)
    .update(`${timestamp}.${rawBody}`)
    .digest();
  const received = Buffer.from(signature, 'hex');
  // timingSafeEqual throws on length mismatch; check first
  return received.length === expected.length && timingSafeEqual(received, expected);
}

export async function POST(request: NextRequest) {
  const rawBody = await request.text(); // the signature covers the exact bytes
  if (
    !verifySignature(
      rawBody,
      request.headers.get('acme-timestamp'),
      request.headers.get('acme-signature')
    )
  ) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  let json: unknown;
  try {
    json = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const parsed = EventSchema.safeParse(json);
  // Unknown or malformed event types: acknowledge, grant nothing
  if (!parsed.success) return NextResponse.json({ received: true });
  const event = parsed.data;

  try {
    await db.$transaction(async (tx) => {
      // Provider event ID under a UNIQUE constraint: retries run once
      await tx.processedWebhookEvent.create({ data: { id: `acme:${event.id}` } });
      await tx.invoice.updateMany({
        where: { id: event.data.invoiceId, accountId: event.data.accountId },
        data: { status: 'paid' },
      });
    });
  } catch (error) {
    if (isUniqueViolation(error)) return NextResponse.json({ received: true });
    console.error('Acme webhook failed:', error);
    return NextResponse.json({ error: 'Handler failed' }, { status: 500 }); // provider retries
  }

  return NextResponse.json({ received: true });
}
```

Never send the shared secret to a caller-supplied URL, and never accept a webhook whose signature check was skipped because a header was missing.

### Stripe webhook with exhaustive dispatch

`stripe.webhooks.constructEvent` performs the HMAC check with a constant-time comparison and rejects stale timestamps. `satisfies Record<HandledEvent, Handler>` fails the build when an event type has no handler; a `HandledEvent[]` array would only check membership.

```tsx
// app/api/webhooks/stripe/route.ts — Server (Node.js runtime)
import { NextResponse, type NextRequest } from 'next/server';
import Stripe from 'stripe';
import type { Prisma } from '@prisma/client';
import { db } from '@/lib/db';
import { isUniqueViolation } from '@/lib/db-errors';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

type Plan = 'free' | 'pro' | 'team';
type HandledEvent =
  | 'customer.subscription.created'
  | 'customer.subscription.updated'
  | 'customer.subscription.deleted';
// `current` is the subscription re-fetched from Stripe before the transaction opens
type Handler = (
  event: Stripe.Event,
  current: Stripe.Subscription,
  tx: Prisma.TransactionClient
) => Promise<void>;

const PRICE_TO_PLAN: Record<string, Plan> = {
  [process.env.STRIPE_PRICE_PRO!]: 'pro',
  [process.env.STRIPE_PRICE_TEAM!]: 'team',
};

// Zero-entitlement: anything not provably paid and active resolves to 'free'.
// Never fall back to the stored user.plan.
function planFor(sub: Stripe.Subscription): Plan {
  if (sub.status !== 'active' && sub.status !== 'trialing') return 'free';
  return PRICE_TO_PLAN[sub.items.data[0]?.price.id ?? ''] ?? 'free';
}

const setPlan: Handler = async (event, sub, tx) => {
  const customerId = typeof sub.customer === 'string' ? sub.customer : sub.customer.id;

  // updateMany: no throw (P2025) when no user is linked to this customer yet
  const { count } = await tx.user.updateMany({
    where: { stripeCustomerId: customerId },
    data: { plan: planFor(sub) },
  });
  if (count === 0) {
    // Common for subscription.created before checkout links the account. The event is
    // still recorded and acknowledged; the code that links the customer must derive
    // the plan from stripe.subscriptions.list({ customer }) at link time.
    console.warn(`Stripe ${event.type} ${event.id}: no user for customer ${customerId}`);
  }
};

const handlers = {
  'customer.subscription.created': setPlan,
  'customer.subscription.updated': setPlan,
  'customer.subscription.deleted': setPlan,
} satisfies Record<HandledEvent, Handler>;

const isHandled = (type: string): type is HandledEvent => Object.hasOwn(handlers, type);

export async function POST(request: NextRequest) {
  const rawBody = await request.text(); // raw body: the signature covers exact bytes
  let event: Stripe.Event;
  try {
    // Verifies the HMAC signature and rejects stale timestamps (default 300 s tolerance)
    event = stripe.webhooks.constructEvent(
      rawBody,
      request.headers.get('stripe-signature') ?? '',
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // Unknown event types: acknowledge, grant nothing
  const type = event.type;
  if (!isHandled(type)) return NextResponse.json({ received: true });

  try {
    // The payload is a snapshot from when the event fired, and events arrive out of
    // order. Re-fetch current state so an older "updated (active)" event processed after
    // "deleted" cannot re-grant a paid plan. Fetch before the transaction so no database
    // transaction stays open during a network call. A Stripe error lands in the catch
    // below and returns 500, so Stripe retries.
    const snapshot = event.data.object as Stripe.Subscription;
    const current = await stripe.subscriptions.retrieve(snapshot.id);

    // Idempotency: Stripe retries; event.id under a UNIQUE constraint runs each event once
    await db.$transaction(async (tx) => {
      await tx.processedWebhookEvent.create({ data: { id: event.id } });
      await handlers[type](event, current, tx);
    });
  } catch (error) {
    if (isUniqueViolation(error)) return NextResponse.json({ received: true });
    console.error('Stripe webhook failed:', error);
    return NextResponse.json({ error: 'Handler failed' }, { status: 500 }); // Stripe retries
  }

  return NextResponse.json({ received: true });
}
```

Stripe does not guarantee delivery order, so a handler that grants entitlements must not trust the event payload: derive the plan from `stripe.subscriptions.retrieve` as above. For extra protection, store a `planUpdatedAt` column and skip writes whose `event.created` is older; this guard alone is not enough, because two events can share the same second. When no user matches the customer, the handler records the event and returns `200`, so the account-linking step has to set the initial plan from Stripe. Required env vars: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_PRO`, `STRIPE_PRICE_TEAM`. Required table: `processedWebhookEvent` with `id` as the primary key.

## Checklist

- [ ] Project inspected: version, `app/` vs `src/app/`, aliases, auth and DB helpers, existing response shape
- [ ] No `page.tsx` in the same folder
- [ ] `params` awaited from the second handler argument
- [ ] `auth()` called inside every mutating handler (and reads of private data)
- [ ] Ownership checked: `401` signed out, `404` missing or hidden, `403` not allowed
- [ ] Bodies and query strings validated with Zod `safeParse`; only parsed fields reach the DB
- [ ] Owner IDs, prices, and roles taken from the session or DB, never from the body
- [ ] Retried mutations require a validated `Idempotency-Key` stored under a UNIQUE `(userId, key)` constraint
- [ ] Webhooks read `request.text()`, verify the HMAC with `timingSafeEqual` (or the provider SDK), reject stale timestamps, and dedupe on the provider event ID
- [ ] Event dispatch uses `satisfies Record<Union, Handler>`; unknown cases grant nothing, with no fallback to stored entitlement fields
- [ ] No Pages Router `config.api.bodyParser`
- [ ] Correct status codes; unexpected errors logged and answered with a generic `500`
- [ ] Cache revalidation called after mutations that affect cached pages
- [ ] Created files, env vars, DB constraints, and packages reported

## Related

- [nextjs-data-fetching.md](../nextjs-data-fetching.md#route-handlers): request parsing, status codes, streaming, CORS
- [nextjs-routing.md](../nextjs-routing.md#route-handlers): file placement
- [nextjs-caching.md](../nextjs-caching.md#revalidation): revalidating after mutations
- [nextjs-middleware.md](../nextjs-middleware.md) and [workflows/nextjs-middleware.md](nextjs-middleware.md): rate limiting and coarse auth gating in front of handlers
- [forms-server-actions.md](../forms-server-actions.md#server-actions-with-forms): Server Actions for the app's own forms
