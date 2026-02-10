# ArkType Scopes and Generics Reference

## Scope API

| Method | Description |
|---|---|
| `scope({...})` | Create a new scope with named type definitions |
| `$.export()` | Export all public types as a module |
| `$.export("A", "B")` | Export only named types |
| `$.import()` | Export all types as private (for spreading) |
| `$.type(def)` | Create a type within the scope (for thunks) |
| `type.module({...})` | Inline scope creation + export |

## Scope Definition Syntax

```typescript
const $ = scope({
  // Simple alias
  Id: "string",

  // Object type referencing aliases
  User: { id: "Id", name: "string" },

  // Array of aliased type
  UserList: "User[]",

  // Union with alias
  IdOrUser: "Id | User",

  // Private alias (excluded from export)
  "#Internal": { secret: "string" },

  // Generic definition
  "Box<t>": { value: "t" },

  // Thunk (for fluent API chains)
  Processed: () => $.type("string").pipe(s => s.trim())
})
```

## Module Composition Patterns

### Spread public types
```typescript
const combined = scope({
  ...moduleA.export(),
  ...moduleB.export(),
  Combined: { a: "TypeFromA", b: "TypeFromB" }
})
```

### Spread as private (import)
```typescript
const app = type.module({
  ...utilScope.import(),        // all util types become private
  Public: { helper: "UtilType" }
})
```

### Selective export
```typescript
const partial = $.export("User", "Post")  // only User and Post
```

### Submodule nesting
```typescript
const sub = type.module({ Item: { name: "string" } })
const root = scope({ items: "sub.Item[]", sub }).export()
```

### Rooted submodule
```typescript
const User = type.module({
  root: { name: "string" },           // makes User directly callable
  Admin: { "...": "root", admin: "true" }
})

const types = type.module({
  User,                                // User(data) validates against root
  Admins: "User.Admin[]"              // dot access to submodule types
})
```

## Generics

### Inline Declaration

```typescript
// Single parameter
const Box = type("<t>", { value: "t" })

// Multiple parameters
const Pair = type("<a, b>", { first: "a", second: "b" })

// Constrained parameter
const NonEmpty = type("<arr extends unknown[]>", "arr > 0")

// Default parameter
const Container = type("<t = string>", { value: "t" })
```

### In Scopes

```typescript
const $ = scope({
  "Box<t>": { value: "t" },
  "Pair<a, b>": { first: "a", second: "b" },
  StringBox: "Box<string>",
  NumPair: "Pair<number, number>"
})
```

### Invoking Generics

```typescript
// String syntax
type("Record<string, number>")
type("Pick<User, 'name' | 'email'>")
type("Extract<0 | 1, 1>")

// Fluent methods
User.pick("name", "email")
User.omit("password")
User.partial()
User.required()
```

### Built-in Generic Keywords

| Generic | Description |
|---|---|
| `Record<K, V>` | Object with key type K and value type V |
| `Pick<T, K>` | Pick properties K from T |
| `Omit<T, K>` | Omit properties K from T |
| `Partial<T>` | All properties optional |
| `Required<T>` | All properties required |
| `Merge<A, B>` | Merge two object types |
| `Extract<T, U>` | Extract union members matching U |
| `Exclude<T, U>` | Exclude union members matching U |

### HKT (Higher-Kinded Types)

For advanced generic type manipulation:

```typescript
import { generic, Hkt } from "arktype"

const MyPartial = generic(["T", "object"])(
  args => args.T.partial(),
  class extends Hkt<[object]> {
    declare body: Partial<this[0]>
  }
)
```

**Limitation:** Recursive and cyclic generics are not currently supported. Use scoped cyclic types instead.
