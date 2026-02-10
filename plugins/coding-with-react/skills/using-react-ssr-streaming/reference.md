# React SSR Streaming Reference

Complete reference for React server-side rendering with streaming, static generation, and partial pre-rendering.

## renderToPipeableStream (Node.js)

Full API for Node.js streaming SSR.

```tsx
import { renderToPipeableStream } from "react-dom/server";

const { pipe, abort } = renderToPipeableStream(
  reactNode,
  {
    bootstrapScripts: string[],
    bootstrapModules: string[],
    identifierPrefix: string,
    namespaceURI: string,
    nonce: string,
    progressiveChunkSize: number,
    signal: AbortSignal,
    onShellReady: () => void,
    onShellError: (error: Error) => void,
    onAllReady: () => void,
    onError: (error: Error) => void,
  }
);
```

### Options

- **`bootstrapScripts`**: Array of script URLs to load (e.g., `["/main.js"]`). These scripts run after HTML is parsed.
- **`bootstrapModules`**: Array of ES module URLs to load (e.g., `["/app.js"]`). Use for modern bundlers.
- **`identifierPrefix`**: Prefix for React-generated IDs. Useful for avoiding conflicts when multiple React apps exist on one page.
- **`namespaceURI`**: Namespace for SVG/MathML rendering (rarely needed).
- **`nonce`**: CSP nonce for inline scripts.
- **`progressiveChunkSize`**: Minimum byte size before flushing a chunk (default: 12800).
- **`signal`**: AbortSignal to cancel rendering externally.

### Callbacks

| Callback | When It Fires | Typical Action |
|----------|---------------|----------------|
| **`onShellReady`** | Initial shell (above Suspense boundaries) is ready | `pipe(res)` to start streaming to users |
| **`onAllReady`** | All content (including suspended) is ready | `pipe(res)` for crawlers/SSG; avoid for users (loses streaming benefit) |
| **`onShellError`** | Shell rendering fails (unrecoverable error) | Send fallback HTML (e.g., `res.send("<h1>Error</h1>")`) |
| **`onError`** | Any error during rendering (shell or suspended content) | Log error, set status code |

### Methods

- **`pipe(destination)`**: Starts writing HTML to the destination stream (e.g., `res`).
- **`abort(reason)`**: Cancels rendering and immediately flushes fallbacks for any pending Suspense boundaries.

### Example: Streaming with Timeout

```tsx
app.get("/", (req, res) => {
  let didError = false;

  const { pipe, abort } = renderToPipeableStream(<App />, {
    bootstrapScripts: ["/client.js"],
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

  setTimeout(() => abort(), 10_000); // Abort after 10 seconds
});
```

### Example: Separate Handling for Crawlers

```tsx
app.get("/", (req, res) => {
  const isCrawler = /bot|googlebot|crawler|spider/i.test(
    req.headers["user-agent"] || ""
  );

  const { pipe } = renderToPipeableStream(<App />, {
    bootstrapScripts: ["/client.js"],
    onShellReady() {
      if (!isCrawler) {
        res.setHeader("content-type", "text/html");
        pipe(res); // Stream immediately for users
      }
    },
    onAllReady() {
      if (isCrawler) {
        res.setHeader("content-type", "text/html");
        pipe(res); // Wait for all content for crawlers
      }
    },
  });
});
```

## renderToReadableStream (Web Streams)

For edge runtimes (Cloudflare Workers, Deno, Bun) and environments supporting Web Streams.

```tsx
import { renderToReadableStream } from "react-dom/server";

const stream = await renderToReadableStream(
  reactNode,
  {
    bootstrapScripts: string[],
    bootstrapModules: string[],
    identifierPrefix: string,
    namespaceURI: string,
    nonce: string,
    progressiveChunkSize: number,
    signal: AbortSignal,
    onError: (error: Error) => void,
  }
);
```

### Properties

- **`stream.allReady`**: Promise that resolves when all content (including suspended) is rendered.

### Example: Edge Runtime

```tsx
async function handler(request: Request) {
  const stream = await renderToReadableStream(<App />, {
    bootstrapScripts: ["/main.js"],
    onError(error) {
      console.error(error);
    },
  });

  return new Response(stream, {
    headers: { "content-type": "text/html" },
  });
}
```

### Example: Wait for All Content (SSG)

