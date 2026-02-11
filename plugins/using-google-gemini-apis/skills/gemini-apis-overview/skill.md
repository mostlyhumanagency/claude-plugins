---
name: gemini-apis-overview
description: Use only when a user wants an overview of available Google Gemini API skills or when unsure which Gemini skill applies. Routes to the correct sub-skill.
---

# Google Gemini APIs Overview

## Available API Areas

### Live API
Real-time audio and video streaming. Use for interactive voice conversations, live audio processing, or real-time video analysis.

- Model: `gemini-2.5-flash-native-audio-preview-12-2025`

### Veo (Video Generation)
Generate videos from text prompts or images. Use for creating short video clips, visual content, or motion graphics.

- Models:
  - `veo-3.1-generate-preview` -- highest quality
  - `veo-3.1-fast-generate-preview` -- faster generation
  - `veo-2.0-generate-001` -- previous generation

### Nano Banana (Image Generation)
Generate and edit images from text prompts. Use for creating illustrations, editing existing images, or generating visual assets.

- Models:
  - `gemini-2.5-flash-image` -- standard image generation
  - `gemini-3-pro-image-preview` -- Pro quality

## SDK Installation

Python:

```bash
pip install google-genai
```

TypeScript:

```bash
npm install @google/genai
```

## Authentication

Set one of these environment variables with your API key:

```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

## Client Setup

Python:

```python
from google import genai

client = genai.Client()
```

TypeScript:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});
```

The client automatically reads the API key from the environment variables listed above.

## Skill Routing Table

| Task | Language | Skill |
|------|----------|-------|
| Real-time audio/video streaming | Python | `using-gemini-live-api-python` |
| Real-time audio/video streaming | TypeScript | `using-gemini-live-api-typescript` |
| Video generation | Python | `using-veo-api-python` |
| Video generation | TypeScript | `using-veo-api-typescript` |
| Image generation/editing | Python | `using-nano-banana-python` |
| Image generation/editing | TypeScript | `using-nano-banana-typescript` |

## Related Skills

- `using-gemini-live-api-python` -- Live API with Python
- `using-gemini-live-api-typescript` -- Live API with TypeScript
- `using-veo-api-python` -- Veo video generation with Python
- `using-veo-api-typescript` -- Veo video generation with TypeScript
- `using-nano-banana-python` -- Nano Banana image generation with Python
- `using-nano-banana-typescript` -- Nano Banana image generation with TypeScript
