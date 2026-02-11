---
name: streaming-claude-responses
description: "Use when streaming Claude API responses in real time, parsing Server-Sent Events (SSE), handling text_delta/input_json_delta/thinking_delta events, building a streaming chat UI, displaying tokens as they arrive, or recovering from stream errors. Also use for stream event types, partial response handling, streaming with tool use and extended thinking, or reducing perceived latency in Claude-powered applications."
---

## Overview

Streaming lets you receive Claude's response incrementally via Server-Sent Events (SSE) instead of waiting for the complete response. Set `"stream": true` in your request body and the API pushes a structured sequence of events so you can render tokens as they arrive, reducing perceived latency for end users.

## When to Use

- Building chat UIs where perceived latency matters
- Working with large `max_tokens` values where HTTP timeouts are a risk
- Displaying tool call progress or thinking steps in real time
- Showing partial results to users before the full response completes
- Implementing typewriter-style text rendering

## When Not to Use

- Batch processing where only the final result matters -- use the non-streaming endpoint or the Message Batches API
- Serverless environments with short HTTP timeouts that cannot hold SSE connections
- Simple request/response patterns where latency is not a concern
- For basic message structure, see the `working-with-claude-messages` skill
- For tool use details, see the `implementing-claude-tool-use` skill
- For extended thinking configuration, see the `using-claude-thinking-and-effort` skill

## Core Patterns

### Basic SSE Streaming

Add `"stream": true` to any Messages API request. The response becomes an SSE event stream instead of a single JSON object.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --data '{
    "model": "claude-sonnet-4-5-20250514",
    "messages": [{"role": "user", "content": "Explain photosynthesis briefly."}],
    "max_tokens": 256,
    "stream": true
  }'
```

### Event Flow

Events always arrive in this order:

1. `message_start` -- contains the `Message` shell with empty `content` and initial `usage`.
2. For each content block:
   - `content_block_start` -- block type and index.
   - One or more `content_block_delta` -- the incremental payload.
   - `content_block_stop`.
3. `message_delta` -- top-level changes including `stop_reason` and cumulative `usage.output_tokens`.
4. `message_stop` -- stream is complete.

Interspersed `ping` events may appear at any point and should be ignored. Always handle unknown event types gracefully by skipping them, as new event types may be added in the future.

### Streaming with Tool Use

When Claude calls tools during streaming, tool input arrives as `input_json_delta` events containing partial JSON strings. Accumulate all partial strings and parse the JSON only after `content_block_stop` fires.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "stream": true,
    "tools": [{
      "name": "get_weather",
      "description": "Get the current weather in a given location",
      "input_schema": {
        "type": "object",
        "properties": {
          "location": {"type": "string", "description": "City and state, e.g. San Francisco, CA"}
        },
        "required": ["location"]
      }
    }],
    "tool_choice": {"type": "any"},
    "messages": [{"role": "user", "content": "What is the weather in San Francisco?"}]
  }'
```

Key behaviors for tool use streaming:

- Tool input streams as `input_json_delta` with `partial_json` strings.
- Accumulate all `partial_json` values, then `JSON.parse()` after `content_block_stop`.
- The `stop_reason` in `message_delta` is `"tool_use"` instead of `"end_turn"`.
- Enable `eager_input_streaming` per tool for even finer-grained parameter streaming.

### Streaming with Extended Thinking

When extended thinking is enabled, the stream produces thinking content before the final answer.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 16000,
    "stream": true,
    "thinking": {
      "type": "enabled",
      "budget_tokens": 10000
    },
    "messages": [{"role": "user", "content": "What is the GCD of 1071 and 462?"}]
  }'
```

The stream produces these blocks in order:

1. A `thinking` content block with `thinking_delta` events containing reasoning text.
2. A `signature_delta` event just before the thinking block closes (used for integrity verification).
3. A `text` content block with the final answer via `text_delta` events.

### Web Search Streaming

When web search tools are enabled, the stream includes additional block types:

- `server_tool_use` blocks appear for search invocations.
- `web_search_tool_result` blocks carry results.

Both appear within the same event stream alongside regular text and tool use blocks.

### Reconstructing the Full Response

To build the complete response from stream events:

1. On `message_start`, initialize the message object from the shell.
2. On `content_block_start`, create a new content block at the given `index`.
3. On `content_block_delta`, append the delta payload to the block at `index`:
   - `text_delta`: append `delta.text` to the text block.
   - `input_json_delta`: append `delta.partial_json` to an accumulator string.
   - `thinking_delta`: append `delta.thinking` to the thinking block.
   - `citations_delta`: append `delta.citation` to the block's citations array.
4. On `content_block_stop`, finalize the block. For tool use blocks, parse the accumulated JSON string.
5. On `message_delta`, read `stop_reason` and `usage.output_tokens`.
6. On `message_stop`, the stream is complete.

### Error Handling in Streams

Errors during streaming arrive as `event: error` with a JSON payload. Common errors:

- `overloaded_error` -- equivalent to HTTP 529. Retry with exponential backoff.
- `api_error` -- server-side issue. Retry after a delay.

For stream recovery after an error, only text blocks can be partially recovered. Tool use and thinking blocks cannot be resumed mid-stream -- you must retry the entire request.

### Eager Input Streaming for Tools

Enable `eager_input_streaming` on individual tool definitions to receive finer-grained parameter streaming. This is useful when tool parameters are large (e.g., generated code) and you want to show partial input to users as it streams.

```json
{
  "name": "write_code",
  "description": "Write code to a file",
  "eager_input_streaming": true,
  "input_schema": {
    "type": "object",
    "properties": {
      "filename": {"type": "string"},
      "code": {"type": "string"}
    },
    "required": ["filename", "code"]
  }
}
```

## Quick Reference

| Delta Type | Field | Trigger |
|---|---|---|
| `text_delta` | `text` | Standard text generation |
| `input_json_delta` | `partial_json` | Tool use parameter streaming |
| `thinking_delta` | `thinking` | Extended thinking enabled |
| `signature_delta` | `signature` | End of thinking block |
| `citations_delta` | `citation` | Documents with citations enabled |

| Event | Purpose |
|---|---|
| `message_start` | Message shell with initial usage |
| `content_block_start` | New content block (type + index) |
| `content_block_delta` | Incremental content payload |
| `content_block_stop` | Content block is complete |
| `message_delta` | Stop reason + cumulative output tokens |
| `message_stop` | Stream is finished |
| `ping` | Keep-alive, ignore |
| `error` | Stream-level error (e.g., overloaded) |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Parsing `input_json_delta` immediately | JSON parse errors on partial strings | Accumulate all `partial_json` deltas, parse only after `content_block_stop` |
| Ignoring unknown event types | Code crashes on new event types | Always handle unknown events gracefully by skipping them |
| Treating `usage.output_tokens` as per-event | Token counts seem wrong or inflated | The `usage` in `message_delta` is cumulative, not incremental |
| Not handling `content_block_start` index | Content blocks assigned to wrong positions | Each block has an `index` matching its position in the final `content` array |
| Resuming from tool_use or thinking block | Corrupted continuation | Only text blocks can be partially recovered for stream error recovery |
| Missing error event handling | Unhandled stream errors | Listen for `event: error` with JSON error payload (e.g., `overloaded_error`) |

## References

- Anthropic streaming documentation: https://docs.anthropic.com/en/docs/build-with-claude/streaming
- For citation streaming behavior, see `using-claude-citations`
- For tool use patterns, see `implementing-claude-tool-use`
- For extended thinking setup, see `using-claude-thinking-and-effort`
