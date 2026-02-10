# Type System Essentials

Core TypeScript type system patterns referenced by the skill.

## `satisfies` Operator

Validate type without widening:

```typescript
type Config = {
  endpoint: string;
  port: number;
};

const config = {
  endpoint: "https://api.com",
  port: 8080,
  extra: "metadata"
} satisfies Config; // ✅ validates + keeps precise type

config.extra; // ✅ still accessible
```

### `satisfies` vs `as const` (Inference Tradeoffs)

Use `satisfies` when you want to validate a shape but keep precise types:

```typescript
type Route = { path: string; method: "GET" | "POST" };

const routes = [
  { path: "/users", method: "GET" },
  { path: "/users", method: "POST" }
] satisfies readonly Route[];

// routes[0].method is "GET" | "POST" (precise from values)
```

Use `as const` when you want literal types and deep readonly:

```typescript
const statusMap = {
  ok: 200,
  notFound: 404
} as const;

// statusMap.ok is 200 (literal), object is deeply readonly
```

Rule of thumb:
- `satisfies` preserves inference while checking shape.
- `as const` forces literals and readonly everywhere.

## Const Assertions

```typescript
const routes = {
  home: "/",
  about: "/about"
} as const;

// Type: { readonly home: "/"; readonly about: "/about" }

const tuple = [1, 2] as const; // readonly [1, 2]
```

## Variance and Function Types (Pitfalls)

Be careful with function parameter variance. Use strict function types in `tsconfig` and avoid unsound widening:

```typescript
type Handler = (value: string) => void;
type AnyHandler = (value: string | number) => void;

const acceptsString: Handler = (v) => console.log(v);
const acceptsAny: AnyHandler = (v) => console.log(v);

// Avoid assigning broader parameter functions to narrower ones:
// const bad: Handler = acceptsAny; // ❌ unsafe
```

## Related Skills

- For discriminated unions, type guards, and exhaustiveness: `coding-typescript-narrowing`
- For type operators (keyof, conditional, mapped, template literal types): `coding-typescript-type-operators`
- For generic constraints and inference: `coding-typescript-generics`
