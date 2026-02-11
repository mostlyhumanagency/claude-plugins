---
description: Diagnose an Anthropic TypeScript SDK error or unexpected behavior
argument-hint: <error message or symptom>
agent: anthropic-sdk-ts-debugger
---

# Debug SDK Error

Diagnose this Anthropic TypeScript SDK error or unexpected behavior: $ARGUMENTS

## Process

1. Search all skill files in ${CLAUDE_PLUGIN_ROOT}/skills/ for the error message or symptom
2. Read the matching skill's Common Mistakes table
3. Identify the root cause and provide the fix
4. Show corrected TypeScript code

## Output Format

Present:
- **Error**: The error or symptom
- **Root Cause**: Why it happens
- **Fix**: The concrete solution with corrected TypeScript code
- **Skill Reference**: Which skill documents this issue
