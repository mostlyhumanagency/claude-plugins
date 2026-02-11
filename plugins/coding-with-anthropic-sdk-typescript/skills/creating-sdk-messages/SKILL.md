---
name: creating-sdk-messages
description: "Use when sending a prompt to Claude via the TypeScript SDK, calling client.messages.create, building a chatbot or multi-turn conversation, handling response objects and content blocks, setting model parameters (temperature, max_tokens, top_p, stop_sequences), counting tokens, or configuring system prompts. Also use for constructing multi-turn message arrays, processing text and tool_use blocks, or building any TypeScript application that calls Claude."
---

## Overview

The Messages API is the primary interface for interacting with Claude models through the TypeScript SDK. It accepts a list of messages with alternating user/assistant roles and returns a structured response containing text, tool use blocks, or thinking blocks. This skill covers request construction, parameter configuration, response handling, multi-turn conversations, and token counting.

## When to Use

- Sending a prompt to Claude and receiving a response
- Building multi-turn conversations with message history
- Configuring model parameters (temperature, top_p, stop sequences)
- Setting system prompts for conversation context
- Counting tokens before sending a request
- Reading and processing response content blocks
- Checking usage statistics (input/output tokens, cache hits)
- Using extended thinking or output configuration

When NOT to use:

- For installing or configuring the SDK client (see `setting-up-anthropic-sdk-typescript`)
- For streaming responses incrementally (see `streaming-sdk-responses`)
- For tool use / function calling patterns (see dedicated tool use skill)

## Core Patterns

### Send a Single Message

The minimum required parameters are `model`, `max_tokens`, and `messages`:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  messages: [{ role: "user", content: "What is the capital of France?" }],
});

// Extract text from the response
const textBlock = message.content[0];
if (textBlock.type === "text") {
  console.log(textBlock.text); // "The capital of France is Paris."
}
```

### Use a System Prompt

Set conversation-level instructions with the `system` parameter:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  system: "You are a concise technical writer. Answer in 2 sentences or fewer.",
  messages: [{ role: "user", content: "Explain TCP handshakes" }],
});
```

The system prompt can also be an array of content blocks for cache control:

```typescript
const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  system: [
    {
      type: "text",
      text: "You are a helpful coding assistant with deep TypeScript expertise.",
      cache_control: { type: "ephemeral" },
    },
  ],
  messages: [{ role: "user", content: "How do conditional types work?" }],
});
```

### Build a Multi-turn Conversation

Messages must alternate between `user` and `assistant` roles. Include previous turns to maintain context:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const conversation: Anthropic.MessageParam[] = [
  { role: "user", content: "My name is Alice." },
  { role: "assistant", content: "Hello Alice! How can I help you today?" },
  { role: "user", content: "What is my name?" },
];

const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 256,
  messages: conversation,
});

// Response: "Your name is Alice."
```

To accumulate conversation turns in a loop:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const messages: Anthropic.MessageParam[] = [];

async function chat(userText: string): Promise<string> {
  messages.push({ role: "user", content: userText });

  const response = await client.messages.create({
    model: "claude-sonnet-4-5-20250929",
    max_tokens: 1024,
    messages,
  });

  // Append assistant response to history
  messages.push({ role: "assistant", content: response.content });

  const textBlock = response.content.find((b) => b.type === "text");
  return textBlock ? textBlock.text : "";
}

const reply1 = await chat("Hello, I need help with TypeScript");
const reply2 = await chat("How do I use generics?");
```

### Configure Model Parameters

Control response generation with sampling parameters:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 2048,
  temperature: 0.3,          // Lower = more deterministic (0.0-1.0, default 1.0)
  top_p: 0.9,                // Nucleus sampling threshold
  top_k: 40,                 // Limit to top K tokens
  stop_sequences: ["END"],   // Stop generation at these strings
  metadata: {
    user_id: "user-abc-123", // For usage tracking and rate limits
  },
  messages: [{ role: "user", content: "Write a haiku about code" }],
});
```

### Enable Extended Thinking

Extended thinking lets Claude reason through complex problems before responding:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 16000,
  thinking: {
    type: "enabled",
    budget_tokens: 10000, // Max tokens for internal reasoning
  },
  messages: [
    {
      role: "user",
      content: "Solve this step by step: If 3x + 7 = 22, what is x?",
    },
  ],
});

// Response may contain thinking blocks followed by text blocks
for (const block of message.content) {
  if (block.type === "thinking") {
    console.log("Thinking:", block.thinking);
  } else if (block.type === "text") {
    console.log("Answer:", block.text);
  }
}
```

Adaptive thinking adjusts the thinking budget automatically:

```typescript
const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 16000,
  thinking: { type: "adaptive" },
  messages: [{ role: "user", content: "What is 2+2?" }],
});
```

### Send Images

Pass images as base64 or URL content blocks:

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";

const client = new Anthropic();

// Base64 image
const imageData = readFileSync("chart.png").toString("base64");

