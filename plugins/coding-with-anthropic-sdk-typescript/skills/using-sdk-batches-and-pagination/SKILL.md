---
name: using-sdk-batches-and-pagination
description: "Use when sending bulk requests with message batches in the TypeScript SDK, processing batch results at 50% cost reduction, paginating through API list endpoints, listing available Claude models, or counting tokens before sending requests. Also use for client.batches.create, batch status polling, auto-pagination with for-await, batch result file parsing, or optimizing cost for high-volume Claude API usage."
---

## Overview

The Anthropic TypeScript SDK supports the Message Batches API for processing large volumes of requests asynchronously at 50% cost reduction, auto-pagination helpers for list endpoints, a Models API for discovering available models, and a token counting endpoint. This skill covers batch creation and result retrieval, pagination patterns, model listing, and token counting.

## When to Use

- Creating message batches for bulk processing at reduced cost
- Polling for batch completion and retrieving results
- Paginating through list endpoints (batches, models)
- Listing available Claude models and their metadata
- Counting tokens before sending a request
- Processing large datasets or offline workloads with the Batches API

When NOT to use:

- For individual synchronous message requests (see `creating-sdk-messages`)
- For real-time streaming responses (see `streaming-sdk-responses`)
- For SDK installation and client setup (see `setting-up-anthropic-sdk-typescript`)

## Core Patterns

### Create a Message Batch

Submit multiple message requests as a batch. Each request has a `custom_id` for tracking and standard `params` matching the Messages API:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const batch = await client.messages.batches.create({
  requests: [
    {
      custom_id: "summarize-doc-1",
      params: {
        model: "claude-opus-4-6",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: "Summarize: The quick brown fox jumps over the lazy dog.",
          },
        ],
      },
    },
    {
      custom_id: "summarize-doc-2",
      params: {
        model: "claude-opus-4-6",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: "Summarize: TypeScript is a typed superset of JavaScript.",
          },
        ],
      },
    },
    {
      custom_id: "summarize-doc-3",
      params: {
        model: "claude-opus-4-6",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: "Summarize: The Anthropic API provides access to Claude.",
          },
        ],
      },
    },
  ],
});

console.log("Batch ID:", batch.id);
console.log("Status:", batch.processing_status); // "in_progress"
```

Batches are processed asynchronously. The response includes a batch ID for polling and result retrieval.

### Poll for Batch Completion

Check the batch status until processing finishes:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

async function waitForBatch(batchId: string): Promise<Anthropic.Messages.MessageBatch> {
  const pollIntervalMs = 10_000; // 10 seconds

  while (true) {
    const batch = await client.messages.batches.retrieve(batchId);
    console.log(
      `Status: ${batch.processing_status} | ` +
      `Succeeded: ${batch.request_counts.succeeded} | ` +
      `Errored: ${batch.request_counts.errored} | ` +
      `Expired: ${batch.request_counts.expired}`
    );

    if (batch.processing_status === "ended") {
      return batch;
    }

    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
  }
}

// Usage:
// const completedBatch = await waitForBatch("msgbatch_abc123");
```

The `processing_status` transitions from `"in_progress"` to `"ended"`. Individual requests within a batch can succeed, error, or expire independently.

### Retrieve and Process Batch Results

Once a batch has ended, stream results using the async iterator:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

async function processBatchResults(batchId: string) {
  const results = await client.messages.batches.results(batchId);

  for await (const entry of results) {
    console.log(`--- ${entry.custom_id} ---`);

    switch (entry.result.type) {
      case "succeeded": {
        // entry.result.message is a standard Anthropic.Message
        const text = entry.result.message.content
          .filter((b) => b.type === "text")
          .map((b) => {
            if (b.type === "text") return b.text;
            return "";
          })
          .join("");
        console.log("Response:", text);
        console.log("Tokens:", entry.result.message.usage);
        break;
      }
      case "errored": {
        console.error("Error:", entry.result.error);
        break;
      }
      case "expired": {
        console.warn("Request expired before processing");
        break;
      }
      case "canceled": {
        console.warn("Request was canceled");
        break;
      }
    }
  }
}
```

Results are streamed as JSONL. Each entry contains the `custom_id` and a `result` with one of four types: `succeeded`, `errored`, `expired`, or `canceled`.

### Complete Batch Workflow

End-to-end example: create a batch, wait for completion, and process results:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Step 1: Prepare batch requests from your data
const documents = [
  { id: "doc-1", text: "TypeScript adds static types to JavaScript." },
  { id: "doc-2", text: "Node.js is a JavaScript runtime built on V8." },
  { id: "doc-3", text: "The Anthropic API powers Claude AI assistants." },
];

const requests = documents.map((doc) => ({
  custom_id: doc.id,
  params: {
    model: "claude-opus-4-6" as const,
    max_tokens: 256,
    messages: [
      {
        role: "user" as const,
        content: `Summarize in one sentence: ${doc.text}`,
      },
    ],
  },
}));

// Step 2: Create the batch
const batch = await client.messages.batches.create({ requests });
console.log(`Created batch ${batch.id} with ${requests.length} requests`);

// Step 3: Poll until done
let status = batch.processing_status;
while (status !== "ended") {
  await new Promise((r) => setTimeout(r, 10_000));
  const updated = await client.messages.batches.retrieve(batch.id);
  status = updated.processing_status;
  console.log(`Batch ${batch.id}: ${status}`);
}

// Step 4: Collect results
const summaries: Record<string, string> = {};
const results = await client.messages.batches.results(batch.id);
for await (const entry of results) {
  if (entry.result.type === "succeeded") {
    const block = entry.result.message.content[0];
    summaries[entry.custom_id] = block.type === "text" ? block.text : "";
  }
}
console.log("Summaries:", summaries);
```

