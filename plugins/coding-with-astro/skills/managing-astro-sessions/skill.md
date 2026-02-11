---
name: managing-astro-sessions
description: "Use when storing user data across requests in Astro, implementing login sessions, or configuring session storage drivers. Use for tasks like 'add user sessions', 'store cart data between requests', 'set up session storage with Redis', or 'access session in middleware'. Also covers Astro.session get/set/regenerate/destroy, typing session data with generics, cookie-backed sessions, and accessing sessions in actions, middleware, and API endpoints."
---

# Managing Astro Sessions

Astro sessions provide server-side state management backed by pluggable storage drivers. Sessions are cookie-backed but store data on the server, not in the cookie itself. The cookie holds only a session ID.

## Configuration

Enable sessions in `astro.config.mjs` by setting the `session` option with a `driver` property:

```js
// astro.config.mjs
import { defineConfig } from "astro/config";
import node from "@astrojs/node";

export default defineConfig({
  output: "server",
  adapter: node({ mode: "standalone" }),
  session: {
    driver: "fs",
  },
});
```

The `driver` property determines where session data is stored. Astro uses the `unstorage` library under the hood, so any unstorage driver works.

### Storage Drivers

| Driver | Value | Notes |
|---|---|---|
| Filesystem | `"fs"` | Good for local development |
| Redis | `"redis"` | Requires `options.url` |
| Netlify Blobs | `"netlify-blobs"` | Auto-configured on Netlify |
| Cloudflare KV | `"cloudflare-kv-binding"` | Auto-configured on Cloudflare |
| Node (default) | `"fs-lite"` | Default for Node adapter |

Platform adapters for Cloudflare, Netlify, and Vercel auto-configure a default driver. When deploying to Node or a custom server, you must specify a driver explicitly.

### Redis Driver Example

```js
// astro.config.mjs
import { defineConfig } from "astro/config";
import node from "@astrojs/node";

export default defineConfig({
  output: "server",
  adapter: node({ mode: "standalone" }),
  session: {
    driver: "redis",
    options: {
      url: process.env.REDIS_URL,
    },
  },
});
```

### Cookie Options

Customize the session cookie alongside the driver:

```js
// astro.config.mjs
export default defineConfig({
  session: {
    driver: "redis",
    options: {
      url: process.env.REDIS_URL,
    },
    cookie: {
      name: "my-session",
      httpOnly: true,
      secure: true,
      sameSite: "lax",
      maxAge: 60 * 60 * 24 * 7, // 1 week in seconds
    },
  },
});
```

## Accessing Sessions

Sessions are available through different objects depending on context:

| Context | Access via |
|---|---|
| `.astro` pages | `Astro.session` |
| API endpoints | `context.session` |
| Actions | `context.session` |
| Middleware | `context.session` |

## Core Methods

### get

Retrieve a value from the session by key. Returns a `Promise` that resolves to the value or `undefined` if the key does not exist.

```astro
---
// src/pages/dashboard.astro
const username = await Astro.session.get("username");
const cartItems = await Astro.session.get("cartItems");
---

{username ? (
  <p>Welcome back, {username}. You have {cartItems?.length ?? 0} items in your cart.</p>
) : (
  <p>Please log in.</p>
)}
```

### set

Store a value in the session. Values must be serializable by devalue.

```astro
---
// src/pages/login.astro
export const prerender = false;

if (Astro.request.method === "POST") {
  const formData = await Astro.request.formData();
  const username = formData.get("username") as string;

  await Astro.session.set("username", username);
  await Astro.session.set("loginTime", new Date());
  await Astro.session.set("preferences", { theme: "dark", lang: "en" });

  return Astro.redirect("/dashboard");
}
---

<form method="POST">
  <input type="text" name="username" required />
  <button type="submit">Log in</button>
</form>
```

### regenerate

Create a new session ID while preserving all existing session data. Use this after authentication to prevent session fixation attacks.

```astro
---
// src/pages/api/auth/login.ts
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ request, session, redirect }) => {
  const data = await request.json();
  const user = await authenticateUser(data.email, data.password);

  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid credentials" }), {
      status: 401,
    });
  }

  // Regenerate session ID to prevent session fixation
  await session.regenerate();

  await session.set("userId", user.id);
  await session.set("role", user.role);

  return redirect("/dashboard");
};
```

### destroy

Delete all session data and invalidate the session cookie. Use this for logout flows.

```ts
// src/pages/api/auth/logout.ts
import type { APIRoute } from "astro";

export const POST: APIRoute = async ({ session, redirect }) => {
  await session.destroy();
  return redirect("/");
};
```

## TypeScript Typing

Type session data by extending the `App.SessionData` interface in `src/env.d.ts`:

```ts
// src/env.d.ts
/// <reference types="astro/client" />

declare namespace App {
  interface SessionData {
    username: string;
    userId: string;
    role: "admin" | "user" | "editor";
    loginTime: Date;
    cartItems: Array<{ productId: string; quantity: number }>;
    preferences: {
      theme: "light" | "dark";
      lang: string;
    };
  }
}
```

With this declaration, `Astro.session.get("username")` returns `Promise<string | undefined>` and `Astro.session.set("role", "admin")` is type-checked against the allowed values.

