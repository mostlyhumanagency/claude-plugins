# Agent Definition Template

Use this template when creating agent .md files for the `agents/` directory.

## Template

```markdown
---
name: {{AGENT_NAME}}
description: |
  {{DESCRIPTION_WITH_EXAMPLES}}

  <example>
  Context: {{CONTEXT}}
  user: "{{USER_MESSAGE}}"
  assistant: "{{ASSISTANT_RESPONSE}}"
  <commentary>
  {{WHY_THIS_AGENT}}
  </commentary>
  </example>

  <example>
  Context: {{CONTEXT_2}}
  user: "{{USER_MESSAGE_2}}"
  assistant: "{{ASSISTANT_RESPONSE_2}}"
  <commentary>
  {{WHY_THIS_AGENT_2}}
  </commentary>
  </example>
model: {{MODEL}}
color: {{COLOR}}
tools: [{{TOOL_LIST}}]
---

{{SYSTEM_PROMPT}}

## How to Work

### Step 1: {{FIRST_PHASE}}
...

### Step 2: {{SECOND_PHASE}}
...

## Rules

- {{RULE_1}}
- {{RULE_2}}
```

## Notes

### Model Selection
- **opus**: Complex research, multi-step reasoning, orchestration across subagents
- **sonnet**: Focused implementation tasks, code generation, single-domain work
- **haiku**: Quick lookups, simple transformations, lightweight operations

### Color Assignment
Choose from: magenta, yellow, cyan, green, orange, blue, purple, red. No two agents in the same plugin should share a color.

### Tools
List only what the agent actually needs. Common groupings:
- **Research**: Read, Grep, Glob, WebFetch, WebSearch
- **Implementation**: Read, Grep, Glob, Bash, Write, Edit
- **Orchestration**: Read, Grep, Glob, Bash, Write, Edit, WebFetch, WebSearch, Task

### Description
- Must include 2+ examples using the `<example>` XML format
- Each example needs Context, user message, assistant response, and commentary
- Examples should show distinct use cases, not variations of the same one

### System Prompt
- Write in imperative style ("Analyze the codebase", not "You should analyze")
- Front-load the most important behavioral instructions
- Keep under 500 words — agents that need more context should read reference files
