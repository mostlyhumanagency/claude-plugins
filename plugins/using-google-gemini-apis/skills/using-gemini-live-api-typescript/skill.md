---
name: using-gemini-live-api-typescript
description: Use when building real-time audio/video streaming applications with the Gemini Live API using the @google/genai TypeScript SDK — WebSocket sessions, audio streaming, video input, voice activity detection, native audio, tool use, or session management.
---

# Gemini Live API -- TypeScript SDK

## Overview

The Gemini Live API provides low-latency, bidirectional streaming for real-time audio and video interactions over WebSockets. It supports continuous audio conversations, live video analysis, function calling, and native audio features like affective dialog and proactive responses. The TypeScript SDK (`@google/genai`) wraps the WebSocket protocol with a callback-based interface.

## When to Use

- Real-time voice conversations with a model
- Live audio processing and transcription
- Streaming video or camera frames for real-time analysis
- Interactive applications requiring low-latency responses
- Multimodal streaming (audio + video + text combined)

## When NOT to Use

- Simple text-in/text-out generation -- use the standard `generateContent` API instead
- Batch audio transcription -- use the standard API with audio file uploads
- One-shot image analysis -- use `generateContent` with inline images
- Non-interactive, offline processing tasks

## Quick Reference

| Property | Value |
|---|---|
| Native audio model | `gemini-2.5-flash-native-audio-preview-12-2025` |
| Non-native model | `gemini-live-2.5-flash-preview` |
| Audio input format | PCM 16-bit, 16kHz, mono |
| Audio output format | PCM 16-bit, 24kHz, mono |
| Audio-only session limit | 15 minutes |
| Audio + video session limit | 2 minutes |
| Context window (native audio) | 128k tokens |
| Context window (other Live models) | 32k tokens |
| SDK package | `@google/genai` |
| Install | `npm install @google/genai` |

## Installation and Setup

```bash
npm install @google/genai
```

Set your API key:

```bash
export GEMINI_API_KEY="your-key-here"
# or
export GOOGLE_API_KEY="your-key-here"
```

The client reads the key automatically from these environment variables:

```typescript
import { GoogleGenAI, Modality } from "@google/genai";

const ai = new GoogleGenAI({});
```

## Core Connection Pattern

Every Live API session follows the same callback-based structure. The `ai.live.connect()` method opens a WebSocket connection and returns a session object for sending data.

```typescript
import { GoogleGenAI, Modality } from "@google/genai";

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const config = {
  responseModalities: [Modality.AUDIO],
  systemInstruction: "You are a helpful assistant.",
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: function () {
        console.log("Connected");
      },
      onmessage: function (message: any) {
        responseQueue.push(message);
      },
      onerror: function (e: any) {
        console.error("Error:", e.message);
      },
      onclose: function (e: any) {
        console.log("Closed:", e.reason);
      },
    },
  });

  // Use the session...

  session.close();
}

main();
```

### Message Queue Helpers

Most examples in this document use these helper functions to process messages from the response queue:

```typescript
async function waitMessage(responseQueue: any[]): Promise<any> {
  let message: any;
  while (true) {
    message = responseQueue.shift();
    if (message) return message;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
}

async function handleTurn(responseQueue: any[]): Promise<any[]> {
  const turns: any[] = [];
  while (true) {
    const message = await waitMessage(responseQueue);
    turns.push(message);
    if (message.serverContent && message.serverContent.turnComplete) {
      break;
    }
    if (message.toolCall) {
      break;
    }
  }
  return turns;
}
```

## Examples

### Basic Text-to-Audio Session

Send text input and receive audio output:

