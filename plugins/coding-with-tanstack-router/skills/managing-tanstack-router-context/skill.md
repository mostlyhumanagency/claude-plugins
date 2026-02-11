---
name: managing-tanstack-router-context
description: Use when working with TanStack Router context — createRootRouteWithContext, passing context to createRouter, accessing context in loader and beforeLoad, dependency injection pattern, modifying context in beforeLoad for child routes, React hooks in router context via RouterProvider, router.invalidate to recompute context, or type-safe context hierarchy.
---

# TanStack Router Context

Router context enables type-safe dependency injection and data sharing across the entire route hierarchy.

## Creating Typed Context

Use `createRootRouteWithContext<T>()` instead of `createRootRoute()`:

```tsx
// src/routes/__root.tsx
import { createRootRouteWithContext, Outlet } from '@tanstack/react-router'

interface RouterContext {
  queryClient: QueryClient
  auth: { isLoggedIn: boolean; userId?: string }
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: () => <Outlet />,
})
```

## Providing Context

Supply context when creating the router:

```tsx
const router = createRouter({
  routeTree,
  context: {
    queryClient,
    auth: { isLoggedIn: false },
  },
})
```

TypeScript errors if required context properties are missing.

## Accessing Context in Routes

```tsx
// In loaders
export const Route = createFileRoute('/todos')({
  loader: async ({ context }) => {
    // context.queryClient and context.auth are fully typed
    return context.queryClient.ensureQueryData(todosQueryOptions)
  },
})

// In beforeLoad
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context }) => {
    if (!context.auth.isLoggedIn) {
      throw redirect({ to: '/login' })
    }
  },
})
```

## Modifying Context for Children

Return values from `beforeLoad` merge into context for the current route and all children:

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context }) => {
    const user = await fetchUser(context.auth.userId!)
    return { user }  // Now context.user is available in all child routes
  },
})

// Child route
export const Route = createFileRoute('/dashboard/profile')({
  loader: async ({ context }) => {
    // context.user is typed and available
    return fetchProfile(context.user.id)
  },
})
```

## React Hooks in Context

React hooks can't be called outside components, so pass hook values via `RouterProvider`:

```tsx
function App() {
  const auth = useAuth()           // React hook
  const theme = useTheme()         // React hook
  const network = useNetworkStrength()

  return (
    <RouterProvider
      router={router}
      context={{ auth, theme, network }}
    />
  )
}
```

When these values change, call `router.invalidate()` to recompute context and re-run loaders.

## Dependency Injection Pattern

Pass services and clients instead of importing them directly:

```tsx
interface RouterContext {
  queryClient: QueryClient
  api: ApiClient
  analytics: AnalyticsService
  featureFlags: FeatureFlags
}

// Routes access services from context — no direct imports needed
loader: async ({ context: { api, queryClient } }) => {
  return queryClient.ensureQueryData({
    queryKey: ['posts'],
    queryFn: () => api.getPosts(),
  })
}
```

Benefits:
- Testable — swap real services for mocks
- Decoupled — routes don't import implementation details
- Configurable — different contexts per environment

## Accumulated Context (Breadcrumbs)

Access all matched route contexts via `useRouterState`:

```tsx
function Breadcrumbs() {
  const matches = useRouterState({ select: (s) => s.matches })
  return (
    <nav>
      {matches
        .filter((m) => m.staticData?.breadcrumb)
        .map((m) => (
          <Link key={m.id} to={m.fullPath}>
            {m.staticData.breadcrumb}
          </Link>
        ))}
    </nav>
  )
}
```

## Common Mistakes

- Using `createRootRoute()` when you need context — use `createRootRouteWithContext<T>()`
- Forgetting to provide context in `createRouter()` — TypeScript error at runtime
- Accessing context in components — context is only available in `loader`/`beforeLoad`, not in component render
- Not invalidating after context source changes — loaders see stale context values
