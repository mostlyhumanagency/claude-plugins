---
name: handling-errors-tanstack-start
description: Use when working with TanStack Start error handling — errorComponent, defaultErrorComponent, ErrorComponentProps with error and reset, notFound and notFoundComponent, route-level error boundaries, hydration errors and hydration mismatch, ClientOnly component for browser-only rendering, suppressHydrationWarning, useHydrated hook, or debugging SSR vs client rendering differences.
---

# Error Handling in TanStack Start

TanStack Start uses TanStack Router's route-level error boundaries and provides specific tools for hydration error prevention.

## Route Error Boundaries

### Default Error Component

Set a fallback for all routes:

```tsx
const router = createRouter({
  routeTree,
  defaultErrorComponent: ({ error, reset }) => (
    <div>
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={() => { reset(); router.invalidate() }}>
        Try again
      </button>
    </div>
  ),
})
```

### Route-Specific Error Component

```tsx
export const Route = createFileRoute('/posts/$postId')({
  errorComponent: PostError,
  component: PostPage,
  loader: async ({ params }) => fetchPost(params.postId),
})

function PostError({ error, reset }: ErrorComponentProps) {
  const router = useRouter()
  return (
    <div>
      <h2>Failed to load post</h2>
      <pre>{error.message}</pre>
      <button onClick={() => { reset(); router.invalidate() }}>
        Retry
      </button>
    </div>
  )
}
```

### The `reset()` Function

Calling `reset()` clears the error boundary state. Combine with `router.invalidate()` to re-run the loader:

```tsx
<button onClick={() => {
  reset()              // Clear error boundary
  router.invalidate()  // Re-run loaders
}}>
  Retry
</button>
```

## Not Found Handling

### Throwing notFound

```tsx
import { notFound } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    const post = await fetchPost(params.postId)
    if (!post) throw notFound()
    return { post }
  },
  notFoundComponent: () => (
    <div>
      <h2>Post not found</h2>
      <Link to="/posts">Back to posts</Link>
    </div>
  ),
})
```

### Default Not Found

```tsx
const router = createRouter({
  routeTree,
  defaultNotFoundComponent: () => (
    <div>
      <h2>Page not found</h2>
      <Link to="/">Go home</Link>
    </div>
  ),
})
```

## Triggering Errors

Errors can be thrown in `beforeLoad` or `loader` and are caught by the nearest error boundary:

```tsx
beforeLoad: async () => {
  const user = await getUser()
  if (!user) throw redirect({ to: '/login' })
  if (!user.isActive) throw new Error('Account deactivated')
}
```

## Hydration Errors

Hydration errors occur when server HTML differs from client render. Common causes: timestamps, random IDs, locale/timezone, browser APIs, feature flags.

### Strategy 1: Deterministic Rendering

Use cookies for client context (locale, timezone) and compute once server-side:

```tsx
// In beforeLoad or server function
const locale = getCookie('locale') || 'en-US'
// Pass to components via context
```

### Strategy 2: ClientOnly Component

Skip server rendering for inherently dynamic content:

```tsx
import { ClientOnly } from '@tanstack/react-start'

function TimezoneDisplay() {
  return (
    <ClientOnly fallback={<span>Loading...</span>}>
      {() => <span>{Intl.DateTimeFormat().resolvedOptions().timeZone}</span>}
    </ClientOnly>
  )
}
```

### Strategy 3: useHydrated Hook

```tsx
import { useHydrated } from '@tanstack/react-start'

function DynamicContent() {
  const isHydrated = useHydrated()

  if (!isHydrated) return <Skeleton />
  return <BrowserOnlyWidget />
}
```

### Strategy 4: Selective SSR

Disable component SSR for routes with inherently dynamic UI:

```tsx
export const Route = createFileRoute('/editor')({
  ssr: 'data-only',  // Fetch data server-side, render client-side
  component: Editor,
})
```

### Strategy 5: suppressHydrationWarning (last resort)

For small, predictable differences only:

```tsx
<time suppressHydrationWarning>
  {new Date().toLocaleTimeString()}
</time>
```

## Best Practices

- Prefer cookies over headers for client context
- Use `<ClientOnly>` for inherently dynamic content (clocks, user agents, canvas)
- Keep `suppressHydrationWarning` minimal — it hides real bugs
- Use `ssr: 'data-only'` when the entire page depends on browser APIs
- Always provide meaningful fallbacks in `<ClientOnly>`

## Common Mistakes

- Using `window` or `document` in loader — loaders run on server too
- Not calling both `reset()` AND `router.invalidate()` — error stays cleared but data is still stale
- Using `suppressHydrationWarning` on large subtrees — hides real SSR bugs
- Rendering `Date.now()` or `Math.random()` without `<ClientOnly>` — guaranteed mismatch
