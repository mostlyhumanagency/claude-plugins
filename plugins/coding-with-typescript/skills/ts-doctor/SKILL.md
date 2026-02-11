---
name: ts-doctor
description: "Use when reviewing or auditing tsconfig.json, diagnosing confusing TypeScript compiler behavior, fixing misconfigured tsconfig options, validating tsconfig against framework best practices (Next.js, Vite, Angular, Node.js), debugging unexpected module resolution, or when the user asks to review, audit, or fix their TypeScript configuration."
---

# TypeScript Configuration Doctor

## Overview

This skill audits a project's `tsconfig.json` against best practices specific to the detected framework and runtime. It reads the full configuration (resolving `extends` chains), identifies the project type (Next.js, Vite, Node.js, Angular, etc.), and checks each compiler option against known recommendations. The goal is to catch misconfigurations that cause confusing errors, slow builds, or incorrect output before they become debugging nightmares.

TypeScript configuration is one of the most common sources of developer confusion. Options interact in non-obvious ways, frameworks have specific requirements, and defaults change between TypeScript versions. This skill acts as an automated reviewer that catches issues a developer might spend hours debugging.

## When to Use

Use this skill when:

- The user asks to "review tsconfig", "audit my config", "fix tsconfig", or "check my TypeScript setup"
- The user reports confusing compiler behavior that does not match expectations
- Module resolution is failing unexpectedly (TS2307: Cannot find module)
- The user is setting up a new TypeScript project and wants to start with correct configuration
- The user is upgrading TypeScript versions and wants to verify their config is still optimal
- Build output is appearing in unexpected locations or with unexpected formats
- Path aliases are not resolving correctly

Do not use this skill for type-checking errors in source code (use ts-check) or for strict mode migration (use ts-strict).

## Process

Follow these steps to audit a TypeScript configuration:

1. **Read the full config chain.** Start with the project's `tsconfig.json`. If it uses `extends`, recursively read each base config. Build the effective (merged) configuration with all inherited options resolved. Note which options come from which config file in the chain.

2. **Detect the framework.** Read `package.json` and check dependencies for framework markers:
   - `next` -> Next.js
   - `vite` or `@vitejs/*` -> Vite
   - `@angular/core` -> Angular
   - `nuxt` -> Nuxt
   - `@sveltejs/kit` -> SvelteKit
   - None of the above with `@types/node` -> Plain Node.js
   - None of the above -> Browser/vanilla TypeScript

3. **Check module and moduleResolution pairing.** These two options must be compatible:
   - Node.js ESM projects: `"module": "node16"` or `"nodenext"` with matching `moduleResolution`
   - Bundler projects (Vite, webpack, etc.): `"module": "esnext"` with `"moduleResolution": "bundler"`
   - Legacy Node.js: `"module": "commonjs"` with `"moduleResolution": "node"`
   - Flag any mismatch as an error

4. **Validate target.** Check that `target` is appropriate for the runtime:
   - Node 18+: `"target": "es2022"` or later
   - Node 20+: `"target": "es2023"` or later
   - Modern browsers: `"target": "es2020"` minimum
   - Flag outdated targets like `"es5"` unless the project explicitly needs legacy support

5. **Check framework-specific requirements.** Each framework has known requirements:
   - **Next.js**: needs `"jsx": "preserve"`, `"moduleResolution": "bundler"`, `"isolatedModules": true`, `"incremental": true`
   - **Vite**: needs `"moduleResolution": "bundler"`, `"isolatedModules": true`
   - **Angular**: needs `"experimentalDecorators": true`, `"emitDecoratorMetadata": true` (pre-v17)
   - **Node.js**: `"module"` and `"moduleResolution"` should match the `"type"` field in package.json

6. **Audit general best practices.** Check for:
   - `"skipLibCheck": true` recommended for build performance in most projects
   - `"esModuleInterop": true` for CJS/ESM interop unless using `"module": "nodenext"`
   - `"resolveJsonModule": true` if JSON imports are used
   - `"outDir"` should not point inside `"rootDir"` or `"src"`
   - `"include"` and `"exclude"` patterns: ensure source files are covered and `node_modules` is excluded
   - `"paths"` aliases must have corresponding bundler or runtime configuration
   - Deprecated options: `"keyofStringsOnly"`, `"suppressImplicitAnyIndexErrors"`, etc.
   - No-op options for the current TS version

7. **Report findings.** Present each finding with:
   - Severity: Error (will cause problems), Warning (may cause problems), Info (suboptimal but functional)
   - The option name and current value
   - The recommended value and why
   - Which config file in the chain sets the value

8. **Generate a corrected config.** If changes are recommended, output a corrected `tsconfig.json` or a diff showing only the changed options.

## Quick Reference

| Scenario | Action |
|---|---|
| User says "review my tsconfig" | Run full audit against detected framework |
| Module resolution errors (TS2307) | Check `module`, `moduleResolution`, `paths`, `baseUrl` |
| "jsx" errors in React/Next.js | Verify `jsx` is set to `"preserve"` (Next.js) or `"react-jsx"` (Vite/CRA) |
| Output files in wrong location | Check `outDir`, `rootDir`, `declarationDir` |
| Path aliases not working | Verify `paths` has corresponding bundler config and `baseUrl` is set |
| Slow type checking | Suggest `skipLibCheck`, `incremental`, project references |
| Upgrading TypeScript | Check for deprecated options and new recommended defaults |

## Common Mistakes

- **Not resolving the `extends` chain.** Many issues hide in base configs. A project extending `@tsconfig/node20` inherits specific `module` and `target` settings. If the local config overrides only some of them, the result may be inconsistent. Always resolve the full chain.

- **Recommending `"moduleResolution": "bundler"` for Node.js projects.** The `bundler` module resolution is only valid when a bundler (Vite, webpack, esbuild) processes the code. Pure Node.js projects should use `"node16"` or `"nodenext"` to match Node's actual resolution algorithm.

- **Ignoring the `"type"` field in package.json.** In Node.js projects, `"type": "module"` or `"type": "commonjs"` in package.json determines the default module system. The tsconfig `module` option must align with it, or the emitted code will not run correctly.

- **Assuming `"strict": true` is always correct.** While strict mode is generally recommended, some projects (especially those migrating from JavaScript) intentionally use non-strict settings. The doctor should flag the absence of strict mode as an informational finding, not an error.

- **Overlooking `isolatedModules`.** Projects that use bundlers, SWC, or esbuild for transpilation (rather than tsc) require `"isolatedModules": true` because these tools transpile files individually. Without it, code that relies on cross-file type information (like `const enum` re-exports) will break at build time.
