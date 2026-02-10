# TypeScript Complete Examples

Complete, production-ready examples demonstrating core TypeScript patterns.

## Table of Contents

- [Example 1: API Response Handler](#example-1-api-response-handler-type-safe-error-handling)
- [Example 2: Immutable State Updates](#example-2-immutable-state-updates)
- [Example 3: Discriminated Union for State Machine](#example-3-discriminated-union-for-state-machine)
- [Example 4: Generic Factory with Constraints](#example-4-generic-factory-with-constraints)
- [Example 5: Configuration with satisfies](#example-5-configuration-with-satisfies-and-as-const)
- [Usage Notes](#usage-notes)
- [Common Mistakes](#common-mistakes)

---

## Example 1: API Response Handler (Type-Safe Error Handling)

### Input: Raw API response that could fail
```typescript
async function fetchUser(id: string): Promise<unknown> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
```

### Output: Type-safe Result pattern with validation
```typescript
// Result<T, E> — see SKILL.md

interface User {
  readonly id: string;
  readonly name: string;
  readonly email: string;
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

// Validator function with inferred type predicate (5.5+)
const isUser = (data: unknown): data is User => {
  if (!isRecord(data)) return false;

  return (
    "id" in data && typeof data.id === "string" &&
    "name" in data && typeof data.name === "string" &&
    "email" in data && typeof data.email === "string"
  );
};

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return { ok: false, error: new Error(`HTTP ${response.status}`) };
    }

    const data: unknown = await response.json();

    if (isUser(data)) {
      return { ok: true, value: data };
    }

    return { ok: false, error: new Error('Invalid user data') };
  } catch (error) {
    if (error instanceof Error) {
      return { ok: false, error };
    }
    return { ok: false, error: new Error('Unknown error') };
  }
}

// Usage
const result = await fetchUser('123');
if (result.ok) {
  console.log(result.value.name); // Type-safe access
} else {
  console.error(result.error.message);
}
```

### Why this works:
- Uses `unknown` for untrusted data, never `any`
- Inferred type predicate validates structure
- Result type makes error handling explicit
- No type assertions or non-null assertions
- All data is `readonly` by default

---

## Example 2: Immutable State Updates

### Input: Mutable state management pattern
```typescript
interface TodoState {
  todos: Todo[];
  filter: string;
}

function addTodo(state: TodoState, todo: Todo) {
  state.todos.push(todo); // Mutates!
  return state;
}
```

### Output: Immutable updates with proper types
```typescript
interface Todo {
  readonly id: string;
  readonly text: string;
  readonly completed: boolean;
}

interface TodoState {
  readonly todos: readonly Todo[];
  readonly filter: string;
}

// All operations return new state
const addTodo = (state: TodoState, todo: Todo): TodoState => ({
  ...state,
  todos: [...state.todos, todo], // Creates new array
});

const toggleTodo = (state: TodoState, id: string): TodoState => ({
  ...state,
  todos: state.todos.map(todo =>
    todo.id === id
      ? { ...todo, completed: !todo.completed } // Creates new object
      : todo
  ),
});

const setFilter = (state: TodoState, filter: string): TodoState => ({
  ...state,
  filter,
});

// Usage - state never mutates
let state: TodoState = {
  todos: [],
  filter: 'all',
};

state = addTodo(state, { id: '1', text: 'Learn TS', completed: false });
state = toggleTodo(state, '1');
```

### Why this works:
- All interfaces use `readonly` to prevent mutation
- Spread operators create new objects/arrays
- Compiler catches any mutation attempts
- Pure functions enable time-travel debugging and testing

---

## Example 3: Discriminated Union for State Machine

### Input: Unclear state management with optional fields
```typescript
interface LoadingState {
  loading: boolean;
  data?: User;
  error?: Error;
}
```

### Output: Type-safe discriminated union
```typescript
type AsyncState<T, E = Error> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: E };

interface User {
  readonly id: string;
  readonly name: string;
}

function renderUser(state: AsyncState<User>): string {
  // Compiler enforces exhaustive checking
  if (state.status === 'idle') {
    return 'Click to load';
  }

  if (state.status === 'loading') {
    return 'Loading...';
  }

  if (state.status === 'success') {
    return `Welcome ${state.data.name}`; // data guaranteed to exist
  }

  if (state.status === 'error') {
    return `Error: ${state.error.message}`; // error guaranteed to exist
  }

  // TypeScript ensures we handled all cases
  const _exhaustive: never = state;
  return _exhaustive;
}

// Impossible states are impossible
let state: AsyncState<User> = { status: 'idle' };
// state = { status: 'success' }; // ❌ Error: missing data
// state = { status: 'success', data: user, error: err }; // ❌ Error: can't have both
```

### Why this works:
- Each state is mutually exclusive
- TypeScript narrows type based on discriminant
- Impossible states can't be represented
- Exhaustiveness checking catches missing cases

---

## Example 4: Generic Factory with Constraints

### Input: Untyped factory function
```typescript
function createRepository(model: any) {
  return {
    findById: (id: any) => { /* ... */ },
    save: (entity: any) => { /* ... */ },
  };
}
```

### Output: Type-safe generic factory
```typescript
// Define entity constraint
interface Entity {
  readonly id: string;
}

interface User extends Entity {
  readonly name: string;
  readonly email: string;
}

interface Product extends Entity {
  readonly title: string;
  readonly price: number;
}

// Generic repository with constraints
interface Repository<T extends Entity> {
  findById(id: string): Promise<Result<T>>;
  save(entity: T): Promise<Result<T>>;
  findAll(): Promise<Result<readonly T[]>>;
}

function createRepository<T extends Entity>(
  tableName: string,
  validate: (data: unknown) => data is T
): Repository<T> {
  return {
    async findById(id: string): Promise<Result<T>> {
      // Implementation with proper error handling
      try {
        const data: unknown = await db.query(`SELECT * FROM ${tableName} WHERE id = ?`, [id]);
        if (!validate(data)) {
          return { ok: false, error: new Error('Invalid data structure') };
        }
        return { ok: true, value: data };
      } catch (error) {
        if (error instanceof Error) {
          return { ok: false, error };
        }
        return { ok: false, error: new Error('Unknown error') };
      }
    },

    async save(entity: T): Promise<Result<T>> {
      try {
        await db.query(`INSERT INTO ${tableName} VALUES (?)`, [entity]);
        return { ok: true, value: entity };
      } catch (error) {
        if (error instanceof Error) {
          return { ok: false, error };
        }
        return { ok: false, error: new Error('Unknown error') };
      }
    },

    async findAll(): Promise<Result<readonly T[]>> {
      try {
        const rows: unknown = await db.query(`SELECT * FROM ${tableName}`);
        if (!Array.isArray(rows) || !rows.every(validate)) {
          return { ok: false, error: new Error('Invalid data structure') };
        }
        return { ok: true, value: rows };
      } catch (error) {
        if (error instanceof Error) {
          return { ok: false, error };
        }
        return { ok: false, error: new Error('Unknown error') };
      }
    },
  };
}

// Usage - fully typed repositories
const userRepo = createRepository<User>('users', isUser);
const productRepo = createRepository<Product>('products', isProduct);

const result = await userRepo.findById('123');
if (result.ok) {
  console.log(result.value.name); // Type-safe: knows it's User
}
```

### Why this works:
- Generic constraint ensures all entities have `id`
- TypeScript infers correct types throughout
- Repository operations are type-safe per entity
- No type assertions in usage code

---

## Example 5: Configuration with `satisfies` and `as const`

### Input: Loosely typed configuration
```typescript
const config = {
  api: {
    baseUrl: "https://api.example.com",
    timeout: 5000,
  },
  features: {
    darkMode: true,
  }
};
```

### Output: Strongly typed, validated configuration
```typescript
// Define expected shape
interface ApiConfig {
  readonly baseUrl: string;
  readonly timeout: number;
  readonly retries?: number;
}

interface FeatureFlags {
  readonly darkMode: boolean;
  readonly analytics: boolean;
}

interface AppConfig {
  readonly api: ApiConfig;
  readonly features: FeatureFlags;
}

// Use satisfies to validate without widening types
const config = {
  api: {
    baseUrl: "https://api.example.com",
    timeout: 5000,
    // retries omitted - optional
  },
  features: {
    darkMode: true,
    analytics: false,
  },
} as const satisfies AppConfig;

// Benefits:
// 1. config.api.baseUrl has type "https://api.example.com" (literal)
type BaseUrl = typeof config.api.baseUrl; // "https://api.example.com"

// 2. Validation at compile time
const badConfig = {
  api: {
    baseUrl: "https://api.example.com",
    // timeout: "5000", // ❌ Error: string not assignable to number
  },
  features: {
    darkMode: true,
    analytics: false,
  },
} as const satisfies AppConfig;

// 3. Additional properties allowed for environment-specific config
const devConfig = {
  api: {
    baseUrl: "http://localhost:3000",
    timeout: 10000,
    retries: 3,
  },
  features: {
    darkMode: false,
    analytics: false,
  },
  debug: true, // ✅ Extra property OK with satisfies
} as const satisfies AppConfig;

// Usage with type safety
function makeRequest(endpoint: string) {
  fetch(`${config.api.baseUrl}${endpoint}`, {
    signal: AbortSignal.timeout(config.api.timeout),
  });
}
```

### Why this works:
- `as const` creates deeply readonly literal types
- `satisfies` validates structure without type widening
- Autocomplete works for all properties
- Typos caught at compile time
- Extra properties allowed for extensibility

---

## Usage Notes

**When to use these examples:**
- Learning a new pattern
- Stuck on implementation
- Need a template to adapt
- Want to see "why this works" explanations

**Loading strategy:**
- Examples loaded on-demand when complexity requires it
- Reference from SKILL.md for specific patterns
- Each example is complete and production-ready

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Using `any` type | Disables type checking, allows runtime errors | Use `unknown` + type guards or validators |
| Mutating arrays with `.push()`, `.sort()` | Breaks immutability, causes bugs in React/state management | Use `[...arr, item]`, `[...arr].sort()` |
| Type assertion `as Type` | Bypasses validation, assumes correctness | Write validator function with type predicate |
| Non-null assertion `value!` | Crashes if value is null/undefined | Use `value ?? default` or optional chaining `value?.prop` |
| Truthy check `\|\|` for defaults | Wrong default for `0`, `""`, `false` | Use nullish coalescing `??` |
| Missing `readonly` on data | Allows accidental mutations | Add `readonly` to interface properties and arrays |
| Redundant type annotations | Noise, maintenance burden | Let TypeScript infer types from implementation |
| Overly complex generics | Hard to understand and maintain | Start simple, add constraints only when needed |
| Not using `satisfies` for config | Loses literal types, no validation | Use `as const satisfies Type` pattern |
| Catch clause typed as `any` | Can't safely access error properties | Type as `unknown`, check with `instanceof Error` |
