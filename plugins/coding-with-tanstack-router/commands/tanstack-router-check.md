---
description: "Scan TanStack Router codebase for anti-patterns: missing type registration, unoptimized data loading, navigation issues, and suboptimal configurations"
---

# tanstack-router-check

Scan the codebase for common TanStack Router anti-patterns.

## Process

1. Check type safety:
   - Missing `Register` interface declaration
   - `useParams({ strict: false })` used excessively (lose type safety)
   - `useSearch({ strict: false })` used excessively
   - Routes without `validateSearch` when using search params
2. Check data loading patterns:
   - Routes using search params in loaders without `loaderDeps`
   - Missing `errorComponent` on routes with loaders
   - Missing `pendingComponent` on routes with slow loaders
   - `staleTime: Infinity` without good reason
   - Direct data fetching in components instead of loaders
3. Check navigation patterns:
   - `useNavigate` used where `<Link>` would be better (accessibility)
   - Missing `preload` configuration (no default preloading)
   - Pagination links without `resetScroll={false}`
   - Navigation without `from` parameter (loses type safety)
4. Check code splitting:
   - Large route files without code splitting
   - Loaders in `.lazy.tsx` files (not supported)
   - Direct route imports in lazy components (defeats splitting)
5. Check configuration:
   - Missing `scrollRestoration` setting
   - Missing `defaultPreload` setting
   - Missing `defaultStructuralSharing` for search-heavy apps
   - `notFoundMode` not configured
6. Report each finding with file path, line number, severity, and fix
7. Summarize: total issues by severity, recommended action order
