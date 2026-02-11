---
name: coding-typescript-async
description: Use when writing async functions, awaiting promises, handling concurrent operations, adding retries or timeouts, cancelling async work, streaming with async iterators, or fixing "floating promise" warnings in TypeScript. Also use when refactoring callback-based code to async/await, implementing error handling for async operations, or when you see TS2801 (not callable on Promise), TS1378 (top-level await requires module), TS2345 (Promise vs value mismatch), or TS18046 (unknown caught error).
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
