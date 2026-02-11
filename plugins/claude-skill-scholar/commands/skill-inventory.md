---
description: List all skills in a plugin with stats and validation status
argument-hint: <plugin-directory-path>
---

# Skill Inventory

List all skills in the plugin at **$ARGUMENTS** with stats and validation status.

## Process

1. Resolve the plugin directory from `$ARGUMENTS`; use the current working directory if no argument is provided
2. Run the count script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/count-skills.sh "$ARGUMENTS"
   ```
3. Optionally run `review-skill.sh` on each discovered skill to get validation status
4. Present the inventory as a table with columns: Skill Name, Word Count, Reference Count, Validation Status (pass/fail)
5. Highlight any skills that have errors requiring attention
