---
name: working-with-claude-messages
description: "Use when sending a message to the Claude API, calling the /messages endpoint, building a chatbot or multi-turn conversation, constructing the messages array, handling stop reasons (end_turn, tool_use, max_tokens), processing content blocks, or debugging request/response issues. Also use for 'max_tokens error', empty responses, agent loops, model parameter configuration, or building any application that calls Claude."
---

## Overview

The Messages API is Claude's sole interface for inference. Send a stateless array of `user` and `assistant` messages, receive a response containing one or more content blocks, and branch on `stop_reason` to decide what happens next. Every request must include `model`, `max_tokens`, and `messages`.

## When to Use

- Building any application that calls Claude (chatbots, agents, pipelines)
- Sending multi-turn conversations with full history replay
- Sending images, PDFs, or mixed content alongside text
- Handling truncated responses, tool calls, or safety refusals in an agent loop
- Diagnosing empty responses or unexpected `stop_reason` values

## When Not to Use

- Generating embeddings -- Claude has no embeddings endpoint
- Fine-tuning or training -- the Messages API is inference only
- Batch processing thousands of independent prompts -- use the Message Batches API instead
- Managing long conversations that exceed context limits -- see `managing-claude-context`
- Implementing tool definitions and execution -- see `implementing-claude-tool-use`
- Server-sent event streaming -- see `streaming-claude-responses`
- Enforcing JSON output schemas -- see `using-claude-structured-outputs`

## Core Patterns

### Basic Request and Response

Send a single prompt and receive a complete response. Every request requires `model`, `max_tokens`, and `messages`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "Explain HTTP status codes in one paragraph."}
    ]
  }'
```

The response contains an `id`, a `content` array with one or more blocks, `stop_reason`, and `usage` with token counts:

```json
{
  "id": "msg_01XFDUDYJgAACzvnptvVoYEL",
  "type": "message",
  "role": "assistant",
  "content": [
    {"type": "text", "text": "HTTP status codes are three-digit numbers..."}
  ],
  "model": "claude-sonnet-4-5-20250929",
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {"input_tokens": 18, "output_tokens": 95}
}
```

Add a system prompt with `"system": "You are a technical writer."` at the top level. Use `"temperature": 0.0` for deterministic tasks and `1.0` (the default) for creative work. Use one of `temperature` or `top_p`, never both.

### Multi-Turn Conversations

The API is stateless. Replay the full conversation history on every request. Alternate `user` and `assistant` roles. Consecutive same-role messages are automatically combined.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": "You are a patient math tutor.",
    "messages": [
      {"role": "user", "content": "What is a derivative?"},
      {"role": "assistant", "content": "A derivative measures the rate of change of a function."},
      {"role": "user", "content": "Can you give me a simple example?"}
    ]
  }'
```

Inject synthetic `assistant` messages you wrote yourself (not from Claude) to steer behavior. This is useful for providing example responses or correcting the conversation flow.

### Multimodal Content Blocks

Send images, documents, or mixed content by using an array of content blocks instead of a plain string for the `content` field.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "image",
            "source": {"type": "url", "url": "https://example.com/photo.jpg"}
          },
          {
            "type": "text",
            "text": "Describe what you see in this image."
          }
        ]
      }
    ]
  }'
```

Use `"source": {"type": "base64", "media_type": "image/png", "data": "..."}` for inline images. Use `"type": "document"` with `"media_type": "application/pdf"` for PDF input. Supported image types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`.

### Handling Stop Reasons in an Agent Loop

Check `stop_reason` on every response to decide what to do next. Stop reasons are successful outcomes, not errors (HTTP 4xx/5xx are errors).

Detect truncation and continue generation:

```bash
RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 50,
    "messages": [
      {"role": "user", "content": "Write a 500-word essay on climate change."}
    ]
  }')

STOP_REASON=$(echo "$RESPONSE" | jq -r '.stop_reason')
PARTIAL_TEXT=$(echo "$RESPONSE" | jq -r '.content[0].text')

if [ "$STOP_REASON" = "max_tokens" ]; then
  # Continue by replaying history with the partial response
  curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{
      \"model\": \"claude-sonnet-4-5-20250929\",
      \"max_tokens\": 1024,
      \"messages\": [
        {\"role\": \"user\", \"content\": \"Write a 500-word essay on climate change.\"},
        {\"role\": \"assistant\", \"content\": $(echo "$PARTIAL_TEXT" | jq -Rs .)},
        {\"role\": \"user\", \"content\": \"Please continue from where you left off.\"}
      ]
    }"
fi
```

