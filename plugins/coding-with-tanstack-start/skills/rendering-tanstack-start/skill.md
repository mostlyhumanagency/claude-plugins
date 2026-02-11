---
name: rendering-tanstack-start
description: Use when working with TanStack Start rendering modes — server-side rendering SSR, selective SSR with ssr true false data-only, SPA mode single page application, static prerendering at build time, ISR incremental static regeneration, prerender option in vite.config.ts, shellComponent, crawlLinks, autoStaticPathsDiscovery, or choosing between SSR SPA and static rendering.
---

# TanStack Start Rendering Modes

TanStack Start supports multiple rendering strategies configurable per-route or globally.

## Server-Side Rendering (SSR) — Default

All routes are SSR'd by default. On initial request:
1. Server runs `beforeLoad` and `loader`
2. Server renders the component to HTML
3. HTML streams to client
4. Client hydrates and takes over

No configuration needed — this is the default behavior.

## Selective SSR

Control SSR per-route with the `ssr` option:

### `ssr: true` (default)

Full SSR — data functions and components render on server.

### `ssr: false`

Completely disables server-side execution. `beforeLoad`, `loader`, and component rendering all happen on the client during hydration.

```tsx
export const Route = createFileRoute('/canvas-editor')({
  ssr: false,  // Browser-only APIs needed
  component: CanvasEditor,
})
```

### `ssr: 'data-only'`

Data functions run on server, but component rendering is client-only:

```tsx
export const Route = createFileRoute('/dashboard')({
  ssr: 'data-only',  // Fetch data server-side, render client-side
  loader: async () => fetchDashboard(),
  component: Dashboard,
})
```

### Dynamic SSR with function

```tsx
export const Route = createFileRoute('/posts/$postId')({
  ssr: ({ params }) => {
    // Only SSR for specific posts
    return params.postId !== 'draft'
  },
})
```

This function runs only on the server and is stripped from client bundles.

### Inheritance Rules

Child routes inherit parent SSR config but can only become **more restrictive**:
- `true` → `'data-only'` → `false`
- A child cannot be `true` if parent is `false`

### Root Route SSR

Disabling root component SSR still requires a server-rendered HTML shell via `shellComponent`:

```tsx
export const Route = createRootRoute({
  ssr: false,
  shellComponent: ({ children }) => (
    <html>
      <head><HeadContent /></head>
      <body>{children}<Scripts /></body>
    </html>
  ),
  component: App,
})
```

## SPA Mode

Ship a static HTML shell that bootstraps entirely on the client.

### Configuration

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'

export default defineConfig({
  plugins: [
    tanstackStart({
      spa: {
        enabled: true,
      },
    }),
  ],
})
```

### How It Works

1. Build prerenders only the root route
2. Renders the router's pending fallback instead of matched routes
3. Outputs static HTML to `/_shell.html`
4. All unmatched requests redirect to the shell

### Advantages

- Deploy on any static CDN — no server needed
- Cheap hosting
- No hydration/SSR complexity

### Drawbacks

- Longer initial load (waits for JS)
- SEO limitations (content not in initial HTML)

### Shell Detection

```tsx
function App() {
  const router = useRouter()
  if (router.isShell()) {
    return <FullPageSpinner />
  }
  return <Dashboard />
}
```

### Server Functions Still Work

SPA mode doesn't disable server-side features. Server functions and server routes remain fully functional.

## Static Prerendering

Generate HTML files at build time for optimal performance.

### Configuration

```ts
// vite.config.ts
export default defineConfig({
  plugins: [
    tanstackStart({
      prerender: {
        enabled: true,
        autoStaticPathsDiscovery: true,  // Auto-find static routes
        crawlLinks: true,                // Follow links in rendered pages
        concurrency: 14,                 // Parallel render jobs
      },
    }),
  ],
})
```

### Key Options

| Option | Default | Purpose |
|--------|---------|---------|
| `enabled` | `false` | Activate prerendering |
| `autoStaticPathsDiscovery` | `true` | Auto-discover static routes |
| `crawlLinks` | `false` | Extract and prerender linked pages |
| `concurrency` | `14` | Parallel render jobs |
| `filter` | — | Custom function to exclude paths |
| `failOnError` | `false` | Stop build on render errors |
| `retryCount` | `0` | Retry failed renders |
| `onSuccess` | — | Callback after successful render |

### Automatic Discovery

Static routes (no `$` params, no `_` prefix, with components) are discovered automatically. Dynamic routes are excluded unless reached via `crawlLinks`.

### Filtering

```ts
prerender: {
  enabled: true,
  filter: (path) => {
    // Skip admin routes
    if (path.startsWith('/admin')) return false
    return true
  },
}
```

## Static Server Functions

Experimental: cache server function results as static JSON at build time.

```tsx
import { staticFunctionMiddleware } from '@tanstack/react-start'

export const getStaticPosts = createServerFn()
  .middleware([staticFunctionMiddleware])  // Must be LAST middleware
  .handler(async () => {
    return db.getPosts()
  })
```

Results are cached as JSON files keyed by function ID + params hash. Subsequent client calls fetch from the static file instead of hitting the server.

## Choosing a Rendering Strategy

| Strategy | Use When |
|----------|----------|
| **SSR** (default) | SEO matters, fast first paint, dynamic content |
| **Selective SSR** | Some routes need browser APIs |
| **SPA** | Admin panels, internal tools, no SEO needed |
| **Static** | Content sites, blogs, docs |
| **Static + SSR** | Hybrid: static for content, SSR for dynamic pages |

## Common Mistakes

- Using `ssr: false` and expecting loaders to run on server — they run on client only
- Forgetting `shellComponent` when disabling root SSR — HTML shell still needs server rendering
- Setting `crawlLinks: true` without `filter` — may prerender unwanted dynamic routes
- Using browser APIs in loaders without `ssr: false` — breaks SSR
