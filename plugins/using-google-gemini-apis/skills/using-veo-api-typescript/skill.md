---
name: using-veo-api-typescript
description: Use when generating videos with Google Veo API using the @google/genai TypeScript SDK — text-to-video, video extension, frame-specific generation, reference images, portrait/landscape modes, resolution control, and prompt engineering.
---

# Google Veo Video Generation -- TypeScript SDK

## Overview

Veo generates short video clips (4-8 seconds) from text prompts or images using the Gemini API. The `@google/genai` TypeScript SDK provides async video generation with an operation polling pattern.

**Models:**

| Model | Use Case | Max Resolution | Strengths |
|-------|----------|----------------|-----------|
| `veo-3.1-generate-preview` | Highest quality | 4K | Best visual fidelity, native audio, cinematic quality |
| `veo-3.1-fast-generate-preview` | Fast iteration | 720p | Quicker generation for prototyping and drafts |
| `veo-2.0-generate-001` | Legacy/stable | 720p | Previous generation, widely tested |

## When to Use

- Generating short video clips from text descriptions
- Creating videos from reference images (image-to-video)
- Extending existing videos with new scenes
- Interpolating between first and last frames
- Generating portrait (9:16) or landscape (16:9) video content

## When NOT to Use

- Real-time video streaming (use the Live API instead)
- Video editing or compositing (Veo generates new clips, not edits)
- Videos longer than 8 seconds in a single generation (use extension for longer content)
- Image generation (use Nano Banana / Gemini image models instead)

## Installation

```bash
npm install @google/genai
```

## Authentication

Set your API key as an environment variable:

```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

The client reads the key automatically from these environment variables.

## Quick Reference

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

// Generate video
let operation = await ai.models.generateVideos({
  model: "veo-3.1-generate-preview",
  prompt: "A cinematic shot of ocean waves at sunset.",
});

// Poll until done
while (!operation.done) {
  await new Promise((resolve) => setTimeout(resolve, 10000));
  operation = await ai.operations.getVideosOperation({ operation });
}

// Download result
await ai.files.download({
  file: operation.response!.generatedVideos![0].video!,
  downloadPath: "output.mp4",
});
```

## Configuration Parameters

| Parameter | Type | Values | Notes |
|-----------|------|--------|-------|
| `aspectRatio` | `string` | `"16:9"`, `"9:16"` | Defaults to `"16:9"` |
| `resolution` | `string` | `"720p"`, `"1080p"`, `"4k"` | `1080p`/`4k` require `durationSeconds: "8"` |
| `negativePrompt` | `string` | Free text | Describe elements to exclude |
| `numberOfVideos` | `number` | `1` | Currently limited to 1 per request |
| `durationSeconds` | `string` | `"4"`, `"6"`, `"8"` | Must be `"8"` for HD/4K |
| `personGeneration` | `string` | `"allow_all"`, `"allow_adult"` | Region-dependent availability |

---

## 1. Basic Text-to-Video

The simplest generation: provide a prompt and model name.

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function generateBasicVideo(): Promise<void> {
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "A close-up of two people staring at a cryptic drawing on a wall, " +
      "torchlight flickering. A man murmurs, 'This must be it. " +
      "That is the secret code.' The woman looks at him and whispers " +
      "excitedly, 'What did you find?'",
  });

  while (!operation.done) {
    console.log("Waiting for video generation...");
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  const video = operation.response!.generatedVideos![0];
  await ai.files.download({
    file: video.video!,
    downloadPath: "basic_output.mp4",
  });
  console.log("Video saved to basic_output.mp4");
}

generateBasicVideo();
```

## 2. High-Resolution with Negative Prompt

Generate at 1080p or 4K. Higher resolutions require `durationSeconds: "8"`.

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function generateHighResVideo(): Promise<void> {
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "A stunning drone view of the Grand Canyon during a flamboyant sunset " +
      "that highlights the canyon's colors. The drone slowly flies towards " +
      "the sun then accelerates, dives and flies inside the canyon.",
    config: {
      aspectRatio: "16:9",
      resolution: "4k",
      durationSeconds: "8",
      negativePrompt: "cartoon, drawing, low quality, blurry, watermark",
    },
  });

  while (!operation.done) {
    console.log("Generating 4K video...");
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "canyon_4k.mp4",
  });
  console.log("4K video saved to canyon_4k.mp4");
}

generateHighResVideo();
```

