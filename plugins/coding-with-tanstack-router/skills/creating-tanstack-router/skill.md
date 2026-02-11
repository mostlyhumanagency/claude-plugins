---
name: creating-tanstack-router
description: Use when setting up TanStack Router — createRouter function, routeTree configuration, Register interface for type safety, RouterProvider component, file-based vs code-based routing setup, routeTree.gen.ts generation, createRootRoute, addChildren, or installing @tanstack/react-router.
---

# Creating a TanStack Router

The Router instance is the core of TanStack Router. It manages the route tree, matches routes, coordinates navigations, and provides type safety.

## Installation

```bash
npm install @tanstack/react-router
# For file-based routing with Vite:
npm install -D @tanstack/router-plugin
```

## File-Based Routing Setup (Recommended)

### 1. Vite Plugin

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    tanstackRouter(),  // Generates routeTree.gen.ts
    react(),
  ],
})
```

### 2. Router Instance

```tsx
// src/router.tsx
import { createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

const router = createRouter({ routeTree })

// Type registration — enables type safety across the app
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}

export { router }
```

### 3. Root Route

```tsx
// src/routes/__root.tsx
import { createRootRoute, Outlet } from '@tanstack/react-router'

export const Route = createRootRoute({
  component: () => (
    <div>
      <nav>{/* navigation */}</nav>
      <Outlet />
    </div>
  ),
})
```

### 4. Mount

```tsx
// src/main.tsx
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'

function App() {
  return <RouterProvider router={router} />
}
```

The `routeTree.gen.ts` file is auto-generated on first run.

## Code-Based Routing Setup

For manual route tree construction without file generation:

```tsx
import { createRouter, createRoute, createRootRoute } from '@tanstack/react-router'

const rootRoute = createRootRoute({
  component: () => <div><Outlet /></div>,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: () => <h1>Home</h1>,
})

const aboutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/about',
  component: () => <h1>About</h1>,
})

const routeTree = rootRoute.addChildren([indexRoute, aboutRoute])

const router = createRouter({ routeTree })
```

## Key createRouter Options

```tsx
const router = createRouter({
  routeTree,

  // Defaults
  defaultPreload: 'intent',           // Preload on hover
  defaultPreloadDelay: 50,            // Ms before preload triggers
  defaultStaleTime: 0,                // Ms data stays fresh
  defaultPreloadStaleTime: 30_000,    // Ms preloaded data stays fresh
  defaultGcTime: 1_800_000,           // Ms before GC (30min)

  // Error handling
  defaultErrorComponent: ({ error }) => <div>{error.message}</div>,
  defaultNotFoundComponent: () => <div>Not found</div>,
  defaultPendingComponent: () => <div>Loading...</div>,
  defaultPendingMs: 1000,             // Ms before showing pending
  defaultPendingMinMs: 500,           // Min ms to show pending

  // Scroll
  scrollRestoration: true,

  // Structural sharing
  defaultStructuralSharing: true,

  // Context (for dependency injection)
  context: { queryClient, auth },

  // Search param serialization
  parseSearch: customParser,
  stringifySearch: customStringifier,

  // Not found behavior
  notFoundMode: 'fuzzy',  // 'fuzzy' | 'root'

  // Route masks
  routeMasks: [myRouteMask],
})
```

## Type Registration

The `Register` interface enables type safety for all router exports:

```tsx
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
```

Without this, `Link`, `useNavigate`, `useParams`, etc. have no type information about your routes.

## Dynamic Context via RouterProvider

Pass React hook values into router context:

```tsx
function App() {
  const auth = useAuth()
  return <RouterProvider router={router} context={{ auth }} />
}
```

## Common Mistakes

- Forgetting the `Register` interface — all navigation/params lose type safety
- Importing `routeTree.gen` before first dev run — file doesn't exist yet
- Using `createRootRoute` when you need context — use `createRootRouteWithContext<T>()`
- Not wrapping app in `<RouterProvider>` — router hooks throw errors
