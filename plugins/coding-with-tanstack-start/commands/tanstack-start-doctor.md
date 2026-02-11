---
description: "Audit TanStack Start project health: configuration, dependencies, route structure, and common misconfigurations"
---

# tanstack-start-doctor

Audit the health of a TanStack Start project by checking configuration, dependencies, and common issues.

## Process

1. Read `package.json` and verify required dependencies:
   - `@tanstack/react-start` and `@tanstack/react-router` installed
   - `vite` and `@vitejs/plugin-react` in devDependencies
   - `"type": "module"` is set
   - Scripts include `dev` and `build` commands
2. Read `vite.config.ts` and validate:
   - `tanstackStart()` is the FIRST plugin
   - `react()` plugin is present
   - SPA/prerender config is valid if present
3. Read `tsconfig.json` and check:
   - `"jsx": "react-jsx"` is set
   - `"target"` is ES2022 or later
   - `"moduleResolution"` is bundler
4. Check `src/router.tsx` exists and exports `getRouter`
5. Check `src/routes/__root.tsx` exists and includes:
   - `<HeadContent />` in head
   - `<Outlet />` in body
   - `<Scripts />` in body
6. Verify `routeTree.gen.ts` exists (if project has been run)
7. Check for `.env` files and verify no secrets use `VITE_` prefix
8. Scan for common misconfigurations:
   - Duplicate route paths
   - Server files imported in client code
   - Missing middleware `next()` calls
9. Report findings with severity (error, warning, info) and suggested fix
10. Summarize: total issues, health score, top priorities
