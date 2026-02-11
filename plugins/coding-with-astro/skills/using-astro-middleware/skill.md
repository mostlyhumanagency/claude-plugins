---
name: using-astro-middleware
description: Use when intercepting requests and responses in Astro — the onRequest function in src/middleware.ts, context.locals for sharing data, sequence() for chaining middleware, defineMiddleware for TypeScript, rewrites with context.rewrite(), response manipulation, or cookie/header access in on-demand routes.
---

## Overview

Astro middleware intercepts every request and response flowing through the application. It runs via a single `onRequest` function exported from `src/middleware.ts`. Middleware can read/modify requests before they reach pages, share data across the request lifecycle through `context.locals`, manipulate responses after rendering, rewrite routes, and chain multiple handlers with `sequence()`.

## File Location

Middleware lives in exactly one of two places:

- `src/middleware.ts` (or `.js`)
- `src/middleware/index.ts` (or `.js`)

Only one middleware entry point is allowed per project. The file must export a named `onRequest` function (not a default export).

## The onRequest Function

The middleware entry point receives two arguments: the request context and a `next` function that continues the pipeline.

```typescript
// src/middleware.ts
export function onRequest(context, next) {
  // Run code before the page renders
  console.log(`Incoming: ${context.url.pathname}`);

  // Continue to the next middleware or page handler
  return next();
}
```

The `context` object exposes `url`, `request`, `locals`, `cookies`, `rewrite()`, and other request-scoped data. The `next()` function returns a `Promise<Response>` representing the rendered page.

You must always call `next()` and return its result (or return your own `Response`). Failing to do so will hang the request.

## context.locals -- Sharing Data

`context.locals` is a mutable object scoped to a single request. Write to it in middleware; read from it in pages, layouts, API routes, and components via `Astro.locals`.

```typescript
// src/middleware.ts
export function onRequest(context, next) {
  context.locals.user = { id: 42, name: "Alice" };
  context.locals.requestedAt = Date.now();
  return next();
}
```

```astro
---
// src/pages/dashboard.astro
const { user, requestedAt } = Astro.locals;
---
<h1>Welcome, {user.name}</h1>
<p>Request received at {new Date(requestedAt).toISOString()}</p>
```

Rules for `context.locals`:

- You can set and mutate properties on it, but you cannot reassign the object itself (`context.locals = { ... }` will not work).
- Values are isolated per request. Concurrent requests never share locals.
- You can store any value: primitives, objects, functions, class instances.

### Accessing locals in API endpoints

```typescript
// src/pages/api/user.ts
import type { APIRoute } from "astro";

export const GET: APIRoute = (context) => {
  const { user } = context.locals;
  return new Response(JSON.stringify(user), {
    headers: { "Content-Type": "application/json" },
  });
};
```

## Type Safety

### defineMiddleware

Use `defineMiddleware` from `astro:middleware` for full type inference on `context` and `next`.

```typescript
// src/middleware.ts
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  // context is fully typed: context.url, context.locals, context.cookies, etc.
  context.locals.user = { id: 1, role: "admin" };
  return next();
});
```

### Typing context.locals with App.Locals

Declare the shape of `locals` globally so that both middleware and pages share the same types.

```typescript
// src/env.d.ts
/// <reference types="astro/client" />

declare namespace App {
  interface Locals {
    user: {
      id: number;
      role: "admin" | "user" | "guest";
    };
    requestId: string;
    session?: import("./lib/session").Session;
  }
}
```

After declaring this, `Astro.locals.user` and `context.locals.user` are both typed automatically.

## Chaining Middleware with sequence()

When middleware logic grows, split it into separate functions and combine them with `sequence()`.

```typescript
// src/middleware.ts
import { defineMiddleware, sequence } from "astro:middleware";

const auth = defineMiddleware(async (context, next) => {
  const token = context.cookies.get("session")?.value;
  if (token) {
    context.locals.user = await verifyToken(token);
  } else {
    context.locals.user = { id: 0, role: "guest" };
  }
  return next();
});

const logging = defineMiddleware(async (context, next) => {
  const start = performance.now();
  const response = await next();
  const duration = performance.now() - start;
  console.log(`${context.request.method} ${context.url.pathname} ${response.status} ${duration.toFixed(1)}ms`);
  return response;
});

const guard = defineMiddleware((context, next) => {
  if (context.url.pathname.startsWith("/admin") && context.locals.user.role !== "admin") {
    return new Response("Forbidden", { status: 403 });
  }
  return next();
});

export const onRequest = sequence(auth, logging, guard);
```

Execution order follows the array order: `auth` runs first, then `logging`, then `guard`. Response handling flows back in reverse order (like an onion model).

## Response Manipulation

Await `next()` to get the rendered response, then read, modify, or replace it.

### Modifying HTML content

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware(async (context, next) => {
  const response = await next();

  // Only modify HTML responses
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("text/html")) {
    return response;
  }

  const html = await response.text();
  const modified = html.replace(
    "</head>",
    `<script>window.__REQUEST_ID="${crypto.randomUUID()}";</script></head>`
  );

  return new Response(modified, {
    status: response.status,
    headers: response.headers,
  });
});
```

### Adding response headers

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware(async (context, next) => {
  const response = await next();
  response.headers.set("X-Request-Id", crypto.randomUUID());
  response.headers.set("X-Powered-By", "Astro");
  return response;
});
```

### Short-circuiting with a custom response