const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  messages: [
    {
      role: "user",
      content: [
        {
          type: "image",
          source: {
            type: "base64",
            media_type: "image/png",
            data: imageData,
          },
        },
        { type: "text", text: "Describe what this chart shows" },
      ],
    },
  ],
});
```

### Count Tokens Before Sending

Estimate input token count without making a generation request:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const tokenCount = await client.messages.countTokens({
  model: "claude-sonnet-4-5-20250929",
  messages: [
    {
      role: "user",
      content: "Explain the theory of relativity in detail.",
    },
  ],
});

console.log(`Input tokens: ${tokenCount.input_tokens}`);

// Use this to check costs or truncate context before sending
if (tokenCount.input_tokens > 50000) {
  console.warn("Large request -- consider trimming context");
}
```

### Process the Response Object

The full response contains content blocks, stop reason, and usage data:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
});

// Response metadata
console.log(message.id);          // "msg_01A2B3C4..."
console.log(message.model);       // "claude-sonnet-4-5-20250929"
console.log(message.stop_reason); // "end_turn" | "max_tokens" | "stop_sequence" | "tool_use"

// Usage statistics
console.log(message.usage.input_tokens);                  // Token count for input
console.log(message.usage.output_tokens);                 // Token count for output
console.log(message.usage.cache_creation_input_tokens);   // Tokens written to cache
console.log(message.usage.cache_read_input_tokens);       // Tokens read from cache

// Iterate content blocks
for (const block of message.content) {
  switch (block.type) {
    case "text":
      console.log("Text:", block.text);
      break;
    case "tool_use":
      console.log("Tool call:", block.name, block.input);
      break;
    case "thinking":
      console.log("Thinking:", block.thinking);
      break;
  }
}
```

## Quick Reference

### Required Parameters

| Parameter | Type | Description |
|---|---|---|
| `model` | `string` | Model ID (`claude-opus-4-6`, `claude-sonnet-4-5-20250929`, `claude-haiku-4-5-20251001`) |
| `max_tokens` | `number` | Maximum tokens to generate |
| `messages` | `MessageParam[]` | Array of `{ role, content }` objects |

### Optional Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `system` | `string \| TextBlockParam[]` | none | System prompt |
| `temperature` | `number` | `1.0` | Sampling temperature (0.0-1.0) |
| `top_p` | `number` | none | Nucleus sampling cutoff |
| `top_k` | `number` | none | Top-K sampling limit |
| `stop_sequences` | `string[]` | none | Custom stop strings |
| `metadata` | `{ user_id: string }` | none | Request metadata for tracking |
| `thinking` | `ThinkingConfig` | disabled | Extended thinking configuration |
| `stream` | `boolean` | `false` | Enable SSE streaming |
| `service_tier` | `string` | `"auto"` | `"auto"` or `"standard_only"` |

### Stop Reasons

| Value | Meaning |
|---|---|
| `end_turn` | Natural end of response |
| `max_tokens` | Hit `max_tokens` limit |
| `stop_sequence` | Hit a custom stop sequence |
| `tool_use` | Model wants to call a tool |
| `pause_turn` | Turn paused (agentic workflows) |
| `refusal` | Model declined to respond |

### Content Block Types (Response)

| Type | Key Fields | Description |
|---|---|---|
| `text` | `text` | Generated text content |
| `tool_use` | `id`, `name`, `input` | Tool call request |
| `thinking` | `thinking`, `signature` | Extended thinking output |

## Common Mistakes

**Forgetting to check `stop_reason` for `max_tokens`**
When `stop_reason` is `"max_tokens"`, the response was truncated. Always check this if complete output matters. Increase `max_tokens` or implement continuation logic.

**Not alternating message roles**
Messages must alternate `user` / `assistant`. Two consecutive `user` messages cause an API error. If you need to combine context, merge them into a single `user` message with multiple content blocks.

**Using `temperature: 0` instead of `temperature: 0.0`**
Both work, but be aware that `temperature: 0` does not guarantee deterministic output. Claude may still produce slight variations. For maximum reproducibility, use `temperature: 0.0` and `top_k: 1`.

**Ignoring cache usage tokens**
The `usage` object includes `cache_creation_input_tokens` and `cache_read_input_tokens`. When using prompt caching, these fields show how much of your input was cached vs. freshly processed. Ignoring them leads to inaccurate cost calculations.

**Setting `max_tokens` too low for thinking mode**
When extended thinking is enabled, `max_tokens` must be large enough to accommodate both the thinking tokens and the visible response tokens. The `budget_tokens` for thinking comes out of the total `max_tokens` budget. If `max_tokens` is too low, the response may be cut short.

**Passing `thinking` blocks incorrectly in multi-turn**
When continuing a conversation that used extended thinking, include the `thinking` blocks from the assistant response in your message history. Omitting or modifying thinking blocks (other than redacting the `thinking` field while keeping the `signature`) causes validation errors.

## References

- Messages API documentation: https://docs.anthropic.com/en/api/messages
- Token counting: https://docs.anthropic.com/en/api/counting-tokens
- Extended thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
- Vision (images): https://docs.anthropic.com/en/docs/build-with-claude/vision
- Prompt caching: https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
