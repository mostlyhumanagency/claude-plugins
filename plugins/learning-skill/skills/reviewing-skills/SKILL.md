---
name: reviewing-skills
description: >
  This skill should be used when the user asks to "review skill quality", "check my skill",
  "is this skill good enough", "improve skill quality", "skill quality checklist", or wants
  a structured quality assessment of Claude Code skills. Triggers on requests to review, audit,
  check, grade, or validate skill quality before or after publishing.
---

# Reviewing Skill Quality

## Overview

Perform structured quality reviews of Claude Code skills by combining automated structural validation with content analysis. Catch issues before publishing — missing sections, weak triggers, broken examples, skill overlap, and content gaps. Produce a grade and actionable fix list so the skill author knows exactly what to address.

## When to Use

- After writing a new skill, before publishing
- Before packaging skills into a plugin
- When quality is uncertain or a skill "feels off"
- Periodic quality audits of an existing plugin's skill set
- After updating a skill to verify the update did not introduce regressions

Do NOT use when:
- Creating skills from scratch — use `learning-skill` instead
- Updating stale skills with new upstream content — use `maintaining-skills` instead
- Packaging skills into a plugin — use `publishing-skills` instead

## Core Patterns

### Structural Review

Run automated structural validation first. It catches the most common issues instantly.

