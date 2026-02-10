---
name: managing-node-modules
description: Use when Node.js v24 module behavior is unclear — ESM vs CommonJS, package.json "type"/"exports" setup, dynamic import interop, module resolution — or when you see ERR_MODULE_NOT_FOUND, ERR_REQUIRE_ESM, ERR_PACKAGE_PATH_NOT_EXPORTED, or ERR_UNKNOWN_FILE_EXTENSION.
---

# Managing Node Modules

## Overview

Choose a module system intentionally and keep boundary rules explicit.

## Version Scope

Assumes a modern Node.js runtime with built-in web APIs and type stripping; validate behavior if targeting older LTS lines.

## When to Use

- Migrating between CommonJS and ESM.
- Designing package entry points with `exports`.
- Debugging resolution or conditional exports behavior.
- Evaluating dynamic import vs static import.

## When Not to Use

- You are focusing on packaging/publishing; use `publishing-node-packages`.
- You need bundler-specific module behavior.
- You only need a quick runtime import; use Node core guidance.

## Quick Reference

- Pick one module system per package when possible.
- Use explicit file extensions in ESM.
- Use `exports` to define the public surface area.
- Use `--input-type` for `--eval` and stdin.

## Examples

### Conditional exports

```json
{
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  }
}
```

### ESM entry point

```json
{
  "type": "module",
  "exports": {
    ".": "./dist/index.js"
  }
}
```

### CJS entry point

```json
{
  "type": "commonjs",
  "main": "./dist/index.cjs"
}
```

### Dynamic import from CJS

```js
const mod = await import('./feature.js');
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_MODULE_NOT_FOUND | Cannot find module | Add file extension to import specifier (.js/.mjs) |
| ERR_REQUIRE_ESM | require() of ES Module not supported | Use dynamic `import()` or convert to ESM |
| ERR_PACKAGE_PATH_NOT_EXPORTED | Package subpath not defined by "exports" | Add the subpath to the `exports` field in package.json |
| ERR_UNKNOWN_FILE_EXTENSION | Unknown file extension ".ts" | Use `.mjs`/`.cjs` or set `"type"` in package.json |
| ERR_IMPORT_ASSERTION_TYPE_MISSING | Import assertion type is missing | Add `{ type: 'json' }` for JSON imports |

## References

- `modules.md`
