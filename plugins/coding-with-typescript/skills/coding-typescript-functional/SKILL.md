---
name: coding-typescript-functional
description: Use when writing pure functions, composing functions with pipe or flow, enforcing immutability, using map/filter/reduce patterns, implementing FP-style error handling (Result, Option, Either), or refactoring imperative code to a functional style in TypeScript. Also use when you see TS2540 (cannot assign to readonly), TS2345 (argument type mismatch in composition), TS2322 (return type mismatch in composed functions), or TS7006 (implicit any in higher-order functions).
---

# Coding TypeScript Functional

## Overview

Favor pure functions, immutable data, and composition. Keep effects at the boundaries.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2540 | Cannot assign to 'x' because it is a read-only property | Use spread/copy instead of mutation |
| TS2345 | Argument of type 'X' is not assignable | Check function composition — output of f must match input of g |
| TS2322 | Type 'X' is not assignable to type 'Y' | Verify return type of composed functions matches expected |
| TS7006 | Parameter implicitly has an 'any' type | Add explicit parameter types to higher-order functions |
| TS2769 | No overload matches this call | Simplify overloads or use a union return type |

## References

- `functional.md`
