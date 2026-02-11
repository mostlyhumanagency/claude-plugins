---
name: coding-typescript-pnpm-monorepo
description: "Use when setting up a pnpm workspace with TypeScript, configuring pnpm-workspace.yaml, adding TypeScript project references and composite builds, running tsc --build across packages, sharing types between packages, fixing cross-package import errors, or integrating pnpm monorepo with Turborepo or Nx."
---

# Coding TypeScript pnpm Monorepo

## Overview

A pnpm + TypeScript monorepo combines pnpm workspaces for dependency linking with TypeScript project references for incremental type-checking and compilation. pnpm's strict `node_modules` layout prevents phantom dependencies, and project references let `tsc --build` skip unchanged packages.

## References

- `pnpm-monorepo.md`
