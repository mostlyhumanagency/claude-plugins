# Type Operators and Type Transformations

## Overview

Use type operators to derive new types from existing types. Keep transformations readable and avoid overly clever types.

## `keyof`

Get union of all property keys:

```typescript
type User = { id: string; name: string; age: number };
type UserKey = keyof User; // "id" | "name" | "age"

function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

## `typeof`

Derive type from a runtime value:

```typescript
const config = { retries: 3, timeoutMs: 1000 } as const;
type Config = typeof config; // { readonly retries: 3; readonly timeoutMs: 1000 }

// Combine with keyof for enum-like patterns
type ConfigKey = keyof typeof config; // "retries" | "timeoutMs"
```

## Indexed Access Types

Extract nested property types:

```typescript
type User = { id: string; profile: { email: string; avatar: string } };

type Email = User["profile"]["email"]; // string
type ProfileKeys = keyof User["profile"]; // "email" | "avatar"

// With arrays
type Responses = { data: string[] };
type Item = Responses["data"][number]; // string
```

## Conditional Types

### Basic Pattern

```typescript
type AsyncOrSync<T, Async extends boolean> =
  Async extends true ? Promise<T> : T;

type IsString<T> = T extends string ? true : false;
```

### `infer` — Extracting Types

```typescript
// Extract return type
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

// Extract element type from array
type ElementType<T> = T extends (infer E)[] ? E : never;

// Unwrap Promise
type Awaited<T> = T extends Promise<infer U> ? Awaited<U> : T;

// Extract function parameters
type FirstParam<T> = T extends (first: infer F, ...rest: any[]) => any ? F : never;

// Extract tuple elements
type Head<T extends any[]> = T extends [infer H, ...any[]] ? H : never;
type Tail<T extends any[]> = T extends [any, ...infer R] ? R : [];
```

### Real-World: Deep Partial

```typescript
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T;

// Usage: patch objects without requiring all nested fields
function updateConfig(patch: DeepPartial<AppConfig>): void { ... }
```

### Real-World: Extract/Exclude Patterns

```typescript
// Built-in Extract — keep members assignable to U
type StringOrNumber = Extract<string | number | boolean, string | number>;
// string | number

// Built-in Exclude — remove members assignable to U
type NoStrings = Exclude<string | number | boolean, string>;
// number | boolean

// Custom: extract object types from union by discriminant
type SuccessEvents = Extract<AppEvent, { status: "success" }>;
```

### Distributive Conditional Types

Conditional types distribute over unions by default:

```typescript
type ToArray<T> = T extends any ? T[] : never;
type Result = ToArray<string | number>; // string[] | number[]

// Prevent distribution by wrapping in tuple
type ToArrayNonDist<T> = [T] extends [any] ? T[] : never;
type Result2 = ToArrayNonDist<string | number>; // (string | number)[]
```

## Mapped Types

Transform all properties of a type:

```typescript
// Remove readonly
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};

// Make all required
type Required<T> = {
  [P in keyof T]-?: T[P];
};

// Deep readonly
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};
```

### Modifiers (`+` and `-`)

```typescript
type AddReadonly<T> = { +readonly [K in keyof T]: T[K] };    // add readonly
type RemoveReadonly<T> = { -readonly [K in keyof T]: T[K] };  // remove readonly
type AddOptional<T> = { [K in keyof T]+?: T[K] };            // add optional
type RemoveOptional<T> = { [K in keyof T]-?: T[K] };         // remove optional
```

### Key Remapping with `as`

```typescript
// Rename keys
type Getters<T> = {
  [P in keyof T as `get${Capitalize<string & P>}`]: () => T[P];
};
type UserGetters = Getters<{ name: string; age: number }>;
// { getName: () => string; getAge: () => number }

// Filter keys
type OnlyStrings<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};

// Remove specific keys
type OmitId<T> = {
  [K in keyof T as K extends "id" ? never : K]: T[K];
};
```

## Template Literal Types

String-pattern types for type-safe naming:

```typescript
// Event handler names
type EventName = "click" | "focus" | "blur";
type HandlerName = `on${Capitalize<EventName>}`;
// "onClick" | "onFocus" | "onBlur"

// API routes
type ApiRoute = `/api/${string}`;
type CrudRoute = `/api/${string}/${"create" | "read" | "update" | "delete"}`;

