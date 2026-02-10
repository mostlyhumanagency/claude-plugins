# Evaluation Rubric Template

Use this template when generating skill-specific A/B evaluation rubrics.

## Rubric for: {{SKILL_NAME}}

### Domain
{{skill domain description}}

### Key Patterns the Skill Teaches
1. {{Pattern 1}}
2. {{Pattern 2}}
3. {{Pattern 3}}

### Common Mistakes the Skill Helps Avoid
1. {{Mistake 1}} — {{Symptom}}
2. {{Mistake 2}} — {{Symptom}}

### Scoring Dimensions

#### Accuracy (0-10)
- 0-3: Major factual errors (wrong API, incorrect behavior)
- 4-6: Mostly correct but minor inaccuracies or outdated info
- 7-8: Factually correct with proper API usage
- 9-10: Perfect including edge cases and version-specific details

#### Completeness (0-10)
- 0-3: Surface level only, misses critical aspects
- 4-6: Covers main point but omits important considerations
- 7-8: All major aspects with reasonable depth
- 9-10: Comprehensive including error handling and alternatives

#### Best Practices (0-10)
- 0-3: Anti-patterns or outdated approaches
- 4-6: Functional but doesn't follow recommended patterns
- 7-8: Follows most best practices from the skill
- 9-10: Exemplary use of all taught patterns

#### Error Avoidance (0-10)
- 0-3: Falls into multiple common mistakes
- 4-6: Avoids obvious but misses subtle mistakes
- 7-8: Avoids all listed common mistakes
- 9-10: Proactively warns about potential pitfalls

#### Specificity (0-10)
- 0-3: Vague, generic advice with no code
- 4-6: Some specific advice but incomplete examples
- 7-8: Specific, mostly runnable code examples
- 9-10: Complete, runnable, well-commented code

### Evaluation Prompt Guidelines
- Target the skill's domain without naming the skill directly
- Test knowledge of: {{key concepts}}
- Include scenarios where {{common mistake}} would be tempting
- Compare responses with and without the skill loaded
