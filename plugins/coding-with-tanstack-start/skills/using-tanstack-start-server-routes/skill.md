---
name: using-tanstack-start-server-routes
description: Use when working with TanStack Start server routes — API routes, HTTP endpoints, createFileRoute with server property, GET POST PUT DELETE handlers, request.json() request.formData(), Response.json(), route-level middleware on server routes, dynamic API route params, or building REST API endpoints alongside page routes.
---

# TanStack Start Server Routes

Server routes are HTTP endpoints defined alongside page routes in `src/routes/`. They handle API requests, webhooks, and form submissions.

## Defining Server Routes

Add a `server` property to `createFileRoute()`:

```tsx
// src/routes/api/posts.ts
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/api/posts')({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const posts = await db.getPosts()
        return Response.json(posts)
      },
      POST: async ({ request }) => {
        const body = await request.json()
        const post = await db.createPost(body)
        return Response.json(post, { status: 201 })
      },
    },
  },
})
```

## File Naming

Server routes follow the same file conventions as page routes:

| File | URL | Description |
|------|-----|-------------|
| `api/posts.ts` | `/api/posts` | Static route |
| `api/posts/$id.ts` | `/api/posts/:id` | Dynamic route |
| `api/posts/$id/comments.$commentId.ts` | `/api/posts/:id/comments/:commentId` | Nested dynamic |
| `api/file/$.ts` | `/api/file/*` | Wildcard catch-all |

**IMPORTANT**: Each path must have exactly one handler file. These cause errors:
- `api/users.index.ts` AND `api/users.ts` — duplicate
- `api/users/index.ts` AND `api/users.ts` — duplicate

## Handler Context

Each handler receives:

```tsx
handlers: {
  GET: async ({ request, params, context }) => {
    // request — incoming Request object
    // params — dynamic path parameters { id: '123' }
    // context — request context from middleware
  },
}
```

## Request Parsing

```tsx
// JSON body
const data = await request.json()

// Form data
const formData = await request.formData()
const name = formData.get('name')

// URL search params
const url = new URL(request.url)
const page = url.searchParams.get('page')

// Plain text
const text = await request.text()
```

## Response Patterns

```tsx
// JSON response
return Response.json({ posts }, { status: 200 })

// With headers
return Response.json(data, {
  status: 200,
  headers: {
    'Cache-Control': 'public, max-age=3600',
    'X-Custom-Header': 'value',
  },
})

// Empty response
return new Response(null, { status: 204 })

// Redirect
return Response.redirect('/api/v2/posts', 301)

// Plain text
return new Response('OK', { status: 200 })

// Stream
const stream = new ReadableStream({ ... })
return new Response(stream, {
  headers: { 'Content-Type': 'text/event-stream' },
})
```

## Dynamic Route Parameters

```tsx
// src/routes/api/posts/$postId.ts
export const Route = createFileRoute('/api/posts/$postId')({
  server: {
    handlers: {
      GET: async ({ params }) => {
        const post = await db.getPost(params.postId)
        if (!post) {
          return Response.json({ error: 'Not found' }, { status: 404 })
        }
        return Response.json(post)
      },
      DELETE: async ({ params }) => {
        await db.deletePost(params.postId)
        return new Response(null, { status: 204 })
      },
    },
  },
})
```

## Middleware on Server Routes

### Route-level (applies to ALL handlers)

```tsx
export const Route = createFileRoute('/api/admin/users')({
  server: {
    middleware: [authMiddleware, adminMiddleware],
    handlers: {
      GET: async ({ context }) => {
        // context.user available from middleware
        const users = await db.getUsers()
        return Response.json(users)
      },
    },
  },
})
```

### Handler-specific middleware

```tsx
export const Route = createFileRoute('/api/posts')({
  server: {
    handlers: {
      GET: async () => {
        // No auth needed for reading
        return Response.json(await db.getPosts())
      },
      POST: {
        middleware: [authMiddleware],  // Auth only for creating
        handler: async ({ context }) => {
          // ...
        },
      },
    },
  },
})
```

### Combined (route + handler)

Route-level middleware executes first, then handler-specific middleware.

## Server Routes vs Server Functions

| Feature | Server Routes | Server Functions |
|---------|--------------|-----------------|
| Definition | `createFileRoute` with `server` | `createServerFn()` |
| URL | File-path based (`/api/posts`) | Auto-generated hash |
| Methods | Full HTTP (GET, POST, PUT, DELETE, etc.) | GET or POST only |
| Response | Raw `Response` object | Serialized return value |
| Use case | REST APIs, webhooks, file downloads | RPC from components/loaders |
| Type safety | Manual request/response typing | End-to-end type safety |

## Common Mistakes

- Putting server routes in a `server/` folder — they must be in `src/routes/`
- Returning plain objects instead of `Response` — handler must return a `Response`
- Creating both page and server route at same path — use one or the other
- Forgetting to parse request body — `request.json()` is async
