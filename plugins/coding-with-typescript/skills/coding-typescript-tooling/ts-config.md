# TypeScript Configuration

Recommended `tsconfig.json` settings for maximum type safety.

## Table of Contents

- [Recommended Configuration](#recommended-configuration)
- [Flag Explanations](#flag-explanations)
- [Common Configurations](#common-configurations)
- [Migration Strategy](#migration-strategy)
- [Troubleshooting](#troubleshooting)
- [Validation](#validation)
- [Resources](#resources)

## Recommended Configuration

```json
{
  "compilerOptions": {
    // Strict Type Checking
    "strict": true,                            // Enable all strict checks
    "noUncheckedIndexedAccess": true,          // Index access returns T | undefined
    "exactOptionalPropertyTypes": true,        // Optional props can't be undefined explicitly

    // Module System
    "module": "node20",                        // Node.js ESM support
    "moduleDetection": "force",                // Treat all files as modules
    "verbatimModuleSyntax": true,              // Enforce import/export syntax
    "isolatedModules": true,                   // Each file can be transpiled independently
    "noUncheckedSideEffectImports": true,      // Warn about imports with side effects

    // Target
    "target": "es2023",                        // Modern JavaScript features

    // Performance
    "skipLibCheck": true,                      // Skip type checking of declaration files

    // Output
    "outDir": "./dist",                        // Output directory
    "rootDir": "./src",                        // Root source directory
    "sourceMap": true,                         // Generate source maps
    "declaration": true,                       // Generate .d.ts files

    // Additional Safety
    "noImplicitReturns": true,                 // Functions must return in all paths
    "noFallthroughCasesInSwitch": true,        // Switch cases must break/return
    "noUnusedLocals": true,                    // Error on unused local variables
    "noUnusedParameters": true,                // Error on unused parameters
    "allowUnusedLabels": false,                // Error on unused labels
    "allowUnreachableCode": false              // Error on unreachable code
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Flag Explanations

### Strict Checks

**`"strict": true`**
- Enables all strict type checking options
- Includes: strictNullChecks, strictFunctionTypes, strictBindCallApply, etc.
- **Why:** Foundation of type safety

**`"noUncheckedIndexedAccess": true`**
```typescript
// Without: array[0] has type T (unsafe)
const first = items[0];  // Type: Item

// With: array[0] has type T | undefined (safe)
const first = items[0];  // Type: Item | undefined
if (first) {
  // Now type-safe
}
```
- **Why:** Array/object access can fail at runtime

**`"exactOptionalPropertyTypes": true`**
```typescript
interface Config {
  timeout?: number;
}

// Without: Both allowed
const config1: Config = { timeout: undefined };
const config2: Config = {};

// With: Only omission allowed
const config1: Config = { timeout: undefined };  // ❌ Error
const config2: Config = {};  // ✅ OK
```
- **Why:** Distinguishes between "not provided" and "explicitly undefined"

### Module System

**`"module": "node20"`**
- Modern Node.js ESM support
- Native import/export
- Top-level await support

**`"moduleDetection": "force"`**
- Treats all files as modules
- No global scope pollution
- Enforces explicit imports/exports

**`"verbatimModuleSyntax": true`**
- Import syntax must match module type
- `import type` for type-only imports
- No mixing of styles

**`"isolatedModules": true`**
- Each file transpiles independently
- Required for tools like Babel, esbuild
- Catches issues early

**`"noUncheckedSideEffectImports": true`**
- Warns about imports that may have side effects
- Forces explicit side-effect imports
- Prevents accidental side effects

### Environment Notes

Match module settings to your runtime:
- **Node ESM**: `"module": "node20"`, `"moduleResolution": "node20"`
- **Bundlers** (Vite, Webpack, esbuild): `"module": "esnext"`, `"moduleResolution": "bundler"`
- **CommonJS**: `"module": "commonjs"`, `"moduleResolution": "node"`

### Target

**`"target": "es2023"`**
- Modern JavaScript features
- Native async/await
- Optional chaining, nullish coalescing
- Top-level await

### Performance

**`"skipLibCheck": true`**
- Skips type checking of .d.ts files
- Faster builds
- Only checks your code
- **Trade-off:** May miss issues in dependencies

### Additional Safety

**`"noImplicitReturns": true`**
```typescript
// ❌ Error: Not all code paths return
function process(x: number): string {
  if (x > 0) {
    return "positive";
  }
  // Missing return for x <= 0
}
```

**`"noFallthroughCasesInSwitch": true`**
```typescript
// ❌ Error: Case falls through
switch (status) {
  case 'idle':
    doIdle();
    // Missing break/return
  case 'loading':
    doLoading();
    break;
}
```

**`"noUnusedLocals": true` / `"noUnusedParameters": true`**
- Catches dead code
- Enforces cleanup
- Improves maintainability

## Quick Reference

| Flag | Effect | Priority |
|---|---|---|
| `strict: true` | Enables all strict type checks | Must-have |
| `noUncheckedIndexedAccess` | Index access returns `T \| undefined` | Must-have |
| `exactOptionalPropertyTypes` | Optional props can't be set to `undefined` | Recommended |
| `verbatimModuleSyntax` | Enforces `import type` for type-only imports | Recommended |
| `isolatedModules` | Each file transpiles independently | Required for esbuild/Babel |
| `skipLibCheck` | Skips .d.ts type checking (faster builds) | Trade-off |
| `noImplicitReturns` | All code paths must return | Safety |
| `noFallthroughCasesInSwitch` | Switch cases must break/return | Safety |
| `module: "node20"` | Modern Node.js ESM support | Match runtime |
| `target: "es2023"` | Modern JS output | Match runtime |

## Common Configurations

### Library/Package

```json
{
  "compilerOptions": {
    "strict": true,
    "declaration": true,             // Generate .d.ts
    "declarationMap": true,          // Source maps for .d.ts
    "outDir": "./dist",
    "rootDir": "./src",
    "module": "node20",
    "target": "es2023",
    "moduleDetection": "force"
  }
}
```

### Application

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "module": "node20",
    "target": "es2023",
    "sourceMap": true
  }
}
```

### Frontend (React)

```json
{
  "compilerOptions": {
    "strict": true,
    "jsx": "react-jsx",               // React 17+ JSX transform
    "module": "esnext",
    "target": "es2023",
    "moduleResolution": "bundler",    // For bundlers like Vite
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

## Migration Strategy

### From Loose to Strict

**Phase 1: Enable basic strict**
```json
{
  "strict": true
}
```
Fix errors incrementally.

**Phase 2: Add indexed access check**
```json
{
  "noUncheckedIndexedAccess": true
}
```
Add null checks for array/object access.

**Phase 3: Enable exact optional properties**
```json
{
  "exactOptionalPropertyTypes": true
}
```
Remove explicit `undefined` assignments.

**Phase 4: Add additional safety**
```json
{
  "noImplicitReturns": true,
  "noFallthroughCasesInSwitch": true,
  "noUnusedLocals": true,
  "noUnusedParameters": true
}
```
Clean up dead code and missing returns.

## Troubleshooting

### "Cannot find module" errors

**Problem:** Module resolution issues

**Fix:**
```json
{
  "moduleResolution": "node20",      // or "bundler" for bundlers
  "baseUrl": "./",
  "paths": {
    "@/*": ["src/*"]
  }
}
```

### "Type 'X' is not assignable" after enabling strict

**Problem:** Strict null checks catching real bugs

**Fix:** Don't disable strict. Fix the bugs:
```typescript
// Before: Unsafe
const value = array[0].name;

// After: Safe
const item = array[0];
if (item) {
  const value = item.name;
}
```

### Slow compilation

**Enable:**
```json
{
  "skipLibCheck": true,
  "incremental": true,
  "tsBuildInfoFile": "./dist/.tsbuildinfo"
}
```

## Validation

Verify your config is working:

```typescript
// Test 1: Should error without null check
const items: string[] = [];
const first = items[0];
first.toUpperCase();  // Should error with noUncheckedIndexedAccess

// Test 2: Should error on unsafe type
const data: unknown = JSON.parse(input);
data.name;  // Should error

// Test 3: Should error on mutation
interface State {
  readonly value: number;
}
const state: State = { value: 1 };
state.value = 2;  // Should error
```

If all three error, your config is working!

## Resources

- [TypeScript Compiler Options](https://www.typescriptlang.org/tsconfig)
- [TSConfig Bases](https://github.com/tsconfig/bases)
- [TypeScript Strict Mode](https://www.typescriptlang.org/tsconfig#strict)
