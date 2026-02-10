# pnpm + TypeScript Monorepo Guide

## Workspace Setup

### pnpm-workspace.yaml

Define which directories contain packages. Place this file at the repository root.

```yaml
packages:
  - "packages/*"
  - "apps/*"
```

Every directory matching these globs that contains a `package.json` becomes a workspace package. pnpm links them automatically — no manual `npm link` needed.

### Workspace Protocol

Reference sibling packages in `package.json` using the workspace protocol:

```json
{
  "dependencies": {
    "@myorg/shared-types": "workspace:*",
    "@myorg/utils": "workspace:^1.0.0"
  }
}
```

- `workspace:*` — always resolve to the local package (any version).
- `workspace:^1.0.0` — resolve locally if the version satisfies the range, otherwise error.

When publishing, pnpm replaces `workspace:` with the actual version.

## TypeScript Configuration

### Root tsconfig.json — References Only

The root `tsconfig.json` should contain **only** references, not compiler options. If you put `compilerOptions` here and packages try to extend this file, it creates a circular reference when combined with project references.

```json
{
  "files": [],
  "references": [
    { "path": "packages/shared-types" },
    { "path": "packages/utils" },
    { "path": "apps/web" },
    { "path": "apps/api" }
  ]
}
```

- `"files": []` prevents the root from compiling anything on its own.
- Every package and app must be listed in `references`.

### Shared Compiler Options — tsconfig.base.json

Put shared compiler options in a separate `tsconfig.base.json` at the root. Every package extends this file:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true
  }
}
```

### Per-Package tsconfig.json

Each package extends the base and adds project-reference-specific options:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "composite": true,
    "declaration": true,
    "declarationMap": true,
    "incremental": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"],
  "references": [
    { "path": "../shared-types" }
  ]
}
```

**Required fields for project references:**

| Option | Purpose |
|---|---|
| `composite: true` | Enables project references; implicitly turns on `declaration` and `incremental` |
| `declaration: true` | Emits `.d.ts` files so dependent projects can type-check without reading source |
| `declarationMap: true` | Emits `.d.ts.map` files so "Go to Definition" in editors jumps to source, not `.d.ts` |
| `incremental: true` | Caches build info in `.tsbuildinfo` for faster rebuilds |
| `outDir` | Where compiled JS and declarations land |
| `rootDir` | Root of source files; controls output directory structure |

### Quick Reference: tsconfig Fields by Package Type

| Field | Library Package | App Package |
|---|---|---|
| `composite` | `true` (required) | `true` (required for tsc -b) |
| `declaration` | `true` | Optional (apps rarely consumed by others) |
| `declarationMap` | `true` | Optional |
| `incremental` | `true` | `true` |
| `outDir` | `"dist"` | `"dist"` |
| `rootDir` | `"src"` | `"src"` |
| `references` | List dependency packages | List dependency packages |
| `noEmit` | `false` (must emit) | `true` if bundler handles emit |

**Important:** When an app uses a bundler (Vite, esbuild, webpack), the app's tsconfig can set `noEmit: true` for type-checking only. But library packages consumed via project references **must emit** declarations.

## Building with tsc --build

### tsc -b vs Regular tsc

| Aspect | `tsc` (regular) | `tsc --build` / `tsc -b` |
|---|---|---|
| Scope | Single project | Multi-project graph |
| Incremental | Only if `incremental: true` | Automatic across all referenced projects |
| Build order | N/A | Topologically sorted by `references` |
| Skips unchanged | No | Yes — skips up-to-date projects |
| Reads `.tsbuildinfo` | If present | Always |

### Usage

```bash
# Build everything from root
tsc -b

# Build a specific package and its dependencies
tsc -b packages/utils

# Clean build artifacts
tsc -b --clean

# Force full rebuild
tsc -b --force

# Watch mode
tsc -b --watch
```

`tsc -b` reads the root `tsconfig.json`, resolves the `references` graph, topologically sorts it, and only recompiles packages whose source files changed since the last `.tsbuildinfo` snapshot.

## Shared Types Across Packages

### The shared-types Package Pattern

Create a dedicated package for shared type definitions:

```
packages/shared-types/
  src/
    index.ts        # re-exports all types
    api-types.ts
    domain-types.ts
  tsconfig.json
  package.json
```

`package.json`:

```json
{
  "name": "@myorg/shared-types",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  },
  "scripts": {
    "build": "tsc -b"
  }
}
```

Consumer packages add a reference and a workspace dependency:

