---
name: maintaining-skills
description: >
  This skill should be used when the user asks to "update a skill", "refresh skills from new docs",
  "skill is outdated", "check skill staleness", "documentation has changed", or wants to bring
  existing Claude Code skills up to date with upstream changes. Triggers on requests to update,
  refresh, maintain, or check staleness of skills after documentation or version changes.
---

# Maintaining Existing Skills

## Overview

Update existing Claude Code skills when upstream documentation changes — without rewriting from scratch. Detect staleness, identify what changed, apply surgical edits, and validate the result. The goal is minimal churn: preserve custom additions, update only affected sections, and keep the skill production-ready throughout.

## When to Use

- Upstream documentation has been updated or restructured
- A new major or minor version of the technology has been released
- A skill contains stale patterns, deprecated APIs, or outdated defaults
- A user reports that skill advice is outdated or produces errors
- Periodic maintenance check on a plugin's skill set

Do NOT use when:
- Creating a new skill from scratch — use `learning-skill` instead
- Fixing structural quality issues (missing sections, bad formatting) — use `reviewing-skills` instead
- The skill content is correct but the plugin packaging is wrong — that is a publishing concern

## Core Patterns

### Staleness Detection

Start every maintenance pass by determining whether a skill is actually stale.

1. **Check source manifest** — Open `source-manifest.md` in the skill directory. Compare the `last-checked` date and `version` fields against current reality.
2. **Compare version numbers** — If the skill covers "React 19" and React 20 is out, the skill is stale. Use WebSearch to check the latest stable release.
3. **Check llms.txt** — Fetch `llms.txt` or `llms-full.txt` from the technology's domain root. Compare the document list and timestamps against what was originally used.
4. **Search for changelogs** — WebSearch for `<technology> changelog` or `<technology> release notes`. Scan for breaking changes, new APIs, and deprecations since the skill's last-checked date.
5. **Check GitHub releases** — For open-source projects, check the releases page for version bumps and migration guides.

If none of these checks reveal changes, update the `last-checked` date in `source-manifest.md` and stop. No edits needed.

### Diff Strategy

Once staleness is confirmed, identify exactly what changed before touching the skill.

1. **Categorize changes** into buckets:
   - **New APIs or features** — require new content sections
   - **Deprecated patterns** — require warnings or replacements in existing sections
   - **Changed defaults** — require updates to configuration examples
   - **Removed features** — require deletion or archival notes
   - **Restructured docs** — may require updated source URLs but no content changes

2. **Map changes to skill sections** — For each change, identify which section of SKILL.md or which reference file is affected. Many upstream changes will not affect the skill at all — a new CLI flag, for example, may not be relevant to the skill's scope.

3. **Assess scope** — If more than 60% of the skill content is affected, consider whether a rewrite is more efficient. This is rare; most updates touch 1-3 sections.

### Surgical Updates

Edit specific sections rather than rewriting. This is the core discipline of skill maintenance.

**For new APIs or features:**
- Add a new subsection or table row in the appropriate location
- Include a code example following the skill's existing example style
- Update the Quick Reference table if the skill has one

**For deprecated patterns:**
- Add a deprecation note directly above or below the deprecated content
- Provide the replacement pattern immediately after the deprecation note
- Do not remove the deprecated content if users may still be on the old version

**For changed defaults:**
- Update the specific configuration values in code examples
- Add a note about what changed and which version introduced the change
- Update any Quick Reference table entries

**For removed features:**
- Remove the content if the feature is gone from all supported versions
- If some users may still be on the old version, add a version gate: "In v5 and earlier: ... In v6+: removed"

**Preserve custom additions** — Skills often contain opinionated guidance, agent-specific tips, or common-mistake entries that do not come from upstream docs. Never remove these during an update unless they are factually wrong.

### Source Re-Fetching

When upstream docs have moved or been restructured:

1. **Re-check original URLs** from `source-manifest.md` — note any 404s or redirects
2. **Fetch llms.txt** again — it may list new or renamed pages
3. **Search for migration guides** — major versions often have dedicated migration docs
4. **Update source-manifest.md** — replace broken URLs, add new sources, remove irrelevant ones

### Version-Scoped Content

When a skill covers multiple versions of a technology:

- **Add, do not replace** — If the skill says "In v5, use `createStore()`" and v6 introduces `defineStore()`, add the v6 pattern alongside the v5 pattern
- **Use clear version labels** — Mark each pattern with the version range: "v5-v5.4:", "v6+:"
- **Set a deprecation horizon** — When a version reaches end-of-life, note it. After two major versions, consider removing the old content entirely
- **Keep the default current** — If examples do not specify a version, they should reflect the latest stable release

### Post-Update Validation

After all edits are complete:

1. **Run structural validation** — Execute `review-skill.sh` from `${CLAUDE_PLUGIN_ROOT}skills/learning-skill/scripts/` to check frontmatter, word counts, and section presence
2. **Check word counts** — SKILL.md should remain within 1,500-2,000 words. If updates pushed it over, extract detail into `references/`
3. **Verify code examples** — Mentally trace or run each updated code example to confirm correctness
4. **Update source-manifest.md** — Bump the `last-checked` date, update the `version` field, and add any new sources

## Quick Reference

| Action | When | How |
|---|---|---|
| Check staleness | After major release or on schedule | Compare `source-manifest.md` dates with current versions via WebSearch |
| Diff sources | Sources confirmed changed | Fetch updated docs, diff against skill content |
| Update sections | Specific changes identified | Edit only affected sections, preserve unchanged content |
| Add version-scoped content | New version adds alternatives | Add new patterns alongside old with version labels |
| Validate update | After all edits complete | Run `review-skill.sh`, check word counts, trace examples |
| Update manifest | After validation passes | Bump `last-checked` date and `version` in `source-manifest.md` |

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Rewriting from scratch | Lost custom additions, unnecessary churn, large diffs | Only edit sections affected by upstream changes |
| Ignoring source manifest | Cannot trace what changed or when | Always update `last-checked` date and version in `source-manifest.md` |
| Not checking llms.txt | Miss structured doc updates that are easy to diff | `llms.txt` is the fastest way to detect documentation changes |
| Removing old version content | Breaks users still on the old version | Add new version info alongside old, clearly labeled with version ranges |
| Updating without diffing first | Touch sections that did not actually change | Always categorize changes before editing |
| Forgetting to validate | Ship skills with broken word counts or missing sections | Run `review-skill.sh` after every maintenance pass |