```tsx
async function generateStaticPage() {
  const stream = await renderToReadableStream(<App />, {
    bootstrapScripts: ["/main.js"],
  });

  await stream.allReady; // Wait for all Suspense boundaries

  return new Response(stream, {
    headers: { "content-type": "text/html" },
  });
}
```

## prerender (Static Generation)

Waits for all data (including Suspense boundaries) before returning HTML. Use for static site generation.

```tsx
import { prerender } from "react-dom/static";

const { prelude, postponed } = await prerender(
  reactNode,
  {
    bootstrapScripts: string[],
    bootstrapModules: string[],
    identifierPrefix: string,
    namespaceURI: string,
    nonce: string,
    progressiveChunkSize: number,
    signal: AbortSignal,
    onError: (error: Error) => void,
    onPostpone: (reason: string) => void,
  }
);
```

### Return Values

- **`prelude`**: ReadableStream containing the pre-rendered HTML.
- **`postponed`**: Opaque object representing postponed content (used for Partial Pre-rendering).

### Example: Basic Static Generation

```tsx
async function generatePage() {
  const { prelude } = await prerender(<App />, {
    bootstrapScripts: ["/main.js"],
  });

  return new Response(prelude, {
    headers: { "content-type": "text/html" },
  });
}
```

### prerenderToNodeStream

Node.js version returning a Node stream instead of Web Stream.

```tsx
import { prerenderToNodeStream } from "react-dom/static.node";

const { prelude } = await prerenderToNodeStream(<App />, options);
```

## Partial Pre-rendering (React 19.2+)

Combines static pre-rendering at build time with dynamic content at request time.

### Step 1: Pre-render Static Shell

```tsx
import { prerender } from "react-dom/static";

// At build time
const controller = new AbortController();
const { prelude, postponed } = await prerender(<App />, {
  signal: controller.signal,
  onPostpone(reason) {
    controller.abort(); // Stop pre-rendering when dynamic content is encountered
  },
});

// Save `prelude` (HTML) and `postponed` (serialized data) to disk
```

### Step 2: Resume with Dynamic Content (Request Time)

For dynamic content at request time:

```tsx
import { resume } from "react-dom/server";

const stream = await resume(<App />, postponed, {
  bootstrapScripts: ["/main.js"],
  onError(error) {
    console.error(error);
  },
});

return new Response(stream, {
  headers: { "content-type": "text/html" },
});
```

For Node.js:

```tsx
import { resumeToPipeableStream } from "react-dom/server.node";

const { pipe } = resumeToPipeableStream(<App />, postponed, {
  bootstrapScripts: ["/main.js"],
  onShellReady() {
    pipe(res);
  },
});
```

### Step 3: Or Resume for Fully Static Output

For static builds (e.g., crawlers, prerendering dynamic routes):

```tsx
import { resumeAndPrerender } from "react-dom/static";

const { prelude } = await resumeAndPrerender(<App />, postponed, {
  bootstrapScripts: ["/main.js"],
});

return new Response(prelude, {
  headers: { "content-type": "text/html" },
});
```

For Node.js:

```tsx
import { resumeAndPrerenderToNodeStream } from "react-dom/static.node";

const { prelude } = await resumeAndPrerenderToNodeStream(<App />, postponed, options);
```

## Client Hydration

Hydrate server-rendered HTML on the client.

```tsx
import { hydrateRoot } from "react-dom/client";

hydrateRoot(document, <App />);
```

### Important

- The client `<App />` must render the same output as the server to avoid hydration mismatches.
- React automatically handles streamed-in content (Suspense boundaries).

## Suspense Streaming Order

Suspense boundaries control streaming order. Content renders in this sequence:

1. **Shell**: Everything outside Suspense boundaries
2. **Outer Suspense fallback**: Fallback content for outer boundary
3. **Outer content + nested fallback**: Resolved outer content + fallback for nested boundary
4. **Nested content**: Resolved nested content

### Example

```tsx
function Page() {
  return (
    <Layout>
      <Header /> {/* Part of shell */}
      <Suspense fallback={<Spinner />}>
        <Sidebar /> {/* Streams after shell */}
        <Suspense fallback={<PostsPlaceholder />}>
          <Posts /> {/* Streams last */}
        </Suspense>
      </Suspense>
    </Layout>
  );
}
```

