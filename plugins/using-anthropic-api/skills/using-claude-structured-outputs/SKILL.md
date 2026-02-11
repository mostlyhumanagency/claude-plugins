---
name: using-claude-structured-outputs
description: "Use when forcing Claude to return valid JSON, enforcing a JSON schema on API output, extracting structured data from text, using output_config format or constrained decoding, counting tokens with the count_tokens endpoint, or passing search results for RAG with source attribution. Also use for strict tool use for structured output, search_result content blocks, multilingual prompts, or building data extraction pipelines."
---

## Overview

This skill covers four complementary API capabilities: structured outputs for guaranteed JSON conformance, token counting for cost estimation, multilingual support for non-English languages, and search result content blocks for RAG with source attribution. Structured outputs use constrained decoding to guarantee responses match a JSON schema. Token counting provides free pre-request cost estimates. Multilingual support requires no special configuration. Search results enable cited RAG responses.

## When to Use

- Extracting structured data (names, emails, classifications) from unstructured text
- Validating tool call parameters with strict schema enforcement
- Estimating token costs before sending expensive prompts
- Building applications serving multilingual users
- Feeding RAG search results to Claude with automatic source citations
- Any pipeline consuming structured data from Claude's responses

## When Not to Use

- Free-form creative writing where JSON format is inappropriate
- When you need citations in the same response as structured output (incompatible)
- Recursive or deeply nested schemas that exceed supported complexity
- For message prefilling (incompatible with JSON outputs)
- For basic message patterns, see `working-with-claude-messages`
- For document-level citations, see `using-claude-citations`
- For tool use fundamentals, see `implementing-claude-tool-use`

## Core Patterns

### JSON Outputs with Schema Enforcement

Use `output_config.format` with `type: "json_schema"` to guarantee Claude's response matches your schema exactly. No retries or parsing errors.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "Extract info: John Smith (john@example.com) wants the Enterprise plan, demo next Tuesday 2pm."}
    ],
    "output_config": {
      "format": {
        "type": "json_schema",
        "schema": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "email": {"type": "string"},
            "plan_interest": {"type": "string"},
            "demo_requested": {"type": "boolean"}
          },
          "required": ["name", "email", "plan_interest", "demo_requested"],
          "additionalProperties": false
        }
      }
    }
  }'
```

The response appears in `content[0].text` as valid JSON matching the schema. The grammar is auto-cached for 24 hours, so the first request may have slightly higher latency.

### Strict Tool Use

Add `strict: true` to a tool definition to guarantee tool call inputs always match the declared schema.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "What is the weather in San Francisco?"}
    ],
    "tools": [{
      "name": "get_weather",
      "description": "Get current weather for a location",
      "strict": true,
      "input_schema": {
        "type": "object",
        "properties": {
          "location": {"type": "string", "description": "City and state"},
          "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
        },
        "required": ["location"],
        "additionalProperties": false
      }
    }]
  }'
```

Combine both in the same request: `output_config.format` for the final response shape, `strict: true` on tools for validated tool call parameters.

### Supported Schema Types

Structured outputs support these JSON Schema types:

- Primitives: `string`, `integer`, `number`, `boolean`, `null`
- Containers: `object`, `array`
- Composition: `enum`, `const`, `anyOf`, `allOf`, `$ref`/`$def`
- String formats: `date-time`, `time`, `date`, `duration`, `email`, `hostname`, `uri`, `ipv4`, `ipv6`, `uuid`

All `object` types must include `additionalProperties: false`. Numerical constraints (`minimum`, `maximum`) and string constraints (`minLength`, `maxLength`) are not supported -- use the field description to communicate these requirements instead.

### Handling Refusals and Truncation

Check `stop_reason` in the response:

- `"end_turn"` -- normal completion, output matches schema.
- `"refusal"` -- Claude declined the request; output may not match schema.
- `"max_tokens"` -- output was truncated; JSON may be incomplete. Increase `max_tokens`.

### Token Counting

Determine the exact input token cost of a request before sending it. The endpoint is free and has independent rate limits.

```bash
curl https://api.anthropic.com/v1/messages/count_tokens \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "system": "You are a scientist",
    "messages": [{"role": "user", "content": "Hello, Claude"}]
  }'
# Response: {"input_tokens": 14}
```

Count tokens with tools included -- tool schemas add 300-400+ tokens of overhead:

```bash
curl https://api.anthropic.com/v1/messages/count_tokens \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
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
    "messages": [{"role": "user", "content": "What is the weather in SF?"}]
  }'
# Response: {"input_tokens": 403}
```

The request body mirrors the Messages API shape (same system, messages, tools, images, PDFs) minus `max_tokens`. The response contains a single `input_tokens` field. Treat this as an estimate -- the actual billed amount may differ slightly.

### Multilingual Prompting

