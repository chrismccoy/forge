# React Patterns: HOC, Custom Hooks, Provider, Controlled, Prop Getter, State Reducer

Full code examples for HOC, custom-hook-as-pattern, Provider pattern, controlled vs uncontrolled components, prop getter, and state reducer. `patterns.md` keeps compound-components and render-props in full; this reference holds the remaining six patterns.

## Contents

- [Higher-Order Components (HOC)](#higher-order-components-hoc)
- [Custom Hooks as Patterns](#custom-hooks-as-patterns)
- [Provider Pattern](#provider-pattern)
- [Controlled vs Uncontrolled Components](#controlled-vs-uncontrolled-components)
- [Prop Getter Pattern](#prop-getter-pattern)
- [State Reducer Pattern](#state-reducer-pattern)

## Higher-Order Components (HOC)

### Basic HOC

```tsx
import { ComponentType } from 'react';

interface WithLoadingProps {
  isLoading: boolean;
}

function withLoading<P extends object>(
  WrappedComponent: ComponentType<P>
) {
  return function WithLoadingComponent(props: P & WithLoadingProps) {
    const { isLoading, ...rest } = props;

    if (isLoading) {
      return <div className="loading-spinner">Loading...</div>;
    }

    return <WrappedComponent {...(rest as P)} />;
  };
}

// Usage
interface UserListProps {
  users: User[];
}

function UserList({ users }: UserListProps) {
  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

const UserListWithLoading = withLoading(UserList);

// In parent component
<UserListWithLoading isLoading={loading} users={users} />
```

### HOC with Injected Props

```tsx
import { ComponentType, useEffect, useState } from 'react';

interface User {
  id: string;
  name: string;
  email: string;
}

interface WithUserProps {
  user: User | null;
  userLoading: boolean;
}

function withUser<P extends WithUserProps>(
  WrappedComponent: ComponentType<P>
) {
  return function WithUserComponent(
    props: Omit<P, keyof WithUserProps>
  ) {
    const [user, setUser] = useState<User | null>(null);
    const [userLoading, setUserLoading] = useState(true);

    // In production prefer TanStack Query/SWR or a shared useFetch (see hooks-custom-library.md)
    useEffect(() => {
      const controller = new AbortController();

      fetch('/api/me', { signal: controller.signal })
        .then((res) => {
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          return res.json() as Promise<User>;
        })
        .then((data) => {
          if (!controller.signal.aborted) setUser(data);
        })
        .catch((err: unknown) => {
          if (err instanceof DOMException && err.name === 'AbortError') return;
          setUser(null);
        })
        .finally(() => {
          if (!controller.signal.aborted) setUserLoading(false);
        });

      // Abort on unmount so a late response never updates an unmounted component
      return () => controller.abort();
    }, []);

    return (
      <WrappedComponent
        {...(props as P)}
        user={user}
        userLoading={userLoading}
      />
    );
  };
}

// Usage
interface ProfileProps extends WithUserProps {
  showAvatar?: boolean;
}

function Profile({ user, userLoading, showAvatar = true }: ProfileProps) {
  if (userLoading) return <div>Loading user...</div>;
  if (!user) return <div>Not logged in</div>;

  return (
    <div>
      {showAvatar && <img src={`/avatars/${user.id}`} alt="" />}
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}

const ProfileWithUser = withUser(Profile);
```

### Composing Multiple HOCs

```tsx
import { ComponentType } from 'react';

// Utility for composing HOCs
function compose<P>(...hocs: Array<(c: ComponentType<any>) => ComponentType<any>>) {
  return (Component: ComponentType<P>) =>
    hocs.reduceRight((acc, hoc) => hoc(acc), Component);
}

// Usage
const EnhancedComponent = compose(
  withLoading,
  withUser,
  withTheme
)(BaseComponent);
```

## Custom Hooks as Patterns

### useToggle

The canonical `useToggle` (returns `value`, `toggle`, `setTrue`, `setFalse`, `setValue`) is in [hooks-custom-library.md](hooks-custom-library.md#usetoggle---boolean-state-with-named-actions). Usage as a pattern:

```tsx
import { useToggle } from '@/hooks/useToggle';

// Usage
function Modal() {
  const { value: isOpen, toggle, setFalse: close } = useToggle();

  return (
    <>
      <button onClick={toggle}>Open Modal</button>
      {isOpen && (
        <div className="modal">
          <button onClick={close}>Close</button>
        </div>
      )}
    </>
  );
}
```

### useDisclosure

```tsx
import { useId, useState } from 'react';

interface UseDisclosureReturn {
  isOpen: boolean;
  onOpen: () => void;
  onClose: () => void;
  onToggle: () => void;
  getDisclosureProps: () => { 'aria-expanded': boolean; 'aria-controls': string };
  getContentProps: () => { id: string; hidden: boolean };
}

function useDisclosure(
  { id: idProp, defaultOpen = false }: { id?: string; defaultOpen?: boolean } = {}
): UseDisclosureReturn {
  // useId gives a stable, SSR-safe id; pass `id` only to match an existing element
  const generatedId = useId();
  const id = idProp ?? generatedId;
  const [isOpen, setIsOpen] = useState(defaultOpen);

  const onOpen = () => setIsOpen(true);
  const onClose = () => setIsOpen(false);
  const onToggle = () => setIsOpen((prev) => !prev);

  const getDisclosureProps = () => ({
    'aria-expanded': isOpen,
    'aria-controls': `${id}-content`,
  });

  const getContentProps = () => ({
    id: `${id}-content`,
    hidden: !isOpen,
  });

  return {
    isOpen,
    onOpen,
    onClose,
    onToggle,
    getDisclosureProps,
    getContentProps,
  };
}
```

### useClickOutside

A ref-returning hook is a common custom-hook pattern. Use the canonical `useClickOutside` from `hooks-custom-library.md` instead of writing another copy:

```tsx
import { useState } from 'react';
import { useClickOutside } from './hooks/useClickOutside'; // copied from hooks-custom-library.md

function Dropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const ref = useClickOutside<HTMLDivElement>(() => setIsOpen(false));

  return (
    <div ref={ref}>
      <button type="button" aria-expanded={isOpen} onClick={() => setIsOpen(true)}>
        Open
      </button>
      {isOpen && <div className="dropdown-menu">Menu content</div>}
    </div>
  );
}
```

## Provider Pattern

### Context with Reducer

```tsx
import { createContext, useContext, useReducer, ReactNode, Dispatch } from 'react';

// Types
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: Omit<CartItem, 'quantity'> }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' };

// Reducer
function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingItem = state.items.find((item) => item.id === action.payload.id);

      if (existingItem) {
        const items = state.items.map((item) =>
          item.id === action.payload.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
        return { items, total: calculateTotal(items) };
      }

      const items = [...state.items, { ...action.payload, quantity: 1 }];
      return { items, total: calculateTotal(items) };
    }
    case 'REMOVE_ITEM': {
      const items = state.items.filter((item) => item.id !== action.payload);
      return { items, total: calculateTotal(items) };
    }
    case 'UPDATE_QUANTITY': {
      const items = state.items.map((item) =>
        item.id === action.payload.id
          ? { ...item, quantity: action.payload.quantity }
          : item
      );
      return { items, total: calculateTotal(items) };
    }
    case 'CLEAR_CART':
      return { items: [], total: 0 };
    default:
      return state;
  }
}

function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Context
interface CartContextType {
  state: CartState;
  dispatch: Dispatch<CartAction>;
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
}

const CartContext = createContext<CartContextType | null>(null);

// Provider
function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [], total: 0 });

  const addItem = (item: Omit<CartItem, 'quantity'>) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
  };

  const removeItem = (id: string) => {
    dispatch({ type: 'REMOVE_ITEM', payload: id });
  };

  const updateQuantity = (id: string, quantity: number) => {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { id, quantity } });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  return (
    <CartContext.Provider
      value={{ state, dispatch, addItem, removeItem, updateQuantity, clearCart }}
    >
      {children}
    </CartContext.Provider>
  );
}

// Hook
function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}

export { CartProvider, useCart };
```

## Controlled vs Uncontrolled Components

### Controlled Input

```tsx
import { useState, ChangeEvent } from 'react';

function ControlledInput() {
  const [value, setValue] = useState('');

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setValue(e.target.value);
  };

  return (
    <input
      type="text"
      value={value}
      onChange={handleChange}
      placeholder="Controlled input"
    />
  );
}
```

### Uncontrolled Input

```tsx
import { useRef, FormEvent } from 'react';

function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    console.log('Value:', inputRef.current?.value);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input ref={inputRef} type="text" defaultValue="" />
      <button type="submit">Submit</button>
    </form>
  );
}
```

### Hybrid Controlled/Uncontrolled Component

```tsx
import { useState, type ChangeEvent } from 'react';

interface InputProps {
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
}

function Input({ value: controlledValue, defaultValue = '', onChange }: InputProps) {
  const [internalValue, setInternalValue] = useState(defaultValue);

  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;

    if (!isControlled) {
      setInternalValue(newValue);
    }

    onChange?.(newValue);
  };

  return <input type="text" value={value} onChange={handleChange} />;
}

// Usage - Controlled
function ControlledUsage() {
  const [value, setValue] = useState('');
  return <Input value={value} onChange={setValue} />;
}

// Usage - Uncontrolled
function UncontrolledUsage() {
  return <Input defaultValue="initial" onChange={console.log} />;
}
```

## Prop Getter Pattern

A prop getter returns every prop an element needs (role, ARIA state, ids, handlers), so consumers spread one object and cannot forget the accessibility wiring. This `useSelect` follows the WAI-ARIA select-only combobox pattern: focus stays on the combobox, `aria-activedescendant` points at the highlighted option, and the keyboard supports ArrowDown/ArrowUp, Home/End, Enter/Space, Escape, and Tab. For production, prefer a headless library such as Downshift or React Aria, which also handle typeahead, scrolling the highlighted option into view, and screen-reader quirks.

```tsx
import { useId, useState, type HTMLAttributes, type KeyboardEvent, type MouseEvent } from 'react';

interface UseSelectReturn<T> {
  selectedItem: T | null;
  isOpen: boolean;
  highlightedIndex: number;
  getLabelProps: () => HTMLAttributes<HTMLElement>;
  getComboboxProps: () => HTMLAttributes<HTMLDivElement>;
  getMenuProps: () => HTMLAttributes<HTMLUListElement>;
  getItemProps: (options: { item: T; index: number }) => HTMLAttributes<HTMLLIElement>;
}

function useSelect<T extends { id: string; label: string }>(
  items: T[]
): UseSelectReturn<T> {
  const [selectedItem, setSelectedItem] = useState<T | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);

  const baseId = useId();
  const labelId = `${baseId}-label`;
  const menuId = `${baseId}-menu`;
  const optionId = (index: number) => `${baseId}-option-${index}`;

  const selectedIndex = selectedItem
    ? items.findIndex((item) => item.id === selectedItem.id)
    : -1;
  const lastIndex = items.length - 1;

  const open = (index: number) => {
    setIsOpen(true);
    setHighlightedIndex(index);
  };

  const close = () => {
    setIsOpen(false);
    setHighlightedIndex(-1);
  };

  const select = (index: number) => {
    const item = items[index];
    if (item) setSelectedItem(item);
    close();
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (items.length === 0) return;

    switch (e.key) {
      case 'ArrowDown':
        if (isOpen) setHighlightedIndex(Math.min(highlightedIndex + 1, lastIndex));
        else open(Math.max(selectedIndex, 0));
        break;
      case 'ArrowUp':
        if (isOpen) setHighlightedIndex(Math.max(highlightedIndex - 1, 0));
        else open(Math.max(selectedIndex, 0));
        break;
      case 'Home':
        open(0);
        break;
      case 'End':
        open(lastIndex);
        break;
      case 'Enter':
      case ' ':
        if (isOpen && highlightedIndex >= 0) select(highlightedIndex);
        else open(Math.max(selectedIndex, 0));
        break;
      case 'Escape':
        if (!isOpen) return;
        close();
        break;
      case 'Tab':
        // Select the highlighted option, then let focus move on as usual
        if (isOpen && highlightedIndex >= 0) select(highlightedIndex);
        return;
      default:
        return;
    }
    e.preventDefault();
  };

  const getLabelProps = () => ({ id: labelId });

  const getComboboxProps = () => ({
    role: 'combobox' as const,
    tabIndex: 0,
    'aria-haspopup': 'listbox' as const,
    'aria-expanded': isOpen,
    'aria-controls': menuId,
    'aria-labelledby': labelId,
    'aria-activedescendant':
      isOpen && highlightedIndex >= 0 ? optionId(highlightedIndex) : undefined,
    onClick: () => (isOpen ? close() : open(Math.max(selectedIndex, 0))),
    onKeyDown: handleKeyDown,
    onBlur: close,
  });

  const getMenuProps = () => ({
    id: menuId,
    role: 'listbox' as const,
    'aria-labelledby': labelId,
    tabIndex: -1,
    hidden: !isOpen,
  });

  const getItemProps = ({ item, index }: { item: T; index: number }) => ({
    id: optionId(index),
    role: 'option' as const,
    'aria-selected': selectedItem?.id === item.id,
    // Keep focus on the combobox so its onBlur does not close the menu first
    onMouseDown: (e: MouseEvent) => e.preventDefault(),
    onClick: () => select(index),
    onMouseMove: () => setHighlightedIndex(index),
  });

  return {
    selectedItem,
    isOpen,
    highlightedIndex,
    getLabelProps,
    getComboboxProps,
    getMenuProps,
    getItemProps,
  };
}

// Usage
function Select({ label, items }: { label: string; items: Array<{ id: string; label: string }> }) {
  const {
    selectedItem,
    highlightedIndex,
    getLabelProps,
    getComboboxProps,
    getMenuProps,
    getItemProps,
  } = useSelect(items);

  return (
    <div className="select">
      <div {...getLabelProps()}>{label}</div>
      <div {...getComboboxProps()} className="select-combobox">
        {selectedItem?.label ?? 'Select an item'}
      </div>
      <ul {...getMenuProps()}>
        {items.map((item, index) => (
          <li
            key={item.id}
            {...getItemProps({ item, index })}
            className={highlightedIndex === index ? 'highlighted' : ''}
          >
            {item.label}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

## State Reducer Pattern

```tsx
import { useReducer, Reducer } from 'react';

// Types
type ToggleState = { on: boolean };
type ToggleAction = { type: 'toggle' } | { type: 'reset'; initialState: ToggleState };

// Default reducer
function toggleReducer(state: ToggleState, action: ToggleAction): ToggleState {
  switch (action.type) {
    case 'toggle':
      return { on: !state.on };
    case 'reset':
      return action.initialState;
    default:
      return state;
  }
}

interface UseToggleOptions {
  initialOn?: boolean;
  reducer?: Reducer<ToggleState, ToggleAction>;
}

function useToggleWithReducer({
  initialOn = false,
  reducer = toggleReducer,
}: UseToggleOptions = {}) {
  const initialState = { on: initialOn };
  const [state, dispatch] = useReducer(reducer, initialState);

  const toggle = () => dispatch({ type: 'toggle' });
  const reset = () => dispatch({ type: 'reset', initialState });

  return { ...state, toggle, reset, dispatch };
}

// Usage with custom reducer
function App() {
  const customReducer: Reducer<ToggleState, ToggleAction> = (state, action) => {
    // Custom logic: can only toggle if some condition
    if (action.type === 'toggle' && state.on) {
      // Prevent turning off
      return state;
    }
    return toggleReducer(state, action);
  };

  const { on, toggle } = useToggleWithReducer({ reducer: customReducer });

  return (
    <button onClick={toggle}>
      {on ? 'ON (cannot turn off)' : 'OFF'}
    </button>
  );
}
```
