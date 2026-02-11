# Router Skill Template

When a topic produces 4+ skills, create a lightweight router skill. Use this template.

## Template

```markdown
---
name: [topic-name]
description: >
  This skill should be used when the user asks about [topic] and it is unclear
  which specific subskill applies. Routes to the most specific [topic] skill.
---

# [Topic Name]

## Overview

[One sentence about the topic.]

## Subskills

| Skill | Use When |
|---|---|
| [topic]-[area-1] | [triggering condition] |
| [topic]-[area-2] | [triggering condition] |
| [topic]-[area-3] | [triggering condition] |
| [topic]-[area-4] | [triggering condition] |

If unsure, start with [topic]-[most-fundamental-area].
```

## Rules

- Router SKILL.md MUST be <200 words
- Description says "...unclear which specific subskill applies" — it's a fallback
- Table has one row per subskill with clear trigger
- Point to the most fundamental subskill as default
- No code examples, no reference files — just routing
