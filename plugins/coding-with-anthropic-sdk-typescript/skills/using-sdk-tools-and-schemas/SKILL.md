---
name: using-sdk-tools-and-schemas
description: "Use when giving Claude tools in the TypeScript SDK, defining tool schemas with JSON Schema or Zod, handling tool_use responses in an agentic loop, configuring tool_choice, enabling built-in or server tools, or running automatic tool execution with runTools. Also use for tool result formatting, Zod-to-JSON-schema conversion, 'tool_use ids were found without tool_result' errors, or building an agent that calls external APIs and databases."
---

## Overview

The Anthropic TypeScript SDK supports tool use (function calling) where Claude can request execution of developer-defined tools during a conversation. Tools are defined with JSON Schema input specifications, and the SDK provides helpers for Zod-based schemas and automatic tool execution loops. This skill covers tool definition, tool choice configuration, manual and automated tool result handling, and built-in server tools.

## When to Use

- Defining tools with JSON Schema input definitions for Claude to call
- Configuring tool choice to control when and which tools Claude uses
- Using Zod schemas to define type-safe tool inputs with automatic validation
- Implementing the tool use loop (send request, execute tool, return result)
- Using the `toolRunner` helper to automate multi-turn tool execution
- Enabling built-in server tools (bash, text editor, web search)
- Troubleshooting "tool_use" stop reasons or malformed tool inputs
- Controlling parallel tool use behavior

When NOT to use:

- For basic message creation without tools (see `creating-sdk-messages`)
- For streaming tool use responses (see `streaming-sdk-responses`)
- For SDK installation or client setup (see `setting-up-anthropic-sdk-typescript`)

## Core Patterns

### Define a Tool with JSON Schema

Tools are defined in the `tools` array of a message request. Each tool has a `name`, `description`, and `input_schema` using JSON Schema:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "What is the weather in San Francisco?" }],
  tools: [
    {
      name: "get_weather",
      description: "Get the current weather for a given location. Returns temperature and conditions.",
      input_schema: {
        type: "object" as const,
        properties: {
          location: {
            type: "string",
            description: "City name, e.g. 'San Francisco, CA'",
          },
          units: {
            type: "string",
            enum: ["celsius", "fahrenheit"],
            description: "Temperature units. Defaults to fahrenheit.",
          },
        },
        required: ["location"],
      },
    },
  ],
});

// When Claude wants to use a tool, stop_reason is "tool_use"
console.log(message.stop_reason); // "tool_use"
```

Write clear, specific tool descriptions. Claude uses the `description` field to decide when and how to use the tool. Include what the tool returns and any constraints.

### Configure Tool Choice

Control whether and which tools Claude may use with the `tool_choice` parameter:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// "auto" (default) -- Claude decides whether to use a tool
await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello" }],
  tools: [/* ... */],
  tool_choice: { type: "auto" },
});

// "any" -- Claude must use at least one tool
await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Check the weather" }],
  tools: [/* ... */],
  tool_choice: { type: "any" },
});

// "tool" -- Claude must use a specific tool
await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Check the weather" }],
  tools: [/* ... */],
  tool_choice: { type: "tool", name: "get_weather" },
});

// "none" -- Claude cannot use any tools (tools still visible for context)
await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "What tools do you have?" }],
  tools: [/* ... */],
  tool_choice: { type: "none" },
});
```

All types except `"none"` support `disable_parallel_tool_use: boolean` to prevent Claude from calling multiple tools in a single response.

### Implement the Manual Tool Use Loop

When Claude returns a `tool_use` content block, execute the tool and send back a `tool_result`:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const tools: Anthropic.Tool[] = [
  {
    name: "get_weather",
    description: "Get weather for a location",
    input_schema: {
      type: "object" as const,
      properties: {
        location: { type: "string", description: "City name" },
      },
      required: ["location"],
    },
  },
];

// Step 1: Send the initial request
const messages: Anthropic.MessageParam[] = [
  { role: "user", content: "What is the weather in Boston?" },
];

let response = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages,
  tools,
});

