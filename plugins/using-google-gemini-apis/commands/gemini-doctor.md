---
description: "Audit Gemini API setup: SDK versions, authentication, model availability, and configuration health"
---

# gemini-doctor

Audit the health of a Google Gemini API project by checking SDK installation, authentication, and configuration.

## Process

1. Check for Python SDK: look for `google-genai` in requirements.txt, pyproject.toml, or Pipfile
2. Check for TypeScript SDK: look for `@google/genai` in package.json
3. Verify SDK versions are current (Python >= 1.0.0, TypeScript >= 1.0.0)
4. Check for API key configuration: GEMINI_API_KEY or GOOGLE_API_KEY in .env files, environment setup
5. Scan source files for deprecated model names or API patterns
6. Check for common misconfigurations:
   - Using response_modalities without "IMAGE" for image generation
   - Using v1alpha endpoints when v1 is available
   - Missing async/await on Live API calls
   - Polling without timeout on Veo operations
7. Verify imports match SDK version (e.g., `from google import genai` not `import google.generativeai`)
8. Report findings with severity (error, warning, info) and suggested fix
9. Summarize: total issues, health score, top priorities
