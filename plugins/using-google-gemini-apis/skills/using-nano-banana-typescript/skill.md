---
name: using-nano-banana-typescript
description: Use when generating or editing images with Google Nano Banana (Gemini image models) using the @google/genai TypeScript SDK — text-to-image, image editing, text rendering, multi-turn editing, reference images, high-resolution output, and Google Search grounding.
---

# Nano Banana Image Generation (TypeScript SDK)

## Overview

Nano Banana is Google's native image generation and editing capability built into Gemini models. It supports text-to-image generation, image editing with text and image inputs, text rendering within images, multi-turn conversational editing, reference-image-guided generation, high-resolution output up to 4K, and Google Search grounding for real-time data visualization. The `@google/genai` TypeScript SDK provides a unified interface for both AI Studio and Vertex AI.

## When to Use

- Generating images from text prompts (text-to-image)
- Editing existing images with natural language instructions
- Rendering readable text within generated images (signs, labels, infographics)
- Multi-turn conversational image editing (iterative refinement via chat)
- Using reference images to maintain subject consistency across generations
- Creating high-resolution images (2K, 4K) for production assets
- Generating images grounded in real-time data via Google Search

## When Not to Use

- Video generation -- use the Veo API (`using-veo-api-typescript`)
- Real-time audio/video streaming -- use the Live API (`using-gemini-live-api-typescript`)
- Image understanding or analysis without generation -- use standard `ai.models.generateContent()` with `responseModalities: ["TEXT"]`
- Batch image processing at scale -- consider server-side Python workflows (`using-nano-banana-python`)

## Quick Reference

| Property | Values |
|----------|--------|
| Models | `gemini-2.5-flash-image` (fast, efficient), `gemini-3-pro-image-preview` (pro quality, advanced reasoning) |
| Aspect ratios | `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9` |
| Resolutions | `1K` (default), `2K`, `4K` (Pro model only for 4K) |
| Response modalities | `["TEXT", "IMAGE"]` for image output; `["TEXT"]` for text-only |
| Output format | Base64-encoded PNG in `part.inlineData.data` |
| Max reference images | Up to 5 with Pro model |
| Google Search grounding | Supported via `tools: [{ googleSearch: {} }]` |
| Watermark | All generated images include SynthID watermark |

## SDK Installation

```bash
npm install @google/genai
```

## Authentication

Set one of these environment variables:

```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

The client reads the API key automatically from the environment.

## Examples

### Basic Text-to-Image

Generate an image from a text prompt and save it to disk.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function generateImage(): Promise<void> {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-image",
    contents: "A serene Japanese garden with a wooden bridge over a koi pond, watercolor style",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("garden.png", buffer);
      console.log("Image saved as garden.png");
    }
  }
}

generateImage();
```

### Image Editing (Text + Image Input)

Edit an existing image by providing it alongside a text instruction. The model understands the image context and applies the requested changes.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function editImage(): Promise<void> {
  const imageBytes = fs.readFileSync("input-photo.png");
  const base64Image = imageBytes.toString("base64");

  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-image",
    contents: [
      {
        text: "Change the background to a sunset beach scene while keeping the subject unchanged",
      },
      {
        inlineData: {
          mimeType: "image/png",
          data: base64Image,
        },
      },
    ],
    config: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("edited-photo.png", buffer);
      console.log("Image saved as edited-photo.png");
    }
  }
}

editImage();
```

### High-Resolution Output (Pro Model, 4K)

Use the Pro model with `imageConfig` to generate high-resolution images. The `imageSize` parameter accepts `"1K"`, `"2K"`, or `"4K"`.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function generateHighRes(): Promise<void> {
  const response = await ai.models.generateContent({
    model: "gemini-3-pro-image-preview",
    contents: "A detailed architectural blueprint of a modern minimalist house, isometric view, technical drawing style",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "16:9",
        imageSize: "4K",
      },
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("blueprint-4k.png", buffer);
      console.log("4K image saved as blueprint-4k.png");
    }
  }
}

generateHighRes();
```

### Text Rendering in Images

Nano Banana can render readable text within generated images. Be explicit about text content, placement, and styling in your prompt.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function generateWithText(): Promise<void> {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-image",
    contents: [
      "A vintage-style travel poster for Tokyo, Japan. " +
      "The poster has the title 'TOKYO' in large bold Art Deco lettering at the top. " +
      "Below the illustration, the text reads 'The City of the Future' in elegant serif font. " +
      "Include cherry blossoms, Mount Fuji in the background, and neon signs with Japanese characters.",
    ].join(""),
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "2:3",
      },
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("tokyo-poster.png", buffer);
      console.log("Image saved as tokyo-poster.png");
    }
  }
}

