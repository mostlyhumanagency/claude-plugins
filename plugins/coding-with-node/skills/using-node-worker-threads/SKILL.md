---
name: using-node-worker-threads
description: Use when working with Node.js worker_threads for CPU-intensive tasks, parallel processing, shared memory with SharedArrayBuffer, or message passing — or when you see ERR_WORKER_PATH, ERR_WORKER_INIT_FAILED, or ERR_WORKER_UNSERIALIZABLE_ERROR.
---

# Using Node Worker Threads

## Overview

Offload CPU-intensive work to worker threads to keep the main event loop responsive.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Running CPU-intensive computations (hashing, compression, image processing).
- Parallelizing independent tasks across multiple cores.
- Sharing memory between threads with SharedArrayBuffer.
- Isolating untrusted or heavy computation from the main thread.

## When Not to Use

- I/O-bound work (network, file reads) — the event loop handles these efficiently.
- Simple one-off shell commands — use `child_process` instead.
- You need process isolation (separate memory space) — use `child_process.fork`.

## Quick Reference

- Use `new Worker(filename)` to spawn a worker thread.
- Pass initial data with `workerData`.
- Communicate via `parentPort.postMessage()` and `worker.on('message')`.
- Transfer large buffers with `transferList` to avoid copying.
- Use `SharedArrayBuffer` + `Atomics` for zero-copy shared memory.

## Examples

### Basic worker

```js
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

if (isMainThread) {
  const worker = new Worker(new URL(import.meta.url), {
    workerData: { input: [1, 2, 3, 4, 5] }
  });
  worker.on('message', (result) => console.log('Result:', result));
  worker.on('error', (err) => console.error('Worker error:', err));
} else {
  const sum = workerData.input.reduce((a, b) => a + b, 0);
  parentPort.postMessage(sum);
}
```

### Transferring an ArrayBuffer

```js
const buffer = new ArrayBuffer(1024);
worker.postMessage({ buffer }, [buffer]);
// buffer is now detached in the sending thread
```

### SharedArrayBuffer with Atomics

```js
const shared = new SharedArrayBuffer(4);
const view = new Int32Array(shared);
const worker = new Worker('./worker.js', { workerData: { shared } });
// In worker: Atomics.add(view, 0, 1);
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_WORKER_PATH | The worker script path must be absolute or a relative path starting with './' | Use `new URL(import.meta.url)` or an absolute path |
| ERR_WORKER_INIT_FAILED | Worker initialization failed | Check that the worker file exists and is valid JavaScript |
| ERR_WORKER_UNSERIALIZABLE_ERROR | Serializing an uncaught exception failed | Ensure thrown values are serializable (Error objects, not functions) |
| ERR_WORKER_OUT_OF_MEMORY | Worker terminated due to reaching memory limit | Increase `resourceLimits.maxOldGenerationSizeMb` |

## References

- `workers.md`
