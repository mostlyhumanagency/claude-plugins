---
name: running-claude-on-bedrock
description: "Use when deploying Claude on Amazon Bedrock, setting up AWS credentials for Claude API access, choosing global vs regional endpoints, converting Anthropic API calls to Bedrock format, or using the AnthropicBedrock SDK client. Also use for Bedrock model ID formats like 'global.anthropic.claude-opus-4-6-v1', ValidationException errors, cross-region inference, or migrating from direct API to Bedrock."
---

# Running Claude on Amazon Bedrock

## Overview

Amazon Bedrock lets you call the same Claude Messages API through AWS infrastructure using IAM credentials instead of an Anthropic API key. The request/response format is nearly identical to the direct API -- the main differences are model ID format, endpoint URL, and the addition of `anthropic_version: "bedrock-2023-05-31"` in the request body when using boto3.

## When to Use

- Your organization is already on AWS and needs IAM-based access control
- Data residency requirements mandate specific geographic regions
- You want consolidated AWS billing and existing cost management tooling
- You need VPC integration or AWS PrivateLink for private connectivity

## When Not to Use

- You need the latest beta features immediately (some reach the direct API first)
- You want the simplest setup (direct API with an API key is simpler)
- You need the Skills API (currently a direct API beta feature only)
- Your workload is small and AWS auth overhead is not justified
- Use `working-with-claude-messages` for general Messages API patterns that apply to both direct and Bedrock

## Core Patterns

### Direct API Call via AWS CLI

Use the `invoke-model` command with the same Messages body format. Add `anthropic_version` in the body.

```bash
aws bedrock-runtime invoke-model \
  --region us-west-2 \
  --model-id "global.anthropic.claude-opus-4-6-v1" \
  --content-type "application/json" \
  --accept "application/json" \
  --body '{
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 256,
    "messages": [
      {"role": "user", "content": "Hello, world"}
    ]
  }' \
  output.json
```

### Using the Anthropic Bedrock SDK (Python)

Install the Bedrock extras and use `AnthropicBedrock` for the same Messages API interface with automatic AWS auth.

```bash
pip install "anthropic[bedrock]"
```

```python
from anthropic import AnthropicBedrock

client = AnthropicBedrock(
    aws_region="us-west-2",
    # Uses default AWS credential chain (env vars, ~/.aws/credentials, IAM role)
)

message = client.messages.create(
    model="us.anthropic.claude-opus-4-6-v1",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Explain quantum computing in simple terms"}
    ]
)
print(message.content[0].text)
```

The SDK handles SigV4 signing automatically. You do not need to set `anthropic_version` in the body -- the SDK adds it.

### Using the Anthropic Bedrock SDK (TypeScript)

```bash
npm install @anthropic-ai/bedrock-sdk
```

```typescript
import AnthropicBedrock from "@anthropic-ai/bedrock-sdk";

const client = new AnthropicBedrock({
  awsRegion: "us-west-2",
});

const message = await client.messages.create({
  model: "us.anthropic.claude-opus-4-6-v1",
  maxTokens: 1024,
  messages: [
    { role: "user", content: "Explain quantum computing in simple terms" }
  ]
});
console.log(message.content[0].text);
```

### Global vs Regional Endpoints

Choose the endpoint type by the model ID prefix:

```bash
# Global endpoint (recommended default) -- dynamic routing, no premium
aws bedrock-runtime invoke-model \
  --model-id "global.anthropic.claude-opus-4-6-v1" \
  --region us-west-2 \
  --body '{"anthropic_version": "bedrock-2023-05-31", "max_tokens": 256, "messages": [{"role": "user", "content": "Hello"}]}' \
  output.json

# Regional endpoint -- data stays in region, 10% pricing premium
aws bedrock-runtime invoke-model \
  --model-id "us.anthropic.claude-opus-4-6-v1" \
  --region us-west-2 \
  --body '{"anthropic_version": "bedrock-2023-05-31", "max_tokens": 256, "messages": [{"role": "user", "content": "Hello"}]}' \
  output.json

# No prefix -- routes to the specific region you connect to
aws bedrock-runtime invoke-model \
  --model-id "anthropic.claude-opus-4-6-v1" \
  --region us-west-2 \
  --body '{"anthropic_version": "bedrock-2023-05-31", "max_tokens": 256, "messages": [{"role": "user", "content": "Hello"}]}' \
  output.json
```

### 1M Context on Bedrock

Enable the extended 1M context window with a beta header.

```bash
aws bedrock-runtime invoke-model \
  --model-id "global.anthropic.claude-opus-4-6-v1" \
  --region us-west-2 \
  --body '{
    "anthropic_version": "bedrock-2023-05-31",
    "anthropic_beta": ["context-1m-2025-08-07"],
    "max_tokens": 4096,
    "messages": [{"role": "user", "content": "Summarize this very long document..."}]
  }' \
  output.json
```

Note: On Bedrock, beta headers go inside the body as `anthropic_beta` (an array), not as HTTP headers.

## Quick Reference

| Feature | Value | Notes |
|---|---|---|
| Opus 4.6 | `anthropic.claude-opus-4-6-v1` | Global: add `global.` prefix |
| Sonnet 4.5 | `anthropic.claude-sonnet-4-5-20250929-v1:0` | Not available in APAC |
| Haiku 4.5 | `anthropic.claude-haiku-4-5-20251001-v1:0` | Not available in JP or APAC |
| Global endpoints | `global.` prefix | Dynamic routing, no premium. Recommended default |
| Regional: US | `us.` prefix | Data residency. 10% premium |
| Regional: EU | `eu.` prefix | Data residency. 10% premium |
| Regional: JP | `jp.` prefix | Data residency. 10% premium |
| Regional: APAC | `apac.` prefix | Data residency. 10% premium |
| anthropic_version | `bedrock-2023-05-31` | Required in body for boto3/raw HTTP. Not needed with Anthropic SDK |
| Auth | AWS IAM / SigV4 | No Anthropic API key. Uses default credential chain |
| Python SDK | `pip install "anthropic[bedrock]"` | Uses `AnthropicBedrock` client |
| TypeScript SDK | `npm install @anthropic-ai/bedrock-sdk` | Uses `AnthropicBedrock` class |
| 1M context beta | `context-1m-2025-08-07` | Opus 4.6, Sonnet 4.5, Sonnet 4 |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Wrong model ID format | `ValidationException` | Use full ID like `global.anthropic.claude-opus-4-6-v1`; check region availability |
| Missing `anthropic_version` in boto3 body | 400 error from Bedrock | Add `"anthropic_version": "bedrock-2023-05-31"` in the request body |
| Using direct API key with Bedrock | Auth failure | Bedrock uses AWS IAM credentials, not `x-api-key` |
| Using `anthropic-beta` header instead of body field | Beta features not enabled | On Bedrock, use `"anthropic_beta": [...]` array in the body |
| Model not available in chosen region | `ValidationException` | Check model availability; Sonnet 4.5 not in APAC, Haiku 4.5 not in JP/APAC |
| Forgetting region parameter | Default region may not have model | Always specify `--region` explicitly |

## References

- [Claude on Amazon Bedrock](https://platform.claude.com/docs/en/build-with-claude/claude-on-amazon-bedrock)
