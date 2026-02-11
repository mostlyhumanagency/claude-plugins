---
name: building-node-http-server
description: Use when building an API server, creating HTTP endpoints, handling requests and responses, implementing routing, streaming responses, adding HTTPS/TLS, or performing graceful shutdown in Node.js without a framework — covers node:http, createServer, request parsing, response streaming, keep-alive, and HTTPS setup. Triggers on EADDRINUSE, ERR_HTTP_HEADERS_SENT, ECONNRESET, ECONNREFUSED.
---

# Building Node HTTP Server

## Overview

Build HTTP servers with `node:http` for full control over request and response handling without frameworks.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Building an HTTP/HTTPS server without a framework.
- Learning request/response lifecycle fundamentals.
- Implementing custom routing or middleware patterns.
- Serving static files or streaming responses.
- Configuring keep-alive, timeouts, and graceful shutdown.

## When Not to Use

- You want a full framework with routing, middleware, validation — use Express, Fastify, or Hono.
- You need WebSocket support — use `ws` or a framework with WebSocket built-in.

## Quick Reference

- Use `http.createServer(handler)` to create a server.
- Always call `res.end()` to finish the response.
- Set `Content-Type` before writing body.
- Handle `'error'` events on both server and request.
- Implement graceful shutdown with `server.close()` and `SIGTERM` handling.

## Examples

### Basic server

```js
import { createServer } from 'node:http';

const server = createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello World\n');
});

server.listen(3000, () => {
  console.log('Listening on http://localhost:3000');
});
```

### JSON API endpoint

```js
const server = createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/api/data') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});
```

### Reading POST body

```js
async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString();
}
```

### Graceful shutdown

```js
process.on('SIGTERM', () => {
  server.close(() => {
    console.log('Server shut down gracefully');
    process.exit(0);
  });
});
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| EADDRINUSE | Address already in use | Another process is using the port; choose a different port or kill the process |
| ERR_HTTP_HEADERS_SENT | Cannot set headers after they are sent | Ensure `res.writeHead`/`res.setHeader` is called before `res.write`/`res.end` |
| ECONNRESET | Connection reset by peer | Client disconnected; handle the error event on the socket |
| ECONNREFUSED | Connection refused | The target server is not running or not accepting connections |
| ERR_HTTP_INVALID_STATUS_CODE | Invalid status code | Use a valid HTTP status code (100-599) |

## References

- `http-server.md`
