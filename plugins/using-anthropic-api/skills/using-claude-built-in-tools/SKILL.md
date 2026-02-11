---
name: using-claude-built-in-tools
description: "Use when letting Claude run code, execute bash commands, control a computer, or edit files via built-in tools in the API — bash_20250124, code_execution_20250825, computer_20251124, text_editor_20250728. Also use for wrong tool type errors, missing beta headers, str_replace matching failures, choosing which built-in tool to use, or building agents that interact with a shell, browser, or filesystem."
---

# Using Claude Built-in Tools

## Overview

Anthropic provides four pre-built tools with special type identifiers: Bash (persistent shell), Code Execution (server-side sandbox), Computer Use (GUI automation via screenshots), and Text Editor (structured file editing). These tools use `type` instead of `input_schema` -- Claude already knows their interfaces.

## When to Use

- Running shell commands via the Bash tool
- Executing code in Anthropic's server-side sandbox
- Automating desktop GUI interactions through screenshots and clicks
- Making precise, safe file edits with exact-match replacements
- Choosing between client-side (Bash, Text Editor) and server-side (Code Execution) execution

## When Not to Use

- Use `implementing-claude-tool-use` for defining and calling your own custom tools
- Use `using-claude-server-tools-and-mcp` for web search, web fetch, memory, or MCP connector
- Use `using-claude-agent-skills` for pre-built document generation skills (pptx, xlsx, docx, pdf)

## Core Patterns

### Bash Tool

Run shell commands in a persistent session. State (environment variables, working directory) persists between commands within a conversation. You host the execution environment.

Type identifier: `bash_20250124`. No beta header required.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tools": [{
      "type": "bash_20250124",
      "name": "bash"
    }],
    "messages": [
      {"role": "user", "content": "List all Python files and count their lines."}
    ]
  }'
```

Claude responds with a `tool_use` block containing `command` (the shell command to run). Execute it and return stdout/stderr as a `tool_result`.

Key parameters: `command` (required), `restart` (optional, set `true` to reset the session).

### Code Execution Tool

Server-side sandboxed environment hosted by Anthropic. Claude runs code without requiring you to implement execution infrastructure. Pre-installed Python and data-science libraries.

Type identifier: `code_execution_20250825`. Beta header required: `code-execution-2025-08-25`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: code-execution-2025-08-25" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [{
      "role": "user",
      "content": "Calculate the mean and standard deviation of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
    }],
    "tools": [{
      "type": "code_execution_20250825",
      "name": "code_execution"
    }]
  }'
```

This is a server tool. The response includes `server_tool_use` blocks (not regular `tool_use`), and results come back as `bash_code_execution_tool_result` or `text_editor_code_execution_tool_result` blocks. You do NOT execute anything yourself.

Reuse containers to persist files across requests by passing the `container` ID from the previous response:

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: code-execution-2025-08-25" \
  -H "content-type: application/json" \
  -d '{
    "container": "cntr_01ABC...",
    "model": "claude-opus-4-6",
    "max_tokens": 4096,
    "messages": [{"role": "user", "content": "Read /tmp/number.txt"}],
    "tools": [{"type": "code_execution_20250825", "name": "code_execution"}]
  }'
```

Sandbox limits: 1 CPU, 5 GiB RAM, 5 GiB disk, no internet access, containers expire after 30 days.

### Computer Use Tool

Interact with graphical desktops through screenshots, mouse clicks, and keyboard input. Claude sees screenshots, decides on actions, and you execute them in a VM or container.

Type identifier: `computer_20251124` (Opus 4.5/4.6) or `computer_20250124` (other models). Beta header required: `computer-use-2025-11-24` or `computer-use-2025-01-24`.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: computer-use-2025-11-24" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tools": [{
      "type": "computer_20251124",
      "name": "computer",
      "display_width_px": 1024,
      "display_height_px": 768,
      "display_number": 1
    }],
    "messages": [
      {"role": "user", "content": "Take a screenshot and describe what you see."}
    ]
  }'
```

Required parameters: `display_width_px`, `display_height_px`. Optional: `display_number`, `enable_zoom`.

Available actions: `screenshot`, `left_click`, `right_click`, `double_click`, `triple_click`, `middle_click`, `type`, `key`, `mouse_move`, `scroll`, `left_click_drag`, `left_mouse_down`/`up`, `hold_key`, `wait`, `zoom` (Opus 4.5/4.6 only).

Execute each action in your VM/container and return screenshots as base64 images in the `tool_result`.

### Text Editor Tool

Structured file viewing and editing with exact-match replacements. Safer than raw shell manipulation because `str_replace` requires a unique match.

Type identifier: `text_editor_20250728` (Claude 4.x) or `text_editor_20250124` (Sonnet 3.7). No beta header required.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-6",
    "max_tokens": 1024,
    "tools": [{
      "type": "text_editor_20250728",
      "name": "str_replace_based_edit_tool"
    }],
    "messages": [
      {"role": "user", "content": "Fix the syntax error in primes.py."}
    ]
  }'
```

Commands: `view` (read file or directory), `str_replace` (exact find-and-replace), `create` (new file), `insert` (add text at line number).

Optional parameter: `max_characters` (truncate large file views, `text_editor_20250728` only).

Note: `undo_edit` was available in Sonnet 3.7 but removed in Claude 4. Implement your own backup/undo logic.

## Quick Reference

| Tool | Type Identifier | Beta Header | Execution | Token Overhead |
|---|---|---|---|---|
| Bash | `bash_20250124` | None | Client-side (you host) | 245 input tokens |
| Code Execution | `code_execution_20250825` | `code-execution-2025-08-25` | Server-side (Anthropic hosts) | 1,550 free hrs/mo, then $0.05/hr |
| Computer Use | `computer_20251124` / `computer_20250124` | `computer-use-2025-11-24` / `computer-use-2025-01-24` | Client-side (you host VM) | 735 tokens + system prompt |
| Text Editor | `text_editor_20250728` / `text_editor_20250124` | None | Client-side (you host) | 700 input tokens |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Wrong tool version for model | Unexpected behavior or errors | Use `bash_20250124` / `text_editor_20250728` for Claude 4.x; `text_editor_20250124` for Sonnet 3.7 |
| Missing beta header for Code Execution | 400 error or tool not recognized | Add `anthropic-beta: code-execution-2025-08-25` |
| Missing beta header for Computer Use | 400 error or tool not recognized | Add `anthropic-beta: computer-use-2025-11-24` (Opus 4.5/4.6) or `computer-use-2025-01-24` (others) |
| Executing Code Execution results yourself | Duplicated or broken execution | Code Execution is a server tool -- Anthropic runs it. Pass the response back in conversation |
| Coordinate scaling issues in Computer Use | Clicks miss targets | Resize screenshots and scale Claude's coordinates back to original resolution |
| `str_replace` matches multiple locations | Error: "Found N matches" | Provide more surrounding context in `old_str` to make the match unique |
| `str_replace` matches nothing | Error: "No match found" | Verify exact whitespace/indentation; use `view` first to confirm content |
| Using `undo_edit` with Claude 4.x | Command not recognized | `undo_edit` removed in Claude 4; implement your own undo |
| Missing `display_width_px`/`display_height_px` | Validation error | These are required parameters for the computer tool |
| Expecting internet in Code Execution sandbox | Network requests fail | Sandbox has no internet; upload data via Files API |

## References

- [Bash tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/bash-tool)
- [Code execution tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool)
- [Computer use tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)
- [Text editor tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/text-editor-tool)
