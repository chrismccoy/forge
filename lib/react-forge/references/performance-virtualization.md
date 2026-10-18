# React Virtualization Guide

Complete guide to virtualized lists for handling large datasets efficiently.

## Contents

- [Why Virtualization?](#why-virtualization)
- [Libraries Comparison](#libraries-comparison)
- [react-window Implementation](#react-window-implementation)
- [react-virtuoso Implementation](#react-virtuoso-implementation)
- [@tanstack/react-virtual (Headless)](#tanstackreact-virtual-headless)
- [Performance Tips](#performance-tips)

## Why Virtualization?

Rendering every row of a long list costs DOM nodes, layout, and React work proportional to the list length. Virtualization renders only the visible rows plus a small overscan buffer, so render cost stays roughly constant as the list grows. Measure before and after with the React DevTools Profiler and the browser Performance panel on the real data; gains depend on row complexity and device.

## Libraries Comparison

| Library | Features | Best For |
|---------|----------|----------|
| react-window (2.x) | Fixed, function-based, or dynamic row heights; grids | Simple lists and grids |
| react-virtuoso | Auto-sizing, grouping, tables, reverse/chat lists | Complex lists |
| @tanstack/react-virtual | Headless, flexible | Custom implementations |

## react-window Implementation

This section targets react-window 2.x. Version 2 replaced the 1.x fixed- and variable-size list and grid components with `List` and `Grid`, replaced render-prop children and `itemData` with `rowComponent`/`rowProps` (or `cellComponent`/`cellProps`), and ships its own TypeScript types.

### Installation

```bash
npm install react-window
# TypeScript types are bundled; do not install @types/react-window (that package is for 1.x)
```

### List - Basic Usage

```tsx
import { List, type RowComponentProps } from 'react-window';

interface Item {
  id: string;
  name: string;
  email: string;
}

// Row receives index, style, ariaAttributes, plus everything in rowProps
function Row({ index, style, ariaAttributes, users }: RowComponentProps<{ users: Item[] }>) {
  const item = users[index];

  return (
    <div style={style} {...ariaAttributes} className="flex items-center px-4 border-b">
      <span className="flex-1">{item.name}</span>
      <span className="text-gray-500">{item.email}</span>
    </div>
  );
}

function UserList({ users }: { users: Item[] }) {
  return (
    <List
      rowComponent={Row}
      rowCount={users.length}
      rowHeight={50}          // Row height in pixels
      rowProps={{ users }}    // Extra props passed to Row
      style={{ height: 600 }} // List fills this height (or its parent's)
    />
  );
}
```

### List - With Interaction

```tsx
import { List, type RowComponentProps } from 'react-window';
import { useState } from 'react';

interface Item {
  id: string;
  name: string;
  status: 'active' | 'inactive';
}

interface RowData {
  items: Item[];
  onSelect: (item: Item) => void;
  onDelete: (id: string) => void;
  selectedId: string | null;
}

function Row({
  index,
  style,
  ariaAttributes,
  items,
  onSelect,
  onDelete,
  selectedId,
}: RowComponentProps<RowData>) {
  const item = items[index];
  const isSelected = item.id === selectedId;

  return (
    <div
      style={style}
      {...ariaAttributes}
      className={`flex items-center px-4 border-b cursor-pointer ${
        isSelected ? 'bg-blue-100' : 'hover:bg-gray-50'
      }`}
      onClick={() => onSelect(item)}
    >
      <span className="flex-1 font-medium">{item.name}</span>
      <span
        className={`px-2 py-1 rounded text-sm ${
          item.status === 'active'
            ? 'bg-green-100 text-green-800'
            : 'bg-gray-100 text-gray-600'
        }`}
      >
        {item.status}
      </span>
      <button
        className="ml-2 p-1 text-red-500 hover:text-red-700"
        onClick={(e) => {
          e.stopPropagation();
          onDelete(item.id);
        }}
      >
        Delete
      </button>
    </div>
  );
}

function InteractiveList({ items }: { items: Item[] }) {
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const handleSelect = (item: Item) => setSelectedId(item.id);
  const handleDelete = (id: string) => {
    // Handle deletion
  };

  // List re-renders rows when values in rowProps change; there is no need
  // to wrap rowProps in useMemo.
  return (
    <List
      rowComponent={Row}
      rowCount={items.length}
      rowHeight={56}
      rowProps={{ items, onSelect: handleSelect, onDelete: handleDelete, selectedId }}
      style={{ height: 400 }}
    />
  );
}
```

### List - Variable and Dynamic Heights

When the height can be computed from the data, pass a function. It receives the index and `rowProps`:

```tsx
import { List, type RowComponentProps } from 'react-window';

interface Message {
  id: string;
  text: string;
  sender: string;
  timestamp: Date;
}

type RowData = { messages: Message[] };

function MessageRow({ index, style, ariaAttributes, messages }: RowComponentProps<RowData>) {
  const message = messages[index];

  return (
    <div style={style} {...ariaAttributes} className="px-4 py-2">
      <div className="flex justify-between">
        <span className="font-medium">{message.sender}</span>
        <span className="text-gray-400 text-sm">
          {message.timestamp.toLocaleTimeString()}
        </span>
      </div>
      <p className="text-gray-700">{message.text}</p>
    </div>
  );
}

// Estimate height from content: base height + lines of text
function getRowHeight(index: number, { messages }: RowData) {
  const lines = Math.ceil(messages[index].text.length / 60);
  return 40 + lines * 24;
}

function ChatMessages({ messages }: { messages: Message[] }) {
  return (
    <List
      rowComponent={MessageRow}
      rowCount={messages.length}
      rowHeight={getRowHeight}
      rowProps={{ messages }}
      style={{ height: 500 }}
    />
  );
}
```

When heights are only known after rendering, use the `useDynamicRowHeight` cache. The list measures rendered rows with a ResizeObserver. This is less efficient than known sizes, so prefer a number or function when possible:

```tsx
import { List, useDynamicRowHeight } from 'react-window';

function ChatMessagesMeasured({ messages }: { messages: Message[] }) {
  const rowHeight = useDynamicRowHeight({ defaultRowHeight: 64 });

  return (
    <List
      rowComponent={MessageRow}
      rowCount={messages.length}
      rowHeight={rowHeight}
      rowProps={{ messages }}
      style={{ height: 500 }}
    />
  );
}
```

### Scrolling Imperatively

```tsx
import { List, useListRef } from 'react-window';

function JumpableList({ messages }: { messages: Message[] }) {
  const listRef = useListRef(null);

  return (
    <>
      <button
        onClick={() =>
          listRef.current?.scrollToRow({ index: messages.length - 1, align: 'end' })
        }
      >
        Jump to latest
      </button>
      <List
        listRef={listRef}
        rowComponent={MessageRow}
        rowCount={messages.length}
        rowHeight={getRowHeight}
        rowProps={{ messages }}
        style={{ height: 500 }}
      />
    </>
  );
}
```

### Grid - 2D Virtualization

```tsx
import { Grid, type CellComponentProps } from 'react-window';

interface Product {
  id: string;
  name: string;
  price: number;
  image: string;
}

type CellData = { products: Product[]; columns: number };

function Cell({
  columnIndex,
  rowIndex,
  style,
  ariaAttributes,
  products,
  columns,
}: CellComponentProps<CellData>) {
  const product = products[rowIndex * columns + columnIndex];

  if (!product) return <div style={style} />;

  return (
    <div style={style} {...ariaAttributes} className="p-2">
      <div className="border rounded-lg p-4 h-full">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-32 object-cover rounded"
        />
        <h3 className="mt-2 font-medium">{product.name}</h3>
        <p className="text-green-600">${product.price}</p>
      </div>
    </div>
  );
}

function ProductGrid({ products }: { products: Product[] }) {
  const columns = 4;
  const rows = Math.ceil(products.length / columns);

  // Unlike List rows, Grid cell sizes must be known ahead of time
  return (
    <Grid
      cellComponent={Cell}
      cellProps={{ products, columns }}
      columnCount={columns}
      columnWidth={200}
      rowCount={rows}
      rowHeight={250}
      style={{ height: 600, width: 800 }}
    />
  );
}
```

## react-virtuoso Implementation

### Installation

```bash
npm install react-virtuoso
```

### Basic List - Auto Height

```tsx
import { Virtuoso } from 'react-virtuoso';

interface Item {
  id: string;
  title: string;
  description: string;
}

function AutoSizeList({ items }: { items: Item[] }) {
  return (
    <Virtuoso
      style={{ height: 600 }}
      data={items}
      itemContent={(index, item) => (
        <div className="p-4 border-b">
          <h3 className="font-medium">{item.title}</h3>
          <p className="text-gray-600">{item.description}</p>
        </div>
      )}
    />
  );
}
```

### Infinite Scroll

`endReached` can fire again before the previous request finishes, so guard with a ref (state updates are not visible until the next render), stop when there is nothing more to load, and surface failures with a retry instead of swallowing them.

```tsx
import { Virtuoso } from 'react-virtuoso';
import { useRef, useState } from 'react';

interface Item {
  id: string;
  name: string;
}

const PAGE_SIZE = 20;

async function fetchItems(offset: number, limit: number): Promise<Item[]> {
  const res = await fetch(`/api/items?offset=${offset}&limit=${limit}`);
  if (!res.ok) throw new Error(`Failed to load items (${res.status})`);
  return res.json();
}

interface FooterContext {
  hasMore: boolean;
  isLoading: boolean;
  error: Error | null;
  onRetry: () => void;
}

// Defined at module level so Virtuoso does not remount it on every render;
// it reads list state through Virtuoso's `context` prop
function Footer({ context }: { context?: FooterContext }) {
  if (!context) return null;
  const { hasMore, isLoading, error, onRetry } = context;

  if (error) {
    return (
      <div role="alert" className="p-4 text-center">
        <p>Could not load more items.</p>
        <button type="button" onClick={onRetry}>Try again</button>
      </div>
    );
  }
  if (isLoading) {
    return <div role="status" className="p-4 text-center">Loading more...</div>;
  }
  if (!hasMore) {
    return <div className="p-4 text-center text-gray-500">No more items</div>;
  }
  return null;
}

// initialItems is the first page, loaded by the parent (or on the server)
function InfiniteList({ initialItems }: { initialItems: Item[] }) {
  const [items, setItems] = useState(initialItems);
  const [hasMore, setHasMore] = useState(initialItems.length === PAGE_SIZE);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const loadingRef = useRef(false); // in-flight guard, updated synchronously

  async function loadMore() {
    if (loadingRef.current || !hasMore) return;
    loadingRef.current = true;
    setIsLoading(true);
    setError(null);

    try {
      const newItems = await fetchItems(items.length, PAGE_SIZE);
      setItems((prev) => [...prev, ...newItems]);
      if (newItems.length < PAGE_SIZE) setHasMore(false);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load items'));
    } finally {
      loadingRef.current = false;
      setIsLoading(false);
    }
  }

  return (
    <Virtuoso
      style={{ height: 600 }}
      data={items}
      // Do not auto-retry on scroll after a failure; the footer offers a retry button
      endReached={hasMore && !error ? loadMore : undefined}
      itemContent={(index, item) => (
        <div className="p-4 border-b">{item.name}</div>
      )}
      context={{ hasMore, isLoading, error, onRetry: loadMore }}
      components={{ Footer }}
    />
  );
}
```

### Grouped List

```tsx
import { GroupedVirtuoso } from 'react-virtuoso';

interface Contact {
  name: string;
  email: string;
}

interface ContactGroup {
  letter: string;
  contacts: Contact[];
}

function GroupedContactList({ groups }: { groups: ContactGroup[] }) {
  const groupCounts = groups.map((g) => g.contacts.length);
  const allContacts = groups.flatMap((g) => g.contacts);

  return (
    <GroupedVirtuoso
      style={{ height: 600 }}
      groupCounts={groupCounts}
      groupContent={(index) => (
        <div className="bg-gray-100 px-4 py-2 font-bold sticky top-0">
          {groups[index].letter}
        </div>
      )}
      itemContent={(index) => (
        <div className="px-4 py-3 border-b">
          <div className="font-medium">{allContacts[index].name}</div>
          <div className="text-gray-500 text-sm">{allContacts[index].email}</div>
        </div>
      )}
    />
  );
}
```

### Virtuoso Table

```tsx
import { TableVirtuoso } from 'react-virtuoso';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive';
}

function VirtualTable({ users }: { users: User[] }) {
  return (
    <TableVirtuoso
      style={{ height: 500 }}
      data={users}
      fixedHeaderContent={() => (
        <tr className="bg-gray-100">
          <th className="px-4 py-2 text-left">Name</th>
          <th className="px-4 py-2 text-left">Email</th>
          <th className="px-4 py-2 text-left">Role</th>
          <th className="px-4 py-2 text-left">Status</th>
        </tr>
      )}
      itemContent={(index, user) => (
        <>
          <td className="px-4 py-2 border-b">{user.name}</td>
          <td className="px-4 py-2 border-b">{user.email}</td>
          <td className="px-4 py-2 border-b">{user.role}</td>
          <td className="px-4 py-2 border-b">
            <span
              className={`px-2 py-1 rounded text-sm ${
                user.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-gray-100'
              }`}
            >
              {user.status}
            </span>
          </td>
        </>
      )}
    />
  );
}
```

## @tanstack/react-virtual (Headless)

### Installation

```bash
npm install @tanstack/react-virtual
```

### Custom Implementation

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

interface Item {
  id: string;
  name: string;
  description: string;
}

function HeadlessList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80, // Estimated row height
    overscan: 5, // Buffer items
  });

  return (
    <div
      ref={parentRef}
      className="h-[600px] overflow-auto"
    >
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => {
          const item = items[virtualRow.index];

          return (
            <div
              key={virtualRow.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
              className="p-4 border-b"
            >
              <h3 className="font-medium">{item.name}</h3>
              <p className="text-gray-600">{item.description}</p>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

### Dynamic Measurement

```tsx
import { useRef } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';

function DynamicHeightList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    measureElement: (element) => element.getBoundingClientRect().height,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            data-index={virtualRow.index}
            ref={virtualizer.measureElement}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            {/* Content with dynamic height */}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Performance Tips

### 1. Keep Row Components Cheap

Rows mount and unmount constantly while scrolling, so per-row cost matters more than in a normal list. Keep row markup shallow, avoid per-row effects and data fetching, and pass data in through `rowProps` rather than having each row subscribe to a store. Profile scrolling before reaching for `memo`; react-window 2.x already re-renders rows only when `rowProps` values or the visible range change.

### 2. Define Row Components at Module Level

```tsx
// BAD - a new component type every render remounts every visible row
function UserList({ users }: { users: Item[] }) {
  const Row = ({ index, style }: RowComponentProps) => <div style={style}>{users[index].name}</div>;
  return <List rowComponent={Row} rowCount={users.length} rowHeight={50} rowProps={{}} />;
}

// GOOD - stable component, data passed through rowProps
function Row({ index, style, users }: RowComponentProps<{ users: Item[] }>) {
  return <div style={style}>{users[index].name}</div>;
}

function UserList({ users }: { users: Item[] }) {
  return <List rowComponent={Row} rowCount={users.length} rowHeight={50} rowProps={{ users }} />;
}
```

### 3. Prefer Known Sizes

A numeric `rowHeight`, or a function that derives height from data, avoids measurement work. Use `useDynamicRowHeight` only when height genuinely depends on rendered content.

### 4. Use CSS for Styling

```tsx
// Inline style objects are fine in most components; inside very large or
// frequently re-rendered rows, prefer classes for static styling
<div className="text-red-500 p-2">
```

### 5. Let the List Size Itself

react-window 2.x `List` and `Grid` fill the height of their `style` or parent container and observe resizes themselves, so there is no need for a window-resize listener or an AutoSizer wrapper:

```tsx
function ResponsiveList({ users }: { users: Item[] }) {
  return (
    <div className="h-screen">
      <List rowComponent={Row} rowCount={users.length} rowHeight={50} rowProps={{ users }} />
    </div>
  );
}
```

Use the `onResize` prop to get the measured size.
