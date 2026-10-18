# React Performance

## Contents

- [Core Workflow](#core-workflow)
- [Key Gotchas](#key-gotchas)
- [Quick Reference](#quick-reference)
- [Measuring Performance](#measuring-performance)
- [Memoization](#memoization)
- [Code Splitting](#code-splitting)
- [List Virtualization](#list-virtualization)
- [Avoiding Unnecessary Renders](#avoiding-unnecessary-renders)
- [Concurrent Features](#concurrent-features)
- [Image Optimization](#image-optimization)
- [Bundle Optimization](#bundle-optimization)
- [Media Element Performance](#media-element-performance)
- [Additional References](#additional-references)

## Core Workflow

1. Measure first with React DevTools Profiler, Web Vitals, browser performance tools, or a bundle analyzer before changing code.
2. Identify the bottleneck class: unnecessary re-renders, expensive calculations, large lists, large bundles, slow interactions, image/media loading, or state placed too high.
3. Apply the smallest targeted fix: state colocation, composition, memoization, virtualization, lazy loading, dynamic import, or concurrent rendering APIs.
4. For media-heavy UIs, protect video element identity, avoid remounting, use refs for imperative controls, and lazy-load sources with IntersectionObserver.
5. Re-measure after each change and keep only optimizations that improve duration, Web Vitals, memory, decoder churn, or bundle size.

## Key Gotchas

- Memoization has overhead; use `React.memo`, `useMemo`, and `useCallback` for measured hotspots or stable prop boundaries, not everywhere.
- Custom `React.memo` comparisons can be slower than rendering if they perform deep equality on large structures.
- Index keys in filtered/reordered lists can cause remounts and state loss, especially costly for video elements.
- Video elements are stateful browser resources; remounting can destroy hardware decoders and buffered playback state.
- Concurrent features improve responsiveness but do not make expensive work disappear; they schedule non-urgent work.

## Quick Reference

| Issue | Solution |
|-------|----------|
| Unnecessary re-renders | State colocation, composition (`children`); `React.memo` only at a measured, stable-prop boundary |
| Expensive computations | `useMemo` when profiling shows the computation is costly |
| Large bundles | Code splitting, `React.lazy` |
| Long lists | Virtualization (`react-window`, `react-virtuoso`) |
| Slow state updates | `useTransition`, `useDeferredValue` |
| Image performance | Lazy loading, responsive images |
| State too high | State colocation |

With React Compiler (`babel-plugin-react-compiler`) enabled, manual `memo`, `useMemo`, and `useCallback` are mostly unnecessary; the compiler memoizes automatically.

| Tool | Purpose |
|------|---------|
| React DevTools Profiler | Component render timing |
| `web-vitals` | CLS, INP, LCP, FCP, TTFB |
| Bundle analyzer | Identify large dependencies |

## Measuring Performance

### React DevTools Profiler

```tsx
// Wrap components with Profiler for measurement
import { Profiler, ProfilerOnRenderCallback } from 'react';

const onRenderCallback: ProfilerOnRenderCallback = (
  id,
  phase,
  actualDuration,
  baseDuration,
  startTime,
  commitTime
) => {
  console.log({
    id,
    phase,
    actualDuration, // Time spent rendering
    baseDuration,   // Estimated time without memoization
    startTime,
    commitTime,
  });
};

function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <MainContent />
    </Profiler>
  );
}
```

### Web Vitals

```tsx
import { onCLS, onINP, onLCP, onFCP, onTTFB, type Metric } from 'web-vitals';

function reportWebVitals(metric: Metric) {
  // Send to analytics; keepalive lets the request finish if the page is unloading
  fetch('/api/analytics', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(metric),
    keepalive: true,
  });
}

onCLS(reportWebVitals);  // Cumulative Layout Shift
onINP(reportWebVitals);  // Interaction to Next Paint
onLCP(reportWebVitals);  // Largest Contentful Paint
onFCP(reportWebVitals);  // First Contentful Paint
onTTFB(reportWebVitals); // Time to First Byte
```

## Memoization

Do not memoize by default. Profile first, and reach for `React.memo`, `useMemo`, or `useCallback` only when the Profiler shows a specific component or computation is a hotspot, or when a memoized boundary needs stable props to work. If React Compiler is enabled, skip manual memoization. The examples below show how to apply each tool once that evidence exists.

### React.memo

```tsx
import { memo, useState } from 'react';

// Memoized component - only re-renders when props change
const ExpensiveList = memo(function ExpensiveList({
  items,
  onItemClick,
}: {
  items: Item[];
  onItemClick: (id: string) => void;
}) {
  console.log('ExpensiveList rendered');

  return (
    <ul>
      {items.map((item) => (
        <li key={item.id} onClick={() => onItemClick(item.id)}>
          {item.name}
        </li>
      ))}
    </ul>
  );
});

// With custom comparison. Deep comparisons such as JSON.stringify can cost
// more than the render they skip; measure before keeping one.
const DeepCompareList = memo(
  function DeepCompareList({ data }: { data: ComplexData }) {
    return <div>{/* render */}</div>;
  },
  (prevProps, nextProps) => {
    // Return true if props are equal (skip re-render)
    return JSON.stringify(prevProps.data) === JSON.stringify(nextProps.data);
  }
);
```

### useMemo for Expensive Computations

```tsx
import { useMemo, useState } from 'react';

function DataTable({ data, filters, sortConfig }: Props) {
  // Memoize filtered data
  const filteredData = useMemo(() => {
    console.log('Filtering data...');
    return data.filter((item) => {
      return Object.entries(filters).every(([key, value]) => {
        if (!value) return true;
        return item[key]?.toLowerCase().includes(value.toLowerCase());
      });
    });
  }, [data, filters]);

  // Memoize sorted data
  const sortedData = useMemo(() => {
    console.log('Sorting data...');
    if (!sortConfig.key) return filteredData;

    return [...filteredData].sort((a, b) => {
      const aVal = a[sortConfig.key];
      const bVal = b[sortConfig.key];

      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [filteredData, sortConfig]);

  // Memoize statistics
  const stats = useMemo(() => {
    // Guard the empty case: dividing by 0 gives NaN and Math.max() gives -Infinity
    if (sortedData.length === 0) return { total: 0, average: 0, max: 0 };
    return {
      total: sortedData.length,
      average: sortedData.reduce((sum, item) => sum + item.value, 0) / sortedData.length,
      max: sortedData.reduce((m, item) => Math.max(m, item.value), -Infinity),
    };
  }, [sortedData]);

  return (
    <div>
      <Stats data={stats} />
      <Table data={sortedData} />
    </div>
  );
}
```

### useCallback for Stable Function References

```tsx
import { useCallback, useState, memo } from 'react';

// Child already wrapped in memo because profiling showed its renders are costly.
// useCallback matters only because of that memo boundary.
const SearchInput = memo(function SearchInput({
  onSearch,
}: {
  onSearch: (query: string) => void;
}) {
  console.log('SearchInput rendered');
  return <input onChange={(e) => onSearch(e.target.value)} />;
});

function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Result[]>([]);

  // Stable callback reference
  const handleSearch = useCallback((searchQuery: string) => {
    setQuery(searchQuery);
    // Perform search...
  }, []);

  // Without useCallback, SearchInput would re-render on every parent render
  return (
    <div>
      <SearchInput onSearch={handleSearch} />
      <ResultsList results={results} />
    </div>
  );
}
```

## Code Splitting

### React.lazy and Suspense

```tsx
import { lazy, Suspense } from 'react';

// Lazy load components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Analytics = lazy(() => import('./pages/Analytics'));

// With named exports
const Chart = lazy(() =>
  import('./components/Charts').then((module) => ({
    default: module.PieChart,
  }))
);

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/analytics" element={<Analytics />} />
      </Routes>
    </Suspense>
  );
}
```

### Preloading a Route Chunk on Hover

```tsx
import { lazy, type ReactNode } from 'react';

// One loader for both lazy() and preloading; the bundler caches the module,
// so calling it again on hover or focus does not refetch
const loadDashboard = () => import('./pages/Dashboard');
export const DashboardPage = lazy(loadDashboard); // render in your route config

// Use your router's link component (React Router or Next.js `Link`) in place of <a>;
// the preload handlers are the same
function DashboardLink({ children }: { children: ReactNode }) {
  return (
    <a href="/dashboard" onMouseEnter={loadDashboard} onFocus={loadDashboard}>
      {children}
    </a>
  );
}
```

### Component-Level Splitting

```tsx
import { lazy, Suspense, useState } from 'react';

// Heavy component loaded only when needed
const RichTextEditor = lazy(() => import('./components/RichTextEditor'));
const ImageEditor = lazy(() => import('./components/ImageEditor'));

function CreatePost() {
  const [showEditor, setShowEditor] = useState(false);
  const [showImageEditor, setShowImageEditor] = useState(false);

  return (
    <div>
      <button onClick={() => setShowEditor(true)}>Open Editor</button>

      {showEditor && (
        <Suspense fallback={<EditorSkeleton />}>
          <RichTextEditor />
        </Suspense>
      )}

      <button onClick={() => setShowImageEditor(true)}>Edit Image</button>

      {showImageEditor && (
        <Suspense fallback={<ImageEditorSkeleton />}>
          <ImageEditor />
        </Suspense>
      )}
    </div>
  );
}
```

## List Virtualization

Virtualize when a list or grid renders hundreds of rows or more and profiling shows rendering or scrolling cost from the off-screen rows. For a few dozen rows, plain rendering is simpler and keeps native find-in-page, scrolling, and accessibility behavior. Virtualization removes off-screen rows from the DOM, so in-page search and screen readers only see the rendered window; give the list an accessible name and announce the total count where it matters.

Which library:

- **react-window**: small and fast for fixed or known row heights (2.x API with `List`/`Grid`, `rowComponent`, and `rowProps`).
- **react-virtuoso**: measures variable heights automatically and has built-in grouping, sticky headers, and endless scrolling (`endReached`).
- **@tanstack/react-virtual**: headless; the app renders the markup, which suits tables and custom layouts.

Setup, dynamic row heights, grids, infinite loading, and accessibility details are in `performance-virtualization.md`.

## Avoiding Unnecessary Renders

### State Colocation

```tsx
// Bad - state too high in tree
function App() {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <div>
      <Header /> {/* Re-renders when searchQuery changes */}
      <SearchSection query={searchQuery} setQuery={setSearchQuery} />
      <Footer /> {/* Re-renders when searchQuery changes */}
    </div>
  );
}

// Good - state colocated with usage
function App() {
  return (
    <div>
      <Header />
      <SearchSection /> {/* Manages its own state */}
      <Footer />
    </div>
  );
}

function SearchSection() {
  const [searchQuery, setSearchQuery] = useState('');
  return (
    <div>
      <input value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
      <SearchResults query={searchQuery} />
    </div>
  );
}
```

### Children as Props

```tsx
// Bad - the expensive content is created inside the stateful component,
// so every position change re-renders ExpensiveContent
function DraggablePanel() {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  return (
    <div
      style={{ left: position.x, top: position.y }}
      onPointerMove={(e) => setPosition({ x: e.clientX, y: e.clientY })}
    >
      <ExpensiveContent /> {/* Re-renders on every pointer move */}
    </div>
  );
}

// Good - the parent creates the expensive content and passes it as children.
// When DraggablePanel's state changes, the children element is the same
// object from the parent's last render, so React skips re-rendering it.
function DraggablePanel({ children }: { children: React.ReactNode }) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  return (
    <div
      style={{ left: position.x, top: position.y }}
      onPointerMove={(e) => setPosition({ x: e.clientX, y: e.clientY })}
    >
      {children}
    </div>
  );
}

function Page() {
  return (
    <DraggablePanel>
      <ExpensiveContent /> {/* Does not re-render when position changes */}
    </DraggablePanel>
  );
}
```

### Composition Pattern

```tsx
// Bad - entire tree re-renders
function SlowComponent({ isOpen }: { isOpen: boolean }) {
  const [count, setCount] = useState(0);
  const [items] = useState(generateLargeList());

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
      <ExpensiveTree items={items} /> {/* Re-renders on count change */}
    </div>
  );
}

// Good - expensive component isolated
function FastComponent() {
  return (
    <div>
      <Counter />
      <ExpensiveTreeWrapper />
    </div>
  );
}

function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>;
}

function ExpensiveTreeWrapper() {
  const [items] = useState(generateLargeList());
  return <ExpensiveTree items={items} />;
}
```

## Concurrent Features

### useTransition for Non-Blocking Updates

Keep two pieces of state: the input value updates urgently, and the value the slow list reads updates inside the transition. The slow list is wrapped in `memo` so that urgent renders (which only change `inputValue`) skip it; without that boundary it would re-render with the old `listQuery` on every keystroke anyway.

```tsx
import { useState, useTransition, memo } from 'react';

const SlowList = memo(function SlowList({ text }: { text: string }) {
  const items = [];
  for (let i = 0; i < 10000; i++) {
    items.push(<li key={i}>{text}</li>);
  }
  return <ul>{items}</ul>;
});

function SearchWithTransition() {
  const [inputValue, setInputValue] = useState('');
  const [listQuery, setListQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;

    // Urgent update - keep the input responsive
    setInputValue(value);

    // Non-urgent update - can be interrupted by further typing
    startTransition(() => {
      setListQuery(value);
    });
  };

  return (
    <div>
      <input value={inputValue} onChange={handleChange} />
      <div style={{ opacity: isPending ? 0.7 : 1 }}>
        <SlowList text={listQuery} />
      </div>
    </div>
  );
}
```

### useDeferredValue for Deferred Rendering

```tsx
import { useState, useDeferredValue, memo } from 'react';

const SearchResults = memo(function SearchResults({ query }: { query: string }) {
  // Expensive search/filter operation
  const results = expensiveSearch(query);
  return (
    <ul>
      {results.map((result) => (
        <li key={result.id}>{result.name}</li>
      ))}
    </ul>
  );
});

function SearchWithDeferredValue() {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query);

  // Show stale indicator
  const isStale = query !== deferredQuery;

  return (
    <div>
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search..."
      />
      <div style={{ opacity: isStale ? 0.7 : 1 }}>
        <SearchResults query={deferredQuery} />
      </div>
    </div>
  );
}
```

## Image Optimization

Framework-agnostic patterns for plain `<img>` and `<picture>`. For `next/image` sizing, the LCP image, and image config, see [nextjs-performance.md](nextjs-performance.md#images).

### Lazy Loading Images

```tsx
function LazyImage({ src, alt, ...props }: React.ImgHTMLAttributes<HTMLImageElement>) {
  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      decoding="async"
      {...props}
    />
  );
}

// With placeholder
function OptimizedImage({ src, alt, width, height }: Props) {
  const [isLoaded, setIsLoaded] = useState(false);

  return (
    <div style={{ position: 'relative', width, height }}>
      {!isLoaded && <div className="placeholder skeleton" />}
      <img
        src={src}
        alt={alt}
        loading="lazy"
        onLoad={() => setIsLoaded(true)}
        style={{ opacity: isLoaded ? 1 : 0 }}
      />
    </div>
  );
}
```

### Responsive Images

```tsx
function ResponsiveImage({ src, alt }: { src: string; alt: string }) {
  return (
    <picture>
      <source
        media="(max-width: 640px)"
        srcSet={`${src}?w=640 1x, ${src}?w=1280 2x`}
      />
      <source
        media="(max-width: 1024px)"
        srcSet={`${src}?w=1024 1x, ${src}?w=2048 2x`}
      />
      <img
        src={`${src}?w=1920`}
        alt={alt}
        loading="lazy"
        decoding="async"
      />
    </picture>
  );
}
```

## Bundle Optimization

For `next analyze`, `@next/bundle-analyzer`, `next/dynamic`, and `optimizePackageImports`, see [nextjs-performance.md](nextjs-performance.md#bundle-size).

### Analyzing Bundle

```bash
# With webpack
npx webpack-bundle-analyzer stats.json

# With Vite
npx vite-bundle-analyzer
```

### Tree Shaking

```tsx
// Bad - imports entire library
import _ from 'lodash';
const sorted = _.sortBy(items, 'name');

// Good - import only what you need
import sortBy from 'lodash/sortBy';
const sorted = sortBy(items, 'name');

// Best - use native methods when possible
const sorted = [...items].sort((a, b) => a.name.localeCompare(b.name));
```

### Dynamic Imports

```tsx
// Load heavy libraries on demand
async function handleExport() {
  const { jsPDF } = await import('jspdf');
  const doc = new jsPDF();
  doc.text('Hello world!', 10, 10);
  doc.save('document.pdf');
}

async function handleChart() {
  const { Chart } = await import('chart.js/auto');
  new Chart(ctx, config);
}
```

## Media Element Performance

Video and audio elements (stable keys, refs, portals, lazy video, mobile attributes, decoder limits) are covered in [media-video.md](media-video.md).

## Additional References

For comprehensive guides on specific optimization techniques, see:

- `performance-virtualization.md` - Complete guide to virtualized lists with react-window, react-virtuoso, and @tanstack/react-virtual
- `media-video.md` - Video and audio element performance: preventing remounts, ref-based control, portals, lazy loading with IntersectionObserver, mobile attributes, and limiting simultaneous decoders
- `nextjs-performance.md` - Next.js-specific images (`next/image`), fonts, scripts, and bundle analysis
