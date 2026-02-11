---
name: managing-environment-tanstack-start
description: Use when working with TanStack Start environment variables — VITE_ prefix for client variables, process.env for server variables, import.meta.env for client access, .env .env.local .env.production .env.development files, env.d.ts type declarations, createServerOnlyFn for secret protection, createClientOnlyFn for browser APIs, createIsomorphicFn for environment-adaptive code, execution model server vs client, or code execution patterns.
---

# Environment Variables and Execution Model

TanStack Start has a security-first environment variable system and provides APIs to control where code runs.

## Environment Variables

### Server vs Client Access

| Context | Access Method | Prefix Required | Example |
|---------|--------------|-----------------|---------|
| Server (server functions, middleware) | `process.env.VAR` | None | `process.env.DATABASE_URL` |
| Client (components, hooks) | `import.meta.env.VITE_VAR` | `VITE_` | `import.meta.env.VITE_API_URL` |

**CRITICAL**: Only `VITE_`-prefixed variables are bundled into client JavaScript. All other `process.env` variables are server-only and never exposed.

### File Loading Order

Files are loaded in this order (later overrides earlier):

1. `.env` — defaults, committed to repo
2. `.env.development` / `.env.production` — mode-specific
3. `.env.local` — local overrides, add to `.gitignore`

### Server Usage

```tsx
const dbConnect = createServerFn().handler(async () => {
  const connectionString = process.env.DATABASE_URL  // Safe — server only
  const apiKey = process.env.EXTERNAL_API_SECRET     // Safe — server only
  return await db.connect(connectionString)
})
```

### Client Usage

```tsx
function ApiProvider({ children }: { children: React.ReactNode }) {
  const apiUrl = import.meta.env.VITE_API_URL
  const publicKey = import.meta.env.VITE_PUBLIC_KEY
  return <ApiContext.Provider value={{ apiUrl, publicKey }}>{children}</ApiContext.Provider>
}
```

### TypeScript Declarations

Create `src/env.d.ts` for type safety:

```tsx
interface ImportMetaEnv {
  readonly VITE_APP_NAME: string
  readonly VITE_API_URL: string
}

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      readonly DATABASE_URL: string
      readonly JWT_SECRET: string
      readonly REDIS_URL: string
    }
  }
}

export {}
```

### Runtime Validation

Validate required variables at startup:

```tsx
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
})

// In a server function or start.ts
const env = envSchema.parse(process.env)
```

## Execution Model

All code in TanStack Start is **isomorphic by default** — it runs in both server and client bundles unless explicitly constrained.

### Server Environment (Node.js)

- Initial page rendering (SSR)
- Server function execution
- Static generation/prerendering
- File system, database, env var access

### Client Environment (Browser)

- Post-hydration interactivity
- Route loaders during client-side navigation
- DOM interactions, user events
- Browser APIs (localStorage, canvas, etc.)

### CRITICAL: Route Loaders Are Isomorphic

Loaders run on BOTH server (during SSR) and client (during client-side navigation). Do NOT put secrets in loaders:

```tsx
// WRONG — leaks DATABASE_URL to client bundle
loader: async () => {
  return db.connect(process.env.DATABASE_URL)
}

// RIGHT — use a server function
const getData = createServerFn().handler(async () => {
  return db.connect(process.env.DATABASE_URL)
})

loader: async () => {
  return getData()
}
```

## Code Execution Pattern APIs

### createServerOnlyFn — crashes on client

```tsx
import { createServerOnlyFn } from '@tanstack/react-start'

const getSecret = createServerOnlyFn(() => process.env.JWT_SECRET)
```

### createClientOnlyFn — crashes on server

```tsx
import { createClientOnlyFn } from '@tanstack/react-start'

const getLocalStorage = createClientOnlyFn(() => window.localStorage.getItem('theme'))
```

### createIsomorphicFn — different implementations per environment

```tsx
import { createIsomorphicFn } from '@tanstack/react-start'

const getStorage = createIsomorphicFn()
  .server(() => {
    // Use file-based storage on server
    return new FileStorage()
  })
  .client(() => {
    // Use localStorage on client
    return new BrowserStorage()
  })
```

### ClientOnly Component

Render only after hydration, with a server fallback:

```tsx
import { ClientOnly } from '@tanstack/react-start'

<ClientOnly fallback={<div>Loading map...</div>}>
  {() => <InteractiveMap />}
</ClientOnly>
```

### useHydrated Hook

```tsx
import { useHydrated } from '@tanstack/react-start'

function Widget() {
  const hydrated = useHydrated()
  if (!hydrated) return <Skeleton />
  return <BrowserWidget />
}
```

## Build-Time Behavior

`process.env.NODE_ENV` is statically replaced at build time in server bundles (configurable via `server.build.staticNodeEnv`). This enables tree-shaking of dev-only code.

Disable when deploying identical builds across environments:

```ts
// vite.config.ts
tanstackStart({
  server: {
    build: {
      staticNodeEnv: false,  // Keep dynamic at runtime
    },
  },
})
```

## Security Checklist

- Never use `VITE_` prefix for secrets
- Move secret operations to server functions
- Validate required variables at startup
- Keep `.env.local` in `.gitignore`
- Configure production variables on hosting platform
- Use `createServerOnlyFn` for guaranteed server-only code

## Common Mistakes

- Accessing `process.env` directly in components — exposed in client bundle
- Using `window` in loaders — breaks SSR (loaders are isomorphic)
- Prefixing secrets with `VITE_` — exposes them in client JS
- Assuming loaders are server-only — they run on both server and client