### Paginate Through List Endpoints

The SDK provides automatic pagination with `for await...of` on list methods:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Automatic pagination -- iterates through all pages
const allBatches: Anthropic.Messages.MessageBatch[] = [];
for await (const batch of client.messages.batches.list({ limit: 20 })) {
  allBatches.push(batch);
  console.log(`Batch ${batch.id}: ${batch.processing_status}`);
}
console.log(`Total batches: ${allBatches.length}`);
```

For manual page-by-page control:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Manual pagination -- process one page at a time
let page = await client.messages.batches.list({ limit: 20 });

for (const batch of page.data) {
  console.log(`Batch ${batch.id}: ${batch.processing_status}`);
}

while (page.hasNextPage()) {
  page = await page.getNextPage();
  for (const batch of page.data) {
    console.log(`Batch ${batch.id}: ${batch.processing_status}`);
  }
}
```

### List Available Models

Use the Models API to discover available Claude models:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// List all models with auto-pagination
for await (const model of client.models.list()) {
  console.log(`${model.id} -- ${model.display_name} (created: ${model.created_at})`);
}

// Retrieve a specific model by ID
const model = await client.models.retrieve("claude-opus-4-6");
console.log(model.display_name); // "Claude Opus 4.6"
```

Each model object contains:
- `id` -- the model identifier used in API requests
- `display_name` -- human-readable name
- `created_at` -- ISO 8601 timestamp
- `type` -- always `"model"`

### Count Tokens Before Sending

Estimate token usage before making a request. The counting endpoint accepts the same parameters as `messages.create`:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// Count tokens for a simple message
const count = await client.messages.countTokens({
  model: "claude-opus-4-6",
  messages: [
    {
      role: "user",
      content: "Explain the theory of relativity in detail.",
    },
  ],
});
console.log(`Input tokens: ${count.input_tokens}`);

// Count tokens with system prompt and tools
const fullCount = await client.messages.countTokens({
  model: "claude-opus-4-6",
  system: "You are a helpful science tutor.",
  messages: [
    { role: "user", content: "What is quantum entanglement?" },
  ],
  tools: [
    {
      name: "search_papers",
      description: "Search scientific papers",
      input_schema: {
        type: "object" as const,
        properties: {
          query: { type: "string" },
        },
        required: ["query"],
      },
    },
  ],
});
console.log(`Input tokens (with tools): ${fullCount.input_tokens}`);
```

Use token counting to estimate costs, check if messages fit within context limits, or decide whether to truncate content before sending.

### Cancel a Batch

Cancel an in-progress batch. Already-completed requests within the batch are not affected:

```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

const canceled = await client.messages.batches.cancel("msgbatch_abc123");
console.log(canceled.processing_status); // "canceling" then eventually "ended"
```

## Quick Reference

### Batch Lifecycle

| Status | Description |
|---|---|
| `in_progress` | Batch is being processed |
| `canceling` | Cancellation requested, finishing in-flight requests |
| `ended` | All requests completed, results available |

### Batch Result Types

| Result Type | Description |
|---|---|
| `succeeded` | Request completed; `result.message` contains the response |
| `errored` | Request failed; `result.error` contains error details |
| `expired` | Request was not processed before batch expiry |
| `canceled` | Request was canceled before processing |

### Batch Request Counts

| Field | Description |
|---|---|
| `request_counts.succeeded` | Number of successful requests |
| `request_counts.errored` | Number of failed requests |
| `request_counts.expired` | Number of expired requests |
| `request_counts.canceled` | Number of canceled requests |
| `request_counts.processing` | Number of requests still in progress |

### Key Methods

| Method | Description |
|---|---|
| `client.messages.batches.create()` | Create a new batch |
| `client.messages.batches.retrieve(id)` | Get batch status |
| `client.messages.batches.results(id)` | Stream batch results |
| `client.messages.batches.list()` | List batches (paginated) |
| `client.messages.batches.cancel(id)` | Cancel an in-progress batch |
| `client.models.list()` | List available models (paginated) |
| `client.models.retrieve(id)` | Get a specific model |
| `client.messages.countTokens()` | Count input tokens |

## Common Mistakes

**Trying to read results before batch has ended**
Calling `batches.results()` on a batch with `processing_status: "in_progress"` returns an error. Always check that `processing_status === "ended"` before retrieving results.

**Not handling all result types**
Batch results can be `succeeded`, `errored`, `expired`, or `canceled`. Code that only checks for `succeeded` silently drops failed requests. Always handle all four result types or at minimum log unexpected ones.

**Using batches for real-time requests**
Batches are processed asynchronously and may take minutes to hours. They are designed for offline workloads, not real-time responses. For immediate results, use the standard `messages.create` or streaming endpoints.

**Duplicate custom_id values in a batch**
Each `custom_id` within a batch must be unique. Duplicate IDs cause the batch creation to fail with a 400 error. Generate unique IDs per request (e.g., using UUIDs or sequential identifiers).

**Not paginating large list results**
List endpoints return paginated results. Using `.list()` without iteration only returns the first page. Always use `for await...of` for complete results, or manually call `hasNextPage()` and `getNextPage()`.

**Assuming token counts are exact for responses**
`countTokens` counts input tokens only. It does not predict how many output tokens Claude will generate. Use it for input cost estimation and context window management, not total cost prediction.

## References

- Message Batches API: https://docs.anthropic.com/en/docs/build-with-claude/message-batches
- Models API: https://docs.anthropic.com/en/api/models
- Token counting: https://docs.anthropic.com/en/docs/build-with-claude/token-counting
- Anthropic TypeScript SDK: https://github.com/anthropics/anthropic-sdk-typescript
- Pagination helpers: https://github.com/anthropics/anthropic-sdk-typescript#pagination
