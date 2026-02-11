---
name: using-anthropic-api
description: "Use when making HTTP requests to the Claude API, building integrations with Anthropic's REST endpoints, or troubleshooting raw API calls — covers messages, context, caching, thinking, streaming, citations, media, structured outputs, tools, built-in tools, server tools, agent skills, and Bedrock. Routes to the specific subskill."
---

# Using the Anthropic API (Dispatcher)

## Overview

Pick the most specific Anthropic API skill and use it. Do not load broad references unless no specific skill fits.

## Skill Map

| Skill | Triggers |
|---|---|
| `working-with-claude-messages` | Messages API basics, roles, stop reasons, system prompts, multi-turn conversations, model selection |
| `streaming-claude-responses` | SSE streaming, server-sent events, content_block_delta, stream events |
| `using-claude-thinking-and-effort` | Extended thinking, thinking budget, effort parameter, adaptive effort |
| `managing-claude-context` | Context window, token limits, compaction, context editing, long conversations |
| `using-claude-prompt-caching` | Prompt caching, cache_control, ephemeral breakpoints, reducing costs |
| `sending-media-to-claude` | Images, PDFs, files, vision, base64, media_type, document content blocks |
| `using-claude-structured-outputs` | JSON mode, structured output, JSON schema, prefilled responses |
| `using-claude-citations` | Citations, source attribution, cited quotes, document citations |
| `implementing-claude-tool-use` | Custom tools, tool_use, tool_result, tool_choice, programmatic calling, fine-grained streaming |
| `using-claude-built-in-tools` | Bash tool, code execution, computer use, text editor, type identifiers |
| `using-claude-server-tools-and-mcp` | Web search, web fetch, memory, tool search, MCP connector, remote MCP servers |
| `using-claude-agent-skills` | Agent skills, pptx/xlsx/docx/pdf generation, Skills API, custom skills, SKILL.md |
| `running-claude-on-bedrock` | Amazon Bedrock, AWS, IAM auth, global/regional endpoints, AnthropicBedrock SDK |

## Default

When no specific skill matches, use `working-with-claude-messages`.
