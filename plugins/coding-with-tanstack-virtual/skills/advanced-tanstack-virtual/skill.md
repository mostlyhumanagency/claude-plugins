---
name: advanced-tanstack-virtual
description: Use when implementing advanced TanStack Virtual patterns — sticky headers with rangeExtractor, SSR with initialRect, RTL scrolling, gap spacing, getItemKey for stable keys, isScrolling state, useFlushSync, React 19 compatibility, paddingStart/End
---

### Sticky Headers
Use a custom `rangeExtractor` to always include header items:
```tsx
import { defaultRangeExtractor, useVirtualizer } from '@tanstack/react-virtual'
import type { Range } from '@tanstack/react-virtual'

const stickyIndexes = [0, 15, 30] // indexes of header rows
const activeStickyRef = React.useRef(0)

const virtualizer = useVirtualizer({
  count: rows.length,
  estimateSize: () => 50,
  getScrollElement: () => parentRef.current,
  rangeExtractor: React.useCallback((range: Range) => {
    activeStickyRef.current =
      [...stickyIndexes].reverse().find((i) => range.startIndex >= i) ?? 0
    const next = new Set([activeStickyRef.current, ...defaultRangeExtractor(range)])
    return [...next].sort((a, b) => a - b)
  }, []),
})

// Render: active sticky gets position: sticky, others get position: absolute
{virtualizer.getVirtualItems().map((virtualRow) => (
  <div
    key={virtualRow.key}
    style={{
      ...(isActiveSticky(virtualRow.index)
        ? { position: 'sticky', zIndex: 1, background: '#fff' }
        : { position: 'absolute', transform: `translateY(${virtualRow.start}px)` }),
      top: 0,
      left: 0,
      width: '100%',
      height: `${virtualRow.size}px`,
    }}
  >
    {rows[virtualRow.index]}
  </div>
))}
```
- `rangeExtractor`: receives Range ({ startIndex, endIndex, overscan }), returns array of indexes to render
- Always include the active sticky index in the returned set
- Active sticky item uses `position: sticky` instead of absolute

### SSR / initialRect
For SSR, provide initial dimensions to avoid layout shift:
```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  initialRect: { width: 800, height: 600 },
  initialOffset: 0,
})
```

### RTL (Right-to-Left)
```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  horizontal: true,
  isRtl: true,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 100,
})
```

### Gap Between Items
```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  gap: 8, // 8px between items
})
```
Gap is added between items but not before first or after last.

### Padding
```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  paddingStart: 16,
  paddingEnd: 16,
})
```
- `paddingStart/End`: content padding in pixels
- `scrollPaddingStart/End`: extra padding when programmatically scrolling

### getItemKey
Provide stable keys (important when items reorder):
```tsx
const virtualizer = useVirtualizer({
  count: items.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  getItemKey: React.useCallback((index: number) => items[index].id, [items]),
})
```
Memoize getItemKey to prevent unnecessary recalculations.

### isScrolling State
Track whether user is actively scrolling:
```tsx
// virtualizer.isScrolling — boolean
// virtualizer.scrollDirection — 'forward' | 'backward' | null
// virtualizer.scrollOffset — current pixel position

// isScrollingResetDelay (default: 150ms) — how long after scroll stops before isScrolling = false
const virtualizer = useVirtualizer({
  ...options,
  isScrollingResetDelay: 200,
})
```
Use isScrolling to show placeholder content during fast scroll (performance optimization).

### useFlushSync (React 19)
```tsx
const virtualizer = useVirtualizer({
  count: 10000,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 35,
  useFlushSync: false, // disable for React 19 compatibility
})
```
- Default: true (uses flushSync for synchronous rendering during scroll)
- Set false for: React 19 (avoids lifecycle warnings), lower-end devices, testing
- When false: React batches scroll updates naturally, minor visual delay possible

### onChange Callback
React to virtualizer state changes:
```tsx
const virtualizer = useVirtualizer({
  ...options,
  onChange: (instance, sync) => {
    // sync: true if from flushSync, false otherwise
    // instance: the virtualizer instance
  },
})
```

### measure()
Force recalculation of all item sizes:
```tsx
virtualizer.measure() // reset all measurements
```
Useful after data changes that affect item sizes.

### resizeItem()
Manually set an item's size (useful for animations/transitions):
```tsx
virtualizer.resizeItem(index, newSize)
```
