# Node CLI Essentials (v24)

## Running Scripts

- `node app.js` runs a script once.
- `node --watch app.js` re-runs on file changes for dev loops.
- `node --watch-path=src app.js` limits watch scope on macOS and Windows.
- `node --watch-preserve-output app.js` prevents clearing the screen on restart.
- `node --env-file=.env` loads environment variables from a file when supported.

## REPL

- Run `node` with no args for the REPL.
- Use it to quickly evaluate snippets and inspect values.

## Standard I/O

- `process.stdin`, `process.stdout`, `process.stderr` are streams.
- Use piping for large input and output instead of buffering everything.

## Environment Variables

- Read via `process.env`.
- Validate and coerce types on startup.
- Set `NODE_USE_ENV_PROXY=1` to enable HTTP proxy environment variables (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`).

## Security

- Use `--zero-fill-buffers` to zero-fill newly allocated `Buffer` and `SlowBuffer` instances.

## Exit Codes

- Use `process.exitCode = 0` for success and non-zero for failure.
- Avoid `process.exit()` in async code unless you fully control cleanup.

## Quick Reference

| Feature | Command / API | Notes |
|---|---|---|
| Run script | `node app.js` | Single execution |
| Watch mode | `node --watch app.js` | Re-runs on file changes (dev only) |
| Watch path | `node --watch-path=src app.js` | Limits watch scope |
| Env file | `node --env-file=.env app.js` | Loads environment variables from file |
| Stdin | `process.stdin` (Readable stream) | Pipe data in for composable CLIs |
| Stdout | `process.stdout` (Writable stream) | Output data; errors to `process.stderr` |
| Exit code | `process.exitCode = N` | Prefer over `process.exit()` |
| Args | `process.argv.slice(2)` | Raw argument array after node and script |
| REPL | `node` (no args) | Quick inspection and evaluation |
| Proxy env | `NODE_USE_ENV_PROXY=1` | Enables HTTP_PROXY/HTTPS_PROXY |

## Common Mistakes

**Using `process.exit()` instead of `process.exitCode`** — `process.exit()` skips pending async work. Set `process.exitCode` and let the event loop drain.

**Writing errors to stdout instead of stderr** — Errors on stdout corrupt piped output. Always use `process.stderr.write()` or `console.error()`.

**Not handling empty stdin** — If no data is piped, stdin stays open. Set a timeout or detect TTY with `process.stdin.isTTY`.

**Trusting `process.argv` without validation** — User-supplied arguments can contain injection payloads. Validate and sanitize before using in shell commands or file paths.

## Constraints and Edges

- `node --watch` is for dev workflows, not production supervisors.
- `process.exit()` can skip pending async cleanup; prefer exit codes.
- Stdin can be empty; handle zero-length input without hanging.

## Do / Don't

- Do accept input from stdin for composable CLI tools.
- Do write errors to stderr, not stdout.
- Don't assume `process.argv` includes validated user input.
- Don't swallow errors without setting a non-zero exit code.

## Examples

### Read stdin and write to stdout

```js
process.stdin.setEncoding('utf8');
let data = '';
process.stdin.on('data', chunk => (data += chunk));
process.stdin.on('end', () => {
  process.stdout.write(data.toUpperCase());
});
```

### Basic argument parsing

```js
const args = process.argv.slice(2);
if (args.includes('--help')) {
  console.log('Usage: node app.js [--flag]');
  process.exitCode = 0;
}
```

### Handle SIGINT cleanly

```js
process.on('SIGINT', () => {
  console.error('Interrupted');
  process.exitCode = 130;
});
```

## Verification

- Check exit codes in shell: `echo $?`.
- Pipe input in tests to verify stdin handling.
