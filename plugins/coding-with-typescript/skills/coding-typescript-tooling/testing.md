# Type-Safe Testing Patterns in TypeScript

Leverage the type system in tests. Protocol interfaces replace mock frameworks. Factories produce valid data. Helpers preserve narrowing through assertions.

## Table of Contents

- [Type-Safe Mocks](#type-safe-mocks)
- [Test Factories](#test-factories)
- [Type-Safe Test Helpers](#type-safe-test-helpers)
- [Testing with Protocols](#testing-with-protocols)
- [Testing Discriminated Unions](#testing-discriminated-unions)
- [Anti-Patterns](#anti-patterns)
- [Summary](#summary)

## Type-Safe Mocks

Small interfaces make test doubles trivial. The compiler verifies completeness:

```typescript
interface UserRepository {
  findById(id: string): Promise<User | undefined>;
  save(user: User): Promise<User>;
}

class StubUserRepository implements UserRepository {
  private users = new Map<string, User>();
  async findById(id: string) { return this.users.get(id); }
  async save(user: User) { this.users.set(user.id, user); return user; }
  seed(user: User) { this.users.set(user.id, user); }
}
```

For single-method interfaces, inline objects or spy factories suffice:

```typescript
interface SendEmail {
  send(to: string, subject: string, body: string): Promise<void>;
}
const noopEmail: SendEmail = { send: async () => {} };

// Spy records calls for assertion
function spyEmail() {
  const calls: Array<{ to: string; subject: string }> = [];
  return { send: async (to: string, subject: string) => { calls.push({ to, subject }); }, calls };
}
```

## Test Factories

Build valid defaults, override selectively. Tests express only what matters:

```typescript
function createTestUser(overrides?: Partial<User>): User {
  return {
    id: "user-1", name: "Alice", email: "alice@test.com",
    role: "member", createdAt: new Date("2024-01-01"),
    ...overrides,
  };
}
const admin = createTestUser({ role: "admin" });
const bob = createTestUser({ name: "Bob", email: "bob@test.com" });
```

Compose factories for nested structures. Each factory owns its defaults:

```typescript
function createTestOrder(overrides?: Partial<Order>): Order {
  return { id: "order-1", user: createTestUser(), status: "pending",
    items: [{ productId: "prod-1", quantity: 1, unitPrice: 9.99 }], ...overrides };
}
```

## Type-Safe Test Helpers

Return narrowed values so subsequent code stays fully typed:

```typescript
function assertOk<T, E>(result: Result<T, E>): T {
  if (!result.ok) throw new Error(`Expected ok, got: ${String(result.error)}`);
  return result.value;
}
function assertErr<T, E>(result: Result<T, E>): E {
  if (result.ok) throw new Error(`Expected error, got ok`);
  return result.error;
}

const user = assertOk(await service.getUser("u-1")); // ^? User
const error = assertErr(await service.getUser("bad")); // ^? Error
```

Narrow discriminated union variants via `Extract`:

```typescript
function assertVariant<U extends { readonly kind: string }, K extends U["kind"]>(
  value: U, kind: K,
): Extract<U, { readonly kind: K }> {
  if (value.kind !== kind) throw new Error(`Expected "${kind}", got "${value.kind}"`);
  // TS cannot narrow generic unions via control flow — cast is sound after runtime check
  return value as Extract<U, { readonly kind: K }>;
}
const click = assertVariant(event, "click");
click.x; // number - fully narrowed, no cast needed
```

## Testing with Protocols

Implement interfaces directly -- deterministic, no mocking framework:

```typescript
interface Clock { now(): Date; }
interface IdGenerator { next(): string; }

function fixedClock(date: Date): Clock { return { now: () => date }; }
function sequentialIds(prefix = "id"): IdGenerator {
  let n = 0; return { next: () => `${prefix}-${++n}` };
}

class InMemoryRepository<T extends { readonly id: string }> implements Repository<T> {
  private readonly data = new Map<string, T>();
  async findById(id: string) { return this.data.get(id); }
  async findAll() { return [...this.data.values()]; }
  async save(entity: T) { this.data.set(entity.id, entity); return entity; }
  async delete(id: string) { return this.data.delete(id); }
}
```

Bundle doubles into a typed deps factory for one-line test setup:

```typescript
function createTestDeps(overrides?: Partial<ServiceDeps>): ServiceDeps {
  return { repo: new InMemoryRepository<User>(), clock: fixedClock(new Date("2024-01-01")),
    ids: sequentialIds(), email: noopEmail, ...overrides };
}
```

## Testing Discriminated Unions

One test case per variant, no gaps:

```typescript
type PaymentResult =
  | { readonly status: "success"; readonly transactionId: string }
  | { readonly status: "declined"; readonly reason: string }
  | { readonly status: "pending"; readonly retryAfter: number };

handlePayment({ status: "success", transactionId: "tx-123" });
handlePayment({ status: "declined", reason: "insufficient funds" });
handlePayment({ status: "pending", retryAfter: 5000 });
```

Use `never` as an exhaustiveness guard -- adding a variant without a case is a compile error:

```typescript
function assertNever(value: never): never {
  throw new Error(`Unhandled: ${JSON.stringify(value)}`);
}
function handlePayment(result: PaymentResult): string {
  switch (result.status) {
    case "success": return result.transactionId;
    case "declined": return result.reason;
    case "pending": return String(result.retryAfter);
    default: return assertNever(result); // compile error if a variant is missing
  }
}
```

## Anti-Patterns

**`as any` in tests** -- hides type errors; tests pass but production breaks. Implement the interface instead so the compiler verifies completeness.

```typescript
// BAD
const repo = { findById: () => null } as any;
// GOOD
const repo: UserRepository = { findById: async () => undefined, save: async (u) => u };
```

**`@ts-ignore` / `@ts-expect-error`** -- suppresses real errors alongside intentional ones. Validate through the same path production code uses.

**Testing implementation details** -- accessing `(service as any).internalCache` couples tests to internals. Test observable behavior through the public interface.

**Incomplete union coverage** -- only testing the happy path means new variants slip through. Test every variant. Use `assertNever` so the compiler catches gaps.

## Summary

- Implement protocol interfaces directly instead of casting mocks with `as any`
- Use factory functions with `Partial<T>` overrides for test data
- Write assertion helpers that return narrowed types (`assertOk<T>` returns `T`)
- Prefer InMemory implementations over mocking frameworks
- Test every variant of discriminated unions; use `assertNever` for compile-time coverage
- No `as any`, no `@ts-ignore`, no testing private internals
