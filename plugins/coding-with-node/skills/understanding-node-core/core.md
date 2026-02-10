# Node Core Fundamentals (v24)

## Runtime Model

- Node runs JavaScript on a single main thread with an event loop, plus a libuv thread pool for some I/O.
- Use async APIs for I/O and move CPU-heavy work to worker threads.

## Process and Globals

- Use `process.env` for configuration and validate on startup.
- Use `process.on('SIGINT'|'SIGTERM')` for graceful shutdown.
- Prefer `globalThis` for globals and avoid app-specific globals.

## Errors and Exit Codes

- Throw `Error` instances, ideally typed subclasses.
- Use `process.exitCode` to signal failure from async paths.
- Reserve `process.exit()` for immediate termination after cleanup.

## Buffers and Security

- Use `Buffer` for binary data, but avoid exposing raw buffers across trust boundaries.
- Consider `--zero-fill-buffers` when handling sensitive data.

## Timers and Scheduling

- `setImmediate` runs after I/O callbacks and is a good way to yield.
- `process.nextTick` runs before other queued work; avoid recursive `nextTick` loops.

## Production Readiness

- Distinguish dev vs prod configs (logging, stack traces, env).
- Handle shutdown and in-flight requests before exiting.

## Quick Reference

| Concept | API / Pattern | Notes |
|---|---|---|
| Event loop | Single-threaded + libuv pool | Async I/O; CPU work blocks all requests |
| Graceful shutdown | `process.on('SIGTERM', ...)` | Close servers, drain connections before exit |
| Exit code | `process.exitCode = 1` | Prefer over `process.exit()` in async code |
| Worker threads | `new Worker('./task.js')` | Offload CPU-heavy work |
| Zero-fill buffers | `--zero-fill-buffers` | Prevents leaked data in Buffer allocations |
| Env validation | Check `process.env` at startup | Fail fast on missing/invalid config |
| Error subclass | `class AppError extends Error` | Use `{ cause }` for error chaining |

## Common Mistakes

**Blocking the event loop with sync work** — `fs.readFileSync` or CPU loops in request handlers block all concurrent requests. Use async APIs or worker threads.

**Calling `process.exit()` in async code** — Skips pending callbacks and open handles. Set `process.exitCode` and let the event loop drain instead.

**Leaking secrets via `process.env` mutation** — Mutating `process.env` at runtime is visible to child processes. Read and validate env once at startup.

**Ignoring `SIGTERM` in production** — Without a handler, Node exits immediately, dropping in-flight requests. Always close servers gracefully.

## Constraints and Edges

- Avoid synchronous CPU-heavy work on the main thread; it blocks all requests.
- `process.exit()` bypasses pending async cleanup unless you coordinate it.
- Globals should be limited to stable, cross-module constants only.

## Do / Don't

- Do prefer async I/O and streaming for large data.
- Do fail fast on invalid configuration.
- Don't block the event loop with long loops or heavy CPU work.
- Don't leak globals or mutate `process.env` at runtime.

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

### Yield to the event loop

```js
setImmediate(() => {
  // continue work after I/O callbacks
});
```

### Typed errors with cause

```js
class ConfigError extends Error {
  constructor(msg, cause) {
    super(msg, { cause });
    this.name = 'ConfigError';
  }
}
```

## Verification

- Confirm `process.exitCode` is non-zero on failure paths.
- Load-test critical endpoints and watch event-loop lag.
