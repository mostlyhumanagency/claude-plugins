---
name: ssr-tanstack-query
description: Use when server-side rendering with TanStack Query — dehydrate function to serialize query cache, HydrationBoundary component for client hydration, prefetchQuery on server, initialData approach, creating QueryClient per request, staleTime configuration for SSR, Next.js Pages Router getServerSideProps getStaticProps, Next.js App Router server components, Remix loader, TanStack Start integration, or streaming with Suspense.
---

# SSR with TanStack Query

Server rendering eliminates client loading states by prefetching data on the server and sending pre-rendered HTML.

## The Hydration Pattern (Recommended)

### 1. Prefetch on server → 2. Dehydrate → 3. Hydrate on client

```tsx
// Server: prefetch and dehydrate
const queryClient = new QueryClient()
await queryClient.prefetchQuery({
  queryKey: ['posts'],
  queryFn: getPosts,
})
const dehydratedState = dehydrate(queryClient)

// Client: hydrate into cache
<HydrationBoundary state={dehydratedState}>
  <PostsPage />
</HydrationBoundary>
```

## Next.js Pages Router

### Setup in _app.tsx

```tsx
import { QueryClient, QueryClientProvider, HydrationBoundary } from '@tanstack/react-query'

export default function MyApp({ Component, pageProps }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: { staleTime: 60 * 1000 },  // Prevent immediate refetch
    },
  }))

  return (
    <QueryClientProvider client={queryClient}>
      <HydrationBoundary state={pageProps.dehydratedState}>
        <Component {...pageProps} />
      </HydrationBoundary>
    </QueryClientProvider>
  )
}
```

### getServerSideProps

```tsx
export async function getServerSideProps() {
  const queryClient = new QueryClient()

  await queryClient.prefetchQuery({
    queryKey: ['posts'],
    queryFn: getPosts,
  })

  return {
    props: {
      dehydratedState: dehydrate(queryClient),
    },
  }
}
```

### getStaticProps

```tsx
export async function getStaticProps() {
  const queryClient = new QueryClient()
  await queryClient.prefetchQuery({
    queryKey: ['posts'],
    queryFn: getPosts,
  })

  return {
    props: { dehydratedState: dehydrate(queryClient) },
    revalidate: 60,
  }
}
```

### Dependent Queries on Server

Use `fetchQuery` (throws on error) for sequential dependencies:

```tsx
export async function getServerSideProps({ params }) {
  const queryClient = new QueryClient()

  const user = await queryClient.fetchQuery({
    queryKey: ['user', params.id],
    queryFn: () => getUser(params.id),
  })

  await queryClient.prefetchQuery({
    queryKey: ['projects', user.id],
    queryFn: () => getProjects(user.id),
  })

  return { props: { dehydratedState: dehydrate(queryClient) } }
}
```

## TanStack Router/Start Integration

```tsx
const router = createRouter({
  routeTree,
  context: { queryClient },
  defaultPreloadStaleTime: 0,  // Let Query handle caching
})

export const Route = createFileRoute('/posts')({
  loader: async ({ context: { queryClient } }) => {
    await queryClient.ensureQueryData(postsQueryOptions())
  },
  component: () => {
    const { data } = useSuspenseQuery(postsQueryOptions())
    return <PostList posts={data} />
  },
})
```

## The initialData Approach (Simple)

Pass server-fetched data directly — no dehydrate/hydrate:

```tsx
export async function getServerSideProps() {
  const posts = await getPosts()
  return { props: { posts } }
}

function PostsPage({ posts }) {
  const { data } = useQuery({
    queryKey: ['posts'],
    queryFn: getPosts,
    initialData: posts,
  })
  return <PostList posts={data} />
}
```

**Trade-offs**: Simpler but can't track when data was fetched, requires prop drilling, `initialData` never overwrites existing cache.

## Key SSR Configuration

### staleTime

Set `staleTime > 0` to prevent immediate client refetch:

```tsx
new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60 * 1000 },  // 1 minute
  },
})
```

Without this, the client refetches immediately on mount (wasting the prefetch).

### One QueryClient Per Request

**CRITICAL**: Create a new `QueryClient` for each server request to prevent data leakage between users:

```tsx
// WRONG — shared between all users
const queryClient = new QueryClient()

// RIGHT — per-request
export async function getServerSideProps() {
  const queryClient = new QueryClient()
  // ...
}
```

### gcTime

On servers, `gcTime` defaults to `Infinity` (auto cleanup). Don't set `gcTime: 0` — causes hydration errors. Minimum `2000` if needed.

### Error Handling

`prefetchQuery` never throws — failed queries are silently excluded from dehydrated state. For critical data, use `fetchQuery`:

```tsx
try {
  await queryClient.fetchQuery(postsQueryOptions())
} catch (error) {
  return { notFound: true }
}
```

To include failed queries:

```tsx
dehydrate(queryClient, {
  shouldDehydrateQuery: () => true,
})
```

## Common Mistakes

- Creating QueryClient at module level — data leaks between users
- `staleTime: 0` with SSR — client refetches immediately, negating prefetch
- `gcTime: 0` with SSR — causes hydration errors
- Using `prefetchQuery` for critical data — use `fetchQuery` (throws on error)
- Missing `HydrationBoundary` — client cache empty, refetches everything
