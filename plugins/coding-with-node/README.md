# skill-coding-node

A Claude Code plugin for working with Node.js v24 — core runtime, async patterns, streams, modules, testing, web APIs, and more.

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
| `using-node-test-runner` | node:test, filtering, sharding, reporters, coverage |
| `using-node-web-apis` | fetch, URL/URLPattern, WebSocket client, AbortController |
| `using-webassembly-in-node` | Loading .wasm, JS↔WASM memory and data exchange, export validation |
| `diagnosing-node` | CPU profiles, heap snapshots, diagnostic reports, inspector debugging |

## Installation

### As a plugin (recommended)

```sh
/plugin marketplace add mostlyhumanagency/skill-coding-node
```

### Manual

Symlink each skill directory into `~/.claude/skills/`:

```sh
git clone <repo-url>
for skill in skills/*/; do
  ln -s "$(pwd)/$skill" ~/.claude/skills/$(basename "$skill")
done
```
