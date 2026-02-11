---
name: virtualizing-grids
description: Use when virtualizing two-dimensional grids or masonry layouts with TanStack Virtual — combining row and column virtualizers, lanes for masonry, multi-dimensional positioning
---

# Virtualizing Grids with TanStack Virtual

## Grid Virtualization

Combine a row virtualizer and a column virtualizer for 2D grids:

```tsx
function GridVirtualizer() {
  const parentRef = React.useRef<HTMLDivElement>(null)

  const rowVirtualizer = useVirtualizer({
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35,
    overscan: 5,
  })

  const columnVirtualizer = useVirtualizer({
    horizontal: true,
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
    overscan: 5,
  })

  return (
    <div ref={parentRef} style={{ height: '500px', width: '500px', overflow: 'auto' }}>
      <div
        style={{
          height: `${rowVirtualizer.getTotalSize()}px`,
          width: `${columnVirtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {rowVirtualizer.getVirtualItems().map((virtualRow) => (
          <React.Fragment key={virtualRow.index}>
            {columnVirtualizer.getVirtualItems().map((virtualColumn) => (
              <div
                key={virtualColumn.index}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: `${virtualColumn.size}px`,
                  height: `${virtualRow.size}px`,
                  transform: `translateX(${virtualColumn.start}px) translateY(${virtualRow.start}px)`,
                }}
              >
                Cell {virtualRow.index}, {virtualColumn.index}
              </div>
            ))}
          </React.Fragment>
        ))}
      </div>
    </div>
  )
}
```

## Variable-Size Grid

Use per-index sizes for rows and columns:

```tsx
const rowSizes = new Array(10000).fill(0).map(() => 25 + Math.round(Math.random() * 100))
const colSizes = new Array(10000).fill(0).map(() => 75 + Math.round(Math.random() * 100))

const rowVirtualizer = useVirtualizer({
  count: rowSizes.length,
  getScrollElement: () => parentRef.current,
  estimateSize: (i) => rowSizes[i],
})

const columnVirtualizer = useVirtualizer({
  horizontal: true,
  count: colSizes.length,
  getScrollElement: () => parentRef.current,
  estimateSize: (i) => colSizes[i],
})
```

## Masonry Layout

Use the `lanes` option for multi-column masonry:

```tsx
// Vertical masonry — 4 columns
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: (i) => sizes[i],
  lanes: 4,
})

// Each item has virtualRow.lane (0-3) for horizontal positioning
{virtualizer.getVirtualItems().map((virtualRow) => (
  <div
    key={virtualRow.key}
    style={{
      position: 'absolute',
      top: 0,
      left: `${virtualRow.lane * 25}%`,
      width: '25%',
      height: `${virtualRow.size}px`,
      transform: `translateY(${virtualRow.start}px)`,
    }}
  >
    Item {virtualRow.index}
  </div>
))}
```

- `lanes`: number of columns (vertical) or rows (horizontal) for masonry
- Each `VirtualItem` has a `.lane` property (0 to lanes-1)
- Items are distributed across lanes automatically
- Horizontal masonry: set `horizontal: true` with `lanes`

## Tips

- For grids: both virtualizers share the same scroll element
- Container size = row `getTotalSize()` x column `getTotalSize()`
- Items are positioned absolutely with combined `translateX` + `translateY`
- For dynamic grid cells: use `measureElement` on each cell with `data-index`