// Step 2: Loop until Claude stops requesting tools
while (response.stop_reason === "tool_use") {
  // Find all tool_use blocks in the response
  const toolUseBlocks = response.content.filter(
    (block): block is Anthropic.ToolUseBlock => block.type === "tool_use"
  );

  // Execute each tool and collect results
  const toolResults: Anthropic.ToolResultBlockParam[] = toolUseBlocks.map(
    (toolUse) => ({
      type: "tool_result" as const,
      tool_use_id: toolUse.id,
      content: executeMyTool(toolUse.name, toolUse.input), // your implementation
    })
  );

  // Step 3: Append assistant response and tool results to message history
  messages.push({ role: "assistant", content: response.content });
  messages.push({ role: "user", content: toolResults });

  // Step 4: Send the next request with tool results
  response = await client.messages.create({
    model: "claude-opus-4-6",
    max_tokens: 1024,
    messages,
    tools,
  });
}

// Final text response
const textBlock = response.content.find((b) => b.type === "text");
if (textBlock && textBlock.type === "text") {
  console.log(textBlock.text);
}

function executeMyTool(name: string, input: unknown): string {
  // Route to actual tool implementation
  if (name === "get_weather") {
    const { location } = input as { location: string };
    return `Weather in ${location}: 62°F, partly cloudy`;
  }
  return "Unknown tool";
}
```

The loop pattern: send request, check for `tool_use` stop reason, execute tools, append assistant content and tool results to messages, repeat.

### Use Zod Tool Helpers for Type-Safe Tools

The SDK provides a `betaZodTool` helper that combines tool definition, Zod validation, and execution in one object:

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { betaZodTool } from "@anthropic-ai/sdk/helpers/beta/zod";
import { z } from "zod";

const client = new Anthropic();

// Define a tool with Zod schema and an inline run function
const weatherTool = betaZodTool({
  name: "get_weather",
  description: "Get weather for a location",
  inputSchema: z.object({
    location: z.string().describe("City name, e.g. 'San Francisco'"),
    units: z.enum(["celsius", "fahrenheit"]).default("fahrenheit"),
  }),
  run: async (input) => {
    // input is fully typed: { location: string; units: "celsius" | "fahrenheit" }
    return `Weather in ${input.location}: 72°F and sunny`;
  },
});

// Use with toolRunner for automatic multi-turn execution
const finalMessage = await client.beta.messages.toolRunner({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "What's the weather in SF?" }],
  tools: [weatherTool],
});

// toolRunner handles the full loop: tool calls, execution, result submission
console.log(finalMessage.content);
```

Install `zod` as a dependency: `npm install zod`. The `betaZodTool` helper automatically converts Zod schemas to JSON Schema for the API and validates inputs before calling `run`.

### Use the Tool Runner for Automatic Loops

The `toolRunner` helper manages the entire tool use conversation loop. It calls tools, sends results back to Claude, and repeats until Claude produces a final text response:

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { betaZodTool } from "@anthropic-ai/sdk/helpers/beta/zod";
import { z } from "zod";

const client = new Anthropic();

const calculatorTool = betaZodTool({
  name: "calculate",
  description: "Evaluate a math expression",
  inputSchema: z.object({
    expression: z.string().describe("Math expression to evaluate"),
  }),
  run: async (input) => {
    // In production, use a proper math parser -- not eval
    return String(Function(`"use strict"; return (${input.expression})`)());
  },
});

const lookupTool = betaZodTool({
  name: "lookup_price",
  description: "Look up the price of an item",
  inputSchema: z.object({
    item: z.string(),
  }),
  run: async (input) => {
    const prices: Record<string, number> = { apple: 1.5, banana: 0.75 };
    return JSON.stringify({ item: input.item, price: prices[input.item] ?? 0 });
  },
});

// toolRunner handles multi-tool, multi-turn conversations
const result = await client.beta.messages.toolRunner({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [
    { role: "user", content: "How much do 3 apples and 5 bananas cost total?" },
  ],
  tools: [calculatorTool, lookupTool],
});

console.log(result.content);
```

### Enable Built-in Server Tools

Claude supports server-side tools that run in the API infrastructure. Define them by `type` instead of providing an `input_schema`:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const message = await client.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 4096,
  messages: [{ role: "user", content: "Search for the latest TypeScript release" }],
  tools: [
    // Web search -- runs server-side, no tool_result needed
    {
      type: "web_search_20250305",
      name: "web_search",
      max_uses: 5,               // optional: limit search calls
      // allowed_domains: ["typescriptlang.org"],  // optional: restrict domains
      // blocked_domains: ["example.com"],          // optional: block domains
    },
  ],
});
```

