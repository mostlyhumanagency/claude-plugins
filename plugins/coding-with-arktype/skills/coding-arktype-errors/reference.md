# ArkErrors API Reference

## ArkErrors Object

Returned by `Type(data)` when validation fails. Implements `Iterable<ArkError>`.

| Property / Method | Type | Description |
|---|---|---|
| `errors.summary` | `string` | Human-readable multi-line error summary |
| `errors.message` | `string` | Same as `.summary` (toString also uses this) |
| `errors.count` | `number` | Total number of errors |
| `errors.byPath` | `Record<string, ArkError>` | Errors keyed by their path string |
| `for...of errors` | `Iterable<ArkError>` | Iterate individual errors |

```typescript
const out = MyType(data)
if (out instanceof type.errors) {
  console.log(out.count)          // 3
  console.log(out.summary)        // multi-line description
  for (const err of out) {
    console.log(err.path, err.message)
  }
}
```

## Individual ArkError Properties

Each `ArkError` in the collection exposes:

| Property | Type | Description |
|---|---|---|
| `.code` | `string` | Error code identifying the failure type |
| `.path` | `TraversalPath` | Array of keys/indices to the failing value |
| `.message` | `string` | Fully formatted error string |
| `.expected` | `string` | Description of what was expected |
| `.actual` | `string` | Description of what was received |
| `.problem` | `string` | Combined expected/actual statement |
| `.data` | `unknown` | The original input value at the root |

```typescript
for (const err of out) {
  // err.code     → "predicate"
  // err.path     → ["users", 0, "email"]
  // err.expected → "a valid email"
  // err.actual   → "'not-an-email'"
  // err.problem  → "must be a valid email (was 'not-an-email')"
  // err.message  → "users/0/email must be a valid email (was 'not-an-email')"
}
```

## Error Codes

| Code | Trigger |
|---|---|
| `"domain"` | Wrong primitive type (e.g. string where number expected) |
| `"unit"` | Value does not match a literal or unit type |
| `"proto"` | Value is not an instance of expected prototype |
| `"predicate"` | Custom `.narrow()` or `.filter()` predicate returned false |
| `"divisor"` | Number not divisible by specified divisor |
| `"bound"` | Numeric or length bound violated (min/max/range) |
| `"pattern"` | String does not match regex pattern |
| `"required"` | Required property is missing |
| `"undeclared"` | Object has a key not in the type definition |
| `"union"` | No branch of a union matched |
| `"intersection"` | Conflicting intersection requirements |
| `"morph"` | A morph (pipe/transform) threw or returned an error |
| `"custom"` | Error created via `ctx.reject()` or `ctx.error()` |

## Serializing Errors for HTTP Responses

```typescript
// JSON-friendly error formatting
app.post("/user", (req, res) => {
  const out = User(req.body)
  if (out instanceof type.errors) {
    return res.status(400).json({
      ok: false,
      errors: [...out].map(e => ({
        path: e.path.join("/"),
        code: e.code,
        message: e.message,
        expected: e.expected,
        actual: e.actual
      }))
    })
  }
  // out is valid User
})
```

## Configuration Cascade

Error messages resolve through a cascade. Each level overrides the previous:

| Priority | Level | How to Set |
|---|---|---|
| 1 (lowest) | ArkType defaults | Built-in messages |
| 2 | Global `configure()` | `import { configure } from "arktype/config"` |
| 3 | Scope `configure` | `scope({ ... }).configure({ ... })` |
| 4 | Type `.configure()` | `MyType.configure({ ... })` |
| 5 (highest) | Type `.describe()` | `MyType.describe("a positive integer")` |

`.describe(str)` is shorthand for `.configure({ description: str })`. When a description is set, it replaces the `expected` field entirely.

## Full configure() Options Reference

| Option | Type | Default | Description |
|---|---|---|---|
| `onUndeclaredKey` | `"ignore" \| "delete" \| "reject"` | `"ignore"` | How to handle keys not in the type definition |
| `clone` | `false \| typeof structuredClone \| (data: unknown) => unknown` | built-in deep clone | Controls input cloning before morphs. `false` mutates in place |
| `jitless` | `boolean` | `false` | Disable JIT compilation (required for Cloudflare Workers, edge runtimes without `new Function`) |
| `onFail` | `(errors: ArkErrors) => void` | return errors | Callback invoked on validation failure instead of returning errors |
| `keywords` | `Record<string, string \| KeywordConfig>` | `{}` | Customize error messages per keyword (see below) |
| `description` | `string` | — | Human-readable description used as `expected` |
| `expected` | `string \| ((ctx: ErrorContext) => string)` | — | Override the expected portion of error messages |
| `actual` | `string \| ((data: unknown) => string)` | — | Override the actual portion of error messages |
| `problem` | `string \| ((ctx: ProblemContext) => string)` | — | Override the full problem statement (expected + actual) |
| `message` | `string \| ((ctx: MessageContext) => string)` | — | Override the final message (path + problem) |

### keywords Customization

```typescript
import { configure } from "arktype/config"

configure({
  keywords: {
    // Simple string replaces expected
    string: "must be text",

    // Object form for full control
    "string.email": {
      description: "a valid email address",
      expected: () => "a valid email",
      actual: (data) => `${typeof data} (${JSON.stringify(data)})`,
      problem: (ctx) => `${ctx.expected} but got ${ctx.actual}`,
      message: (ctx) => `Error at ${ctx.path}: ${ctx.problem}`
    },

    number: {
      expected: () => "a numeric value"
    }
  }
})
```

Each keyword entry accepts `string` (replaces expected) or an object with: `description`, `expected`, `actual`, `problem`, `message`.

## Testing Errors Pattern

Assert that a type correctly rejects invalid data in unit tests:

```typescript
import { type } from "arktype"
import { describe, it, assert } from "node:test"

describe("User validation", () => {
  const User = type({
    name: "string > 0",
    email: "string.email",
    age: "number >= 0"
  })

  it("rejects missing required fields", () => {
    const out = User({})
    assert(out instanceof type.errors)
    assert(out.count >= 1)
  })

  it("rejects invalid email", () => {
    const out = User({ name: "Ada", email: "not-email", age: 30 })
    assert(out instanceof type.errors)
    const emailErr = [...out].find(e => e.path.includes("email"))
    assert(emailErr, "expected an error at email path")
    assert.strictEqual(emailErr.code, "predicate")
  })

  it("reports correct error summary", () => {
    const out = User({ name: "", email: "bad", age: -1 })
    assert(out instanceof type.errors)
    assert(out.summary.includes("email"))
    assert(out.summary.includes("age"))
  })

  it("accepts valid data", () => {
    const out = User({ name: "Ada", email: "ada@example.com", age: 30 })
    assert(!(out instanceof type.errors))
    assert.strictEqual(out.name, "Ada")
  })

  it("iterates all errors", () => {
    const out = User({ name: 42, email: 42, age: "old" })
    assert(out instanceof type.errors)
    const codes = [...out].map(e => e.code)
    assert(codes.length >= 3)
  })
})
```