Execute `review-skill.sh` from `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/scripts/`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}skills/learning-skill/scripts/review-skill.sh" <path-to-SKILL.md>
```

The script checks:
- **Frontmatter** — `name` and `description` fields present and correctly formatted
- **Required sections** — Overview, When to Use, at least one core content section, Common Mistakes
- **Word counts** — SKILL.md body between 1,500-2,000 words; router skills under 200 words
- **Path references** — All intra-plugin paths use `${CLAUDE_PLUGIN_ROOT}`, no hardcoded absolute paths
- **Description format** — Starts with "This skill should be used when"

Fix auto-fixable issues with the `--fix` flag:

```bash
bash "${CLAUDE_PLUGIN_ROOT}skills/learning-skill/scripts/review-skill.sh" --fix <path-to-SKILL.md>
```

Auto-fixable issues include trailing whitespace, missing trailing newline, and minor formatting inconsistencies. Content issues always require manual fixes.

### Content Review

After structural validation passes, perform a content review using six weighted criteria.

**1. Code Correctness (25%)** — Are code examples syntactically correct, runnable, and idiomatic? Do they use current APIs and recommended patterns? Mentally trace each example or run it through `test-skill.sh`.

Checklist:
- No syntax errors in any code block
- Correct import paths and package names
- Uses current stable API (not deprecated or beta)
- Follows the technology's official style guide
- Examples are complete enough to run without guessing missing context

**2. Trigger Quality (20%)** — Will the skill's `description` field cause it to activate for the right user prompts? Are trigger phrases specific enough to avoid false positives, and broad enough to avoid false negatives?

Checklist:
- Description contains 5+ distinct trigger phrases or patterns
- Triggers include specific tool names, error messages, or symptoms where applicable
- No overlap with sibling skills' triggers (check their "When to Use" sections)
- "Do NOT use" section correctly excludes adjacent skill territories

**3. Accuracy (15%)** — Is the content factually correct? Are there outdated patterns, wrong defaults, or incorrect claims?

Checklist:
- Version numbers match current stable releases
- Configuration defaults match actual defaults
- Claims about behavior match official documentation
- No conflation of similar but distinct concepts

**4. Progressive Disclosure (15%)** — Does the skill follow the SKILL.md-as-entrypoint pattern? Is heavy reference material extracted to `references/`? Is the SKILL.md within word count limits?

Checklist:
- SKILL.md body is 1,500-2,000 words (not counting frontmatter)
- Dense API tables and comprehensive pattern lists are in `references/`
- SKILL.md links to reference files with `${CLAUDE_PLUGIN_ROOT}` paths
- One level of depth only — no references linking to other references

**5. Overlap Analysis (15%)** — Does this skill duplicate content from sibling skills in the same plugin?

Checklist:
- No section duplicates content from another skill's SKILL.md
- "When to Use" boundaries are clear and non-overlapping
- Shared concepts are referenced, not repeated
- Router skill (if present) correctly delineates skill boundaries

**6. Common Mistakes Quality (10%)** — Does the Common Mistakes section contain real, specific, actionable entries?

Checklist:
- At least 3 common mistakes listed
- Each mistake describes the symptom (how you notice it)
- Each mistake provides a concrete fix (not just "be careful")
- Mistakes reflect real pitfalls, not hypothetical edge cases

### Grading

Assign a letter grade based on the weighted criteria:

| Grade | Meaning | Action |
|---|---|---|
| A | Production-ready | Publish. No changes needed. |
| B | Minor issues | Fix listed issues, re-validate, then publish. |
| C | Needs work | Multiple sections need revision. Do not publish until fixed. |
| D | Major rewrite needed | Fundamental content or structure problems. Consider starting relevant sections over. |
| F | Failing | Missing required sections, wrong topic, or completely broken. Restart the skill. |

Calculate the grade by scoring each criterion 0-100, applying weights, and mapping the total:
- A: 90-100
- B: 80-89
- C: 70-79
- D: 50-69
- F: Below 50

### Batch Review

When reviewing all skills in a plugin, add cross-cutting checks:

1. **Overlap scan** — Read every skill's "When to Use" section. Flag any pair of skills where a single user prompt could reasonably trigger both.
2. **Boundary clarity** — For each flagged pair, verify that the "Do NOT use" sections correctly exclude the other skill's territory.
3. **Consistency** — Check that all skills use the same formatting conventions, code example style, and terminology.
4. **Router accuracy** — If a router skill exists, verify it lists all subskills and that trigger descriptions match the individual skills' descriptions.

### Trigger Testing

Generate 5 realistic user prompts and evaluate whether the skill's description would match:

1. Write 5 prompts that should trigger the skill
2. Write 3 prompts that should NOT trigger the skill (but are related)
3. For each prompt, check if the `description` field contains matching keywords or phrases
4. If any "should trigger" prompt would not match, add the missing trigger phrase to the description
5. If any "should not trigger" prompt would match, tighten the description or add a "Do NOT use" entry

### Fix Workflow

After grading, produce an actionable fix list:

1. **Run with --fix** for auto-fixable structural issues
2. **List manual fixes** in priority order (highest-weight criteria first)
3. **For each fix**, specify the exact section to edit and what the change should be
4. **After all fixes**, re-run the full review to confirm the grade improved
5. **Iterate** until grade B or above

## Quick Reference

| Review Type | Tool | When |
|---|---|---|
| Structural validation | `review-skill.sh` | After every edit |
| Auto-fix | `review-skill.sh --fix` | After structural review finds fixable issues |
| Deep content review | `review-skill.sh --deep` | Before publishing |
| Full quality review | `/review-skill` command or `skill-quality-reviewer` agent | Before publishing, periodic audits |
| Smoke testing | `/test-skill` command | After writing, before publishing |
| A/B evaluation | `/evaluate-skill` command | To measure skill impact on agent behavior |
| Batch review | Manual cross-skill analysis | Before publishing a multi-skill plugin |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Skipping structural checks | Ship skills with missing sections or broken frontmatter | Always run `review-skill.sh` before any content review |
| Generic trigger phrases | Skill does not activate for real user prompts | Include specific quoted phrases, error messages, and tool names in the description |
| Untested code examples | Agent produces broken code when following the skill | Mentally trace every code example or run `test-skill.sh` to validate |
| Ignoring overlap with siblings | Multiple skills fight for the same user queries | Check all sibling skills' "When to Use" and "Do NOT use" sections during review |
| Grading without criteria | Subjective "looks good" reviews miss real issues | Use the six weighted criteria and calculate a numeric score |
| Fixing without re-validating | Fixes introduce new issues or do not actually resolve the original problem | Always re-run the full review after applying fixes |
