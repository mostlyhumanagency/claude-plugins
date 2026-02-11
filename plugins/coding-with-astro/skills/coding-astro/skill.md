---
name: coding-astro
description: "Use when building, reviewing, or debugging Astro websites and applications — covers components, routing, content collections, SSR, actions, middleware, sessions, view transitions, framework islands, endpoints, Astro DB, images, and Astro 6 features. Routes to the specific subskill."
---

# Astro Overview

Astro is a content-driven web framework built on islands architecture. It is server-first and ships zero JavaScript by default. Current stable release is v5; v6 is in beta.

## Quick Start

```bash
npm create astro@latest
```

Project structure: `src/pages/`, `src/components/`, `src/layouts/`, `src/content/`.

## CLI

- `astro dev` -- start dev server
- `astro build` -- production build
- `astro preview` -- preview build locally
- `astro add` -- add integrations

## Configuration

Use `astro.config.mjs` with `defineConfig()` from `astro/config`.

## TypeScript

Astro includes TypeScript support out of the box. Extend `astro/tsconfigs/base` in `tsconfig.json`.

## Skill Routing

| Task | Skill |
|---|---|
| Components, props, slots | `building-astro-components` |
| File routing, dynamic routes, pagination | `routing-astro-pages` |
| Content collections, Zod schemas, loaders | `using-astro-content-collections` |
| Scoped/global styles, Tailwind, Sass | `styling-astro-components` |
| Image/Picture components, optimization | `optimizing-astro-images` |
| SSR, adapters, prerender | `rendering-astro-on-demand` |
| Backend functions, form handling | `using-astro-actions` |
| Request interception, locals | `using-astro-middleware` |
| Server-side state, cookies | `managing-astro-sessions` |
| Page transitions, animations | `using-astro-view-transitions` |
| React/Vue/Svelte/Solid in Astro | `integrating-frameworks-in-astro` |
| API routes, static/server endpoints | `building-astro-endpoints` |
| SQL database, Drizzle ORM | `using-astro-db` |
| Astro 6 dev server, Cloudflare Workers | `using-astro-6-dev-server` |
| Content Security Policy | `configuring-astro-6-csp` |
| Live content collections | `using-astro-6-live-collections` |
