---
name: coding-arktype-morphs
description: "Use when transforming or converting data during validation, piping one type into another, parsing strings to numbers or JSON, coercing input shapes, or using .to(), .narrow(), .filter(), .pipe(), morphs, or the |> operator in ArkType. Also use for 'string.json.parse', 'string.numeric.parse', or input/output type mismatches."
---

# Using ArkType Morphs

## Overview

Morphs transform validated data. ArkType pipes chain validation and transformation steps. Input type and output type can differ — use `Type.infer` (output) and `Type.inferIn` (input) to distinguish.

## Built-in Parse Morphs

```typescript
"string.numeric.parse"        // string → number
"string.integer.parse"        // string → integer
"string.json.parse"           // string → object (JSON)
"string.date.parse"           // date string → Date
"string.date.iso.parse"       // ISO date → Date
"string.date.epoch.parse"     // epoch string → Date
"string.url.parse"            // URL string → URL object
```

## Built-in Transform Morphs

```typescript
"string.trim"                 // trim whitespace
"string.lower"                // to lowercase
"string.upper"                // to uppercase
"string.capitalize"           // capitalize first letter
"string.normalize.NFC"        // Unicode normalization (NFC/NFD/NFKC/NFKD)
```

## Pipe — Custom Transformations

```typescript
// Basic pipe
const trimmed = type("string").pipe(s => s.trim())

// pipe.try — catches thrown errors as ArkErrors
const parseJson = type("string").pipe.try((s): object => JSON.parse(s))

// Chain validation after transform
type("string").pipe.try(
  (s): object => JSON.parse(s),
  type({ name: "string", version: "string.semver" })
)

// String syntax with |> operator
const parsed = type("string.numeric.parse |> number % 2")

// N-ary form
const pipeline = type.pipe(
  type.string,
  s => s.trimStart(),
  type.string.atLeastLength(1)
)
```

See `patterns.md` for more pipe composition patterns.

## `.to()` — Sugar for Pipe to Type

```typescript
// These are equivalent:
type("string.json.parse").to({ name: "string", version: "string.semver" })
type("string.json.parse").pipe(type({ name: "string", version: "string.semver" }))
```

## `.narrow()` — Custom Validation (No Transform)

Returns `true` or a rejection. Does NOT change the type unless using a type predicate.

```typescript
const Positive = type("number").narrow((n, ctx) =>
  n > 0 ? true : ctx.mustBe("positive")
)

// With type predicate — narrows the type
const ArkStr = type("string").narrow(
  (s, ctx): s is `ark${string}` =>
    s.startsWith("ark") || ctx.mustBe("a string starting with 'ark'")
)

// Object-level narrowing
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

## `.filter()` — Narrow on Input

Like `.narrow()` but applied to the input type (before morphs):

```typescript
const NonEmpty = type("string").filter((s, ctx) =>
  s.length > 0 ? true : ctx.mustBe("non-empty")
)
```

## `.brand()` — Compile-Time Branding

```typescript
const Email = type("string.email").brand("Email")
// type: string & { readonly __brand: "Email" }

// Also via string syntax:
const Even = type("(number % 2)#even")
```

## Common Mistakes

- **No async morphs** — ArkType does not support async transformations. Handle promises on the output object instead.
- **Union morph conflict** — a union that could apply different morphs to the same data throws a `ParseError`. Ensure union branches are mutually exclusive before piping.
- **Forgetting `.pipe.try()`** — if your transform can throw (e.g., `JSON.parse`), use `.pipe.try()` to catch errors as `ArkErrors` instead of crashing.
- **`narrow` vs `pipe`** — `.narrow()` validates without changing the value/type (unless using a type predicate). `.pipe()` transforms the value and can change the type.
