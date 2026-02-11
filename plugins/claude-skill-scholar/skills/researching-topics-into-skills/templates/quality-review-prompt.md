# Quality Review Subagent Prompt

You are reviewing the quality of a Claude Code skill. Evaluate against the criteria below.

## Skill to Review
Skill directory: {{SKILL_DIR}}
Plugin directory: {{PLUGIN_DIR}}

## SKILL.md Content
{{SKILL_CONTENT}}

## Reference Files
{{REFERENCE_CONTENT}}

## Sibling Skills (for overlap check)
{{SIBLING_DESCRIPTIONS}}

## Evaluation Criteria

For each criterion provide: Grade (A-F), Evidence (specific quotes), Improvements (concrete suggestions).

### 1. Code Example Correctness (25%)
Are code examples syntactically valid, runnable, and using current APIs? Do imports and function signatures match real libraries?

### 2. Trigger Description Quality (20%)
Is the skill description specific enough to activate on relevant prompts and avoid false positives? Does it clearly delineate when the skill applies vs. when it does not?

### 3. Content Accuracy (15%)
Are factual claims correct? Are version numbers, API behaviors, and default values accurate? Is anything outdated?

### 4. Common Mistakes Quality (10%)
Are listed mistakes genuinely common? Do they include concrete wrong-code vs. right-code comparisons? Would an experienced developer find them useful?

### 5. Progressive Disclosure (15%)
Does the skill start with the most important information? Can a reader get value from just the first section? Is advanced material separated from basics?

### 6. Skill Overlap (15%)
Does this skill duplicate content from sibling skills? Are boundaries between related skills clear? Could any content be moved to a more appropriate sibling?

## Output Format

```
CRITERION: [name]
GRADE: [A-F]
EVIDENCE: [quotes/references]
IMPROVEMENTS: [suggestions]

CRITERION: [name]
GRADE: [A-F]
EVIDENCE: [quotes/references]
IMPROVEMENTS: [suggestions]

...

OVERALL_GRADE: [letter]
TOP_IMPROVEMENTS:
1. [most impactful]
2. [second]
3. [third]
```
