# coding-with-typescript

A Claude Code plugin for writing safe, modern TypeScript — core patterns, async, generics, narrowing, validation, tooling, and more.

## Skills

| Skill | Description |
|---|---|
| `coding-typescript` | Router — routes to the most specific TypeScript subskill |
| `coding-typescript-core` | Core rules, type system, utility types, modules, immutability, library interop |
| `coding-typescript-async` | Async/await, Promises, concurrency, retries, timeouts, cancellation |
| `coding-typescript-classes` | Classes, inheritance, access modifiers, abstract classes, mixins |
| `coding-typescript-declarations` | Declaration files, ambient modules, global declarations, module augmentation |
| `coding-typescript-design` | Router — routes to functional, classes, or protocol-oriented skills |
| `coding-typescript-functional` | Pure functions, immutability, composition, FP-style error handling |
| `coding-typescript-generics` | Type parameters, constraints, defaults, inference, conditional/mapped types |
| `coding-typescript-linting` | Router — routes to ESLint or oxlint linting skills |
| `coding-typescript-linting-with-eslint` | ESLint flat config, typescript-eslint rules, strict presets |
| `coding-typescript-linting-with-oxlint` | oxlint setup, type-aware rules, ESLint migration |
| `coding-typescript-monorepo` | Router — routes to monorepo-specific skills (pnpm workspaces, etc.) |
| `coding-typescript-narrowing` | Control-flow narrowing, type guards, type predicates, exhaustiveness checks |
| `coding-typescript-performance` | Compilation speed, type-level performance, bundle size, monorepo scaling |
| `coding-typescript-pnpm-monorepo` | pnpm workspaces + TS project references, shared configs |
| `coding-typescript-protocol` | Interface composition, capability-based design, mix-and-match behaviors |
| `coding-typescript-tooling` | tsconfig, TS version features, compiler errors, testing patterns |
| `coding-typescript-type-operators` | keyof, typeof, indexed access, conditional types, mapped types, template literals |
| `coding-typescript-validation` | Runtime data validation, schema validation, type guards, assertion functions |
| `running-typescript-in-node` | Running/publishing TS in Node.js v24, type stripping vs TS runners |
| `ts-check` | Run `tsc --noEmit` and parse diagnostics (also a command) |
| `ts-strict` | Analyze strict flags individually, report error counts per flag (also a command) |
| `ts-doctor` | Audit tsconfig against best practices (also a command) |
| `ts-json-to-types` | Convert JSON samples to TypeScript interfaces (also a command) |
| `ts-declare` | Generate `.d.ts` stubs for untyped modules (also a command) |

## Commands

| Command | Description |
|---|---|
| `/ts-check` | Run `tsc --noEmit` and parse type-check diagnostics |
| `/ts-strict` | Analyze strict compiler flags individually |
| `/ts-doctor` | Audit tsconfig.json against best practices |
| `/ts-json-to-types` | Convert a JSON sample to TypeScript interfaces |
| `/ts-declare` | Generate `.d.ts` declaration stubs for untyped modules |

## Agents

| Agent | Model | Description |
|---|---|---|
| `typescript-expert` | Opus | Full TypeScript specialist — routes to all skills, diagnoses type errors |
| `ts-error-debugger` | Sonnet | Lightweight agent focused on diagnosing TypeScript type errors |

## Scripts

| Script | Description |
|---|---|
| `scripts/check-strict-flags.sh` | Tests 10 strict flags individually, reports error counts per flag |
| `scripts/tsconfig-audit.sh` | Reads tsconfig.json and checks against best practices |

## Templates

| Template | Description |
|---|---|
| `templates/tsconfig-node.json` | Strict tsconfig for Node.js projects |
| `templates/tsconfig-nextjs.json` | tsconfig for Next.js projects |
| `templates/tsconfig-library.json` | tsconfig for publishable library packages |
| `templates/module-augmentation.d.ts` | Module augmentation patterns (Express, Window, ProcessEnv, CSS, assets) |

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/coding-with-typescript
```
