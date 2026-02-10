# Node Modules (v24)

## ESM vs CommonJS

- ESM uses `import` and `export` with `"type": "module"` or `.mjs` files.
- CommonJS uses `require` and `module.exports` with `"type": "commonjs"` or `.cjs` files.
- In ESM, file extensions are mandatory in `import` specifiers.

## Module System Rules

- `.mjs` is always ESM; `.cjs` is always CommonJS.
- `.js` and `.ts` follow the nearest `package.json` `type` field.
- For `--eval` or stdin, use `--input-type=module` or `--input-type=commonjs`.

## Package Boundaries

- Use `"exports"` to define public entry points.
- Keep internal files private and avoid deep imports in docs and examples.

## Dynamic Loading

- Use `import()` for conditional or lazy loading in ESM.
- From CommonJS, use dynamic `import()` to load ESM.

## Quick Reference

| Rule | Applies To | Notes |
|---|---|---|
| `"type": "module"` | package.json | Makes `.js` files ESM by default |
| `"type": "commonjs"` | package.json | Makes `.js` files CJS by default (Node default) |
| `.mjs` always ESM | File extension | Overrides package.json `type` |
| `.cjs` always CJS | File extension | Overrides package.json `type` |
| `"exports"` field | package.json | Defines public entry points, hides internals |
| `import()` from CJS | Dynamic import | Only way to load ESM from CommonJS |
| `--input-type` | CLI flag | Sets module type for `--eval` and stdin |
| File extensions required | ESM imports | `import './mod.js'` not `import './mod'` |

## Common Mistakes

**Missing file extension in ESM imports (ERR_MODULE_NOT_FOUND)** — ESM requires explicit `.js`/`.mjs` extensions. Node does not resolve extensionless imports in ESM.

**Mixing `require` and `import` in the same file** — CJS files cannot use static `import`. Use dynamic `import()` to load ESM from CJS.

**Forgetting `"type": "module"` in package.json** — Without it, `.js` files default to CommonJS. Top-level `await` and `import` syntax won't work.

**Exposing internals without `"exports"` (ERR_PACKAGE_PATH_NOT_EXPORTED)** — Without an `exports` field, all files are importable. Use `exports` to control the public API.

## Constraints and Edges

- ESM requires explicit file extensions in specifiers.
- Avoid deep imports across package boundaries; prefer `exports`.
- Mixing ESM and CJS in a single package increases interop friction.

## Do / Don't

- Do choose one module system per package when possible.
- Do provide stable entry points through `exports`.
- Don't rely on deep imports from other packages.
- Don't mix ESM and CJS without explicit boundaries.

## Examples

### ESM package.json

```json
{
  "name": "my-lib",
  "type": "module",
  "exports": {
    ".": "./dist/index.js",
    "./feature": "./dist/feature.js"
  }
}
```

### CommonJS package.json

```json
{
  "name": "my-lib",
  "type": "commonjs",
  "main": "./dist/index.cjs"
}
```

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

### Dynamic import in CJS

```js
const mod = await import('./feature.js');
mod.run();
```

## Verification

- Run `node -p "import('pkg')"` for ESM entry points.
- Run `node -p "require('pkg')"` for CommonJS entry points.
