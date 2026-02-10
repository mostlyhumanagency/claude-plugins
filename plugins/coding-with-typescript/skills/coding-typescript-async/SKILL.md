---
name: coding-typescript-async
description: Use when dealing with async/await, Promises, concurrency, retries, timeouts, cancellation, or async iterators in TypeScript — or when you see TS2801 (this expression is not callable on Promise), TS1378 (top-level await requires module), or floating promise warnings.
---

# Coding TypeScript Async

## Overview

Prefer `async`/`await`, keep return types explicit, and handle errors with `Result` patterns or typed exceptions.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2801 | This expression is not callable (Promise) | You forgot `await` — the value is still a Promise |
| TS1378 | Top-level 'await' expressions require 'module' | Set `"module": "esnext"` or `"node20"` in tsconfig |
| TS2345 | Argument not assignable (Promise vs value) | Await the promise before passing the result |
| TS18046 | 'x' is of type 'unknown' | Narrow the caught error with `instanceof Error` |
| TS2769 | No overload matches this call (Promise.all) | Check that all array elements are Promises of compatible type |

## References

- `async.md`
