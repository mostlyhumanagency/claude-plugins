---
name: using-server-functions
description: Use when working with TanStack Start server functions — createServerFn, server-side RPC, GET and POST methods, inputValidator with Zod schema validation, FormData handling, calling server functions from loaders or components, useServerFn hook, file organization with .functions.ts and .server.ts, getRequest getRequestHeader setResponseHeaders, redirect and notFound from server functions, streaming responses, or progressive enhancement with .url property.
---

# TanStack Start Server Functions

Server functions are server-only logic callable from anywhere in your app. Created with `createServerFn()`, they provide type-safe RPC from client to server.

## Creating Server Functions

```tsx
import { createServerFn } from '@tanstack/react-start'

// GET (default) — used for data fetching
export const getPosts = createServerFn().handler(async () => {
  const posts = await db.query('SELECT * FROM posts')
  return posts
})

// POST — used for mutations
export const createPost = createServerFn({ method: 'POST' }).handler(async () => {
  await db.query('INSERT INTO posts ...')
  return { success: true }
})
```

## Input Validation

### Basic validation

```tsx
export const greetUser = createServerFn({ method: 'GET' })
  .inputValidator((data: { name: string }) => data)
  .handler(async ({ data }) => {
    return `Hello, ${data.name}!`
  })

// Call
const greeting = await greetUser({ data: { name: 'World' } })
```

### Zod validation

```tsx
import { z } from 'zod'

const CreatePostSchema = z.object({
  title: z.string().min(1),
  body: z.string().min(10),
  tags: z.array(z.string()).optional(),
})

export const createPost = createServerFn({ method: 'POST' })
  .inputValidator(CreatePostSchema)
  .handler(async ({ data }) => {
    // data is fully typed as { title: string; body: string; tags?: string[] }
    const post = await db.insert('posts', data)
    return post
  })
```

### FormData handling

```tsx
export const submitForm = createServerFn({ method: 'POST' })
  .inputValidator((data) => {
    if (!(data instanceof FormData)) throw new Error('Expected FormData')
    return {
      name: data.get('name')?.toString() || '',
      email: data.get('email')?.toString() || '',
    }
  })
  .handler(async ({ data }) => {
    await saveContact(data)
    return { success: true }
  })
```

## Calling Server Functions

### From route loaders (most common)

```tsx
export const Route = createFileRoute('/posts')({
  loader: async () => {
    const posts = await getPosts()
    return { posts }
  },
})
```

### From components with useServerFn

```tsx
import { useServerFn } from '@tanstack/react-start'

function CreatePostForm() {
  const createPostFn = useServerFn(createPost)

  const handleSubmit = async (formData: FormData) => {
    const result = await createPostFn({
      data: { title: formData.get('title') as string, body: formData.get('body') as string },
    })
  }

  return <form onSubmit={...}>...</form>
}
```

### From event handlers

```tsx
function DeleteButton({ postId }: { postId: string }) {
  const router = useRouter()

  const handleDelete = async () => {
    await deletePost({ data: { id: postId } })
    await router.invalidate({ sync: true })
  }

  return <button onClick={handleDelete}>Delete</button>
}
```

## Error Handling and Navigation

### Redirects

```tsx
import { redirect } from '@tanstack/react-router'

export const requireAuth = createServerFn().handler(async () => {
  const user = await getCurrentUser()
  if (!user) throw redirect({ to: '/login' })
  return user
})
```

### Not Found

```tsx
import { notFound } from '@tanstack/react-router'

export const getPost = createServerFn()
  .inputValidator((data: { id: string }) => data)
  .handler(async ({ data }) => {
    const post = await db.findPost(data.id)
    if (!post) throw notFound()
    return post
  })
```

## Server Context Utilities

Access request/response metadata within handlers:

```tsx
import {
  getRequest,
  getRequestHeader,
  setResponseHeader,
  setResponseHeaders,
  setResponseStatus,
} from '@tanstack/react-start/server'

export const getCachedData = createServerFn({ method: 'GET' }).handler(async () => {
  const authHeader = getRequestHeader('Authorization')

  setResponseHeaders(new Headers({
    'Cache-Control': 'public, max-age=300',
  }))
  setResponseStatus(200)

  return fetchData()
})
```

## File Organization

Recommended pattern for scalable codebases:

| File suffix | Purpose | Safe to import on client? |
|-------------|---------|--------------------------|
| `.functions.ts` | Export `createServerFn` wrappers | Yes — build replaces with RPC stubs |
| `.server.ts` | Server-only helpers, DB queries | No — server-only |
| `.ts` (no suffix) | Types, schemas, constants | Yes |

```
src/
  features/
    posts/
      posts.functions.ts   # createServerFn exports
      posts.server.ts      # DB queries, internal logic
      posts.types.ts       # Shared types/schemas
```

## Progressive Enhancement

Server functions have a `.url` property for use with HTML forms that work without JS:

```tsx
<form method="POST" action={submitForm.url}>
  <input name="name" />
  <button type="submit">Submit</button>
</form>
```

## Middleware Integration

```tsx
export const protectedFn = createServerFn({ method: 'POST' })
  .middleware([authMiddleware])
  .inputValidator(schema)
  .handler(async ({ data, context }) => {
    // context.user is available from auth middleware
  })
```

## Common Mistakes

- Importing `.server.ts` files in client code — causes build errors or leaks server code
- Forgetting `{ data: ... }` wrapper when calling server functions — data must be passed in `data` property
- Using `GET` method for mutations — use `POST` for write operations
- Not invalidating router after mutations — UI shows stale data
