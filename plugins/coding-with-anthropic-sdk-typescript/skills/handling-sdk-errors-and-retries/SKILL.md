---
name: handling-sdk-errors-and-retries
description: "Use when handling API errors from the Anthropic TypeScript SDK, configuring retries for rate limits or timeouts, catching specific error types, debugging failed requests, logging HTTP traffic, or using request IDs for support tickets. Also use for APIError, AuthenticationError, RateLimitError (429), InternalServerError (500), overriding default retry/timeout behavior, or making Claude API calls more resilient."
---

## Overview

The Anthropic TypeScript SDK provides a structured error hierarchy, automatic retries with exponential backoff, configurable timeouts, and logging facilities. All API errors extend `Anthropic.APIError` with typed subclasses for each HTTP status code. This skill covers error handling patterns, retry configuration, timeout tuning, request ID tracking, and debug logging.

## When to Use

- Catching and handling specific API errors (rate limits, authentication failures, server errors)
- Configuring automatic retry behavior for transient failures
- Setting request or client-level timeouts
- Debugging failed API calls with request IDs and logging
- Implementing custom retry logic or circuit breakers
- Troubleshooting "connection timeout" or "rate limit exceeded" errors
- Setting up structured logging with pino, winston, or other loggers

When NOT to use:

- For SDK installation and client setup (see `setting-up-anthropic-sdk-typescript`)
- For message creation or tool use (see `creating-sdk-messages`, `using-sdk-tools-and-schemas`)
- For streaming error handling (see `streaming-sdk-responses`)

## Core Patterns

### Catch and Handle API Errors

All API errors extend `Anthropic.APIError`. Use `instanceof` to match specific error types:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

