---
name: using-veo-api-python
description: Use when generating videos with Google Veo API using the Python google-genai SDK — text-to-video, video extension, frame-specific generation, reference images, portrait/landscape modes, resolution control, and prompt engineering.
---

# Veo Video Generation API (Python)

## Overview

Veo 3.1 generates high-fidelity 8-second videos with native audio at up to 4K resolution. It uses an asynchronous generation model where you submit a request and poll for completion. Generated videos are stored for 2 days only, so download them promptly.

## When to Use

- Generating videos from text prompts (text-to-video)
- Extending existing Veo-generated videos
- Creating videos with specific start and/or end frames (image-to-video)
- Using reference images to guide video style or subject
- Creating portrait (9:16) or landscape (16:9) videos
- Controlling resolution from 720p up to 4K

## When Not to Use

- Real-time audio/video streaming -- use the Live API (`using-gemini-live-api-python`)
- Image generation or editing -- use Nano Banana (`using-nano-banana-python`)
- Video understanding or analysis -- use `client.models.generate_content()` with video file input

## Quick Reference

| Property | Values |
|----------|--------|
| Models | `veo-3.1-generate-preview` (best quality), `veo-3.1-fast-generate-preview` (speed), `veo-2.0-generate-001` (stable, no audio) |
| Resolutions | `720p` (default), `1080p`, `4K` |
| Duration | `4`, `6`, or `8` seconds |
| Aspect ratios | `16:9` (landscape), `9:16` (portrait) |
| Frame rate | 24fps |
| Latency | 11 seconds minimum, up to 6 minutes during peak |
| Storage | Generated videos retained for 2 days only |
| Watermark | All videos include SynthID watermark |

## SDK Installation

```bash
pip install google-genai
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

### Basic Text-to-Video

```python
import time
from google import genai
from google.genai import types

client = genai.Client()

operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="A golden retriever running through a sunlit meadow, cinematic slow motion, shallow depth of field",
    config=types.GenerateVideosConfig(
        aspect_ratio="16:9",
        resolution="720p",
    ),
)

# Poll for completion
while not operation.done:
    time.sleep(10)
    operation = client.operations.get(operation)

# Download the video
video = operation.response.generated_videos[0]
client.files.download(file=video.video)
video.video.save("meadow.mp4")
print(f"Video saved. Duration: {video.video.duration}")
```

### High-Resolution Video with Negative Prompt

```python
operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="A chef preparing sushi in a traditional Japanese kitchen, warm lighting, close-up shots",
    config=types.GenerateVideosConfig(
        resolution="1080p",
        duration_seconds="8",
        negative_prompt="blurry, low quality, text overlay, watermark",
    ),
)
```

### Portrait Video (9:16)

```python
operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="A dancer performing contemporary dance in a studio, dramatic lighting",
    config=types.GenerateVideosConfig(
        aspect_ratio="9:16",
        resolution="1080p",
    ),
)
```

### Video Extension

Extend a previously generated Veo video with a new prompt. Extension is limited to 720p and the input video must be under 141 seconds. You can extend up to 20 times.

```python
# First generate a base video
base_op = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="A rocket launching from a pad, smoke billowing",
    config=types.GenerateVideosConfig(resolution="720p"),
)
while not base_op.done:
    time.sleep(10)
    base_op = client.operations.get(base_op)

base_video = base_op.response.generated_videos[0].video

# Extend the video
extend_op = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    video=base_video,
    prompt="The rocket soars through clouds into the upper atmosphere",
    config=types.GenerateVideosConfig(resolution="720p"),
)
while not extend_op.done:
    time.sleep(10)
    extend_op = client.operations.get(extend_op)

extended_video = extend_op.response.generated_videos[0]
client.files.download(file=extended_video.video)
extended_video.video.save("rocket_extended.mp4")
```

### Frame-Specific Generation (First Frame)

Use a starting image to anchor the first frame of the generated video.

```python
from google.genai import types
from PIL import Image
import io

# Load a starting frame
img = Image.open("start_frame.png")
buf = io.BytesIO()
img.save(buf, format="PNG")

first_frame = types.Image(image_bytes=buf.getvalue(), mime_type="image/png")

operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="The scene comes to life with gentle wind blowing through the trees",
    image=first_frame,
    config=types.GenerateVideosConfig(resolution="720p"),
)

while not operation.done:
    time.sleep(10)
    operation = client.operations.get(operation)
