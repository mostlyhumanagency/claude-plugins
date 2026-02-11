---
name: streaming-sdk-responses
description: "Use when streaming Claude responses token by token in TypeScript, building a real-time chat UI, displaying tokens as they arrive, processing text deltas incrementally, using the SDK streaming helper (.stream()), or cancelling in-progress streams. Also use for client.messages.stream, on('text') events, stream error handling, reducing time-to-first-token, or implementing a typewriter effect in a Claude-powered app."
---

## Overview

The Anthropic TypeScript SDK provides two streaming interfaces: a low-level async iterator using `stream: true` and a high-level helper via `.stream()`. Both deliver server-sent events (SSE) incrementally as Claude generates output, enabling real-time display, lower time-to-first-token, and reliable handling of long responses that might otherwise timeout.

## When to Use

- Displaying Claude's response as it generates (typewriter effect, CLI output, chat UI)
- Processing large responses that may exceed non-streaming timeout limits
- Building real-time applications that need incremental content delivery
- Implementing cancellation logic to stop generation early
- Monitoring content blocks as they arrive (text, tool use, thinking)

When NOT to use:

- For simple request/response patterns where latency is acceptable (see `creating-sdk-messages`)
- For batch processing where you need only the final result and don't need incremental output
- For token counting or parameter configuration (see `creating-sdk-messages`)

## Core Patterns

### Low-level Streaming with `stream: true`

Pass `stream: true` to `messages.create()` to receive an async iterable of SSE events:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Explain how async iterators work in JavaScript" }],
  stream: true,
});

// Process events as they arrive
for await (const event of stream) {
  if (
    event.type === "content_block_delta" &&
    event.delta.type === "text_delta"
  ) {
    process.stdout.write(event.delta.text);
  }
}
console.log(); // Final newline
```

This approach gives direct access to every SSE event, uses minimal memory since it does not accumulate the final message, and supports early cancellation by breaking from the loop.

### High-level Streaming with `.stream()`

The `.stream()` helper provides event callbacks and automatically accumulates the final message:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = client.messages
  .stream({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Write a short story about a robot" }],
  })
  .on("text", (text) => {
    // Called for each text chunk
    process.stdout.write(text);
  });

// Wait for completion and get the full message
const message = await stream.finalMessage();
console.log("\n\nTotal tokens:", message.usage.output_tokens);
```

The helper accumulates all content blocks internally, so calling `finalMessage()` returns the complete `Message` object identical to what a non-streaming call would return.

### Collect Full Text from a Stream

When you need the complete text but still want streaming behavior (for timeout avoidance or progress indication):

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 2048,
  messages: [{ role: "user", content: "List 50 programming languages" }],
  stream: true,
});

const chunks: string[] = [];
for await (const event of stream) {
  if (
    event.type === "content_block_delta" &&
    event.delta.type === "text_delta"
  ) {
    chunks.push(event.delta.text);
  }
}
const fullText = chunks.join("");
```

### Cancel a Stream Early

Break from the `for await` loop to cancel the underlying HTTP connection:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 4096,
  messages: [{ role: "user", content: "Write a very long essay" }],
  stream: true,
});

let totalChars = 0;
for await (const event of stream) {
  if (
    event.type === "content_block_delta" &&
    event.delta.type === "text_delta"
  ) {
    totalChars += event.delta.text.length;
    process.stdout.write(event.delta.text);

    // Stop after 500 characters
    if (totalChars > 500) {
      console.log("\n[Cancelled after 500 chars]");
      break; // Cancels the stream and closes the connection
    }
  }
}
```

### Stream with Extended Thinking

When extended thinking is enabled, thinking content arrives as `thinking_delta` events before the text response:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 16000,
  thinking: { type: "enabled", budget_tokens: 10000 },
  messages: [
    { role: "user", content: "What are the implications of Godel's incompleteness theorems?" },
  ],
  stream: true,
});