async function callClaude(prompt: string): Promise<string> {
  try {
    const message = await client.messages.create({
      model: "claude-opus-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    });
    const block = message.content[0];
    return block.type === "text" ? block.text : "";
  } catch (err) {
    if (err instanceof Anthropic.RateLimitError) {
      // 429 -- back off and retry, or queue for later
      console.error("Rate limited. Retry after backoff.");
      throw err;
    }
    if (err instanceof Anthropic.AuthenticationError) {
      // 401 -- API key is invalid or missing
      console.error("Invalid API key. Check ANTHROPIC_API_KEY.");
      throw err;
    }
    if (err instanceof Anthropic.BadRequestError) {
      // 400 -- malformed request (bad model name, invalid params)
      console.error("Bad request:", err.message);
      throw err;
    }
    if (err instanceof Anthropic.InternalServerError) {
      // 500+ -- server-side issue, usually transient
      console.error("Server error:", err.status, err.message);
      throw err;
    }
    if (err instanceof Anthropic.APIConnectionError) {
      // Network failure -- no response received
      console.error("Connection failed:", err.message);
      throw err;
    }
    if (err instanceof Anthropic.APIConnectionTimeoutError) {
      // Timeout -- request took too long
      console.error("Request timed out");
      throw err;
    }
    // Unknown error
    throw err;
  }
}
```

### Use the Catch Handler Pattern

For concise error handling, use the `.catch()` method on the promise:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages
  .create({
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  })
  .catch(async (err) => {
    if (err instanceof Anthropic.APIError) {
      console.error(`API error ${err.status}: ${err.message}`);
      console.error("Request ID:", err.headers?.["request-id"]);
      return null; // return a fallback value
    }
    throw err;
  });

if (message) {
  console.log(message.content);
}
```

### Access Error Properties

Every `Anthropic.APIError` instance provides:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

try {
  await client.messages.create({
    model: "nonexistent-model",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  });
} catch (err) {
  if (err instanceof Anthropic.APIError) {
    console.log(err.status);   // HTTP status code: 404
    console.log(err.name);     // Error class name: "NotFoundError"
    console.log(err.message);  // Human-readable error message
    console.log(err.headers);  // Response headers (includes request-id)
  }
}
```

### Configure Automatic Retries

The SDK retries automatically on connection errors and status codes 408, 409, 429, and 5xx. Default is 2 retries with exponential backoff:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Disable all automatic retries
const noRetryClient = new Anthropic({
  maxRetries: 0,
});

// Increase retries for high-reliability use cases
const resilientClient = new Anthropic({
  maxRetries: 5,
});

// Override retries for a single request
const message = await resilientClient.messages.create(
  {
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  },
  {
    maxRetries: 10, // override client default for this request only
  }
);
```

The SDK uses exponential backoff between retries. For 429 responses, it respects the `retry-after` header if present.

### Configure Timeouts

The default timeout is 10 minutes, with automatic scaling for large `max_tokens` values:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Set a shorter timeout for fast-response use cases
const fastClient = new Anthropic({
  timeout: 30_000, // 30 seconds
});

// Override timeout for a single long-running request
const message = await fastClient.messages.create(
  {
    model: "claude-opus-4-6",
    max_tokens: 8192,
    messages: [{ role: "user", content: "Write a detailed essay" }],
  },
  {
    timeout: 120_000, // 2 minutes for this request only
  }
);
```

Timeout auto-scaling formula (when no custom timeout is set):

```
minimum  = 10 * 60 seconds (10 minutes)
scaled   = (60 * 60 * max_tokens) / 128_000 seconds
effective = max(minimum, scaled), capped at 60 minutes
```

A request with `max_tokens: 128000` gets a 60-minute timeout automatically. Setting a custom `timeout` overrides this auto-scaling.

### Track Request IDs for Debugging

Every API response includes a request ID. Log it for support tickets and debugging:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});

// Access the request ID from the response object
console.log("Request ID:", message._request_id);
// Example: "req_018EeWyXxfu5pfWkrYcMdjWG"

// Also available in error responses via headers
try {
  await client.messages.create({
    model: "bad-model",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  });
} catch (err) {
  if (err instanceof Anthropic.APIError) {
    console.log("Failed request ID:", err.headers?.["request-id"]);
  }
}
```

Include the request ID when filing support tickets with Anthropic.

### Enable Debug Logging

Use SDK logging to inspect HTTP requests and responses:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Option 1: Set log level on the client
const client = new Anthropic({
  logLevel: "debug", // 'debug' | 'info' | 'warn' | 'error' | 'off'
});

// Option 2: Use environment variable (no code changes)
// ANTHROPIC_LOG=debug node app.js

// Option 3: Use a custom logger (pino, winston, bunyan, etc.)
import pino from "pino";

const logger = pino({ level: "debug" });

const clientWithPino = new Anthropic({
  logger: logger.child({ name: "Anthropic" }),
  logLevel: "debug",
});
```

At `debug` level, the SDK logs all HTTP request and response headers and bodies. Authentication headers are automatically redacted.

Log level hierarchy: `debug` > `info` > `warn` (default) > `error` > `off`.

### Implement Custom Retry Logic

When the built-in retry mechanism is not sufficient (e.g., you need circuit breaking or different backoff strategies), disable auto-retries and handle them manually:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({ maxRetries: 0 });

async function callWithCustomRetry(
  prompt: string,
  maxAttempts: number = 3
): Promise<Anthropic.Message> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await client.messages.create({
        model: "claude-opus-4-6",
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }],
      });
    } catch (err) {
      if (err instanceof Anthropic.RateLimitError) {
        // Respect retry-after header if present
        const retryAfter = err.headers?.["retry-after"];
        const waitMs = retryAfter
          ? parseInt(retryAfter, 10) * 1000
          : Math.pow(2, attempt) * 1000;
        console.log(`Rate limited. Waiting ${waitMs}ms (attempt ${attempt})`);
        await new Promise((resolve) => setTimeout(resolve, waitMs));
        continue;
      }
      if (
        err instanceof Anthropic.InternalServerError &&
        attempt < maxAttempts
      ) {
        const waitMs = Math.pow(2, attempt) * 1000;
        await new Promise((resolve) => setTimeout(resolve, waitMs));
        continue;
      }
      throw err; // Non-retryable error
    }
  }
  throw new Error("Max retry attempts exceeded");
}
```

## Quick Reference

### Error Types

| Status Code | Error Class | Auto-Retried |
|---|---|---|
| 400 | `BadRequestError` | No |
| 401 | `AuthenticationError` | No |
| 403 | `PermissionDeniedError` | No |
| 404 | `NotFoundError` | No |
| 408 | `RequestTimeoutError` | Yes |
| 409 | `ConflictError` | Yes |
| 422 | `UnprocessableEntityError` | No |
| 429 | `RateLimitError` | Yes |
| >=500 | `InternalServerError` | Yes |
| N/A | `APIConnectionError` | Yes |
| N/A | `APIConnectionTimeoutError` | Yes |

### Configuration Options

| Option | Scope | Default | Description |
|---|---|---|---|
| `maxRetries` | Client or request | `2` | Number of automatic retry attempts |
| `timeout` | Client or request | `600000` ms | Request timeout in milliseconds |
| `logLevel` | Client | `"warn"` | Log verbosity level |
| `logger` | Client | built-in | Custom logger instance |

### Environment Variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_LOG` | Set log level without code changes |

## Common Mistakes

**Double retry logic**
The SDK retries 429 and 5xx errors automatically (default: 2 retries). If you wrap calls in your own retry loop without setting `maxRetries: 0`, you get multiplicative retries (e.g., 3 custom retries x 3 SDK retries = up to 9 attempts). Either use the built-in retries or disable them and implement your own.

**Catching the wrong error base class**
Use `instanceof Anthropic.APIError` for API errors, not generic `Error`. Network errors like `APIConnectionError` also extend `APIError`, so the base class catches everything from the SDK. Non-SDK errors (e.g., JSON parse failures in your code) will not match.

**Setting a custom timeout that overrides auto-scaling**
When you set `timeout` on the client, it replaces the SDK's automatic timeout scaling for large `max_tokens` values. A 30-second timeout with `max_tokens: 128000` will almost always time out. Either omit the custom timeout for large-token requests, override per-request, or use streaming.

**Ignoring request IDs in error logs**
When an API error occurs, always log `err.headers?.["request-id"]`. Without the request ID, Anthropic support cannot look up what happened on the server side.

**Not handling APIConnectionError separately**
`APIConnectionError` means no HTTP response was received (DNS failure, network down, TLS error). It has no `status` code. Code that reads `err.status` will get `undefined` for connection errors. Check the error type before accessing status-specific properties.

**Logging sensitive data at debug level in production**
At `debug` log level, the SDK logs full HTTP request and response bodies, which include your prompts and Claude's responses. Authentication headers are redacted, but message content is not. Use `"warn"` or higher in production environments.

## References

- Anthropic TypeScript SDK: https://github.com/anthropics/anthropic-sdk-typescript
- Error handling section: https://github.com/anthropics/anthropic-sdk-typescript#handling-errors
- Retries documentation: https://github.com/anthropics/anthropic-sdk-typescript#retries
- Timeouts documentation: https://github.com/anthropics/anthropic-sdk-typescript#timeouts
- API error codes: https://docs.anthropic.com/en/api/errors
