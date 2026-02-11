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

Use the Task tool with `subagent_type: "general-purpose"` for research subagents. Limit to 4-5 parallel subagents to avoid overwhelming context.

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
  Use when the user asks to "do X", "configure Y",
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
bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/validate-skill.sh /path/to/skill-dir
```

This checks word count, required sections, description format, and structural rules.

---

## Phase 3b: Packaging (Optional)

After all skills are written and validated, **ask the user** if they want to package the skills into a plugin. If the user declines, stop here — the validated skill files are the deliverable. If the user accepts, proceed with packaging.

### Plugin Metadata

Create `.claude-plugin/plugin.json` with required fields:
- `name`: lowercase, hyphens only (e.g., `coding-with-svelte`)
- `version`: semver (start at `1.0.0`)
- `description`: one-line summary of what the plugin teaches
- `author`: plugin author name
- `keywords`: array of discovery terms

Use `templates/plugin-json-template.json` as a starting point.

### Router Skill

If the plugin has 4+ subskills, create a router skill using `templates/router-template.md`. The router is a lightweight SKILL.md (<200 words) that directs the agent to the correct subskill based on the user's request.

### Agent and Command Definitions

Every plugin must include:
- At least one agent definition — use `templates/agent-template.md`
- At least one command — use `templates/command-template.md`

### README and Marketplace

- Generate `README.md` using `scripts/generate-readme.sh` or write manually
- Update `marketplace.json` at the repo root if the plugin will be listed

---

## Phase 4: Testing and Validation

After packaging, validate the complete plugin:

### Step 1: Structural Review

Run review-skill.sh on every produced skill:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/review-skill.sh <skill-dir> --plugin-dir <plugin-dir>
```

Fix all errors. Warnings are acceptable but should be addressed.

### Step 2: Smoke Testing

Run test-skill.sh on each skill to verify triggers activate correctly:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/test-skill.sh <skill-dir> --model haiku --budget 0.25
```

All scenarios should pass. If failures occur, improve the SKILL.md triggers and descriptions.

### Step 3: Impact Evaluation (optional but recommended)

Run evaluate-skill.sh on key skills to measure their impact:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/evaluate-skill.sh <skill-dir> --trials 3
```

Skills should score MARGINAL or better (delta > +0.3). Skills scoring NEUTRAL or NEGATIVE need content improvements.

### Step 4: Plugin Inventory

Generate the plugin inventory to verify completeness:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/count-skills.sh <plugin-dir>
```

---

## Error Recovery

Common failures and how to handle them:

- **WebFetch fails**: Try alternative URLs, fall back to WebSearch, check if the site requires authentication
- **llms.txt malformed**: Skip and use regular documentation URLs
- **Source unavailable**: Note in source manifest, use cached/archived versions, WebSearch for mirrors
- **Scope too broad**: Suggest decomposing into multiple plugin sets
- **Scope too narrow**: Suggest combining with related topics
