---
description: "Audit TanStack Router project health: configuration, type registration, route structure, and common misconfigurations"
---

# tanstack-router-doctor

Audit the health of a TanStack Router project.

## Process

1. Read `package.json` and verify:
   - `@tanstack/react-router` is installed
   - `@tanstack/router-plugin` in devDependencies (for file-based routing)
   - Compatible React version
2. Read `vite.config.ts` and check:
   - `tanstackRouter()` plugin present (for file-based routing)
   - `autoCodeSplitting` setting if applicable
3. Find and read the router creation file (router.tsx or similar):
   - `createRouter()` called with `routeTree`
   - `Register` interface declared for type safety
   - Sensible defaults (defaultPreload, scrollRestoration, etc.)
4. Check `src/routes/__root.tsx`:
   - Uses `createRootRoute` or `createRootRouteWithContext`
   - Has `<Outlet />` in component
   - Has `<HeadContent />` and `<Scripts />` if using TanStack Start
5. Verify `routeTree.gen.ts` exists and is up to date
6. Check for common misconfigurations:
   - Duplicate route paths
   - Missing `<Outlet />` in layout routes
   - Dynamic params in pathless layouts
   - Routes without error handling
7. Check TypeScript config:
   - `"moduleResolution": "bundler"` for proper imports
   - Strict mode enabled
8. Report findings with severity (error, warning, info) and suggested fix
9. Summarize: total issues, health score, top priorities
