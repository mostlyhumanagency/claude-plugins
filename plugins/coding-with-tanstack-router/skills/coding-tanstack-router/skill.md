---
name: coding-tanstack-router
description: Use only when a user wants an overview of available TanStack Router skills or when unsure which TanStack Router skill applies. Routes to the correct sub-skill.
---

# TanStack Router Overview

TanStack Router is a fully type-safe router for React (and Solid) with first-class search param support, built-in SWR caching, file-based routing, and automatic code splitting.

## Quick Start

```bash
# Standalone router (no framework)
npx create-tsrouter-app@latest my-app --template file-router

# With TanStack Start (full-stack framework)
pnpm create @tanstack/start@latest
```

## Core Features

- 100% inferred TypeScript — params, search, context, loader data all typed
- File-based route generation with mixed code-based options
- JSON-first search params as first-class state
- Built-in SWR caching with configurable staleTime/gcTime
- Automatic code splitting (critical vs non-critical)
- Route preloading (intent, viewport, render)
- Structural sharing for render optimizations
- Navigation blocking for unsaved changes
- Route masking for modal/overlay patterns
- Document head management (title, meta, scripts)

## Skill Routing

| Task | Skill |
|---|---|
| createRouter, RouterProvider, type registration | `creating-tanstack-router` |
| createFileRoute, path params, wildcards, layouts | `defining-tanstack-router-routes` |
| Loaders, beforeLoad, deferred data, mutations | `loading-tanstack-router-data` |
| Router context, dependency injection | `managing-tanstack-router-context` |
| Code splitting, lazy routes, auto splitting | `splitting-tanstack-router-code` |
| HeadContent, Scripts, meta tags, title | `managing-tanstack-router-head` |
| useBlocker, confirmation dialogs | `blocking-tanstack-router-navigation` |
| Route masking, createRouteMask | `masking-tanstack-router-routes` |
| Scroll restoration, preloading, render perf | `optimizing-tanstack-router` |

## Related Plugins

For TanStack Start (full-stack framework built on this router), see the `coding-with-tanstack-start` plugin which covers server functions, middleware, SSR, authentication, and deployment.
