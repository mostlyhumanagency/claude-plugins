---
name: authenticating-tanstack-start
description: Use when implementing authentication in TanStack Start — useSession hook for cookie sessions, route protection with beforeLoad redirect, auth middleware pattern, Clerk integration, WorkOS integration, Auth.js integration, Supabase auth, Better Auth, role-based access control RBAC, bcrypt password hashing, OAuth social login, or session management with httpOnly cookies.
---

# Authentication in TanStack Start

TanStack Start supports both hosted auth solutions and DIY implementations via server functions, middleware, and session management.

## Session Management

### useSession Hook

TanStack Start provides secure HTTP-only cookie sessions:

```tsx
import { useSession } from '@tanstack/react-start/server'

const sessionConfig = {
  password: process.env.SESSION_SECRET!,  // Min 32 characters
  cookieName: 'app-session',
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax' as const,
    maxAge: 60 * 60 * 24 * 7,  // 7 days
  },
}

type SessionData = {
  userId?: string
  role?: 'user' | 'admin'
}

const getSession = createServerFn().handler(async () => {
  const session = await useSession<SessionData>(sessionConfig)
  return session.data
})

const login = createServerFn({ method: 'POST' })
  .inputValidator(z.object({ email: z.string(), password: z.string() }))
  .handler(async ({ data }) => {
    const user = await verifyCredentials(data.email, data.password)
    if (!user) throw new Error('Invalid credentials')

    const session = await useSession<SessionData>(sessionConfig)
    await session.update({ userId: user.id, role: user.role })

    return { success: true }
  })

const logout = createServerFn({ method: 'POST' }).handler(async () => {
  const session = await useSession<SessionData>(sessionConfig)
  await session.clear()
  throw redirect({ to: '/login' })
})
```

## Route Protection

### With beforeLoad

Protect routes by checking auth in `beforeLoad`:

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async () => {
    const session = await getSession()
    if (!session.userId) {
      throw redirect({ to: '/login', search: { redirect: '/dashboard' } })
    }
  },
  component: Dashboard,
})
```

### With Auth Middleware

Create reusable auth middleware:

```tsx
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const session = await useSession<SessionData>(sessionConfig)
    if (!session.data.userId) {
      throw redirect({ to: '/login' })
    }

    const user = await db.getUser(session.data.userId)
    return next({ context: { user } })
  })
```

### Layout-Level Protection

Protect a group of routes with a pathless layout:

```tsx
// src/routes/_authenticated.tsx
export const Route = createFileRoute('/_authenticated')({
  beforeLoad: async () => {
    const session = await getSession()
    if (!session.userId) throw redirect({ to: '/login' })
  },
  component: ({ children }) => <Outlet />,
})

// src/routes/_authenticated.dashboard.tsx — auto-protected
// src/routes/_authenticated.settings.tsx — auto-protected
```

## Role-Based Access Control

```tsx
const adminMiddleware = createMiddleware({ type: 'function' })
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.user.role !== 'admin') {
      throw new Error('Forbidden: admin access required')
    }
    return next()
  })

export const deleteUser = createServerFn({ method: 'POST' })
  .middleware([adminMiddleware])
  .inputValidator(z.object({ userId: z.string() }))
  .handler(async ({ data }) => {
    await db.deleteUser(data.userId)
  })
```

## Email/Password Authentication

```tsx
import bcrypt from 'bcrypt'

const register = createServerFn({ method: 'POST' })
  .inputValidator(z.object({
    email: z.string().email(),
    password: z.string().min(8),
    name: z.string().min(1),
  }))
  .handler(async ({ data }) => {
    const existing = await db.findUserByEmail(data.email)
    if (existing) throw new Error('Email already registered')

    const hashedPassword = await bcrypt.hash(data.password, 12)
    const user = await db.createUser({
      email: data.email,
      password: hashedPassword,
      name: data.name,
    })

    const session = await useSession<SessionData>(sessionConfig)
    await session.update({ userId: user.id, role: 'user' })

    throw redirect({ to: '/dashboard' })
  })
```

## Hosted Auth Providers

### Clerk

```bash
npm install @clerk/tanstack-start
```

Clerk provides pre-built components and middleware. See the `start-clerk-basic` example template.

### Auth.js

```bash
npm install @auth/core
```

See the `start-basic-auth` example template for integration patterns.

### Supabase

```bash
npm install @supabase/supabase-js
```

See the `start-supabase-basic` example template.

### WorkOS

See the `start-workos` example template.

## Auth Context Pattern

Share auth state across the app via router context:

```tsx
// Root route
export const Route = createRootRouteWithContext<{ auth: AuthState }>()({
  beforeLoad: async () => {
    const session = await getSession()
    return { auth: { user: session.userId ? await getUser(session.userId) : null } }
  },
  component: RootComponent,
})

// Any child route
export const Route = createFileRoute('/profile')({
  component: () => {
    const { auth } = Route.useRouteContext()
    return <div>Hello, {auth.user?.name}</div>
  },
})
```

## Security Best Practices

- Use bcrypt with 12+ salt rounds for password hashing
- Set `httpOnly: true` and `secure: true` in production for cookies
- Use `sameSite: 'lax'` or `'strict'` to prevent CSRF
- Validate and sanitize all auth inputs with Zod
- Rate-limit login attempts
- Never store plain-text passwords
- Set reasonable session expiry (7-30 days)
- Regenerate session after login to prevent fixation

## Common Mistakes

- Putting auth checks in `loader` instead of `beforeLoad` — loader runs in parallel, beforeLoad is serial
- Not using `throw redirect()` — return redirect doesn't work, must throw
- Storing sensitive data in client-accessible cookies — use `httpOnly`
- Not clearing session on logout — user stays authenticated
