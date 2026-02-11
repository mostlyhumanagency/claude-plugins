---
name: coding-typescript-tooling
description: Use when configuring tsconfig.json, choosing compiler options, setting up module resolution (node, bundler, nodenext), enabling strict mode flags, fixing tsconfig errors, upgrading TypeScript versions, understanding new TS features, or resolving ESM vs CJS module issues. Also use when you see TS5110 (module format mismatch), TS1286 (ESM syntax in CJS), TS6133 (declared but never used), TS1371 (import never used as value), or TS5023 (unknown compiler option).
---

# Coding TypeScript Tooling

## Overview

Configure strict, modern TypeScript settings and align them with the runtime (Node, bundler, browser). Use the release notes to verify feature availability by TS version.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS5110 | Option 'module' must be set to | Match module setting to your runtime (node20, esnext, bundler) |
| TS1286 | ESM syntax not allowed in CJS file | Use `.mts` extension or set `"type": "module"` in package.json |
| TS6133 | 'x' is declared but its value is never read | Remove unused variable or prefix with `_` |
| TS1371 | This import is never used as a value | Use `import type` for type-only imports |
| TS5023 | Unknown compiler option | Check tsconfig spelling or TS version compatibility |

## References

- `ts-config.md`
- `ts-features.md`
- `testing.md`
- `test-scenarios.md`
