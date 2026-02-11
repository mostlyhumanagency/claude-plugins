---
name: loading-data-tanstack-start
description: Use when working with TanStack Start/Router data loading — route loader function, beforeLoad hook, useLoaderData, loaderDeps for search param dependencies, staleTime and gcTime cache configuration, pendingComponent for loading states, deferred data, preloading routes, SWR caching strategy, shouldReload, or integrating TanStack Query with router loaders.
---

# Data Loading in TanStack Start

TanStack Router coordinates async data dependencies at the route level with built-in SWR caching, deduplication, and background refetching.

## Route Loading Lifecycle

On URL/history change:
1. **Route Matching** (top-down) — parse params, validate search params
2. **Route Pre-Loading** (serial) — execute `beforeLoad`, handle errors/redirects
3. **Route Loading** (parallel) — preload components, execute `loader`, render pending/component

## Route Loaders

The `loader` function runs when a route matches:

```tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts')({
  loader: async () => {
    const posts = await fetchPosts()
    return { posts }
  },
  component: PostsPage,
})

function PostsPage() {
  const { posts } = Route.useLoaderData()
  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### Loader Parameters

The loader receives an object with:

```tsx
loader: async ({ params, context, deps, abortController, cause, preload, location }) => {
  // params — path parameters (e.g. { postId: '5' })
  // context — merged parent + route context
  // deps — values from loaderDeps
  // abortController — cancel network requests
  // cause — 'enter' | 'preload' | 'stay'
  // preload — boolean (true during preload)
  // location — current location object
}
```

### Accessing Loader Data

```tsx
// Inside the route component
const data = Route.useLoaderData()

// From a nested component (outside route context)
import { getRouteApi } from '@tanstack/react-router'
const routeApi = getRouteApi('/posts')
const data = routeApi.useLoaderData()
```

## beforeLoad

Runs before `loader`, serially from parent to child. Use for auth checks and context setup:

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context }) => {
    const user = await getUser()
    if (!user) throw redirect({ to: '/login' })
    return { user }  // Adds to context for this route and children
  },
  loader: async ({ context }) => {
    // context.user is available here
    return fetchDashboardData(context.user.id)
  },
})
```

## Search Params as Loader Dependencies

Use `loaderDeps` to include search params in the cache key:

```tsx
export const Route = createFileRoute('/posts')({
  validateSearch: (search) => ({
    page: Number(search?.page ?? 1),
    filter: String(search?.filter ?? ''),
  }),
  loaderDeps: ({ search: { page, filter } }) => ({ page, filter }),
  loader: async ({ deps: { page, filter } }) => {
    return fetchPosts({ page, filter })
  },
})
```

**IMPORTANT**: Only include deps you actually use in the loader. Extra deps cause unnecessary cache invalidation.

## SWR Cache Configuration

Data is keyed by fully parsed pathname + `loaderDeps`.

| Option | Default | Purpose |
|--------|---------|---------|
| `staleTime` | `0` | Ms data stays fresh (0 = always revalidate on navigate) |
| `preloadStaleTime` | `30_000` | Ms before preloaded data is stale |
| `gcTime` | `1_800_000` (30min) | Ms before cached data is garbage collected |
| `shouldReload` | — | Function to control when to reload beyond staleTime |

```tsx
// Route-level cache config
export const Route = createFileRoute('/posts')({
  staleTime: 10_000, // Fresh for 10 seconds
  loader: async () => fetchPosts(),
})

// Global defaults
const router = createRouter({
  routeTree,
  defaultStaleTime: 5_000,
  defaultPreloadStaleTime: 30_000,
})
```

### shouldReload

```tsx
export const Route = createFileRoute('/posts')({
  shouldReload: ({ cause }) => cause === 'enter',  // Only reload on navigation, not on focus
  loader: async () => fetchPosts(),
})
```

## Pending / Loading States

When loaders take longer than the pending threshold (default 1s):

```tsx
export const Route = createFileRoute('/posts')({
  pendingComponent: () => <div>Loading posts...</div>,
  pendingMinMs: 500,  // Show for at least 500ms to avoid flash
  pendingMs: 1000,    // Wait 1s before showing pending
  loader: async () => fetchPosts(),
})
```

## Error Handling in Loaders

```tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPost(params.postId)
    if (!post) throw notFound()
    return { post }
  },
  errorComponent: ({ error, reset }) => (
    <div>
      <p>Error: {error.message}</p>
      <button onClick={() => { reset(); router.invalidate() }}>Retry</button>
    </div>
  ),
  notFoundComponent: () => <div>Post not found</div>,
})
```

## Router Context

Pass global dependencies via router context:

```tsx
// Define context type in root route
import { createRootRouteWithContext } from '@tanstack/react-router'

interface RouterContext {
  queryClient: QueryClient
  auth: AuthState
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootComponent,
})

// Provide context in router
const router = createRouter({
  routeTree,
  context: { queryClient, auth },
})

// Access in any route loader
loader: async ({ context: { queryClient } }) => {
  return queryClient.ensureQueryData(postsQueryOptions())
}
```

## Invalidating Data After Mutations

```tsx
const router = useRouter()

const handleSave = async () => {
  await savePost(data)
  await router.invalidate({ sync: true })  // Reloads all active route loaders
}
```

## TanStack Query Integration

For apps needing shared caching, optimistic updates, or mutations:

```tsx
// Set this so router doesn't short-circuit loader calls
const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreloadStaleTime: 0,  // Let React Query handle caching
})

// In route loader — prefetch into Query cache
export const Route = createFileRoute('/posts')({
  loader: async ({ context: { queryClient } }) => {
    await queryClient.ensureQueryData(postsQueryOptions())
  },
  component: PostsPage,
})

function PostsPage() {
  const { data: posts } = useSuspenseQuery(postsQueryOptions())
  return <PostList posts={posts} />
}
```

## Common Mistakes

- Assuming loaders are server-only — loaders are **isomorphic** (run on both server and client)
- Not using `loaderDeps` for search-param-dependent loaders — causes stale data on filter changes
- Setting `staleTime: Infinity` globally — disables all background revalidation
- Calling `router.invalidate()` without `{ sync: true }` — UI may not update immediately
