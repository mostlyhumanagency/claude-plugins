---
name: coding-typescript-linting
description: "This skill should be used when the user asks about 'TypeScript linting', 'lint setup', 'code quality rules', or linter configuration and it is unclear which specific linter applies. Routes to the most specific linting skill."
---

# Coding TypeScript Linting (Router)

## Overview

Route to the most specific linting skill based on the user's tooling and context. If the user has not specified a linter, default to ESLint.

## Skill Map

| Trigger | Skill |
|---|---|
| eslint, typescript-eslint, flat config, eslint.config, type-checked rules, .eslintrc | `coding-typescript-linting-with-eslint` |
| oxlint, oxc, fast linting, Rust linter, tsgolint, oxlintrc | `coding-typescript-linting-with-oxlint` |
| Generic "TypeScript linting", lint setup, code quality rules, linter config | `coding-typescript-linting-with-eslint` (default) |

## Scope

Only ESLint (with typescript-eslint) and oxlint are covered. Other linters (TSLint, Biome's linting, deno lint) are out of scope for this skill tree.

## Default

If the tooling is ambiguous or unspecified, use `coding-typescript-linting-with-eslint`.
