---
name: sending-media-to-claude
description: "Use when sending images, PDFs, or files to the Claude API, uploading files via the Files API, base64 encoding media for the Messages API, using Claude's vision capabilities, estimating image token costs, or processing document content. Also use for file_id references, supported media types (JPEG, PNG, GIF, WebP, PDF), Voyage AI embeddings, or building applications that analyze visual or document content."
---

## Overview

Claude accepts images, PDFs, and text files as input alongside text messages. Media can be provided inline (base64-encoded or URL-referenced) or via the Files API for persistent upload-once, use-many-times storage. For vector embeddings (semantic search, RAG retrieval), Anthropic recommends Voyage AI as the embedding provider since Claude's API does not include an embeddings endpoint.

## When to Use

- Sending images for description, analysis, OCR, chart interpretation, or visual comparison
- Processing PDFs to extract information, summarize, or answer questions about document content
- Uploading files once and referencing them across multiple API calls
- Building RAG retrieval pipelines with Voyage AI embeddings
- Combining document input with prompt caching for repeated queries

## When Not to Use

- Image generation or editing (Claude is read-only for images)
- Precise spatial reasoning or object counting in images
- Person identification from photographs
- Medical diagnostic imaging without human oversight
- Encrypted or password-protected PDFs
- PDFs exceeding 100 pages (split first)
- For citation-grounded document analysis, see `using-claude-citations`
- For basic message structure, see `working-with-claude-messages`
- For prompt caching patterns, see `using-claude-prompt-caching`

## Core Patterns

### Sending Images via URL

The simplest approach -- provide a URL and Claude fetches the image.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "url",
            "url": "https://example.com/photo.jpg"
          }
        },
        {
          "type": "text",
          "text": "Describe this image."
        }
      ]
    }]
  }'
```

### Sending Images via Base64

Encode local images and include them directly in the request.

```bash
BASE64_IMAGE=$(base64 < photo.jpg)

curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "image/jpeg",
            "data": "'"$BASE64_IMAGE"'"
          }
        },
        {
          "type": "text",
          "text": "What objects are in this image?"
        }
      ]
    }]
  }'
```

Supported image formats: JPEG, PNG, GIF, WebP. Place images before the question text for best results.

### Multiple Images

Include multiple `image` blocks in the content array. Label them for clarity when asking comparative questions.

```json
{
  "role": "user",
  "content": [
    {"type": "image", "source": {"type": "url", "url": "https://example.com/before.jpg"}},
    {"type": "image", "source": {"type": "url", "url": "https://example.com/after.jpg"}},
    {"type": "text", "text": "Image 1 is before renovation, Image 2 is after. What changed?"}
  ]
}
```

Up to 100 images per API request. If sending more than 20 images, each must be under 2000x2000 pixels.

### Processing PDFs via URL

Use `"type": "document"` for PDFs. Claude extracts both text and page images, enabling analysis of charts, tables, and diagrams.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "url",
            "url": "https://example.com/report.pdf"
          }
        },
        {
          "type": "text",
          "text": "Summarize the key findings."
        }
      ]
    }]
  }'
```

### Processing PDFs via Base64 with Caching

For repeated queries against the same PDF, combine base64 encoding with prompt caching.

```bash
jq -n --rawfile PDF_BASE64 pdf_base64.txt '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
        "role": "user",
        "content": [{
            "type": "document",
            "source": {
                "type": "base64",
                "media_type": "application/pdf",
                "data": $PDF_BASE64
            },
            "cache_control": { "type": "ephemeral" }
        },
        {
            "type": "text",
            "text": "What revenue figures are shown in the charts?"
        }]
    }]
}' > request.json

curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d @request.json
```

### Files API: Upload, Reference, Manage

Upload a file once, then reference it by `file_id` in any number of Messages requests. Currently in beta.

```bash
# Step 1: Upload a file
curl -X POST https://api.anthropic.com/v1/files \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -F "file=@/path/to/document.pdf"
# Response: { "id": "file_abc123", "filename": "document.pdf", ... }

# Step 2: Reference by file_id in messages
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {"type": "file", "file_id": "file_abc123"}
        },
        {"type": "text", "text": "Summarize this document."}
      ]
    }]
  }'

# List all uploaded files
curl https://api.anthropic.com/v1/files \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14"

# Delete a file (permanent)
curl -X DELETE https://api.anthropic.com/v1/files/file_abc123 \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14"
```