```typescript
import { GoogleGenAI, Modality } from "@google/genai";
import * as fs from "node:fs";
import pkg from "wavefile";
const { WaveFile } = pkg;

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const config = {
  responseModalities: [Modality.AUDIO],
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: function () { console.log("Opened"); },
      onmessage: function (message: any) { responseQueue.push(message); },
      onerror: function (e: any) { console.error("Error:", e.message); },
      onclose: function (e: any) { console.log("Close:", e.reason); },
    },
  });

  // Send text and mark the turn as complete
  session.sendClientContent({
    turns: "Hello, how are you?",
    turnComplete: true,
  });

  const turns = await handleTurn(responseQueue);

  // Combine all audio chunks into a single buffer
  const combinedAudio = turns.reduce((acc: number[], turn: any) => {
    if (turn.data) {
      const buffer = Buffer.from(turn.data, "base64");
      const intArray = new Int16Array(
        buffer.buffer,
        buffer.byteOffset,
        buffer.byteLength / Int16Array.BYTES_PER_ELEMENT,
      );
      return acc.concat(Array.from(intArray));
    }
    return acc;
  }, []);

  // Write audio to a WAV file (output is 24kHz)
  const audioBuffer = new Int16Array(combinedAudio);
  const wf = new WaveFile();
  wf.fromScratch(1, 24000, "16", audioBuffer);
  fs.writeFileSync("output.wav", wf.toBuffer());

  session.close();
}

main();
```

### Multi-Turn Text Conversation

Build a conversation incrementally using structured turns:

```typescript
// Send a conversation history
const inputTurns = [
  { role: "user", parts: [{ text: "What is the capital of France?" }] },
  { role: "model", parts: [{ text: "Paris" }] },
];

session.sendClientContent({ turns: inputTurns, turnComplete: false });

// Continue with a follow-up question
const followUp = [
  { role: "user", parts: [{ text: "What is the capital of Germany?" }] },
];
session.sendClientContent({ turns: followUp, turnComplete: true });
```

### Streaming Microphone Audio

Stream live microphone audio using the `mic` package:

```typescript
import { GoogleGenAI, Modality } from "@google/genai";
import mic from "mic";
import Speaker from "speaker";

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const config = {
  responseModalities: [Modality.AUDIO],
  systemInstruction: "You are a helpful and friendly AI assistant.",
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: () => console.log("Connected to Gemini Live API"),
      onmessage: (message: any) => responseQueue.push(message),
      onerror: (e: any) => console.error("Error:", e.message),
      onclose: (e: any) => console.log("Closed:", e.reason),
    },
  });

  // Set up microphone: 16kHz, 16-bit, mono PCM
  const micInstance = mic({
    rate: "16000",
    bitwidth: "16",
    channels: "1",
    encoding: "signed-integer",
  });

  const micInputStream = micInstance.getAudioStream();

  micInputStream.on("data", (data: Buffer) => {
    session.sendRealtimeInput({
      audio: {
        data: data.toString("base64"),
        mimeType: "audio/pcm;rate=16000",
      },
    });
  });

  // Set up speaker for playback: 24kHz, 16-bit, mono PCM
  const speaker = new Speaker({
    channels: 1,
    bitDepth: 16,
    sampleRate: 24000,
  });

  micInstance.start();
  console.log("Microphone started. Speak to interact.");

  // Process responses and play audio
  while (true) {
    const message = await waitMessage(responseQueue);
    if (message.data) {
      const audioBuffer = Buffer.from(message.data, "base64");
      speaker.write(audioBuffer);
    }
  }
}

main();
```

### Streaming Audio from a File

Send a pre-recorded audio file through the realtime input channel:

```typescript
import { GoogleGenAI, Modality } from "@google/genai";
import * as fs from "node:fs";
import pkg from "wavefile";
const { WaveFile } = pkg;

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const config = {
  responseModalities: [Modality.AUDIO],
  inputAudioTranscription: {},
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: function () { console.log("Opened"); },
      onmessage: function (message: any) { responseQueue.push(message); },
      onerror: function (e: any) { console.error("Error:", e.message); },
      onclose: function (e: any) { console.log("Close:", e.reason); },
    },
  });

  // Read and convert WAV to 16kHz 16-bit PCM
  const fileBuffer = fs.readFileSync("input.wav");
  const wav = new WaveFile();
  wav.fromBuffer(fileBuffer);
  wav.toSampleRate(16000);
  wav.toBitDepth("16");
  const base64Audio = wav.toBase64();

  session.sendRealtimeInput({
    audio: {
      data: base64Audio,
      mimeType: "audio/pcm;rate=16000",
    },
  });

  const turns = await handleTurn(responseQueue);
  for (const turn of turns) {
    if (turn.serverContent && turn.serverContent.inputTranscription) {
      console.log("Input transcription:", turn.serverContent.inputTranscription.text);
    }
    if (turn.data) {
      console.log("Received audio data");
    }
  }

  session.close();
}

main();
```

