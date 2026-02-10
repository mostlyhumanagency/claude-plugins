# Asynchronous Work in Node.js (v24)

## Core Principles

- Keep the event loop responsive by avoiding long synchronous CPU work.
- Use promise-based APIs and `async`/`await` for clarity.

## Timers and Scheduling

- `setTimeout` and `setInterval` schedule work in the timers phase.
- `setImmediate` runs after I/O callbacks.
- `process.nextTick` runs before other queued work and can starve I/O if abused.

## Callbacks to Promises

- Prefer built-in promise APIs (for example, `fs.promises`).
- Use `util.promisify` only when no promise API exists.

## EventEmitter

- Use `EventEmitter` for pub/sub patterns.
- Remove listeners with `off` or `removeListener` to prevent leaks.

## AsyncLocalStorage (v24)

- `AsyncLocalStorage` accepts options:
  - `defaultValue` to return when no store is set.
  - `name` to aid diagnostics.
- Initialize once at request entry points and avoid nesting conflicting stores.

## CPU Work

- Offload CPU-heavy tasks to worker threads.
- Consider batching or chunking synchronous loops to yield back to the event loop.

## Quick Reference

| Pattern | API / Syntax | Use When |
|---|---|---|
| Promise API | `fs.promises.readFile()` | Prefer over callback-based APIs |
| Promisify | `util.promisify(fn)` | Wrapping callback APIs without promise variants |
| setImmediate | `setImmediate(cb)` | Yielding after I/O callbacks |
| nextTick | `process.nextTick(cb)` | Running before I/O (use sparingly) |
| AsyncLocalStorage | `new AsyncLocalStorage({ name, defaultValue })` | Request-scoped context propagation |
| Worker threads | `new Worker('./worker.js')` | CPU-heavy work off the main thread |
| Promise.all | `await Promise.all([...])` | Parallel independent async work |
| EventEmitter | `.on()` / `.off()` | Pub/sub patterns |

## Common Mistakes

**Recursive `process.nextTick` starving I/O** — `nextTick` callbacks run before I/O. Recursive usage blocks the event loop. Use `setImmediate` instead.

**Forgetting to remove EventEmitter listeners** — Listeners accumulate and cause memory leaks. Use `.off()` or `{ once: true }` for one-shot handlers.

**Unbounded `setInterval` without cleanup** — Intervals keep the process alive and leak if not cleared. Always store the handle and call `clearInterval` on shutdown.

**AsyncLocalStorage context loss in callbacks** — Context is lost when crossing non-promise boundaries. Wrap callbacks in `als.run()` or use promise-based APIs.

## Constraints and Edges

- `process.nextTick` can starve I/O; avoid recursive usage.
- Async patterns do not fix CPU saturation; move heavy work off the main thread.
- Use streams for large data pipelines instead of buffering in promises.

## Do / Don't

- Do use `Promise.all` for independent work.
- Do use `setImmediate` to yield after I/O.
- Don't use `nextTick` for general scheduling.
- Don't create unbounded `setInterval` loops without backoff or cancellation.

## Examples

### Promisify a callback API

```js
const { promisify } = require('node:util');
const readFile = promisify(require('node:fs').readFile);
const text = await readFile('README.md', 'utf8');
```

### Request-scoped context with defaults

```js
const { AsyncLocalStorage } = require('node:async_hooks');
const als = new AsyncLocalStorage({
  name: 'request-context',
  defaultValue: { requestId: 'unknown' }
});

function handler(req, res) {
  als.run({ requestId: req.headers['x-request-id'] }, () => {
    doWork();
  });
}

function doWork() {
  const ctx = als.getStore();
  log(ctx.requestId);
}
```

### Yield after I/O

```js
setImmediate(() => {
  // continue work without blocking I/O callbacks
});
```

### Offload CPU work

```js
const { Worker } = require('node:worker_threads');
const worker = new Worker('./worker.js');
```

## Verification

- Monitor event-loop lag under load.
- Confirm long-running tasks are off the main thread.
