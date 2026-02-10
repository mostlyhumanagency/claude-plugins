# Declarations and Augmentation

## Overview

Use declaration files and augmentation to type external modules, globals, and legacy libraries. Keep declarations scoped and minimal.

## Triple-Slash Directives

Reference directives at the top of a file (before any code):

```typescript
/// <reference types="node" />       // Include @types/node
/// <reference path="./globals.d.ts" /> // Include local declaration
/// <reference lib="dom" />           // Include built-in lib
```

- `types` — loads an `@types` package (e.g., `/// <reference types="jest" />`)
- `path` — includes another declaration file relative to current file
- `lib` — includes a built-in TypeScript lib (dom, es2022, etc.)

Use sparingly — prefer `types` and `lib` in tsconfig.json instead.

## Ambient Module Declarations

Use when importing non-TS assets or untyped modules:

```typescript
// globals.d.ts — typing CSS imports
declare module "*.css" {
  const classes: { readonly [key: string]: string };
  export default classes;
}

// typing image imports
declare module "*.png" {
  const src: string;
  export default src;
}
```

```typescript
// Typing an untyped npm package
declare module "legacy-lib" {
  export function doWork(input: string): number;
  export interface Config {
    retries: number;
    timeout: number;
  }
}
```

### Typing an Entire Untyped Package

When `@types/pkg` doesn't exist, create `types/pkg.d.ts`:

```typescript
// types/legacy-analytics.d.ts
declare module "legacy-analytics" {
  interface Event {
    name: string;
    properties?: Record<string, unknown>;
  }

  export function track(event: Event): void;
  export function identify(userId: string, traits?: Record<string, unknown>): void;
  export function page(name?: string): void;
}
```

Then add to tsconfig:
```json
{
  "compilerOptions": {
    "typeRoots": ["./types", "./node_modules/@types"]
  }
}
```

## `types` vs `typeRoots` in tsconfig

| Setting | Purpose | Default |
|---|---|---|
| `typeRoots` | Directories to search for `@types` packages | `["./node_modules/@types"]` |
| `types` | Whitelist specific `@types` packages to include | All found in typeRoots |

```json
// Only include specific @types packages (reduces noise)
{
  "compilerOptions": {
    "types": ["node", "jest"]
  }
}

// Add custom type directories alongside @types
{
  "compilerOptions": {
    "typeRoots": ["./types", "./node_modules/@types"]
  }
}
```

**Key rule**: Setting `types` means ONLY listed packages are included. Unlisted `@types` are excluded.

## Global Declarations

```typescript
// globals.d.ts
export {};  // REQUIRED — forces module treatment

declare global {
  interface Window {
    analytics: {
      track(event: string, props?: Record<string, unknown>): void;
    };
  }

  // Add method to built-in type
  interface Array<T> {
    first(): T | undefined;
  }

  // Global variable
  var __APP_VERSION__: string;
}
```

The `export {}` is critical — without it, the file is a script (not a module) and declarations pollute the global scope unpredictably.

## Module Augmentation

Extend types from third-party packages without modifying them:

### Express Request Extension

```typescript
// types/express.d.ts
import "express";

declare module "express" {
  interface Request {
    user?: { id: string; email: string; role: "admin" | "user" };
    requestId: string;
  }
}
```

### Environment Variables (ProcessEnv)

```typescript
// types/env.d.ts
export {};

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: "development" | "production" | "test";
      DATABASE_URL: string;
      API_KEY: string;
      PORT?: string;
    }
  }
}
```

### CSS Modules with Typed Classes

```typescript
// types/css-modules.d.ts
declare module "*.module.css" {
  const classes: { readonly [key: string]: string };
  export default classes;
}

declare module "*.module.scss" {
  const classes: { readonly [key: string]: string };
  export default classes;
}
```

### Static Asset Imports

```typescript
// types/assets.d.ts
declare module "*.svg" {
  import type { FC, SVGProps } from "react";
  const SVGComponent: FC<SVGProps<SVGSVGElement>>;
  export default SVGComponent;
}

declare module "*.png" {
  const src: string;
  export default src;
}
```

## Declaration Merging

Interfaces with the same name merge automatically:

```typescript
// From library
interface ApiConfig {
  baseUrl: string;
}

// Your extension — merges with above
interface ApiConfig {
  timeoutMs: number;
  retries?: number;
}

// Result: { baseUrl: string; timeoutMs: number; retries?: number }
const config: ApiConfig = {
  baseUrl: "https://api.example.com",
  timeoutMs: 5000,
};
```

**What merges**: interfaces, namespaces, enum + namespace.
**What doesn't merge**: type aliases (`type X = ...` cannot be re-declared).

## Quick Reference

| Pattern | Syntax | Use When |
|---|---|---|
| Triple-slash types | `/// <reference types="node" />` | Including @types in a specific file |
| Triple-slash path | `/// <reference path="./types.d.ts" />` | Including local declarations |
| Ambient module | `declare module "*.css" {}` | Typing non-TS imports (CSS, JSON, images) |
| Untyped package | `declare module "lib" { ... }` | Adding types for a package without `@types` |
| Global augmentation | `declare global { ... }` | Extending Window, Array, ProcessEnv |
| Module augmentation | `declare module "express" { ... }` | Adding fields to third-party module types |
| Declaration merging | Two `interface Foo` blocks | Extending an interface across files |
| export {} guard | `export {};` at top of .d.ts | Ensuring file is treated as a module |
| typeRoots | `"typeRoots": ["./types", ...]` | Custom declaration directories |
| types whitelist | `"types": ["node", "jest"]` | Limiting which @types are included |

## Common Mistakes

**Missing `export {}` in .d.ts (TS2669)** — Without it, declarations pollute the global scope. Always include `export {}` to force module treatment.

**Augmenting instead of declaring (TS2305)** — `declare module "x"` inside a module augments; at top level in a script file it replaces. Make sure the file context matches your intent.

**Conflicting declaration merging (TS2717)** — Two interfaces with the same property name but different types cause errors. Ensure merged declarations are compatible.

**Forgetting to install `@types` (TS7016)** — `Could not find a declaration file for module`. Install `@types/package` or write a local `declare module`.

**Custom typeRoots replacing defaults** — Setting `typeRoots` overrides the default `node_modules/@types`. Always include both: `["./types", "./node_modules/@types"]`.

**Implementation code in .d.ts files** — Declaration files contain ONLY type information. Never include function bodies, variable assignments, or runtime logic.

## When to Avoid

- Avoid global augmentation unless necessary — it slows compilation and affects all files.
- Prefer module augmentation scoped to specific modules.
- Keep `.d.ts` files small and targeted to reduce type conflicts.
- Prefer `@types` packages from DefinitelyTyped over hand-written declarations when available.
