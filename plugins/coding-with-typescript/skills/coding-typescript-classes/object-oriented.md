# Object-Oriented TypeScript

**Core Principle:** Classes earn their place through true encapsulation -- private mutable state behind a readonly public API.

## Table of Contents

- [When Classes Are Appropriate](#when-classes-are-appropriate)
- [Interfaces for Capabilities, Classes for Implementation](#interfaces-for-capabilities-classes-for-implementation)
- [Private Mutable State, Readonly Public API](#private-mutable-state-readonly-public-api)
- [Class Features (Handbook Highlights)](#class-features-handbook-highlights)
- [Class vs Plain Object + Closures](#class-vs-plain-object-closures)
- [Anti-Patterns](#anti-patterns)
- [Summary](#summary)

## When Classes Are Appropriate

Use a class when you need:

1. **True encapsulation** -- private mutable state with controlled access
2. **Identity semantics** -- instances carry identity beyond their data
3. **Lifecycle management** -- resources that must be acquired and released

If none of these apply, prefer plain functions, objects, or closures.

## Interfaces for Capabilities, Classes for Implementation

Define what something can do with an interface. Use a class to provide one concrete implementation.

```typescript
interface EventBus {
  subscribe(event: string, handler: (data: unknown) => void): void;
  publish(event: string, data: unknown): void;
}

class InMemoryEventBus implements EventBus {
  private readonly handlers = new Map<string, Array<(data: unknown) => void>>();

  subscribe(event: string, handler: (data: unknown) => void): void {
    const existing = this.handlers.get(event) ?? [];
    existing.push(handler);
    this.handlers.set(event, existing);
  }

  publish(event: string, data: unknown): void {
    const handlers = this.handlers.get(event) ?? [];
    for (const handler of handlers) {
      handler(data);
    }
  }
}
```

Consumers depend on `EventBus`, never on `InMemoryEventBus`. Swap implementations without touching call sites.

## Private Mutable State, Readonly Public API

Private mutation is fine. The boundary that matters is the public surface -- it must be readonly and return immutable data.

```typescript
interface RegistryEntry {
  readonly key: string;
  readonly value: string;
  readonly registeredAt: Date;
}

class Registry {
  private readonly entries = new Map<string, RegistryEntry>();

  register(key: string, value: string): void {
    this.entries.set(key, {
      key,
      value,
      registeredAt: new Date(),
    });
  }

  lookup(key: string): RegistryEntry | undefined {
    return this.entries.get(key);
  }

  getAll(): readonly RegistryEntry[] {
    return Array.from(this.entries.values());
  }

  get size(): number {
    return this.entries.size;
  }
}
```

Key properties of this pattern:

- `entries` is `private` -- callers cannot touch the Map directly
- `getAll()` returns `readonly RegistryEntry[]` -- callers cannot mutate the result
- `RegistryEntry` has all `readonly` fields -- no backdoor mutation of returned data
- The class freely mutates its private Map internally

## Class vs Plain Object + Closures

Closures can achieve encapsulation without classes:

```typescript
// Closure-based encapsulation
function createCounter(initial = 0) {
  let count = initial;
  return {
    increment: () => { count++; },
    decrement: () => { count--; },
    get value() { return count; },
  } as const;
}

// Class-based encapsulation
class Counter {
  private count: number;

  constructor(initial = 0) {
    this.count = initial;
  }

  increment(): void { this.count++; }
  decrement(): void { this.count--; }
  get value(): number { return this.count; }
}
```

**Choose closures when:** single instance, no interface conformance needed, simple state.

**Choose classes when:** multiple instances with shared behavior, implementing an interface, dependency injection, or lifecycle methods (dispose/cleanup).

## Class Features (Handbook Highlights)

### Access Modifiers and `#private`

Use `private`/`protected` for encapsulation. Use `#private` when you want runtime-enforced privacy.

```typescript
class Session {
  private token: string;
  #secret: string;

  constructor(token: string, secret: string) {
    this.token = token;
    this.#secret = secret;
  }
}
```

### Parameter Properties

Use parameter properties to reduce boilerplate for constructor args that become fields:

```typescript
class User {
  constructor(
    public readonly id: string,
    private readonly email: string
  ) {}
}
```

### Accessors (Getters/Setters)

Prefer getters for derived values; use setters only when you need validation.

```typescript
class Account {
  private _balance = 0;

  get balance(): number {
    return this._balance;
  }

  set balance(value: number) {
    if (value < 0) throw new Error("Invalid balance");
    this._balance = value;
  }
}
```

### `readonly` Fields

Use `readonly` to enforce immutability of public fields after construction:

```typescript
class Point {
  constructor(
    public readonly x: number,
    public readonly y: number
  ) {}
}
```

### `extends`, `implements`, and `override`

Use `implements` for capability contracts and `extends` sparingly for shared behavior.

```typescript
interface Identifiable { readonly id: string }

class Base implements Identifiable {
  constructor(readonly id: string) {}
}

class Derived extends Base {
  override toString(): string {
    return `Derived(${this.id})`;
  }
}
```

### Abstract Classes

Use abstract classes when you need shared behavior + enforced overrides.

```typescript
abstract class Repository<T> {
  abstract findById(id: string): Promise<T | null>;
}
```

### Static Members

Use static members for class-level utilities or factories.

```typescript
class Id {
  static next(): string {
    return crypto.randomUUID();
  }
}
```

### Fluent APIs with `this` Types

Use `this` return types to preserve subtype chaining:

```typescript
class Builder {
  withName(name: string): this {
    return this;
  }
}
```

### Mixins (Composition of Behaviors)

Use mixins to compose class behaviors when inheritance is too rigid.

```typescript
type Constructor<T = {}> = new (...args: any[]) => T;

function Timestamped<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    readonly createdAt = new Date();
  };
}
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Interface contract | `class X implements Y` | Defining capability, swapping implementations |
| Private field | `private readonly field` | Encapsulating mutable state |
| ES private | `#field` | Runtime-enforced privacy |
| Parameter property | `constructor(readonly id: string)` | Reducing constructor boilerplate |
| Getter | `get value(): T` | Derived/computed properties |
| Abstract class | `abstract class Base` | Shared behavior + enforced overrides |
| Override | `override method()` | Explicit intent to override parent |
| Fluent API | `method(): this` | Chainable builder methods |
| Mixin | `function Mixin<T extends Constructor>(Base: T)` | Composing behaviors without deep inheritance |

## Anti-Patterns

### Mutable Public Properties

```typescript
// BAD -- public mutable state, no encapsulation
class UserStore {
  users: Map<string, User> = new Map();
}

// GOOD -- private state, readonly public API
class UserStore {
  private readonly users = new Map<string, User>();

  add(user: User): void { this.users.set(user.id, user); }
  get(id: string): User | undefined { return this.users.get(id); }
  getAll(): readonly User[] { return Array.from(this.users.values()); }
}
```

### Classes With No State

```typescript
// BAD -- stateless class is just a namespace
class MathUtils {
  static add(a: number, b: number): number { return a + b; }
  static multiply(a: number, b: number): number { return a * b; }
}

// GOOD -- plain functions
const add = (a: number, b: number): number => a + b;
const multiply = (a: number, b: number): number => a * b;
```

## Summary

- Classes justify themselves through encapsulation, identity, or lifecycle -- not habit
- Define capabilities as interfaces; use classes for implementation
- Private mutable state is fine -- the public API must be readonly
- Return immutable data (readonly arrays, readonly properties) from public methods
- Prefer closures for simple, single-instance encapsulation
- Prefer plain functions over stateless classes