Streaming order:
1. `<Layout>` + `<Header>` + `<Spinner>`
2. `<Sidebar>` + `<PostsPlaceholder>`
3. `<Posts>`

## Error Handling

### Shell Errors vs Content Errors

- **Shell error** (before first Suspense): Unrecoverable. Triggers `onShellError`. Send fallback HTML.
- **Content error** (inside Suspense): Recoverable. Triggers `onError`. React shows nearest error boundary.

### Example: Robust Error Handling

```tsx
let didError = false;

const { pipe, abort } = renderToPipeableStream(<App />, {
  bootstrapScripts: ["/client.js"],
  onShellReady() {
    res.statusCode = didError ? 500 : 200;
    res.setHeader("content-type", "text/html");
    pipe(res);
  },
  onShellError(error) {
    console.error("Shell error:", error);
    res.statusCode = 500;
    res.send("<!DOCTYPE html><h1>Something went wrong</h1>");
  },
  onError(error) {
    didError = true;
    console.error("Streaming error:", error);
  },
});

setTimeout(() => abort(), 10_000);
```

## Common Patterns

### Pattern: Streaming with Data Fetching

```tsx
async function fetchUser(id: string) {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
}

function UserProfile({ userId }: { userId: string }) {
  const user = use(fetchUser(userId)); // React 19 `use` hook
  return <div>{user.name}</div>;
}

function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserProfile userId="123" />
    </Suspense>
  );
}
```

### Pattern: Nested Suspense for Progressive Loading

```tsx
function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<Skeleton />}>
        <Stats />
        <Suspense fallback={<TableSkeleton />}>
          <DataTable />
        </Suspense>
      </Suspense>
    </div>
  );
}
```

### Pattern: Conditional Streaming for Different Clients

```tsx
function renderForClient(isCrawler: boolean) {
  const { pipe } = renderToPipeableStream(<App />, {
    bootstrapScripts: ["/client.js"],
    [isCrawler ? "onAllReady" : "onShellReady"]() {
      pipe(res);
    },
  });
}
```

## Troubleshooting

### Hydration Mismatches

**Symptom**: Console warnings about server/client HTML differences.

**Causes**:
- Conditional rendering based on browser-only APIs (e.g., `window`)
- Non-deterministic content (e.g., `Date.now()`, `Math.random()`)
- Different data on server vs client

**Fix**: Ensure identical server/client output. Use `useEffect` for browser-only logic:

```tsx
function Component() {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  return <div>{isClient ? <BrowserOnlyContent /> : null}</div>;
}
```

### Page Renders but Isn't Interactive

**Cause**: Missing `bootstrapScripts` or `bootstrapModules`.

**Fix**: Add client bundle path:

```tsx
renderToPipeableStream(<App />, {
  bootstrapScripts: ["/client.js"],
});
```

### Slow Requests Hang Forever

**Cause**: No abort timeout.

**Fix**: Call `abort()` after a reasonable timeout:

```tsx
const { abort } = renderToPipeableStream(<App />, options);
setTimeout(() => abort(), 10_000);
```

### Entire Page Waits for Slow Data

**Cause**: No Suspense boundaries.

**Fix**: Wrap slow components in `<Suspense>`:

```tsx
<Suspense fallback={<Loading />}>
  <SlowComponent />
</Suspense>
```

## API Summary

| API | Runtime | Returns | Use Case |
|-----|---------|---------|----------|
| `renderToPipeableStream` | Node.js | `{ pipe, abort }` | Streaming SSR |
| `renderToReadableStream` | Web Streams | `ReadableStream` | Streaming SSR (edge) |
| `prerender` | Any | `{ prelude, postponed }` | Static generation |
| `prerenderToNodeStream` | Node.js | `{ prelude, postponed }` | Static generation (Node) |
| `resume` | Web Streams | `ReadableStream` | PPR: resume with dynamic content |
| `resumeToPipeableStream` | Node.js | `{ pipe, abort }` | PPR: resume with dynamic content (Node) |
| `resumeAndPrerender` | Any | `{ prelude }` | PPR: resume for static output |
| `resumeAndPrerenderToNodeStream` | Node.js | `{ prelude }` | PPR: resume for static output (Node) |
| `hydrateRoot` | Client | `Root` | Hydrate server HTML |
