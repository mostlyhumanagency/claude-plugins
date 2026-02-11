---
name: using-sdk-beta-apis
description: "Use when accessing beta or preview features in the Anthropic TypeScript SDK, uploading files with the Files API, running code execution in a sandbox, using extended context, enabling skills, or managing beta headers. Also use for client.beta.*, 'anthropic-beta' header configuration, toFile helper for uploads, feature-gated API access, or enabling new Claude capabilities before they reach general availability."
---

## Overview

The Anthropic TypeScript SDK exposes beta and preview features through the `client.beta.*` namespace. Each beta feature requires a specific header value passed in the `betas` array. This skill covers activating beta features, using the Files API, working with the Skills API, and managing beta headers correctly.

## When to Use

- Enabling a beta or preview feature (code execution, files, extended context, etc.)
- Uploading files using the Files API beta
- Using `toFile` helper to convert streams, buffers, or fetch responses to uploadable files
- Checking which beta header value to use for a given feature
- Working with the Skills API beta
- Enabling extended cache TTL, 128K output, or 1M context betas

When NOT to use:

- For general message creation without beta features (see `creating-sdk-messages`)
- For streaming (see `streaming-sdk-responses`)
- For error handling and retries (see `handling-sdk-errors-and-retries`)

## Core Patterns

### Access Beta Features

All beta features live under `client.beta.*`. Pass the required beta header in the `betas` array on every request that uses the feature:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Example: use the code execution beta
const response = await client.beta.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 1024,
  messages: [
    { role: "user", content: "What is 4242424242 * 4242424242?" },
  ],
  tools: [
    { name: "code_execution", type: "code_execution_20250522" },
  ],
  betas: ["code-execution-2025-05-22"],
});

// Process the response — code execution returns server_tool_use blocks
for (const block of response.content) {
  if (block.type === "text") {
    console.log(block.text);
  } else if (block.type === "server_tool_use") {
    console.log("Tool used:", block.name);
  }
}
```

### Upload Files with the Files API

The Files API beta lets you upload files for use in conversations. Use the `toFile` helper to convert various input types into uploadable files:

```typescript
import fs from "fs";
import Anthropic, { toFile } from "@anthropic-ai/sdk";

const client = new Anthropic();

// Upload from a Node.js ReadStream
const fromStream = await client.beta.files.upload({
  file: await toFile(
    fs.createReadStream("/path/to/data.json"),
    undefined,
    { type: "application/json" }
  ),
  betas: ["files-api-2025-04-14"],
});
console.log("Uploaded:", fromStream.id, fromStream.filename);

// Upload from the File web API
const fromFileApi = await client.beta.files.upload({
  file: new File(["file content here"], "notes.txt", {
    type: "text/plain",
  }),
  betas: ["files-api-2025-04-14"],
});

// Upload from a fetch Response
const fromFetch = await client.beta.files.upload({
  file: await fetch("https://example.com/document.pdf"),
  betas: ["files-api-2025-04-14"],
});

// Upload from a Buffer or Uint8Array
const fromBuffer = await client.beta.files.upload({
  file: await toFile(
    Buffer.from("raw bytes here"),
    "output.txt",
    { type: "text/plain" }
  ),
  betas: ["files-api-2025-04-14"],
});
```

The upload response includes: `id`, `created_at`, `filename`, `mime_type`, `size_bytes`, `type` (`"file"`), and optionally `downloadable`.

### Use the toFile Helper

Import `toFile` from the SDK root. It converts streams, buffers, and byte arrays into uploadable file objects:

```typescript
import Anthropic, { toFile } from "@anthropic-ai/sdk";

// Signature: toFile(data, filename?, options?)
// data: fs.ReadStream | Buffer | Uint8Array
// filename: string | undefined (auto-detected from stream when undefined)
// options: { type: string } — always set content-type explicitly
```

Always provide the `type` option. The Files API does not infer MIME types from file extensions.

### Enable Multiple Betas

Pass multiple beta header values in the `betas` array to combine features:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const response = await client.beta.messages.create({
  model: "claude-opus-4-6",
  max_tokens: 16384,
  messages: [{ role: "user", content: "Analyze this data thoroughly." }],
  betas: [
    "output-128k-2025-02-19",           // Enable 128K output tokens
    "token-efficient-tools-2025-02-19",  // Reduce token usage for tools
  ],
});
```

