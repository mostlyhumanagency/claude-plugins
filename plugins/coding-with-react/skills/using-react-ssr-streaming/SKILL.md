---
name: using-react-ssr-streaming
description: Use when server-rendering a React app, sending HTML progressively to the browser, improving time-to-first-byte for slow data sources, hydrating server-rendered markup on the client, generating static HTML at build time, or implementing partial pre-rendering for hybrid static/dynamic pages. Covers renderToPipeableStream, renderToReadableStream, prerender, hydrateRoot, and Suspense-based streaming.
---

# React SSR Streaming

## Overview

React SSR streaming renders HTML on the server and sends it progressively to the client. Instead of waiting for all data to load before sending HTML, streaming sends the initial shell immediately and streams in suspended content as it resolves. The core APIs are `renderToPipeableStream` (Node.js) and `renderToReadableStream` (Web Streams/Edge). For static generation, use `prerender` to wait for all data. Partial Pre-rendering combines pre-rendered static shells with dynamic content that resumes at request time.

## When to Use

- Building server-rendered React applications with progressive content loading
- Implementing Suspense-based data fetching on the server
- Optimizing time-to-first-byte while waiting for slow data sources
- Creating static sites with `prerender` for build-time HTML generation
- Implementing Partial Pre-rendering for hybrid static/dynamic pages

## Core Patterns

### Basic Streaming SSR

```tsx
import { renderToPipeableStream } from "react-dom/server";

app.get("/", (req, res) => {
  let didError = false;
  const { pipe, abort } = renderToPipeableStream(<App />, {
    bootstrapScripts: ["/main.js"],
    onShellReady() {
      res.statusCode = didError ? 500 : 200;
      res.setHeader("content-type", "text/html");
      pipe(res);
    },
    onShellError(error) {
      res.statusCode = 500;
      res.send("<h1>Server error</h1>");
    },
    onError(error) {
      didError = true;
      console.error(error);
    },
  });

  setTimeout(() => abort(), 10_000);
});
```

### Suspense Boundaries

```tsx
function ProfilePage() {
  return (
    <ProfileLayout>
      <ProfileCover />
      <Suspense fallback={<BigSpinner />}>
        <Sidebar />
        <Suspense fallback={<PostsGlimmer />}>
          <Posts />
        </Suspense>
      </Suspense>
    </ProfileLayout>
  );
}
```

Streaming order: shell -> outer fallback -> Sidebar + inner fallback -> Posts content.

### Client Hydration

```tsx
import { hydrateRoot } from "react-dom/client";

hydrateRoot(document, <App />);
```

## Quick Reference

| API | Runtime | Use Case |
|-----|---------|----------|
| `renderToPipeableStream` | Node.js | Streaming SSR |
| `renderToReadableStream` | Web Streams/Edge | Streaming SSR |
| `prerender` | Any | Static generation (waits for all data) |
| `resume` / `resumeToPipeableStream` | Node.js | Partial Pre-rendering (dynamic) |
| `resumeAndPrerender` | Any | Partial Pre-rendering (static) |
| `hydrateRoot` | Client | Hydrate server HTML |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No `<Suspense>` boundaries | Wrap slow components to enable streaming |
| Using `onAllReady` for users | Use `onShellReady` for streaming, `onAllReady` only for crawlers |
| Hydration mismatch | Ensure identical server/client render output |
| Missing `bootstrapScripts` | Add client bundle path for interactivity |
| No abort timeout | Call `abort()` after timeout to prevent hanging |

See [reference.md](./reference.md) for complete API documentation, Web Streams patterns, prerender/resume APIs, and Partial Pre-rendering details.
