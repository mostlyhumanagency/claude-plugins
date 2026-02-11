---
name: managing-claude-context
description: "Use when hitting context window limits, managing long conversations, compacting or summarizing chat history, clearing old tool results or thinking blocks, counting tokens, or optimizing how much context fits in a request. Also use for 'context window exceeded' errors, context_management configuration, compaction strategies, 1M context window usage, or building agents that run for many turns."
---

## Overview

The context window is Claude's working memory -- all text (system prompt, conversation history, tool definitions, and response) that the model can reference. The API provides three strategies to manage it: understanding context limits and counting tokens, compaction (server-side summarization of older context), and context editing (selectively clearing tool results or thinking blocks).

## When to Use

- Building long-running conversations or agentic workflows that may exceed 200K tokens
- Needing automatic summarization to keep conversations going indefinitely
- Clearing old tool results that are no longer relevant to save context space
- Removing thinking blocks from earlier turns to reduce token usage
- Processing very large documents that require the 1M context window
- Checking token counts before sending requests to avoid validation errors

## When Not to Use

- Short conversations that fit comfortably within 200K tokens -- no context management needed
- Situations where precise recall of early conversation details is required -- compaction summarizes and loses detail
- Optimizing cost of repeated prefixes -- see `using-claude-prompt-caching`
- Building basic requests or handling stop reasons -- see `working-with-claude-messages`

## Core Patterns

### Context Windows and Limits

All Claude models have a standard 200K token context window. A 1M token beta window is available for Claude Opus 4.6, Sonnet 4.5, and Sonnet 4 (requires usage tier 4).

```bash
# 1M context window requires the beta header and usage tier 4
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: context-1m-2025-08-07" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "Process this very large document..."}
    ]
  }'
```

Key facts about context windows:

- Newer models (Sonnet 3.7 onward) return a validation error when tokens exceed the window, rather than silently truncating.
- Extended thinking tokens are billed as output but automatically stripped from subsequent turns' input. Exception: during a tool-use cycle, thinking blocks must be returned alongside the `tool_result`.
- 1M requests exceeding 200K tokens are charged at premium rates (2x input, 1.5x output).
- Sonnet 4.5 and Haiku 4.5 receive automatic context awareness with token budget tracking.

### Compaction (Server-Side Summarization)

Compaction automatically summarizes older context when input tokens exceed a configured threshold. Currently supported on Claude Opus 4.6 only.

```bash
# Compaction is beta -- requires the compact-2026-01-12 header
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: compact-2026-01-12" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [
      {"role": "user", "content": "Help me build a website"}
    ],
    "context_management": {
      "edits": [
        {
          "type": "compact_20260112",
          "trigger": {"type": "input_tokens", "value": 100000}
        }
      ]
    }
  }'
```

When compaction triggers, the response includes a `compaction` content block:

```json
{
  "content": [
    {
      "type": "compaction",
      "content": "Summary of the conversation: The user requested help building..."
    },
    {
      "type": "text",
      "text": "Based on our conversation so far..."
    }
  ]
}
```

Pass the full `response.content` (including the compaction block) back on the next turn. The API automatically drops everything before the compaction block.

### Pause After Compaction

Set `"pause_after_compaction": true` to intercept the compaction and inject additional content before continuing. When `stop_reason` is `"compaction"`, append preserved messages and re-send.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: compact-2026-01-12" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [
      {"role": "user", "content": "Help me build a website"}
    ],
    "context_management": {
      "edits": [
        {
          "type": "compact_20260112",
          "pause_after_compaction": true
        }
      ]
    }
  }'
```

### Custom Summarization Instructions

The `instructions` parameter completely replaces the default summarization prompt. Use this to preserve specific types of information:

```json
{
  "type": "compact_20260112",
  "instructions": "Focus on preserving code snippets, variable names, and technical decisions."
}
```

### Tool Result Clearing

Remove old tool use/result pairs (oldest first) to free context space. Useful in agentic workflows with heavy tool use where old results are disposable.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: context-management-2025-06-27" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [
      {"role": "user", "content": "Search for recent developments in AI"}
    ],
    "tools": [
      {"type": "web_search_20250305", "name": "web_search"}
    ],
    "context_management": {
      "edits": [
        {
          "type": "clear_tool_uses_20250919",
          "trigger": {"type": "input_tokens", "value": 30000},
          "keep": {"type": "tool_uses", "value": 3},
          "clear_at_least": {"type": "input_tokens", "value": 5000},
          "exclude_tools": ["web_search"]
        }
      ]
    }
  }'
```

