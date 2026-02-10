---
name: handling-node-async
description: Use when Node.js v24 async behavior is confusing or broken — event loop ordering, timer quirks, callback/promise conversions, AsyncLocalStorage context loss, EventEmitter leaks, event-loop blocking — or when you see ERR_UNHANDLED_REJECTION, MaxListenersExceededWarning, or event loop lag.
---

# Handling Node Async

## Overview

Async patterns that keep the event loop responsive and code readable.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Debugging event loop order or timer behavior.
- Converting callbacks to promises or standardizing async flow.
- Propagating request context across async boundaries.
- Avoiding event-loop blocking and CPU contention.

## When Not to Use

- You need CPU-bound work without async boundaries; use worker threads or a native addon instead.
- You need strict, synchronous ordering guarantees and can safely block.
- You are primarily dealing with streaming backpressure; use `working-with-node-streams` instead.

## Quick Reference

- Prefer `async`/`await` and native promise APIs.
- Use `setImmediate` to yield after I/O; use `nextTick` sparingly.
- Use `AsyncLocalStorage` with `name` and `defaultValue` in v24.
- Use worker threads for CPU-heavy work.

## Examples

### Yield after I/O

```js
setImmediate(() => {
  continueWork();
});
```

### Promise-based fs

```js
const fs = require('node:fs/promises');
const text = await fs.readFile('README.md', 'utf8');
```

### AsyncLocalStorage defaults

```js
const { AsyncLocalStorage } = require('node:async_hooks');
const als = new AsyncLocalStorage({ name: 'req', defaultValue: {} });
```

## Common Errors

| Code / Warning | Message Fragment | Fix |
|---|---|---|
| ERR_UNHANDLED_REJECTION | Unhandled promise rejection | Add `.catch()` or wrap in try/catch with await |
| MaxListenersExceededWarning | Possible EventEmitter memory leak | Remove listeners with `.off()` or increase limit if justified |
| ERR_USE_AFTER_CLOSE | Resource used after close | Ensure async operations complete before closing handles |
| ERR_ASYNC_TYPE | Invalid async resource type | Pass valid type string to AsyncResource constructor |
| ETIMEDOUT | Connection timed out | Add AbortController timeout or retry with backoff |

## References

- `async.md`
