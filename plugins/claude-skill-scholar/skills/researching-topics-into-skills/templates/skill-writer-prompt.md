# Skill Writer Subagent Prompt Template

Use this template when dispatching a subagent to write a skill from research notes.

```
Task tool (general-purpose):
  description: "Write skill [skill-name]"
  prompt: |
    Write a Claude Code skill from research notes.

    ## Skill Metadata

    - Name: [skill-name]
    - Target directory: [path/skill-name/]
    - Router skill (if any): [router-skill-name]

    ## Research Notes

    [Paste full research output from researcher subagent]

    ## Writing Rules

    ### SKILL.md (required)

    YAML frontmatter:
    - name: [skill-name] (lowercase, hyphens only, max 64 chars)
    - description: "Use when the user asks to..." — third person, specific trigger phrases

    Body structure:
    1. ## Overview — Core concept in 1-2 sentences
    2. ## When to Use — Bullet list of triggers. When NOT to use.
    3. ## Core Patterns — Code examples with before/after if applicable
    4. ## Quick Reference — Scannable table
    5. ## Common Mistakes — What goes wrong + fixes
    6. ## References — Links to reference files (if any)

    Body target: 1,500-2,000 words. Hard limit: 5,000 words.
    Move heavy content to references/.

    ### Reference files (only if needed)

    Create under references/ for:
    - API/syntax tables >100 lines
    - Code patterns >50 lines
    - Comprehensive guides

    Reference files are ONE LEVEL DEEP. Never reference other reference files.

    ### Examples (only if needed)

    Create under examples/ for:
    - Complete runnable code examples
    - Configuration files
    - Template files users copy

    ### Quality rules

    - One excellent code example per pattern (complete, runnable, commented)
    - Keywords for discoverability: error messages, tool names, symptoms
    - No narrative storytelling — techniques and patterns only
    - No emojis unless user requested them
    - Third-person voice in description, imperative in body
    - Gerund-form naming (using-, writing-, testing-)
    - Use ${CLAUDE_PLUGIN_ROOT} for intra-plugin path references

    ### Plugin Completeness (when writing the final skill in a set)

    After writing all individual skills, also produce:
    - Router skill (if 4+ subskills) — use ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/templates/router-template.md
    - At least one agent definition — use ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/templates/agent-template.md
    - At least one command — use ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/templates/command-template.md
    - plugin.json — use ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/templates/plugin-json-template.json
    - README.md — generate with ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/generate-readme.sh

    ## Output

    Write all files to disk using the Write tool:
    - [path/skill-name/SKILL.md] (always)
    - [path/skill-name/references/*.md] (if needed)
    - [path/skill-name/examples/*] (if needed)

    After writing, report:
    - Files created with word counts
    - SKILL.md body word count (must be 1,500-2,000)
    - Description field (verify it starts with "Use when")
```
