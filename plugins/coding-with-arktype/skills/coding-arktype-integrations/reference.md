# ArkType Integrations Reference

## Version Compatibility Matrix

| Integration | Package | ArkType Version | Library Version | Adapter |
|---|---|---|---|---|
| tRPC (Standard Schema) | `@trpc/server` | >= 2.0 | >= 11 | None (native) |
| tRPC (legacy) | `@trpc/server` | any | < 11 | `.assert` method |
| React Hook Form | `@hookform/resolvers` | >= 2.0 | >= 3.0 | `@hookform/resolvers/arktype` |
| Drizzle ORM | `drizzle-arktype` | >= 2.0 | `drizzle-orm` >= 0.30 | `drizzle-arktype` |
| Hono | `@hono/arktype-validator` | >= 2.0 | `hono` >= 4.0 | `@hono/arktype-validator` |
| oRPC | `@orpc/server` | >= 2.0 | any | None (Standard Schema native) |
| Tanstack Form | `@tanstack/form` | >= 2.0 | >= 0.20 | None (Standard Schema native) |

### tRPC Integration Details

```typescript
// tRPC >= 11 — Standard Schema, no adapter
import { type } from "arktype"
import { initTRPC } from "@trpc/server"

const t = initTRPC.create()
const router = t.router({
  createUser: t.procedure
    .input(type({ name: "string", email: "string.email" }))
    .mutation(({ input }) => {
      // input is typed as { name: string; email: string }
    })
})

// tRPC < 11 — pass .assert as validator
const router = t.router({
  createUser: t.procedure
    .input(type({ name: "string", email: "string.email" }).assert)
    .mutation(({ input }) => { ... })
})
```

## Standard Schema Spec

ArkType co-authors the Standard Schema specification (alongside Zod and Valibot). Any library that accepts Standard Schema validators works with ArkType out of the box.

| Property | Type | Description |
|---|---|---|
| `~standard.version` | `1` | Standard Schema spec version |
| `~standard.vendor` | `"arktype"` | Vendor identifier |
| `~standard.validate(value)` | `StandardResult` | Validate and return `{ value }` or `{ issues }` |
| `~standard.types.input` | type | TypeScript input type (compile-time only) |
| `~standard.types.output` | type | TypeScript output type (compile-time only) |

```typescript
// Any ArkType type is already a Standard Schema
const User = type({ name: "string", age: "number" })

// Works with any Standard Schema consumer
someLibrary.validate(User)  // no wrapper needed
```

## Match API Reference

### Match Initialization

| Form | Description |
|---|---|
| `match({ ... })` | Case record with string type keys |
| `match.in<T>()` | Constrain input type, then chain `.match({})` |
| `match.in<T>().at(key)` | Discriminated match on a specific property |
| `match({}).case(def, handler)` | Fluent case chaining |

### Case Record Syntax

```typescript
const handle = match({
  string: v => v.length,          // v: string
  number: v => v.toFixed(2),      // v: number
  "string[]": v => v.join(", "),  // v: string[]
  default: "assert"               // see default options below
})
```

### Fluent .case() API

```typescript
const classify = match({ string: v => `text:${v}` })
  .case("number", v => `num:${v}`)
  .case({ name: "string" }, v => `obj:${v.name}`)
  .default(() => "unknown")
```

### Discriminated .at() Matching

```typescript
type Event =
  | { type: "click"; x: number; y: number }
  | { type: "keypress"; key: string }

const describe = match
  .in<Event>()
  .at("type")
  .match({
    click: e => `clicked at ${e.x},${e.y}`,
    keypress: e => `pressed ${e.key}`,
    default: "assert"
  })
```

### Default Options

| Option | Behavior |
|---|---|
| `"assert"` | Throw `ArkError` on unmatched input |
| `"never"` | Accept only inputs already covered by cases (TS error if not exhaustive), throw at runtime |
| `"reject"` | Return `ArkErrors` on unmatched input (does not throw) |
| `(v) => result` | Custom fallback function |

## Declare API Reference

Validate a runtime type definition against a pre-existing TypeScript type.

| Method | Description |
|---|---|
| `type.declare<T>()` | Declare the expected output type |
| `type.declare<T, { side: "in" }>()` | Declare the expected input type |
| `type.declare<T, { side: "out" }>()` | Declare the expected output type (explicit) |
| `.type(def)` | Provide the runtime definition — errors if it does not match `T` |

```typescript
// Basic: output must match User
interface User { name: string; age?: number }
const UserType = type.declare<User>().type({
  name: "string",
  "age?": "number"
})

// With morph: validate the output side
interface Parsed { value: number }
const T = type.declare<Parsed, { side: "out" }>().type({
  value: "string.numeric.parse"   // input is string, output is number
})

// With morph: validate the input side
interface RawInput { value: string }
const T2 = type.declare<RawInput, { side: "in" }>().type({
  value: "string.numeric.parse"
})
```

### Declare Constraints

