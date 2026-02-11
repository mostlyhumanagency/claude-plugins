---
name: setting-up-tanstack-query
description: Use when setting up TanStack Query — installing @tanstack/react-query, creating QueryClient, QueryClientProvider wrapper, configuring default options staleTime gcTime retry refetchOnWindowFocus, React Query DevTools, or understanding important defaults.
---

# Setting Up TanStack Query

## Installation

```bash
npm install @tanstack/react-query
# Optional: DevTools
npm install @tanstack/react-query-devtools
```

## Basic Setup

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

// Create a client — do this ONCE, outside components (or in useState)
const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  )
}
```

For SSR/Next.js, create the client inside state to avoid sharing between requests:

```tsx
function App() {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: { staleTime: 60 * 1000 },
    },
  }))

  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
    </QueryClientProvider>
  )
}
```

## Important Defaults

| Setting | Default | Meaning |
|---------|---------|---------|
| `staleTime` | `0` | Data is immediately stale — refetches on mount, focus, reconnect |
| `gcTime` | `5 * 60 * 1000` (5min) | Inactive queries garbage collected after 5 minutes |
| `retry` | `3` | Failed queries retry 3 times with exponential backoff |
| `retryDelay` | Exponential | `attempt => Math.min(1000 * 2 ** attempt, 30000)` |
| `refetchOnMount` | `true` | Refetch stale queries when component mounts |
| `refetchOnWindowFocus` | `true` | Refetch stale queries when window regains focus |
| `refetchOnReconnect` | `true` | Refetch stale queries when network reconnects |
| `refetchInterval` | `false` | No polling by default |
| Structural sharing | `true` | Preserves data references when unchanged |

## Configuring Defaults

```tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,       // 5 minutes fresh
      gcTime: 10 * 60 * 1000,         // 10 minutes in cache
      retry: 1,                        // Retry once
      refetchOnWindowFocus: false,     // Don't refetch on tab focus
    },
    mutations: {
      retry: 0,                        // Don't retry mutations
    },
  },
})
```

## DevTools

```tsx
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <YourApp />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

DevTools only bundle in development — they're tree-shaken in production builds.

## Key Behaviors to Understand

1. **staleTime: 0** means every mount/focus/reconnect triggers a background refetch — set higher to reduce network requests
2. **Structural sharing** means `data` keeps the same reference if values haven't changed — safe for `useMemo`/`useEffect` deps
3. **Queries retry silently** — users won't see errors until all retries fail
4. **Window focus refetching** is aggressive — disable if it causes UX issues
5. **gcTime controls memory** — lower it for memory-constrained apps, raise it for frequently revisited data

## Common Mistakes

- Creating QueryClient inside a component without `useState` — new client on every render
- Setting `staleTime: Infinity` without understanding you must manually invalidate
- Setting `gcTime: 0` — can cause hydration errors with SSR
- Forgetting `<QueryClientProvider>` — all hooks throw errors
