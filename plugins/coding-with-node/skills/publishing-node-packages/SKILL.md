---
name: publishing-node-packages
description: Use when publishing a package to npm, setting up package.json exports and typings, creating a dual ESM/CJS library, building native addons with Node-API, versioning releases, or fixing issues consumers report after install — covers exports map, types entry points, prepublish scripts, provenance, Node-API/NAPI, and semver strategy. Triggers on ERR_PACKAGE_PATH_NOT_EXPORTED, missing types, broken imports after upgrade.
---

# Publishing Node Packages

## Overview

Package Node libraries cleanly with explicit exports and stable APIs.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Publishing a library to npm.
- Designing `exports` and `types` entry points.
- Shipping native addons with Node-API.
- Versioning and release planning.

## When Not to Use

 - You only need module system guidance; use `managing-node-modules`.
- You are publishing non-Node artifacts (use appropriate tooling).
- You are debugging runtime import behavior in apps.

## Quick Reference

- Prefer `exports` over `main` for entry points.
- Use conditional exports for `import` and `require`.
- Use Node-API for ABI stability in native addons.
- Document supported Node versions.

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
      "require": "./dist/index.cjs"
    }
  }
}
```

### Document supported Node versions

```md
## Supported Node versions

- Node 20+
```

### Clean install validation

```bash
npm pack
npm install ./my-lib-1.0.0.tgz
```

## Common Errors

| Code / Issue | Message Fragment | Fix |
|---|---|---|
| ERR_PACKAGE_PATH_NOT_EXPORTED | Package subpath not defined by "exports" | Add missing subpath to `exports` in package.json |
| ERR_MODULE_NOT_FOUND | Cannot find module (after install) | Check `files` field includes dist/ and exports are correct |
| TS7016 | Could not find a declaration file | Add `"types"` field pointing to .d.ts entry |
| ERR_REQUIRE_ESM | require() of ES Module not supported | Add `"require"` condition to conditional exports |
| ERESOLVE | Could not resolve dependency | Check `engines` field and peerDependencies ranges |

## References

- `packaging.md`
