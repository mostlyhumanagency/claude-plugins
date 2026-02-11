---
name: coding-typescript-core
description: Use when writing general TypeScript code, fixing type errors, making code more type-safe, enforcing immutability, structuring modules, choosing between types and interfaces, or handling general compiler errors. Also use for adding type annotations, removing implicit any, fixing null/undefined issues, using Result types for error handling, or when you see TS2322 (not assignable), TS2540 (readonly), TS7006 (implicit any), TS18048 (possibly undefined), or other common TypeScript compiler errors not specific to generics, async, or narrowing.
---

# Coding TypeScript Core

## Overview

Write clean, idiomatic TypeScript with strong type safety and immutability by default. Use boundaries to validate unknown data and keep runtime errors rare.

## Core Rules

See `rules.md` for detailed rules, red flags, and explicit exceptions.

## Result Type (Standard)

Use a consistent Result shape for error handling:

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2322 | Type 'X' is not assignable to type 'Y' | Check types match — narrow, validate, or fix the source type |
| TS2540 | Cannot assign to 'x' (read-only) | Use spread/copy instead of in-place mutation |
| TS7006 | Parameter 'x' implicitly has an 'any' type | Add an explicit type annotation |
| TS18048 | 'x' is possibly 'undefined' | Add a null/undefined check before accessing |
| TS2741 | Property 'x' is missing in type | Add the missing property or use Partial<T> |

## References

- `rules.md`
- `patterns.md`
- `type-system.md`
- `utility-types.md`
- `modules.md`
- `immutability.md`
- `library-interop.md`
- `examples.md`
- `sources.md`
