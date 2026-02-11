---
name: using-gemini-live-api-python
description: Use when building real-time audio/video streaming applications with the Gemini Live API using the Python google-genai SDK — WebSocket sessions, audio streaming, video input, voice activity detection, native audio, tool use, or session management.
---

# Gemini Live API -- Python SDK

## Overview

The Gemini Live API enables low-latency bidirectional streaming over WebSockets for real-time voice and video interactions. It supports continuous audio input and output, video frame streaming, voice activity detection (VAD), function calling, and native audio features like affective dialog and proactive responses. All communication happens through a persistent WebSocket session managed by the `google-genai` Python SDK.

## When to Use

- Real-time voice conversations with AI
- Streaming video or screen sharing for visual understanding
- Building voice assistants with function calling
- Audio-only or audio+video interactive sessions
- Applications requiring low-latency, bidirectional audio streaming

## When Not to Use

- One-shot text generation -- use standard `generateContent` instead
- Image generation -- use Nano Banana (Gemini image generation)
- Video generation -- use the Veo API
- Batch audio transcription -- use the standard audio input to `generateContent`

## Quick Reference

| Property | Value |
|---|---|
| Model | `gemini-2.5-flash-native-audio-preview-12-2025` |
| Audio input format | 16-bit PCM, little-endian, 16kHz, mono |
| Audio output sample rate | 24kHz |
| Session limit (audio-only) | 15 minutes |
| Session limit (audio+video) | 2 minutes |
| Context window (native audio) | 128k tokens |
| Context window (other) | 32k tokens |
| Response modalities | ONE of `TEXT` or `AUDIO` per session (not both) |

## Setup

```bash
pip install google-genai
```

Set your API key:

```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

## Examples

### Basic text-to-audio session

Send text input and receive audio output.

```python
from google import genai
from google.genai import types

client = genai.Client()

config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    system_instruction="You are a helpful assistant.",
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    await session.send_client_content(
        turns=types.Content(role="user", parts=[types.Part(text="Hello!")]),
        turn_complete=True,
    )
    async for response in session.receive():
        if response.data:
            # PCM audio bytes at 24kHz
            audio_data = response.data
```

### Basic text-to-text session

Send and receive text instead of audio.

```python
config = types.LiveConnectConfig(
    response_modalities=["TEXT"],
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    await session.send_client_content(
        turns=types.Content(role="user", parts=[types.Part(text="What is the capital of France?")]),
        turn_complete=True,
    )
    async for response in session.receive():
        if response.text:
            print(response.text, end="")
```

### Streaming microphone audio

Stream audio from a microphone and play back the response.

```python
import asyncio
from google import genai
from google.genai import types

client = genai.Client()

config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Puck")
        )
    ),
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    # Send audio chunks as they arrive from the microphone
    audio_chunk = get_audio_from_mic()  # 16-bit PCM, 16kHz, mono
    await session.send_realtime_input(
        audio=types.Blob(data=audio_chunk, mime_type="audio/pcm;rate=16000")
    )

    async for response in session.receive():
        if response.data:
            play_audio(response.data)
```

### Full duplex audio streaming

Run audio input and output concurrently using separate tasks.

```python
import asyncio
from google import genai
from google.genai import types

client = genai.Client()

config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Aoede")
        )
    ),
)


async def send_audio(session):
    """Continuously capture and send microphone audio."""
    while True:
        audio_chunk = await get_audio_from_mic_async()
        if audio_chunk is None:
            break
        await session.send_realtime_input(
            audio=types.Blob(data=audio_chunk, mime_type="audio/pcm;rate=16000")
        )


async def receive_audio(session):
    """Continuously receive and play back model audio."""
    async for response in session.receive():
        if response.data:
            await play_audio_async(response.data)
        if response.server_content and response.server_content.interrupted:
            stop_audio_playback()


async def main():
    async with client.aio.live.connect(
        model="gemini-2.5-flash-native-audio-preview-12-2025",
        config=config,
    ) as session:
        send_task = asyncio.create_task(send_audio(session))
        receive_task = asyncio.create_task(receive_audio(session))
        await asyncio.gather(send_task, receive_task)


