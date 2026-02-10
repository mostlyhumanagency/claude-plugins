---
name: coding-typescript-pnpm-monorepo
description: "Use when setting up or configuring a pnpm + TypeScript monorepo — pnpm-workspace.yaml, project references, composite builds, tsc --build, shared types across packages, or integrating with Turborepo/Nx."
---

# Coding TypeScript pnpm Monorepo

## Overview

A pnpm + TypeScript monorepo combines pnpm workspaces for dependency linking with TypeScript project references for incremental type-checking and compilation. pnpm's strict `node_modules` layout prevents phantom dependencies, and project references let `tsc --build` skip unchanged packages.

## References

- `pnpm-monorepo.md`
