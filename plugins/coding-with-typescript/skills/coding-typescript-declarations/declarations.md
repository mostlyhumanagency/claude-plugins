# Declarations and Augmentation

## Overview

Use declaration files and augmentation to type external modules, globals, and legacy libraries. Keep declarations scoped and minimal.

## Ambient Module Declarations

Use when importing non-TS assets or untyped modules:

```typescript
// globals.d.ts
declare module "*.css" {}
```

```typescript
// Un-typed package
declare module "legacy-lib" {
  export function doWork(input: string): number;
}
```

## Global Declarations

```typescript
// globals.d.ts
export {};

declare global {
  interface Array<T> {
    first(): T | undefined;
  }
}

Array.prototype.first = function () {
  return this[0];
};
```

Use `export {}` to ensure the file is treated as a module and avoid accidental global scope pollution.

## Module Augmentation

```typescript
import "express";

declare module "express" {
  interface Request {
    user?: User;
  }
}
```

Augmentations add to existing declarations; they do not replace or create unrelated top-level declarations.

## Declaration Merging

Interfaces with the same name merge:

```typescript
interface ApiConfig {
  baseUrl: string;
}

interface ApiConfig {
  timeoutMs: number;
}

const config: ApiConfig = {
  baseUrl: "https://api.example.com",
  timeoutMs: 5000
};
```

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Ambient module | `declare module "*.css" {}` | Typing non-TS imports (CSS, JSON, images) |
| Untyped package | `declare module "lib" { ... }` | Adding types for a package without `@types` |
| Global augmentation | `declare global { ... }` | Extending global types (Array, Window) |
| Module augmentation | `declare module "express" { ... }` | Adding fields to third-party module types |
| Declaration merging | Two `interface Foo` blocks | Extending an interface across files |
| export {} guard | `export {};` at top of .d.ts | Ensuring file is treated as a module |

## Common Mistakes

**Missing `export {}` in .d.ts (TS2669)** — Without it, declarations pollute the global scope. Always include `export {}` to force module treatment.

**Augmenting instead of declaring (TS2305)** — `declare module "x"` inside a module augments; at top level it replaces. Make sure the file context matches your intent.

**Conflicting declaration merging (TS2717)** — Two interfaces with the same property name but different types cause errors. Ensure merged declarations are compatible.

**Forgetting to install `@types` (TS7016)** — `Could not find a declaration file for module`. Install `@types/package` or write a local `declare module`.

## When to Avoid

- Avoid global augmentation unless necessary.
- Prefer module augmentation scoped to specific modules.
- Keep `.d.ts` files small and targeted to reduce type conflicts.
