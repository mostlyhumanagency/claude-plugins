---
description: "Scan codebase for Gemini API anti-patterns: deprecated models, missing error handling, suboptimal configurations"
---

# gemini-check

Scan the codebase for common Gemini API anti-patterns and suggest improvements.

## Process

1. Find all files importing Gemini SDK (`google.genai`, `@google/genai`, `google.generativeai`)
2. Check for deprecated model names:
   - `gemini-pro` (use `gemini-2.5-flash` or newer)
   - `gemini-pro-vision` (use multimodal models)
   - Old preview model IDs that may have been deprecated
3. Check Live API usage:
   - Missing error handling on WebSocket connections
   - No timeout on session duration
   - Requesting both TEXT and AUDIO response modalities (not supported)
   - Missing VAD configuration for voice applications
4. Check Veo usage:
   - No timeout on operation polling (infinite loop risk)
   - Not checking `operation.error` before accessing response
   - Not downloading videos promptly (2-day expiry)
   - Using extension with non-Veo videos
5. Check Nano Banana usage:
   - Missing "IMAGE" in response_modalities
   - Using lowercase image_size values
   - Using standard model for features requiring Pro
   - Not handling safety filter rejections
6. Check authentication patterns:
   - Hardcoded API keys in source code
   - Missing environment variable validation
7. Report each finding with file path, line number, severity, and fix suggestion
8. Summarize: total issues by severity, recommended action order
