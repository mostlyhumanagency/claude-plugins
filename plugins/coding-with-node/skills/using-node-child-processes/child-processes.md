# Node Child Processes (v24)

## Core APIs

- `spawn(command, args, options)` — stream-based, no shell by default.
- `exec(command, options, callback)` — shell-based, buffers output.
- `execFile(file, args, options, callback)` — runs file directly, no shell.
- `fork(modulePath, args, options)` — spawns Node process with IPC.

## Quick Reference

| Method | Shell | Output | IPC | Best For |
|---|---|---|---|---|
| `spawn` | No (opt-in) | Stream | No (opt-in) | Long-running, large output |
| `exec` | Yes | Buffered | No | Short commands, small output |
| `execFile` | No | Buffered | No | Running binaries safely |
| `fork` | No | Stream | Yes (built-in) | Node-to-Node IPC |

## spawn Options

| Option | Default | Notes |
|---|---|---|
| `cwd` | `process.cwd()` | Working directory |
| `env` | `process.env` | Environment variables |
| `stdio` | `'pipe'` | `'pipe'`, `'inherit'`, `'ignore'`, or array |
| `shell` | `false` | Set true to run in shell (use with caution) |
| `signal` | — | AbortSignal to cancel |
| `timeout` | `0` | Kill after ms (0 = no timeout) |
| `detached` | `false` | Run independently of parent |

## Common Mistakes

**Using shell: true with user input** — This enables command injection. Never pass user-controlled strings to `exec` or `spawn` with `shell: true`. Use `execFile` or `spawn` without shell and pass arguments as an array.

**Not handling the 'error' event** — If the command is not found, `spawn` emits `'error'`, not `'exit'`. Attach both handlers.

**Ignoring exit codes** — A child process may exit with a non-zero code indicating failure. Always check the exit code in the `'close'` or `'exit'` event.

**Forgetting to close stdin** — If piping data to a child process, call `child.stdin.end()` when done. Otherwise the child may hang waiting for more input.

**Exceeding maxBuffer with exec** — `exec` buffers all output in memory (default 1MB). For large output, use `spawn` with streaming.

## Constraints

- `exec` has a default `maxBuffer` of 1MB (1024 * 1024 bytes).
- `fork` only works with Node.js scripts (not arbitrary executables).
- IPC messages are serialized with `JSON.stringify` — no functions or circular references.
- `detached` processes may outlive the parent — call `child.unref()` to allow the parent to exit.

## Do / Don't

- Do use `spawn` with argument arrays for safety.
- Do use `execFile` instead of `exec` when you know the binary path.
- Do use `fork` for Node-to-Node communication with IPC.
- Do set timeouts to prevent hung child processes.
- Do use `AbortController` with `signal` option for cancellation.
- Don't use `exec` or `shell: true` with untrusted input.
- Don't ignore exit codes from child processes.
- Don't forget to handle both `'error'` and `'exit'` events.

## Examples

### spawn with AbortController

```js
import { spawn } from 'node:child_process';

const controller = new AbortController();
const child = spawn('long-running-cmd', [], { signal: controller.signal });

setTimeout(() => controller.abort(), 5000); // Cancel after 5s

child.on('error', (err) => {
  if (err.code === 'ABORT_ERR') console.log('Process aborted');
});
```

### fork with IPC

```js
// parent.js
import { fork } from 'node:child_process';

const child = fork('./worker.js');
child.send({ type: 'start', payload: { items: [1, 2, 3] } });
child.on('message', (msg) => {
  if (msg.type === 'done') {
    console.log('Result:', msg.result);
    child.disconnect();
  }
});

// worker.js
process.on('message', (msg) => {
  if (msg.type === 'start') {
    const result = msg.payload.items.reduce((a, b) => a + b, 0);
    process.send({ type: 'done', result });
  }
});
```

### Piping between processes

```js
import { spawn } from 'node:child_process';

const grep = spawn('grep', ['error']);
const cat = spawn('cat', ['app.log']);

cat.stdout.pipe(grep.stdin);
grep.stdout.on('data', (data) => console.log(data.toString()));
cat.on('close', () => grep.stdin.end());
```

### stdio configuration

```js
// Inherit parent's stdio (output goes to terminal)
spawn('npm', ['test'], { stdio: 'inherit' });

// Ignore all stdio
spawn('daemon', [], { stdio: 'ignore', detached: true }).unref();

// Custom: pipe stdout, inherit stderr, ignore stdin
spawn('cmd', [], { stdio: ['ignore', 'pipe', 'inherit'] });
```

## Verification

- Check `child.exitCode` after the `'close'` event.
- Use `child.killed` to verify if the process was killed by signal.
- Test IPC with `child.connected` before sending messages.
