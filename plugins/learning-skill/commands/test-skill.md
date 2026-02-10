---
description: Test a skill by running Claude CLI instances against generated scenarios
argument-hint: <skill-directory-path>
context: fork
---

# Test a Skill

Test the skill at **$ARGUMENTS** by running generated scenarios through Claude CLI.

## Process

1. Resolve the skill directory path from `$ARGUMENTS` (convert relative to absolute if needed)
2. Verify that `SKILL.md` exists in the resolved directory; abort with a clear error if missing
3. Run structural validation first:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/learning-skill/scripts/validate-skill.sh "$ARGUMENTS"
   ```
   If validation fails, report errors and stop before running tests.
4. Run the test script:
   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/learning-skill/scripts/test-skill.sh "$ARGUMENTS" --model haiku --verbose --budget 0.25
   ```
5. Parse the test output and present a formatted report with each scenario showing PASS/FAIL and pattern match percentage
6. If any scenarios fail, analyze SKILL.md and suggest specific improvements:
   - Are triggers too vague?
   - Are key terms missing from "When to Use"?
   - Is the scope too narrow?
7. Present a final pass/fail summary with total scenarios, passes, and failures
