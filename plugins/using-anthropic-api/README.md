# using-anthropic-api

Claude Code plugin for the Anthropic Claude API — everything you need to build with Claude's Messages API, except the language-specific SDKs.

## Skills (13 + router)

| Skill | Description |
|---|---|
| **using-anthropic-api** (router) | Routes to the right subskill when the topic is unclear |
| **working-with-claude-messages** | Messages API basics: requests, responses, multi-turn, content blocks, stop reasons |
| **managing-claude-context** | Context windows, 1M beta, compaction, tool result clearing, thinking block clearing |
| **using-claude-prompt-caching** | Prompt caching: cache_control, TTL, breakpoints, multi-turn caching, tool caching |
| **using-claude-thinking-and-effort** | Extended thinking, adaptive thinking, effort levels, fast mode |
| **streaming-claude-responses** | SSE streaming: event flow, text/tool/thinking deltas, error recovery |
| **using-claude-citations** | Citations: plain text, PDF, custom content, streaming citations |
| **sending-media-to-claude** | Vision, PDF support, Files API, Voyage AI embeddings |
| **using-claude-structured-outputs** | JSON schema enforcement, strict tool use, token counting, multilingual, search results |
| **implementing-claude-tool-use** | Tool definitions, tool_choice, parallel tools, fine-grained streaming, programmatic calling |
| **using-claude-built-in-tools** | Bash, Code Execution, Computer Use, Text Editor tools |
| **using-claude-server-tools-and-mcp** | Web search, web fetch, memory, tool search, MCP connector |
| **using-claude-agent-skills** | Pre-built and custom Agent Skills, Skills API, SKILL.md format |
| **running-claude-on-bedrock** | Claude on Amazon Bedrock: model IDs, endpoints, AWS auth |

## Agents (2)

| Agent | Description |
|---|---|
| **anthropic-api-expert** | Deep help with any Anthropic API feature — design, integration, best practices |
| **anthropic-api-debugger** | Diagnose API errors, unexpected responses, and integration issues |

## Commands (2)

| Command | Description |
|---|---|
| `/api-reference <topic>` | Look up API reference for a specific topic |
| `/debug-api-error <error>` | Diagnose an API error or unexpected behavior |

## Installation

```bash
claude install-plugin github:mostlyhumanagency/claude-plugins/plugins/using-anthropic-api
```

## What's NOT Covered

- **Language SDKs** — Python SDK, TypeScript SDK, etc. will be separate plugins
- **Prompt engineering** — General prompting techniques and strategies
- **Claude.ai / Claude Code** — This plugin covers the API, not the consumer products
