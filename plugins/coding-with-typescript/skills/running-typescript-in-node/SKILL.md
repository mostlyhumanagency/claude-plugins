---
name: running-typescript-in-node
description: Use when running or publishing TypeScript in Node.js — type stripping, ts runners (tsx), .mts/.cts module rules, runtime import issues — or when you see ERR_MODULE_NOT_FOUND, TS2307 (cannot find module), or TS1286 (ESM syntax in CJS).
---

# Running TypeScript In Node

## Overview

Run TypeScript safely in Node and choose appropriate tooling for production.

## Version Scope

Assumes a modern Node.js runtime with built-in web APIs and type stripping; validate behavior if targeting older LTS lines.

## When to Use

- Deciding between Node v24 type stripping vs a TS runner.
- Aligning `.ts`/`.mts`/`.cts` module behavior with ESM/CJS.
- Publishing TS libraries with correct `exports` and types.

## When Not to Use

- You need full TypeScript transforms (enums, namespaces, parameter properties).
- You need `tsconfig` path mapping at runtime.
- You are targeting browsers instead of Node.

## Quick Reference

- Type stripping is enabled by default and ignores `tsconfig` at runtime.
- `.mts` is ESM and `.cts` is CommonJS.
- Always emit `.d.ts` for libraries.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS2307 | Cannot find module './x' | Add file extension (.ts/.mts) to the import specifier |
| TS1286 | ESM syntax is not allowed in CJS | Use `.mts` extension or set `"type": "module"` in package.json |
| ERR_MODULE_NOT_FOUND | Cannot find module (Node) | Add explicit file extension to import path |
| ERR_UNKNOWN_FILE_EXTENSION | Unknown file extension ".ts" | Upgrade to Node v24+ or use a TS runner like tsx |
| TS5110 | Option 'module' must be set | Align tsconfig module setting with your runtime |

## Examples

### Run TypeScript entry point

```bash
node src/index.ts
```

### Use a TS runner

```bash
npx tsx src/index.ts
```

### Ensure type-only imports

```ts
import type { Config } from './config.ts';
import { loadConfig } from './config.ts';
```

### Avoid TS-only runtime features without transpile

```ts
// Avoid enums/namespaces unless you transpile.
```

## References

- `typescript.md`
