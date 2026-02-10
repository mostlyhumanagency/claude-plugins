# Node HTTP Server (v24)

## Core APIs

- `node:http` — HTTP/1.1 server and client.
- `node:https` — TLS-wrapped HTTP server and client.
- `node:http2` — HTTP/2 server with multiplexing.

## Quick Reference

| API | Purpose | Notes |
|---|---|---|
| `http.createServer(handler)` | Create HTTP server | Handler receives (req, res) |
| `server.listen(port, cb)` | Start listening | Callback fires on ready |
| `server.close(cb)` | Stop accepting connections | Existing connections finish |
| `req.method` | HTTP method | GET, POST, PUT, DELETE, etc. |
| `req.url` | Request URL path | Includes query string |
| `req.headers` | Request headers | Lowercase keys |
| `res.writeHead(status, headers)` | Set status + headers | Must call before body |
| `res.write(chunk)` | Send body chunk | Can call multiple times |
| `res.end(data)` | Finish response | Required to complete |
| `res.setHeader(name, value)` | Set single header | Before writeHead or implicit head |
| `server.setTimeout(ms)` | Set request timeout | Default: 0 (no timeout) |
| `server.keepAliveTimeout` | Keep-alive timeout | Default: 5000ms |
| `server.headersTimeout` | Headers receive timeout | Default: 60000ms |

## Common Mistakes

**Not calling res.end()** — The client hangs waiting for the response to complete. Always call `res.end()`, even for empty responses.

**Setting headers after res.write()** — Once you start writing the body, headers are sent. Call `res.writeHead()` or `res.setHeader()` before any `res.write()`.

**Not handling request errors** — If the client disconnects mid-request, an error is emitted. Attach `req.on('error', cb)` to avoid unhandled exceptions.

**Ignoring backpressure on res.write()** — `res.write()` returns false when the buffer is full. Wait for the `'drain'` event before writing more.

**Missing Content-Type header** — Without it, clients may misinterpret the response body. Always set it explicitly.

## Constraints

- `node:http` is HTTP/1.1 only. Use `node:http2` for HTTP/2.
- Request body is a stream — you must read it asynchronously.
- `req.url` does not include the protocol or host, just the path and query.
- Keep-alive is enabled by default in Node.js; set timeouts to prevent resource leaks.

## Do / Don't

- Do set explicit `Content-Type` headers on every response.
- Do implement graceful shutdown with `server.close()`.
- Do set `server.timeout` and `server.keepAliveTimeout` to prevent hung connections.
- Do handle `'error'` events on both the server and individual requests.
- Don't use `res.write()` without checking backpressure.
- Don't parse URLs manually — use `new URL(req.url, 'http://localhost')`.
- Don't forget to handle all HTTP methods (return 405 for unsupported methods).

## Examples

### URL parsing and routing

```js
import { createServer } from 'node:http';

const server = createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/api/users' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify([{ id: 1, name: 'Alice' }]));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});
```

### Streaming a file as response

```js
import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';

const server = createServer(async (req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  await pipeline(createReadStream('index.html'), res);
});
```

### HTTPS server

```js
import { createServer } from 'node:https';
import { readFileSync } from 'node:fs';

const server = createServer({
  key: readFileSync('key.pem'),
  cert: readFileSync('cert.pem')
}, (req, res) => {
  res.writeHead(200);
  res.end('Secure Hello');
});

server.listen(443);
```

### Graceful shutdown with connection tracking

```js
const connections = new Set();
server.on('connection', (conn) => {
  connections.add(conn);
  conn.on('close', () => connections.delete(conn));
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
  // Force-close idle connections after timeout
  setTimeout(() => {
    for (const conn of connections) conn.destroy();
    process.exit(1);
  }, 10_000);
});
```

### POST body with size limit

```js
async function readBody(req, maxBytes = 1_048_576) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > maxBytes) throw new Error('Payload too large');
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString();
}
```

## Verification

- `curl -v http://localhost:3000` to test basic responses.
- `curl -X POST -d '{"key":"val"}' -H 'Content-Type: application/json' http://localhost:3000` to test POST handling.
- Check graceful shutdown by sending SIGTERM and verifying in-flight requests complete.
