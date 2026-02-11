---
name: navigating-tanstack-start
description: Use when working with TanStack Start/Router navigation — Link component, useNavigate hook, Navigate component, router.navigate, search params with validateSearch and useSearch, search middlewares retainSearchParams stripSearchParams, active link styling activeProps, preloading with preload="intent", type-safe navigation with from/to, or dynamic/optional route params.
---

# TanStack Start Navigation

Navigation in TanStack Router is type-safe and based on origin (`from`) and destination (`to`) paths.

## Navigation APIs

### `<Link>` Component (preferred)

Renders an anchor tag with valid `href`. Supports cmd/ctrl+click for new tabs.

```tsx
import { Link } from '@tanstack/react-router'

// Basic
<Link to="/about">About</Link>

// With params
<Link to="/posts/$postId" params={{ postId: '123' }}>Post 123</Link>

// With search params
<Link to="/posts" search={{ page: 2, filter: 'recent' }}>Page 2</Link>

// Relative from current route
<Link from={Route.fullPath} search={(prev) => ({ ...prev, page: prev.page + 1 })}>
  Next Page
</Link>
```

### `useNavigate()` Hook

For imperative navigation after side effects:

```tsx
const navigate = useNavigate()

const handleSubmit = async () => {
  await saveData()
  navigate({ to: '/dashboard' })
}
```

### `<Navigate>` Component

Navigates immediately on mount — for client-side redirects:

```tsx
function ProtectedPage() {
  if (!user) return <Navigate to="/login" />
  return <Dashboard />
}
```

### `router.navigate()`

Available anywhere with router instance access:

```tsx
const router = useRouter()
router.navigate({ to: '/posts', search: { page: 1 } })
```

## Search Params

TanStack Router treats search params as first-class typed state using JSON serialization (not flat strings).

### Defining with `validateSearch`

```tsx
import { z } from 'zod'
import { zodValidator } from '@tanstack/zod-adapter'
import { fallback } from '@tanstack/zod-adapter'

export const Route = createFileRoute('/products')({
  validateSearch: zodValidator(
    z.object({
      page: fallback(z.number(), 1).default(1),
      filter: fallback(z.string(), '').default(''),
      sort: fallback(z.enum(['newest', 'price', 'rating']), 'newest').default('newest'),
    })
  ),
  component: ProductsPage,
})
```

Manual validation (no library):

```tsx
validateSearch: (search: Record<string, unknown>) => ({
  page: Number(search?.page ?? 1),
  filter: String(search?.filter ?? ''),
})
```

### Reading search params

```tsx
// Inside the route
const { page, filter, sort } = Route.useSearch()

// From a nested component
import { getRouteApi } from '@tanstack/react-router'
const routeApi = getRouteApi('/products')
const search = routeApi.useSearch()

// Loose (any route) — loses type safety
const search = useSearch({ strict: false })
```

### Writing search params

```tsx
// Via Link (preferred)
<Link to="." search={(prev) => ({ ...prev, page: prev.page + 1 })}>Next</Link>

// Via navigate
navigate({ search: (prev) => ({ ...prev, page: prev.page + 1 }) })
```

### Search Middlewares

```tsx
import { retainSearchParams, stripSearchParams } from '@tanstack/react-router'

export const Route = createFileRoute('/products')({
  validateSearch: zodValidator(schema),
  search: {
    middlewares: [
      retainSearchParams(['globalFilter']),  // Keep across navigation
      stripSearchParams({ page: 1 }),        // Remove defaults from URL
    ],
  },
})
```

## Active Link Styling

```tsx
// With props
<Link to="/about" activeProps={{ className: 'text-blue-600 font-bold' }}>About</Link>

// With data attribute (CSS)
<Link to="/about">About</Link>
// CSS: a[data-status="active"] { color: blue; }

// With function children
<Link to="/about">
  {({ isActive }) => <span className={isActive ? 'active' : ''}>About</span>}
</Link>
```

Active matching options:

```tsx
<Link to="/posts" activeOptions={{ exact: true }}>Posts</Link>  // Exact match only
```

## Preloading

```tsx
// Preload on hover intent
<Link to="/posts/$postId" params={{ postId: '5' }} preload="intent">
  Post 5
</Link>

// Custom delay
<Link to="/heavy-page" preload="intent" preloadDelay={200}>Heavy Page</Link>
```

## Route Matching

```tsx
import { useMatchRoute } from '@tanstack/react-router'

function Nav() {
  const matchRoute = useMatchRoute()
  const isOnPosts = matchRoute({ to: '/posts' })
  return <nav className={isOnPosts ? 'highlight' : ''}>...</nav>
}
```

## Common Mistakes

- Forgetting `from` when using relative search updates — defaults to root `/`
- Using `useNavigate` for links — use `<Link>` instead for accessibility and preloading
- Not providing `params` for dynamic routes in `<Link>` — causes type error
- Search params typed as strings — TanStack Router uses JSON, so numbers stay numbers
