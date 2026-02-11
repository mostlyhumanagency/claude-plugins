---
name: using-claude-citations
description: "Use when adding citations to Claude API responses, grounding answers in source documents, building RAG with verifiable references, tracing claims back to specific passages, or working with char_location/page_location/content_block_location citation types. Also use for cited_text extraction, enabling citations on plain text, PDF, and custom content, or replacing prompt-based quoting with native citation support."
---

## Overview

Citations let Claude trace its claims back to specific locations in source documents you provide. Attach documents (plain text, PDF, or custom content blocks) with `citations.enabled = true`, and the response comes back with interleaved text blocks -- some containing a `citations` array pointing to exact character ranges, page numbers, or content block indices in your source material.

## When to Use

- Building RAG applications where users must verify sources
- Grounding Claude's answers in provided documents with verifiable references
- Replacing prompt-based "quote the source" approaches (citations are cheaper and more reliable)
- Analyzing legal, financial, or research documents where traceability matters
- Any scenario requiring auditable source attribution

## When Not to Use

- When you need structured output (`output_config.format`) -- citations and structured outputs are incompatible
- Documents are image-only PDFs with no extractable text
- You want to cite images (not yet supported)
- Simple Q&A where source attribution is unnecessary
- For streaming citation events, see `streaming-claude-responses`
- For sending images and PDFs without citations, see `sending-media-to-claude`
- For structured output patterns, see `using-claude-structured-outputs`

## Core Patterns

### Citations with Plain Text

Provide a document with `source.type = "text"` and enable citations. Claude auto-chunks the text into sentences and cites by character index.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "text",
            "media_type": "text/plain",
            "data": "Photosynthesis converts sunlight into chemical energy. Plants use chlorophyll to absorb light."
          },
          "title": "Biology Notes",
          "citations": {"enabled": true}
        },
        {
          "type": "text",
          "text": "How do plants get energy?"
        }
      ]
    }]
  }'
```

The response `content` array alternates between:

- Plain text blocks (no citations) for connective language.
- Text blocks with a `citations` array, each citation containing:
  - `type`: `"char_location"` for plain text.
  - `cited_text`: the exact quoted source text (does NOT count toward output tokens).
  - `document_index`: 0-indexed reference to which document.
  - `start_char_index` / `end_char_index`: character range (0-indexed, exclusive end).

### Citations with PDF Documents

PDF citations use `page_location` instead of `char_location`, referencing page numbers.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "base64",
            "media_type": "application/pdf",
            "data": "'"$(base64 < report.pdf)"'"
          },
          "title": "Annual Report",
          "citations": {"enabled": true}
        },
        {
          "type": "text",
          "text": "What are the key findings?"
        }
      ]
    }]
  }'
```

PDF citations return `type: "page_location"` with page number references instead of character indices.

### Citations with Custom Content (Controlled Granularity)

When you need citations at a specific granularity (per bullet point, per transcript line) instead of automatic sentence chunking, use `source.type = "content"` with an array of text blocks.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "content",
            "content": [
              {"type": "text", "text": "Q3 revenue was $4.2M, up 15% YoY."},
              {"type": "text", "text": "Customer churn decreased to 2.1%."},
              {"type": "text", "text": "New enterprise deals: 12 signed in Q3."}
            ]
          },
          "title": "Q3 Report",
          "citations": {"enabled": true}
        },
        {
          "type": "text",
          "text": "Summarize the key metrics."
        }
      ]
    }]
  }'
```

Custom content citations use `content_block_location` with `start_block_index` / `end_block_index` (0-indexed, exclusive end) pointing into the content array you provided. No automatic chunking occurs -- each text block is a citable unit.

### Citations with Files API

Reference uploaded files by `file_id` for documents used across multiple requests.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {"type": "file", "file_id": "file_abc123"},
          "citations": {"enabled": true}
        },
        {"type": "text", "text": "Summarize this document with citations."}
      ]
    }]
  }'
```

### Citations in Streaming Mode

