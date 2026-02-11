---
description: "Audit TanStack Query project health: QueryClient configuration, provider setup, defaults, DevTools, and common misconfigurations"
---

# tanstack-query-doctor

Audit the health of a TanStack Query setup.

## Process

1. Read `package.json` and verify:
   - `@tanstack/react-query` is installed
   - Version is v5+ (current major)
   - `@tanstack/react-query-devtools` in devDependencies
2. Find QueryClient creation and check:
   - Created outside components or inside useState
   - Not at module level in SSR apps
   - Default options configured (staleTime, retry, gcTime)
3. Find QueryClientProvider and verify:
   - Wraps the entire app
   - DevTools included in development
4. Check for SSR setup if applicable:
   - Per-request QueryClient creation
   - HydrationBoundary present
   - staleTime > 0 to prevent double-fetch
   - gcTime not set to 0
5. Check for global type registration:
   - Register interface for defaultError
   - Custom queryMeta/mutationMeta if used
6. Scan for common misconfigurations:
   - QueryClient created inside component without useState
   - Multiple QueryClientProvider instances
   - staleTime: Infinity without invalidation patterns
   - retry: false in production (should only be in tests)
7. Report findings with severity and suggested fix
8. Summarize: total issues, health score, top priorities
