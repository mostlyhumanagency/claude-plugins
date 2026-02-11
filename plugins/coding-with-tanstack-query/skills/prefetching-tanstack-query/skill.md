---
name: prefetching-tanstack-query
description: Use when prefetching data with TanStack Query — prefetchQuery to populate cache ahead of time, ensureQueryData that returns cached or fetched data, queryOptions helper for reusable query configs, infiniteQueryOptions, usePrefetchQuery hook, router integration for prefetching in loaders, manual cache priming with setQueryData, prefetchInfiniteQuery, or event-based prefetching on hover.
---

# Prefetching with TanStack Query

Load data before it's needed to eliminate loading states.

## prefetchQuery

Populates cache silently — never throws errors:

```tsx
const queryClient = useQueryClient()

// Prefetch on hover
<Link
  to={`/post/${postId}`}
  onMouseEnter={() => {
    queryClient.prefetchQuery({
      queryKey: ['post', postId],
      queryFn: () => fetchPost(postId),
    })
  }}
>
  View Post
</Link>
```

- Uses default `staleTime` to decide if data is fresh enough
- Returns `Promise<void>` (no data, no errors)
- Data is GC'd after `gcTime` if no `useQuery` uses it

## ensureQueryData

Like `prefetchQuery` but returns the data and throws on error:

```tsx
// In a route loader or server function
const data = await queryClient.ensureQueryData({
  queryKey: ['post', postId],
  queryFn: () => fetchPost(postId),
})
```

If cache already has fresh data, returns it immediately without fetching.

## queryOptions Helper

Centralize query config for reuse across hooks, prefetching, and cache operations:

```tsx
// Define once
function postQueryOptions(postId: string) {
  return queryOptions({
    queryKey: ['post', postId],
    queryFn: () => fetchPost(postId),
    staleTime: 5 * 60 * 1000,
  })
}

// Use everywhere
useQuery(postQueryOptions(postId))
useSuspenseQuery(postQueryOptions(postId))
queryClient.prefetchQuery(postQueryOptions(postId))
queryClient.ensureQueryData(postQueryOptions(postId))
queryClient.setQueryData(postQueryOptions(postId).queryKey, newData)
queryClient.getQueryData(postQueryOptions(postId).queryKey)
```

TypeScript infers all types from the `queryFn` return type.

### infiniteQueryOptions

Same pattern for infinite queries:

```tsx
function postsInfiniteOptions() {
  return infiniteQueryOptions({
    queryKey: ['posts'],
    queryFn: ({ pageParam }) => fetchPosts(pageParam),
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
  })
}
```

## usePrefetchQuery Hook

Prefetch before a Suspense boundary:

```tsx
function App() {
  // Start prefetching immediately on render
  usePrefetchQuery(postQueryOptions(postId))

  return (
    <Suspense fallback={<Spinner />}>
      <PostDetail postId={postId} />
    </Suspense>
  )
}

function PostDetail({ postId }) {
  // Data may already be cached from prefetch
  const { data } = useSuspenseQuery(postQueryOptions(postId))
  return <div>{data.title}</div>
}
```

## Router Integration

Prefetch in route loaders to prevent waterfalls:

```tsx
// TanStack Router
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params, context: { queryClient } }) => {
    await queryClient.ensureQueryData(postQueryOptions(params.postId))
  },
  component: PostPage,
})

// Next.js (Pages Router)
export async function getServerSideProps({ params }) {
  const queryClient = new QueryClient()
  await queryClient.prefetchQuery(postQueryOptions(params.postId))
  return { props: { dehydratedState: dehydrate(queryClient) } }
}
```

## Manual Cache Priming

Set data directly when available synchronously:

```tsx
queryClient.setQueryData(['post', postId], postData)
```

## Prefetch Infinite Queries

```tsx
await queryClient.prefetchInfiniteQuery({
  queryKey: ['posts'],
  queryFn: ({ pageParam }) => fetchPosts(pageParam),
  initialPageParam: 0,
  pages: 3,  // Prefetch first 3 pages
  getNextPageParam: (lastPage) => lastPage.nextCursor,
})
```

## Conditional Prefetching

Prefetch based on previous query results:

```tsx
const { data: user } = useQuery(userQueryOptions)

usePrefetchQuery({
  ...projectsQueryOptions(user?.id),
  enabled: !!user?.id,
})
```

## Common Mistakes

- Expecting `prefetchQuery` to return data — it returns `Promise<void>`, use `ensureQueryData` instead
- Not setting `staleTime` on prefetched queries — data may refetch immediately on mount
- Prefetching with different options than `useQuery` — cache miss due to key mismatch
- Not using `queryOptions` helper — duplicating queryKey/queryFn across prefetch and useQuery