```json
// packages/api/tsconfig.json
{
  "references": [{ "path": "../shared-types" }]
}
```

```json
// packages/api/package.json
{
  "dependencies": {
    "@myorg/shared-types": "workspace:*"
  }
}
```

Both the `references` entry (for TypeScript) and the `workspace:*` dependency (for pnpm linking) are needed. Missing either one causes different failures.

## Integration with Turbo and Nx

### Turborepo

Turborepo orchestrates `tsc -b` across packages with caching. In `turbo.json`:

```json
{
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".tsbuildinfo"]
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": [".tsbuildinfo"]
    }
  }
}
```

- `"^build"` means "run build in dependency packages first."
- Cache `dist/**` and `.tsbuildinfo` so unchanged packages are skipped entirely.
- Use `turbo run build` instead of `tsc -b` at the root for parallelism and remote caching.

### Nx

Nx provides similar orchestration with its task graph. For pnpm workspaces, Nx auto-detects packages:

```json
// nx.json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "cache": true,
      "outputs": ["{projectRoot}/dist", "{projectRoot}/.tsbuildinfo"]
    }
  }
}
```

Run `nx run-many -t build` for parallel, cached builds. Nx also provides `nx graph` to visualize the dependency graph — useful for spotting circular references.

## Common Mistakes

### 1. Forgetting references Entries

**Symptom:** Types from a sibling package resolve to `any`, or "Cannot find module" errors appear even though the package is installed.

**Fix:** Add `{ "path": "../sibling-package" }` to the `references` array in the consuming package's `tsconfig.json`. Also ensure the sibling is listed in `pnpm-workspace.yaml` globs and as a `workspace:*` dependency.

### 2. Circular Dependencies

**Symptom:** `error TS6202: Project references may not form a circular graph.`

**Fix:** Refactor shared code into a separate package that both sides depend on. Use `tsc -b` or `nx graph` to visualize and confirm no cycles remain. If packages A and B reference each other, extract the shared interface into package C.

### 3. Wrong Relative Paths in references

**Symptom:** `error TS6053: File not found` or `error TS6306: Referenced project may not disable emit.`

**Fix:** The `path` in a reference must point to the **directory** containing a `tsconfig.json`, or to a specific tsconfig file. Use relative paths from the referencing `tsconfig.json`'s directory:

```json
// packages/api/tsconfig.json — correct
{ "references": [{ "path": "../shared-types" }] }

// NOT this:
{ "references": [{ "path": "../../packages/shared-types" }] }
```

### 4. Not Using tsc -b

**Symptom:** Running plain `tsc` on the root tsconfig produces "error TS18003: No inputs were found" or compiles nothing because `"files": []`.

**Fix:** Always use `tsc -b` (or `tsc --build`) for monorepos with project references. Plain `tsc` does not understand the references graph.

### 5. Putting compilerOptions in Root tsconfig.json

**Symptom:** Packages that extend the root tsconfig and are also referenced by it trigger circular-reference warnings or unexpected option inheritance.

**Fix:** Keep the root `tsconfig.json` as references-only. Put shared compiler options in `tsconfig.base.json` and have packages extend that instead.

### 6. Missing composite: true

**Symptom:** `error TS6306: Referenced project must have setting "composite": true.`

**Fix:** Every package that is listed in any `references` array must set `"composite": true` in its `compilerOptions`.

### 7. Stale Declaration Files

**Symptom:** Types appear correct in source but "Go to Definition" shows outdated `.d.ts` files, or types resolve to previous versions.

**Fix:** Run `tsc -b --clean` then `tsc -b` to regenerate all outputs. Ensure `declarationMap: true` is set so editors map back to source correctly. Add `dist/` and `.tsbuildinfo` to `.gitignore` and rebuild in CI.

## Typical Directory Layout

```
my-monorepo/
  pnpm-workspace.yaml
  tsconfig.json          # references only, files: []
  tsconfig.base.json     # shared compilerOptions
  package.json           # root scripts, devDependencies (typescript, turbo)
  turbo.json             # (if using Turborepo)
  packages/
    shared-types/
      src/index.ts
      tsconfig.json      # extends ../../tsconfig.base.json, composite: true
      package.json
    utils/
      src/index.ts
      tsconfig.json      # references: [../shared-types]
      package.json
  apps/
    web/
      src/index.ts
      tsconfig.json      # references: [../../packages/shared-types, ../../packages/utils]
      package.json
    api/
      src/index.ts
      tsconfig.json
      package.json
```
