---
name: coding-arktype-errors
description: Use when handling ArkType validation errors, customizing error messages, using the traversal API (ctx.reject, ctx.mustBe), or configuring ArkType behavior globally or per-type.
---

# Using ArkType Errors and Configuration

## Overview

ArkType returns `ArkErrors` on validation failure. Customize error messages at four levels: default < global < scope < type.

## Checking for Errors

```typescript
const out = MyType(data)
if (out instanceof type.errors) {
  console.error(out.summary)   // human-readable multi-line summary
} else {
  console.log(out)             // typed, validated data
}
```

## Traversal Context

Used inside `.narrow()` and `.pipe()` callbacks for custom error reporting:

```typescript
const Positive = type("number").narrow((n, ctx) =>
  n > 0 ? true : ctx.mustBe("positive")
)

const Form = type({
  password: "string",
  confirm: "string"
}).narrow((data, ctx) => {
  if (data.password === data.confirm) return true
  return ctx.reject({
    expected: "identical to password",
    actual: "",
    path: ["confirm"]
  })
})
```

| Method | Returns | Use for |
|---|---|---|
| `ctx.mustBe(desc)` | `false` | Simple "must be X" error |
| `ctx.reject(opts)` | `false` | Structured error with path/expected/actual |
| `ctx.error(arkError)` | `ArkError` | Add and return an error object |
| `ctx.hasError` | `boolean` | Check if current branch has errors |
| `ctx.path` | `string[]` | Current traversal path (mutable — snapshot with `.slice(0)`) |
| `ctx.root` | `unknown` | Original input value |

## Configuration Levels

```typescript
// Global — import before any type definitions
import { configure } from "arktype/config"
configure({ onUndeclaredKey: "delete" })

// Type-level
const Email = type("string.email").configure({
  description: "a valid email address"
})
// Shorthand:
const Email = type("string.email").describe("a valid email address")
```

## Error Customization

```typescript
configure({
  keywords: {
    string: "must be text",
    "string.email": {
      expected: () => "a valid email",
      actual: (data) => `${typeof data} (${String(data)})`
    }
  }
})
```

Fields: `description`, `expected`, `actual`, `problem`, `message`

## Quick Reference

| Config Option | Values | Default |
|---|---|---|
| `onUndeclaredKey` | `"ignore"`, `"delete"`, `"reject"` | `"ignore"` |
| `clone` | `false`, `structuredClone`, custom fn | built-in |
| `jitless` | `true`/`false` | `false` (enable for Cloudflare Workers) |
| `onFail` | `(errors) => void` | return errors |

## Common Mistakes

- **Forgetting `jitless: true`** for Cloudflare Workers / environments without `new Function`
- **Mutating `ctx.path`** without snapshotting — use `ctx.path.slice(0)` to capture current path
- **Missing `skipLibCheck`** in tsconfig — causes false type errors in `node_modules`
