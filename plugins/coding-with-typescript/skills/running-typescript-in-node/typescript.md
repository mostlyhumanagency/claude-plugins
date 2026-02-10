# TypeScript in Node.js (v24)

## Runtime Options

- For full TypeScript support (tsconfig, transforms, type-checking), use a third-party runner such as `tsx`.
- For lightweight support, use Node's built-in type stripping.

## Built-in Type Stripping

- Type stripping is enabled by default and removes erasable TypeScript syntax only.
- Disable type stripping with `--no-experimental-strip-types`.

## Constraints

- Node ignores `tsconfig.json` at runtime. Paths, downleveling, and other compiler transforms are not applied.
- TypeScript files under `node_modules` are not executed by Node.
- `.tsx` files are unsupported.
- `tsconfig` paths are not applied at runtime.

## Constraints and Edges

- Features that emit runtime code (`enum`, `namespace`, parameter properties) require transpilation.
- Use a TS build step when you need downleveling or path mapping.
- Keep `.d.ts` emission for published packages.

## Module System Rules

- `.ts` files follow the same module system rules as `.js`.
- `.mts` files are always ESM; `.cts` files are always CommonJS.
- File extensions are mandatory in `import` and `require` specifiers.
- Use `import type` for type-only imports to avoid runtime errors.

## REPL and Input

- Type stripping works for `--eval` and STDIN.
- Module system for `--eval` and STDIN is controlled by `--input-type`.
- TypeScript syntax is unsupported in the REPL, `--check`, and `inspect`.

## Recommended tsconfig for Type Stripping

```json
{
  "compilerOptions": {
    "noEmit": true,
    "target": "esnext",
    "module": "nodenext",
    "rewriteRelativeImportExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true
  }
}
```

## Do / Don't

- Do use `import type` with `verbatimModuleSyntax` to avoid runtime errors.
- Do transpile for production if you need full TypeScript syntax support.
- Don't expect `tsconfig` paths to resolve at runtime.
- Don't publish `.ts` sources to `node_modules` expecting Node to run them.

## Examples

### Run TS with type stripping

```bash
node app.ts
```

### Enable transforms for enums

```bash
node --experimental-transform-types app.ts
```

### Use type-only imports

```ts
import type { Config } from './config.ts';
import { loadConfig } from './config.ts';
```

### Full TS support via runner

```bash
npx tsx src/index.ts
```

## Quick Reference

| Scenario | Command / Config | Notes |
|---|---|---|
| Run TS directly | `node app.ts` | Type stripping only (no transforms) |
| Enable transforms | `node --experimental-transform-types app.ts` | Needed for enums/namespaces |
| Full TS support | `npx tsx src/index.ts` | Uses third-party runner |
| Type-only import | `import type { T } from './mod.ts'` | Avoids runtime errors with type stripping |
| ESM file | `.mts` extension | Always treated as ESM |
| CJS file | `.cts` extension | Always treated as CommonJS |
| Emit declarations | `"declaration": true` in tsconfig | Required for published packages |

## Common Mistakes

**Expecting tsconfig paths at runtime (TS2307)** — Node ignores `tsconfig.json` path mappings. Use explicit relative imports or a bundler.

**Using enums without transform flag** — Enums emit runtime code that type stripping can't handle. Use `--experimental-transform-types` or string literal unions instead.

**Missing file extension in imports (ERR_MODULE_NOT_FOUND)** — Node ESM requires explicit `.ts`/`.mts` extensions in import specifiers.

**Publishing .ts to node_modules** — Node does not execute TypeScript files under `node_modules`. Always compile to `.js` + `.d.ts` before publishing.

## Verification

- Ensure `.ts` entry points run without runtime errors.
- Confirm type-only imports are stripped and do not emit value imports.