Claude processes and generates text in most world languages using standard Unicode. No special configuration is needed -- just send text in the target language and optionally specify the desired output language in the system prompt.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": "Respond in Spanish using idiomatic speech as if you were a native speaker.",
    "messages": [
      {"role": "user", "content": "Explain how photosynthesis works."}
    ]
  }'
```

Best practices for multilingual use:

- Explicitly state desired output language in the system prompt.
- Submit text in its native script (Chinese characters, Arabic script), not transliteration.
- Consider cultural and regional context beyond pure translation.
- For low-resource languages, consider an English intermediate step for better quality.

### Search Result Content Blocks

Provide structured search results so Claude can produce naturally cited responses -- the primary building block for RAG applications.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "search_result",
          "source": "https://docs.example.com/auth",
          "title": "Authentication Guide",
          "content": [
            {"type": "text", "text": "All API requests require a Bearer token in the Authorization header. Tokens expire after 24 hours."}
          ],
          "citations": {"enabled": true}
        },
        {
          "type": "search_result",
          "source": "https://docs.example.com/rate-limits",
          "title": "Rate Limiting",
          "content": [
            {"type": "text", "text": "Standard tier: 1000 req/hour. Premium tier: 10000 req/hour. Exceeded limits return HTTP 429."}
          ],
          "citations": {"enabled": true}
        },
        {"type": "text", "text": "How do I authenticate and what are the rate limits?"}
      ]
    }]
  }'
```

The response includes `search_result_location` citations with `source`, `title`, `cited_text`, `search_result_index`, and block indices.

### Search Results from Tool Calls (Dynamic RAG)

Return `search_result` blocks in the `content` array of a `tool_result` message. The schema is identical. Claude cites tool-returned results the same way as top-level results.

```json
{
  "role": "user",
  "content": [{
    "type": "tool_result",
    "tool_use_id": "toolu_abc123",
    "content": [{
      "type": "search_result",
      "source": "https://docs.example.com/api",
      "title": "API Reference",
      "content": [{"type": "text", "text": "The /users endpoint accepts GET and POST methods."}],
      "citations": {"enabled": true}
    }]
  }]
}
```

## Quick Reference

| Feature | Syntax | Notes |
|---|---|---|
| JSON output | `output_config: {format: {type: "json_schema", schema: {...}}}` | Response in `content[0].text` |
| Strict tool use | `strict: true` on tool definition | Validates tool_use input |
| Combined | Both in same request | JSON for response, strict for tools |
| Count tokens | `POST /v1/messages/count_tokens` | Free; independent rate limits |
| Multilingual | System prompt: "Respond in [language]" | No special mode required |
| Search results | `type: "search_result"` in content array | Required: source, title, content |

| Language Tier | Languages | Performance vs English |
|---|---|---|
| Tier 1 (>97%) | Spanish, Portuguese (BR), Italian, French, Indonesian, German | 97-98% |
| Tier 2 (95-97%) | Arabic, Chinese (Simplified), Korean, Japanese, Hindi | 95-97% |
| Tier 3 (90-95%) | Bengali | ~95% |
| Tier 4 (<90%) | Swahili (~90%), Yoruba (~80%) | Variable |

| Token Counting | Detail |
|---|---|
| Endpoint | `POST /v1/messages/count_tokens` |
| Response | `{"input_tokens": N}` |
| Cost | Free |
| Rate limits | 100-8,000 RPM by usage tier |
| Accuracy | Estimate; may differ slightly from billing |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Missing `additionalProperties: false` | 400 error | Must be `false` on all objects in the schema |
| Using recursive schemas | 400 error | Flatten or restructure the schema |
| Using `minimum`/`maximum` constraints | 400 error | Remove constraints; use description text instead |
| Using `minLength`/`maxLength` | 400 error | Use description to specify length requirements |
| Setting `max_tokens` too low | Truncated invalid JSON | Increase `max_tokens`; check `stop_reason` |
| Combining structured output with citations | 400 error | These features are incompatible |
| Combining with message prefilling | 400 error | Prefilling is incompatible with JSON outputs |
| Forgetting tool tokens in count | Budget overrun | Always include tools when counting tokens |
| Using transliteration instead of native script | Lower quality output | Always use native Unicode script |
| Not specifying output language | Claude responds in wrong language | Explicitly state target language in system prompt |
| Empty search result content array | 400 error | Content must contain at least one text block |
| Mixing citation settings across search results | 400 error | All search results must have same citation setting |

## References

- Structured outputs documentation: https://docs.anthropic.com/en/docs/build-with-claude/structured-outputs
- Token counting documentation: https://docs.anthropic.com/en/docs/build-with-claude/token-counting
- Multilingual support documentation: https://docs.anthropic.com/en/docs/build-with-claude/multilingual-support
- Search results documentation: https://docs.anthropic.com/en/docs/build-with-claude/search-results
- For document-level citations, see `using-claude-citations`
- For tool use fundamentals, see `implementing-claude-tool-use`
- For message structure, see `working-with-claude-messages`
