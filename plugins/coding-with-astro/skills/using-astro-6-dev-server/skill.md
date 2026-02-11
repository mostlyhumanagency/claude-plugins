---
name: using-astro-6-dev-server
description: Use when working with Astro 6 beta features — the redesigned dev server using Vite Environment API, workerd runtime for Cloudflare Workers, accessing Durable Objects, KV Namespaces, R2 Storage, and Workers Analytics Engine during local development, or first-class Cloudflare Workers deployment.
---

# Using the Astro 6 Dev Server

Astro 6 is currently in beta. It introduces a redesigned dev server built on the Vite Environment API, providing the same runtime in development as in production. This is especially impactful for Cloudflare Workers deployment, where the local dev server now runs the workerd runtime with hot module replacement.

## Beta Status

Astro 6 is in active beta development. APIs may change before the stable release. Use it for new projects or testing, but be aware of potential breaking changes between beta versions.

## Installation

### New Project

```bash
npm create astro@latest -- --ref next
```

### Upgrading an Existing Project

```bash
npx @astrojs/upgrade beta
```

### Requirements

- **Node 22+** is required for Astro 6

## Redesigned Dev Server

The Astro 6 dev server is rebuilt on the **Vite Environment API**. This means the dev server runs the same runtime environment as your production deployment target, eliminating an entire class of "works in dev but not in production" bugs.

### Key Benefits

- Same runtime in development and production
- Faster startup and hot module replacement
- Better error messages with accurate stack traces
- Native support for platform-specific APIs during development

## Cloudflare Workers Support

Astro 6 provides first-class Cloudflare Workers deployment with the workerd runtime running locally during development.

### Accessing Cloudflare Bindings in Dev

Use the `cloudflare:workers` module to access bindings:

```typescript
import { env } from "cloudflare:workers";
```

### KV Namespaces

```typescript
import { env } from "cloudflare:workers";

// Read from KV
const value = await env.MY_KV_NAMESPACE.get("key");

// Write to KV
await env.MY_KV_NAMESPACE.put("key", "value");

// Delete from KV
await env.MY_KV_NAMESPACE.delete("key");
```

### Durable Objects

```typescript
import { env } from "cloudflare:workers";

// Get a Durable Object stub
const id = env.MY_DURABLE_OBJECT.idFromName("my-id");
const stub = env.MY_DURABLE_OBJECT.get(id);

// Send a request to the Durable Object
const response = await stub.fetch("https://fake-host/endpoint");
```

### R2 Storage

```typescript
import { env } from "cloudflare:workers";

// Upload to R2
await env.MY_R2_BUCKET.put("file.txt", "contents");

// Download from R2
const object = await env.MY_R2_BUCKET.get("file.txt");
const text = await object.text();

// List objects
const listed = await env.MY_R2_BUCKET.list({ prefix: "uploads/" });
```

### Workers Analytics Engine

```typescript
import { env } from "cloudflare:workers";

// Write a data point to Analytics Engine
env.MY_ANALYTICS.writeDataPoint({
  blobs: ["page_view", "/about"],
  doubles: [1],
  indexes: ["user-123"],
});
```

### Hot Module Replacement

The workerd runtime in development supports HMR, so changes to your server code are reflected immediately without a full server restart.

## Breaking Changes in Astro 6

### Removed APIs

- **`Astro.glob()`** — Removed. Use `import.meta.glob()` instead:

  ```typescript
  // Before (removed)
  const posts = await Astro.glob("./posts/*.md");

  // After
  const posts = await Object.values(import.meta.glob("./posts/*.md", { eager: true }));
  ```

- **`emitESMImage()`** — Removed from the image service API.

- **Legacy `<ViewTransitions />`** — Removed. Use the `<ClientRouter />` component instead:

  ```astro
  ---
  // Before (removed)
  import { ViewTransitions } from "astro:transitions";
  // After
  import { ClientRouter } from "astro:transitions";
  ---
  <head>
    <ClientRouter />
  </head>
  ```

- **Legacy content collections** — The old content collections API using `src/content/config.ts` with `defineCollection()` from `astro:content` is removed. Migrate to the new content layer API with `src/content.config.ts` and loaders.

### Zod 4 Upgrade

Astro 6 upgrades to **Zod 4**. While mostly backward-compatible, review your schemas for any edge cases. Key differences:

- Improved error messages
- Better TypeScript inference
- Some subtle behavioral changes in union and intersection types
