---
name: skill-scholar-router
description: >
  Use when the user asks about Claude Code skills — creating, reviewing, maintaining, or publishing them.
  Routes to the correct subskill based on the user's intent.
---

# Skill Scholar Router

Route to the correct skill for the user's request.

| Skill | Use When |
|---|---|
| `researching-topics-into-skills` | "learn a technology", "create skills for a framework", "study docs and build skills", "research a topic" |
| `reviewing-skills` | "review skill quality", "check my skill", "is this skill good enough", "skill quality checklist" |
| `maintaining-skills` | "update a skill", "refresh skills from new docs", "skill is outdated", "check skill staleness" |
| `publishing-skills` | "package skills into a plugin", "create plugin.json", "publish a plugin", "plugin directory structure" |
