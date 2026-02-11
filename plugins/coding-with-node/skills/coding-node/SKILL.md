---
name: coding-node
description: Use when writing, reviewing, debugging, or architecting any Node.js application code — building APIs, creating servers, reading files, running shell commands, writing tests, handling async logic, processing data, managing dependencies, or deploying packages. Routes to the specific Node.js subskill for HTTP servers, async patterns, streams, modules, testing, file system, crypto, workers, child processes, SQLite, WebAssembly, diagnostics, security, CLI tools, web APIs, and TypeScript execution.
---

# Coding Node (Dispatcher)

## Overview

Pick the most specific Node.js skill and use it. Do not load broad references unless no specific skill fits.

## Skill Map

- `understanding-node-core` for runtime model, globals, process lifecycle, event loop, errors, buffers, security
- `handling-node-async` for event loop ordering, timers, callback/promise conversion, AsyncLocalStorage, EventEmitter
- `working-with-node-streams` for large data, backpressure, pipeline composition, Web Streams interop
- `managing-node-modules` for ESM vs CommonJS, package.json type/exports, dynamic imports, resolution
- `publishing-node-packages` for npm publishing, exports/types entry points, Node-API addons, versioning
- `using-node-cli` for running scripts, REPL, stdin/stdout, env files, watch mode, exit codes
- `using-node-test-runner` for node:test, filtering, sharding, reporters, coverage
- `using-node-web-apis` for fetch, URL/URLPattern, WebSocket client, AbortController
- `using-webassembly-in-node` for loading .wasm, JS↔WASM memory, export validation
- `diagnosing-node` for CPU profiles, heap snapshots, diagnostic reports, debugging
- `using-node-worker-threads` for Worker creation, SharedArrayBuffer, Atomics, message channels, transferable objects
- `using-node-file-system` for file I/O with fs/promises, watching, glob, recursive operations, temp files
- `building-node-http-server` for HTTP/HTTPS servers, request handling, routing, graceful shutdown
- `using-node-child-processes` for spawn, exec, fork, IPC messaging, signal handling, shell safety
- `using-node-crypto` for hashing, encryption, password hashing, random bytes, Web Crypto API
- `using-node-sqlite` for built-in SQLite database, queries, prepared statements, transactions
- `securing-node-applications` for permission model, input validation, security patterns, dependency auditing
- `running-typescript-in-node` for type stripping, running .ts files, tsconfig for Node