### Work with the Skills API

The Skills API beta provides endpoints for creating and managing skills:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Create a skill
const skill = await client.beta.skills.create({
  // skill body parameters
  betas: ["skills-2025-10-02"],
});

// Response shape:
// {
//   id: string,
//   created_at: string,
//   display_title: string,
//   latest_version: object,
//   source: object,
//   type: "skill",
//   updated_at: string,
// }
console.log("Skill created:", skill.id, skill.display_title);
```

## Quick Reference

### Beta Header Values

| Beta Feature | Header Value |
|---|---|
| Message Batches | `message-batches-2024-09-24` |
| Prompt Caching | `prompt-caching-2024-07-31` |
| Computer Use | `computer-use-2025-01-24` |
| PDFs | `pdfs-2024-09-25` |
| Token Counting | `token-counting-2024-11-01` |
| Token-efficient Tools | `token-efficient-tools-2025-02-19` |
| Output 128K | `output-128k-2025-02-19` |
| Files API | `files-api-2025-04-14` |
| MCP Client | `mcp-client-2025-11-20` |
| Full Thinking (dev) | `dev-full-thinking-2025-05-14` |
| Interleaved Thinking | `interleaved-thinking-2025-05-14` |
| Code Execution | `code-execution-2025-05-22` |
| Extended Cache TTL | `extended-cache-ttl-2025-04-11` |
| Context 1M | `context-1m-2025-08-07` |
| Context Management | `context-management-2025-06-27` |
| Skills API | `skills-2025-10-02` |
| Fast Mode | `fast-mode-2026-02-01` |

### toFile Input Types

| Input Type | Example |
|---|---|
| `fs.ReadStream` | `toFile(fs.createReadStream("path"), undefined, { type: "..." })` |
| `Buffer` | `toFile(Buffer.from("data"), "file.txt", { type: "..." })` |
| `Uint8Array` | `toFile(new Uint8Array([...]), "file.bin", { type: "..." })` |
| `File` (web) | Pass directly, no `toFile` needed |
| `fetch` Response | Pass `await fetch(url)` directly |

### Files API Response Shape

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Unique file identifier |
| `created_at` | `string` | ISO 8601 timestamp |
| `filename` | `string` | Original filename |
| `mime_type` | `string` | Content type of the file |
| `size_bytes` | `number` | File size |
| `type` | `"file"` | Always `"file"` |
| `downloadable` | `boolean?` | Whether the file can be downloaded |

## Common Mistakes

**Missing the `betas` array on the request**
Beta features require the `betas` array on every request, not just the first one. If you omit it, the API returns a standard (non-beta) response or an error. Always include the correct beta header value.

**Not setting MIME type when using toFile**
The Files API does not infer content types from filenames. Always pass `{ type: "application/json" }` or the appropriate MIME type in the options. Omitting it may cause upload failures or incorrect file handling.

**Using `client.messages.create` instead of `client.beta.messages.create`**
Beta features are only available through the `client.beta.*` namespace. Calling `client.messages.create` with beta-specific parameters (like code execution tools) will fail. Use `client.beta.messages.create` instead.

**Passing an invalid beta header value**
Beta header values follow a strict format: `feature-name-YYYY-MM-DD`. A typo or wrong date causes the API to ignore the beta. Copy header values from the reference table above.

**Combining incompatible betas**
Not all beta features can be used together. If you receive an error about incompatible features, check the API documentation for the specific combination. Remove one beta at a time to isolate the conflict.

## References

- Anthropic TypeScript SDK repository: https://github.com/anthropics/anthropic-sdk-typescript
- Anthropic API documentation: https://docs.anthropic.com/en/api
- Files API guide: https://docs.anthropic.com/en/docs/build-with-claude/files
- Beta features overview: https://docs.anthropic.com/en/docs/about-claude/models#beta-features
- SDK README: https://github.com/anthropics/anthropic-sdk-typescript/blob/main/README.md
