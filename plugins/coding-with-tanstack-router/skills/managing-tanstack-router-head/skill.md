---
name: managing-tanstack-router-head
description: Use when working with TanStack Router document head management — HeadContent component for rendering meta tags, Scripts component for body scripts, ScriptOnce for pre-hydration scripts, route head option for title meta links styles, automatic tag deduping, composable head from nested routes, or SEO optimization with meta tags.
---

# Document Head Management

TanStack Router manages document `<head>` tags (title, meta, links, styles, scripts) with automatic deduping and composable merging across nested routes.

## Key Components

### HeadContent

Renders all head-related tags. Place in `<head>`:

```tsx
// src/routes/__root.tsx
export const Route = createRootRoute({
  component: () => (
    <html>
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

### Scripts

Renders body scripts. Must be in `<body>` for proper hydration.

### ScriptOnce

Executes a script before React hydration — prevents FOUC:

```tsx
import { ScriptOnce } from '@tanstack/react-router'

// In root route component
<ScriptOnce>
  {`
    const theme = localStorage.getItem('theme') || 'light'
    document.documentElement.setAttribute('data-theme', theme)
  `}
</ScriptOnce>
```

ScriptOnce renders during SSR, executes immediately on parse, removes itself from DOM, and skips on client-side navigation. Use `suppressHydrationWarning` on elements ScriptOnce modifies.

## Route Head Configuration

Define head tags via the `head` option:

```tsx
export const Route = createFileRoute('/posts/$postId')({
  loader: async ({ params }) => fetchPost(params.postId),
  head: ({ loaderData }) => ({
    meta: [
      { title: loaderData.title },
      { name: 'description', content: loaderData.excerpt },
      { property: 'og:title', content: loaderData.title },
      { property: 'og:description', content: loaderData.excerpt },
      { property: 'og:image', content: loaderData.coverImage },
    ],
  }),
})
```

### Head Object Properties

```tsx
head: () => ({
  // Page title
  title: 'My Page',

  // Meta tags
  meta: [
    { name: 'description', content: 'Page description' },
    { name: 'keywords', content: 'react, router' },
    { property: 'og:title', content: 'My Page' },
    { charSet: 'utf-8' },
  ],

  // Link tags (favicon, stylesheets, preload)
  links: [
    { rel: 'icon', href: '/favicon.ico' },
    { rel: 'stylesheet', href: '/styles.css' },
    { rel: 'preload', href: '/font.woff2', as: 'font', crossOrigin: 'anonymous' },
  ],

  // Inline styles
  styles: [
    { content: 'body { margin: 0 }' },
    { content: '@media print { .no-print { display: none } }', media: 'print' },
  ],

  // Scripts
  scripts: [
    { src: '/analytics.js', async: true },
    { children: 'console.log("inline script")' },
  ],
})
```

## Deduping Rules

Tags are deduped by preferring the **last** occurrence (deepest nested route wins):

- **title**: Last route's title overrides parents
- **meta**: Tags with the same `name` or `property` attribute are deduped
- **links/styles/scripts**: Deduped by matching all attributes

```tsx
// Root route: { meta: [{ name: 'description', content: 'My App' }] }
// Child route: { meta: [{ name: 'description', content: 'About Page' }] }
// Result: 'About Page' wins (child overrides parent)
```

## Composing Head Across Routes

Head tags from all matched routes are merged:

```tsx
// __root.tsx — base tags for every page
head: () => ({
  meta: [
    { charSet: 'utf-8' },
    { name: 'viewport', content: 'width=device-width, initial-scale=1' },
  ],
  links: [{ rel: 'icon', href: '/favicon.ico' }],
})

// posts.$postId.tsx — route-specific tags
head: ({ loaderData }) => ({
  meta: [
    { title: loaderData.title },
    { name: 'description', content: loaderData.excerpt },
  ],
})

// Result: both sets of tags are rendered, with child overriding duplicates
```

## Common Mistakes

- Placing `<HeadContent />` outside `<head>` — tags render in wrong location
- Missing `<Scripts />` in body — no client-side JS, app is static HTML
- Using `<script>` tags directly — use `ScriptOnce` or `head.scripts` for proper management
- ScriptOnce modifying DOM without `suppressHydrationWarning` — causes mismatch
