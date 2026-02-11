---
description: Refresh a skill from updated documentation sources
argument-hint: <skill-directory-path>
agent: skill-maintainer
context: fork
---

# Update a Skill

Refresh the skill at **$ARGUMENTS** from its original documentation sources.

## Process

1. Read the skill's SKILL.md and all reference files in the skill directory
2. Look for `source-manifest.md` in the skill directory or the parent plugin directory for original source URLs and versions
3. Re-fetch each source to check for updates:
   - Look for version changes
   - Identify new API additions
   - Detect deprecations or breaking changes
4. Diff the current skill content against the updated source material
5. Present a change report:
   - **Stale**: Content that no longer matches the source
   - **Needs Updating**: Patterns or APIs that have changed
   - **New**: Features or patterns added since the skill was written
6. Apply targeted, surgical updates to SKILL.md and reference files — do not rewrite entire files, only update the sections that changed
7. Re-run the review script to validate the updated skill:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/review-skill.sh "$ARGUMENTS"
   ```
8. Report all changes made with a summary of what was updated and why
