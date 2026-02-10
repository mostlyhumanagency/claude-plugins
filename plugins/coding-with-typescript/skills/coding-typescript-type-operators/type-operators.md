# Type Operators and Type Transformations

## Overview

Use type operators to derive new types from existing types. Keep transformations readable and avoid overly clever types.

## `keyof`

```typescript
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

## `typeof`

```typescript
const config = { retries: 3, timeoutMs: 1000 };

type Config = typeof config;
```

## Indexed Access Types

```typescript
type User = { id: string; profile: { email: string } };

type Email = User["profile"]["email"];
```

## Conditional Types

```typescript
type AsyncOrSync<T, Async extends boolean> =
  Async extends true ? Promise<T> : T;
```

### `infer` in Conditional Types

```typescript
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;
type ElementType<T> = T extends (infer E)[] ? E : never;
```

### Distributive Conditional Types

```typescript
type ToArray<T> = T extends any ? T[] : never;
// Distributes over unions

type ToArrayNonDist<T> = [T] extends [any] ? T[] : never;
```

## Mapped Types

```typescript
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};
```

### Key Remapping

```typescript
type Getters<T> = {
  [P in keyof T as `get${Capitalize<string & P>}`]: () => T[P];
};
```

## Template Literal Types

```typescript
type EventName = "click" | "focus" | "blur";
type HandlerName = `on${Capitalize<EventName>}`;

// API routes
type ApiRoute = `/api/${string}`;
```

## Quick Reference

| Operator | Syntax | Use When |
|---|---|---|
| keyof | `keyof T` | Getting union of property keys |
| typeof | `typeof value` | Deriving type from runtime value |
| Indexed access | `T["prop"]` | Extracting nested property type |
| Conditional | `T extends U ? A : B` | Type-level branching |
| infer | `T extends (...) => infer R ? R : never` | Extracting types inside conditional |
| Mapped | `{ [K in keyof T]: ... }` | Transforming all properties of a type |
| Key remapping | `[K in keyof T as ...]` | Renaming/filtering keys in mapped types |
| Template literal | `` `on${Capitalize<E>}` `` | String-pattern types |

## Common Mistakes

**Overly complex mapped types (TS2589)** — Deeply nested mapped or conditional types can hit the recursion limit. Simplify or split into intermediate type aliases.

**Forgetting distributive behavior (TS2344)** — `ToArray<string | number>` distributes to `string[] | number[]`, not `(string | number)[]`. Wrap in tuple `[T]` to prevent distribution.

**Indexed access on optional properties (TS2536)** — `T["prop"]` fails if `prop` may not exist on `T`. Add a constraint: `T extends { prop: infer P }`.

**Template literal excess (TS2590)** — Large unions in template literals can explode combinatorially. Keep union inputs small or use `string` as escape hatch.

## Guidance

- Prefer simple unions or overloads when transformations add complexity.
- Use `satisfies` to validate shapes without widening (see `coding-typescript-core`).
