---
name: using-claude-thinking-and-effort
description: "Use when enabling extended thinking for complex reasoning, controlling how much effort Claude spends on a response, configuring budget_tokens, choosing between adaptive and manual thinking, setting effort levels (low/medium/high/max), enabling fast mode for lower latency, or preserving thinking blocks across tool use turns. Also use for 'thinking signature error', thinking budget configuration, or tuning cost/quality tradeoffs."
---

## Overview

Extended thinking gives Claude a private scratchpad to reason step-by-step before answering. Adaptive thinking (Opus 4.6 only) lets Claude decide dynamically how much to think. The effort parameter controls token spend across the entire response -- text, tool calls, and thinking. Fast mode delivers up to 2.5x faster output from Opus 4.6 at premium pricing.

## When to Use

- Complex reasoning tasks (math proofs, code analysis, multi-step logic) that benefit from step-by-step thinking
- Using Opus 4.6 and wanting Claude to decide thinking depth automatically (adaptive thinking)
- Controlling cost/quality tradeoff across high-volume classification (low effort) or maximum capability (max effort)
- Latency-sensitive agentic workflows where faster output justifies 6x pricing (fast mode)
- Tool-use loops where thinking continuity must be preserved across turns

## When Not to Use

- Simple lookups, classification, or tasks where thinking adds no value -- omit the `thinking` parameter entirely
- Cost-sensitive workloads where thinking token costs are not justified
- Models other than Opus 4.6 for adaptive thinking, `max` effort, or fast mode
- Batch processing -- fast mode is not supported for batches
- Faster time-to-first-token needs -- fast mode improves output tokens/sec, not TTFT
- Building basic message requests -- see `working-with-claude-messages`
- Implementing tool definitions -- see `implementing-claude-tool-use`
- Streaming thinking deltas -- see `streaming-claude-responses`

## Core Patterns

### Extended Thinking (Manual Mode)

Set a fixed token budget for thinking. Use this with Sonnet 4.5, Opus 4.5, and earlier models. The `budget_tokens` value must be at least 1024 and strictly less than `max_tokens`.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 16000,
    "thinking": {
      "type": "enabled",
      "budget_tokens": 10000
    },
    "messages": [
      {
        "role": "user",
        "content": "Prove that there are infinitely many primes p where p mod 4 = 3."
      }
    ]
  }'
```

The response contains `thinking` blocks followed by `text` blocks:

```json
{
  "content": [
    {
      "type": "thinking",
      "thinking": "Let me analyze this step by step...",
      "signature": "WaUjzkypQ2mUEVM36O2Txu..."
    },
    {
      "type": "text",
      "text": "Here is the proof..."
    }
  ]
}
```

Key constraints for manual thinking:
- Claude 4 models return summarized thinking (billed for full tokens, not the summary)
- Claude Sonnet 3.7 returns full thinking output
- Temperature and `top_k` cannot be modified when thinking is enabled
- Cannot pre-fill assistant responses when thinking is enabled
- `tool_choice` must be `"auto"` or `"none"` (no forced tool use with thinking)

### Adaptive Thinking with Effort (Opus 4.6)

Adaptive thinking removes the guesswork of setting `budget_tokens`. Claude decides dynamically whether and how much to think. Combine with the `effort` parameter for a high-level cost/quality dial. This is the recommended approach for Opus 4.6.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-opus-4-6",
    "max_tokens": 16000,
    "thinking": {
      "type": "adaptive"
    },
    "output_config": {
      "effort": "medium"
    },
    "messages": [
      {
        "role": "user",
        "content": "What is the capital of France?"
      }
    ]
  }'
```

Adaptive thinking also automatically enables interleaved thinking (thinking between tool calls) without requiring a separate beta header.

### Effort Levels

The effort parameter is a behavioral signal that works with or without thinking enabled. It controls how eagerly Claude spends tokens across the entire response.

| Effort | With Adaptive Thinking | Without Thinking |
|---|---|---|
| `max` | Always thinks, no depth constraints. Opus 4.6 only. | Maximum verbosity and thoroughness |
| `high` | Always thinks (default). Deep reasoning. | Standard detailed responses |
| `medium` | Moderate thinking. May skip for simple queries. | Concise responses |
| `low` | Minimal thinking. Skips when speed matters. | Brief, terse responses |

### Effort Without Thinking

Control token spend without enabling thinking at all. Useful for classification, quick lookups, or high-volume tasks.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [
      {
        "role": "user",
        "content": "Classify this text as positive, negative, or neutral: I love this product!"
      }
    ],
    "output_config": {
      "effort": "low"
    }
  }'
```

### Fast Mode

Deliver up to 2.5x higher output tokens per second from Opus 4.6 at 6x standard pricing. This is the same model, not a smaller one. Requires beta header and waitlist access.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "anthropic-beta: fast-mode-2026-02-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "speed": "fast",
    "messages": [
      {
        "role": "user",
        "content": "Refactor this module to use dependency injection"
      }
    ]
  }'
```