generateWithText();
```

### Multi-Turn Editing (Chat)

Use the chat interface for iterative image editing. The model retains context from previous turns, so you can refine an image step by step.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function multiTurnEdit(): Promise<void> {
  const chat = ai.chats.create({
    model: "gemini-3-pro-image-preview",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  });

  // Turn 1: Generate the initial image
  let response = await chat.sendMessage({
    message: "Create a colorful infographic explaining the water cycle. " +
      "Include evaporation, condensation, precipitation, and collection stages " +
      "with clear labels and arrows showing the flow.",
  });

  let imageIndex = 1;
  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log("Turn 1:", part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(`water-cycle-v${imageIndex}.png`, buffer);
      console.log(`Saved water-cycle-v${imageIndex}.png`);
      imageIndex++;
    }
  }

  // Turn 2: Refine the image
  response = await chat.sendMessage({
    message: "Make the color palette more muted and professional. " +
      "Change the style to flat design with a dark background.",
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log("Turn 2:", part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(`water-cycle-v${imageIndex}.png`, buffer);
      console.log(`Saved water-cycle-v${imageIndex}.png`);
      imageIndex++;
    }
  }

  // Turn 3: Change aspect ratio and resolution for final output
  response = await chat.sendMessage({
    message: "Translate all labels into Spanish. Do not change any other elements.",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "16:9",
        imageSize: "2K",
      },
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log("Turn 3:", part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(`water-cycle-v${imageIndex}.png`, buffer);
      console.log(`Saved water-cycle-v${imageIndex}.png`);
    }
  }
}

multiTurnEdit();
```

### Reference Images for Consistency

Provide multiple reference images to guide subject appearance or style. The Pro model supports up to 5 reference images. Describe each reference image's role in the prompt so the model understands how to use them.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

function loadImageAsBase64(filePath: string): string {
  return fs.readFileSync(filePath).toString("base64");
}

async function generateWithReferences(): Promise<void> {
  const person1 = loadImageAsBase64("person1.jpg");
  const person2 = loadImageAsBase64("person2.jpg");
  const styleRef = loadImageAsBase64("art-style-reference.jpg");

  const response = await ai.models.generateContent({
    model: "gemini-3-pro-image-preview",
    contents: [
      {
        text: "Create a group portrait of these two people standing in front of the Eiffel Tower. " +
          "Use the art style from the third reference image. " +
          "The first image is Person A, the second is Person B, the third is the style reference.",
      },
      {
        inlineData: { mimeType: "image/jpeg", data: person1 },
      },
      {
        inlineData: { mimeType: "image/jpeg", data: person2 },
      },
      {
        inlineData: { mimeType: "image/jpeg", data: styleRef },
      },
    ],
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "5:4",
        imageSize: "2K",
      },
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("group-portrait.png", buffer);
      console.log("Image saved as group-portrait.png");
    }
  }
}

generateWithReferences();
```

### Google Search Grounding

Enable Google Search grounding to generate images informed by real-time data. This is useful for visualizing current events, live data, or up-to-date information.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});

async function generateWithSearch(): Promise<void> {
  const response = await ai.models.generateContent({
    model: "gemini-3-pro-image-preview",
    contents: "Visualize the current weather forecast for the next 5 days in San Francisco " +
      "as a clean, modern weather chart. Include temperature highs and lows, " +
      "weather icons, and a visual suggestion for what to wear each day.",
    config: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "16:9",
        imageSize: "2K",
      },
      tools: [{ googleSearch: {} }],
    },
  });

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      console.log(part.text);
    } else if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync("weather-forecast.png", buffer);
      console.log("Image saved as weather-forecast.png");
    }
  }
}

generateWithSearch();
```

### Reusable Helper Function

For production code, wrap the generation and saving logic in a reusable utility.

```typescript
import { GoogleGenAI, type GenerateContentResponse } from "@google/genai";
import * as fs from "node:fs";
import * as path from "node:path";

const ai = new GoogleGenAI({});

interface GeneratedResult {
  text: string[];
  imagePaths: string[];
}

async function generateAndSave(options: {
  model?: string;
  prompt: string | Array<Record<string, unknown>>;
  outputDir?: string;
  filePrefix?: string;
  aspectRatio?: string;
  imageSize?: string;
  useSearch?: boolean;
}): Promise<GeneratedResult> {
  const {
    model = "gemini-2.5-flash-image",
    prompt,
    outputDir = ".",
    filePrefix = "generated",
    aspectRatio,
    imageSize,
    useSearch = false,
  } = options;

  const config: Record<string, unknown> = {
    responseModalities: ["TEXT", "IMAGE"],
  };

  if (aspectRatio || imageSize) {
    config.imageConfig = {
      ...(aspectRatio && { aspectRatio }),
      ...(imageSize && { imageSize }),
    };
  }

  if (useSearch) {
    config.tools = [{ googleSearch: {} }];
  }

  const response: GenerateContentResponse = await ai.models.generateContent({
    model,
    contents: prompt,
    config,
  });

  const result: GeneratedResult = { text: [], imagePaths: [] };
  let imageCount = 0;

  for (const part of response.candidates![0].content.parts) {
    if (part.text) {
      result.text.push(part.text);
    } else if (part.inlineData) {
      imageCount++;
      const ext = part.inlineData.mimeType === "image/jpeg" ? "jpg" : "png";
      const filePath = path.join(outputDir, `${filePrefix}-${imageCount}.${ext}`);
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(filePath, buffer);
      result.imagePaths.push(filePath);
    }
  }

  return result;
}

// Usage
async function main(): Promise<void> {
  const result = await generateAndSave({
    model: "gemini-3-pro-image-preview",
    prompt: "A photorealistic image of a coffee shop interior, morning light streaming through windows",
    outputDir: "./output",
    filePrefix: "coffee-shop",
    aspectRatio: "16:9",
    imageSize: "2K",
  });

  console.log("Text:", result.text.join("\n"));
  console.log("Images:", result.imagePaths);
}

main();
```

