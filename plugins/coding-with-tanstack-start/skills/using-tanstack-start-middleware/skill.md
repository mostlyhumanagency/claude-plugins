---
name: using-tanstack-start-middleware
description: Use when working with TanStack Start middleware — createMiddleware, request middleware vs server function middleware, middleware chaining with .middleware([]), context sharing with next({ context }), sendContext for client-to-server data, global middleware in start.ts with createStart, authentication middleware pattern, input validation in middleware, or header modification in middleware.
---

# TanStack Start Middleware

Middleware customizes server request behavior and server function execution through composable, chainable operations.

## Two Middleware Types

### Request Middleware

Handles ALL server requests (routes, SSR, functions). Has `.server()` only.

```tsx
import { createMiddleware } from '@tanstack/react-start'

const loggingMiddleware = createMiddleware().server(async ({ next }) => {
  const start = Date.now()
  const result = await next()
  console.log(`Request took ${Date.now() - start}ms`)
  return result
})
```

### Server Function Middleware

Specialized for server functions. Has `.client()`, `.server()`, and `.inputValidator()`.

```tsx
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const user = await getUser()
    if (!user) throw redirect({ to: '/login' })
    return next({ context: { user } })
  })
```

## Context Sharing

Pass data down the middleware chain and to handlers via `next({ context })`:

```tsx
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const session = await getSession()
    if (!session) throw redirect({ to: '/login' })

    return next({
      context: {
        user: session.user,
        permissions: session.permissions,
      },
    })
  })

// Use in server function
export const getProfile = createServerFn()
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    // context.user and context.permissions are typed and available
    return db.getProfile(context.user.id)
  })
```

## Chaining Middleware

Compose middleware by declaring dependencies:

```tsx
const loggingMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    console.log('Request started')
    const result = await next()
    console.log('Request completed')
    return result
  })

const authMiddleware = createMiddleware({ type: 'function' })
  .middleware([loggingMiddleware])  // Depends on logging
  .server(async ({ next }) => {
    const user = await getUser()
    if (!user) throw redirect({ to: '/login' })
    return next({ context: { user } })
  })

// authMiddleware automatically runs loggingMiddleware first
```

## Client-Side Middleware

Server function middleware can run logic on the client before/after the server call:

```tsx
const optimisticMiddleware = createMiddleware({ type: 'function' })
  .client(async ({ next }) => {
    // Runs on client BEFORE server call
    showLoadingSpinner()
    const result = await next()
    // Runs on client AFTER server call
    hideLoadingSpinner()
    return result
  })
  .server(async ({ next }) => {
    return next()
  })
```

## sendContext — Client to Server Data

Pass validated data from client middleware to server middleware:

```tsx
const timezoneMiddleware = createMiddleware({ type: 'function' })
  .client(async ({ next }) => {
    return next({
      sendContext: {
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      },
    })
  })
  .server(async ({ next, sendContext }) => {
    // sendContext.timezone is available
    return next({ context: { timezone: sendContext.timezone } })
  })
```

## Input Validation in Middleware

```tsx
const validatedMiddleware = createMiddleware({ type: 'function' })
  .inputValidator(z.object({ userId: z.string().uuid() }))
  .server(async ({ next, data }) => {
    // data is validated { userId: string }
    return next()
  })
```

## Header Modification

```tsx
const corsMiddleware = createMiddleware()
  .server(async ({ next }) => {
    return next({
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
    })
  })
```

## Global Middleware

Apply middleware to all requests/functions via `src/start.ts`:

```tsx
// src/start.ts
import { createStart } from '@tanstack/react-start'

export const startInstance = createStart(() => ({
  requestMiddleware: [loggingMiddleware, corsMiddleware],
  functionMiddleware: [authMiddleware],
}))
```

## Execution Order

Middleware executes dependency-first:
1. Global request middleware
2. Global function middleware
3. Function-specific middleware (in dependency order)
4. Handler

Calling `next()` passes control to the next middleware. Returning early (without calling `next()`) short-circuits the chain.

## Authentication Middleware Pattern

```tsx
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const session = await getSession()
    if (!session) throw redirect({ to: '/login' })

    return next({
      context: { user: session.user },
    })
  })

const adminMiddleware = createMiddleware({ type: 'function' })
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.user.role !== 'admin') {
      throw new Error('Unauthorized')
    }
    return next()
  })

// Usage
export const deleteUser = createServerFn({ method: 'POST' })
  .middleware([adminMiddleware])  // Includes auth check automatically
  .inputValidator(z.object({ userId: z.string() }))
  .handler(async ({ data, context }) => {
    await db.deleteUser(data.userId)
  })
```

## Common Mistakes

- Using `type: 'function'` middleware on server routes — function middleware only works with `createServerFn`
- Forgetting to call `next()` — the chain stops and no response is returned
- Not returning the result of `next()` — downstream context/data is lost
- Putting auth checks in request middleware when they need function-specific context
