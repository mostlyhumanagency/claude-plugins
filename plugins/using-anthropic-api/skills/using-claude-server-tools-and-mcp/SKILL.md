---
name: using-claude-server-tools-and-mcp
description: "Use when enabling Claude to search the web, fetch URLs, remember information across conversations, search large tool libraries, or connect to MCP servers via the API. Covers web_search, web_fetch, memory tool, tool_search, and mcp_toolset configuration. Also use for url_not_allowed errors, defer_loading validation, remote MCP server setup, or adding real-time web access and persistent memory to Claude applications."
---

# Using Claude Server Tools and MCP

## Overview

Claude provides server-side tools for real-time web access, persistent memory, tool discovery at scale, and remote MCP server connections. These extend Claude beyond its training data and enable multi-session workflows, large tool libraries, and third-party integrations -- all configured through the Messages API.

## When to Use

- Adding real-time web search to Claude responses
- Fetching and analyzing full web page or PDF content from URLs
- Building cross-session memory for long-running agents
- Managing 10-10,000 tools with on-demand discovery
- Connecting Claude to remote MCP tool servers (Slack, GitHub, databases)

## When Not to Use

- Use `implementing-claude-tool-use` for defining and calling your own custom tools
- Use `using-claude-built-in-tools` for bash, code execution, computer use, or text editor tools
- Use `using-claude-agent-skills` for pre-built document generation skills

## Core Patterns

### Web Search

Give Claude real-time internet access. Claude decides when to search, executes queries, and synthesizes results with automatic source citations. Server-side -- you just enable it.

Type identifier: `web_search_20250305`. No beta header required.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "What are the latest Claude API changes?"}
    ],
    "tools": [{
      "type": "web_search_20250305",
      "name": "web_search",
      "max_uses": 3,
      "allowed_domains": ["docs.anthropic.com", "anthropic.com"],
      "user_location": {
        "type": "approximate",
        "country": "US",
        "timezone": "America/Los_Angeles"
      }
    }]
  }'
```

Use `allowed_domains` to restrict to trusted sources, or `blocked_domains` to exclude sites. Never use both together. Set `max_uses` to limit the number of searches per request. Pricing: $10 per 1,000 searches plus token costs.

Pass the full assistant response (including `encrypted_content` fields) back in multi-turn conversations to preserve citations.

### Web Fetch

Retrieve full content from specific URLs (HTML pages and PDFs). Unlike web search which finds pages, web fetch reads them in full. Claude can only fetch URLs already present in the conversation -- it cannot fabricate URLs.

Type identifier: `web_fetch_20250910`. Beta header required: `web-fetch-2025-09-10`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: web-fetch-2025-09-10" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 4096,
    "messages": [
      {"role": "user", "content": "Analyze the content at https://example.com/report.pdf"}
    ],
    "tools": [{
      "type": "web_fetch_20250910",
      "name": "web_fetch",
      "max_uses": 2,
      "max_content_tokens": 50000,
      "citations": {"enabled": true}
    }]
  }'
```

Set `max_content_tokens` to prevent runaway token usage from large pages. Citations are optional on web fetch (unlike web search where they are always on). Web fetch does not execute JavaScript -- use static pages or APIs.

### Combined Search + Fetch

Find pages via search, then read them in full. Include both tools and Claude orchestrates the flow automatically.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: web-fetch-2025-09-10" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 4096,
    "messages": [
      {"role": "user", "content": "Find and deeply analyze recent research on protein folding"}
    ],
    "tools": [
      {"type": "web_search_20250305", "name": "web_search", "max_uses": 3},
      {
        "type": "web_fetch_20250910",
        "name": "web_fetch",
        "max_uses": 2,
        "max_content_tokens": 50000,
        "citations": {"enabled": true}
      }
    ]
  }'
```

### Memory Tool

Persistent file-based storage across conversations. Claude can create, read, update, and delete files in a `/memories` directory. Your application implements the actual file operations -- Claude emits tool calls.

Type identifier: `memory_20250818`. Beta header required: `context-management-2025-06-27`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: context-management-2025-06-27" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 2048,
    "messages": [
      {"role": "user", "content": "Continue refactoring the auth module from yesterday"}
    ],
    "tools": [{
      "type": "memory_20250818",
      "name": "memory"
    }]
  }'
```

Claude emits commands like:

```json
{"command": "view", "path": "/memories"}
{"command": "view", "path": "/memories/auth_progress.xml"}
{"command": "create", "path": "/memories/status.xml", "file_text": "..."}
{"command": "str_replace", "path": "/memories/status.txt", "old_str": "Step 2: In progress", "new_str": "Step 2: Complete"}
{"command": "delete", "path": "/memories/old_notes.txt"}
{"command": "rename", "path": "/memories/old.txt", "new_path": "/memories/new.txt"}
```

Implement handlers for all 6 commands: `view`, `create`, `str_replace`, `insert`, `delete`, `rename`. The SDKs provide base classes (`BetaAbstractMemoryTool` in Python, `betaMemoryTool` in TypeScript) to simplify this.

### Tool Search for Large Tool Libraries

