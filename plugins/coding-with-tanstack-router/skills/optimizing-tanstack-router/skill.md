---
name: optimizing-tanstack-router
description: Use when optimizing TanStack Router performance — scroll restoration with scrollRestoration option, scrollToTopSelectors, useElementScrollRestoration, resetScroll, route preloading with defaultPreload intent viewport render, preloadStaleTime, preloadDelay, manual preloading with router.preloadRoute, render optimizations with structural sharing, select option on useSearch useParams, fine-grained subscriptions, or defaultStructuralSharing.
---

# Optimizing TanStack Router

Performance features: scroll restoration, preloading, and render optimizations.

## Scroll Restoration

Restore scroll positions when navigating back to previously visited pages.

### Basic Setup

```tsx
const router = createRouter({
  routeTree,
  scrollRestoration: true,
})
```

### Nested Scrollable Areas

Track scroll position of nested containers:

```tsx
const router = createRouter({
  routeTree,
  scrollRestoration: true,
  scrollToTopSelectors: ['#main-content', '.scrollable-panel'],
})
```

### Custom Cache Keys

Control which navigations share scroll positions:

```tsx
const router = createRouter({
  scrollRestoration: true,
  getScrollRestorationKey: (location) => {
    // Same scroll for all /posts/* pages
    if (location.pathname.startsWith('/posts')) return '/posts'
    return location.state.__TSR_key  // Default behavior
  },
})
```

### Preventing Scroll Reset

Keep scroll position on certain navigations:

```tsx
<Link to="/posts" search={{ page: 2 }} resetScroll={false}>
  Page 2
</Link>

navigate({ to: '/posts', search: { page: 2 }, resetScroll: false })
```

### Scroll Behavior

```tsx
const router = createRouter({
  scrollRestoration: true,
  scrollRestorationBehavior: 'smooth',  // 'smooth' | 'instant' | 'auto'
})
```

### Manual Scroll Restoration (Virtualized Lists)

```tsx
import { useElementScrollRestoration } from '@tanstack/react-router'

function VirtualList() {
  const scrollRef = useRef<HTMLDivElement>(null)

  useElementScrollRestoration({
    id: 'virtual-list',
    getElement: () => scrollRef.current,
  })

  return <div ref={scrollRef} data-scroll-restoration-id="virtual-list">...</div>
}
```

## Route Preloading

Load route dependencies before navigation to eliminate loading states.

### Strategies

| Strategy | Trigger | Use Case |
|----------|---------|----------|
| `'intent'` | Hover / touch start | General navigation links |
| `'viewport'` | Element enters viewport | Below-the-fold content |
| `'render'` | Component mounts | Always-accessed routes |

### Global Default

```tsx
const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
  defaultPreloadDelay: 50,  // Ms after hover before preload (default 50)
})
```

### Per-Link Override

```tsx
<Link to="/heavy-page" preload="viewport">Heavy Page</Link>
<Link to="/settings" preload={false}>Settings</Link>  // Disable
```

### Preload Freshness

```tsx
const router = createRouter({
  defaultPreloadStaleTime: 30_000,  // Preloaded data fresh for 30s (default)
})

// Per route
export const Route = createFileRoute('/posts')({
  preloadStaleTime: 60_000,  // This route's preloaded data fresh for 60s
})
```

For external caches (React Query), set `defaultPreloadStaleTime: 0` to bypass router caching.

### Manual Preloading

```tsx
// Preload a route programmatically
await router.preloadRoute({
  to: '/posts/$postId',
  params: { postId: '5' },
})

// Just load the JS chunk (no data)
await router.loadRouteChunk(postRoute)
```

## Render Optimizations

### Structural Sharing

Maintains reference stability across re-renders. When URL state changes partially, unchanged properties keep their original references.

```
Navigate: /details?foo=f1&bar=b1 → /details?foo=f1&bar=b2
Result: search.foo keeps same reference, search.bar gets new reference
```

```tsx
// Enable globally
const router = createRouter({
  routeTree,
  defaultStructuralSharing: true,
})

// Enable per-hook
const result = Route.useSearch({ structuralSharing: true })
```

**Constraint**: Only works with JSON-serializable data. Class instances and non-serializable objects cause TypeScript errors.

### Fine-Grained Selectors

Subscribe to specific state slices to avoid unnecessary re-renders:

```tsx
// Only re-renders when 'page' changes, not when 'sort' changes
const page = Route.useSearch({ select: (s) => s.page })

// Select multiple values
const { page, filter } = Route.useSearch({
  select: (s) => ({ page: s.page, filter: s.filter }),
  structuralSharing: true,  // Important when select returns new objects
})
```

Without `structuralSharing`, the `select` function creates a new object every render (even if values haven't changed), causing unnecessary re-renders.

### Best Practice: Combine Both

```tsx
const router = createRouter({
  routeTree,
  defaultStructuralSharing: true,  // Enable globally
})

// In components — select only what you need
const page = Route.useSearch({ select: (s) => s.page })
```

## Performance Checklist

- [ ] Enable `defaultPreload: 'intent'` for faster perceived navigation
- [ ] Use `scrollRestoration: true` for proper back/forward behavior
- [ ] Enable `defaultStructuralSharing: true` to reduce re-renders
- [ ] Use `select` on `useSearch`/`useParams` when only using subset of data
- [ ] Set appropriate `staleTime` to reduce unnecessary loader calls
- [ ] Use automatic code splitting to minimize initial bundle
- [ ] Use `preload="viewport"` for below-fold navigation links

## Common Mistakes

- Using `select` without `structuralSharing` when returning objects — defeats the purpose
- Setting `preloadDelay: 0` — preloads on every mouse move, wastes bandwidth
- Enabling structural sharing with non-JSON data — TypeScript error
- Missing `scrollRestoration: true` — users lose scroll position on back navigation
- Not using `resetScroll: false` for pagination — scroll jumps to top on page change
