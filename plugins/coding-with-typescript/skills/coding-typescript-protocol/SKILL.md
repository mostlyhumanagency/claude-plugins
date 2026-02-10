---
name: coding-typescript-protocol
description: Use when designing protocol-oriented TypeScript with interface composition, capability-based design, mix-and-match behaviors, or when you see TS2415 (class incorrectly implements interface), TS2322 (structural compatibility issues), or TS2345 (argument not assignable to protocol type).
---

# Coding TypeScript Protocol-Oriented

## Overview

Prefer interface composition over inheritance. Design capabilities as small, focused protocols.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2415 | Class incorrectly implements interface | Add missing protocol members or fix their signatures |
| TS2322 | Type 'X' is not assignable to type 'Y' | Check structural compatibility — all required members must match |
| TS2345 | Argument of type 'X' is not assignable | Ensure the object satisfies all composed interface constraints |
| TS2559 | Type 'X' has no properties in common with type 'Y' | Verify intersection types share at least one common member |
| TS2339 | Property 'x' does not exist on type | The interface doesn't include this member — add it or narrow first |

## References

- `protocol-oriented.md`
