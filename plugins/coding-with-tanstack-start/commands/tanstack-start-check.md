---
description: "Scan TanStack Start codebase for anti-patterns: unsafe environment access, hydration risks, missing loaders, and suboptimal configurations"
---

# tanstack-start-check

Scan the codebase for common TanStack Start anti-patterns and suggest improvements.

## Process

1. Find all route files in `src/routes/` and scan for:
   - Routes with `loader` but no `errorComponent` — unhandled loader errors
   - Routes with `loader` but no `pendingComponent` — no loading state
   - Dynamic routes without input validation in loaders
   - Missing `loaderDeps` when search params are used in loaders
   - Duplicate route definitions at same path
2. Check server functions:
   - `createServerFn` without `inputValidator` on POST methods
   - Server functions missing error handling (no try/catch or redirect)
   - `.server.ts` files imported in non-server contexts
   - Missing `{ data: ... }` wrapper in server function calls
3. Check environment variable usage:
   - `process.env` accessed in components or loaders (should be in server functions)
   - Secrets using `VITE_` prefix (exposed to client)
   - `window`/`document`/`localStorage` used in loaders or server functions
4. Check middleware:
   - Middleware that doesn't call `next()`
   - Middleware that doesn't return `next()` result
   - Auth middleware not applied to protected server functions
5. Check hydration safety:
   - `Date.now()`, `Math.random()` rendered without `<ClientOnly>`
   - Browser-only APIs used outside `<ClientOnly>` or `useHydrated`
   - Components with `suppressHydrationWarning` (flag for review)
6. Check rendering config:
   - `ssr: false` routes using server-only APIs in loader
   - Missing `shellComponent` when root has `ssr: false`
   - Static prerender without `filter` but `crawlLinks: true`
7. Report each finding with file path, line number, severity, and fix
8. Summarize: total issues by severity, recommended action order
