---
name: understanding-node-core
description: Use when understanding how Node.js works under the hood, handling process signals and graceful shutdown, working with Buffers and binary data, managing global objects, or fixing process lifecycle issues — covers runtime model, globals, process events, exit codes, SIGTERM/SIGINT handling, Buffers, error classes, and v8 internals. Triggers on ERR_WORKER_OUT_OF_MEMORY, SIGTERM handling, process.exit vs process.exitCode confusion.
---

# Understanding Node Core

## Overview

Foundational Node.js runtime concepts and safe defaults for production.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Clarifying how Node runs JS, handles I/O, and schedules work.
- Deciding how to handle process lifecycle, signals, exit codes.
- Choosing safe defaults for binary data handling.
- Establishing baseline security and production hygiene.

## When Not to Use

- You need deep guidance on streams, modules, or test runner specifics.
- You are debugging performance; use `diagnosing-node` or `handling-node-async`.
- You need framework-specific production guidance.

## Quick Reference

- Prefer async I/O and avoid long synchronous CPU work on the main thread.
- Use `process.exitCode` in async code instead of `process.exit()`.
- Use `--zero-fill-buffers` for sensitive data.
- Validate inputs at boundaries and avoid `eval` or shell interpolation.

## Examples

### Graceful shutdown

```js
const server = app.listen(3000);
process.on('SIGTERM', () => {
  server.close(() => {
    process.exitCode = 0;
  });
});
```

### Fail fast on bad config

```js
const port = Number(process.env.PORT);
if (!Number.isFinite(port)) {
  throw new Error('PORT must be a number');
}
```

### Avoid blocking the event loop

```js
const { Worker } = require('node:worker_threads');
new Worker('./cpu-task.js');
```

### Zero-fill sensitive buffers

```js
const buf = Buffer.alloc(32); // run node with --zero-fill-buffers
```

## Common Errors

| Code / Signal | Message Fragment | Fix |
|---|---|---|
| ERR_WORKER_OUT_OF_MEMORY | Worker terminated due to reaching memory limit | Increase `--max-old-space-size` or reduce payload |
| SIGTERM / SIGINT | Process exits without cleanup | Add signal handlers to close servers gracefully |
| ERR_UNHANDLED_REJECTION | Unhandled promise rejection | Add `.catch()` or use `process.on('unhandledRejection')` |
| ERR_INVALID_ARG_TYPE | argument must be of type string | Validate `process.env` values and coerce types at startup |
| ERR_ASSERTION | assertion error in node:assert | Use typed error subclasses with `{ cause }` |

## References

- `core.md`
- `sources.md`