## 3. Portrait Video (9:16)

Use `aspectRatio: "9:16"` for vertical video suitable for mobile, stories, or reels.

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function generatePortraitVideo(): Promise<void> {
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "A montage of pizza making: a chef tossing and flattening the floury " +
      "dough, ladling rich red tomato sauce in a spiral, sprinkling " +
      "mozzarella cheese and pepperoni, and a final shot of the bubbling " +
      "golden-brown pizza. Upbeat electronic music with a rhythmical beat " +
      "is playing. High energy professional video.",
    config: {
      aspectRatio: "9:16",
    },
  });

  while (!operation.done) {
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "portrait_pizza.mp4",
  });
  console.log("Portrait video saved to portrait_pizza.mp4");
}

generatePortraitVideo();
```

## 4. Video Extension

Extend an existing video by providing a `video` parameter. The model generates a continuation based on the final second of the input video to maintain visual continuity.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "fs";

const ai = new GoogleGenAI({});

async function extendVideo(): Promise<void> {
  // Load the source video as bytes
  const videoBytes = fs.readFileSync("butterfly_garden.mp4");

  const sourceVideo = {
    videoBytes: videoBytes.toString("base64"),
    mimeType: "video/mp4",
  };

  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    video: sourceVideo,
    prompt:
      "Track the butterfly into the garden as it lands on an orange " +
      "origami flower. A fluffy white puppy runs up and gently pats " +
      "the flower.",
    config: {
      numberOfVideos: 1,
      resolution: "720p",
    },
  });

  while (!operation.done) {
    console.log("Extending video...");
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "extended_butterfly.mp4",
  });
  console.log("Extended video saved to extended_butterfly.mp4");
}

extendVideo();
```

## 5. Frame-Specific Generation

### First Frame Only (Image-to-Video)

Provide an image as the starting frame. The model animates from that image.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "fs";

const ai = new GoogleGenAI({});

async function generateFromFirstFrame(): Promise<void> {
  const imageBytes = fs.readFileSync("starting_frame.png");

  const firstImage = {
    imageBytes: imageBytes.toString("base64"),
    mimeType: "image/png",
  };

  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "Panning wide shot of a calico kitten sleeping in the sunshine. " +
      "The kitten slowly opens its eyes, stretches, and yawns.",
    image: firstImage,
  });

  while (!operation.done) {
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "kitten_wakeup.mp4",
  });
  console.log("Video from first frame saved to kitten_wakeup.mp4");
}

generateFromFirstFrame();
```

You can also generate the first frame with an image model:

```typescript
const imageResponse = await ai.models.generateContent({
  model: "gemini-2.5-flash-image",
  prompt: "Panning wide shot of a calico kitten sleeping in the sunshine",
});

let operation = await ai.models.generateVideos({
  model: "veo-3.1-generate-preview",
  prompt: "Panning wide shot of a calico kitten sleeping in the sunshine",
  image: {
    imageBytes: imageResponse.generatedImages![0].image!.imageBytes!,
    mimeType: "image/png",
  },
});
```

### First and Last Frame Interpolation

Provide both a starting and ending frame. The model generates a video that transitions between them.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "fs";

const ai = new GoogleGenAI({});

async function generateFromFrames(): Promise<void> {
  const firstBytes = fs.readFileSync("frame_start.png");
  const lastBytes = fs.readFileSync("frame_end.png");

  const firstImage = {
    imageBytes: firstBytes.toString("base64"),
    mimeType: "image/png",
  };

  const lastImage = {
    imageBytes: lastBytes.toString("base64"),
    mimeType: "image/png",
  };

  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "A cinematic, haunting video. A ghostly woman with long white hair " +
      "and a flowing dress swings gently on a rope swing hanging from an " +
      "ancient oak tree. Mist swirls around the ground.",
    image: firstImage,
    config: {
      lastFrame: lastImage,
    },
  });

  while (!operation.done) {
    console.log("Interpolating between frames...");
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "frame_interpolation.mp4",
  });
  console.log("Interpolated video saved to frame_interpolation.mp4");
}

generateFromFrames();
```

