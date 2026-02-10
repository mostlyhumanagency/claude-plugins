---
name: coding-typescript-validation
description: Use when validating runtime data in TypeScript — parsing JSON, handling unknown inputs, schema validation (Zod), type guards, assertion functions — or when you see TS2352 (unsafe type assertion), TS18046 (value is of type unknown), or TS2345 (argument not assignable after validation).
---

# Coding TypeScript Validation

## Overview

Validate `unknown` at boundaries and return a typed `Result` or throw well-typed errors. Prefer schema validation for complex inputs.

## Result Type (Standard)

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2352 | Conversion of type 'X' may be a mistake | Replace `as` cast with a type guard or Zod schema |
| TS18046 | 'x' is of type 'unknown' | Validate with a type guard before using the value |
| TS2345 | Argument of type 'X' is not assignable | Narrow the type with validation before passing |
| TS2322 | Type 'X' is not assignable to type 'Y' | Check that validation result type matches expected |
| TS1228 | Assertions require every name to be declared with explicit type annotation | Add explicit return type to assertion function |

## References

- `validation.md`
