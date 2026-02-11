---
name: defining-tanstack-router-routes
description: Use when defining TanStack Router routes — createFileRoute, createRootRoute, createRoute, file naming conventions with $ _ () [] - dot separator, dynamic route params with $ prefix, optional params with {-$param}, param prefix/suffix with {$param}, catch-all wildcard routes, pathless layout routes with _ prefix, non-nested routes with _ suffix, route groups with parentheses, index routes, .route.tsx files, or routeTree.gen.ts.
---

# Defining Routes in TanStack Router

Routes define URL-to-component mappings with type-safe params, search validation, data loading, and error handling.

## File Naming Conventions

Routes live in `src/routes/` and map to URL paths:

| Pattern | Example File | URL | Purpose |
|---------|-------------|-----|---------|
| Root | `__root.tsx` | — | Root layout (wraps all routes) |
| Index | `index.tsx` | `/` | Index for parent path |
| Static | `about.tsx` | `/about` | Static segment |
| Dot nesting | `blog.post.tsx` | `/blog/post` | Nested via dots |
| Dynamic `$` | `posts.$postId.tsx` | `/posts/:postId` | Dynamic parameter |
| Catch-all `$` | `files.$.tsx` | `/files/*` | Wildcard rest-of-path |
| Pathless `_` prefix | `_app.tsx` | — | Layout without URL segment |
| Non-nested `_` suffix | `posts_.$postId.tsx` | `/posts/:postId` | Un-nest from parent |
| Group `()` | `(auth)/login.tsx` | `/login` | Folder grouping only |
| Escape `[]` | `api[.]v1.tsx` | `/api.v1` | Escape special chars |
| Exclude `-` prefix | `-utils.ts` | — | Excluded from routing |
| Route file | `blog/post/route.tsx` | `/blog/post` | Directory-based route |

## Path Parameters

### Basic Dynamic Params

```tsx
// src/routes/posts.$postId.tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => {
    return fetchPost(params.postId)  // params.postId is typed as string
  },
  component: () => {
    const { postId } = Route.useParams()
    return <div>Post {postId}</div>
  },
})
```

### Prefix and Suffix Params

Wrap params in `{}` with surrounding text:

```
post-{$postId}.tsx        → /post-123       (prefix)
{$fileName}.json.tsx      → /data.json      (suffix)
user-{$userId}.profile.tsx → /user-5.profile (both)
```

### Optional Parameters

Use `{-$param}` for segments that may be absent:

```tsx
// src/routes/{-$locale}.about.tsx
// Matches: /about, /en/about, /fr/about
export const Route = createFileRoute('/{-$locale}/about')({
  component: () => {
    const { locale } = Route.useParams()
    // locale is string | undefined
    return <h1>{locale ? `About (${locale})` : 'About'}</h1>
  },
})
```

Optional params are ideal for i18n URL patterns.

### Catch-All / Wildcard

The bare `$` captures all remaining segments:

```tsx
// src/routes/files.$.tsx
// Matches: /files/a, /files/a/b/c
export const Route = createFileRoute('/files/$')({
  component: () => {
    const { _splat } = Route.useParams()
    // _splat contains everything after /files/
    return <div>Path: {_splat}</div>
  },
})
```

## Route Options

```tsx
export const Route = createFileRoute('/posts/$postId')({
  // Components
  component: PostPage,
  errorComponent: PostError,
  pendingComponent: PostLoading,
  notFoundComponent: PostNotFound,

  // Data loading
  loader: async ({ params, context, deps }) => fetchPost(params.postId),
  beforeLoad: async ({ params, context }) => { /* auth, context setup */ },

  // Search params
  validateSearch: (search) => ({ page: Number(search.page ?? 1) }),
  loaderDeps: ({ search }) => ({ page: search.page }),

  // Cache
  staleTime: 10_000,
  gcTime: 300_000,

  // SSR (TanStack Start only)
  ssr: true,

  // Head management
  head: ({ loaderData }) => ({
    meta: [{ title: loaderData.post.title }],
  }),

  // Static data
  staticData: { breadcrumb: 'Post' },
})
```

## Pathless Layout Routes

Wrap child routes without adding a URL segment:

```
src/routes/
  _app.tsx              # Layout (no URL path)
  _app.dashboard.tsx    # /dashboard — wrapped in _app layout
  _app.settings.tsx     # /settings — wrapped in _app layout
```

```tsx
// _app.tsx
export const Route = createFileRoute('/_app')({
  component: () => (
    <div className="app-shell">
      <Sidebar />
      <main><Outlet /></main>
    </div>
  ),
})
```

Pathless layouts CANNOT have dynamic params — `_$id.tsx` is invalid.

## Non-Nested Routes

Suffix parent segment with `_` to escape nesting:

```
src/routes/
  posts.tsx                  # /posts (layout with Outlet)
  posts.$postId.tsx          # /posts/:id — nested in posts layout
  posts_.$postId.edit.tsx    # /posts/:id/edit — NOT nested in posts layout
```

## Route Groups

Parenthesized folders organize without affecting URL:

```
src/routes/
  (marketing)/
    pricing.tsx    # /pricing
    features.tsx   # /features
  (app)/
    dashboard.tsx  # /dashboard
```

## Code-Based Route Definition

```tsx
const postsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/posts',
  component: PostsPage,
  loader: async () => fetchPosts(),
})

const postRoute = createRoute({
  getParentRoute: () => postsRoute,
  path: '$postId',
  component: PostPage,
  loader: async ({ params }) => fetchPost(params.postId),
})
```

## Character Encoding

Path params use `encodeURIComponent` by default. Allow additional characters:

```tsx
const router = createRouter({
  routeTree,
  pathParamsAllowedCharacters: [';', ':', '@'],
})
```

## Common Mistakes

- Both `users.tsx` and `users/index.tsx` existing — duplicate route error
- Missing `<Outlet />` in layout routes — children don't render
- Dynamic params in pathless layouts — not supported
- Forgetting to run dev server after adding routes — routeTree.gen.ts stale
- Using `_splat` without catch-all `$` route — param doesn't exist