### Streaming Video Input

Send video frames (images) alongside audio for multimodal interaction:

```typescript
import { GoogleGenAI, Modality, MediaResolution } from "@google/genai";
import * as fs from "node:fs";

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const config = {
  responseModalities: [Modality.AUDIO],
  mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: () => console.log("Connected"),
      onmessage: (message: any) => responseQueue.push(message),
      onerror: (e: any) => console.error("Error:", e.message),
      onclose: (e: any) => console.log("Closed:", e.reason),
    },
  });

  // Send a video frame as a JPEG image
  const frameBuffer = fs.readFileSync("frame.jpg");
  const base64Frame = frameBuffer.toString("base64");

  session.sendRealtimeInput({
    video: {
      data: base64Frame,
      mimeType: "image/jpeg",
    },
  });

  // Send a text prompt about the video
  session.sendClientContent({
    turns: "Describe what you see in this image.",
    turnComplete: true,
  });

  const turns = await handleTurn(responseQueue);
  for (const turn of turns) {
    if (turn.text) {
      console.log("Response:", turn.text);
    }
  }

  session.close();
}

main();
```

For continuous video streaming (e.g., from a webcam), send frames at a regular interval:

```typescript
// In a browser or Electron environment with canvas access:
function captureAndSendFrame(
  session: any,
  videoElement: HTMLVideoElement,
  canvas: HTMLCanvasElement,
): void {
  const ctx = canvas.getContext("2d")!;
  ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);

  canvas.toBlob(
    (blob) => {
      if (!blob) return;
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64 = (reader.result as string).split(",")[1];
        session.sendRealtimeInput({
          video: {
            data: base64,
            mimeType: "image/jpeg",
          },
        });
      };
      reader.readAsDataURL(blob);
    },
    "image/jpeg",
    0.8,
  );
}

// Send frames at approximately 1 FPS
setInterval(() => {
  captureAndSendFrame(session, videoElement, canvas);
}, 1000);
```

### Media Resolution Configuration

Control the resolution of video/image input to manage token usage:

```typescript
import { MediaResolution } from "@google/genai";

const config = {
  responseModalities: [Modality.TEXT],
  mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
};
```

### VAD Configuration -- Automatic Mode

Voice Activity Detection (VAD) is enabled by default. You can tune sensitivity:

```typescript
import {
  GoogleGenAI,
  Modality,
  StartSensitivity,
  EndSensitivity,
} from "@google/genai";

const config = {
  responseModalities: [Modality.TEXT],
  realtimeInputConfig: {
    automaticActivityDetection: {
      disabled: false,
      startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
      endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
      prefixPaddingMs: 20,
      silenceDurationMs: 100,
    },
  },
};
```

**Sensitivity options:**

- `StartSensitivity.START_SENSITIVITY_LOW` -- requires more confident speech detection to trigger, reduces false starts
- `StartSensitivity.START_SENSITIVITY_HIGH` -- triggers on quieter or less distinct speech
- `EndSensitivity.END_SENSITIVITY_LOW` -- allows longer pauses before ending the turn
- `EndSensitivity.END_SENSITIVITY_HIGH` -- ends the turn after shorter pauses

**Timing parameters:**

- `prefixPaddingMs` -- milliseconds of audio to include before detected speech onset
- `silenceDurationMs` -- milliseconds of silence required to consider speech ended

