---
name: scrolling-tanstack-virtual
description: Use when controlling scroll behavior in TanStack Virtual — scrollToIndex, scrollToOffset, smooth scrolling with custom easing, useWindowVirtualizer for window-based scrolling, scrollMargin, infinite scroll with TanStack Query
---

### scrollToIndex
Jump to a specific item by index:
```tsx
virtualizer.scrollToIndex(500, { align: 'start' })  // top of viewport
virtualizer.scrollToIndex(500, { align: 'center' })  // center of viewport
virtualizer.scrollToIndex(500, { align: 'end' })     // bottom of viewport
virtualizer.scrollToIndex(500, { align: 'auto' })    // nearest edge (default)
```
- `align`: 'start' | 'center' | 'end' | 'auto'
- `behavior`: 'auto' | 'smooth'

### scrollToOffset
Jump to a pixel position:
```tsx
virtualizer.scrollToOffset(5000, { align: 'start' })
```

### Smooth Scrolling with Custom Easing
Provide a custom scrollToFn for animated scrolling:
```tsx
const easeInOutQuint = (t: number) =>
  t < 0.5 ? 16 * t * t * t * t * t : 1 - Math.pow(-2 * t + 2, 5) / 2

const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  scrollToFn: (offset, { adjustments, behavior }, instance) => {
    if (behavior === 'smooth') {
      const start = instance.scrollOffset
      const target = offset + adjustments
      const duration = 1000
      let startTime: number | null = null
      const run = (ts: number) => {
        if (!startTime) startTime = ts
        const elapsed = Math.min((ts - startTime) / duration, 1)
        const progress = easeInOutQuint(elapsed)
        const scrollTo = start + (target - start) * progress
        instance.scrollElement?.scrollTo({ top: scrollTo })
        if (elapsed < 1) requestAnimationFrame(run)
      }
      requestAnimationFrame(run)
    } else {
      instance.scrollElement?.scrollTo({ top: offset + adjustments })
    }
  },
})

// Trigger smooth scroll:
virtualizer.scrollToIndex(Math.floor(Math.random() * 10000), { behavior: 'smooth' })
```
Note: smooth scrolling is incompatible with dynamic measurement (measureElement).

### Window Virtualizer
Use `useWindowVirtualizer` when the window/document is the scroll container:
```tsx
import { useWindowVirtualizer } from '@tanstack/react-virtual'

function WindowList() {
  const listRef = React.useRef<HTMLDivElement>(null)

  const virtualizer = useWindowVirtualizer({
    count: 10000,
    estimateSize: () => 35,
    overscan: 5,
    scrollMargin: listRef.current?.offsetTop ?? 0,
  })

  return (
    <div ref={listRef}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((item) => (
          <div
            key={item.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${item.size}px`,
              transform: `translateY(${item.start - virtualizer.options.scrollMargin}px)`,
            }}
          >
            Row {item.index}
          </div>
        ))}
      </div>
    </div>
  )
}
```
Key differences from useVirtualizer:
- No getScrollElement needed (uses window automatically)
- scrollMargin: offset from page top to list start (account for headers/content above)
- translateY must subtract scrollMargin: `item.start - virtualizer.options.scrollMargin`

### Infinite Scroll with TanStack Query
Combine useVirtualizer with useInfiniteQuery:
```tsx
import { useInfiniteQuery } from '@tanstack/react-query'
import { useVirtualizer } from '@tanstack/react-virtual'

function InfiniteList() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
    queryKey: ['items'],
    queryFn: ({ pageParam = 0 }) => fetchPage(pageParam),
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    initialPageParam: 0,
  })

  const allRows = data ? data.pages.flatMap((p) => p.rows) : []
  const parentRef = React.useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: hasNextPage ? allRows.length + 1 : allRows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
    overscan: 5,
  })

  // Trigger fetch when last item is visible
  React.useEffect(() => {
    const items = virtualizer.getVirtualItems()
    const lastItem = items[items.length - 1]
    if (!lastItem) return
    if (lastItem.index >= allRows.length - 1 && hasNextPage && !isFetchingNextPage) {
      fetchNextPage()
    }
  }, [hasNextPage, fetchNextPage, allRows.length, isFetchingNextPage, virtualizer.getVirtualItems()])

  return (
    <div ref={parentRef} style={{ height: '500px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualRow) => {
          const isLoader = virtualRow.index > allRows.length - 1
          return (
            <div
              key={virtualRow.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
            >
              {isLoader ? (hasNextPage ? 'Loading...' : 'End') : allRows[virtualRow.index]}
            </div>
          )
        })}
      </div>
    </div>
  )
}
```
Pattern: count = allRows.length + 1 (extra slot for loader row), check last visible item in useEffect.
