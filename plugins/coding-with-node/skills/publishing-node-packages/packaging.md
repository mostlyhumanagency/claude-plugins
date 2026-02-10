# Node Packaging (v24)

## Publishing Basics

- Define `"exports"` to control the public surface.
- Provide `"types"` for TypeScript consumers.
- Document supported Node versions and runtime requirements.

## Entry Points

- Prefer `"exports"` over `"main"` for modern packages.
- Use conditional exports for `import` and `require`.
- Keep a single stable entry point for the main API.
- Add subpath exports only when they are part of your public API.

## Node-API (N-API)

- Use Node-API for native addons to keep ABI stability across Node versions.
- Document the minimum Node version required by the addon.

## Versioning

- Use semver and clearly document breaking changes.
- Avoid breaking public exports without a major version bump.

## Quick Reference

| Concern | Field / Tool | Notes |
|---|---|---|
| Entry point | `"exports": { ".": "./dist/index.js" }` | Prefer `exports` over `main` |
| Dual ESM/CJS | `"import"` + `"require"` conditions | Conditional exports for both module systems |
| TypeScript types | `"types": "./dist/index.d.ts"` | Always ship .d.ts for TS consumers |
| Subpath exports | `"./feature": "./dist/feature.js"` | Only for intentional public sub-APIs |
| Native addons | Node-API (N-API) | ABI-stable across Node versions |
| Dry run | `npm pack && npm install ./pkg.tgz` | Validate package contents before publishing |
| Semver | Major for breaking, minor for features | Document breaking changes in CHANGELOG |
| files field | `"files": ["dist"]` | Control what gets published to npm |

## Common Mistakes

**Using `main` instead of `exports`** — `main` only provides a single entry point and doesn't restrict deep imports. Use `exports` for modern packages.

**Missing `"types"` field** — TypeScript consumers can't find type declarations. Always include `"types"` pointing to your `.d.ts` entry.

**Publishing without `npm pack` test** — Files may be missing from the tarball. Always `npm pack` and inspect or install the tarball before publishing.

**Breaking deep imports without major version bump** — Consumers relying on internal paths will break. Use `exports` to prevent deep imports from the start.

## Constraints and Edges

- Do not expose internal paths via deep imports.
- Native addons must declare minimum supported Node versions.
- Validate install in a clean project to catch missing files.

## Do / Don't

- Do keep public APIs small and stable.
- Do publish TypeScript declarations for libraries.
- Don't expose internal modules via deep imports.
- Don't ship native addons without a compatibility statement.

## Examples

### Minimal exports and types

```json
{
  "name": "my-lib",
  "exports": {
    ".": "./dist/index.js"
  },
  "types": "./dist/index.d.ts"
}
```

### Dual ESM/CJS exports

```json
{
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "default": "./dist/index.js"
    }
  }
}
```

## Verification

- Test `import` and `require` entry points.
- Install the package in a clean project and run a minimal example.
