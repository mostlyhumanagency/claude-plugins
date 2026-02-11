---
name: coding-tanstack-virtual
description: Use only when a user wants an overview of available TanStack Virtual skills or when unsure which TanStack Virtual skill applies. Routes to the correct sub-skill.
---

# TanStack Virtual Overview

TanStack Virtual is a headless UI utility for virtualizing long lists of elements. Instead of rendering every item in a large dataset, it only renders the items currently visible in the viewport, dramatically improving performance.

Key characteristics:
- **Headless** — provides logic only, you control the markup and styling
- **Supports vertical, horizontal, and grid layouts**
- **Framework-agnostic** core with a dedicated React adapter (`@tanstack/react-virtual`)
- **Handles fixed-size, variable-size, and dynamically measured items**

## Quick Start

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList() {
  const parentRef = React.useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: 10000,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 35,
  })

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, width: '100%', position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
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
            Row {virtualRow.index}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Core Concepts

1. **Scroll container** — a ref to the scrollable parent element
2. **Virtualizer instance** — created via `useVirtualizer`, manages visible item calculation
3. **Absolute positioning** — items are positioned with `transform: translateY()` inside a container sized to `getTotalSize()`
4. **estimateSize** — function returning the estimated pixel size per item index
5. **overscan** — extra items rendered outside the viewport for smoother scrolling

## Skill Routing

| Task | Skill |
|------|-------|
| Vertical/horizontal lists, fixed/variable size, dynamic measurement | virtualizing-lists |
| Grid layouts, masonry, multi-lane | virtualizing-grids |
| Table virtualization, TanStack Table integration | virtualizing-tables |
| scrollToIndex, smooth scroll, window virtualizer, infinite scroll | scrolling-tanstack-virtual |
| Sticky headers, SSR, RTL, gap, getItemKey, React 19 | advanced-tanstack-virtual |
