---
name: coding-typescript-type-operators
description: Use when working with TypeScript type operators or type transformations — keyof, typeof, indexed access, conditional types, mapped types, template literal types — or when you see TS2536 (cannot use as index type), TS2344 (type does not satisfy constraint), or TS2589 (type instantiation is excessively deep).
---

# Coding TypeScript Type Operators

## Overview

Use type operators to derive types from existing structures. Keep transformations small and readable.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2536 | Type 'X' cannot be used as an index type | Add a `keyof` constraint or indexed-access guard |
| TS2344 | Type 'X' does not satisfy the constraint | Ensure generic argument extends the required type |
| TS2589 | Type instantiation is excessively deep | Simplify recursive/conditional types or add base case |
| TS2590 | Expression produces a union type that is too complex | Reduce union size in template literal or mapped types |
| TS1270 | Decorator not valid here | Ensure target is correct for the decorator type |

## References

- `type-operators.md`
