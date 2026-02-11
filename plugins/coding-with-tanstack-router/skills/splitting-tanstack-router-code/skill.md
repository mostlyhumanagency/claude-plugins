---
name: splitting-tanstack-router-code
description: Use when working with TanStack Router code splitting — automatic code splitting with autoCodeSplitting option, .lazy.tsx file pattern, createLazyFileRoute, createLazyRoute, critical vs non-critical route configuration, virtual routes, lazy route components, splitting loaders with lazyFn, getRouteApi for cross-file type-safe access, or optimizing bundle size.
---

# Code Splitting in TanStack Router

Code splitting separates route configuration into critical (loaded immediately) and non-critical (loaded on demand) to optimize bundle size.

## What Gets Split

| Critical (loaded immediately) | Non-Critical (loaded on demand) |
|-------------------------------|--------------------------------|
| Path parsing/serialization | `component` |
| Search param validation (`validateSearch`) | `errorComponent` |
| Loaders and `beforeLoad` | `pendingComponent` |
| Route context and static data | `notFoundComponent` |
| Links, scripts, styles | |

## Automatic Code Splitting (Recommended)

Enable in your Vite/bundler config:

```ts
// vite.config.ts
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [
    tanstackRouter({
      autoCodeSplitting: true,  // Automatically splits all routes
    }),
    react(),
  ],
})
```

With this enabled, every route's component, errorComponent, pendingComponent, and notFoundComponent are automatically split into separate chunks. No manual file splitting needed.

## Manual Splitting with `.lazy.tsx`

For projects that can't use automatic splitting, manually separate files:

### Original file

```tsx
// src/routes/posts.tsx (before splitting)
export const Route = createFileRoute('/posts')({
  loader: async () => fetchPosts(),
  component: PostsPage,
})

function PostsPage() { ... }
```

### Split into two files

```tsx
// src/routes/posts.tsx — critical (loader stays here)
export const Route = createFileRoute('/posts')({
  loader: async () => fetchPosts(),
})
```

```tsx
// src/routes/posts.lazy.tsx — non-critical (component moves here)
import { createLazyFileRoute } from '@tanstack/react-router'

export const Route = createLazyFileRoute('/posts')({
  component: PostsPage,
  // Can also export: errorComponent, pendingComponent, notFoundComponent
})
```

## Virtual Routes

If the critical file becomes empty after splitting (no loader, no beforeLoad), delete it entirely. A virtual route is auto-generated as an anchor for the `.lazy.tsx` file.

## Code-Based Lazy Routes

```tsx
const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
  loader: async () => fetchPosts(),
}).lazy(() => import('./posts.lazy').then((d) => d.Route))
```

```tsx
// posts.lazy.tsx
import { createLazyRoute } from '@tanstack/react-router'

export const Route = createLazyRoute('/posts')({
  component: PostsPage,
})
```

## Type-Safe Access Across Files

Use `getRouteApi` to access typed hooks without importing the route directly:

```tsx
import { getRouteApi } from '@tanstack/react-router'

const routeApi = getRouteApi('/posts')

function PostsPage() {
  const data = routeApi.useLoaderData()   // Typed!
  const params = routeApi.useParams()     // Typed!
  const search = routeApi.useSearch()     // Typed!
  const match = routeApi.useMatch()       // Typed!
}
```

This is essential for lazy-loaded components that live in separate files from the route definition.

## Loader Splitting (Advanced)

Split the loader function itself using `lazyFn`:

```tsx
export const Route = createFileRoute('/posts')({
  loader: lazyFn(() => import('./posts.loader'), 'loader'),
})
```

**Warning**: This means you pay twice — once to load the chunk, then to execute the loader. Only split loaders for rarely-visited routes with very heavy loader code.

## Directory Organization

Move route files into directories for cleaner structure:

```
# Before
src/routes/posts.tsx
src/routes/posts.lazy.tsx

# After (equivalent)
src/routes/posts/route.tsx
src/routes/posts/route.lazy.tsx
```

## Common Mistakes

- Using `createLazyFileRoute` in the main route file — only use it in `.lazy.tsx` files
- Exporting `loader` or `beforeLoad` from `.lazy.tsx` — only components can be lazy
- Splitting loaders unnecessarily — the double-fetch penalty usually isn't worth it
- Forgetting `getRouteApi` in lazy components — importing the route directly defeats code splitting
