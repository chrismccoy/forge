# React Component Patterns

Compound components and render props in full, with pointers to the remaining component patterns.

## Contents

- [Quick Reference](#quick-reference)
- [Compound Components](#compound-components)
- [Render Props Pattern](#render-props-pattern)
- [Additional React Patterns](#additional-react-patterns)

## Quick Reference

| Pattern | Use Case | Example |
|---------|----------|---------|
| Compound Components | Related components sharing state | `<Tabs><Tab /><Panel /></Tabs>` |
| Render Props | Dynamic rendering with shared logic | `<Mouse>{({x,y}) => ...}</Mouse>` |
| HOC | Cross-cutting concerns | `withAuth(Component)` |
| Custom Hooks | Stateful logic reuse | `useToggle()`, `useDebounce()` |
| Provider Pattern | Global/shared state | `<CartProvider>...</CartProvider>` |
| Controlled/Uncontrolled | Form input flexibility | `value` vs `defaultValue` |
| Prop Getters | Accessible component APIs | `getButtonProps()` |
| State Reducer | Customizable state logic | `useReducer(customReducer)` |

## Compound Components

### Basic Compound Component

Tabs follow the WAI-ARIA Tabs pattern: `tablist`/`tab`/`tabpanel` roles, `aria-selected`, `aria-controls`/`aria-labelledby` wired with `useId`, a roving `tabIndex` (only the selected tab is in the Tab order), and Left/Right/Home/End arrow-key navigation.

```tsx
import { createContext, useContext, useId, useState, type KeyboardEvent, type ReactNode } from 'react';

// Context for sharing state
interface TabsContextType {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  baseId: string;
}

const TabsContext = createContext<TabsContextType | null>(null);

function useTabsContext() {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within a Tabs provider');
  }
  return context;
}

const tabId = (baseId: string, value: string) => `${baseId}-tab-${value}`;
const panelId = (baseId: string, value: string) => `${baseId}-panel-${value}`;

// Parent component
interface TabsProps {
  defaultTab: string;
  children: ReactNode;
}

function Tabs({ defaultTab, children }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  const baseId = useId();

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab, baseId }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// Tab List: owns arrow-key navigation
interface TabListProps {
  label: string; // accessible name for the tablist
  children: ReactNode;
}

function TabList({ label, children }: TabListProps) {
  const handleKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    const tabs = Array.from(
      e.currentTarget.querySelectorAll<HTMLButtonElement>('[role="tab"]:not(:disabled)')
    );
    const index = tabs.findIndex((tab) => tab === document.activeElement);
    if (index === -1) return;

    let next: number;
    switch (e.key) {
      case 'ArrowRight':
        next = (index + 1) % tabs.length;
        break;
      case 'ArrowLeft':
        next = (index - 1 + tabs.length) % tabs.length;
        break;
      case 'Home':
        next = 0;
        break;
      case 'End':
        next = tabs.length - 1;
        break;
      default:
        return;
    }

    e.preventDefault();
    tabs[next].focus();
    tabs[next].click(); // automatic activation: selection follows focus
  };

  return (
    <div className="tab-list" role="tablist" aria-label={label} onKeyDown={handleKeyDown}>
      {children}
    </div>
  );
}

// Tab Button
interface TabProps {
  value: string;
  children: ReactNode;
}

function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab, baseId } = useTabsContext();
  const isSelected = activeTab === value;

  return (
    <button
      type="button"
      role="tab"
      id={tabId(baseId, value)}
      aria-selected={isSelected}
      aria-controls={panelId(baseId, value)}
      tabIndex={isSelected ? 0 : -1}
      onClick={() => setActiveTab(value)}
      className={isSelected ? 'active' : ''}
    >
      {children}
    </button>
  );
}

// Tab Panel: stays mounted (hidden) so every tab's aria-controls target exists
interface TabPanelProps {
  value: string;
  children: ReactNode;
}

function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab, baseId } = useTabsContext();

  return (
    <div
      role="tabpanel"
      id={panelId(baseId, value)}
      aria-labelledby={tabId(baseId, value)}
      tabIndex={0}
      hidden={activeTab !== value}
      className="tab-panel"
    >
      {children}
    </div>
  );
}

// Attach sub-components
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

export { Tabs };

// Usage (values are used in DOM ids, so keep them free of spaces)
function App() {
  return (
    <Tabs defaultTab="overview">
      <Tabs.List label="Product details">
        <Tabs.Tab value="overview">Overview</Tabs.Tab>
        <Tabs.Tab value="features">Features</Tabs.Tab>
        <Tabs.Tab value="pricing">Pricing</Tabs.Tab>
      </Tabs.List>
      <Tabs.Panel value="overview">Overview content</Tabs.Panel>
      <Tabs.Panel value="features">Features content</Tabs.Panel>
      <Tabs.Panel value="pricing">Pricing content</Tabs.Panel>
    </Tabs>
  );
}
```

**Server Components:** the compound component file is a Client Component (`'use client'`, because it uses state and context). A Server Component that imports it receives a client reference, so dot access such as `Tabs.List` does not resolve there. When the parts are used from a Server Component, export them as separate named exports and import each one:

```tsx
// Tabs.tsx ('use client')
export { Tabs, TabList, Tab, TabPanel };

// page.tsx (Server Component)
import { Tabs, TabList, Tab, TabPanel } from './Tabs';
```

Dot access is fine when the code that renders `<Tabs.List>` is itself in a client file.

### Flexible Compound Component with Slot Pattern

```tsx
import { createContext, useContext, useId, useState, ReactNode, isValidElement, Children, cloneElement } from 'react';

interface AccordionContextType {
  openItems: Set<string>;
  toggleItem: (id: string) => void;
  allowMultiple: boolean;
}

const AccordionContext = createContext<AccordionContextType | null>(null);

interface AccordionProps {
  children: ReactNode;
  allowMultiple?: boolean;
  defaultOpen?: string[];
}

function Accordion({ children, allowMultiple = false, defaultOpen = [] }: AccordionProps) {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set(defaultOpen));

  const toggleItem = (id: string) => {
    setOpenItems((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        if (!allowMultiple) next.clear();
        next.add(id);
      }
      return next;
    });
  };

  return (
    <AccordionContext.Provider value={{ openItems, toggleItem, allowMultiple }}>
      <div className="accordion">{children}</div>
    </AccordionContext.Provider>
  );
}

interface AccordionItemProps {
  id: string;
  children: ReactNode;
}

function AccordionItem({ id, children }: AccordionItemProps) {
  const context = useContext(AccordionContext);
  if (!context) throw new Error('AccordionItem must be within Accordion');

  const isOpen = context.openItems.has(id);
  // Ids that link the trigger and the panel for assistive technology
  const baseId = useId();
  const triggerId = `${baseId}-trigger`;
  const panelId = `${baseId}-panel`;

  return (
    <div className={`accordion-item ${isOpen ? 'open' : ''}`} data-state={isOpen ? 'open' : 'closed'}>
      {Children.map(children, (child) => {
        if (isValidElement(child)) {
          return cloneElement(child as React.ReactElement<AccordionSlotProps>, {
            itemId: id,
            isOpen,
            triggerId,
            panelId,
          });
        }
        return child;
      })}
    </div>
  );
}

// Props that AccordionItem injects into its children
interface AccordionSlotProps {
  itemId?: string;
  isOpen?: boolean;
  triggerId?: string;
  panelId?: string;
}

interface AccordionTriggerProps extends AccordionSlotProps {
  children: ReactNode;
}

function AccordionTrigger({ children, itemId, isOpen, triggerId, panelId }: AccordionTriggerProps) {
  const context = useContext(AccordionContext);
  if (!context || !itemId) return null;

  return (
    <button
      type="button"
      id={triggerId}
      className="accordion-trigger"
      aria-expanded={isOpen}
      aria-controls={panelId}
      onClick={() => context.toggleItem(itemId)}
    >
      {children}
      <span className="icon" aria-hidden="true">{isOpen ? '−' : '+'}</span>
    </button>
  );
}

interface AccordionContentProps extends AccordionSlotProps {
  children: ReactNode;
}

// Stays mounted (hidden) so the trigger's aria-controls target always exists
function AccordionContent({ children, isOpen, triggerId, panelId }: AccordionContentProps) {
  return (
    <div
      id={panelId}
      role="region"
      aria-labelledby={triggerId}
      hidden={!isOpen}
      className="accordion-content"
    >
      {children}
    </div>
  );
}

Accordion.Item = AccordionItem;
Accordion.Trigger = AccordionTrigger;
Accordion.Content = AccordionContent;

export { Accordion };
```

## Render Props Pattern

### Basic Render Props

```tsx
import { useState, ReactNode } from 'react';

interface ToggleRenderProps {
  on: boolean;
  toggle: () => void;
  setOn: (value: boolean) => void;
}

interface ToggleProps {
  defaultOn?: boolean;
  children: (props: ToggleRenderProps) => ReactNode;
}

function Toggle({ defaultOn = false, children }: ToggleProps) {
  const [on, setOn] = useState(defaultOn);

  const toggle = () => setOn((prev) => !prev);

  return <>{children({ on, toggle, setOn })}</>;
}

// Usage
function App() {
  return (
    <Toggle defaultOn={false}>
      {({ on, toggle }) => (
        <div>
          <p>The toggle is {on ? 'ON' : 'OFF'}</p>
          <button onClick={toggle}>Toggle</button>
        </div>
      )}
    </Toggle>
  );
}
```

### Mouse Position Tracker

```tsx
import { useState, useEffect, ReactNode } from 'react';

interface MousePosition {
  x: number;
  y: number;
}

interface MouseTrackerProps {
  children: (position: MousePosition) => ReactNode;
}

function MouseTracker({ children }: MouseTrackerProps) {
  const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return <>{children(position)}</>;
}

// Usage
function App() {
  return (
    <MouseTracker>
      {({ x, y }) => (
        <div
          style={{
            position: 'absolute',
            left: x + 10,
            top: y + 10,
            background: 'black',
            color: 'white',
            padding: '4px 8px',
            borderRadius: '4px',
          }}
        >
          {x}, {y}
        </div>
      )}
    </MouseTracker>
  );
}
```

### Data Fetching Render Props

This shows the render-prop shape. For production data fetching prefer TanStack Query or SWR; for a hand-rolled hook, see `hooks-custom-library.md` → `useFetch`.

```tsx
import { useState, useEffect, type ReactNode } from 'react';

interface FetchState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

interface FetchProps<T> {
  url: string;
  children: (state: FetchState<T>) => ReactNode;
}

function Fetch<T>({ url, children }: FetchProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    // Reset when the URL changes so the previous URL's result never shows
    setData(null);
    setLoading(true);
    setError(null);

    (async () => {
      try {
        const response = await fetch(url, { signal: controller.signal });
        if (!response.ok) throw new Error(`Failed to fetch: ${response.status}`);
        const result = (await response.json()) as T;
        if (!controller.signal.aborted) setData(result);
      } catch (err) {
        if (controller.signal.aborted) return; // AbortError or a stale failure
        setError(err instanceof Error ? err : new Error('Unknown error'));
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    })();

    // Cancels the stale request, so a slow response for an old URL cannot overwrite a newer one
    return () => controller.abort();
  }, [url, reloadKey]);

  const refetch = () => setReloadKey((k) => k + 1);

  return <>{children({ data, loading, error, refetch })}</>;
}

// Usage
interface User {
  id: string;
  name: string;
}

function UserList() {
  return (
    <Fetch<User[]> url="/api/users">
      {({ data, loading, error, refetch }) => {
        if (loading) return <p>Loading...</p>;
        if (error) return <p>Error: {error.message}</p>;

        return (
          <div>
            <button type="button" onClick={refetch}>Refresh</button>
            <ul>
              {data?.map((user) => (
                <li key={user.id}>{user.name}</li>
              ))}
            </ul>
          </div>
        );
      }}
    </Fetch>
  );
}
```

## Additional React Patterns

For when to use each pattern, see the [Quick Reference](#quick-reference) table. For full code examples of the remaining six patterns, see `patterns-hoc-provider-controlled.md`:

- **Higher-Order Components (HOC)** — function that takes a component and returns a new component with added behavior.
- **Custom Hooks as Patterns** — encapsulate stateful logic in `useX` hooks; favored over HOCs and render props in modern React.
- **Provider Pattern** — `React.createContext` plus a `useContext` consumer hook.
- **Controlled vs Uncontrolled Components** — value-driven via props vs ref-driven internal state.
- **Prop Getter Pattern** — return a `getProps()` callback that hands the consumer pre-wired props (used by Downshift, Headless UI).
- **State Reducer Pattern** — accept a reducer prop so consumers can override state transitions (Kent C. Dodds canonical implementation).
