---
description: "Scan TanStack Query codebase for anti-patterns: unstable query keys, missing invalidation, unsafe cache access, and suboptimal configurations"
---

# tanstack-query-check

Scan the codebase for common TanStack Query anti-patterns.

## Process

1. Check query key patterns:
   - Objects created inline in queryKey — should use stable references or queryOptions
   - Variables used in queryFn but not in queryKey — stale data risk
   - Deeply nested query keys that complicate invalidation
2. Check query patterns:
   - useQuery without error handling (no errorComponent or conditional)
   - fetch() calls in queryFn that don't check res.ok — errors silently return HTML
   - enabled: false without manual refetch mechanism
   - Data fetching in components instead of loaders (with TanStack Router)
3. Check mutation patterns:
   - useMutation without onSuccess/onSettled invalidation — stale data after mutation
   - mutate() called in render — infinite loop risk
   - mutateAsync without try/catch — unhandled rejections
   - Missing optimistic update rollback (onMutate without onError)
4. Check cache management:
   - setQueryData without matching useQuery key — data never displayed
   - cancelQueries missing before optimistic setQueryData — race conditions
   - removeQueries used when invalidateQueries intended
5. Check Suspense usage:
   - Multiple useSuspenseQuery in one component — waterfall
   - useSuspenseQuery without Suspense boundary
   - Missing QueryErrorResetBoundary with error boundaries
6. Check SSR patterns:
   - QueryClient at module level — data leaks between users
   - staleTime: 0 with SSR prefetching — negates prefetch
   - Missing HydrationBoundary
7. Report each finding with file path, line number, severity, and fix
8. Summarize: total issues by severity, recommended action order