### VAD Configuration -- Manual Mode

Disable automatic VAD and manually signal speech boundaries:

```typescript
const config = {
  responseModalities: [Modality.TEXT],
  realtimeInputConfig: {
    automaticActivityDetection: {
      disabled: true,
    },
  },
};

// Signal that speech has started
session.sendRealtimeInput({ activityStart: {} });

// Stream audio chunks
session.sendRealtimeInput({
  audio: {
    data: base64Audio,
    mimeType: "audio/pcm;rate=16000",
  },
});

// Signal that speech has ended
session.sendRealtimeInput({ activityEnd: {} });
```

Use manual VAD when you have your own speech detection logic or when you need precise control over turn boundaries.

### Function Calling / Tool Use

Define functions and handle tool calls during a live session:

```typescript
import { GoogleGenAI, Modality } from "@google/genai";
import * as fs from "node:fs";
import pkg from "wavefile";
const { WaveFile } = pkg;

const ai = new GoogleGenAI({});
const model = "gemini-2.5-flash-native-audio-preview-12-2025";

const turnOnTheLights = { name: "turn_on_the_lights" };
const turnOffTheLights = { name: "turn_off_the_lights" };

const tools = [
  { functionDeclarations: [turnOnTheLights, turnOffTheLights] },
];

const config = {
  responseModalities: [Modality.AUDIO],
  tools: tools,
};

async function main(): Promise<void> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: config,
    callbacks: {
      onopen: function () { console.log("Opened"); },
      onmessage: function (message: any) { responseQueue.push(message); },
      onerror: function (e: any) { console.error("Error:", e.message); },
      onclose: function (e: any) { console.log("Close:", e.reason); },
    },
  });

  session.sendClientContent({
    turns: "Turn on the lights please",
    turnComplete: true,
  });

  let turns = await handleTurn(responseQueue);

  for (const turn of turns) {
    if (turn.toolCall) {
      console.log("Tool call received");
      const functionResponses = [];
      for (const fc of turn.toolCall.functionCalls) {
        console.log(`Calling function: ${fc.name}`);
        functionResponses.push({
          id: fc.id,
          name: fc.name,
          response: { result: "ok" },
        });
      }

      // Send the function results back to the model
      session.sendToolResponse({ functionResponses: functionResponses });
    }
  }

  // Get the model's response after processing tool results
  turns = await handleTurn(responseQueue);

  const combinedAudio = turns.reduce((acc: number[], turn: any) => {
    if (turn.data) {
      const buffer = Buffer.from(turn.data, "base64");
      const intArray = new Int16Array(
        buffer.buffer,
        buffer.byteOffset,
        buffer.byteLength / Int16Array.BYTES_PER_ELEMENT,
      );
      return acc.concat(Array.from(intArray));
    }
    return acc;
  }, []);

  const audioBuffer = new Int16Array(combinedAudio);
  const wf = new WaveFile();
  wf.fromScratch(1, 24000, "16", audioBuffer);
  fs.writeFileSync("tool_response.wav", wf.toBuffer());

  session.close();
}

main();
```

#### Function Declarations with Parameters

For functions that accept parameters, provide a full JSON Schema:

```typescript
const getWeather = {
  name: "get_weather",
  description: "Get the current weather for a location",
  parameters: {
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "City name or coordinates",
      },
      units: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "Temperature units",
      },
    },
    required: ["location"],
  },
};

const tools = [{ functionDeclarations: [getWeather] }];
```

#### Non-Blocking Functions

Mark functions as non-blocking so the model can continue generating while the function executes:

```typescript
import { Behavior, FunctionResponseScheduling } from "@google/genai";

const turnOnTheLights = {
  name: "turn_on_the_lights",
  behavior: Behavior.NON_BLOCKING,
};

// When sending the response, control how it affects generation:
const functionResponse = {
  id: fc.id,
  name: fc.name,
  response: {
    result: "ok",
    scheduling: FunctionResponseScheduling.INTERRUPT,
  },
};
```

