---
name: rendering-astro-on-demand
description: "Use when enabling SSR or server-side rendering in Astro, installing a deployment adapter, or switching pages between static and on-demand rendering. Use for tasks like 'set up SSR in Astro', 'deploy Astro to Vercel/Netlify/Cloudflare', 'make a page server-rendered', 'read cookies or headers at request time', or 'fix adapter configuration errors'. Also covers prerender export, output server/hybrid modes, Node/Netlify/Vercel/Cloudflare adapters, response status codes, and HTML streaming."
---

# On-Demand / Server-Side Rendering in Astro

## Overview

Astro renders pages statically at build time by default. On-demand rendering (also called server-side rendering or SSR) generates pages on each request, enabling dynamic content, authentication, personalization, and API-driven data. To use on-demand rendering you need a server adapter and must opt pages into server rendering either individually or globally.

## When to Use On-Demand Rendering

- Pages that display user-specific or session-dependent content (dashboards, profiles)
- Pages that depend on data that changes frequently and cannot be rebuilt on every change
- Routes that require reading cookies, headers, or query parameters at request time
- Protected routes that check authentication before serving content
- E-commerce pages with real-time inventory or pricing
- Form submissions that need server-side validation and processing

## When to Use Static Rendering Instead

- Content sites (blogs, docs, marketing pages) where content changes infrequently
- Pages where build-time data fetching is sufficient
- Sites that benefit from CDN edge caching without server infrastructure
- Pages that are the same for every visitor

## Performance Trade-offs

| Aspect | Static (prerendered) | On-demand (SSR) |
|---|---|---|
| Time to First Byte | Fast (served from CDN) | Slower (computed per request) |
| Server cost | None after build | Ongoing compute cost |
| Data freshness | Stale until rebuild | Always fresh |
| Personalization | Not possible | Fully supported |
| Scaling | CDN handles scale | Requires server scaling |

Prefer static rendering for any page that does not truly need per-request data. You can mix both modes in the same project.

## Adapters

An adapter connects Astro to a server runtime. You must install one before using on-demand rendering.

### Installing an Adapter

Use `npx astro add` for automatic installation and configuration:

```bash
# Node.js (Express/standalone)
npx astro add node

# Netlify
npx astro add netlify

# Vercel
npx astro add vercel

# Cloudflare
npx astro add cloudflare
```

This installs the adapter package and adds it to `astro.config.mjs` automatically.

### Manual Installation

If you prefer manual setup:

```bash
npm install @astrojs/node
```

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  adapter: node({
    mode: 'standalone', // or 'middleware'
  }),
});
```

### Adapter-Specific Considerations

**Node.js (`@astrojs/node`)**
- Two modes: `standalone` (runs its own HTTP server) and `middleware` (exports a handler for Express, Fastify, etc.)
- Standalone mode listens on `HOST` and `PORT` environment variables (defaults to `localhost:4321`)
- Use `middleware` mode when integrating into an existing Node server

```js
// astro.config.mjs -- middleware mode with Express
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  adapter: node({ mode: 'middleware' }),
});
```

```js
// server.mjs -- Express integration
import express from 'express';
import { handler as ssrHandler } from './dist/server/entry.mjs';

const app = express();
app.use(express.static('dist/client/'));
app.use(ssrHandler);
app.listen(3000);
```

**Netlify (`@astrojs/netlify`)**
- Deploys as Netlify Functions or Edge Functions
- Supports Netlify-specific features like image CDN
- Environment variables are read from Netlify dashboard or `netlify.toml`

**Vercel (`@astrojs/vercel`)**
- Deploys as Vercel Serverless Functions or Edge Functions
- Supports Vercel Image Optimization, ISR, and edge middleware
- Configure ISR (Incremental Static Regeneration) for cached SSR responses

**Cloudflare (`@astrojs/cloudflare`)**
- Runs on Cloudflare Workers / Pages
- Access Cloudflare bindings (KV, D1, R2) via `Astro.locals.runtime.env`
- Does not support Node.js built-in modules -- use Cloudflare-compatible alternatives

## Enabling On-Demand Rendering

### Per-Page: Hybrid Mode (Default Behavior)

By default Astro prerenders all pages. To make a specific page render on demand, add the `prerender` export set to `false` in the page frontmatter:

```astro
---
// src/pages/dashboard.astro
export const prerender = false;

const user = await getUser(Astro.cookies.get('session')?.value);
---
<html>
  <body>
    <h1>Welcome, {user.name}</h1>
  </body>
