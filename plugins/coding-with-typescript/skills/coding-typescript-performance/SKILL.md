---
name: coding-typescript-performance
description: Use when TypeScript compilation is slow, tsc takes too long, builds need to be faster, or the type checker runs out of memory. Also use when choosing between tsc, swc, and esbuild for transpilation, enabling incremental builds, tuning tsconfig for performance, simplifying expensive type-level patterns, or when you see TS2589 (excessively deep type instantiation) or out-of-memory errors during compilation.
---

# Coding TypeScript Performance

## Overview

TypeScript compilation performance depends on three factors: compiler configuration, type-level complexity, and tooling choices. This skill covers all three, from quick tsconfig wins to architectural decisions about your build pipeline.

## Build Performance

### Incremental Compilation

The single biggest build-speed improvement. TypeScript caches type information between compilations and only rechecks changed files.

```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo"
  }
}
```

- First build: normal speed. Subsequent builds: dramatically faster.
- The `.tsbuildinfo` file stores dependency graphs and type signatures. Add it to `.gitignore`.
- For monorepos using project references, use `"composite": true` instead (implies `incremental`).

### skipLibCheck

Skips type-checking `.d.ts` files from `node_modules` and your own declaration files.

```json
{
  "compilerOptions": {
    "skipLibCheck": true
  }
}
```

- Safe for virtually all projects. You still get type checking for your own source code.
- Can reduce check time by 30-50% on dependency-heavy projects.
- Only skip this if you are authoring `.d.ts` files that must be validated.

### isolatedModules

Forces each file to be transpilable independently, without cross-file type information.

```json
{
  "compilerOptions": {
    "isolatedModules": true
  }
}
```

- Required for alternative transpilers (swc, esbuild, Babel).
- Catches patterns that break file-by-file transpilation: `const enum` across files, re-exporting types without `export type`.
- No performance cost. Enables faster tooling options.

### Project References (Monorepo)

Split a large codebase into smaller TypeScript projects that build independently.

```json
// tsconfig.json (root)
{
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/api" }
  ]
}
```

```json
// packages/core/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "outDir": "./dist",
    "declarationMap": true
  }
}
```

- Build with `tsc --build` (or `tsc -b`). Only rebuilds changed projects.
- Each project must set `"composite": true`.
- `declarationMap` enables "go to definition" to jump to source, not `.d.ts`.

## Type-Level Performance

Complex types are the most common cause of slow TypeScript compilation. The compiler has internal limits: 50 levels of type instantiation depth and 100,000 type instantiation count by default.

### Avoiding Deep Instantiation

Recursive conditional types are powerful but expensive.

```typescript
// SLOW: deeply recursive type
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};

// FAST: limit recursion depth with a counter
type DeepReadonly<T, Depth extends number[] = []> =
  Depth['length'] extends 5 ? T :
  T extends object ? {
    readonly [K in keyof T]: DeepReadonly<T[K], [...Depth, 0]>;
  } : T;
```

Rules:
- Cap recursive types at a reasonable depth (3-5 levels).
- Prefer built-in utility types (`Readonly`, `Partial`, `Pick`) over hand-rolled recursive versions.
- If a type takes > 1 second to resolve in your editor, it is too complex.

### Large Union Types

Unions with hundreds of members cause combinatorial explosions during assignability checks.

```typescript
// SLOW: 500-member union checked against every branch
type Route = '/a' | '/b' | '/c' | /* ... 500 more */;

// FAST: use a branded string or generic constraint instead
type Route = string & { __brand: 'Route' };

// ALTERNATIVE: group into sub-unions
type ApiRoutes = '/api/users' | '/api/posts' | '/api/comments';
type PageRoutes = '/home' | '/about' | '/contact';
type Route = ApiRoutes | PageRoutes;
```

### Complex Conditional Types

Each conditional type branch is evaluated independently. Nested conditionals multiply the cost.

```typescript
// SLOW: 4 levels of nesting = 2^4 branches
type Resolve<T> =
  T extends A ? (T extends B ? (T extends C ? (T extends D ? X : Y) : Z) : W) : V;

// FAST: use overloads or a type map instead
interface TypeMap {
  string: StringHandler;
  number: NumberHandler;
  boolean: BooleanHandler;
}
type Resolve<T extends keyof TypeMap> = TypeMap[T];
```

### Mapped Types with Complex Transformations

Every key runs the transformation. Keep per-key logic simple.

```typescript
// SLOW: complex conditional per key
type Transform<T> = {
  [K in keyof T]: T[K] extends Function
    ? ReturnType<T[K] extends (...args: any[]) => any ? T[K] : never>
    : T[K] extends object
    ? Transform<T[K]>
    : T[K];
};

// FAST: split into focused utilities
type FunctionKeys<T> = {
  [K in keyof T]: T[K] extends Function ? K : never;
}[keyof T];
type DataKeys<T> = Exclude<keyof T, FunctionKeys<T>>;
```

### TS2589: Type Instantiation Is Excessively Deep

This error means you hit the compiler's recursion limit. Fixes:
1. Add explicit type annotations to break inference chains.
2. Reduce recursion depth in your types.
3. Use `as` assertions at the boundary where the recursive type is consumed.
4. Consider if you really need the type to be that precise.

## Diagnostic Tools

### --extendedDiagnostics

Shows detailed timing for each compilation phase.

```bash
tsc --noEmit --extendedDiagnostics
```

Output includes:
- Files, lines, and nodes processed
- Check time, emit time, total time
- Memory used
- Types, instantiations, and symbols count

