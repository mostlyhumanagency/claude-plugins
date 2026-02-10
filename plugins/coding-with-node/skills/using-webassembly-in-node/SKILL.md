---
name: using-webassembly-in-node
description: Use when running or embedding WebAssembly in Node.js — loading .wasm files, validating exports, JS↔WASM memory and data exchange — or when you see CompileError, LinkError, RuntimeError from WebAssembly, or memory access issues.
---

# Using WebAssembly In Node

## Overview

Load and execute WebAssembly modules safely with explicit boundaries.

## Version Scope

Assumes a modern Node.js runtime with built-in web APIs and type stripping; validate behavior if targeting older LTS lines.

## When to Use

- Calling WebAssembly from Node for performance or portability.
- Managing memory and data exchange across JS/WASM.
- Loading WASM modules from files or buffers.

## When Not to Use

- The workload is I/O-bound and better served by async JS.
- You need dynamic plugin loading without strict contracts.
- You are optimizing micro-hotpaths before profiling.

## Quick Reference

- Compile or instantiate from a `Buffer` or `WebAssembly.Module`.
- Validate expected exports before calling.
- Keep JS↔WASM boundaries small and typed.

## Examples

### Instantiate a module

```js
const fs = require('node:fs');
const bytes = fs.readFileSync('module.wasm');
const { instance } = await WebAssembly.instantiate(bytes, {});
```

### Validate exports

```js
const { add } = instance.exports;
if (typeof add !== 'function') throw new Error('missing export: add');
```

### Use linear memory

```js
const mem = instance.exports.memory;
const view = new Uint8Array(mem.buffer);
view[0] = 255;
```

### Limit input sizes

```js
if (input.length > 64 * 1024) throw new Error('input too large');
```

## Common Errors

| Error Type | Message Fragment | Fix |
|---|---|---|
| CompileError | WebAssembly.compile(): invalid module | Ensure .wasm file is valid; re-compile from source |
| LinkError | WebAssembly.instantiate(): import mismatch | Provide all required imports with correct signatures |
| RuntimeError | memory access out of bounds | Validate offsets before read/write; grow memory if needed |
| RuntimeError | unreachable executed | WASM hit an unreachable instruction; check logic |
| TypeError | WebAssembly.instantiate(): argument must be BufferSource | Pass a Buffer or ArrayBuffer, not a string or path |

## References

- `webassembly.md`
