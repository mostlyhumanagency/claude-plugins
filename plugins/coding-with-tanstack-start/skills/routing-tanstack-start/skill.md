---
name: routing-tanstack-start
description: Use when working with TanStack Start file-based routing — createFileRoute, __root.tsx root route, index routes, dynamic routes with $ params, catch-all routes with $, pathless layout routes with _ prefix, non-nested routes with _ suffix, route groups with parentheses, dot separator for nesting, .route.tsx files, or routeTree.gen.ts generation.
---

# TanStack Start Routing

TanStack Start uses TanStack Router's file-based routing. Routes live in `src/routes/` and the route tree is auto-generated as `routeTree.gen.ts`.

## File Naming Conventions

| Pattern | Example File | URL Path | Purpose |
|---------|-------------|----------|---------|
| `__root.tsx` | `__root.tsx` | — | Root layout wrapping all routes |
| `index.tsx` | `index.tsx` | `/` | Index route for parent path |
| Static | `about.tsx` | `/about` | Static route segment |
| Dot nesting | `blog.post.tsx` | `/blog/post` | Nested route using dots |
| Dynamic `$` | `posts.$postId.tsx` | `/posts/:postId` | Dynamic parameter segment |
| Catch-all `$` | `files.$.tsx` | `/files/*` | Wildcard capturing rest of path |
| Pathless `_` prefix | `_app.tsx` | — | Layout without URL segment |
| Non-nested `_` suffix | `posts_.$postId.tsx` | `/posts/:postId` | Un-nest from parent layout |
| Route group `()` | `(auth)/login.tsx` | `/login` | Folder grouping without URL impact |
| Escape `[]` | `api[.]v1.tsx` | `/api.v1` | Escape special characters |
| Exclude `-` prefix | `-utils.ts` | — | Excluded from route tree |
| Route file | `blog/post/route.tsx` | `/blog/post` | Alternative to `blog.post.tsx` |

## Root Route

The `__root.tsx` file is mandatory. It wraps every route:

```tsx
import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'

export const Route = createRootRoute({
  component: () => (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        <Outlet />
        <Scripts />
      </body>
    </html>
  ),
})
```

## Creating Routes

Use `createFileRoute()` — the path string auto-updates via the Router CLI:

```tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
  component: PostPage,
})

function PostPage() {
  const { postId } = Route.useParams()
  return <div>Post {postId}</div>
}
```

## Pathless Layout Routes

Prefix with `_` to create a layout that doesn't add a URL segment:

```
src/routes/
  _app.tsx          # Layout component (no URL path)
  _app.dashboard.tsx  # Renders at /dashboard inside _app layout
  _app.settings.tsx   # Renders at /settings inside _app layout
```

```tsx
// _app.tsx
export const Route = createFileRoute('/_app')({
  component: () => (
    <div className="app-shell">
      <Sidebar />
      <Outlet />
    </div>
  ),
})
```

## Non-Nested Routes

Suffix parent segment with `_` to un-nest from parent layout:

```
src/routes/
  posts.tsx            # /posts layout with Outlet
  posts.$postId.tsx    # /posts/:postId — nested inside posts layout
  posts_.$postId.edit.tsx  # /posts/:postId/edit — NOT nested inside posts layout
```

## Route Groups

Parenthesized folders group files without affecting URL:

```
src/routes/
  (auth)/
    login.tsx    # /login
    register.tsx # /register
  (dashboard)/
    home.tsx     # /home
```

## Key Components

- `<Outlet />` — renders the next matching child route
- `<HeadContent />` — renders meta/title tags from route head config
- `<Scripts />` — loads client-side JS for hydration

## Route Options

```tsx
export const Route = createFileRoute('/posts')({
  component: PostsPage,
  errorComponent: PostsError,
  pendingComponent: PostsLoading,
  loader: async () => fetchPosts(),
  beforeLoad: async ({ context }) => { /* auth checks */ },
  validateSearch: (search) => ({ page: Number(search.page ?? 1) }),
  head: () => ({ meta: [{ title: 'Posts' }] }),
})
```

## Common Mistakes

- Creating both `users.tsx` and `users/index.tsx` — causes duplicate route error
- Forgetting `<Outlet />` in layout routes — child routes won't render
- Dynamic segments in pathless layouts — not supported (`_$id.tsx` is invalid)