## 6. Reference Images (Up to 3)

Provide up to 3 reference images to guide the video's visual style, character appearance, or asset details. Each reference has a `referenceType` of `"asset"`.

```typescript
import { GoogleGenAI } from "@google/genai";
import * as fs from "fs";

const ai = new GoogleGenAI({});

async function generateWithReferenceImages(): Promise<void> {
  const dressBytes = fs.readFileSync("red_dress.png");
  const glassesBytes = fs.readFileSync("sunglasses.png");
  const personBytes = fs.readFileSync("woman_portrait.png");

  const dressReference = {
    image: {
      imageBytes: dressBytes.toString("base64"),
      mimeType: "image/png",
    },
    referenceType: "asset" as const,
  };

  const sunglassesReference = {
    image: {
      imageBytes: glassesBytes.toString("base64"),
      mimeType: "image/png",
    },
    referenceType: "asset" as const,
  };

  const womanReference = {
    image: {
      imageBytes: personBytes.toString("base64"),
      mimeType: "image/png",
    },
    referenceType: "asset" as const,
  };

  let operation = await ai.models.generateVideos({
    model: "veo-3.1-generate-preview",
    prompt:
      "The video opens with a medium, eye-level shot of a beautiful woman " +
      "with dark hair wearing the red dress and sunglasses from the " +
      "reference images. She walks confidently down a sunlit city street. " +
      "Cinematic color grading, shallow depth of field.",
    config: {
      referenceImages: [dressReference, sunglassesReference, womanReference],
    },
  });

  while (!operation.done) {
    console.log("Generating video with reference images...");
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "reference_output.mp4",
  });
  console.log("Reference-based video saved to reference_output.mp4");
}

generateWithReferenceImages();
```

## 7. Fast Generation for Iteration

Use the fast model for quicker turnaround when iterating on prompts or prototyping.

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function generateFastVideo(): Promise<void> {
  let operation = await ai.models.generateVideos({
    model: "veo-3.1-fast-generate-preview",
    prompt:
      "A time-lapse of a flower blooming in a garden, morning light " +
      "streaming through the petals. Soft ambient music.",
    config: {
      aspectRatio: "16:9",
    },
  });

  while (!operation.done) {
    await new Promise((resolve) => setTimeout(resolve, 10000));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  await ai.files.download({
    file: operation.response!.generatedVideos![0].video!,
    downloadPath: "fast_flower.mp4",
  });
  console.log("Fast video saved to fast_flower.mp4");
}

generateFastVideo();
```

**Workflow tip:** Use `veo-3.1-fast-generate-preview` to test prompt ideas, then switch to `veo-3.1-generate-preview` for the final high-quality render.

## 8. Reusable Helper Function

Extract the polling and download logic into a helper for cleaner code:

```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});

async function generateAndDownload(
  params: Parameters<typeof ai.models.generateVideos>[0],
  outputPath: string,
  pollIntervalMs: number = 10000
): Promise<void> {
  let operation = await ai.models.generateVideos(params);

  while (!operation.done) {
    console.log(`Polling... (waiting ${pollIntervalMs / 1000}s)`);
    await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
    operation = await ai.operations.getVideosOperation({ operation });
  }

  const videos = operation.response?.generatedVideos;
  if (!videos || videos.length === 0) {
    throw new Error("No videos were generated.");
  }

  await ai.files.download({
    file: videos[0].video!,
    downloadPath: outputPath,
  });
  console.log(`Video saved to ${outputPath}`);
}