When streaming with citations enabled, a new delta type `citations_delta` appears in the event stream. It carries a single citation object to append to the current text block's `citations` array.

```
event: content_block_delta
data: {"type": "content_block_delta", "index": 0,
       "delta": {"type": "text_delta", "text": "the grass is green"}}

event: content_block_delta
data: {"type": "content_block_delta", "index": 0,
       "delta": {"type": "citations_delta",
                 "citation": {
                     "type": "char_location",
                     "cited_text": "The grass is green.",
                     "document_index": 0,
                     "document_title": "My Document",
                     "start_char_index": 0,
                     "end_char_index": 20
                 }}}
```

Accumulate text deltas and citations deltas per content block index to reconstruct the full cited response.

### Multiple Documents

Provide multiple documents in the same request. Each gets a unique `document_index` in citation responses.

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250514",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {"type": "text", "media_type": "text/plain", "data": "Revenue grew 15% in Q3."},
          "title": "Finance Report",
          "citations": {"enabled": true}
        },
        {
          "type": "document",
          "source": {"type": "text", "media_type": "text/plain", "data": "Employee satisfaction is at 92%."},
          "title": "HR Report",
          "citations": {"enabled": true}
        },
        {"type": "text", "text": "Give me a company overview."}
      ]
    }]
  }'
```

### Document Metadata

Add `title` and `context` fields to document blocks. Both are passed to Claude for understanding but are NOT citable -- only `source` content produces citations.

```json
{
  "type": "document",
  "source": {"type": "text", "media_type": "text/plain", "data": "..."},
  "title": "Q3 Financial Report",
  "context": "This report covers July through September 2024.",
  "citations": {"enabled": true}
}
```

### Caching Cited Documents

Add `cache_control` to document blocks for prompt caching. This reduces cost when the same documents are queried repeatedly.

```json
{
  "type": "document",
  "source": {"type": "text", "media_type": "text/plain", "data": "..."},
  "title": "Policy Document",
  "citations": {"enabled": true},
  "cache_control": {"type": "ephemeral"}
}
```

## Quick Reference

| Citation Type | Source Type | Location Reference |
|---|---|---|
| `char_location` | Plain text (`source.type = "text"`) | `start_char_index` / `end_char_index` |
| `page_location` | PDF (`source.type = "base64"` or `"file"`) | Page number |
| `content_block_location` | Custom content (`source.type = "content"`) | `start_block_index` / `end_block_index` |
| `search_result_location` | Search result blocks | `search_result_index` + block indices |

| Document Source | Syntax | Auto-Chunking |
|---|---|---|
| Plain text | `source.type: "text"`, `media_type: "text/plain"` | Yes (sentences) |
| PDF (base64) | `source.type: "base64"`, `media_type: "application/pdf"` | Yes (sentences) |
| PDF (URL) | `source.type: "url"`, `url: "..."` | Yes (sentences) |
| File API | `source.type: "file"`, `file_id: "file_..."` | Depends on file type |
| Custom content | `source.type: "content"`, `content: [...]` | No (your blocks) |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Enabling citations on some documents but not others | API error | Citations must be enabled on ALL or NONE of the documents in a request |
| Combining citations with structured outputs | 400 error | Citations and `output_config.format` are incompatible; pick one |
| Expecting citations from image-only PDFs | No citations returned | Only extractable text is citable; scanned-image PDFs produce no citations |
| Putting citable info in `title` or `context` | Claude references but cannot cite it | Only `source` content is citable; `title` and `context` are metadata |
| Expecting cited_text to count as output tokens | Budget calculations off | `cited_text` does NOT count toward output token usage |
| Not handling multiple citation types | Code breaks on PDFs vs plain text | Check `citation.type` and handle `char_location`, `page_location`, and `content_block_location` |

## References

- Anthropic citations documentation: https://docs.anthropic.com/en/docs/build-with-claude/citations
- For streaming citation events, see `streaming-claude-responses`
- For sending documents and PDFs, see `sending-media-to-claude`
- For structured outputs (incompatible with citations), see `using-claude-structured-outputs`
