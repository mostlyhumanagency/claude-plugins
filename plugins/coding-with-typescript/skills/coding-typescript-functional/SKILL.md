---
name: coding-typescript-functional
description: Use when designing or reviewing functional programming patterns in TypeScript — pure functions, immutability, composition, FP-style error handling — or when you see TS2540 (cannot assign to readonly property), TS2345 (argument type mismatch in composition), or issues with function type inference.
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
