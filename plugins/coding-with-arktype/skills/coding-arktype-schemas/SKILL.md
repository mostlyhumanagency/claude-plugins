---
name: coding-arktype-schemas
description: Use when defining ArkType types, object schemas, optional/default properties, arrays, tuples, unions, intersections, string/number constraints, or built-in keywords.
---

# Using ArkType Schemas

## Overview

Define runtime validators using TypeScript-like string syntax. Types are callable — pass data to validate and get typed output or `ArkErrors`.

## Defining Types

```typescript
import { type } from "arktype"

const User = type({
  name: "string",
  email: "string.email",
  "age?": "number.integer >= 0",       // optional
  role: "'admin' | 'user' = 'user'"    // default
})

type User = typeof User.infer          // extract TS type
type UserInput = typeof User.inferIn   // input type (before morphs)
```

## Validation

```typescript
const out = User(data)
if (out instanceof type.errors) {
  console.error(out.summary)
} else {
  out.name  // string — typed
}

User.assert(data)   // throws on failure
User.allows(data)   // boolean, no morphs applied
```

## Quick Reference

See `reference.md` for full keyword tables (string, number, object, array).

## Core Patterns

### Objects — Properties

```typescript
const Config = type({
  host: "string",              // required
  "port?": "number",           // optional
  debug: "boolean = false",    // default value
  "+": "reject"                // reject undeclared keys
})
```

### Objects — Composition

```typescript
Base.merge({ extra: "string" })              // merge objects
type.merge(A, B, C)                          // n-ary merge
MyObj.pick("name", "email")                  // pick keys
MyObj.omit("password")                       // omit keys
MyObj.partial()                              // all optional
MyObj.required()                             // all required
MyObj.keyof()                                // union of keys
MyObj.get("nested", "deep")                  // extract property type
```

### Index Signatures

```typescript
const Dict = type({ "[string]": "number" })
const Mixed = type({ "[string | symbol]": "unknown" })
```

### Arrays and Tuples

```typescript
"string[]"                                   // array
"string[] > 0"                               // non-empty
type(["string", "number"])                   // tuple [string, number]
type(["string", "boolean = false"])          // tuple with default
type(["string", "number?"])                  // tuple with optional
type(["string", "...", "number[]"])          // variadic
type(["...", "number[]", "boolean"])         // postfix after variadic
```

### Unions and Intersections

```typescript
"string | number"                            // union (string syntax)
type.or(type.string, "number", { k: "any" })  // union (n-ary)
"string.email & /@company\\.com$/"           // intersection
type.and(ObjA, { extra: "string" })          // intersection (n-ary)
```

### Brands and Recursive Types

```typescript
const Even = type("(number % 2)#even")       // branded type
const Tree = type({ value: "unknown", "children?": "this[]" })  // recursive
```

### Enums and Exact Values

```typescript
type.unit(mySymbol)                          // exact non-serializable value
type.enumerated(1, 2, 3)                     // set of exact values
type.valueOf(MyTsEnum)                       // TypeScript enum
```

## Common Mistakes

- **`"key?"` vs `"undefined"`** — `"key?": "string"` makes the key optional. Adding `undefined` to the value type does NOT make the key optional.
- **Optional with exactOptionalPropertyTypes** — optional keys reject `undefined` as a value unless you explicitly include it in the type.
- **Union morphs** — a union applying different morphs to the same input throws a `ParseError`.
- **`keyof` excludes `number`** — matches JS runtime behavior where object keys are strings.
