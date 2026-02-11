---
name: coding-typescript-linting-with-oxlint
description: "Use when setting up oxlint for a TypeScript project, configuring oxlintrc.json, enabling type-aware linting with tsgolint, running oxlint alongside ESLint, adding oxlint to CI, choosing lint rule categories, or migrating from ESLint to oxlint for faster linting."
---

# Coding TypeScript Linting with oxlint

## Overview

oxlint is a Rust-based JavaScript/TypeScript linter from the OXC project (backed by VoidZero). It reached v1.0 stable in June 2025 and is 50-100x faster than ESLint. oxlint ships 660+ built-in rules, supports type-aware linting via tsgolint (powered by TypeScript 7 / tsgo), and requires zero configuration to start. It is used in production by Shopify, Airbnb, and Mercedes-Benz.

## References

- `references/oxlint-setup.md`
- `references/oxlint-type-aware.md`
