# learning-skill

A Claude Code plugin for researching a technology or knowledge domain and producing a set of structured, well-packaged skills from it.

## What It Does

Given a topic (framework, library, language feature), this plugin:
1. Discovers official and community documentation sources (including llms.txt)
2. Builds a breadth-first topic map and decomposes into scoped skill units
3. Dispatches parallel research subagents per skill unit
4. Writes each skill following progressive disclosure and plugin packaging best practices
5. Validates produced skills against a quality checklist

## Installation

```sh
claude plugin add mostlyhumanagency/claude-plugins --path plugins/learning-skill
```

## Usage

### Slash command

```
/learn svelte-5
/learn drizzle-orm
/learn postgresql-indexing
```

### Via agent

The `skill-learner` agent is also available for delegation from other contexts.

## Plugin Structure

```
learning-skill/
├── .claude-plugin/plugin.json
├── agents/
│   └── skill-learner.md          # Opus-powered research + writing agent
├── commands/
│   └── learn.md                  # /learn slash command
└── skills/
    └── learning-skill/
        ├── SKILL.md              # Main skill (~1,500 words)
        ├── references/
        │   ├── process-guide.md  # Detailed phase-by-phase instructions
        │   └── quality-checklist.md
        ├── templates/
        │   ├── researcher-prompt.md
        │   ├── skill-writer-prompt.md
        │   ├── source-discovery-prompt.md
        │   ├── router-template.md
        │   ├── source-manifest.md
        │   └── SKILL.md.template
        └── scripts/
            └── validate-skill.sh # Validates produced skills
```