### Thinking Block Clearing

Remove thinking blocks from older assistant turns to reduce context usage.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: context-management-2025-06-27" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "Solve this step by step..."}],
    "thinking": {"type": "enabled", "budget_tokens": 10000},
    "context_management": {
      "edits": [
        {
          "type": "clear_thinking_20251015",
          "keep": {"type": "thinking_turns", "value": 2}
        }
      ]
    }
  }'
```

### Combining Strategies

Use tool clearing and thinking clearing together. `clear_thinking_20251015` must be listed first in the `edits` array:

```json
"context_management": {
  "edits": [
    {"type": "clear_thinking_20251015", "keep": {"type": "thinking_turns", "value": 2}},
    {"type": "clear_tool_uses_20250919", "trigger": {"type": "input_tokens", "value": 50000}, "keep": {"type": "tool_uses", "value": 5}}
  ]
}
```

## Quick Reference

| Operation | API Syntax | Notes |
|---|---|---|
| Standard context window | 200K tokens (all models) | Validation error if exceeded (Sonnet 3.7+) |
| 1M context window | Header: `anthropic-beta: context-1m-2025-08-07` | Beta, tier 4 only. 2x input / 1.5x output pricing above 200K |
| Enable compaction | `context_management.edits[{type: "compact_20260112"}]` | Beta header: `compact-2026-01-12`. Opus 4.6 only |
| Compaction trigger | `trigger: {type: "input_tokens", value: N}` | Default 150K, minimum 50K |
| Pause after compaction | `pause_after_compaction: true` | Returns `stop_reason: "compaction"` |
| Custom summarization | `instructions: "your prompt"` | Replaces default prompt entirely |
| Clear tool results | `{type: "clear_tool_uses_20250919"}` | Beta header: `context-management-2025-06-27` |
| Tool clearing trigger | `trigger: {type: "input_tokens", value: N}` | Default 100K |
| Keep N tool uses | `keep: {type: "tool_uses", value: N}` | Default 3 |
| Exclude tools from clearing | `exclude_tools: ["tool_name"]` | Those tools' results are never cleared |
| Clear thinking blocks | `{type: "clear_thinking_20251015"}` | Must be listed first when combining strategies |
| Keep N thinking turns | `keep: {type: "thinking_turns", value: N}` | Default 1. Use `"all"` to maximize cache hits |
| Count tokens | `POST /v1/messages/count_tokens` | Supports `context_management` to preview post-edit token count |
| Cache compaction block | `cache_control: {type: "ephemeral"}` on compaction block | Also cache system prompt separately for best hit rate |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Not passing compaction block back to API | Conversation loses all context after compaction | Append full `response.content` (including compaction block) to the messages array |
| Modifying thinking blocks during tool use | Cryptographic signature error | Never modify thinking blocks; pass them back verbatim during tool-use cycles |
| Stripping thinking blocks too early | Breaks reasoning continuity | Keep thinking blocks until the tool-use cycle completes |
| Setting compaction trigger too low | Frequent compaction causes information loss and extra cost | Minimum is 50K tokens; 100K-150K is a good starting point |
| Not accounting for compaction billing | Unexpected costs | Sum all entries in `usage.iterations` for true cost |
| Listing `clear_thinking` after `clear_tool_uses` | API error or unexpected behavior | `clear_thinking_20251015` must come first in the `edits` array |
| Using `usage.input_tokens` for cost with compaction | Undercounting actual spend | Top-level fields exclude compaction iterations; use `usage.iterations` array |
| Using 1M context without beta header | Request limited to 200K | Include `anthropic-beta: context-1m-2025-08-07` header |

## References

- [Context windows](https://platform.claude.com/docs/en/build-with-claude/context-windows)
- [Compaction](https://platform.claude.com/docs/en/build-with-claude/compaction)
- [Context editing](https://platform.claude.com/docs/en/build-with-claude/context-editing)