When you have 10-10,000 tools, loading all definitions wastes tokens and degrades selection accuracy. Tool search lets Claude discover tools on-demand. Tools marked `defer_loading: true` stay out of context until found.

Two variants available. Beta header required: `advanced-tool-use-2025-11-20`.

**Regex variant** -- Claude writes Python regex patterns:

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: advanced-tool-use-2025-11-20" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 2048,
    "messages": [
      {"role": "user", "content": "Create a Jira ticket for the login bug"}
    ],
    "tools": [
      {"type": "tool_search_tool_regex_20251119", "name": "tool_search_tool_regex"},
      {
        "name": "jira_create_issue",
        "description": "Create a new Jira issue in a project",
        "input_schema": {
          "type": "object",
          "properties": {
            "project": {"type": "string"},
            "summary": {"type": "string"},
            "type": {"type": "string", "enum": ["bug", "task", "story"]}
          },
          "required": ["project", "summary", "type"]
        },
        "defer_loading": true
      }
    ]
  }'
```

**BM25 variant** -- Claude writes natural language queries. Use `tool_search_tool_bm25_20251119` instead.

At least one tool must NOT have `defer_loading: true`. Keep 3-5 most-used tools non-deferred. Never defer the tool_search tool itself. Maximum 10,000 tools supported.

### MCP Connector

Connect Claude to remote MCP (Model Context Protocol) servers directly from the Messages API without building your own MCP client. Supports OAuth authentication and multiple simultaneous servers.

Beta header required: `mcp-client-2025-11-20`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: mcp-client-2025-11-20" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1000,
    "messages": [
      {"role": "user", "content": "Post a summary of recent GitHub PRs to Slack"}
    ],
    "mcp_servers": [
      {
        "type": "url",
        "url": "https://github-mcp.example.com/sse",
        "name": "github-mcp",
        "authorization_token": "ghp_xxx"
      },
      {
        "type": "url",
        "url": "https://slack-mcp.example.com/sse",
        "name": "slack-mcp",
        "authorization_token": "xoxb-xxx"
      }
    ],
    "tools": [
      {"type": "mcp_toolset", "mcp_server_name": "github-mcp"},
      {
        "type": "mcp_toolset",
        "mcp_server_name": "slack-mcp",
        "configs": {
          "delete_channel": {"enabled": false}
        }
      }
    ]
  }'
```

Configuration patterns for MCP tools:
- **Allowlist**: Set `default_config.enabled: false`, then enable specific tools in `configs`
- **Denylist**: Default enabled, disable specific dangerous tools in `configs`
- **Deferred + tool search**: Set `default_config.defer_loading: true` and combine with `tool_search_tool_regex`

Every `mcp_servers` entry needs exactly one matching `mcp_toolset` in `tools`. HTTPS only. Only tools are supported (not MCP resources or prompts). Not available on Bedrock/Vertex.

## Quick Reference

| Tool/Feature | Type Identifier | Beta Header | Key Capabilities |
|---|---|---|---|
| Web Search | `web_search_20250305` | None | Real-time search, auto-citations, domain filtering |
| Web Fetch | `web_fetch_20250910` | `web-fetch-2025-09-10` | Full page/PDF retrieval, optional citations |
| Memory | `memory_20250818` | `context-management-2025-06-27` | Persistent file storage across conversations |
| Tool Search (Regex) | `tool_search_tool_regex_20251119` | `advanced-tool-use-2025-11-20` | Regex-based tool discovery, max 10K tools |
| Tool Search (BM25) | `tool_search_tool_bm25_20251119` | `advanced-tool-use-2025-11-20` | Natural language tool discovery |
| MCP Connector | `mcp_toolset` + `mcp_servers` | `mcp-client-2025-11-20` | Remote MCP server connection, OAuth |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Web fetch without beta header | 400 error | Add `anthropic-beta: web-fetch-2025-09-10` |
| Fetching JS-rendered pages | Empty or partial content | Web fetch does not execute JavaScript |
| Fetching URLs not in conversation | `url_not_allowed` error | Claude can only fetch URLs from user messages, prior search results, or prior fetch results |
| All tools set to `defer_loading: true` | 400 validation error | At least one tool must be non-deferred |
| `allowed_domains` AND `blocked_domains` together | Validation error | Use one or the other, never both |
| MCP server not referenced by toolset | Validation error | Every `mcp_servers` entry needs exactly one `mcp_toolset` in `tools` |
| Deferring the tool_search tool | Tool search unavailable | Never defer the tool_search tool itself |
| Not implementing memory handlers | Memory calls go unanswered | Implement all 6 commands: view, create, str_replace, insert, delete, rename |
| Regex syntax in BM25 (or vice versa) | Poor results | Regex uses Python `re.search()` patterns; BM25 uses natural language |
| Forgetting `encrypted_content` in multi-turn search | Citations break | Include full assistant response in conversation history |

## References

- [Web search tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool)
- [Web fetch tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-fetch-tool)
- [Memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)
- [Tool search tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)
- [MCP connector](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector)
- [Remote MCP servers](https://platform.claude.com/docs/en/agents-and-tools/remote-mcp-servers)
