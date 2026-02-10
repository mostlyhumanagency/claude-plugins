# ArkType Morph Patterns

## Parse JSON and Validate Shape

```typescript
// String syntax — parse then validate
const Config = type("string.json.parse").to({
  name: "string",
  version: "string.semver",
  "debug?": "boolean"
})

// Equivalent pipe form
const Config = type("string").pipe.try(
  (s): object => JSON.parse(s),
  type({ name: "string", version: "string.semver", "debug?": "boolean" })
)
```

## Numeric String Parsing

```typescript
// Parse form inputs
const FormData = type({
  age: "string.integer.parse",      // "25" → 25
  price: "string.numeric.parse",    // "9.99" → 9.99
  name: "string.trim"               // "  Ada  " → "Ada"
})
```

## Pipeline with Multiple Steps

```typescript
// N-ary pipe: validate → transform → validate
const CleanEmail = type.pipe(
  type.string,
  s => s.trim().toLowerCase(),
  type("string.email")
)

// String syntax with |> operator
const EvenFromStr = type("string.numeric.parse |> number % 2")
```

## Conditional Transform

```typescript
const Normalize = type("string | number").pipe(v =>
  typeof v === "number" ? String(v) : v
)
```

## Object Transform

```typescript
const ApiResponse = type({
  data: "string.json.parse",
  timestamp: "string.date.iso.parse"
}).pipe(({ data, timestamp }) => ({
  ...(data as Record<string, unknown>),
  fetchedAt: timestamp
}))
```

## Combining Narrow + Pipe

```typescript
// Validate constraint, then transform
const PositiveStr = type("string.numeric.parse")
  .narrow((n, ctx) => n > 0 ? true : ctx.mustBe("positive"))
  .pipe(n => ({ value: n, label: `+${n}` }))
```

## Default Values with Morphs

```typescript
const Settings = type({
  theme: "'light' | 'dark' = 'light'",
  fontSize: "string.integer.parse = '14'",  // default as input type
  locale: "string = 'en-US'"
})
```

## Error-Safe Parsing

```typescript
// pipe.try catches thrown errors as ArkErrors
const safeParse = type("string").pipe.try((s): unknown => {
  const result = JSON.parse(s)
  if (!result || typeof result !== "object") {
    throw new Error("Expected object")
  }
  return result
})

const out = safeParse('invalid json')
if (out instanceof type.errors) {
  // Error captured, not thrown
}
```
