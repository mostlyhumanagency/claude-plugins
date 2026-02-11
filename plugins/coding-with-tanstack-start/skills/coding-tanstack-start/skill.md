---
name: coding-tanstack-start
description: Use only when a user wants an overview of available TanStack Start skills or when unsure which TanStack Start skill applies. Routes to the correct sub-skill.
---

# TanStack Start Overview

TanStack Start is a full-stack React framework powered by TanStack Router and Vite. It provides full-document SSR, streaming, server functions, bundling, and universal deployment. Currently in Release Candidate status.

## Quick Start

```bash
pnpm create @tanstack/start@latest
```

Or from scratch:
```bash
npm init -y
npm install @tanstack/react-start @tanstack/react-router react react-dom
npm install -D vite @vitejs/plugin-react typescript
```

Project structure: `src/routes/` for pages, `src/router.tsx` for config, `vite.config.ts` for build.

## CLI

- `npm run dev` — start dev server (port 3000)
- `npm run build` — production build via Vite

## Configuration

Use `vite.config.ts` with `tanstackStart()` plugin from `@tanstack/react-start/plugin/vite`.

## Key Features

- Full-document SSR with streaming
- Type-safe file-based routing via TanStack Router
- Server functions with `createServerFn`
- Composable middleware system
- Selective SSR, SPA mode, static prerendering
- Built-in SWR caching for route data
- End-to-end type safety

## Skill Routing

| Task | Skill |
|---|---|
| Project setup, config, dependencies | `setting-up-tanstack-start` |
| File routing, layouts, dynamic routes | `routing-tanstack-start` |
| Link, useNavigate, search params | `navigating-tanstack-start` |
| Route loaders, beforeLoad, caching | `loading-data-tanstack-start` |
| createServerFn, validation, RPC | `using-server-functions` |
| createMiddleware, auth middleware | `using-tanstack-start-middleware` |
| SSR, SPA mode, static prerendering | `rendering-tanstack-start` |
| Error boundaries, hydration errors | `handling-errors-tanstack-start` |
| API routes, HTTP handlers | `using-tanstack-start-server-routes` |
| Env vars, execution model, server/client | `managing-environment-tanstack-start` |
| Sessions, route protection, auth providers | `authenticating-tanstack-start` |
| Netlify, Cloudflare, Railway deployment | `deploying-tanstack-start` |
