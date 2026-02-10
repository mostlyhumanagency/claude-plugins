---
name: working-with-node-streams
description: Use when working with Node.js v24 streams — large data handling, backpressure issues, pipeline composition, Node/Web Streams interop — or when you see ERR_STREAM_PREMATURE_CLOSE, ERR_STREAM_WRITE_AFTER_END, or memory spikes from unbounded buffering.
---

# Working With Node Streams

## Overview

Use streams for large data and respect backpressure.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Processing large files or network payloads.
- Composing pipelines of transforms.
- Debugging backpressure or memory spikes.
- Converting between Node streams and Web Streams.

## When Not to Use

- The data set is small and fits comfortably in memory.
- You need random access rather than sequential processing.
- You are dealing with async control flow rather than streaming.

## Quick Reference

- Use `stream.pipeline` for error handling and cleanup.
- Respect backpressure and wait for `'drain'` after `write(false)`.
- Prefer `objectMode` for non-binary data.
- Use `Readable.toWeb` / `Readable.fromWeb` for Web Streams interop.

## Examples

### Pipeline with cleanup

```js
const { pipeline } = require('node:stream/promises');
const fs = require('node:fs');

await pipeline(
  fs.createReadStream('in.txt'),
  fs.createWriteStream('out.txt')
);
```

### Respect backpressure

```js
if (!writable.write(chunk)) {
  await new Promise(resolve => writable.once('drain', resolve));
}
```

### Object mode transform

```js
const { Transform } = require('node:stream');
const upper = new Transform({
  objectMode: true,
  transform(obj, _enc, cb) {
    cb(null, String(obj).toUpperCase());
  }
});
```

### Web Streams interop

```js
const { Readable } = require('node:stream');
const nodeReadable = Readable.fromWeb(webReadable);
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_STREAM_PREMATURE_CLOSE | Premature close | Handle stream errors; use `pipeline()` for automatic cleanup |
| ERR_STREAM_WRITE_AFTER_END | write after end | Check stream state before writing; don't write after `.end()` |
| ERR_STREAM_DESTROYED | Cannot call write after a stream was destroyed | Ensure stream is not destroyed before writing |
| ERR_STREAM_PUSH_AFTER_EOF | stream.push() after EOF | Don't push data after pushing `null` to signal end |
| MaxListenersExceededWarning | Possible memory leak | Remove unused stream event listeners |

## References

- `streams.md`