#### Google Search Integration

Enable grounding with Google Search as a tool:

```typescript
const tools = [{ googleSearch: {} }];

const config = {
  responseModalities: [Modality.AUDIO],
  tools: tools,
};
```

#### Combining Multiple Tools

Use function calling and Google Search together:

```typescript
const tools = [
  { googleSearch: {} },
  { functionDeclarations: [turnOnTheLights, turnOffTheLights] },
];

const config = {
  responseModalities: [Modality.AUDIO],
  tools: tools,
};
```

### Native Audio Features

These features require the native audio model (`gemini-2.5-flash-native-audio-preview-12-2025`) and some require the `v1alpha` API version.

#### Affective Dialog

Enables the model to detect and respond to the emotional tone of speech:

```typescript
const ai = new GoogleGenAI({
  httpOptions: { apiVersion: "v1alpha" },
});

const config = {
  responseModalities: [Modality.AUDIO],
  enableAffectiveDialog: true,
};
```

#### Proactive Audio

Allows the model to initiate responses without waiting for explicit user input, based on audio context:

```typescript
const ai = new GoogleGenAI({
  httpOptions: { apiVersion: "v1alpha" },
});

const config = {
  responseModalities: [Modality.AUDIO],
  proactivity: { proactiveAudio: true },
};
```

#### Thinking

Enable the model to use internal reasoning before responding. The `thinkingBudget` controls the maximum number of tokens allocated to thinking:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  thinkingConfig: {
    thinkingBudget: 1024,
  },
};
```

To receive thinking summaries in the response:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  thinkingConfig: {
    thinkingBudget: 1024,
    includeThoughts: true,
  },
};
```

### Audio Transcription

#### Output Audio Transcription

Get a text transcript of the model's audio responses:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  outputAudioTranscription: {},
};

// In the message handler:
const turns = await handleTurn(responseQueue);
for (const turn of turns) {
  if (turn.serverContent && turn.serverContent.outputTranscription) {
    console.log("Model said:", turn.serverContent.outputTranscription.text);
  }
}
```

#### Input Audio Transcription

Get a text transcript of the user's audio input:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  inputAudioTranscription: {},
};

// In the message handler:
const turns = await handleTurn(responseQueue);
for (const turn of turns) {
  if (turn.serverContent && turn.serverContent.inputTranscription) {
    console.log("User said:", turn.serverContent.inputTranscription.text);
  }
}
```

### Handling Interruptions

When the user starts speaking while the model is generating audio, the model's generation is interrupted. Check for the interrupted flag:

```typescript
const turns = await handleTurn(responseQueue);

for (const turn of turns) {
  if (turn.serverContent && turn.serverContent.interrupted) {
    console.log("Model was interrupted by user speech");
    // Stop playing any buffered audio
    // The model will process the new user input
  }
}
```

### Generation Complete

Detect when the model has finished generating all content (distinct from `turnComplete`, which signals end of a conversational turn):

```typescript
const turns = await handleTurn(responseQueue);

for (const turn of turns) {
  if (turn.serverContent && turn.serverContent.generationComplete) {
    console.log("Generation complete");
  }
}
```

### Token Usage

Track token consumption during a session:

```typescript
const turns = await handleTurn(responseQueue);

for (const turn of turns) {
  if (turn.usageMetadata) {
    console.log("Total tokens used:", turn.usageMetadata.totalTokenCount);

    if (turn.usageMetadata.responseTokensDetails) {
      for (const detail of turn.usageMetadata.responseTokensDetails) {
        console.log("Token detail:", detail);
      }
    }
  }
}
```

### Session Management

#### GoAway Messages

The server sends a GoAway message before disconnecting. Use it to gracefully handle session endings:

```typescript
const turns = await handleTurn(responseQueue);

for (const turn of turns) {
  if (turn.goAway) {
    console.log("Session ending. Time left:", turn.goAway.timeLeft);
    // Prepare to reconnect or save state
  }
}
```