```

### Frame-Specific Generation (First and Last Frame)

Provide both a starting and ending frame. The model interpolates between them.

```python
operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="A smooth transition between the two scenes",
    image=first_frame,
    config=types.GenerateVideosConfig(
        last_frame=final_frame,
        resolution="720p",
    ),
)
```

### Reference Images (Up to 3)

Use reference images to guide the subject appearance or visual style of the generated video. Each reference image must specify a `reference_type` of either `"asset"` or `"style"`.

```python
references = [
    types.VideoGenerationReferenceImage(
        image=subject_image,
        reference_type="asset",
    ),
    types.VideoGenerationReferenceImage(
        image=style_image,
        reference_type="style",
    ),
]

operation = client.models.generate_videos(
    model="veo-3.1-generate-preview",
    prompt="The subject walks through a forest in the style of the reference",
    config=types.GenerateVideosConfig(
        reference_images=references,
        resolution="720p",
    ),
)
```

### Fast Generation for Iteration

Use the fast model to iterate quickly on prompts before committing to the higher-quality model.

```python
operation = client.models.generate_videos(
    model="veo-3.1-fast-generate-preview",
    prompt="A cat playing with a ball of yarn, close up, soft lighting",
    config=types.GenerateVideosConfig(
        resolution="720p",
        duration_seconds="4",
    ),
)
```

### Polling Helper

For production code, wrap the polling logic in a reusable function.

```python
import time
from google import genai
from google.genai import types


def generate_video_sync(
    client: genai.Client,
    model: str,
    prompt: str,
    config: types.GenerateVideosConfig,
    poll_interval: int = 10,
    **kwargs,
) -> types.GeneratedVideo:
    """Generate a video and block until completion."""
    operation = client.models.generate_videos(
        model=model,
        prompt=prompt,
        config=config,
        **kwargs,
    )

    while not operation.done:
        time.sleep(poll_interval)
        operation = client.operations.get(operation)

    return operation.response.generated_videos[0]


# Usage
client = genai.Client()
result = generate_video_sync(
    client=client,
    model="veo-3.1-generate-preview",
    prompt="A timelapse of a city skyline from sunset to night, 4K cinematic",
    config=types.GenerateVideosConfig(resolution="1080p", duration_seconds="8"),
)
client.files.download(file=result.video)
result.video.save("skyline.mp4")
```

## Prompt Engineering Tips

- Structure prompts with five components: **subject** (what), **action** (movement), **style** (aesthetic), **camera work** (angles/motion), **ambiance** (lighting/color)
- Use cinematic terms: "dolly shot", "tracking shot", "crane shot", "shallow depth of field", "rack focus"
- Specify dialogue in quotation marks for native audio generation (Veo 3.1 only)
- Use negative prompts to exclude unwanted elements like "blurry, low quality, text overlay, distorted faces"
- Be specific about motion: "slowly panning left" is better than "camera moves"
- Describe lighting explicitly: "golden hour backlighting" produces more consistent results than "nice lighting"

## Common Pitfalls

- **2-day storage limit** -- Generated videos are deleted after 2 days. Always download with `client.files.download()` and `video.save()` immediately after generation completes.
- **Extension restrictions** -- Video extension only works on Veo-generated videos, not uploaded videos. Extension is limited to 720p. Input must be under 141 seconds. Maximum 20 extensions per chain.
- **Resolution and cost** -- Higher resolution means higher cost and longer generation time. Use 720p for iteration, then re-generate at higher resolution for final output.
- **Async generation** -- Generation is always asynchronous. You must poll `operation.done` in a loop. Do not assume the video is ready immediately after the API call returns.
- **Fast model limitations** -- `veo-3.1-fast-generate-preview` does not support video extension and caps at 1080p.
- **Veo 2 has no audio** -- Only Veo 3.1 and 3.1 Fast generate native audio. Veo 2 produces silent video.
- **Duration as string** -- The `duration_seconds` config value is a string (`"4"`, `"6"`, `"8"`), not an integer.

## Model Comparison

| Feature | Veo 3.1 | Veo 3.1 Fast | Veo 2 |
|---------|---------|--------------|-------|
| Audio | Native | Native | Silent |
| Max resolution | 4K | 1080p | 720p |
| Duration | 4/6/8s | 4/6/8s | 5-8s |
| Extension | Yes | No | No |
| Speed | Slower | Faster | Moderate |
| Reference images | Yes | Yes | No |
| Frame control | Yes | Yes | No |

## Related Skills

- `gemini-apis-overview` -- Overview of all Gemini API skills
- `using-veo-api-typescript` -- Veo video generation with TypeScript
- `using-gemini-live-api-python` -- Live API for real-time streaming
- `using-nano-banana-python` -- Image generation with Python
