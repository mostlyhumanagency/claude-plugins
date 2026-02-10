# Node Worker Threads (v24)

## Core API

- `Worker` — spawns a new thread running a JavaScript file.
- `isMainThread` — boolean, true in the main thread.
- `parentPort` — MessagePort for communicating with the parent from inside a worker.
- `workerData` — cloned data passed from the parent at creation time.
- `threadId` — unique integer ID for each thread.

## Quick Reference

| API | Purpose | Notes |
|---|---|---|
| `new Worker(filename, options)` | Spawn worker | `workerData` passes initial data |
| `worker.postMessage(value, transferList)` | Send to worker | Transfer avoids copying |
| `parentPort.postMessage(value)` | Send to parent | From inside worker |
| `worker.on('message', cb)` | Receive from worker | Main thread side |
| `parentPort.on('message', cb)` | Receive from parent | Worker side |
| `worker.terminate()` | Force stop worker | Returns promise |
| `SharedArrayBuffer` | Shared memory | Zero-copy between threads |
| `Atomics.wait/notify` | Thread synchronization | Block/wake on shared memory |
| `resourceLimits` | Memory limits | `maxOldGenerationSizeMb`, `maxYoungGenerationSizeMb` |

## Common Mistakes

**Passing non-transferable objects** — Functions, closures, and class instances with methods cannot be sent via `postMessage`. Only structured-cloneable values work. Use `workerData` for initial config and message passing for results.

**Forgetting to handle worker errors** — Always attach `worker.on('error', cb)`. Unhandled worker errors silently terminate the worker.

**Using SharedArrayBuffer without Atomics** — Reading/writing shared memory without `Atomics` leads to race conditions. Always use `Atomics.load`, `Atomics.store`, `Atomics.add`, etc.

**Creating too many workers** — Each worker has its own V8 instance (~5-10MB overhead). Use a worker pool for recurring tasks instead of spawning per-request.

## Constraints

- Workers have their own event loop and V8 isolate.
- `require` and `import` work inside workers, but some Node APIs differ (no `process.stdin`).
- `SharedArrayBuffer` is always available in Node.js (no special flags needed).
- `worker.terminate()` is not instant — it returns a promise that resolves when cleanup is done.

## Do / Don't

- Do use worker pools for repeated CPU tasks.
- Do transfer large ArrayBuffers instead of cloning.
- Do set `resourceLimits` to prevent memory leaks in workers.
- Don't spawn a new worker per HTTP request — use a pool.
- Don't share state via global variables — use message passing or SharedArrayBuffer.
- Don't use workers for I/O-bound tasks — the event loop is faster.

## Examples

### Worker pool pattern

```js
import { Worker } from 'node:worker_threads';

class WorkerPool {
  #workers = [];
  #queue = [];

  constructor(filename, size) {
    for (let i = 0; i < size; i++) {
      const worker = new Worker(filename);
      worker.on('message', (result) => {
        const { resolve } = worker._task;
        worker._task = null;
        resolve(result);
        this.#drain();
      });
      this.#workers.push(worker);
    }
  }

  run(data) {
    return new Promise((resolve, reject) => {
      this.#queue.push({ data, resolve, reject });
      this.#drain();
    });
  }

  #drain() {
    const idle = this.#workers.find((w) => !w._task);
    if (!idle || this.#queue.length === 0) return;
    const task = this.#queue.shift();
    idle._task = task;
    idle.postMessage(task.data);
  }
}
```

### Resource limits

```js
const worker = new Worker('./heavy.js', {
  resourceLimits: {
    maxOldGenerationSizeMb: 128,
    maxYoungGenerationSizeMb: 16,
    codeRangeSizeMb: 16
  }
});
```

### Using MessageChannel for direct worker-to-worker communication

```js
import { Worker, MessageChannel } from 'node:worker_threads';

const { port1, port2 } = new MessageChannel();
const workerA = new Worker('./a.js', { workerData: { port: port1 }, transferList: [port1] });
const workerB = new Worker('./b.js', { workerData: { port: port2 }, transferList: [port2] });
```

## Verification

- Check `isMainThread` to confirm execution context.
- Use `worker.threadId` to track workers in logs.
- Monitor memory with `worker.getHeapSnapshot()` or `--max-old-space-size` flags.