If `T` and the runtime definition diverge, TypeScript reports a compile-time error. This catches:

| Mismatch | Example |
|---|---|
| Missing property | Declared `{ a: string; b: number }` but defined `{ a: "string" }` |
| Extra property | Defined a key not present in `T` |
| Wrong type | Declared `string` but defined `"number"` |
| Wrong morph side | Used `side: "out"` but definition input does not transform to `T` |

## ArkEnv Reference

Environment variable validation using ArkType syntax. Reads from `process.env` by default.

```typescript
import arkenv from "arkenv"

const env = arkenv({
  HOST: "string.host",
  PORT: "number.port",
  NODE_ENV: "'development' | 'production' | 'test' = 'development'",
  DEBUG: "boolean = false",
  DATABASE_URL: "string.url",
  API_KEY: "string > 0",
  MAX_RETRIES: "number.integer >= 0 = 3"
})
```

### Supported Syntax

| Syntax | Description |
|---|---|
| `"string"` | Any string (most env vars) |
| `"string.email"` | Email-validated string |
| `"string.url"` | URL-validated string |
| `"string.host"` | Hostname or IP |
| `"string.ip"` | IPv4 or IPv6 |
| `"number"` | Parsed as number from string |
| `"number.port"` | Integer 0-65535 |
| `"number.integer"` | Parsed integer |
| `"boolean"` | `"true"` / `"false"` / `"1"` / `"0"` |
| `"'a' \| 'b'"` | String literal union |
| `"type = default"` | Default value when env var is unset |
| Constraints | `"string > 0"`, `"number >= 1024"`, etc. |

### Custom Transformers

```typescript
const env = arkenv({
  ALLOWED_ORIGINS: {
    type: "string",
    transform: (v) => v.split(",").map(s => s.trim())
  }
})
```

## JSON Schema Export Options

```typescript
const schema = MyType.toJsonSchema()
```

### Fallback Handlers

For types that have no direct JSON Schema equivalent:

```typescript
const schema = MyType.toJsonSchema({
  fallback: {
    // Default fallback for any unsupported type
    default: (ctx) => ctx.base,

    // Type-specific fallbacks
    date: (ctx) => ({
      ...ctx.base,
      type: "string",
      format: "date-time"
    }),
    bigint: (ctx) => ({
      ...ctx.base,
      type: "integer"
    }),
    symbol: (ctx) => ({
      ...ctx.base,
      type: "string"
    })
  }
})
```

### Unsupported Type Mapping

| ArkType Feature | JSON Schema Handling |
|---|---|
| `Date` | No equivalent — use `fallback.date` |
| `bigint` | No equivalent — use `fallback.bigint` |
| `symbol` | No equivalent — use `fallback.symbol` |
| Morphs / pipes | Output type only; transform logic lost |
| Brands | Stripped (compile-time only) |
| Cyclic types | `$ref` with `$defs` |
| Generics | Resolved at export time |
| Custom narrows | Dropped (no JSON Schema equivalent) |
| Index signatures | `additionalProperties` |
| Tuple variadics | `items` + `additionalItems` |

## Integration Gotchas

| Integration | Issue | Fix |
|---|---|---|
| tRPC < 11 | Type errors passing ArkType directly | Use `.assert` method: `MyType.assert` |
| tRPC >= 11 | `"Cannot find module 'arktype'"` | Ensure `arktype@>=2.0` is installed; check `moduleResolution` in tsconfig |
| React Hook Form | Resolver not validating on blur | Set `mode: "onBlur"` in `useForm` options |
| React Hook Form | Morph outputs not reflected in form state | Use `.inferIn` for the form type, `.infer` for submission type |
| Drizzle | `createSelectSchema` returns wrong optional keys | Check Drizzle column `.notNull()` — nullable columns become optional in ArkType |
| Drizzle | Custom column types not mapped | Provide explicit type overrides: `createSelectSchema(table, { col: type("string") })` |
| Hono | Validation errors return 500 | Wrap with try/catch or use `hook` option in `arktypeValidator` for custom error responses |
| Hono | Body not parsed before validation | Ensure correct target: `"json"`, `"form"`, `"query"`, or `"param"` |
| oRPC | Types not inferred in handler | Ensure `strict: true` in tsconfig and `arktype@>=2.0` |
| JSON Schema | Morph types produce unexpected schema | Export the input or output type separately: `MyType.in.toJsonSchema()` |
| JSON Schema | `toJsonSchema()` throws on Date | Add `fallback.date` handler (see above) |
| ArkEnv | Env var parsed as string instead of number | ArkEnv auto-coerces; ensure the var is defined (not `undefined`) |
| ArkEnv | Missing env var does not throw | Only vars without defaults throw; add `> 0` constraint for required strings |
| Cloudflare Workers | `new Function` error at runtime | Set `jitless: true` in global `configure()` |
| Standard Schema | Library does not recognize ArkType | Ensure library supports Standard Schema v1; check `~standard.version` |
