---
name: running-typescript-in-node
description: Use when running .ts files directly in Node.js without a build step, prototyping TypeScript scripts, configuring tsconfig.json for Node.js, or fixing TypeScript execution errors — covers --experimental-strip-types, .ts/.mts/.cts file handling, type stripping limitations (no enums/namespaces), and tsconfig moduleResolution settings. Triggers on ERR_UNKNOWN_FILE_EXTENSION, unsupported TypeScript syntax errors.
---

# Running TypeScript in Node

## Overview

Run TypeScript files directly in Node.js by stripping type annotations at load time, without a separate compilation step.

## Version Scope

The `--experimental-strip-types` flag is available in Node.js v24+. This feature is experimental and may change.

## When to Use

- Running `.ts` files directly during development.
- Prototyping without a build step.
- Scripts and CLI tools written in TypeScript.
- Setting up tsconfig.json for Node.js projects.

## When Not to Use

- You need enums, namespaces, or parameter decorators — these require a build step.
- Production builds — use `tsc` or a bundler for compiled output.
- You need declaration file (.d.ts) generation.

## Quick Reference

- Run with `node --experimental-strip-types file.ts`.
- Works with: type annotations, interfaces, type aliases, generics, `as const`.
- Does NOT work with: enums, namespaces, parameter decorators, `const enum`.
- Use `.mts` for ESM, `.cts` for CommonJS TypeScript files.
- Set `"module": "node20"` and `"moduleResolution": "node20"` in tsconfig.json.
- Use const objects instead of enums.

## Examples

### Run a TypeScript file

```bash
node --experimental-strip-types app.ts
```

### What works

```ts
// Type annotations — stripped at runtime
function greet(name: string): string {
  return `Hello, ${name}`;
}

// Interfaces — stripped entirely
interface User {
  id: number;
  name: string;
}

// Generics — stripped
function first<T>(items: T[]): T | undefined {
  return items[0];
}

// as const — works fine
const COLORS = ['red', 'green', 'blue'] as const;
```

### What does NOT work

```ts
// Enums — use const objects instead
// BAD: enum Direction { Up, Down }
// GOOD:
const Direction = { Up: 0, Down: 1 } as const;
type Direction = typeof Direction[keyof typeof Direction];
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_UNKNOWN_FILE_EXTENSION | Unknown file extension ".ts" | Add --experimental-strip-types flag |
| SyntaxError | Unexpected token 'enum' | Replace enum with const object |
| SyntaxError | Decorators are not valid here | Remove parameter decorators; use a build step |
| ERR_MODULE_NOT_FOUND | Cannot find module | Check import specifier and file extension |

## References

- `typescript.md`
