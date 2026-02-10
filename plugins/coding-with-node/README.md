# coding-with-node

A Claude Code plugin for Node.js v24 — 19 skills, 4 agents, 4 commands, 6 scripts, and 7 templates covering runtime, async, streams, modules, testing, crypto, security, and more.

## Skills

| Skill | Description |
|---|---|
| `coding-node` | Router — routes to the most specific Node.js subskill |
| `understanding-node-core` | Runtime model, globals, process lifecycle, event loop, errors, buffers, security |
| `handling-node-async` | Event loop ordering, timers, callback/promise conversion, AsyncLocalStorage, EventEmitter |
| `working-with-node-streams` | Streams, backpressure, pipeline composition, Web Streams interop |
| `managing-node-modules` | ESM vs CommonJS, package.json type/exports, dynamic imports, module resolution |
| `publishing-node-packages` | npm publishing, exports/types entry points, Node-API addons, versioning |
| `using-node-cli` | Running scripts, REPL, stdin/stdout, env files, watch mode, exit codes |
| `using-node-test-runner` | node:test, filtering, sharding, reporters, coverage, snapshots, mocking |
| `using-node-web-apis` | fetch, URL/URLPattern, WebSocket client, AbortController |
| `using-webassembly-in-node` | Loading .wasm, WASI, JS-WASM memory exchange, streaming compilation |
| `diagnosing-node` | CPU profiles, heap snapshots, diagnostic reports, V8 profiler |
| `using-node-worker-threads` | Worker creation, SharedArrayBuffer, Atomics, message channels, transferables |
| `using-node-file-system` | File I/O with fs/promises, watching, glob, recursive operations, temp files |
| `building-node-http-server` | HTTP/HTTPS servers, request handling, routing, graceful shutdown |
| `using-node-child-processes` | spawn, exec, fork, IPC messaging, signal handling, shell safety |
| `using-node-crypto` | Hashing, encryption, password hashing, secure random, signing, Web Crypto |
| `using-node-sqlite` | Built-in SQLite (v24+), queries, prepared statements, transactions |
| `securing-node-applications` | Permission model, input validation, security patterns, dependency auditing |
| `running-typescript-in-node` | Type stripping, running .ts files directly, tsconfig for Node |

## Agents

| Agent | Model | Description |
|---|---|---|
| `node-expert` | opus | Full-featured Node.js expert with access to all skills |
| `node-debugger` | sonnet | Runtime error diagnosis — error codes, stack traces, crash debugging |
| `node-security-auditor` | sonnet | Security audit — OWASP patterns, dependency vulnerabilities, code scanning |
| `node-perf-profiler` | sonnet | Performance diagnostics — CPU profiles, memory leaks, event loop analysis |

## Commands

| Command | Description |
|---|---|
| `/node-doctor` | Audit project health: package.json, engine compatibility, deprecated APIs |
| `/node-deps` | Analyze dependencies: unused, outdated, vulnerabilities, duplicates |
| `/node-perf` | Profile performance: anti-patterns, event loop blocking, optimization |
| `/node-test` | Run tests and analyze coverage results |

## Scripts

| Script | Description |
|---|---|
| `check-esm-compat.sh` | Scan for CJS patterns that break in ESM mode |
| `audit-dependencies.sh` | Dependency health check (audit + outdated + size) |
| `check-node-version.sh` | Verify Node version consistency across config files |
| `check-deprecated-apis.sh` | Find deprecated Node.js API usage |
| `check-package-json.sh` | Validate package.json best practices |
| `find-sync-calls.sh` | Find synchronous blocking calls in source code |

## Templates

| Template | Description |
|---|---|
| `package-esm.json` | Modern ESM Node.js project starter |
| `package-library.json` | Dual ESM/CJS library with conditional exports |
| `docker-node.Dockerfile` | Multi-stage Dockerfile with non-root user |
| `env.example` | Common Node.js environment variables |
| `jest.config.js` | Jest configuration for Node.js ESM projects |
| `vitest.config.js` | Vitest configuration with v8 coverage |
| `npmrc` | npm and pnpm settings (.npmrc) |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/coding-with-node
```
