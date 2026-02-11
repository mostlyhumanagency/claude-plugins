---
name: loading-tanstack-router-data
description: Use when loading data in TanStack Router routes — loader function, beforeLoad hook, useLoaderData, loaderDeps for cache key dependencies, staleTime gcTime preloadStaleTime SWR cache configuration, pendingComponent pendingMs pendingMinMs loading states, deferred data loading with Await component and unawaited promises, external data loading with TanStack Query ensureQueryData, data mutations with router.invalidate, shouldReload, or abortController in loaders.
---

# Data Loading in TanStack Router

TanStack Router coordinates async data at the route level with built-in SWR caching, deduplication, and background refetching.

## Route Loading Lifecycle

1. **Route Matching** (top-down) — parse params, validate search
2. **beforeLoad** (serial, parent->child) — auth checks, context setup
3. **loader** (parallel across sibling routes) — fetch data
4. **Component render** — display data

## Route Loaders

```tsx
export const Route = createFileRoute('/posts')({
  loader: async () => {
    const posts = await fetchPosts()
    return { posts }
  },
  component: () => {
    const { posts } = Route.useLoaderData()
    return <ul>{posts.map(p => <li key={p.id}>{p.title}</li>)}</ul>
  },
})
```

### Loader Parameters

```tsx
loader: async ({
  params,          // Path parameters
  context,         // Router + route context
  deps,            // Values from loaderDeps
  abortController, // Cancel requests on route change
  cause,           // 'enter' | 'preload' | 'stay'
  preload,         // true during preload
  location,        // Current location
  parentMatchPromise, // Promise resolving parent match
}) => { ... }
```

### Accessing Data Outside Route

```tsx
import { getRouteApi } from '@tanstack/react-router'

const routeApi = getRouteApi('/posts')

function PostList() {
  const { posts } = routeApi.useLoaderData()
  return <ul>...</ul>
}
```

## beforeLoad

Runs serially before loaders. Use for auth and context:

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context, location }) => {
    if (!context.auth.isLoggedIn) {
      throw redirect({
        to: '/login',
        search: { redirect: location.href },
      })
    }
    // Return values merge into context for this route + children
    return { user: await getUser(context.auth.userId) }
  },
  loader: async ({ context }) => {
    // context.user available here
    return fetchDashboard(context.user.id)
  },
})
```

## Search Params as Cache Dependencies

```tsx
export const Route = createFileRoute('/posts')({
  validateSearch: z.object({
    page: z.number().catch(1),
    sort: z.enum(['newest', 'oldest']).catch('newest'),
  }),
  // Only include deps used in loader — extras cause unnecessary invalidation
  loaderDeps: ({ search: { page, sort } }) => ({ page, sort }),
  loader: async ({ deps: { page, sort } }) => {
    return fetchPosts({ page, sort })
  },
})
```

## SWR Cache Configuration

Data is keyed by pathname + loaderDeps.

| Option | Default | Purpose |
|--------|---------|---------|
| `staleTime` | `0` | Ms data stays fresh (0 = revalidate on navigate) |
| `preloadStaleTime` | `30_000` | Ms preloaded data stays fresh |
| `gcTime` | `1_800_000` | Ms before garbage collection (30min) |
| `shouldReload` | — | Function for custom reload logic |

```tsx
// Route-level
export const Route = createFileRoute('/posts')({
  staleTime: 10_000,
  loader: async () => fetchPosts(),
})

// Global defaults
const router = createRouter({
  routeTree,
  defaultStaleTime: 5_000,
})
```

### shouldReload

```tsx
shouldReload: ({ cause }) => cause === 'enter'  // Only on navigation, not focus
```

## Pending / Loading States

```tsx
export const Route = createFileRoute('/posts')({
  pendingComponent: () => <Spinner />,
  pendingMs: 1000,    // Wait 1s before showing
  pendingMinMs: 500,  // Show for at least 500ms (prevent flash)
  loader: async () => fetchPosts(),
})
```

## Deferred Data Loading

Return unawaited promises for non-critical data:

```tsx
import { Await } from '@tanstack/react-router'

export const Route = createFileRoute('/dashboard')({
  loader: async () => {
    const criticalData = await fetchCritical()       // Awaited — blocks render
    const slowDataPromise = fetchAnalytics()          // NOT awaited — streams later
    return { criticalData, slowDataPromise }
  },
  component: () => {
    const { criticalData, slowDataPromise } = Route.useLoaderData()
    return (
      <div>
        <h1>{criticalData.title}</h1>
        <Await promise={slowDataPromise} fallback={<Spinner />}>
          {(analytics) => <Chart data={analytics} />}
        </Await>
      </div>
    )
  },
})
```

The `Await` component shows `fallback` until the promise resolves, then renders children. Rejections propagate to the nearest error boundary.

With SSR/streaming, deferred promises are streamed to the client as they resolve.

## External Data Loading (TanStack Query)

For shared caching, optimistic updates, and mutations:

```tsx
// Disable router cache to let Query handle it
const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreloadStaleTime: 0,
})

// In route
const postsQueryOptions = queryOptions({
  queryKey: ['posts'],
  queryFn: fetchPosts,
})

export const Route = createFileRoute('/posts')({
  loader: async ({ context: { queryClient } }) => {
    await queryClient.ensureQueryData(postsQueryOptions)
  },
  component: () => {
    const { data: posts } = useSuspenseQuery(postsQueryOptions)
    return <PostList posts={posts} />
  },
})
```

### Deferred with Query

```tsx
loader: async ({ context: { queryClient } }) => {
  queryClient.prefetchQuery(slowQueryOptions)   // NOT awaited — deferred
  await queryClient.ensureQueryData(fastQueryOptions)  // Awaited — blocks
}
```

## Data Mutations & Invalidation

The router doesn't manage mutations — use external libraries. After mutations, refresh loaders:

```tsx
const router = useRouter()

const handleSave = async () => {
  await api.updatePost(data)
  await router.invalidate({ sync: true })  // Reloads all active loaders
}
```

## Error Handling

```tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPost(params.postId)
    if (!post) throw notFound()
    return { post }
  },
  errorComponent: ({ error, reset }) => (
    <div>
      <p>{error.message}</p>
      <button onClick={() => { reset(); router.invalidate() }}>Retry</button>
    </div>
  ),
  notFoundComponent: () => <p>Post not found</p>,
})
```

## Common Mistakes

- Assuming loaders are server-only — they're isomorphic (run on both server and client)
- Missing `loaderDeps` for search-dependent loaders — stale data on filter changes
- Setting `staleTime: Infinity` globally — disables all revalidation
- Not awaiting critical data — renders before data is ready
- Calling `router.invalidate()` without `{ sync: true }` — UI may not update immediately
