---
name: suspense-tanstack-query
description: Use when using TanStack Query with React Suspense — useSuspenseQuery hook, useSuspenseInfiniteQuery, useSuspenseQueries for multiple queries, Suspense boundary integration, QueryErrorResetBoundary for error recovery, useQueryErrorResetBoundary hook, ErrorBoundary from react-error-boundary, throwOnError configuration, or render-as-you-fetch pattern.
---

# Suspense with TanStack Query

## useSuspenseQuery

Dedicated hook that integrates with React Suspense — no `isPending` checks needed:

```tsx
import { useSuspenseQuery } from '@tanstack/react-query'

function PostDetail({ postId }: { postId: string }) {
  // Suspends until data is ready — data is ALWAYS defined
  const { data } = useSuspenseQuery({
    queryKey: ['post', postId],
    queryFn: () => fetchPost(postId),
  })

  return <h1>{data.title}</h1>
}

// Parent wraps with Suspense boundary
function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <PostDetail postId="1" />
    </Suspense>
  )
}
```

Key difference from `useQuery`: `data` is never `undefined` — the component only renders after data resolves.

## useSuspenseInfiniteQuery

```tsx
const { data, fetchNextPage, hasNextPage } = useSuspenseInfiniteQuery({
  queryKey: ['posts'],
  queryFn: ({ pageParam }) => fetchPosts(pageParam),
  initialPageParam: 0,
  getNextPageParam: (lastPage) => lastPage.nextCursor,
})
```

## useSuspenseQueries

Multiple queries in parallel with Suspense:

```tsx
const [postsQuery, usersQuery] = useSuspenseQueries({
  queries: [
    { queryKey: ['posts'], queryFn: fetchPosts },
    { queryKey: ['users'], queryFn: fetchUsers },
  ],
})
// Both data properties are defined — component renders after all resolve
```

**Important**: Don't use multiple `useSuspenseQuery` hooks in the same component — the first suspends before the second can start, creating a waterfall. Use `useSuspenseQueries` instead.

## Error Handling with Boundaries

Errors throw to the nearest error boundary instead of returning in the result:

```tsx
import { QueryErrorResetBoundary } from '@tanstack/react-query'
import { ErrorBoundary } from 'react-error-boundary'

function App() {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          onReset={reset}
          fallbackRender={({ resetErrorBoundary, error }) => (
            <div>
              <p>Error: {error.message}</p>
              <button onClick={resetErrorBoundary}>Retry</button>
            </div>
          )}
        >
          <Suspense fallback={<Spinner />}>
            <PostDetail postId="1" />
          </Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  )
}
```

`QueryErrorResetBoundary` resets the query error state when the error boundary resets, allowing a fresh retry.

### Hook alternative

```tsx
function PostDetail() {
  const { reset } = useQueryErrorResetBoundary()
  // Use within an ErrorBoundary
}
```

## throwOnError Configuration

By default, errors only throw to boundaries when no cached data exists:

```tsx
// Default behavior
throwOnError: (error, query) => typeof query.state.data === 'undefined'
```

To always throw:

```tsx
useSuspenseQuery({
  queryKey: ['post', postId],
  queryFn: fetchPost,
  throwOnError: true,  // Always throw to boundary
})
```

## Render-as-you-fetch Pattern

Prefetch before component mounts to avoid Suspense waterfalls:

```tsx
// Parent prefetches
function PostPage({ postId }) {
  usePrefetchQuery(postQueryOptions(postId))

  return (
    <Suspense fallback={<Spinner />}>
      <PostDetail postId={postId} />
    </Suspense>
  )
}

// Child uses Suspense query — data may already be cached
function PostDetail({ postId }) {
  const { data } = useSuspenseQuery(postQueryOptions(postId))
  return <div>{data.title}</div>
}
```

## Suspense Limitations

- Query cancellation does NOT work with Suspense hooks
- Multiple `useSuspenseQuery` in one component creates waterfalls — use `useSuspenseQueries`
- `enabled` option is NOT available on Suspense hooks — use `skipToken` instead

```tsx
import { skipToken } from '@tanstack/react-query'

useSuspenseQuery({
  queryKey: ['post', postId],
  queryFn: postId ? () => fetchPost(postId) : skipToken,
})
```

## Common Mistakes

- Using `useQuery` in Suspense mode — use `useSuspenseQuery` instead
- Multiple `useSuspenseQuery` hooks in one component — waterfall, use `useSuspenseQueries`
- Missing `Suspense` boundary — component never renders
- Missing error boundary — unhandled errors crash the app
- Using `enabled: false` with Suspense — not supported, use `skipToken`
