---
name: invalidating-tanstack-query-cache
description: Use when working with TanStack Query cache management — invalidateQueries to mark stale and refetch, query filters with queryKey exact type stale predicate, setQueryData for direct cache updates, getQueryData to read cache, removeQueries to delete cached data, cancelQueries to abort in-flight requests, resetQueries, or fetchQuery for imperative fetching.
---

# Cache Invalidation & Management

## invalidateQueries

Marks queries as stale and triggers background refetch for rendered queries.

```tsx
const queryClient = useQueryClient()

// Invalidate everything
queryClient.invalidateQueries()

// Invalidate by prefix (matches ['todos'], ['todos', 1], ['todos', { page: 1 }])
queryClient.invalidateQueries({ queryKey: ['todos'] })

// Exact match only
queryClient.invalidateQueries({ queryKey: ['todos'], exact: true })

// With filters
queryClient.invalidateQueries({
  queryKey: ['todos', { type: 'done' }],
})

// Predicate function
queryClient.invalidateQueries({
  predicate: (query) => query.queryKey[0] === 'todos' && query.state.data?.version > 5,
})
```

When invalidated:
1. Query is marked stale (overrides `staleTime`)
2. If currently rendered, refetches in background

## Query Filters

Filters are used by `invalidateQueries`, `cancelQueries`, `removeQueries`, `resetQueries`, and `isFetching`.

| Property | Type | Description |
|----------|------|-------------|
| `queryKey` | `QueryKey` | Match queries by key prefix |
| `exact` | `boolean` | Match exact key only |
| `type` | `'active' \| 'inactive' \| 'all'` | Filter by mount status |
| `stale` | `boolean` | Filter by staleness |
| `fetchStatus` | `'fetching' \| 'paused' \| 'idle'` | Filter by fetch state |
| `predicate` | `(query) => boolean` | Custom filter function |

```tsx
// Cancel all active queries
queryClient.cancelQueries({ type: 'active' })

// Remove inactive todos queries
queryClient.removeQueries({ queryKey: ['todos'], type: 'inactive' })

// Invalidate only stale queries
queryClient.invalidateQueries({ stale: true })
```

## setQueryData — Direct Cache Updates

Update cache without a network request:

```tsx
// Set data directly
queryClient.setQueryData(['todo', todoId], updatedTodo)

// Update using previous value
queryClient.setQueryData(['todos'], (old) =>
  old?.map(todo => todo.id === updatedId ? { ...todo, ...updates } : todo)
)
```

## getQueryData — Read Cache

```tsx
const todos = queryClient.getQueryData(['todos'])
const todo = queryClient.getQueryData(['todo', todoId])
```

## removeQueries — Delete Cache Entries

```tsx
queryClient.removeQueries({ queryKey: ['todos'] })
```

Unlike invalidation, removal deletes the cache entry entirely.

## cancelQueries — Abort Requests

```tsx
await queryClient.cancelQueries({ queryKey: ['todos'] })
```

Cancels in-flight queries. Essential before optimistic updates to prevent race conditions.

## resetQueries — Reset to Initial State

```tsx
queryClient.resetQueries({ queryKey: ['todos'] })
```

Resets queries to their initial state (uses `initialData` if provided, otherwise refetches).

## fetchQuery — Imperative Fetch

```tsx
const data = await queryClient.fetchQuery({
  queryKey: ['todo', todoId],
  queryFn: () => fetchTodo(todoId),
})
```

Unlike `prefetchQuery`, `fetchQuery` throws on error.

## Invalidation After Mutation (Common Pattern)

```tsx
const mutation = useMutation({
  mutationFn: updateTodo,
  onSuccess: () => {
    // Invalidate and refetch related queries
    queryClient.invalidateQueries({ queryKey: ['todos'] })
    queryClient.invalidateQueries({ queryKey: ['todo', todoId] })
  },
})
```

## Common Mistakes

- Using `removeQueries` when you want `invalidateQueries` — removal loses cached data entirely
- Invalidating with wrong key structure — `['todos', 1]` won't match `['todo', 1]`
- Not awaiting `cancelQueries` before `setQueryData` in optimistic updates — race conditions
- Forgetting `queryClient` must be accessed via `useQueryClient()` hook in components
