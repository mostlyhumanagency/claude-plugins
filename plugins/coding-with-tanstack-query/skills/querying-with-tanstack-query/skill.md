---
name: querying-with-tanstack-query
description: Use when working with TanStack Query queries — useQuery hook, queryKey array structure, queryFn query function, isPending isError isSuccess status states, isFetching fetchStatus, data and error properties, enabled option for conditional queries, select option for data transformation, staleTime gcTime per-query configuration, refetchInterval polling, refetchOnWindowFocus, dependent serial queries, parallel queries with useQueries, or disabling queries with enabled false.
---

# Querying with TanStack Query

## useQuery Basics

```tsx
import { useQuery } from '@tanstack/react-query'

function Todos() {
  const { data, isPending, isError, error, isFetching } = useQuery({
    queryKey: ['todos'],
    queryFn: fetchTodos,
  })

  if (isPending) return <Spinner />
  if (isError) return <p>Error: {error.message}</p>

  return (
    <ul>
      {data.map(todo => <li key={todo.id}>{todo.title}</li>)}
    </ul>
  )
}
```

## Query States

| Property | Status | Meaning |
|----------|--------|---------|
| `isPending` | `'pending'` | No data yet (first load) |
| `isError` | `'error'` | Query failed (after retries) |
| `isSuccess` | `'success'` | Data available |

### Fetch Status (orthogonal to status)

| Property | Meaning |
|----------|---------|
| `isFetching` | Query function is executing (including background refetch) |
| `fetchStatus === 'paused'` | Query wants to fetch but network is offline |
| `fetchStatus === 'idle'` | Query is not executing |

A query can be `status: 'success'` AND `isFetching: true` during a background refetch.

## Query Keys

Keys must be arrays and are serialized with `JSON.stringify`:

```tsx
// Simple
useQuery({ queryKey: ['todos'], queryFn: fetchTodos })

// With ID
useQuery({ queryKey: ['todo', todoId], queryFn: () => fetchTodo(todoId) })

// With filters (object order doesn't matter)
useQuery({ queryKey: ['todos', { status: 'done', page: 1 }], queryFn: ... })

// Rule: include ALL variables used in queryFn
useQuery({
  queryKey: ['todos', { status, page }],
  queryFn: () => fetchTodos({ status, page }),
})
```

## Query Functions

Must return a promise that resolves data or throws an error:

```tsx
// Fetch
const queryFn = async () => {
  const res = await fetch('/api/todos')
  if (!res.ok) throw new Error('Failed to fetch')
  return res.json()
}

// Query function receives context with queryKey and signal
const queryFn = async ({ queryKey, signal }) => {
  const [, todoId] = queryKey
  const res = await fetch(`/api/todos/${todoId}`, { signal })
  if (!res.ok) throw new Error('Failed')
  return res.json()
}
```

## Conditional / Dependent Queries

Use `enabled` to control when a query runs:

```tsx
// Don't fetch until userId exists
const { data: user } = useQuery({
  queryKey: ['user', email],
  queryFn: () => getUserByEmail(email),
})

const { data: projects } = useQuery({
  queryKey: ['projects', user?.id],
  queryFn: () => getProjectsByUser(user!.id),
  enabled: !!user?.id,  // Only fetch when user.id is available
})
```

When `enabled: false`:
- Status starts as `'pending'` with `fetchStatus: 'idle'`
- Query won't auto-fetch on mount, focus, or reconnect
- `queryClient.invalidateQueries` won't trigger it
- `refetch()` still works manually

## Data Transformation with select

```tsx
const { data: todoCount } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
  select: (data) => data.length,  // Only re-renders when count changes
})

const { data: doneTodos } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
  select: (data) => data.filter(t => t.done),
})
```

`select` runs on the cached data — the query function only fetches once even with multiple `select` transformations.

## Parallel Queries

Multiple hooks in the same component run in parallel:

```tsx
function Dashboard() {
  const users = useQuery({ queryKey: ['users'], queryFn: fetchUsers })
  const projects = useQuery({ queryKey: ['projects'], queryFn: fetchProjects })
  // Both fetch simultaneously
}
```

### Dynamic Parallel Queries with useQueries

```tsx
const results = useQueries({
  queries: userIds.map(id => ({
    queryKey: ['user', id],
    queryFn: () => fetchUser(id),
  })),
})
// results is an array of query results
```

## Per-Query Configuration

```tsx
useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
  staleTime: 5 * 60 * 1000,       // Fresh for 5 minutes
  gcTime: 30 * 60 * 1000,         // Cache for 30 minutes
  refetchInterval: 10_000,         // Poll every 10 seconds
  refetchOnWindowFocus: false,     // Don't refetch on tab focus
  retry: 2,                        // Retry twice
  retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 10000),
  enabled: isReady,                // Conditional
  select: (data) => data.items,    // Transform
  placeholderData: previousData,   // Show while fetching
})
```

## Polling

```tsx
useQuery({
  queryKey: ['notifications'],
  queryFn: fetchNotifications,
  refetchInterval: 5000,  // Every 5 seconds
  refetchIntervalInBackground: true,  // Even when tab is hidden
})
```

## Common Mistakes

- Missing variables in queryKey — `['todos']` when queryFn uses `status` — stale data
- Not throwing errors in queryFn — `fetch` doesn't throw on 4xx/5xx, you must check `res.ok`
- Using `enabled: false` and expecting invalidation to work — it won't trigger disabled queries
- Creating new objects in queryKey on every render — causes infinite refetching
- Using `useQuery` in Suspense mode — use `useSuspenseQuery` instead
