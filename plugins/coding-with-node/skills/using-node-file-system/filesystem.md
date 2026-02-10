# Node File System (v24)

## Core APIs

- `node:fs/promises` — promise-based file operations (preferred).
- `node:fs` — callback and synchronous variants.
- `node:fs/promises` glob (v24+) — built-in file globbing.

## Quick Reference

| API | Purpose | Notes |
|---|---|---|
| `readFile(path, encoding)` | Read entire file | Use `'utf8'` for text, omit for Buffer |
| `writeFile(path, data)` | Write entire file | Creates or overwrites |
| `appendFile(path, data)` | Append to file | Creates if missing |
| `mkdir(path, { recursive })` | Create directory | `recursive: true` creates parents |
| `rm(path, { recursive, force })` | Delete file/dir | `force: true` ignores ENOENT |
| `readdir(path, { recursive })` | List directory | `recursive: true` for deep listing |
| `stat(path)` | Get file metadata | size, mtime, isFile(), isDirectory() |
| `rename(oldPath, newPath)` | Move/rename | Atomic on same filesystem |
| `copyFile(src, dest)` | Copy file | Uses `COPYFILE_EXCL` flag to prevent overwrite |
| `watch(path, options)` | Watch for changes | Returns async iterable (v24+) |
| `glob(pattern)` | Match file paths | v24+ built-in, returns async iterable |
| `open(path, flags)` | Get FileHandle | Must close explicitly |

## Common Mistakes

**Using sync methods in async code paths** — `readFileSync`, `writeFileSync`, etc. block the event loop. Use `node:fs/promises` for all async contexts.

**Not closing file handles** — `fs.open()` returns a FileHandle that must be closed. Use try/finally or the `using` keyword (v24+).

**Forgetting recursive option for mkdir** — `mkdir('a/b/c')` fails if `a/b` does not exist. Always pass `{ recursive: true }` unless the parent is guaranteed to exist.

**Race conditions with stat-then-act** — Checking `stat` then acting on the result is a TOCTOU race. Use flag-based APIs (`writeFile` with `wx` flag) or catch errors instead.

**Reading large files into memory** — `readFile` loads the entire file. For files larger than ~100MB, use `createReadStream` with streaming.

## Constraints

- `readFile` loads the entire file into memory — not suitable for very large files.
- `watch` behavior varies by platform (macOS uses FSEvents, Linux uses inotify).
- `rename` across filesystems requires copy + delete.
- `glob` is v24+ only — use a third-party package for older Node versions.

## Do / Don't

- Do use `node:fs/promises` over callback or sync APIs.
- Do use streams for files larger than available memory.
- Do use `mkdir({ recursive: true })` to create nested directories.
- Do close file handles in a finally block or with `using`.
- Don't use sync APIs in request handlers or hot paths.
- Don't check existence then act — catch errors instead.
- Don't read binary files with `'utf8'` encoding.

## Examples

### Safe file write with temp file

```js
import { writeFile, rename } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';

const tempPath = join(tmpdir(), randomUUID());
await writeFile(tempPath, data);
await rename(tempPath, finalPath); // atomic on same filesystem
```

### Watch directory for changes

```js
import { watch } from 'node:fs/promises';

const watcher = watch('./src', { recursive: true });
for await (const event of watcher) {
  console.log(event.eventType, event.filename);
}
```

### FileHandle with using (v24+)

```js
import { open } from 'node:fs/promises';

{
  using file = await open('data.txt', 'r');
  const content = await file.readFile('utf8');
  // file.close() called automatically
}
```

### Temporary directory

```js
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const dir = await mkdtemp(join(tmpdir(), 'myapp-'));
try {
  // use dir...
} finally {
  await rm(dir, { recursive: true, force: true });
}
```

## Verification

- Use `stat()` to confirm file was written with expected size.
- Use `access()` to check permissions before opening.
- Run `node -e "import('node:fs/promises').then(fs => fs.readdir('.'))"` to verify fs works.
