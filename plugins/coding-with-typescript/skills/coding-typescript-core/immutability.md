# Immutability in TypeScript

**Core Principle:** Make mutation impossible at the type level, not just avoided in practice.

## Table of Contents

- [Why Immutability Matters](#why-immutability-matters)
- [The Gap: Convention vs. Enforcement](#the-gap-convention-vs-enforcement)
- [When to Use readonly](#when-to-use-readonly)
- [Deep Readonly Patterns](#deep-readonly-patterns)
- [Immutable Operations](#immutable-operations)
- [Common Mistakes](#common-mistakes)
- [Real-World Impact](#real-world-impact)

---

## Why Immutability Matters

### Bugs Prevented

**Without immutability:**
```typescript
interface State {
  items: Item[];  // Mutable
}

function processState(state: State) {
  state.items.push(newItem);  // ✅ Compiles, ❌ Bug: mutates original
  return state;
}

const original = { items: [item1] };
const result = processState(original);
console.log(original.items.length); // 2 - original was mutated!
```

**With immutability:**
```typescript
interface State {
  readonly items: readonly Item[];  // Immutable
}

function processState(state: State): State {
  state.items.push(newItem);  // ❌ Compiler error: readonly
  return {
    ...state,
    items: [...state.items, newItem]  // ✅ Creates new state
  };
}
```

### Benefits

1. **Time-travel debugging** - Every state transition creates new object
2. **Undo/redo** - Just keep array of previous states
3. **Predictable updates** - Function can't change inputs
4. **Concurrent safety** - Multiple readers, no surprise mutations
5. **Testing** - Compare before/after states easily

---

## The Gap: Convention vs. Enforcement

### The Problem

```typescript
// ❌ Baseline approach: Convention without enforcement
interface CartState {
  items: CartItem[];  // Not readonly
  total: number;
}

// Implementation follows immutable pattern
const addItem = (state: CartState, item: CartItem): CartState => ({
  ...state,
  items: [...state.items, item],  // ✅ Creates new array
});

// But nothing prevents this later:
const badUpdate = (state: CartState) => {
  state.items.push(newItem);  // ✅ Compiles! ❌ Breaks immutability
};
```
**Reality:** Without `readonly`, the compiler cannot stop accidental mutation later.

### The Solution

```typescript
// ✅ With readonly: Compiler enforces immutability
interface CartState {
  readonly items: readonly CartItem[];  // Double readonly!
  readonly total: number;
}

const addItem = (state: CartState, item: CartItem): CartState => ({
  ...state,
  items: [...state.items, item],  // ✅ Still works
});

const badUpdate = (state: CartState) => {
  state.items.push(newItem);  // ❌ Compiler error!
  state.total = 100;  // ❌ Compiler error!
};
```

**Impact:** Entire class of bugs become impossible.

---

## When to Use `readonly`

### Default Rule

**Use `readonly` for EVERYTHING by default.** Remove only when mutation is truly needed.

### Always `readonly`

```typescript
// ✅ API response types
interface User {
  readonly id: string;
  readonly name: string;
  readonly email: string;
}

// ✅ Configuration objects
interface Config {
  readonly apiUrl: string;
  readonly timeout: number;
}

// ✅ State in state machines
interface AppState {
  readonly user: readonly User[];
  readonly loading: boolean;
}

// ✅ Domain model entities
interface Product {
  readonly id: string;
  readonly price: number;
  readonly inventory: number;
}

// ✅ Function parameters (especially objects/arrays)
function processUsers(users: readonly User[]) {
  // Can't accidentally mutate input
}
```

### When NOT to use `readonly`

```typescript
// ❌ Don't use for builders/accumulators
class StringBuilder {
  private content: string = '';  // Mutable by design

  append(str: string): this {
    this.content += str;
    return this;
  }
}

// ❌ Don't use for performance-critical hot paths (rare)
function sortInPlace(arr: number[]) {  // Intentionally mutable
  // When profiling shows copying is bottleneck
  arr.sort((a, b) => a - b);
}
```

**Rule:** If you're skipping `readonly` "to be pragmatic" - that's a rationalization. Have data.

---

## Deep Readonly Patterns

### Shallow vs. Deep

```typescript
// ❌ Shallow readonly - array can't be reassigned but items can mutate
interface State {
  readonly items: CartItem[];
}

const state: State = { items: [] };
state.items = [];  // ❌ Error: readonly
state.items[0].quantity = 5;  // ✅ Compiles! Not deeply readonly

// ✅ Deep readonly - both array and items are readonly
interface State {
  readonly items: readonly CartItem[];
}

const state: State = { items: [] };
state.items = [];  // ❌ Error: readonly
state.items[0].quantity = 5;  // ❌ Error: if CartItem has readonly quantity
state.items.push(item);  // ❌ Error: readonly array
```

### Pattern: Double Readonly

```typescript
interface Todo {
  readonly id: string;
  readonly text: string;
  readonly completed: boolean;
}

interface TodoState {
  readonly todos: readonly Todo[];  // Both readonly!
  readonly filter: string;
}
```

**Why double?**
- `readonly todos` - Can't reassign the array reference
- `readonly Todo[]` - Can't mutate array contents (push, pop, sort)

### Nested Objects

```typescript
interface User {
  readonly id: string;
  readonly profile: {
    readonly name: string;
    readonly email: string;
  };
  readonly tags: readonly string[];
}

// All levels are readonly:
user.id = 'x';  // ❌ Error
user.profile = {};  // ❌ Error
user.profile.name = 'x';  // ❌ Error
user.tags = [];  // ❌ Error
user.tags.push('x');  // ❌ Error
```

### Utility Type: DeepReadonly

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object
    ? DeepReadonly<T[P]>
    : T[P];
};

interface Mutable {
  user: {
    name: string;
    tags: string[];
  };
}

type Immutable = DeepReadonly<Mutable>;
// {
//   readonly user: {
//     readonly name: string;
//     readonly tags: readonly string[];
//   };
// }
```

---

## Immutable Operations

### Arrays

```typescript
const items: readonly Item[] = [item1, item2];

// ❌ Mutating methods don't exist
items.push(item3);  // Error
items.pop();  // Error
items.splice(0, 1);  // Error
items.sort();  // Error
items.reverse();  // Error

// ✅ Immutable alternatives
const added = [...items, item3];
const removed = items.slice(0, -1);
const spliced = [...items.slice(0, 1), ...items.slice(2)];
const sorted = [...items].sort((a, b) => a.id.localeCompare(b.id));
const reversed = [...items].reverse();

// ✅ Non-mutating methods work
const filtered = items.filter(item => item.active);
const mapped = items.map(item => ({ ...item, processed: true }));
const found = items.find(item => item.id === '123');
```

### Objects

```typescript
const user: User = {
  id: '1',
  name: 'Alice',
  email: 'alice@example.com'
};

// ❌ Can't mutate properties
user.name = 'Bob';  // Error if User has readonly properties

// ✅ Create new object with changes
const updated = { ...user, name: 'Bob' };

// ✅ Merge multiple updates
const merged = { ...user, name: 'Bob', email: 'bob@example.com' };

// ✅ Nested updates
const state: State = {
  user: { id: '1', profile: { name: 'Alice' } },
  settings: { theme: 'dark' }
};

const updatedState = {
  ...state,
  user: {
    ...state.user,
    profile: {
      ...state.user.profile,
      name: 'Bob'
    }
  }
};
```

### State Update Patterns

```typescript
interface TodoState {
  readonly todos: readonly Todo[];
  readonly filter: string;
}

// ✅ Add item
const addTodo = (state: TodoState, todo: Todo): TodoState => ({
  ...state,
  todos: [...state.todos, todo]
});

// ✅ Update item
const updateTodo = (state: TodoState, id: string, updates: Partial<Todo>): TodoState => ({
  ...state,
  todos: state.todos.map(todo =>
    todo.id === id ? { ...todo, ...updates } : todo
  )
});

// ✅ Remove item
const removeTodo = (state: TodoState, id: string): TodoState => ({
  ...state,
  todos: state.todos.filter(todo => todo.id !== id)
});

// ✅ Replace all items
const setTodos = (state: TodoState, todos: readonly Todo[]): TodoState => ({
  ...state,
  todos
});
```

---

## Common Mistakes

### Mistake 1: Mutable Types, Immutable Code

```typescript
// ❌ Types allow mutation
interface State {
  items: Item[];  // No readonly
}

// Code follows immutable pattern
const addItem = (state: State, item: Item): State => ({
  ...state,
  items: [...state.items, item]  // ✅ Immutable
});

// But nothing prevents this:
const buggyCode = (state: State) => {
  state.items.push(item);  // ✅ Compiles, ❌ Breaks everything
};
```

**Fix:**
```typescript
// ✅ Types enforce immutability
interface State {
  readonly items: readonly Item[];
}
```


### Mistake 2: Shallow Readonly

```typescript
// ❌ Only array reference is readonly
const items: readonly Item[] = [item1, item2];
items[0].quantity = 10;  // ✅ Compiles if Item is mutable!
```

**Fix:**
```typescript
// ✅ Both array and items are readonly
interface Item {
  readonly id: string;
  readonly quantity: number;
}

const items: readonly Item[] = [item1, item2];
items[0].quantity = 10;  // ❌ Compiler error
```

### Mistake 3: Forgetting Function Parameters

```typescript
// ❌ Function can mutate input
function processUsers(users: User[]) {
  users.sort((a, b) => a.name.localeCompare(b.name));  // ✅ Compiles, ❌ Mutates input!
  return users;
}
```

**Fix:**
```typescript
// ✅ Function can't mutate input
function processUsers(users: readonly User[]): readonly User[] {
  return [...users].sort((a, b) => a.name.localeCompare(b.name));
}
```

### Mistake 4: "I'll Be Careful"

**Thinking:** "I don't need `readonly`, I'll just remember not to mutate"

**Reality:** Works until it doesn't. One late-night `.push()` breaks production.

**Fix:** Use compiler to enforce safety. Don't rely on discipline.

---

## Real-World Impact

### Case Study: Shopping Cart

**Baseline (without readonly):**
```typescript
interface CartState {
  items: CartItem[];  // Mutable
  total: number;
}
```

**Problems:**
- Developer adds `cart.items.push(newItem)` in one place
- Breaks Redux time-travel debugging
- Unit tests fail intermittently (mutation side effects)
- Undo/redo feature doesn't work

**With readonly:**
```typescript
interface CartState {
  readonly items: readonly CartItem[];
  readonly total: number;
}
```

**Results:**
- `cart.items.push()` → Compiler error caught immediately
- All state transitions create new objects
- Time-travel debugging works perfectly
- Tests are deterministic
- Undo/redo works on first try

### Performance Considerations

**Myth:** "Immutability is slow, spreading creates too many objects"

**Reality:**
- Modern JS engines optimize object spreading
- Structural sharing (only changed parts copied)
- Immutability enables memoization (React.memo, useMemo)
- Predictability worth marginal performance cost

**When to measure:**
```typescript
// Profile first, optimize later
const LARGE_ARRAY = 100_000;

// If profiling shows this is bottleneck:
const sorted = [...largeArray].sort();  // Creates copy

// Consider:
const sorted = largeArray.slice().sort();  // Still immutable, maybe faster?

// Or accept mutation in isolated scope:
function sortCopy(arr: readonly number[]): readonly number[] {
  const copy = arr.slice();  // Still can't mutate original
  copy.sort((a, b) => a - b);  // Mutate the copy
  return copy;
}
```

**99% of the time:** Readability and safety > micro-optimizations

### React/Redux Integration

```typescript
// ✅ Redux state is readonly
interface RootState {
  readonly cart: CartState;
  readonly user: UserState;
}

// ✅ Reducers can't mutate
const cartReducer = (
  state: CartState,
  action: CartAction
): CartState => {
  switch (action.type) {
    case 'ADD_ITEM':
      return { ...state, items: [...state.items, action.item] };
    default:
      return state;
  }
};

// ✅ React props are readonly
interface Props {
  readonly user: User;
  readonly onUpdate: (user: User) => void;
}
```

---

## Encapsulated Mutable State

Private mutable state behind a readonly public API is perfectly fine. Immutability is about **public contracts**, not internal implementation.

```typescript
// ✅ Private mutable state is OK
class Cache<K, V> {
  private store = new Map<K, V>();  // Mutable internally

  // Public API is readonly
  get(key: K): V | undefined {
    return this.store.get(key);
  }

  set(key: K, value: V): void {
    this.store.set(key, value);
  }

  entries(): ReadonlyMap<K, V> {
    return this.store;  // Expose as readonly
  }
}

// ✅ Builder with mutable internals, immutable output
class QueryBuilder {
  private conditions: string[] = [];  // Mutable during construction

  where(condition: string): this {
    this.conditions.push(condition);
    return this;
  }

  build(): string {  // Returns immutable value
    return this.conditions.join(" AND ");
  }
}
```

**The rule:** Readonly at boundaries, mutable inside encapsulated scope. For class-based encapsulation guidance, use the `coding-typescript-classes` skill.

## Summary

### The Rules

1. **Default to `readonly`** - Remove only when mutation is proven necessary
2. **Double readonly for collections** - `readonly items: readonly Item[]`
3. **All the way down** - Nested objects need readonly too
4. **Function parameters** - Especially for objects and arrays
5. **No "I'll be careful"** - Use compiler to enforce

### The Pattern

```typescript
// ✅ Perfect immutability
interface Todo {
  readonly id: string;
  readonly text: string;
  readonly completed: boolean;
}

interface State {
  readonly todos: readonly Todo[];
  readonly filter: string;
}

const updateState = (state: State, updates: Partial<State>): State => ({
  ...state,
  ...updates
});
```

**Red Flags:**
- Mutable types with immutable code ("pragmatic approach")
- "I'll be careful not to mutate"
- Missing `readonly` on function parameters
- Shallow readonly (`readonly Item[]` without `readonly` on `Item`)

**When you catch yourself skipping `readonly` - that's a rationalization. Add it.**
