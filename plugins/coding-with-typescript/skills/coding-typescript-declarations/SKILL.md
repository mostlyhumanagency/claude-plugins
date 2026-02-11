---
name: coding-typescript-declarations
description: Use when creating or editing .d.ts declaration files, typing untyped packages, adding ambient module declarations, augmenting existing modules (e.g. extending Express Request or Window), declaring global variables, or fixing missing type definitions. Also use when you see TS7016 (could not find declaration file), TS2305 (module has no exported member), TS2669 (augmentations for global scope), or TS2717 (subsequent property declarations must have same type).
---

# Coding TypeScript Declarations

## Overview

Type external modules and globals safely using `.d.ts` files and module augmentation. Keep scope minimal to avoid conflicts.

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| TS7016 | Could not find a declaration file for module | Install `@types/pkg` or add `declare module "pkg"` |
| TS2305 | Module '"x"' has no exported member | Check spelling or add the member to the declaration |
| TS2669 | Augmentations for the global scope can only be in external modules | Add `export {}` to make the file a module |
| TS2717 | Subsequent property declarations must have the same type | Ensure merged interface properties are compatible |
| TS1046 | Top-level 'await' requires module | Set `"module": "esnext"` or `"node20"` in tsconfig |

## References

- `declarations.md`
