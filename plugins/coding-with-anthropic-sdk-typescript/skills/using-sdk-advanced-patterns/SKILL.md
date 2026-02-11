---
name: using-sdk-advanced-patterns
description: "Use when accessing raw HTTP responses from the Anthropic TypeScript SDK, configuring a proxy or custom fetch, calling undocumented API endpoints, overriding headers, or deploying Claude on Amazon Bedrock or Google Vertex AI. Also use for AnthropicBedrock, AnthropicVertex, withResponse(), advanced client configuration, or migrating SDK code between direct API, Bedrock, and Vertex providers."
---

## Overview

The Anthropic TypeScript SDK provides low-level hooks for accessing raw HTTP responses, customizing the fetch implementation, configuring proxies, calling undocumented endpoints, and integrating with cloud platforms like Amazon Bedrock and Google Vertex AI. This skill covers advanced SDK patterns that go beyond standard message creation.

## When to Use

- Accessing raw HTTP response headers or status codes from API calls
- Configuring a custom fetch function or fetch options
- Routing SDK traffic through an HTTP proxy
- Calling undocumented or preview API endpoints
- Passing undocumented parameters to known endpoints
- Overriding default SDK headers (e.g., `anthropic-version`)
- Deploying Claude through Amazon Bedrock or Google Vertex AI

When NOT to use:

- For basic message creation (see `creating-sdk-messages`)
- For streaming responses (see `streaming-sdk-responses`)
- For beta features like Files API or code execution (see `using-sdk-beta-apis`)
- For error handling and retries (see `handling-sdk-errors-and-retries`)

## Core Patterns

### Access Raw HTTP Responses

The SDK provides two methods to access the underlying HTTP response alongside the parsed data:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Method 1: .asResponse() — returns the raw Response immediately when headers
// are received. The body is NOT consumed; you must read it yourself.
const rawResponse = await client.messages
  .create({
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  })
  .asResponse();

console.log("Status:", rawResponse.status, rawResponse.statusText);
console.log("Request-ID:", rawResponse.headers.get("request-id"));
// Read body manually if needed
const body = await rawResponse.json();

// Method 2: .withResponse() — returns both the parsed SDK object and the raw
// Response. The body IS consumed and parsed for you.
const { data: message, response: raw } = await client.messages
  .create({
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  })
  .withResponse();

console.log("Request-ID:", raw.headers.get("request-id"));
console.log("Content:", message.content[0].type === "text" && message.content[0].text);
console.log("Usage:", message.usage);
```

Use `.withResponse()` when you need both the parsed message and response metadata (headers, status). Use `.asResponse()` when you only need the raw response and want to handle body parsing yourself.

### Configure a Custom Fetch Function

Replace the SDK's built-in fetch with a custom implementation for logging, instrumentation, or compatibility:

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Option 1: Pass a custom fetch function
const client = new Anthropic({
  fetch: async (url: RequestInfo, init?: RequestInit) => {
    const start = Date.now();
    console.log(`[SDK] ${init?.method ?? "GET"} ${url}`);
    const response = await globalThis.fetch(url, init);
    console.log(`[SDK] ${response.status} in ${Date.now() - start}ms`);
    return response;
  },
});

// Option 2: Pass extra RequestInit options via fetchOptions
const clientWithOptions = new Anthropic({
  fetchOptions: {
    // Any valid RequestInit properties
    keepalive: true,
  },
});

// Option 3: Polyfill fetch globally (for environments lacking it)
import nodeFetch from "node-fetch";
(globalThis as any).fetch = nodeFetch;

const clientWithPolyfill = new Anthropic();
```

### Configure Proxy Connections

Proxy configuration differs by runtime. Each runtime has its own mechanism:

```typescript
// --- Node.js (using undici) ---
import Anthropic from "@anthropic-ai/sdk";
import { ProxyAgent } from "undici";

const nodeClient = new Anthropic({
  fetchOptions: {
    dispatcher: new ProxyAgent("http://proxy.example.com:8080"),
  },
});

// --- Bun ---
const bunClient = new Anthropic({
  fetchOptions: {
    proxy: "http://proxy.example.com:8080",
  },
});

// --- Deno ---
const httpClient = Deno.createHttpClient({
  proxy: { url: "http://proxy.example.com:8080" },
});
const denoClient = new Anthropic({
  fetchOptions: {
    client: httpClient,
  },
});
```

### Call Undocumented Endpoints

Access API endpoints that are not yet in the SDK's typed interface using the generic HTTP methods:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Use client.post(), client.get(), client.put(), client.delete()
const result = await client.post("/some/preview/endpoint", {
  body: {
    some_prop: "value",
    another_prop: 42,
  },
  query: {
    some_query_arg: "filter",
  },
});

console.log(result);
```

These methods handle authentication, retries, and base URL automatically.

### Pass Undocumented Parameters

Send parameters that are not yet in the SDK's TypeScript types:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
  // @ts-expect-error — parameter exists in the API but not yet in SDK types
  some_preview_param: "experimental_value",
});
```

Use `@ts-expect-error` on the line immediately before the undocumented property. This suppresses the TypeScript error while documenting that it is intentional.

### Access Undocumented Response Properties

Read response fields that are not yet in the SDK's type definitions:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});

// Option 1: @ts-expect-error
// @ts-expect-error — preview field not in types yet
const previewField = message.some_new_field;

