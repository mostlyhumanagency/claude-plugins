---
name: setting-up-anthropic-sdk-typescript
description: "Use when installing @anthropic-ai/sdk, creating a new Anthropic client instance, setting the API key via environment variables or constructor, configuring retries or timeouts, setting up a proxy, or fixing 'APIConnectionError' or client initialization issues. Also use for npm install, first-time SDK setup, choosing a runtime (Node.js, Deno, Bun, Cloudflare Workers), or getting started with the Anthropic TypeScript SDK."
---

## Overview

The `@anthropic-ai/sdk` package is the official TypeScript SDK for the Anthropic API. It provides a typed client for creating messages, streaming responses, and managing tool use with Claude models. This skill covers installation, client initialization, configuration options, proxy setup, and supported runtimes.

## When to Use

- Installing the Anthropic TypeScript SDK in a new or existing project
- Creating and configuring an `Anthropic` client instance
- Setting up API key authentication via environment variables or constructor
- Configuring retries, timeouts, or custom fetch functions
- Setting up proxy connections for the SDK
- Troubleshooting "API key not found" or timeout errors
- Checking runtime compatibility (Node.js, Deno, Bun, Cloudflare Workers, etc.)

When NOT to use:

- For making API calls or creating messages (see `creating-sdk-messages`)
- For streaming responses (see `streaming-sdk-responses`)
- For Python SDK setup (this skill covers TypeScript only)

## Core Patterns

### Install the SDK

```bash
npm install @anthropic-ai/sdk
```

Requirements: TypeScript >= 4.9. The SDK ships with its own type definitions -- no separate `@types` package is needed.

### Create a Basic Client

The simplest setup reads the API key from the `ANTHROPIC_API_KEY` environment variable automatically:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Reads ANTHROPIC_API_KEY from environment by default
const client = new Anthropic();

// Verify the client works
const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 256,
  messages: [{ role: "user", content: "Say hello" }],
});
console.log(message.content[0].type === "text" && message.content[0].text);
```

### Pass the API Key Explicitly

When the key is stored somewhere other than `ANTHROPIC_API_KEY`, pass it directly:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  apiKey: getSecretFromVault("anthropic-api-key"),
});
```

### Configure Retries and Timeouts

The SDK auto-retries on connection errors, 408, 409, 429, and 5xx status codes. Adjust the behavior:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  maxRetries: 5,        // default: 2
  timeout: 30_000,      // 30 seconds; default: 10 minutes
});
```

For requests with large `max_tokens`, the SDK automatically scales the timeout using this formula:

```
minimum = 10 * 60 seconds
calculated = (60 * 60 * maxTokens) / 128_000 seconds
timeout = max(minimum, calculated), capped at 60 minutes
```

This means a request with `max_tokens: 128000` gets a 60-minute timeout automatically.

### Configure Logging

Control SDK log output with `logLevel` or a custom logger:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Use built-in log levels
const client = new Anthropic({
  logLevel: "debug", // 'debug' | 'info' | 'warn' | 'error' | 'off'
});

// Or use a custom logger (pino, winston, bunyan, consola, signale)
import pino from "pino";
const logger = pino({ level: "debug" });

const clientWithPino = new Anthropic({
  logger: logger,
});
```

The `ANTHROPIC_LOG` environment variable also controls the log level when `logLevel` is not set in code.

### Use TypeScript Types for Request Parameters

Import types directly from the SDK for full type safety:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const params: Anthropic.MessageCreateParams = {
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Explain TypeScript generics" }],
};

const message: Anthropic.Message = await client.messages.create(params);
```

### Configure a Proxy (Node.js)

Use `undici.ProxyAgent` via the `fetchOptions.dispatcher` option:

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { ProxyAgent } from "undici";

const client = new Anthropic({
  fetchOptions: {
    dispatcher: new ProxyAgent("https://my-proxy.example.com:8080"),
  },
});
```

