# coding-with-anthropic-sdk-typescript

Claude Code plugin for the Anthropic TypeScript SDK (`@anthropic-ai/sdk`) — everything you need to build with Claude using the official TypeScript/JavaScript client.

## Skills (8 + router)

| Skill | Description |
|---|---|
| **coding-with-anthropic-sdk-typescript** (router) | Routes to the right subskill when the topic is unclear |
| **setting-up-anthropic-sdk-typescript** | Installation, client configuration, environments, TypeScript types, proxies |
| **creating-sdk-messages** | messages.create(), parameters, multi-turn, system prompts, token counting |
| **streaming-sdk-responses** | stream: true (async iterable), .stream() helper, events, cancellation |
| **using-sdk-tools-and-schemas** | Tool definitions, Zod helpers (betaZodTool), toolRunner, tool_choice, server tools |
| **handling-sdk-errors-and-retries** | APIError subclasses, retries, timeouts, request IDs, logging |
| **using-sdk-batches-and-pagination** | Message batches, auto-pagination, models API, token counting endpoint |
| **using-sdk-beta-apis** | Beta namespace, files API, skills API, code execution, beta headers |
| **using-sdk-advanced-patterns** | Raw responses, custom fetch, proxies, Bedrock/Vertex SDKs, undocumented endpoints |

## Agents (2)

| Agent | Description |
|---|---|
| **anthropic-sdk-ts-expert** | Deep help with any Anthropic TypeScript SDK feature — design, integration, best practices |
| **anthropic-sdk-ts-debugger** | Diagnose SDK errors, TypeScript issues, and integration problems |

## Commands (2)

| Command | Description |
|---|---|
| `/sdk-reference <topic>` | Look up SDK reference for a specific topic |
| `/debug-sdk-error <error>` | Diagnose an SDK error or unexpected behavior |

## Installation

```bash
claude install-plugin github:mostlyhumanagency/claude-plugins/plugins/coding-with-anthropic-sdk-typescript
```

## What's Covered

- **@anthropic-ai/sdk** — The main TypeScript SDK for the Anthropic API
- **@anthropic-ai/bedrock-sdk** — Amazon Bedrock integration
- **@anthropic-ai/vertex-sdk** — Google Vertex AI integration

## What's NOT Covered

- **Raw API** — See the `using-anthropic-api` plugin for raw REST API usage (curl, HTTP)
- **Python SDK** — Will be a separate plugin
- **Prompt engineering** — General prompting techniques
