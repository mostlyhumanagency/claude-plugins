# Sources

Content provenance for the Node.js skill suite.

## Primary Sources

| Source | URL | Used For |
|---|---|---|
| Node.js v24 Documentation | https://nodejs.org/docs/latest/api/ | Core APIs, streams, modules, test runner, CLI, diagnostics |
| Node.js Guides | https://nodejs.org/en/learn | Event loop, backpressure, module system |
| Node.js GitHub | https://github.com/nodejs/node | Error codes, runtime behavior, edge cases |
| Undici Documentation | https://undici.nodejs.org | fetch implementation details |
| WebAssembly MDN | https://developer.mozilla.org/en-US/docs/WebAssembly | WASM API reference |
| npm Documentation | https://docs.npmjs.com | Package publishing, exports field, semver |

## Content Guidelines

- All code examples are original, written to illustrate patterns from the sources above
- Error codes (ERR_*) are verified against the Node.js source
- All content targets Node.js v24; validate behavior for older LTS lines
- Runtime behavior is tested against the documented Node version

## Last Updated

2026-02-06
