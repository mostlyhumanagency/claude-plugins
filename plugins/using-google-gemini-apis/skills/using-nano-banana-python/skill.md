---
name: using-nano-banana-python
description: Use when generating or editing images with Google Nano Banana (Gemini image models) using the Python google-genai SDK — text-to-image, image editing, text rendering, multi-turn editing, reference images, high-resolution output, and Google Search grounding.
---

# Nano Banana Image Generation (Python SDK)

## Overview

Nano Banana is Gemini's native image generation capability, available through the `google-genai` Python SDK. It supports generating images from text, editing existing images, rendering text within images, iterative multi-turn refinement, and using reference images for visual consistency.

Two models are available:

- **Standard** (`gemini-2.5-flash-image`): Optimized for speed and cost efficiency. Best for rapid prototyping, batch workflows, and general-purpose image generation.
- **Pro** (`gemini-3-pro-image-preview`): Professional-quality output with advanced reasoning (Thinking enabled by default). Supports high-resolution output up to 4K, superior text rendering, reference image consistency, and Google Search grounding.

## When to Use

- Generating images from text descriptions (illustrations, product shots, concept art)
- Editing existing images (add, remove, or modify elements)
- Rendering legible text in images (logos, posters, signs, infographics)
- Multi-turn iterative image refinement via chat sessions
- Using reference images for character or object consistency across outputs
- Generating images informed by real-time data via Google Search grounding (Pro only)

## When Not to Use

- **Video generation**: Use the Veo API instead.
- **Real-time streaming**: Use the Live API instead.
- **Image understanding or analysis without generation**: Use standard Gemini `generateContent` with vision capabilities (no need for image generation models).
- **Batch processing with strict latency requirements**: The Batch API trades latency (up to 24 hours) for higher throughput.

## Quick Reference

| Property | Standard (Flash) | Pro |
|---|---|---|
| Model ID | `gemini-2.5-flash-image` | `gemini-3-pro-image-preview` |
| Speed | Fast | Slower (includes reasoning) |
| Max resolution | 1K | 4K |
| Text rendering | Basic | Professional |
| Reference images | Limited | Up to 6 objects + 5 humans |
| Search grounding | No | Yes |
| Approximate cost | ~$0.02/image | ~$0.10/image |
| Thinking | No | Yes (default on) |

**Supported resolutions**: 1K, 2K, 4K (2K and 4K require Pro model)

**Supported aspect ratios**: `1:1`, `16:9`, `9:16`, `4:3`, `3:4`, `21:9`

All generated images include a SynthID digital watermark.

## Installation

```bash
pip install google-genai Pillow
```

Set your API key as an environment variable:

```bash
export GOOGLE_API_KEY="your-api-key"
```

Or pass it directly when creating the client:

```python
client = genai.Client(api_key="your-api-key")
```

## Examples

### Basic Text-to-Image

```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="A serene Japanese garden with a koi pond, watercolor style",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        image = part.as_image()
        image.save("garden.png")
    elif part.text:
        print(part.text)
```

### Image Editing (Text + Image Input)

Load an existing image and provide editing instructions alongside it:

```python
from PIL import Image
import io

from google import genai
from google.genai import types

client = genai.Client()

# Load the source image
img = Image.open("photo.jpg")
buf = io.BytesIO()
img.save(buf, format="JPEG")

image_part = types.Part.from_bytes(data=buf.getvalue(), mime_type="image/jpeg")

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=[
        "Change the sky to a dramatic sunset with orange and purple hues",
        image_part,
    ],
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("edited_photo.png")
    elif part.text:
        print(part.text)
```

### High-Resolution Output (Pro Model)

Use `image_config` to control aspect ratio and resolution. The `image_size` parameter accepts `"1K"`, `"2K"`, or `"4K"` (Pro model only for 2K and 4K).

```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents="A professional product photo of a luxury watch on black marble, studio lighting",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        image_config=types.ImageConfig(
            aspect_ratio="1:1",
            image_size="4K",
        ),
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("watch_4k.png")
    elif part.text:
        print(part.text)
```