#### Session Resumption

Resume a session after disconnection by saving and reusing the session handle:

```typescript
let previousSessionHandle: string | null = null;

async function connectSession(): Promise<any> {
  const responseQueue: any[] = [];

  const session = await ai.live.connect({
    model: model,
    config: {
      responseModalities: [Modality.AUDIO],
      sessionResumption: { handle: previousSessionHandle },
    },
    callbacks: {
      onopen: () => console.log("Connected"),
      onmessage: (message: any) => {
        responseQueue.push(message);

        // Watch for session resumption updates
        if (message.sessionResumptionUpdate) {
          if (
            message.sessionResumptionUpdate.resumable &&
            message.sessionResumptionUpdate.newHandle
          ) {
            previousSessionHandle = message.sessionResumptionUpdate.newHandle;
            console.log("Saved session handle for resumption");
          }
        }
      },
      onerror: (e: any) => console.error("Error:", e.message),
      onclose: (e: any) => console.log("Closed:", e.reason),
    },
  });

  return { session, responseQueue };
}
```

#### Context Window Compression

Enable sliding window compression to handle long sessions that approach the context limit:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  contextWindowCompression: { slidingWindow: {} },
};
```

### Changing the Voice

Set the voice in the config using `speechConfig`:

```typescript
const config = {
  responseModalities: [Modality.AUDIO],
  speechConfig: {
    voiceConfig: {
      prebuiltVoiceConfig: {
        voiceName: "Kore",
      },
    },
  },
};
```

## Common Pitfalls

1. **Wrong audio format.** Input audio MUST be PCM 16-bit at 16kHz mono. Output audio is PCM 16-bit at 24kHz mono. Sending audio at the wrong sample rate produces garbled results or errors.

2. **Forgetting `turnComplete: true`.** When using `sendClientContent`, the model will not respond until a message with `turnComplete: true` is sent. Omitting it causes the session to hang waiting for more input.

3. **Not handling all message types.** The `onmessage` callback receives many different message types -- audio data (`turn.data`), text (`turn.text`), tool calls (`turn.toolCall`), transcriptions, usage metadata, GoAway messages, and session resumption updates. Ensure your message handler accounts for all relevant types.

4. **Session time limits.** Audio-only sessions last a maximum of 15 minutes. Audio + video sessions last only 2 minutes. Plan for reconnection using session resumption handles.

5. **Blocking the event loop.** The `onmessage` callback should be fast. Do not perform heavy synchronous work inside it. Push messages to a queue and process them asynchronously.

6. **Using v1alpha features without setting the API version.** Affective dialog and proactive audio require `httpOptions: { apiVersion: "v1alpha" }` when constructing the `GoogleGenAI` client. Without this, those config options are silently ignored or cause errors.

7. **Not closing the session.** Always call `session.close()` when finished. Orphaned sessions consume server resources until they time out.

8. **Sending tool responses without matching IDs.** When handling `toolCall` messages, each function response must include the `id` from the corresponding `functionCall`. Mismatched IDs cause the model to ignore the response.

9. **Video frame rate too high.** Sending video frames too frequently wastes tokens and can overwhelm the connection. For most use cases, 1 FPS is sufficient.

10. **Not handling the `interrupted` flag.** When the user interrupts the model, previously buffered audio should be discarded. Continuing to play stale audio creates a poor user experience.

## Available Voices

The following prebuilt voices are available for the Live API:

| Voice | Description |
|---|---|
| Puck | Conversational, friendly (default) |
| Charon | Deep, authoritative |
| Kore | Neutral, professional |
| Fenrir | Warm, approachable |
| Aoede | Bright, expressive |
| Leda | Calm, composed |
| Orus | Clear, articulate |
| Zephyr | Light, airy |

Set the voice using the `speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName` property as shown in the "Changing the Voice" section above. If no voice is specified, the default is Puck.

Native audio models may support additional voices beyond this list. Preview available voices in [Google AI Studio](https://aistudio.google.com/app/live).
