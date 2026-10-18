# Zod 4 Schemas

Reusable Zod 4 schemas for forms, Server Actions, Route Handlers, query strings, and environment variables: formats, coercion at boundaries, unions, refinements, transforms, error formatting, and typed inputs and outputs. Load it when designing a validation layer, parsing `FormData` or `searchParams`, or fixing Zod 3 code that no longer type-checks.

## Contents

- [Quick Reference](#quick-reference)
- [Formats and Objects](#formats-and-objects)
- [Reusable Building Blocks](#reusable-building-blocks)
- [Coercion at Boundaries](#coercion-at-boundaries)
- [Unions and Recursive Schemas](#unions-and-recursive-schemas)
- [Refinements](#refinements)
- [Transforms and Input vs Output Types](#transforms-and-input-vs-output-types)
- [Error Handling](#error-handling)
- [Environment Variables](#environment-variables)
- [Best Practices](#best-practices)

## Quick Reference

| Zod 3 (do not write) | Zod 4 |
|----------------------|-------|
| `z.string().email()`, `.uuid()`, `.url()` | `z.email()`, `z.uuid()`, `z.url()` |
| `z.string().datetime()` | `z.iso.datetime()`, `z.iso.date()` |
| `{ message: '...' }`, `errorMap`, `invalid_type_error` | `{ error: '...' }` or a string shorthand: `.min(3, 'Too short')` |
| `z.object({...}).strict()` / `.passthrough()` | `z.strictObject({...})` / `z.looseObject({...})` |
| `z.record(z.string())` | `z.record(z.string(), z.string())` (key schema required) |
| `error.errors` | `error.issues` |
| `error.flatten()` / `error.format()` | `z.flattenError(error)` / `z.treeifyError(error)` |
| `z.lazy(() => ...)` for recursion | Getter on the object shape |
| `z.coerce.boolean()` for `"false"` | `z.stringbool()` |

| Need | API |
|------|-----|
| Recoverable validation (forms, actions, handlers) | `schema.safeParse(input)` |
| Fail fast (config, invariants) | `schema.parse(input)` |
| Schema with an async refinement | `safeParseAsync` / `parseAsync` |
| Type of parsed data | `z.infer<typeof S>` (same as `z.output`) |
| Type the form holds before parsing | `z.input<typeof S>` |

## Formats and Objects

```ts
import { z } from 'zod';

export const UserId = z.uuid({ error: 'Invalid user id' });
export const Email = z.email({ error: 'Enter a valid email address' });

export const Profile = z.strictObject({
  id: UserId,
  email: Email,
  website: z.url().optional(),             // undefined allowed
  bio: z.string().max(280).nullable(),     // null allowed
  avatarUrl: z.url().nullish(),            // null or undefined allowed
  locale: z.string().default('en'),        // fallback when undefined
  birthday: z.iso.date().optional(),       // "YYYY-MM-DD"
  tags: z.array(z.string().trim().min(1).max(40)).max(15),
  attributes: z.record(z.string(), z.union([z.string(), z.number(), z.boolean()])),
});

export type Profile = z.infer<typeof Profile>;
```

Use `z.strictObject` for persisted payloads, so unknown keys are rejected instead of silently stripped. `z.object` strips unknown keys, which is also safe as long as the code writes `parsed.data` and never the raw input.

## Reusable Building Blocks

Define small shared schemas once and compose them. Derive create, update, and response variants from one base object.

```ts
// lib/schemas/post.ts
import { z } from 'zod';

export const Slug = z.string().trim().toLowerCase().regex(/^[a-z0-9-]+$/, 'Use letters, numbers, and dashes');

export const PostBase = z.object({
  title: z.string().trim().min(3, 'Title must be at least 3 characters').max(200),
  slug: Slug,
  content: z.string().trim().min(1, 'Content is required').max(10_000),
  status: z.enum(['draft', 'published']),
});

export const CreatePost = PostBase;
export const UpdatePost = PostBase.partial().extend({ id: z.uuid() });
export const PostSummary = PostBase.pick({ title: true, slug: true });

export const Pagination = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});
```

- Keep cross-field refinements off the base object. Derive variants with `.pick`, `.omit`, `.partial`, or `.extend` from the plain object, then add `.refine()` to each final schema.
- Never accept `authorId`, `role`, or other ownership fields from client input. Take them from the session on the server.

## Coercion at Boundaries

`FormData`, `searchParams`, and environment variables are strings. Coerce only where data enters the app, and bound every coerced value.

```ts
import { z } from 'zod';

// "" coerces to 0 with z.coerce.number(). Map empty strings to undefined first.
const emptyToUndefined = (v: unknown) => (v === '' ? undefined : v);

export const ProductFilters = z.object({
  q: z.string().trim().max(100).optional(),
  minPrice: z.preprocess(emptyToUndefined, z.coerce.number().nonnegative().optional()),
  inStock: z.stringbool().default(false),  // "true"/"false", "1"/"0", "on"/"off", "yes"/"no"
  sort: z.enum(['price', 'newest']).catch('newest'), // fall back on unknown values
});
```

- Do not use `z.coerce.boolean()` for user input: `Boolean("false")` is `true`. Use `z.stringbool()`.
- An unchecked checkbox is absent from `FormData`. Give its schema `.default(false)` or `.optional()`.
- Read multi-value fields with `formData.getAll('tags')`. `Object.fromEntries(formData)` keeps only the last value and includes `$ACTION_*` keys added by the framework.

```ts
// Server Action input built field by field
const UploadSchema = z.object({
  title: z.string().trim().min(1).max(120),
  tags: z.array(z.string().trim().min(1)).max(10),
  file: z.file().max(5_000_000, 'Max 5 MB').mime(['image/png', 'image/jpeg', 'image/webp']),
});

const parsed = UploadSchema.safeParse({
  title: formData.get('title'),
  tags: formData.getAll('tags'),
  file: formData.get('file'),
});
```

Treat the declared MIME type as a hint. Re-check the file's bytes on the server before storing or serving it.

## Unions and Recursive Schemas

Use `z.discriminatedUnion` when variants share a literal key. Parsing is faster and errors point at the right variant.

```ts
import { z } from 'zod';

export const PaymentMethod = z.discriminatedUnion('type', [
  z.object({ type: z.literal('card'), last4: z.string().regex(/^\d{4}$/) }),
  z.object({ type: z.literal('paypal'), email: z.email() }),
  z.object({ type: z.literal('wire'), iban: z.string().min(15).max(34) }),
]);
type PaymentMethod = z.infer<typeof PaymentMethod>;

function describe(method: PaymentMethod): string {
  switch (method.type) {
    case 'card':
      return `Card ending ${method.last4}`;
    case 'paypal':
      return `PayPal (${method.email})`;
    case 'wire':
      return 'Bank transfer';
    default: {
      const unreachable: never = method; // compile error if a variant is unhandled
      return unreachable;
    }
  }
}
```

Define recursive schemas with a getter. The inferred type is recursive without a manual annotation.

```ts
export const Category = z.object({
  id: z.string(),
  name: z.string(),
  get children() {
    return z.array(Category);
  },
});
export type Category = z.infer<typeof Category>;
```

## Refinements

Use `.refine` with `error` and `path` for one rule. Use `.superRefine` when one check can raise several issues.

```ts
import { z } from 'zod';

export const Register = z
  .object({
    email: z.email(),
    password: z.string().min(12, 'Use at least 12 characters'),
    confirmPassword: z.string(),
  })
  .refine((d) => d.password === d.confirmPassword, {
    error: 'Passwords do not match',
    path: ['confirmPassword'],
  });

export const DateRange = z
  .object({ from: z.iso.date(), to: z.iso.date(), maxDays: z.number().int().positive() })
  .superRefine((d, ctx) => {
    if (d.to < d.from) {
      ctx.addIssue({ code: 'custom', path: ['to'], message: 'End date must be after start date' });
    }
    const days = (Date.parse(d.to) - Date.parse(d.from)) / 86_400_000;
    if (days > d.maxDays) {
      ctx.addIssue({ code: 'custom', path: ['to'], message: `Range is limited to ${d.maxDays} days` });
    }
  });
```

An async refinement (a uniqueness check against the database) forces `safeParseAsync`. Calling `safeParse` on that schema throws. Keep such checks on the server, and still enforce uniqueness with a database constraint, because the check and the insert can race.

```ts
const Username = z
  .string()
  .regex(/^[a-z0-9_]{3,20}$/)
  .refine(async (name) => !(await db.users.exists({ username: name })), {
    error: 'Username is taken',
  });

const result = await Username.safeParseAsync(formData.get('username'));
```

## Transforms and Input vs Output Types

`.transform` changes the output type. `.pipe` validates the transformed value with a second schema.

```ts
export const Tags = z
  .string()
  .transform((s) => s.split(',').map((t) => t.trim()).filter(Boolean))
  .pipe(z.array(z.string().max(30)).max(10));

type TagsIn = z.input<typeof Tags>;   // string
type TagsOut = z.output<typeof Tags>; // string[]
```

With React Hook Form, the form holds input values and `handleSubmit` receives output values. Recent `@hookform/resolvers` versions infer both from the resolver; when passing generics, pass both:

```tsx
const ProfileForm = z.object({
  name: z.string().trim().min(2, 'Name is too short'),
  age: z.coerce.number().int().min(18, 'You must be 18 or older'),
});

const form = useForm<z.input<typeof ProfileForm>, unknown, z.output<typeof ProfileForm>>({
  resolver: zodResolver(ProfileForm),
  defaultValues: { name: '', age: '' },
});
```

Form wiring, field components, and accessible error display: [forms.md](forms.md#with-zod-validation).

## Error Handling

```ts
import { z } from 'zod';

const result = CreatePost.safeParse(input);

if (!result.success) {
  // Flat forms: { formErrors: string[], fieldErrors: { title?: string[], ... } }
  const { fieldErrors, formErrors } = z.flattenError(result.error);

  // Nested objects and arrays: { errors, properties: { address: { properties: { zip: { errors } } } } }
  const tree = z.treeifyError(result.error);

  // Logs and CLI output: a readable multi-line string
  console.error(z.prettifyError(result.error));

  // Raw issues: { code, path, message, ... }[]
  for (const issue of result.error.issues) {
    // issue.path is (string | number)[]
  }
}
```

- Return `fieldErrors` to the client, not raw `issues`: issues can echo the submitted values and internal paths.
- Map field errors to `aria-invalid` and `aria-describedby` on the input. See [forms-server-actions.md](forms-server-actions.md#server-actions-with-forms).
- Use `parse` (throwing) only where failure is a bug, such as config at startup.

## Environment Variables

Validate environment variables once, at startup, in a server-only module.

```ts
// lib/env.ts
import 'server-only';
import { z } from 'zod';

const ServerEnv = z.object({
  DATABASE_URL: z.url(),
  AUTH_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  RATE_LIMIT_PER_MINUTE: z.coerce.number().int().positive().default(60),
});

export const env = ServerEnv.parse(process.env);
```

```ts
// lib/public-env.ts — safe to import from Client Components
import { z } from 'zod';

// Next.js inlines NEXT_PUBLIC_ values only for literal property access.
// Do not pass process.env as a whole or read it with a computed key.
export const publicEnv = z
  .object({ NEXT_PUBLIC_API_URL: z.url() })
  .parse({ NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL });
```

Never put a secret in a `NEXT_PUBLIC_` variable: its value is embedded in the browser bundle at build time.

## Best Practices

| Practice | Why |
|----------|-----|
| Validate on the server even when the client validates | Client checks are a UX aid; the server is the boundary |
| Define schemas once and share them between client and server | One contract, no drift |
| Coerce only at boundaries, and bound every coerced value | Coercion hides bad upstream data |
| Use `z.stringbool()` for boolean strings | `z.coerce.boolean()` turns `"false"` into `true` |
| Write `parsed.data`, never the raw input | Unknown keys and ownership fields never reach the database |
| Use `z.discriminatedUnion` for tagged variants | Precise errors and exhaustive narrowing |
| Use `z.input`/`z.output` when a schema transforms | Form state and submitted data have different types |
| Use `safeParseAsync` for async refinements | `safeParse` throws on them |
