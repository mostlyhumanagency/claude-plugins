# TypeScript Modules

## Table of Contents

- [Import/Export Basics](#importexport-basics)
- [TypeScript 5.9+ Module Features](#typescript-59-module-features)
- [Module Patterns](#module-patterns)
- [Path Mapping](#path-mapping)
- [Side-Effect Imports](#side-effect-imports)
- [Module Augmentation](#module-augmentation)
- [Namespace vs. Modules](#namespace-vs-modules)
- [Anti-Patterns](#anti-patterns)
- [Summary](#summary)

Import/export patterns, module resolution, ES modules (TS 5.9+).

## Import/Export Basics

> **Reminder:** Use named exports (`export function`, `export interface`) over default exports. Use `import type` for type-only imports. Re-export from barrel files sparingly — they can hurt tree-shaking.

## TypeScript 5.9+ Module Features

### `import defer` (5.9+)

Lazy module evaluation:

```typescript
import defer * as HeavyParser from "./heavy-parser";
import defer * as Analytics from "./analytics";

export function process(data: Data) {
  if (needsParsing(data)) {
    // Module loads only when accessed
    return HeavyParser.parse(data);
  }
}

// Analytics loaded only when actually used
export function trackEvent(name: string) {
  Analytics.track(name);
}
```

### Module Resolution

#### `--module node20` (5.9+)

```json
{
  "compilerOptions": {
    "module": "node20",
    "moduleResolution": "node20",
    "target": "es2023"
  }
}
```

#### Import with type modifier

```typescript
// Import only for types (erased at runtime)
import type { User } from "./user";

// Import value and type separately
import { type User, createUser } from "./user";
```

### JSON Imports (5.7+)

```typescript
// ❌ Error without attributes
import config from "./config.json";

// ✅ Correct (TS 5.7+)
import config from "./config.json" with { type: "json" };

// Type is inferred from JSON
config.apiUrl; // string
```

### `verbatimModuleSyntax` (Recommended)

```json
{
  "compilerOptions": {
    "verbatimModuleSyntax": true
  }
}
```

Forces explicit `import type`:

```typescript
// ❌ Error with verbatimModuleSyntax
import { User } from "./user"; // used only as type

// ✅ Correct
import type { User } from "./user";
import { createUser } from "./user";
```

## Module Patterns

### Barrel Files

```typescript
// api/index.ts
export * from "./users";
export * from "./posts";
export * from "./comments";

// Import
import { getUser, getPost, getComment } from "./api";
```

**Warning**: Barrel files can hurt tree-shaking. Use sparingly.

### Facade Pattern

```typescript
// database/index.ts
import { PostgresConnection } from "./postgres";
import { MongoConnection } from "./mongo";

export function createConnection(type: "postgres" | "mongo") {
  return type === "postgres"
    ? new PostgresConnection()
    : new MongoConnection();
}

// Users only import from facade
import { createConnection } from "./database";
```

### Lazy Loading

```typescript
// Heavy module loaded on demand
async function loadHeavyFeature() {
  const module = await import("./heavy-feature");
  return module.default;
}

// Usage
button.onclick = async () => {
  const Feature = await loadHeavyFeature();
  new Feature().run();
};
```

## Path Mapping

### `paths` in tsconfig.json

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@utils/*": ["src/utils/*"]
    }
  }
}
```

```typescript
// Instead of: import { Button } from "../../../../components/Button";
import { Button } from "@components/Button";
import { formatDate } from "@utils/date";
```

## Side-Effect Imports

### `noUncheckedSideEffectImports` (5.6+)

```json
{
  "compilerOptions": {
    "noUncheckedSideEffectImports": true
  }
}
```

```typescript
// ❌ Error: module not found
import "./non-existent-polyfill";

// For ambient module declarations, use the `coding-typescript-declarations` skill.
```

### Side Effects

```typescript
// polyfills.ts
import "core-js/stable";
import "regenerator-runtime/runtime";

// main.ts
import "./polyfills"; // Run side effects
import { app } from "./app";
```

## Module Augmentation

For global declarations, ambient modules, and module augmentation, use the `coding-typescript-declarations` skill.

## Namespace vs. Modules

```typescript
// ❌ Old-style namespace (avoid)
namespace Utils {
  export function format(s: string): string {
    return s.toUpperCase();
  }
}

// ✅ Modern module
export function format(s: string): string {
  return s.toUpperCase();
}
```

## Anti-Patterns

### ❌ Circular Dependencies

```typescript
// a.ts
import { b } from "./b";
export const a = b + 1;

// b.ts
import { a } from "./a"; // ❌ circular
export const b = a + 1;

// GOOD: extract shared code
// shared.ts
export const base = 1;

// a.ts
import { base } from "./shared";
export const a = base + 1;

// b.ts
import { base } from "./shared";
export const b = base + 2;
```

### ❌ Deep Barrel Imports

```typescript
// ❌ Imports entire barrel
import { oneFunction } from "@/utils"; // loads all utils

// ✅ Direct import
import { oneFunction } from "@/utils/one-function";
```

### ❌ Mixing Default and Named Exports

```typescript
// ❌ Confusing
export default class User { }
export const DEFAULT_USER = new User();

// ✅ Consistent - all named
export class User { }
export const DEFAULT_USER = new User();
```

## Summary

- Prefer named exports over default
- Use `import type` for type-only imports
- Enable `verbatimModuleSyntax` for clarity
- Use `import defer` for heavy modules (5.9+)
- Validate JSON imports with `with { type: "json" }` (5.7+)
- Avoid circular dependencies
- Use path mapping for clean imports
