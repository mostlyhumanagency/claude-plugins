---
name: using-node-cli
description: Use when working with the Node.js v24 CLI — running scripts, REPL usage, stdin/stdout handling, env file loading, watch mode, exit codes — or when you see ERR_INVALID_ARG_VALUE, unexpected exit code behavior, or stdin/stdout piping issues.
---

# Using Node CLI

## Overview

Run Node scripts, use the REPL, and handle standard I/O safely.

## Version Scope

Assumes a modern Node.js runtime with built-in web APIs and type stripping; validate behavior if targeting older LTS lines.

## When to Use

- Running scripts with flags and environment configuration.
- Using the REPL for quick inspection.
- Building CLI tools that read and write streams.
- Handling exit codes and process signals.

## When Not to Use

- You need a full-featured CLI framework (commands, completion, prompts).
- You need persistent TUI behavior; a terminal UI library is a better fit.
- You are primarily teaching stream backpressure; use `working-with-node-streams`.

## Quick Reference

- Use `process.stdin` and `process.stdout` as streams.
- Prefer `process.exitCode` over `process.exit()` in async code.
- Use `node --watch` and `--watch-path` for dev loops.
- Use `--watch-preserve-output` to keep screen output.
- Load env files with `node --env-file` when supported.
- Use `NODE_USE_ENV_PROXY=1` to enable proxy env vars.
- Use `--zero-fill-buffers` for sensitive data.

## Examples

### Read stdin and write stdout

```js
process.stdin.setEncoding('utf8');
let data = '';
process.stdin.on('data', chunk => (data += chunk));
process.stdin.on('end', () => process.stdout.write(data));
```

### Run with watch

```bash
node --watch app.js
```

### Load env file

```bash
node --env-file=.env app.js
```

### Set exit code on error

```js
try {
  run();
} catch {
  process.exitCode = 1;
}
```

## Common Errors

| Code / Issue | Message Fragment | Fix |
|---|---|---|
| ERR_INVALID_ARG_VALUE | Invalid argument value | Validate CLI arguments and env vars before use |
| ERR_WORKER_PATH | Absolute path required for Worker | Use `path.resolve()` or `new URL()` for worker paths |
| EPIPE | Write after pipe closed | Handle `process.stdout` errors when piped output is closed early |
| ERR_USE_AFTER_CLOSE | Cannot use after close | Don't write to stdin/stdout after stream is closed |
| Exit code 130 | Process terminated by SIGINT | Add SIGINT handler for cleanup before exit |

## References

- `cli.md`