// CSS units
type CSSLength = `${number}${"px" | "em" | "rem" | "%"}`;
```

### Combining with Mapped Types

```typescript
// Type-safe event emitter
type EventMap = {
  click: { x: number; y: number };
  focus: { target: HTMLElement };
};

type EventHandlers<T extends Record<string, unknown>> = {
  [K in keyof T as `on${Capitalize<string & K>}`]: (event: T[K]) => void;
};

type Handlers = EventHandlers<EventMap>;
// { onClick: (event: { x: number; y: number }) => void;
//   onFocus: (event: { target: HTMLElement }) => void; }
```

### Intrinsic String Manipulation Types

```typescript
type Upper = Uppercase<"hello">;       // "HELLO"
type Lower = Lowercase<"HELLO">;       // "hello"
type Cap = Capitalize<"hello">;        // "Hello"
type Uncap = Uncapitalize<"Hello">;    // "hello"
```

## Combining Operators

Real-world patterns that combine multiple operators:

### Type-Safe Object.fromEntries

```typescript
type FromEntries<T extends readonly [string, unknown][]> = {
  [K in T[number] as K extends [infer Key, any] ? Key & string : never]:
    K extends [any, infer Value] ? Value : never;
};
```

### Builder Pattern Types

```typescript
type Builder<T, Built extends Partial<T> = {}> = {
  [K in keyof T as K extends keyof Built ? never : K]:
    (value: T[K]) => Builder<T, Built & Pick<T, K>>;
} & (keyof T extends keyof Built ? { build(): T } : {});
```

## Quick Reference

| Operator | Syntax | Use When |
|---|---|---|
| keyof | `keyof T` | Getting union of property keys |
| typeof | `typeof value` | Deriving type from runtime value |
| Indexed access | `T["prop"]` | Extracting nested property type |
| Array element | `T[number]` | Getting element type of array/tuple |
| Conditional | `T extends U ? A : B` | Type-level branching |
| infer | `T extends (...) => infer R ? R : never` | Extracting types inside conditional |
| Distributive | `T extends any ? ... : never` | Map over union members |
| Non-distributive | `[T] extends [any] ? ... : never` | Prevent union distribution |
| Mapped | `{ [K in keyof T]: ... }` | Transforming all properties |
| Mapped + modifier | `{ -readonly [K in keyof T]-?: ... }` | Adding/removing readonly/optional |
| Key remapping | `[K in keyof T as ...]` | Renaming/filtering keys |
| Template literal | `` `on${Capitalize<E>}` `` | String-pattern types |
| Intrinsic string | `Uppercase<T>`, `Capitalize<T>` | Transforming string literal types |

## Common Mistakes

**Overly complex mapped types (TS2589)** — Deeply nested mapped or conditional types can hit the recursion limit. Simplify or split into intermediate type aliases.

**Forgetting distributive behavior (TS2344)** — `ToArray<string | number>` distributes to `string[] | number[]`, not `(string | number)[]`. Wrap in tuple `[T]` to prevent distribution.

**Indexed access on optional properties (TS2536)** — `T["prop"]` fails if `prop` may not exist on `T`. Add a constraint: `T extends { prop: infer P }`.

**Template literal explosion (TS2590)** — Large unions in template literals can explode combinatorially. Keep union inputs small or use `string` as escape hatch.

**Missing string constraint in key remapping** — `` as `get${Capitalize<K>}` `` requires `K` to be a string. Use `string & K` or add `K extends string` constraint.

**Recursive types without base case** — `type Deep<T> = { [K in keyof T]: Deep<T[K]> }` recurses infinitely on primitives. Add `T extends object ? ... : T` guard.

## Performance Considerations

- Conditional types with `infer` create new type instantiations — keep nesting shallow
- Large mapped types over big unions are expensive — consider splitting
- Template literal types with multiple union inputs create cartesian products
- Use intermediate type aliases to help the compiler cache results
- If hitting TS2589 (too deep), break into smaller helper types

## Guidance

- Prefer simple unions or overloads when type operators add more complexity than safety.
- Use `satisfies` to validate shapes without widening (see `coding-typescript-core`).
- Name intermediate types — `type X = ...` helps both readability and compiler performance.
- Test complex types with `// ^?` twoslash queries or `tsd` / `expect-type`.