The full agent loop pattern:

1. Send the initial request.
2. Read `stop_reason`:
   - `end_turn` -- generation finished naturally. Display the result.
   - `tool_use` -- Claude wants to call a tool. Execute it, append the result, re-request.
   - `max_tokens` -- response truncated. Continue generation or warn the user.
   - `pause_turn` -- server tool loop hit its iteration limit. Re-send the assistant response to continue.
   - `stop_sequence` -- a custom delimiter was matched. Parse output up to the delimiter.
   - `refusal` -- safety policy triggered. Inform the user. Do not retry the same content.
   - `model_context_window_exceeded` -- context window full. Response is valid but truncated. Reduce input or summarize.

## Quick Reference

### Request Parameters

| Parameter | Type | Required | Default | Notes |
|---|---|---|---|---|
| `model` | string | Yes | -- | e.g. `claude-sonnet-4-5-20250929`, `claude-opus-4-6` |
| `max_tokens` | integer | Yes | -- | Maximum output tokens. Model may stop earlier. |
| `messages` | array | Yes | -- | Alternating `user`/`assistant` message objects |
| `system` | string or array | No | -- | System prompt (top-level, not a message role) |
| `temperature` | float | No | 1.0 | 0.0 = deterministic, 1.0 = creative |
| `top_p` | float | No | -- | Nucleus sampling (alternative to temperature) |
| `top_k` | integer | No | -- | Sample from top K tokens |
| `stop_sequences` | string[] | No | -- | Custom strings that halt generation |
| `stream` | boolean | No | false | Enable SSE streaming |
| `tools` | array | No | -- | Tool definitions with `input_schema` |
| `tool_choice` | object | No | `auto` | `auto`, `any`, `tool` (by name), `none` |
| `metadata` | object | No | -- | `user_id` for abuse tracking |
| `thinking` | object | No | -- | Extended thinking configuration |
| `output_config` | object | No | -- | Structured output JSON schema, effort level |

### Stop Reason Values

| Value | Meaning | Action |
|---|---|---|
| `end_turn` | Claude finished naturally | Display result to user |
| `max_tokens` | Hit the `max_tokens` limit | Warn user or continue generation |
| `stop_sequence` | Hit a custom stop sequence | Parse output up to the delimiter |
| `tool_use` | Claude wants to call a tool | Execute the tool, return result, re-request |
| `pause_turn` | Server tool loop hit iteration limit | Re-send assistant response to continue |
| `refusal` | Safety policy triggered | Inform user; do not retry same content |
| `model_context_window_exceeded` | Context window full | Response is valid but truncated; reduce input |

### Content Block Types

| Type | Direction | Description |
|---|---|---|
| `text` | Input/Output | Plain text content |
| `image` | Input | Base64 or URL image |
| `document` | Input | PDF or other document |
| `tool_use` | Output | Claude requesting a tool call |
| `tool_result` | Input | Your tool execution result |
| `thinking` | Output | Extended thinking (when enabled) |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `max_tokens` | 400 error: `max_tokens` is required | Always include `max_tokens` in every request |
| Not checking `stop_reason` | Truncated responses silently passed to user | Always branch on `stop_reason` before processing content |
| Adding text blocks after `tool_result` | Empty responses (2-3 tokens, no content) | Send `tool_result` blocks alone without extra `text` blocks in the same user message |
| Retrying empty responses without modification | Claude returns empty again | Append a new `user` message like "Please continue" instead of replaying the same request |
| Treating `stop_reason` as an error | Confused error handling; missed tool calls | Stop reasons are successful outcomes, not errors |
| Setting `max_tokens` too low for tool use | Claude cannot complete its tool call JSON | Use at least 1024 for tool-use scenarios; 4096 is safer |
| Using `top_p` and `temperature` together | Unpredictable sampling behavior | Use one or the other, not both |
| Ignoring `pause_turn` in server-tool loops | Incomplete results from web search or server tools | Detect `pause_turn`, re-send the assistant response to continue |
| Prefilling on newer models | Unexpected behavior or errors | Prefilling is deprecated on Opus 4.6 and Sonnet 4.5. Use structured outputs or system prompts instead. |

## References

- [Messages API reference](https://platform.claude.com/docs/en/api/messages)
- [Working with messages](https://platform.claude.com/docs/en/build-with-claude/working-with-messages)
- [Handling stop reasons](https://platform.claude.com/docs/en/build-with-claude/handling-stop-reasons)