</html>
```

All other pages remain statically prerendered. This is the recommended approach when most pages are static and only a few need server rendering.

### Global: Server Output Mode

To make all pages render on demand by default, set `output: 'server'` in the Astro config:

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  output: 'server',
  adapter: node({ mode: 'standalone' }),
});
```

In server mode, individual pages can opt into prerendering:

```astro
---
// src/pages/about.astro
export const prerender = true;
---
<html>
  <body>
    <h1>About Us</h1>
    <p>This page is statically generated at build time.</p>
  </body>
</html>
```

## Cookies

The `Astro.cookies` object provides methods for reading and writing HTTP cookies in on-demand rendered pages.

### Checking for a Cookie

```astro
---
export const prerender = false;

if (!Astro.cookies.has('session')) {
  return Astro.redirect('/login');
}
---
```

### Reading a Cookie

```astro
---
export const prerender = false;

const sessionCookie = Astro.cookies.get('session');

// .value returns the raw string
const sessionId = sessionCookie?.value;

// .json() parses the cookie value as JSON
const preferences = Astro.cookies.get('prefs')?.json();

// .number() parses the cookie value as a number
const visits = Astro.cookies.get('visits')?.number();

// .boolean() parses the cookie value as a boolean
const darkMode = Astro.cookies.get('darkMode')?.boolean();
---
```

### Setting a Cookie

```astro
---
export const prerender = false;

Astro.cookies.set('session', newSessionId, {
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  path: '/',
  maxAge: 60 * 60 * 24 * 7, // 1 week
});
---
```

### Deleting a Cookie

```astro
---
export const prerender = false;

Astro.cookies.delete('session', {
  path: '/',
});
---
```

## Request Object

Access the incoming HTTP request through `Astro.request`, which is a standard Web `Request` object.

### Reading Request Headers

```astro
---
export const prerender = false;

const authHeader = Astro.request.headers.get('authorization');
const contentType = Astro.request.headers.get('content-type');
const userAgent = Astro.request.headers.get('user-agent');
---
```

### Reading the HTTP Method

```astro
---
export const prerender = false;

if (Astro.request.method === 'POST') {
  const formData = await Astro.request.formData();
  const email = formData.get('email');
  // process form submission
}
---
<html>
  <body>
    <form method="POST">
      <input type="email" name="email" required />
      <button type="submit">Subscribe</button>
    </form>
  </body>
</html>
```

### Reading the Request URL

```astro
---
export const prerender = false;

const url = new URL(Astro.request.url);
const searchQuery = url.searchParams.get('q');
const page = url.searchParams.get('page') ?? '1';
---
```

## Response Object

Use `Astro.response` to configure the outgoing HTTP response headers and status.

### Setting Status Code and Status Text

```astro
---
export const prerender = false;

const product = await getProduct(Astro.params.id);

if (!product) {
  Astro.response.status = 404;
  Astro.response.statusText = 'Product not found';
}
---
<html>
  <body>
    {product ? (
      <h1>{product.name}</h1>
    ) : (
      <h1>Product Not Found</h1>
    )}
  </body>
</html>
```

### Setting Response Headers

```astro
---
export const prerender = false;

// Cache the response for 60 seconds, allow stale-while-revalidate for 600 seconds
Astro.response.headers.set('Cache-Control', 'public, max-age=60, s-maxage=600, stale-while-revalidate=600');

// Set a custom header
Astro.response.headers.set('X-Custom-Header', 'my-value');
---
```

### Returning a Response Directly

From any `.astro` page or API endpoint, you can return a `Response` object directly to bypass Astro's template rendering:

```astro
---
export const prerender = false;

const session = Astro.cookies.get('session')?.value;

if (!session) {
  return new Response('Unauthorized', {
    status: 401,
    headers: {
      'WWW-Authenticate': 'Bearer',
    },
  });
}
---
```

Returning JSON from an `.astro` page (though API endpoints in `src/pages/api/` are usually preferred for this):

```astro
---
export const prerender = false;

const data = await fetchData();

return new Response(JSON.stringify(data), {
  status: 200,
  headers: {
    'Content-Type': 'application/json',
  },
});
---
```

## Redirects

Use `Astro.redirect()` to redirect the user to another page. This returns a `Response` object with a 302 status by default.

```astro
---
export const prerender = false;

const isLoggedIn = await checkAuth(Astro.cookies.get('session')?.value);

if (!isLoggedIn) {
  return Astro.redirect('/login');
}

// Redirect with a specific status code (301 permanent redirect)
// return Astro.redirect('/new-location', 301);
---
```

## HTML Streaming

Astro streams HTML to the browser by default in on-demand rendered pages. The browser receives and renders HTML as it is generated, without waiting for the full page to be ready. This improves perceived performance, especially for pages with slow data fetches.