For Bun, use the `fetchOptions.proxy` string instead:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  fetchOptions: {
    proxy: "https://my-proxy.example.com:8080",
  },
});
```

### Enable Browser Usage

Browser usage is disabled by default because it exposes your API key to end users. Only enable it for prototyping or when the key exposure is acceptable:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// WARNING: This exposes your API key in client-side code
const client = new Anthropic({
  apiKey: "sk-ant-...",
  dangerouslyAllowBrowser: true,
});
```

For production browser apps, proxy requests through your own backend instead.

### Custom Fetch Function

Replace the built-in fetch with a custom implementation:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({
  fetch: async (url: RequestInfo, init?: RequestInit) => {
    console.log("Requesting:", url);
    return globalThis.fetch(url, init);
  },
});
```

## Quick Reference

| Option | Type | Default | Description |
|---|---|---|---|
| `apiKey` | `string` | `ANTHROPIC_API_KEY` env var | API authentication key |
| `maxRetries` | `number` | `2` | Auto-retry attempts on transient errors |
| `timeout` | `number` | `600000` (10 min) | Request timeout in milliseconds |
| `logLevel` | `string` | `"warn"` | `debug`, `info`, `warn`, `error`, `off` |
| `logger` | `object` | built-in | Custom logger instance |
| `dangerouslyAllowBrowser` | `boolean` | `false` | Allow usage in browsers |
| `fetch` | `function` | built-in | Custom fetch implementation |
| `fetchOptions` | `RequestInit` | `{}` | Extra options passed to fetch |

### Supported Runtimes

| Runtime | Minimum Version | Notes |
|---|---|---|
| Node.js | 20 LTS (non-EOL) | Primary target |
| Deno | 1.28.0+ | Works out of the box |
| Bun | 1.0+ | Proxy uses `fetchOptions.proxy` |
| Cloudflare Workers | Current | Supported |
| Vercel Edge Runtime | Current | Supported |
| Jest | 28+ | Must use `node` environment, NOT `jsdom` |
| Nitro | 2.6+ | Supported |
| Web Browsers | N/A | Must enable `dangerouslyAllowBrowser` |
| React Native | N/A | NOT supported |

### Environment Variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Default API key |
| `ANTHROPIC_LOG` | Default log level |

## Common Mistakes

**"API key not found" error when key is set**
The SDK reads `ANTHROPIC_API_KEY` by default. If you use a different variable name (e.g., `CLAUDE_API_KEY`), you must pass it explicitly via the `apiKey` constructor option.

**Timeout errors on large responses**
The default 10-minute timeout may not be enough for non-streaming requests with very large `max_tokens`. The SDK auto-scales timeouts for large values, but if you set a custom `timeout`, it overrides the auto-scaling. Either remove the custom timeout or use streaming for long requests.

**Jest tests fail with "fetch is not defined"**
Jest must be configured to use the `node` environment, not `jsdom`. Set `testEnvironment: "node"` in your Jest config or add `@jest-environment node` to the test file.

**Using the SDK in a browser without `dangerouslyAllowBrowser`**
The SDK throws an error when it detects a browser environment. This is intentional -- your API key would be visible to users. For production, proxy through a backend. For prototyping, set `dangerouslyAllowBrowser: true`.

**Auto-retry on 429 rate limit errors**
The SDK retries 429 responses automatically using exponential backoff. If you implement your own retry logic on top, you may get double retries. Either rely on the SDK's built-in retries (configured via `maxRetries`) or set `maxRetries: 0` and handle retries yourself.

**Importing types incorrectly**
Types are namespaced under the default `Anthropic` import. Use `Anthropic.MessageCreateParams`, not a separate import path.

## References

- Anthropic TypeScript SDK repository: https://github.com/anthropics/anthropic-sdk-typescript
- Anthropic API documentation: https://docs.anthropic.com/en/api
- SDK README and changelog: https://github.com/anthropics/anthropic-sdk-typescript/blob/main/README.md
- API versioning: The SDK sends `anthropic-version: 2023-06-01` by default
