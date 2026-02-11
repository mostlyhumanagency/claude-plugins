---
name: paginating-tanstack-query
description: Use when implementing pagination with TanStack Query — useInfiniteQuery for infinite scroll and load more, getNextPageParam and getPreviousPageParam, fetchNextPage and fetchPreviousPage, hasNextPage and isFetchingNextPage, data.pages array structure, initialPageParam, maxPages limit, placeholderData with keepPreviousData for page transitions, offset and cursor based pagination, or bi-directional infinite lists.
---

# Pagination with TanStack Query

## Offset Pagination with useQuery

Simple page-based pagination:

```tsx
function PaginatedPosts() {
  const [page, setPage] = useState(1)

  const { data, isPending, isPlaceholderData } = useQuery({
    queryKey: ['posts', page],
    queryFn: () => fetchPosts(page),
    placeholderData: keepPreviousData,  // Show previous page while loading next
  })

  return (
    <div>
      {isPending ? (
        <Spinner />
      ) : (
        <>
          <ul>
            {data.posts.map(post => <li key={post.id}>{post.title}</li>)}
          </ul>
          <div style={{ opacity: isPlaceholderData ? 0.5 : 1 }}>
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              Previous
            </button>
            <span>Page {page}</span>
            <button
              onClick={() => setPage(p => p + 1)}
              disabled={isPlaceholderData || !data.hasMore}
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  )
}
```

`keepPreviousData` keeps the previous page visible while the next page loads, preventing UI flicker. `isPlaceholderData` indicates when showing old data.

## Infinite Queries with useInfiniteQuery

For "load more" and infinite scroll patterns:

```tsx
import { useInfiniteQuery } from '@tanstack/react-query'

function InfinitePostList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isPending,
    isError,
    error,
  } = useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: async ({ pageParam }) => {
      const res = await fetch(`/api/posts?cursor=${pageParam}`)
      return res.json()
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  })

  if (isPending) return <Spinner />
  if (isError) return <p>Error: {error.message}</p>

  return (
    <div>
      {data.pages.map((page, i) => (
        <Fragment key={i}>
          {page.items.map(post => (
            <PostCard key={post.id} post={post} />
          ))}
        </Fragment>
      ))}
      <button
        onClick={() => fetchNextPage()}
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage ? 'Loading more...' : hasNextPage ? 'Load More' : 'No more posts'}
      </button>
    </div>
  )
}
```

### Data Structure

```tsx
data.pages   // Array of page results: [page1Data, page2Data, ...]
data.pageParams  // Array of params used: [0, 'cursor1', 'cursor2', ...]
```

### Key Options

| Option | Required | Description |
|--------|----------|-------------|
| `initialPageParam` | Yes | Starting page parameter |
| `getNextPageParam` | Yes | Return next cursor/page or `undefined` to stop |
| `getPreviousPageParam` | No | For bi-directional scrolling |
| `maxPages` | No | Limit stored pages (older pages removed) |

### getNextPageParam

Receives `(lastPage, allPages, lastPageParam, allPageParams)`:

```tsx
// Cursor-based
getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined

// Offset-based
getNextPageParam: (lastPage, allPages) =>
  lastPage.hasMore ? allPages.length : undefined

// Page-number based
getNextPageParam: (lastPage, allPages, lastPageParam) =>
  lastPage.hasMore ? lastPageParam + 1 : undefined
```

Return `undefined` or `null` to signal no more pages (`hasNextPage` becomes `false`).

## Bi-Directional Infinite Query

```tsx
useInfiniteQuery({
  queryKey: ['messages'],
  queryFn: ({ pageParam }) => fetchMessages(pageParam),
  initialPageParam: currentMessageId,
  getNextPageParam: (lastPage) => lastPage.nextCursor,
  getPreviousPageParam: (firstPage) => firstPage.prevCursor,
})

// Usage
fetchNextPage()     // Load newer messages
fetchPreviousPage() // Load older messages
```

## Infinite Scroll with Intersection Observer

```tsx
const loadMoreRef = useRef<HTMLDivElement>(null)

useEffect(() => {
  const observer = new IntersectionObserver(
    (entries) => {
      if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
        fetchNextPage()
      }
    },
    { threshold: 1.0 }
  )
  if (loadMoreRef.current) observer.observe(loadMoreRef.current)
  return () => observer.disconnect()
}, [hasNextPage, isFetchingNextPage, fetchNextPage])

return (
  <div>
    {/* ... render pages ... */}
    <div ref={loadMoreRef} />
  </div>
)
```

## Limiting Stored Pages

```tsx
useInfiniteQuery({
  queryKey: ['posts'],
  queryFn: fetchPosts,
  initialPageParam: 0,
  getNextPageParam: (lastPage) => lastPage.nextCursor,
  maxPages: 3,  // Only keep 3 pages in memory
})
```

## Common Mistakes

- Missing `initialPageParam` — required, causes runtime error
- Returning `null` from `getNextPageParam` when you mean to stop — return `undefined`
- Calling `fetchNextPage` while `isFetchingNextPage` is true — can overwrite data
- Not checking `hasNextPage` before enabling "Load More" button
- Forgetting that `data.pages` is an array of pages, not a flat list