## Serialization with devalue

Session values are serialized using the `devalue` library. The following types are supported:

- `string`
- `number` (including `NaN`, `Infinity`, `-Infinity`, `-0`)
- `boolean`
- `undefined`
- `null`
- `BigInt`
- `Date`
- `RegExp`
- `Map`
- `Set`
- `URL`
- `Uint8Array` and `Uint16Array`
- Plain objects and arrays (containing the above types)

Functions, class instances, Symbols, and DOM nodes are not serializable and cannot be stored in sessions.

## Sessions in Actions

Actions receive `context.session` as part of the action handler context:

```ts
// src/actions/index.ts
import { defineAction } from "astro:actions";
import { z } from "astro:schema";

export const server = {
  addToCart: defineAction({
    input: z.object({
      productId: z.string(),
      quantity: z.number().int().positive(),
    }),
    handler: async (input, context) => {
      const cartItems = (await context.session.get("cartItems")) ?? [];

      const existingIndex = cartItems.findIndex(
        (item) => item.productId === input.productId
      );

      if (existingIndex >= 0) {
        cartItems[existingIndex].quantity += input.quantity;
      } else {
        cartItems.push({
          productId: input.productId,
          quantity: input.quantity,
        });
      }

      await context.session.set("cartItems", cartItems);

      return { cartSize: cartItems.length };
    },
  }),

  clearCart: defineAction({
    handler: async (_input, context) => {
      await context.session.set("cartItems", []);
      return { success: true };
    },
  }),
};
```

## Sessions in Middleware

Access `context.session` in middleware to implement authentication guards, session-based locale detection, or request-scoped state:

```ts
// src/middleware.ts
import { defineMiddleware } from "astro:middleware";

export const onRequest = defineMiddleware(async (context, next) => {
  const protectedPaths = ["/dashboard", "/settings", "/admin"];
  const isProtected = protectedPaths.some((path) =>
    context.url.pathname.startsWith(path)
  );

  if (isProtected) {
    const userId = await context.session.get("userId");

    if (!userId) {
      return context.redirect("/login");
    }

    // Check admin access
    if (context.url.pathname.startsWith("/admin")) {
      const role = await context.session.get("role");
      if (role !== "admin") {
        return context.redirect("/dashboard");
      }
    }
  }

  return next();
});
```

## Sessions in API Endpoints

Endpoints access sessions through `context.session`:

```ts
// src/pages/api/user/profile.ts
import type { APIRoute } from "astro";

export const GET: APIRoute = async ({ session }) => {
  const userId = await session.get("userId");

  if (!userId) {
    return new Response(JSON.stringify({ error: "Not authenticated" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const username = await session.get("username");
  const preferences = await session.get("preferences");

  return new Response(
    JSON.stringify({ userId, username, preferences }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }
  );
};

export const PUT: APIRoute = async ({ request, session }) => {
  const userId = await session.get("userId");

  if (!userId) {
    return new Response(null, { status: 401 });
  }

  const body = await request.json();

  if (body.preferences) {
    await session.set("preferences", body.preferences);
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
```

## Sessions in Pages

Use `Astro.session` in the frontmatter of any server-rendered page:

```astro
---
// src/pages/cart.astro
export const prerender = false;

const cartItems = (await Astro.session.get("cartItems")) ?? [];
const username = await Astro.session.get("username");
---

<html>
  <head><title>Shopping Cart</title></head>
  <body>
    <h1>Cart for {username ?? "Guest"}</h1>
    {cartItems.length === 0 ? (
      <p>Your cart is empty.</p>
    ) : (
      <ul>
        {cartItems.map((item) => (
          <li>
            Product: {item.productId} -- Qty: {item.quantity}
          </li>
        ))}
      </ul>
    )}
  </body>
</html>
```

## Edge Middleware Limitation

Sessions are not available in edge middleware environments. Edge runtimes (such as Cloudflare Workers in edge mode or Vercel Edge Functions) do not support the full session API because they cannot access persistent storage drivers synchronously. If your middleware runs at the edge, you must handle authentication through other mechanisms such as JWTs in cookies or headers.

## Common Pitfalls

1. **Sessions require server rendering.** Pages using `Astro.session` must have `export const prerender = false` or be in a project with `output: "server"`. Sessions are not available during static builds.

2. **Always await session methods.** `get`, `set`, `regenerate`, and `destroy` are all asynchronous. Forgetting `await` leads to silent failures where data is not read or persisted.

3. **Regenerate after authentication.** Always call `session.regenerate()` after a user logs in to prevent session fixation vulnerabilities. This creates a new session ID while keeping the data intact.

4. **Values must be devalue-serializable.** Storing functions, class instances, or other non-serializable types throws a runtime error. Stick to plain objects, arrays, and the supported primitive types.

5. **Session storage must be configured for production.** The default filesystem driver does not persist across deployments or scale across multiple server instances. Use Redis, a database-backed driver, or a platform-specific driver for production.

6. **No session access in static pages.** Attempting to call `Astro.session.get()` in a prerendered page results in an error at build time. Guard session access behind `prerender = false`.
