# shadcn/ui

shadcn/ui with the `shadcn` 4.x CLI, Tailwind CSS 4, and React 19: setup, theming, safe customization, composition, forms, accessibility, and Server Component boundaries. Load it when adding or customizing shadcn/ui components, building forms or data tables with them, or wiring dark mode.

## Contents

- [Quick Reference](#quick-reference)
- [What shadcn/ui Is](#what-shadcnui-is)
- [Setup](#setup)
- [components.json](#componentsjson)
- [File Layout](#file-layout)
- [Theming](#theming)
- [Customizing Components](#customizing-components)
- [Composing Components](#composing-components)
- [Data Tables](#data-tables)
- [Forms](#forms)
- [Accessibility](#accessibility)
- [Server Component Boundary](#server-component-boundary)
- [Dark Mode](#dark-mode)
- [Registries, MCP, and Monorepos](#registries-mcp-and-monorepos)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Command or pattern |
|------|--------------------|
| Initialize | `npx shadcn@latest init` |
| Scaffold a new app | `npx shadcn@latest init -t vite` (pick a template) |
| Add components | `npx shadcn@latest add button dialog field` |
| Preview changes before overwrite | `npx shadcn@latest add button --diff` |
| Re-add over local edits | `npx shadcn@latest add button --overwrite` |
| List or search a registry | `npx shadcn@latest search @shadcn -q table` |
| Run a migration | `npx shadcn@latest migrate --list` |
| Toasts | `sonner` (the old `toast` component is deprecated) |

## What shadcn/ui Is

shadcn/ui is a set of component source files that the CLI copies into the project. It is not a runtime dependency upgraded with `npm update`; after `add`, the code belongs to the project to read, edit, and test.

- Components are built on an accessible primitive library (Radix UI by default; Base UI and React Aria are offered as alternative bases at `init`) and styled with Tailwind utilities and CSS variables.
- Current components use React 19 patterns: plain function components that take `ref` as a regular prop, no `forwardRef`, and a `data-slot` attribute on every part for styling hooks.
- Variants are defined with `class-variance-authority`; classes merge through `cn()` (`clsx` + `tailwind-merge`). See [styling-tailwind.md](styling-tailwind.md#composing-classes).

Because the project owns the code, upstream fixes do not arrive automatically. Re-add a component with `--diff` to see what changed, then merge by hand.

## Setup

Set up Tailwind CSS 4 first ([styling-tailwind.md](styling-tailwind.md#setup)) and configure the `@/*` path alias in `tsconfig.json` (and `tsconfig.app.json` for Vite).

```bash
npx shadcn@latest init                     # existing project: components.json, lib/utils.ts, theme CSS
npx shadcn@latest init --preset <code> -t vite  # new app; preset from ui.shadcn.com/create
npx shadcn@latest add button card dialog dropdown-menu field input sonner
```

Useful `init` flags: `-b, --base <radix|base|aria>`, `-d, --defaults`, `--monorepo`, `--rtl`, `--no-css-variables`. Useful `add` flags: `-y`, `-o, --overwrite`, `-p, --path`, `--dry-run`, `--diff`, `-a, --all`.

For Vite, also add `resolve.alias: { '@': path.resolve(__dirname, './src') }` to `vite.config.ts` (and `@types/node`).

## components.json

`components.json` tells the CLI where to put files and how to transform them. Commit it.

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": { "config": "", "css": "app/globals.css", "baseColor": "neutral", "cssVariables": true },
  "aliases": {
    "components": "@/components",
    "ui": "@/components/ui",
    "utils": "@/lib/utils",
    "hooks": "@/hooks"
  },
  "registries": { "@acme": "https://registry.acme.com/{name}.json" }
}
```

| Field | Notes |
|-------|-------|
| `style` | `new-york`; the old `default` style is deprecated. Cannot change after init |
| `rsc` | `true` makes the CLI add `"use client"` to components that need it. Set `false` for Vite SPAs |
| `tailwind.css`, `tailwind.config` | CSS entry the CLI writes tokens into; leave `config` `""` for Tailwind 4 |
| `tailwind.baseColor` | Neutral palette for tokens. Cannot change after init (use `migrate base-color`) |
| `tailwind.cssVariables` | Keep `true` to get semantic tokens (`bg-primary`) instead of inline palette classes |
| `aliases` | Import roots the CLI writes into generated files; must match `tsconfig` paths |
| `registries` | Namespaced third-party or private registries (`@acme/login-form`); values support `${ENV_VAR}` |

## File Layout

```text
src/
├── components/
│   ├── ui/                 # CLI-owned primitives: button.tsx, dialog.tsx, field.tsx ...
│   ├── theme-provider.tsx  # app-level wrappers
│   └── invoice-dialog.tsx  # product components composed from ui/
├── lib/utils.ts            # cn()
└── app/globals.css         # @import "tailwindcss"; tokens; @custom-variant dark
```

Keep `components/ui` close to upstream. Put product-specific compositions outside it so re-adding a primitive never clobbers feature code.

## Theming

`init` writes semantic tokens in OKLCH to the CSS entry: raw values in `:root` and `.dark`, mapped into Tailwind with `@theme inline`.

```css
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  /* card, popover, secondary, muted, accent, destructive,
     border, input, ring, chart-1..5, sidebar-* */

  /* Added token: define in :root and .dark, expose in @theme inline */
  --warning: oklch(0.84 0.16 84);
  --warning-foreground: oklch(0.28 0.07 46);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --warning: oklch(0.41 0.11 46);
  --warning-foreground: oklch(0.99 0.02 95);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
  --radius-lg: var(--radius);
}
```

Use the added token as `bg-warning text-warning-foreground`. Change the brand by editing token values, not component classes; every component follows. Chart colors are referenced as `var(--chart-1)` directly, with no `hsl()` wrapper.

## Customizing Components

A generated primitive looks like this (trimmed):

```tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { Slot } from 'radix-ui';
import { cn } from '@/lib/utils';

const buttonVariants = cva('inline-flex items-center gap-2 rounded-md text-sm font-medium outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:opacity-50 ...', {
  variants: {
    variant: { default: 'bg-primary text-primary-foreground hover:bg-primary/90', outline: '...', ghost: '...' },
    size: { default: 'h-9 px-4 py-2', sm: 'h-8 px-3', icon: 'size-9' },
  },
  defaultVariants: { variant: 'default', size: 'default' },
});

function Button({ className, variant, size, asChild = false, ...props }:
  React.ComponentProps<'button'> & VariantProps<typeof buttonVariants> & { asChild?: boolean }) {
  const Comp = asChild ? Slot.Root : 'button';
  return <Comp data-slot="button" className={cn(buttonVariants({ variant, size, className }))} {...props} />;
}

export { Button, buttonVariants };
```

No `forwardRef`: `ref` arrives in `props` and is spread onto the element.

Customize in this order, from least to most invasive:

1. **Tokens.** Change `--primary`, `--radius`, etc. in CSS.
2. **`className` at the call site.** `cn()` lets the caller override any class: `<Button className="w-full">`.
3. **Add a variant** to the `cva` config in `components/ui/button.tsx` (`variant: { success: 'bg-success ...' }`). Keep the existing ones intact.
4. **Wrap** in a product component that constrains props (see [styling-tailwind.md](styling-tailwind.md#design-system)).
5. **Edit structure** only when the above cannot express the change, and note the edit at the top of the file so the next `add --overwrite` is reviewed.

Target parts from a parent with `data-slot` instead of class names: `className="*:data-[slot=card-header]:pb-2"`. Use `asChild` (Radix base) to render a primitive's behavior on a custom element, such as a router link styled as a button: `<Button asChild><Link href="/login">Log in</Link></Button>`. With the Base UI base, primitives use a `render` prop instead of `asChild`; follow the docs for the base recorded in the project.

## Composing Components

Compose primitives into product components. Keep state at the composition level, and pass `open`/`onOpenChange` only when something outside the component must control it.

### Dialog with a form

```tsx
'use client';

// imports: useState, and Button, Dialog*, Input, Label from '@/components/ui/*'

export function RenameDialog({ name, rename }: { name: string; rename: (formData: FormData) => Promise<void> }) {
  const [open, setOpen] = useState(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild><Button variant="outline">Rename</Button></DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Rename project</DialogTitle>
          <DialogDescription>The new name is visible to all members.</DialogDescription>
        </DialogHeader>
        <form action={async (fd) => { await rename(fd); setOpen(false); }} className="grid gap-4">
          <Label htmlFor="rename-name">Name</Label>
          <Input id="rename-name" name="name" defaultValue={name} required />
          <DialogFooter>
            <DialogClose asChild><Button type="button" variant="outline">Cancel</Button></DialogClose>
            <Button type="submit">Save</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

`rename` can be a Server Action passed from a Server Component page.

Every `DialogContent` needs a `DialogTitle`. If the design has no visible title, wrap it in `sr-only` rather than omitting it. Use `AlertDialog` for destructive confirmations; it does not close on outside click.

### DropdownMenu

```tsx
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="ghost" size="icon" aria-label="Row actions">
      <MoreHorizontal aria-hidden />
    </Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent align="end">
    <DropdownMenuItem onSelect={() => copyId(row.id)}>Copy ID</DropdownMenuItem>
    <DropdownMenuSeparator />
    <DropdownMenuItem variant="destructive" onSelect={() => setConfirmOpen(true)}>
      Delete
    </DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>

```

For a command palette, render `CommandDialog` with `CommandInput`, `CommandList`, `CommandEmpty`, `CommandGroup`, and `CommandItem onSelect`; it filters and handles arrow keys itself. To open a dialog from a menu item, lift the dialog's `open` state above both and render the dialog outside the menu; a dialog nested in `DropdownMenuContent` unmounts when the menu closes.

### Sonner toasts

Mount `<Toaster />` from `@/components/ui/sonner` once in the root layout, then call `toast` from client code:

```tsx
import { toast } from 'sonner';

toast.success('Invoice sent');
toast.error('Could not send invoice', { description: error.message });
toast.promise(sendInvoice(id), { loading: 'Sending...', success: 'Sent', error: 'Failed' });
```

Toasts are announced politely to screen readers and disappear. Never put the only copy of an error or a required action in a toast.

## Data Tables

Combine the `table` component (markup only) with TanStack Table 9 (logic). Install with `npx shadcn@latest add table` and `npm install @tanstack/react-table`. TanStack Table 9 requires registering the features a table uses.

```tsx
// data-table.tsx
'use client';

import { useState } from 'react';
import {
  createSortedRowModel, rowSortingFeature, sortFn_alphanumeric, tableFeatures, useTable,
  type ColumnDef, type RowData, type SortingState,
} from '@tanstack/react-table';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';

// Only registered features are bundled
export const features = tableFeatures({
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
  sortFns: { alphanumeric: sortFn_alphanumeric },
});
export type DataTableFeatures = typeof features;

type DataTableProps<TData extends RowData> = {
  columns: ColumnDef<DataTableFeatures, TData>[];
  data: TData[];
};

export function DataTable<TData extends RowData>({ columns, data }: DataTableProps<TData>) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const table = useTable({ features, data, columns, onSortingChange: setSorting, state: { sorting } });

  return (
    <div className="overflow-hidden rounded-md border">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((group) => (
            <TableRow key={group.id}>
              {group.headers.map((header) => (
                <TableHead key={header.id}>
                  {header.isPlaceholder ? null : <table.FlexRender header={header} />}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.map((row) => (
            <TableRow key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>
                  <table.FlexRender cell={cell} />
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
```

Render a `No results.` row with `colSpan={columns.length}` when `rows` is empty. Define columns in a client module with `createColumnHelper<DataTableFeatures, Payment>()` and `columnHelper.columns([...])`. Make sortable headers real buttons (`<Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}>`). Fetch data in a Server Component page and pass it as a prop. For thousands of rows, paginate or virtualize ([performance-virtualization.md](performance-virtualization.md)).

## Forms

The current shadcn form pattern pairs React Hook Form's `Controller` with the `Field` components (`npx shadcn@latest add field`). `Field` handles layout and labels; wire `id`, `htmlFor`, and `aria-invalid` explicitly. See [forms.md](forms.md) for React Hook Form, Server Actions, and validation in depth.

```tsx
'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { Controller, useForm } from 'react-hook-form';
import { toast } from 'sonner';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Field, FieldDescription, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field';
import { Input } from '@/components/ui/input';

const schema = z.object({
  email: z.email({ error: 'Enter a valid email address' }),
});

type Values = z.infer<typeof schema>;

export function InviteForm({ onInvite }: { onInvite: (v: Values) => Promise<void> }) {
  const form = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { email: '' },
  });

  async function onSubmit(values: Values) {
    await onInvite(values);
    toast.success(`Invited ${values.email}`);
    form.reset();
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} noValidate>
      <FieldGroup>
        <Controller
          name="email"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor="invite-email">Email</FieldLabel>
              <Input {...field} id="invite-email" type="email" autoComplete="email" aria-invalid={fieldState.invalid} />
              <FieldDescription>We send the invitation here.</FieldDescription>
              {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
            </Field>
          )}
        />
        <Button type="submit" disabled={form.formState.isSubmitting}>Send invite</Button>
      </FieldGroup>
    </form>
  );
}
```

- Use Zod 4 APIs: top-level `z.email()`, `z.url()`, `z.uuid()`, and the `error` option for messages (not `message` or `errorMap`).
- Group radios and checkboxes with `FieldSet` and `FieldLegend`; use `<Field orientation="horizontal">` for a control beside its label.
- For non-input controls (`Select`, `Checkbox`, `Switch`), map `field.value`/`field.onChange` to the component's `value`/`onValueChange` or `checked`/`onCheckedChange`, and put the `id` on the trigger.
- Projects initialized earlier may have the older `Form`, `FormField`, `FormItem`, `FormControl`, `FormMessage` wrappers, which wire ARIA automatically through context. They still work; do not mix both patterns in one form.

## Accessibility

The primitives handle focus trapping and restoration in dialogs and sheets, roving focus and typeahead in menus, `Escape` to close, `aria-expanded`/`aria-controls` on triggers, and portal rendering for overlays. Do not re-implement any of that. The app remains responsible for:

- **Names.** Every `DialogContent`/`SheetContent` has a Title (use `sr-only` if hidden) and preferably a Description. Icon-only buttons get `aria-label`, and the icon gets `aria-hidden`.
- **Labels.** Every input has a `FieldLabel`/`Label` with `htmlFor` matching the control's `id`. A placeholder is not a label.
- **Errors.** Set `aria-invalid` on the control and render the message in `FieldError` next to it.
- **Triggers.** Pass a real `<button>` or link to `asChild`; never a `div`.
- **Contrast.** Check every changed token pair, in both themes ([styling-tailwind.md](styling-tailwind.md#accessibility)).
- **Motion.** Overlay animations come from `tw-animate-css`; add `motion-reduce:animate-none` where they are large or long.

## Server Component Boundary

With `rsc: true`, the CLI adds `"use client"` to every component that uses state, effects, or context (Dialog, DropdownMenu, Sheet, Command, Select, Tabs, Sonner, Form). Static ones (Card, Badge, Table, Separator, Skeleton) stay server-safe. Check the first line of the file in `components/ui` when unsure.

Keep pages and layouts as Server Components. Fetch data there and import interactive shadcn pieces as client leaves:

```tsx
// app/invoices/page.tsx: Server Component; the imported leaves are 'use client' modules
import { columns } from './columns';
import { DataTable } from './data-table';
import { NewInvoiceDialog } from './new-invoice-dialog';

export default async function InvoicesPage() {
  const invoices = await getInvoices();
  return (
    <section className="grid gap-4">
      <h1 className="text-2xl font-semibold">Invoices</h1>
      <NewInvoiceDialog />
      <DataTable columns={columns} data={invoices} />
    </section>
  );
}
```

- Do not add `"use client"` to a page just because it renders a Dialog; extract the dialog into its own client file.
- Props crossing into a client component must be serializable. Pass data and Server Actions, not functions defined in the server file.
- Pass server-rendered content into client wrappers as `children` (for example, a server-rendered list inside a `Sheet`).

See [nextjs-data-fetching.md](nextjs-data-fetching.md) for data loading in Server Components.

## Dark Mode

Components read semantic tokens, so dark mode only needs the `.dark` class on `<html>`. In Next.js, use `next-themes`:

```tsx
// components/theme-provider.tsx (npm install next-themes)
'use client';

import { ThemeProvider as NextThemesProvider } from 'next-themes';

export function ThemeProvider(props: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props} />;
}

// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

`next-themes` injects a blocking script that sets the class before paint, which changes `<html>` before hydration; `suppressHydrationWarning` on `<html>` covers only that element. See [react-19-upgrade.md](react-19-upgrade.md#hydration-mismatches).

```tsx
// components/mode-toggle.tsx
'use client';

import { Moon, Sun } from 'lucide-react';
import { useTheme } from 'next-themes';
import { Button } from '@/components/ui/button';

export function ModeToggle() {
  const { resolvedTheme, setTheme } = useTheme();

  return (
    <Button
      variant="outline"
      size="icon"
      aria-label="Toggle dark mode"
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
    >
      <Sun aria-hidden className="size-4 dark:hidden" />
      <Moon aria-hidden className="hidden size-4 dark:block" />
    </Button>
  );
}
```

For a light/dark/system choice, put `DropdownMenuRadioGroup value={theme} onValueChange={setTheme}` in a `DropdownMenu`. The icon swap uses CSS (`dark:hidden`), so the server and first client render match. `theme` is `undefined` on the server; do not branch markup on it before mount. For Vite, React Router, or TanStack Start, use the inline-script approach in [styling-tailwind.md](styling-tailwind.md#dark-mode).

## Registries, MCP, and Monorepos

- **Registries.** Install from any namespaced registry configured in `components.json`: `npx shadcn@latest add @acme/login-form`. Build a custom registry with `npx shadcn@latest build` (outputs to `public/r`). Review third-party registry code before adding it; it lands in the project's source tree.
- **MCP.** `npx shadcn@latest mcp init --client claude` registers the shadcn MCP server in `.mcp.json`, letting an assistant browse and install registry items.
- **Monorepos.** `init --monorepo` creates a shared `packages/ui` workspace and an app workspace, each with its own `components.json`. Run `add` from the repo root with `-c apps/web`; the CLI places primitives in the shared package and rewrites imports.

## Best Practices

- Treat `components/ui` as vendored code: small, reviewed edits only, and diff before `--overwrite`.
- Customize through tokens, `className`, and added variants before editing component structure.
- Compose product components outside `components/ui`; keep pages as Server Components and import interactive pieces as client leaves.
- Use `Field` + `Controller` with Zod 4 schemas for forms, with a label, `aria-invalid`, and an inline error for every field.
- Give every dialog and sheet a title, every icon button an `aria-label`, and every `asChild` a real interactive element.
- Use `sonner` for toasts and `tw-animate-css` for animations; remove `toast` and `tailwindcss-animate` from older projects.
- Set the theme before paint (`next-themes` or an inline script) and switch theme-dependent icons with `dark:` classes.
