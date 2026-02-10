---
name: using-node-web-apis
description: Use when using Node v24 web APIs — fetch, URL/URLPattern, WebSocket client, AbortController, Headers, FormData — for outbound HTTP requests, URL parsing, or WebSocket connections — or when you see UND_ERR_CONNECT_TIMEOUT, AbortError, or fetch status handling issues.
---

# Using Node Web APIs

## Overview

Use Node's built-in web APIs for HTTP, URL handling, and WebSocket clients.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Making outbound HTTP requests with `fetch`.
- Parsing and constructing URLs safely.
- Using the global WebSocket client.
- Matching URLs with `URLPattern`.

## When Not to Use

- You need a full HTTP client with retries, caching, or middleware.
- You require server-side frameworks; this is client-side usage only.
- You need browser APIs not present in Node.

## Quick Reference

- Use `fetch` with explicit status checks.
- Use the WHATWG `URL` class instead of string concatenation.
- Use `AbortController` for timeouts.
- Handle WebSocket reconnects and backoff explicitly.

## Examples

### Fetch with status check

```js
const res = await fetch('https://api.example.com/data');
if (!res.ok) throw new Error(`HTTP ${res.status}`);
```

### Fetch with timeout

```js
const ac = new AbortController();
const t = setTimeout(() => ac.abort(), 5000);
await fetch(url, { signal: ac.signal });
clearTimeout(t);
```

### URL construction

```js
const url = new URL('/v1/items', 'https://api.example.com');
url.searchParams.set('limit', '50');
```

### WebSocket open/close

```js
const ws = new WebSocket('wss://example.com');
ws.addEventListener('open', () => ws.send('hello'));
ws.addEventListener('close', () => {});
```

## Common Errors

| Code / Error | Message Fragment | Fix |
|---|---|---|
| UND_ERR_CONNECT_TIMEOUT | Connect timeout | Increase timeout or check network connectivity |
| AbortError | The operation was aborted | Expected when using AbortController; handle in catch |
| TypeError: fetch failed | Network error or DNS failure | Check URL validity and network access |
| UND_ERR_HEADERS_TIMEOUT | Headers timeout | Server too slow to respond; increase timeout |
| ERR_INVALID_URL | Invalid URL | Use `new URL()` constructor for validation before fetch |

## References

- `web.md`
