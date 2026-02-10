# TypeScript Generics

## Table of Contents

- [Overview](#overview)
- [Generics Basics](#generics-basics)
- [Generic Constraints](#generic-constraints)
- [Advanced Patterns](#advanced-patterns)
- [Type Inference](#type-inference)
- [Anti-Patterns](#anti-patterns)
- [Branded Types (Nominal Typing)](#branded-types-nominal-typing)
- [Summary](#summary)

## Overview

Type-safe abstraction via generic type parameters, constraints, defaults, and inference.

For conditional, mapped, and template literal types, use the `coding-typescript-type-operators` skill.

## When to Use Generics

- A function or type must work over many concrete types while preserving relationships between inputs and outputs.
- You want callers to get precise inference without repeating types.
- A single implementation should support multiple shapes while enforcing capabilities via constraints.

## When *Not* to Use Generics

- A simple union or overload is clearer.
- The type parameter would be unused or only used in one place (avoid “generic for its own sake”).
- The API is already monomorphic and unlikely to generalize.

## Generics Basics

> **Reminder:** Generic functions use `<T>`, generic interfaces use `interface Box<T>`, generic classes use `class Stack<T>`. TypeScript infers type parameters from usage. Start here only if new to generics; otherwise skip to constraints.

## Generic Constraints

### `extends` Keyword

```typescript
// Constrain to objects with 'length'
function logLength<T extends { length: number }>(item: T): void {
  console.log(item.length);
}

logLength("hello");    // OK
logLength([1, 2, 3]);  // OK
logLength({ length: 5 }); // OK
// logLength(123);     // Error: number has no length

// Constrain to interface
interface Identifiable {
  readonly id: string;
}

function findById<T extends Identifiable>(
  items: readonly T[],
  id: string
): T | undefined {
  return items.find(item => item.id === id);
}
```

### `keyof` Constraint

```typescript
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: "Alice", age: 30 };

const name = getProperty(user, "name"); // string
const age = getProperty(user, "age");   // number
// getProperty(user, "invalid"); // Error: not a key

// Set property type-safely
function setProperty<T, K extends keyof T>(
  obj: T,
  key: K,
  value: T[K]
): T {
  return { ...obj, [key]: value };
}
```

### Generic Parameter Defaults

Prefer defaults to reduce call-site noise and improve inference:

```typescript
interface Container<T, U = T[]> {
  readonly value: T;
  readonly children: U;
}
```

Rules to remember:
- Optional type parameters must come after required ones.
- Defaults must satisfy constraints, if any.
- Unspecified type arguments resolve to defaults when provided.
- If inference can't choose a candidate, the default type is inferred.

TypedArray types also use default type parameters for their backing buffer. Specify the buffer type when you need stronger guarantees:

```typescript
const bytes: Uint8Array<ArrayBuffer> = new Uint8Array(new ArrayBuffer(8));
```

In newer TS lib definitions, `ArrayBuffer` is no longer a supertype of many `TypedArray` types. When a function requires `ArrayBuffer` or `SharedArrayBuffer`, pass `typedArray.buffer` instead of the typed array itself.

### Multiple Constraints

```typescript
interface Named {
  readonly name: string;
}

interface Aged {
  readonly age: number;
}

function describe<T extends Named & Aged>(entity: T): string {
  return `${entity.name} is ${entity.age} years old`;
}

describe({ name: "Alice", age: 30 }); // OK
// describe({ name: "Bob" }); // Error: missing 'age'
```

## Advanced Patterns

### Generic Repository

```typescript
interface Identifiable {
  readonly id: string;
}

interface Repository<T extends Identifiable> {
  findById(id: string): Promise<T | null>;
  findAll(filter?: Partial<T>): Promise<readonly T[]>;
  save(entity: T): Promise<T>;
  update(id: string, updates: Partial<T>): Promise<T | null>;
  delete(id: string): Promise<boolean>;
}

// For InMemoryRepository implementation, use the `coding-typescript-protocol` skill.
```

### Generic Builder Pattern

```typescript
interface Builder<T> {
  build(): T;
}

class UserBuilder implements Builder<User> {
  private user: Partial<User> = {};

  withName(name: string): this {
    this.user.name = name;
    return this;
  }

  withAge(age: number): this {
    this.user.age = age;
    return this;
  }

  withEmail(email: string): this {
    this.user.email = email;
    return this;
  }

  build(): User {
    const { name, age, email } = this.user;
    if (!name || !age || !email) {
      throw new Error("Missing required fields");
    }
    return { name, age, email };
  }
}

const user = new UserBuilder()
  .withName("Alice")
  .withAge(30)
  .withEmail("alice@example.com")
  .build();
```

### Generic Event System

```typescript
interface EventMap {
  click: { x: number; y: number };
  keypress: { key: string };
  submit: { data: unknown };
}

type EventCallback<T> = (event: T) => void;

class EventEmitter<T extends Record<string, unknown>> {
  private listeners: { [K in keyof T]?: Array<EventCallback<T[K]>> } = {};

  on<K extends keyof T>(event: K, callback: EventCallback<T[K]>): void {
    const callbacks = (this.listeners[event] ??= []);
    callbacks.push(callback);
  }

  emit<K extends keyof T>(event: K, data: T[K]): void {
    const callbacks = this.listeners[event] ?? [];
    callbacks.forEach(cb => cb(data));
  }
}

const emitter = new EventEmitter<EventMap>();

emitter.on("click", ({ x, y }) => {
  console.log(`Clicked at ${x}, ${y}`);
});

emitter.emit("click", { x: 10, y: 20 }); // Type-safe!
// emitter.emit("click", { invalid: true }); // Error!
```

### Recursive Generics

```typescript
// DeepReadonly<T> — use the `coding-typescript-core` skill (immutability).

// Deep partial
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object
    ? DeepPartial<T[P]>
    : T[P];
};

// Flatten nested type
type Flatten<T> = T extends (infer U)[]
  ? Flatten<U>
  : T;

type Nested = number[][][];
type Flat = Flatten<Nested>; // number
```

### Const Type Parameters (TS 5.0+)

Use `const` type parameters to preserve literal inference without requiring `as const` at call sites:

```typescript
type HasNames = { names: readonly string[] };

function getNamesExactly<const T extends HasNames>(arg: T): T["names"] {
  return arg.names;
}

const names = getNamesExactly({ names: ["Alice", "Bob", "Eve"] });
// names: readonly ["Alice", "Bob", "Eve"]
```

> **Note:** The `const` modifier doesn’t require immutable constraints and doesn’t reject mutable values. Using a mutable constraint can produce surprising results.

## Type Inference

### Explicit Type Arguments (When Inference Falls Short)

Prefer inference, but supply type arguments when inference produces `unknown` or overly broad types:

```typescript
function wrap<T>(value: T): { value: T } {
  return { value };
}

const inferred = wrap(123); // { value: number }
const explicit = wrap<string>("ok"); // { value: string }
```

If inference produces errors in generic calls, provide explicit type arguments to pin the intended types.

### Inferred Return Types

```typescript
// Compiler infers return type
function createUser(name: string, age: number) {
  return { name, age, createdAt: new Date() };
}

// Inferred: { name: string; age: number; createdAt: Date }
type User = ReturnType<typeof createUser>;
```

### Inferred Generics

```typescript
// TypeScript 5.5+ infers type predicates
const isString = (x: unknown) => typeof x === 'string';
// Inferred: (x: unknown) => x is string

const isNumber = (x: unknown) => typeof x === 'number';
// Inferred: (x: unknown) => x is number

const data = [1, "two", 3, "four"];
const strings = data.filter(isString); // string[]
const numbers = data.filter(isNumber); // number[]
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Basic generic | `function f<T>(x: T): T` | Preserving input/output type relationship |
| Constraint | `T extends { length: number }` | Requiring capabilities on type parameter |
| keyof constraint | `K extends keyof T` | Type-safe property access |
| Default parameter | `T = string` | Reducing call-site noise |
| Multiple constraints | `T extends A & B` | Requiring multiple capabilities |
| Const type param | `<const T extends ...>` (TS 5.0+) | Preserving literal types without `as const` |
| Branded type | `T & { __brand: B }` | Nominal typing in a structural system |
| Generic event map | `EventEmitter<T extends Record<string, unknown>>` | Type-safe event systems |
| Recursive generic | `DeepPartial<T>` | Transforming nested object types |

## Anti-Patterns

### ❌ Over-Constraining

```typescript
// BAD - unnecessarily strict
function process<T extends { id: string; name: string; age: number }>(
  item: T
): void { }

// GOOD - constrain only what you need
function process<T extends { id: string }>(item: T): void { }
```

### ❌ Unused Type Parameters

```typescript
// BAD - T is never used
function log<T>(message: string): void {
  console.log(message);
}

// GOOD - remove unused parameter
function log(message: string): void {
  console.log(message);
}
```

### ❌ `any` in Generics

```typescript
// BAD - defeats purpose of generics
function identity<T>(value: any): T {
  return value; // unsafe cast
}

// GOOD - proper generic
function identity<T>(value: T): T {
  return value;
}
```

## Branded Types (Nominal Typing)

TypeScript uses structural typing. Branded types add nominal uniqueness:

```typescript
// Brand type — the `as` here is the ONE acceptable boundary for branding
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId = Brand<string, "UserId">;
type OrderId = Brand<string, "OrderId">;

// Constructor functions — branding boundary
const UserId = (id: string): UserId => id as UserId;
const OrderId = (id: string): OrderId => id as OrderId;

// Type safety: can't mix IDs
function getUser(id: UserId): User { /* ... */ }

const userId = UserId("u_123");
const orderId = OrderId("o_456");

getUser(userId);   // OK
getUser(orderId);  // Error: OrderId not assignable to UserId
getUser("raw");    // Error: string not assignable to UserId
```

> **Note:** The `as` cast in brand constructors is the one acceptable use of type assertions — it's the branding boundary where you intentionally add the phantom brand.

### Common Branded Types

```typescript
type Email = Brand<string, "Email">;
type PositiveNumber = Brand<number, "PositiveNumber">;
type NonEmptyString = Brand<string, "NonEmptyString">;

// Validate at construction
const Email = (value: string): Email => {
  if (!value.includes("@")) throw new Error("Invalid email");
  return value as Email;
};

const PositiveNumber = (value: number): PositiveNumber => {
  if (value <= 0) throw new Error("Must be positive");
  return value as PositiveNumber;
};
```

## Summary

- Use generics for reusable, type-safe abstractions
- Constrain with `extends` for required capabilities
- Use `keyof` for type-safe property access
- Infer types from existing structures
- Avoid over-constraining and unused parameters
