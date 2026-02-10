# WebAssembly in Node.js

## Loading Modules

- Use `WebAssembly.compile` or `WebAssembly.instantiate`.
- Validate expected exports before calling into the module.

## Memory and Data Exchange

- Use `WebAssembly.Memory` and typed arrays for shared buffers.
- Keep JS↔WASM boundaries small and strongly typed.

## Quick Reference

| Operation | API | Notes |
|---|---|---|
| Compile | `WebAssembly.compile(buffer)` | Compile .wasm bytes to a Module |
| Instantiate | `WebAssembly.instantiate(bytes, imports)` | Compile + create instance in one step |
| Validate | `WebAssembly.validate(bytes)` | Check if bytes are valid WASM |
| Access memory | `new Uint8Array(instance.exports.memory.buffer)` | Typed array view of linear memory |
| Grow memory | `instance.exports.memory.grow(pages)` | Each page is 64KB |
| Call export | `instance.exports.fn(args)` | Call exported WASM function |
| Import object | `{ env: { log: console.log } }` | Provide JS functions to WASM |

## Common Mistakes

**Not validating exports before calling** — Accessing a missing export returns `undefined`, not a function. Check `typeof export === 'function'` before calling.

**Forgetting memory buffer invalidation after `grow()`** — `memory.grow()` may detach the old `ArrayBuffer`. Re-create typed array views after growing memory.

**Passing large inputs without size validation** — Unbounded input can exhaust linear memory. Validate input sizes before copying into WASM memory.

**Assuming memory layout without contracts** — WASM memory is unstructured bytes. Document offset conventions and validate before reading/writing.

## Constraints and Edges

- Validate input sizes before copying into linear memory.
- Do not assume memory layout without explicit contracts.
- Avoid calling exports that are missing or mismatched.

## Do / Don't

- Do validate input sizes before copying into WASM memory.
- Do check for missing exports and provide clear errors.
- Don't expose untrusted inputs without validation.
- Don't assume a module's memory layout without explicit contracts.

## Examples

### Instantiate from a buffer

```js
const fs = require('node:fs');
const bytes = fs.readFileSync('module.wasm');
const { instance } = await WebAssembly.instantiate(bytes, {});
```

### Use exported functions

```js
const { add } = instance.exports;
const result = add(2, 3);
```

### Access linear memory

```js
const mem = instance.exports.memory;
const view = new Uint8Array(mem.buffer);
view[0] = 255;
```

## WASI (WebAssembly System Interface)

Run WASM modules with system access through WASI:

```js
import { readFile } from 'node:fs/promises';
import { WASI } from 'node:wasi';

const wasi = new WASI({
  version: 'preview1',
  args: process.argv,
  env: process.env,
  preopens: { '/sandbox': './data' },
});

const wasm = await WebAssembly.compile(await readFile('./module.wasm'));
const instance = await WebAssembly.instantiate(wasm, wasi.getImportObject());
wasi.start(instance);
```

WASI provides sandboxed access to the file system, environment, and stdio. Use `preopens` to grant access to specific directories.

## Streaming Compilation

Compile WASM modules from a stream for better memory efficiency:

```js
const response = await fetch('https://example.com/module.wasm');
const module = await WebAssembly.compileStreaming(response);
const instance = await WebAssembly.instantiate(module);
```

`compileStreaming` compiles while downloading, reducing peak memory usage for large modules.

## Verification

- Assert exports exist before calling them.
- Validate memory bounds in tests.
