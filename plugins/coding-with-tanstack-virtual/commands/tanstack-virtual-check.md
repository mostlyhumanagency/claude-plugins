---
description: "Scan TanStack Virtual codebase for anti-patterns: missing overscan, inline estimateSize, unstable refs, incorrect positioning, and performance issues"
---

# tanstack-virtual-check

Scan the codebase for common TanStack Virtual anti-patterns.

## Process

1. Check virtualizer setup:
   - Missing overscan option — default is 1, too low for smooth scrolling
   - estimateSize too small — causes scroll jumping when items are measured
   - getScrollElement returning stale ref — should use callback with ref.current
   - getItemKey not memoized — causes unnecessary recalculations on every render
2. Check container patterns:
   - Scroll container missing fixed height and overflow: auto
   - Inner container missing height/width from getTotalSize()
   - Inner container missing position: relative
   - Items missing position: absolute
3. Check positioning:
   - Missing translateY/translateX on virtual items
   - Window virtualizer not subtracting scrollMargin from translateY
   - Grid items missing both translateX and translateY
   - Fixed height set on items that use measureElement — prevents dynamic sizing
4. Check measurement:
   - measureElement used without data-index attribute
   - estimateSize returning 0 or very small value
   - Smooth scrolling combined with dynamic measurement — incompatible
5. Check performance:
   - useFlushSync: true with React 19 — causes lifecycle warnings
   - Very high overscan (>20) without justification — excessive DOM nodes
   - Missing React.useCallback on getItemKey or rangeExtractor
   - Subscribing to isScrolling without purpose
6. Check infinite scroll:
   - count doesn't include +1 for loader row when hasNextPage
   - Missing effect to trigger fetchNextPage
   - Effect dependencies missing virtualizer.getVirtualItems()
7. Report each finding with file path, line number, severity, and fix
8. Summarize: total issues by severity, recommended action order