asyncio.run(main())
```

### Streaming video input

Send video frames alongside audio for visual understanding.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    media_resolution=types.MediaResolution.MEDIA_RESOLUTION_LOW,
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    # Send a video frame (JPEG-encoded bytes)
    await session.send_realtime_input(
        video=types.Blob(data=frame_bytes, mime_type="image/jpeg")
    )

    # Ask about what the model sees
    await session.send_client_content(
        turns=types.Content(role="user", parts=[types.Part(text="What do you see?")]),
        turn_complete=True,
    )

    async for response in session.receive():
        if response.data:
            audio_data = response.data
```

Video frames should be JPEG or PNG. Use `MEDIA_RESOLUTION_LOW` to reduce token usage. Audio+video sessions are limited to 2 minutes.

### Voice Activity Detection (VAD) configuration

Automatic VAD detects when the user starts and stops speaking. Configure sensitivity and timing thresholds.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    realtime_input_config=types.RealtimeInputConfig(
        automatic_activity_detection=types.AutomaticActivityDetection(
            disabled=False,
            start_of_speech_sensitivity=types.StartSensitivity.START_SENSITIVITY_HIGH,
            end_of_speech_sensitivity=types.EndSensitivity.END_SENSITIVITY_HIGH,
            prefix_padding_ms=200,
            silence_duration_ms=600,
        )
    ),
)
```

- `start_of_speech_sensitivity` -- how quickly speech onset is detected. `HIGH` triggers faster, `LOW` requires more confident speech.
- `end_of_speech_sensitivity` -- how quickly silence is treated as end of turn. `HIGH` ends sooner, `LOW` waits longer.
- `prefix_padding_ms` -- milliseconds of audio to include before detected speech onset.
- `silence_duration_ms` -- milliseconds of silence before the turn is considered complete.

### Manual VAD

Disable automatic detection and explicitly signal speech activity boundaries.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    realtime_input_config=types.RealtimeInputConfig(
        automatic_activity_detection=types.AutomaticActivityDetection(disabled=True)
    ),
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    # Signal start of speech
    await session.send_realtime_input(activity_start=types.ActivityStart())

    # Send audio data
    await session.send_realtime_input(
        audio=types.Blob(data=audio_chunk, mime_type="audio/pcm;rate=16000")
    )

    # Signal end of speech
    await session.send_realtime_input(activity_end=types.ActivityEnd())

    async for response in session.receive():
        if response.data:
            play_audio(response.data)
```

### Function calling / tool use

Define functions that the model can invoke during a live session.

```python
from google import genai
from google.genai import types

client = genai.Client()

turn_on_lights = types.FunctionDeclaration(
    name="turn_on_lights",
    description="Turn on the lights in a room",
    parameters=types.Schema(
        type="OBJECT",
        properties={
            "room": types.Schema(type="STRING", description="The name of the room"),
        },
        required=["room"],
    ),
)

config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    tools=[types.Tool(function_declarations=[turn_on_lights])],
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    await session.send_client_content(
        turns=types.Content(
            role="user",
            parts=[types.Part(text="Turn on the kitchen lights")],
        ),
        turn_complete=True,
    )

    async for response in session.receive():
        if response.tool_call:
            for fc in response.tool_call.function_calls:
                result = handle_function_call(fc.name, fc.args)
                await session.send_tool_response(
                    function_responses=[
                        types.FunctionResponse(
                            name=fc.name,
                            response={"result": result},
                        )
                    ]
                )
```

### Native audio features

These features are available with the native audio model.

#### Affective dialog

The model responds with emotional awareness, matching tone and mood.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    enable_affective_dialog=True,
)
```

#### Proactive audio

The model decides when to speak without waiting for explicit user input.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    proactivity=types.ProactivityConfig(proactive_audio=True),
)
```

#### Thinking (chain-of-thought reasoning)

Enable internal reasoning before the model responds.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    thinking_config=types.ThinkingConfig(thinking_budget=1024),
    include_thoughts=True,
)

async for response in session.receive():
    if response.server_content:
        if response.server_content.model_turn:
            for part in response.server_content.model_turn.parts:
                if part.thought:
                    print("Thinking:", part.text)
```

### Audio transcription

Get text transcriptions of both input and output audio.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    output_audio_transcription=types.AudioTranscriptionConfig(),
    input_audio_transcription=types.AudioTranscriptionConfig(),
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    # ... send audio ...

    async for response in session.receive():
        if response.server_content:
            if response.server_content.output_audio_transcription:
                print("Model:", response.server_content.output_audio_transcription.text)
            if response.server_content.input_audio_transcription:
                print("User:", response.server_content.input_audio_transcription.text)
        if response.data:
            play_audio(response.data)
```

