# Type Narrowing

## Overview

Use control-flow analysis to safely narrow unions. Prefer type guards, `in` checks, and discriminated unions over assertions.

## Core Narrowing Patterns

### `typeof`

```typescript
function stringify(value: string | number): string {
  if (typeof value === "string") return value;
  return value.toFixed(2);
}
```

### `instanceof`

```typescript
class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

function handle(err: Error | HttpError): number {
  if (err instanceof HttpError) return err.status;
  return 500;
}
```

### `in` Operator

```typescript
type User = { id: string; email: string };
type Service = { id: string; url: string };

type Entity = User | Service;

function getKey(e: Entity): string {
  if ("email" in e) return e.email;
  return e.url;
}
```

### Truthiness (Use Carefully)

Avoid truthiness checks when `0`, `""`, or `false` are valid values. Prefer `== null` or explicit checks.

```typescript
function formatCount(count: number | null): string {
  if (count == null) return "-";
  return count.toString();
}
```

## Discriminated Unions

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function getValue<T>(r: Result<T>): T {
  if (r.ok) return r.value;
  throw r.error;
}
```

## Exhaustiveness with `never`

```typescript
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "square"; size: number };

function area(s: Shape): number {
  switch (s.kind) {
    case "circle":
      return Math.PI * s.radius ** 2;
    case "square":
      return s.size ** 2;
    default: {
      const _exhaustive: never = s;
      return _exhaustive;
    }
  }
}
```

## User-Defined Type Guards

```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

const items: unknown[] = ["a", 1, "b"];
const strings = items.filter(isString); // string[]
```

## Assertion Functions

Use assertion functions when you want to narrow after a call that throws on failure:

```typescript
function assertString(value: unknown): asserts value is string {
  if (typeof value !== "string") throw new Error("Expected string");
}

function readName(value: unknown): string {
  assertString(value);
  return value.toUpperCase();
}
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| typeof guard | `if (typeof x === "string")` | Narrowing primitives |
| instanceof | `if (err instanceof HttpError)` | Narrowing class instances |
| in operator | `if ("email" in entity)` | Narrowing by property existence |
| Truthiness | `if (count != null)` | Guarding against null/undefined (avoid for 0/"") |
| Discriminated union | `if (r.ok)` on `{ ok: boolean }` | Narrowing tagged unions |
| Exhaustiveness | `const _: never = x` in default | Catching unhandled union members at compile time |
| Type predicate | `value is string` return type | Reusable narrowing in filter/find callbacks |
| Assertion function | `asserts value is T` | Imperative narrow-then-continue (throws on failure) |

## Common Mistakes

**Using `as` instead of narrowing (TS2352)** — `data as User` bypasses runtime checks. Use a type guard or assertion function to validate at runtime.

**Forgetting exhaustiveness check (TS2339)** — Switch without `const _: never = x` default lets new union members slip through silently. Always add the never-assignability check.

**Truthiness check on falsy values** — `if (value)` fails for `0`, `""`, and `false`. Use `value != null` or explicit comparisons when these are valid values.

**Incorrect type predicate** — A `value is T` function that returns `true` for non-T values causes unsound narrowing downstream. Keep predicate logic aligned with the asserted type.
