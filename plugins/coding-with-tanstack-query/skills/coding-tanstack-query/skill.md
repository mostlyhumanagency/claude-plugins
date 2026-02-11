---
name: coding-tanstack-query
description: Use only when a user wants an overview of available TanStack Query skills or when unsure which TanStack Query skill applies. Routes to the correct sub-skill.
---

# TanStack Query Overview

TanStack Query (formerly React Query) is a data-fetching and server state management library. It handles fetching, caching, synchronizing, and updating server state with zero-config defaults and powerful customization.

## Quick Start

```bash
npm install @tanstack/react-query
```

```tsx
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query'

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Todos />
    </QueryClientProvider>
  )
}

function Todos() {
  const { data, isPending, error } = useQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  })
  if (isPending) return <span>Loading...</span>
  if (error) return <span>Error: {error.message}</span>
  return <ul>{data.map(t => <li key={t.id}>{t.title}</li>)}</ul>
}
```

## Core Concepts

- **Queries** — declarative data fetching with automatic caching and refetching
- **Mutations** — create/update/delete with lifecycle callbacks
- **Query Keys** — unique array identifiers for cache entries
- **Invalidation** — mark queries stale and trigger refetch
- **Optimistic Updates** — update UI before server confirms
- **Prefetching** — load data before it's needed
- **Suspense** — integrate with React Suspense boundaries

## Skill Routing

| Task | Skill |
|---|---|
| QueryClient, QueryClientProvider, defaults | `setting-up-tanstack-query` |
| useQuery, queryKey, queryFn, states | `querying-with-tanstack-query` |
| useMutation, onSuccess, onError | `mutating-with-tanstack-query` |
| invalidateQueries, setQueryData, filters | `invalidating-tanstack-query-cache` |
| Optimistic UI, onMutate rollback | `optimistic-updates-tanstack-query` |
| useInfiniteQuery, pagination | `paginating-tanstack-query` |
| prefetchQuery, ensureQueryData, queryOptions | `prefetching-tanstack-query` |
| useSuspenseQuery, error boundaries | `suspense-tanstack-query` |
| dehydrate, HydrationBoundary, Next.js SSR | `ssr-tanstack-query` |
| Testing hooks, mocking, renderHook | `testing-tanstack-query` |
| Type inference, Register, queryOptions types | `typing-tanstack-query` |
