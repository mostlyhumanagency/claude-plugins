# Quality Checklist for Produced Skills

Run this checklist against every skill unit before delivery.

## Frontmatter

- [ ] `name` field present — lowercase, hyphens only, max 64 chars
- [ ] `description` present — starts with "This skill should be used when the user asks to..."
- [ ] Description includes specific trigger phrases users would say (quoted)
- [ ] Description includes keywords: error messages, tool names, symptoms
- [ ] Description is 50-500 characters
- [ ] No workflow summary in description — triggering conditions only

## SKILL.md Body

- [ ] Body is 1,000-2,500 words (ideal), hard limit: 5,000
- [ ] Sections present: Overview, When to Use, Core Patterns, Quick Reference, Common Mistakes
- [ ] One excellent code example per core pattern (complete, runnable, commented)
- [ ] Quick reference table present and scannable
- [ ] Common mistakes section has symptom + fix for each
- [ ] Writing style is imperative ("Configure the server" not "You should configure")
- [ ] No emojis unless user requested them
- [ ] No narrative storytelling — techniques and patterns only
- [ ] References to bundled files use relative paths

## Progressive Disclosure

- [ ] Heavy reference content (>100 lines) extracted to `references/`
- [ ] Reference files are ONE level deep — no nested references
- [ ] SKILL.md clearly points to reference files where relevant
- [ ] Large references (>10k words) have grep search patterns in SKILL.md
- [ ] Scripts are executable and documented
- [ ] Templates/examples are complete and runnable

## Router Skill (if 4+ subskills)

- [ ] Router SKILL.md is <200 words
- [ ] Description says "...unsure which subskill applies" — it's a fallback
- [ ] Table has one row per subskill with clear trigger
- [ ] Points to the most fundamental subskill as default
- [ ] No code examples, no reference files — just routing

## Plugin Packaging

- [ ] All skills under `skills/` directory
- [ ] All agents under `agents/` directory
- [ ] All commands under `commands/` directory
- [ ] `.claude-plugin/plugin.json` has valid name, version, description
- [ ] Paths use `${CLAUDE_PLUGIN_ROOT}` for intra-plugin references
- [ ] No components inside `.claude-plugin/` (only plugin.json there)

## Testing and Validation

- [ ] Structural review passes: `review-skill.sh <skill-dir>` returns 0 errors
- [ ] Smoke tests pass: `test-skill.sh <skill-dir>` — all scenarios PASS
- [ ] A/B evaluation scores MARGINAL or better (delta > +0.3) if evaluated
- [ ] Plugin inventory shows all expected skills, agents, commands
- [ ] README.md accurately lists all components

## Maintenance

- [ ] Source manifest has `last-checked` date for each source
- [ ] Source versions match current upstream versions
- [ ] No deprecated API patterns in code examples
