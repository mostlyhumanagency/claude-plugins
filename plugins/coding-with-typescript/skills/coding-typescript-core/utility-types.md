# TypeScript Utility Types

## Table of Contents

- [Built-In Utility Types](#built-in-utility-types)
- [Custom Utility Types](#custom-utility-types)
- [String Manipulation Types](#string-manipulation-types)
- [Conditional Utility Types](#conditional-utility-types)
- [Recursive Types](#recursive-types)
- [Usage Patterns](#usage-patterns)
- [Summary](#summary)

Built-in and custom type transformations for common patterns.

## Built-In Utility Types

> **Reminder:** TS provides `Partial<T>`, `Required<T>`, `Readonly<T>`, `Record<K,V>`, `Pick<T,K>`, `Omit<T,K>`, `Exclude<T,U>`, `Extract<T,U>`, `NonNullable<T>`, `Parameters<T>`, `ReturnType<T>`, `ConstructorParameters<T>`, `InstanceType<T>`. Use these before writing custom types. The `any` in built-in definitions (e.g., `Parameters<T extends (...args: any) => any>`) mirrors TS stdlib constraints.

## Custom Utility Types

### Deep Readonly

> `DeepReadonly<T>` — see [immutability.md](immutability.md) for definition and usage patterns.

### Mutable (Remove Readonly)

```typescript
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};

interface Immutable {
  readonly id: string;
  readonly name: string;
}

type Editable = Mutable<Immutable>; // { id: string; name: string }
```

### PickByType

```typescript
type PickByType<T, ValueType> = {
  [P in keyof T as T[P] extends ValueType ? P : never]: T[P];
};

interface Mixed {
  name: string;
  age: number;
  active: boolean;
  email: string;
}

type StringProps = PickByType<Mixed, string>; // { name: string; email: string }
type NumberProps = PickByType<Mixed, number>; // { age: number }
```

### RequireAtLeastOne

```typescript
type RequireAtLeastOne<T> = {
  [K in keyof T]-?: Required<Pick<T, K>> & Partial<Pick<T, Exclude<keyof T, K>>>;
}[keyof T];

interface Filters {
  name?: string;
  age?: number;
  email?: string;
}

// Must provide at least one filter
type FilterOptions = RequireAtLeastOne<Filters>;
```

### RequireExactlyOne

```typescript
type RequireExactlyOne<T, Keys extends keyof T = keyof T> =
  Pick<T, Exclude<keyof T, Keys>> &
  {
    [K in Keys]-?:
      Required<Pick<T, K>> &
      Partial<Record<Exclude<Keys, K>, undefined>>;
  }[Keys];

type AuthMethod = RequireExactlyOne<{
  password: string;
  oauth: string;
  apiKey: string;
}>;

// Valid: { password: "secret" }
// Invalid: { password: "secret", oauth: "token" }
```

### ValueOf

```typescript
type ValueOf<T> = T[keyof T];

interface User {
  name: string;
  age: number;
  active: boolean;
}

type UserValue = ValueOf<User>; // string | number | boolean
```

### Unwrap/UnwrapPromise

```typescript
type Unwrap<T> = T extends Promise<infer U> ? U : T;

type AsyncString = Promise<string>;
type SyncString = Unwrap<AsyncString>; // string

type DeepUnwrap<T> = T extends Promise<infer U>
  ? DeepUnwrap<U>
  : T;

type Nested = Promise<Promise<Promise<string>>>;
type Flat = DeepUnwrap<Nested>; // string
```

### Paths (Type-Safe Object Paths)

```typescript
type Paths<T> = T extends object
  ? {
      [K in keyof T]: K extends string
        ? T[K] extends object
          ? K | `${K}.${Paths<T[K]>}`
          : K
        : never;
    }[keyof T]
  : never;

interface User {
  profile: {
    name: string;
    address: {
      street: string;
      city: string;
    };
  };
  age: number;
}

type UserPaths = Paths<User>;
// "profile" | "age" | "profile.name" | "profile.address" | "profile.address.street" | "profile.address.city"
```

### Immutable Collections

```typescript
type ImmutableArray<T> = readonly T[];
type ImmutableSet<T> = ReadonlySet<T>;
type ImmutableMap<K, V> = ReadonlyMap<K, V>;

type DeepImmutable<T> = T extends Map<infer K, infer V>
  ? ReadonlyMap<K, DeepImmutable<V>>
  : T extends Set<infer U>
  ? ReadonlySet<DeepImmutable<U>>
  : T extends (infer U)[]
  ? readonly DeepImmutable<U>[]
  : T extends object
  ? { readonly [P in keyof T]: DeepImmutable<T[P]> }
  : T;
```

## String Manipulation Types

Intrinsic helpers for template literal types:

```typescript
type Route = "user-profile";
type Upper = Uppercase<Route>; // "USER-PROFILE"
type Lower = Lowercase<Route>; // "user-profile"
type Capped = Capitalize<"user">; // "User"
type Uncapped = Uncapitalize<"User">; // "user"
```

Use with template literals for consistent naming conventions:

```typescript
type EventName<T extends string> = `on${Capitalize<T>}`;
type ClickEvent = EventName<"click">; // "onClick"
```

## Conditional Utility Types

Use conditional types to create reusable, type-safe transformations:

```typescript
type ElementType<T> = T extends readonly (infer U)[] ? U : T;

type A = ElementType<readonly number[]>; // number
type B = ElementType<string>; // string
```

Combine with `keyof` for type-level filtering:

```typescript
type KeysOfType<T, U> = {
  [K in keyof T]-?: T[K] extends U ? K : never
}[keyof T];

interface Mixed {
  name: string;
  age: number;
  active: boolean;
}

type StringKeys = KeysOfType<Mixed, string>; // "name"
```

## Recursive Types

Recursive conditional types let you model deep transformations:

```typescript
type DeepElement<T> =
  T extends readonly (infer U)[] ? DeepElement<U> : T;

type Flat = DeepElement<readonly (readonly number[])[]>; // number
```

Use sparingly: recursive types are powerful but can be hard to debug.

## Usage Patterns

### API Response Types

```typescript
type ApiResponse<T> = {
  data: T;
  status: number;
  message: string;
};

type PaginatedResponse<T> = ApiResponse<{
  items: readonly T[];
  total: number;
  page: number;
  pageSize: number;
}>;

type UserListResponse = PaginatedResponse<User>;
```

### Form State

```typescript
type FormState<T> = {
  values: T;
  errors: Partial<Record<keyof T, string>>;
  touched: Partial<Record<keyof T, boolean>>;
  isSubmitting: boolean;
};

interface LoginForm {
  email: string;
  password: string;
}

type LoginState = FormState<LoginForm>;
```

## Summary

- Use built-in utilities for common transformations
- Create custom utilities for domain-specific patterns
- Combine utilities for complex type manipulations
- Keep utilities focused and reusable
