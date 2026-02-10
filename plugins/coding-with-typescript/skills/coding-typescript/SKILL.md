---
name: coding-typescript
description: Use only when a user wants an overview of available TypeScript skills or when unsure which TypeScript subskill applies. This skill routes to the most specific TypeScript skill.
---

# Coding TypeScript (Dispatcher)

## Overview

Pick the most specific TypeScript skill and use it. Do not load broad references unless no specific skill fits.

## Skill Map

- `coding-typescript-core` for general TS rules, type system, immutability, modules
- `coding-typescript-generics` for type parameters, constraints, defaults, and inference
- `coding-typescript-async` for async/await, Promises, concurrency, cancellation
- `coding-typescript-validation` for runtime validation, Zod, type guards
- `coding-typescript-functional` for functional programming patterns
- `coding-typescript-classes` for class-based design and encapsulation
- `coding-typescript-protocol` for protocol-oriented composition
- `coding-typescript-tooling` for tsconfig, TS version features, testing
- `coding-typescript-narrowing` for type guards, control-flow narrowing, discriminated unions
- `coding-typescript-type-operators` for keyof/typeof/indexed access/conditional/mapped/template literal types
- `coding-typescript-declarations` for `.d.ts`, ambient modules, module augmentation
- `coding-typescript-monorepo` for TypeScript monorepo routing (project references, composite builds)
- `coding-typescript-pnpm-monorepo` for pnpm workspaces + TS project references
- `coding-typescript-linting` for linting routing (ESLint vs oxlint)
- `coding-typescript-linting-with-eslint` for ESLint flat config, typescript-eslint
- `coding-typescript-linting-with-oxlint` for oxlint setup, type-aware rules
- `coding-typescript-performance` for compilation speed, type-level perf, bundle size
- `running-typescript-in-node` for type stripping, ts runners (tsx), .mts/.cts module rules, runtime import issues

## Command-Skills

- `ts-check` — run `tsc --noEmit` and parse diagnostics
- `ts-strict` — analyze strict flags individually
- `ts-doctor` — audit tsconfig against best practices
- `ts-json-to-types` — convert JSON to TypeScript interfaces
- `ts-declare` — generate `.d.ts` stubs for untyped modules
