---
name: implementing-claude-tool-use
description: "Use when giving Claude tools to call via the API, defining function schemas for tool use, handling tool_use and tool_result blocks, building an agentic loop, controlling which tools Claude picks with tool_choice, or streaming tool inputs. Also use for 'tool_use ids were found without tool_result blocks' errors, stop_reason 'tool_use', eager_input_streaming, programmatic tool calling, or integrating Claude with external APIs and databases."
---

# Implementing Claude Tool Use

## Overview

Tool use lets Claude interact with external functions by emitting structured `tool_use` blocks that your code executes, then returning results via `tool_result` blocks. The request/response cycle forms an agentic loop: define tools, Claude decides when to call them, you execute and return results, Claude incorporates them into its answer.

## When to Use

- Extending Claude with external capabilities (APIs, databases, calculations)
- Building agentic workflows where Claude orchestrates multi-step operations
- Extracting structured JSON output conforming to a schema
- Controlling whether and which tools Claude calls
- Streaming large tool inputs incrementally
- Reducing round-trips with programmatic tool calling

## When Not to Use

- Claude can answer directly from training data without external calls
- Task is pure text generation with no external dependencies
- Use `using-claude-built-in-tools` for Anthropic's pre-built tools (bash, code execution, computer use, text editor)
- Use `using-claude-server-tools-and-mcp` for web search, web fetch, memory, or MCP connector
- Use `streaming-claude-responses` for general SSE streaming patterns

## Core Patterns

### Define and Call a Tool (Full Round-Trip)

Define tools with `name`, `description`, and `input_schema` (JSON Schema). Claude returns `stop_reason: "tool_use"` with a `tool_use` content block. Execute the tool, return a `tool_result`, and Claude produces a final response.

```bash
# Step 1: Send tools + user prompt
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tools": [{
      "name": "get_weather",
      "description": "Get the current weather in a given location. Returns temperature and conditions. Use when user asks about weather in a specific city.",
      "input_schema": {
        "type": "object",
        "properties": {
          "location": {
            "type": "string",
            "description": "City and state, e.g. San Francisco, CA"
          },
          "unit": {
            "type": "string",
            "enum": ["celsius", "fahrenheit"],
            "description": "Temperature unit"
          }
        },
        "required": ["location"]
      }
    }],
    "messages": [
      {"role": "user", "content": "What is the weather like in San Francisco?"}
    ]
  }'
```

Claude responds with a `tool_use` block:

```json
{
  "stop_reason": "tool_use",
  "content": [
    {"type": "text", "text": "I will check the weather for you."},
    {
      "type": "tool_use",
      "id": "toolu_01A09q90qw90lq917835lq9",
      "name": "get_weather",
      "input": {"location": "San Francisco, CA", "unit": "celsius"}
    }
  ]
}
```

Return the result in a follow-up request:

```bash
# Step 2: Return the tool result
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tools": [{"name": "get_weather", "description": "Get weather for a location.", "input_schema": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}}],
    "messages": [
      {"role": "user", "content": "What is the weather like in San Francisco?"},
      {"role": "assistant", "content": [
        {"type": "text", "text": "I will check the weather for you."},
        {"type": "tool_use", "id": "toolu_01A09q90qw90lq917835lq9", "name": "get_weather", "input": {"location": "San Francisco, CA", "unit": "celsius"}}
      ]},
      {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "toolu_01A09q90qw90lq917835lq9", "content": "15 degrees celsius, partly cloudy"}
      ]}
    ]
  }'
```

### Controlling Tool Selection with tool_choice

Force or prevent tool use by setting `tool_choice` on the request.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tool_choice": {"type": "tool", "name": "get_weather"},
    "tools": [{
      "name": "get_weather",
      "description": "Get weather for a location",
      "input_schema": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}
    }],
    "messages": [{"role": "user", "content": "San Francisco"}]
  }'
```

With `any` or `tool`, Claude will NOT emit natural language before the `tool_use` block.

Disable parallel tool use by adding `"disable_parallel_tool_use": true` alongside `tool_choice`. This ensures Claude calls at most one tool per response with `auto`, or exactly one with `any`/`tool`.

### Parallel Tool Calls

Claude can emit multiple `tool_use` blocks in one response. Return ALL `tool_result` blocks in a single `user` message. The `tool_result` blocks must come FIRST in the content array, before any text.

### Error Results

Set `"is_error": true` on the `tool_result` block to indicate failure. Claude will explain the error to the user.

```json
{
  "type": "tool_result",
  "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
  "is_error": true,
  "content": "API rate limit exceeded. Try again in 30 seconds."
}
```

### Fine-grained Tool Streaming

Reduce latency for large tool inputs by streaming parameter values incrementally. Enable by setting `"eager_input_streaming": true` on the tool definition, plus `"stream": true` on the request.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 65536,
    "stream": true,
    "tools": [{
      "name": "make_file",
      "description": "Write text to a file",
      "eager_input_streaming": true,
      "input_schema": {
        "type": "object",
        "properties": {
          "filename": {"type": "string"},
          "lines_of_text": {"type": "array", "description": "Lines to write"}
        },
        "required": ["filename", "lines_of_text"]
      }
    }],
    "messages": [{"role": "user", "content": "Write a long poem to poem.txt"}]
  }'
```

