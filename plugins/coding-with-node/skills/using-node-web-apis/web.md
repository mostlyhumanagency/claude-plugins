# Node Web APIs (v24)

## Fetch

- `fetch` is globally available and backed by Undici.
- Always check `response.ok` and handle non-2xx status codes.
- Use `AbortController` for timeouts and cancellation.
- Use `Request`, `Response`, `Headers`, `FormData`, and `Blob` from the global Web APIs.

## URL and URLPattern

- Use the WHATWG `URL` class for parsing and formatting.
- Prefer `URLSearchParams` for query strings.
- `URLPattern` is available for URL matching (experimental).

## WebSocket Client

- `WebSocket` is globally available.
- Implement reconnect and backoff logic explicitly.

## Quick Reference

| API | Usage | Notes |
|---|---|---|
| fetch | `await fetch(url)` | Global; backed by Undici; check `res.ok` |
| AbortController | `new AbortController()` | Timeout/cancel for fetch and other async ops |
| URL | `new URL(path, base)` | WHATWG URL parsing; prefer over string concat |
| URLSearchParams | `url.searchParams.set(k, v)` | Safe query string building |
| URLPattern | `new URLPattern({ pathname: '/api/:id' })` | URL route matching (experimental) |
| WebSocket | `new WebSocket('wss://...')` | Global WebSocket client |
| Headers | `new Headers({ 'Content-Type': '...' })` | Request/response header management |
| FormData | `new FormData()` | Multipart form data for fetch |
| Blob | `new Blob([data])` | Binary data handling |

## Common Mistakes

**Not checking `response.ok` after fetch** — `fetch` does not throw on HTTP 4xx/5xx errors. Always check `res.ok` or `res.status` before reading the body.

**Missing AbortController timeout** — Fetch requests without a timeout can hang indefinitely. Always use `AbortController` with `setTimeout`.

**Building URLs with string concatenation** — Leads to encoding bugs and injection risks. Use `new URL()` and `URLSearchParams` for safe URL construction.

**Ignoring WebSocket close events** — Without handling `close`, reconnection logic never triggers. Always listen for `close` and implement backoff.

## Constraints and Edges

- Always validate status codes and content type; `fetch` does not throw on HTTP errors.
- Use timeouts for outbound requests to avoid hanging sockets.
- WebSocket reconnects must be explicit; no automatic retry is provided.

## Do / Don't

- Do validate response status and content types.
- Do set timeouts for outbound requests.
- Don't build URLs with string concatenation.
- Don't ignore WebSocket close events.

## Examples

### Fetch with status check

```js
const res = await fetch('https://api.example.com/data');
if (!res.ok) {
  throw new Error(`HTTP ${res.status}`);
}
const data = await res.json();
```

### Fetch with timeout

```js
const ac = new AbortController();
const t = setTimeout(() => ac.abort(), 5000);
const res = await fetch(url, { signal: ac.signal });
clearTimeout(t);
```

### URL construction

```js
const url = new URL('/v1/items', 'https://api.example.com');
url.searchParams.set('limit', '50');
```

### WebSocket client

```js
const ws = new WebSocket('wss://example.com/socket');
ws.addEventListener('open', () => ws.send('hello'));
ws.addEventListener('close', () => {/* reconnect */});
```

## Verification

- Simulate non-2xx responses and confirm error handling.
- Verify URL encoding by inspecting `url.toString()`.