## Prompt Engineering Tips

- **Be specific about composition.** Describe subject, background, lighting, camera angle, and art style explicitly. "A golden retriever sitting in a sunlit meadow, shallow depth of field, warm golden hour lighting" produces better results than "a dog in a field."
- **Use art direction vocabulary.** Terms like "isometric", "flat design", "watercolor", "oil painting", "photorealistic", "cinematic lighting", "bird's-eye view" give the model concrete stylistic anchors.
- **Quote exact text for rendering.** When you want text in the image, put it in quotes and describe font style and placement: "The title 'HELLO WORLD' in bold sans-serif lettering centered at the top."
- **Describe reference images explicitly.** When providing reference images, describe the role of each in the text prompt: "The first image is the subject, the second is the style reference." The model does not infer roles automatically.
- **Iterate with multi-turn chat.** Start with a broad prompt, then refine in subsequent turns. Chat context carries forward, so you can say "make the background darker" without re-describing the entire scene.
- **Use negative phrasing sparingly.** Rather than "no blurry images", describe what you want positively: "sharp focus, high detail." The model responds better to positive descriptions.
- **Leverage Google Search for data accuracy.** When generating infographics or data visualizations with real-world data, enable Google Search grounding to ensure accuracy.
- **Match aspect ratio to content.** Use `16:9` for landscapes and presentations, `9:16` for mobile/portrait content, `1:1` for social media, `2:3` or `3:4` for posters.

## Common Pitfalls

- **Missing `responseModalities`.** If you do not set `responseModalities: ["TEXT", "IMAGE"]`, the model returns text only. This is the most common mistake.
- **Using `"text"` instead of `"TEXT"`.** Response modality values must be uppercase strings: `"TEXT"` and `"IMAGE"`.
- **Resolution string format.** The `imageSize` values are `"1K"`, `"2K"`, `"4K"` (uppercase K). Values like `"1080p"` or `"4k"` (lowercase) are not valid.
- **4K only on Pro model.** The `"4K"` resolution is only supported on `gemini-3-pro-image-preview`. Using it with `gemini-2.5-flash-image` will produce an error or fall back to a lower resolution.
- **Response structure.** Always check `response.candidates![0].content.parts` -- the response may contain a mix of text and image parts in any order. Iterate over all parts rather than assuming a fixed structure.
- **Large base64 payloads.** Input images are sent as base64, which increases payload size by approximately 33%. Very large images may hit request size limits. Resize input images to reasonable dimensions before encoding.
- **Chat config per turn.** In multi-turn chat, you can override `config` on individual `sendMessage` calls (for example, to change aspect ratio or resolution). The override applies only to that turn.
- **No streaming for image output.** Image generation does not support streaming responses. The entire image is returned in a single response after generation completes.
- **SynthID watermark.** All generated images include an invisible SynthID watermark. This cannot be disabled.
- **Content safety filters.** Prompts and generated images are subject to safety filtering. Requests that trigger safety filters return no image data. Check that `response.candidates` is not empty before accessing parts.

## Model Comparison

| Feature | gemini-2.5-flash-image | gemini-3-pro-image-preview |
|---------|------------------------|----------------------------|
| Speed | Faster | Slower |
| Quality | Good | Best |
| Max resolution | 2K | 4K |
| Text rendering | Good | Better |
| Reference images | Supported | Up to 5, better consistency |
| Multi-turn chat | Supported | Supported |
| Google Search grounding | Supported | Supported |
| Advanced reasoning | Basic | Advanced (layout, composition) |
| Cost per image | Lower | Higher |
| Best for | Rapid iteration, simple generations | Production assets, complex scenes |

## Related Skills

- `gemini-apis-overview` -- Overview of all Gemini API skills
- `using-nano-banana-python` -- Nano Banana image generation with Python
- `using-veo-api-typescript` -- Veo video generation with TypeScript
- `using-gemini-live-api-typescript` -- Live API for real-time streaming
