# Test Scenario Template

Use this template when generating test prompts for skill evaluation.

## Variables

- **SKILL_NAME**: {{skill-name}}
- **SCENARIO_TYPE**: {{positive|negative|mistake}}
- **SCENARIO_DESCRIPTION**: {{what this tests}}
- **USER_PROMPT**: {{the prompt to send}}
- **PROJECT_CONTEXT**: {{files in test dir}}
- **EXPECTED_IN_RESPONSE**: {{patterns expected in good response}}
- **NOT_EXPECTED**: {{patterns indicating incorrect behavior}}

## Prompt Construction

- **Positive scenarios**: Send USER_PROMPT directly. The skill should activate and provide relevant guidance.
- **Negative scenarios**: Send USER_PROMPT and verify the skill does NOT incorrectly activate. The prompt is outside the skill's domain.
- **Mistake scenarios**: Include a code snippet demonstrating a common mistake. The skill should identify and correct it.

## Evaluation Checklist

### Positive Pass Criteria
- [ ] Response contains 2+ of EXPECTED_IN_RESPONSE patterns
- [ ] Response includes a code example
- [ ] Response is >50 words (not a shallow answer)
- [ ] Advice follows the skill's recommended patterns

### Negative Pass Criteria
- [ ] Response does NOT incorrectly apply SKILL_NAME concepts
- [ ] Response redirects to an appropriate alternative if applicable
- [ ] Response answers the actual question asked

### Mistake Pass Criteria
- [ ] Response identifies the specific mistake
- [ ] Response provides correct fix with working code
- [ ] Response references the correct API or pattern
- [ ] Response explains why the original code is wrong