Other server tools:

```typescript
// Bash tool -- executes shell commands server-side
{ type: "bash_20250124", name: "bash" }

// Text editor -- reads/writes files server-side
{ type: "text_editor_20250124", name: "str_replace_editor" }
```

Server tools are executed by the API. They do not require sending `tool_result` messages back.

### Tool Options: Strict Mode and Input Streaming

```typescript
const tools: Anthropic.Tool[] = [
  {
    name: "get_weather",
    description: "Get weather for a location",
    input_schema: {
      type: "object" as const,
      properties: {
        location: { type: "string" },
      },
      required: ["location"],
    },
    // Guarantee schema-valid inputs (API validates before returning)
    strict: true,
    // Stream partial tool inputs incrementally (useful with streaming)
    eager_input_streaming: true,
  },
];
```

Use `strict: true` when malformed inputs would cause errors in your tool implementation. Use `eager_input_streaming: true` with streaming to get tool input tokens as they are generated.

## Quick Reference

| Tool Choice | Behavior |
|---|---|
| `{ type: "auto" }` | Claude decides whether to use tools (default) |
| `{ type: "any" }` | Claude must use at least one tool |
| `{ type: "tool", name: "..." }` | Claude must use the named tool |
| `{ type: "none" }` | Claude cannot use tools |

| Response Field | Meaning |
|---|---|
| `stop_reason: "tool_use"` | Claude wants to call one or more tools |
| `stop_reason: "end_turn"` | Claude finished with a text response |
| `content[].type === "tool_use"` | A tool call with `id`, `name`, `input` |
| `content[].type === "text"` | A text response block |

| Server Tool Type | Name | Purpose |
|---|---|---|
| `bash_20250124` | `bash` | Execute shell commands |
| `text_editor_20250124` | `str_replace_editor` | Read/edit files |
| `web_search_20250305` | `web_search` | Search the web |

| Tool Option | Type | Purpose |
|---|---|---|
| `strict` | `boolean` | Guarantee schema-valid tool inputs |
| `eager_input_streaming` | `boolean` | Stream tool inputs incrementally |
| `cache_control` | `object` | Cache tool definitions for prompt caching |

## Common Mistakes

**Forgetting to send tool results back**
When `stop_reason` is `"tool_use"`, you must execute the tool and send a `tool_result` message. If you send another user message instead, the API returns an error. The assistant message containing `tool_use` blocks must be followed by a user message with matching `tool_result` blocks.

**Mismatched tool_use_id in tool results**
Each `tool_result` must reference the exact `tool_use_id` from the corresponding `tool_use` block. A mismatched or missing ID causes a 400 error.

**Not looping on tool use responses**
Claude may need multiple tool calls to answer a question. A single request-response is not enough. Always loop while `stop_reason === "tool_use"` and send results back until you get `"end_turn"`.

**Sending tool_result for server tools**
Server tools (bash, text editor, web search) are executed by the API itself. Do not send `tool_result` messages for these tools. They appear in the response content but are handled automatically.

**Overly vague tool descriptions**
Claude relies on the `description` field to understand when and how to use a tool. Descriptions like "does stuff" lead to incorrect tool usage. Include what the tool does, what it returns, and any constraints on inputs.

**Using `type: "object"` without `as const`**
TypeScript narrows string literals only with `as const`. Without it, `type: "object"` is typed as `string`, which does not match the SDK's expected literal type. Add `as const` to the `type` field or use the Zod helper to avoid this entirely.

## References

- Tool use guide: https://docs.anthropic.com/en/docs/build-with-claude/tool-use/overview
- Anthropic TypeScript SDK: https://github.com/anthropics/anthropic-sdk-typescript
- Zod helper source: https://github.com/anthropics/anthropic-sdk-typescript/tree/main/helpers
- JSON Schema specification: https://json-schema.org/
- Server tool types: https://docs.anthropic.com/en/docs/build-with-claude/tool-use/server-tools
