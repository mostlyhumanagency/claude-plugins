---
name: coding-typescript-generics
description: Use when designing reusable functions, creating type-safe containers, building generic APIs, adding type parameters to functions or classes, fixing generic type errors, or working with branded types in TypeScript. Also use when adding constraints or defaults to generics, improving type inference, or when you see TS2344 (does not satisfy constraint), TS2322 (not assignable to type parameter), TS2589 (excessively deep type instantiation), TS2314 (requires N type arguments), or TS2558 (wrong number of type arguments).
---

# Coding TypeScript Generics

## Overview

Design generic APIs that are reusable, precise, and easy to infer. Prefer constraints over assertions and keep generic scopes minimal.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2344 | Type 'X' does not satisfy the constraint | Ensure the type argument extends the required constraint |
| TS2322 | Type 'X' is not assignable to type 'Y' | Check generic inference — supply explicit type arguments if needed |
| TS2589 | Type instantiation is excessively deep | Simplify recursive generics or add a base case |
| TS2314 | Generic type requires N type argument(s) | Provide all required type parameters or add defaults |
| TS2558 | Expected N type arguments, but got M | Match the number of type arguments to the generic signature |

## References

- `generics.md`
