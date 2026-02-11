---
name: virtualizing-lists
description: Use when virtualizing vertical or horizontal lists with TanStack Virtual — useVirtualizer hook, fixed-size and variable-size items, estimateSize, overscan, dynamic measurement with measureElement, ref callbacks
---

# Virtualizing Lists with TanStack Virtual

## Install

```bash
npm install @tanstack/react-virtual
```

## Core Pattern

1. Create a ref for the scroll container
2. Call `useVirtualizer` with `count`, `getScrollElement`, `estimateSize`
3. Render a container div with height = `getTotalSize()`
4. Map `getVirtualItems()` — position each absolutely with `translateY(virtualRow.start)`

## Required Options

- `count`: total number of items
- `getScrollElement`: returns the scrollable parent element (via ref)
- `estimateSize`: function returning estimated height (vertical) or width (horizontal) per index

## Fixed-Size Lists

Every item has the same height — `estimateSize` returns a constant:

```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  overscan: 5,
})
```

## Variable-Size Lists

Items have different sizes — `estimateSize` returns a per-index estimate:

```tsx
const sizes = React.useMemo(() =>
  new Array(10000).fill(0).map(() => 25 + Math.round(Math.random() * 100)), [])

const virtualizer = useVirtualizer({
  count: sizes.length,
  getScrollElement: () => parentRef.current,
  estimateSize: (i) => sizes[i],
  overscan: 5,
})
```

## Dynamic Measurement

For items whose size is not known upfront — use the `measureElement` ref callback:

```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 45, // estimate largest possible
})

// In render:
{virtualizer.getVirtualItems().map((virtualRow) => (
  <div
    key={virtualRow.key}
    data-index={virtualRow.index}
    ref={virtualizer.measureElement}
    style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: '100%',
      transform: `translateY(${virtualRow.start}px)`,
    }}
  >
    {/* content with unknown height */}
  </div>
))}
```

Key: add the `data-index` attribute and pass `virtualizer.measureElement` as the ref. Do NOT set a fixed height — let the content determine its size.

## Horizontal Lists

Set `horizontal: true`:

```tsx
const virtualizer = useVirtualizer({
  horizontal: true,
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 100,
})
// Use translateX instead of translateY, width instead of height
```

## Overscan

`overscan` controls how many items to render outside the viewport (default: 1). Higher values mean smoother scrolling but more DOM nodes:

```tsx
overscan: 5 // render 5 extra items above/below viewport
```

## VirtualItem Properties

- `key`: unique identifier (default: index, customize with `getItemKey`)
- `index`: item index in the original list
- `start`: pixel offset from container start
- `end`: pixel offset end
- `size`: measured or estimated size
- `lane`: lane index (0 for regular lists)