for await (const event of stream) {
  if (event.type === "content_block_start") {
    if (event.content_block.type === "thinking") {
      console.log("--- Thinking started ---");
    } else if (event.content_block.type === "text") {
      console.log("--- Response started ---");
    }
  }

  if (event.type === "content_block_delta") {
    if (event.delta.type === "thinking_delta") {
      process.stdout.write(event.delta.thinking);
    } else if (event.delta.type === "text_delta") {
      process.stdout.write(event.delta.text);
    }
  }
}
```

### Stream with Tool Use

Tool use blocks arrive as `input_json_delta` events. The high-level helper simplifies this:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const tools: Anthropic.Tool[] = [
  {
    name: "get_weather",
    description: "Get current weather for a location",
    input_schema: {
      type: "object" as const,
      properties: {
        location: { type: "string", description: "City name" },
      },
      required: ["location"],
    },
  },
];

const stream = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  tools,
  messages: [{ role: "user", content: "What is the weather in Tokyo?" }],
  stream: true,
});

let currentToolName = "";
let toolInputJson = "";

for await (const event of stream) {
  switch (event.type) {
    case "content_block_start":
      if (event.content_block.type === "tool_use") {
        currentToolName = event.content_block.name;
        toolInputJson = "";
        console.log(`Tool call: ${currentToolName}`);
      }
      break;

    case "content_block_delta":
      if (event.delta.type === "input_json_delta") {
        toolInputJson += event.delta.partial_json;
      } else if (event.delta.type === "text_delta") {
        process.stdout.write(event.delta.text);
      }
      break;

    case "content_block_stop":
      if (currentToolName) {
        const input = JSON.parse(toolInputJson);
        console.log(`Tool input:`, input);
        currentToolName = "";
      }
      break;
  }
}
```

### Handle Stream Events with the High-level Helper

The `.stream()` helper supports several event types:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const stream = client.messages
  .stream({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 1024,
    messages: [{ role: "user", content: "Hello" }],
  })
  .on("text", (text) => {
    // Fired for each text delta
    process.stdout.write(text);
  })
  .on("message", (message) => {
    // Fired once when the complete message is assembled
    console.log("\nDone. Stop reason:", message.stop_reason);
  })
  .on("error", (error) => {
    // Fired on stream errors
    console.error("Stream error:", error);
  });

await stream.finalMessage();
```

## Quick Reference

### SSE Event Types

| Event Type | Description | Key Fields |
|---|---|---|
| `message_start` | Stream begins | `message` (initial Message object) |
| `content_block_start` | New content block | `index`, `content_block` (type, initial data) |
| `content_block_delta` | Incremental content | `index`, `delta` (see Delta Types below) |
| `content_block_stop` | Block complete | `index` |
| `message_delta` | Message-level update | `delta.stop_reason`, `usage.output_tokens` |
| `message_stop` | Stream finished | (none) |
| `ping` | Keepalive | (none) |
| `error` | Error occurred | `error` |

### Delta Types

| Delta Type | Parent Event | Key Fields |
|---|---|---|
| `text_delta` | `content_block_delta` | `text` |
| `input_json_delta` | `content_block_delta` | `partial_json` |
| `thinking_delta` | `content_block_delta` | `thinking` |

### Low-level vs High-level Comparison

| Feature | `stream: true` | `.stream()` helper |
|---|---|---|
| Access pattern | `for await...of` | `.on()` callbacks |
| Memory usage | Low (no accumulation) | Higher (builds final message) |
| Final message | Must build manually | `await stream.finalMessage()` |
| Cancellation | `break` from loop | Abort controller |
| Best for | Custom processing, memory-sensitive | Convenience, simple text streaming |

## Common Mistakes

**Not handling all delta types**
A stream can contain `text_delta`, `input_json_delta`, and `thinking_delta` events. Code that only checks for `text_delta` silently drops tool use input and thinking content. Always handle all delta types relevant to your use case, or at minimum log unexpected types.

**Accumulating JSON deltas incorrectly**
Tool use input arrives as `input_json_delta` events containing partial JSON strings. These must be concatenated as raw strings and parsed only after the `content_block_stop` event. Attempting to parse each delta individually fails because partial JSON is not valid JSON.

**Using non-streaming for large `max_tokens` values**
Non-streaming requests with large `max_tokens` can timeout. The SDK throws an error if expected latency exceeds 10 minutes for non-streaming calls. Use streaming for any request where `max_tokens` is large or where response time is unpredictable.

**Forgetting to await `finalMessage()`**
When using the `.stream()` helper, the `.on()` methods return the stream object for chaining, not a Promise. You must `await stream.finalMessage()` (or iterate the stream) to actually start and complete the request. Without this, the stream may never execute.

**Mixing up `stream: true` and `.stream()`**
`client.messages.create({ ..., stream: true })` and `client.messages.stream({ ... })` are different APIs. The first returns a raw async iterable. The second returns a `MessageStream` with `.on()`, `.finalMessage()`, and other helper methods. Do not pass `stream: true` to `.stream()` -- the helper handles streaming internally.

**Not draining the stream on error**
If you catch an error mid-stream but do not break from the loop or abort the stream, the HTTP connection remains open. Always ensure the stream is fully consumed or explicitly cancelled when handling errors.

## References

- Streaming documentation: https://docs.anthropic.com/en/api/streaming
- Messages API streaming: https://docs.anthropic.com/en/api/messages-streaming
- TypeScript SDK streaming helpers: https://github.com/anthropics/anthropic-sdk-typescript#streaming-helpers
- Server-sent events specification: https://html.spec.whatwg.org/multipage/server-sent-events.html