### Handling interruptions

When the user speaks while the model is responding, the model is interrupted.

```python
async for response in session.receive():
    if response.server_content and response.server_content.interrupted:
        # User interrupted -- stop playing the current audio buffer
        stop_audio_playback()
    if response.data:
        enqueue_audio(response.data)
```

### Session resume

Resume a disconnected session using a session handle.

```python
# On initial connection, capture the session handle
session_handle = None

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=config,
) as session:
    async for response in session.receive():
        if response.session_resumption_update:
            if response.session_resumption_update.resumable:
                session_handle = response.session_resumption_update.new_handle

# To resume, pass the handle in the config
resume_config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    session_resumption=types.SessionResumptionConfig(handle=session_handle),
)

async with client.aio.live.connect(
    model="gemini-2.5-flash-native-audio-preview-12-2025",
    config=resume_config,
) as resumed_session:
    # Session continues with previous context
    pass
```

### Context window management

Provide pre-existing conversation context when connecting.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    context_window_compression=types.ContextWindowCompressionConfig(
        trigger_tokens=10000,
        sliding_window=types.SlidingWindow(target_tokens=5000),
    ),
)
```

This enables automatic compression when the context reaches `trigger_tokens`, keeping approximately `target_tokens` of the most recent content.

### Token usage monitoring

Track token consumption during a session.

```python
async for response in session.receive():
    if response.usage_metadata:
        print(f"Total tokens: {response.usage_metadata.total_token_count}")
        print(f"Input tokens: {response.usage_metadata.prompt_token_count}")
        print(f"Output tokens: {response.usage_metadata.candidates_token_count}")
```

### Ephemeral tokens for client-side use

For browser or client-side applications, create short-lived tokens to avoid exposing your API key.

```python
# Server-side: create an ephemeral token
client = genai.Client()
token_response = client.auth_tokens.create(
    config=types.CreateAuthTokenConfig(
        uses=1,  # single-use
        expire_time="2025-01-01T00:00:00Z",
        http_options=types.HttpOptions(api_version="v1alpha"),
    )
)
ephemeral_token = token_response.name

# Client-side: use the ephemeral token
client = genai.Client(api_key=ephemeral_token)
async with client.aio.live.connect(model=MODEL, config=config) as session:
    pass
```

## Available Voices

Set the voice via `speech_config.voice_config.prebuilt_voice_config.voice_name` in the `LiveConnectConfig`.

Built-in voices: Puck, Charon, Kore, Fenrir, Aoede, Leda, Orus, Zephyr, and additional HD voices (30 total).

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name="Kore")
        )
    ),
)
```

## Language selection

Specify the language for both input and output audio.

```python
config = types.LiveConnectConfig(
    response_modalities=["AUDIO"],
    speech_config=types.SpeechConfig(
        language_code="es-ES",
    ),
)
```

## Common Pitfalls

- **One modality per session.** You must choose either `TEXT` or `AUDIO` as the response modality. You cannot have both in the same session.
- **Audio+video time limit.** Sessions with video input are limited to 2 minutes. Audio-only sessions last up to 15 minutes.
- **Audio format requirements.** Input audio must be 16-bit PCM, little-endian, 16kHz, mono. Sending other formats produces errors or garbled output.
- **VAD interruptions cancel pending function calls.** If the user speaks while the model is about to call a function, the function call may be cancelled.
- **Ephemeral tokens for client-side.** Never expose your API key in browser code. Use ephemeral tokens created server-side.
- **Session not resumable immediately.** Wait until you receive a `session_resumption_update` with `resumable=True` before relying on the handle.
- **send_client_content vs send_realtime_input.** Use `send_client_content` for structured turns (text or pre-recorded audio). Use `send_realtime_input` for streaming real-time audio/video from a live source.
- **Receive loop required.** You must iterate over `session.receive()` to get responses. The session does not push responses without an active receive loop.

## API Method Reference

| Method | Purpose |
|---|---|
| `client.aio.live.connect(model, config)` | Open a WebSocket session (async context manager) |
| `session.send_client_content(turns, turn_complete)` | Send structured content (text or pre-recorded audio) |
| `session.send_realtime_input(audio, video, activity_start, activity_end)` | Stream real-time audio/video or signal VAD boundaries |
| `session.send_tool_response(function_responses)` | Return function call results to the model |
| `session.receive()` | Async iterator yielding server responses |