Chunks arrive faster and are longer. Handle potentially invalid JSON if `max_tokens` is hit mid-stream.

### Programmatic Tool Calling (Beta)

Claude writes Python code that calls tools in loops and conditionals inside a sandboxed container, reducing round-trips and token cost. Requires beta header `advanced-tool-use-2025-11-20`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: advanced-tool-use-2025-11-20" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [{"role": "user", "content": "Query sales for West, East, and Central regions, then tell me which had the highest revenue"}],
    "tools": [
      {"type": "code_execution_20250825", "name": "code_execution"},
      {
        "name": "query_database",
        "description": "Execute SQL against the sales database. Returns rows as JSON.",
        "input_schema": {
          "type": "object",
          "properties": {"sql": {"type": "string"}},
          "required": ["sql"]
        },
        "allowed_callers": ["code_execution_20250825"]
      }
    ]
  }'
```

Use `allowed_callers` to control invocation: `["code_execution_20250825"]` for code-only, `["direct"]` for direct-only, or both. The `caller` field in the response tells you where the call originated. Tool results from programmatic calls do NOT enter the context window -- only the final code output does.

### Strict Schema Validation

Add `"strict": true` to a tool definition to guarantee Claude's inputs match the schema exactly. Not supported with programmatic calling.

## Quick Reference

| Operation | Syntax | Notes |
|---|---|---|
| Define a tool | `tools: [{name, description, input_schema}]` | `name` must match `^[a-zA-Z0-9_-]{1,64}$` |
| Force specific tool | `tool_choice: {"type": "tool", "name": "X"}` | No text before tool call |
| Force any tool | `tool_choice: {"type": "any"}` | Must pick one tool |
| Prevent tool use | `tool_choice: {"type": "none"}` | Default when no tools provided |
| Let Claude decide | `tool_choice: {"type": "auto"}` | Default when tools provided |
| Disable parallel calls | `tool_choice: {..., "disable_parallel_tool_use": true}` | At most 1 tool call per response |
| Return tool result | `{"type": "tool_result", "tool_use_id": "...", "content": "..."}` | Must be in a `user` message; results come FIRST in content array |
| Return error result | Add `"is_error": true` to `tool_result` | Claude explains the failure |
| Enable eager streaming | `"eager_input_streaming": true` on tool + `"stream": true` | May produce invalid JSON on truncation |
| Programmatic calling | `"allowed_callers": ["code_execution_20250825"]` | Beta header: `advanced-tool-use-2025-11-20` |
| Strict validation | `"strict": true` on tool definition | Guarantees inputs match schema exactly |
| Tool use examples | `"input_examples": [...]` on tool definition | Beta header: `advanced-tool-use-2025-11-20` |
| Handle pause_turn | Check `stop_reason == "pause_turn"`, resend as assistant content | For server tools hitting iteration limit |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Text before `tool_result` in content array | 400: "tool_use ids found without tool_result blocks" | `tool_result` blocks must come FIRST, text AFTER |
| Parallel tool results in separate messages | Claude stops making parallel calls; 400 errors | All `tool_result` blocks for one response go in a single `user` message |
| Vague tool descriptions | Claude picks wrong tools or hallucinates parameters | Write 3-4+ sentence descriptions covering what, when, parameters, caveats |
| Mismatched `tool_use_id` in result | 400 error | The `tool_use_id` must exactly match the `id` from the `tool_use` block |
| Ignoring `max_tokens` truncation | Incomplete tool_use block with no valid JSON | Check `stop_reason == "max_tokens"` and retry with higher limit |
| `tool_choice: any/tool` with extended thinking | Error | Only `auto` and `none` work with extended thinking |
| Treating eager-streamed JSON as valid | Parse errors at runtime | With `eager_input_streaming`, streamed JSON may be incomplete |
| Not reusing container for programmatic calls | Container timeout / lost state | Pass `container` ID from previous response to maintain state |

## References

- [Tool use overview](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview)
- [Implement tool use](https://platform.claude.com/docs/en/agents-and-tools/tool-use/implement-tool-use)
- [Fine-grained tool streaming](https://platform.claude.com/docs/en/agents-and-tools/tool-use/fine-grained-tool-streaming)
- [Programmatic tool calling](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling)