### Text Rendering in Images

The Pro model produces significantly better text rendering. Place the desired text in quotes within your prompt and specify a font style or typographic treatment.

```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=(
        'A vintage movie poster with the title "MIDNIGHT VOYAGE" in bold art deco '
        "typography, dark blue and gold color scheme, dramatic spotlight lighting"
    ),
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("poster.png")
    elif part.text:
        print(part.text)
```

### Multi-Turn Editing (Chat)

Use chat sessions for iterative refinement. The model maintains context across turns, allowing you to build on previous outputs.

```python
from google import genai
from google.genai import types

client = genai.Client()

chat = client.chats.create(
    model="gemini-3-pro-image-preview",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

# First turn: generate the base image
response1 = chat.send_message("Draw a cartoon cat sitting on a windowsill")
for part in response1.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("cat_v1.png")

# Second turn: add to the scene
response2 = chat.send_message("Add a rainy scene outside the window")
for part in response2.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("cat_v2.png")

# Third turn: further refinement
response3 = chat.send_message("Make the cat wear a tiny scarf")
for part in response3.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("cat_v3.png")
```

### Reference Images for Consistency

Provide one or more reference images to maintain visual consistency for a character or object across different scenes. The Pro model supports up to 6 object reference images and 5 human reference images.

```python
from google import genai
from google.genai import types

client = genai.Client()

# Load the reference image
with open("character_ref.png", "rb") as f:
    ref_bytes = f.read()

ref_image = types.Part.from_bytes(data=ref_bytes, mime_type="image/png")

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[
        "Generate a new image of this character in a different pose, standing on a mountain peak at sunrise",
        ref_image,
    ],
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("character_mountain.png")
    elif part.text:
        print(part.text)
```

### Multiple Reference Images

```python
from google import genai
from google.genai import types

client = genai.Client()

def load_image(path: str, mime_type: str = "image/png") -> types.Part:
    with open(path, "rb") as f:
        return types.Part.from_bytes(data=f.read(), mime_type=mime_type)

ref_character = load_image("character.png")
ref_outfit = load_image("outfit_reference.png")
ref_background = load_image("environment.png")

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[
        "Place this character wearing the outfit from the second image in the environment shown in the third image",
        ref_character,
        ref_outfit,
        ref_background,
    ],
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("composite_scene.png")
```

### Google Search Grounding (Real-Time Information)

Pro model can ground image generation in real-time data from Google Search. Useful for infographics, data visualizations, or images that depend on current information.

```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents="Generate an infographic showing today's weather forecast for San Francisco",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        tools=[types.Tool(google_search=types.GoogleSearch())],
    ),
)

for part in response.candidates[0].content.parts:
    if part.inline_data:
        part.as_image().save("weather_infographic.png")
    elif part.text:
        print(part.text)
```

### Extracting and Saving Multiple Images

A single response can contain multiple images. Always iterate over all parts.

```python
from google import genai
from google.genai import types
from pathlib import Path

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="Create a set of four seasonal landscape illustrations: spring, summer, autumn, winter",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

output_dir = Path("seasonal_landscapes")
output_dir.mkdir(exist_ok=True)

image_count = 0
for part in response.candidates[0].content.parts:
    if part.inline_data:
        image = part.as_image()
        image.save(output_dir / f"season_{image_count}.png")
        image_count += 1
    elif part.text:
        print(part.text)

print(f"Saved {image_count} images to {output_dir}")
```

### Configuring Aspect Ratio

```python
from google import genai
from google.genai import types

client = genai.Client()

# Wide cinematic aspect ratio
response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="A panoramic cyberpunk cityscape at night, neon lights reflecting off wet streets",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        image_config=types.ImageConfig(
            aspect_ratio="21:9",
        ),
    ),
)

# Portrait aspect ratio (suitable for phone wallpapers)
response_portrait = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents="A tall redwood forest with sunbeams filtering through the canopy",
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
        image_config=types.ImageConfig(
            aspect_ratio="9:16",
        ),
    ),
)
```

