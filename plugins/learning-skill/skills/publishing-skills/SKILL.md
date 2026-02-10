---
name: publishing-skills
description: >
  This skill should be used when the user asks to "package skills into a plugin", "create plugin.json",
  "publish a plugin", "generate README for plugin", "plugin directory structure", or wants to assemble
  a set of skills into a complete, distributable Claude Code plugin. Triggers on requests to package,
  publish, bundle, or structure a plugin for distribution.
---

# Publishing Skills as a Plugin

## Overview

Package a set of validated skills into a complete, distributable Claude Code plugin. This covers directory structure, metadata, router skills, agents, commands, README generation, marketplace registration, and version management. The input is a set of written and reviewed skills; the output is a plugin directory ready for installation or distribution.

## When to Use

- Skills are written and validated, ready to package into a plugin
- User wants to create the plugin scaffolding around existing skills
- User asks to generate plugin.json, README, or marketplace entry
- User wants to add agents or commands to an existing plugin
- User needs to bump a version and update marketplace metadata

Do NOT use when:
- Writing individual skill content — use `learning-skill` instead
- Fixing quality issues in skill content — use `reviewing-skills` instead
- Updating skill content for upstream doc changes — use `maintaining-skills` instead

## Plugin Directory Structure

Every plugin follows this layout:

```
plugin-name/
  .claude-plugin/
    plugin.json              # Required: plugin metadata
  skills/
    skill-name/
      SKILL.md               # Required: at least one skill
      references/             # Optional: dense reference material
      templates/              # Optional: reusable templates
      scripts/                # Optional: executable utilities
      examples/               # Optional: runnable code examples
    router-skill/
      SKILL.md               # Required if 4+ skills
  agents/
    agent-name.md            # Recommended: specialized agent definitions
  commands/
    command-name.md          # Recommended: user-facing entry points
  scripts/                   # Optional: plugin-level scripts
  templates/                 # Optional: plugin-level templates
  README.md                  # Recommended: plugin documentation
```

### Required Components

**plugin.json** — The only strictly required file beyond at least one SKILL.md. Place it at `.claude-plugin/plugin.json`:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "One-line description of what the plugin teaches",
  "author": "Author Name",
  "homepage": "https://github.com/org/repo",
  "repository": "https://github.com/org/repo",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

**Required fields**: `name`, `version`, `description`. All others are recommended but not enforced.

**Version**: Follow semver strictly. Start at `1.0.0` for new plugins. Patch (`1.0.1`) for fixes, minor (`1.1.0`) for new skills or features, major (`2.0.0`) for breaking changes to skill structure or behavior.

### Router Skill

Create a router skill when the plugin contains 4 or more subskills. The router is a lightweight SKILL.md (under 200 words) that lists all subskills with their trigger phrases so the agent can route to the correct skill.

Use the router template at `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/templates/router-template.md` as a starting point.

Router skill rules:
- Name it after the plugin topic (e.g., `svelte-skills` for a Svelte plugin)
- Keep it under 200 words — it is a routing table, not content
- List each subskill with its name, one-line description, and 3-5 trigger phrases
- Do not duplicate content from subskills

### Agents

Create agents for complex multi-step workflows that benefit from dedicated tool selection and system prompts. Common agent patterns:

- **Researcher agent** — Uses WebFetch and WebSearch to gather information
- **Writer agent** — Uses Read, Write, Edit to produce skill files
- **Reviewer agent** — Uses Read, Grep, Bash to validate skill quality
- **Tester agent** — Uses Bash, Read to run test scenarios

Agent files live in `agents/` and follow the agent template at `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/templates/agent-template.md`.

When defining agents:
- Select the minimum set of tools needed for the task
- Write a focused system prompt that constrains the agent's scope
- Specify the model — use `claude-sonnet-4-5-20250929` for most agents, `claude-opus-4-6` for complex reasoning tasks
- Include clear success criteria so the agent knows when to stop

### Commands

Create commands as user-facing entry points. Commands are invoked with `/<command-name>` and typically delegate to agents or orchestrate multi-step workflows.

Command files live in `commands/` and follow the command template at `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/templates/command-template.md`.

Command design rules:
- One command per distinct user action (learn, review, test, publish)
- Accept arguments for flexibility (e.g., `/review-skill <path>`)
- Delegate heavy work to agents — commands should be thin orchestration layers
- Provide clear usage instructions and examples in the command file

### README Generation

Generate a README.md for the plugin root that includes:

1. **Title and description** — What the plugin does
2. **Installation instructions** — How to install the plugin
3. **Skills table** — Name, description, and trigger phrases for each skill
4. **Agents table** — Name, description, and purpose for each agent
5. **Commands table** — Name, syntax, and description for each command
6. **Scripts table** — Name and purpose for each script (if any)

Use `generate-readme.sh` if available in the plugin's scripts, or manually construct the README following the tables above.

### Marketplace Entry

After packaging the plugin, update the marketplace registry at the repository root. The marketplace file (`marketplace.json` or equivalent) must contain a matching entry:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Same description as plugin.json",
  "source": "plugins/plugin-name/"
}
```

Keep the marketplace entry synchronized with `plugin.json` on every version bump. The `name`, `version`, and `description` fields must match exactly.

### Path References

Use `${CLAUDE_PLUGIN_ROOT}` for all paths that reference files within the plugin. This variable resolves to the plugin's root directory at runtime and ensures the plugin works regardless of where it is installed.

Examples:
- `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/scripts/validate-skill.sh`
- `${CLAUDE_PLUGIN_ROOT}templates/source-manifest.md`

Never hardcode absolute paths like `/Users/name/plugins/my-plugin/`. Never use relative paths like `../templates/`.

## Quick Reference

| Component | Location | Required |
|---|---|---|
| plugin.json | `.claude-plugin/plugin.json` | Yes |
| Skills | `skills/<name>/SKILL.md` | Yes (at least 1) |
| Router skill | `skills/<router-name>/SKILL.md` | If 4+ skills |
| Agents | `agents/<name>.md` | Recommended |
| Commands | `commands/<name>.md` | Recommended |
| Scripts | `skills/<name>/scripts/` or `scripts/` | Optional |
| Templates | `skills/<name>/templates/` or `templates/` | Optional |
| README | `README.md` | Recommended |
| Marketplace entry | Repository root `marketplace.json` | Yes for distribution |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Missing plugin.json | Plugin will not install or be recognized | Create `.claude-plugin/plugin.json` with at least `name`, `version`, `description` |
| No router skill | Users cannot discover subskills, wrong skill activates | Add a router skill if the plugin has 4 or more skills |
| Hardcoded paths | Plugin breaks on other machines or install locations | Use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin path references |
| Version not bumped | Users get stale cached version after updates | Always bump version in both `plugin.json` and marketplace entry on changes |
| Marketplace out of sync | Install fetches wrong version or description | Update marketplace entry to match `plugin.json` on every release |
| README missing skill table | Users cannot discover what the plugin offers | Include tables for skills, agents, and commands in README |
| Agent with too many tools | Agent is slow and unfocused | Select the minimum set of tools needed for the agent's specific task |
| Commands doing heavy work | Slow commands, duplicated logic | Commands should delegate to agents for complex workflows |
