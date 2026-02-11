---
name: setting-up-tanstack-start
description: Use when setting up a TanStack Start project from scratch — installing dependencies, configuring vite.config.ts with tanstackStart plugin, creating router.tsx, __root.tsx root route, package.json scripts, TypeScript tsconfig, or scaffolding with create @tanstack/start.
---

# Setting Up TanStack Start

## Scaffolding

```bash
pnpm create @tanstack/start@latest
# Options: React framework, TypeScript, file-based router
```

## From Scratch

### 1. Initialize and install

```bash
npm init -y
npm install @tanstack/react-start @tanstack/react-router react react-dom
npm install -D vite @vitejs/plugin-react typescript @types/react @types/react-dom
```

### 2. package.json

```json
{
  "type": "module",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build"
  }
}
```

### 3. tsconfig.json

```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "paths": { "~/*": ["./src/*"] }
  },
  "include": ["src"]
}
```

### 4. vite.config.ts

**CRITICAL**: `tanstackStart()` must come FIRST in the plugins array.

```ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    tanstackStart(), // Must be FIRST
    react(),
  ],
})
```

### 5. Router configuration — src/router.tsx

```tsx
import { createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

export function getRouter() {
  return createRouter({ routeTree })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
```

The `routeTree.gen.ts` file is auto-generated on first `npm run dev`.

### 6. Root route — src/routes/__root.tsx

```tsx
import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'

export const Route = createRootRoute({
  component: RootComponent,
})

function RootComponent() {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <HeadContent />
      </head>
      <body>
        <Outlet />
        <Scripts />
      </body>
    </html>
  )
}
```

- `<HeadContent />` renders meta/title tags in the `<head>`
- `<Outlet />` renders the matched child route
- `<Scripts />` loads client-side JavaScript — required for hydration

### 7. First route — src/routes/index.tsx

```tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: Home,
})

function Home() {
  return <h1>Welcome to TanStack Start</h1>
}
```

### 8. Run

```bash
npm run dev
# Opens http://localhost:3000
```

## Common Mistakes

- Putting `react()` before `tanstackStart()` in vite plugins — causes build failures
- Missing `"type": "module"` in package.json
- Forgetting `<Scripts />` in root — app renders but has no interactivity
- Forgetting `<HeadContent />` in root — meta tags and title don't render
- Trying to import `routeTree.gen` before first dev run — file doesn't exist yet