// Usage
await generateAndDownload(
  {
    model: "veo-3.1-generate-preview",
    prompt: "A serene lake at dawn with mist rising from the water.",
    config: {
      aspectRatio: "16:9",
      resolution: "1080p",
      durationSeconds: "8",
      negativePrompt: "text, watermark, low quality",
    },
  },
  "lake_dawn.mp4"
);
```

---

## Prompt Engineering Tips

**Be specific about camera work:** Use terms like "close-up", "wide shot", "tracking shot", "drone view", "dolly zoom", "panning shot", "eye-level", "low angle". The model responds well to cinematography language.

**Describe audio explicitly (Veo 3.1):** The model generates native audio. Include audio descriptions in your prompt: "upbeat electronic music", "soft ambient sounds", "birds chirping in the background", dialogue in quotes.

**Include dialogue in quotes:** For Veo 3.1, place spoken words in quotes within the prompt. Example: `A man says, 'Look at this view.'`

**Layer visual details:** Describe lighting ("golden hour", "harsh overhead light"), color grading ("warm tones", "desaturated"), and atmosphere ("misty", "rain-soaked streets").

**Use negative prompts for quality control:** Common negative prompt terms: `"cartoon, drawing, low quality, blurry, watermark, text overlay, distorted faces, extra limbs"`.

**Keep prompts focused:** One clear scene or action per generation works better than cramming multiple unrelated actions. For complex sequences, generate multiple clips and stitch them together.

**Describe motion and pacing:** "Slow motion water droplet", "fast-paced montage", "the camera slowly orbits the subject". Motion descriptions directly influence the generated video.

---

## Common Pitfalls

**Forgetting to poll the operation.** `generateVideos` returns an async operation, not a completed video. You must poll with `ai.operations.getVideosOperation()` until `operation.done` is `true`.

**Using wrong resolution/duration combinations.** Resolutions `"1080p"` and `"4k"` require `durationSeconds: "8"`. Requesting 4K with a 4-second duration will fail.

**Not handling the nullable response.** The operation response and its nested properties can be null/undefined. Always use non-null assertions (`!`) or proper null checks when accessing `operation.response.generatedVideos[0].video`.

**Polling too frequently.** Video generation takes 1-3 minutes typically. Polling every 1 second wastes API calls. Use 10-second intervals (10000ms) as shown in the examples.

**Snake_case instead of camelCase.** The TypeScript SDK uses camelCase property names: `aspectRatio`, `negativePrompt`, `durationSeconds`, `numberOfVideos`, `personGeneration`, `referenceImages`, `lastFrame`, `downloadPath`. Do not use Python-style `snake_case`.

**Confusing `image` with `video` parameters.** Use `image` for first-frame image-to-video generation. Use `video` for extending an existing video clip. These are separate top-level parameters, not interchangeable.

**Exceeding reference image limit.** You can provide a maximum of 3 reference images in `config.referenceImages`. More than 3 will cause an error.

**Using the fast model for final output.** `veo-3.1-fast-generate-preview` is limited to 720p and produces lower quality. Always switch to `veo-3.1-generate-preview` for production renders.

---

## Model Comparison

| Feature | `veo-3.1-generate-preview` | `veo-3.1-fast-generate-preview` | `veo-2.0-generate-001` |
|---------|----------------------------|----------------------------------|-------------------------|
| Max Resolution | 4K | 720p | 720p |
| Duration Options | 4s, 6s, 8s | 4s, 6s, 8s | 4s, 6s, 8s |
| Native Audio | Yes | Yes | No |
| Image-to-Video | Yes | Yes | Yes |
| Video Extension | Yes | Yes | No |
| First+Last Frame | Yes | Yes | No |
| Reference Images | Up to 3 | Up to 3 | No |
| Generation Speed | Slower (1-3 min) | Faster | Moderate |
| Best For | Final production output | Prompt iteration, prototyping | Legacy workflows |

## Related Skills

- `gemini-apis-overview` -- Overview of all Gemini API skills
- `using-veo-api-python` -- Veo video generation with Python SDK
- `using-nano-banana-typescript` -- Image generation with TypeScript SDK
