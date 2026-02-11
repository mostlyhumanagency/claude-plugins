# Command Definition Template

Use this template when creating command .md files for the `commands/` directory.

## Template

```markdown
---
description: {{SHORT_DESCRIPTION}}
argument-hint: {{ARGUMENT_HINT}}
agent: {{AGENT_NAME}}
context: fork
---

# {{COMMAND_TITLE}}

{{BRIEF_INTRO_USING_$ARGUMENTS}}

## Process

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

## Output Format

{{DESCRIBE_EXPECTED_OUTPUT}}
```

## Notes

### Frontmatter Fields
- **description**: Concise one-line summary shown in command listings
- **argument-hint**: Shows expected argument format (e.g., `<topic>`, `<file-path>`, `[optional-flag]`)
- **agent**: Optional. Set only if the command delegates to a specific agent. Omit to use the default agent.
- **context**: Optional. Set to `fork` for long-running commands that should run in a background context. Omit for quick commands that complete in seconds.

### Referencing Arguments
- `$ARGUMENTS` contains everything the user typed after the slash command
- Example: if user types `/research Node.js streams`, then `$ARGUMENTS` is `Node.js streams`

### Referencing Plugin Files
- Use `${CLAUDE_PLUGIN_ROOT}` to build paths to files within the plugin
- Example: `${CLAUDE_PLUGIN_ROOT}/skills/my-skill/templates/prompt.md`

### Guidelines
- Keep the process section to 3-7 steps
- Each step should be a clear, actionable instruction
- Output format section tells the agent what the user expects to see when done
- Commands that produce files should specify where files are written
