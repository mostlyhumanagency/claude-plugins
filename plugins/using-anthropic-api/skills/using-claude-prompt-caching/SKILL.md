---
name: using-claude-prompt-caching
description: "Use when reducing Claude API costs or latency by caching repeated content, placing cache_control breakpoints, caching system prompts or tool definitions, implementing multi-turn caching, or debugging cache misses. Also use for cache_creation_input_tokens, cache_read_input_tokens, TTL configuration, ephemeral cache_control, or optimizing cost for high-volume API usage."
---

## Overview

Prompt caching marks stable prefixes in API requests so the server can skip re-processing them on subsequent calls. The first request writes to cache at 1.25x the base input price. Every follow-up that matches reads from cache at 0.1x the base input price -- a 90% discount on cached tokens. Place `"cache_control": {"type": "ephemeral"}` on the last content block of each cacheable section.

## When to Use

- Sending the same large document, codebase, or knowledge base across multiple requests
- Agent applications with many tool definitions that stay identical across calls
- Multi-turn conversations where each turn re-sends the full history
- Repetitive system prompts sent with every request
- Latency-sensitive applications where cache hits reduce time-to-first-token

## When Not to Use

- Prompts below the minimum cacheable token threshold (1024 tokens on Sonnet/Opus 4.1/4, 4096 tokens on Opus 4.5/4.6 and Haiku 4.5)
- Every request has entirely unique content -- you pay the 25% write premium for no benefit
- Single-shot requests where you never re-send the same prompt
- Highly dynamic tool definitions that change on every request
- Managing context window limits -- see `managing-claude-context`
- Building basic message requests -- see `working-with-claude-messages`

## Core Patterns

### Caching a Large Context Document

Cache a static document (legal contract, book, codebase) in the system prompt to ask multiple questions about it without re-processing.

```bash
# First request -- writes the document to cache (1.25x input cost)
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": [
      {
        "type": "text",
        "text": "You are a legal analyst. Analyze documents precisely."
      },
      {
        "type": "text",
        "text": "Full contract text here... (50 pages of legal text)",
        "cache_control": {"type": "ephemeral"}
      }
    ],
    "messages": [
      {"role": "user", "content": "What are the termination clauses?"}
    ]
  }'
# Usage: cache_creation_input_tokens: ~50000, cache_read_input_tokens: 0, input_tokens: 12
```

```bash
# Second request -- reads from cache (0.1x input cost for cached portion)
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": [
      {
        "type": "text",
        "text": "You are a legal analyst. Analyze documents precisely."
      },
      {
        "type": "text",
        "text": "Full contract text here... (50 pages of legal text)",
        "cache_control": {"type": "ephemeral"}
      }
    ],
    "messages": [
      {"role": "user", "content": "What are the liability limitations?"}
    ]
  }'
# Usage: cache_creation_input_tokens: 0, cache_read_input_tokens: ~50000, input_tokens: 10
```

Cache images and PDFs the same way using content blocks with `type: "image"` or `type: "document"` and adding `cache_control` to the block.

### Caching Tool Definitions

Place `cache_control` on the last tool definition. The cache covers everything from the start of the request up to and including the marked block, so marking the last tool caches all tools.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "tools": [
      {
        "name": "search_db",
        "description": "Search the database",
        "input_schema": {
          "type": "object",
          "properties": {"query": {"type": "string"}},
          "required": ["query"]
        }
      },
      {
        "name": "run_sql",
        "description": "Execute a SQL query",
        "input_schema": {
          "type": "object",
          "properties": {"sql": {"type": "string"}},
          "required": ["sql"]
        },
        "cache_control": {"type": "ephemeral"}
      }
    ],
    "messages": [
      {"role": "user", "content": "Find all orders from last week"}
    ]
  }'
```

### Multi-Turn Conversation Caching

Mark the last content block of the last user message with `cache_control`. The system automatically looks backward (up to 20 blocks) and reuses the longest cached prefix, so earlier turns cached in prior requests get cache hits automatically.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": [
      {
        "type": "text",
        "text": "You are a helpful coding assistant.",
        "cache_control": {"type": "ephemeral"}
      }
    ],
    "messages": [
      {"role": "user", "content": [{"type": "text", "text": "What is Python?"}]},
      {"role": "assistant", "content": "Python is a high-level programming language..."},
      {"role": "user", "content": [{"type": "text", "text": "How do decorators work?"}]},
      {"role": "assistant", "content": "Decorators are functions that modify other functions..."},
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Show me a caching decorator example.",
            "cache_control": {"type": "ephemeral"}
          }
        ]
      }
    ]
  }'
```

### Extended TTL (1 Hour)

The default cache TTL is 5 minutes, refreshed on each hit. Use `"ttl": "1h"` for content reused less frequently.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "system": [
      {
        "type": "text",
        "text": "Long system prompt or document...",
        "cache_control": {"type": "ephemeral", "ttl": "1h"}
      }
    ],
    "messages": [
      {"role": "user", "content": "Summarize the key points."}
    ]
  }'
```

1-hour cache writes cost 2x the base input price (vs 1.25x for 5-minute). Cache reads remain 0.1x regardless of TTL.

## Quick Reference

| Operation | Syntax | Notes |
|---|---|---|
| Enable caching | `"cache_control": {"type": "ephemeral"}` | Place on the last block of each cacheable section |
| Set 1-hour TTL | `"cache_control": {"type": "ephemeral", "ttl": "1h"}` | Write cost: 2x base (vs 1.25x for default 5m) |
| Max breakpoints | 4 per request | Usually 1 is enough; more for independently-updating sections |
| Cache hierarchy | `tools` -> `system` -> `messages` | Changes earlier invalidate everything after |
| Min cacheable tokens | 1024 (Sonnet/Opus 4.1/4), 4096 (Opus 4.5/4.6, Haiku 4.5) | Below minimum, `cache_control` is silently ignored |
| Default TTL | 5 minutes, refreshed on each cache hit | No extra cost to refresh |
| Lookback window | 20 blocks before each breakpoint | Add extra breakpoints if prompt exceeds 20 blocks |
| Check cache performance | Read `usage.cache_creation_input_tokens` and `usage.cache_read_input_tokens` | `input_tokens` = only tokens after the last breakpoint |
| Total input formula | `cache_read + cache_creation + input_tokens` | Use for cost and rate-limit calculations |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Prompt below minimum token threshold | `cache_creation_input_tokens` is always 0 | Ensure cached content meets the model's minimum (1024 or 4096 tokens) |
| Changing tools/images/tool_choice between calls | Cache misses on every request | Keep tools, images, and `tool_choice` identical across calls |
| Parallel requests before first response completes | All concurrent requests miss cache | Wait for the first response before sending parallel requests |
| Placing `cache_control` on intermediate blocks | Only partial content is cached | Put `cache_control` on the last block of each cacheable section |
| More than 20 content blocks with single breakpoint | Early content is never cached | Add additional breakpoints within 20 blocks of older content |
| Unstable JSON key ordering | Cache misses despite identical requests | Ensure deterministic key ordering in serialized content |
| Using beta SDK prefix | `AttributeError` / `TypeError` | Prompt caching is GA -- use `client.messages.create(...)` directly |
| Mixing TTL order incorrectly | Unexpected billing | Longer TTLs (1h) must appear before shorter TTLs (5m) in the request |
| Expecting thinking blocks to be cacheable | `cache_control` on thinking blocks fails | Thinking blocks cannot be marked directly; they cache automatically in tool-use turns |

## References

- [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