Return your own `Response` without calling `next()` to skip rendering entirely.

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  if (context.url.pathname === "/healthz") {
    return new Response("OK", { status: 200 });
  }
  return next();
});
```

## Rewrites

Rewrites serve a different route's content without changing the URL in the browser.

### context.rewrite() -- with re-execution

`context.rewrite()` triggers a full re-execution of the middleware chain and page rendering for the target route. Use this when you need the rewritten route to see updated headers or context.

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  if (context.url.pathname === "/old-page") {
    // Reruns the full middleware chain for /new-page
    return context.rewrite("/new-page");
  }
  return next();
});
```

You can pass a string path, a URL, or a `Request` object with custom headers:

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  if (!isAuthenticated(context)) {
    return context.rewrite(
      new Request("/login", {
        headers: {
          "x-redirect-from": context.url.pathname,
        },
      })
    );
  }
  return next();
});
```

### next() with a new Request -- without re-execution

Pass a path or `Request` to `next()` to rewrite without re-running earlier middleware in the chain. The current middleware's `next` skips straight to the target route's rendering.

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  if (context.url.pathname === "/old-page") {
    // Renders /new-page content but does NOT re-run middleware
    return next("/new-page");
  }
  return next();
});
```

### Rewrite constraints

- Do not consume `Request.body` before or after a rewrite; doing so throws a runtime error.
- For rewrites triggered by Astro Actions in HTML forms, use `Astro.rewrite()` in the page template instead of middleware.

## Cookies and Headers (On-Demand Routes Only)

Cookies and dynamic headers are only available on server-rendered (on-demand) routes. For prerendered (static) pages, cookies are not accessible at request time because the page was built at build time.

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware(async (context, next) => {
  // Read a cookie
  const theme = context.cookies.get("theme")?.value ?? "light";
  context.locals.theme = theme;

  const response = await next();

  // Set a cookie (only works on on-demand routes)
  context.cookies.set("last-visited", context.url.pathname, {
    path: "/",
    maxAge: 60 * 60 * 24 * 7, // 1 week
  });

  return response;
});
```

Reading request headers:

```typescript
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware((context, next) => {
  const lang = context.request.headers.get("accept-language") ?? "en";
  context.locals.preferredLanguage = lang.split(",")[0];
  return next();
});
```

## Error Page Behavior (404 and 500)

Middleware attempts to run for 404 and 500 error pages, but behavior depends on the adapter:

- For **prerendered** 404/500 pages, middleware runs at build time, not at request time.
- For **on-demand** 404/500 pages, middleware runs normally when the error occurs.
- If middleware itself throws an error, `Astro.locals` becomes unavailable during error page rendering. Guard against this in error page templates:

```astro
---
// src/pages/500.astro
const user = Astro.locals?.user;
---
<h1>Something went wrong</h1>
{user && <p>Logged in as {user.name}</p>}
```

## Build Time vs. Runtime Behavior

| Route type | When middleware runs | Cookies/headers available | Dynamic context |
|---|---|---|---|
| Prerendered (static) | At build time (`astro build`) | No | No |
| On-demand (SSR) | At each request | Yes | Yes |
| Hybrid (default static, some on-demand) | Build time for static; request time for on-demand | Only on on-demand routes | Only on on-demand routes |

For prerendered routes, middleware runs once during the build. Any values set in `locals` are baked into the static HTML. Dynamic features like cookies, headers, and request-specific data only work on on-demand routes (those with `export const prerender = false` or in a fully SSR project).

## Complete Example: Auth + Logging + Route Protection

```typescript
// src/middleware.ts
import { defineMiddleware, sequence } from "astro:middleware";
import { verifyJwt } from "./lib/auth";

const PUBLIC_PATHS = ["/", "/login", "/signup", "/api/health"];

const authenticate = defineMiddleware(async (context, next) => {
  const token = context.cookies.get("auth-token")?.value;

  if (token) {
    try {
      context.locals.user = await verifyJwt(token);
    } catch {
      context.locals.user = null;
      context.cookies.delete("auth-token", { path: "/" });
    }
  } else {
    context.locals.user = null;
  }

  return next();
});

const protect = defineMiddleware((context, next) => {
  const isPublic = PUBLIC_PATHS.some((p) => context.url.pathname === p);
  const isApi = context.url.pathname.startsWith("/api/");

  if (!isPublic && !isApi && !context.locals.user) {
    return context.rewrite(
      new Request("/login", {
        headers: { "x-redirect-to": context.url.pathname },
      })
    );
  }

  return next();
});

const requestLogger = defineMiddleware(async (context, next) => {
  const id = crypto.randomUUID().slice(0, 8);
  context.locals.requestId = id;

  const response = await next();
  response.headers.set("X-Request-Id", id);

  console.log(
    JSON.stringify({
      id,
      method: context.request.method,
      path: context.url.pathname,
      status: response.status,
      user: context.locals.user?.id ?? "anonymous",
    })
  );

  return response;
});

export const onRequest = sequence(authenticate, protect, requestLogger);
```

```typescript
// src/env.d.ts
/// <reference types="astro/client" />

declare namespace App {
  interface Locals {
    user: { id: number; email: string; role: string } | null;
    requestId: string;
  }
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting to return `next()` | Always `return next()` or return your own `Response` |
| Reassigning `context.locals = { ... }` | Mutate properties instead: `context.locals.key = value` |
| Reading cookies on prerendered routes | Cookies are only available on on-demand rendered routes |
| Consuming `Request.body` before a rewrite | Do not read the body if you plan to rewrite |
| Using default export | Must use named export: `export function onRequest` or `export const onRequest` |
| Creating multiple middleware files | Only one entry point is allowed (`src/middleware.ts` or `src/middleware/index.ts`) |
| Expecting middleware to re-run on static 404 | Prerendered error pages run middleware at build time only |
