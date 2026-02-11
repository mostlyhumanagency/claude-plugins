---
name: coding-arktype-scopes
description: "Use when organizing multiple related types, creating recursive or cyclic schemas, reusing type definitions across files, building type modules, defining generics, or using scopes, submodules, and private aliases in ArkType. Also use when types need to reference each other by name."
---

# Using ArkType Scopes

## Overview

Scopes let you define named types that reference each other — enabling cyclic types, type reuse, and modular organization. Types defined in a scope can reference other aliases in that scope by name.

## Creating a Scope

```typescript
import { scope } from "arktype"

const $ = scope({
  Id: "string",
  User: { id: "Id", name: "string", "friends?": "User[]" },
  UsersById: { "[Id]": "User | undefined" }
})
const types = $.export()

const out = types.User({ id: "1", name: "Ada", friends: [] })
```

**Critical rule:** Never wrap definitions in `type()` inside a scope — alias references only resolve within the scope's own definitions.

```typescript
// WRONG — "Id" won't resolve
const $ = scope({ Id: "string", User: type({ id: "Id" }) })

// RIGHT
const $ = scope({ Id: "string", User: { id: "Id" } })
```

## Inline Modules

```typescript
const myModule = type.module({
  User: { name: "string", email: "string.email" },
  Admin: { "...": "User", role: "'admin'" }
})
```

## Cyclic Types

```typescript
const types = scope({
  Package: {
    name: "string",
    "dependencies?": "Package[]",
    "contributors?": "Contributor[]"
  },
  Contributor: {
    email: "string.email",
    "packages?": "Package[]"
  }
}).export()
```

## Private Aliases

Prefix with `#` to exclude from export:

```typescript
const $ = scope({
  "#Base": { id: "string", createdAt: "Date" },
  User: { "...": "Base", name: "string" },
  Post: { "...": "Base", title: "string" }
})
// $.export() includes User and Post, not Base
```

## Spreading and Composing Modules

```typescript
const combined = scope({
  ...authModule.export(),
  ...dataModule.export("User", "Post"),  // selective export
  Dashboard: { user: "User", posts: "Post[]" }
})
```

Use `.import()` to auto-privatize spread types:

```typescript
const app = type.module({
  ...authScope.import(),       // all auth types private
  Payload: { user: "User" }   // can reference User internally
})
```

## Submodules

```typescript
const sub = type.module({ Item: { name: "string" } })
const root = scope({
  main: "sub.Item[]",
  sub
}).export()
```

### Rooted Submodules

A submodule with a `root` key becomes directly callable:

```typescript
const User = type.module({
  root: { name: "string" },
  Admin: { "...": "root", isAdmin: "true" }
})

const types = type.module({
  User,                                    // User is callable (uses root)
  AdminList: "User.Admin[]"               // access submodule members
})
```

## Thunks (Fluent API in Scopes)

Use arrow functions to access the scope variable for chaining:

```typescript
const $ = scope({
  Id: "string#id",
  UserOrId: () =>
    $.type({ name: "string", id: "Id" })
      .or("Id")
      .pipe(v => typeof v === "string" ? { id: v, name: "Anon" } : v)
})
```

## Generics

See `reference.md` for full generics API.

```typescript
// Inline generic
type("<t>", { box: "t" })

// Constrained
type("<arr extends unknown[]>", "arr > 0")

// In scopes
const $ = scope({
  "box<t>": { value: "t" },
  StringBox: "box<string>"
})
```

Built-in generics: `Record`, `Pick`, `Omit`, `Partial`, `Required`, `Merge`, `Extract`, `Exclude`

## Common Mistakes

- **Wrapping scope defs in `type()`** — alias names like `"Id"` only resolve within scope definitions, not inside standalone `type()` calls.
- **Forgetting `.export()`** — scopes aren't usable until exported. Call `$.export()` to get the module.
- **Recursive generics** — not currently supported. Use scoped cyclic types instead.
- **Thunk arrow functions** — needed when using fluent methods (`.or()`, `.pipe()`) inside scopes. Plain object syntax can't chain.
