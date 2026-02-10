# Detailed Process Guide

## Phase 1: Source Discovery — Deep Dive

### Checking llms.txt

Fetch these URLs for every topic domain:
- `https://<domain>/llms.txt`
- `https://<domain>/llms-full.txt`
- `https://<domain>/.well-known/llms.txt`

If found, parse for documentation structure, key page URLs, and recommended reading order. This is the most agent-friendly source available.

### Evaluating Community Sources

Only supplement official docs. For each candidate source, verify:
- Published within current major version era
- Author is known/reputable (conference speaker, core team, recognized expert)
- High engagement (stars, upvotes, shares)
- Not AI-generated or SEO-farmed content

### Source Manifest

Save a source manifest using the `templates/source-manifest.md` template. This provides traceability for every fact in the produced skills.

---

## Phase 2: Decomposition — Deep Dive

### Building the Topic Map

Extract a breadth-first topic map from sources:

```
Topic: Svelte 5
├── Reactivity model (runes, signals, $state, $derived, $effect)
├── Component anatomy (.svelte files, script/template/style)
├── Template syntax (each, if, await, snippets, @render)
├── Component composition (props, events, slots, context)
├── Stores and global state ($state outside components, stores migration)
├── Lifecycle and side effects ($effect, onMount, onDestroy, tick)
├── Styling (scoped CSS, global, CSS variables, transitions, animations)
├── SvelteKit integration (routing, load functions, SSR, forms)
├── Testing (component testing, e2e, vitest setup)
└── Migration from Svelte 4 (runes migration, breaking changes)
```

### Skill Naming Convention

Use gerund form, verb-first: `using-svelte-runes`, `testing-svelte-components`, `styling-svelte-apps`.

For the router skill (if 4+ subskills), use the bare topic name: `coding-svelte` or `using-svelte`.

### Approval Gate

Always present the decomposition to the user as a table before writing:

```markdown
| Skill Name | Triggers (when to use) | Est. Files |
|---|---|---|
| using-svelte-runes | Writing reactive state in Svelte 5, using $state/$derived/$effect | SKILL.md + references/runes-api.md |
| testing-svelte-components | Testing Svelte components, vitest setup, component testing | SKILL.md + references/testing-patterns.md |
```

Wait for explicit approval before proceeding to Phase 3.

---

## Phase 3: Research and Write — Deep Dive

### Dispatching Research Subagents

For each approved skill unit, dispatch a research subagent using `templates/researcher-prompt.md`:

```
Task tool (general-purpose):
  description: "Research [skill-name] for [topic]"
  prompt: [paste filled template]
```

**Dispatch independent skill units in parallel.** Skills with dependencies should be researched sequentially.

### Writing Skills

For each skill, dispatch a writing subagent using `templates/skill-writer-prompt.md`. The writer receives research notes and produces:

```
skill-name/
├── SKILL.md                    # Entrypoint (1,500-2,000 words)
├── references/
│   └── detailed-guide.md       # Heavy reference (2,000-5,000+ words)
├── examples/
│   └── working-example.ts      # Complete runnable code
└── scripts/
    └── utility.sh              # Executable tools if applicable
```

### SKILL.md Structure

```markdown
---
name: skill-name
description: >
  This skill should be used when the user asks to "do X", "configure Y",
  or encounters [specific error messages]. Triggers on [topic area] work
  involving [keywords].
---

# Skill Name

## Overview
Core concept in 1-2 sentences.

## When to Use
- Triggering conditions and symptoms
- When NOT to use

## Core Patterns
Before/after comparisons, code examples.
See references/detailed-guide.md for comprehensive patterns.

## Quick Reference
| Operation | Syntax/API | Notes |
|---|---|---|

## Common Mistakes
| Mistake | Symptom | Fix |
|---|---|---|
```

### Progressive Disclosure Rules

- SKILL.md is always the entrypoint — concise, scannable
- Reference files are ONE LEVEL DEEP from SKILL.md
- Never nest references inside references
- If a reference file exceeds 10,000 words, include grep search patterns in SKILL.md so the agent can search rather than reading the whole file
- Scripts in `scripts/` are executable — the agent runs them without reading into context
- Templates in `templates/` or `examples/` are copied, not loaded as knowledge

### Validation

After writing each skill, run the validation script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/learning-skill/scripts/validate-skill.sh /path/to/skill-dir
```

This checks word count, required sections, description format, and structural rules.
