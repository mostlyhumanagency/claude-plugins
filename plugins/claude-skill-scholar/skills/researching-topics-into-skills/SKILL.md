---
name: researching-topics-into-skills
description: >
  Use when the user asks to "learn a technology", "create skills for a framework",
  "study a library and build skills", "research a topic for Claude Code", or wants to turn documentation
  into structured Claude Code skills. Triggers on requests to study, learn, research, or produce skills
  for any technology, framework, library, or knowledge domain.
---

# Learning a Topic Into Skills

## Overview

Research a technology or knowledge domain, decompose it into scoped skill units, and produce a plugin-ready skill set — each with SKILL.md, reference files, and optional assets.

## When to Use

- User wants to create Claude Code skills for a new technology
- User wants to study a framework and produce structured knowledge
- User asks to "learn X and make skills for it"

Do NOT use when the user wants to learn something for themselves (not for Claude Code skill authoring).

## The Three-Phase Process

### Phase 1: Scope and Sources

1. **Clarify scope** — Ask the user (one question at a time):
   - What topic? (e.g., "Svelte 5", "PostgreSQL indexing")
   - What depth? Overview vs. production-ready reference
   - Focus areas or exclusions?

2. **Discover official sources** — Priority order:
   - `llms.txt` / `llms-full.txt` at the domain root (machine-readable doc index)
   - Official documentation site
   - Official API reference (if separate)
   - GitHub repo README and docs/
   - Official blog / changelog

3. **Discover community sources** — Only after exhausting official sources:
   - Widely-cited tutorials from known authors
   - Community-curated collections (awesome-* repos)
   - High-vote Stack Overflow canonical answers
   - Discard: blog spam, SEO content, AI-generated summaries

4. **Save source manifest** using `templates/source-manifest.md` for traceability.

Use the `templates/source-discovery-prompt.md` template to dispatch a source discovery subagent.

### Phase 2: Topic Map and Decomposition

1. **Build breadth-first topic map** from sources — flat list of knowledge areas
2. **Decompose into skill units** applying the granularity test:
   - Independently useful (agent can apply without loading others)
   - Clear "when to use" trigger
   - SKILL.md body fits 1,500-2,000 words (heavy reference in separate files)
   - No significant overlap with sibling units
3. **Name skills** in gerund form: `using-svelte-runes`, `testing-svelte-components`
4. **Create router skill** if 4+ subskills — lightweight SKILL.md (<200 words) that lists subskills with triggers. Use `templates/router-template.md`.
5. **Present skill map** to user as a table and wait for approval:

| Skill Name | Triggers | Est. Files |
|---|---|---|
| using-svelte-runes | Reactive state, $state/$derived/$effect | SKILL.md + references/runes-api.md |

### Phase 3: Research and Write

1. **Dispatch research subagents** in parallel for independent skill units using `templates/researcher-prompt.md`
2. **Write each skill** using `templates/skill-writer-prompt.md`, following progressive disclosure:
   - SKILL.md: entrypoint, 1,500-2,000 words max
   - `references/`: dense API tables, comprehensive patterns (2,000-5,000+ words each)
   - `examples/`: complete runnable code
   - `scripts/`: executable utilities
3. **Validate** each produced skill with `scripts/validate-skill.sh`
4. **Ask the user** if they want to package the skills into a plugin. If yes, delegate to `publishing-skills` for plugin scaffolding (plugin.json, agents, commands, README, marketplace entry). If no, stop after delivering the validated skill files.

See `references/process-guide.md` for detailed phase instructions and `references/quality-checklist.md` for the verification checklist.

## Key Principles

- **Official docs first** — including llms.txt. Community sources supplement only.
- **Progressive disclosure** — SKILL.md is the entrypoint. Heavy content goes to `references/`. One level deep only.
- **One great example beats five mediocre ones** — each pattern gets one excellent, complete, runnable code example.
- **Third-person descriptions** — "Use when the user asks to..."
- **Imperative writing style** — "Configure the server" not "You should configure the server"
- **`${CLAUDE_PLUGIN_ROOT}`** for all intra-plugin path references

## Common Mistakes

**Copying docs verbatim** — Skills are opinionated guides for agents, not documentation mirrors. Distill and structure for agent use.

**Skipping llms.txt** — Many major projects publish llms.txt. Always check first — it's the most agent-friendly source.

**One giant skill** — If SKILL.md exceeds 2,000 words, extract to references/ or decompose further.

**Over-decomposing** — Each unit must be independently useful. Tightly coupled phases belong in one skill.

**Weak descriptions** — Include exact trigger phrases users would say, error messages, tool names, symptoms.

**Stale community sources** — Check publication date. Discard anything older than the topic's current major version.