// Option 2: type casting
const previewField2 = (message as any).some_new_field;
```

### Override Default Headers

The SDK sends `anthropic-version: 2023-06-01` automatically. Override it or add custom headers per-request:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create(
  {
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  },
  {
    headers: {
      "anthropic-version": "2024-01-01",  // Override SDK default
      "X-Custom-Header": "my-value",      // Add custom header
    },
  }
);
```

The second argument to any SDK method accepts request options including `headers`, `signal`, and `timeout`.

### Deploy on Amazon Bedrock

Use the `@anthropic-ai/bedrock-sdk` package to call Claude through Amazon Bedrock:

```typescript
// npm install @anthropic-ai/bedrock-sdk
import { AnthropicBedrock } from "@anthropic-ai/bedrock-sdk";

// Uses AWS credentials from environment (AWS_ACCESS_KEY_ID,
// AWS_SECRET_ACCESS_KEY, AWS_REGION) or the default credential chain
const client = new AnthropicBedrock();

const message = await client.messages.create({
  // Bedrock uses full model ARN-style IDs
  model: "anthropic.claude-opus-4-6-v1",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Explain quantum computing." }],
});

console.log(message.content[0].type === "text" && message.content[0].text);
```

The Bedrock SDK mirrors the main SDK's interface. Streaming, tools, and multi-turn conversations all work the same way.

### Deploy on Google Vertex AI

Use the `@anthropic-ai/vertex-sdk` package to call Claude through Google Cloud Vertex AI:

```typescript
// npm install @anthropic-ai/vertex-sdk
import { AnthropicVertex } from "@anthropic-ai/vertex-sdk";

// Uses Google Cloud credentials from environment
// (CLOUD_ML_REGION, ANTHROPIC_VERTEX_PROJECT_ID, or Application Default Credentials)
const client = new AnthropicVertex();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Explain quantum computing." }],
});

console.log(message.content[0].type === "text" && message.content[0].text);
```

## Quick Reference

### Raw Response Methods

| Method | Body Consumed | Returns | Use When |
|---|---|---|---|
| `.asResponse()` | No | `Response` | You only need headers/status |
| `.withResponse()` | Yes | `{ data, response }` | You need both parsed data and headers |

### Proxy Configuration by Runtime

| Runtime | Configuration Key | Value Type |
|---|---|---|
| Node.js | `fetchOptions.dispatcher` | `undici.ProxyAgent` instance |
| Bun | `fetchOptions.proxy` | `string` (proxy URL) |
| Deno | `fetchOptions.client` | `Deno.HttpClient` instance |

### Platform SDK Packages

| Platform | Package | Model ID Format |
|---|---|---|
| Direct API | `@anthropic-ai/sdk` | `claude-opus-4-6` |
| Amazon Bedrock | `@anthropic-ai/bedrock-sdk` | `anthropic.claude-opus-4-6-v1` |
| Google Vertex AI | `@anthropic-ai/vertex-sdk` | `claude-opus-4-6` |

### Generic HTTP Methods

| Method | Usage |
|---|---|
| `client.get(path, options?)` | GET requests to undocumented endpoints |
| `client.post(path, options?)` | POST requests with body and query params |
| `client.put(path, options?)` | PUT requests for updates |
| `client.delete(path, options?)` | DELETE requests for resource removal |

### Per-Request Options

| Option | Type | Description |
|---|---|---|
| `headers` | `Record<string, string>` | Override or add HTTP headers |
| `signal` | `AbortSignal` | Cancel the request |
| `timeout` | `number` | Override client-level timeout (ms) |

## Common Mistakes

**Trying to read the body after `.asResponse()`**
When using `.asResponse()`, the response body is unconsumed. You must call `response.json()` or `response.text()` yourself. If you want the SDK to parse the response, use `.withResponse()` instead.

**Using the wrong proxy config key for the runtime**
Node.js uses `fetchOptions.dispatcher` with an `undici.ProxyAgent`, Bun uses `fetchOptions.proxy` as a string, and Deno uses `fetchOptions.client`. Using the wrong key silently ignores the proxy configuration.

**Forgetting to install the platform-specific SDK package**
`AnthropicBedrock` comes from `@anthropic-ai/bedrock-sdk`, not from `@anthropic-ai/sdk`. Similarly, `AnthropicVertex` comes from `@anthropic-ai/vertex-sdk`. Install the correct package for your deployment target.

**Using direct API model IDs on Bedrock**
Bedrock uses its own model ID format: `anthropic.claude-opus-4-6-v1` instead of `claude-opus-4-6`. Using the wrong format results in a "model not found" error.

**Overriding `anthropic-version` without understanding the implications**
Changing the API version header may alter response formats or available features. Only override it if you specifically need a different API version, and test thoroughly.

**Using `@ts-ignore` instead of `@ts-expect-error`**
Prefer `@ts-expect-error` over `@ts-ignore`. The former will produce a TypeScript error if the suppressed error goes away (e.g., when the SDK adds the type), alerting you to remove the workaround. `@ts-ignore` silently suppresses errors forever.

## References

- Anthropic TypeScript SDK repository: https://github.com/anthropics/anthropic-sdk-typescript
- Anthropic API documentation: https://docs.anthropic.com/en/api
- Amazon Bedrock SDK: https://github.com/anthropics/anthropic-sdk-typescript/tree/main/packages/bedrock-sdk
- Google Vertex AI SDK: https://github.com/anthropics/anthropic-sdk-typescript/tree/main/packages/vertex-sdk
- SDK README: https://github.com/anthropics/anthropic-sdk-typescript/blob/main/README.md
