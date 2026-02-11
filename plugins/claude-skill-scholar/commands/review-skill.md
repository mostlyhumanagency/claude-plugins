---
description: Review a skill directory against the quality checklist
argument-hint: <skill-directory-path>
---

# Review a Skill

Review the skill at **$ARGUMENTS** against the quality checklist.

## Process

1. Validate that the argument is a directory containing a SKILL.md file
2. Detect the parent plugin by walking up the directory tree to find `.claude-plugin/plugin.json`
3. Run the review script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/researching-topics-into-skills/scripts/review-skill.sh "$ARGUMENTS"
   ```
   Pass `--plugin-dir <path>` if a parent plugin was detected.
   Do NOT use `--deep` or `--fix` unless the user explicitly requests it.
4. Present results grouped by severity: errors first, warnings second, passes last
5. For each error, suggest a concrete fix with specific edits to make
6. If the user asks to fix issues, re-run with `--fix`, then verify the results
7. If the user wants deeper analysis, re-run with `--deep`

## Output

Present a summary table:

| Category | Errors | Warnings | Passed |
|----------|--------|----------|--------|

Then list each error and warning with its suggested fix.
