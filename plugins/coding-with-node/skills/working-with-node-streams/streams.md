# Node Streams (v24)

## Core Concepts

- Readable, Writable, Duplex, and Transform streams.
- Backpressure prevents producers from overwhelming consumers.
- Duplex and Transform streams maintain separate internal buffers for read/write sides.

## Backpressure and Flow

- Honor `write()` return values; when `false`, wait for `'drain'`.
- Prefer `stream.pipeline()` to wire streams with proper error handling and cleanup.
- Avoid manual `data` handlers unless you understand flowing mode.

## Web Streams Interop

- Web Streams (WHATWG) are stable and widely supported.
- Convert Node streams to Web Streams via `Readable.toWeb`, `Writable.toWeb`, and `Duplex.toWeb`.
- Convert Web Streams to Node streams via `Readable.fromWeb`, `Writable.fromWeb`, and `Duplex.fromWeb`.
- `Readable.fromWeb` is stable in v24.

## Quick Reference

| Pattern | API | Use When |
|---|---|---|
| Pipeline | `stream.pipeline(src, ...transforms, dest)` | Composing streams with error handling |
| Backpressure | Check `write()` return, wait for `'drain'` | Writing faster than consumer can handle |
| Transform | `new Transform({ transform(chunk, enc, cb) })` | Processing data chunk-by-chunk |
| Object mode | `{ objectMode: true }` | Streaming non-binary data (objects, strings) |
| Node → Web | `Readable.toWeb(nodeStream)` | Passing to Web API consumers |
| Web → Node | `Readable.fromWeb(webStream)` | Consuming Web ReadableStream in Node |
| Async iteration | `for await (const chunk of stream)` | Simple consumption without event handlers |

## Common Mistakes

**Ignoring backpressure (memory spikes)** — Not checking `write()` return value causes unbounded buffering. Always wait for `'drain'` when `write()` returns `false`.

**Using `.on('data')` without `.pause()`** — Attaching a `data` handler switches to flowing mode. Use `pipeline()` or async iteration instead.

**Not handling errors on all streams** — An unhandled error on any stream in a chain crashes the process. Use `pipeline()` which propagates errors automatically.

**Mixing flowing and paused modes** — Calling `.read()` and `.on('data')` on the same stream causes unpredictable behavior. Pick one consumption pattern.

## Constraints and Edges

- Avoid mixing flowing and paused modes accidentally.
- Backpressure only works if every stream in the chain honors it.
- For tiny payloads, streams add overhead without benefit.

## Do / Don't

- Do honor backpressure and avoid buffering entire inputs.
- Do handle errors on all streams in the chain.
- Don't mix flowing and paused modes without intent.
- Don't use undocumented internal buffers for normal usage.

## Examples

### Pipeline with error handling

```js
const { pipeline } = require('node:stream/promises');
const fs = require('node:fs');

await pipeline(
  fs.createReadStream('in.txt'),
  fs.createWriteStream('out.txt')
);
```

### Transform stream

```js
const { Transform } = require('node:stream');

const upper = new Transform({
  transform(chunk, _enc, cb) {
    cb(null, chunk.toString().toUpperCase());
  }
});
```

### Web Streams interop

```js
const { Readable } = require('node:stream');
const { ReadableStream } = require('node:stream/web');

const web = new ReadableStream();
const nodeReadable = Readable.fromWeb(web);
```

## Verification

- Test with large files to confirm memory stays flat.
- Simulate slow consumers to verify backpressure.
