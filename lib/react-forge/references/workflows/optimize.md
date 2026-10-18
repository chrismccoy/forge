# Workflow: Optimize React Component Performance

Analyze and optimize a React component for better performance.

## Instructions

Analyze and optimize the specified React component:

1. **Measure First**
   - Read the component file specified in the request
   - Profile the interaction that feels slow with the React DevTools Profiler (enable "Record why each component rendered"); use why-did-you-render if needed to see which renders are avoidable
   - Identify the actual hotspot: which component renders too often or takes too long per render, and why
   - Check whether React Compiler (`babel-plugin-react-compiler`) is enabled in the build config. If it is, skip manual `memo`/`useMemo`/`useCallback`; the compiler already memoizes. Focus on structural fixes instead
   - If there is no measurable problem, report that and stop. Do not add memoization speculatively

2. **Common Issues to Check**
   - State held higher than it needs to be (colocate it with the component that uses it)
   - Expensive computations repeated on every render of a measured hotspot
   - Large component bundles (code splitting opportunities)
   - Missing keys or unstable keys in lists
   - Long lists rendered in full (virtualization candidates)
   - Urgent and non-urgent updates mixed together (transition candidates)
   - Video/media element re-render issues (see below)

   **Video/Media Element Checks**:
   - `<video>` elements with unstable keys (e.g., array index, or a key that changes with unrelated state). A changed `key`, or a different element/component type at the same position, remounts the element and restarts decoding; a plain re-render does not
   - Video playback controlled via state and props instead of refs. Use `useRef` to control play/pause/seek imperatively
   - Video player components re-rendering on every parent update, when the Profiler shows this is costly. Fix with state colocation first; use `React.memo` (with stable props) only for that measured case
   - Multiple simultaneous video elements exceeding mobile hardware decoder limits (often only a few concurrent decoders)
   - Missing `playsInline` attribute for iOS Safari compatibility
   - Videos loading outside viewport. Use Intersection Observer for lazy loading

3. **Optimization Techniques** (apply where measurement points, roughly in this order)
   - For the full impact-ranked checklist (waterfalls, bundle size, server work, client fetching, re-renders, rendering, JS hot paths), work through `references/performance-rules.md` from the top and stop where the profile stops pointing
   - Move state down, or lift content up by passing expensive subtrees as `children`
   - Implement code splitting with `React.lazy`
   - Add virtualization for long lists
   - Use `useTransition` or `useDeferredValue` for non-urgent updates
   - Without React Compiler, and only for a measured hotspot: `React.memo` at a boundary whose props can be kept stable, `useMemo` for an expensive computation, `useCallback` for a callback passed to a memoized child or used as an effect dependency

4. **Report Format**
   - List identified issues, with the profiling evidence for each
   - Provide optimized code
   - Explain each optimization
   - Note any trade-offs

## Analysis Checklist

### Re-render Prevention
```tsx
// Before - typing in the input re-renders the whole page
function Page() {
  const [query, setQuery] = useState('');
  return (
    <>
      <input value={query} onChange={(e) => setQuery(e.target.value)} />
      <ExpensiveChart />
    </>
  );
}

// After - state colocated; ExpensiveChart no longer re-renders on keystrokes
function SearchInput() {
  const [query, setQuery] = useState('');
  return <input value={query} onChange={(e) => setQuery(e.target.value)} />;
}

function Page() {
  return (
    <>
      <SearchInput />
      <ExpensiveChart />
    </>
  );
}
```

### Callback Stability (only when the child is memoized)
```tsx
// Inline callbacks are fine by default. Stabilize one only when it is passed
// to a component wrapped in memo (a measured hotspot) or used as an effect dependency.
const handleItemClick = useCallback((id: string) => {
  handleClick(id);
}, [handleClick]);
<MemoizedList onItemClick={handleItemClick} />
```

### Expensive Computation (only when measured)
```tsx
// Before - mutates the items prop in place on every render
const sortedItems = items.sort((a, b) => a.name.localeCompare(b.name));

// After - copy before sorting; wrap in useMemo only if the Profiler shows the sort is costly
const sortedItems = useMemo(
  () => [...items].sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);
```

### Component Memoization (only at a measured, stable-prop boundary)
```tsx
// Wrap in memo only when the Profiler shows this component re-rendering
// with unchanged props and those renders are expensive. memo has no effect
// if the parent passes new objects or functions on every render.
const ExpensiveList = memo(function ExpensiveList({ items }: Props) { ... });
```

### Code Splitting
```tsx
// Before - imported directly
import HeavyEditor from './HeavyEditor';

// After - lazy loaded
const HeavyEditor = lazy(() => import('./HeavyEditor'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyEditor />
    </Suspense>
  );
}
```

### List Virtualization
```tsx
// Before - renders all items
{items.map(item => <Item key={item.id} {...item} />)}

// After - virtualized with react-window 2.x
import { List, type RowComponentProps } from 'react-window';

function Row({ index, style, ariaAttributes, items }: RowComponentProps<{ items: ItemData[] }>) {
  return <Item style={style} {...ariaAttributes} {...items[index]} />;
}

<List
  rowComponent={Row}
  rowCount={items.length}
  rowHeight={50}
  rowProps={{ items }}
  style={{ height: 400 }}
/>
```

For variable heights, interaction, and library choice, see [performance-virtualization.md](../performance-virtualization.md).

### Non-Urgent Updates
```tsx
// Before - blocks UI
setSearchResults(results);

// After - non-blocking
startTransition(() => {
  setSearchResults(results);
});
```

## Output Format

After analysis, provide:

1. **Issues Found**
   - List each performance issue with severity (High/Medium/Low) and the measurement that shows it

2. **Optimized Code**
   - Show the optimized component code

3. **Changes Made**
   - Explain each optimization applied

4. **Additional Recommendations**
   - Suggest further improvements if applicable