Files persist until explicitly deleted and are scoped to the API key's workspace. File operations (upload, list, delete) are free; token costs apply only when files are used in Messages.

### Images via Files API

Use `"type": "image"` (not `"document"`) when referencing uploaded images.

```json
{
  "type": "image",
  "source": {"type": "file", "file_id": "file_img456"}
}
```

### Embeddings with Voyage AI

Anthropic does not offer an embeddings endpoint. Use Voyage AI for semantic search, RAG retrieval, recommendations, and clustering.

```bash
# Generate embeddings for documents
curl https://api.voyageai.com/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $VOYAGE_API_KEY" \
  -d '{
    "input": ["Sample document text", "Another document"],
    "model": "voyage-3.5",
    "input_type": "document"
  }'

# Generate embeddings for queries (use input_type="query")
curl https://api.voyageai.com/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $VOYAGE_API_KEY" \
  -d '{
    "input": ["What is the revenue forecast?"],
    "model": "voyage-3.5",
    "input_type": "query"
  }'
```

Voyage AI model options:

- `voyage-3-large` for best quality
- `voyage-3.5` for general purpose
- `voyage-3.5-lite` for speed and cost optimization
- `voyage-code-3` for code embeddings
- `voyage-finance-2` and `voyage-law-2` for domain-specific use
- `voyage-multimodal-3` for images and text combined
- Quantization: `float` (default), `int8`, `binary` for storage savings

## Quick Reference

| Operation | Content Type | Source Types |
|---|---|---|
| Send image | `"type": "image"` | `url`, `base64`, `file` |
| Send PDF | `"type": "document"` | `url`, `base64`, `file` |
| Send plain text file | `"type": "document"` | `text`, `file` |
| Upload file | `POST /v1/files` | Multipart form data |
| List files | `GET /v1/files` | Beta header required |
| Delete file | `DELETE /v1/files/{file_id}` | Permanent, not recoverable |
| Download file | `GET /v1/files/{file_id}/content` | Only for code execution outputs |

| Limit | Value |
|---|---|
| Max images per request | 100 (20 on claude.ai) |
| Max image dimensions | 8000x8000 px (2000x2000 if >20 images) |
| Max PDF pages | 100 per request |
| Max request payload | 32 MB |
| Max file upload size | 500 MB |
| Image token formula | `(width * height) / 750` |
| PDF token cost | ~1,500-3,000 text tokens/page + image tokens/page |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Sending oversized images | High latency, no quality gain | Resize to max 1568px on longest edge before sending |
| Exceeding image dimension limits | 400 error | Keep under 8000x8000 px (2000x2000 if >20 images) |
| Using `"type": "document"` for images | 400 invalid file type error | Images use `"type": "image"`; PDFs/text use `"type": "document"` |
| Forgetting Files API beta header | 400 or feature-not-found error | Include `anthropic-beta: files-api-2025-04-14` |
| Trying to download an uploaded file | 400 error | Only files created by code execution are downloadable |
| Sending encrypted/password-protected PDFs | Processing fails | Use standard, unprotected PDFs only |
| Placing images after text | Slightly degraded performance | Place images before question text for best results |
| Omitting `input_type` in Voyage embeddings | Reduced retrieval quality | Always set `input_type="document"` or `input_type="query"` |
| Exceeding 100 pages per PDF | 400 error | Split large PDFs into chunks of 100 pages or fewer |
| Exceeding 32 MB request payload | 413 error | Compress or split content |

## References

- Vision documentation: https://docs.anthropic.com/en/docs/build-with-claude/vision
- PDF support documentation: https://docs.anthropic.com/en/docs/build-with-claude/pdf-support
- Files API documentation: https://docs.anthropic.com/en/docs/build-with-claude/files
- Embeddings documentation: https://docs.anthropic.com/en/docs/build-with-claude/embeddings
- For citation-grounded analysis, see `using-claude-citations`
- For prompt caching with documents, see `using-claude-prompt-caching`