The response confirms the speed used in the `usage` object:

```json
{
  "usage": {
    "input_tokens": 523,
    "output_tokens": 1842,
    "speed": "fast"
  }
}
```

### Preserving Thinking Blocks in Tool Use

When Claude uses tools with thinking enabled, pass all thinking blocks back unmodified to maintain reasoning continuity. This includes the `signature` field and any `redacted_thinking` blocks.

```bash
curl https://api.anthropic.com/v1/messages \
  --header "x-api-key: $ANTHROPIC_API_KEY" \
  --header "anthropic-version: 2023-06-01" \
  --header "content-type: application/json" \
  --data '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 16000,
    "thinking": {"type": "enabled", "budget_tokens": 10000},
    "tools": [
      {
        "name": "get_weather",
        "description": "Get weather",
        "input_schema": {
          "type": "object",
          "properties": {"location": {"type": "string"}},
          "required": ["location"]
        }
      }
    ],
    "messages": [
      {"role": "user", "content": "What is the weather in Paris?"},
      {"role": "assistant", "content": [
        {"type": "thinking", "thinking": "The user wants weather...", "signature": "ORIGINAL_SIGNATURE_HERE"},
        {"type": "tool_use", "id": "toolu_01abc", "name": "get_weather", "input": {"location": "Paris"}}
      ]},
      {"role": "user", "content": [
        {"type": "tool_result", "tool_use_id": "toolu_01abc", "content": "20C, sunny"}
      ]}
    ]
  }'
```

Critical rules for thinking with tools:
- Pass back ALL thinking blocks unmodified (including `signature`)
- Do not rearrange or edit the sequence of thinking blocks
- `redacted_thinking` blocks must also be passed back as-is
- With adaptive thinking on Opus 4.6, interleaved thinking is automatic
- With other Claude 4 models, interleaved thinking requires beta header `interleaved-thinking-2025-05-14`
- Do not toggle thinking parameters mid-turn during a tool-use loop

## Quick Reference

| Operation | Syntax | Notes |
|---|---|---|
| Enable manual thinking | `"thinking": {"type": "enabled", "budget_tokens": N}` | N >= 1024, N < max_tokens. Deprecated on Opus 4.6. |
| Enable adaptive thinking | `"thinking": {"type": "adaptive"}` | Opus 4.6 only. Recommended. |
| Set effort level | `"output_config": {"effort": "low\|medium\|high\|max"}` | Works with or without thinking. `max` is Opus 4.6 only. |
| Enable fast mode | `"speed": "fast"` + header `anthropic-beta: fast-mode-2026-02-01` | Opus 4.6 only. Beta/waitlist. 6x price. |
| Disable thinking | Omit `thinking` parameter entirely | Lowest latency. |
| Interleaved thinking (Claude 4) | Header `anthropic-beta: interleaved-thinking-2025-05-14` | Automatic with adaptive thinking on Opus 4.6. |
| Streaming thinking deltas | `"stream": true` | Thinking arrives via `thinking_delta` events. |
| Check fast mode speed | `response.usage.speed` | Returns `"fast"` or `"standard"`. |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Setting `budget_tokens` >= `max_tokens` | Validation error | `budget_tokens` must be strictly less than `max_tokens` |
| Using `budget_tokens` on Opus 4.6 | Works but deprecated | Switch to `thinking: {type: "adaptive"}` with `effort` |
| Forcing tool use with thinking enabled | Error: incompatible | Only use `tool_choice: "auto"` or `"none"` with thinking |
| Dropping thinking blocks when sending tool results | Broken reasoning, signature errors | Always pass back ALL thinking blocks unmodified |
| Modifying or reordering thinking blocks | Signature verification failure | Pass blocks back exactly as received |
| Setting temperature with thinking | Error | Temperature and `top_k` are not compatible with thinking |
| Pre-filling assistant response with thinking | Error | Cannot use assistant prefill when thinking is enabled |
| Toggling thinking mid-turn in tool-use loop | Thinking silently disabled | Plan thinking strategy at start of each turn |
| Changing thinking params and expecting cache hits | Cache miss on messages | Changing `budget_tokens` or thinking type invalidates message cache |
| Expecting TTFT improvement from fast mode | No improvement | Fast mode improves output tokens/sec, not time to first token |
| Using `speed: "fast"` without beta header | Error | Must include `anthropic-beta: fast-mode-2026-02-01` header |
| Using `effort: "max"` on non-Opus 4.6 models | Error | `max` effort is Opus 4.6 only. Use `high` for other models. |
| Expecting billed tokens to match visible tokens | Billing surprise | Summarized thinking means you pay for full tokens, not the summary |

## References

- [Extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)
- [Adaptive thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)
- [Effort](https://platform.claude.com/docs/en/build-with-claude/effort)
- [Fast mode](https://platform.claude.com/docs/en/build-with-claude/fast-mode)
