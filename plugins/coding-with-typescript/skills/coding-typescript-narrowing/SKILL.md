---
name: coding-typescript-narrowing
description: Use when TypeScript needs control-flow narrowing, type guards, type predicates, exhaustiveness checks, discriminated unions, or when you see TS2352 (type assertion), TS2339 (property does not exist on narrowed type), or TS2345 (argument type mismatch after narrowing).
---

# Coding TypeScript Narrowing

## Overview

Use TypeScript's control-flow analysis to narrow unions safely. Prefer type guards and exhaustiveness checks over assertions.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2352 | Conversion of type 'X' may be a mistake | Replace `as` with a type guard or assertion function |
| TS2339 | Property does not exist on type 'never' | Add missing case to switch/if for exhaustiveness |
| TS2345 | Argument of type 'X' is not assignable | Narrow the union before passing to the function |
| TS18046 | 'x' is of type 'unknown' | Add a typeof/instanceof check before using the value |
| TS2322 | Type 'X' is not assignable to type 'never' | Exhaustiveness check caught unhandled union member |

## References

- `narrowing.md`
