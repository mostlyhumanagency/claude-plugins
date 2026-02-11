---
name: deploying-tanstack-start
description: Use when deploying TanStack Start applications — Netlify deployment with @netlify/vite-plugin-tanstack-start, Cloudflare Workers or Pages deployment, Railway deployment, vite build production build, CDN asset URL configuration, static asset hosting, SSR deployment requirements, netlify.toml configuration, or choosing between static and server deployment.
---

# Deploying TanStack Start

TanStack Start supports deployment to various hosting platforms. The choice depends on your rendering strategy.

## Build

```bash
npm run build
# or
vite build
```

Output goes to `dist/` with `client/` and `server/` subdirectories.

## Netlify

### Setup

```bash
npm install -D @netlify/vite-plugin-tanstack-start
```

### vite.config.ts

```ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import react from '@vitejs/plugin-react'
import netlify from '@netlify/vite-plugin-tanstack-start'

export default defineConfig({
  plugins: [
    tanstackStart(),
    netlify(),
    react(),
  ],
})
```

### netlify.toml

```toml
[build]
  command = "vite build"
  publish = "dist/client"

[dev]
  command = "vite dev"
  port = 3000
```

### Deploy

Push to GitHub and connect the repository to Netlify, or use Netlify CLI:

```bash
npx netlify deploy --prod
```

## Cloudflare

### Workers

```bash
npm install -D @opennextjs/cloudflare
```

Configure in `vite.config.ts` with the Cloudflare adapter. Deploy with `wrangler`:

```bash
npx wrangler deploy
```

### Pages

Cloudflare Pages can host static TanStack Start builds (SPA mode) or use Functions for SSR.

## Railway

Railway auto-detects Node.js projects. Configure:

```json
// package.json
{
  "scripts": {
    "start": "node dist/server/index.js",
    "build": "vite build"
  }
}
```

Set environment variables in Railway dashboard.

## CDN Asset URLs

Configure a custom CDN URL for static assets:

```ts
// vite.config.ts
export default defineConfig({
  base: 'https://cdn.example.com/assets/',
  plugins: [tanstackStart(), react()],
})
```

## Static Deployment (SPA Mode)

For SPA-mode apps, any static file host works:

```ts
// vite.config.ts
tanstackStart({
  spa: { enabled: true },
})
```

Deploy `dist/client/` to any CDN (Vercel, Netlify, S3 + CloudFront, GitHub Pages).

Configure redirect rules so all paths serve `/_shell.html`:

```
# Netlify _redirects
/*    /_shell.html   200

# Vercel vercel.json
{ "rewrites": [{ "source": "/(.*)", "destination": "/_shell.html" }] }
```

## Static Prerendered Deployment

With prerendering enabled, `dist/client/` contains all generated HTML files. Deploy as static files:

```ts
tanstackStart({
  prerender: {
    enabled: true,
    crawlLinks: true,
  },
})
```

## SSR Deployment Requirements

SSR apps need a Node.js runtime (or compatible edge runtime):

- **Server**: Node.js 18+ or Bun
- **Entry**: `dist/server/index.js`
- **Static assets**: Serve `dist/client/` from CDN or same server

## Deployment Checklist

- [ ] Set `NODE_ENV=production` on hosting platform
- [ ] Configure all `process.env` variables in hosting dashboard
- [ ] `VITE_` variables are baked at build time — set before building
- [ ] Verify `vite.config.ts` plugin order: `tanstackStart()` first
- [ ] Test build locally with `npm run build && node dist/server/index.js`
- [ ] Configure CDN/caching headers for static assets
- [ ] Set up HTTPS in production

## Common Mistakes

- Forgetting to set environment variables on hosting platform — app crashes at runtime
- Using `VITE_` vars that differ between build and runtime — they're baked at build time
- Not serving `dist/client/` statically — missing CSS/JS assets
- Running `vite dev` in production — use `node dist/server/index.js`
- Missing redirect rules for SPA mode — direct URL access returns 404
