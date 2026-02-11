---
description: Look up Anthropic API reference for a specific topic
argument-hint: <topic>
---

# API Reference Lookup

Look up the Anthropic Claude API reference for: $ARGUMENTS

## Process

1. Read ${CLAUDE_PLUGIN_ROOT}/skills/using-anthropic-api/SKILL.md to find the most relevant subskill for the topic
2. Read the matching skill's SKILL.md file
3. Extract and present the Quick Reference table, key patterns, and common mistakes
4. If the topic spans multiple skills, read and synthesize from all relevant ones

## Output Format

Present a concise reference card with:
- The relevant quick reference table(s)
- One key code example (curl)
- Common mistakes to watch for
