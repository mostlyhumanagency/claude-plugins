---
name: using-node-file-system
description: Use when reading or writing files in Node.js, creating directories, watching for file changes, listing directory contents, copying or moving files, or globbing file paths — covers fs/promises, readFile, writeFile, mkdir, readdir, watch, glob, stat, rename, and temp file patterns. Triggers on ENOENT, EACCES, EPERM, EISDIR, EMFILE, ENOSPC errors.
---

# Using Node File System

## Overview

Use the promise-based `node:fs/promises` API for file operations. Reserve streams for large files.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Reading and writing files or directories.
- Watching files for changes.
- Globbing file paths (v24+ built-in `fs.glob`).
- Streaming large files with backpressure.
- Creating temporary files and directories.

## When Not to Use

- You need to serve static files over HTTP — use `building-node-http-server`.
- You need to run shell commands to process files — use `using-node-child-processes`.

## Quick Reference

- Prefer `node:fs/promises` over callback-based `node:fs`.
- Always use `await` with promise-based APIs.
- Use `createReadStream`/`createWriteStream` for files larger than available memory.
- Close file handles explicitly with `fileHandle.close()` or use `using` (v24+).
- Use `fs.glob` (v24+) instead of third-party glob libraries.

## Examples

### Read and write files

```js
import { readFile, writeFile } from 'node:fs/promises';

const data = await readFile('input.txt', 'utf8');
await writeFile('output.txt', data.toUpperCase());
```

### Recursive directory listing

```js
import { readdir } from 'node:fs/promises';

const files = await readdir('./src', { recursive: true });
```

### Glob files (v24+)

```js
import { glob } from 'node:fs/promises';

for await (const entry of glob('**/*.js')) {
  console.log(entry);
}
```

### Stream a large file

```js
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';

await pipeline(
  createReadStream('large-input.csv'),
  createWriteStream('copy.csv')
);
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ENOENT | No such file or directory | Check the path exists before reading; create parent dirs with `mkdir({ recursive: true })` |
| EACCES | Permission denied | Check file permissions; run with appropriate user |
| EPERM | Operation not permitted | File may be read-only or locked by another process |
| EISDIR | Illegal operation on a directory | You tried to read/write a directory as a file |
| EMFILE | Too many open files | Close file handles; increase ulimit; use a queue |
| ENOSPC | No space left on device | Free disk space or write to a different volume |

## References

- `filesystem.md`
