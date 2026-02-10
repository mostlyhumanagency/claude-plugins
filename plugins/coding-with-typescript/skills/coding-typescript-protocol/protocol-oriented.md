# Protocol-Oriented Programming in TypeScript

## Table of Contents

- [Overview](#overview)
- [Core Concepts](#core-concepts)
- [Patterns](#patterns)
- [vs. Traditional OOP](#vs-traditional-oop)
- [When to Use](#when-to-use)
- [Common Patterns](#common-patterns)
- [Anti-Patterns](#anti-patterns)
- [Summary](#summary)

## Overview

Design with small, focused interfaces composed via `&`. Model capabilities, not inheritance hierarchies.

## Core Concepts

### Small Capability Interfaces

Define single-purpose contracts:

```typescript
interface Identifiable {
  readonly id: string;
}

interface Timestamped {
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface Serializable {
  toJSON(): Record<string, unknown>;
}

interface Validatable<T> {
  validate(): Result<T>;
}
```

### Interface Composition

Combine with intersection types:

```typescript
// Compose capabilities
type Entity = Identifiable & Timestamped;
type PersistedEntity = Entity & Serializable & Validatable<unknown>;

// Use satisfies to validate conformance
const user = {
  id: "u_42",
  createdAt: new Date(),
  updatedAt: new Date(),
  toJSON: () => ({ id: "u_42" }),
  validate: () => ({ ok: true, value: undefined })
} satisfies PersistedEntity;
```

You can also compose via `extends` for named protocols:

```typescript
interface Entity extends Identifiable, Timestamped {}

interface PersistedEntity extends Entity, Serializable, Validatable<unknown> {}
```

### Protocol Extensions via Free Functions

TypeScript lacks Swift's protocol extensions. Use constrained functions:

```typescript
// Protocol
interface Comparable<T> {
  compareTo(other: T): number;
}

// "Extension" via free function
function lessThan<T extends Comparable<T>>(a: T, b: T): boolean {
  return a.compareTo(b) < 0;
}

function greaterThan<T extends Comparable<T>>(a: T, b: T): boolean {
  return a.compareTo(b) > 0;
}

// Use it
class Price implements Comparable<Price> {
  constructor(readonly amount: number) {}

  compareTo(other: Price): number {
    return this.amount - other.amount;
  }
}

const p1 = new Price(10);
const p2 = new Price(20);
lessThan(p1, p2); // true
```

## Patterns

### Dependency Injection via Protocols

```typescript
interface Logger {
  log(message: string): void;
  error(message: string): void;
}

interface Database {
  query<T>(sql: string): Promise<T[]>;
}

interface EmailService {
  send(to: string, subject: string, body: string): Promise<void>;
}

// Service depends on protocols, not concrete types
class UserService {
  constructor(
    private db: Database,
    private logger: Logger,
    private email: EmailService
  ) {}

  async createUser(data: UserData): Promise<User> {
    this.logger.log("Creating user");
    const user = await this.db.query<User>("INSERT...");
    await this.email.send(user.email, "Welcome", "...");
    return user[0];
  }
}

// Swap implementations easily
const service = new UserService(
  new PostgresDB(),
  new ConsoleLogger(),
  new SendGridEmail()
);
```

### Generic Protocols

```typescript
interface Repository<T extends Identifiable> {
  findById(id: string): Promise<T | null>;
  findAll(): Promise<readonly T[]>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<boolean>;
}

class InMemoryRepository<T extends Identifiable> implements Repository<T> {
  private data = new Map<string, T>();

  async findById(id: string): Promise<T | null> {
    return this.data.get(id) ?? null;
  }

  async save(entity: T): Promise<T> {
    // Defensive copy for immutability
    this.data.set(entity.id, { ...entity });
    return entity;
  }

  async findAll(): Promise<readonly T[]> {
    return Array.from(this.data.values());
  }

  async delete(id: string): Promise<boolean> {
    return this.data.delete(id);
  }
}
```

### Type-Safe Protocol Composition

```typescript
// Domain protocols
interface Cacheable {
  getCacheKey(): string;
  getCacheTTL(): number;
}

interface Loggable {
  toLogEntry(): string;
}

// Compose for specific use cases
type CacheableEntity = Entity & Cacheable;
type AuditableEntity = Entity & Loggable & Timestamped;

// Generic function works with any composition
function cacheEntity<T extends Identifiable & Cacheable>(
  entity: T,
  cache: Cache
): void {
  cache.set(entity.getCacheKey(), entity, entity.getCacheTTL());
}
```

### Retroactive Conformance via Structural Typing

TypeScript's structural typing allows implicit conformance:

```typescript
// External type you don't control
class ThirdPartyUser {
  constructor(
    public userId: string,
    public userName: string
  ) {}
}

// Your protocol
interface Identifiable {
  readonly id: string;
}

// Adapter for explicit conformance
function makeIdentifiable<T extends { userId: string }>(obj: T): T & Identifiable {
  return {
    ...obj,
    id: obj.userId
  };
}

const adapted = makeIdentifiable(new ThirdPartyUser("123", "Alice"));
adapted.id; // "123"
```

**Compatibility caveat:** private/protected members affect structural typing. Two classes with private members are only compatible if they share the same declaration, so prefer protocol interfaces at boundaries.

## vs. Traditional OOP

### Inheritance Hierarchy (OOP)

```typescript
// ❌ Rigid, coupled
class User {
  readContent() { }
}

class Author extends User {
  writeContent() { }
}

class Admin extends Author {
  deleteContent() { }
}

// Can't create Moderator (read + delete, no write) without refactoring
```

### Protocol Composition (POP)

```typescript
// ✅ Flexible, decoupled
interface CanRead {
  readContent(): void;
}

interface CanWrite {
  writeContent(): void;
}

interface CanDelete {
  deleteContent(): void;
}

type Guest = CanRead;
type Author = CanRead & CanWrite;
type Admin = CanRead & CanWrite & CanDelete;
type Moderator = CanRead & CanDelete; // Easy to add
```

## When to Use

**Use protocols when:**
- Multiple types share behavior without inheritance
- Need to mix capabilities freely
- Want to decouple dependencies
- Testing requires swappable implementations

**Use classes when:**
- Need true encapsulation with private state
- Identity semantics matter
- Single concrete implementation suffices

## Common Patterns

### Functional Core with Protocol Boundaries

```typescript
// Pure domain logic
interface OrderValidator {
  canConfirm(order: Order): ValidationResult;
}

const validator: OrderValidator = {
  canConfirm(order) {
    return order.items.length > 0 && order.total > 0
      ? { valid: true }
      : { valid: false, errors: ["Invalid order"] };
  }
};

// Shell coordinates I/O
class OrderService {
  constructor(
    private repo: Repository<Order>,
    private validator: OrderValidator
  ) {}

  async confirmOrder(id: string): Promise<Result<Order>> {
    const order = await this.repo.findById(id);
    if (!order) return { ok: false, error: "Not found" };

    const validation = this.validator.canConfirm(order);
    if (!validation.valid) {
      return { ok: false, error: validation.errors.join(", ") };
    }

    const confirmed = { ...order, status: "confirmed" };
    await this.repo.save(confirmed);
    return { ok: true, value: confirmed };
  }
}
```

### Protocol Witnesses (Type Class Pattern)

```typescript
// Protocol for equality
interface Eq<A> {
  equals(x: A, y: A): boolean;
}

// Witness instances
const eqNumber: Eq<number> = {
  equals: (x, y) => x === y
};

const eqString: Eq<string> = {
  equals: (x, y) => x === y
};

// Generic function constrained by protocol
function includes<A>(eq: Eq<A>, xs: readonly A[], x: A): boolean {
  return xs.some(y => eq.equals(x, y));
}

includes(eqNumber, [1, 2, 3], 2); // true
includes(eqString, ["a", "b"], "c"); // false
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Capability interface | `interface Identifiable { id: string }` | Single-responsibility contract |
| Composition | `type Entity = A & B & C` | Mixing capabilities freely |
| extends composition | `interface Entity extends A, B` | Named protocol combining interfaces |
| Protocol extension | Free function `fn<T extends Proto>(x: T)` | Adding behavior to a protocol without classes |
| DI via protocols | `constructor(private dep: Interface)` | Swappable implementations, testability |
| Generic protocol | `Repository<T extends Identifiable>` | Reusable typed contracts |
| Retroactive conformance | Adapter function mapping fields | Making third-party types fit your protocols |
| Protocol witness | `Eq<A>`, `Monoid<A>` objects | Type-class pattern for polymorphic behavior |

## Anti-Patterns

### ❌ God Interfaces

```typescript
// BAD - too many responsibilities
interface UserManager {
  authenticate(): void;
  updateProfile(): void;
  sendEmail(): void;
  logActivity(): void;
  calculatePermissions(): void;
}
```

### ❌ Premature Abstraction (with nuance)

```typescript
// BAD - interface with single implementation AND no testing need
interface UserRepository {
  save(user: User): void;
}

class UserRepositoryImpl implements UserRepository {
  save(user: User): void { /* only impl */ }
}

// GOOD - concrete class when interface doesn't earn its keep
class UserRepository {
  save(user: User): void { }
}
```

**When interfaces earn their keep early:**
- **Testing** — you need an InMemory or mock implementation
- **Module boundaries** — the interface is the public contract of a module
- **Second implementation likely** — you're already planning for it

Don't wait for the second production implementation if testing or module boundaries justify the interface now.

### ❌ Leaky Abstractions

```typescript
// BAD - protocol exposes implementation details
interface Database {
  getMongoClient(): MongoClient; // leaks MongoDB
}

// GOOD - protocol hides implementation
interface Database {
  query<T>(collection: string, filter: unknown): Promise<T[]>;
}
```

## Summary

- Define small, focused interfaces (single responsibility)
- Compose with `&` for flexible capability mixing
- Use generic constraints for type-safe protocols
- Depend on interfaces, not concrete types
- Test with protocol-conforming mocks