### Ordering Content for Streaming

Place slow data fetches lower in the template so the browser can display the page shell while waiting:

```astro
---
export const prerender = false;

// Fast data -- fetched first
const user = await getUser(Astro.cookies.get('session')?.value);
---
<html>
  <body>
    <header>Welcome, {user.name}</header>
    <nav><!-- navigation renders immediately --></nav>

    {async () => {
      // Slow data -- streamed in later
      const recommendations = await getRecommendations(user.id);
      return (
        <section>
          {recommendations.map(item => <div>{item.title}</div>)}
        </section>
      );
    }}
  </body>
</html>
```

### Disabling Streaming

If your adapter or deployment target does not support streaming, or if you need the complete HTML before sending (for example to calculate `Content-Length`), you can disable streaming in the config:

```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  adapter: node({ mode: 'standalone' }),
  server: {
    streaming: false,
  },
});
```

## Dynamic Routes Without getStaticPaths

In static mode, dynamic routes (files like `src/pages/[slug].astro`) require `getStaticPaths()` to define all possible parameter values at build time. In on-demand rendering mode, `getStaticPaths()` is not needed because the route parameters are resolved from the incoming request URL at runtime.

```astro
---
// src/pages/products/[id].astro
export const prerender = false;

const { id } = Astro.params;
const product = await db.products.findById(id);

if (!product) {
  return new Response('Not Found', { status: 404 });
}
---
<html>
  <body>
    <h1>{product.name}</h1>
    <p>{product.description}</p>
    <span>${product.price}</span>
  </body>
</html>
```

Rest parameters also work without `getStaticPaths`:

```astro
---
// src/pages/docs/[...path].astro
export const prerender = false;

const { path } = Astro.params;
// path = "guides/getting-started" for /docs/guides/getting-started
const doc = await loadDoc(path);
---
```

## Complete Example: Authenticated Dashboard

A full example combining multiple on-demand rendering features:

```astro
---
// src/pages/dashboard.astro
export const prerender = false;

// Check authentication via cookie
const sessionId = Astro.cookies.get('session')?.value;
if (!sessionId) {
  return Astro.redirect('/login');
}

const user = await getUser(sessionId);
if (!user) {
  Astro.cookies.delete('session', { path: '/' });
  return Astro.redirect('/login');
}

// Handle POST requests (e.g., updating preferences)
if (Astro.request.method === 'POST') {
  const formData = await Astro.request.formData();
  const theme = formData.get('theme');
  await updatePreferences(user.id, { theme });
  Astro.cookies.set('prefs', JSON.stringify({ theme }), {
    path: '/',
    maxAge: 60 * 60 * 24 * 365,
  });
  return Astro.redirect('/dashboard');
}

// Read preferences from cookie
const prefs = Astro.cookies.get('prefs')?.json() ?? { theme: 'light' };

// Set cache headers -- private because content is user-specific
Astro.response.headers.set('Cache-Control', 'private, no-cache');

const stats = await getUserStats(user.id);
---
<html>
  <body>
    <h1>Dashboard</h1>
    <p>Hello, {user.name}</p>
    <p>Total orders: {stats.orderCount}</p>

    <form method="POST">
      <label>
        Theme:
        <select name="theme">
          <option value="light" selected={prefs.theme === 'light'}>Light</option>
          <option value="dark" selected={prefs.theme === 'dark'}>Dark</option>
        </select>
      </label>
      <button type="submit">Save</button>
    </form>
  </body>
</html>
```

## Quick Reference

| Feature | API |
|---|---|
| Opt page into SSR | `export const prerender = false` |
| Opt page into static (in server mode) | `export const prerender = true` |
| All pages on-demand | `output: 'server'` in config |
| Check cookie exists | `Astro.cookies.has('name')` |
| Read cookie | `Astro.cookies.get('name')?.value` |
| Parse cookie as JSON | `Astro.cookies.get('name')?.json()` |
| Set cookie | `Astro.cookies.set('name', value, options)` |
| Delete cookie | `Astro.cookies.delete('name', options)` |
| Read request header | `Astro.request.headers.get('header')` |
| Read HTTP method | `Astro.request.method` |
| Read URL / query params | `new URL(Astro.request.url).searchParams` |
| Set response status | `Astro.response.status = 404` |
| Set response header | `Astro.response.headers.set('key', 'val')` |
| Return raw Response | `return new Response(body, options)` |
| Redirect | `return Astro.redirect(url, status?)` |
| Dynamic route param | `Astro.params.paramName` |
