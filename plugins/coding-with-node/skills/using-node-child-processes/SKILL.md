---
name: using-node-child-processes
description: Use when spawning external commands, running parallel processes, or using IPC with fork — or when you see ERR_CHILD_PROCESS_STDIO_MAXBUFFER, ENOENT (command not found), or EPERM errors related to child processes.
---

# Using Node Child Processes

## Overview

Spawn external commands and parallel Node processes with `node:child_process`. Choose the right method for each use case.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Running shell commands or external binaries from Node.
- Parallel processing with separate Node processes via `fork`.
- Piping data between processes.
- Running untrusted or resource-heavy tasks in isolation.

## When Not to Use

- CPU-intensive JavaScript work — use `worker_threads` (same process, shared memory).
- Simple async I/O — the event loop handles this without child processes.
- You need shared memory between parent and child — use `worker_threads` with SharedArrayBuffer.

## Quick Reference

- `spawn` — stream-based, best for long-running processes or large output.
- `exec` — buffered output, best for short commands where you want stdout as a string.
- `execFile` — like `exec` but runs a file directly (no shell), safer.
- `fork` — spawns a new Node process with built-in IPC channel.
- Always handle `'error'` and `'exit'` events.
- Avoid `shell: true` with user-controlled input (command injection risk).

## Examples

### spawn — stream output

```js
import { spawn } from 'node:child_process';

const child = spawn('ls', ['-la', '/tmp']);
child.stdout.on('data', (data) => console.log(data.toString()));
child.stderr.on('data', (data) => console.error(data.toString()));
child.on('close', (code) => console.log('Exited with', code));
```

### exec — buffered output

```js
import { exec } from 'node:child_process';
import { promisify } from 'node:util';

const execAsync = promisify(exec);
const { stdout, stderr } = await execAsync('git log --oneline -5');
console.log(stdout);
```

### fork — IPC messaging

```js
import { fork } from 'node:child_process';

const child = fork('./worker.js');
child.send({ task: 'process', data: [1, 2, 3] });
child.on('message', (result) => console.log('Result:', result));
```

### execFile — no shell

```js
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);
const { stdout } = await execFileAsync('node', ['--version']);
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_CHILD_PROCESS_STDIO_MAXBUFFER | stdout/stderr maxBuffer exceeded | Increase `maxBuffer` option or use `spawn` for streaming |
| ENOENT | spawn ENOENT | Command not found; check the command exists and PATH is correct |
| EPERM | Operation not permitted | Insufficient permissions to execute the command |
| ERR_IPC_CHANNEL_CLOSED | Channel closed | IPC channel was closed before message was sent; check child is still running |

## References

- `child-processes.md`