Key numbers to watch:
- **Check time** > 10s: type complexity issue.
- **Instantiations** > 500,000: complex generics or conditional types.
- **Memory** > 2GB: may need to split into project references.

### --generateTrace

Produces a Chrome-compatible trace for profiling type checking.

```bash
tsc --noEmit --generateTrace ./trace-output
```

Open `trace.json` in `chrome://tracing` or [Perfetto](https://ui.perfetto.dev). Shows:
- Which types take the longest to check.
- Where instantiation counts spike.
- Hot paths in the type checker.

### --listFiles

Shows every file the compiler includes.

```bash
tsc --noEmit --listFiles
```

If you see unexpected files (especially from `node_modules`), you have `include`/`exclude` misconfiguration or missing `skipLibCheck`.

### Combining Diagnostics

```bash
# Quick health check
tsc --noEmit --extendedDiagnostics 2>&1 | grep -E 'Check time|Instantiations|Memory'

# Full trace for investigation
tsc --noEmit --generateTrace ./trace && echo "Open trace/trace.json in chrome://tracing"
```

## Alternative Transpilers

### When to Use Alternative Transpilers

TypeScript's `tsc` does two jobs: type checking and transpilation (TS to JS). You can split these:
- **tsc**: type checking only (`--noEmit`)
- **swc / esbuild**: fast transpilation (10-100x faster)

This separation is safe because transpilation only strips types; it does not need type information.

### swc

```bash
npm install -D @swc/cli @swc/core
```

```json
// .swcrc
{
  "jsc": {
    "parser": { "syntax": "typescript", "tsx": true },
    "target": "es2022"
  },
  "module": { "type": "es6" }
}
```

```bash
swc src -d dist          # transpile
tsc --noEmit             # type check separately
```

### esbuild

```bash
npm install -D esbuild
```

```bash
esbuild src/index.ts --outdir=dist --bundle --platform=node --format=esm
tsc --noEmit             # type check separately
```

### Key Constraints

Both swc and esbuild have limitations because they do not resolve types:
- `const enum` is not inlined across files (use regular `enum` or string unions).
- `namespace` merging is not supported.
- `emitDecoratorMetadata` has limited support in swc, none in esbuild.
- `paths` aliases require additional configuration (e.g., `tsconfig-paths` or bundler aliases).

Set `"isolatedModules": true` in your tsconfig to catch code that would break under these transpilers.

## Performance-Impacting tsconfig Settings

### Settings That Slow Compilation

| Setting | Impact | Recommendation |
|---|---|---|
| `declaration: true` | Generates .d.ts for every file | Only enable for libraries |
| `sourceMap: true` | Generates .map files | Disable for type-check-only runs |
| `declarationMap: true` | Maps .d.ts to source | Only with project references |
| Missing `skipLibCheck` | Checks all .d.ts files | Almost always enable |
| Missing `incremental` | Full rebuild every time | Almost always enable |
| `strict: true` (initially) | More checks = slightly slower | Worth it; never disable for speed |

### Settings That Improve Compilation

| Setting | Effect |
|---|---|
| `incremental: true` | Caches between builds, 2-10x faster rebuilds |
| `skipLibCheck: true` | Skips .d.ts checks, 30-50% faster |
| `isolatedModules: true` | Enables alternative transpilers |
| `tsBuildInfoFile` | Controls cache location for incremental |
| `composite: true` | Enables project references for monorepos |
| `disableReferencedProjectLoad` | Lazy-loads referenced projects in editor |

## Quick Reference: Performance Settings

```json
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo",
    "skipLibCheck": true,
    "isolatedModules": true
  }
}
```

Add all four to every project. Zero risk, significant speed improvement.

## Common Mistakes

### 1. Missing incremental

**Symptom:** Every `tsc` run takes the same time, even when nothing changed.
**Fix:** Add `"incremental": true` and `"tsBuildInfoFile"`.

### 2. Not Using skipLibCheck

**Symptom:** Large projects with many dependencies are slow to compile.
**Fix:** Add `"skipLibCheck": true`. You are not responsible for type-checking `node_modules`.

### 3. Overly Complex Generics

**Symptom:** Editor lag, TS2589 errors, `--extendedDiagnostics` shows high instantiation count.
**Fix:** Simplify types. Use explicit annotations. Cap recursion depth. Prefer type maps over nested conditionals.

### 4. Checking Types During Transpilation

**Symptom:** Build pipeline runs `tsc` for both checking and emitting.
**Fix:** Use `tsc --noEmit` for checking, swc/esbuild for transpilation.

### 5. Missing Project References in Monorepo

**Symptom:** Monorepo builds are slow because the entire codebase is one TypeScript project.
**Fix:** Split into projects with `"composite": true` and use `tsc --build`.

### 6. Broad include Patterns

**Symptom:** `--listFiles` shows files outside your source directory.
**Fix:** Narrow `"include"` to only your source, and set proper `"exclude"`.

## Workflow: Diagnosing a Slow Build

1. Run `tsc --noEmit --extendedDiagnostics` to get baseline numbers.
2. Check the easy wins: `incremental`, `skipLibCheck`, `isolatedModules`.
3. If instantiation count is high (>100k), run `--generateTrace` and look for hot types.
4. If file count is high, run `--listFiles` and check your `include`/`exclude`.
5. For monorepos, consider project references with `composite`.
6. For build speed (not checking), evaluate swc or esbuild as the transpiler.
