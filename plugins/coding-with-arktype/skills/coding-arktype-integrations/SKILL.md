---
name: coding-arktype-integrations
description: Use when integrating ArkType with tRPC, Drizzle, React Hook Form, Hono, oRPC, or when using Standard Schema, match API, JSON Schema export, declare API, or ArkEnv.
---

# Using ArkType Integrations

## Overview

ArkType co-authors Standard Schema (alongside Zod and Valibot), enabling drop-in use with any Standard Schema-compatible library.

## tRPC

```typescript
// tRPC >= 11 — direct (Standard Schema)
t.procedure.input(type({ name: "string", "age?": "number" }))

// tRPC < 11 — pass .assert
t.procedure.input(type({ name: "string", "age?": "number" }).assert)
```

## React Hook Form

```typescript
import { arktypeResolver } from "@hookform/resolvers/arktype"
const { register, handleSubmit } = useForm({
  resolver: arktypeResolver(type({ email: "string.email", age: "number > 0" }))
})
```

## Drizzle ORM

```typescript
import { createSelectSchema } from "drizzle-arktype"
const UserSchema = createSelectSchema(users)
```

## Hono

```typescript
import { arktypeValidator } from "@hono/arktype-validator"
app.post("/user", arktypeValidator("json", User), (c) => { ... })
```

## oRPC

Supports Standard Schema natively — use ArkType types directly, no adapter needed.

## JSON Schema Export

```typescript
const schema = MyType.toJsonSchema()

// With fallbacks for unsupported types
MyType.toJsonSchema({
  fallback: {
    default: ctx => ctx.base,
    date: ctx => ({ ...ctx.base, type: "string", format: "date-time" })
  }
})
```

## Match API

Type-safe pattern matching on values:

```typescript
import { match } from "arktype"

// Case record — exhaustive by default
const sizeOf = match({
  "string | Array": v => v.length,
  number: v => v,
  bigint: v => v,
  default: "assert"    // throw on unmatched
})

// Fluent API — chain .case() calls
const classify = match({ string: v => v.length })
  .case({ length: "number" }, o => o.length)
  .default(() => 0)

// Discriminated matching
const handle = match
  .in<Event>()
  .at("type")
  .match({
    click: e => `${e.x},${e.y}`,
    keypress: e => e.key,
    default: "assert"
  })
```

Default options: `"assert"` (throw), `"never"` (accept inferred, throw), `"reject"` (return ArkErrors), or a function.

## Declare API

Validate against pre-existing TypeScript types with autocomplete:

```typescript
type User = { name: string; age?: number }

const UserType = type.declare<User>().type({
  name: "string",
  "age?": "number"
})

// With morphs — specify which side to validate
type Parsed = { value: number }
const T = type.declare<Parsed, { side: "out" }>().type({
  value: "string.numeric.parse"
})
```

## ArkEnv

Environment variable validation:

```typescript
import arkenv from "arkenv"
const env = arkenv({
  HOST: "string.host",
  PORT: "number.port",
  NODE_ENV: "'development' | 'production' | 'test' = 'development'"
})
```