## Prompt Engineering Tips

- **Narrative descriptions over keyword lists**: Write prompts as descriptive sentences rather than comma-separated tags. "A cozy cabin nestled in a snowy forest clearing, smoke rising from the chimney" works better than "cabin, snow, forest, chimney, smoke."
- **Photorealistic images**: Mention camera details such as lens type, aperture, and lighting conditions. For example: "Shot on 85mm lens, f/1.4 aperture, golden hour lighting, shallow depth of field."
- **Illustrations and art styles**: Specify the medium or art style explicitly. For example: "watercolor painting," "flat vector illustration," "16-bit pixel art," "oil painting in the style of impressionism."
- **Text in images**: Always use the Pro model for text rendering. Place the exact text in double quotes within the prompt. Specify the font style or typographic treatment (e.g., "bold sans-serif," "hand-lettered script," "art deco typography").
- **Product photography**: Include lighting setup ("studio softbox lighting," "rim light on dark background"), material descriptions ("brushed aluminum," "matte ceramic"), and camera angle ("45-degree overhead," "eye-level close-up").
- **Stickers and icons**: Explicitly request "transparent background" or "white background with clean edges" for assets intended for compositing.
- **Consistency across images**: Use reference images with the Pro model rather than relying on text descriptions alone for maintaining character or object consistency.

## Common Pitfalls

- **Missing `response_modalities`**: You must include `"IMAGE"` in `response_modalities` or the response will contain only text. This is the most common mistake.
- **Case sensitivity on `image_size`**: The values must be uppercase strings: `"1K"`, `"2K"`, `"4K"`. Lowercase values like `"1k"` will cause errors.
- **Using 2K/4K with the standard model**: Only the Pro model (`gemini-3-pro-image-preview`) supports `"2K"` and `"4K"` output. The standard model is limited to `"1K"`.
- **Pro model Thinking**: The Pro model has Thinking enabled by default. This means it performs internal reasoning before generating the image, which improves quality but increases latency. Be aware of this when comparing generation times between models.
- **Base64 encoded output**: Generated images are returned as base64-encoded data in `part.inline_data`. Use `part.as_image()` to get a PIL Image object for convenient saving and manipulation.
- **Safety filters**: Content safety filters may reject prompts that contain violent, explicit, or otherwise inappropriate content. If a prompt is rejected, rephrase it to be more appropriate.
- **Rate limits**: Default rate limits vary by model and API tier. For high-volume workloads, consider the Batch API which offers higher throughput with a 24-hour turnaround window.

## Model Comparison

| Feature | Nano Banana (Flash) | Nano Banana Pro |
|---|---|---|
| Model ID | `gemini-2.5-flash-image` | `gemini-3-pro-image-preview` |
| Speed | Fast | Slower (with reasoning) |
| Max resolution | 1K | 4K |
| Text rendering | Basic | Professional |
| Reference images | Limited | Up to 6 objects + 5 humans |
| Search grounding | No | Yes |
| Cost | ~$0.02/image | ~$0.10/image |
| Thinking | No | Yes (default) |
| Multi-turn editing | Yes | Yes |
| Image editing | Yes | Yes |
| Aspect ratios | All supported | All supported |
| SynthID watermark | Yes | Yes |

## Error Handling

```python
from google import genai
from google.genai import types

client = genai.Client()

try:
    response = client.models.generate_content(
        model="gemini-2.5-flash-image",
        contents="A mountain landscape at dawn",
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
        ),
    )

    if not response.candidates:
        print("No candidates returned. The prompt may have been filtered.")
    else:
        for part in response.candidates[0].content.parts:
            if part.inline_data:
                part.as_image().save("output.png")
            elif part.text:
                print(part.text)

except Exception as e:
    print(f"Image generation failed: {e}")
```
