---
name: coding-typescript-monorepo
description: "Use when setting up a TypeScript monorepo, configuring project references, sharing types across packages, fixing cross-package import issues, or choosing a monorepo tool (pnpm workspaces, Turborepo, Nx). Routes to the specific monorepo skill based on the tooling."
---

# Coding TypeScript Monorepo (Router)

## Overview

Route to the most specific monorepo skill based on the user's tooling. If the user has not specified a tool, default to pnpm.

## Skill Map

| Trigger | Skill |
|---|---|
| pnpm workspaces, pnpm-workspace.yaml, pnpm monorepo | `coding-typescript-pnpm-monorepo` |
| Generic "TypeScript monorepo", project references, composite builds, tsc --build | `coding-typescript-pnpm-monorepo` (default) |

## Scope

Only pnpm-based monorepos are covered. Other monorepo package managers (Lerna, Rush, Yarn workspaces) are out of scope for this skill tree.

## Default

If the tooling is ambiguous or unspecified, use `coding-typescript-pnpm-monorepo`.
